import 'dart:async';
import 'dart:io'; // لـ File
import 'package:cloud_firestore/cloud_firestore.dart'; // لـ Timestamp (إذا كنت ستستخدمه هنا)
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // لـ kDebugMode
import 'package:get/get.dart'; // للوصول للخدمات عبر Get.find
import 'package:get_storage/get_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart'; // لإنشاء messageId
import 'package:path/path.dart' as p; // تأكد من وجود الاستيراد
import 'package:html/parser.dart' show parse;  // <--- الاستيراد لتحليل HTML

import 'ChatService.dart';
import 'FirestoreConstants.dart';
import 'LocalDatabaseService2GetxService.dart';
import 'Message.dart';
import 'MessageStatus.dart';
import 'package:http/http.dart' as http; // <--- قم بإضافة هذا السطر



class UploadResult {
  final bool success;
  final String? contentUrl;
  final String? thumbnailUrl;

  UploadResult({required this.success, this.contentUrl, this.thumbnailUrl});
}
enum DownloadType { mainFile, thumbnail }

// --- استيراد الخدمات والنماذ
class MessageRepository extends GetxService {
  // الحصول على مثيلات الخدمات التي تم تسجيلها مسبقًا باستخدام GetX
  final LocalDatabaseService _localDbService = Get.find<LocalDatabaseService>();
  final ChatService _firebaseService = Get.find<ChatService>();
  final Uuid _uuid = const Uuid(); // لإنشاء IDs فريدة
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // يمكنك الوصول لـ Firestore مباشرة هنا مؤقتًا
  String _currentUserName = "";
  final RxList<Map<String, dynamic>> _downloadQueue = <Map<String, dynamic>>[].obs;
  bool _isDownloadProcessorRunning = false; // علامة لمنع تشغيل المعالج أكثر من مرة
  late final String currentUserId; // تم تهيئته في onInit
  final GetStorage _storage = GetStorage(); // للوصول لصندوق التخزين
  final String _downloadQueueStorageKey = 'download_queue'; // مفتاح الحفظ
  final GetStorage _syncStorage = GetStorage('SyncTimestampsBox'); // صندوق تخزين مخصص
  final String _lastSyncPrefix = 'last_sync_ts_'; // بادئة لمفاتيح التخزين
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription; // <--- التغيير الرئيسي هنا

  // معرف المستخدم الحالي (يُفضل تمريره أو الحصول عليه من خدمة مصادقة)
  // افترض وجود خدمة مصادقة مسجلة في GetX
  // final AuthService _authService = Get.find<AuthService>();
  // String get currentUserId => _authService.currentUserId;
  // --- بديل مؤقت إذا لم تكن خدمة المصادقة موجودة ---

  // --- نهاية البديل المؤقت ---

  // MessageRepository() : currentUserId = _getCurrentUserIdFromAuth(), // التهيئة أولاً بالـ ID
  //       _currentUserName = "" // تهيئة أولية للاسم
  // {
  //   if (kDebugMode) debugPrint("[MessageRepository] Initializing with User ID: $currentUserId");
  //   if (currentUserId.isEmpty) {
  //     throw StateError("FATAL: Could not get current user ID for MessageRepository.");
  //   }
  //   // *** جلب الاسم بشكل غير متزامن هنا أو افترض أنه موجود في خدمة أخرى ***
  //   // هذا مثال بسيط جدًا يفترض جلب سريع - قد تحتاج لمنطق أفضل
  //   _fetchCurrentUserName(); // <--- استدعاء دالة لجلب الاسم
  // }




  @override
  void onInit() {
    super.onInit();
    if (kDebugMode) debugPrint("[MessageRepository] onInit - Initializing...");
    currentUserId = _getCurrentUserIdFromAuth(); // تهيئة ID المستخدم
    if (currentUserId.isEmpty) {
      throw StateError("FATAL: MessageRepository User ID is empty onInit.");
    }
    _fetchCurrentUserName(); // بدء جلب الاسم

    // --- **[جديد]** استعادة قائمة الانتظار وبدء المعالجة ---
    _restoreAndProcessDownloadQueue();
    _listenToConnectivityChanges();

    // -------------------------------------------------
    if (kDebugMode) debugPrint("[MessageRepository] Initialization complete.");
  }



  @override
  void onClose() {
    // ... (الكود الموجود للتخلص من downloadQueue وما إلى ذلك) ...
    _connectivitySubscription?.cancel(); // <--- إلغاء اشتراك الاتصال
    if (kDebugMode) debugPrint("[MessageRepository] Closed and connectivity listener cancelled.");
    super.onClose();
  }



  // --- [جديد] دالة تعديل الرسالة ---
  Future<void> editMessage({
    required String messageId,
    required String newContent,
    required String recipientId, // نحتاجه لتحديث صندوق المرسل والمستقبل
  }) async {
    if (kDebugMode) debugPrint("  [MsgRepo] Editing message $messageId. New content: '$newContent'");
    final String myId = currentUserId; // ID المرسل (الذي يقوم بالتعديل)
    final Timestamp editTimestamp = Timestamp.now(); // طابع التعديل

    // 1. تحديث الرسالة محليًا لدى المرسل
    // أضف حقل isEdited إذا لم يكن موجودًا
    bool localUpdateSuccess = await _localDbService.updateMessageFields(messageId, {
      FirestoreConstants.messageContent: newContent,
      'isEdited': 1, // أو true إذا كان نوع الحقل boolean في SQLite
      // قد ترغب في تحديث الطابع الزمني المحلي أيضًا، أو الاحتفاظ بالأصلي وإضافة طابع تعديل
      // FirestoreConstants.timestamp: editTimestamp.millisecondsSinceEpoch,
    });

    if (!localUpdateSuccess) {
      if (kDebugMode) debugPrint("  !!! [MsgRepo] Failed to update message $messageId locally for edit. Firestore update will be skipped.");
      throw Exception("فشل تحديث الرسالة محليًا.");
    }

    // 2. تحديث الرسالة في Firestore (لكلا الطرفين)
    WriteBatch batch = _firestore.batch();

    // أ. نسخة المرسل (صندوقه الصادر)
    DocumentReference senderMsgRef = _firebaseService.messagesCollection(myId, recipientId).doc(messageId);
    batch.update(senderMsgRef, {
      FirestoreConstants.messageContent: newContent,
      'isEdited': true,
      'editedAt': editTimestamp, // <--- طابع زمني للتعديل (اختياري لكن جيد)
      // FirestoreConstants.timestamp: editTimestamp, // هل نحدث الطابع الأصلي؟ يفضل لا للحفاظ على الترتيب الأصلي
    });

    // ب. نسخة المستلم (صندوقه الوارد)
    DocumentReference recipientMsgRef = _firebaseService.messagesCollection(recipientId, myId).doc(messageId);
    batch.update(recipientMsgRef, {
      FirestoreConstants.messageContent: newContent,
      'isEdited': true,
      'editedAt': editTimestamp,
    });

    try {
      await batch.commit();
      if (kDebugMode) debugPrint("  [MsgRepo] Message $messageId EDITED successfully in Firestore for both parties.");

      // 3. (اختياري) تحديث ملخص آخر رسالة إذا كانت هذه هي آخر رسالة
      // هذا الجزء يحتاج إلى التحقق إذا كانت الرسالة المعدلة هي آخر رسالة في الملخص.
      // إذا كان النص الجديد يؤثر على `summaryText`.
      // يمكن استدعاء دالة مشابهة لـ `_commitMessageToFirebase` لتحديث الملخصات
      // مع التأكد من تمرير البيانات الصحيحة.
      // مثال:
      await _updateLastMessageSummaryAfterEditOrDelete(
          myId,                         // 1. actionInitiatorId (من قام بالتعديل، وهو أنا)
          recipientId,                  // 2. chatPartnerId (الطرف الآخر)
          messageId,                    // 3. relevantMessageId (ID الرسالة التي تم تعديلها)
          newContent,                   // 4. newSummaryContent (محتوى النص الجديد للملخص)
          FirestoreConstants.typeText,  // 5. newSummaryType (نوع الملخص هو نص لأننا نعدل رسالة نصية)
          editTimestamp,                // 6. actionTimestamp (وقت التعديل)
          currentUserName,              // 7. actionInitiatorName (اسمي أنا)
          true                          // 8. wasOriginalSenderMe (نعم، أنا مرسل الرسالة الأصلية التي أقوم بتعديلها)
      );

    } catch (e) {
      if (kDebugMode) debugPrint("  !!! [MsgRepo] Failed to edit message $messageId in Firestore: $e");
      // إعادة الحالة المحلية إلى ما كانت عليه قبل محاولة التعديل؟ (أكثر تعقيدًا)
      // أو تركها محدثة محليًا وإظهار خطأ في الإرسال؟
      // حاليًا، إذا فشل تحديث Firestore، ستظل الرسالة محدثة محليًا فقط لدى المرسل.
      throw Exception("فشل تحديث الرسالة في الخادم.");
    }
  }

// MessageRepository.dart
  Future<void> checkAndUpdateOverallUnreadStatusForCurrentUser() async {
    final String myId = currentUserId;
    if (myId.isEmpty) {
      if (kDebugMode) debugPrint("[MsgRepo _checkUnread] myId is empty. ABORTING.");
      return;
    }
    if (kDebugMode) debugPrint("==>> [MsgRepo _checkUnread $myId] Initiating overall unread status check for User Document. <<==");

    QuerySnapshot<Map<String, dynamic>> unreadSummariesSnapshot;
    try {
      final query = _firestore
          .collection(FirestoreConstants.chatCollection).doc(myId)
          .collection(FirestoreConstants.chatSubCollection)
          .where(FirestoreConstants.isRead, isEqualTo: false)
          .where(FirestoreConstants.senderId, isNotEqualTo: myId)
          .limit(5); // زد الـ limit مؤقتًا لترى أكثر من نتيجة إذا وجدت

      if (kDebugMode) {
        debugPrint("    [MsgRepo _checkUnread $myId] Executing query for unread summaries from OTHERS:");
        debugPrint("        Collection: ${FirestoreConstants.chatCollection}/$myId/${FirestoreConstants.chatSubCollection}");
        debugPrint("        Where: ${FirestoreConstants.isRead} == false");
        debugPrint("        AND: ${FirestoreConstants.senderId} != $myId");
      }

      unreadSummariesSnapshot = await query.get(const GetOptions(source: Source.server));

    } catch (e, s) {
      if (kDebugMode) {
        debugPrint("  ❌❌❌ [MsgRepo _checkUnread $myId] Firestore QUERY FAILED for unread summaries!");
        debugPrint("        Query Error: $e");
        debugPrint("        Query StackTrace: $s");
      }
      // لا تتابع إذا فشل الاستعلام
      return;
    }

    DocumentReference myUserDocRef = _firestore
        .collection(FirestoreConstants.userCollection).doc(myId);

    final bool noUnreadChatsFromOthersFound = unreadSummariesSnapshot.docs.isEmpty;

    if (kDebugMode) {
      debugPrint("    [MsgRepo _checkUnread $myId] Unread summaries query (from others) returned ${unreadSummariesSnapshot.docs.length} documents.");
      if (!noUnreadChatsFromOthersFound) {
        debugPrint("      🚨 [MsgRepo _checkUnread $myId] Found a_test_target_unread chat summaries FROM OTHERS. 'hasUnreadMessages' will be set to TRUE.");
        for (var i = 0; i < unreadSummariesSnapshot.docs.length; i++) {
          var doc = unreadSummariesSnapshot.docs[i];
          debugPrint("        [${i+1}] Unread Summary ID (otherUserId): ${doc.id}");
          debugPrint("            Data: ${doc.data()}");
          // اطبع الحقول المهمة
          debugPrint("            isRead: ${doc.data()[FirestoreConstants.isRead]}");
          debugPrint("            senderId (in summary): ${doc.data()[FirestoreConstants.senderId]}");
          debugPrint("            content (in summary): ${doc.data()[FirestoreConstants.messageContent]}");
        }
      } else {
        debugPrint("    [MsgRepo _checkUnread $myId] NO unread chat summaries from others found. 'hasUnreadMessages' should be set to FALSE.");
      }
    }

    final bool newHasUnreadValueTarget = !noUnreadChatsFromOthersFound; // إذا لم تكن فارغة -> true, إذا فارغة -> false

    try {
      // قراءة القيمة الحالية من Firestore (اختياري لكن جيد للتأكد)
      final userDocSnap = await myUserDocRef.get(const GetOptions(source: Source.server));
      bool currentFirestoreHasUnreadValue = false; // افتراضي
      if (userDocSnap.exists && userDocSnap.data() != null) {
        currentFirestoreHasUnreadValue = (userDocSnap.data() as Map<String, dynamic>)['hasUnreadMessages'] ?? false;
      }
      if (kDebugMode) debugPrint("    [MsgRepo _checkUnread $myId] Current 'hasUnreadMessages' in Firestore: $currentFirestoreHasUnreadValue. Target value: $newHasUnreadValueTarget");


      if (currentFirestoreHasUnreadValue != newHasUnreadValueTarget || !userDocSnap.exists) { // أو إذا لم تكن الوثيقة موجودة، أنشئ الحقل
        await myUserDocRef.set({'hasUnreadMessages': newHasUnreadValueTarget}, SetOptions(merge: true));
        if (kDebugMode) debugPrint("  ✅ [MsgRepo _checkUnread $myId] 'hasUnreadMessages' in Usercodora/$myId SET/UPDATED to: $newHasUnreadValueTarget.");
      } else {
        if (kDebugMode) debugPrint("  [MsgRepo _checkUnread $myId] 'hasUnreadMessages' in Usercodora/$myId is already $newHasUnreadValueTarget. No Firestore write needed for user doc.");
      }
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint("  ❌❌❌ [MsgRepo _checkUnread $myId] Error SETTING/UPDATING 'hasUnreadMessages' on Usercodora/$myId!");
        debugPrint("        Update Error: $e");
        debugPrint("        Update StackTrace: $s");
      }
    }
    if (kDebugMode) debugPrint("<== [MsgRepo _checkUnread $myId] Finished overall unread status check. Final target value for hasUnreadMessages: $newHasUnreadValueTarget ==>");
  }

  Future<void> _updateLastMessageSummaryAfterEditOrDelete(
      String actionInitiatorId, // من قام بالتعديل/الحذف
      String chatPartnerId,    // الطرف الآخر في المحادثة
      String relevantMessageId, // ID الرسالة التي تم تعديلها/حذفها
      String newSummaryContent,
      String newSummaryType,
      Timestamp actionTimestamp,
      String actionInitiatorName,
      bool wasOriginalSenderMe, // هل كنت أنا مرسل الرسالة الأصلية التي تم تعديلها/حذفها
      ) async {

    // الهدف: تحديث ملخص المحادثة فقط إذا كانت الرسالة المعدلة/المحذوفة هي *نفسها* آخر رسالة في الملخص.
    // جلب ملخص المحادثة الحالي لكلا الطرفين
    final myChatSummaryRef = _firebaseService.userChatRef(actionInitiatorId, chatPartnerId);
    final partnerChatSummaryRef = _firebaseService.userChatRef(chatPartnerId, actionInitiatorId);

    try {
      DocumentSnapshot mySummarySnap = await myChatSummaryRef.get();
      DocumentSnapshot partnerSummarySnap = await partnerChatSummaryRef.get();

      WriteBatch summaryBatch = _firestore.batch();
      bool updateMySummary = false;
      bool updatePartnerSummary = false;

      // تحديث ملخصي إذا كانت الرسالة ذات الصلة هي آخر رسالة فيه
      if (mySummarySnap.exists && mySummarySnap.data() != null) {
        final mySummaryData = mySummarySnap.data() as Map<String, dynamic>;
        if (mySummaryData[FirestoreConstants.messageId] == relevantMessageId) {
          summaryBatch.update(myChatSummaryRef, {
            FirestoreConstants.messageContent: newSummaryContent,
            FirestoreConstants.messageType: newSummaryType,
            FirestoreConstants.timestamp: actionTimestamp, // استخدم طابع التعديل/الحذف
            FirestoreConstants.senderId: actionInitiatorId, // الشخص الذي أجرى التعديل/الحذف هو "مرسل" هذا التحديث
            'senderName': actionInitiatorName,
            // FirestoreConstants.isRead يبقى كما هو في ملخصي (عادة true)
          });
          updateMySummary = true;
        }
      }

      // تحديث ملخص الطرف الآخر إذا كانت الرسالة ذات الصلة هي آخر رسالة فيه
      if (partnerSummarySnap.exists && partnerSummarySnap.data() != null) {
        final partnerSummaryData = partnerSummarySnap.data() as Map<String, dynamic>;
        if (partnerSummaryData[FirestoreConstants.messageId] == relevantMessageId) {
          summaryBatch.update(partnerChatSummaryRef, {
            FirestoreConstants.messageContent: newSummaryContent,
            FirestoreConstants.messageType: newSummaryType,
            FirestoreConstants.timestamp: actionTimestamp,
            FirestoreConstants.senderId: actionInitiatorId, // نفس الشيء
            'senderName': actionInitiatorName,
            FirestoreConstants.isRead: false, // يجب أن يصبح الملخص "غير مقروء" للطرف الآخر لأنه تحديث جديد
          });
          updatePartnerSummary = true;
        }
      }

      if (updateMySummary || updatePartnerSummary) {
        await summaryBatch.commit();
        if (kDebugMode) debugPrint("  [MsgRepo] Last message summaries updated after edit/delete. MySummary: $updateMySummary, PartnerSummary: $updatePartnerSummary");
      }

    } catch (e) {
      if (kDebugMode) debugPrint("  !!! [MsgRepo] Error updating last message summary after edit/delete: $e");
    }
  }


