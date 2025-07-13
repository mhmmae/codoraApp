import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;

/// Controller للإشعارات المحلية خاص بتطبيق البائع
class LocalNotificationController {
  
  /// الحصول على رمز الوصول لـ Firebase Cloud Messaging
  static Future<String> getAccessToken() async {
    final serviceAccountJson = {
      "type": "service_account",
      "project_id": "codora-app1",
      "private_key_id": "0b629d8df10b84ea48f807c1450e4a55e20949c7",
      "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDXuA2UMoHMNwhI\nOn4lc5i/VSK/5f6Aen/v0Zijp1I0JoiCJm5TrRAZgv51+cj2osW/O6M6AJ2S8g7E\nzjmnUsxjqj/xheZEQVmUY9s8RMywmx5cGERRdZ/0LqJKGgjLH7pScFM64R+bv9cu\nzgRxCRN6Tp++yAILEdUf10wywEp/g4igsiIv+zrLD+fYUqWwqvfoYkuvRjxn48JO\nDEJfuQeBBLTthPnSdOEsmhIRvA3jeB/qL3a6Vw1sDDdSDBgmkR6mVeih1pLoLoj7\nFlobyU4Ncu124ipxn2FcdKd+XmtbO9aMHRbYCpD+MOhqCzYB12brepi53U5D79FC\neGk1DbNRAgMBAAECggEAClTDkbgO2fuTZ0zQgx/+I2uttl21dUG9+Xui68jfpE++\nyeeSm79LaMK1R8Emtr56P1ED3YtEq1JHEsstnQMszA54nCs60+9X8vC1VzWUTVZL\nJe347Ph300ydyR67Z776lWgmaZ4j0rm6pysxW0MsA6IwVFq6flKO+m9n3tEGwFnd\nzC3ow8k62VGC32OSOm5a/7mjN/dlcS53dA7kg5DcGu43iARNX+7NNrVwp838XyL4\nJVM+JnL8CwPmC+ILKn3i1W7H65gcby+F6CQGHY+VpiprMHiOk+BVIZWk3YP43WCk\nasfQsDNqxsg9Ua2ZAUuCDCZosj5au27esg5lWmKGgQKBgQDsBFFKl4+FBDtq8Dty\nRGL/Z7PyviFQsMcFOt0zPI7AcHqmCCmL7yt7MaQlHTSCngxlXKSJ8QLqurO+wCFw\nl6XH2LOubfhiFz5Cl0/u0q29Co25NC6xe9IP7JlEAMx/ukyM8HEs6ngiLTKcI0Ih\nr4IMBbjYFCyRsS2gyl4luMy21QKBgQDp+8bh5bBVpoBoY1LhzhwHA6yVtjSTJREo\nwAPyca4cV7DKTy99M9tbhpkao0tj66Vs4XCKjhNViK1tfsTjAF6dp9/HYqDaTsRb\n8ytDydbKnYinvGoIzW9+FgUO14wuEwAbN+2ItAi6i5To8GqunvYItabSbd6oooFq\n5tS2C5kAjQKBgQDaqnligZ8v3ybpwh9hk+igt0TqfqtBJjeOKeZtJQshUlTf5SoR\nAwsm/WwWEsPmzGWxt66eOtS4AzirXzjcJzQqPyTiU/LPdrdxXN1q6Hidb9y0nZsx\nRwXtSQkLDy5onIN2BQLmWWnqSDPeo3AO45u6ZcbHM5HDfgNHOJcXnerU7QKBgQCe\n1yc6bzz3yCJfux2m4M6yDFJ7B8hFI+K0MTX8viOeZgFENeFdM3j0dzk0lio12ODi\nO2C1DqIdbL2fGXH7UGLqz+3gYxojWVl/umJikIDZ53u/su6gryXDCJvCaZ1mIcvu\nrlb4eI98ZAlg4OTrSkpnuzlWnPOMs1T8B1vbgaAKeQKBgCpZiPJN3ay9+cU2Sl0A\nYHLmKKz7nWo+ltrwIt2hRG1pcJIu3Bz2QBwUKeeVbDtdRygZY46QFUc0+hEyh60z\nyq06c5kazkBVD3GTyI86aRwd9CZ7Q641PHwtu6vk+PAsJEMcHnSQNxx6EqvUOkPD\nLKEnRDLScjJHuoblMohirXgG\n-----END PRIVATE KEY-----\n",
      "client_email": "firebase-adminsdk-fbsvc@codora-app1.iam.gserviceaccount.com",
      "client_id": "100961151944557655382",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40codora-app1.iam.gserviceaccount.com",
      "universe_domain": "googleapis.com"
    };

    List<String> scopes = [
      "https://www.googleapis.com/auth/userinfo.email",
      "https://www.googleapis.com/auth/firebase.database",
      "https://www.googleapis.com/auth/firebase.messaging"
    ];

    http.Client client1 = await auth.clientViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
      scopes,
    );

    auth.AccessCredentials credentials = await auth.obtainAccessCredentialsViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
      scopes,
      client1
    );

    client1.close();
    return credentials.accessToken.data;
  }

  /// إرسال إشعار إلى مستخدم معين
  static Future<void> sendNotificationMessageToUser({
    required String to,
    required String title,
    required String body,
    required String uid,
    required String type,
    String? image,
  }) async {
    try {
      final String serverKey = await getAccessToken();
      final Map<String, dynamic> dataPayload = {
        'uid': uid,
        'type': type,
      };

      if (image != null && image.isNotEmpty) {
        dataPayload['image'] = image;
      }

      final Map<String, dynamic> message = {
        'message': {
          'token': to,
          'notification': {
            'body': body,
            'title': title
          },
          'data': dataPayload,
        }
      };

      const String fcmEndpoint = "https://fcm.googleapis.com/v1/projects/codora-app1/messages:send";

      final http.Response response = await http.post(
        Uri.parse(fcmEndpoint),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $serverKey',
        },
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ تم إرسال الإشعار بنجاح');
      } else {
        debugPrint('❌ فشل في إرسال الإشعار: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ خطأ في إرسال الإشعار: $e');
    }
  }

  /// إرسال إشعار لعدة مستخدمين
  static Future<void> sendNotificationToMultipleUsers({
    required List<String> tokens,
    required String title,
    required String body,
    required String uid,
    required String type,
    String? image,
  }) async {
    for (String token in tokens) {
      if (token.isNotEmpty) {
        await sendNotificationMessageToUser(
          to: token,
          title: title,
          body: body,
          uid: uid,
          type: type,
          image: image,
        );
      }
    }
  }
} 