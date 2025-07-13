import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_storage/get_storage.dart';

import '../../../XXX/xxx_firebase.dart';
import 'FirestoreConstants.dart';
import 'MessageRepository.dart';

class GlobalMessageListenerService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription? _conversationsSubscription;
  final GetStorage _storage = GetStorage(); // <--- إنشاء صندوق تخزين
  final String _lastSyncTimestampsKey = 'last_sync_timestamps';

  // متغير لتتبع آخر timestamp تمت معالجته لكل محادثة لمنع التكرار
  final Map<String, Timestamp> _lastProcessedTimestamp = {};

  @override
  void onInit() {
    super.onInit();
    debugPrint("[GlobalListenerService] Initializing...");
    // البدء الفوري للاستماع بمجرد تسجيل دخول المستخدم
    // يمكنك استخدام Rx لاشتراك Firebase Auth أو طريقة أخرى لمعرفة حالة تسجيل الدخول
    // هنا نفترض أن الخدمة يتم إنشاؤها فقط بعد تسجيل الدخول
    startListening();
  }

  @override
  void onClose() {
    debugPrint("[GlobalListenerService] Closing...");
    stopListening(); // إيقاف الاستماع عند إغلاق الخدمة
    super.onClose();
  }





  // --- جلب الخريطة المخزنة للطوابع الزمنية ---
  Map<String, int> _loadLastTimestamps() {
    try {
      // قراءة الخريطة من GetStorage
      final Map<String, dynamic>? storedMap = _storage.read<Map<String, dynamic>>(_lastSyncTimestampsKey);
      // تحويل القيم إلى int (millisecondsSinceEpoch)
      return storedMap?.map((key, value) => MapEntry(key, value is int ? value : 0)) ?? {};
    } catch (e) {
      if (kDebugMode) debugPrint("!!! Error loading last timestamps from GetStorage: $e");
      return {}; // إرجاع خريطة فارغة عند الخطأ
    }
  }

  // --- حفظ الطابع الزمني الأخير لمحادثة معينة ---
  Future<void> _saveLastTimestamp(String otherUserId, Timestamp timestamp) async {
    // التأكد من أن المعرف والطابع الزمني صالحان
    if (otherUserId.isEmpty || timestamp.millisecondsSinceEpoch <= 0) return;

    // قراءة الخريطة الحالية
    Map<String, int> currentTimestamps = _loadLastTimestamps();
    // تحديث أو إضافة الطابع الزمني (كم عدد صحيح يمثل مللي ثانية)
    currentTimestamps[otherUserId] = timestamp.millisecondsSinceEpoch;
    // حفظ الخريطة المحدثة
    await _storage.write(_lastSyncTimestampsKey, currentTimestamps);
    if (kDebugMode) debugPrint("   -> Updated last timestamp for $otherUserId to ${timestamp.toDate()}");
  }

  // --- جلب آخر طابع زمني محفوظ لمحادثة معينة ---
  Timestamp _getLastTimestampFor(String otherUserId) {
    final Map<String, int> timestamps = _loadLastTimestamps();
    final int millis = timestamps[otherUserId] ?? 0; // القيمة الافتراضية صفر
    // أضف جزء صغير جداً من الثانية للتأكد من أن where isGreaterThan يعمل
    return Timestamp(millis ~/ 1000, (millis % 1000) * 1000000 + 1);
    // أو يمكنك فقط إرجاع Timestamp.fromMillisecondsSinceEpoch(millis)
    // والاعتماد على أن Firestore ستجلب الوثائق المساوية أيضًا في بعض الأحيان
  }

  /// تبدأ الاستماع لتغييرات ملخصات المحادثات للمستخدم الحالي.
  void startListening() {
    final userId = _auth.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      debugPrint("[GlobalListenerService] Cannot start listening: User not logged in.");
      return;
    }

    // تأكد من إلغاء أي مستمع قديم
    stopListening();

    if (kDebugMode) debugPrint("[GlobalListenerService] Starting to listen for conversation updates for user: $userId");

    final conversationsQuery = _firestore
        .collection(FirestoreConstants.chatCollection)
        .doc(userId)
        .collection(FirestoreConstants.chatSubCollection)
        .orderBy(FirestoreConstants.timestamp, descending: true);
    // استمع فقط للتغييرات التي تحدث الآن فصاعدًا (اختياري، يساعد في تقليل الحمل الأولي)
    // .where(FirestoreConstants.timestamp, isGreaterThan: Timestamp.now())
    // **ملاحظة:** الاعتماد على isRead: false هنا قد يكون غير دقيق إذا كان الطرف
    // الآخر يقرأ الرسالة قبل أن تراها أنت. الأفضل الاعتماد على timestamp.

    _conversationsSubscription = conversationsQuery.snapshots().listen(
            (snapshot) {
          if (kDebugMode) debugPrint("[GlobalListenerService] Received ${snapshot.docChanges.length} document change(s).");
          // معالجة كل تغيير (رسالة جديدة أو تعديل على ملخص محادثة)
          for (var change in snapshot.docChanges) {
            // اهتم فقط بالتغييرات الجديدة أو المعدلة التي لم تتم معالجتها
            if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
              _processConversationUpdate(change.doc); // الدالة ستتحقق من الطابع الزمني
            }
          }
        },
        onError: (error, stackTrace) {
          if (kDebugMode) debugPrint("!!! [GlobalListenerService] Error in conversations listener: $error\n$stackTrace");
          // يمكنك محاولة إعادة الاتصال هنا
          // Future.delayed(Duration(seconds: 10), () => startListening());
        },
        onDone: () { // عند إغلاق التيار (نادر، قد يحدث عند مشاكل اتصال)
          if (kDebugMode) debugPrint("[GlobalListenerService] Conversations stream closed.");
          // يمكنك محاولة إعادة الاتصال
          // startListening();
        }
    );
    debugPrint("[GlobalListenerService] Listener attached successfully.");
  }


  /// إيقاف الاستماع الحالي.
  void stopListening() {
    if (_conversationsSubscription != null) {
      _conversationsSubscription!.cancel();
      _conversationsSubscription = null;
      if (kDebugMode) debugPrint("[GlobalListenerService] Listener stopped.");
    }
  }






  // // داخل كلاس GlobalMessageListenerService
  //
  // // --- تعديل _processConversationUpdate (النسخة الكاملة والمحدثة) ---
  // Future<void> _processConversationUpdate(DocumentSnapshot convSummaryDoc) async {
  //   final myUserId = _auth.currentUser?.uid;
  //   if (myUserId == null || myUserId.isEmpty) {
  //     debugPrint("!!! [GlobalListenerService] Cannot process update: User not logged in.");
  //     return;
  //   }
  //
  //   final data = convSummaryDoc.data() as Map<String, dynamic>? ?? {};
  //
  //   // --- 1. استخراج البيانات الهامة من الملخص ---
  //   final String otherUserId = convSummaryDoc.id; // معرف الطرف الآخر هو معرف وثيقة الملخص
  //   final String lastSenderId = data[FirestoreConstants.senderId] ?? ''; // ID آخر من أرسل
  //   final String lastMessageId = data[FirestoreConstants.messageId] ?? ''; // ID آخر رسالة
  //   final Timestamp? lastTimestamp = data[FirestoreConstants.timestamp] as Timestamp?;
  //   final String lastMessageType = data[FirestoreConstants.messageType] ?? FirestoreConstants.typeText;
  //   final String previewText = data[FirestoreConstants.messageContent] ?? ''; // نص المعاينة أو نوع الوسائط
  //   // اقرأ senderName المحفوظ في الملخص، استخدم ID الطرف الآخر كاحتياطي
  //   final String senderNameForNotification = data['senderName'] ?? otherUserId;
  //
  //   if (kDebugMode) {
  //     debugPrint("-> [GlobalListener Processing $otherUserId] Summary update detected:");
  //     debugPrint("   LastSender: $lastSenderId, LastMsgID: $lastMessageId, LastTimestamp: ${lastTimestamp?.toDate()}");
  //     debugPrint("   MyUserID: $myUserId");
  //   }
  //
  //   // --- **2. جلب اسم المرسل (senderName) ديناميكيًا** ---
  //   String senderNameToDisplay = otherUserId; // قيمة افتراضية أولية (ID)
  //   try {
  //
  //     // تأكد من أن lastSenderId ليس فارغًا قبل استخدامه
  //     if(lastSenderId.isNotEmpty){
  //       final userDoc = await _firestore
  //           .collection(FirebaseX.collectionApp) // <--- تأكد أن هذا اسم المجموعة الصحيح للمستخدمين
  //           .doc(lastSenderId) // <-- استخدام ID آخر مرسل من الملخص
  //           .get();
  //
  //       if (userDoc.exists) {
  //         // استخدم اسم الحقل 'name' كما ذكرت أنه موجود في مجموعتك
  //         senderNameToDisplay = userDoc.data()?['name'] as String? ?? otherUserId; // <-- قراءة حقل 'name'
  //         if (kDebugMode) debugPrint("      Fetched sender name for $lastSenderId: '$senderNameToDisplay'");
  //       } else {
  //         if (kDebugMode) debugPrint("      Sender document $lastSenderId not found. Using ID as name.");
  //         senderNameToDisplay = lastSenderId; // أو يمكنك استخدام otherUserId إذا أردت
  //       }
  //     } else {
  //       if (kDebugMode) debugPrint("      Last sender ID is empty in summary! Using otherUserID as fallback name.");
  //     }
  //   } catch(e){
  //     if(kDebugMode) debugPrint("!!! Error fetching sender name ($lastSenderId): $e. Using ID/OtherID as name.");
  //     // استخدم ID المرسل أو الطرف الآخر كاحتياطي عند الخطأ
  //     senderNameToDisplay = lastSenderId.isNotEmpty ? lastSenderId : otherUserId;
  //   }
  //   // --- **نهاية جلب الاسم** ---
  //
  //
  //   // --- 2. التحقق الأولي ---
  //   // تجاهل إذا كنت أنا آخر مرسل، أو إذا لم يكن هناك ID للرسالة أو timestamp
  //   if (lastSenderId == myUserId || lastMessageId.isEmpty || lastTimestamp == null) {
  //     if (kDebugMode && lastSenderId == myUserId) debugPrint("   -> Skipping: Last message sent by me.");
  //     if (kDebugMode && (lastMessageId.isEmpty || lastTimestamp == null)) debugPrint("   -> Skipping: Missing message ID or timestamp in summary.");
  //     return;
  //   }
  //
  //
  //
  //   // --- 3. التحقق من الطابع الزمني لمنع المعالجة المكررة ---
  //   final lastProcessedTimestamp = _getLastTimestampFor(otherUserId);
  //   if (!lastTimestamp.toDate().isAfter(lastProcessedTimestamp.toDate())) {
  //     // if (kDebugMode) debugPrint("   -> Skipping update for $otherUserId: Already processed timestamp ${lastTimestamp.toDate()} (or newer: ${lastProcessedTimestamp.toDate()}).");
  //     return;
  //   }
  //   // --- نهاية التحقق من الطابع الزمني ---
  //
  //   if (kDebugMode) debugPrint("   -> Processing NEW update for $otherUserId (Msg ID: $lastMessageId)");
  //
  //   // --- 4. محاولة جلب الرسالة الكاملة ---
  //   DocumentSnapshot? fullMessageDoc;
  //   try {
  //     // --- المحاولة الأولى: من صندوق الوارد الخاص بي (الأمثل) ---
  //     if (kDebugMode) debugPrint("      Attempting to fetch full msg $lastMessageId from MY inbox (path: Chat/$myUserId/chat/$lastSenderId/messages/$lastMessageId)...");
  //     fullMessageDoc = await _firestore
  //         .collection(FirestoreConstants.chatCollection).doc(myUserId)
  //         .collection(FirestoreConstants.chatSubCollection).doc(lastSenderId)
  //         .collection(FirestoreConstants.messagesSubCollection).doc(lastMessageId)
  //         .get();
  //
  //     // --- المحاولة الثانية (احتياطية): من صندوق الصادر للمرسل (إذا لم توجد في صندوقي ويتطلب قواعد أمان تسمح بذلك) ---
  //     if (!fullMessageDoc.exists) {
  //       if (kDebugMode) debugPrint("      Message $lastMessageId not found in MY inbox. Attempting to fetch from SENDER'S outbox (path: Chat/$lastSenderId/chat/$myUserId/messages/$lastMessageId)...");
  //       // هذا يفترض أنك قمت بتعديل Firestore Rules للسماح بذلك
  //       fullMessageDoc = await _firestore
  //           .collection(FirestoreConstants.chatCollection).doc(lastSenderId)
  //           .collection(FirestoreConstants.chatSubCollection).doc(myUserId)
  //           .collection(FirestoreConstants.messagesSubCollection).doc(lastMessageId)
  //           .get();
  //
  //       if (!fullMessageDoc.exists){
  //         if (kDebugMode) debugPrint("      !!! Message $lastMessageId not found in SENDER'S outbox either!");
  //         // لم يتم العثور على الرسالة في أي مكان (مشكلة مزامنة؟ أو خطأ في commit؟)
  //         // ماذا نفعل هنا؟ هل نظهر الإشعار أم نتجاهل؟
  //         // لنفترض أننا سنتجاهلها لأن البيانات غير كاملة
  //         return; // تجاهل هذه الرسالة الآن
  //       }
  //     }
  //     if (kDebugMode) debugPrint("      Successfully fetched full message $lastMessageId. Has data: ${fullMessageDoc.data() != null}");
  //
  //   } catch (e, s) {
  //     if (kDebugMode) debugPrint("!!! [GlobalListenerService] Error fetching full message ($lastMessageId): $e\n$s");
  //     // فشل الجلب، سنكتفي بالإشعار لاحقاً بناءً على الملخص
  //     fullMessageDoc = null;
  //   }
  //
  //   // --- 5. معالجة الرسالة الكاملة في المستودع (إذا تم جلبها) ---
  //   bool processedSuccessfully = false; // تتبع نجاح المعالجة لتحديث الطابع الزمني
  //   MessageRepository? repository;
  //
  //   if (fullMessageDoc != null && fullMessageDoc.exists) {
  //     try {
  //       repository = Get.find<MessageRepository>();
  //
  //       if (kDebugMode) debugPrint("   -> Calling repository.processAndStoreIncomingMessage for $lastMessageId...");
  //       await repository.processAndStoreIncomingMessage(fullMessageDoc, otherUserId);
  //       if (kDebugMode) debugPrint("   -> Repository processing done for $lastMessageId.");
  //       processedSuccessfully = true;
  //     } catch (e, s) {
  //       if (kDebugMode) debugPrint("!!! [GlobalListenerService] Error calling repository for $lastMessageId: $e\n$s");
  //       // يمكنك إضافة آلية إعادة محاولة للمستودع هنا
  //     }
  //   }
  //   if (processedSuccessfully) {
  //     if (repository != null && lastTimestamp != null) {
  //       // هنا نحدّث "الطابع العام لآخر مزامنة ناجحة للمحادثة"
  //       // لأنه تم جلب *هذه الرسالة المحددة* (lastMessageId) ومعالجتها بنجاح.
  //       await repository.updateLastSyncTimestampForChat(otherUserId, lastTimestamp);
  //       if (kDebugMode) debugPrint("     -> GMLS: Updated REPOSITORY's last successful sync timestamp for '$otherUserId' to ${lastTimestamp.toDate()} because a specific message from summary was processed.");
  //     }
  //   }
  //
  //   if (lastTimestamp != null) {
  //     await _saveLastTimestamp(otherUserId, lastTimestamp); // هذا خاص بـ GMLS ليعرف آخر *ملخص* عالجه.
  //     if (kDebugMode) debugPrint("   -> Updated GMLS's own last processed SUMMARY timestamp for $otherUserId to ${lastTimestamp.toDate()}.");
  //   }
  //
  //
  //
  //   if (repository != null && fullMessageDoc != null && fullMessageDoc.exists) {
  //       try {
  //         if (kDebugMode) debugPrint("   -> GMLS calling repository.processAndStoreIncomingMessage for msg '$lastMessageId' (chat with '$otherUserId')...");
  //         // *** تمرير otherUserId هنا للـ repository ***
  //         await repository.processAndStoreIncomingMessage(fullMessageDoc, otherUserId); // otherUserId هو convSummaryDoc.id
  //         // ------------------------------------------
  //         if (kDebugMode) debugPrint("   -> GMLS: Repository processing presumably done for '$lastMessageId'.");
  //         processedSuccessfully = true;
  //
  //         // --- تحديث الطابع الزمني لآخر مزامنة ناجحة لهذه المحادثة ---
  //         // otherUserId هو convSummaryDoc.id, و lastTimestamp هو من ملخص المحادثة.
  //         if (lastTimestamp != null) { // تأكد أن الطابع غير فارغ
  //           await repository.updateLastSyncTimestampForChat(otherUserId, lastTimestamp);
  //           if (kDebugMode) debugPrint("     -> GMLS: Updated last successful sync timestamp for '$otherUserId' via repository.");
  //         }
  //         // -----------------------------------------------------------
  //
  //       } catch (e, s) {
  //         if (kDebugMode) debugPrint("!!! [GlobalListenerService _processConversationUpdate] Error calling repository for '$lastMessageId': $e\n$s");
  //         // يمكنك إضافة آلية إعادة محاولة هنا إذا فشل المستودع بشكل كامل
  //       }
  //     }
  //
  //   // --- 6. تحديث الطابع الزمني الأخير لهذه المحادثة ---
  //   // نقوم بالتحديث بغض النظر عما إذا كانت الرسالة الكاملة قد عولجت أم لا
  //   // لمنع محاولة المعالجة المتكررة لنفس تحديث الملخص.
  //   // لكن، يمكنك اختيار التحديث *فقط* عند نجاح processedSuccessfully إذا أردت
  //   // إعادة محاولة جلب الرسالة الكاملة لاحقًا إذا فشلت المرة الأولى.
  //   await _saveLastTimestamp(otherUserId, lastTimestamp);
  //   if (kDebugMode) debugPrint("   -> Updated last processed timestamp for $otherUserId to ${lastTimestamp.toDate()}.");
  //
  //
  //   // --- 7. إظهار الإشعار المحلي ---
  //   if (kDebugMode) debugPrint("   -> Showing local notification for $lastMessageId from $otherUserId...");
  //   await LocalNotification.showBasicNotification(
  //     id: otherUserId.hashCode + lastTimestamp.millisecondsSinceEpoch % 100000, // تركيب ID فريد أكثر
  //     title: senderNameToDisplay,
  //     body: _createNotificationBody(lastMessageType, previewText),
  //     payloadMap: { 'notificationType': 'chat_message',
  //       'senderId': lastSenderId,
  //       'recipientId': myUserId, // المستخدم الحالي هو المتلقي
  //       'chatPartnerId': otherUserId,
  //       'messageId': lastMessageId, // تمرير ID الرسالة قد يكون مفيدًا
  //     },
  //   );
  //
  //   if (kDebugMode) debugPrint("--- [GlobalListenerService] Finished processing update for $otherUserId ---");
  //
  //
  // } // نهاية _processConversationUpdate


