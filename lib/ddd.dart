// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class DataPage extends StatelessWidget {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
//     app: Firebase.app('SecondaryApp'),
//   );
//
//   // حفظ البيانات إلى Cloud Firestore
//   Future<void> _saveData(String collection, Map<String, dynamic> data) async {
//     try {
//       await _firestore.collection(collection).add(data);
//       print("Data saved successfully");
//     } catch (e) {
//       print("Failed to save data: $e");
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Save Data')),
//       body: Center(
//         child: ElevatedButton(
//           onPressed: () {
//             _saveData('users', {'name': 'Mostafa', 'age': 30});
//           },
//           child: Text('Save Data'),
//         ),
//       ),
//     );
//   }
// }



//
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
//
// class LoginPage extends StatelessWidget {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//
//   // تسجيل الدخول باستخدام البريد الإلكتروني وكلمة المرور
//   Future<void> _signInWithEmailAndPassword(String email, String password) async {
//     try {
//       UserCredential userCredential = await _auth.signInWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//       print("Successfully logged in: ${userCredential.user!.email}");
//     } catch (e) {
//       print("Failed to sign in: $e");
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Login')),
//       body: Center(
//         child: ElevatedButton(
//           onPressed: () {
//             _signInWithEmailAndPassword('test@example.com', 'password123');
//           },
//           child: Text('Sign In'),
//         ),
//       ),
//     );
//   }
// }


//
//
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_native_splash/flutter_native_splash.dart';
// import 'package:get/get.dart';
//
// import 'TheOrder/statistics/statistics.dart';
// import 'bottonBar/botonBar.dart';
//
// import 'controler/local-notification-onroller.dart';
// import 'registration/signin/signinPage.dart';
// import 'firebase_options_login.dart' as login_options;
// import 'firebase_options_data.dart' as data_options;
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
//   FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
//
//   await Firebase.initializeApp(
//     name: 'homy-3693e',
//     options: data_options.DefaultFirebaseOptions.currentPlatform,
//   );
//   await Firebase.initializeApp(
//     name: 'hayderaltlal',
//     options: login_options.DefaultFirebaseOptions.currentPlatform,
//   );
//
//   await messaging.requestPermission(
//     alert: true,
//     announcement: false,
//     badge: true,
//     carPlay: false,
//     criticalAlert: false,
//     provisional: false,
//     sound: true,
//   );
//   await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
//     alert: true, // Required to display a heads up notification
//     badge: true,
//     sound: true,
//   );
//
//   await localNotification.inti();
//
//   runApp(const MyApp());
// }
//
// FirebaseMessaging messaging = FirebaseMessaging.instance;
//
// @pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp(
//     options: data_options.DefaultFirebaseOptions.currentPlatform,
//   );
//
//   if (message.data['type'] == 'message') {
//     await localNotification.showNotoficationMsseage(
//       message.notification!.title.toString(),
//       message.notification!.body.toString(),
//       message.data['uid'],
//     );
//   }
//   // Repeat similar code for other notification types
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return GetMaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: SignInPage(isFirstTime: false),
//     );
//   }
// }
//
// // وظيفة تسجيل الدخول باستخدام مشروع Firebase المخصص لتسجيل الدخول
// Future<void> signIn() async {
//   FirebaseApp loginApp = Firebase.app('hayderaltlal');
//   FirebaseAuth loginAuth = FirebaseAuth.instanceFor(app: loginApp);
//
//   try {
//     UserCredential userCredential = await loginAuth.signInWithEmailAndPassword(
//       email: 'user@example.com',
//       password: 'password',
//     );
//     print('User signed in: ${userCredential.user.email}');
//   } catch (e) {
//     print('Error: $e');
//   }
// }
//
// // وظيفة حفظ البيانات باستخدام مشروع Firebase المخصص لحفظ البيانات
// Future<void> saveData() async {
//   FirebaseApp dataApp = Firebase.app('homy-3693e');
//   FirebaseFirestore firestore = FirebaseFirestore.instanceFor(app: dataApp);
//
//   try {
//     await firestore.collection('data').add({
//       'text': 'Sample data',
//       'timestamp': FieldValue.serverTimestamp(),
//     });
//     print('Data saved');
//   } catch (e) {
//     print('Error: $e');
//   }
// }

