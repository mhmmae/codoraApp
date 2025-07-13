

import 'dart:async';
import 'dart:convert'; // <-- إضافة استيراد jsonDecode و jsonEncode
import 'dart:io';
// import 'package:flutter_dotenv/flutter_dotenv.dart'; // تأكد إذا كنت تستخدمه بالفعل
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:path_provider/path_provider.dart';
// تأكد من أن المسارات والأسماء صحيحة
// افترض وجود ImageX.ImageApp، تأكد من تعريفها بشكل صحيح
// class ImageX { static const String ImageApp = 'app_icon'; } // مثال


class LocalNotification{
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  // --- إعادة تسمية لتحسين الوضوح (اختياري) ---
  static final StreamController<NotificationResponse> notificationTapStreamController = StreamController.broadcast(); // استخدام .broadcast للسماح بأكثر من مستمع إذا لزم الأمر

  // الدالة التي تستدعى عند الضغط على الإشعار
  static void _onNotificationTap(NotificationResponse response) {
    debugPrint("Notification tapped: ${response.payload}"); // طباعة للمساعدة في التصحيح
    notificationTapStreamController.add(response);
  }

  // تهيئة الإشعارات
  static Future<void> init() async { // استخدام void لأنها لا ترجع شيئًا ذا معنى
    const InitializationSettings initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'), // تأكد أن هذا الملف موجود
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
          // يمكنك إضافة onDidReceiveLocalNotification للتعامل مع إشعارات iOS في المقدمة هنا إذا أردت
        )
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        // تحديد الدوال لمعالجة النقرات
        onDidReceiveBackgroundNotificationResponse: _onNotificationTap,
        onDidReceiveNotificationResponse: _onNotificationTap
    );

    // طلب الأذونات (اختياري: يمكن فعله عند الحاجة في التطبيق)
    _requestPermissions();
  }

  // طلب الأذونات (خاص بنظام Android 13+)
  static void _requestPermissions() {
    if (Platform.isAndroid) {
      flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission(); // لنظام Android 13+
    }
    // يمكن إضافة طلب أذونات iOS هنا إذا لم يتم طلبه في DarwinInitializationSettings
  }

  // ---!!! دالة جديدة لعرض إشعار أساسي !!!---
  static Future<void> showBasicNotification({
    required int id, // يجب أن يكون لكل إشعار ID فريد
    required String title,
    required String body,
    Map<String, dynamic>? payloadMap, // استقبل Map
  }) async {
    // تحويل الـ Map إلى JSON String لتمريره كـ payload
    final String? payloadJson = payloadMap != null ? jsonEncode(payloadMap) : null;

    // تعريف تفاصيل الإشعار الأساسية لكل نظام
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'basic_channel_id', // معرف القناة
      'إشعارات عامة',       // اسم القناة (يظهر للمستخدم)
      channelDescription: 'قناة الإشعارات العامة للتطبيق', // وصف القناة
      importance: Importance.max,   // الأهمية القصوى
      priority: Priority.high,    // الأولوية العالية
      // يمكنك إضافة أيقونة مخصصة هنا
      // icon: 'notification_icon', // تأكد من وجودها في android/app/src/main/res/drawable
      playSound: true,
      // يمكنك إضافة صوت مخصص: sound: RawResourceAndroidNotificationSound('notification_sound'),
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      // يمكن إضافة صوت مخصص: sound: 'notification_sound.aiff',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // عرض الإشعار
    try {
      debugPrint("Showing basic notification: id=$id, title=$title, payload=$payloadJson");
      await flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payloadJson, // تمرير JSON String
      );
    } catch (e) {
      debugPrint("Error showing basic notification: $e");
    }
  }
  // ---!!! نهاية الدالة الجديدة !!!---


  // الدوال الأخرى الموجودة (showNotofication, showNotoficationMsseage, ...) يمكن تركها كما هي أو إعادة هيكلتها لاحقًا
  // ملاحظة: يوجد خطأ في showNotofication Done حيث تستخدم BitmapAsset ولكن يجب أن يكون Asset Icon ل Person

  // الدالة التي تتطلب تحميل صورة (للحفاظ عليها كما هي مؤقتا)
  static Future<String> _downloadAndSaveFile(String url, String fileName) async {
    // ... (الكود كما هو، مع التأكد من صلاحية الـ URL ومعالجة الأخطاء) ...
    try {
      final Directory directory = await getApplicationDocumentsDirectory();
      final String filePath = '${directory.path}/$fileName';
      final http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final File file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        return filePath;
      } else {
        throw Exception('Failed to download image: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("Error downloading file: $e");
      // إرجاع قيمة افتراضية أو رمي الخطأ مجددًا
      return ''; // أو throw e;
    }
  }

  // (يجب تمرير المعاملات بالترتيب الصحيح عند استدعائها)
  static Future<void> showNotofication(String title, String body, String payloadString, String imageUrl) async {
    if (imageUrl.isEmpty) {
      // إذا لم يتم توفير صورة، اعرض إشعارًا بسيطًا بدلاً من ذلك
      return showBasicNotification(
        id: 1, // ID ثابت لهذه الحالة
        title: title,
        body: body,
        payloadMap: {'payload_data': payloadString}, // غلّف الـ payload القديم في Map إذا لزم الأمر
      );
    }

    String largeIconPath = '';
    try {
      largeIconPath = await _downloadAndSaveFile(imageUrl, 'large_icon.png');
    } catch (e) {
      debugPrint("Failed to download image for notification: $e");
      // اعرض إشعارًا بسيطًا في حالة فشل التحميل
      return showBasicNotification(
        id: 1,
        title: title,
        body: body,
        payloadMap: {'payload_data': payloadString},
      );
    }

    if (largeIconPath.isEmpty) return; // لم يتم تحميل الصورة

    // ... (الكود المتبقي لتنسيق MessagingStyle)
    final Person lunchBot = Person( name: title, key: 'bot', important: true, bot: true, icon: BitmapFilePathAndroidIcon(largeIconPath));
    final List<Message> messages = <Message>[ Message(body, DateTime.now().add(const Duration(seconds: 20)), lunchBot)];
    final MessagingStyleInformation messagingStyle = MessagingStyleInformation( lunchBot, groupConversation: true, conversationTitle: 'Message', htmlFormatContent: true, htmlFormatTitle: true, messages: messages);
    final DarwinNotificationDetails darwinPlatformChannelSpecifics = DarwinNotificationDetails( attachments: <DarwinNotificationAttachment>[ DarwinNotificationAttachment(largeIconPath) ],);
    final NotificationDetails details = NotificationDetails(
      iOS: darwinPlatformChannelSpecifics,
      android: AndroidNotificationDetails(
        'messaging_channel_id_1', // استخدم ID قناة مختلف
        'رسائل مخصصة', // اسم قناة مختلف
        importance: Importance.high, priority: Priority.max, styleInformation: messagingStyle,
        category: AndroidNotificationCategory.message, // تغيير الـ category إلى message قد يكون أنسب
      ),
    );
    await flutterLocalNotificationsPlugin.show(1, title, body, details, payload: payloadString); // لا تزال تستخدم الـ String الأصلي هنا
  }

  // ... باقي الدوال showNotoficationDone, showNotoficationAcceptTheRequest إلخ ...
  // يمكنك تعديلها لتستخدم showBasicNotification أو تحسينها لتقليل التكرار

  // ----- دوال إرسال الإشعارات (يفضل نقلها إلى كلاس منفصل) -----
  static Future<String> getAccessToken() async { /* ... الكود كما هو ... */
    final serviceAccountJson = { /* ... بيانات الاعتماد ... */
      "type": "service_account", "project_id": "codora-app1", "private_key_id": "0b629d8df10b84ea48f807c1450e4a55e20949c7", "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDXuA2UMoHMNwhI\nOn4lc5i/VSK/5f6Aen/v0Zijp1I0JoiCJm5TrRAZgv51+cj2osW/O6M6AJ2S8g7E\nzjmnUsxjqj/xheZEQVmUY9s8RMywmx5cGERRdZ/0LqJKGgjLH7pScFM64R+bv9cu\nzgRxCRN6Tp++yAILEdUf10wywEp/g4igsiIv+zrLD+fYUqWwqvfoYkuvRjxn48JO\nDEJfuQeBBLTthPnSdOEsmhIRvA3jeB/qL3a6Vw1sDDdSDBgmkR6mVeih1pLoLoj7\nFlobyU4Ncu124ipxn2FcdKd+XmtbO9aMHRbYCpD+MOhqCzYB12brepi53U5D79FC\neGk1DbNRAgMBAAECggEAClTDkbgO2fuTZ0zQgx/+I2uttl21dUG9+Xui68jfpE++\nyeeSm79LaMK1R8Emtr56P1ED3YtEq1JHEsstnQMszA54nCs60+9X8vC1VzWUTVZL\nJe347Ph300ydyR67Z776lWgmaZ4j0rm6pysxW0MsA6IwVFq6flKO+m9n3tEGwFnd\nzC3ow8k62VGC32OSOm5a/7mjN/dlcS53dA7kg5DcGu43iARNX+7NNrVwp838XyL4\nJVM+JnL8CwPmC+ILKn3i1W7H65gcby+F6CQGHY+VpiprMHiOk+BVIZWk3YP43WCk\nasfQsDNqxsg9Ua2ZAUuCDCZosj5au27esg5lWmKGgQKBgQDsBFFKl4+FBDtq8Dty\nRGL/Z7PyviFQsMcFOt0zPI7AcHqmCCmL7yt7MaQlHTSCngxlXKSJ8QLqurO+wCFw\nl6XH2LOubfhiFz5Cl0/u0q29Co25NC6xe9IP7JlEAMx/ukyM8HEs6ngiLTKcI0Ih\nr4IMBbjYFCyRsS2gyl4luMy21QKBgQDp+8bh5bBVpoBoY1LhzhwHA6yVtjSTJREo\nwAPyca4cV7DKTy99M9tbhpkao0tj66Vs4XCKjhNViK1tfsTjAF6dp9/HYqDaTsRb\n8ytDydbKnYinvGoIzW9+FgUO14wuEwAbN+2ItAi6i5To8GqunvYItabSbd6oooFq\n5tS2C5kAjQKBgQDaqnligZ8v3ybpwh9hk+igt0TqfqtBJjeOKeZtJQshUlTf5SoR\nAwsm/WwWEsPmzGWxt66eOtS4AzirXzjcJzQqPyTiU/LPdrdxXN1q6Hidb9y0nZsx\nRwXtSQkLDy5onIN2BQLmWWnqSDPeo3AO45u6ZcbHM5HDfgNHOJcXnerU7QKBgQCe\n1yc6bzz3yCJfux2m4M6yDFJ7B8hFI+K0MTX8viOeZgFENeFdM3j0dzk0lio12ODi\nO2C1DqIdbL2fGXH7UGLqz+3gYxojWVl/umJikIDZ53u/su6gryXDCJvCaZ1mIcvu\nrlb4eI98ZAlg4OTrSkpnuzlWnPOMs1T8B1vbgaAKeQKBgCpZiPJN3ay9+cU2Sl0A\nYHLmKKz7nWo+ltrwIt2hRG1pcJIu3Bz2QBwUKeeVbDtdRygZY46QFUc0+hEyh60z\nyq06c5kazkBVD3GTyI86aRwd9CZ7Q641PHwtu6vk+PAsJEMcHnSQNxx6EqvUOkPD\nLKEnRDLScjJHuoblMohirXgG\n-----END PRIVATE KEY-----\n",
      "client_email": "firebase-adminsdk-fbsvc@codora-app1.iam.gserviceaccount.com", "client_id": "100961151944557655382", "auth_uri": "https://accounts.google.com/o/oauth2/auth", "token_uri": "https://oauth2.googleapis.com/token", "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs", "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40codora-app1.iam.gserviceaccount.com", "universe_domain": "googleapis.com" };
    List<String> scopes = [ "https://www.googleapis.com/auth/userinfo.email", "https://www.googleapis.com/auth/firebase.database", "https://www.googleapis.com/auth/firebase.messaging" ];
    http.Client client1 = await auth.clientViaServiceAccount( auth.ServiceAccountCredentials.fromJson(serviceAccountJson), scopes, );
    auth.AccessCredentials credentials = await auth.obtainAccessCredentialsViaServiceAccount( auth.ServiceAccountCredentials.fromJson(serviceAccountJson), scopes, client1 ); client1.close();
    return credentials.accessToken.data;
  }

  // OLD:
// static Future<void> sendNotificationMessageToUser(String to, String title, String body, String uid, String type, {String? image}) async { ... }

// NEW:
  static Future<void> sendNotificationMessageToUser({
    required String to,
    required String title,
    required String body,
    required String uid,
    required String type,
    String? image, // يبقى هذا اختياريًا مُسمى
    // يمكنك إضافة required له إذا أردت أن يكون إلزاميًا أيضًا
  }) async {
    final String serverKey = await getAccessToken() ;
    final Map<String, dynamic> dataPayload = { 'uid': uid, 'type': type, };
    if (image != null && image.isNotEmpty) { dataPayload['image'] = image; }

    final Map<String, dynamic> message = {
      'message': {
        'token': to,
        'notification': { 'body': body, 'title': title },
        'data': dataPayload,
      }
    };

    const String fcmEndpoint = "https://fcm.googleapis.com/v1/projects/codora-app1/messages:send"; // تأكد من اسم المشروع الصحيح

    try {
      final http.Response response = await http.post(
        Uri.parse(fcmEndpoint),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $serverKey',
        },
        body: jsonEncode(message),
      );
      if (response.statusCode == 200) { debugPrint('FCM message sent successfully!'); }
      else { debugPrint('Failed to send FCM message: ${response.statusCode} - ${response.body}'); }
    } catch (e) { debugPrint('Error sending FCM message: $e'); }
  }

  // Missing methods that were referenced in main.dart
  static Future<void> showNotificationMessage(String title, String body, String payload) async {
    await showBasicNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      payloadMap: {'payload_data': payload},
    );
  }

  static Future<void> showNotificationAcceptTheRequest(String title, String body, String payload) async {
    await showBasicNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      payloadMap: {'type': 'accept_request', 'payload_data': payload},
    );
  }

  static Future<void> showNotificationRequestRejected(String title, String body, String payload) async {
    await showBasicNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      payloadMap: {'type': 'request_rejected', 'payload_data': payload},
    );
  }

  static Future<void> showNotificationScannerBarCode(String title, String body, String payload) async {
    await showBasicNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      payloadMap: {'type': 'scanner_barcode', 'payload_data': payload},
    );
  }

  static Future<void> showNotificationDone(String title, String body, String payload) async {
    await showBasicNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      payloadMap: {'type': 'done', 'payload_data': payload},
    );
  }

} // نهاية كلاس LocalNotification