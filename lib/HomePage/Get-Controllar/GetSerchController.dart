//
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// import '../../bottonBar/botonBar.dart';
// import '../../controler/local-notification-onroller.dart';
//
// class GetSearchController extends GetxController{
//   late PageController pageController;
//   int corintPage = 0;
//
//   @override
//   void onInit() {
//     // TODO: implement onInit
//     pageController = PageController(
//       initialPage: corintPage,
//     );
//
//
//     if(!localNotification.streamController2.hasListener){
//       localNotification.streamController2.stream.listen((notificatin) {
//         if (notificatin.id == 6) {
//           Get.to(bottonBar(theIndex: 2,));
//         }
//
//
//         if (notificatin.id == 2) {
//           Get.to(bottonBar(theIndex: 0,));
//         }
//
//
//
//         if (notificatin.id == 3) {
//           Get.to(bottonBar(theIndex: 0,));
//         }
//
//         if (notificatin.id == 4) {
//           Get.to(bottonBar(theIndex: 3,));
//         }
//
//
//         if (notificatin.id == 5) {
//           Get.to(bottonBar(theIndex: 0,));
//         }
//
//
//         else {
//           print('eeeeeee');
//         }
//       });
//       print('1111111qqqqqqqaaaaaaaaaaaaa');
//
//     }
//
//
//
//
//     // streamNotification();
//     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message)async{
//
//       if (message.data['type'] == 'message') {
//         await localNotification.showNotoficationMsseage(message.notification!.title.toString(), message.notification!.body.toString(), message.data['uid'],);
//       }
//
//
//
//       if (message.data['type'] == 'audio') {
//         await localNotification.showNotoficationMsseage(message.notification!.title.toString(), message.notification!.body.toString(), message.data['uid']);
//       }
//
//
//       if (message.data['type'] == 'AcceptTheRequest') {
//         await localNotification.showNotoficationAcceptTheRequest(message.notification!.title.toString(), message.notification!.body.toString(), message.data['uid']);
//       }
//
//
//       if (message.data['type'] == 'RequestRejected') {
//         await localNotification.showNotoficationRequestRejected(message.notification!.title.toString(), message.notification!.body.toString(), message.data['uid'], );
//       }
//
//       if (message.data['type'] == 'ScanerBarCode') {
//         await localNotification.showNotoficationScanerBarCode(message.notification!.title.toString(), message.notification!.body.toString(), message.data['uid']);
//       }
//
//
//
//       if (message.data['type'] == 'Done') {
//         await localNotification.showNotoficationDone(message.notification!.title.toString(), message.notification!.body.toString(), message.data['uid'], );
//       }
//
//
//       if (message.data['type'] == 'image') {
//         await localNotification.showNotoficationMsseage(message.notification!.title.toString(), message.notification!.body.toString(), message.data['uid'],);
//       }
//
//       if (message.data['type'] == 'video') {
//         await localNotification.showNotoficationMsseage(message.notification!.title.toString(), message.notification!.body.toString(), message.data['uid']);
//       }
//
//     });
//
//
//     FirebaseMessaging.onMessage.listen((RemoteMessage message)async{
//
//
//
//
//
//       if (message.data['type'] == 'message') {
//        await localNotification.showNotoficationMsseage(message.notification!.title.toString(), message.notification!.body.toString(), message.data['uid'], );
//       }
//
//
//       if (message.data['type'] == 'audio') {
//        await localNotification.showNotoficationMsseage(message.notification!.title.toString(), message.notification!.body.toString(), message.data['uid'], );
//       }
//
//
//       if (message.data['type'] == 'AcceptTheRequest') {
//         await localNotification.showNotoficationAcceptTheRequest(message.notification!.title.toString(), message.notification!.body.toString(), message.data['uid'],);
//       }
//
//       if (message.data['type'] == 'RequestRejected') {
//         await localNotification.showNotoficationRequestRejected(message.notification!.title.toString(), message.notification!.body.toString(), message.data['uid'], );
//       }
//
//
//       if (message.data['type'] == 'ScanerBarCode') {
//         await localNotification.showNotoficationScanerBarCode(message.notification!.title.toString(), message.notification!.body.toString(), message.data['uid'], );
//       }
//
//
//       if (message.data['type'] == 'Done') {
//         await localNotification.showNotoficationDone(message.notification!.title.toString(), message.notification!.body.toString(), message.data['uid'], );
//       }
//
//
//       if (message.data['type'] == 'image') {
//         await localNotification.showNotoficationMsseage(message.notification!.title.toString(), message.notification!.body.toString(), message.data['uid'],);
//       }
//
//
//       if (message.data['type'] == 'video') {
//         await localNotification.showNotoficationMsseage(message.notification!.title.toString(), message.notification!.body.toString(), message.data['uid'], );
//       }
//
//
//     });
//
//
//
//     super.onInit();
//   }
//
//
//   @override
//   void dispose() {
//     // TODO: implement dispose
//     pageController.dispose();
//
//
//     super.dispose();
//   }
//
//   @override
//   void onClose() {
//
//
//
//     // TODO: implement onClose
//     super.onClose();
//   }
//
//
// }


















