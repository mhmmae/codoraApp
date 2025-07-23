import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'controllers/code_phone_controller.dart';
import 'widgets/pinput_code_field.dart';

/// صفحة إدخال رمز التحقق المحسنة والمتطورة
/// تتضمن رسوم متحركة وتجربة مستخدم متقدمة ومعالجة أخطاء ذكية
class CodePhonePage extends StatelessWidget {
  final String phoneNumber;
  final Uint8List userImage;
  final String name;
  final String email;
  final String password;
  final bool hasPassword;

  const CodePhonePage({
    super.key,
    required this.phoneNumber,
    required this.userImage,
    required this.name,
    required this.email,
    required this.password,
    required this.hasPassword,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      CodePhoneController(
        phoneNumber: phoneNumber,
        userImage: userImage,
        name: name,
        email: email,
        password: password,
      ),
    );

    return WillPopScope(
      onWillPop: () async {
        // تأكيد قبل الخروج
        return await _showExitConfirmation(context);
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: _buildSmartAppBar(controller),
        body: _buildResponsiveBody(context, controller),
      ),
    );
  }

  /// تأكيد الخروج
  Future<bool> _showExitConfirmation(BuildContext context) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('تأكيد الخروج'),
        content: const Text('هل تريد الخروج؟ ستحتاج لإعادة إرسال رمز التحقق.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('خروج'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// بناء شريط التطبيق الذكي
  PreferredSizeWidget _buildSmartAppBar(CodePhoneController controller) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: _buildBackButton(),
      title: _buildAnimatedTitle(),
      centerTitle: true,
      actions: [_buildNetworkStatusIndicator(controller)],
    );
  }

  /// زر الرجوع المحسن
  Widget _buildBackButton() {
    return Container(
      margin: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20.sp),
        onPressed: () async {
          if (await _showExitConfirmation(Get.context!)) {
            Get.back();
          }
        },
      ),
    ).animate().slideX(begin: -1, duration: 600.ms).fadeIn();
  }

  /// العنوان المتحرك
  Widget _buildAnimatedTitle() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Text(
        'تأكيد رقم الهاتف',
        style: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 18.sp,
        ),
      ),
    ).animate().slideY(begin: -1, duration: 600.ms).fadeIn();
  }

  /// مؤشر حالة الشبكة
  Widget _buildNetworkStatusIndicator(CodePhoneController controller) {
    return Obx(
      () => Container(
        margin: EdgeInsets.all(8.w),
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color:
              controller.isNetworkConnected.value
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(
          controller.isNetworkConnected.value ? Icons.wifi : Icons.wifi_off,
          color:
              controller.isNetworkConnected.value ? Colors.green : Colors.red,
          size: 20.sp,
        ),
      ).animate().scale(duration: 300.ms),
    );
  }

  /// الجسم المتجاوب
  Widget _buildResponsiveBody(
    BuildContext context,
    CodePhoneController controller,
  ) {
    return Container(
      decoration: _buildBackgroundDecoration(),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 20.h),

                      // Header Section with Animation
                      _buildAnimatedHeader()
                          .animate()
                          .slideY(begin: 0.3, duration: 800.ms)
                          .fadeIn(),

                      SizedBox(height: 30.h),

                      // Code Input Section with Animation
                      _buildEnhancedCodeInputSection(controller)
                          .animate(delay: 200.ms)
                          .slideY(begin: 0.3, duration: 800.ms)
                          .fadeIn(),

                      SizedBox(height: 20.h),

                      // Network Status Section
                      _buildNetworkStatusSection(controller),

                      SizedBox(height: 20.h),

                      // Resend Section with Animation
                      _buildEnhancedResendSection(controller)
                          .animate(delay: 400.ms)
                          .slideY(begin: 0.3, duration: 800.ms)
                          .fadeIn(),

                      SizedBox(height: 20.h),

                      // Progress and Status Section
                      _buildProgressSection(controller)
                          .animate(delay: 600.ms)
                          .slideY(begin: 0.3, duration: 800.ms)
                          .fadeIn(),

                      SizedBox(height: 30.h),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// بناء الخلفية المتدرجة
  BoxDecoration _buildBackgroundDecoration() {
    return const BoxDecoration(
      image: DecorationImage(
        image: AssetImage('assets/logo.png'),
        fit: BoxFit.cover,
        opacity: 0.03,
      ),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFF8FBFF),
          Color(0xFFE3F2FD),
          Color(0xFFF1F8FF),
          Color(0xFFE8F5E8),
        ],
        stops: [0.0, 0.3, 0.7, 1.0],
      ),
    );
  }

  /// قسم العنوان المحسن والمتحرك
  Widget _buildAnimatedHeader() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 15.r,
            offset: Offset(0, 5.h),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 70.w,
            height: 70.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade600],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 10.r,
                  offset: Offset(0, 3.h),
                ),
              ],
            ),
            child: Icon(Icons.verified_user, size: 35.sp, color: Colors.white),
          ),
          SizedBox(height: 16.h),
          Text(
            'أدخل رمز التأكيد',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'تم إرسال رمز مكون من 6 أرقام إلى',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
          ),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.phone_android,
                  color: Colors.blue.shade700,
                  size: 16.sp,
                ),
                SizedBox(width: 6.w),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    phoneNumber,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// قسم إدخال الرمز المحسن
  Widget _buildEnhancedCodeInputSection(CodePhoneController controller) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.sms, color: Colors.blue.shade600, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                'أدخل الرمز المرسل',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          // حقل إدخال رمز التحقق باستخدام Pinput
          PinputCodeField(controller: controller),
          // رسائل الخطأ
          Obx(
            () =>
                controller.errorMessage.value.isNotEmpty
                    ? Padding(
                      padding: EdgeInsets.only(top: 12.h),
                      child: _buildErrorMessage(controller.errorMessage.value),
                    )
                    : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  /// قسم حالة الشبكة
  Widget _buildNetworkStatusSection(CodePhoneController controller) {
    return Obx(() {
      if (!controller.isNetworkConnected.value) {
        return Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.red.shade600, size: 20.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'لا يوجد اتصال بالإنترنت. تحقق من اتصالك.',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ).animate().shake(duration: 800.ms);
      }
      return const SizedBox.shrink();
    });
  }

  /// قسم إعادة الإرسال المحسن
  Widget _buildEnhancedResendSection(CodePhoneController controller) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.refresh, color: Colors.orange.shade600, size: 18.sp),
              SizedBox(width: 8.w),
              Text(
                'لم تتلق الرمز؟',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Obx(
            () =>
                controller.canResend.value
                    ? _buildResendButton(controller)
                    : _buildResendTimer(controller),
          ),
          // عداد المحاولات
          Obx(
            () =>
                controller.resendAttempts.value > 0
                    ? Padding(
                      padding: EdgeInsets.only(top: 8.h),
                      child: Text(
                        'محاولات الإرسال: ${controller.resendAttempts.value} من 3',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    )
                    : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  /// قسم التقدم والحالة
  Widget _buildProgressSection(CodePhoneController controller) {
    return Obx(() {
      if (!controller.isLoading.value &&
          controller.statusMessage.value.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.1),
              blurRadius: 8.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Column(
          children: [
            if (controller.isLoading.value) ...[
              // شريط التقدم
              Obx(
                () =>
                    controller.progress.value > 0
                        ? Column(
                          children: [
                            LinearProgressIndicator(
                              value: controller.progress.value,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue.shade600,
                              ),
                            ),
                            SizedBox(height: 8.h),
                          ],
                        )
                        : CircularProgressIndicator(
                          strokeWidth: 2.w,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue.shade600,
                          ),
                        ),
              ),
              SizedBox(height: 12.h),
            ],
            if (controller.statusMessage.value.isNotEmpty)
              Text(
                controller.statusMessage.value,
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      );
    });
  }

  /// رسالة خطأ محسنة
  Widget _buildErrorMessage(String message) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600, size: 16.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// زر إعادة الإرسال
  Widget _buildResendButton(CodePhoneController controller) {
    return ElevatedButton.icon(
      onPressed: () => controller.resendCode(),
      icon: Icon(Icons.refresh, size: 18.sp, color: Colors.white),
      label: Text(
        'إعادة إرسال الرمز',
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade600,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
      ),
    );
  }

  /// مؤقت إعادة الإرسال
  Widget _buildResendTimer(CodePhoneController controller) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer, color: Colors.orange.shade600, size: 16.sp),
          SizedBox(width: 8.w),
          Obx(
            () => Text(
              'إعادة الإرسال خلال ${controller.resendCounter.value} ثانية',
              style: TextStyle(
                color: Colors.orange.shade800,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
