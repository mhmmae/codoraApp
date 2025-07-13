


import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Widget لعرض رسالة الخطأ الخاصة بالماسح.
/// يظهر هذا الـ widget عند وقوع خطأ أثناء عملية المسح،
/// ويعرض رمز الخطأ ونص توضيحي بشكل جذاب وواضح للمستخدم.
class ScannerErrorWidget extends StatelessWidget {
  const ScannerErrorWidget({super.key, required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    // تحديد رسالة الخطأ بناءً على رمز الخطأ باستخدام switch-case مع عبارات break
    String errorMessage;
    switch (error.errorCode) {
      case MobileScannerErrorCode.controllerUninitialized:
        errorMessage = 'لم يتم تهيئة المراقب بعد.';
        break;
      case MobileScannerErrorCode.permissionDenied:
        errorMessage = 'تم رفض الحصول على الأذونات.';
        break;
      case MobileScannerErrorCode.unsupported:
        errorMessage = 'المسح غير مدعوم في هذا الجهاز.';
        break;
      default:
        errorMessage = 'حدث خطأ غير معروف.';
        break;
    }

    return Container(
      // استخدم تدرج لوني بسيط لخلفية جذابة
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black87, Colors.black],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black45,
                offset: Offset(0, 4),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // أيقونة الخطأ مع حجم كبير لجذب الانتباه
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 48,
              ),
              const SizedBox(height: 16),
              // الرسالة الرئيسية لشرح الخطأ
              Text(
                errorMessage,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // شرح إضافي إذا كانت هناك تفاصيل إضافية للخطأ
              Text(
                error.errorDetails?.message ?? '',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