// ... (بقية المستودع)


  // --- [جديد] دالة حذف الرسالة محليًا فقط ---
  Future<void> deleteMessageLocally(String messageId, String myId, String otherUserId) async {
    if (kDebugMode) debugPrint("  [MsgRepo] Deleting message $messageId locally for user $myId in chat with $otherUserId.");
    try {
      // بدلًا من الحذف الفعلي من SQLite، قد تفضل "تمييزها كمحذوفة محليًا"
      // أو إذا كنت متأكدًا، قم بالحذف:
      // bool deleted = await _localDbService.deleteMessage(messageId);
      // هذا يتطلب إضافة `deleteMessage` في `LocalDatabaseService`.
      // مثال لتمييزها كمحذوفة (أكثر أمانًا لتجنب فقدان البيانات نهائيًا بالخطأ):
      await _localDbService.updateMessageFields(messageId, {'status': 'deleted_locally'.toUpperCase()}); // حالة جديدة؟
      // أو ببساطة، الـ ChatController يتوقف عن عرضها إذا لم تعد في قائمة Stream
      // أو يمكنك أن تجعلها لا تُجلب من `_fetchAndEmitMessages`.

      // الطريقة الأسهل والأكثر مباشرة هي أن يقوم Controller بحذفها من قائمته المعروضة
      // أو أن يتم تصفية الـ stream.
      // إذا أردت حذفها من SQLite بالفعل:
      await _localDbService.deleteMessage(messageId); // <-- إضافة هذه الدالة لـ LocalDatabaseService
      _localDbService.notifyMessageStreamListeners(myId, otherUserId, ); // أخبر الواجهة بالتحديث

      if (kDebugMode) debugPrint("  [MsgRepo] Message $messageId DELETED locally from SQLite.");
    } catch (e) {
      if (kDebugMode) debugPrint("  !!! [MsgRepo] Error deleting message $messageId locally: $e");
      throw Exception("فشل حذف الرسالة محليًا.");
    }
  }

  // --- [جديد] دالة حذف الرسالة لدى الجميع ---
  Future<void> deleteMessageForEveryone({
    required Message message, // الرسالة الأصلية لمعرفة نوعها ومحتواها السابق
    required String recipientId,
    required String currentUserName, // اسم المستخدم الذي قام بالحذف (لتحديث الملخص)
  }) async {
    final String messageId = message.messageId;
    final String myId = currentUserId;
    final Timestamp deleteTimestamp = Timestamp.now();

    if (kDebugMode) debugPrint("  [MsgRepo] Deleting message $messageId for EVERYONE in chat between $myId and $recipientId.");

    // 1. تحديث الرسالة في Firestore (لكلا الطرفين) لتصبح "محذوفة"
    WriteBatch batch = _firestore.batch();
    final Map<String, dynamic> deletedMessageData = {
      FirestoreConstants.messageContent: FirestoreConstants.deletedMessageContent,
      FirestoreConstants.messageType: FirestoreConstants.typeDeleted, // تغيير النوع
      FirestoreConstants.timestamp: message.timestamp.millisecondsSinceEpoch, // الحفاظ على الطابع الأصلي للترتيب
      'deletedBy': myId, // من قام بالحذف
      'deletedAt': deleteTimestamp, // وقت الحذف
      // الحقول الأصلية الأخرى مثل senderId, recipientId تبقى كما هي
      FirestoreConstants.senderId: message.senderId,
      FirestoreConstants.recipientId: message.recipientId,
      // مسح أي بيانات وسائط أو ردود قد تكون مرتبطة بها
      FirestoreConstants.thumbnailUrl: null,
      'quotedMessageId': null,
      'quotedMessageText': null,
      'quotedMessageSenderId': null,
      'isEdited': false, // لم تعد مُعدلة، بل محذوفة
      FirestoreConstants.isRead: message.status == MessageStatus.read || message.status == MessageStatus.delivered, // إذا كانت مقروءة/مسلمة، تبقى isRead true ليعرف المرسل
    };


    // أ. نسخة المرسل (صندوقه الصادر)
    DocumentReference senderMsgRef = _firebaseService.messagesCollection(myId, recipientId).doc(messageId);
    batch.set(senderMsgRef, deletedMessageData, SetOptions(merge: false)); // Set بدلاً من Update لتغيير النوع والكتابة فوقها

    // ب. نسخة المستلم (صندوقه الوارد)
    DocumentReference recipientMsgRef = _firebaseService.messagesCollection(recipientId, myId).doc(messageId);
    batch.set(recipientMsgRef, deletedMessageData, SetOptions(merge: false));

    try {
      await batch.commit();
      if (kDebugMode) debugPrint("  [MsgRepo] Message $messageId marked as DELETED in Firestore for both parties.");

      // 2. تحديث الرسالة محليًا لدى المرسل (أنت) لتصبح محذوفة
      // يمكنك اختيار حذفها بالكامل من SQLite أو تحديث محتواها ونوعها.
      // تحديثها أفضل لكي تظهر "تم حذف هذه الرسالة"
      await _localDbService.updateMessageFields(messageId, {
        FirestoreConstants.messageContent: FirestoreConstants.deletedMessageContent,
        FirestoreConstants.messageType: FirestoreConstants.typeDeleted,
        'status': MessageStatus.sent.name, // يمكن اعتبارها كمرسلة (لأن الحذف عملية إرسال)
        //  FirestoreConstants.timestamp: message.timestamp.millisecondsSinceEpoch, // يجب ألا نغير الطابع الزمني
      });
      // لا تحتاج لإخبار _localDbService بالتحديث لأن هذا سيحدث عند استلام التحديث من GMLS/listener

      // 3. تحديث ملخص آخر رسالة إذا كانت هذه هي آخر رسالة
      // ويجب أن يعكس الملخص الآن "🚫 تم حذف هذه الرسالة"
      await _updateLastMessageSummaryAfterEditOrDelete(
          myId,
          recipientId,
          messageId,
          FirestoreConstants.deletedMessageContent, // محتوى الملخص الجديد
          FirestoreConstants.typeDeleted,         // نوع الملخص الجديد
          deleteTimestamp, // طابع الحذف
          currentUserName, // اسم المستخدم الذي حذف
          message.senderId == myId // هل كنت أنا مرسل الرسالة الأصلية (لتحديد isRead للملخص)
      );


    } catch (e) {
      if (kDebugMode) debugPrint("  !!! [MsgRepo] Failed to delete message $messageId for everyone in Firestore: $e");
      throw Exception("فشل حذف الرسالة لدى الجميع في الخادم.");
    }
  }






