import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../XXX/xxx_firebase.dart';

class LocationPickerController extends GetxController {
  GoogleMapController? mapController;
  final Rx<LatLng> currentLocation = const LatLng(33.3152, 44.3661).obs; // بغداد كموقع افتراضي
  final RxString selectedAddress = ''.obs;
  final RxString savedAddress = ''.obs;
  final RxBool isLoading = true.obs;
  final RxBool isMapReady = false.obs; // إضافة حالة جاهزية الخريطة
  final RxSet<Marker> markers = <Marker>{}.obs;
  
  @override
  void onInit() {
    super.onInit();
    _initializeLocation();
  }
  
  /// تهيئة الموقع
  Future<void> _initializeLocation() async {
    try {
      debugPrint('🔄 بدء تهيئة الموقع...');
      
      // محاولة الحصول على العنوان المحفوظ من البائع
      await _loadSavedAddress();
      
      // محاولة الحصول على الموقع الحالي
      await getCurrentLocation();
      
      debugPrint('✅ تم تهيئة الموقع بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة الموقع: $e');
      
      // في حالة الخطأ، استخدم الموقع الافتراضي (بغداد)
      selectedAddress.value = 'بغداد، العراق (موقع افتراضي)';
      _updateMarker(currentLocation.value);
    } finally {
      isLoading.value = false;
    }
  }
  
