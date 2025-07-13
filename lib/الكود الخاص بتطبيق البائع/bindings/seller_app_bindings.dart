import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/seller_main_controller.dart';
import '../controllers/orders_controller.dart';

/// ربط تبعيات تطبيق البائع
/// يقوم بتهيئة جميع المتحكمات المطلوبة لتطبيق البائع
class SellerAppBindings extends Bindings {
  @override
  void dependencies() {
    // تهيئة متحكم تطبيق البائع الرئيسي
    Get.lazyPut<SellerMainController>(() => SellerMainController());
    
    // تهيئة متحكم الطلبات
    Get.lazyPut<OrdersController>(() => OrdersController());
    // Get.lazyPut(()=>SellerRegistrationController());
    debugPrint("🔧 [SellerAppBindings] تم تهيئة متحكمات تطبيق البائع بنجاح");
  }
} 