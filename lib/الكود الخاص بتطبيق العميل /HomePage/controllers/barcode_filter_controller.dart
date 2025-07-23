import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_storage/get_storage.dart';

import '../../../Model/model_item.dart';
import '../../../XXX/xxx_firebase.dart';

/// كنترولر البحث بالباركود للفلترة
class BarcodeFilterController extends GetxController
    with GetSingleTickerProviderStateMixin {
  // تخزين محلي
  final GetStorage _storage = GetStorage();

  // متحكم المسح
  late MobileScannerController scannerController;

  // حالة النظام
  final RxBool isBarcodeSearchActive = false.obs;
  final RxBool isScanning = false.obs;
  final RxBool hasPermission = false.obs;
  final RxString scannedBarcode = ''.obs;
  final RxString currentSearchBarcode = ''.obs;

  // نتائج البحث
  final RxList<ItemModel> searchResults = <ItemModel>[].obs;
  final Rxn<ItemModel> foundProduct = Rxn<ItemModel>();
  final RxBool showProductNotFound = false.obs;

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

    slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeInOutQuint),
      ),
    );

    fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.2, 0.9, curve: Curves.easeOutExpo),
      ),
    );

    scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
      ),
    );
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
    // تم حذف إشعار "الكاميرا جاهزة" حسب طلب المستخدم
  }

  /// إلغاء البحث بالباركود
  void deactivateBarcodeSearch() {
    // مسح جميع الإشعارات الحالية أولاً
    clearAllNotifications();

    // إيقاف المسح أولاً
    scannerController.stop();

    // انيميشن إغلاق احترافي مع تأخير متدرج
    animationController
        .animateTo(
          0.0,
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeInOutQuart,
        )
        .then((_) {
          isBarcodeSearchActive.value = false;
          currentSearchBarcode.value = '';
          scannedBarcode.value = '';
          isScanning.value = false;
          _resetScanner();
        });

    // تم حذف إشعار "تم الإغلاق" حسب طلب المستخدم

    debugPrint('تم إلغاء البحث بالباركود');
  }

  /// عند مسح الباركود بنجاح
  void onBarcodeDetected(BarcodeCapture capture) {
    if (!isScanning.value) return; // منع المسح إذا لم تكن الكاميرا نشطة

    final List<Barcode> barcodes = capture.barcodes;

    if (barcodes.isNotEmpty) {
      final barcode = barcodes.first;
      scannedBarcode.value = barcode.rawValue ?? '';

      if (scannedBarcode.value.isNotEmpty) {
        // إيقاف الكاميرا مؤقتاً
        scannerController.stop();

        // فحص وجود المنتجات بهذا الباركود
        _checkProductsExistenceInWidget(scannedBarcode.value);
      }
    }
  }

  /// فحص وجود المنتجات بالباركود في الويدجت
  Future<void> _checkProductsExistenceInWidget(String barcode) async {
    try {
      // البحث في قاعدة البيانات عن منتجات بهذا الباركود
      final QuerySnapshot result =
          await FirebaseFirestore.instance
              .collection(FirebaseX.itemsCollection)
              .where('appName', isEqualTo: FirebaseX.appName)
              .where('productBarcode', isEqualTo: barcode)
              .limit(1)
              .get();

      if (result.docs.isNotEmpty) {
        // تم العثور على منتج
        final doc = result.docs.first;
        final product = ItemModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );

        foundProduct.value = product;
        currentSearchBarcode.value = barcode;
        isScanning.value = false; // إيقاف المسح

        Get.snackbar(
          '✅ تم العثور على المنتج',
          'تم العثور على منتج بالباركود',
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          colorText: Colors.green[800],
          duration: Duration(seconds: 2),
          icon: Icon(Icons.check_circle, color: Colors.green),
        );
      } else {
        // لم يتم العثور على منتجات
        showProductNotFound.value = true;
        isScanning.value = false; // إيقاف المسح
      }
    } catch (e) {
      // خطأ في البحث
      Get.snackbar(
        '❌ خطأ في البحث',
        'حدث خطأ أثناء البحث عن المنتج',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red[800],
        duration: Duration(seconds: 3),
        icon: Icon(Icons.error, color: Colors.red),
      );

      // إعادة بدء المسح
      restartScanning();
    }
  }

  /// إعادة بدء المسح
  void restartScanning() {
    foundProduct.value = null;
    showProductNotFound.value = false;
    scannedBarcode.value = '';

    if (hasPermission.value) {
      isScanning.value = true;
      scannerController.start();
    }
  }

  /// إعادة تعيين المسح
  void _resetScanner() {
    isScanning.value = false;
    scannedBarcode.value = '';
  }

  /// مسح الباركود المحفوظ
  void clearCurrentBarcode() {
    // مسح جميع الإشعارات الحالية أولاً
    clearAllNotifications();

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

  /// عرض رسالة توضيحية لاستخدام الميزة (مرة واحدة فقط)
  void _showUsageMessage() {
    // التحقق من عرض الرسالة مسبقاً
    bool hasShownMessage =
        _storage.read('barcode_usage_message_shown') ?? false;

    if (!hasShownMessage) {
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
              style: TextStyle(color: Colors.blue[800], fontSize: 14),
            ),
            SizedBox(height: 8),
            Text(
              '💡 اجعل الباركود واضحاً أمام الكاميرا',
              style: TextStyle(color: Colors.blue[600], fontSize: 12),
            ),
          ],
        ),
      );

      // حفظ أنه تم عرض الرسالة
      _storage.write('barcode_usage_message_shown', true);
    }
  }

  /// بدء مسح الكاميرا في نفس الويدجت
  void startCameraScanning() async {
    if (!hasPermission.value) {
      await _requestCameraPermission();
      if (!hasPermission.value) {
        Get.snackbar(
          '❌ خطأ',
          'يجب السماح للتطبيق بالوصول للكاميرا',
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          colorText: Colors.red,
        );
        return;
      }
    }

    // مسح الحالة السابقة
    foundProduct.value = null;
    showProductNotFound.value = false;
    scannedBarcode.value = '';

    // بدء المسح
    isScanning.value = true;

    // تأكد من بدء الكاميرا
    try {
      await scannerController.start();

      // تم حذف إشعار "الكاميرا جاهزة" حسب طلب المستخدم
    } catch (e) {
      debugPrint('خطأ في بدء الكاميرا: $e');
      Get.snackbar(
        '❌ خطأ في الكاميرا',
        'لا يمكن تشغيل الكاميرا',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
      isScanning.value = false;
    }
  }

  /// إيقاف مسح الكاميرا
  void stopCameraScanning() {
    // مسح الإشعارات أولاً
    clearAllNotifications();

    isScanning.value = false;
    scannerController.stop();

    // مسح الحالة
    foundProduct.value = null;
    showProductNotFound.value = false;
    scannedBarcode.value = '';

    // تم حذف إشعار "تم الإغلاق" حسب طلب المستخدم
  }

  /// مسح رسالة المنتج غير موجود
  void clearNotFoundMessage() {
    showProductNotFound.value = false;
    scannedBarcode.value = '';
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
      final QuerySnapshot result =
          await FirebaseFirestore.instance
              .collection(FirebaseX.itemsCollection)
              .where('appName', isEqualTo: FirebaseX.appName)
              .where('productBarcode', isEqualTo: barcode)
              .get();

      if (result.docs.isNotEmpty) {
        // تحويل النتائج إلى قائمة منتجات
        searchResults.clear();
        for (var doc in result.docs) {
          try {
            final item = ItemModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
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

  /// مسح جميع الإشعارات الحالية
  void clearAllNotifications() {
    Get.closeAllSnackbars();
  }
}
