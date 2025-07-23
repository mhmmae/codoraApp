import 'package:codora/%D8%A7%D9%84%D9%83%D9%88%D8%AF%20%D8%A7%D9%84%D8%AE%D8%A7%D8%B5%20%D8%A8%D8%AA%D8%B7%D8%A8%D9%8A%D9%82%20%D8%A7%D9%84%D8%A8%D8%A7%D8%A6%D8%B9/seller_app_auth/ui/welcome1.dart';
import 'package:codora/%D8%A7%D9%84%D9%83%D9%88%D8%AF%20%D8%A7%D9%84%D8%AE%D8%A7%D8%B5%20%D8%A8%D8%AA%D8%B7%D8%A8%D9%8A%D9%82%20%D8%A7%D9%84%D8%A8%D8%A7%D8%A6%D8%B9/ui/controllers/retail_cart_controller.dart';
import 'package:codora/%D8%A7%D9%84%D9%83%D9%88%D8%AF%20%D8%A7%D9%84%D8%AE%D8%A7%D8%B5%20%D8%A8%D8%AA%D8%B7%D8%A8%D9%8A%D9%82%20%D8%A7%D9%84%D8%A8%D8%A7%D8%A6%D8%B9/ui/seller_main_screen.dart';
import 'package:codora/%D8%A7%D9%84%D9%83%D9%88%D8%AF%20%D8%A7%D9%84%D8%AE%D8%A7%D8%B5%20%D8%A8%D8%AA%D8%B7%D8%A8%D9%8A%D9%82%20%D8%A7%D9%84%D8%B9%D9%85%D9%8A%D9%84%20/chat/google/InitialBindings.dart';
import 'routes/app_pages.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:io';

import 'الكود الخاص بتطبيق العميل /controler/local-notification-onroller.dart';
import 'الكود الخاص بتطبيق العميل /services/phone_auth_service.dart';
import 'الكود الخاص بتطبيق البائع/seller_app_auth/controllers/seller_auth_controller.dart';
import 'firebase_options.dart';
import 'package:permission_handler/permission_handler.dart';

late FirebaseMessaging messaging;

class InitialBindings extends Bindings {
  @override
  void dependencies() {
    // تهيئة PhoneAuthService مع ضمان التسجيل الصحيح
    try {
      // التحقق من وجود الخدمة أولاً وإزالتها إن وجدت
      if (Get.isRegistered<PhoneAuthService>()) {
        Get.delete<PhoneAuthService>();
        debugPrint("🔄 تم حذف PhoneAuthService السابق");
      }

      // إنشاء وتسجيل الخدمة الجديدة
      final phoneAuthService = PhoneAuthService();
      Get.put(phoneAuthService, permanent: true);
      debugPrint("✅ تم تسجيل PhoneAuthService بنجاح في InitialBindings");

      // انتظار تهيئة كاملة للخدمة
      Future.delayed(Duration(seconds: 2), () {
        try {
          final service = Get.find<PhoneAuthService>();
          service.testService();
          final report = service.getServiceReport();
          debugPrint("📊 تقرير خدمة المصادقة: ${report['status']}");

          // اختبار أساسي للتأكد من جاهزية الخدمة
          debugPrint("🔍 اختبار جاهزية الخدمة...");
          if (service.canMakeRequest) {
            debugPrint("✅ الخدمة جاهزة لاستقبال الطلبات");
          } else {
            debugPrint("⚠️ الخدمة غير جاهزة لاستقبال الطلبات");
          }
        } catch (e) {
          debugPrint("❌ خطأ في اختبار PhoneAuthService: $e");
          // محاولة إعادة تسجيل الخدمة
          try {
            Get.delete<PhoneAuthService>();
            Get.put(PhoneAuthService(), permanent: true);
            debugPrint("🔄 تم إعادة تسجيل PhoneAuthService");
          } catch (retryError) {
            debugPrint("❌ فشل في إعادة تسجيل PhoneAuthService: $retryError");
          }
        }
      });
    } catch (e) {
      debugPrint("❌ فشل في تسجيل PhoneAuthService: $e");
      // محاولة تسجيل بديلة
      try {
        debugPrint("🔄 محاولة تسجيل بديلة...");
        Get.lazyPut(() => PhoneAuthService(), fenix: true);
        debugPrint("✅ تم التسجيل البديل لـ PhoneAuthService");
      } catch (fallbackError) {
        debugPrint("❌ فشل في التسجيل البديل: $fallbackError");
      }
    }

    // ✅ تهيئة SellerAuthController للبائعين
    try {
      // التحقق من وجود الكنترولر أولاً وإزالته إن وجد
      if (Get.isRegistered<SellerAuthController>()) {
        Get.delete<SellerAuthController>();
        debugPrint("🔄 تم حذف SellerAuthController السابق");
      }

      // إنشاء وتسجيل الكنترولر الجديد
      final sellerAuthController = SellerAuthController();
      Get.lazyPut(() => RetailCartController());
      Get.put(sellerAuthController, permanent: true);
      debugPrint("✅ تم تسجيل SellerAuthController بنجاح في InitialBindings");
    } catch (e) {
      debugPrint("❌ فشل في تسجيل SellerAuthController: $e");
      // محاولة تسجيل بديلة
      try {
        debugPrint("🔄 محاولة تسجيل بديلة لـ SellerAuthController...");
        Get.lazyPut(() => SellerAuthController(), fenix: true);
        debugPrint("✅ تم التسجيل البديل لـ SellerAuthController");
      } catch (fallbackError) {
        debugPrint(
          "❌ فشل في التسجيل البديل لـ SellerAuthController: $fallbackError",
        );
      }
    }

    // استدعاء InitialBindings1 للحصول على جميع الخدمات الإضافية
    try {
      final initialBindings1 = InitialBindings1();
      initialBindings1.dependencies();
      debugPrint("✅ تم استدعاء InitialBindings1 بنجاح");
    } catch (e) {
      debugPrint("❌ فشل في استدعاء InitialBindings1: $e");
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase properly with iOS-specific handling
  try {
    print("🔧 Starting Firebase initialization...");

    // Always try to initialize from Dart to ensure proper configuration
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("✅ Firebase initialized successfully from Dart");

    // اختبار Firebase Auth بعد التهيئة
    try {
      final auth = FirebaseAuth.instance;
      print("🔐 Firebase Auth instance created: ${auth.app.name}");
      print("📱 Current user: ${auth.currentUser?.uid ?? 'No user'}");
      print("🌍 App ID: ${auth.app.options.appId}");
      print("🏗️ Project ID: ${auth.app.options.projectId}");
    } catch (authError) {
      print("❌ Firebase Auth test failed: $authError");
    }

    // Wait longer for iOS to ensure everything is ready
    if (Platform.isIOS) {
      await Future.delayed(Duration(milliseconds: 5000));
      print("✅ iOS Firebase extended initialization delay completed");
    } else {
      await Future.delayed(Duration(milliseconds: 2000));
      print("✅ Android Firebase initialization delay completed");
    }

    // Initialize Firebase Messaging safely
    try {
      messaging = FirebaseMessaging.instance;
      print("✅ Firebase Messaging initialized");
    } catch (messagingError) {
      print("⚠️ Firebase Messaging initialization error: $messagingError");
      // Continue without messaging features
    }
  } catch (e) {
    print("⚠️ Firebase initialization error: $e");

    // If initialization fails, try to use existing app (for iOS)
    if (Platform.isIOS && Firebase.apps.isNotEmpty) {
      print("🔄 Using existing Firebase app on iOS");
      try {
        messaging = FirebaseMessaging.instance;
        print("✅ Firebase Messaging initialized with existing app");
      } catch (msgError) {
        print("⚠️ Messaging error with existing app: $msgError");
      }
    } else {
      print("⚠️ App will continue with limited Firebase features");
    }
  }

  // Configure messaging permissions safely
  try {
    await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Configure foreground notifications
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

    print("✅ Firebase Messaging permissions configured");
  } catch (e) {
    print("⚠️ Firebase Messaging configuration error: $e");
  }

  // Initialize local notifications
  await LocalNotification.init();

  // Request notification permissions
  await requestNotificationPermission();

  // Set background message handler safely
  try {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    print("✅ Background message handler set");
  } catch (e) {
    print("⚠️ Background message handler error: $e");
  }

  await GetStorage.init();
  await initializeDateFormatting();

  final User? currentUser = FirebaseAuth.instance.currentUser;

  runApp(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MyApp(isLoggedIn: currentUser != null);
      },
    ),
  );
}

