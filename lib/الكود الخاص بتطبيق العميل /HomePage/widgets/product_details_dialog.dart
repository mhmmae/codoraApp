import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../Model/model_item.dart';

/// ويدجت تفاصيل المنتج الاحترافية
class ProductDetailsDialog extends StatelessWidget {
  final ItemModel product;

  const ProductDetailsDialog({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(16.r),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.95,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20.r,
              offset: Offset(0, 10.h),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(theme),

            // محتوى المنتج
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // صورة المنتج
                    _buildProductImage(),

                    SizedBox(height: 20.h),

                    // معلومات أساسية
                    _buildBasicInfo(theme),

                    SizedBox(height: 16.h),

                    // تفاصيل إضافية
                    _buildAdditionalDetails(theme),

                    SizedBox(height: 20.h),

                    // أزرار العمل
                    _buildActionButtons(theme),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header العلوي
  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor,
            theme.primaryColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(Icons.inventory_2, color: Colors.white, size: 24.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تفاصيل المنتج',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'المعلومات الكاملة للمنتج',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Get.back();
            },
            icon: Icon(Icons.close, color: Colors.white, size: 24.sp),
          ),
        ],
      ),
    );
  }

  /// صورة المنتج
  Widget _buildProductImage() {
    return Center(
      child: Container(
        width: 200.w,
        height: 200.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.3),
              blurRadius: 15.r,
              offset: Offset(0, 8.h),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child:
              product.imageUrl?.isNotEmpty == true
                  ? CachedNetworkImage(
                    imageUrl: product.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => Container(
                          color: Colors.grey.shade100,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2.w),
                          ),
                        ),
                    errorWidget:
                        (context, url, error) => Container(
                          color: Colors.grey.shade100,
                          child: Icon(
                            Icons.inventory_2,
                            color: Colors.grey,
                            size: 60.sp,
                          ),
                        ),
                  )
                  : Container(
                    color: Colors.grey.shade100,
                    child: Icon(
                      Icons.inventory_2,
                      color: Colors.grey,
                      size: 60.sp,
                    ),
                  ),
        ),
      ),
    );
  }

  /// المعلومات الأساسية
  Widget _buildBasicInfo(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // اسم المنتج
        Text(
          product.name.isNotEmpty ? product.name : 'غير محدد',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
          ),
        ),

        SizedBox(height: 12.h),

        // السعر
        if (product.price > 0) ...[
          _buildInfoRow(
            icon: Icons.attach_money,
            label: 'السعر',
            value: '${product.price} ر.س',
            color: Colors.green,
          ),
          SizedBox(height: 8.h),
        ],

        // الباركود
        _buildInfoRow(
          icon: Icons.qr_code,
          label: 'الباركود',
          value:
              (product.productBarcode?.isNotEmpty == true)
                  ? product.productBarcode!
                  : 'غير متوفر',
          color: theme.primaryColor,
          isCopyable: true,
        ),
      ],
    );
  }

  /// التفاصيل الإضافية
  Widget _buildAdditionalDetails(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تفاصيل إضافية',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
          ),
        ),

        SizedBox(height: 12.h),

        // الوصف
        if (product.description?.isNotEmpty == true) ...[
          _buildInfoSection(
            title: 'الوصف',
            content: product.description!,
            icon: Icons.description,
          ),
          SizedBox(height: 12.h),
        ],

        // معرف المنتج
        _buildInfoRow(
          icon: Icons.tag,
          label: 'معرف المنتج',
          value: product.id,
          color: Colors.grey.shade600,
          isSmall: true,
        ),
      ],
    );
  }

  /// صف معلومات
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isCopyable = false,
    bool isSmall = false,
  }) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.w),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: isSmall ? 16.sp : 20.sp),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isSmall ? 10.sp : 12.sp,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: isSmall ? 12.sp : 14.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          if (isCopyable) ...[
            const Spacer(),
            IconButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                HapticFeedback.selectionClick();
                Get.snackbar(
                  'تم النسخ',
                  'تم نسخ $label إلى الحافظة',
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: Colors.green.withValues(alpha: 0.8),
                  colorText: Colors.white,
                  duration: const Duration(seconds: 2),
                );
              },
              icon: Icon(Icons.copy, color: color, size: 16.sp),
            ),
          ],
        ],
      ),
    );
  }

  /// قسم معلومات
  Widget _buildInfoSection({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.grey.shade300, width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey.shade600, size: 16.sp),
              SizedBox(width: 8.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            content,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey.shade800,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// أزرار العمل
  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
              foregroundColor: Colors.grey.shade700,
              elevation: 0,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: Text(
              'إغلاق',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              // يمكن إضافة منطق إضافة المنتج للسلة أو المفضلة
              Get.snackbar(
                '✅ تم',
                'يمكن إضافة منطق إضافي هنا',
                backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                colorText: theme.primaryColor,
                duration: const Duration(seconds: 2),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              elevation: 2,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_shopping_cart, size: 18.sp),
                SizedBox(width: 8.w),
                Text(
                  'إضافة للسلة',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// عرض نافذة تفاصيل المنتج
  static void show(ItemModel product) {
    Get.dialog(
      ProductDetailsDialog(product: product),
      barrierDismissible: true,
    );
  }
}
