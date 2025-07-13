import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../Model/model_item.dart';
import '../../../../XXX/xxx_firebase.dart';

// إعادة تعريف SortType هنا
enum SortType {
  alphabetical,
  newest,
  price,
  quantity,
}

class ProductsListController extends GetxController {
  final TextEditingController searchController = TextEditingController();
  final RxString searchText = ''.obs;
  final RxList<ItemModel> allProducts = <ItemModel>[].obs;
  final RxList<ItemModel> filteredProducts = <ItemModel>[].obs;
  final RxBool isLoading = false.obs;
  final Rx<SortType> currentSortType = SortType.newest.obs;
  
  Timer? _debounceTimer;

  @override
  void onInit() {
    super.onInit();
    loadProducts();
    searchController.addListener(() {
      searchText.value = searchController.text;
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    _debounceTimer?.cancel();
    super.onClose();
  }

  /// تحميل جميع منتجات البائع الحالي
  Future<void> loadProducts() async {
    try {
      isLoading.value = true;
      
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        Get.snackbar(
          'خطأ',
          'يجب تسجيل الدخول أولاً',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // جلب جميع المنتجات للبائع الحالي
      final querySnapshot = await FirebaseFirestore.instance
          .collection(FirebaseX.itemsCollection)
          .where('uidAdd', isEqualTo: currentUserId)
          .where('appName', isEqualTo: FirebaseX.appName)
          .get();
      
      final products = querySnapshot.docs
          .map((doc) => ItemModel.fromMap(doc.data(), doc.id))
          .toList();
      
      allProducts.value = products;
      _applyCurrentSort();
      
    } catch (e) {
      print('❌ خطأ في تحميل المنتجات: $e');
      Get.snackbar(
        'خطأ',
        'حدث خطأ في تحميل المنتجات',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// البحث في المنتجات
  void searchProducts(String query) {
    _debounceTimer?.cancel();
    searchText.value = query; // تحديث النص المتابع
    
    if (query.trim().isEmpty) {
      filteredProducts.value = allProducts;
      _applyCurrentSort();
      return;
    }
    
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      final searchQuery = query.toLowerCase().trim();
      
      final results = allProducts.where((product) {
        final nameMatch = product.name.toLowerCase().contains(searchQuery);
        final barcodeMatch = product.productBarcode?.toLowerCase().contains(searchQuery) ?? false;
        final mainBarcodeMatch = product.mainProductBarcode?.toLowerCase().contains(searchQuery) ?? false;
        final descriptionMatch = product.description?.toLowerCase().contains(searchQuery) ?? false;
        
        return nameMatch || barcodeMatch || mainBarcodeMatch || descriptionMatch;
      }).toList();
      
      filteredProducts.value = results;
      _applyCurrentSort();
    });
  }

  /// مسح البحث
  void clearSearch() {
    searchController.clear();
    searchText.value = ''; // مسح النص المتابع أيضاً
    filteredProducts.value = allProducts;
    _applyCurrentSort();
  }

  /// تغيير نوع الترتيب
  void changeSortType(SortType newSortType) {
    currentSortType.value = newSortType;
    _applyCurrentSort();
  }

  /// تطبيق الترتيب الحالي
  void _applyCurrentSort() {
    final productsToSort = List<ItemModel>.from(
      searchController.text.isEmpty ? allProducts : filteredProducts
    );
    
    switch (currentSortType.value) {
      case SortType.alphabetical:
        productsToSort.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortType.newest:
        // يمكن استخدام تاريخ الإضافة إذا كان متوفراً
        productsToSort.sort((a, b) => b.id.compareTo(a.id));
        break;
      case SortType.price:
        productsToSort.sort((a, b) => b.price.compareTo(a.price));
        break;
      case SortType.quantity:
        productsToSort.sort((a, b) {
          final quantityA = a.quantity ?? 0;
          final quantityB = b.quantity ?? 0;
          return quantityB.compareTo(quantityA);
        });
        break;
    }
    
    filteredProducts.value = productsToSort;
  }

  /// تحديث قائمة المنتجات
  Future<void> refreshProducts() async {
    searchController.clear();
    await loadProducts();
  }
} 