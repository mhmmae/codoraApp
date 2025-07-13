import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../XXX/xxx_firebase.dart';
import 'CompanyRegistrationController.dart';
// import 'company_registration_controller.dart'; // استورد المتحكم
// import 'location_picker_screen.dart'; // استورد شاشة اختيار الموقع

class CompanyRegistrationScreen extends GetView<CompanyRegistrationController> {
  const CompanyRegistrationScreen({super.key});



  Widget _buildHubsListSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("مقرات/فروع الشركة (اختياري)", style: Get.textTheme.titleLarge?.copyWith(color: Get.theme.primaryColorDark, fontWeight: FontWeight.w600)),
            IconButton.filled(
              icon: const Icon(Icons.add_location_alt_outlined, size: 20),
              tooltip: "إضافة مقر جديد",
              style: IconButton.styleFrom(backgroundColor: Get.theme.colorScheme.secondary, foregroundColor: Get.theme.colorScheme.onSecondary, padding: EdgeInsets.all(8)),
              onPressed: () => controller.openHubFormDialog(), // فتح حوار الإضافة
            )
          ],
        ),
        const Text("أضف مقرات شركتك إذا كنت ستستخدمها كنقاط تجميع أو استلام/تسليم.", style:TextStyle(fontSize:12, color: Colors.grey)),
        const Divider(height: 16),
        Obx(() { // لعرض قائمة المقرات أو رسالة "لا يوجد"
          if (controller.companyHubs.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0),
              child: Center(child: Text("لم تقم بإضافة أي مقرات بعد. انقر على (+) للإضافة.", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.blueGrey))),
            );
          }
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(), // لأنها داخل SingleChildScrollView
            itemCount: controller.companyHubs.length,
            itemBuilder: (ctx, index) {
              final hub = controller.companyHubs[index];
              final String hubId = hub['hubId'] as String? ?? controller. uuid.v4(); // <--- تأكد من وجود hubId أو أنشئه إذا لم يكن موجودًا
              final hubLoc = hub['hubLocation'] as LatLng?; // افترض أنه LatLng هنا
              return Card(
                key: ValueKey(hubId), // <--- إضافة ValueKey هنا باستخدام hubId
                elevation: 1.5,
                margin: const EdgeInsets.symmetric(vertical: 5),
                child: ListTile(
                    leading: CircleAvatar(radius:15, child: Text((index+1).toString())),
                    title: Text(hub['hubName'] as String? ?? 'مقر غير مسمى', style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(hub['hubAddressText'] as String? ?? 'لا يوجد عنوان'),
                        if(hubLoc != null) Text("إحداثيات: ${hubLoc.latitude.toStringAsFixed(3)}, ${hubLoc.longitude.toStringAsFixed(3)}", style:const TextStyle(fontSize:10, color:Colors.grey)),
                        Text("باركود المقر: ${hub['hubConfirmationBarcode'] as String? ?? 'N/A'}", style:const TextStyle(fontSize:11, color:Colors.teal)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit_outlined, color:Colors.blueGrey, size:20), tooltip: "تعديل المقر", onPressed: () => controller.openHubFormDialog(hubToEdit: hub, editIndex: index)),
                        IconButton(icon: const Icon(Icons.delete_outline, color:Colors.redAccent, size:20), tooltip: "حذف المقر", onPressed: () => controller.removeHub(index)),
                      ],
                    )
                ),
              );
            },
          );
        }),
      ],
    );
  }













  Widget _buildLogoPicker() {
    return Column(
      children: [
        Obx(
              () => CircleAvatar(
            radius: 65,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: controller.logoImageFile.value != null
                ? FileImage(controller.logoImageFile.value!)
                : (FirebaseX.defaultCompanyLogoUrl.isNotEmpty
                ? NetworkImage(FirebaseX.defaultCompanyLogoUrl) as ImageProvider // Cast to ImageProvider
                : null),
            child: (controller.logoImageFile.value == null && FirebaseX.defaultCompanyLogoUrl.isEmpty)
                ? Icon(Icons.business_rounded, size: 60, color: Colors.grey.shade500)
                : null,
          ),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          TextButton.icon(icon: const Icon(Icons.photo_library_outlined, size: 20), label: const Text("المعرض"),
              onPressed: () => controller.pickLogoImage(ImageSource.gallery)),
          const SizedBox(width: 10),
          TextButton.icon(icon: const Icon(Icons.camera_alt_outlined, size: 20), label: const Text("الكاميرا"),
              onPressed: () => controller.pickLogoImage(ImageSource.camera)),
        ])
      ],
    );
  }

  Widget _buildServiceAreasInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("مناطق الخدمة (أضف واحدة على الأقل)*", style: Get.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField( // يمكنك استخدام TextFormField بسيط هنا إذا كنت لا تريد validator خاص به
                controller: controller.newServiceAreaController,
                decoration: const InputDecoration(
                    hintText: "مثال: الكرخ - المنصور",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)
                ),
                onFieldSubmitted: (_) => controller.addServiceArea(), // الإضافة عند الضغط على Enter
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              icon: const Icon(Icons.add_circle_outline),
              style: IconButton.styleFrom(backgroundColor: Get.theme.primaryColor),
              onPressed: controller.addServiceArea,
              tooltip: "إضافة منطقة",
            )
          ],
        ),
        const SizedBox(height: 8),
        Obx( // هذا الـ Obx لعرض الـ Chips فقط (آمن)
              () => Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: controller.serviceAreaDescriptions.map((area) {
              return Chip(
                label: Text(area),
                onDeleted: () => controller.removeServiceArea(area),
                deleteIconColor: Colors.red.shade400,
                backgroundColor: Colors.teal.shade50,
                labelStyle: TextStyle(color: Colors.teal.shade800),
              );
            }).toList(),
          ),
        ),
        // --- عرض رسالة الخطأ بناءً على متغير Rx ---
        Obx(() { // Obx جديد للاستماع إلى serviceAreaValidationError
          if (controller.serviceAreaValidationError.value.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                controller.serviceAreaValidationError.value,
                style: TextStyle(color: Theme.of(Get.context!).colorScheme.error, fontSize: 12),
              ),
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    // Get.put(CompanyRegistrationController()); // أو استخدم Binding

    return Scaffold(
      appBar: AppBar(
        title: const Text("تسجيل شركة توصيل جديدة"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Text("معلومات الشركة الأساسية", style: Get.textTheme.headlineSmall?.copyWith(color: Get.theme.primaryColorDark))),
              const Divider(height: 24, thickness: 0.5),
              _buildLogoPicker(),
              const SizedBox(height: 20),
              TextFormField(
                controller: controller.companyNameController,
                decoration: const InputDecoration(labelText: "اسم الشركة*", prefixIcon: Icon(Icons.business_outlined)),
                validator: (v) => (v == null || v.trim().isEmpty) ? "اسم الشركة مطلوب" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.contactPhoneNumberController,
                decoration: InputDecoration(
                  labelText: "رقم هاتف الشركة للتواصل*",
                  prefixIcon: Icon(Icons.phone_in_talk_outlined),
                  // يمكن عرض حالة التحقق بجانب الحقل مباشرة
                  // suffixIcon: Obx(()=> controller.isPhoneVerifiedByOtp.value ? Icon(Icons.check_circle, color: Colors.green) : SizedBox.shrink())
                ),
                keyboardType: TextInputType.phone,
                validator: (v) => (v == null || v.trim().isEmpty) ? "رقم الهاتف مطلوب" : (!GetUtils.isPhoneNumber(v.trim().replaceAll(' ', '')) ? "رقم هاتف غير صالح" : null),
              ),
              // زر منفصل للتحقق من الهاتف
              Obx(() => controller.isPhoneVerifiedByOtp.value
                  ? Padding(padding: const EdgeInsets.only(top: 8.0), child: Row(children: [const Icon(Icons.check_circle, color: Colors.green),const SizedBox(width: 5), Text("تم التحقق من رقم الهاتف", style: TextStyle(color: Colors.green.shade700))]))
                  : (controller.isSendingPhoneOtp.value
                  ? const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Center(child: SizedBox(width: 24, height: 24, child:CircularProgressIndicator(strokeWidth: 2.5))))
                  : Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.phone_iphone_outlined, size: 20),
                  label: const Text("التحقق من رقم هاتف الشركة (OTP)"),
                  onPressed: () => controller.initiateCompanyPhoneVerification(context),
                  style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical:10)),
                ),
              ))),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.contactEmailController,
                decoration: InputDecoration(
                  labelText: "البريد الإلكتروني الرسمي للشركة*",
                  prefixIcon: Icon(Icons.alternate_email_outlined),
                  //  suffixIcon: Obx(()=> controller.isCompanyEmailVerified.value ? Icon(Icons.check_circle, color: Colors.green) : SizedBox.shrink())
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v == null || v.trim().isEmpty) ? "البريد مطلوب" : (!GetUtils.isEmail(v.trim()) ? "بريد إلكتروني غير صالح" : null),
              ),
              Obx(() => controller.isCompanyEmailVerified.value
                  ? Padding(padding: const EdgeInsets.only(top: 8.0), child: Row(children: [const Icon(Icons.check_circle, color: Colors.green), const SizedBox(width: 5), Text("تم التحقق من البريد الإلكتروني", style: TextStyle(color: Colors.green.shade700))]))
                  : (controller.isSendingEmailVerification.value
                  ? const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Center(child: SizedBox(width: 24, height: 24, child:CircularProgressIndicator(strokeWidth: 2.5))))
                  : Padding(
                padding: const EdgeInsets.only(top:8.0),
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.mark_email_read_outlined, size: 20),
                  label: const Text("إرسال رابط التحقق للبريد"),
                  onPressed: controller.sendCompanyEmailVerification,
                  style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical:10)),
                ),
              ))),
              const SizedBox(height: 24),
              Center(child: Text("معلومات إضافية (اختياري)", style: Get.textTheme.headlineSmall?.copyWith(color: Get.theme.primaryColorDark))),
              const Divider(height: 24, thickness: 0.5),

              TextFormField(
                controller: controller.commercialRegNumController,
                decoration: const InputDecoration(labelText: "رقم السجل التجاري (اختياري)", prefixIcon: Icon(Icons.badge_outlined)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.websiteUrlController,
                decoration: const InputDecoration(labelText: "موقع الشركة الإلكتروني (اختياري)", prefixIcon: Icon(Icons.language_outlined)),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.companyBioController,
                decoration: const InputDecoration(labelText: "نبذة عن الشركة (اختياري)", alignLabelWithHint: true, prefixIcon: Icon(Icons.info_outline_rounded)),
                maxLines: 3,
                minLines: 1,
              ),

              const SizedBox(height: 24),
              Center(child: Text("المقر ومناطق الخدمة", style: Get.textTheme.headlineSmall?.copyWith(color: Get.theme.primaryColorDark))),
              const Divider(height: 24, thickness: 0.5),
              InkWell( // لتحديد موقع المقر
                onTap: () => controller.openHeadquartersLocationPicker(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: "موقع المقر الرئيسي على الخريطة*",
                    border: const OutlineInputBorder(),
                    suffixIcon: Icon(Icons.map_outlined, color: Get.theme.primaryColor),
                  ),
                  child: Obx(() => Text(
                    controller.headquartersLocation.value != null
                        ? (controller.hqAddressTextController.text.isNotEmpty ? controller.hqAddressTextController.text : "تم تحديد الموقع: ${controller.headquartersLocation.value!.latitude.toStringAsFixed(4)}, ${controller.headquartersLocation.value!.longitude.toStringAsFixed(4)}")
                        : "انقر هنا لتحديد موقع المقر",
                    style: TextStyle(color: controller.headquartersLocation.value != null ? Colors.black87 : Colors.grey.shade600),
                  )),
                ),
              ),
              // يمكن إضافة TextFormField لـ hqAddressTextController هنا إذا أردت السماح بالإدخال اليدوي للعنوان *بالإضافة* للخريطة
              const SizedBox(height: 16),

              _buildHubsListSection(context),

              const SizedBox(height: 16),


              _buildServiceAreasInput(), // ودجة مناطق الخدمة

              const SizedBox(height: 30),
              Obx(() => ElevatedButton.icon(
                icon: controller.isLoading.value
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                    : const Icon(Icons.app_registration_rounded),
                label: Text(controller.isLoading.value ? "جاري الإرسال..." : "إرسال طلب تسجيل الشركة"),
                onPressed: controller.isLoading.value ? null : controller.submitCompanyProfile,
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