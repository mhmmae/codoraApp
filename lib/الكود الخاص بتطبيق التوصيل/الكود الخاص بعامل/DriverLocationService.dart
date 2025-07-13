import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../../XXX/xxx_firebase.dart'; //  لـ GetxService أو GetxController

//  استورد FirebaseX من تطبيق السائق
// import 'path_to_constants/firebase_x_driver_app.dart';

// مثال لـ FirebaseX
// class FirebaseXDriverApp { static String deliveryDriversCollection = "delivery_drivers"; }


class DriverLocationService extends GetxService { // أو GetxController إذا أردت إدارة حالة أكثر تعقيدًا
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<DocumentSnapshot>? _driverStatusSubscription; // للاستماع لحالة السائق
  String? _currentDriverId;
  bool isServiceActive = false; // لتتبع ما إذا كانت خدمة تتبع الموقع نشطة

  // متغيرات للتحكم في دقة وتواتر التحديثات (يمكن جعلها قابلة للتعديل من إعدادات السائق)
  final LocationAccuracy _desiredAccuracy = LocationAccuracy.high; //  أو best للملاحة
  final int _distanceFilter = 15; //  تحديث الموقع كل 15 مترًا على الأقل
  final Duration _timeInterval = const Duration(seconds: 30); // أو تحديث كل 30 ثانية

  // --- يمكن ربط هذا بحالة السائق الفعلية ---
  // bool _shouldTrackLocation = false; // يتم تحديثها بناءً على availabilityStatus

  @override
  void onInit() {
    super.onInit();
    _currentDriverId = _auth.currentUser?.uid;
    if (_currentDriverId != null) {
      _listenToDriverStatusAndControlTracking();
    } else {
      _auth.authStateChanges().firstWhere((user) => user != null).then((user) {
        _currentDriverId = user?.uid;
        if(_currentDriverId != null) _listenToDriverStatusAndControlTracking();
      });
    }
  }

// In DriverLocationService.dart
  void _listenToDriverStatusAndControlTracking() {
    if (_currentDriverId == null) return;
    _driverStatusSubscription?.cancel();
    _driverStatusSubscription = _firestore
        .collection(FirebaseX.deliveryDriversCollection) // اسم مجموعة السائقين
        .doc(_currentDriverId!)
        .snapshots()
        .listen((driverDoc) {
      if (driverDoc.exists && driverDoc.data() != null) {
        final driverData = driverDoc.data()!;
        final String currentFirestoreStatus = driverData['availabilityStatus'] as String? ?? 'offline';
        debugPrint("DriverLocationService: Received Firestore status update for driver $_currentDriverId: $currentFirestoreStatus");

        bool shouldBeTracking = (currentFirestoreStatus == 'online_available' || currentFirestoreStatus == 'on_task');

        if (shouldBeTracking && !isServiceActive) { // إذا يجب أن يتتبع والخدمة ليست نشطة
          startLocationUpdates();
        } else if (!shouldBeTracking && isServiceActive) { // إذا لا يجب أن يتتبع والخدمة نشطة
          stopLocationUpdates();
        }
      } else {
        debugPrint("DriverLocationService: Driver doc for $_currentDriverId not found. Stopping updates.");
        stopLocationUpdates();
      }
    }, onError: (error){ /* ... */ });
  }


  Future<bool> _checkAndRequestPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  Future<void> startLocationUpdates() async {
    if (_currentDriverId == null) {
      debugPrint("DriverLocationService: Cannot start updates, driverId is null.");
      return;
    }
    if (isServiceActive) {
      debugPrint("DriverLocationService: Updates already active.");
      return;
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint("DriverLocationService: Location services are disabled.");
      //  يمكنك طلب تفعيلها من المستخدم أو إظهار تنبيه
      // await Geolocator.openLocationSettings();
      return;
    }

    bool permissionsGranted = await _checkAndRequestPermissions();
    if (!permissionsGranted) {
      debugPrint("DriverLocationService: Location permissions not granted.");
      // يمكنك إظهار تنبيه للسائق بأهمية الأذونات
      return;
    }

    debugPrint("DriverLocationService: Starting location updates for driver $_currentDriverId...");
    isServiceActive = true;

    // إلغاء أي اشتراك سابق لضمان عدم وجود تكرار
    await _positionStreamSubscription?.cancel();

    final LocationSettings locationSettings = LocationSettings(
      accuracy: _desiredAccuracy,
      distanceFilter: _distanceFilter, // بالمتر
      // timeInterval: _timeInterval, // (Android only) قد لا تعمل بشكل دقيق دائمًا
    );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      debugPrint("DriverLocationService: Position Update for $_currentDriverId - Lat: ${position.latitude}, Lng: ${position.longitude}");
      _updateDriverLocationInFirestore(position);
    }, onError: (error) {
      debugPrint("DriverLocationService: Error in position stream: $error");
      // يمكنك إضافة منطق لإعادة المحاولة أو إيقاف التحديثات بعد عدد معين من الأخطاء
      if (error is LocationServiceDisabledException) {
        stopLocationUpdates(); // أوقف التتبع إذا تم تعطيل خدمة الموقع
      }
    });
    // لتطبيق أندرويد، إذا كنت تريد الخدمة أن تعمل في الخلفية حتى لو أغلق التطبيق
    // ستحتاج إلى استخدام Foreground Service (متقدم ويتطلب كودًا أصليًا أو حزمًا خاصة).
  }

  void stopLocationUpdates() {
    if (!isServiceActive) return;
    debugPrint("DriverLocationService: Stopping location updates for driver $_currentDriverId.");
    _positionStreamSubscription?.cancel();
    isServiceActive = false;
    // (اختياري) يمكنك تحديث الموقع الأخير بـ null أو آخر موقع معروف قبل الإيقاف
    //  _firestore.collection(FirebaseX.deliveryDriversCollection)
    //      .doc(_currentDriverId!)
    //      .update({'currentLocation': null, 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> _updateDriverLocationInFirestore(Position position) async {
    if (_currentDriverId == null) return;
    try {
      await _firestore
          .collection(FirebaseX.deliveryDriversCollection) // تأكد من اسم المجموعة
          .doc(_currentDriverId!)
          .update({
        'currentLocation': GeoPoint(position.latitude, position.longitude),
        'currentLocationAccuracy': position.accuracy,
        'currentLocationTimestamp': Timestamp.fromMillisecondsSinceEpoch(position.timestamp.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch),
        'updatedAt': FieldValue.serverTimestamp(), // لتتبع آخر تحديث للمستند
      });
    } catch (e) {
      debugPrint("DriverLocationService: Error updating location to Firestore: $e");
    }
  }

  @override
  void onClose() {
    debugPrint("DriverLocationService: Closing and stopping updates.");
    _driverStatusSubscription?.cancel();
    stopLocationUpdates(); // تأكد من إيقاف أي تحديثات جارية
    super.onClose();
  }
}