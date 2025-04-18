//
// class ModelUser{
//   final String email;
//   final String name;
//   final String password;
//   final String phneNumber;
//   final String token;
//   final String uid;
//   final String url;
//   final String appName;
//
//   ModelUser({required this.url,required this.uid,required this.token,required this.phneNumber,required this.password,required this.email,required this.name,required this.appName});
//
//
//
//   Map<String,dynamic> toMap(){
//     return <String,dynamic>{
//       'email':email,
//       'name':name,
//       'password':password,
//       'phneNumber':phneNumber,
//       'token':token,
//       'uid':uid,
//       'url':url,
//       'appName':appName
//
//
//
//
//
//
//     };
//   }
//
//   factory ModelUser.fromMap(Map<String,dynamic> map){
//     return ModelUser(url: map['url']??'',
//         uid: map['uid']??'',
//         token: map['token']??'',
//         phneNumber: map['phneNumber']??'',
//         password: map['password']??'',
//         email: map['email']??'',
//         name: map['name']??'',
//         appName: map['appName']??'');
//   }
//
// }










import 'package:flutter/foundation.dart';

@immutable
class ModelUser {
  final String email;
  final String name;
  final String password;
  final String phneNumber; // تم تعديل التهجئة هنا
  final String token;
  final String uid;
  final String url;
  final String appName;

  const ModelUser({
    required this.email,
    required this.name,
    required this.password,
    required this.phneNumber,
    required this.token,
    required this.uid,
    required this.url,
    required this.appName,
  });

  /// دالة لإنشاء نسخة جديدة من الكائن مع إمكانية تعديل بعض الحقول فقط.
  ModelUser copyWith({
    String? email,
    String? name,
    String? password,
    String? phoneNumber,
    String? token,
    String? uid,
    String? url,
    String? appName,
  }) {
    return ModelUser(
      email: email ?? this.email,
      name: name ?? this.name,
      password: password ?? this.password,
      phneNumber: phoneNumber ?? this.phneNumber,
      token: token ?? this.token,
      uid: uid ?? this.uid,
      url: url ?? this.url,
      appName: appName ?? this.appName,
    );
  }

  /// تحويل الكائن إلى خريطة (Map) للقراءة/الكتابة في قاعدة البيانات.
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'password': password,
      'phneNumber': phneNumber,
      'token': token,
      'uid': uid,
      'url': url,
      'appName': appName,
    };
  }

  /// المصنع لإنشاء كائن من خريطة (Map).
  factory ModelUser.fromMap(Map<String, dynamic> map) {
    return ModelUser(
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      password: map['password'] ?? '',
      phneNumber: map['phneNumber'] ?? '',
      token: map['token'] ?? '',
      uid: map['uid'] ?? '',
      url: map['url'] ?? '',
      appName: map['appName'] ?? '',
    );
  }

  @override
  String toString() {
    return 'ModelUser(email: $email, name: $name, password: $password, phneNumber: $phneNumber, token: $token, uid: $uid, url: $url, appName: $appName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ModelUser &&
        other.email == email &&
        other.name == name &&
        other.password == password &&
        other.phneNumber == phneNumber &&
        other.token == token &&
        other.uid == uid &&
        other.url == url &&
        other.appName == appName;
  }

  @override
  int get hashCode {
    return email.hashCode ^
    name.hashCode ^
    password.hashCode ^
    phneNumber.hashCode ^
    token.hashCode ^
    uid.hashCode ^
    url.hashCode ^
    appName.hashCode;
  }
}
