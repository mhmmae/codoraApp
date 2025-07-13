import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'dart:convert'; // <-- إضافة استيراد ضروري

import '../../bottonBar/Get2/Get2.dart';   // تأكد من المسار الصحيح
import '../../bottonBar/botonBar.dart';  // تأكد من المسار الصحيح
import '../../controler/local-notification-onroller.dart'; // تأكد من المسار الصحيح





enum SortOption {
  latestFirst(label: 'الأحدث أولاً', field: 'timestamp', descending: true),
  oldestFirst(label: 'الأقدم أولاً', field: 'timestamp', descending: false),
  priceLowToHigh(label: 'السعر: من الأقل للأعلى', field: 'priceOfItem', descending: false),
  priceHighToLow(label: 'السعر: من الأعلى للأقل', field: 'priceOfItem', descending: true);
  // يمكن إضافة Name AZ/ZA إذا أردت

  const SortOption({
    required this.label,
    required this.field,
    required this.descending,
  });

  final String label;
  final String field; // اسم الحقل في Firestore
  final bool descending; // هل الترتيب تنازلي؟
}



class GetSearchController extends GetxController {
  final TextEditingController searchFieldController = TextEditingController();
  final RxString searchQuery = ''.obs;
  late PageController offerPageController;
  final RxInt currentOfferPage = 0.obs;
  final Rx<SortOption> currentSortOption = SortOption.latestFirst.obs;


  void changeSortOption(SortOption newOption) {
    if (currentSortOption.value != newOption) {
      currentSortOption.value = newOption;
      debugPrint("Sort option changed to: ${newOption.label}");
      // لا تحتاج لـ update() لأننا نستخدم .obs و Obx/StreamBuilder
      // قد تحتاج لتحديث الـ Stream أو إعادة تحميل البيانات إذا لم يكن StreamBuilder يراقب SortOption مباشرة
    }
  }

  @override
  void onInit() {
    super.onInit();

    offerPageController = PageController(initialPage: currentOfferPage.value);
    // --- إضافة مستمع لمراقبة تغييرات الصفحة في offerPageController ---
    offerPageController.addListener(() {
      // استخدم round() للحصول على أقرب صفحة صحيحة أثناء التمرير
      final currentPage = offerPageController.page?.round() ?? 0;
      if (currentOfferPage.value != currentPage) {
        currentOfferPage.value = currentPage;
      }
    });
    // --- ربط متحكم البحث مع حقل النص ---
    searchFieldController.addListener(() {
      if (searchQuery.value != searchFieldController.text) {
        searchQuery.value = searchFieldController.text;
      }
    });
    _setupNotificationListeners();
    debugPrint("GetSearchController Initialized.");
  }