// -- [إضافة جديدة] دوال مساعدة لطوابع المزامنة --
  Future<void> _setLastSuccessfulSyncTimestamp(String chatPartnerId, Timestamp timestamp) async {
    try {
      await _syncStorage.write(_lastSyncPrefix + chatPartnerId, timestamp.millisecondsSinceEpoch);
      if (kDebugMode) debugPrint("  [Sync] Updated last successful sync for '$chatPartnerId' to ${timestamp.toDate()}");
    } catch (e) {
      if (kDebugMode) debugPrint("!!! [Sync] Error writing sync timestamp for '$chatPartnerId': $e");
    }
  }
  Future<Timestamp?> getPublicLastFullySyncedTimestamp(String chatPartnerId) async {
    // تستدعي ببساطة الدالة الخاصة الموجودة
    return await _getLastSuccessfulSyncTimestamp(chatPartnerId);
  }

  Future<Timestamp?> _getLastSuccessfulSyncTimestamp(String chatPartnerId) async {
    try {
      final millis = _syncStorage.read<int?>(_lastSyncPrefix + chatPartnerId);
      final millisValue = millis;
      if (millisValue != null) {
        return Timestamp(millisValue ~/ 1000, (millisValue % 1000) * 1000000);
      }
    } catch (e) {
      if (kDebugMode) debugPrint("!!! [Sync] Error reading sync timestamp for '$chatPartnerId': $e");
    }
    return null;
  }
// ----------------------------------------------------

// -- [إضافة جديدة] دالة للاستماع لتغيرات الاتصال --
  // داخل MessageRepository.dart

  void _listenToConnectivityChanges() {
    // إذا كنت تريد التأكد من إلغاء أي اشتراك سابق، يمكنك فعل ذلك هنا
    // _connectivitySubscription?.cancel();

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.isEmpty) {
        return;
      }
      final ConnectivityResult currentResult = results.last; // استخدم آخر حالة اتصال

      if (kDebugMode) debugPrint("[ConnectivityListener MR] Status changed to: $currentResult (List had ${results.length} items)");

      if (currentResult != ConnectivityResult.none) {
        if (kDebugMode) debugPrint("  [ConnectivityListener MR] Connection detected. ChatControllers should handle sync if needed.");
        // لا حاجة لمحاولة مزامنة عامة من هنا إذا كان ChatController سيتولى الأمر
      } else {
        if (kDebugMode) debugPrint("  [ConnectivityListener MR] Connection LOST.");
        // يمكنك اتخاذ إجراءات أخرى عند فقدان الاتصال إذا أردت
      }
    }, onError: (error) { // من الجيد دائمًا إضافة معالجة للخطأ في التيارات
      if (kDebugMode) debugPrint("!!! [ConnectivityListener MR] Error in connectivity stream: $error");
    });

    if (kDebugMode) debugPrint("[MessageRepository] Connectivity listener attached.");
  }







  /// تُستدعى من GlobalListener لتحديث طابع المزامنة بعد معالجة رسالة.
  Future<void> updateLastSyncTimestampForChat(String chatPartnerId, Timestamp timestamp) async {
    await _setLastSuccessfulSyncTimestamp(chatPartnerId, timestamp);
  }







  Future<void> processMessageUpdateFromFirestore(DocumentSnapshot messageDoc) async { // <--- جعلناها عامة
    final messageId = messageDoc.id;
    final data = messageDoc.data() as Map<String, dynamic>?;

    if (data == null) {
      if (kDebugMode) debugPrint("  [MsgRepo ProcessUpdateFS] Data is null for $messageId. Skipping.");
      return;
    }

    final String senderOfThisMessageInDoc = data[FirestoreConstants.senderId] ?? '';
    if (senderOfThisMessageInDoc != currentUserId) {
      if (kDebugMode) debugPrint("  [MsgRepo ProcessUpdateFS] Msg $messageId (sender $senderOfThisMessageInDoc) not sent by current user ($currentUserId). Skipping read receipt update by sender.");
      return;
    }

    final Message? localMessage = await _localDbService.getMessageById(messageId, currentUserId);
    if (localMessage == null) {
      if (kDebugMode) debugPrint("  [MsgRepo ProcessUpdateFS] Local message $messageId not found by sender for status update.");
      return;
    }

    final bool? firestoreIsRead = data[FirestoreConstants.isRead] as bool?;
    // مهم: تحقق أن الحالة المحلية ليست مقروءة بالفعل لتجنب تحديثات غير ضرورية لقاعدة البيانات وإعادة بناء الواجهة.
    if (firestoreIsRead == true && localMessage.status != MessageStatus.read) {
      if (kDebugMode) debugPrint("  [MsgRepo ProcessUpdateFS] Sender ($currentUserId) received confirmation that message $messageId is NOW READ. Updating local status.");
      // التحديث إلى status: MessageStatus.read.name
      await _localDbService.updateMessageFields(messageId, {'status': MessageStatus.read.name});
    } else if (firestoreIsRead == true && localMessage.status == MessageStatus.read) {
      if (kDebugMode) debugPrint("  [MsgRepo ProcessUpdateFS] Msg $messageId already marked as read locally by sender. No DB update needed.");
    }
  }

// في MessageRepository.dart
// في MessageRepository.dart
  Future<void> triggerCatchUpSyncIfNeeded(String otherUserId, {bool forceSync = false}) async {
    if (kDebugMode) debugPrint("  [SyncTrigger V6] Checking for '$otherUserId'. Forced: $forceSync. User: $currentUserId");

    final connectivityResults = await Connectivity().checkConnectivity();
    final currentConnectivity = connectivityResults.isNotEmpty ? connectivityResults.first : ConnectivityResult.none;
    if (currentConnectivity == ConnectivityResult.none && !forceSync) {
      if (kDebugMode) debugPrint("  [SyncTrigger V3] No connection. Skipping for '$otherUserId'.");
      return;
    }

    // الطابع الزمني لأقدم رسالة موجودة محليًا (أو بداية التاريخ إذا لا يوجد)
    final Timestamp? latestLocalTs = await _localDbService.getLatestLocalMessageTimestamp(currentUserId, otherUserId);
    final Timestamp? lastFullySyncedUpToTs = await _getLastSuccessfulSyncTimestamp(otherUserId);


    if (kDebugMode) {
      if(lastFullySyncedUpToTs != null) {
        debugPrint("    [SyncTrigger V3] Earliest LOCAL for '$otherUserId' is ${lastFullySyncedUpToTs.toDate()}");
      } else {
        debugPrint("    [SyncTrigger V3] No EARLIEST local for '$otherUserId'.");
      }
      if(latestLocalTs != null) {
        debugPrint("    [SyncTrigger V3] Latest   LOCAL for '$otherUserId' is ${latestLocalTs.toDate()}");
      } else {
        debugPrint("    [SyncTrigger V3] No LATEST   local for '$otherUserId'.");
      }
    }

    bool performCatchUp = false;
    Timestamp syncSinceWhen = Timestamp(0,0); // الافتراضي هو الجلب الكامل

    if (forceSync) {
      performCatchUp = true;
      if (kDebugMode) debugPrint("    [SyncTrigger V6] Force sync initiated.");
    } else {
      if (lastFullySyncedUpToTs == null) {
        // لم تتم أي مزامنة كاملة مؤكدة من قبل لهذه المحادثة.
        // حتى لو وجد latestLocalTs (ربما من GMLS)، لا يمكننا الوثوق بأنه كل شيء.
        performCatchUp = true;
        if (kDebugMode) debugPrint("    [SyncTrigger V6] No 'lastFullySyncedUpToTs'. Performing full sync from potentially 'latestLocalTs' or epoch.");
      } else {
        // لدينا آخر نقطة مزامنة كاملة. هل هي قديمة؟
        final Duration routineCheckInterval = const Duration(seconds: 1); // أو حتى أقصر عند فتح الشاشة
        if (Timestamp.now().toDate().difference(lastFullySyncedUpToTs.toDate()) > routineCheckInterval) {
          performCatchUp = true;
          if (kDebugMode) debugPrint("    [SyncTrigger V6] Routine check interval exceeded since last full sync. Performing catch-up.");
        } else {
          // المزامنة الكاملة الأخيرة حديثة. هل آخر رسالة محلية لدينا (التي قد تكون أضيفت بواسطة GMLS)
          // أحدث من آخر مزامنة كاملة؟ هذا يعني أن GMLS عمل بعد آخر catch-up.
          if (latestLocalTs != null && latestLocalTs.toDate().isAfter(lastFullySyncedUpToTs.toDate())) {
            // نعم، GMLS أضاف شيئًا. هل نحتاج لمزامنة كاملة فقط بسبب هذا؟
            // لا بالضرورة، لأننا نثق أن fetchMissingMessages إذا بدأت من lastFullySyncedUpToTs
            // ستجلب كل شيء بعده، بما في ذلك ما أضافه GMLS.
            if (kDebugMode) debugPrint("    [SyncTrigger V6] Recent full sync. Latest local is newer, but GMLS should cover it if no other trigger.");
            // ومع ذلك، إذا أردنا أن نكون أكثر حرصًا، يمكن أن نجبر المزامنة إذا مر وقت بسيط
            // حتى لو كان latestLocalTs أحدث.
            // لكن دعنا نجرب عدم المزامنة هنا إذا كان الفارق بسيطًا.
          } else {
            if (kDebugMode) debugPrint("    [SyncTrigger V6] Recent full sync covers local messages, and routine check interval not met. No catch-up needed now.");
          }
        }
      }
    }

    if (performCatchUp) {
      // ** نقطة بدء المزامنة هي دائماً آخر نقطة مزامنة كاملة مؤكدة، **
      // ** أو بداية التاريخ إذا لم تحدث مزامنة كاملة من قبل. **
      // latestLocalTs هنا يُستخدم كمرجع ثانوي إذا كان أقدم من lastFullySyncedUpToTs
      // وهو ما لا ينبغي أن يحدث.
      final Timestamp syncSinceWhen = lastFullySyncedUpToTs ?? Timestamp(0,0);
      if (kDebugMode) debugPrint("    [SyncTrigger V6] ==> Starting FETCH MISSING for '$otherUserId' since ${syncSinceWhen.toDate()}");
      await fetchMissingMessagesFromFirebase(otherUserId, syncSinceWhen);
    } else {
      if (kDebugMode) debugPrint("  [SyncTrigger V6] No catch-up action triggered for '$otherUserId'.");
    }
  }

// ستحتاج لإضافة getEarliestLocalMessageTimestamp إلى LocalDatabaseService:
// Future<Timestamp?> getEarliestLocalMessageTimestamp(String currentUserId, String otherUserId) async {
//   // نفس استعلام getLatest ولكن بـ orderBy: 'timestamp ASC'
// }


  /// يجلب الرسائل المفقودة من Firebase منذ طابع زمني معين.