// في GlobalMessageListenerService.dart

// ... (داخل class GlobalMessageListenerService) ...

  Future<void> _processConversationUpdate(DocumentSnapshot convSummaryDoc) async {
    final myUserId = _auth.currentUser?.uid;
    if (myUserId == null || myUserId.isEmpty) {
      // ... (معالجة المستخدم غير المسجل) ...
      return;
    }

    final data = convSummaryDoc.data() as Map<String, dynamic>? ?? {};
    final String otherUserId = convSummaryDoc.id;
    final String lastSenderId = data[FirestoreConstants.senderId] ?? '';
    final String lastMessageId = data[FirestoreConstants.messageId] ?? '';
    final Timestamp? summaryTimestamp = data[FirestoreConstants.timestamp] as Timestamp?; // <--- طابع الملخص

    if (kDebugMode) {
      debugPrint("-> [GMLS Processing $otherUserId] Summary update: Sender=$lastSenderId, MsgID=$lastMessageId, SummaryTS=${summaryTimestamp?.toDate()}");
    }

    // --- الخطوة 0: التحقق الأولي الأساسي ---
    if (lastSenderId == myUserId || lastMessageId.isEmpty || summaryTimestamp == null) {
      if (kDebugMode && lastSenderId == myUserId) debugPrint("   -> [GMLS] Skipping: Last message sent by me.");
      if (kDebugMode && (lastMessageId.isEmpty || summaryTimestamp == null)) debugPrint("   -> [GMLS] Skipping: Missing message ID or timestamp in summary.");
      return;
    }

    // --- الخطوة 1: التحقق من طابع GMLS الخاص (لمنع معالجة نفس تحديث الملخص مرارًا) ---
    final lastProcessedByGMLSForThisChat = _getLastTimestampFor(otherUserId); // هذا من _syncStorage الخاص بـ GMLS
    if (!summaryTimestamp.toDate().isAfter(lastProcessedByGMLSForThisChat.toDate())) {
      // if (kDebugMode) debugPrint("   -> [GMLS Skipping $otherUserId]: SummaryTS ${summaryTimestamp.toDate()} not newer than GMLS_processed_TS ${lastProcessedByGMLSForThisChat.toDate()}.");
      return;
    }
    // إذا وصلنا هنا، فهذا تحديث ملخص جديد لم يره GMLS من قبل.

    // --- [التحسين الجديد] الخطوة 2: التحقق من آخر مزامنة كاملة من MessageRepository ---
    MessageRepository? msgRepo;
    Timestamp? lastFullySyncedUpToTsFromRepo;
    try {
      msgRepo = Get.find<MessageRepository>();
      lastFullySyncedUpToTsFromRepo = await msgRepo.getPublicLastFullySyncedTimestamp(otherUserId);
      if (kDebugMode && lastFullySyncedUpToTsFromRepo != null) {
        debugPrint("    [GMLS $otherUserId] Last FULLY SYNCED timestamp from Repo: ${lastFullySyncedUpToTsFromRepo.toDate()}");
      } else if (kDebugMode) {
        debugPrint("    [GMLS $otherUserId] No FULLY SYNCED timestamp found in Repo.");
      }
    } catch (e) {
      if (kDebugMode) debugPrint("!!! [GMLS $otherUserId] Error finding MessageRepository or getting last fully synced ts: $e. Will proceed with full processing.");
      msgRepo = null; // للتأكد من عدم استخدامه إذا فشل البحث
    }

    if (lastFullySyncedUpToTsFromRepo != null && !summaryTimestamp.toDate().isAfter(lastFullySyncedUpToTsFromRepo.toDate())) {
      // طابع الملخص الحالي أقدم من أو يساوي آخر نقطة مزامنة كاملة مؤكدة.
      // هذا يعني أن "catch-up sync" قد غطى هذه النقطة بالفعل.
      // يمكننا تخطي المعالجة التفصيلية (جلب الرسالة الكاملة، إلخ).
      if (kDebugMode) {
        debugPrint("   -> [GMLS Skipping Detailed Processing for $otherUserId]: SummaryTS (${summaryTimestamp.toDate()}) is NOT AFTER last REPO full sync TS (${lastFullySyncedUpToTsFromRepo.toDate()}). Catch-up likely handled this.");
      }
      // **هام:** لا يزال يجب علينا تحديث طابع GMLS الخاص *لهذا الملخص*،
      // حتى لا نحاول فحصه مقابل الريبو مرة أخرى.
      await _saveLastTimestamp(otherUserId, summaryTimestamp);
      if (kDebugMode) debugPrint("     [GMLS $otherUserId] Updated GMLS's own last processed summary timestamp to ${summaryTimestamp.toDate()} (after repo check).");
      // لا نظهر إشعارًا هنا بالضرورة، لأن الـ catch-up يفترض أنه أظهر أي إشعارات ضرورية أو أن المستخدم يرى الشاشة.
      // أو، يمكنك اختيار إظهار إشعار إذا كان `processedSuccessfullyInRepo` من المحاولة السابقة لهذا الملخص كانت false.
      // هذا يعقد الأمور. الأبسط هو الافتراض أن الـ catch-up تعامل معه.
      return; // تخطي بقية المعالجة
    }
    // --- نهاية التحسين الجديد ---

    // إذا وصلنا إلى هنا، فهذا يعني أن طابع الملخص أحدث من أي مزامنة كاملة سابقة،
    // أو لم نتمكن من التحقق من الريبو. لذا، نبدأ المعالجة الكاملة.
    if (kDebugMode) debugPrint("   -> [GMLS Processing Detail for $otherUserId] SummaryTS ${summaryTimestamp.toDate()} is newer than Repo's full sync / or Repo check failed. (Msg ID: $lastMessageId)");


    // --- بقية الكود (جلب الاسم، جلب الرسالة الكاملة، معالجة المستودع، تحديث الطوابع، الإشعار) يبقى كما هو تقريبًا ---
    String senderNameToDisplay = await _fetchSenderName(lastSenderId, otherUserId); // دالة مساعدة مقترحة
    DocumentSnapshot? fullMessageDoc = await _fetchFullMessage(myUserId, lastSenderId, otherUserId, lastMessageId);

    bool processedSuccessfullyInRepo = false;
    if (msgRepo != null && fullMessageDoc != null && fullMessageDoc.exists) {
      try {
        await msgRepo.processAndStoreIncomingMessage(fullMessageDoc, otherUserId);
        processedSuccessfullyInRepo = true;
        if (kDebugMode) debugPrint("     [GMLS $otherUserId] Repo processing successful for $lastMessageId.");
        // هنا، msgRepo.processAndStoreIncomingMessage
        // و fetchMissingMessagesFromFirebase (عندما يعمل)
        // هما المسؤولان عن تحديث _setLastSuccessfulSyncTimestamp (الطابع العام للمزامنة الكاملة).
        // GMLS لا يحتاج لتحديثه مباشرة.
      } catch (e, s) {
        if (kDebugMode) debugPrint("!!! [GMLS $otherUserId] Error during msgRepo.processAndStoreIncomingMessage for $lastMessageId: $e\n$s");
      }
    }

    // تحديث طابع GMLS الخاص بمعالجة هذا الملخص *دائمًا* بعد محاولة المعالجة
    await _saveLastTimestamp(otherUserId, summaryTimestamp);
    if (kDebugMode) debugPrint("   [GMLS $otherUserId] Updated GMLS's own last processed summary timestamp to ${summaryTimestamp.toDate()}. Processed in repo: $processedSuccessfullyInRepo");

    // إظهار الإشعار (يمكن جعله مشروطًا بـ processedSuccessfullyInRepo إذا أردت)
    if (fullMessageDoc != null && fullMessageDoc.exists && processedSuccessfullyInRepo) { // أظهر فقط إذا تمت المعالجة بنجاح لتجنب إشعارات مكررة إذا فشل الريبو وحاول GMLS مرة أخرى
      if (kDebugMode) debugPrint("   -> [GMLS $otherUserId] Showing local notification for $lastMessageId from $senderNameToDisplay...");
      // await LocalNotification.showBasicNotification(
      //       id: otherUserId.hashCode + lastTimestamp.millisecondsSinceEpoch % 100000, // تركيب ID فريد أكثر
      //       title: senderNameToDisplay,
      //       body: _createNotificationBody(lastMessageType, previewText),
      //       payloadMap: { 'notificationType': 'chat_message',
      //         'senderId': lastSenderId,
      //         'recipientId': myUserId, // المستخدم الحالي هو المتلقي
      //         'chatPartnerId': otherUserId,
      //         'messageId': lastMessageId, // تمرير ID الرسالة قد يكون مفيدًا
      //       },
      //     );
    } else if (fullMessageDoc == null || !fullMessageDoc.exists) {
      // إذا فشلنا في جلب الرسالة الكاملة، ولكن الملخص جديد، قد نظهر إشعارًا عامًا
      if (kDebugMode) debugPrint("   -> [GMLS $otherUserId] Could not fetch full message for $lastMessageId. Notification based on summary.");
      // await LocalNotification.showBasicNotification(... using previewText ...); // اختياري
    }


    if (kDebugMode) debugPrint("--- [GMLS $otherUserId] Finished processing update for summaryTS ${summaryTimestamp.toDate()} ---");
  }

