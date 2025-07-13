import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

// import '../ui/auth/user_type_selection_screen.dart'; // تم إزالة هذا الاستيراد
import '../controllers/SellerRegistrationController.dart';
import '../../../services/gpu_service.dart';

// import 'seller_registration_controller.dart'; // Make sure path is correct
// Assuming controller is in the same directory for simplicity here

class SellerRegistrationScreen extends GetView<SellerRegistrationController> {
  const SellerRegistrationScreen({super.key});

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Text(
        title,
        style: Get.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Get.theme.primaryColorDark,
        ),
      ),
    );
  }

  Widget _buildImagePicker({
    required String label,
    required Rxn<File> imageFile,
    required Function() onGalleryPressed,
    required Function() onCameraPressed,
    required Function()? onRemovePressed, // New: For removing image
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Center(
              child: Obx(
                    () => imageFile.value != null
                    ? Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        imageFile.value!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (onRemovePressed != null)
                      Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 20),
                          onPressed: onRemovePressed,
                          tooltip: 'إزالة الصورة',
                        ),
                      )
                  ],
                )
                    : Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey.shade50,
                  ),
                  child: Icon(Icons.image_search_outlined, size: 60, color: Colors.grey.shade400),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text("المعرض"),
                    onPressed: onGalleryPressed,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Get.theme.primaryColor),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text("الكاميرا"),
                    onPressed: onCameraPressed,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Get.theme.primaryColor),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    IconData? prefixIcon,
  }) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0), // Reduced padding for inside card
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: labelText,
            hintText: hintText,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Get.theme.primaryColor) : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
        ),
      ),
    );
  }

  Widget _buildWorkingHoursSection(BuildContext context) {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: controller.workingHours.entries.map((entry) {
        String dayKey = entry.key;
        Map<String, dynamic> dayData = entry.value;
        bool isOpen = dayData['isOpen'] as bool;
        String? opensAt = dayData['opensAt'] as String?;
        String? closesAt = dayData['closesAt'] as String?;
        String dayNameAr = dayData['name_ar'] as String;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 5.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 1.5,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(dayNameAr, style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    Transform.scale(
                      scale: 0.9,
                      child: Switch( // Simpler switch, manage title separately
                        value: isOpen,
                        onChanged: (bool value) => controller.toggleDayOpen(dayKey),
                        activeColor: Get.theme.primaryColor,
                      ),
                    ),
                  ],
                ),
                Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Text(isOpen ? "مفتوح" : "مغلق", style: TextStyle(fontSize: 13, color: isOpen ? Colors.green.shade700 : Colors.red.shade700, fontWeight: FontWeight.bold))),
                if (isOpen) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => controller.selectTime(context, dayKey, true),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'وقت الفتح',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              suffixIcon: Icon(Icons.access_time, size: 20, color: Get.theme.primaryColor),
                            ),
                            child: Text(opensAt ?? 'لم يحدد', style: const TextStyle(fontSize: 15)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () => controller.selectTime(context, dayKey, false),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'وقت الإغلاق',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              suffixIcon: Icon(Icons.access_time_filled, size: 20, color: Get.theme.primaryColor),
                            ),
                            child: Text(closesAt ?? 'لم يحدد', style: const TextStyle(fontSize: 15)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isOpen && (opensAt == null || closesAt == null))
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text('يجب تحديد أوقات الفتح والإغلاق.', style: TextStyle(color: Colors.orange.shade800, fontSize: 12)),
                    ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // تحسين GPU عند بناء الصفحة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GPUService.optimizeForMaliGPU();
    });
    
    // التأكد من تهيئة وحدة التحكم إذا لم تكن قد تهيأت بعد
    if (!Get.isRegistered<SellerRegistrationController>()) {
      Get.put(SellerRegistrationController());
    }
    
    // الحصول على controller بشكل آمن
    final controller = Get.find<SellerRegistrationController>();

    return WillPopScope(
      onWillPop: () async {
        // تنظيف الذاكرة والصفحات قبل الرجوع
        GPUService.handlePageTransition();
        
        // تنظيف controller إذا كان موجود
        if (Get.isRegistered<SellerRegistrationController>()) {
          Get.delete<SellerRegistrationController>();
        }
        
        // تنظيف جميع الصفحات والرجوع للصفحة المحددة
        Get.until((route) => route.settings.name == '/seller_type_selection' || route.isFirst);
        
        // إضافة تأخير قصير للتأكد من تنظيف الذاكرة
        await Future.delayed(Duration(milliseconds: 200));
        GPUService.clearMemory();
        
        return false; // منع الرجوع الافتراضي لأننا تعاملنا معه يدوياً
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("تسجيل معلومات البائع"),
          centerTitle: true,
          elevation: 1,
          backgroundColor: Get.theme.primaryColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              // تنظيف الذاكرة والصفحات قبل الرجوع
              GPUService.handlePageTransition();
              
              // تنظيف controller إذا كان موجود
              if (Get.isRegistered<SellerRegistrationController>()) {
                Get.delete<SellerRegistrationController>();
              }
              
              // تنظيف جميع الصفحات والرجوع للصفحة المحددة
              Get.until((route) => route.settings.name == '/seller_type_selection' || route.isFirst);
              
              // إضافة تأخير قصير للتأكد من تنظيف الذاكرة
              await Future.delayed(Duration(milliseconds: 200));
              GPUService.clearMemory();
            },
          ),
        ),
        body: Obx(() => Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0), // Add padding for FAB
              child: Form(
                key: controller.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionTitle("المعلومات الأساسية"),
                    _buildTextFormField(
                      controller: controller.sellerNameController,
                      labelText: "اسم صاحب المحل*",
                      hintText: "الاسم الكامل",
                      prefixIcon: Icons.person_outline,
                      validator: (value) => (value == null || value.trim().isEmpty) ? "هذا الحقل مطلوب" : null,
                    ),
                    _buildImagePicker(
                      label: "الصورة الشخصية لصاحب المحل*",
                      imageFile: controller.sellerProfileImageFile,
                      onGalleryPressed: () => controller.pickImage(ImageSource.gallery, isProfileImage: true),
                      onCameraPressed: () => controller.pickImage(ImageSource.camera, isProfileImage: true),
                      onRemovePressed: () => controller.removeImage(isProfileImage: true),
                    ),
                    _buildTextFormField(
                      controller: controller.shopNameController,
                      labelText: "اسم المحل التجاري*",
                      hintText: "الاسم التجاري للمحل",
                      prefixIcon: Icons.storefront_outlined,
                      validator: (value) => (value == null || value.trim().isEmpty) ? "هذا الحقل مطلوب" : null,
                    ),
                    _buildImagePicker(
                      label: "صورة واجهة المحل*",
                      imageFile: controller.shopFrontImageFile,
                      onGalleryPressed: () => controller.pickImage(ImageSource.gallery, isProfileImage: false),
                      onCameraPressed: () => controller.pickImage(ImageSource.camera, isProfileImage: false),
                      onRemovePressed: () => controller.removeImage(isProfileImage: false),
                    ),
                    _buildTextFormField(
                      controller: controller.shopPhoneNumberController,
                      labelText: "رقم هاتف المحل*",
                      hintText: "مثال: 07701234567",
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return "هذا الحقل مطلوب";
                        if (!GetUtils.isPhoneNumber(value.trim())) return "رقم الهاتف غير صالح"; // Basic validation
                        return null;
                      },
                    ),
                    Card(
                      elevation: 1.5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: "فئة المحل الرئيسية*",
                            prefixIcon: Icon(Icons.category_outlined, color: Get.theme.primaryColor),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          value: controller.selectedShopCategory.value == "" || !controller.shopCategories.contains(controller.selectedShopCategory.value) ? null : controller.selectedShopCategory.value,
                          hint: const Text("اختر فئة المحل"),
                          isExpanded: true,
                          items: controller.shopCategories.map((String category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: controller.onCategoryChanged,
                          validator: (value) => value == null ? "يرجى اختيار فئة" : null,
                        ),
                      ),
                    ),
                    _buildTextFormField(
                      controller: controller.shopDescriptionController,
                      labelText: "وصف المحل (اختياري)",
                      hintText: "نبذة عن نشاط المحل وما يقدمه",
                      prefixIcon: Icons.description_outlined,
                      maxLines: 3,
                    ),

                    _buildSectionTitle("موقع المحل على الخريطة"),
                    Card(
                      elevation: 1.5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Obx(() {
                              final LatLng? currentLocation = controller.shopLocation.value;
                              if (currentLocation == null) {
                                return InkWell(
                                  onTap: () => controller.openLocationPickerScreen(context),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    height: 180,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.map_outlined, size: 50, color: Colors.grey.shade500),
                                          const SizedBox(height: 12),
                                          Text("انقر هنا لتحديد موقع المحل", style: Get.textTheme.titleSmall?.copyWith(color: Colors.grey.shade700)),
                                          const SizedBox(height: 4),
                                          Text("(مطلوب)", style: Get.textTheme.bodySmall?.copyWith(color: Colors.red.shade600)),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return SizedBox(
                                height: 200, // Adjust height as needed
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10.0),
                                  child: AbsorbPointer(
                                    absorbing: true, // Makes the map non-interactive on the registration screen
                                    child: GoogleMap(
                                      key: ValueKey('reg_map_${currentLocation.latitude}_${currentLocation.longitude}'),
                                      initialCameraPosition: CameraPosition(
                                        target: currentLocation,
                                        zoom: 16.0,
                                      ),
                                      markers: {
                                        Marker(
                                          markerId: const MarkerId("shop_registration_marker"),
                                          position: currentLocation,
                                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                                        ),
                                      },
                                      mapType: MapType.normal,
                                      zoomGesturesEnabled: false,
                                      scrollGesturesEnabled: false,
                                      tiltGesturesEnabled: false,
                                      rotateGesturesEnabled: false,
                                      myLocationButtonEnabled: false,
                                      myLocationEnabled: false,
                                      mapToolbarEnabled: false,
                                      onMapCreated: controller.onMapCreated, // Controller can still use this if needed for other logic
                                    ),
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: 12),
                            Obx(() => Text(
                                  controller.shopAddressText.value.isNotEmpty
                                      ? "العنوان: ${controller.shopAddressText.value}"
                                      : (controller.shopLocation.value != null ? "جاري جلب العنوان..." : "لم يتم تحديد الموقع بعد"),
                                  style: Get.textTheme.bodyMedium?.copyWith(color: Colors.black54),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                )),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.edit_location_alt_outlined),
                                    label: const Text("تعديل الموقع"),
                                    onPressed: () => controller.openLocationPickerScreen(context),
                                    style: OutlinedButton.styleFrom(side: BorderSide(color: Get.theme.primaryColor)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                OutlinedButton.icon(
                                  icon: Icon(Icons.my_location, color: Get.theme.primaryColor),
                                  label: const Text("موقعي"),
                                  onPressed: controller.tryMoveToCurrentLocation, // Action to get current location
                                  style: OutlinedButton.styleFrom(side: BorderSide(color: Get.theme.primaryColor)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    _buildTextFormField(
                      controller: controller.streetAddressController,
                      labelText: "عنوان الشارع (اختياري)",
                      hintText: "اسم الشارع، رقم البناية، أقرب معلم",
                      prefixIcon: Icons.signpost_outlined,
                    ),

                    _buildSectionTitle("أوقات العمل الأسبوعية"),
                    _buildWorkingHoursSection(context),

                    const SizedBox(height: 30),
                    Obx(() => ElevatedButton.icon(
                      icon: controller.isLoading.value 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.app_registration, color: Colors.white),
                      label: Text(
                        controller.isLoading.value ? "جاري التسجيل..." : "تسجيل واستمرار",
                        style: const TextStyle(fontSize: 18, color: Colors.white),
                      ),
                      onPressed: controller.isLoading.value ? null : () {
                        // منع الضغط المتكرر
                        if (!controller.isLoading.value) {
                          controller.submitRegistration(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: controller.isLoading.value 
                            ? Colors.grey.shade400 
                            : Get.theme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                    )),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        )),
        floatingActionButton: Obx(() => FloatingActionButton.extended(
          onPressed: controller.isLoading.value ? null : () {
            // منع الضغط المتكرر
            if (!controller.isLoading.value) {
              controller.submitRegistration(context);
            }
          },
          label: Text(
            controller.isLoading.value ? "جاري التسجيل..." : "تسجيل ومتابعة",
            style: const TextStyle(color: Colors.white),
          ),
          icon: controller.isLoading.value 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.app_registration, color: Colors.white),
          backgroundColor: controller.isLoading.value 
              ? Colors.grey.shade400 
              : Get.theme.primaryColor,
          elevation: 4,
        )),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        ),
    );
  }
}