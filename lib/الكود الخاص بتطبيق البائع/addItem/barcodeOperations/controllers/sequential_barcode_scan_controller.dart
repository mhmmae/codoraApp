import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../Model/model_item.dart';

class SequentialBarcodeScanController extends GetxController {
  final TextEditingController searchController = TextEditingController();
  late MobileScannerController scannerController;
  
  final RxList<ItemModel> products = <ItemModel>[].obs;
  final RxList<ItemModel> allProducts = <ItemModel>[].obs;
  final Rx<ItemModel?> selectedProduct = Rx<ItemModel?>(null);
  final RxList<String> scannedBarcodes = <String>[].obs;
  
  final RxBool isLoading = false.obs;
  final RxBool isSearching = false.obs;
  final RxBool isSaving = false.obs;
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      detectionTimeoutMs: 1000,
    );
    loadProducts();
  }

  @override
  void onClose() {
    searchController.dispose();
    scannerController.dispose();
    super.onClose();
  }

  void onBarcodeDetected(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
        addScannedBarcode(barcode.rawValue!);
      }
    }
  }

  void addScannedBarcode(String barcode) {
    // التحقق من عدم تكرار الباركود
    if (!scannedBarcodes.contains(barcode)) {
      scannedBarcodes.add(barcode);
      
      // صوت أو اهتزاز للتأكيد
      Get.snackbar(
        'تم المسح',
        'تم إضافة باركود: $barcode',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 1),
        snackPosition: SnackPosition.TOP,
      );
    } else {
      Get.snackbar(
        'تحذير',
        'هذا الباركود موجود بالفعل',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 1),
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  void removeBarcode(String barcode) {
    scannedBarcodes.remove(barcode);
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

  void selectProduct(ItemModel product) {
    selectedProduct.value = product;
    scannedBarcodes.clear();
  }

  void resetSelection() {
    selectedProduct.value = null;
    scannedBarcodes.clear();
    scannerController.stop();
  }

  Future<void> saveBarcodes() async {
    if (selectedProduct.value == null || scannedBarcodes.isEmpty) {
      Get.snackbar(
        'خطأ',
        'لا توجد باركودات للحفظ',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isSaving.value = true;
      
      final batch = _firestore.batch();
      
      // حفظ كل باركود كوثيقة منفصلة
      for (String barcode in scannedBarcodes) {
        final barcodeDoc = _firestore
            .collection('الباركودات_التسلسلية')
            .doc(barcode);
        
        batch.set(barcodeDoc, {
          'barcode': barcode,
          'productId': selectedProduct.value!.id,
          'productName': selectedProduct.value!.name,
          'userId': userId,
          'createdAt': FieldValue.serverTimestamp(),
          'isUsed': false,
          'addedByScanning': true,
          'scannedAt': FieldValue.serverTimestamp(),
        });
      }
      
      // تحديث المنتج بإضافة الباركودات التسلسلية
      final productDoc = _firestore.collection('Item').doc(selectedProduct.value!.id);
      batch.update(productDoc, {
        'sequentialBarcodes': FieldValue.arrayUnion(scannedBarcodes.toList()),
        'totalSequentialBarcodes': FieldValue.increment(scannedBarcodes.length),
        'lastBarcodeAddition': FieldValue.serverTimestamp(),
      });
      
      await batch.commit();
      
      // إشعار النجاح
      final int count = scannedBarcodes.length;
      final String productName = selectedProduct.value!.name;
      
      Get.back(); // العودة للصفحة الرئيسية
      
      Get.snackbar(
        'نجح',
        'تم حفظ $count باركود للمنتج: $productName',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في حفظ الباركودات: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isSaving.value = false;
    }
  }

  // تشغيل أو إيقاف الفلاش
  Future<void> toggleFlash() async {
    await scannerController.toggleTorch();
  }

  // تغيير الكاميرا
  Future<void> flipCamera() async {
    await scannerController.switchCamera();
  }

  // إعادة تشغيل الكاميرا
  void resumeCamera() {
    scannerController.start();
  }

  // إيقاف الكاميرا مؤقتاً
  void pauseCamera() {
    scannerController.stop();
  }
}
