import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../Model/model_item.dart';
import '../../../../XXX/xxx_firebase.dart';

// تعداد لأنواع الترتيب
enum SortType {
  alphabetical,
  price,
  sellPrice,
  costPrice,
  quantity,
  urgent,
  newest,
  lowestStock
}

class SearchExistingProductController extends GetxController {
  final TextEditingController searchController = TextEditingController();
  final RxList<ItemModel> searchResults = <ItemModel>[].obs;
  final RxList<ItemModel> allProducts = <ItemModel>[].obs; // قائمة جميع المنتجات
  final RxBool isSearching = false.obs;
  final Rx<SortType> currentSortType = SortType.urgent.obs; // الترتيب الافتراضي
  
  Timer? _debounceTimer;
  
  @override
  void onInit() {
    super.onInit();
    // بدء البحث عند تهيئة الصفحة بالمنتجات الحديثة
    _loadAllProducts();
  }
  
  @override
  void onReady() {
    super.onReady();
    print('🔄 Controller جاهز - تحديث البيانات');
  }
  
  @override
  void onClose() {
    searchController.dispose();
    _debounceTimer?.cancel();
    super.onClose();
  }
  
  /// البحث عند تغيير النص
  void onSearchChanged(String value) {
    _debounceTimer?.cancel();
    
    if (value.trim().isEmpty) {
      _applyCurrentSort();
      return;
    }
    
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchProducts(value.trim());
    });
  }

  /// تغيير نوع الترتيب
  void changeSortType(SortType newSortType) {
    currentSortType.value = newSortType;
    _applyCurrentSort();
  }

  /// تطبيق الترتيب الحالي
  void _applyCurrentSort() {
    final productsToSort = searchController.text.isEmpty ? 
        List<ItemModel>.from(allProducts) : 
        List<ItemModel>.from(searchResults);
    
    switch (currentSortType.value) {
      case SortType.alphabetical:
        productsToSort.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortType.sellPrice:
        productsToSort.sort((a, b) => (b.price).compareTo(a.price));
        break;
      case SortType.costPrice:
        productsToSort.sort((a, b) => (a.price).compareTo(b.price));
        break;
      case SortType.quantity:
        productsToSort.sort((a, b) => (b.quantity ?? 0).compareTo(a.quantity ?? 0));
        break;
      case SortType.urgent:
        productsToSort.sort((a, b) {
          final quantityA = a.quantity ?? 0;
          final quantityB = b.quantity ?? 0;
          // الأولوية للمنتجات التي نفدت، ثم القليلة
          final urgencyA = quantityA == 0 ? 3 : quantityA <= 5 ? 2 : quantityA <= 20 ? 1 : 0;
          final urgencyB = quantityB == 0 ? 3 : quantityB <= 5 ? 2 : quantityB <= 20 ? 1 : 0;
          return urgencyB.compareTo(urgencyA);
        });
        break;
      case SortType.newest:
        // ترتيب حسب التاريخ إذا كان متوفر، وإلا حسب الاسم
        productsToSort.sort((a, b) => b.name.compareTo(a.name));
        break;
      case SortType.lowestStock:
        productsToSort.sort((a, b) => (a.quantity ?? 0).compareTo(b.quantity ?? 0));
        break;
      case SortType.price:
        productsToSort.sort((a, b) => (b.price).compareTo(a.price));
        break;
    }
    
    searchResults.value = productsToSort;
  }
  
  /// تحميل جميع المنتجات
  Future<void> _loadAllProducts() async {
    try {
      isSearching.value = true;
      
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      print('🔍 تحميل جميع المنتجات - User ID: $currentUserId');
      print('🔍 App Name: ${FirebaseX.appName}');
      print('🔍 Collection: ${FirebaseX.itemsCollection}');
      
      if (currentUserId == null) {
        Get.snackbar(
          'خطأ',
          'يجب تسجيل الدخول أولاً',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
      
      // جلب جميع المنتجات للبائع
      final querySnapshot = await FirebaseFirestore.instance
          .collection(FirebaseX.itemsCollection)
          .where('uidAdd', isEqualTo: currentUserId)
          .where('appName', isEqualTo: FirebaseX.appName)
          .get();
      
      print('🔍 عدد المنتجات المعثور عليها: ${querySnapshot.docs.length}');
      
      final products = querySnapshot.docs
          .map((doc) => ItemModel.fromMap(doc.data(), doc.id))
          .toList();
      
      allProducts.value = products;
      _applyCurrentSort(); // تطبيق الترتيب الافتراضي
      
      print('🔍 المنتجات بعد التحويل: ${products.length}');
      
    } catch (e) {
      print('❌ خطأ في تحميل المنتجات: $e');
      Get.snackbar(
        'خطأ',
        'حدث خطأ في تحميل المنتجات: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isSearching.value = false;
    }
  }
  
  /// البحث عن المنتجات
  Future<void> _searchProducts(String query) async {
    try {
      isSearching.value = true;
      
      print('🔍 البحث عن: "$query"');
      
      // البحث محلياً في جميع المنتجات المحملة
      final filteredProducts = allProducts.where((product) {
        final nameMatch = product.name.toLowerCase().contains(query.toLowerCase());
        final barcodeMatch = product.mainProductBarcode == query || 
                            product.productBarcode == query ||
                            (product.productBarcodes?.contains(query) ?? false);
        return nameMatch || barcodeMatch;
      }).toList();
      
      print('🔍 المنتجات المطابقة للبحث: ${filteredProducts.length}');
      
      searchResults.value = filteredProducts;
      _applyCurrentSort(); // تطبيق الترتيب على نتائج البحث
      
    } catch (e) {
      print('❌ خطأ في البحث: $e');
      Get.snackbar(
        'خطأ',
        'حدث خطأ في البحث: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isSearching.value = false;
    }
  }
  
  /// مسح حقل البحث
  void clearSearch() {
    searchController.clear();
    _applyCurrentSort();
  }
  
  /// مسح الباركود
  Future<void> scanBarcode() async {
    try {
      // الانتقال لصفحة مسح الباركود
      Get.to(() => _BarcodeScannerPage());
    } catch (e) {
      print('خطأ في مسح الباركود: $e');
      Get.snackbar(
        'خطأ',
        'حدث خطأ في مسح الباركود',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  /// تعيين نتيجة مسح الباركود
  void setBarcodeResult(String barcode) {
    if (barcode.isNotEmpty) {
      searchController.text = barcode;
      _searchProducts(barcode);
    }
  }
  
  /// تحديث البيانات بعد إضافة كمية
  Future<void> refreshData() async {
    print('🔄 تحديث البيانات بعد إضافة الكمية...');
    
    try {
      await _loadAllProducts(); // إعادة تحميل جميع المنتجات
      
      if (searchController.text.isNotEmpty) {
        // إعادة البحث بنفس النص المُدخل
        await _searchProducts(searchController.text);
      }
      
      print('✅ تم تحديث البيانات بنجاح');
      
      // إظهار رسالة تأكيد سريعة
      Get.snackbar(
        'تم التحديث',
        'تم تحديث بيانات المنتجات',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.BOTTOM,
      );
      
    } catch (e) {
      print('❌ خطأ في تحديث البيانات: $e');
      Get.snackbar(
        'خطأ',
        'حدث خطأ في تحديث البيانات',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}

/// صفحة مسح الباركود
class _BarcodeScannerPage extends StatefulWidget {
  @override
  _BarcodeScannerPageState createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<_BarcodeScannerPage> {
  MobileScannerController cameraController = MobileScannerController();
  bool isScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مسح الباركود'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => cameraController.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // كاميرا مسح الباركود
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              if (!isScanned) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
                    setState(() {
                      isScanned = true;
                    });
                    
                    // إرجاع النتيجة للـ controller
                    final controller = Get.find<SearchExistingProductController>();
                    controller.setBarcodeResult(barcode.rawValue!);
                    
                    // العودة للصفحة السابقة
                    Get.back();
                    
                    break;
                  }
                }
              }
            },
          ),
          
          // إطار مسح الباركود
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.green,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: CustomPaint(
                painter: _ScannerOverlayPainter(),
              ),
            ),
          ),
          
          // تعليمات
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'وجه الكاميرا نحو الباركود لمسحه',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}

/// رسام إطار مسح الباركود
class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const cornerLength = 30.0;

    // الزوايا الأربع
    // الزاوية العلوية اليسرى
    canvas.drawLine(Offset(0, 0), Offset(cornerLength, 0), paint);
    canvas.drawLine(Offset(0, 0), Offset(0, cornerLength), paint);

    // الزاوية العلوية اليمنى
    canvas.drawLine(Offset(size.width - cornerLength, 0), Offset(size.width, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLength), paint);

    // الزاوية السفلية اليسرى
    canvas.drawLine(Offset(0, size.height - cornerLength), Offset(0, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(cornerLength, size.height), paint);

    // الزاوية السفلية اليمنى
    canvas.drawLine(Offset(size.width - cornerLength, size.height), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height - cornerLength), Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}