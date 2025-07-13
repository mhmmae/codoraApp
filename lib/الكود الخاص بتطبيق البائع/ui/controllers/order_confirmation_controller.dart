import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../Model/SellerModel.dart';
import '../../../XXX/xxx_firebase.dart';
import 'retail_cart_controller.dart';

class OrderConfirmationController extends GetxController {
  bool isLoading = true;
  bool isProcessing = false;
  
  List<CartItem> cartItems = [];
  SellerModel? storeInfo;
  Map<String, dynamic>? buyerInfo;
  String deliveryAddress = '';
  Map<String, dynamic>? deliveryLocation;
  
  double subtotal = 0.0;
  double deliveryFee = 0.0;
  double total = 0.0;
  
  @override
  void onInit() {
    super.onInit();
    _initializeData();
  }
  
  /// تهيئة البيانات
  Future<void> _initializeData() async {
    try {
      // الحصول على بيانات الموقع من arguments
      deliveryLocation = Get.arguments as Map<String, dynamic>?;
      deliveryAddress = deliveryLocation?['address'] ?? '';
      
      // الحصول على بيانات السلة
      final cartController = Get.find<RetailCartController>();
      cartItems = List.from(cartController.cartItems);
      storeInfo = cartController.currentStore;
      
      // حساب المبالغ
      _calculateTotals();
      
      // تحميل معلومات المشتري
      await _loadBuyerInfo();
      
    } catch (e) {
      debugPrint('خطأ في تهيئة البيانات: $e');
      Get.snackbar(
        'خطأ',
        'فشل في تحميل بيانات الطلب',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoading = false;
      update();
    }
  }
  
  /// تحميل معلومات المشتري (بائع التجزئة)
  Future<void> _loadBuyerInfo() async {
    try {
      final String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;
      
      final doc = await FirebaseFirestore.instance
          .collection(FirebaseX.collectionSeller)
          .doc(userId)
          .get();
      
      if (doc.exists) {
        buyerInfo = doc.data() as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('خطأ في تحميل معلومات المشتري: $e');
    }
  }
  
  /// حساب المبالغ
  void _calculateTotals() {
    subtotal = 0.0;
    for (final item in cartItems) {
      subtotal += item.totalPrice;
    }
    
    deliveryFee = 0.0; // مجاني للآن
    total = subtotal + deliveryFee;
  }
  
  /// تأكيد الطلب وحفظه
  Future<void> confirmOrder() async {
    if (isProcessing) return;
    
    isProcessing = true;
    update();
    
    try {
      final String? buyerId = FirebaseAuth.instance.currentUser?.uid;
      if (buyerId == null) {
        throw Exception('المستخدم غير مسجل');
      }
      
      if (storeInfo == null) {
        throw Exception('معلومات المتجر غير متوفرة');
      }
      
      // إنشاء رقم طلب فريد
      final String orderNumber = 'RO${DateTime.now().millisecondsSinceEpoch}';
      
      // إعداد بيانات الطلب
      final Map<String, dynamic> orderData = {
        // معلومات أساسية
        'numberOfOrder': orderNumber,
        'orderType': 'retail', // نوع الطلب: بائع تجزئة
        'appName': FirebaseX.appName,
        'timeOrder': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        
        // معلومات المشتري (بائع التجزئة)
        'uidUser': buyerId,
        'buyerType': 'retailer',
        'buyerInfo': {
          'name': buyerInfo?['sellerName'] ?? '',
          'phone': buyerInfo?['shopPhoneNumber'] ?? '',
          'shopName': buyerInfo?['shopName'] ?? '',
          'shopCategory': buyerInfo?['shopCategory'] ?? '',
          'email': buyerInfo?['email'] ?? '',
        },
        
        // معلومات البائع (متجر الجملة)
        'uidAdd': storeInfo!.uid,
        'sellerInfo': {
          'name': storeInfo!.sellerName,
          'shopName': storeInfo!.shopName,
          'phone': storeInfo!.shopPhoneNumber,
          'shopCategory': storeInfo!.shopCategory,
        },
        
        // معلومات التوصيل
        'deliveryInfo': {
          'address': deliveryAddress,
          'location': deliveryLocation != null ? GeoPoint(
            deliveryLocation!['latitude'],
            deliveryLocation!['longitude'],
          ) : null,
        },
        
        // معلومات المنتجات
        'items': cartItems.map((item) => {
          'productId': item.productId,
          'productName': item.productName,
          'productPrice': item.productPrice,
          'productImage': item.productImage,
          'quantity': item.quantity,
          'totalPrice': item.totalPrice,
          'productData': item.productData,
        }).toList(),
        
        // معلومات المبالغ
        'pricing': {
          'subtotal': subtotal,
          'deliveryFee': deliveryFee,
          'total': total,
          'currency': 'IQD',
        },
        
        // حالة الطلب
        'status': {
          'current': 'pending',
          'RequestAccept': false,
          'Delivery': false,
          'isCompleted': false,
          'isCancelled': false,
        },
        
        // معلومات إضافية
        'totalItems': cartItems.fold(0, (sum, item) => sum + item.quantity),
        'itemsCount': cartItems.length,
      };
      
      // حفظ الطلب في Firestore
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderNumber)
          .set(orderData);
      
      // مسح السلة
      final cartController = Get.find<RetailCartController>();
      cartController.clearCart();
      
      // إظهار رسالة نجاح
      Get.snackbar(
        'تم بنجاح',
        'تم إرسال طلبك بنجاح. رقم الطلب: $orderNumber',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      
      // الانتقال لصفحة تتبع الطلبات أو الرئيسية
      Get.offAllNamed('/seller-main');
      
    } catch (e) {
      debugPrint('خطأ في تأكيد الطلب: $e');
      Get.snackbar(
        'خطأ',
        'فشل في إرسال الطلب. يرجى المحاولة مرة أخرى.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isProcessing = false;
      update();
    }
  }
} 