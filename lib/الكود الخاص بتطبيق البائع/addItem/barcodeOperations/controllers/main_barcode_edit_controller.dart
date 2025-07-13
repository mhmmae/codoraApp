import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

import '../../../../Model/model_item.dart';

class MainBarcodeEditController extends GetxController {
  final TextEditingController searchController = TextEditingController();
  final TextEditingController barcodeController = TextEditingController();
  
  final RxList<ItemModel> products = <ItemModel>[].obs;
  final RxList<ItemModel> allProducts = <ItemModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSearching = false.obs;
  final RxBool isUpdating = false.obs;
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    loadProducts();
  }

  @override
  void onClose() {
    searchController.dispose();
    barcodeController.dispose();
    super.onClose();
  }

  Future<void> loadProducts() async {
    if (userId == null) return;
    
    try {
      isLoading.value = true;
      
      final QuerySnapshot snapshot = await _firestore
          .collection('Item')
          .where('uidAdd', isEqualTo: userId)
          .get();

      allProducts.clear();
      products.clear();
      
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final product = ItemModel.fromMap(data, doc.id);
          allProducts.add(product);
          products.add(product);
        } catch (e) {
          print('خطأ في تحويل المنتج: $e');
        }
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في تحميل المنتجات: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void onSearchChanged(String query) {
    isSearching.value = true;
    
    if (query.isEmpty) {
      products.assignAll(allProducts);
    } else {
      products.assignAll(
        allProducts.where((product) => 
          product.name.toLowerCase().contains(query.toLowerCase()) ||
          (product.mainProductBarcode?.contains(query) ?? false)
        ).toList(),
      );
    }
    
    isSearching.value = false;
  }

  void clearSearch() {
    searchController.clear();
    products.assignAll(allProducts);
  }

  void generateRandomBarcode() {
    final Random random = Random();
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String randomPart = random.nextInt(999999).toString().padLeft(6, '0');
    final String generatedBarcode = '${timestamp.substring(timestamp.length - 6)}$randomPart';
    
    barcodeController.text = generatedBarcode;
    
    Get.snackbar(
      'تم التوليد',
      'تم توليد باركود عشوائي جديد',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  void clearBarcode() {
    barcodeController.clear();
  }

  void scanBarcode() {
    // هنا يمكن إضافة وظيفة مسح الباركود بالكاميرا
    Get.snackbar(
      'قريباً',
      'ميزة مسح الباركود بالكاميرا ستكون متاحة قريباً',
      backgroundColor: Colors.grey,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> updateBarcode(ItemModel product) async {
    final newBarcode = barcodeController.text.trim();
    
    if (newBarcode.isEmpty) {
      // التأكد من أن المستخدم يريد حذف الباركود
      final bool? confirm = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: const Text('هل تريد حذف الباركود الرئيسي؟'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('نعم، احذف'),
            ),
          ],
        ),
      );
      
      if (confirm != true) return;
    } else {
      // التحقق من صحة الباركود
      if (newBarcode.length < 6) {
        Get.snackbar(
          'خطأ',
          'الباركود يجب أن يكون 6 أرقام على الأقل',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // التحقق من عدم تكرار الباركود
      if (await _isBarcodeExists(newBarcode, product.id)) {
        Get.snackbar(
          'خطأ',
          'هذا الباركود موجود بالفعل لمنتج آخر',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
    }

    try {
      isUpdating.value = true;
      
      final Map<String, dynamic> updateData = {
        'lastUpdated': FieldValue.serverTimestamp(),
        'barcodeUpdateHistory': FieldValue.arrayUnion([{
          'oldBarcode': product.mainProductBarcode,
          'newBarcode': newBarcode.isEmpty ? null : newBarcode,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': userId,
        }]),
      };
      
      if (newBarcode.isEmpty) {
        updateData['mainProductBarcode'] = FieldValue.delete();
      } else {
        updateData['mainProductBarcode'] = newBarcode;
      }
      
      await _firestore
          .collection('Item')
          .doc(product.id)
          .update(updateData);
      
      // تحديث المنتج محلياً
      final index = products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        final updatedProduct = ItemModel(
          id: product.id,
          name: product.name,
          description: product.description,
          price: product.price,
          imageUrl: product.imageUrl,
          manyImages: product.manyImages,
          videoUrl: product.videoUrl,
          typeItem: product.typeItem,
          itemCondition: product.itemCondition,
          qualityGrade: product.qualityGrade,
          countryOfOrigin: product.countryOfOrigin,
          countryOfOriginAr: product.countryOfOriginAr,
          countryOfOriginEn: product.countryOfOriginEn,
          uidAdd: product.uidAdd,
          appName: product.appName,
          costPrice: product.costPrice,
          addedBySellerType: product.addedBySellerType,
          productBarcode: product.productBarcode,
          mainProductBarcode: newBarcode.isEmpty ? null : newBarcode,
          productBarcodes: product.productBarcodes,
          quantity: product.quantity,
          mainCategoryId: product.mainCategoryId,
          subCategoryId: product.subCategoryId,
          mainCategoryNameAr: product.mainCategoryNameAr,
          mainCategoryNameEn: product.mainCategoryNameEn,
          subCategoryNameAr: product.subCategoryNameAr,
          subCategoryNameEn: product.subCategoryNameEn,
          originalProductId: product.originalProductId,
          originalCompanyId: product.originalCompanyId,
        );
        products[index] = updatedProduct;
        
        final allIndex = allProducts.indexWhere((p) => p.id == product.id);
        if (allIndex != -1) {
          allProducts[allIndex] = updatedProduct;
        }
      }
      
      Get.back(); // إغلاق الحوار
      
      Get.snackbar(
        'نجح',
        newBarcode.isEmpty 
            ? 'تم حذف الباركود الرئيسي بنجاح' 
            : 'تم تحديث الباركود الرئيسي بنجاح',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في تحديث الباركود: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isUpdating.value = false;
    }
  }

  Future<bool> _isBarcodeExists(String barcode, String currentProductId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('Item')
          .where('uidAdd', isEqualTo: userId)
          .where('mainProductBarcode', isEqualTo: barcode)
          .get();
      
      // التحقق من أن الباركود ليس للمنتج الحالي
      for (var doc in snapshot.docs) {
        if (doc.id != currentProductId) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      print('خطأ في التحقق من الباركود: $e');
      return false;
    }
  }

  // وظائف إضافية لإدارة الباركودات
  
  Future<void> generateBarcodeFromProductName(ItemModel product) async {
    final String name = product.name.replaceAll(' ', '').toLowerCase();
    final String nameCode = name.length > 4 ? name.substring(0, 4) : name;
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String timeCode = timestamp.substring(timestamp.length - 6);
    final Random random = Random();
    final String randomCode = random.nextInt(99).toString().padLeft(2, '0');
    
    final String generatedBarcode = '${nameCode.hashCode.abs().toString().substring(0, 2)}$timeCode$randomCode';
    
    barcodeController.text = generatedBarcode;
    
    Get.snackbar(
      'تم التوليد',
      'تم توليد باركود مبني على اسم المنتج',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> copyBarcodeFromAnotherProduct() async {
    // عرض قائمة المنتجات التي لها باركود لنسخ منها
    final productsWithBarcodes = allProducts
        .where((p) => p.mainProductBarcode != null && p.mainProductBarcode!.isNotEmpty)
        .toList();
    
    if (productsWithBarcodes.isEmpty) {
      Get.snackbar(
        'تنبيه',
        'لا توجد منتجات أخرى لها باركود',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }
    
    // هنا يمكن إضافة حوار لاختيار المنتج
    Get.snackbar(
      'قريباً',
      'ميزة نسخ الباركود من منتج آخر ستكون متاحة قريباً',
      backgroundColor: Colors.grey,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }
}
