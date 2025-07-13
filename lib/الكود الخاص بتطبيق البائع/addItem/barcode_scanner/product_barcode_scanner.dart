import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

/// كنترولر مسح الباركود للمنتجات
class ProductBarcodeScannerController extends GetxController {
  // متحكم المسح
  late MobileScannerController scannerController;
  
  // حالة المسح
  final RxBool isScanning = false.obs;
  final RxBool hasPermission = false.obs;
  final RxString scannedBarcode = ''.obs;
  final RxBool isFlashOn = false.obs;
  final RxBool isFrontCamera = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    _initializeScanner();
    _requestCameraPermission();
  }

  @override
  void onClose() {
    scannerController.dispose();
    super.onClose();
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
        
        // عرض نتيجة المسح
        _showBarcodeResult();
      }
    }
  }

  /// عرض نتيجة المسح
  void _showBarcodeResult() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.qr_code_scanner, color: Colors.green),
            SizedBox(width: 10),
            Text('تم مسح الباركود'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الباركود الممسوح:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
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
                scannedBarcode.value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue[800],
                ),
              ),
            ),
            SizedBox(height: 15),
            Text(
              'هل تريد استخدام هذا الباركود للمنتج؟',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // إعادة بدء المسح
              _restartScanning();
              Get.back();
            },
            child: Text('مسح مرة أخرى'),
          ),
          ElevatedButton(
            onPressed: () {
              // إرجاع النتيجة وإغلاق المسح
              Get.back(); // إغلاق الحوار
              Get.back(result: scannedBarcode.value); // إرجاع النتيجة وإغلاق الماسح
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('استخدام هذا الباركود'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  /// إعادة بدء المسح
  void _restartScanning() {
    isScanning.value = false;
    scannedBarcode.value = '';
    scannerController.start();
  }

  /// إعادة تعيين الحالة
  void resetScanner() {
    isScanning.value = false;
    scannedBarcode.value = '';
    isFlashOn.value = false;
    isFrontCamera.value = false;
  }
}

/// واجهة مسح الباركود للمنتجات
class ProductBarcodeScanner extends StatelessWidget {
  const ProductBarcodeScanner({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProductBarcodeScannerController());
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return WillPopScope(
      onWillPop: () async {
        controller.resetScanner();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              controller.resetScanner();
              Get.back();
            },
          ),
          title: Text(
            'مسح باركود المنتج',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            // زر الفلاش
            Obx(() => IconButton(
              icon: Icon(
                controller.isFlashOn.value ? Icons.flash_on : Icons.flash_off,
                color: controller.isFlashOn.value ? Colors.yellow : Colors.white,
              ),
              onPressed: controller.toggleFlash,
            )),
            // زر تبديل الكاميرا
            IconButton(
              icon: Icon(Icons.flip_camera_android, color: Colors.white),
              onPressed: controller.switchCamera,
            ),
          ],
        ),
        body: Obx(() {
          if (!controller.hasPermission.value) {
            return _buildPermissionDeniedView(context, controller);
          }

          return Stack(
            children: [
              // شاشة المسح
              MobileScanner(
                controller: controller.scannerController,
                onDetect: controller.onBarcodeDetected,
              ),
              
              // إطار المسح
              _buildScanningFrame(width, height),
              
              // تعليمات المسح
              _buildInstructions(context),
              
              // معلومات إضافية
              _buildBottomInfo(context),
            ],
          );
        }),
      ),
    );
  }

  /// بناء إطار المسح
  Widget _buildScanningFrame(double width, double height) {
    return Center(
      child: Container(
        width: width * 0.8,
        height: height * 0.3,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.green,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            // زوايا الإطار
            ...List.generate(4, (index) {
              return Positioned(
                top: index < 2 ? 0 : null,
                bottom: index >= 2 ? 0 : null,
                left: index % 2 == 0 ? 0 : null,
                right: index % 2 == 1 ? 0 : null,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.only(
                      topLeft: index == 0 ? Radius.circular(17) : Radius.zero,
                      topRight: index == 1 ? Radius.circular(17) : Radius.zero,
                      bottomLeft: index == 2 ? Radius.circular(17) : Radius.zero,
                      bottomRight: index == 3 ? Radius.circular(17) : Radius.zero,
                    ),
                  ),
                ),
              );
            }),
            
            // خط المسح المتحرك
            _buildScanningLine(),
          ],
        ),
      ),
    );
  }

  /// خط المسح المتحرك
  Widget _buildScanningLine() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: AlwaysStoppedAnimation(0),
        builder: (context, child) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(seconds: 2),
            builder: (context, value, child) {
              return Positioned(
                top: value * (MediaQuery.of(context).size.height * 0.3 - 4),
                left: 0,
                right: 0,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.green,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// بناء التعليمات
  Widget _buildInstructions(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.15,
      left: 0,
      right: 0,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20),
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Icon(
              Icons.qr_code_scanner,
              color: Colors.white,
              size: 40,
            ),
            SizedBox(height: 10),
            Text(
              'ضع الباركود داخل الإطار',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 5),
            Text(
              'تأكد من وضوح الباركود وإضاءة جيدة',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// بناء المعلومات السفلية
  Widget _buildBottomInfo(BuildContext context) {
    return Positioned(
      bottom: 50,
      left: 0,
      right: 0,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20),
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Text(
                  'نصائح للحصول على أفضل نتائج:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            _buildTip('📱', 'امسك الجهاز بثبات'),
            _buildTip('💡', 'استخدم الفلاش في الإضاءة الخافتة'),
            _buildTip('📏', 'اقترب أو ابتعد حسب حجم الباركود'),
          ],
        ),
      ),
    );
  }

  /// بناء نصيحة واحدة
  Widget _buildTip(String emoji, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(emoji, style: TextStyle(fontSize: 16)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// بناء واجهة عدم السماح
  Widget _buildPermissionDeniedView(BuildContext context, ProductBarcodeScannerController controller) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 100,
              color: Colors.white54,
            ),
            SizedBox(height: 20),
            Text(
              'إذن الكاميرا مطلوب',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 15),
            Text(
              'نحتاج للوصول إلى الكاميرا لمسح الباركود الموجود على المنتج',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () async {
                await controller._requestCameraPermission();
              },
              icon: Icon(Icons.camera_alt),
              label: Text('طلب الإذن'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
            SizedBox(height: 15),
            TextButton(
              onPressed: () {
                openAppSettings();
              },
              child: Text(
                'فتح إعدادات التطبيق',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}