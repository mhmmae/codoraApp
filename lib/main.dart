import 'package:codora/bottonBar/botonBar.dart';
import 'package:codora/registration/signin/signinPage.dart';
import 'package:codora/registration/welcomePage/WelcomePage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/date_symbol_data_local.dart';


import 'controler/local-notification-onroller.dart';
import 'firebase_options.dart';
import 'registration/SginUp/SginUp.dart';
import 'package:permission_handler/permission_handler.dart';




void main() async{
  WidgetsFlutterBinding.ensureInitialized();




  await Firebase.initializeApp(
    name: 'codora',
    options: DefaultFirebaseOptions.currentPlatform,
  );


  // طلب إذن الإشعارات
  await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );
  // إعداد عرض الإشعارات عند ظهورها في المقدمة
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true, // لعرض إشعارات مرئية
    badge: true,
    sound: true,
  );

  // تهيئة نظام الإشعارات المحلية
  await LocalNotification.init();

  // طلب إذن الإشعارات عبر Permission Handler
  await requestNotificationPermission();

   FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);



  await GetStorage.init();
  await initializeDateFormatting();
// <-- تهيئة GetStorage هنا



  final User? currentUser = FirebaseAuth.instance.currentUser;











  runApp( MyApp(isLoggedIn: currentUser != null, )  ); // إذا كان المستخدم مسجل دخولًا أم لا));
}



FirebaseMessaging messaging = FirebaseMessaging.instance;




Future<void> requestNotificationPermission() async {
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
}







@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler1(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (message.data['type'] == 'message') {
    await LocalNotification.showNotificationMessage(message.notification!.title.toString(), message.notification!.body.toString(), message.data['uid'], );
  }
  // ====================================================================================================================================================================
  // ====================================================================================================================================================================
  // ====================================================================================================================================================================


  if (message.data['type'] == 'audio') {
    await LocalNotification.showNotificationMessage(message.notification!.title.toString(), message.notification!.body.toString(), message.data['uid'], );
  }
  // ====================================================================================================================================================================
  // ====================================================================================================================================================================
  // ====================================================================================================================================================================

  // if (message.data['type'] == 'order') {
  //   await localNotification.showNotofication(message.notification!.title.toString(), message.notification!.body.toString(), message.data['uid'] );
  // }
  // ====================================================================================================================================================================
  // ====================================================================================================================================================================
  // ====================================================================================================================================================================

  if (message.data['type'] == 'AcceptTheRequest') {
    await LocalNotification.showNotificationAcceptTheRequest(message.notification!.title.toString(), message.notification!.body.toString(), message.data['uid'], );
  }
  // ====================================================================================================================================================================
  // ====================================================================================================================================================================
  // ====================================================================================================================================================================

  if (message.data['type'] == 'RequestRejected') {
    await LocalNotification.showNotificationRequestRejected(message.notification!.title.toString(), message.notification!.body.toString(), message.data['uid'], );
  }
  // ====================================================================================================================================================================
  // ====================================================================================================================================================================
  // ====================================================================================================================================================================

  if (message.data['type'] == 'ScanerBarCode') {
    await LocalNotification.showNotificationScannerBarCode(message.notification!.title.toString(), message.notification!.body.toString(), message.data['uid'], );
  }

  // ====================================================================================================================================================================
  // ====================================================================================================================================================================
  // ====================================================================================================================================================================

  if (message.data['type'] == 'Done') {
    await LocalNotification.showNotificationDone(message.notification!.title.toString(), message.notification!.body.toString(), message.data['uid'],  );
  }

  // ====================================================================================================================================================================
  // ====================================================================================================================================================================
  // ====================================================================================================================================================================

  if (message.data['type'] == 'image') {
    await LocalNotification.showNotificationMessage(message.notification!.title.toString(), message.notification!.body.toString(), message.data['uid'],);
  }
  // ====================================================================================================================================================================
  // ====================================================================================================================================================================
  // ====================================================================================================================================================================

  if (message.data['type'] == 'video') {
    await LocalNotification.showNotificationMessage(message.notification!.title.toString(), message.notification!.body.toString(), message.data['uid'], );
  }
  // ====================================================================================================================================================================
  // ====================================================================================================================================================================
  // ====================================================================================================================================================================



}
/// التعامل مع الإشعارات الواردة في الخلفية
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  try {
    final String type = message.data['type'];

    switch (type) {
      case 'message':
        await LocalNotification.showNotificationMessage(
          message.notification!.title!,
          message.notification!.body!,
          message.data['uid'],
        );
        break;
      case 'audio':
        await LocalNotification.showNotificationMessage(
          message.notification!.title!,
          message.notification!.body!,
          message.data['uid'],
        );
        break;
      case 'AcceptTheRequest':
        await LocalNotification.showNotificationAcceptTheRequest(
          message.notification!.title!,
          message.notification!.body!,
          message.data['uid'],
        );
        break;
      case 'RequestRejected':
        await LocalNotification.showNotificationRequestRejected(
          message.notification!.title!,
          message.notification!.body!,
          message.data['uid'],
        );
        break;
      case 'ScanerBarCode':
        await LocalNotification.showNotificationScannerBarCode(
          message.notification!.title!,
          message.notification!.body!,
          message.data['uid'],
        );
        break;
      case 'Done':
        await LocalNotification.showNotificationDone(
          message.notification!.title!,
          message.notification!.body!,
          message.data['uid'],
        );
        break;
      case 'image':
        await LocalNotification.showNotificationMessage(
          message.notification!.title!,
          message.notification!.body!,
          message.data['uid'],
        );
        break;
      case 'video':
        await LocalNotification.showNotificationMessage(
          message.notification!.title!,
          message.notification!.body!,
          message.data['uid'],
        );
        break;
      default:
        print('Unhandled notification type: $type');
    }
  } catch (e) {
    print('Error handling background notification: $e');
  }
}





class MyApp extends StatelessWidget {
   MyApp({super.key, this.isLoggedIn});
  final bool? isLoggedIn;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(

        elevation: 0,
        titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold, ),
             ),
             ),

      // You can use the library anywhere in the app even in theme

      home:isLoggedIn!
          ? BottomBar(theIndex: 2,)
          : WelcomePage(),
    );
  }
}


