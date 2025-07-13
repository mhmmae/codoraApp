// barcode_scanner_page.dart (مثال مبسط جدًا)
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  MobileScannerController scannerController = MobileScannerController(
    // يمكنك ضبط إعدادات الكاميرا هنا، مثل:
    // detectionSpeed: DetectionSpeed.normal,
    // facing: CameraFacing.back,
    // torchEnabled: false,
  );
  bool _isProcessing = false; // لمنع معالجة متكررة لنفس الباركود

  @override
  void dispose() {
    scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String? purpose = Get.arguments?['purposeTitle'] as String?;
    return Scaffold(
      appBar: AppBar(
        title: Text(purpose ?? "مسح الباركود"),
        leading: IconButton(icon: Icon(Icons.close), onPressed: () => Get.back(result:null)), // رجوع مع null للإلغاء
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: scannerController,
            onDetect: (capture) {
              if (_isProcessing) return; // تجاهل إذا كانت هناك عملية معالجة جارية
              setState(() => _isProcessing = true);

              final List<Barcode> barcodes = capture.barcodes;
              // final Uint8List? image = capture.image; // إذا كنت تحتاج للصورة

              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                final String scannedValue = barcodes.first.rawValue!;
                debugPrint("Barcode detected by MobileScanner: $scannedValue");
                //  توقف المسح وأرجع القيمة
                scannerController.stop();
                Get.back(result: scannedValue); //  أرجع قيمة الباركود
              } else {
                setState(() => _isProcessing = false); // أعد تفعيل المسح إذا لم يتم الكشف عن شيء صالح
              }
            },
            errorBuilder: (context, error) {
              debugPrint("MobileScanner Error: $error");
              return Center(child: Text("خطأ في الكاميرا: ${error.toString()}", style:TextStyle(color:Colors.red)));
            },
          ),
          // يمكنك إضافة overlay هنا لتحديد منطقة المسح أو إرشادات
          Center(
            child: Container(
              width: Get.width * 0.7,
              height: Get.width * 0.7,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green.withOpacity(0.7), width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          )
        ],
      ),
    );
  }
}