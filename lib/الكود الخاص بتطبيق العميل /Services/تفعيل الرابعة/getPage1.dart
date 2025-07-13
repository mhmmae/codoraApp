import 'dart:async';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/material.dart';

import 'page2.dart';

class BarcodeController extends GetxController {
  // متغيرات الحالة المستخدمة مع GetX
  RxBool barcodeFound = false.obs;
  RxString scannedBarcode = "".obs;
  RxDouble zoomScale = 1.0.obs;

  Timer? zoomTimer;

  @override
  void onInit() {
    super.onInit();
    // استخدام debounce للإستجابة لتغير قيمة الباركود بعد فترة متأخرة (500 مللي ثانية)
    debounce(scannedBarcode, (_) {
      if (barcodeFound.value && scannedBarcode.value.isNotEmpty) {
        _startZoomAnimationAndNavigate();
      }
    }, time: const Duration(milliseconds: 500));
  }

  /// دالة الاستجابة عند الكشف عن الباركود
  /// نستخدم Try/Catch لمعالجة الأخطاء أثناء المعالجة
  void onDetect(BarcodeCapture capture, BuildContext context) async {
    try {
      // لتقليل استهلاك المعالج، إذا تم اكتشاف باركود مسبقاً نتجاهل المزيد من الإطارات
      if (barcodeFound.value) return;
      final List<Barcode> barcodes = capture.barcodes;
      if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
        barcodeFound.value = true;
        scannedBarcode.value = barcodes.first.rawValue!;
        // يمكنك هنا إيقاف بث الصور إذا رغبت؛ فمثلاً:
        // controller.stopImageStream(); (وفق مكتبة الكاميرا إذا كان ذلك ممكناً)
      }
    } catch (e) {
      Get.snackbar(
        "خطأ",
        "حدث خطأ أثناء معالجة الباركود: $e",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// يبدأ تأثير التكبير (Zoom) لمدة 3 ثوانٍ مع عرض رسالة انتظار للمستخدم،
  /// ثم يتم إيقاف التأثير والانتقال إلى صفحة النتائج.
  void _startZoomAnimationAndNavigate() {
    // عرض Dialog انتظار للمستخدم
    Get.dialog(
      AlertDialog(
        content: const Text("الرجاء الانتظار "),
      ),
      barrierDismissible: false,
    );

    // بدء تأثير التكبير باستخدام Timer.periodic لزيادة قيمة zoomScale تدريجيًا
    zoomTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (zoomScale.value < 2.0) {
        zoomScale.value += 0.1;
      }
    });

    // بعد 3 ثوانٍ، يتم إيقاف Timer، إغلاق الـ Dialog والانتقال إلى صفحة النتائج
    Future.delayed(const Duration(seconds: 3), () {
      zoomTimer?.cancel();
      zoomScale.value = 1.0; // إعادة حجم الزوم للحالة الطبيعية
      if (Get.isDialogOpen ?? false) {
        Get.back(); // إغلاق Dialog الانتظار
      }
      Get.to(() => BarcodeResultPage(barcode: scannedBarcode.value))?.then((_) {
        // --- يتم استدعاء هذا الكود **بعد** الرجوع من BarcodeResultPage ---
        debugPrint("Returned from BarcodeResultPage. Resetting scanner state.");
        // إعادة تعيين الحالة للسماح بالمسح مرة أخرى
        barcodeFound.value = false;
        scannedBarcode.value = "";
      });
    });
  }

  @override
  void onClose() {
    zoomTimer?.cancel();
    super.onClose();
  }
}
