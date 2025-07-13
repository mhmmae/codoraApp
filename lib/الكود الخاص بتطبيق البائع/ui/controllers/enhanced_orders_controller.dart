import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../XXX/xxx_firebase.dart';

class EnhancedOrdersController extends GetxController {
  final RxList<Map<String, dynamic>> allOrders = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> filteredOrders = <Map<String, dynamic>>[].obs;
  final RxString selectedFilter = 'all'.obs; // all, customer, retail
  final RxBool isLoading = false.obs;
  
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  
  @override
  void onInit() {
    super.onInit();
    loadOrders();
    ever(selectedFilter, (_) => _applyFilter());
  }
  
  /// تحميل جميع الطلبات
  Future<void> loadOrders() async {
    if (currentUserId == null) return;
    
    isLoading.value = true;
    try {
      final QuerySnapshot ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('appName', isEqualTo: FirebaseX.appName)
          .where('uidAdd', isEqualTo: currentUserId)
          .orderBy('timeOrder', descending: true)
          .get();
      
      List<Map<String, dynamic>> orders = [];
      
      for (var orderDoc in ordersSnapshot.docs) {
        final orderData = orderDoc.data() as Map<String, dynamic>;
        
        // تحديد نوع الطلب
        final String orderType = orderData['orderType'] ?? 'customer';
        
        // تحميل بيانات المستخدم/المشتري
        Map<String, dynamic>? userData;
        if (orderType == 'retail') {
          // طلب من بائع تجزئة - الحصول على البيانات من buyerInfo
          userData = orderData['buyerInfo'] as Map<String, dynamic>?;
        } else {
          // طلب من مستخدم عادي - الحصول على البيانات من collection المستخدمين
          try {
            final userDoc = await FirebaseFirestore.instance
                .collection(FirebaseX.collectionApp)
                .doc(orderData['uidUser'])
                .get();
            
            if (userDoc.exists) {
              userData = userDoc.data() as Map<String, dynamic>;
            }
          } catch (e) {
            debugPrint('خطأ في تحميل بيانات المستخدم: $e');
          }
        }
        
        // إضافة بيانات الطلب مع معلومات المستخدم
        orders.add({
          ...orderData,
          'userData': userData,
          'orderType': orderType,
          'docId': orderDoc.id,
        });
      }
      
      allOrders.value = orders;
      _applyFilter();
      
    } catch (e) {
      debugPrint('خطأ في تحميل الطلبات: $e');
      Get.snackbar(
        'خطأ',
        'فشل في تحميل الطلبات',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  /// تطبيق الفلتر
  void _applyFilter() {
    switch (selectedFilter.value) {
      case 'customer':
        filteredOrders.value = allOrders
            .where((order) => order['orderType'] != 'retail')
            .toList();
        break;
      case 'retail':
        filteredOrders.value = allOrders
            .where((order) => order['orderType'] == 'retail')
            .toList();
        break;
      default:
        filteredOrders.value = List.from(allOrders);
    }
  }
  
  /// تغيير الفلتر
  void changeFilter(String filter) {
    selectedFilter.value = filter;
  }
  
  /// تحديث الطلبات
  Future<void> refreshOrders() async {
    await loadOrders();
  }
  
  /// الحصول على عدد الطلبات حسب النوع
  int getOrdersCount(String type) {
    switch (type) {
      case 'customer':
        return allOrders.where((order) => order['orderType'] != 'retail').length;
      case 'retail':
        return allOrders.where((order) => order['orderType'] == 'retail').length;
      default:
        return allOrders.length;
    }
  }
  
  /// الحصول على لون التمييز حسب نوع الطلب
  Color getOrderTypeColor(String orderType) {
    switch (orderType) {
      case 'retail':
        return const Color(0xFF8B5CF6); // بنفسجي لبائعي التجزئة
      default:
        return const Color(0xFF6366F1); // أزرق للمستخدمين العاديين
    }
  }
  
  /// الحصول على أيقونة نوع الطلب
  IconData getOrderTypeIcon(String orderType) {
    switch (orderType) {
      case 'retail':
        return Icons.store_outlined; // أيقونة متجر لبائعي التجزئة
      default:
        return Icons.person_outline; // أيقونة شخص للمستخدمين العاديين
    }
  }
  
  /// الحصول على نص نوع الطلب
  String getOrderTypeText(String orderType) {
    switch (orderType) {
      case 'retail':
        return 'بائع تجزئة';
      default:
        return 'مستخدم عادي';
    }
  }
} 