// في MessageRepository.dart
// في MessageRepository.dart
// استبدل دالة fetchMissingMessagesFromFirebase الحالية بالكامل بهذه النسخة:
  Future<void> fetchMissingMessagesFromFirebase(String otherUserId, Timestamp sinceWhen) async {
    if (kDebugMode) debugPrint("    [FetchMissing V2] Fetching for '$otherUserId' SINCE ${sinceWhen.toDate().toIso8601String()}");

    bool moreMessagesToFetch = true;
    Timestamp currentBatchStartAfter = sinceWhen; // الطابع الذي نبدأ منه الجلب في كل دورة
    int totalFetchedInThisRun = 0;
    int loopSafetyBreak = 0; // لمنع حلقة لا نهائية محتملة (حد أقصى لعدد الدفعات)

    while (moreMessagesToFetch && loopSafetyBreak < 15) { // يمكنك زيادة حد الأمان إذا كانت المحادثات طويلة جدًا
      loopSafetyBreak++;
      moreMessagesToFetch = false; // نفترض أننا انتهينا، إلا إذا وجدنا رسائل جديدة

      try {
        // تأكد أن currentUserId متاح ومُهيأ في MessageRepository
        if (currentUserId.isEmpty) {
          if (kDebugMode) debugPrint("!!! [FetchMissing V2] Current User ID is empty. Cannot construct query.");
          return;
        }

        Query query = _firebaseService // تأكد أن هذه الدالة تُرجع CollectionReference الصحيح
            .getMessagesCollectionRef(currentUserId, otherUserId) // استدعاء للحصول على مرجع المجموعة
            .where(FirestoreConstants.senderId, isEqualTo: otherUserId) // رسائل الطرف الآخر فقط
            .where(FirestoreConstants.timestamp, isGreaterThan: currentBatchStartAfter)
            .orderBy(FirestoreConstants.timestamp, descending: false) // الأقدم أولاً للجلب التسلسلي
            .limit(50); // جلب دفعات بحجم 50 (يمكن تعديل هذا الرقم)

        if (kDebugMode) debugPrint("      [FetchMissing V2] Loop $loopSafetyBreak: Querying since ${currentBatchStartAfter.toDate()}");

        final QuerySnapshot snapshot = await query.get(); // <--- استخدام .get() بدلاً من .snapshots().listen()
        final List<DocumentSnapshot> newDocs = snapshot.docs;
        totalFetchedInThisRun += newDocs.length;

        if (newDocs.isNotEmpty) {
          if (kDebugMode) debugPrint("      [FetchMissing V2] Loop $loopSafetyBreak: Received ${newDocs.length} message(s).");
          // إذا حصلنا على عدد يساوي الحد، فمن المحتمل أن هناك المزيد
          moreMessagesToFetch = newDocs.length == 50;

          Timestamp latestTimestampInThisBatch = currentBatchStartAfter; // القيمة الأولية لهذه الدفعة

          for (final doc in newDocs) {
            // processAndStoreIncomingMessage يحتاج لمعرف الطرف الآخر الصحيح للسياق
            await processAndStoreIncomingMessage(doc, otherUserId);

            final msgData = doc.data() as Map<String, dynamic>?;
            if (msgData != null) {
              final msgTs = msgData[FirestoreConstants.timestamp] as Timestamp?;
              if (msgTs != null && msgTs.compareTo(latestTimestampInThisBatch) > 0) {
                latestTimestampInThisBatch = msgTs;
              }
            }
          }
          currentBatchStartAfter = latestTimestampInThisBatch; // تحديث نقطة البداية للدورة التالية

          // حدّث الطابع العام للمزامنة الناجحة بعد كل دفعة ناجحة
          await _setLastSuccessfulSyncTimestamp(otherUserId, currentBatchStartAfter);
          if (kDebugMode) debugPrint("      [FetchMissing V2] Processed batch $loopSafetyBreak. New 'startAfter' for next loop: ${currentBatchStartAfter.toDate()}. Overall sync for '$otherUserId' set to this point.");
        } else {
          // لم يتم العثور على رسائل جديدة في هذه الدفعة
          if (kDebugMode) debugPrint("      [FetchMissing V2] Loop $loopSafetyBreak: No MORE new messages found for '$otherUserId' since ${currentBatchStartAfter.toDate()}.");
          moreMessagesToFetch = false; // لا يوجد المزيد، أوقف الحلقة
          // إذا كانت هذه أول دورة (loopSafetyBreak == 1) ولم نجد شيئًا *وكانت sinceWhen ليست من بداية التاريخ*
          // فهذا يعني أننا كنا متزامنين بالفعل حتى آخر رسالة محلية.
          // الآن، يجب أن نحدّث _lastSuccessfulSyncTimestamp إلى الوقت الحالي لنعكس أننا "راجعنا" ولم نجد شيئًا جديدًا.
          if (loopSafetyBreak == 1 && (sinceWhen.seconds > 0 || sinceWhen.nanoseconds > 0) ) {
            await _setLastSuccessfulSyncTimestamp(otherUserId, Timestamp.now());
            if (kDebugMode) debugPrint("        [FetchMissing V2] Confirmed up-to-date for '$otherUserId'. Set general sync to NOW.");
          } else if (loopSafetyBreak > 1 || (sinceWhen.seconds == 0 && sinceWhen.nanoseconds == 0) ){
            // إذا كنا في دورات لاحقة، أو كان هذا جلبًا كاملًا، فإن _setLastSuccessfulSyncTimestamp
            // سيكون قد تم تحديثه بالفعل لآخر رسالة في الدفعة السابقة، أو لا شيء إذا كانت المحادثة فارغة.
            // إذا كانت المحادثة فارغة تمامًا من البداية:
            if (totalFetchedInThisRun == 0 && sinceWhen.seconds == 0 && sinceWhen.nanoseconds == 0) {
              await _setLastSuccessfulSyncTimestamp(otherUserId, Timestamp.now());
              if (kDebugMode) debugPrint("        [FetchMissing V2] Chat appears to be completely empty. Set general sync for '$otherUserId' to NOW.");
            }
          }
        }
      } catch (e, s) {
        if (kDebugMode) debugPrint("!!!   [FetchMissing V2] Error in Firebase catch-up query for '$otherUserId' (Loop $loopSafetyBreak): $e\n$s");
        moreMessagesToFetch = false; // أوقف الحلقة عند الخطأ
        break;
      }
    } // نهاية while

    if(loopSafetyBreak >= 15) if(kDebugMode) debugPrint("!!! [FetchMissing V2] Loop safety break triggered for '$otherUserId'. Processed $totalFetchedInThisRun messages.");
    if (kDebugMode && totalFetchedInThisRun == 0 && loopSafetyBreak == 1 && sinceWhen.seconds == 0 && sinceWhen.nanoseconds == 0) {
      // هذا يعني أننا قمنا بجلب كامل (sinceWhen=0) ولم نجد أي رسائل إطلاقًا.
      // يمكن أن يعني أن المحادثة فارغة.
      await _setLastSuccessfulSyncTimestamp(otherUserId, Timestamp.now());
      if (kDebugMode) debugPrint("    [FetchMissing V2] Initial full fetch for '$otherUserId' yielded no messages. Sync timestamp set to NOW.");
    }
    if (kDebugMode) debugPrint("    [FetchMissing V2] Finished catch-up process for '$otherUserId'. Total new messages fetched in this run: $totalFetchedInThisRun.");
  }



  static String _getCurrentUserIdFromAuth() {
    // الطريقة الأكثر موثوقية للحصول على المستخدم الحالي مباشرة
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.uid.isNotEmpty) {
      return user.uid;
    } else {
      if (kDebugMode) debugPrint("!!! [MessageRepository init] FirebaseAuth.instance.currentUser is NULL or has empty UID!");
      return ""; // إرجاع فارغ للإشارة للمشكلة في المنشئ
    }
  }
  // --- نهاية المنشئ ودالة التهيئة ---

// --- دالة مساعدة لجلب اسم المستخدم (يمكن تحسينها) ---
  Future<void> _fetchCurrentUserName() async {
    if (currentUserId.isNotEmpty) {
      // الطريقة المؤقتة باستخدام getUserData
      final userData = await getUserData(currentUserId);
      final fetchedName = userData?['name'] as String? ?? currentUserId; // استخدم ID كاحتياطي
      // _currentUserName = fetchedName; // <-- تعيين هنا يسبب خطأ لأن _currentUserName final!
      // !!! يجب إما جعل _currentUserName غير final أو استخدام آلية تحديث أخرى !!!
      // --- تعديل لجعل _currentUserName غير final ---
      _setUserName(fetchedName);
      if (kDebugMode) debugPrint("[MessageRepository] Current User Name set to: $_currentUserName");
    }
  }

  // --- لجعل _currentUserName قابلة للتحديث ---
  void _setUserName(String name){ // <-- Setter خاص
    _currentUserName = name;
  }
  String get currentUserName => _currentUserName; // <-- Getter عام
  // ----------------------------------------------

  // --- 1. الحصول على تيار الرسائل (من قاعدة البيانات المحلية) ---
  /// يوفر تيارًا مباشرًا للرسائل من قاعدة البيانات المحلية لمحادثة معينة.
  /// الواجهة تستمع لهذا التيار.
  Stream<List<Message>> getMessages(String otherUserId) {
    if (kDebugMode) debugPrint("[MessageRepository] Getting messages stream for chat with $otherUserId");
    // --- تمرير ID المستخدم الحالي ---
    return _localDbService.getMessagesStream(currentUserId, otherUserId, currentUserId);
    // ---------------------------------
  }


  Future<Message?> getMessageByIdFromLocal(String messageId) async { // اسم جديد للدلالة
    // --- تمرير ID المستخدم الحالي ---
    return await _localDbService.getMessageById(messageId, currentUserId);
    // ---------------------------------
  }






  Future<Map<String, dynamic>?> getUserData(String userId) async {
    if (userId.isEmpty) return null;
    try {
      // يمكن استدعاء ChatService هنا أو الوصول لـ Firestore مباشرة
      // الوصول المباشر أفضل إذا أردنا فصل Repository عن تفاصيل الخدمة
      final docRef = _firestore.collection(FirestoreConstants.userCollection).doc(userId);
      final docSnapshot = await docRef.get();
      if (docSnapshot.exists) {
        return docSnapshot.data();
      } else {
        if (kDebugMode) debugPrint("[MessageRepository] User document not found for ID: $userId");
        return null;
      }
    } catch (e, stackTrace) {
      if (kDebugMode) debugPrint("!!! [MessageRepository] Error fetching user data for $userId: $e\n$stackTrace");
      return null;
    }
  }



  // --- 2. إرسال رسالة جديدة ---
  /// يبدأ عملية إرسال رسالة (نصية أو وسائط).
  /// 1. يحفظها محليًا بحالة 'pending'.
  /// 2. يبدأ عملية الرفع/الإرسال للخادم في الخلفية.
  /// 3. يحدّث الحالة محليًا بناءً على نتيجة عملية الخلفية.
// داخل كلاس MessageRepository

// --- تأكد من وجود دالة نسخ الملفات (يمكن وضعها كـ private helper) ---
// يمكنك وضع هذه الدالة هنا أو استيرادها من ملف utils
  // داخل MessageRepository
// في MessageRepository.dart
  Future<File?> _copyFileToAppDocs(File originalFile, String newFileName) async {
    if (!await originalFile.exists()) {
      if (kDebugMode) debugPrint("  ❌ [_copyFileToAppDocs] Source file DOES NOT EXIST: ${originalFile.path}");
      return null;
    }
    try {
      final appDocsDir = await getApplicationDocumentsDirectory();
      final mediaDir = Directory(p.join(appDocsDir.path, 'sent_media')); // <--- المسار الموحد الصحيح
      if (!await mediaDir.exists()) {
        await mediaDir.create(recursive: true);
        if (kDebugMode) debugPrint("    [_copyFileToAppDocs] Created directory: ${mediaDir.path}");
      }
      final newPath = p.join(mediaDir.path, newFileName);
      if (kDebugMode) debugPrint("  [_copyFileToAppDocs] Copying ${p.basename(originalFile.path)} to $newPath");

      final newFile = await originalFile.copy(newPath);

      final copiedFileExists = await newFile.exists();
      final copiedFileLength = copiedFileExists ? await newFile.length() : -1;

      if (copiedFileExists && copiedFileLength > 0) {
        if (kDebugMode) debugPrint("    ✅ [_copyFileToAppDocs] Copy SUCCESSFUL. Path: ${newFile.path}, Size: $copiedFileLength bytes.");
        return newFile;
      } else {
        if (kDebugMode) debugPrint("    ❌ [_copyFileToAppDocs] Copy FAILED or empty file. Exists=$copiedFileExists, Length=$copiedFileLength for $newPath");
        try { if(copiedFileExists) await newFile.delete(); } catch(_){}
        return null;
      }
    } catch (e, s) {
      if (kDebugMode) debugPrint("  ❌ [_copyFileToAppDocs] Error during copy: $e\n$s");
      return null;
    }
  }
// --- نهاية دالة النسخ ---
  String? _extractFirstUrl(String text) {
    // تعبير نمطي أبسط وأكثر شيوعًا للروابط
    final urlRegExp = RegExp(
        r"(?:(?:https?|ftp):\/\/)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b(?:[-a-zA-Z0-9()@:%_\+.~#?&//=]*)");
    final Match? match = urlRegExp.firstMatch(text);
    return match?.group(0);
  }