import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../bottonBar/botonBar.dart';
import '../../controler/local-notification-onroller.dart';

class GetSearchController extends GetxController {
  /// متحكم الصفحات في الواجهة (PageController)
  late PageController pageController;
  int currentPage = 0;

  @override
  void onInit() {
    super.onInit();
    // تهيئة الـ PageController مع الصفحة الابتدائية المحددة
    pageController = PageController(initialPage: currentPage);

    // إضافة مستمع لقناة الإشعارات المحلية (localNotification)
    // يتم استخدام قناة Stream واحدة فقط عند عدم وجود مستمع سابق
    if (!LocalNotification.streamController.hasListener) {
      LocalNotification.streamController.stream.listen((notification) {
        _handleLocalNotification(notification);
      });
      print('تم تسجيل مستمع للإشعارات المحلية.');
    }

    // تسجيل مستمع لإشعارات Firebase عند فتح التطبيق عبر النقر على الإشعار
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      await _handleFirebaseMessage(message);
    });

    // تسجيل مستمع لإشعارات Firebase أثناء تواجد التطبيق في المقدمة
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      await _handleFirebaseMessage(message);
    });
  }

  /// دالة لمعالجة الإشعارات المحلية (من streamController2)
  /// تعتمد على خاصية [id] في الإشعار لتحديد الإجراء المناسب
  void _handleLocalNotification(dynamic notification) {
    switch (notification.id) {
      case 6:
        Get.to(BottomBar(theIndex: 2));
        break;
      case 2:
      case 3:
      case 5:
        Get.to(BottomBar(theIndex: 0));
        break;
      case 4:
        Get.to(BottomBar(theIndex: 3));
        break;
      default:
        print('إشعار غير معالج، id: ${notification.id}');
        break;
    }
  }

  /// دالة لمعالجة رسائل Firebase الواردة
  /// تقوم بفك بيانات الرسالة وتحديد نوعها ثم استدعاء الدالة المناسبة من localNotification
  Future<void> _handleFirebaseMessage(RemoteMessage message) async {
    try {
      // استخراج نوع الرسالة وعناصرها الرئيسية
      final String type = message.data['type'];
      final String title = message.notification?.title?.toString() ?? '';
      final String body = message.notification?.body?.toString() ?? '';
      final String uid = message.data['uid'] ?? '';

      switch (type) {
      // للأنواع التي تستخدم طريقة عرض الرسالة نفسها
        case 'message':
        case 'audio':
        case 'image':
        case 'video':
          await LocalNotification.showNotificationMessage(title, body, uid);
          break;
        case 'AcceptTheRequest':
          await LocalNotification.showNotificationAcceptTheRequest(title, body, uid);
          break;
        case 'RequestRejected':
          await LocalNotification.showNotificationRequestRejected(title, body, uid);
          break;
        case 'ScanerBarCode':
          await LocalNotification.showNotificationScannerBarCode(title, body, uid);
          break;
        case 'Done':
          await LocalNotification.showNotificationDone(title, body, uid);
          break;
        default:
          print('نوع الرسالة غير معالج: $type');
      }
    } catch (e) {
      print('حدث خطأ أثناء معالجة رسالة Firebase: $e');
    }
  }

  @override
  void dispose() {
    // عند التخلص من الـ Controller يتم التخلص من PageController
    pageController.dispose();
    super.dispose();
  }

  @override
  void onClose() {
    // يمكن وضع عمليات تنظيف إضافية هنا إذا لزم الأمر
    super.onClose();
  }
}
