import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // for kDebugMode
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:video_compress/video_compress.dart';
import 'package:uuid/uuid.dart'; // <-- استيراد Uuid

// قم بتعديل المسارات التالية بناءً على هيكل مشروعك الفعلي
import '../../bottonBar/Get2/Get2.dart';
import 'ChatService.dart'; // تأكد من صحة هذا المسار
import 'FirestoreConstants.dart'; // تأكد من صحة هذا المسار
import 'LocalDatabaseService2GetxService.dart';
import 'Message.dart';
import 'MessageRepository.dart';
import 'MessageStatus.dart';
// <-- تأكد من صحة هذا المسار واستيراد شاشة العرض


class ChatController extends GetxController with WidgetsBindingObserver {
  final String recipientId;
  final int chatScreenTabIndexInBottomBar; // يجب تمريره أو تحديده

  ChatController({required this.recipientId, required this.chatScreenTabIndexInBottomBar});

  final Uuid _uuid = const Uuid(); // <-- تعريف متغير Uuid

  // استخدم Get.find للبحث عن الخدمات التي تم حقنها مسبقًا
  // تأكد من حقن ChatService في مكان ما قبل استخدام ChatController
  // مثال: Get.put(ChatService()); في ملف main.dart أو ملف تهيئة الربط (bindings)
  final MessageRepository _messageRepository = Get.find<MessageRepository>();
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final FocusNode focusNode = FocusNode();
// هذا يجعل التحديث أكثر مباشرة ووضوحًا لـ Obx
  final RxBool _canSendMessageInternal = false.obs;
  bool get canSendMessage => _canSendMessageInternal.value;
  final Rx<Message?> messageBeingEdited = Rx<Message?>(null);
  bool get isEditingMessage => messageBeingEdited.value != null;
  // --- Recipient Info ---
  final Rx<Map<String, dynamic>?> recipientData = Rx<Map<String, dynamic>?>(null);
  // استخدام Getters لتبسيط الوصول وتوفير قيم افتراضية
  String get recipientName => recipientData.value?[UserField.name] as String? ?? "Loading...";
  String get recipientProfilePic => recipientData.value?[UserField.profilePic] as String? ?? '';
  final Rx<Message?> currentlyQuotedMessage = Rx<Message?>(null);

  bool get isReplying => currentlyQuotedMessage.value != null;
  // --- UI State ---
  final RxBool _isLoading = false.obs;
  final RxBool _isSending = false.obs;
  final RxBool _isRecording = false.obs;
  final RxBool _isRecordDeleting = false.obs;
  final Rx<Duration> _recordingDuration = Duration.zero.obs;
  final RxBool _isKeyboardVisible = false.obs;
  final Rx<File?> _mediaPreviewFile = Rx<File?>(null);
  final Rx<Uint8List?> _imagePreviewData = Rx<Uint8List?>(null);
  final Rx<String?> _mediaPreviewType = Rx<String?>(null);
  final RxBool isRecipientTyping = false.obs;
  Timer? _typingTimer; // لتأخير إرسال "توقف عن الكتابة"
  Timer? _typingListenerResetTimer; // لتصفير حالة الكتابة إذا لم تصل تحديثات لفترة
  final bool _amCurrentlyTyping = false; // لتتبع حالتي أنا
  StreamSubscription? _recipientTypingSubscription;
  // المسار لوثيقة حالة الكتابة في Firestore (من منظور هذا المستخدم)
  // حيث {currentUserId} هو أنا، و {recipientId} هو الطرف الآخر
  // سأستمع للمسار: Chat/{recipientId}/chat/{currentUserId}/typing_status
  // وسأكتب للمسار: Chat/{currentUserId}/chat/{recipientId}/typing_status
  DocumentReference? _myTypingStatusRef;
  DocumentReference? _recipientTypingStatusRef;
  // --- Getters for simpler UI access ---
  bool get isLoading => _isLoading.value;
  bool get isSending => _isSending.value;
  bool get isRecording => _isRecording.value;
  bool get isRecordDeleting => _isRecordDeleting.value;
  Duration get recordingDuration => _recordingDuration.value;
  bool get isKeyboardVisible => _isKeyboardVisible.value;
  File? get mediaPreviewFile => _mediaPreviewFile.value;
  Uint8List? get imagePreviewData => _imagePreviewData.value;
  String? get mediaPreviewType => _mediaPreviewType.value;
  bool get showMediaPreview => _mediaPreviewFile.value != null || _imagePreviewData.value != null;
  // canSendMessage يعتمد الآن على حقل النص أو وجود معاينة للوسائط
  // bool get canSendMessage => messageController.text.trim().isNotEmpty || showMediaPreview;
  String get currentUserId => Get.find<ChatService>().currentUserId; // TODO: Refactor this dependency
  final RxBool isScreenActive = false.obs;
  StreamSubscription? _bottomBarIndexSubscription;
  StreamSubscription? _sentMessagesReadStatusSubscription; // <--- أضف هذا
  final RxString currentWallpaperPath = ''.obs; // مسار الصورة، أو قيمة خاصة للألوان/الافتراضي
  final GetStorage _storage = GetStorage(); // صندوق تخزين عام أو مخصص
  final String _wallpaperStorageKey = 'chat_wallpaper_path'; // مفتاح التخزين
  StreamSubscription? _localMessagesListenerForMarkingRead; // للمستلم

  // --- Recording specific ---
  final AudioRecorder _audioRecorder = AudioRecorder();
  Timer? _recordingTimer;
  String? _recordingPath;
  Offset _longPressStartOffset = Offset.zero;

  // --- Media Picking ---
  final ImagePicker _picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    try {
      final Get2 bottomBarLogic = Get.find<Get2>();
      _listenToBottomBarChanges(bottomBarLogic);
      // التحقق من الحالة الأولية عند تهيئة المتحكم
      // يتم الآن تعيين isScreenActive.value مباشرة عند بداية _updateScreenActiveState
      _updateScreenActiveState(bottomBarLogic.selectedIndex.value);
    } catch (e) {
      if (kDebugMode) {
        debugPrint("!!! [ChatController - $recipientId] Could not find Get2 instance. "
            "isScreenActive logic relying on BottomBar index might be affected. Error: $e");
      }
      // في حالة عدم العثور على Get2، أو إذا كان `chatScreenTabIndexInBottomBar`
      // غير متوفر بشكل صحيح (مثلاً -1)، فإن السلوك الافتراضي يجب أن يكون
      // أن الشاشة ليست نشطة حتى يتم تفعيلها بطريقة أخرى.
      // أو، إذا كانت ChatScreen تُفتح دائمًا بطريقة مباشرة (Get.to) وليس كجزء من تبويب ثابت في BottomBar،
      // يمكن تعيينها true هنا.
      // حاليًا، بما أن chatScreenTabIndexInBottomBar مُعرف كـ final ومطلوب في المنشئ،
      // فلن يكون null. إذا فشل Get.find<Get2>()، فإن المستمع لن يعمل.
      // الأمان هنا هو تركها false إذا فشل الربط بالـ BottomBar،
      // والاعتماد على `WidgetsBindingObserver` و `onResume` كآلية ثانوية لتفعيلها إذا كانت هي المسار الحالي.
      // أو يمكنك تعيينها إلى true كالسلوك السابق، مع العلم أنها قد تسبب تعليم الرسائل كمقروءة.
      // دعنا نجعلها false إذا فشل Get.find، وسنرى كيف يتصرف WidgetsBindingObserver.
      if (Get.isRegistered<Get2>()) { // تحقق إذا كان مسجلاً قبل محاولة find
        // _updateScreenActiveState سيتم استدعاؤه إذا وجدناه
      } else {
        // لم يتم العثور على Get2، ربما الشاشة فُتحت بطريقة لا تتضمن BottomBar
        // أو هناك مشكلة في تهيئة Get2.
        // كحل احتياطي، نجعلها true، مع العلم بالمشكلة المحتملة إذا بقيت الشاشة حية في IndexedStack
        isScreenActive.value = true; // السلوك الكلاسيكي كاحتياطي
        if (kDebugMode) debugPrint("  [ChatController $recipientId] Get2 not found, isScreenActive defaulted to true.");
      }

    }
    WidgetsBinding.instance.addObserver(this);


    _loadChatWallpaper(); // <--- تحميل الخلفية عند تهيئة المتحكم

    if (kDebugMode) debugPrint("[ChatController] Initializing for recipient: $recipientId");
    _fetchRecipientData();
    _listenToKeyboard();
    _setupStateListeners(); // تجميع المستمعين للحالة
    _initTypingStatusReferences();
    _listenToRecipientTypingStatus();
    isScreenActive.value = true; // عند تهيئة المتحكم، الشاشة نشطة
    // استمع لتيار الرسائل المحلي
    if (currentUserId.isNotEmpty && recipientId.isNotEmpty) {
      _listenForReadReceipts(); // <--- استدعاء دالة الاستماع الجديدة
    }

