import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// مدير الأخطاء للعرض والتعامل مع الأخطاء
class ErrorDisplayManager {
  /// عرض خطأ في شكل SnackBar مخصص
  static void showError(String message, {String? details}) {
    print('ERROR: $message ${details != null ? "Details: $details" : ""}');

    Get.snackbar(
      'خطأ',
      message,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade800,
      icon: Icon(Icons.error_outline, color: Colors.red.shade600),
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      snackPosition: SnackPosition.TOP,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInBack,
    );
  }

  /// عرض رسالة نجاح
  static void showSuccess(String message) {
    print('SUCCESS: $message');

    Get.snackbar(
      'نجح',
      message,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
      icon: Icon(Icons.check_circle_outline, color: Colors.green.shade600),
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      snackPosition: SnackPosition.TOP,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
    );
  }

  /// عرض رسالة تحذير
  static void showWarning(String message) {
    print('WARNING: $message');

    Get.snackbar(
      'تنبيه',
      message,
      backgroundColor: Colors.orange.shade100,
      colorText: Colors.orange.shade800,
      icon: Icon(Icons.warning_outlined, color: Colors.orange.shade600),
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      snackPosition: SnackPosition.TOP,
      isDismissible: true,
    );
  }

  /// عرض رسالة معلومات
  static void showInfo(String message) {
    print('INFO: $message');

    Get.snackbar(
      'معلومات',
      message,
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade800,
      icon: Icon(Icons.info_outline, color: Colors.blue.shade600),
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      snackPosition: SnackPosition.TOP,
      isDismissible: true,
    );
  }

  /// عرض حوار خطأ متقدم
  static void showErrorDialog({
    required String title,
    required String message,
    String? errorCode,
    VoidCallback? onRetry,
    VoidCallback? onCancel,
  }) {
    print(
      'ERROR DIALOG: $title - $message ${errorCode != null ? "Code: $errorCode" : ""}',
    );

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.red.shade50, Colors.red.shade100],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red.shade600,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(fontSize: 16, color: Colors.red.shade700),
                textAlign: TextAlign.center,
              ),
              if (errorCode != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'رمز الخطأ: $errorCode',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade800,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  if (onCancel != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Get.back();
                          onCancel();
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red.shade400),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'إلغاء',
                          style: TextStyle(
                            color: Colors.red.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (onCancel != null && onRetry != null)
                    const SizedBox(width: 12),
                  if (onRetry != null)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Get.back();
                          onRetry();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'إعادة المحاولة',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  if (onRetry == null && onCancel == null)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Get.back(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'موافق',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// عرض شاشة تحميل مع إمكانية الإلغاء
  static void showLoadingDialog({
    required String message,
    bool canCancel = true,
    VoidCallback? onCancel,
  }) {
    print('LOADING: $message');

    Get.dialog(
      WillPopScope(
        onWillPop: () async => canCancel,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue.shade50, Colors.blue.shade100],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.blue.shade600,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (canCancel) ...[
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: () {
                      Get.back();
                      onCancel?.call();
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.blue.shade400),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'إلغاء',
                      style: TextStyle(color: Colors.blue.shade600),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: canCancel,
    );
  }

  /// إخفاء شاشة التحميل
  static void hideLoadingDialog() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
      print('LOADING COMPLETED: Dialog closed');
    }
  }
}
