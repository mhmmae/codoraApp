import 'dart:convert'; // لـ jsonEncode
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;

// **تحذير هام جداً:**
// لا تقم أبدًا بتضمين مفتاح حساب الخدمة الخاص (private key) مباشرة في كود التطبيق.
// هذا يعرض مشروع Firebase بالكامل لخطر الاختراق.
// يجب التعامل مع عملية الحصول على رمز الوصول وإرسال الإشعارات عبر خادم آمن (Backend)
// أو استخدام Firebase Cloud Functions.

// الكود التالي يوضح **الهيكل فقط** لكيفية استخدام رمز الوصول وإرسال الرسالة،
// **ولكن يجب عدم استخدام طريقة الحصول على الرمز المضمنة هنا في تطبيق حقيقي.**

class FcmService1 {

  // اسم المشروع (من المفترض أنه ثابت أو يأتي من إعدادات آمنة)
  static const String _projectId = 'codora-app1'; // أو اسم مشروعك
  static const String _fcmEndpoint = 'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send';

  // --- **[خطير: للطوير فقط - لا تستخدم في الإنتاج]** ---
  // هذه الدالة يجب استبدالها بطريقة آمنة للحصول على رمز وصول OAuth2
  // من خادمك الخاص أو Cloud Function.
  static Future<String?> _getAccessToken_UNSAFE_FOR_PRODUCTION() async {
    debugPrint("WARNING: Using embedded service account key. NOT SAFE FOR PRODUCTION.");
    final Map<String, String> serviceaccountjsonUnsafe = {
      "type": "service_account", "project_id": _projectId,
      "private_key_id": "YOUR_PRIVATE_KEY_ID", // استبدل بمعلوماتك
      "private_key": "-----BEGIN PRIVATE KEY-----\nYOUR_PRIVATE_KEY_DATA\n-----END PRIVATE KEY-----\n", // استبدل بالمفتاح الخاص بك
      "client_email": "YOUR_SERVICE_ACCOUNT_EMAIL", // استبدل
      "client_id": "YOUR_CLIENT_ID", // استبدل
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url": "YOUR_CERT_URL" // استبدل
      // "universe_domain": "googleapis.com" // قد يكون ضروريًا أو لا
    };
    // التحقق من أن القيم تم استبدالها (للتذكير فقط)
    if(serviceaccountjsonUnsafe["private_key"]!.contains("YOUR_PRIVATE_KEY")){
      debugPrint("ERROR: Service account details not replaced in _getAccessToken_UNSAFE_FOR_PRODUCTION.");
      return null;
    }

    List<String> scopes = ["https://www.googleapis.com/auth/firebase.messaging"];
    try {
      http.Client client = await auth.clientViaServiceAccount(
          auth.ServiceAccountCredentials.fromJson(serviceaccountjsonUnsafe), scopes);
      final auth.AccessCredentials credentials = await auth.obtainAccessCredentialsViaServiceAccount(
          auth.ServiceAccountCredentials.fromJson(serviceaccountjsonUnsafe), scopes, client);
      client.close();
      debugPrint("Access token obtained (UNSAFE METHOD).");
      return credentials.accessToken.data;
    } catch (e) {
      debugPrint("Error obtaining access token (UNSAFE METHOD): $e");
      return null;
    }
  }


  /// إرسال إشعار FCM واحد.
  /// يجب تعديل هذه الدالة لاستخدام طريقة آمنة للحصول على accessToken.
  static Future<bool> sendFcmNotification({
    required String userToken, // توكن الجهاز المستلم
    required String title,
    required String body,
    required Map<String, String> data, // بيانات إضافية (مثل type, uid, image)
  }) async {
    // --- 1. الحصول على رمز الوصول (بطريقة آمنة في الإنتاج) ---
    // في الإنتاج، استدع دالة Cloud Function أو اطلب من خادمك
    // String? accessToken = await fetchAccessTokenFromServer();
    // --- استخدام الطريقة غير الآمنة (للتجريب فقط مع التحذير) ---
    String? accessToken = await _getAccessToken_UNSAFE_FOR_PRODUCTION();
    if (accessToken == null) {
      debugPrint("Failed to get access token. Cannot send FCM notification.");
      return false; // فشل الإرسال
    }


    // --- 2. بناء الرسالة ---
    final Map<String, dynamic> message = {
      'message': {
        'token': userToken,
        'notification': { 'body': body, 'title': title, },
        // البيانات يجب أن تكون key-value pairs من نوع String فقط
        'data': data,
        // يمكنك إضافة إعدادات Android و APNS هنا لتخصيص الإشعار أكثر
        // 'android': { 'priority': 'high', /* ... */ },
        // 'apns': { 'headers': {'apns-priority': '10'}, 'payload': { 'aps': { 'sound': 'default', /* ... */ } } }
      }
    };

    // --- 3. إرسال الطلب ---
    try {
      debugPrint("Sending FCM notification to token: $userToken");
      final http.Response response = await http.post(
        Uri.parse(_fcmEndpoint),
        headers: <String, String>{ 'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken', },
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        debugPrint('FCM notification sent successfully.');
        return true; // نجاح الإرسال
      } else {
        debugPrint('Error sending FCM notification. Status: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        return false; // فشل الإرسال
      }
    } catch (e) {
      debugPrint('Exception while sending FCM notification: $e');
      return false; // فشل الإرسال بسبب خطأ
    }
  }
}