// In UserModel.dart

import 'package:flutter/foundation.dart';

@immutable
class UserModel {
  final String email;
  final String name;
  final String password; // ملاحظة: تخزين كلمة المرور كنص عادي ليس آمنًا!
  final String phoneNumber;
  final String token; // افترض أن هذا هو توكن FCM
  final String uid;    // معرف المستخدم الفريد، يجب أن يكون هو معرف المستند
  final String url;    // رابط صورة الملف الشخصي للمستخدم
  final String appName;

  const UserModel({
    required this.email,
    required this.name,
    required this.password,
    required this.phoneNumber,
    required this.token,
    required this.uid,
    required this.url,
    required this.appName,
  });

  UserModel copyWith({
    String? email,
    String? name,
    String? password,
    String? phoneNumber,
    String? token,
    String? uid,
    String? url,
    String? appName,
  }) {
    return UserModel(
      email: email ?? this.email,
      name: name ?? this.name,
      password: password ?? this.password,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      token: token ?? this.token,
      uid: uid ?? this.uid,
      url: url ?? this.url,
      appName: appName ?? this.appName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'password': password, // لا تخزن كلمة المرور كنص عادي إذا أمكن تجنب ذلك.
      // Firebase Authentication تدير هذا بشكل آمن.
      'phoneNumber': phoneNumber,
      'token': token, // توكن FCM
      'uid': uid, // لا تحتاج لتخزينه كحقل إذا كان uid هو معرف المستند
      'url': url,   // رابط صورة الملف الشخصي
      'appName': appName,
    };
  }

  // --- التعديل الرئيسي هنا ---
  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId, // <-- استخدام معرف المستند كـ UID الرئيسي
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? 'مستخدم غير معروف', // قيمة افتراضية
      password: map['password'] as String? ?? '', // انتبه لأمان كلمة المرور
      phoneNumber: map['phoneNumber'] as String? ?? map['phneNumber'] as String? ?? '', // التعامل مع التهجئة القديمة + قيمة افتراضية
      token: map['token'] as String? ?? '',
      url: map['url'] as String? ?? '', // رابط صورة افتراضية إذا لم يكن موجودًا
      appName: map['appName'] as String? ?? '',
    );
  }
  // --------------------------

  @override
  String toString() {
    return 'UserModel(uid: $uid, name: $name, email: $email, phoneNumber: $phoneNumber, ...)'; // اختصر للحفاظ على الوضوح
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.uid == uid && // قارن بـ UID أيضًا
        other.email == email &&
        other.name == name &&
        other.password == password &&
        other.phoneNumber == phoneNumber &&
        other.token == token &&
        other.url == url &&
        other.appName == appName;
  }

  @override
  int get hashCode {
    return uid.hashCode ^ // أضف UID
    email.hashCode ^
    name.hashCode ^
    password.hashCode ^
    phoneNumber.hashCode ^
    token.hashCode ^
    url.hashCode ^
    appName.hashCode;
  }
}