    // ChatController.dart (للمستلم)

// ... داخل onInit أو مستمع الرسائل المحلية
    _sentMessagesReadStatusSubscription = Get.find<MessageRepository>().getMessages(recipientId).listen((messages) {
      if (isScreenActive.value && messages.isNotEmpty) {
        // --- طباعة مكثفة هنا ---
        if (kDebugMode) {
          debugPrint("--------------------------------------------------------------------");
          debugPrint("[ChatCtrl المستلم - $recipientId] Local messages listener triggered. isScreenActive: $isScreenActive");
          debugPrint("[ChatCtrl المستلم - $recipientId] Total messages in local stream: ${messages.length}");
        }

        final unreadFromOther = messages.where((m) {
          // اطبع تفاصيل كل رسالة يتم فحصها
          // if (kDebugMode) {
          //   debugPrint("  [Msg Check] ID: ${m.messageId}, isMe: ${m.isMe}, Status: ${m.status}, FirestoreIsRead (إذا كان متاحًا كحقل): ${m.firestoreIsReadField}");
          // }
          return !m.isMe && m.status != MessageStatus.read; // أو الشرط الأدق بناءً على حقل isRead الفعلي في كائن Message
        }).toList();

        if (kDebugMode) {
          debugPrint("[ChatCtrl المستلم - $recipientId] Found ${unreadFromOther.length} unread messages from sender $recipientId (الطرف الآخر).");
          if (unreadFromOther.isNotEmpty) {
            for (var msg in unreadFromOther) {
              debugPrint("    -> Unread Msg ID: ${msg.messageId}, Sender: ${msg.senderId}, Content: ${msg.content.substring(0, (msg.content.length > 20 ? 20 : msg.content.length))}");
            }
          }
        }
        // --- نهاية الطباعة المكثفة ---

        if (unreadFromOther.isNotEmpty) {
          markMessagesAsRead(unreadFromOther);
        }
      }
    });
    // عند تغيير النص في حقل الإدخال
    // بدء الاستماع للرسائل الجديدة الواردة من Firebase عبر المستودع
    // _messageRepository.initializeMessageListener(recipientId);

    if (_messageRepository.currentUserId.isNotEmpty) { // تحقق أن currentUserId في الريبو ليس فارغًا
      _messageRepository.triggerCatchUpSyncIfNeeded(recipientId);
    } else {
      if (kDebugMode) debugPrint("!!! [ChatController onInit] MessageRepository's currentUserId is empty. Cannot trigger sync.");
    }
  }

  @override
  void onClose() {
    if (kDebugMode) debugPrint("[ChatController] Closing for recipient: $recipientId");
    // إيقاف المستمع للرسائل الواردة
    // _messageRepository.cancelMessageListener();
    // التخلص من الموارد لتجنب تسرب الذاكرة
    _bottomBarIndexSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _localMessagesListenerForMarkingRead?.cancel();

    isScreenActive.value = false;
    _sentMessagesReadStatusSubscription?.cancel(); // <--- لا تنسَ إلغاء الاشتراك
    // ...
    messageController.removeListener(updateCanSendMessageState);
    messageController.dispose();
    scrollController.dispose();
    focusNode.dispose();
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    _mediaPreviewFile.value = null;
    _imagePreviewData.value = null;
    VideoCompress.cancelCompression(); // إلغاء أي ضغط فيديو مستمر
    cancelQuotedMessage(); // تأكد من مسح الرد عند إغلاق المتحكم

    super.onClose();
  }




  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (kDebugMode) debugPrint("[ChatCtrl - $recipientId] AppLifecycleState changed: $state. Current isScreenActive: ${isScreenActive.value}");

    // هذا الكود يعتمد على أن BottomBar index هو المصدر الرئيسي لتحديد نشاط الشاشة المتعلق بالتبويب.
    // AppLifecycleState تتعامل مع حالات التطبيق ككل (مقدمة/خلفية).
    final Get2? bottomBarLogic = Get.isRegistered<Get2>() ? Get.find<Get2>() : null;
    final int currentBottomBarIdx = bottomBarLogic?.selectedIndex.value ?? -1; // -1 إذا لم يتم العثور على BottomBar

    if (state == AppLifecycleState.resumed) {
      if (currentBottomBarIdx == chatScreenTabIndexInBottomBar) { // هل تبويب الدردشة هو النشط؟
        if (!isScreenActive.value) {
          isScreenActive.value = true;
          if (kDebugMode) debugPrint("  [ChatCtrl - $recipientId] App RESUMED & screen became ACTIVE (was inactive). BottomBarIdx: $currentBottomBarIdx");
          _setupMessageListenerForMarkingReadIfNeeded();
          _messageRepository.triggerCatchUpSyncIfNeeded(recipientId);
        } else {
          if (kDebugMode) debugPrint("  [ChatCtrl - $recipientId] App RESUMED. Screen was already active. BottomBarIdx: $currentBottomBarIdx");
        }
      } else {
        // التطبيق عاد للمقدمة ولكن على تبويب مختلف.
        if (isScreenActive.value) { // إذا كانت شاشة الدردشة هذه نشطة بالخطأ
          isScreenActive.value = false;
          if (kDebugMode) debugPrint("  [ChatCtrl - $recipientId] App RESUMED on a DIFFERENT tab ($currentBottomBarIdx). Deactivating this chat screen.");
        }
      }
    } else if (state == AppLifecycleState.paused) {
      if (isScreenActive.value) { // إذا كانت شاشة الدردشة هذه نشطة عندما ذهب التطبيق للخلفية
        isScreenActive.value = false;
        if (kDebugMode) debugPrint("  [ChatCtrl - $recipientId] App PAUSED while this screen was active. Setting inactive. BottomBarIdx: $currentBottomBarIdx");
        _localMessagesListenerForMarkingRead?.pause();
      }
    }
  }


  void _listenToBottomBarChanges(Get2 bottomBarLogic) {
    _bottomBarIndexSubscription = bottomBarLogic.selectedIndex.stream.listen((newIndex) {
      _updateScreenActiveState(newIndex);
    });
  }

  void _updateScreenActiveState(int currentBottomBarIndex) {
    final bool shouldBeActive = (currentBottomBarIndex == chatScreenTabIndexInBottomBar);

    if (shouldBeActive) {
      if (!isScreenActive.value) {
        isScreenActive.value = true;
        if (kDebugMode) debugPrint("  [ChatCtrl - $recipientId] Screen became ACTIVE via BottomBar index ($currentBottomBarIndex). Triggering message processing.");
        // عند العودة إلى هذا التبويب، قد تحتاج إلى "إعادة تشغيل" بعض العمليات
        _messageRepository.triggerCatchUpSyncIfNeeded(recipientId); // جلب أي رسائل فائتة
        _setupMessageListenerForMarkingReadIfNeeded(); // تأكد أن مستمع تعليم القراءة نشط
        // ChatScreen ستستخدم addPostFrameCallback لـ markAsRead
      }
    } else {
      if (isScreenActive.value) {
        isScreenActive.value = false;
        if (kDebugMode) debugPrint("  [ChatCtrl - $recipientId] Screen became INACTIVE via BottomBar index ($currentBottomBarIndex).");
        _localMessagesListenerForMarkingRead?.pause(); // إيقاف مؤقت للمستمع إذا لم تعد الشاشة نشطة
      }
    }
  }

  void _setupMessageListenerForMarkingReadIfNeeded() {
    if (!isScreenActive.value) { // لا تقم بإعداد المستمع إذا كانت الشاشة غير نشطة
      _localMessagesListenerForMarkingRead?.cancel();
      _localMessagesListenerForMarkingRead = null;
      return;
    }

    if (_localMessagesListenerForMarkingRead == null || (_localMessagesListenerForMarkingRead?.isPaused ?? false) ) {
      _localMessagesListenerForMarkingRead?.cancel(); // ألغ القديم قبل الجديد
      _localMessagesListenerForMarkingRead = Get.find<MessageRepository>()
          .getMessages(recipientId)
          .listen((messages) {
        // لا يتم تعليم الرسائل كمقروءة هنا مباشرة، بل من ChatScreen.
        // هذا المستمع فقط لضمان تحديث قائمة messages التي يعتمد عليها StreamBuilder في ChatScreen.
        // ويمكن لـ ChatScreen استدعاء controller.triggerMarkReadForVisibleMessages() إذا أردت.
        if (kDebugMode && isScreenActive.value) { // اطبع فقط إذا كانت الشاشة نشطة
          // debugPrint("  [ChatCtrl $recipientId] Local messages updated in controller: ${messages.length} items. Screen active.");
        }
      }, onError: (e){
        if (kDebugMode) debugPrint("  !!! [ChatCtrl $recipientId] Error in local messages listener for marking read: $e");
      });
      if (kDebugMode) debugPrint("  [ChatCtrl $recipientId] Setup/Resumed local messages listener for marking read.");
    }
  }


  void _loadChatWallpaper() {
    try {
      final String? savedPath = _storage.read<String>(_wallpaperStorageKey);
      if (savedPath != null && savedPath.isNotEmpty) {
        currentWallpaperPath.value = savedPath;
        if (kDebugMode) debugPrint("[ChatController - $recipientId] Loaded wallpaper path: $savedPath");
      } else {
        // لا توجد خلفية محفوظة، استخدم الافتراضي (يمكن تمثيله بسلسلة فارغة أو null)
        currentWallpaperPath.value = ''; // أو يمكنك تعيين مسار خلفية افتراضية مدمجة
        if (kDebugMode) debugPrint("[ChatController - $recipientId] No saved wallpaper, using default.");
      }
    } catch (e) {
      if (kDebugMode) debugPrint("!!! [ChatController - $recipientId] Error loading wallpaper: $e");
      currentWallpaperPath.value = ''; // العودة للافتراضي عند الخطأ
    }
  }

  // دالة لتغيير الخلفية (يتم استدعاؤها من شاشة الإعدادات مثلاً)
  Future<void> changeChatWallpaper(String? newPath) async {
    if (newPath != null && newPath.isNotEmpty) {
      // هنا يجب نسخ الصورة المختارة (إذا كانت من المعرض) إلى مساحة تخزين دائمة للتطبيق
      // ثم حفظ مسارها الجديد الدائم. لنفترض أن newPath هو بالفعل المسار الدائم.
      await _storage.write(_wallpaperStorageKey, newPath);
      currentWallpaperPath.value = newPath;
      if (kDebugMode) debugPrint("[ChatController - $recipientId] Wallpaper changed to: $newPath");
    } else {
      // تم اختيار إزالة الخلفية أو العودة للافتراضي
      await _storage.remove(_wallpaperStorageKey);
      currentWallpaperPath.value = '';
      if (kDebugMode) debugPrint("[ChatController - $recipientId] Wallpaper removed, back to default.");
    }
  }
