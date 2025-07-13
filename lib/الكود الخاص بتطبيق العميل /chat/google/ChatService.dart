import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart'; // لـ kDebugMode
import 'package:get/get.dart'; // قد تحتاجه للوصول لخدمات أخرى مثل StorageService

import 'package:path_provider/path_provider.dart'; // لتحديد مسار الحفظ المحلي
import 'package:path/path.dart' as p;

import 'FirestoreConstants.dart';
import 'Message.dart';
import 'MessageRepository.dart';
import 'StorageService.dart';             // للمساعدة في التعامل مع المسارات


class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // الحصول على StorageService (يجب أن يكون مسجلاً في GetX)
  final StorageService _storageService = Get.find<StorageService>();

  String get currentUserId {
    // تأكد من أن المستخدم مسجل الدخول
    final user = _auth.currentUser;
    if (user == null || user.uid.isEmpty) {
      if(kDebugMode) debugPrint("!!! ChatService Error: Current user is null or has empty UID.");
      // يمكنك رمي خطأ هنا أو إرجاع سلسلة فارغة بحذر
      // throw Exception("User not authenticated");
      return ""; // التعامل بحذر في المستودع
    }
    return user.uid;
  }
  CollectionReference getMessagesCollectionRef(String userId, String otherUserId) {
    // ملاحظة: عند جلب رسائل *الطرف الآخر*، يكون صندوق الوارد الخاص بنا هو
    // messages collection تحت /Chat/{myUserId}/chat/{otherUserId}/messages
    // ولكن في ChatService، عادة ما نعيد المسار العام، والفلترة (بـ senderId) تحدث لاحقًا.
    // لكن، لسيناريو catch-up حيث تجلب رسائل الطرف الآخر الموجهة إليك، يكون هذا المسار هو الصحيح.
    // userId هنا هو myId (المستخدم الحالي), و otherUserId هو شريك المحادثة
    return messagesCollection(userId, otherUserId);
  }

  // --- المراجع الأساسية لمسارات Firestore ---
  DocumentReference userChatRef(String userId, String otherUserId) => _firestore
      .collection(FirestoreConstants.chatCollection)
      .doc(userId)
      .collection(FirestoreConstants.chatSubCollection)
      .doc(otherUserId);

  CollectionReference messagesCollection(String userId, String otherUserId) =>
      userChatRef(userId, otherUserId)
          .collection(FirestoreConstants.messagesSubCollection);

  // --- 1. رفع الملفات وكتابة الرسالة في Firestore ---
  /// يرفع ملف الوسائط والصورة المصغرة (إذا وجدت)، ثم يكتب بيانات الرسالة
  /// إلى Firestore للمرسل والمستقبل.
  Future<UploadResult> uploadAndWriteMessage(
      Message message, { // كائن الرسالة الأصلي
        File? fileToUpload,   // الملف الرئيسي للرفع (صورة/فيديو/صوت)
        File? thumbnailFile, // ملف الصورة المصغرة (للفيديو)
        required String senderName, // <--- استقبل اسم المرسل

      }) async {
    String finalContentUrl = message.content; // النص الأصلي أو المسار المؤقت
    String? finalThumbnailUrl = message.thumbnailUrl;
    final messageId = message.messageId; // استخدم نفس الـ ID الذي تم إنشاؤه محليًا

    try {
      // --- أ. رفع الملف الرئيسي (إذا كان موجودًا) ---
      if (fileToUpload != null) {
        String storagePath = '';
        switch(message.type) {
          case FirestoreConstants.typeImage:
            storagePath = _storageService.getImagePath(messageId);
            break;
          case FirestoreConstants.typeVideo:
            storagePath = _storageService.getVideoPath(messageId, fileToUpload.path);
            break;
          case FirestoreConstants.typeAudio:
            storagePath = _storageService.getAudioPath(messageId);
            break;
          default:
            throw Exception("Invalid media type for upload: ${message.type}");
        }
        if (kDebugMode) debugPrint("[ChatService] Uploading main file to: $storagePath");
        final uploadedUrl = await _storageService.uploadFile(fileToUpload, storagePath);
        if (uploadedUrl == null) {
          throw Exception("Main file upload failed for message $messageId");
        }
        finalContentUrl = uploadedUrl; // تحديث المحتوى ليكون الرابط البعيد
        if (kDebugMode) debugPrint("[ChatService] Main file uploaded successfully. URL: $finalContentUrl");
      }

      // --- ب. رفع الصورة المصغرة (إذا كانت موجودة) ---
      if (thumbnailFile != null) {
        final thumbStoragePath = _storageService.getThumbnailPath(messageId);
        if (kDebugMode) debugPrint("[ChatService] Uploading thumbnail file to: $thumbStoragePath");
        final uploadedThumbUrl = await _storageService.uploadFile(thumbnailFile, thumbStoragePath);
        if (uploadedThumbUrl == null) {
          // لا تفشل العملية كلها بسبب المصغرة، لكن سجل تحذيرًا
          if (kDebugMode) debugPrint("!!! [ChatService] Thumbnail upload failed for message $messageId. Proceeding without thumbnail URL.");
        } else {
          finalThumbnailUrl = uploadedThumbUrl; // تحديث رابط المصغرة
          if (kDebugMode) debugPrint("[ChatService] Thumbnail uploaded successfully. URL: $finalThumbnailUrl");
        }
      }

      // --- ج. تجهيز بيانات الرسالة لـ Firestore ---
      // نستخدم الطابع الزمني للخادم لضمان الترتيب الصحيح عبر الأجهزة
      // ونضمن أن content و thumbnail هي الروابط البعيدة الآن
      final firestoreMessageData = message
          .copyWith(
        content: finalContentUrl, // تأكد من استخدام الرابط البعيد هنا
        thumbnailUrl: finalThumbnailUrl,
        timestamp: null, // للسماح لـ toFirestoreMap باستخدام FieldValue.serverTimestamp
      )
          .toFirestoreMap() // هذه الدالة يجب أن تضيف FieldValue.serverTimestamp إذا كان timestamp هو null
        .. [FirestoreConstants.timestamp] = FieldValue.serverTimestamp(); // تأكيد إضافة الطابع الزمني للخادم


      // --- د. تجهيز ملخص آخر رسالة ---
      // هذا يبقى في _commitMessageToFirebase
      // final lastMessageSummaryData = _prepareLastMessageSummary(...);


      // --- هـ. الكتابة في Firestore باستخدام Batch ---
      await commitMessageToFirebase(
          message.senderId, message.recipientId, messageId, firestoreMessageData, senderName
      );

      // --- و. إرجاع النتيجة مع الروابط ---
      return UploadResult(
        success: true,
        contentUrl: finalContentUrl,
        thumbnailUrl: finalThumbnailUrl,
      );

    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint("!!! [ChatService] Error in uploadAndWriteMessage ($messageId): $e\n$stackTrace");
      }
      // إعادة النتيجة بالفشل
      return UploadResult(success: false);
    }
  }





  Future<File?> downloadMediaAndSaveToAppSpecificDir({
    required String remoteUrl,
    required String targetFileName,
    required String subDirectoryName, // مثل "sent_media"
  }) async {
    if (remoteUrl.isEmpty || targetFileName.isEmpty || subDirectoryName.isEmpty) {
      if (kDebugMode) debugPrint("  ❌ [ChatService downloadMediaAndSave] Invalid parameters: URL, FileName, or SubDirectory is empty.");
      return null;
    }

    File? targetFile; // لسهولة الوصول إليه في كتلة catch

    try {
      final appDocsDir = await getApplicationDocumentsDirectory();
      final targetDirPath = p.join(appDocsDir.path, subDirectoryName);
      final targetDir = Directory(targetDirPath);

      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
        if (kDebugMode) debugPrint("    [ChatService downloadMediaAndSave] Created directory: $targetDirPath");
      }

      final fullLocalPath = p.join(targetDirPath, targetFileName);
      targetFile = File(fullLocalPath);

      if (kDebugMode) debugPrint("  [ChatService downloadMediaAndSave] Attempting to download: $remoteUrl -> $fullLocalPath");

      // حذف أي ملف قديم بنفس المسار إذا أردت ضمان عدم التداخل
      if (await targetFile.exists()) {
        if (kDebugMode) debugPrint("    [ChatService downloadMediaAndSave] Deleting existing local file: $fullLocalPath");
        await targetFile.delete();
      }

      if (remoteUrl.contains("firebasestorage.googleapis.com")) {
        if (kDebugMode) debugPrint("    [ChatService downloadMediaAndSave] Using Firebase Storage DownloadTask.");
        final storageRef = FirebaseStorage.instance.refFromURL(remoteUrl);
        // *** DownloadTask يكتب إلى الملف مباشرة ***
        final downloadTask = storageRef.writeToFile(targetFile);

        // (اختياري) يمكنك الاستماع لتقدم التنزيل هنا إذا أردت
        // downloadTask.snapshotEvents.listen((taskSnapshot) {
        //   final progress = taskSnapshot.bytesTransferred / taskSnapshot.totalBytes;
        //   if (kDebugMode) debugPrint('    [ChatService Download Progress ($targetFileName)]: ${(progress * 100).toStringAsFixed(1)}%');
        // });

        await downloadTask; // انتظر اكتمال التنزيل

        if (await targetFile.exists() && await targetFile.length() > 0) {
          if (kDebugMode) debugPrint("    ✅ [ChatService downloadMediaAndSave] Firebase Download COMPLETE. Path: $fullLocalPath, Size: ${await targetFile.length()} bytes.");
          return targetFile;
        } else {
          throw Exception("Firebase DownloadTask completed but target file invalid or empty.");
        }
      } else {
        // منطق التنزيل لروابط HTTP العادية (إذا كنت تدعمها)
        if (kDebugMode) debugPrint("    [ChatService downloadMediaAndSave] Using GetHttpClient for general URL (NOT IMPLEMENTED YET IN THIS VERSION).");
        // إذا كنت تحتاج لدعم روابط HTTP عامة، أضف الكود هنا باستخدام http.get أو GetHttpClient
        // واحفظ الـ bodyBytes في targetFile.
        // مثال باستخدام http (ستحتاج لإضافة `import 'package:http/http.dart' as http;`)
        // final response = await http.get(Uri.parse(remoteUrl));
        // if (response.statusCode == 200) {
        //   await targetFile.writeAsBytes(response.bodyBytes, flush: true);
        //   if (kDebugMode) debugPrint("    ✅ [ChatService downloadMediaAndSave] HTTP Download COMPLETE. Path: $fullLocalPath, Size: ${await targetFile.length()} bytes.");
        //   return targetFile;
        // } else {
        //   throw HttpException('Failed to download general URL: ${response.statusCode}');
        // }
        throw UnimplementedError("General HTTP URL download not implemented in this ChatService function yet.");
      }
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint("  ❌ [ChatService downloadMediaAndSave] ERROR downloading '$remoteUrl' to '$targetFileName': $e\n$s");
      }
      // حاول حذف الملف غير المكتمل
      try {
        if (targetFile != null && await targetFile.exists()) {
          await targetFile.delete();
        }
      } catch (delErr) {
        if (kDebugMode) debugPrint("    [ChatService downloadMediaAndSave] Error deleting incomplete file: $delErr");
      }
      return null;
    }
  }







  /// دالة مساعدة لكتابة الرسالة وملخصها في Firestore دفعة واحدة.
  Future<void> commitMessageToFirebase(
      String senderId, String recipientId, String messageId, Map<String, dynamic> firestoreMessageDataInput,    String senderName // اسم المرسل
      ) async {

    // * تعديل هنا: اعمل نسخة من firestoreMessageDataInput لتجنب تعديل الكائن الأصلي بطرق غير متوقعة
    final Map<String, dynamic> baseMessageData = Map<String, dynamic>.from(firestoreMessageDataInput);

    // تأكد من أن الطابع الزمني والخادم و isRead مضبوطان بشكل صحيح للرسالة نفسها
    final Map<String, dynamic> finalMessageDataForFirestore = {
      ...baseMessageData,
      FirestoreConstants.isRead: false, // كل نسخ الرسائل تبدأ بـ isRead: false
      FirestoreConstants.timestamp: FieldValue.serverTimestamp(), // ضمان طابع الخادم
    };

    // --- تجهيز ملخص آخر رسالة ---
    final String messageType = finalMessageDataForFirestore[FirestoreConstants.messageType] ?? '';
    String summaryText = '';
    switch (messageType) {
      case FirestoreConstants.typeText:
        String text = finalMessageDataForFirestore[FirestoreConstants.messageContent] ?? '';
        summaryText = text.length > 40 ? '${text.substring(0, 37)}...' : text;
        break;
      case FirestoreConstants.typeImage: summaryText = '📷 Photo'; break;
      case FirestoreConstants.typeVideo: summaryText = '📹 Video'; break;
      case FirestoreConstants.typeAudio: summaryText = '🎤 Voice Message'; break;
      default: summaryText = '...';
    }

    // البيانات المشتركة لملخصي المرسل والمستقبل
    final Map<String, dynamic> commonSummaryData = {
      FirestoreConstants.senderId: senderId,      // مرسل الرسالة
      FirestoreConstants.recipientId: recipientId,  // مستلم الرسالة
      'senderName': senderName,
      FirestoreConstants.messageContent: summaryText,
      FirestoreConstants.messageType: messageType,
      FirestoreConstants.timestamp: finalMessageDataForFirestore[FirestoreConstants.timestamp], // استخدم الطابع الزمني الذي سيُكتب للرسالة
      FirestoreConstants.messageId: messageId,
      FirestoreConstants.thumbnailUrl: finalMessageDataForFirestore[FirestoreConstants.thumbnailUrl],
      if(finalMessageDataForFirestore.containsKey('quotedMessageId')) 'quotedMessageId': finalMessageDataForFirestore['quotedMessageId'],
    };
    // --- نهاية تجهيز الملخص ---

    final batch = _firestore.batch();

    // 1. الرسالة في صندوق المرسل
    final senderMsgRef = messagesCollection(senderId, recipientId).doc(messageId);
    batch.set(senderMsgRef, finalMessageDataForFirestore); // finalMessageDataForFirestore يحتوي على isRead: false

    // 2. الرسالة في صندوق المستقبل
    final recipientMsgRef = messagesCollection(recipientId, senderId).doc(messageId);
    batch.set(recipientMsgRef, finalMessageDataForFirestore); // finalMessageDataForFirestore يحتوي على isRead: false

    // 3. تحديث ملخص آخر رسالة للمرسل
    final senderChatListRef = userChatRef(senderId, recipientId);
    batch.set(senderChatListRef, {
      ...commonSummaryData,
      FirestoreConstants.isRead: true // ملخص المرسل يكون مقروءًا من طرفه
    });

    // 4. تحديث ملخص آخر رسالة للمستقبل
    final recipientChatListRef = userChatRef(recipientId, senderId);
    batch.set(recipientChatListRef, {
      ...commonSummaryData,
      FirestoreConstants.isRead: false // ملخص المستقبل يكون غير مقروء
    });
    DocumentReference recipientUserDocRef = _firestore.collection(FirestoreConstants.userCollection).doc(recipientId);
    batch.update(recipientUserDocRef, {'hasUnreadMessages': true});

    if (kDebugMode) debugPrint("[ChatService] Committing message $messageId. Sender Summary isRead: true, Recipient Summary isRead: false. Message copies isRead: false.");
    await batch.commit();
    if (kDebugMode) debugPrint("[ChatService] Firestore commit successful for $messageId.");
  }


  // --- 2. الاستماع للرسائل الواردة الجديدة فقط ---
  /// يُرجع تيارًا يستمع فقط للرسائل الجديدة التي أرسلها الطرف الآخر لك.
  /// نستخدم طابعًا زمنيًا أو حالة 'sent' لتحديد الرسائل "الجديدة".
  // داخل ChatService.dart

  Stream<List<DocumentSnapshot>> listenForNewFirebaseMessages(String otherUserId, {Timestamp? startAfterTimestamp}) {
    final myId = currentUserId;
    if (myId.isEmpty) return Stream.value([]); // التعامل مع حالة عدم جاهزية ID المستخدم

    // إذا لم يتم توفير startAfterTimestamp، استخدم الوقت الحالي (السلوك الافتراضي لـ GlobalListener)
    // إذا تم توفيره (لـ catch-up)، استخدمه
    final effectiveStartTimestamp = startAfterTimestamp ?? Timestamp.now();

    if (kDebugMode) {
      String mode = startAfterTimestamp != null
          ? 'Catch-up Mode (since ${startAfterTimestamp.toDate().toIso8601String()})'
          : 'Live Mode (from now)';
      debugPrint("[ChatService Listener - $otherUserId] Mode: $mode for user $myId.");
    }

    Query query = messagesCollection(myId, otherUserId)
        .where(FirestoreConstants.senderId, isEqualTo: otherUserId) // رسائل الطرف الآخر فقط
        .where(FirestoreConstants.timestamp, isGreaterThan: effectiveStartTimestamp); // <<--- استخدام الطابع الفعال

    // ترتيب الرسائل الواردة. (تصاعدي: الأقدم أولاً)
    query = query.orderBy(FirestoreConstants.timestamp, descending: false);

    return query.snapshots().map((snapshot) {
      if (kDebugMode && snapshot.docs.isNotEmpty) {
        debugPrint("  [ChatService Listener - $otherUserId] Firestore received ${snapshot.docs.length} new message(s).");
      }
      return snapshot.docs; // إرجاع قائمة الوثائق
    }).handleError((error, stackTrace) {
      if (kDebugMode) {
        debugPrint("!!! [ChatService Listener - $otherUserId] Error in Firestore stream: $error\n$stackTrace");
      }
      // يمكنك إعادة رمي الخطأ أو معالجته هنا إذا لزم الأمر
    });
  }

  // --- 3. تنزيل ملف الوسائط ---
  /// يحمّل ملفًا من رابط Firebase Storage أو أي رابط URL
  /// ويحفظه في مسار محلي مناسب، ثم يُرجع كائن File.
  Future<File?> downloadMedia(String remoteUrl, String localFileName) async {
    if (kDebugMode) debugPrint("[ChatService] Attempting to download media: $remoteUrl into $localFileName");
    final directory = await getTemporaryDirectory(); // الحصول على المجلد المؤقت
    final localFilePath = p.join(directory.path, localFileName); // المسار الكامل للملف المحلي
    final targetFile = File(localFilePath); // كائن الملف المراد الكتابة فيه

    try {

      // حذف أي ملف قديم بنفس الاسم
      if (await targetFile.exists()) {
        if (kDebugMode) debugPrint("[ChatService] Deleting existing local file: $localFilePath");
        await targetFile.delete();
      }

      // التحقق إذا كان الرابط هو رابط Firebase Storage
      if (remoteUrl.contains("firebasestorage.googleapis.com")) {
        // --- استخدام DownloadTask من Firebase ---
        if (kDebugMode) debugPrint("[ChatService] Using Firebase Storage DownloadTask for $remoteUrl");
        final storageRef = FirebaseStorage.instance.refFromURL(remoteUrl);
        // --- تأكد من تمرير targetFile هنا ---
        final downloadTask = storageRef.writeToFile(targetFile);

        // الاستماع للتقدم (اختياري)
        StreamSubscription<TaskSnapshot>? progressSubscription; // لتتمكن من إلغائه
        progressSubscription = downloadTask.snapshotEvents.listen((taskSnapshot) {
          final progress = taskSnapshot.bytesTransferred / taskSnapshot.totalBytes;
          if (kDebugMode) debugPrint('[ChatService] Download Progress ($localFileName): ${(progress * 100).toStringAsFixed(2)}%');
        }, onError: (error){
          if(kDebugMode) debugPrint("!!! [ChatService] Error during DownloadTask stream for $localFileName : $error");
          progressSubscription?.cancel(); // ألغي الاستماع عند الخطأ
        }, onDone: () {
          progressSubscription?.cancel(); // ألغي الاستماع عند الاكتمال
        });

        await downloadTask; // انتظار اكتمال التنزيل

        if(await targetFile.exists()){ // تحقق من وجود الملف
          if (kDebugMode) debugPrint("[ChatService] Firebase Storage Download complete for: $localFilePath");
          return targetFile; // إرجاع الملف المنزل
        } else {
          throw Exception("Firebase DownloadTask completed but file not found.");
        }
      }
      else {
        // --- (الطريقة البديلة) استخدام GetHttpClient ---
        if (kDebugMode) debugPrint("[ChatService] Using GetHttpClient for general URL download: $remoteUrl");

        // --- التعديل هنا لاستخدام GetHttpClient بشكل صحيح ---
        final GetHttpClient httpClient = Get.find<GetHttpClient>();
        final Response<dynamic> response = await httpClient.get(
          remoteUrl,
          // لا يوجد decoder قياسي للبايتات هنا بنفس طريقة الخيارات السابقة،
          // يجب التعامل مع الجسم مباشرة.
          // سنستخدم Response<dynamic> لتلقي الاستجابة الأولية.
        );

        if (response.statusCode == 200 && response.bodyBytes != null) {
          // --- الوصول إلى التيار وتجميعه ---
          final Stream<List<int>> byteStream = response.bodyBytes!; // bodyBytes هو Stream

          // استخدام sink لفتح الملف للكتابة وقراءة التيار إليه
          final IOSink sink = targetFile.openWrite();
          // List<int> allBytes = []; // بديل التجميع في الذاكرة (لا يُنصح به للملفات الكبيرة)

          await byteStream.forEach((chunk) {
            // allBytes.addAll(chunk); // طريقة التجميع في الذاكرة
            sink.add(chunk); // الكتابة مباشرة في الملف جزءًا بجزء
          });

          await sink.flush(); // ضمان كتابة كل شيء من الـ buffer
          await sink.close(); // إغلاق الملف للكتابة

          // await targetFile.writeAsBytes(allBytes, flush: true); // طريقة الكتابة بعد التجميع

          // التحقق النهائي من حجم الملف
          final fileLength = await targetFile.length();
          if (kDebugMode) debugPrint("[ChatService] HTTP Download complete via GetConnect for: $localFilePath (Size: $fileLength bytes)");
          if (fileLength > 0) {
            return targetFile;
          } else {
            // خطأ في الاستجابة
            // الملف فارغ لسبب ما
            try { await targetFile.delete(); } catch (_) {} // حذف الملف الفارغ
            throw Exception("HTTP Download completed but resulted file is empty.");
          }

        } else {
          // خطأ في الاستجابة أو لا يوجد جسم
          throw HttpException('Failed to download file: ${response.statusCode} - ${response.statusText ?? 'No status text'}');
        }
        // --- نهاية التعديل ---
      }

    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint("!!! [ChatService] Error downloading media ($localFileName): $e\n$stackTrace");
      }
      // حذف الملف غير المكتمل
      if(await targetFile.exists()){ try { await targetFile.delete(); } catch(_){} }
      return null; // إرجاع null عند الفشل
    }
  }

// --- (اختياري) وظائف أخرى ---
// Future<void> updateFirestoreReadStatus(...) // لتحديث حالة القراءة في Firestore
// Future<void> deleteMessageFromFirestore(...) // لحذف رسالة

}