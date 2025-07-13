import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../../XXX/xxx_firebase.dart';

/// تعداد حالات الطلب
enum OrderStatus {
  pending, // بانتظار القبول
  accepted, // تم القبول وجاري التحضير
  readyForPickup, // جاهز للاستلام من قبل عامل التوصيل
  pickedUp, // تم استلامه من قبل عامل التوصيل
  delivered, // تم التسليم
  cancelled // تم الإلغاء
}

/// متحكم إدارة الطلبات للبائع
/// يدير عرض الطلبات وحساب عدد الطلبات الجديدة
class OrdersController extends GetxController {
  // حالة عدد الطلبات الجديدة
  final RxInt newOrdersCount = 0.obs;
  
  // حالة عدد الطلبات المقبولة
  final RxInt acceptedOrdersCount = 0.obs;
  
  // حالة عدد الطلبات الجاهزة للاستلام
  final RxInt readyOrdersCount = 0.obs;
  
  // حالة التحميل
  final RxBool isLoading = false.obs;
  
  // قائمة جميع الطلبات
  final RxList<QueryDocumentSnapshot> allOrdersList = <QueryDocumentSnapshot>[].obs;
  
  // قائمة الطلبات الجديدة
  final RxList<QueryDocumentSnapshot> newOrdersList = <QueryDocumentSnapshot>[].obs;
  
  // قائمة الطلبات المقبولة
  final RxList<QueryDocumentSnapshot> acceptedOrdersList = <QueryDocumentSnapshot>[].obs;
  
  // قائمة الطلبات الجاهزة للاستلام
  final RxList<QueryDocumentSnapshot> readyOrdersList = <QueryDocumentSnapshot>[].obs;
  
  // للاستماع لتغييرات الطلبات في الوقت الفعلي
  StreamSubscription<QuerySnapshot>? _ordersStreamSubscription;