// دالة لجلب بيانات المعاينة (مثال بسيط جدًا، ستحتاج لتحليل HTML أو استخدام مكتبة)
  Future<Map<String, dynamic>?> _fetchLinkMetadata(String urlString) async {
    if (kDebugMode) debugPrint("  [LinkPreview] Attempting to fetch metadata for: $urlString");
    String originalUrlInput = urlString; // للاحتفاظ بالرابط الأصلي كما أدخله المستخدم للعودة به

    try {
      // التأكد من أن الرابط يبدأ بـ http أو https
      if (!urlString.toLowerCase().startsWith('http://') && !urlString.toLowerCase().startsWith('https://')) {
        urlString = 'https://$urlString'; // محاولة إضافة https كافتراضي
        if (kDebugMode) debugPrint("    [LinkPreview] Prepended https:// to URL: $urlString");
      }

      final uri = Uri.tryParse(urlString);
      if (uri == null || uri.host.isEmpty) { // تحقق من صحة الـ URI وأن لديه host
        if (kDebugMode) debugPrint("    [LinkPreview] Invalid URI or empty host for: $urlString");
        return null;
      }

      final response = await http.get(uri, headers: {
        // بعض المواقع تتطلب User-Agent لتقديم المحتوى بشكل صحيح
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
      }).timeout(const Duration(seconds: 8)); // إضافة timeout لمنع الانتظار الطويل

      if (kDebugMode) debugPrint("    [LinkPreview] Response status code: ${response.statusCode} for $urlString");

      if (response.statusCode == 200) {
        final document = parse(response.body); // استخدام parse من مكتبة html

        // محاولة استخلاص العنوان من عدة أماكن شائعة
        String? title = document.querySelector('meta[property="og:title"]')?.attributes['content']?.trim() ??
            document.querySelector('meta[name="twitter:title"]')?.attributes['content']?.trim() ??
            document.querySelector('title')?.text.trim();

        // محاولة استخلاص الوصف
        String? description = document.querySelector('meta[property="og:description"]')?.attributes['content']?.trim() ??
            document.querySelector('meta[name="twitter:description"]')?.attributes['content']?.trim() ??
            document.querySelector('meta[name="description"]')?.attributes['content']?.trim();

        // محاولة استخلاص الصورة المصغرة
        String? imageUrl = document.querySelector('meta[property="og:image"]')?.attributes['content']?.trim() ??
            document.querySelector('meta[name="twitter:image"]')?.attributes['content']?.trim() ??
            document.querySelector('link[rel="image_src"]')?.attributes['href']?.trim();

        // محاولة استخلاص اسم الموقع
        String? siteName = document.querySelector('meta[property="og:site_name"]')?.attributes['content']?.trim();

        // التأكد من أن الرابط الذي تم استخلاصه للصورة هو رابط كامل (absolute)
        if (imageUrl != null && imageUrl.isNotEmpty) {
          if (imageUrl.startsWith('data:image')) {
            // هذه data URI، CachedNetworkImage قد لا تتعامل معها بشكل جيد أو لا تحتاج لها
            // يمكنك إما تجاهلها (imageUrl = null) أو محاولة التعامل معها إذا كنت تعرف كيف
            if (kDebugMode) debugPrint("    [LinkPreview] Found data URI for image, might not be displayable by CachedNetworkImage directly: $imageUrl");
            imageUrl = null; // الأبسط هو تجاهلها في هذه الحالة
          } else if (!imageUrl.startsWith('http')) { // إذا لم تكن data URI ولم تبدأ بـ http
            try {
              Uri imageUri = uri.resolve(imageUrl);
              imageUrl = imageUri.toString();
              if (kDebugMode) debugPrint("    [LinkPreview] Resolved relative image URL to: $imageUrl");
            } catch (_) {
              if (kDebugMode) debugPrint("    [LinkPreview] Failed to resolve relative image URL: $imageUrl");
              imageUrl = null;
            }
          }
        }


        if (title != null && title.isNotEmpty) {
          final previewData = {
            'url': originalUrlInput, // الرابط الأصلي الذي تم تحليله أو إدخاله
            'title': title,
            'description': description,
            'image': imageUrl,
            'siteName': siteName,
          };
          if (kDebugMode) debugPrint("    [LinkPreview] Metadata extracted: $previewData");
          return previewData;
        } else {
          if (kDebugMode) debugPrint("    [LinkPreview] Could not extract a valid title for $urlString");
        }
      } else {
        if (kDebugMode) debugPrint("    [LinkPreview] HTTP request failed with status: ${response.statusCode} for $urlString");
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("  ❌ [LinkPreview] Error fetching/parsing link metadata for '$originalUrlInput': $e");
        // debugPrint(s);
      }
    }
    return null; // أرجع null إذا فشلت العملية أو لم يتم العثور على بيانات كافية
  }

// داخل كلاس MessageRepository

  // ... (_copyFileToAppDocs, currentUserId, getUserData, getMessages ...) ...

  // --- دالة sendMessage المُحدثة ---
  Future<void> sendMessage({
    required String recipientId,
    String? textContent,
    File? fileToUpload,          // الملف الأصلي
    File? thumbnailFile,       // المصغرة الأصلية
    required String messageType,
    String? quotedMessageId,
    String? quotedMessageText,
    String? quotedMessageSenderId,
  }) async {
    final stopwatch = Stopwatch()..start();
    if (kDebugMode) debugPrint("---------- [sendMessage REPO v3] Start (Type: $messageType) ----------");
    Map<String, dynamic>? linkPreviewData; // <--- متغير جديد

    final messageId = _uuid.v1();
    final nowTimestamp = Timestamp.now();
    bool insertionSuccess = false;

    File? permanentMainFileRef;      // مرجع للملف المنسوخ (للرفع)
    File? permanentThumbnailFileRef; // مرجع للمصغرة المنسوخة (للرفع)

    String contentForInitialSave = '';      // ما سيتم حفظه في حقل content محلياً مبدئياً
    String? localFileNameForDb;      // *اسم* الملف الرئيسي للداتا بيز
    String? localThumbNameForDb;     // *اسم* المصغرة للداتا بيز
    String? originalFileNameForDb; // الاسم الأصلي قبل النسخ
    if(_currentUserName.isEmpty){
      // انتظر قليلاً لجلب الاسم الأولي، أو استخدم ID كاسم مؤقت
      // await Future.delayed(Duration(milliseconds: 100)); // انتظار بسيط (غير مثالي)
      if (kDebugMode) debugPrint("  !!! [sendMessage REPO] Warning: Sending message before currentUserName is fetched. Using ID as name.");
      _setUserName(currentUserId); // استخدام ID كاسم مؤقت إذا كان الاسم فارغًا
    }

    try {

      // --- خطوة 1: تجهيز البيانات والملفات ---
      if (messageType == FirestoreConstants.typeText) {
        if (textContent == null || textContent.trim().isEmpty) { throw Exception("Cannot send empty text message."); }
        contentForInitialSave = textContent.trim();
        if (kDebugMode) debugPrint("  [sendMessage] Prepared TEXT content: $contentForInitialSave");
      }
      else { // معالجة الوسائط
        if (fileToUpload == null || !await fileToUpload.exists()) { throw Exception("Media file ($messageType) required and must exist."); }

        originalFileNameForDb = p.basename(fileToUpload.path); // الحصول على الاسم الأصلي

        // --- أ. تجهيز ونسخ الملف الرئيسي ---
        String permanentFileName = '${messageId}_${originalFileNameForDb.replaceAll(RegExp(r'[^\w\.\-]+'), '_')}'; // اسم فريد ونظيف
        permanentMainFileRef = await _copyFileToAppDocs(fileToUpload, permanentFileName);
        if (permanentMainFileRef == null) { throw Exception("Failed to copy main media file."); }
        localFileNameForDb = p.basename(permanentMainFileRef.path); // <-- *** حفظ اسم الملف فقط ***
        contentForInitialSave = localFileNameForDb; // المحتوى الأولي هو اسم الملف المحلي
        if (kDebugMode) debugPrint("  [sendMessage] Prepared main MEDIA file. Saved Name: $localFileNameForDb");

        // --- ب. تجهيز ونسخ المصغرة (للفيديو) ---
        if (messageType == FirestoreConstants.typeVideo && thumbnailFile != null) {
          if (await thumbnailFile.exists()) {
            String thumbExt = p.extension(thumbnailFile.path);
            String permanentThumbName = '${messageId}_thumb$thumbExt';
            permanentThumbnailFileRef = await _copyFileToAppDocs(thumbnailFile, permanentThumbName);
            if (permanentThumbnailFileRef != null) {
              localThumbNameForDb = p.basename(permanentThumbnailFileRef.path); // <-- *** حفظ اسم المصغère فقط ***
              if (kDebugMode) debugPrint("  [sendMessage] Prepared MEDIA thumbnail. Saved Name: $localThumbNameForDb");
            } else { if (kDebugMode) debugPrint("  !!! [sendMessage] Failed to copy thumbnail file."); }
          } else { if (kDebugMode) debugPrint("  !!! [sendMessage] Original thumbnail file not found: ${thumbnailFile.path}"); }
        }
        // localThumbNameForDb سيكون null تلقائياً إذا لم يتم النسخ أو لم يكن فيديو

      } // نهاية معالجة الوسائط
      if (kDebugMode) debugPrint("  [sendMessage] Preparation done in ${stopwatch.elapsedMilliseconds}ms.");
      final String? detectedUrl = _extractFirstUrl(contentForInitialSave);
      if (detectedUrl != null) {
        if (kDebugMode) debugPrint("  [sendMessage] Detected URL: $detectedUrl");
        linkPreviewData = await _fetchLinkMetadata(detectedUrl); // <--- جلب البيانات
        if (linkPreviewData != null && kDebugMode) {
          debugPrint("  [sendMessage] Fetched link preview data: ${linkPreviewData['title']}");
        }
      }

      // --- خطوة 2: إنشاء كائن الرسالة ---
      if (contentForInitialSave.isEmpty) { throw Exception("Initial content is empty."); }
      final initialMessage = Message(
        linkPreviewData: linkPreviewData, // <--- تمرير بيانات المعاينة

        messageId: messageId, senderId: currentUserId, recipientId: recipientId,
        content: contentForInitialSave, // النص أو *اسم الملف* المحلي للوسائط
        type: messageType, timestamp: nowTimestamp,
        status: MessageStatus.pending, isMe: true,
        localFilePath: localFileNameForDb,         // *** اسم الملف الرئيسي ***
        localThumbnailPath: localThumbNameForDb,   // *** اسم المصغرة ***
        thumbnailUrl: null,                      // رابط المصغرة البعيد (null مبدئياً)
        originalFileName: originalFileNameForDb,
        quotedMessageId: quotedMessageId,
        quotedMessageText: quotedMessageText,
        quotedMessageSenderId: quotedMessageSenderId,
      );


      // --- خطوة 3: حفظ الرسالة محليًا ---
      if (kDebugMode) debugPrint("  [sendMessage] Attempting to insert pending message: $initialMessage");
      await _localDbService.insertOrReplaceMessage(initialMessage);
      insertionSuccess = true;
      if (kDebugMode) debugPrint("  ✅ [sendMessage] Pending message ($messageId) assumed inserted locally.");


      // --- خطوة 4: بدء عملية Firebase في الخلفية ---
      if (insertionSuccess) {
       await _startFirebaseSendProcess(
            initialMessage.copyWith(status: MessageStatus.sending), // مرر نسخة مع الحالة الصحيحة
            permanentMainFileRef,       // الملف *المنسوخ* للرفع
            permanentThumbnailFileRef,  // المصغرة *المنسوخة* للرفع
            messageId ,// تمرير الـ ID للتعامل مع النتائج
           currentUserName // <--- تمرير اسم المستخدم الحالي

       ).then((success) => debugPrint("  [sendMessage] BG process notified completion for $messageId (Success: $success)."))
            .catchError((e,s) => debugPrint("!!! [sendMessage] UNHANDLED BG error notification for $messageId: $e\n$s"));
        if (kDebugMode) debugPrint("---------- [sendMessage] EXIT (Background started) - Total: ${stopwatch.elapsedMilliseconds}ms ----------");
      } else {
        // لن يتم الوصول هنا إذا كان الإدراج يرمي خطأ ولم يتم التقاطه في الخطوة 3
        if (kDebugMode) debugPrint("---------- [sendMessage] EXIT (Local DB Insert reported fail - SHOULD NOT HAPPEN NORMALLY) ----------");
      }


    } catch (e, s) { // التقاط الأخطاء من التحضير أو النسخ أو الإدراج الأولي
      stopwatch.stop();
      if (kDebugMode) debugPrint("!!! CRITICAL Error during sendMessage prep/insert ($messageId) after ${stopwatch.elapsedMilliseconds}ms: $e\n$s");
      Get.snackbar("خطأ إرسال", "حدث خطأ أثناء تجهيز الرسالة. $e", snackPosition: SnackPosition.BOTTOM);
      if (kDebugMode) debugPrint("---------- [sendMessage] EXIT (Preparation/Insert Failed) ----------");
      // هنا يمكنك محاولة تحديث الرسالة لـ failed إذا تم إدراجها قبل رمي الخطأ
      if (insertionSuccess) { // تحقق إذا تم الإدراج قبل الخطأ (نادر لكن ممكن)
        try { await _localDbService.updateMessageStatus(messageId, MessageStatus.failed); } catch (_) {}
      }
    }
  } // نهاية sendMessage



  // --- دالة معالجة Firebase في الخلفية ---
  Future<bool> _startFirebaseSendProcess(Message messageToSend, File? mainFileToUpload, File? thumbFileToUpload, String messageId  ,       String senderName // <--- استقبل الاسم هنا
  ) async {
    final stopwatch = Stopwatch()..start(); // <--- قياس الوقت
    if (kDebugMode) debugPrint(" -> [BG Process - $messageId] Starting Firebase process...");

    UploadResult result = UploadResult(success: false); // القيمة الافتراضية

    try {
      // 1. تحديث الحالة إلى sending
      bool statusUpdated = await _localDbService.updateMessageStatus(messageId, MessageStatus.sending);
      if (kDebugMode) debugPrint(" -> [BG Process - $messageId] Updated status to sending. DB Update success: $statusUpdated");
      if (!statusUpdated) {
        // إذا فشل تحديث الحالة (لأن الرسالة غير موجودة لسبب ما)، فلا داعي للمتابعة
        throw Exception("Failed to update status to sending for message $messageId (not found locally?)");
      }

      // 2. استدعاء خدمة Firebase
      if (kDebugMode) debugPrint(" -> [BG Process - $messageId] Calling Firebase service (uploadAndWriteMessage)...");
      result = await _firebaseService.uploadAndWriteMessage(
        messageToSend, // نمرر الرسالة بالحالة الأصلية أو pending (لا يهم كثيراً لـ firebase)
        fileToUpload: mainFileToUpload,
        thumbnailFile: thumbFileToUpload,
          senderName: senderName // <--- تمرير الاسم للخدمة

      );
      if (kDebugMode) debugPrint(" -> [BG Process - $messageId] Firebase service returned: Success=${result.success}. Time: ${stopwatch.elapsedMilliseconds}ms");

      // 3. تحديث قاعدة البيانات المحلية بناءً على النتيجة
      if (result.success) {
        // --- النجاح ---
        await _localDbService.updateMessageStatus(messageId, MessageStatus.sent);
        if (kDebugMode) debugPrint(" -> [BG Process - $messageId] Status updated to sent.");
        if (messageToSend.type != FirestoreConstants.typeText) {
          final Map<String, dynamic> updates = {};
          if (result.contentUrl != null && result.contentUrl!.isNotEmpty) updates['content'] = result.contentUrl;
          if (result.thumbnailUrl != null && result.thumbnailUrl!.isNotEmpty) updates['thumbnailUrl'] = result.thumbnailUrl;
          if (updates.isNotEmpty) {
            await _localDbService.updateMessageFields(messageId, updates);
            if (kDebugMode) debugPrint(" -> [BG Process - $messageId] Updated local URLs.");
          }
        }
        stopwatch.stop();
        if (kDebugMode) debugPrint(" -> [BG Process - $messageId] SUCCESSFUL end. Total time: ${stopwatch.elapsedMilliseconds}ms");
        return true; // <<<--- إرجاع نجاح

      } else {
        // --- الفشل المُبلغ عنه من الخدمة ---
        if (kDebugMode) debugPrint("!!! [BG Process - $messageId] Firebase service explicitly reported failure.");
        await _localDbService.updateMessageStatus(messageId, MessageStatus.failed);
        stopwatch.stop();
        if (kDebugMode) debugPrint(" -> [BG Process - $messageId] FAILED (Firebase service). Total time: ${stopwatch.elapsedMilliseconds}ms");
        return false; // <<<--- إرجاع فشل
      }

    } catch (e, stackTrace) {
      // --- خطأ غير متوقع أثناء العملية ---
      if (kDebugMode) debugPrint("!!! [BG Process - $messageId] Error during background process: $e\n$stackTrace");
      // التأكد من تعيين الحالة failed في قاعدة البيانات
      try { await _localDbService.updateMessageStatus(messageId, MessageStatus.failed); } catch (_) {}
      stopwatch.stop();
      if (kDebugMode) debugPrint(" -> [BG Process - $messageId] FAILED (Exception). Total time: ${stopwatch.elapsedMilliseconds}ms");
      return false; // <<<--- إرجاع فشل
    }
  }