// --- نهاية متغيرات ودوال الخلفية ---


  Future<void> manualSync() async {
    Get.snackbar("مزامنة", "جاري مزامنة الرسائل...", snackPosition: SnackPosition.BOTTOM, duration: Duration(seconds: 2));
    if (_messageRepository.currentUserId.isNotEmpty) {
      await _messageRepository.triggerCatchUpSyncIfNeeded(recipientId, forceSync: true);
      Get.snackbar("مزامنة", "تمت محاولة المزامنة.", snackPosition: SnackPosition.BOTTOM, duration: Duration(seconds: 3));
    } else {
      Get.snackbar("خطأ", "لا يمكن المزامنة، خطأ في تحديد المستخدم.", snackPosition: SnackPosition.BOTTOM);
    }
  }
// داخل كلاس ChatController

  String get quotedMessagePreviewText {
    if (currentlyQuotedMessage.value == null) return "";
    final quoted = currentlyQuotedMessage.value!;
    if (quoted.type == FirestoreConstants.typeText) {
      return quoted.content.length > 50
          ? '${quoted.content.substring(0, 47)}...'
          : quoted.content;
    } else if (quoted.type == FirestoreConstants.typeImage) {
      return '📷 صورة';
    } else if (quoted.type == FirestoreConstants.typeVideo) {
      return '📹 فيديو';
    } else if (quoted.type == FirestoreConstants.typeAudio) {
      return '🎤 رسالة صوتية';
    }
    return 'رسالة'; // افتراضي
  }



  // اسم مرسل الرسالة المقتبسة (قد تحتاج لجلبه إذا لم يكن مخزنًا بشكل جيد)
  // الأفضل أن يكون senderName جزءًا من Message object أو يمكن جلبه بسرعة.
  // سنفترض مؤقتًا أنك ستعرض senderId إذا لم يكن الاسم متاحًا بسهولة في quotedMessage
  // أو أنك ستقوم بجلب اسم مرسل الرسالة المقتبسة عند تحديدها.
  // لجعل الأمر أبسط الآن، سنفترض أن الرسالة المقتبسة تحتوي على اسم مرسلها
  // (ستحتاج لضمان ذلك عند جلبها لعرضها في قائمة الرسائل)
  // String get quotedMessageSenderName => currentlyQuotedMessage.value?.senderName ?? "Unknown"; // تحتاج لتعديل Message إذا أضفت senderName

  // دالة لتحديد رسالة للرد عليها
  void setQuotedMessage(Message messageToQuote) {
    // يمكنك هنا جلب اسم المرسل للرسالة المقتبسة إذا لم يكن مدمجًا
    // final senderData = await _messageRepository.getUserData(messageToQuote.senderId);
    // messageToQuote = messageToQuote.copyWith(senderName: senderData?['name']); // مثال
    currentlyQuotedMessage.value = messageToQuote;
    focusNode.requestFocus(); // إعادة التركيز على حقل الإدخال
  }

  // دالة لإلغاء الرد الحالي
  void cancelQuotedMessage() {
    currentlyQuotedMessage.value = null;
  }
  // --- نهاية إضافات حالة الرد ---

  // --- [جديد] دوال حالة الكتابة ---
  void _initTypingStatusReferences() {
    // تأكد أن currentUserId (من ChatService أو مصدر موثوق) متاح
    final myId = currentUserId; // افترض أنه موجود كـ getter في ChatController
    if (myId.isEmpty || recipientId.isEmpty) {
      if(kDebugMode) debugPrint("!!! [Typing] Cannot init typing refs: User ID or Recipient ID is empty.");
      return;
    }
    // المسار الذي سأكتب فيه حالتي (ليراها الطرف الآخر)
    _myTypingStatusRef = FirebaseFirestore.instance
        .collection(FirestoreConstants.chatCollection).doc(myId)
        .collection(FirestoreConstants.chatSubCollection).doc(recipientId)
        .collection('typing_status').doc(myId); // استخدم ID الخاص بي كمعرف للوثيقة

    // المسار الذي سأستمع منه لحالة الطرف الآخر
    _recipientTypingStatusRef = FirebaseFirestore.instance
        .collection(FirestoreConstants.chatCollection).doc(recipientId)
        .collection(FirestoreConstants.chatSubCollection).doc(myId)
        .collection('typing_status').doc(recipientId); // استمع لوثيقة بمعرف الطرف الآخر
  }


// دالة لبدء تعديل رسالة
  void startEditMessage(Message messageToEdit) {
    if (messageToEdit.type == FirestoreConstants.typeText) {
      messageBeingEdited.value = messageToEdit;
      messageController.text = messageToEdit.content; // املأ حقل الإدخال بالنص الحالي
      focusNode.requestFocus();
    }
  }

  // دالة لإلغاء التعديل الحالي
  void cancelEditMessage() {
    messageBeingEdited.value = null;
    messageController.clear(); // امسح حقل الإدخال
  }





  // --- دوال الحذف الجديدة ---
  Future<void> deleteMessageForMe(String messageId) async {
    if (kDebugMode) debugPrint("[ChatCtrl] Deleting message $messageId FOR ME.");
    try {
      await _messageRepository.deleteMessageLocally(messageId, currentUserId, recipientId);
      // الواجهة يجب أن تُحدّث تلقائيًا بسبب التغيير في Stream المحلي
    } catch (e) {
      Get.snackbar("خطأ", "فشل حذف الرسالة محليًا: $e");
    }
  }

  Future<void> deleteMessageForEveryone(Message messageToDelete) async {
    if (kDebugMode) debugPrint("[ChatCtrl] Deleting message ${messageToDelete.messageId} FOR EVERYONE.");
    try {
      // (التحقق من الحد الزمني يمكن أن يكون هنا أو في المستودع)
      await _messageRepository.deleteMessageForEveryone(
          message: messageToDelete,
          recipientId: recipientId, // الطرف الآخر
          // currentUserName ضروري للمستودع لمعرفة اسم مرسل ملخص الرسالة "المحذوفة"
          currentUserName: Get.find<MessageRepository>().currentUserName
      );
    } catch (e) {
      Get.snackbar("خطأ", "فشل حذف الرسالة لدى الجميع: $e");
    }
  }
  final _firestore = FirebaseFirestore.instance;
