







import 'dart:async';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../../../../XXX/xxx_firebase.dart';
import '../../../googleMap/googleMap.dart';

/// المتحكم الخاص بتنقل المُستخدم إلى شاشة الخريطة (Delivery) بعد قراءة الباركود.
/// يتضمن دوال لتحميل صورة الـ Marker من الأصول، جلب الموقع الحالي، والتحقق من صلاحيات الموقع.
class GetGoToMapDelivery extends GetxController {
  // عدد الخرائط الموجودة (يتم تحديثه من Firestore)
  int numberOfMaps = 0;

  // حالة التحميل للمؤشرات، يُستخدم لتحديد ما إذا كانت العملية جارية
  bool isLoading = false;

  // خاصية لتحميل وتخزين بيانات الـ Marker
  Uint8List? markerDelivery;
  Uint8List? markerUser;

  // اشتراك في موقع المستخدم (إن احتجت لمتابعة التغييرات بشكل مستمر)
  late StreamSubscription<Position> positionStream;

  /// دالة لتحميل صورة من الأصول وتحويلها إلى Uint8List لاستخدامها كشكل Marker.
  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }

  /// دالة تحميل الـ Markers (العلامات) من الأصول.
  /// يتم تحميل صورة التطبيق كـ Marker للتوصيل (markerDelivery) وصورة المنزل للمستخدم (markerUser).
  Future<void> loadMarkers() async {
    isLoading = true;
    update();
    // تحميل صورتين من الأصول مع حجم 60 بكسل
    final Uint8List markerDeliveryData = await getBytesFromAsset(ImageX.ImageApp, 40);
    final Uint8List markerUserData = await getBytesFromAsset(ImageX.ImageHome, 40);
    markerDelivery = markerDeliveryData;
    markerUser = markerUserData;
    isLoading = false;
    update();
  }

  /// دالة إرسال الطلب:
  /// - تتحقق من توفر خدمات الموقع وأذونات الوصول.
  /// - تجمع بيانات الموقع الحالي.
  /// - تنتقل إلى شاشة الخريطة (googleMap) مع تمرير الإحداثيات والـ Markers.
  Future<Position> send() async {
    isLoading = true;
    update();

    // تحقق من أن خدمة الموقع مفعلة
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar(
        'تنبيه',
        'خدمات الموقع غير مفعلة. يرجى تفعيلها في إعدادات الجهاز.',
        icon: const Icon(Icons.location_off, color: Colors.white),
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      isLoading = false;
      update();
      return Future.error("خدمات الموقع غير مفعلة");
    }

    // تحقق من أذونات الموقع
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar(
          'تنبيه',
          'تم رفض أذونات الموقع.',
          icon: const Icon(Icons.block, color: Colors.white),
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        isLoading = false;
        update();
        return Future.error("أذونات الموقع مرفوضة");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Get.snackbar(
        'تنبيه',
        'أذونات الموقع مرفوضة بشكل دائم. الرجاء تحديث إعدادات الجهاز.',
        icon: const Icon(Icons.block, color: Colors.white),
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      isLoading = false;
      update();
      return Future.error("أذونات الموقع مرفوضة بشكل دائم");
    }

    // الحصول على الموقع الحالي
    Position currentPosition = await Geolocator.getCurrentPosition();
    double latitude = currentPosition.latitude;
    double longitude = currentPosition.longitude;
    update();

    // الانتقال إلى شاشة الخريطة مع تمرير بيانات الموقع والـ Markers
    Get.to(
          () => GoogleMapView(
        isDelivery: true,
        latitude: latitude,
        longitude: longitude,
        markerUser: markerUser,
        markerDelivery: markerDelivery,
      ),
    );

    isLoading = false;
    update();
    return currentPosition;
  }

  @override
  void onInit() {
    // عند التهيئة، جلب عدد الخرائط من مجموعة DeliveryUser (إذا كنت تحتاج ذلك)
    FirebaseFirestore.instance
        .collection('DeliveryUser')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('DeliveryUID')
        .get()
        .then((QuerySnapshot snapshot) {
      numberOfMaps = snapshot.docs.length;
      debugPrint('عدد خرائط التوصيل: $numberOfMaps');
      update();
    });
    super.onInit();
  }
}