// ... (بقية دوال MessageRepository) ...

// نهاية كلاس MessageRepository
  // دالة مساعدة لنسخ ملف إلى مجلد المستندات الخاص بالتطبيق
// (يمكن وضعها في ملف utils أو داخل الخدمة/المستودع)
  Future<File?> copyFileToAppDocs(File originalFile, String newFileName) async {
    try {
      final appDocsDir = await getApplicationDocumentsDirectory();
      // إنشاء مجلد فرعي للوسائط المرسلة (اختياري ولكن منظم)
      final mediaDir = Directory(p.join(appDocsDir.path, 'sent_media'));
      if (!await mediaDir.exists()) {
        await mediaDir.create(recursive: true);
      }
      // المسار النهائي للملف الجديد
      final newPath = p.join(mediaDir.path, newFileName);
      if (kDebugMode) debugPrint("Copying ${originalFile.path} to permanent path: $newPath");
      // نسخ الملف
      final newFile = await originalFile.copy(newPath);
      return newFile;
    } catch (e) {
      if (kDebugMode) debugPrint("Error copying file to app docs: $e");
      return null;
    }
  }

  // --- 3. الاستماع للرسائل الجديدة من Firebase ومعالجتها ---

  // StreamSubscription? _firebaseListenerSubscription;

  /// بدء الاستماع للرسائل الواردة الجديدة من طرف آخر في محادثة معينة.
  // void initializeMessageListener(String otherUserId) {
  //   // إلغاء أي مستمع سابق لنفس المحادثة لتجنب التكرار
  //   cancelMessageListener();
  //   if (kDebugMode) debugPrint("[MessageRepository] Initializing Firebase message listener for chat with $otherUserId");
  //
  //   _firebaseListenerSubscription = _firebaseService
  //       .listenForNewFirebaseMessages(otherUserId) // تعديل اسم الدالة في ChatService إذا لزم الأمر
  //       .listen((List<DocumentSnapshot> newDocs) async {
  //     if (kDebugMode) debugPrint("[MessageRepository] Received ${newDocs.length} new document(s) from Firebase listener.");
  //     // معالجة كل رسالة جديدة واردة
  //     for (final doc in newDocs) {
  //       await _processIncomingFirebaseMessage(doc);
  //     }
  //   }, onError: (error, stackTrace) {
  //     if (kDebugMode) {
  //       debugPrint("!!! [MessageRepository] Error in Firebase message listener: $error\n$stackTrace");
  //     }
  //     // يمكنك إضافة منطق إعادة المحاولة للاستماع هنا إذا انقطع الاتصال
  //   });
  // }




  // داخل كلاس MessageRepository

  /// بدء تنزيل وسائط بشكل يدوي لرسالة موجودة (يفترض أنها ليست نصية).
  Future<void> downloadMediaManually(String messageId) async {
    if (kDebugMode) debugPrint("[MessageRepository] Manual download requested for $messageId.");
    // 1. جلب الرسالة من قاعدة البيانات المحلية
    // --- *** التصحيح: تمرير currentUserId *** ---
    final Message? message = await _localDbService.getMessageById(messageId, currentUserId); // <-- تم تمرير currentUserId
    // ------------------------------------------

    if (message == null || message.type == FirestoreConstants.typeText || message.content.isEmpty) {
      if (kDebugMode) debugPrint("[MessageRepository] Cannot manually download: Message $messageId not found, is text, or has no remote URL.");
      return;
    }

    // 2. التحقق من الحالة الحالية
    // (أضفنا تحقق من المسار المحلي للتأكيد)
    final String? fullLocalPath = await _buildFullLocalPath(message.localFilePath);
    if (message.status == MessageStatus.downloading || message.status == MessageStatus.received && fullLocalPath != null) {
      if (kDebugMode) debugPrint("[MessageRepository] Skipping manual download for $messageId: Status (${message.status.name}) or local file exists ($fullLocalPath).");
      return;
    }


    if (kDebugMode) debugPrint("[MessageRepository] Starting manual download process for $messageId (URL: ${message.content})");

    // 3. تحديث الحالة إلى 'downloading' محليًا
    bool statusUpdated = await _localDbService.updateMessageStatus(messageId, MessageStatus.downloading);
    if(!statusUpdated){ // إذا فشل تحديث الحالة (لا يجب أن يحدث إذا وُجدت الرسالة)
      if(kDebugMode) debugPrint("!!! [downloadMediaManually] Failed to update status to downloading for $messageId.");
      // يمكنك إظهار خطأ أو الخروج بهدوء
      return;
    }

    // 4. استدعاء دالة التنزيل الفعلية (غير متزامنة)
    _downloadAndSaveMedia(message);
    if (kDebugMode) debugPrint("[MessageRepository] Background download process initiated for $messageId.");
  }