  void _setupNotificationListeners() {
    // ---!!! استخدام StreamController المعاد تسميته (اختياري) وتصحيح معالجة الـ payload !!!---
    if (!LocalNotification.notificationTapStreamController.hasListener) {
      LocalNotification.notificationTapStreamController.stream.listen((NotificationResponse notificationResponse) {
        debugPrint("Local Notification Tapped Raw Payload: ${notificationResponse.payload}");
        final String? payloadString = notificationResponse.payload; // الحصول على الـ payload كـ String
        if (payloadString != null && payloadString.isNotEmpty) {
          try {
            // ---!!! فك ترميز الـ payload من JSON String إلى Map !!!---
            final Map<String, dynamic> payloadMap = jsonDecode(payloadString);
            int? targetIndex = _getTargetIndexFromPayload(payloadMap);
            if (targetIndex != null) {
              _navigateToBottomBarIndex(targetIndex);
            } else {
              debugPrint('Could not determine target index from local notification payload map: $payloadMap');
            }
          } catch (e) {
            debugPrint('Error decoding local notification payload: $e');
            // يمكن محاولة التوجيه إلى صفحة افتراضية في حالة الخطأ
            _navigateToBottomBarIndex(0);
          }
        } else {
          debugPrint("Local notification payload is null or empty.");
          // توجيه افتراضي إذا لم يكن هناك payload
          _navigateToBottomBarIndex(0);
        }
      });
      debugPrint('Local notification tap listener registered.');
    } else {
      debugPrint("Local notification tap listener ALREADY registered.");
    }

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("App opened from Firebase notification: ${message.data}");
      _handleFirebaseNotificationClick(message);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("Firebase message received while app is in foreground: ${message.data}");
      // ---!!! استدعاء الدالة الجديدة لعرض الإشعار البسيط !!!---
      _showLocalNotificationForForegroundMessage(message);
    });

    // طباعة توكن FCM للمساعدة في الاختبار
    FirebaseMessaging.instance.getToken().then((token) {
      debugPrint("-----------------------------------");
      debugPrint("Firebase Messaging Token: $token");
      debugPrint("-----------------------------------");
    }).catchError((e) => debugPrint("Error getting FCM token: $e"));
  }

  // دالة لتحديد الوجهة بناءً على بيانات الـ Payload (تبقى كما هي)
  int? _getTargetIndexFromPayload(Map<String, dynamic> payload) {
    final String? notificationType = payload['type'] as String?;
    // يمكنك إضافة حقل index مباشر في الـ payload لتبسيط الأمر
    final int? screenIndex = payload['screen_index'] as int?;

    debugPrint("Parsing payload for navigation: $payload"); // طباعة للتصحيح

    // إعطاء الأولوية لـ screen_index إذا كان موجوداً وصحيحاً
    // تأكد أن لديك العدد الصحيح للصفحات (0-4 مثلاً لخمس صفحات)
    if (screenIndex != null && screenIndex >= 0 && screenIndex < 5) { // افترض 5 صفحات حالياً
      debugPrint("Target index found directly: $screenIndex");
      return screenIndex;
    }

    // تحديد الوجهة بناءً على النوع إذا لم يتوفر screen_index
    debugPrint("Determining index by type: $notificationType");
    switch (notificationType) {
      case 'message': return 4; // صفحة الرسائل
      case 'order_update': return 3; // صفحة الطلبات (للأدمن؟)
      case 'new_offer':
      case 'new_product':
        return 0; // الصفحة الرئيسية
      case 'cart_reminder': return 2; // السلة
    // أضف أنواع إشعارات أخرى هنا
    // case 'AcceptTheRequest': return 0; // أو صفحة أخرى حسب الحاجة
    // case 'RequestRejected': return 0;
      default:
        debugPrint("Unknown notification type in payload: $notificationType");
        return null; // لم يتم تحديد الوجهة
    }
  }

  // دالة الانتقال بين صفحات الشريط السفلي (تبقى كما هي)
  void _navigateToBottomBarIndex(int index) {
    debugPrint("Navigating to BottomBar index: $index");
    try {
      // تأكد من أن Get2 موجود ومُهيأ (ربما في مكان أعلى مثل main.dart أو في Binding)
      final bottomBarController = Get.find<Get2>();
      bottomBarController.changeIndex(index);
      // استخدام Get.offAll جيد لمنع تراكم الصفحات، لكن تأكد أنه لا يسبب مشاكل مع حالة BottomBar
      Get.offAll(() => BottomBar(initialIndex: index));
    } catch (e) {
      debugPrint("Error finding/updating Get2 controller: $e. Navigating using Get.to()");
      // حل بديل إذا فشل العثور على Get2 (قد يؤدي لتراكم الصفحات)
      Get.to(() => BottomBar(initialIndex: index));
    }
  }

  // دالة معالجة *الضغط* على إشعار Firebase (عندما يكون التطبيق في الخلفية أو مغلق)
  // (تبقى كما هي، مع تعديل الـ index حسب الحاجة)
  void _handleFirebaseNotificationClick(RemoteMessage message) {
    final Map<String, dynamic> data = message.data;
    final String? notificationType = data['type'] as String?;
    debugPrint("Handling Firebase notification click - Type: $notificationType, Data: $data");

    // يمكنك استخدام _getTargetIndexFromPayload هنا أيضاً لتوحيد المنطق
    int? targetIndex = _getTargetIndexFromPayload(data);
    if (targetIndex != null) {
      _navigateToBottomBarIndex(targetIndex);
    } else {
      // إذا لم يحدد الـ payload وجهة، اذهب إلى الصفحة الرئيسية
      debugPrint("No specific target index from Firebase click payload, going to index 0.");
      _navigateToBottomBarIndex(0);
    }
  }

  // دالة عرض إشعار محلي عندما تصل رسالة Firebase *والتطبيق في المقدمة*
  Future<void> _showLocalNotificationForForegroundMessage(RemoteMessage message) async {
    final String title = message.notification?.title ?? 'إشعار جديد';
    final String body = message.notification?.body ?? '';
    // استخدام بيانات الرسالة نفسها كـ payload للإشعار المحلي
    // هذا سيسمح بمعالجتها بنفس الطريقة عند الضغط عليها
    final Map<String, dynamic> payloadData = message.data;

    // استخدام timestamp لـ ID لضمان تفرده
    final int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    try {
      // ---!!! استدعاء الدالة البسيطة الجديدة في LocalNotification !!!---
      await LocalNotification.showBasicNotification(
        id: notificationId,
        title: title,
        body: body,
        payloadMap: payloadData, // تمرير الـ Map مباشرة
      );
    } catch (e) {
      debugPrint("Error displaying local notification for foreground message: $e");
      // عرض Snackbar كحل بديل في حالة فشل الإشعار المحلي
      Get.snackbar(title, body,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.blueGrey,
          colorText: Colors.white
      );
    }
  }

  @override
  void dispose() {
    // تخلص من المتحكمات عند إزالة الـ GetSearchController
    offerPageController.dispose();
    searchFieldController.dispose();
    debugPrint("GetSearchController Disposed.");
    super.dispose();
  }

// لا تحتاج لـ onClose إذا كانت dispose تقوم باللازم
// @override
// void onClose() {
//   super.onClose();
// }
}