// ChatController.dart

  // ChatController.dart (أو يمكن نقلها لـ MessageRepository إذا كانت أعم)
  Future<void> _checkAndUpdateOverallUnreadStatus(String myId) async {
    if (myId.isEmpty) {
      if (kDebugMode) debugPrint("[_checkUnread $myId] myId is empty. Skipping check.");
      return;
    }
    if (kDebugMode) debugPrint("==> [_checkUnread $myId] Checking overall unread status for user document ==");

    try {
      QuerySnapshot unreadSummariesSnapshot = await FirebaseFirestore.instance
          .collection(FirestoreConstants.chatCollection).doc(myId)
          .collection(FirestoreConstants.chatSubCollection)
          .where(FirestoreConstants.isRead, isEqualTo: false)
          .where(FirestoreConstants.senderId, isNotEqualTo: myId) // رسائل من الآخرين فقط
          .limit(1) // يكفي العثور على واحدة فقط لنعرف أن هناك غير مقروء
          .get(const GetOptions(source: Source.server)); // جلب أحدث البيانات من الخادم

      DocumentReference myUserDocRef = FirebaseFirestore.instance
          .collection(FirestoreConstants.userCollection).doc(myId);

      final bool hasUnread = unreadSummariesSnapshot.docs.isNotEmpty;
      if (kDebugMode) debugPrint("    [_checkUnread $myId] Found ${unreadSummariesSnapshot.docs.length} unread chat summaries from others. Should set hasUnreadMessages to: $hasUnread");

      await myUserDocRef.set({'hasUnreadMessages': hasUnread}, SetOptions(merge: true)); // استخدم set مع merge لإنشاء الحقل إذا لم يكن موجودًا

      if (kDebugMode) debugPrint("  ✅ [_checkUnread $myId] Updated 'hasUnreadMessages' field in Usercodora/$myId to: $hasUnread");

    } catch (e, s) {
      if (kDebugMode) {
        debugPrint("  ❌❌❌ [_checkUnread $myId] Error updating 'hasUnreadMessages'!");
        debugPrint("        Error: $e");
        debugPrint("        StackTrace: $s");
      }
    }
    if (kDebugMode) debugPrint("<== [_checkUnread $myId] Finished checking overall unread status ==>");
  }


  Future<void> markMessagesAsRead(List<Message> messages) async {
    final String myId = currentUserId;
    final String otherUserId = recipientId;

    if (otherUserId.isEmpty || myId.isEmpty) {
      if (kDebugMode) debugPrint("[ChatCtrl $myId] markMessagesAsRead: Invalid myId or otherUserId. Skipping.");
      return;
    }

    // لا داعي لمعالجة قائمة رسائل فارغة إذا لم تكن ستفحص الملخص بشكل مستقل
    // if (messages.isEmpty) {
    //   if (kDebugMode) debugPrint("[ChatCtrl $myId] markMessagesAsRead: messages list is empty. Checking summary only.");
    //   // سنصل إلى فحص الملخص أدناه على أي حال
    // } else {
    if (kDebugMode) debugPrint("[ChatCtrl $myId] markMessagesAsRead: Processing ${messages.length} messages FROM sender $otherUserId.");
    // }


    WriteBatch batch = FirebaseFirestore.instance.batch();
    List<String> messageIdsSuccessfullyQueuedForIndividualUpdate = []; // تغيير الاسم ليكون أوضح
    bool anyOperationQueuedInBatch = false; // لتتبع ما إذا كان الـ batch يحتوي على أي شيء

    // 1. تحديث isRead للرسائل الفردية
    if (messages.isNotEmpty) {
      for (var message in messages) {
        if (message.messageId.isEmpty) {
          if (kDebugMode) debugPrint("  [ChatCtrl $myId] Skipping message with EMPTY ID.");
          continue;
        }
        if (message.senderId == otherUserId && !message.isMe && message.status != MessageStatus.read) {
          // التحقق من وجود الوثائق قبل إضافتها للـ batch
          DocumentReference myInboxMessageRef = _firestore
              .collection(FirestoreConstants.chatCollection).doc(myId)
              .collection(FirestoreConstants.chatSubCollection).doc(otherUserId)
              .collection(FirestoreConstants.messagesSubCollection).doc(message.messageId);

          DocumentReference originalSenderOutboxMessageRef = _firestore
              .collection(FirestoreConstants.chatCollection).doc(otherUserId)
              .collection(FirestoreConstants.chatSubCollection).doc(myId)
              .collection(FirestoreConstants.messagesSubCollection).doc(message.messageId);

          bool recipientDocExists = false;
          bool senderDocExists = false;
          try {
            // لا تحتاج بالضرورة لـ Source.server هنا إذا كانت البيانات متزامنة بشكل جيد
            final recipientDocSnap = await myInboxMessageRef.get();
            recipientDocExists = recipientDocSnap.exists;
            final senderDocSnap = await originalSenderOutboxMessageRef.get();
            senderDocExists = senderDocSnap.exists;
          } catch (e) {
            if (kDebugMode) debugPrint("  ⚠️ [ChatCtrl $myId] Error during existence check for msg ${message.messageId} in markMessagesAsRead: $e");
            continue; // تخطى هذه الرسالة
          }

          if (recipientDocExists && senderDocExists) {
            batch.update(myInboxMessageRef, {FirestoreConstants.isRead: true});
            batch.update(originalSenderOutboxMessageRef, {FirestoreConstants.isRead: true});
            messageIdsSuccessfullyQueuedForIndividualUpdate.add(message.messageId);
            anyOperationQueuedInBatch = true;
            if (kDebugMode) debugPrint("    👍 [ChatCtrl $myId] Queued updates for BOTH copies of msg ${message.messageId}.");
          } else {
            if (kDebugMode) debugPrint("    ‼️ [ChatCtrl $myId] SKIPPING Firestore update for msg ${message.messageId} because one or both copies NOT FOUND (MyInbox: $recipientDocExists, SenderOutbox: $senderDocExists).");
          }
        }
      }
    }

    // 2. تحديث وثيقة ملخص المحادثة لدى المستخدم الحالي (المستلم)
    DocumentReference myChatSummaryRef = FirebaseFirestore.instance
        .collection(FirestoreConstants.chatCollection).doc(myId)
        .collection(FirestoreConstants.chatSubCollection).doc(otherUserId);

    bool summaryActuallyNeedsUpdate = false;
    try {
      final summarySnapshot = await myChatSummaryRef.get(const GetOptions(source: Source.server));
      if (summarySnapshot.exists) {
        final summaryData = summarySnapshot.data() as Map<String, dynamic>;
        // تحقق إذا كان الملخص "غير مقروء" (isRead is false OR isRead is null)
        // وأيضًا، إذا كان مرسل آخر رسالة في الملخص هو الطرف الآخر (حتى لا نعلّم محادثة نحن آخر من أرسل فيها كمقروءة هنا)
        if ((summaryData[FirestoreConstants.isRead] == false || summaryData[FirestoreConstants.isRead] == null) &&
            summaryData[FirestoreConstants.senderId] == otherUserId ) { // تأكد أن الطرف الآخر هو من أرسل آخر رسالة في الملخص
          summaryActuallyNeedsUpdate = true;
        }
      } else {
        if (kDebugMode) debugPrint("  [ChatCtrl $myId] Chat summary doc for chat with $otherUserId NOT FOUND. Cannot mark as read from here.");
      }
    } catch (e) {
      if (kDebugMode) debugPrint("  ⚠️ [ChatCtrl $myId] Error getting chat summary status: $e");
    }

    if (summaryActuallyNeedsUpdate) {
      batch.update(myChatSummaryRef, {FirestoreConstants.isRead: true});
      anyOperationQueuedInBatch = true;
      if (kDebugMode) debugPrint("  [ChatCtrl $myId] Queued update for MY CHAT SUMMARY with $otherUserId to isRead: true.");
    }


    // --- تنفيذ الـ Batch والتحديثات اللاحقة ---
    if (anyOperationQueuedInBatch) {
      if (kDebugMode) debugPrint("  [ChatCtrl $myId] Attempting Firestore batch (msgs: ${messageIdsSuccessfullyQueuedForIndividualUpdate.length}, summary needs update: $summaryActuallyNeedsUpdate)");
      try {
        await batch.commit();
        if (kDebugMode) debugPrint("  ✅ [ChatCtrl $myId] Firestore batch commit SUCCESSFUL for read receipts and/or summary.");

        // تحديث الرسائل الفردية محليًا
        for (String msgId in messageIdsSuccessfullyQueuedForIndividualUpdate) {
          await Get.find<LocalDatabaseService>().updateMessageFields(msgId, {'status': MessageStatus.read.name});
          // طباعة صغيرة هنا
        }
        if (messageIdsSuccessfullyQueuedForIndividualUpdate.isNotEmpty && kDebugMode) {
          debugPrint("    [ChatCtrl $myId] Local DB individual message statuses updated to read.");
        }

        // إذا تم تحديث أي شيء بنجاح في Firestore (إما رسائل أو ملخص)، تحقق من الحالة العامة للرسائل غير المقروءة
        await _checkAndUpdateOverallUnreadStatus(myId);

      } catch (e) {
        if (kDebugMode) { /* ... طباعة الخطأ للـ commit ... */ }
      }
    } else {
      if (kDebugMode) debugPrint("  [ChatCtrl $myId] No Firestore updates (individual messages or summary) were queued to be committed.");
      // حتى لو لم يكن هناك شيء لـ commit، إذا كان الملخص يحتاج تحديثًا ولم نتمكن من الحصول على حالته،
      // أو إذا كان موجودًا وهو مقروء بالفعل، فلا يزال يجب التأكد من hasUnreadMessages.
      // لكن بما أننا نقرأ الملخص أعلاه، هذا الشرط قد لا يكون ضروريًا هنا.
      // الأفضل التأكد بعد أي عملية تغيير محتملة.
      // إذا تم استدعاء markMessagesAsRead وكانت القائمة فارغة، هذا قد يعني أنه لا رسائل،
      // أو كلها مقروءة. _checkAndUpdateOverallUnreadStatus ستتعامل مع هذا.
      await _checkAndUpdateOverallUnreadStatus(myId); // استدعِ هذا أيضًا إذا لم يكن هناك عمليات commit
    }
    if (kDebugMode) debugPrint("----------------------- markMessagesAsRead END -------------------------");
  }

  void _listenForReadReceipts() {
    if (kDebugMode) debugPrint("  [ChatCtrl $recipientId] Initializing listener for read receipts on messages I sent.");

    // إلغاء أي اشتراك سابق لنفس المستلم (احتياطي)
    _sentMessagesReadStatusSubscription?.cancel();

    _sentMessagesReadStatusSubscription = FirebaseFirestore.instance
        .collection(FirestoreConstants.chatCollection)
        .doc(currentUserId) // صندوقي الصادر أنا (المرسل)
        .collection(FirestoreConstants.chatSubCollection)
        .doc(recipientId)   // المحادثة مع هذا المستلم
        .collection(FirestoreConstants.messagesSubCollection)
    // الاستماع فقط للرسائل التي أرسلتها أنا (senderId == currentUserId)
        .where(FirestoreConstants.senderId, isEqualTo: currentUserId)
    // والرسائل التي أصبحت isRead == true (لأنها كانت false ثم تغيرت)
        .where(FirestoreConstants.isRead, isEqualTo: true)
    // قد ترغب أيضًا في إضافة فلتر آخر، مثل أن تكون الرسالة أُرسلت خلال فترة معينة
    // أو أن حالتها المحلية ليست "read" بالفعل لتجنب معالجة غير ضرورية،
    // لكن الفلترة الأولية بـ isRead:true هي الأهم.
        .snapshots() // استمع للتغييرات الحية
        .listen((snapshot) {
      if (!isScreenActive.value) { // isScreenActive هو متغير bool يجب أن تديره في ChatController
        if (kDebugMode) debugPrint("  [ChatCtrl $recipientId] Read receipt listener received update, but screen is not active. Skipping immediate processing.");
        return;
      }

      if (kDebugMode) debugPrint("  [ChatCtrl $recipientId] Read receipt listener: Detected ${snapshot.docChanges.length} changes.");

      for (var change in snapshot.docChanges) {
        // نهتم بالتغييرات التي هي "إضافة" (إذا كانت الرسالة مقروءة عند الاستعلام أول مرة)
        // أو "تعديل" (إذا تغيرت isRead من false إلى true)
        if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
          if (kDebugMode) debugPrint("    [ChatCtrl $recipientId] Processing read receipt for msg ID: ${change.doc.id}");
          // --- هنا نستدعي الدالة في MessageRepository ---
          _messageRepository.processMessageUpdateFromFirestore(change.doc); // <--- الاستدعاء هنا
          // ---------------------------------------------
        }
      }
    }, onError: (error) {
      if (kDebugMode) debugPrint("!!! [ChatCtrl $recipientId] Error in read receipt listener: $error");
    });
  }




  void _listenToRecipientTypingStatus() {
    if (_recipientTypingStatusRef == null) return;
    _recipientTypingSubscription?.cancel(); // إلغاء أي استماع سابق

    _recipientTypingSubscription = _recipientTypingStatusRef!.snapshots().listen(
            (snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            final data = snapshot.data() as Map<String, dynamic>;
            final bool isTyping = data['isTyping'] ?? false;
            final String typingUser = data['typingUserId'] ?? '';

            // تأكد أن الحالة قادمة من الطرف الآخر المعني (وليس منك أنت بطريق الخطأ)
            if (typingUser == recipientId) {
              isRecipientTyping.value = isTyping;
              if (isTyping) {
                // إذا كان يكتب، قم بإعادة تعيين مؤقت لتصفير الحالة إذا لم تصل تحديثات
                _typingListenerResetTimer?.cancel();
                _typingListenerResetTimer = Timer(const Duration(seconds: 3), () { // بعد 3 ثوان من عدم وصول تحديث "يكتب"
                  if(isRecipientTyping.value) { // تحقق مرة أخرى قبل التصفير
                    isRecipientTyping.value = false;
                    if (kDebugMode) debugPrint("    [TypingListener] Recipient typing indicator TIMED OUT for $recipientId.");
                  }
                });
                if (kDebugMode) debugPrint("    [TypingListener] Recipient $recipientId IS TYPING.");
              } else {
                _typingListenerResetTimer?.cancel(); // إذا وصل "توقف عن الكتابة" ألغِ المؤقت
                if (kDebugMode) debugPrint("    [TypingListener] Recipient $recipientId STOPPED TYPING.");
              }
            }
          } else {
            // الوثيقة غير موجودة أو فارغة، يعني أنه لا يكتب
            if (isRecipientTyping.value) { // إذا كانت حالتنا السابقة هي "يكتب"
              isRecipientTyping.value = false;
              _typingListenerResetTimer?.cancel();
              if (kDebugMode) debugPrint("    [TypingListener] Recipient typing status doc removed or empty for $recipientId. Assuming not typing.");
            }
          }
        },
        onError: (error) {
          if (kDebugMode) debugPrint("  !!! [TypingListener] Error listening to recipient typing status: $error");
          isRecipientTyping.value = false; // أعدها للقيمة الافتراضية عند الخطأ
          _typingListenerResetTimer?.cancel();
        }
    );
    if (kDebugMode) debugPrint("  [TypingListener] Listening to recipient ($recipientId) typing status at path: ${_recipientTypingStatusRef!.path}");
  }










  /// بدء عملية التنزيل اليدوي لرسالة وسائط معينة
  Future<void> startManualMediaDownload(String messageId) async {
    if (kDebugMode) debugPrint("[ChatController] Requesting manual download for message $messageId");
    Get.snackbar( // إعطاء تغذية راجعة
        "بدء التنزيل", "جاري تنزيل الوسائط...",
        snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 2));
    try {
      // --- استدعاء دالة جديدة في المستودع ---
      // يجب إنشاء هذه الدالة في MessageRepository
      await _messageRepository.downloadMediaManually(messageId);
      // ----------------------------------
    } catch (e) {
      if (kDebugMode) debugPrint("!!! Error calling repository.downloadMediaManually for $messageId: $e");
      Get.snackbar("خطأ", "فشل بدء تنزيل الوسائط يدويًا.", snackPosition: SnackPosition.BOTTOM);
    }
  }

  // === State & UI Update Logic ===
  void _setupStateListeners() {
    messageController.addListener(updateCanSendMessageState);
    // مراقبة تغييرات ملف المعاينة وبيانات المعاينة باستخدام ever
    ever(_mediaPreviewFile, (_) => updateCanSendMessageState());
    ever(_imagePreviewData, (_) => updateCanSendMessageState());
    updateCanSendMessageState(); // حساب الحالة الأولية
  }

  void updateCanSendMessageState() {
    final isTextNotEmpty = messageController.text.trim().isNotEmpty;
    final hasPreview = _mediaPreviewFile.value != null || _imagePreviewData.value != null;
    // تحديث المتغير التفاعلي الذي تعتمد عليه الواجهة (Obx)
    _canSendMessageInternal.value = isTextNotEmpty || hasPreview;
  }

  void _listenToKeyboard() {
    KeyboardVisibilityController().onChange.listen((bool visible) {
      _isKeyboardVisible.value = visible;
      // التمرير للأسفل عند ظهور لوحة المفاتيح
      if (visible && scrollController.hasClients) {
        scrollToBottom(animate: true);
      }
    });
  }

  void scrollToBottom({bool animate = true}) {
    if (!scrollController.hasClients) return;
    // لـ reverse: true, الأسفل هو minScrollExtent
    final double position = scrollController.position.minScrollExtent;

    // استخدام postFrameCallback لضمان اكتمال التخطيط
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        if (animate) {
          scrollController.animateTo(position, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
        } else {
          scrollController.jumpTo(position);
        }
      }
    });
  }





  // داخل كلاس ChatController في ملف chat_controller.dart

  // === دوال إعادة المحاولة ===

  /// إعادة محاولة إرسال رسالة فشل إرسالها
  /// (تُستدعى من واجهة المستخدم، مثلاً زر إعادة المحاولة في MessageBubble)
  Future<void> retrySendMessage(String messageId) async {
    // إعطاء تغذية راجعة للمستخدم أن العملية بدأت
    Get.snackbar(
      "إعادة المحاولة...", // عنوان
      "جاري إعادة إرسال الرسالة.", // الرسالة
      snackPosition: SnackPosition.BOTTOM, // الموقع
      duration: const Duration(seconds: 2), // مدة الظهور
      showProgressIndicator: true, // إظهار مؤشر تقدم (اختياري)
    );

    if (kDebugMode) debugPrint("[ChatController] User requested retry send for message: $messageId");

    try {
      // استدعاء الدالة المقابلة في المستودع
      await _messageRepository.retrySending(messageId);
      // يمكنك إظهار رسالة نجاح هنا إذا أردت
      // Get.snackbar("نجاح", "تمت إعادة إرسال الرسالة.", snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      // التعامل مع أي أخطاء غير متوقعة أثناء استدعاء المستودع
      _showRetryErrorSnackbar("إرسال", e); // استخدام دالة الخطأ المساعدة
    }
  }

  /// إعادة محاولة تنزيل وسائط فشل تنزيلها
  /// (تُستدعى من واجهة المستخدم، مثلاً زر إعادة المحاولة في MessageBubble)
  Future<void> retryDownloadMedia(String messageId) async {
    // إعطاء تغذية راجعة
    Get.snackbar(
      "إعادة المحاولة...",
      "جاري إعادة تنزيل الوسائط.",
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      showProgressIndicator: true,
    );

    if (kDebugMode) debugPrint("[ChatController] User requested retry download for message: $messageId");

    try {
      // استدعاء الدالة المقابلة في المستودع
      await _messageRepository.retryDownload(messageId);
      // لا حاجة لرسالة نجاح هنا غالبًا، الواجهة ستتحدث تلقائيًا
    } catch (e) {
      // التعامل مع أخطاء استدعاء المستودع
      _showRetryErrorSnackbar("تنزيل", e); // استخدام دالة الخطأ المساعدة
    }
  }

  // دالة مساعدة لعرض خطأ إعادة المحاولة (موجودة بالفعل)
  void _showRetryErrorSnackbar(String action, dynamic error) {
    if (kDebugMode) debugPrint("!!! Error during retry $action: $error");
    Get.snackbar("خطأ", "فشلت إعادة محاولة $action.", snackPosition: SnackPosition.BOTTOM);
  }
