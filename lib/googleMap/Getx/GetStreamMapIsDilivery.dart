
// import 'dart:async';
//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
//
//
// import 'package:geolocator/geolocator.dart';
// import 'package:get/get.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
//
// class Getstreammapisdilivery extends GetxController {
//   GoogleMapController? controller2;
//
//   bool idDelivery;
//
//   double latitude;
//
//   double longitude;
//
//   Getstreammapisdilivery(
//       {required this.idDelivery, required this.longitude, required this.latitude,});
//
//
//   late StreamSubscription<Position> positionStream;
//
//
//   Future<Position> _determinePosition() async {
//     bool serviceEnabled;
//     LocationPermission permission;
//
//     // Test if location services are enabled.
//     serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//
//     }
//
//     permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//
//     }
//
//     if (permission == LocationPermission.deniedForever) {
//       // Permissions are denied forever, handle appropriately.
//
//     }
//
//     if (permission == LocationPermission.whileInUse ||
//         permission == LocationPermission.always) {
//       positionStream = Geolocator.getPositionStream().listen(
//               (Position? position) {
//             FirebaseFirestore.instance.collection('DeliveryUser').doc(
//                 FirebaseAuth.instance.currentUser!.uid).set({
//               'latitudeDelivery': position!.latitude,
//               'longitudeDelivery': position.longitude,
//
//             });
//             controller2?.animateCamera(CameraUpdate.newLatLng(
//                 longitude.isNaN ? const LatLng(0, 0) : LatLng(
//                     position.latitude, position.longitude)));
//
//
//             latitude = position.latitude;
//             longitude = position.longitude;
//             update();
//           });
//     }
//
//
//     return await Geolocator.getCurrentPosition();
//   }
//
//   // ~~~~~~~~~~~~~~~~~~{{{{{{{{{{{{{{{{}}}}}}}}}}}}}{{{{{{{{{{{{{{{{{}{{{{{{{{{{{{{{{{{{{{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//   // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//   // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//   // ~~~~~~~~~~~~~~~~~~~~~~~~=========================================================~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//   // -------------------------------------------------------
//
//
//   // -------------------------------------------------------
//
//
//   @override
//   void onInit() {
//     print('onInit 0====================================================0');
//
//
//     _determinePosition();
//
//
//     // TODO: implement onInit
//     super.onInit();
//   }
//
//   @override
//   void onClose() {
//     positionStream.cancel();
//
//     controller2!.dispose();
//
//     print('onClose 0====================================================0');
//
//     // TODO: implement onClose
//     super.onClose();
//   }
// }
//



















import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GetStreamMapIsDelivery extends GetxController {
  GoogleMapController? controller2; // للتحكم في الخريطة
  bool idDelivery; // حالة التوصيل
  double latitude; // خط العرض
  double longitude; // خط الطول
  late StreamSubscription<Position> positionStream; // الاشتراك في تغييرات الموقع

  // بناء الكائن مع المتغيرات الأساسية
  GetStreamMapIsDelivery({
    required this.idDelivery,
    required this.longitude,
    required this.latitude,
  });


  bool isDeliveryInfoVisible = false; // حالة عرض بيانات المستخدم
  Map<String, dynamic>? selectedUser; // بيانات المستخدم الحالي

  /// باقي الكود...

  /// التفاعل عند الضغط على Marker
  void onMarkerTap(Map<String, dynamic> user) {
    selectedUser = user; // تعيين بيانات المستخدم المختار
    isDeliveryInfoVisible = true; // إظهار واجهة المستخدم
    update(); // تحديث الحالة لعرض التغييرات
  }

  /// إخفاء بيانات المستخدم
  void hideDeliveryInfo() {
    isDeliveryInfoVisible = false; // إخفاء واجهة البيانات
    update(); // تحديث الحالة
  }

  /// التحقق من الأذونات وتحديد الموقع
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // التحقق من تفعيل خدمات الموقع
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('خدمات الموقع معطلة. يرجى تفعيلها.');
      return Future.error('خدمات الموقع معطلة.');
    }

    // التحقق من حالة الأذونات
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('تم رفض الأذونات.');
        return Future.error('تم رفض الأذونات.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('تم رفض الأذونات بشكل دائم.');
      return Future.error('تم رفض الأذونات بشكل دائم.');
    }

    // الاشتراك في تدفق الموقع إذا كانت الأذونات مسموحة
    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      positionStream = Geolocator.getPositionStream().listen((Position? position) {
        if (position != null) {
          // تحديث الموقع في Firebase
          FirebaseFirestore.instance
              .collection('DeliveryUser')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .set({
            'latitudeDelivery': position.latitude,
            'longitudeDelivery': position.longitude,
          });

          // تحريك كاميرا الخريطة إلى الموقع الجديد
          controller2?.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(position.latitude, position.longitude),
            ),
          );

          // تحديث القيم المحلية
          latitude = position.latitude;
          longitude = position.longitude;
          update();
        }
      });
    }

    // الحصول على الموقع الحالي
    return await Geolocator.getCurrentPosition();
  }

  /// تحديث الموقع الحالي يدويًا (ميزة إضافية)
  Future<void> refreshLocation() async {
    try {
      Position position = await _determinePosition();
      print('الموقع الحالي: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('خطأ أثناء تحديث الموقع: $e');
    }
  }

  /// تشغيل الكود عند بدء التحكم
  @override
  void onInit() {
    super.onInit();
    print('onInit: بدء التحكم.');

    // بدء تحديد الموقع
    _determinePosition();
  }

  /// تنظيف الموارد عند إغلاق التحكم
  @override
  void onClose() {
    positionStream.cancel(); // إلغاء الاشتراك في تدفق الموقع
    controller2?.dispose(); // التخلص من GoogleMapController إذا كان مستخدمًا
    print('onClose: تم إغلاق التحكم.');
    super.onClose();
  }
}

