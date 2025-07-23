import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'addNewItem/addNewItem.dart';
import 'addQuantity/search_existing_product_page.dart';
import 'barcodeOperations/barcode_operations_page.dart';
import 'editProducts/products_list_for_edit_page.dart';

class ImageController extends GetxController {
  Rx<Uint8List?> selectedImage = Rx<Uint8List?>(
    null,
  ); // الصورة القابلة للمراقبة
  RxBool isAnimating = false.obs; // للتحكم بالانميشن
  void handleImage(ImageSource source, String type) async {
    final ImagePicker imagePicker = ImagePicker();
    final XFile? imageX = await imagePicker.pickImage(source: source);

    if (imageX != null) {
      selectedImage.value = await imageX.readAsBytes(); // تعيين الصورة المختارة
      isAnimating.value = true; // تفعيل الانميشن

      // الانتقال إلى الصفحة الجديدة مع الصورة
      Get.to(() => ViewImage(uint8list: selectedImage.value!, TypeItem: type));
    } else {
      Get.snackbar(
        "خطأ",
        "لم يتم اختيار صورة!",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void resetSelection() {
    selectedImage.value = null; // إعادة تعيين الصورة
    isAnimating.value = false; // إيقاف الانميشن
  }
}

class AddItem extends StatelessWidget {
  const AddItem({super.key});

  @override
  Widget build(BuildContext context) {
    final ImageController controller = Get.put(ImageController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة المنتجات'),
        leading: GestureDetector(
          onTap: () => resetImageOnBack(context),
          child: const Icon(Icons.arrow_back),
        ),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.black12,
        elevation: 2,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blueAccent.withOpacity(0.1), Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.h),

              // البطاقات
              LayoutBuilder(
                builder: (context, constraints) {
                  // تحديد عدد الأعمدة بناءً على عرض الشاشة
                  final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;

                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16.w,
                    mainAxisSpacing: 16.h,
                    childAspectRatio: 0.9,
                    children: [
                      // بطاقة إضافة منتج عادي
                      _buildProductCard(
                        context: context,
                        icon: Icons.add_shopping_cart,
                        title: 'إضافة منتج جديد',
                        subtitle: 'أضف منتج عادي إلى المتجر',
                        color: Colors.blueAccent,
                        onTap: () => _showImagePickerSheet(controller, "Item"),
                      ),

                      // بطاقة إضافة كمية لمنتج موجود
                      _buildProductCard(
                        context: context,
                        icon: Icons.add_circle_outline,
                        title: 'إضافة كمية منتج موجود',
                        subtitle: 'أضف كمية لمنتج موجود في المخزن',
                        color: Colors.green,
                        onTap: () => _navigateToAddQuantity(),
                      ),

                      // بطاقة طباعة الباركود الجديدة
                      _buildProductCard(
                        context: context,
                        icon: Icons.qr_code,
                        title: 'طباعة وإدارة الباركود',
                        subtitle: 'طباعة أو إضافة باركودات للمنتجات',
                        color: Colors.purple,
                        onTap: () => _navigateToBarcodeOperations(),
                      ),

                      // بطاقة تعديل المنتجات
                      _buildProductCard(
                        context: context,
                        icon: Icons.edit,
                        title: 'تعديل المنتجات',
                        subtitle: 'تعديل معلومات المنتجات الموجودة',
                        color: Colors.amber,
                        onTap: () => _navigateToEditProducts(),
                      ),

                      // بطاقة إضافية للمستقبل
                      _buildProductCard(
                        context: context,
                        icon: Icons.analytics,
                        title: 'تقارير المنتجات',
                        subtitle: 'عرض تقارير وإحصائيات المنتجات',
                        color: Colors.orange,
                        onTap: () => _showComingSoon(),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // بناء بطاقة المنتج الجميلة
  Widget _buildProductCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.1), Colors.white],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(10.w), // تقليل المسافة الداخلية أكثر
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // أيقونة مع تأثير دائري - حجم أصغر
                Container(
                  width: 50.w,
                  height: 45.h,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8.r,
                        spreadRadius: 1.r,
                        offset: Offset(0, 3.h),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 20.sp, color: color),
                ),
                SizedBox(height: 6.h),

                // العنوان - حجم خط أصغر
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),

                // النص الفرعي - حجم خط أصغر
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8.h),

                // مؤشر النقر - حجم أصغر
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 4.r,
                        offset: Offset(0, 1.h),
                      ),
                    ],
                  ),
                  child: Text(
                    'ابدأ الآن',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 10.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void resetImageOnBack(BuildContext context) {
    Navigator.pop(context);
    Get.find<ImageController>().resetSelection();
  }

  void _navigateToAddQuantity() {
    Get.to(() => const SearchExistingProductPage());
  }

  void _navigateToBarcodeOperations() {
    Get.to(() => const BarcodeOperationsPage());
  }

  void _navigateToEditProducts() {
    Get.to(() => const ProductsListForEditPage());
  }

  void _showImagePickerSheet(ImageController controller, String type) {
    showModalBottomSheet(
      context: Get.context!,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return Container(
          height: 300.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            children: [
              // مقبض الإغلاق
              Container(
                width: 50.w,
                height: 5.h,
                margin: EdgeInsets.symmetric(vertical: 10.h),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),

              Text(
                'اختر مصدر الصورة',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20.h),

              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(Icons.camera, color: Colors.blue, size: 24.sp),
                ),
                title: Text("التقاط صورة", style: TextStyle(fontSize: 16.sp)),
                subtitle: Text(
                  "استخدام الكاميرا",
                  style: TextStyle(fontSize: 12.sp),
                ),
                onTap: () {
                  Navigator.pop(context);
                  controller.handleImage(ImageSource.camera, type);
                },
              ),

              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(Icons.photo, color: Colors.green, size: 24.sp),
                ),
                title: Text(
                  "اختيار من المعرض",
                  style: TextStyle(fontSize: 16.sp),
                ),
                subtitle: Text(
                  "من الصور المحفوظة",
                  style: TextStyle(fontSize: 12.sp),
                ),
                onTap: () {
                  Navigator.pop(context);
                  controller.handleImage(ImageSource.gallery, type);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showComingSoon() {
    Get.snackbar(
      "قريباً",
      "هذه الميزة قريباً",
      backgroundColor: Colors.grey,
      colorText: Colors.white,
    );
  }
}
