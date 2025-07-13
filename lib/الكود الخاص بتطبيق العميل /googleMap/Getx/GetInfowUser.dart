
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';

import '../../../XXX/xxx_firebase.dart';

class GetInfowUser extends GetxController {
  // المتغيرات الأساسية
  final String userId; // معرف المستخدم
  final double latitude; // خط العرض
  final double longitude; // خط الطول

  // معلومات إضافية للمستخدم
  String? urlOfUser; // صورة المستخدم
  String? email; // البريد الإلكتروني
  String? name; // اسم المستخدم
  String? phoneNumber; // رقم الهاتف
  String? deliveryUidOscar1; // معرف التوصيل

  // معلومات جغرافية
  String? nameOfCountry; // اسم الدولة
  String? nameOfGovernorate; // اسم المحافظة
  String? administrativeArea; // المنطقة الإدارية

  // حالة عرض المعلومات
  bool isDeliveryGetUserInformation = false;

  // البناء
  GetInfowUser({
    required this.userId,
    required this.latitude,
    required this.longitude,
  });

  /// جلب معلومات الموقع باستخدام Geocoding
  Future<void> getGeoCoding() async {
    try {
      List<Placemark>? placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        nameOfCountry = placemarks.first.country; // اسم الدولة
        nameOfGovernorate = placemarks.first.locality; // اسم المحافظة
        administrativeArea = placemarks.first.subAdministrativeArea; // المنطقة الإدارية
        update(); // تحديث الحالة
      }
    } catch (e) {
      debugPrint("خطأ أثناء جلب معلومات الموقع: $e");
    }
  }

  /// جلب بيانات المستخدم من Firebase
  Future<void> fetchUserData() async {
    try {
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection(FirebaseX.collectionApp)
          .doc(userId)
          .get();

      if (documentSnapshot.exists) {
        urlOfUser = documentSnapshot.get('url'); // صورة المستخدم
        email = documentSnapshot.get('email'); // البريد الإلكتروني
        name = documentSnapshot.get('name'); // اسم المستخدم
        phoneNumber = documentSnapshot.get('phneNumber'); // رقم الهاتف
        deliveryUidOscar1 = documentSnapshot.get('DeliveryUidOscar1'); // معرف التوصيل
        update(); // تحديث الحالة
      } else {
        debugPrint("المستند غير موجود في Firebase.");
      }
    } catch (e) {
      debugPrint("خطأ أثناء جلب بيانات المستخدم: $e");
    }
  }

  /// يتم تنفيذ هذه الوظائف عند تشغيل التحكم
  @override
  void onInit() {
    super.onInit();
    debugPrint("onInit: بدء جلب البيانات.");

    // جلب بيانات المستخدم
    fetchUserData();

    // جلب معلومات الموقع
    if (longitude != 0) {
      getGeoCoding();
    }
  }
}
