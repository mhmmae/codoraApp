import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pinput/pinput.dart';
import 'package:get/get.dart';

import '../controllers/code_phone_controller.dart';

/// حقل إدخال رمز التحقق باستخدام Pinput
/// يدعم التحقق التلقائي والتصميم الحديث
class PinputCodeField extends StatelessWidget {
  final CodePhoneController controller;

  const PinputCodeField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 50.w,
      height: 50.h,
      textStyle: TextStyle(
        fontSize: 20.sp,
        color: Colors.black,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        borderRadius: BorderRadius.circular(12.r),
        color: Colors.white,
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: const Color(0xFF4CAF50), width: 2),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF4CAF50).withOpacity(0.2),
          blurRadius: 8.0.clamp(0.0, double.infinity),
          offset: const Offset(0, 2),
          spreadRadius: 0.0,
        ),
      ],
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        color: const Color(0xFF4CAF50).withOpacity(0.1),
        border: Border.all(color: const Color(0xFF4CAF50), width: 1.5),
        boxShadow: [], // إزالة الظلال لتجنب التعارض
      ),
    );

    final errorPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: Colors.red, width: 2),
      boxShadow: [
        BoxShadow(
          color: Colors.red.withOpacity(0.2),
          blurRadius: 8.0.clamp(0.0, double.infinity),
          offset: const Offset(0, 2),
          spreadRadius: 0.0,
        ),
      ],
    );

    return Obx(() {
      return Column(
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: Pinput(
              controller: controller.pinController,
              length: 6,
              defaultPinTheme: defaultPinTheme,
              focusedPinTheme: focusedPinTheme,
              submittedPinTheme: submittedPinTheme,
              errorPinTheme:
                  controller.isCodeValid.value ? null : errorPinTheme,
              pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
              showCursor: true,
              cursor: Container(
                width: 2.w,
                height: 20.h,
                color: const Color(0xFF4CAF50),
              ),
              onCompleted: (pin) {
                controller.verifyCodeFromPinput();
              },
              onChanged: (value) {
                if (controller.errorMessage.value.isNotEmpty) {
                  controller.errorMessage.value = '';
                  controller.isCodeValid.value = true;
                }
              },
              hapticFeedbackType: HapticFeedbackType.lightImpact,
              animationCurve: Curves.easeInOut,
              animationDuration: const Duration(milliseconds: 200),
              keyboardType: TextInputType.number,
              autofocus: true,
              forceErrorState: !controller.isCodeValid.value,
              enableSuggestions: false,
              obscureText: false,
            ),
          ),

          // عرض رسالة الخطأ
          if (controller.errorMessage.value.isNotEmpty)
            Container(
              margin: EdgeInsets.only(top: 8.h),
              child: Text(
                controller.errorMessage.value,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      );
    });
  }
}
