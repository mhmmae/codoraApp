import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../Model/model_item.dart';
import '../../../XXX/xxx_firebase.dart';

/// كنترولر البحث بالباركود للفلترة
class BarcodeFilterController extends GetxController with GetSingleTickerProviderStateMixin {
  // متحكم المسح
  late MobileScannerController scannerController;
  
  // حالة النظام
  final RxBool isBarcodeSearchActive = false.obs;
  final RxBool isScanning = false.obs;
  final RxBool hasPermission = false.obs;
  final RxString scannedBarcode = ''.obs;
  final RxString currentSearchBarcode = ''.obs;
  final RxBool isFlashOn = false.obs;
  final RxBool isFrontCamera = false.obs;
  

  
  // نتائج البحث
  final RxList<ItemModel> searchResults = <ItemModel>[].obs;
  
  // Animation Controller
  late AnimationController animationController;
  late Animation<double> slideAnimation;
  late Animation<double> fadeAnimation;
  late Animation<double> scaleAnimation;
  
  @override
  void onInit() {
    super.onInit();
    _initAnimations();
    _initializeScanner();
    _requestCameraPermission();
  }

  @override
  void onClose() {
    animationController.dispose();
    scannerController.dispose();
    super.onClose();
  }

  /// تهيئة الانيميشن
  void _initAnimations() {
    animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeInOutQuint),
    ));
    
    fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: const Interval(0.2, 0.9, curve: Curves.easeOutExpo),
    ));
    
    scaleAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
    ));
  }

  /// تهيئة المسح
  void _initializeScanner() {
    scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  /// طلب إذن الكاميرا
  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    hasPermission.value = status == PermissionStatus.granted;
    
    if (!hasPermission.value) {
      Get.snackbar(
        '❌ إذن مطلوب',
        'يجب السماح للتطبيق بالوصول للكاميرا لمسح الباركود',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        duration: Duration(seconds: 5),
      );
    }
  }

  /// تفعيل البحث بالباركود
  void activateBarcodeSearch() {
    // عرض رسالة توضيحية
    _showUsageMessage();
    
    // انيميشن تفعيل احترافي
    isBarcodeSearchActive.value = true;
    
    // تشغيل انيميشن متدرج واحترافي
    animationController.reset();
    animationController.forward();
    
    // تأثيرات بصرية للتفعيل
    _addActivationEffects();
    
    // بدء المسح
    if (hasPermission.value) {
      Future.delayed(Duration(milliseconds: 400), () {
        scannerController.start();
      });
    }
    
    debugPrint('تم تفعيل البحث بالباركود');
  }

  /// إضافة تأثيرات بصرية للتفعيل
  void _addActivationEffects() {
    // انيميشن تدريجي للعناصر
    Future.delayed(Duration(milliseconds: 200), () {
      Get.snackbar(
        '📷 الكاميرا جاهزة',
        'يمكنك الآن مسح الباركود',
        backgroundColor: Colors.blue.withOpacity(0.1),
        colorText: Colors.blue[800],
        duration: Duration(seconds: 2),
        animationDuration: Duration(milliseconds: 800),
        icon: Icon(Icons.camera_alt, color: Colors.blue),
        margin: EdgeInsets.all(16),
        borderRadius: 12,
      );
    });
  }

  /// إلغاء البحث بالباركود
  void deactivateBarcodeSearch() {
    // إيقاف المسح أولاً
    scannerController.stop();
    
    // انيميشن إغلاق احترافي مع تأخير متدرج
    animationController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOutQuart,
    ).then((_) {
      isBarcodeSearchActive.value = false;
      currentSearchBarcode.value = '';
      scannedBarcode.value = '';
      isScanning.value = false;
      _resetScanner();
    });
    
    // إضافة انيميشن بصري للإغلاق
    Get.snackbar(
      '✅ تم الإغلاق',
      'تم إغلاق البحث بالباركود بنجاح',
      backgroundColor: Colors.green.withOpacity(0.1),
      colorText: Colors.green[800],
      duration: Duration(seconds: 2),
      animationDuration: Duration(milliseconds: 600),
      icon: Icon(Icons.check_circle_outline, color: Colors.green),
    );
    
    debugPrint('تم إلغاء البحث بالباركود');
  }

  /// تبديل الفلاش
  void toggleFlash() {
    isFlashOn.value = !isFlashOn.value;
    scannerController.toggleTorch();
  }

  /// تبديل الكاميرا
  void switchCamera() {
    isFrontCamera.value = !isFrontCamera.value;
    scannerController.switchCamera();
  }

  /// عند مسح الباركود بنجاح
  void onBarcodeDetected(BarcodeCapture capture) {
    if (isScanning.value) return; // منع المسح المتكرر
    
    final List<Barcode> barcodes = capture.barcodes;
    
    if (barcodes.isNotEmpty) {
      isScanning.value = true;
      final barcode = barcodes.first;
      scannedBarcode.value = barcode.rawValue ?? '';
      
      if (scannedBarcode.value.isNotEmpty) {
        // إيقاف المسح مؤقتاً
        scannerController.stop();
        
        // فحص وجود المنتجات بهذا الباركود
        _checkProductsExistence(scannedBarcode.value);
      }
    }
  }

  /// فحص وجود المنتجات بالباركود
  Future<void> _checkProductsExistence(String barcode) async {
    try {
      // البحث في قاعدة البيانات عن منتجات بهذا الباركود
      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection(FirebaseX.itemsCollection)
          .where('appName', isEqualTo: FirebaseX.appName)
          .where('productBarcode', isEqualTo: barcode)
          .limit(1)
          .get();

      if (result.docs.isNotEmpty) {
        // تم العثور على منتجات
        currentSearchBarcode.value = barcode;
        
        Get.snackbar(
          '✅ تم العثور على المنتج',
          'تم العثور على ${result.docs.length} منتج بالباركود: $barcode',
          backgroundColor: Colors.green.withOpacity(0.1),
          colorText: Colors.green[800],
          duration: Duration(seconds: 3),
          icon: Icon(Icons.check_circle, color: Colors.green),
        );
        
        // إخفاء الكاميرا والعودة للفلترة العادية
        Future.delayed(Duration(seconds: 1), () {
          deactivateBarcodeSearch();
        });
      } else {
        // لم يتم العثور على منتجات
        _showProductNotFoundDialog(barcode);
      }
    } catch (e) {
      // خطأ في البحث
      Get.snackbar(
        '❌ خطأ في البحث',
        'حدث خطأ أثناء البحث عن المنتج: $e',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red[800],
        duration: Duration(seconds: 3),
        icon: Icon(Icons.error, color: Colors.red),
      );
      
      // إعادة بدء المسح
      restartScanning();
    }
  }

  /// عرض رسالة عدم وجود المنتج
  void _showProductNotFoundDialog(String barcode) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Row(
          children: [
            Icon(Icons.search_off, color: Colors.orange, size: 30),
            SizedBox(width: 10),
            Text(
              'المنتج غير متوفر',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange[800],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'لم يتم العثور على أي منتج بالباركود:',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                barcode,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 15),
            Text(
              'يمكنك:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              '• مسح باركود آخر',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            Text(
              '• التحقق من صحة الباركود',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            Text(
              '• البحث بطريقة أخرى',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              deactivateBarcodeSearch();
            },
            child: Text(
              'إلغاء',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              restartScanning();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('مسح مرة أخرى'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  /// إعادة بدء المسح
  void restartScanning() {
    isScanning.value = false;
    scannedBarcode.value = '';
    if (hasPermission.value && isBarcodeSearchActive.value) {
      scannerController.start();
    }
  }

  /// إعادة تعيين المسح
  void _resetScanner() {
    isScanning.value = false;
    scannedBarcode.value = '';
    isFlashOn.value = false;
    isFrontCamera.value = false;
  }

  /// مسح الباركود المحفوظ
  void clearCurrentBarcode() {
    currentSearchBarcode.value = '';
    scannedBarcode.value = '';
    
    Get.snackbar(
      '🗑️ تم المسح',
      'تم مسح الباركود من البحث',
      backgroundColor: Colors.orange.withOpacity(0.1),
      colorText: Colors.orange[800],
      duration: Duration(seconds: 2),
    );
  }

  /// الحصول على مفتاح الفلتر الحالي
  String getFilterKey() {
    if (currentSearchBarcode.value.isNotEmpty) {
      return 'barcode_${currentSearchBarcode.value}';
    }
    return 'all';
  }

  /// وصف الفلتر الحالي
  String getFilterDescription() {
    if (currentSearchBarcode.value.isNotEmpty) {
      return 'البحث بالباركود: ${currentSearchBarcode.value}';
    }
    return 'جميع المنتجات';
  }

  /// التحقق من وجود فلتر نشط
  bool get hasActiveFilter => currentSearchBarcode.value.isNotEmpty;

  /// التحقق من حالة الكاميرا
  bool get isCameraReady => hasPermission.value && !isScanning.value;

  /// عرض رسالة توضيحية لاستخدام الميزة
  void _showUsageMessage() {
    Get.snackbar(
      '📱 البحث بالباركود',
      'اسحب كاميرا الهاتف على الباركود الموجود على المنتج للبحث عنه في التطبيق',
      backgroundColor: Colors.blue.withOpacity(0.1),
      colorText: Colors.blue[800],
      duration: Duration(seconds: 4),
      icon: Icon(Icons.qr_code_scanner, color: Colors.blue),
      messageText: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'اسحب كاميرا الهاتف على الباركود الموجود على المنتج للبحث عنه في التطبيق',
            style: TextStyle(
              color: Colors.blue[800],
              fontSize: 14,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '💡 اجعل الباركود واضحاً أمام الكاميرا',
            style: TextStyle(
              color: Colors.blue[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// بدء مسح الكاميرا
  void startCameraScan() async {
    if (!hasPermission.value) {
      await _requestCameraPermission();
      if (!hasPermission.value) {
        Get.snackbar(
          '❌ خطأ',
          'يجب السماح للتطبيق بالوصول للكاميرا',
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red,
        );
        return;
      }
    }

    // فتح شاشة المسح
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: _buildCameraScannerDialog(),
      ),
      barrierDismissible: true,
    );
  }

  /// بناء حوار مسح الكاميرا
  Widget _buildCameraScannerDialog() {
    return Container(
      width: double.infinity,
      height: 500,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // شريط علوي مع أزرار التحكم
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Get.back(),
                  icon: Icon(Icons.close, color: Colors.white),
                ),
                Text(
                  'مسح الباركود',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: toggleFlash,
                      icon: Obx(() => Icon(
                        isFlashOn.value ? Icons.flash_on : Icons.flash_off,
                        color: Colors.white,
                      )),
                    ),
                    IconButton(
                      onPressed: switchCamera,
                      icon: Icon(Icons.cameraswitch, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // منطقة المسح
          Expanded(
            child: Container(
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: MobileScanner(
                  controller: scannerController,
                  onDetect: onBarcodeDetected,
                ),
              ),
            ),
          ),
          
          // تعليمات
          Container(
            padding: EdgeInsets.all(16),
            child: Text(
              'ضع الباركود داخل الإطار للمسح',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }



  /// البحث بالباركود
  Future<void> searchByBarcode(String barcode) async {
    if (barcode.isEmpty) {
      Get.snackbar(
        '⚠️ تنبيه',
        'يرجى إدخال رقم الباركود',
        backgroundColor: Colors.orange.withOpacity(0.1),
        colorText: Colors.orange[800],
      );
      return;
    }

    try {
      // تحديث الباركود الحالي
      currentSearchBarcode.value = barcode;
      
      // البحث في قاعدة البيانات
      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection(FirebaseX.itemsCollection)
          .where('appName', isEqualTo: FirebaseX.appName)
          .where('productBarcode', isEqualTo: barcode)
          .get();

      if (result.docs.isNotEmpty) {
        // تحويل النتائج إلى قائمة منتجات
        searchResults.clear();
        for (var doc in result.docs) {
          try {
            final item = ItemModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
            searchResults.add(item);
          } catch (e) {
            debugPrint('خطأ في تحويل المنتج: $e');
          }
        }

        Get.snackbar(
          '✅ نجح البحث',
          'تم العثور على ${searchResults.length} منتج',
          backgroundColor: Colors.green.withOpacity(0.1),
          colorText: Colors.green[800],
          icon: Icon(Icons.check_circle, color: Colors.green),
        );
      } else {
        searchResults.clear();
        Get.snackbar(
          '❌ لا توجد نتائج',
          'لم يتم العثور على منتجات بهذا الباركود',
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red[800],
          icon: Icon(Icons.search_off, color: Colors.red),
        );
      }
    } catch (e) {
      Get.snackbar(
        '❌ خطأ',
        'حدث خطأ أثناء البحث: $e',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red[800],
        icon: Icon(Icons.error, color: Colors.red),
      );
    }
  }
} 