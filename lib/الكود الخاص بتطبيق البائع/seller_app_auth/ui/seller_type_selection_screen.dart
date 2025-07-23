import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../XXX/xxx_firebase.dart';
import '../controllers/seller_auth_controller.dart';
import '../../../services/gpu_service.dart';

class SellerTypeSelectionScreen extends GetView<SellerAuthController> {
  const SellerTypeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // تحسين GPU عند بناء الصفحة بشكل آمن
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        GPUService.optimizeForMaliGPU();
      } catch (e) {
        debugPrint("GPU Service error: $e");
      }
    });

    // التأكد من تهيئة وحدة التحكم إذا لم تكن قد تهيأت بعد
    if (!Get.isRegistered<SellerAuthController>()) {
      debugPrint("⚠️ SellerAuthController غير مسجل، جاري التسجيل...");
      Get.put(SellerAuthController(), permanent: true);
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(ImageX.ImageOfSignUp),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.4),
              BlendMode.darken,
            ),
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      'اختر نوع حساب البائع',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color:
                            Colors.white, // لون النص ليتناسب مع الخلفية المعتمة
                      ),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        try {
                          // تحسين GPU قبل التنقل بشكل آمن
                          try {
                            GPUService.handlePageTransition();
                          } catch (gpuError) {
                            debugPrint("GPU Service error: $gpuError");
                          }

                          await Future.delayed(Duration(milliseconds: 100));

                          // التأكد من وجود الكنترولر قبل الاستخدام
                          final authController =
                              Get.find<SellerAuthController>();
                          await authController.selectSellerTypeAndNavigate(
                            'wholesale',
                          );
                        } catch (e) {
                          debugPrint("خطأ في اختيار نوع البائع: $e");
                          Get.snackbar(
                            'خطأ',
                            'حدث خطأ أثناء المعالجة، يرجى المحاولة مرة أخرى',
                            snackPosition: SnackPosition.TOP,
                            backgroundColor: Colors.red.withOpacity(0.1),
                            colorText: Colors.red,
                          );
                        }
                      },
                      child: const Text(
                        'بائع جملة',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.secondary,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        try {
                          // تحسين GPU قبل التنقل بشكل آمن
                          try {
                            GPUService.handlePageTransition();
                          } catch (gpuError) {
                            debugPrint("GPU Service error: $gpuError");
                          }

                          await Future.delayed(Duration(milliseconds: 100));

                          // التأكد من وجود الكنترولر قبل الاستخدام
                          final authController =
                              Get.find<SellerAuthController>();
                          await authController.selectSellerTypeAndNavigate(
                            'retail',
                          );
                        } catch (e) {
                          debugPrint("خطأ في اختيار نوع البائع: $e");
                          Get.snackbar(
                            'خطأ',
                            'حدث خطأ أثناء المعالجة، يرجى المحاولة مرة أخرى',
                            snackPosition: SnackPosition.TOP,
                            backgroundColor: Colors.red.withOpacity(0.1),
                            colorText: Colors.red,
                          );
                        }
                      },
                      child: const Text(
                        'بائع تجزئة',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 30),
                    TextButton(
                      onPressed: () async {
                        try {
                          // تحسين GPU قبل الرجوع بشكل آمن
                          try {
                            GPUService.handlePageTransition();
                          } catch (gpuError) {
                            debugPrint("GPU Service error: $gpuError");
                          }

                          await Future.delayed(Duration(milliseconds: 100));

                          // يمكن إضافة انتقال للرجوع أو إلى شاشة تسجيل الدخول
                          if (Get.previousRoute.isNotEmpty) {
                            Get.back();
                          } else {
                            // Get.offAll(() => SellerLoginScreen()); // مثال
                          }
                        } catch (e) {
                          debugPrint("خطأ في الرجوع: $e");
                          Get.back(); // رجوع بسيط في حالة الخطأ
                        }
                      },
                      child: Text(
                        'الرجوع',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
