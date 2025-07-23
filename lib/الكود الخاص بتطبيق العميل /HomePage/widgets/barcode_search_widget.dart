import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../controllers/barcode_filter_controller.dart';
import 'product_details_dialog.dart';

class BarcodeSearchWidget extends StatelessWidget {
  final BarcodeFilterController controller;
  final ThemeData theme;

  const BarcodeSearchWidget({
    super.key,
    required this.controller,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان القسم
          _buildSectionTitle(),
          SizedBox(height: 16.h),

          // التبديل بين زر المسح والكاميرا
          Obx(
            () =>
                controller.isScanning.value
                    ? _buildCameraScanner()
                    : _buildScanBarcodeButton(),
          ),

          SizedBox(height: 20.h),

          // عرض نتائج البحث أو رسائل الخطأ
          Obx(() => _buildResultsSection()),
        ],
      ),
    );
  }

  /// عنوان القسم
  Widget _buildSectionTitle() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.qr_code_scanner,
            color: theme.primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'البحث بالباركود',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
          ),
        ),
      ],
    );
  }

  /// زر مسح الباركود بالكاميرا
  Widget _buildScanBarcodeButton() {
    return SizedBox(
      width:
          double.infinity * 1.625, // زيادة العرض بنسبة 62.5% (25% + 30% إضافية)
      child: Material(
        elevation: 6.r,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            controller.startCameraScanning();
          },
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            height: 90.h, // تقليل الارتفاع بنسبة 25% من 120 إلى 90
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor,
                  theme.primaryColor.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code_scanner, color: Colors.white, size: 32.sp),
                SizedBox(width: 12.w),
                Text(
                  'مسح الباركود',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// كاميرا المسح في نفس المكان
  Widget _buildCameraScanner() {
    return Container(
      width:
          double.infinity * 1.625, // زيادة العرض بنسبة 62.5% (25% + 30% إضافية)
      height: 120.h, // تقليل الارتفاع بنسبة 40% من 200 إلى 120
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: theme.primaryColor, width: 2.w),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 10.r,
            offset: Offset(0, 5.h),
          ),
        ],
      ),
      child: Stack(
        children: [
          // منطقة الكاميرا
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14.r),
              child:
                  controller.hasPermission.value
                      ? MobileScanner(
                        controller: controller.scannerController,
                        onDetect: controller.onBarcodeDetected,
                      )
                      : Container(
                        color: Colors.grey.shade200,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt_outlined,
                                size: 48.sp,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'لا يمكن الوصول للكاميرا',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
            ),
          ),

          // زر الإغلاق فقط
          Positioned(
            top: 8.h,
            left: 8.w,
            child: _buildControlButton(
              icon: Icon(Icons.close, color: Colors.white, size: 20.sp),
              onTap: controller.stopCameraScanning,
              backgroundColor: Colors.red,
            ),
          ),

          // إطار المسح المتحرك
          Positioned.fill(
            child: Center(
              child: Container(
                width: 200.w,
                height: 100.h,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2.w),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Stack(
                  children: [
                    // زوايا الإطار
                    _buildScannerCorner(Alignment.topLeft),
                    _buildScannerCorner(Alignment.topRight),
                    _buildScannerCorner(Alignment.bottomLeft),
                    _buildScannerCorner(Alignment.bottomRight),

                    // زر إغلاق إضافي فوق مربع الحافة
                    Positioned(
                      top: -35.h,
                      right: 0,
                      child: _buildControlButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 18.sp,
                        ),
                        onTap: controller.stopCameraScanning,
                        backgroundColor: Colors.red.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // تعليمات المسح
          Positioned(
            bottom: 8.h,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Text(
                'ضع الباركود داخل الإطار للمسح',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.7),
                      blurRadius: 4.r,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// زر تحكم مخصص
  Widget _buildControlButton({
    required Widget icon,
    required VoidCallback onTap,
    Color? backgroundColor,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1.w,
          ),
        ),
        child: icon,
      ),
    );
  }

  /// زاوية إطار المسح
  Widget _buildScannerCorner(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 20.w,
        height: 20.h,
        decoration: BoxDecoration(
          border: Border(
            top:
                alignment.y < 0
                    ? BorderSide(color: theme.primaryColor, width: 3.w)
                    : BorderSide.none,
            bottom:
                alignment.y > 0
                    ? BorderSide(color: theme.primaryColor, width: 3.w)
                    : BorderSide.none,
            left:
                alignment.x < 0
                    ? BorderSide(color: theme.primaryColor, width: 3.w)
                    : BorderSide.none,
            right:
                alignment.x > 0
                    ? BorderSide(color: theme.primaryColor, width: 3.w)
                    : BorderSide.none,
          ),
        ),
      ),
    );
  }

  /// قسم النتائج والرسائل
  Widget _buildResultsSection() {
    // عرض رسالة المنتج غير موجود
    if (controller.showProductNotFound.value) {
      return _buildProductNotFoundMessage();
    }

    // عرض نتائج البحث
    if (controller.searchResults.isNotEmpty) {
      return _buildSearchResults();
    }

    // عرض معلومات المنتج الموجود
    if (controller.foundProduct.value != null) {
      return _buildProductDetails();
    }

    return const SizedBox.shrink();
  }

  /// رسالة عدم وجود المنتج
  Widget _buildProductNotFoundMessage() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.search_off, color: Colors.orange.shade600, size: 48.sp),
          SizedBox(height: 8.h),
          Text(
            'المنتج غير متوفر',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade800,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'لم يتم العثور على منتج بالباركود الممسوح',
            style: TextStyle(fontSize: 12.sp, color: Colors.orange.shade600),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: controller.clearNotFoundMessage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade100,
                    foregroundColor: Colors.orange.shade800,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text('إغلاق', style: TextStyle(fontSize: 12.sp)),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: controller.startCameraScanning,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text(
                    'مسح مرة أخرى',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// تفاصيل المنتج الموجود
  Widget _buildProductDetails() {
    final product = controller.foundProduct.value!;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green.shade600,
                size: 24.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'تم العثور على المنتج!',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _buildProductCard(product),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                ProductDetailsDialog.show(product);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.visibility, size: 18.sp),
                  SizedBox(width: 8.w),
                  Text(
                    'عرض التفاصيل الكاملة',
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
      ),
    );
  }

  /// عرض نتائج البحث
  Widget _buildSearchResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.search, color: theme.primaryColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'نتائج البحث:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Obx(
                () => Text(
                  '${controller.searchResults.length} منتج',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          constraints: const BoxConstraints(maxHeight: 300),
          child: Obx(
            () => ListView.builder(
              shrinkWrap: true,
              itemCount: controller.searchResults.length,
              itemBuilder: (context, index) {
                final product = controller.searchResults[index];
                return _buildProductCard(product);
              },
            ),
          ),
        ),
      ],
    );
  }

  /// بطاقة المنتج
  Widget _buildProductCard(product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          // يمكن إضافة منطق للانتقال لصفحة تفاصيل المنتج
          debugPrint('تم اختيار المنتج: ${product.name}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // صورة المنتج
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey.shade100,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child:
                    product.imageUrl != null && product.imageUrl!.isNotEmpty
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl: product.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) => Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                            errorWidget:
                                (context, url, error) => Icon(
                                  Icons.inventory_2,
                                  color: Colors.grey,
                                  size: 30,
                                ),
                          ),
                        )
                        : Icon(Icons.inventory_2, color: Colors.grey, size: 30),
              ),
              const SizedBox(width: 12),

              // معلومات المنتج
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name ?? 'غير محدد',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.qr_code,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'الباركود: ${product.productBarcode ?? 'غير متوفر'}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (product.price != null) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.attach_money,
                            size: 14,
                            color: Colors.green,
                          ),
                          Text(
                            '${product.price} ر.س',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // سهم للتفاصيل
              Icon(
                Icons.arrow_forward_ios,
                color: theme.primaryColor,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