// === نهاية دوال إعادة المحاولة ===


// --- تأكد من أن بقية كود ChatController موجود هنا ---
// ... onInit, onClose, updateCanSendMessageState, sendTextMessage, إلخ ...







  // جلب بيانات المستخدم الآخر (مثل الاسم والصورة)
  // === Data Fetching ===
  // داخل ChatController -> _fetchRecipientData

  Future<void> _fetchRecipientData() async {
    try {
      // --- استدعاء الدالة من المستودع الآن ---
      recipientData.value = await _messageRepository.getUserData(recipientId);
      // ---------------------------------------
      update(); // If AppBar uses GetBuilder for recipient data
    } catch (e) {
      if (kDebugMode) debugPrint("Error fetching recipient data via repository: $e");
    }
  }


  // --- Sending Logic ---
  // === Message Sending Logic (via Repository) ===
  // Future<void> sendTextMessage({
  //   String? quotedMessageId, String? quotedMessageText, String? quotedMessageSenderId
  // }) async {
  //   final text = messageController.text.trim();
  //   if (text.isEmpty) return;
  //
  //   final originalText = text;
  //   messageController.clear();
  //   updateCanSendMessageState(); // Update button state
  //
  //   try {
  //     await _messageRepository.sendMessage(
  //       recipientId: recipientId,
  //       textContent: originalText,
  //       messageType: FirestoreConstants.typeText,
  //       // --- تمرير معلومات الرد هنا إذا كانت موجودة ---
  //       quotedMessageId: quotedMessageId,
  //       quotedMessageText: quotedMessageText,
  //       quotedMessageSenderId: quotedMessageSenderId,
  //     );
  //     scrollToBottom(animate: true);
  //   } catch (e) {
  //     _handleSendError("فشل بدء إرسال الرسالة.", originalText);
  //   }
  // }












  Future<void> sendTextMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty && !isEditingMessage) return; // لا ترسل رسالة فارغة إلا إذا كنت تعدل لحذف النص

    final originalText = text;
    Message? quotedMsg = currentlyQuotedMessage.value;
    Message? editingMsg = messageBeingEdited.value; // احصل على الرسالة قيد التعديل

    messageController.clear();
    cancelQuotedMessage();
    cancelEditMessage(); // <--- ألغِ وضع التعديل بعد تجهيز الرسالة
    updateCanSendMessageState();

    try {
      if (editingMsg != null) {
        // --- حالة التعديل ---
        if (kDebugMode) debugPrint("[ChatCtrl] Attempting to EDIT message ${editingMsg.messageId} with new text: '$originalText'");
        // إذا كان النص الجديد فارغًا، قد تعني حذف النص (أو منع ذلك)
        // هنا سنسمح بتعديل لنص فارغ (يحوله لرسالة فارغة، أو يمكنك حذف الرسالة بدلاً من ذلك)
        if (originalText == editingMsg.content) {
          if (kDebugMode) debugPrint("[ChatCtrl] Edit skipped: New text is same as old text.");
          return; // لا تعديل إذا لم يتغير النص
        }
        await _messageRepository.editMessage(
          messageId: editingMsg.messageId,
          newContent: originalText,
          recipientId: recipientId, // نحتاجه لتحديث كلا نسختي الرسالة
        );

      } else {
        // --- حالة إرسال رسالة جديدة ---
        await _messageRepository.sendMessage(
          recipientId: recipientId,
          textContent: originalText,
          messageType: FirestoreConstants.typeText,
          quotedMessageId: quotedMsg?.messageId,
          quotedMessageText: quotedMsg != null ? _getPreviewTextForQuotedMessage(quotedMsg) : null,
          quotedMessageSenderId: quotedMsg?.senderId,
        );
      }
      scrollToBottom(animate: true);
    } catch (e) {
      _handleSendError("فشل ${editingMsg != null ? 'تعديل' : 'بدء إرسال'} الرسالة.", editingMsg != null ? editingMsg.content : originalText);
      // إذا فشل التعديل، أعد النص القديم لوضع التعديل (اختياري)
      if (editingMsg != null) {
        messageController.text = editingMsg.content; // أعد النص القديم لحقل الإدخال
        messageBeingEdited.value = editingMsg; // أعد تفعيل وضع التعديل
      }
    }
  }






  Future<void> sendMediaMessageFromPreview() async {
    if (!showMediaPreview) return;

    final fileToSend = _mediaPreviewFile.value;
    final dataToSend = _imagePreviewData.value; // (قلنا أن هذا غير مدعوم حاليًا في المستودع)
    final type = _mediaPreviewType.value;
    Message? quotedMsg = currentlyQuotedMessage.value;

    // احتفظ بنسخ من بيانات المعاينة قبل مسحها، قد تحتاجها إذا فشل الإرسال
    final File? originalFilePreview = _mediaPreviewFile.value;
    final Uint8List? originalImagePreviewData = _imagePreviewData.value;
    final String? originalMediaTypePreview = _mediaPreviewType.value;


    clearMediaPreview(); // امسح المعاينة من الواجهة
    cancelQuotedMessage();

    if (type == null || (fileToSend == null && dataToSend == null)) {
      Get.snackbar("خطأ", "لا توجد وسائط للإرسال.", snackPosition: SnackPosition.BOTTOM);
      return;
    }

    File? thumbnailFile; // سيتم تعيينه إذا كان الفيديو

    try {
      // --- [مهم] إنشاء المصغرة للفيديو ---
      if (type == 'video' && fileToSend != null) {
        if (kDebugMode) debugPrint("  [ChatCtrl sendMedia] Generating thumbnail for video: ${fileToSend.path}");
        thumbnailFile = await _generateVideoThumbnail(fileToSend.path); // <--- استدعاء الدالة هنا
        if (thumbnailFile == null) {
          if (kDebugMode) debugPrint("  !!! [ChatCtrl sendMedia] Failed to generate video thumbnail. Proceeding without thumbnail.");
          // يمكنك هنا إظهار رسالة للمستخدم أو الاستمرار بدون مصغère
        } else {
          if (kDebugMode) debugPrint("  [ChatCtrl sendMedia] Thumbnail generated: ${thumbnailFile.path}");
        }
      }
      // ----------------------------------

      if (dataToSend != null) {
        // منطق إرسال Uint8List (لا يزال غير مدعوم بالكامل في المستودع كما ذكرنا)
        if (kDebugMode) debugPrint("!!! Sending Uint8List via sendMediaMessageFromPreview is not fully implemented in repository.");
        Get.snackbar("تنبيه", "إرسال بيانات الصورة المباشرة قيد التطوير.", snackPosition: SnackPosition.BOTTOM);
        // إذا أردت إرجاع المعاينة في حالة الخطأ هنا
        // _mediaPreviewFile.value = originalFilePreview;
        // _imagePreviewData.value = originalImagePreviewData;
        // _mediaPreviewType.value = originalMediaTypePreview;
        // update(); // لتحديث الواجهة بالمعاينة المُعادة
        return;
      } else if (fileToSend != null) {
        await _messageRepository.sendMessage(
          recipientId: recipientId,
          messageType: type == 'video' ? FirestoreConstants.typeVideo : FirestoreConstants.typeImage,
          fileToUpload: fileToSend,
          thumbnailFile: thumbnailFile, // <--- الآن هذا قد يحتوي على ملف المصغرة
          quotedMessageId: quotedMsg?.messageId,
          quotedMessageText: quotedMsg != null ? _getPreviewTextForQuotedMessage(quotedMsg) : null,
          quotedMessageSenderId: quotedMsg?.senderId,
        );
      }
      scrollToBottom(animate: true);
    } catch (e) {
      if (kDebugMode) debugPrint("!!! [ChatCtrl sendMedia] Error caught: $e");
      // إعادة المعاينة إذا فشل الإرسال بالكامل (اختياري)
      _mediaPreviewFile.value = originalFilePreview;
      _imagePreviewData.value = originalImagePreviewData; // على الرغم من أنه لم يتم إرسالها
      _mediaPreviewType.value = originalMediaTypePreview;
      updateCanSendMessageState(); // أعد تحديث حالة زر الإرسال
      update(); // أعد بناء الأجزاء التي تعتمد على المعاينة

      _handleSendError("فشل بدء إرسال الوسائط.");
    }
  }

