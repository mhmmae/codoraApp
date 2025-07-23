import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../Model/DeliveryCompanyModel.dart';
import 'DriverProfileSetupController.dart';

// افتراض وجود هذه الملفات، قم بتعديل المسارات
// import 'driver_profile_setup_controller.dart';
// import '../models/DeliveryCompanyModel.dart'; // لاستخدامه كنوع في القائمة المنسدلة


class DriverProfileSetupScreen extends GetView<DriverProfileSetupController> {
  const DriverProfileSetupScreen({super.key});

  Widget _buildImagePicker() {
    return Column(
      children: [
        Obx(
              () => CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: controller.profileImageFile.value != null
                ? FileImage(controller.profileImageFile.value!)
                : null,
            child: controller.profileImageFile.value == null
                ? Icon(Icons.person_add_alt_1_outlined, size: 60, color: Colors.grey.shade600)
                : null,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text("المعرض"),
              onPressed: () => controller.pickProfileImage(ImageSource.gallery),
            ),
            const SizedBox(width: 10),
            TextButton.icon(
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text("الكاميرا"),
              onPressed: () => controller.pickProfileImage(ImageSource.camera),
            ),
          ],
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // يمكنك وضع Get.put(DriverProfileSetupController()) هنا إذا لم تستخدم Binding
    // Get.put(DriverProfileSetupController());

    return Scaffold(
      appBar: AppBar(
        title: const Text("إكمال ملف عامل التوصيل"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImagePicker(),
              const SizedBox(height: 20),
              TextFormField(
                controller: controller.nameController,
                decoration: const InputDecoration(labelText: "الاسم الكامل*", hintText: "كما في الهوية", prefixIcon: Icon(Icons.person_outline)),
                validator: (value) => (value == null || value.trim().isEmpty) ? "الاسم مطلوب" : null,
              ),
              const SizedBox(height: 16),
              TextFormField( // حقل رقم الهاتف
                controller: controller.phoneNumberController,
                decoration: InputDecoration(
                  labelText: "رقم الهاتف*",
                  hintText: "07XXXXXXXXX",
                  prefixIcon: Icon(Icons.phone_outlined),
                  // يمكنك إضافة زر التحقق بجانب الحقل
                  suffixIcon: Obx(() => controller.isPhoneNumberVerifiedByOtp.value
                    ? Icon(Icons.check_circle, color: Colors.green)
                    : (controller.isSendingOtp.value
                        ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : TextButton(onPressed: () => controller.initiateDriverPhoneVerification(context) , child: Text("تحقق")))
                  )
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return "رقم الهاتف مطلوب";
                  // ** أضف تحققًا أكثر قوة من صحة تنسيق الرقم هنا **
                  if (!GetUtils.isPhoneNumber(value.trim().replaceAll(RegExp(r'\s+'), ''))) return "رقم هاتف غير صالح";
                  return null;
                },
              ),
              // زر تحقق منفصل لرقم الهاتف لجعله أوضح
              Obx(() => Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: controller.isPhoneNumberVerifiedByOtp.value
                    ? Row(children: [Icon(Icons.check_circle, color: Colors.green), SizedBox(width: 5), Text("تم التحقق من الرقم")])
                    : (controller.isSendingOtp.value
                    ? Center(child: CircularProgressIndicator())
                    : OutlinedButton.icon(
                  icon: Icon(Icons.verified_user_outlined),
                  label: Text("إرسال رمز التحقق للهاتف"),
                  onPressed: () => controller.initiateDriverPhoneVerification(context),
                )
                ),
              )
              ),
              const SizedBox(height: 16),
              // --- اختيار نوع المركبة ---
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "نوع المركبة*", border: OutlineInputBorder(), prefixIcon: Icon(Icons.drive_eta_outlined)),
                value: controller.selectedVehicleType.value, // تأكد من وجود هذا المتغير Rx في المتحكم
                hint: const Text("اختر نوع مركبتك"),
                isExpanded: true,
                items: controller.vehicleTypes.map((String type) { // vehicleTypes يجب أن تكون معرفة في المتحكم
                  return DropdownMenuItem<String>(value: type, child: Text(type));
                }).toList(),
                onChanged: controller.onVehicleTypeChanged, // دالة في المتحكم لتحديث القيمة
                validator: (value) => value == null ? "الرجاء اختيار نوع المركبة" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.vehiclePlateController,
                decoration: const InputDecoration(labelText: "رقم لوحة المركبة (اختياري)", prefixIcon: Icon(Icons.pin_outlined)),
                // لا يوجد validator إلزامي هنا
              ),
              const SizedBox(height: 20),
              Text("اختيار شركة التوصيل للانضمام*", style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Obx(() {
                if (controller.isLoadingCompanies.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.availableCompanies.isEmpty) {
                  return const Center(child: Text("لا توجد شركات توصيل متاحة حاليًا."));
                }
                return DropdownButtonFormField<DeliveryCompanyModel>(
                  decoration: const InputDecoration(labelText: "شركة التوصيل*", border: OutlineInputBorder(), prefixIcon: Icon(Icons.business_center_outlined)),
                  value: controller.selectedCompany.value,
                  hint: const Text("اختر شركة للانضمام"),
                  isExpanded: true,
                  items: controller.availableCompanies.map((DeliveryCompanyModel company) {
                    return DropdownMenuItem<DeliveryCompanyModel>(
                      value: company,
                      child: Text(company.companyName, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: controller.onCompanyChanged,
                  validator: (value) => value == null ? "يرجى اختيار شركة توصيل" : null,
                );
              }),
              const SizedBox(height: 30),
              Obx(
                    () => ElevatedButton.icon(
                  icon: controller.isProfileSubmitting.value
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                      : const Icon(Icons.send_to_mobile_outlined),
                  label: Text(controller.isProfileSubmitting.value ? "جاري الإرسال..." : "إرسال طلب الانضمام"),
                  onPressed: controller.isProfileSubmitting.value ? null : controller.sendApplicationToCompany,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// شاشة بسيطة لـ OTP السائق (إذا لم تكن لديك واحدة عامة)
// DriverOtpScreen.dart
class DriverOtpScreen extends StatelessWidget {
  final Function() onVerified;
  final String verificationId; // من Controller
  final DriverProfileSetupController driverController = Get.find(); // Get the existing controller

  DriverOtpScreen({super.key, required this.onVerified, required this.verificationId});

  final TextEditingController otpInputController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("التحقق من الرمز")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("أدخل الرمز المرسل إلى ${driverController.driverPhoneNumberForOtp.value}"),
            SizedBox(height: 20),
            TextField(
              controller: otpInputController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              decoration: InputDecoration(labelText: "OTP"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (otpInputController.text.trim().length == 6) {
                  PhoneAuthCredential credential = PhoneAuthProvider.credential(
                      verificationId: verificationId, // استخدم الـ ID الممرر
                      smsCode: otpInputController.text.trim());
                  try {
                    // لا تحتاج فعليًا لـ signIn أو link هنا، يكفي أن Credential لم ترمِ استثناءً
                    // لكن لتكون متأكدًا أكثر، يمكنك محاولة link
                    // await driverController._auth.currentUser?.linkWithCredential(credential);
                    debugPrint("OTP seems valid based on credential creation for driver.");
                    onVerified(); // استدعاء الـ callback للنجاح
                  } on FirebaseAuthException catch (e) {
                    Get.snackbar("خطأ", "رمز التحقق غير صحيح: ${e.message}", backgroundColor: Colors.red);
                  }
                } else {
                  Get.snackbar("خطأ", "الرمز يجب أن يكون 6 أرقام", backgroundColor: Colors.orange);
                }
              },
              child: Text("تحقق"),
            ),
            TextButton(
                onPressed: () {
                  if (driverController.resendToken.value != null) {
                    // منطق إعادة الإرسال هنا يجب أن يستدعي _auth.verifyPhoneNumber
                    // مع forceResendingToken: driverController.resendToken.value
                    // يمكنك إضافة دالة resendOtpForDriver في المتحكم.
                    debugPrint("TODO: Implement resend OTP for driver with token: ${driverController.resendToken.value}");
                    // driverController.resendDriverOtp(context); // مثال لاسم دالة
                  } else {
                    Get.snackbar("خطأ", "لا يمكن إعادة إرسال الرمز الآن.", backgroundColor: Colors.orange);
                  }
                },
                child: Text("إعادة إرسال الرمز")
            )
          ],
        ),
      ),
    );
  }
}