Future<void> requestNotificationPermission() async {
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
}

/// التعامل مع الإشعارات الواردة في الخلفية
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if not already initialized
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  print("✅ Background handler called - handling notification");

  try {
    final String type = message.data['type'] ?? '';

    switch (type) {
      case 'message':
        await LocalNotification.showNotificationMessage(
          message.notification?.title ?? '',
          message.notification?.body ?? '',
          message.data['uid'] ?? '',
        );
        break;
      case 'audio':
        await LocalNotification.showNotificationMessage(
          message.notification?.title ?? '',
          message.notification?.body ?? '',
          message.data['uid'] ?? '',
        );
        break;
      case 'AcceptTheRequest':
        await LocalNotification.showNotificationAcceptTheRequest(
          message.notification?.title ?? '',
          message.notification?.body ?? '',
          message.data['uid'] ?? '',
        );
        break;
      case 'RequestRejected':
        await LocalNotification.showNotificationRequestRejected(
          message.notification?.title ?? '',
          message.notification?.body ?? '',
          message.data['uid'] ?? '',
        );
        break;
      case 'ScanerBarCode':
        await LocalNotification.showNotificationScannerBarCode(
          message.notification?.title ?? '',
          message.notification?.body ?? '',
          message.data['uid'] ?? '',
        );
        break;
      case 'Done':
        await LocalNotification.showNotificationDone(
          message.notification?.title ?? '',
          message.notification?.body ?? '',
          message.data['uid'] ?? '',
        );
        break;
      case 'image':
        await LocalNotification.showNotificationMessage(
          message.notification?.title ?? '',
          message.notification?.body ?? '',
          message.data['uid'] ?? '',
        );
        break;
      case 'video':
        await LocalNotification.showNotificationMessage(
          message.notification?.title ?? '',
          message.notification?.body ?? '',
          message.data['uid'] ?? '',
        );
        break;
      default:
        debugPrint('Unhandled notification type: $type');
    }
  } catch (e) {
    debugPrint('Error handling background notification: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.isLoggedIn});
  final bool? isLoggedIn;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      initialBinding: InitialBindings(),
      getPages: AppPages.routes,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // You can use the library anywhere in the app even in theme
      home: isLoggedIn! ? SellerMainScreen() : WelcomePage1(),
    );
  }
}