// --- [جديد] دالة مساعدة للحصول على نص المعاينة للرسالة المقتبسة ---
  String _getPreviewTextForQuotedMessage(Message quotedMessage) {
    if (quotedMessage.type == FirestoreConstants.typeText) {
      return quotedMessage.content.length > 100 // حد أطول للمعايير الفعلية للرد
          ? '${quotedMessage.content.substring(0, 97)}...'
          : quotedMessage.content;
    } else if (quotedMessage.type == FirestoreConstants.typeImage) {
      return '📷 صورة';
    } else if (quotedMessage.type == FirestoreConstants.typeVideo) {
      return '📹 فيديو';
    } else if (quotedMessage.type == FirestoreConstants.typeAudio) {
      return '🎤 رسالة صوتية';
    }
    return 'رسالة مرفقة';
  }
























  // إرسال الوسائط (صورة أو فيديو) التي تم اختيارها وعرضها في المعاينة

  // Future<void> sendMediaMessageFromPreview({
  //   String? quotedMessageId, String? quotedMessageText, String? quotedMessageSenderId
  // }) async {
  //   if (!showMediaPreview) return;
  //
  //   final fileToSend = _mediaPreviewFile.value;
  //   final dataToSend = _imagePreviewData.value; // Requires repo/service update
  //   final type = _mediaPreviewType.value;
  //
  //   clearMediaPreview(); // مسح المعاينة فورًا
  //
  //   if (type == null || (fileToSend == null && dataToSend == null)) {
  //     Get.snackbar("خطأ", "بيانات الوسائط غير صالحة للإرسال.", snackPosition: SnackPosition.BOTTOM);
  //     return;
  //   }
  //
  //   File? thumbnailFile;
  //   try {
  //     // إنشاء المصغرة للفيديو أولاً
  //     if (type == 'video' && fileToSend != null) {
  //       thumbnailFile = await _generateVideoThumbnail(fileToSend.path);
  //       if (thumbnailFile == null) if (kDebugMode) debugPrint("فشل إنشاء مصغرة للفيديو.");
  //     }
  //
  //     // --- استدعاء المستودع ---
  //     if (dataToSend != null) { // إرسال بيانات صورة
  //       if (kDebugMode) debugPrint("!!! Sending Uint8List requires repository and service modifications !!!");
  //       // TODO: Implement direct Uint8List sending in Repository/Service
  //       // أو استخدام الحل المؤقت لحفظ الملف (كما هو معلق في الكود السابق)
  //       Get.snackbar("خطأ", "إرسال بيانات الصورة مباشرة غير مدعوم حاليًا.", snackPosition: SnackPosition.BOTTOM); // إبلاغ مؤقت
  //       return; // إيقاف العملية للبيانات غير المدعومة
  //     } else if (fileToSend != null) { // إرسال ملف (صورة أو فيديو)
  //       await _messageRepository.sendMessage(
  //         recipientId: recipientId,
  //         messageType: type == 'video' ? FirestoreConstants.typeVideo : FirestoreConstants.typeImage,
  //         fileToUpload: fileToSend,
  //         thumbnailFile: thumbnailFile,
  //         // --- تمرير معلومات الرد هنا ---
  //         quotedMessageId: quotedMessageId,
  //         quotedMessageText: quotedMessageText,
  //         quotedMessageSenderId: quotedMessageSenderId,
  //       );
  //     }
  //     // ---------------------
  //     scrollToBottom(animate: true); // التمرير للأسفل بعد بدء الإرسال
  //   } catch (e) {
  //     _handleSendError("فشل بدء إرسال الوسائط.");
  //   }
  // }


  // --- دالة مساعدة عامة للتعامل مع أخطاء بدء الإرسال ---
  void _handleSendError(String baseMessage, [String? originalTextToRestore]) {
    if (kDebugMode) debugPrint("!!! Send Error: $baseMessage");
    Get.snackbar(
        "خطأ", "$baseMessage حاول مرة أخرى.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent, colorText: Colors.white);
    if (originalTextToRestore != null) {
      messageController.text = originalTextToRestore;
      updateCanSendMessageState();
    }
  }


  // --- Media Picking ---
  // اختيار صورة من مصدر (كاميرا أو معرض)
  Future<void> pickImage(ImageSource source) async {
    try {
      // إضافة حد أقصى للحجم أو ضغط إضافي إذا لزم الأمر هنا
      final XFile? imageFile = await _picker.pickImage(
        source: source,
        imageQuality: 85, // ضغط الصورة قليلاً (0-100)
        // maxHeight: 1920, // يمكن تحديد أبعاد قصوى
        // maxWidth: 1080,
      );
      if (imageFile != null) {
        _setMediaPreview(File(imageFile.path), 'image');
      }
    } catch (e) {
      if (kDebugMode) debugPrint("خطأ أثناء اختيار الصورة: $e");
      _showPermissionErrorSnackbarIfNeeded(e); // التحقق من أخطاء الأذونات
      Get.snackbar("خطأ", "تعذر اختيار الصورة.", snackPosition: SnackPosition.BOTTOM);
    }
  }

  // اختيار فيديو من مصدر (عادة المعرض)
  Future<void> pickVideo(ImageSource source) async {
    try {
      final XFile? videoFile = await _picker.pickVideo(source: source);
      if (videoFile != null) {
        // يمكنك هنا ضغط الفيديو قبل إظهاره في المعاينة إذا كان حجمه كبيرًا
        // final compressedVideo = await VideoCompress.compressVideo(...);
        // if (compressedVideo != null) {
        //   _setMediaPreview(compressedVideo.file!, 'video');
        // } else {
        //   // Handle compression failure
        // }
        _setMediaPreview(File(videoFile.path), 'video'); // عرض الأصلي مبدئيًا
      }
    } catch (e) {
      if (kDebugMode) debugPrint("خطأ أثناء اختيار الفيديو: $e");
      _showPermissionErrorSnackbarIfNeeded(e);
      Get.snackbar("خطأ", "تعذر اختيار الفيديو.", snackPosition: SnackPosition.BOTTOM);
    }
  }

  // عرض رسالة خطأ إذا كان الخطأ متعلقًا بالأذونات
  void _showPermissionErrorSnackbarIfNeeded(dynamic error) {
    // الأخطاء المتعلقة بالأذونات قد تكون PlatformException
    if (error is Exception && error.toString().contains('permission')) {
      Get.snackbar(
        "الأذونات مطلوبة",
        "يرجى منح الأذونات اللازمة من إعدادات التطبيق للوصول إلى الكاميرا أو المعرض.",
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5), // مدة أطول
        mainButton: TextButton(
          child: const Text("فتح الإعدادات", style: TextStyle(color: Colors.white)),
          onPressed: () => openAppSettings(), // من حزمة permission_handler
        ),
      );
    }
  }

  // تعيين معاينة صورة من بيانات Uint8List (قد تأتي من ويدجت كاميرا مخصصة)
  void setImagePreviewData(Uint8List data) {
    clearMediaPreview(); // مسح أي معاينة ملف سابقة
    _imagePreviewData.value = data;
    _mediaPreviewType.value = 'image';
    // الانتقال إلى شاشة العرض الكامل اختياري
    updateCanSendMessageState(); // <-- تحديث الحالة بعد التعيين

    // _showPreviewScreenIfNeeded(isImageData: true);
    update(); // تحديث الواجهة لإظهار المعاينة فوق حقل الإدخال
  }

  // تعيين معاينة من ملف (صورة أو فيديو)
  void _setMediaPreview(File file, String type) {
    clearMediaPreview(); // مسح أي معاينة بيانات سابقة
    _mediaPreviewFile.value = file;
    _mediaPreviewType.value = type;
    updateCanSendMessageState(); // <-- تحديث الحالة بعد التعيين

    // الانتقال إلى شاشة العرض الكامل اختياري
    // _showPreviewScreenIfNeeded(isImageData: false);
    update(); // تحديث الواجهة لإظهار المعاينة فوق حقل الإدخال
  }

  // // دالة للانتقال إلى شاشة عرض الوسائط بملء الشاشة قبل الإرسال (اختياري)
  // void _showPreviewScreenIfNeeded({required bool isImageData}) {
  //   if (isImageData && _imagePreviewData.value != null) {
  //     // تمرير المتحكم حتى تتمكن الشاشة الأخرى من استدعاء sendMediaMessageFromPreview
  //     Get.to(() => ViewMediaScreen(controller: this, isImageData: true));
  //   } else if (!isImageData && _mediaPreviewFile.value != null) {
  //     Get.to(() => ViewMediaScreen(controller: this, isImageData: false));
  //   }
  // }

  // مسح حالة المعاينة الحالية
  void clearMediaPreview() {
    _mediaPreviewFile.value = null;
    _imagePreviewData.value = null;
    _mediaPreviewType.value = null;
    updateCanSendMessageState(); // <-- تحديث الحالة بعد المسح

    // لا تحتاج لاستدعاء update() هنا إذا كانت العناصر التي تعرض المعاينة تستخدم Obx
    // لكن إذا كنت تستخدم GetBuilder لعرض المعاينة، فاحتفظ بـ update()
    update();
  }

  // --- Video Thumbnail Generation ---
  // إنشاء صورة مصغرة للفيديو باستخدام video_compress
  Future<File?> _generateVideoThumbnail(String videoPath) async {
    try {
      final File thumbFile = await VideoCompress.getFileThumbnail(
          videoPath,
          quality: 60, // جودة 0-100
          position: -1 // -1 لجلب إطار افتراضي (عادةً الأول)
      );
      if (await thumbFile.exists() && await thumbFile.length() > 0) {
        if (kDebugMode) debugPrint("   [_generateVideoThumbnail] Thumbnail created: ${thumbFile.path}, Size: ${await thumbFile.length()}");
        return thumbFile;
      } else {
        if (kDebugMode) debugPrint("   !!! [_generateVideoThumbnail] VideoCompress returned null or empty file for $videoPath");
        if(await thumbFile.exists()) await thumbFile.delete(); // تنظيف إذا تم إنشاء ملف فارغ
        return null;
      }
    } catch (e) {
      if (kDebugMode) debugPrint("!!! Error in _generateVideoThumbnail for $videoPath: $e");
      return null;
    }
  }

  // --- Recording Logic ---
  // التحقق من أذونات الميكروفون وطلبها إذا لزم الأمر
  Future<bool> _checkAndRequestMicPermission() async {
    var status = await Permission.microphone.status;
    if (status.isGranted) {
      return true;
    } else {
      status = await Permission.microphone.request();
      if (!status.isGranted) {
        Get.snackbar(
          "الأذونات مطلوبة",
          "لاستخدام التسجيل الصوتي، يرجى منح إذن الوصول إلى الميكروفون من إعدادات التطبيق.",
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
          mainButton: TextButton(
            child: const Text("فتح الإعدادات", style: TextStyle(color: Colors.white)),
            onPressed: () => openAppSettings(),
          ),
        );
        return false;
      }
      return true; // تم منح الإذن الآن
    }
  }





  void cancelRecording() {
    if (!_isRecording.value) return; // تأكد من أنه كان يسجل

    if (kDebugMode) debugPrint("Recording cancelled by system or external event.");
    _recordingTimer?.cancel(); // إيقاف المؤقت

    // محاولة إيقاف المسجل بهدوء والتخلص من الملف
    _audioRecorder.stop().then((path) {
      if (path != null) {
        try {
          File(path).deleteSync();
        } catch (_) {}
      }
    }).catchError((e) {
      // تجاهل الأخطاء هنا لأننا نقوم بالإلغاء فقط
      if (kDebugMode) debugPrint("Error stopping recorder during cancellation: $e");
    }).whenComplete(() {
      // إعادة تعيين الحالة بغض النظر عن نجاح الإيقاف/الحذف
      _resetRecordingState();
    });
  }




  // بدء التسجيل الصوتي عند الضغط المطول على زر الميكروفون
  Future<void> startRecording(LongPressStartDetails details) async {
    // لا تسجل إذا كان المستخدم يكتب نصًا
    if (messageController.text.trim().isNotEmpty) return;

    // التحقق من الأذونات أولاً
    final hasPermission = await _checkAndRequestMicPermission();
    if (!hasPermission) return; // إيقاف إذا لم يتم منح الإذن

    try {
      // تخزين إحداثيات بداية الضغط لتتبع السحب للإلغاء
      _longPressStartOffset = details.globalPosition;

      // الحصول على مجلد مؤقت لتخزين التسجيل
      final tempDir = await getTemporaryDirectory();
      // إنشاء مسار ملف فريد باستخدام UUID
      _recordingPath = '${tempDir.path}/${_uuid.v1()}.m4a'; // استخدام تنسيق AAC

      // بدء التسجيل باستخدام حزمة record
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc), // تحديد التشفير
        path: _recordingPath!, // تحديد مسار الحفظ
      );

      // تحديث حالة الواجهة
      _isRecording.value = true;
      _isRecordDeleting.value = false; // إعادة تعيين حالة الحذف
      _recordingDuration.value = Duration.zero; // إعادة تعيين المؤقت

      // إلغاء المؤقت السابق إذا كان موجودًا وبدء مؤقت جديد
      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _recordingDuration.value += const Duration(seconds: 1);
        // يمكنك إضافة حد أقصى لمدة التسجيل هنا إذا أردت
        // if (_recordingDuration.value.inMinutes >= 2) { stopRecording(); }
      });
    } catch (e) {
      if (kDebugMode) debugPrint("خطأ أثناء بدء التسجيل: $e");
      _resetRecordingState(); // إعادة تعيين الحالة عند حدوث خطأ
      Get.snackbar("خطأ", "تعذر بدء التسجيل الصوتي.", snackPosition: SnackPosition.BOTTOM);
    }
  }

  // تحديث الواجهة أثناء تحريك الإصبع أثناء الضغط المطول (للإشارة إلى السحب للإلغاء)
  void updateRecordingPosition(LongPressMoveUpdateDetails details) {
    if (!_isRecording.value) return; // التأكد من أن التسجيل نشط

    final currentOffset = details.globalPosition;
    // حساب الإزاحة الأفقية من نقطة البداية
    final deltaX = currentOffset.dx - _longPressStartOffset.dx;
    // تحديد عتبة للسحب إلى اليسار لتفعيل وضع الإلغاء (يمكن تعديلها)
    final cancelThreshold = -(Get.width / 4.5); // مثال: السحب بمقدار ربع عرض الشاشة لليسار

    // تحديث حالة الحذف بناءً على الإزاحة
    if (deltaX < cancelThreshold) {
      _isRecordDeleting.value = true;
    } else {
      _isRecordDeleting.value = false;
    }
  }

  // إيقاف التسجيل عند رفع الإصبع
  Future<void> stopRecording() async { // الإرسال يستدعي المستودع
    if (!_isRecording.value) return;
    _recordingTimer?.cancel();
    String? finalPath;
    try {
      if (await _audioRecorder.isRecording()) { finalPath = await _audioRecorder.stop(); }
      else { finalPath = _recordingPath; }

      bool wasDeleting = _isRecordDeleting.value;
      Duration finalDuration = _recordingDuration.value;

      if (wasDeleting || finalPath == null || finalDuration.inSeconds < 1) {
        if(finalPath != null) { try{File(finalPath).deleteSync();}catch(_){} }
        if(kDebugMode) debugPrint("Recording cancelled/too short. Path: $finalPath, Duration: ${finalDuration.inSeconds}s");
      } else {
        if (kDebugMode) debugPrint("--> Calling Repository to send recording: $finalPath");
        // لا نستخدم isSending بنفس الطريقة، الاعتماد على حالة الرسالة المحلية
        await _messageRepository.sendMessage(
          recipientId: recipientId,
          messageType: FirestoreConstants.typeAudio,
          fileToUpload: File(finalPath),
          // معلومات الرد...
        );
        scrollToBottom(animate: true); // التمرير للأسفل
      }
    } catch (e,s) {
      if (kDebugMode) debugPrint("!!! Error stopping/processing recording: $e\n$s");
      Get.snackbar("خطأ", "حدث خطأ أثناء معالجة التسجيل.", snackPosition: SnackPosition.BOTTOM);
    } finally {
      _resetRecordingState();
    }
  }

  // إعادة تعيين متغيرات حالة التسجيل إلى قيمها الافتراضية
  void _resetRecordingState() {
    _isRecording.value = false;
    _isRecordDeleting.value = false;
    _recordingDuration.value = Duration.zero;
    _recordingPath = null;
    _recordingTimer?.cancel();
    _longPressStartOffset = Offset.zero;
  }






  // --- Attachment Options ---
  // إظهار قائمة سفلية بخيارات إرفاق الوسائط
  void showAttachmentOptions() {
    // التأكد من عدم فتحها أثناء التسجيل أو الإرسال
    if (_isRecording.value || _isSending.value) return;

    Get.bottomSheet(
      // استخدام تصميم أكثر حداثة للخيارات
      Container(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0),
        child: Wrap( // يلتف العناصر تلقائيًا إذا لم تتسع
          alignment: WrapAlignment.spaceAround, // توزيع المسافات
          spacing: 16, // مسافة أفقية بين العناصر
          runSpacing: 24, // مسافة رأسية بين الصفوف
          children: [
            _buildMediaOption(Icons.photo_library_outlined, "المعرض", () => pickImage(ImageSource.gallery)),
            _buildMediaOption(Icons.camera_alt_outlined, "الكاميرا", () => pickImage(ImageSource.camera)),
            _buildMediaOption(Icons.videocam_outlined, "فيديو", () => pickVideo(ImageSource.gallery)),
            // يمكن إضافة خيارات أخرى مثل:
            // _buildMediaOption(Icons.description_outlined, "ملف", () { /* TODO */ }),
            // _buildMediaOption(Icons.location_on_outlined, "الموقع", () { /* TODO */ }),
          ],
        ),
      ),
      backgroundColor: Get.theme.scaffoldBackgroundColor, // استخدام لون خلفية الثيم
      shape: const RoundedRectangleBorder(
        // حواف مستديرة علوية فقط
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      // يمكنك إضافة ارتفاع محدد للـ bottomSheet
      // isScrollControlled: true, // إذا كانت العناصر قد تتجاوز ارتفاع الشاشة
    );
  }

  // ويدجت لعرض خيار واحد في قائمة الإرفاق
  Widget _buildMediaOption(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        Get.back(); // إغلاق القائمة السفلية قبل تنفيذ الإجراء
        onTap();
      },
      borderRadius: BorderRadius.circular(12), // لإظهار تأثير الضغط بشكل أفضل
      child: Padding(
        padding: const EdgeInsets.all(8.0), // هامش داخلي بسيط
        child: Column(
          mainAxisSize: MainAxisSize.min, // ليأخذ العمود أقل مساحة ممكنة
          children: [
            CircleAvatar(
              radius: 30, // حجم الدائرة
              backgroundColor: Get.theme.primaryColor.withOpacity(0.1), // لون خلفية شفاف قليلًا
              child: Icon(icon, size: 30, color: Get.theme.primaryColor), // أيقونة الخيار
            ),
            const SizedBox(height: 8), // مسافة بين الأيقونة والنص
            Text(label, style: Get.textTheme.bodySmall), // تسمية الخيار
          ],
        ),
      ),
    );
  }
}