// --- تأكد من وجود دالة _buildFullLocalPath المساعدة ---
  Future<String?> _buildFullLocalPath(String? localFileName) async {
    if (localFileName == null || localFileName.isEmpty) return null;
    try {
      final appDocsDir = await getApplicationDocumentsDirectory();
      final mediaPath = p.join(appDocsDir.path, 'sent_media', localFileName);
      // لا نحتاج للتحقق من وجوده هنا، سنعتمد على _downloadAndSaveMedia
      return mediaPath;
    } catch (e) { return null; }
  }


  // --- **[جديد]** دالة إضافة رسالة لقائمة انتظار التنزيل ---
  // --- **[تعديل]** دالة إضافة العنصر لقائمة الانتظار والحفظ في Storage ---
  void _queueForDownload({ required String messageId, required String url, required DownloadType type }) {
    // إنشاء Map لتمثيل طلب التنزيل
    final newItem = {
      'messageId': messageId,
      'url': url,
      'type': type.name, // تخزين اسم النوع (mainFile أو thumbnail)
      'timestamp': DateTime.now().millisecondsSinceEpoch // اختياري: لتتبع وقت الإضافة
    };

    // التحقق إذا كان هذا الطلب (لنفس الملف ونفس النوع) موجودًا بالفعل
    if (_downloadQueue.any((item) => item['messageId'] == messageId && item['type'] == type.name && item['url'] == url )) {
      if (kDebugMode) debugPrint("   -> Item ${type.name} for $messageId already in queue. Skipping add.");
      return;
    }

    // إضافة العنصر الجديد لقائمة الانتظار التفاعلية في الذاكرة
    _downloadQueue.add(newItem);
    // حفظ القائمة المحدثة في GetStorage
    _saveQueueToStorage();

    if (kDebugMode) debugPrint("   -> Queued ${type.name} download for $messageId. Queue size: ${_downloadQueue.length}");

    // تشغيل المعالج إذا لم يكن يعمل
    if (!_isDownloadProcessorRunning) {
      _processDownloadQueue();
    }
  }




  // --- **[جديد]** حفظ قائمة الانتظار في GetStorage ---
  Future<void> _saveQueueToStorage() async {
    try {
      // تحويل List<Map<String, dynamic>> إلى JSON String أو تخزينها مباشرة إذا كان GetStorage يدعمها
      // يجب أن تكون القيم داخل الـ Map بسيطة (String, int, bool, double, List, Map)
      await _storage.write(_downloadQueueStorageKey, _downloadQueue.toList()); // تحويل RxList إلى List
      if(kDebugMode) debugPrint("   -> Download queue saved to GetStorage (${_downloadQueue.length} items).");
    } catch (e) {
      if(kDebugMode) debugPrint("!!! Error saving download queue to GetStorage: $e");
    }
  }


  // --- **[جديد]** استعادة قائمة الانتظار من GetStorage وبدء المعالجة ---
  Future<void> _restoreAndProcessDownloadQueue() async {
    try {
      // قراءة القائمة المحفوظة
      List<dynamic>? storedQueue = _storage.read<List<dynamic>>(_downloadQueueStorageKey);

      if (storedQueue != null) {
        // تحويلها مرة أخرى إلى List<Map<String, dynamic>>
        _downloadQueue.assignAll(storedQueue.map((item) => Map<String, dynamic>.from(item as Map)).toList());
        if (kDebugMode) debugPrint("[MessageRepository] Restored ${_downloadQueue.length} items from download queue.");
      } else {
        if (kDebugMode) debugPrint("[MessageRepository] No download queue found in storage.");
      }
    } catch (e) {
      if (kDebugMode) debugPrint("!!! Error restoring download queue: $e");
      // في حالة الخطأ، ابدأ بقائمة فارغة
      _downloadQueue.clear();
    }

    // البدء في معالجة القائمة المستعادة (أو الفارغة)
    if (_downloadQueue.isNotEmpty && !_isDownloadProcessorRunning) {
      if (kDebugMode) debugPrint("[MessageRepository] Starting download processor for restored queue.");
      _processDownloadQueue();
    } else if (!_isDownloadProcessorRunning) {
      if (kDebugMode) debugPrint("[MessageRepository] Download queue is empty or processor already running after restore.");
    }
  }



  // --- **[جديد]** المعالج التسلسلي لقائمة انتظار التنزيل ---
  // --- **[تعديل]** المعالج مع دعم الأولوية للمصغرات ---
  Future<void> _processDownloadQueue() async {
    if (_isDownloadProcessorRunning) return;
    _isDownloadProcessorRunning = true;
    if (kDebugMode) debugPrint(">>> DownloadQ Processor: STARTED <<<");

    while (_downloadQueue.isNotEmpty) { // <--- التحقق هنا
      Map<String, dynamic> itemToProcess;
      int itemIndex = -1;

      // البحث عن مصغرة أولاً
      itemIndex = _downloadQueue.indexWhere((item) => item['type'] == DownloadType.thumbnail.name);
      if (itemIndex != -1) {
        itemToProcess = _downloadQueue.removeAt(itemIndex); // أزل المصغرة للمعالجة
        if(kDebugMode) debugPrint("   -> Prioritizing THUMB: ${itemToProcess['messageId']}");
      } else if (_downloadQueue.isNotEmpty) { // إذا لا توجد مصغرات، خذ العنصر الأول
        itemToProcess = _downloadQueue.removeAt(0); // أزل الملف الرئيسي للمعالجة
        if(kDebugMode) debugPrint("   -> Processing MAIN: ${itemToProcess['messageId']}");
      } else {
        break; // القائمة فارغة، اخرج
      }

      // **مهم:** حفظ الطابور المحدث بعد الإزالة
      await _saveQueueToStorage();


      // ... بقية الكود: استخراج البيانات، إعادة التحقق من الحالة، استدعاء _executeDownload ...
      final String messageId = itemToProcess['messageId']; final String url = itemToProcess['url'];
      final DownloadType type = DownloadType.values.firstWhere((e) => e.name == itemToProcess['type'], orElse: () => DownloadType.mainFile);

      final currentMsg = await _localDbService.getMessageById(messageId, currentUserId);
      bool proceed = false;
      if(currentMsg != null){
        if(type == DownloadType.mainFile && (currentMsg.status == MessageStatus.downloading || currentMsg.status == MessageStatus.downloadFailed)) {
          proceed = true;
        } else if (type == DownloadType.thumbnail && currentMsg.localThumbnailPath == null && (currentMsg.status == MessageStatus.downloading || currentMsg.status == MessageStatus.received || currentMsg.status == MessageStatus.downloadFailed)) proceed = true;
      }
      if (proceed) {
        await _executeDownload(messageId, url, type);
      } else if(kDebugMode) debugPrint("   -> Skipping download $messageId (${type.name}): Conditions not met (Status: ${currentMsg?.status.name})");


      await Future.delayed(const Duration(milliseconds: 200)); // تأخير بسيط
    }
    if (kDebugMode) debugPrint(">>> DownloadQ Processor: FINISHED <<<");
    _isDownloadProcessorRunning = false;
  }















  // --- **[جديد]** الدالة الفعلية للتنزيل (مأخوذة من _downloadAndSaveMedia) ---
