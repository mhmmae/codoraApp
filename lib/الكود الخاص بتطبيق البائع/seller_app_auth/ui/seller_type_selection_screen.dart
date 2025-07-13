import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/seller_auth_controller.dart';
import '../../../services/gpu_service.dart';

class SellerTypeSelectionScreen extends GetView<SellerAuthController> {
  const SellerTypeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // تحسين GPU عند بناء الصفحة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GPUService.optimizeForMaliGPU();
    });
    
    // التأكد من تهيئة وحدة التحكم إذا لم تكن قد تهيأت بعد
    // هذا ضروري إذا كنت تصل إلى هذه الشاشة مباشرة دون المرور بمسار يقوم بـ Get.put
    // Get.put(SellerAuthController()); // قد تحتاج لإضافة هذا السطر أو التأكد من أنه في مكان آخر مناسب

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/logo.png'),
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
                      color: Colors.white, // لون النص ليتناسب مع الخلفية المعتمة
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      // تحسين GPU قبل التنقل
                      GPUService.handlePageTransition();
                      await Future.delayed(Duration(milliseconds: 100));
                      controller.selectSellerTypeAndNavigate('wholesale');
                    },
                    child: const Text('بائع جملة', style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      // تحسين GPU قبل التنقل
                      GPUService.handlePageTransition();
                      await Future.delayed(Duration(milliseconds: 100));
                      controller.selectSellerTypeAndNavigate('retail');
                    },
                    child: const Text('بائع تجزئة', style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 30),
                  TextButton(
                    onPressed: () async {
                      // تحسين GPU قبل الرجوع
                      GPUService.handlePageTransition();
                      await Future.delayed(Duration(milliseconds: 100));
                      
                      // يمكن إضافة انتقال للرجوع أو إلى شاشة تسجيل الدخول
                      if (Get.previousRoute.isNotEmpty) {
                        Get.back();
                      } else {
                        // Get.offAll(() => SellerLoginScreen()); // مثال
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