  // معرف البائع الحالي
  String? get currentSellerId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    _startListeningToOrders();
  }

  @override
  void onClose() {
    _ordersStreamSubscription?.cancel();
    super.onClose();
  }

  /// بدء الاستماع للطلبات في الوقت الفعلي
  void _startListeningToOrders() {
    if (currentSellerId == null) return;

    _ordersStreamSubscription = FirebaseFirestore.instance
        .collection('orders')
        .where('appName', isEqualTo: FirebaseX.appName)
        .where('uidAdd', isEqualTo: currentSellerId)
        .snapshots()
        .listen(
      (QuerySnapshot snapshot) {
        allOrdersList.value = snapshot.docs;
        _categorizeOrders(snapshot.docs);
        
        debugPrint("📋 [OrdersController] تم تحديث جميع الطلبات: ${allOrdersList.length}");
        debugPrint("   - طلبات جديدة: ${newOrdersCount.value}");
        debugPrint("   - طلبات مقبولة: ${acceptedOrdersCount.value}");
        debugPrint("   - طلبات جاهزة: ${readyOrdersCount.value}");
      },
      onError: (error) {
        debugPrint("❌ [OrdersController] خطأ في جلب الطلبات: $error");
      },
    );
  }

  /// تصنيف الطلبات حسب حالتها
  void _categorizeOrders(List<QueryDocumentSnapshot> orders) {
    final newOrders = <QueryDocumentSnapshot>[];
    final acceptedOrders = <QueryDocumentSnapshot>[];
    final readyOrders = <QueryDocumentSnapshot>[];

    for (var order in orders) {
      final data = order.data() as Map<String, dynamic>;
      final orderStatus = _getOrderStatus(data);
      
      switch (orderStatus) {
        case OrderStatus.pending:
          newOrders.add(order);
          break;
        case OrderStatus.accepted:
          acceptedOrders.add(order);
          break;
        case OrderStatus.readyForPickup:
          readyOrders.add(order);
          break;
        default:
          // الطلبات المكتملة أو الملغاة لا تظهر في القوائم الرئيسية
          break;
      }
    }

    newOrdersList.value = newOrders;
    acceptedOrdersList.value = acceptedOrders;
    readyOrdersList.value = readyOrders;
    
    newOrdersCount.value = newOrders.length;
    acceptedOrdersCount.value = acceptedOrders.length;
    readyOrdersCount.value = readyOrders.length;
  }

  /// تحديد حالة الطلب من البيانات
  OrderStatus _getOrderStatus(Map<String, dynamic> orderData) {
    final isAccepted = orderData['RequestAccept'] ?? false;
    final orderStatus = orderData['orderStatus'] as String?;
    
    if (!isAccepted) {
      return OrderStatus.pending;
    }
    
    switch (orderStatus) {
      case 'accepted':
        return OrderStatus.accepted;
      case 'readyForPickup':
        return OrderStatus.readyForPickup;
      case 'pickedUp':
        return OrderStatus.pickedUp;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.accepted; // افتراضي للطلبات المقبولة بدون حالة
    }
  }

  /// إعادة تحميل الطلبات يدوياً
  Future<void> refreshOrders() async {
    if (currentSellerId == null) return;

    isLoading.value = true;
    
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('appName', isEqualTo: FirebaseX.appName)
          .where('uidAdd', isEqualTo: currentSellerId)
          .get();

      allOrdersList.value = snapshot.docs;
      _categorizeOrders(snapshot.docs);
      
      debugPrint("🔄 [OrdersController] تم تحديث جميع الطلبات يدوياً: ${allOrdersList.length}");
    } catch (e) {
      debugPrint("❌ [OrdersController] خطأ في تحديث الطلبات: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// جلب تفاصيل طلب معين
  Future<Map<String, dynamic>?> getOrderDetails(String orderId) async {
    try {
      final DocumentSnapshot orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();

      if (orderDoc.exists) {
        return orderDoc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      debugPrint("❌ [OrdersController] خطأ في جلب تفاصيل الطلب: $e");
      return null;
    }
  }

  /// قبول طلب جديد
  Future<void> acceptOrder(String orderId) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'RequestAccept': true,
        'orderStatus': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      Get.snackbar(
        '✅ تم قبول الطلب',
        'يمكنك الآن البدء في تحضير المنتجات',
        backgroundColor: Get.theme.colorScheme.primary.withOpacity(0.1),
        colorText: Get.theme.colorScheme.primary,
        duration: Duration(seconds: 3),
      );
      
      debugPrint("✅ [OrdersController] تم قبول الطلب $orderId");
    } catch (e) {
      debugPrint("❌ [OrdersController] خطأ في قبول الطلب: $e");
      Get.snackbar(
        '❌ خطأ',
        'فشل في قبول الطلب، حاول مرة أخرى',
        backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
        colorText: Get.theme.colorScheme.error,
      );
      rethrow;
    }
  }

  /// رفض طلب
  Future<void> rejectOrder(String orderId) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'RequestAccept': false,
        'orderStatus': 'cancelled',
        'rejectedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      Get.snackbar(
        '❌ تم رفض الطلب',
        'تم رفض الطلب بنجاح',
        backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
        colorText: Get.theme.colorScheme.error,
        duration: Duration(seconds: 3),
      );
      
      debugPrint("❌ [OrdersController] تم رفض الطلب $orderId");
    } catch (e) {
      debugPrint("❌ [OrdersController] خطأ في رفض الطلب: $e");
      rethrow;
    }
  }

  /// تحديد الطلب كجاهز للاستلام
  Future<void> markOrderReady(String orderId) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'orderStatus': 'readyForPickup',
        'readyAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      Get.snackbar(
        '📦 الطلب جاهز!',
        'تم تحديد الطلب كجاهز للاستلام من قبل عامل التوصيل',
        backgroundColor: Get.theme.colorScheme.tertiary.withOpacity(0.1),
        colorText: Get.theme.colorScheme.tertiary,
        duration: Duration(seconds: 3),
      );
      
      debugPrint("📦 [OrdersController] تم تحديد الطلب $orderId كجاهز للاستلام");
    } catch (e) {
      debugPrint("❌ [OrdersController] خطأ في تحديد الطلب كجاهز: $e");
      Get.snackbar(
        '❌ خطأ',
        'فشل في تحديث حالة الطلب، حاول مرة أخرى',
        backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
        colorText: Get.theme.colorScheme.error,
      );
      rethrow;
    }
  }

  /// تأكيد استلام الطلب من قبل عامل التوصيل
  Future<void> confirmPickup(String orderId) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'orderStatus': 'pickedUp',
        'pickedUpAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      Get.snackbar(
        '🚚 تم الاستلام',
        'تم استلام الطلب من قبل عامل التوصيل',
        backgroundColor: Get.theme.colorScheme.secondary.withOpacity(0.1),
        colorText: Get.theme.colorScheme.secondary,
        duration: Duration(seconds: 3),
      );
      
      debugPrint("🚚 [OrdersController] تم استلام الطلب $orderId من قبل عامل التوصيل");
    } catch (e) {
      debugPrint("❌ [OrdersController] خطأ في تأكيد استلام الطلب: $e");
      rethrow;
    }
  }

  /// الحصول على وصف حالة الطلب
  String getOrderStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'بانتظار القبول';
      case OrderStatus.accepted:
        return 'مقبول - جاري التحضير';
      case OrderStatus.readyForPickup:
        return 'جاهز للاستلام';
      case OrderStatus.pickedUp:
        return 'تم الاستلام';
      case OrderStatus.delivered:
        return 'تم التسليم';
      case OrderStatus.cancelled:
        return 'ملغى';
    }
  }

  /// الحصول على أيقونة حالة الطلب
  String getOrderStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return '⏳';
      case OrderStatus.accepted:
        return '✅';
      case OrderStatus.readyForPickup:
        return '📦';
      case OrderStatus.pickedUp:
        return '🚚';
      case OrderStatus.delivered:
        return '✅';
      case OrderStatus.cancelled:
        return '❌';
    }
  }
} 