// في MessageRepository.dart

  Future<void> _executeDownload(String messageId, String remoteUrl, DownloadType downloadType) async {
    if (kDebugMode) debugPrint("    📦 [_executeDownload $messageId] Type: ${downloadType.name}, URL: $remoteUrl");

    String fileExtension = _getFileExtension(remoteUrl, ''); // استنتاج الامتداد
    final currentMsgForType = await _localDbService.getMessageById(messageId, currentUserId); // لجلب النوع إذا لم يستنتج الامتداد

    if(fileExtension == 'tmp' || fileExtension.isEmpty) { // إذا لم يتمكن من استنتاج امتداد جيد من الرابط
      if (downloadType == DownloadType.mainFile && currentMsgForType != null) {
        fileExtension = _getFileExtension(remoteUrl, currentMsgForType.type); // حاول مرة أخرى باستخدام نوع الرسالة
      } else if (downloadType == DownloadType.thumbnail) {
        fileExtension = 'jpg'; // افترض jpg أو png للمصغرات كقيمة افتراضية
      }
      if (fileExtension == 'tmp' || fileExtension.isEmpty) fileExtension = "dat"; // قيمة افتراضية نهائية إذا فشل كل شيء
      if (kDebugMode) debugPrint("      [_executeDownload $messageId] Deduced/Defaulted extension: .$fileExtension");
    }


    // اسم الملف المحلي فقط (بدون مسار)
    String generatedLocalFileName = downloadType == DownloadType.mainFile
        ? '${messageId}_${_uuid.v1()}.$fileExtension' // اجعله فريدًا لتجنب الكتابة فوق التنزيلات المتزامنة لنفس الرسالة (نادر)
        : '${messageId}_thumb.$fileExtension'; // المصغرات يمكن أن تستخدم اسمًا أكثر ثباتًا متعلقًا بالرسالة

    try {
      // استدعاء دالة الخدمة الجديدة
      final File? downloadedFile = await _firebaseService.downloadMediaAndSaveToAppSpecificDir(
        remoteUrl: remoteUrl,
        targetFileName: generatedLocalFileName,
        subDirectoryName: "sent_media", // <--- اسم المجلد الفرعي الموحد
      );

      if (downloadedFile != null) { // لا داعي لـ .exists() أو .length() هنا، الخدمة يجب أن تضمن ذلك
        // final String actualFileNameOnly = p.basename(downloadedFile.path); // يجب أن يكون هو generatedLocalFileName
        if (kDebugMode) debugPrint("      ✅ [_executeDownload $messageId] ${downloadType.name} Download SUCCESS via ChatService. Local Name: $generatedLocalFileName");

        Map<String, dynamic> updates = {};
        if (downloadType == DownloadType.mainFile) {
          updates['localFilePath'] = generatedLocalFileName; // حفظ اسم الملف الرئيسي فقط
          updates['status'] = MessageStatus.received.name;
        } else { // DownloadType.thumbnail
          updates['localThumbnailPath'] = generatedLocalFileName; // حفظ اسم المصغرة فقط
          // لا نغير status الرسالة عند تنزيل المصغرة وحدها
        }
        await _localDbService.updateMessageFields(messageId, updates);
        if (kDebugMode) debugPrint("        [_executeDownload $messageId] DB updated for ${downloadType.name}.");

      } else {
        // الخدمة أرجعت null، مما يعني فشل التنزيل
        throw Exception("ChatService.downloadMediaAndSaveToAppSpecificDir returned null.");
      }

    } catch (e, s) {
      if (kDebugMode) debugPrint("    ❌ [_executeDownload $messageId] Error processing download for ${downloadType.name}: $e\n$s");
      if (downloadType == DownloadType.mainFile) {
        // فقط غيّر الحالة إلى فشل إذا كان الملف الرئيسي هو الذي فشل
        await _localDbService.updateMessageStatus(messageId, MessageStatus.downloadFailed);
      }
    }
  }

  // --- نهاية التعديلات لقائمة الانتظار ---




  /// تُستدعى بواسطة الخدمة المركزية عند اكتشاف رسالة جديدة.
  Future<void> processAndStoreIncomingMessage(DocumentSnapshot messageDoc, String otherUserIdForContext) async {
    final messageId = messageDoc.id;
    // التحقق من السياق لتجنب التضارب إذا كان GlobalListener و CatchUp يعملان
    if (kDebugMode) debugPrint("  [ProcessIncoming] START for msg '$messageId' (Context: Chat with '$otherUserIdForContext').");

    // ... (بقية الكود الخاص بـ messageExists, Message.fromFirestore, والتحقق من isMe يبقى كما هو)
    bool exists = await _localDbService.messageExists(messageId);
    if (exists) {
      if (kDebugMode) debugPrint("    [ProcessIncoming] Message '$messageId' already exists locally. Skipping storage/download.");
      // قد تحتاج هنا لتحديث حالة القراءة إذا جاءت من خلال catch-up והرسالة موجودة ولكن isRead تغيرت في السحابة.
      // لكن هذا يتطلب مقارنة معقدة. سنتركه الآن.
      return;
    }

    Message incomingMessage;
    try {
      incomingMessage = Message.fromFirestore(messageDoc, currentUserId);
      if (incomingMessage.isMe) {
        if (kDebugMode) debugPrint("    [ProcessIncoming] Skipping store for 'isMe' message '$messageId'.");
        return;
      }
    } catch (e) {
      if (kDebugMode) debugPrint("!!!   [ProcessIncoming] Error parsing incoming message '$messageId': $e");
      return;
    }

    // ... (كود التعامل مع نوع الرسالة وحفظها وتنزيلها يبقى كما هو)
    // هذا الجزء سليم: يحفظ النص كـ received والوسائط كـ downloading ويضيفها للطابور
    if (incomingMessage.type == FirestoreConstants.typeText) {
      if(kDebugMode) debugPrint("    [ProcessIncoming] Storing incoming TEXT message '$messageId' as received.");
      await _localDbService.insertOrReplaceMessage(
          incomingMessage.copyWith(status: MessageStatus.received));
    } else { // Media
      if(kDebugMode) debugPrint("    [ProcessIncoming] Storing incoming MEDIA message '$messageId' (type: ${incomingMessage.type}) as downloading.");
      await _localDbService.insertOrReplaceMessage(incomingMessage.copyWith(
        status: MessageStatus.downloading, // الحالة الأولية قبل بدء التنزيل
        localFilePath: null,      // تأكد من مسح أي مسارات قديمة
        localThumbnailPath: null,
      ));

      // إضافة الملف الرئيسي للطابور إذا كان الرابط صالحًا
      if (incomingMessage.content.isNotEmpty && incomingMessage.content.startsWith('http')) {
        if (kDebugMode) debugPrint("      [ProcessIncoming] Queuing MAIN file download for '$messageId': ${incomingMessage.content}");
        _queueForDownload(messageId: messageId, url: incomingMessage.content, type: DownloadType.mainFile);
      } else {
        if (kDebugMode) debugPrint("  !!!   [ProcessIncoming] Cannot queue MAIN file for '$messageId': Invalid remote URL ('${incomingMessage.content}'). Setting to downloadFailed.");
        await _localDbService.updateMessageStatus(messageId, MessageStatus.downloadFailed);
      }

      // إضافة المصغرة للطابور إذا كان الرابط صالحًا
      if (incomingMessage.thumbnailUrl != null && incomingMessage.thumbnailUrl!.isNotEmpty && incomingMessage.thumbnailUrl!.startsWith('http')) {
        if (kDebugMode) debugPrint("      [ProcessIncoming] Queuing THUMBNAIL download for '$messageId': ${incomingMessage.thumbnailUrl}");
        _queueForDownload(messageId: messageId, url: incomingMessage.thumbnailUrl!, type: DownloadType.thumbnail);
      }
    }
    if (kDebugMode) debugPrint("  [ProcessIncoming] END for msg '$messageId'.");
  }




  /// إلغاء الاستماع لرسائل Firebase (عند الخروج من الشاشة مثلاً).
  // void cancelMessageListener() {
  //   if (_firebaseListenerSubscription != null) {
  //     _firebaseListenerSubscription!.cancel();
  //     _firebaseListenerSubscription = null;
  //     if (kDebugMode) debugPrint("[MessageRepository] Firebase message listener cancelled.");
  //   }
  // }

  /// معالجة رسالة واردة من Firebase.
  // Future<void> _processIncomingFirebaseMessage(DocumentSnapshot doc) async {
  //   final messageId = doc.id;
  //   if (kDebugMode) debugPrint("[MessageRepository] Processing incoming message ($messageId)...");
  //
  //   // --- الخطوة 1: التحقق إذا كانت الرسالة موجودة محليًا ---
  //   final bool existsLocally = await _localDbService.messageExists(messageId); // ستحتاج لإضافة هذه الدالة للخدمة المحلية
  //   if (existsLocally) {
  //     if (kDebugMode) debugPrint("[MessageRepository] Incoming message ($messageId) already exists locally. Skipping.");
  //     // قد تحتاج هنا لمنطق تحديث الحالة إذا كانت Firestore لديها حالة أحدث (مثل delivered/read)
  //     return;
  //   }
  //
  //   // --- الخطوة 2: تحويل بيانات Firebase إلى نموذج Message ---
  //   Message incomingMessage;
  //   try {
  //     incomingMessage = Message.fromFirestore(doc, currentUserId);
  //     // التأكد أنها ليست رسالة أرسلتها أنا للتو (لأنها يجب أن تكون موجودة محليًا بالفعل)
  //     if (incomingMessage.isMe) {
  //       if (kDebugMode) debugPrint("[MessageRepository] Incoming message ($messageId) is 'isMe=true', likely already processed. Skipping insert.");
  //       return; // لا تدرجها مرة أخرى
  //     }
  //   } catch (e) {
  //     if (kDebugMode) debugPrint("!!! [MessageRepository] Failed to parse incoming Firestore message ($messageId): $e");
  //     return; // توقف عن المعالجة إذا فشل التحويل
  //   }
  //
  //   // --- الخطوة 3: التعامل مع نوع الرسالة ---
  //   if (incomingMessage.type == FirestoreConstants.typeText) {
  //     // --- حالة الرسالة النصية ---
  //     if (kDebugMode) debugPrint("[MessageRepository] Incoming message ($messageId) is TEXT. Saving as received.");
  //     // تغيير الحالة إلى received وحفظها محليًا
  //     await _localDbService.insertOrReplaceMessage(
  //       incomingMessage.copyWith(status: MessageStatus.received),
  //     );
  //   } else {
  //     // --- حالة رسالة الوسائط (صورة، فيديو، صوت) ---
  //     if (kDebugMode) debugPrint("[MessageRepository] Incoming message ($messageId) is MEDIA (${incomingMessage.type}). Setting status to downloading and saving.");
  //     // 1. حفظ الرسالة محليًا بحالة 'downloading'
  //     await _localDbService.insertOrReplaceMessage(
  //       incomingMessage.copyWith(status: MessageStatus.downloading),
  //     );
  //
  //     // 2. بدء تنزيل الملف في الخلفية (لا تنتظر هنا)
  //     _downloadAndSaveMedia(incomingMessage); // استدعاء دالة التنزيل غير المتزامنة
  //
  //   }
  // }


  // --- 4. تنزيل وحفظ ملفات الوسائط الواردة ---

  /// تنزيل ملف وسائط وحفظه محليًا وتحديث حالة الرسالة.
  Future<void> _downloadAndSaveMedia(Message message) async {
    final messageId = message.messageId;
    final remoteUrl = message.content; // URL من Firebase Storage
    if (remoteUrl.isEmpty) {
      if (kDebugMode) debugPrint("!!! [MessageRepository] Cannot download media for ($messageId): Remote URL is empty.");
      await _localDbService.updateMessageStatus(messageId, MessageStatus.downloadFailed);
      return;
    }

    if (kDebugMode) debugPrint("[MessageRepository] Starting media download for ($messageId) from $remoteUrl");

    try {
      // استدعاء خدمة Firebase لتنزيل الملف (هذه الدالة يجب أن تحفظه في مسار مؤقت/دائم وتعيد File)
      // ستحتاج لإنشاء اسم ملف محلي فريد (ربما باستخدام messageId)
      String localFileName = '$messageId.${_getFileExtension(remoteUrl, message.type)}'; // إنشاء اسم ملف بامتداد مناسب
      final File? downloadedFile = await _firebaseService.downloadMedia(remoteUrl, localFileName);

      if (downloadedFile != null && await downloadedFile.exists()) {
        // --- حالة نجاح التنزيل ---
        final localPath = downloadedFile.path;
        if (kDebugMode) debugPrint("[MessageRepository] Media ($messageId) downloaded successfully to: $localPath");

        // تحديث المسار المحلي والحالة إلى 'received' في قاعدة البيانات المحلية
        await _localDbService.updateLocalPathAndStatus(messageId, localPath, MessageStatus.received); // تحتاج لإضافة هذه الدالة لخدمة DB

      } else {
        // --- حالة فشل التنزيل (لم يتم إرجاع ملف أو الملف غير موجود) ---
        if (kDebugMode) debugPrint("!!! [MessageRepository] Media download failed for ($messageId): downloadedFile is null or doesn't exist.");
        await _localDbService.updateMessageStatus(messageId, MessageStatus.downloadFailed);
      }

    } catch (e, stackTrace) {
      // --- حالة خطأ أثناء التنزيل ---
      if (kDebugMode) {
        debugPrint("!!! [MessageRepository] Error downloading media for ($messageId): $e\n$stackTrace");
      }
      await _localDbService.updateMessageStatus(messageId, MessageStatus.downloadFailed);
    }
  }

  // --- 5. وظائف إعادة المحاولة (Retry Functions) ---

  /// إعادة محاولة إرسال رسالة فشلت سابقًا.
  Future<void> retrySending(String messageId) async {
    if (kDebugMode) debugPrint("[MessageRepository] Retrying send for message ($messageId)...");


    getMessageByIdFromLocal( messageId);
    // 1. جلب بيانات الرسالة الحالية من قاعدة البيانات المحلية
    final Message? messageToRetry = await _localDbService.getMessageById(messageId,currentUserId); // ستحتاج لهذه الدالة

    if (messageToRetry == null) {
      if (kDebugMode) debugPrint("!!! [MessageRepository] Cannot retry send: Message ($messageId) not found locally.");
      return;
    }

    // تحقق من أنها فعلاً في حالة فشل أو ربما pending لفترة طويلة
    if (messageToRetry.status != MessageStatus.failed && messageToRetry.status != MessageStatus.pending) {
      if (kDebugMode) debugPrint("[MessageRepository] Skipping retry for message ($messageId): Status is ${messageToRetry.status.name}, not failed/pending.");
      return; // لا تعيد إرسال رسالة قيد الإرسال أو تم إرسالها بالفعل
    }

    // 2. "إعادة إرسالها" باستخدام نفس منطق sendMessage تقريبًا
    // يمكن تحسين هذا بإنشاء دالة إرسال داخلية منفصلة لتجنب تكرار الكود.

    File? fileToUpload;
    if (messageToRetry.type != FirestoreConstants.typeText && messageToRetry.localFilePath != null) {
      fileToUpload = File(messageToRetry.localFilePath!);
      // تأكد من أن الملف لا يزال موجودًا
      if(!await fileToUpload.exists()){
        if(kDebugMode) debugPrint("!!! [MessageRepository] Cannot retry send for media message ($messageId): Local file '${messageToRetry.localFilePath}' not found.");
        await _localDbService.updateMessageStatus(messageId, MessageStatus.failed); // التأكيد على الفشل
        Get.snackbar("خطأ", "ملف الوسائط الأصلي غير موجود.", snackPosition: SnackPosition.BOTTOM);
        return;
      }
    }
    // إعادة إنشاء الصورة المصغرة؟ الأفضل هو تخزين مسارها المحلي إذا أمكن،
    // أو الاعتماد على التي تم رفعها مسبقًا إذا فشل فقط تحديث Firestore.
    File? thumbnailFile; // يجب تحديد هذا بناءً على كيفية معالجة المصغرات



    // إعادة استخدام منطق الإرسال الأساسي
    await _resendMessageInternal(messageToRetry, fileToUpload, thumbnailFile);

  }

  /// دالة داخلية لإعادة استخدام منطق الإرسال
  Future<void> _resendMessageInternal(Message messageToResend, File? fileToUpload, File? thumbnailFile) async {
    final messageId = messageToResend.messageId;
    try {
      await _localDbService.updateMessageStatus(messageId, MessageStatus.sending);
      if (kDebugMode) debugPrint("[MessageRepository] Retrying send: Updated status to sending for $messageId.");

      final UploadResult result = await _firebaseService.uploadAndWriteMessage(
        messageToResend,
        fileToUpload: fileToUpload,
        thumbnailFile: thumbnailFile,
          senderName: currentUserName // <--- تمرير اسم المستخدم هنا

      );

      if (result.success) {
        if (kDebugMode) debugPrint("[MessageRepository] Retry send successful for $messageId.");
        await _localDbService.updateMessageStatus(messageId, MessageStatus.sent);
        if (messageToResend.type != FirestoreConstants.typeText && (result.contentUrl != null || result.thumbnailUrl != null)) {
          final Map<String, dynamic> updates = {};
          if (result.contentUrl != null && messageToResend.content != result.contentUrl) updates['content'] = result.contentUrl;
          if (result.thumbnailUrl != null && messageToResend.thumbnailUrl != result.thumbnailUrl) updates['thumbnailUrl'] = result.thumbnailUrl;
          if(updates.isNotEmpty) {
            await _localDbService.updateMessageFields(messageId, updates);
          }
        }
      } else {
        if (kDebugMode) debugPrint("!!! [MessageRepository] Retry send failed for $messageId.");
        await _localDbService.updateMessageStatus(messageId, MessageStatus.failed);
      }
    } catch (e, stackTrace) {
      if (kDebugMode) debugPrint("!!! [MessageRepository] Error during retry send for $messageId: $e\n$stackTrace");
      await _localDbService.updateMessageStatus(messageId, MessageStatus.failed);
    }
  }

  /// إعادة محاولة تنزيل وسائط فشل تنزيلها.
  Future<void> retryDownload(String messageId) async {
    if (kDebugMode) debugPrint("[MessageRepository] Retry download requested for ($messageId)...");
    final Message? messageToRetry = await getMessageByIdFromLocal(messageId);
    if (messageToRetry == null || messageToRetry.type == FirestoreConstants.typeText || messageToRetry.content.isEmpty || !messageToRetry.content.startsWith('http') || messageToRetry.status != MessageStatus.downloadFailed) { return; }

    // إضافة للطابور مجددًا
    await _localDbService.updateMessageStatus(messageId, MessageStatus.downloading);
    _queueForDownload(messageId: messageId, url: messageToRetry.content, type: DownloadType.mainFile);
    // يمكنك إضافة المصغرة للطابور هنا أيضاً إذا كان thumbnailUrl موجود ولم يتم تنزيل المصغرة بعد
    if (messageToRetry.thumbnailUrl?.isNotEmpty ?? false) {
      _queueForDownload(messageId: messageId, url: messageToRetry.thumbnailUrl!, type: DownloadType.thumbnail);
    }
  }


  // --- دوال مساعدة ---
  String _getFileExtension(String url, String messageType) {
    // محاولة استنتاج الامتداد من URL أو النوع
    try {
      final uri = Uri.parse(url);
      String path = uri.path;
      if (path.contains('.')) {
        String ext = path.substring(path.lastIndexOf('.') + 1).toLowerCase();
        // قد تحتاج لـ query parameters cleanup
        if(ext.contains('?')) ext = ext.substring(0, ext.indexOf('?'));
        if (ext.length <= 4 && ext.isNotEmpty) return ext; // امتداد معقول
      }
    } catch (_) {}

    // قيمة افتراضية بناءً على النوع إذا فشل الاستنتاج من الرابط
    switch (messageType) {
      case FirestoreConstants.typeImage: return 'jpg'; // أو png
      case FirestoreConstants.typeVideo: return 'mp4'; // افتراضي
      case FirestoreConstants.typeAudio: return 'm4a'; // أو m4a أو غيره
      default: return 'tmp';
    }
  }

// --- قد تحتاج أيضًا لدوال مثل: ---
// Future<void> updateMessageReadStatusRemotely(...) // لتحديث حالة القراءة في Firestore
// Future<void> deleteMessageLocally(String messageId)
// Future<void> deleteMessageForEveryone(String messageId) // منطق أكثر تعقيدًا

}
