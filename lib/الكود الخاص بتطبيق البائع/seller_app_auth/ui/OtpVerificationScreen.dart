import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/SellerRegistrationController.dart';
// import 'seller_registration_controller.dart'; // Adjust path as needed

class OtpVerificationScreen extends GetView<SellerRegistrationController> {
  const OtpVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String phoneNumberForDisplay = controller.shopPhoneNumberController.text.trim();
    // Potentially format it for better display, e.g., adding +964 or masking parts

    return Scaffold(
      appBar: AppBar(
        title: const Text("التحقق من رقم الهاتف"),
        centerTitle: true,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),
              Icon(Icons.phonelink_lock_outlined, size: 80, color: Get.theme.primaryColor),
              const SizedBox(height: 20),
              Text(
                "أدخل رمز التحقق",
                style: Get.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                "تم إرسال رمز مكون من 6 أرقام إلى رقم الهاتف:\n+964 $phoneNumberForDisplay", // **Adjust display for country code**
                style: Get.textTheme.titleMedium?.copyWith(color: Colors.grey.shade700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Form( // Optional: can add a form key for this OTP field too if needed
                child: TextFormField(
                  controller: controller.otpController,
                  decoration: InputDecoration(
                    labelText: "رمز التحقق (OTP)",
                    hintText: "XXXXXX",
                    prefixIcon: const Icon(Icons.password_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, letterSpacing: 3),
                  validator: (value) {
                    if (value == null || value.trim().length != 6) {
                      return "الرمز يجب أن يكون 6 أرقام";
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 25),
              Obx(
                    () => ElevatedButton.icon(
                  icon: controller.isOtpVerifying.value
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check_circle_outline),
                  label: Text(controller.isOtpVerifying.value ? "جاري التحقق..." : "تحقق من الرمز"),
                  onPressed: controller.isOtpVerifying.value
                      ? null
                      : () {
                          // جلب قيمة الـ OTP من otpController الموجود في SellerRegistrationController
                          final String otpCode = controller.otpController.text;
                          if (otpCode.isNotEmpty && otpCode.length == 6) { // افتراض أن طول الرمز 6
                            controller.verifyOtpAndFinalize(otpCode);
                          } else {
                            Get.snackbar(
                              "خطأ الإدخال",
                              "يرجى إدخال رمز OTP صالح مكون من 6 أرقام.",
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.orange.shade300,
                              colorText: Colors.white,
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Obx(()=> TextButton(
                onPressed: controller.isOtpSending.value 
                    ? null // يتم تعطيله فقط إذا كانت عملية إرسال جارية
                    : () {
                        // عند الضغط على "إعادة الإرسال"، يتم استدعاء نفس الدالة الأصلية لإرسال الـ OTP.
                        // هذه الدالة مصممة للتعامل مع resendToken إذا كان متاحًا.
                        controller.initiatePhoneVerificationAndCollectData();
                      },
                child: controller.isOtpSending.value 
                    ? Row(mainAxisSize: MainAxisSize.min, children: [ Text("جاري إعادة الإرسال... "), SizedBox(width:10, height:10,child:CircularProgressIndicator(strokeWidth:1.5))])
                    : Text("لم تستلم الرمز؟ إعادة الإرسال"),
              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}