  /// تحميل العنوان المحفوظ للبائع
  Future<void> _loadSavedAddress() async {
    try {
      final String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;
      
      final doc = await FirebaseFirestore.instance
          .collection(FirebaseX.collectionSeller)
          .doc(userId)
          .get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        savedAddress.value = data['shopAddressText'] ?? '';
        
        // إذا كان هناك عنوان محفوظ، استخدمه كموقع افتراضي
        if (savedAddress.value.isNotEmpty) {
          final GeoPoint? location = data['location'] as GeoPoint?;
          if (location != null) {
            currentLocation.value = LatLng(location.latitude, location.longitude);
            selectedAddress.value = savedAddress.value;
            _updateMarker(currentLocation.value);
          }
        }
      }
    } catch (e) {
      debugPrint('خطأ في تحميل العنوان المحفوظ: $e');
    }
  }
  
  /// الحصول على الموقع الحالي
  Future<void> getCurrentLocation() async {
    try {
      debugPrint('📍 محاولة الحصول على الموقع الحالي...');
      
      // التحقق من الصلاحيات
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('🔐 صلاحية الموقع الحالية: $permission');
      
      if (permission == LocationPermission.denied) {
        debugPrint('🔐 طلب صلاحية الموقع...');
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('❌ تم رفض صلاحية الموقع');
          Get.snackbar(
            'خطأ',
            'يرجى السماح بالوصول للموقع',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.withOpacity(0.8),
            colorText: Colors.white,
          );
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        debugPrint('❌ صلاحية الموقع مرفوضة نهائياً');
        Get.snackbar(
          'خطأ',
          'يرجى تفعيل صلاحية الموقع من الإعدادات',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
        return;
      }
      
      debugPrint('✅ صلاحية الموقع مُمنوحة');
      
      // التحقق من تفعيل خدمات الموقع
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('❌ خدمات الموقع غير مُفعلة');
        Get.snackbar(
          'خطأ',
          'يرجى تفعيل خدمات الموقع',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
        return;
      }
      
      debugPrint('🛰️ الحصول على الموقع الحالي...');
      
      // الحصول على الموقع الحالي
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10), // إضافة حد زمني
      );
      
      debugPrint('✅ تم الحصول على الموقع: ${position.latitude}, ${position.longitude}');
      
      final LatLng newLocation = LatLng(position.latitude, position.longitude);
      
      // إذا لم يكن هناك عنوان محفوظ، استخدم الموقع الحالي
      if (savedAddress.value.isEmpty) {
        currentLocation.value = newLocation;
        await _getAddressFromCoordinates(newLocation);
        if (isMapReady.value) {
          _updateMarker(newLocation);
        }
      }
      
      // تحريك الكاميرا للموقع الحالي
      if (mapController != null && isMapReady.value) {
        await mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: currentLocation.value,
              zoom: 15.0,
            ),
          ),
        );
      }
    } on TimeoutException {
      debugPrint('⏰ انتهت مهلة الحصول على الموقع');
      Get.snackbar(
        'تنبيه',
        'انتهت مهلة الحصول على الموقع، جارٍ استخدام الموقع الافتراضي',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withOpacity(0.8),
        colorText: Colors.white,
      );
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على الموقع: $e');
      Get.snackbar(
        'خطأ',
        'فشل في الحصول على الموقع الحالي',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }
  
  /// عند إنشاء الخريطة
  void onMapCreated(GoogleMapController controller) {
    debugPrint('🗺️ تم إنشاء الخريطة بنجاح');
    mapController = controller;
    
    // إضافة تأخير قصير للتأكد من أن الخريطة جاهزة
    Future.delayed(const Duration(milliseconds: 500), () {
      isMapReady.value = true;
      _updateMarker(currentLocation.value);
      
      // تحريك الكاميرا للموقع الحالي
      if (mapController != null) {
        mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: currentLocation.value,
              zoom: 15.0,
            ),
          ),
        );
      }
      debugPrint('✅ الخريطة جاهزة للاستخدام');
    });
  }
  
  /// عند النقر على الخريطة
  Future<void> onMapTap(LatLng location) async {
    currentLocation.value = location;
    await _getAddressFromCoordinates(location);
    _updateMarker(location);
  }
  
  /// تحديث العلامة على الخريطة
  void _updateMarker(LatLng location) {
    markers.clear();
    markers.add(
      Marker(
        markerId: const MarkerId('selected_location'),
        position: location,
        infoWindow: InfoWindow(
          title: 'موقع الاستلام',
          snippet: selectedAddress.value.isNotEmpty ? selectedAddress.value : 'الموقع المحدد',
        ),
      ),
    );
  }
  
  /// الحصول على العنوان من الإحداثيات
  Future<void> _getAddressFromCoordinates(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;
        selectedAddress.value = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.country,
        ].where((element) => element != null && element.isNotEmpty).join(', ');
      }
    } catch (e) {
      debugPrint('خطأ في الحصول على العنوان: $e');
      selectedAddress.value = 'موقع غير محدد';
    }
  }
  
  /// استخدام العنوان المحفوظ
  Future<void> useCurrentLocation() async {
    if (savedAddress.value.isEmpty) return;
    
    try {
      final String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;
      
      final doc = await FirebaseFirestore.instance
          .collection(FirebaseX.collectionSeller)
          .doc(userId)
          .get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final GeoPoint? location = data['location'] as GeoPoint?;
        
        if (location != null) {
          currentLocation.value = LatLng(location.latitude, location.longitude);
          selectedAddress.value = savedAddress.value;
          _updateMarker(currentLocation.value);
          
          // تحريك الكاميرا للموقع المحفوظ
          if (mapController != null) {
            await mapController!.animateCamera(
              CameraUpdate.newLatLng(currentLocation.value),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('خطأ في استخدام العنوان المحفوظ: $e');
    }
  }
  
  /// تأكيد الموقع والانتقال لصفحة تأكيد الطلب
  void confirmLocation() {
    if (selectedAddress.value.isEmpty) {
      Get.snackbar(
        'خطأ',
        'يرجى تحديد موقع صحيح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }
    
    // حفظ الموقع المحدد
    final selectedLocationData = {
      'address': selectedAddress.value,
      'latitude': currentLocation.value.latitude,
      'longitude': currentLocation.value.longitude,
    };
    
    // الانتقال لصفحة تأكيد الطلب
    Get.toNamed('/order-confirmation', arguments: selectedLocationData);
  }
  
  @override
  void onClose() {
    mapController?.dispose();
    super.onClose();
  }
} 