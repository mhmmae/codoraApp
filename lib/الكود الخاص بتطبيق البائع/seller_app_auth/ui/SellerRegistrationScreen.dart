import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/SellerRegistrationController.dart';

class SellerRegistrationScreen extends GetView<SellerRegistrationController> {
  const SellerRegistrationScreen({super.key});

  // Color scheme احترافي للتطبيق
  static const Color primaryColor = Color(0xFF6366F1);
  static const Color secondaryColor = Color(0xFF8B5CF6);
  static const Color accentColor = Color(0xFF06B6D4);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color surfaceColor = Color(0xFFF8FAFC);
  static const Color cardColor = Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Column(
                      children: [
                        SizedBox(height: 20.h),
                        _buildWelcomeSection(),
                        _buildPersonalInfoSection(),
                        _buildCategorySection(),
                        _buildImagesSection(),
                        _buildLocationSection(),
                        _buildWorkingHoursSection(),
                        SizedBox(height: 30.h),
                        _buildRegisterButton(),
                        SizedBox(height: 30.h),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 10.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: primaryColor.withOpacity(0.1)),
              ),
              child: Icon(
                Icons.arrow_back_ios_rounded,
                color: primaryColor,
                size: 20.sp,
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Text(
              'تسجيل حساب بائع',
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.w),
              margin: EdgeInsets.only(bottom: 30.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24.r),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    spreadRadius: 0,
                    blurRadius: 20.r,
                    offset: Offset(0, 10.h),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.store_rounded,
                      size: 40.sp,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'انضم لشبكة البائعين',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'املأ المعلومات التالية لإنشاء حسابك كبائع',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPersonalInfoSection() {
    return Form(
      key: controller.formKey,
      child: Column(
        children: [
          _buildAnimatedSectionTitle(
            'المعلومات الشخصية',
            icon: Icons.person_rounded,
          ),
          _buildEnhancedTextField(
            controller: controller.sellerNameController,
            label: 'اسم البائع',
            icon: Icons.person_outline_rounded,
            animationDelay: 0,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'يرجى إدخال اسم البائع';
              }
              return null;
            },
          ),
          SizedBox(height: 16.h),
          _buildEnhancedTextField(
            controller: controller.shopNameController,
            label: 'اسم المتجر',
            icon: Icons.store_outlined,
            animationDelay: 1,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'يرجى إدخال اسم المتجر';
              }
              return null;
            },
          ),
          SizedBox(height: 16.h),
          _buildEnhancedTextField(
            controller: controller.shopPhoneNumberController,
            label: 'رقم الهاتف',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            animationDelay: 2,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'يرجى إدخال رقم الهاتف';
              }
              final phoneRegExp = RegExp(r'^07[3-9]\d{8}$');
              if (!phoneRegExp.hasMatch(value.replaceAll(RegExp(r'\s+'), ''))) {
                return 'يرجى إدخال رقم هاتف عراقي صحيح (07xxxxxxxx)';
              }
              return null;
            },
          ),
          SizedBox(height: 16.h),
          _buildEnhancedTextField(
            controller: controller.shopDescriptionController,
            label: 'وصف المتجر',
            icon: Icons.description_outlined,
            animationDelay: 3,
            maxLines: 3,
            hintText: 'أدخل وصفاً مختصراً عن متجرك ومنتجاتك',
          ),
          SizedBox(height: 16.h),
          _buildEnhancedTextField(
            controller: controller.streetAddressController,
            label: 'عنوان الشارع (اختياري)',
            icon: Icons.location_city_outlined,
            animationDelay: 4,
            hintText: 'مثال: شارع الكفاح، حي المنصور',
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    return Column(
      children: [
        _buildAnimatedSectionTitle('فئة المتجر', icon: Icons.category_rounded),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(50 * (1 - value), 0),
              child: Opacity(
                opacity: value,
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.08),
                        spreadRadius: 0,
                        blurRadius: 20.r,
                        offset: Offset(0, 4.h),
                      ),
                    ],
                    border: Border.all(
                      color: primaryColor.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [primaryColor, secondaryColor],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Icon(
                                Icons.category_outlined,
                                color: Colors.white,
                                size: 20.sp,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'فئات المتجر',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1F2937),
                                    ),
                                  ),
                                  Obx(
                                    () => Text(
                                      'اختر حتى ${controller.maxCategoriesAllowed} فئات - مختار: ${controller.selectedCategoriesCount}',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: const Color(0xFF6B7280),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        Obx(
                          () => Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 12.h,
                            ),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: primaryColor.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: primaryColor,
                                  size: 18.sp,
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    controller.selectedCategoriesDisplay,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w500,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        _buildCategoriesGrid(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildImagesSection() {
    return Column(
      children: [
        _buildAnimatedSectionTitle('الصور', icon: Icons.photo_camera_rounded),
        _buildEnhancedImagePicker(
          label: 'صورة البائع الشخصية',
          imageFile: controller.sellerProfileImageFile,
          onGalleryPressed:
              () => controller.pickImage(
                ImageSource.gallery,
                isProfileImage: true,
              ),
          onCameraPressed:
              () => controller.pickImage(
                ImageSource.camera,
                isProfileImage: true,
              ),
          onRemovePressed: () => controller.removeImage(isProfileImage: true),
          animationDelay: 0,
        ),
        _buildEnhancedImagePicker(
          label: 'صورة واجهة المتجر',
          imageFile: controller.shopFrontImageFile,
          onGalleryPressed:
              () => controller.pickImage(
                ImageSource.gallery,
                isProfileImage: false,
              ),
          onCameraPressed:
              () => controller.pickImage(
                ImageSource.camera,
                isProfileImage: false,
              ),
          onRemovePressed: () => controller.removeImage(isProfileImage: false),
          animationDelay: 1,
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      children: [
        _buildAnimatedSectionTitle('الموقع', icon: Icons.location_on_rounded),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: Opacity(
                opacity: value,
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 12.h),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.1),
                        spreadRadius: 0,
                        blurRadius: 20.r,
                        offset: Offset(0, 8.h),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [accentColor, primaryColor],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Icon(
                                Icons.my_location_rounded,
                                color: Colors.white,
                                size: 24.sp,
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'موقع المتجر',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1F2937),
                                    ),
                                  ),
                                  Text(
                                    'اختر موقع متجرك على الخريطة',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20.h),
                        Obx(
                          () =>
                              controller.shopLocation.value != null
                                  ? _buildLocationPreview()
                                  : _buildLocationSelector(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLocationPreview() {
    return Column(
      children: [
        Container(
          height: 200.h,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: primaryColor.withOpacity(0.2)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: controller.shopLocation.value!,
                zoom: 16,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('selected_location'),
                  position: controller.shopLocation.value!,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueBlue,
                  ),
                ),
              },
              onTap: (latLng) => controller.shopLocation.value = latLng,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        _buildImageButton(
          icon: Icons.edit_location_rounded,
          label: "تعديل الموقع",
          onPressed: () => _showLocationPicker(),
          gradient: [warningColor, primaryColor],
        ),
      ],
    );
  }

  Widget _buildLocationSelector() {
    return Column(
      children: [
        Container(
          height: 150.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: primaryColor.withOpacity(0.2), width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_location_alt_rounded,
                  size: 32.sp,
                  color: primaryColor,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'اختر موقع المتجر',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        _buildImageButton(
          icon: Icons.location_searching_rounded,
          label: "تحديد الموقع",
          onPressed: () => _showLocationPicker(),
          gradient: [successColor, accentColor],
        ),
      ],
    );
  }

  void _showLocationPicker() {
    // استخدام الوظيفة المحسنة من Controller
    controller.showEnhancedLocationPicker(Get.context!);
  }

  Widget _buildRegisterButton() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1200),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value,
            child: Container(
              width: double.infinity,
              height: 56.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, secondaryColor],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.4),
                    spreadRadius: 0,
                    blurRadius: 20.r,
                    offset: Offset(0, 8.h),
                  ),
                ],
              ),
              child: Obx(
                () => Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap:
                        controller.isLoading.value
                            ? null
                            : () => controller.submitRegistration(context),
                    borderRadius: BorderRadius.circular(16.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (controller.isLoading.value) ...[
                            SizedBox(
                              width: 24.w,
                              height: 24.h,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 16.w),
                          ] else ...[
                            Icon(
                              Icons.check_circle_rounded,
                              color: Colors.white,
                              size: 24.sp,
                            ),
                            SizedBox(width: 12.w),
                          ],
                          Text(
                            controller.isLoading.value
                                ? 'جارٍ التسجيل...'
                                : 'إنشاء حساب البائع',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedSectionTitle(String title, {IconData? icon}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: EdgeInsets.only(top: 24.h, bottom: 16.h),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withOpacity(0.1),
                    secondaryColor.withOpacity(0.1),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: primaryColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(icon, color: primaryColor, size: 20.sp),
                    ),
                    SizedBox(width: 12.w),
                  ],
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required int animationDelay,
    TextInputType? keyboardType,
    String? hintText,
    int? maxLines,
    String? Function(String?)? validator,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (animationDelay * 200)),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(50 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.08),
                    spreadRadius: 0,
                    blurRadius: 20.r,
                    offset: Offset(0, 4.h),
                  ),
                ],
                border: Border.all(
                  color: primaryColor.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: TextFormField(
                controller: controller,
                keyboardType: keyboardType,
                maxLines: maxLines ?? 1,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: const Color(0xFF1F2937),
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  labelText: label,
                  hintText: hintText,
                  prefixIcon: Container(
                    margin: EdgeInsets.all(12.w),
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryColor.withOpacity(0.1),
                          secondaryColor.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(icon, color: primaryColor, size: 20.sp),
                  ),
                  labelStyle: TextStyle(
                    color: const Color(0xFF6B7280),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  hintStyle: TextStyle(
                    color: const Color(0xFF9CA3AF),
                    fontSize: 14.sp,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 20.h,
                  ),
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                ),
                validator: validator,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedImagePicker({
    required String label,
    required Rxn<File> imageFile,
    required Function() onGalleryPressed,
    required Function() onCameraPressed,
    required Function()? onRemovePressed,
    required int animationDelay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (animationDelay * 200)),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 12.h),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.1),
                    spreadRadius: 0,
                    blurRadius: 20.r,
                    offset: Offset(0, 8.h),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 0,
                    blurRadius: 10.r,
                    offset: Offset(0, 2.h),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primaryColor, secondaryColor],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Icon(
                            Icons.add_a_photo_rounded,
                            color: Colors.white,
                            size: 20.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Center(
                      child: Obx(
                        () =>
                            imageFile.value != null
                                ? _buildImagePreview(
                                  imageFile.value!,
                                  onRemovePressed,
                                )
                                : _buildImagePlaceholder(),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildImageButton(
                            icon: Icons.photo_library_rounded,
                            label: "المعرض",
                            onPressed: onGalleryPressed,
                            gradient: [accentColor, primaryColor],
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _buildImageButton(
                            icon: Icons.camera_alt_rounded,
                            label: "الكاميرا",
                            onPressed: onCameraPressed,
                            gradient: [successColor, accentColor],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImagePreview(File imageFile, Function()? onRemovePressed) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        Hero(
          tag: imageFile.path,
          child: Container(
            height: 200.h,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 0,
                  blurRadius: 10.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: Image.file(imageFile, fit: BoxFit.cover),
            ),
          ),
        ),
        if (onRemovePressed != null)
          Positioned(
            top: 8.h,
            right: 8.w,
            child: GestureDetector(
              onTap: onRemovePressed,
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: errorColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: errorColor.withOpacity(0.3),
                      spreadRadius: 0,
                      blurRadius: 8.r,
                      offset: Offset(0, 2.h),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 18.sp,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 200.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: primaryColor.withOpacity(0.2),
          width: 2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1500),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add_photo_alternate_rounded,
                    size: 48.sp,
                    color: primaryColor.withOpacity(0.7),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 12.h),
          Text(
            'اضغط لإضافة صورة',
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required List<Color> gradient,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withOpacity(0.3),
                spreadRadius: 0,
                blurRadius: 8.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkingHoursSection() {
    return Column(
      children: [
        _buildAnimatedSectionTitle(
          'أوقات العمل',
          icon: Icons.access_time_rounded,
        ),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 1000),
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: Opacity(
                opacity: value,
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 12.h),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.1),
                        spreadRadius: 0,
                        blurRadius: 20.r,
                        offset: Offset(0, 8.h),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [primaryColor, secondaryColor],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Icon(
                                Icons.schedule_rounded,
                                color: Colors.white,
                                size: 24.sp,
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'أوقات عمل المتجر',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1F2937),
                                    ),
                                  ),
                                  Text(
                                    'حدد أيام وأوقات عمل متجرك',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20.h),
                        Obx(() => _buildWorkingDaysList()),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildWorkingDaysList() {
    return Column(
      children:
          controller.dayKeys.map((dayKey) {
            final dayData = controller.workingHours[dayKey]!;
            final dayName = dayData['name_ar'] as String;
            final isOpen = dayData['isOpen'] as bool;
            final opensAt = dayData['opensAt'] as String?;
            final closesAt = dayData['closesAt'] as String?;

            return Container(
              margin: EdgeInsets.only(bottom: 12.h),
              decoration: BoxDecoration(
                color: isOpen ? primaryColor.withOpacity(0.05) : surfaceColor,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color:
                      isOpen
                          ? primaryColor.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Theme(
                data: Theme.of(
                  Get.context!,
                ).copyWith(dividerColor: Colors.transparent),
                child: Obx(
                  () => ExpansionTile(
                    key: ValueKey(
                      '${dayKey}_${controller.expandedDayPanel.value}_$isOpen',
                    ),
                    initiallyExpanded:
                        controller.expandedDayPanel.value == dayKey,
                    onExpansionChanged: (expanded) {
                      if (expanded) {
                        controller.expandedDayPanel.value = dayKey;
                      } else {
                        controller.expandedDayPanel.value = null;
                      }
                    },
                    tilePadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    childrenPadding: EdgeInsets.all(16.w),
                    leading: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color:
                            isOpen
                                ? primaryColor.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        isOpen
                            ? Icons.store_rounded
                            : Icons.store_mall_directory_outlined,
                        color: isOpen ? primaryColor : Colors.grey,
                        size: 20.sp,
                      ),
                    ),
                    title: Text(
                      dayName,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color:
                            isOpen
                                ? const Color(0xFF1F2937)
                                : const Color(0xFF6B7280),
                      ),
                    ),
                    subtitle:
                        isOpen && opensAt != null && closesAt != null
                            ? Text(
                              '$opensAt - $closesAt',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            )
                            : Text(
                              isOpen ? 'محدد كمفتوح - اختر الأوقات' : 'مغلق',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color:
                                    isOpen
                                        ? warningColor
                                        : const Color(0xFF9CA3AF),
                              ),
                            ),
                    trailing: Switch(
                      value: isOpen,
                      onChanged: (value) => controller.toggleDayOpen(dayKey),
                      activeColor: primaryColor,
                      inactiveThumbColor: Colors.grey,
                      inactiveTrackColor: Colors.grey.withOpacity(0.3),
                    ),
                    children:
                        isOpen ? [_buildTimeSelectionRow(dayKey, dayData)] : [],
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildTimeSelectionRow(String dayKey, Map<String, dynamic> dayData) {
    final opensAt = dayData['opensAt'] as String?;
    final closesAt = dayData['closesAt'] as String?;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTimeButton(
                label: 'وقت الفتح',
                time: opensAt ?? 'اختر',
                icon: Icons.wb_sunny_rounded,
                onPressed:
                    () => controller.selectTime(Get.context!, dayKey, true),
                color: successColor,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: _buildTimeButton(
                label: 'وقت الإغلاق',
                time: closesAt ?? 'اختر',
                icon: Icons.nightlight_round,
                onPressed:
                    () => controller.selectTime(Get.context!, dayKey, false),
                color: errorColor,
              ),
            ),
          ],
        ),
        if (controller.canApplyToOthers(dayKey) &&
            opensAt != null &&
            closesAt != null) ...[
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed:
                  () => controller.offerToApplyTimesToOtherDays(
                    Get.context!,
                    dayKey,
                    opensAt,
                    closesAt,
                  ),
              icon: Icon(Icons.copy_all_rounded, size: 18.sp),
              label: Text('تطبيق على أيام أخرى'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: BorderSide(color: primaryColor.withOpacity(0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 12.h),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTimeButton({
    required String label,
    required String time,
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 12.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20.sp),
              SizedBox(height: 4.h),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                time,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    return SizedBox(
      height: 300.h,
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 12.h,
          childAspectRatio: 3,
        ),
        itemCount: controller.shopCategories.length,
        itemBuilder: (context, index) {
          final category = controller.shopCategories[index];

          return Obx(() {
            final isSelected = controller.isCategorySelected(category);

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => controller.toggleCategorySelection(category),
                borderRadius: BorderRadius.circular(12.r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    gradient:
                        isSelected
                            ? LinearGradient(
                              colors: [primaryColor, secondaryColor],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                            : null,
                    color: isSelected ? null : surfaceColor,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color:
                          isSelected
                              ? primaryColor
                              : Colors.grey.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow:
                        isSelected
                            ? [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.3),
                                spreadRadius: 0,
                                blurRadius: 8.r,
                                offset: Offset(0, 3.h),
                              ),
                            ]
                            : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color:
                            isSelected ? Colors.white : const Color(0xFF6B7280),
                        size: 18.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            color:
                                isSelected
                                    ? Colors.white
                                    : const Color(0xFF1F2937),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          });
        },
      ),
    );
  }
}
