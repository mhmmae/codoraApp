




import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'GetxBarCode/GetXBarCode.dart';

/// ودجة عرض خاصة بمسح الباركود وعرض النتيجة.
/// تستخدم هذه الودجة MobileScannerController لتلقي بيانات الباركود الممسوحة،
/// وتستفيد من متحكم GetxBarcode لمعالجة الباركود وإجراء العمليات اللازمة بعد المسح.
///
/// يتم التحكم في عملية المعالجة بحيث يتم استدعاؤها مرة واحدة لكل باركود باستخدام
/// متغير الحالة isProcessing داخل المتحكم.
class ScannedBarcodeLabel extends StatelessWidget {
  const ScannedBarcodeLabel({
    super.key,
    required this.barcodes,
    required this.controller,
  });

  /// بث بيانات الباركود الممسوحة.
  final Stream<BarcodeCapture> barcodes;

  /// متحكم المسح (MobileScannerController) المستخدم لتحكم الكاميرا.
  final MobileScannerController controller;

  @override
  Widget build(BuildContext context) {
    // الحصول على أبعاد الشاشة لضبط حجم النصوص والعناصر.
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;

    return GetBuilder<GetxBarcode>(
      init: GetxBarcode(controller: controller),
      builder: (barcodeController) {
        return StreamBuilder<BarcodeCapture>(
          stream: barcodes,
          builder: (context, snapshot) {
            // التحقق من وجود بيانات في الـ snapshot
            if (!snapshot.hasData) {
              return const Center(
                child: Text(
                  'قم بمسح باركود العميل',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            // استخراج قائمة الباركود الممسوحة، مع القيمة الافتراضية لقائمة فارغة.
            final List<Barcode> scannedBarcodes = snapshot.data?.barcodes ?? [];

            // في حالة عدم وجود باركود، عرض رسالة للمستخدم.
            if (scannedBarcodes.isEmpty) {
              return Text(
                'قم بمسح باركود العميل',
                overflow: TextOverflow.fade,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: width / 44,
                ),
              );
            }

            // إذا كانت القائمة غير فارغة وكان المتحكم غير مشغول بمعالجة عملية مسح أخرى،
            // يتم بدء عملية المعالجة باستخدام post-frame callback لمنع تعارض البناء.
            if (scannedBarcodes.isNotEmpty && !barcodeController.isProcessing) {
              barcodeController.startProcessing();
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                await barcodeController.barCodeScanner(scannedBarcodes, context);
                barcodeController.stopProcessing();
              });
            }

            // عرض نتيجة الباركود الأول (مثلاً قيمة العرض الخاصة به).
            return Text(
              scannedBarcodes.first.displayValue ?? 'No display value.',
              overflow: TextOverflow.fade,
              style: const TextStyle(color: Colors.white),
            );
          },
        );
      },
    );
  }
}