// دالة مساعدة مقترحة لجلب الاسم لتقليل التكرار
  Future<String> _fetchSenderName(String lastSenderId, String otherUserIdAsFallback) async {
    if (lastSenderId.isEmpty) return otherUserIdAsFallback;
    try {
      final userDoc = await _firestore.collection(FirebaseX.collectionApp).doc(lastSenderId).get();
      if (userDoc.exists) {
        return userDoc.data()?['name'] as String? ?? lastSenderId;
      }
      return lastSenderId;
    } catch (e) {
      if (kDebugMode) debugPrint("!!! Error fetching sender name ($lastSenderId) in GMLS: $e");
      return lastSenderId;
    }
  }

// دالة مساعدة مقترحة لجلب الرسالة الكاملة لتقليل التكرار
  Future<DocumentSnapshot?> _fetchFullMessage(String myUserId, String lastSenderId, String otherUserId, String lastMessageId) async {
    if (lastSenderId.isEmpty || lastMessageId.isEmpty) return null; // يجب أن يكون Sender ID صالحًا (ليس myUserId هنا)

    // لا يمكن جلب الرسالة من صندوق صادر المرسل إذا كان هو المستخدم الحالي
    if (lastSenderId == myUserId) {
      if (kDebugMode) debugPrint("     [GMLS _fetchFullMessage] Attempting to fetch 'my own' message ($lastMessageId) from my inbox with $otherUserId.");
      // المسار الصحيح لرسالة أرسلتها أنا للطرف الآخر otherUserId، ولكن هذا لا يجب أن يحدث عادةً
      // لأن GMLS يجب أن يتجاهل lastSenderId == myUserId.
      // مع ذلك، إذا وصل هنا، فهذا هو المسار:
      try {
        return await _firestore
            .collection(FirestoreConstants.chatCollection).doc(myUserId)
            .collection(FirestoreConstants.chatSubCollection).doc(otherUserId) // المستلم
            .collection(FirestoreConstants.messagesSubCollection).doc(lastMessageId)
            .get();
      } catch (e) {
        if (kDebugMode) debugPrint("!!! Error fetching supposedly 'my message' in _fetchFullMessage: $e");
        return null;
      }
    }


    DocumentSnapshot? messageDoc;
    // المحاولة الأولى: صندوق الوارد الخاص بي (الرسالة من otherUserId إلي)
    // otherUserId هنا هو convSummaryDoc.id وهو مُرسِل الرسالة بالنسبة لي.
    // lastSenderId في الملخص يجب أن يكون هو otherUserId (مُرسِل الرسالة)
    if (kDebugMode) debugPrint("     [GMLS _fetchFullMessage] Attempting to fetch msg $lastMessageId from MY inbox (path: Chat/$myUserId/chat/$lastSenderId/messages/$lastMessageId)... (Sender in summary: $lastSenderId)");
    try {
      messageDoc = await _firestore
          .collection(FirestoreConstants.chatCollection).doc(myUserId)
          .collection(FirestoreConstants.chatSubCollection).doc(lastSenderId) // هذا هو مُرسِل الرسالة الفعلية (الطرف الآخر)
          .collection(FirestoreConstants.messagesSubCollection).doc(lastMessageId)
          .get();

      if (!messageDoc.exists) {
        if (kDebugMode) debugPrint("       [GMLS _fetchFullMessage] Not in MY inbox. Trying SENDER'S ($lastSenderId) outbox for msg to ME ($myUserId)...");
        messageDoc = await _firestore
            .collection(FirestoreConstants.chatCollection).doc(lastSenderId) // صندوق مُرسِل الرسالة
            .collection(FirestoreConstants.chatSubCollection).doc(myUserId)  // إلى صندوقي (كمستلم)
            .collection(FirestoreConstants.messagesSubCollection).doc(lastMessageId)
            .get();
        if (!messageDoc.exists && kDebugMode) debugPrint("       [GMLS _fetchFullMessage] Not in sender's outbox either!");
      }
      if (messageDoc.exists && kDebugMode) debugPrint("       [GMLS _fetchFullMessage] Successfully fetched. Has data: ${messageDoc.data() != null}");
      return messageDoc;

    } catch (e) {
      if (kDebugMode) debugPrint("!!! [GMLS _fetchFullMessage] Error fetching $lastMessageId: $e");
      return null;
    }
  }
  /// إنشاء نص الإشعار بناءً على نوع الرسالة.
  String _createNotificationBody(String messageType, String previewText) {
    switch (messageType) {
      case FirestoreConstants.typeText: return previewText;
      case FirestoreConstants.typeImage: return '📷 أرسل صورة';
      case FirestoreConstants.typeVideo: return '📹 أرسل فيديو';
      case FirestoreConstants.typeAudio: return '🎤 أرسل رسالة صوتية';
      default: return 'رسالة جديدة';
    }
  }


} // نهاية كلاس GlobalMessageListenerService