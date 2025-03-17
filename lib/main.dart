import 'package:codora/bottonBar/botonBar.dart';
import 'package:codora/registration/signin/signinPage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


import 'controler/local-notification-onroller.dart';
import 'firebase_options.dart';
import 'registration/SginUp/SginUp.dart';
import 'package:permission_handler/permission_handler.dart';




void main() async{
  WidgetsFlutterBinding.ensureInitialized();



  // await Firebase.initializeApp(
  //   name: 'homy-3693e',
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );
  await Firebase.initializeApp(
    name: 'codora',
    options: DefaultFirebaseOptions.currentPlatform,
  );


   await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true, // Required to display a heads up notification
    badge: true,
    sound: true,
  );

  await localNotification.inti();
  requestNotificationPermission();

   FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
















  runApp(const MyApp());
}



FirebaseMessaging messaging = FirebaseMessaging.instance;




Future<void> requestNotificationPermission() async {
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
}







@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (message.data['type'] == 'message') {
    await localNotification.showNotoficationMsseage(message.notification!.title.toString(), message.notification!.body.toString(), message.data['uid'], );
  }
  // ====================================================================================================================================================================
  // ====================================================================================================================================================================
  // ====================================================================================================================================================================


  if (message.data['type'] == 'audio') {
    await localNotification.showNotoficationMsseage(message.notification!.title.toString(), message.notification!.body.toString(), message.data['uid'], );
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
    await localNotification.showNotoficationAcceptTheRequest(message.notification!.title.toString(), message.notification!.body.toString(), message.data['uid'], );
  }
  // ====================================================================================================================================================================
  // ====================================================================================================================================================================
  // ====================================================================================================================================================================

  if (message.data['type'] == 'RequestRejected') {
    await localNotification.showNotoficationRequestRejected(message.notification!.title.toString(), message.notification!.body.toString(), message.data['uid'], );
  }
  // ====================================================================================================================================================================
  // ====================================================================================================================================================================
  // ====================================================================================================================================================================

  if (message.data['type'] == 'ScanerBarCode') {
    await localNotification.showNotoficationScanerBarCode(message.notification!.title.toString(), message.notification!.body.toString(), message.data['uid'], );
  }

  // ====================================================================================================================================================================
  // ====================================================================================================================================================================
  // ====================================================================================================================================================================

  if (message.data['type'] == 'Done') {
    await localNotification.showNotoficationDone(message.notification!.title.toString(), message.notification!.body.toString(), message.data['uid'],  );
  }

  // ====================================================================================================================================================================
  // ====================================================================================================================================================================
  // ====================================================================================================================================================================

  if (message.data['type'] == 'image') {
    await localNotification.showNotoficationMsseage(message.notification!.title.toString(), message.notification!.body.toString(), message.data['uid'],);
  }
  // ====================================================================================================================================================================
  // ====================================================================================================================================================================
  // ====================================================================================================================================================================

  if (message.data['type'] == 'video') {
    await localNotification.showNotoficationMsseage(message.notification!.title.toString(), message.notification!.body.toString(), message.data['uid'], );
  }
  // ====================================================================================================================================================================
  // ====================================================================================================================================================================
  // ====================================================================================================================================================================



}





class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,

      // You can use the library anywhere in the app even in theme

      home: bottonBar(theIndex: 0,)
    );
  }
}


