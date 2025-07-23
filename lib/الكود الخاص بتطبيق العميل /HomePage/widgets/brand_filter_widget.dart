import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../Model/company_model.dart';
import '../controllers/brand_filter_controller.dart';
import '../controllers/barcode_filter_controller.dart';
import 'barcode_search_widget.dart';

/// رسام مخصص لنمط الباركود
class BarcodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.1)
          ..strokeWidth = 1.5;

    final spacing = size.width / 20;

    for (int i = 0; i < 20; i++) {
      final x = i * spacing;
      final height =
          (i % 3 == 0)
              ? size.height * 0.6
              : (i % 2 == 0)
              ? size.height * 0.4
              : size.height * 0.8;
      final startY = (size.height - height) / 2;

      canvas.drawLine(Offset(x, startY), Offset(x, startY + height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ويدجت البحث من خلال البراند مع الانيميشن الاحترافي
class BrandFilterWidget extends StatelessWidget {
  const BrandFilterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final BrandFilterController controller = Get.put(BrandFilterController());
    final BarcodeFilterController barcodeController = Get.put(
      BarcodeFilterController(),
    );
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        children: [
          // الأيقونة المتحركة للتبديل بين الأنماط
          _buildAnimatedToggleButton(controller, barcodeController, theme),

          SizedBox(height: 12.h),

          // المحتوى المتحرك
          AnimatedBuilder(
            animation: controller.animationController,
            builder: (context, child) {
              return Obx(() {
                if (barcodeController.isBarcodeSearchActive.value) {
                  return _buildBarcodeSearchContent(barcodeController, theme);
                } else if (controller.isBrandModeActive.value) {
                  return _buildBrandFilterContent(controller, theme);
                } else {
                  return _buildAllProductsButton(
                    controller,
                    barcodeController,
                    theme,
                  );
                }
              });
            },
          ),

          // عرض الباركود المحفوظ للبحث
          Obx(
            () =>
                barcodeController.currentSearchBarcode.value.isNotEmpty
                    ? _buildCurrentBarcodeDisplay(barcodeController, theme)
                    : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  /// بناء عرض الباركود المحفوظ - تصميم احترافي
  Widget _buildCurrentBarcodeDisplay(
    BarcodeFilterController barcodeController,
    ThemeData theme,
  ) {
    return Container(
      margin: EdgeInsets.only(top: 12.h),
      child: Material(
        elevation: 12.r,
        borderRadius: BorderRadius.circular(16.r),
        shadowColor: theme.primaryColor.withValues(alpha: 0.3),
        child: Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            gradient: LinearGradient(
              colors: [
                theme.primaryColor.withValues(alpha: 0.1),
                theme.primaryColor.withValues(alpha: 0.05),
                Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: theme.primaryColor.withValues(alpha: 0.3),
              width: 1.5.w,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withValues(alpha: 0.2),
                blurRadius: 15.r,
                offset: Offset(0, 8.h),
                spreadRadius: 1.r,
              ),
            ],
          ),
          child: Column(
            children: [
              // العنوان مع الأيقونة
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.primaryColor,
                          theme.primaryColor.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 8.r,
                          offset: Offset(0, 4.h),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.qr_code,
                      color: Colors.white,
                      size: 22.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الباركود المحفوظ',
                          style: TextStyle(
                            fontSize: 15.sp,
                            color: theme.primaryColor,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                offset: Offset(0, 1.h),
                                blurRadius: 2.r,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'اضغط لمسح الباركود',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: theme.primaryColor.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // زر المسح مع تصميم محسن
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        barcodeController.clearCurrentBarcode();
                      },
                      borderRadius: BorderRadius.circular(10.r),
                      child: Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3),
                            width: 1.w,
                          ),
                        ),
                        child: Icon(
                          Icons.close,
                          color: Colors.red,
                          size: 18.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12.h),

              // عرض الباركود مع تصميم احترافي
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: Colors.grey.shade300, width: 1.w),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6.r,
                      offset: Offset(0, 3.h),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // أيقونة الباركود
                    Container(
                      padding: EdgeInsets.all(6.r),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Icon(
                        Icons.qr_code_scanner,
                        color: theme.primaryColor,
                        size: 16.sp,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    // النص
                    Expanded(
                      child: Text(
                        barcodeController.currentSearchBarcode.value,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          letterSpacing: 1.0.w,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // زر النسخ
                    InkWell(
                      onTap: () {
                        Clipboard.setData(
                          ClipboardData(
                            text: barcodeController.currentSearchBarcode.value,
                          ),
                        );
                        HapticFeedback.selectionClick();
                        Get.snackbar(
                          'تم النسخ',
                          'تم نسخ الباركود إلى الحافظة',
                          snackPosition: SnackPosition.TOP,
                          backgroundColor: Colors.green.withValues(alpha: 0.8),
                          colorText: Colors.white,
                          duration: const Duration(seconds: 2),
                        );
                      },
                      borderRadius: BorderRadius.circular(6.r),
                      child: Container(
                        padding: EdgeInsets.all(6.r),
                        child: Icon(
                          Icons.copy,
                          color: theme.primaryColor,
                          size: 15.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// بناء الزر المتحرك للتبديل
  Widget _buildAnimatedToggleButton(
    BrandFilterController controller,
    BarcodeFilterController barcodeController,
    ThemeData theme,
  ) {
    return AnimatedBuilder(
      animation: controller.animationController,
      builder: (context, child) {
        return Obx(() {
          final isBrandActive = controller.isBrandModeActive.value;
          final isBarcodeActive = barcodeController.isBarcodeSearchActive.value;
          final isAllActive = !isBrandActive && !isBarcodeActive;

          return SizedBox(
            height: 72.h, // مقلل بنسبة 40% من 120 ليتطابق مع الأزرار
            child:
                isAllActive
                    ? Row(
                      children: [
                        // عرض الأزرار الثلاثة جنباً إلى جنب في الوضع العادي
                        Expanded(
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 600),
                            opacity: 1.0,
                            child: _buildBrandSearchButton(
                              controller,
                              barcodeController,
                              theme,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 600),
                            opacity: 1.0,
                            child: _buildBarcodeSearchButton(
                              controller,
                              barcodeController,
                              theme,
                            ),
                          ),
                        ),
                      ],
                    )
                    : Stack(
                      children: [
                        // وضع النشاط الفردي مع زر العودة
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeInOutCubic,
                          left: 0,
                          top: 0,
                          bottom: 0,
                          right: 48.w, // تعديل المساحة حسب العرض الجديد
                          child: Transform.scale(
                            scale: 1.0,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 400),
                              opacity: 1.0,
                              child:
                                  isBrandActive
                                      ? _buildBrandSearchButton(
                                        controller,
                                        barcodeController,
                                        theme,
                                      )
                                      : _buildBarcodeSearchButton(
                                        controller,
                                        barcodeController,
                                        theme,
                                      ),
                            ),
                          ),
                        ),

                        // زر "كل المنتجات" للعودة
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeInOutCubic,
                          right: 0,
                          top: 0,
                          bottom: 0,
                          width: 42.w, // مقلل بنسبة 40% من 70
                          child: Transform.scale(
                            scale: 1.0,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 400),
                              opacity: 1.0,
                              child: _buildAllProductsToggleButton(
                                controller,
                                barcodeController,
                                theme,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
          );
        });
      },
    );
  }

  /// زر "البحث من خلال البراند" - تصميم احترافي جنوني
  Widget _buildBrandSearchButton(
    BrandFilterController controller,
    BarcodeFilterController barcodeController,
    ThemeData theme,
  ) {
    return Material(
      elevation: 12.r,
      borderRadius: BorderRadius.circular(18.r),
      shadowColor: Colors.purple.withValues(alpha: 0.4),
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          debugPrint('🖱️ تم النقر على زر البحث من خلال البراند');

          if (barcodeController.isBarcodeSearchActive.value) {
            barcodeController.deactivateBarcodeSearch();
          }
          controller.activateBrandMode();
        },
        borderRadius: BorderRadius.circular(18.r),
        splashColor: Colors.white.withValues(alpha: 0.3),
        highlightColor: Colors.white.withValues(alpha: 0.1),
        child: Container(
          height: 72.h, // مقلل بنسبة 40% من 120
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withValues(alpha: 0.4),
                blurRadius: 15.r,
                offset: Offset(0, 9.h),
                spreadRadius: 3.r,
              ),
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.3),
                blurRadius: 9.r,
                offset: Offset(0, 5.h),
              ),
            ],
          ),
          child: Stack(
            children: [
              // الصورة الخلفية تأخذ كامل المساحة
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18.r),
                  child: CachedNetworkImage(
                    imageUrl:
                        'https://img.youm7.com/ArticleImgs/2020/5/14/73940-3.jpg',
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.purple.shade600,
                                Colors.blue.shade600,
                                Colors.teal.shade500,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.business,
                              color: Colors.white,
                              size: 24.sp,
                            ),
                          ),
                        ),
                    errorWidget:
                        (context, url, error) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.purple.shade600,
                                Colors.blue.shade600,
                                Colors.teal.shade500,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.business,
                              color: Colors.white,
                              size: 24.sp,
                            ),
                          ),
                        ),
                  ),
                ),
              ),

              // طبقة التدرج الداكن للنص
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18.r),
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.black.withValues(alpha: 0.3),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.4),
                      ],
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                      stops: const [0.0, 0.3, 0.7, 1.0],
                    ),
                  ),
                ),
              ),

              // النص والأيقونات فوق الصورة
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.all(12.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // العنوان الرئيسي
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(3.r),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6.r),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 0.6.w,
                              ),
                            ),
                            child: Icon(
                              Icons.business_center,
                              color: Colors.white,
                              size: 8.sp, // مقلل بنسبة 40% من 14sp
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: EdgeInsets.all(2.5.r),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 6.sp, // مقلل بنسبة 40% من 10sp
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // النص الرئيسي
                      Flexible(
                        child: Text(
                          'البحث من خلال البراند',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 7.8.sp, // مقلل بنسبة 40% من 13sp
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2.w,
                            height: 1.0,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.8),
                                offset: Offset(0.8.w, 0.8.h),
                                blurRadius: 3.r,
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      SizedBox(height: 1.h),

                      // النص الفرعي
                      Flexible(
                        child: Text(
                          'اختر من مئات الشركات والماركات',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 5.4.sp, // مقلل بنسبة 40% من 9sp
                            fontWeight: FontWeight.w500,
                            height: 1.0,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.6),
                                offset: Offset(0.3.w, 0.3.h),
                                blurRadius: 1.5.r,
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // تأثير الإضاءة في الزاوية
              Positioned(
                top: -12.h,
                right: -12.w,
                child: Container(
                  width: 48.w,
                  height: 48.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.3),
                        Colors.white.withValues(alpha: 0.1),
                        Colors.transparent,
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

  /// زر "البحث بالباركود" - تصميم احترافي جنوني
  Widget _buildBarcodeSearchButton(
    BrandFilterController controller,
    BarcodeFilterController barcodeController,
    ThemeData theme,
  ) {
    return Material(
      elevation: 12.r,
      borderRadius: BorderRadius.circular(18.r),
      shadowColor: Colors.deepPurple.withValues(alpha: 0.4),
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          debugPrint('🖱️ تم النقر على زر البحث بالباركود');

          if (controller.isBrandModeActive.value) {
            controller.deactivateBrandModeAndClearMemory();
          }
          barcodeController.activateBarcodeSearch();
        },
        borderRadius: BorderRadius.circular(18.r),
        splashColor: Colors.white.withValues(alpha: 0.3),
        highlightColor: Colors.white.withValues(alpha: 0.1),
        child: Container(
          height: 72.h, // مقلل بنسبة 40% من 120
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withValues(alpha: 0.4),
                blurRadius: 15.r,
                offset: Offset(0, 9.h),
                spreadRadius: 3.r,
              ),
              BoxShadow(
                color: Colors.indigo.withValues(alpha: 0.3),
                blurRadius: 9.r,
                offset: Offset(0, 5.h),
              ),
            ],
          ),
          child: Stack(
            children: [
              // الخلفية المتدرجة الأساسية
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18.r),
                    gradient: LinearGradient(
                      colors: [
                        Colors.deepPurple.shade600,
                        Colors.indigo.shade600,
                        Colors.blue.shade600,
                        Colors.cyan.shade500,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: const [0.0, 0.3, 0.7, 1.0],
                    ),
                  ),
                ),
              ),

              // نمط الباركود في الخلفية
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                  child: CustomPaint(painter: BarcodePainter()),
                ),
              ),

              // طبقة التدرج للنص
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18.r),
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.6),
                        Colors.black.withValues(alpha: 0.2),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.3),
                      ],
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                      stops: const [0.0, 0.3, 0.7, 1.0],
                    ),
                  ),
                ),
              ),

              // المحتوى النصي والأيقونات
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.all(12.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // الصف العلوي مع الأيقونة
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(3.6.r),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(7.r),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4),
                                width: 0.7.w,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 3.r,
                                  offset: Offset(0, 1.5.h),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.qr_code_scanner,
                              color: Colors.white,
                              size: 8.sp, // مقلل بنسبة 40% من 14sp
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: EdgeInsets.all(2.5.r),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 6.sp, // مقلل بنسبة 40% من 10sp
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // النص الرئيسي
                      Flexible(
                        child: Text(
                          'البحث بالباركود',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 7.8.sp, // مقلل بنسبة 40% من 13sp
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2.w,
                            height: 1.0,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.8),
                                offset: Offset(0.8.w, 0.8.h),
                                blurRadius: 3.r,
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      SizedBox(height: 1.h),

                      // النص الفرعي
                      Flexible(
                        child: Text(
                          'امسح الكود السريع',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 5.4.sp, // مقلل بنسبة 40% من 9sp
                            fontWeight: FontWeight.w500,
                            height: 1.0,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.6),
                                offset: Offset(0.3.w, 0.3.h),
                                blurRadius: 1.5.r,
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // تأثيرات بصرية إضافية
              Positioned(
                top: -12.h,
                right: -12.w,
                child: Container(
                  width: 48.w,
                  height: 48.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.3),
                        Colors.white.withValues(alpha: 0.1),
                        Colors.transparent,
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

  /// زر "كل المنتجات" للعودة
  Widget _buildAllProductsToggleButton(
    BrandFilterController controller,
    BarcodeFilterController barcodeController,
    ThemeData theme,
  ) {
    return Material(
      elevation: 4.r,
      borderRadius: BorderRadius.circular(11.r),
      shadowColor: theme.primaryColor.withValues(alpha: 0.25),
      child: InkWell(
        onTap: () {
          // إضافة اهتزاز فوري لتأكيد النقر
          HapticFeedback.lightImpact();

          debugPrint('🖱️ تم النقر على زر الإغلاق');

          // إلغاء أي وضع نشط
          if (controller.isBrandModeActive.value) {
            controller
                .deactivateBrandModeAndClearMemory(); // مسح جميع المعلومات من الذاكرة
          }
          if (barcodeController.isBarcodeSearchActive.value) {
            barcodeController.deactivateBarcodeSearch();
          }
        },
        borderRadius: BorderRadius.circular(11.r),
        splashColor: theme.primaryColor.withValues(alpha: 0.3),
        highlightColor: theme.primaryColor.withValues(alpha: 0.1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
          height: 48.h, // مقلل بنسبة 40% من 80
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11.r),
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: theme.primaryColor.withValues(alpha: 0.4),
              width: 0.9.w,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withValues(alpha: 0.2),
                blurRadius: 7.r,
                offset: Offset(0, 4.h),
                spreadRadius: 0.6.r,
              ),
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.15),
                blurRadius: 4.r,
                offset: Offset(0, 2.h),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 14.w, // مقلل بنسبة 40% من 24.w
                height: 14.h, // مقلل بنسبة 40% من 24.h
                padding: EdgeInsets.all(3.r),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4.r),
                  border: Border.all(
                    color: theme.primaryColor.withValues(alpha: 0.3),
                    width: 0.4.w,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryColor.withValues(alpha: 0.1),
                      blurRadius: 1.5.r,
                      offset: Offset(0, 0.8.h),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.close,
                  color: theme.primaryColor,
                  size: 7.sp, // مقلل بنسبة 40% من 12sp
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                'إغلاق',
                style: TextStyle(
                  color: theme.primaryColor,
                  fontSize: 3.6.sp, // مقلل بنسبة 40% من 6sp
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      offset: Offset(0, 0.4.h),
                      blurRadius: 0.8.r,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// محتوى فلتر البراند
  Widget _buildBrandFilterContent(
    BrandFilterController controller,
    ThemeData theme,
  ) {
    return FadeTransition(
      opacity: controller.fadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(controller.slideAnimation),
        child: ScaleTransition(
          scale: controller.scaleAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // عنوان الشركات
              _buildSectionTitle('الشركات المتاحة', theme),
              const SizedBox(height: 12),

              // قائمة الشركات
              _buildCompaniesGrid(controller, theme),

              // المنتجات الفرعية للشركة المختارة
              Obx(
                () =>
                    controller.selectedCompany.value != null
                        ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            _buildSectionTitle(
                              'منتجات ${controller.selectedCompany.value!.nameAr}',
                              theme,
                            ),
                            const SizedBox(height: 12),
                            _buildCompanyProductsGrid(controller, theme),
                          ],
                        )
                        : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// عنوان القسم
  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: theme.primaryColor,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
    );
  }

  /// شبكة الشركات
  Widget _buildCompaniesGrid(
    BrandFilterController controller,
    ThemeData theme,
  ) {
    return Obx(() {
      if (controller.isLoading.value) {
        return SizedBox(
          height: 100,
          child: const Center(child: CircularProgressIndicator()),
        );
      }

      if (controller.companies.isEmpty) {
        return SizedBox(
          height: 100,
          child: const Center(
            child: Text(
              'لا توجد شركات متاحة',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
        );
      }

      return SizedBox(
        height: 85.h, // مقلل بنسبة 50% من 170
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: controller.companies.length,
          itemBuilder: (context, index) {
            final company = controller.companies[index];

            return _buildCompanyCard(controller, company, false, theme);
          },
        ),
      );
    });
  }

  /// بطاقة الشركة مع التحسينات البصرية
  Widget _buildCompanyCard(
    BrandFilterController controller,
    CompanyModel company,
    bool isSelected,
    ThemeData theme,
  ) {
    return Obx(() {
      final isSelectedReactive =
          controller.selectedCompany.value?.id == company.id;
      return _CompanyCardTappable(
        key: ValueKey(company.id), // مفتاح لضمان إعادة البناء الصحيحة
        company: company,
        isSelected: isSelectedReactive,
        theme: theme,
        onTap: () {
          controller.selectCompany(company);
        },
      );
    });
  }

  /// محتوى كل المنتجات
  Widget _buildAllProductsButton(
    BrandFilterController controller,
    BarcodeFilterController barcodeController,
    ThemeData theme,
  ) {
    return const SizedBox.shrink();
  }

  /// محتوى البحث بالباركود
  Widget _buildBarcodeSearchContent(
    BarcodeFilterController barcodeController,
    ThemeData theme,
  ) {
    return FadeTransition(
      opacity: AlwaysStoppedAnimation(1.0),
      child: BarcodeSearchWidget(controller: barcodeController, theme: theme),
    );
  }

  /// شبكة منتجات الشركة
  Widget _buildCompanyProductsGrid(
    BrandFilterController controller,
    ThemeData theme,
  ) {
    return Obx(() {
      if (controller.selectedCompanyProducts.isEmpty) {
        return SizedBox(
          height: 80,
          child: const Center(
            child: Text(
              'لا توجد منتجات لهذه الشركة',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
        );
      }

      return SizedBox(
        height: 70.h, // مقلل بنسبة 50% من 140
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: controller.selectedCompanyProducts.length,
          itemBuilder: (context, index) {
            final product = controller.selectedCompanyProducts[index];

            return _buildCompanyProductCard(controller, product, false, theme);
          },
        ),
      );
    });
  }

  /// بطاقة منتج الشركة مع التحسينات البصرية
  Widget _buildCompanyProductCard(
    BrandFilterController controller,
    CompanyProductModel product,
    bool isSelected,
    ThemeData theme,
  ) {
    return Obx(() {
      final isSelectedReactive =
          controller.selectedCompanyProduct.value?.id == product.id;
      return _ProductCardTappable(
        key: ValueKey(product.id),
        product: product,
        isSelected: isSelectedReactive,
        theme: theme,
        onTap: () {
          controller.selectCompanyProduct(product);
        },
      );
    });
  }
}

/// ويدجت مخصص للتعامل مع النقر على بطاقة الشركة مع تأثيرات بصرية محسنة
class _CompanyCardTappable extends StatefulWidget {
  final CompanyModel company;
  final bool isSelected;
  final ThemeData theme;
  final VoidCallback onTap;

  const _CompanyCardTappable({
    super.key,
    required this.company,
    required this.isSelected,
    required this.theme,
    required this.onTap,
  });

  @override
  State<_CompanyCardTappable> createState() => _CompanyCardTappableState();
}

class _CompanyCardTappableState extends State<_CompanyCardTappable> {
  @override
  Widget build(BuildContext context) {
    final bool showAsSelected = widget.isSelected;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        debugPrint('🖱️ الضغط على الشركة: ${widget.company.nameAr}');
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutBack,
        width: 91.w, // مقلل بنسبة 30% من 130
        height: 80.h, // مقلل بنسبة 50% من 160
        margin: EdgeInsets.only(right: 11.w), // مقلل من 16
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.r), // مقلل من 25
          boxShadow:
              showAsSelected
                  ? [
                    BoxShadow(
                      color: widget.theme.primaryColor.withValues(alpha: 0.4),
                      blurRadius: 15.r, // مقلل من 25
                      offset: Offset(0, 9.h), // مقلل من 15
                      spreadRadius: 3.r, // مقلل من 5
                    ),
                    BoxShadow(
                      color: widget.theme.primaryColor.withValues(alpha: 0.2),
                      blurRadius: 9.r, // مقلل من 15
                      offset: Offset(0, 5.h), // مقلل من 8
                    ),
                  ]
                  : [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.3),
                      blurRadius: 9.r, // مقلل من 15
                      offset: Offset(0, 5.h), // مقلل من 8
                    ),
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 5.r, // مقلل من 8
                      offset: Offset(0, 2.h), // مقلل من 4
                    ),
                  ],
        ),
        child: Material(
          elevation: 0,
          borderRadius: BorderRadius.circular(15.r),
          color: Colors.transparent,
          child: Stack(
            children: [
              // الخلفية الأساسية مع الصورة
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15.r),
                  child:
                      widget.company.logoUrl != null &&
                              widget.company.logoUrl!.isNotEmpty
                          ? CachedNetworkImage(
                            imageUrl: widget.company.logoUrl!,
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) => Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.grey.shade300,
                                        Colors.grey.shade500,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.business,
                                      color: Colors.white,
                                      size: 24, // مقلل من 40
                                    ),
                                  ),
                                ),
                            errorWidget:
                                (context, url, error) => Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.grey.shade300,
                                        Colors.grey.shade500,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.business,
                                      color: Colors.white,
                                      size: 24, // مقلل من 40
                                    ),
                                  ),
                                ),
                          )
                          : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.grey.shade300,
                                  Colors.grey.shade500,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.business,
                                color: Colors.white,
                                size: 24, // مقلل من 40
                              ),
                            ),
                          ),
                ),
              ),

              // طبقة التدرج للنص
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15.r),
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                        Colors.black.withValues(alpha: 0.9),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.4, 0.8, 1.0],
                    ),
                  ),
                ),
              ),

              // إطار الاختيار الاحترافي مع تأثيرات متقدمة
              if (showAsSelected)
                Positioned.fill(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOutBack,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15.r),
                      border: Border.all(
                        color: widget.theme.primaryColor,
                        width: 3.w, // زيادة العرض للتأكيد
                      ),
                      boxShadow: [
                        // ظل داخلي متوهج
                        BoxShadow(
                          color: widget.theme.primaryColor.withValues(
                            alpha: 0.5,
                          ),
                          blurRadius: 8.r,
                          spreadRadius: -2.r,
                          offset: Offset(0, 0),
                        ),
                        // ظل خارجي ناعم
                        BoxShadow(
                          color: widget.theme.primaryColor.withValues(
                            alpha: 0.3,
                          ),
                          blurRadius: 12.r,
                          spreadRadius: 2.r,
                          offset: Offset(0, 4.h),
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        gradient: LinearGradient(
                          colors: [
                            widget.theme.primaryColor.withValues(alpha: 0.1),
                            widget.theme.primaryColor.withValues(alpha: 0.05),
                            Colors.transparent,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                ),

              // علامة الاختيار المحسنة مع انيميشن ناعم
              if (showAsSelected)
                Positioned(
                  top: 6.h,
                  right: 6.w,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.elasticOut,
                    scale: showAsSelected ? 1.2 : 0.0, // زيادة الحجم للتأكيد
                    child: Container(
                      padding: EdgeInsets.all(3.r),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: widget.theme.primaryColor.withValues(
                              alpha: 0.4,
                            ),
                            blurRadius: 6.r,
                            offset: Offset(0, 2.h),
                          ),
                        ],
                      ),
                      child: Container(
                        width: 18.w, // زيادة الحجم
                        height: 18.h,
                        decoration: BoxDecoration(
                          color: widget.theme.primaryColor,
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              widget.theme.primaryColor,
                              widget.theme.primaryColor.withValues(alpha: 0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 12.sp, // زيادة حجم الأيقونة
                        ),
                      ),
                    ),
                  ),
                ),

              // النص في الأسفل
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(8.r), // مقلل من 16
                  child: Text(
                    widget.company.nameAr,
                    style: TextStyle(
                      fontSize: 10.sp, // مقلل من 16 واستخدام ScreenUtil
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.8),
                          offset: Offset(0.5.w, 0.5.h), // مقلل من Offset(1, 1)
                          blurRadius: 2.r, // مقلل من 4
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              // تأثير الإضاءة المتوهجة عند الاختيار
              if (showAsSelected)
                Positioned.fill(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15.r),
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 0.8,
                        colors: [
                          widget.theme.primaryColor.withValues(alpha: 0.3),
                          widget.theme.primaryColor.withValues(alpha: 0.15),
                          widget.theme.primaryColor.withValues(alpha: 0.05),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.3, 0.6, 1.0],
                      ),
                      boxShadow: [
                        // تأثير توهج خارجي
                        BoxShadow(
                          color: widget.theme.primaryColor.withValues(
                            alpha: 0.4,
                          ),
                          blurRadius: 20.r,
                          spreadRadius: 4.r,
                          offset: Offset(0, 0),
                        ),
                      ],
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

/// ويدجت مخصص للتعامل مع النقر على بطاقة المنتج مع تأثيرات بصرية محسنة
class _ProductCardTappable extends StatefulWidget {
  final CompanyProductModel product;
  final bool isSelected;
  final ThemeData theme;
  final VoidCallback onTap;

  const _ProductCardTappable({
    super.key,
    required this.product,
    required this.isSelected,
    required this.theme,
    required this.onTap,
  });

  @override
  State<_ProductCardTappable> createState() => _ProductCardTappableState();
}

class _ProductCardTappableState extends State<_ProductCardTappable> {
  @override
  Widget build(BuildContext context) {
    final bool showAsSelected = widget.isSelected;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        debugPrint('🖱️ الضغط على المنتج: ${widget.product.nameAr}');
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutBack,
        width: 77.w, // مقلل بنسبة 30% من 110
        height: 65.h, // مقلل بنسبة 50% من 130
        margin: EdgeInsets.only(right: 8.w), // مقلل من 12
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r), // مقلل من 20
          boxShadow:
              showAsSelected
                  ? [
                    BoxShadow(
                      color: widget.theme.primaryColor.withValues(alpha: 0.4),
                      blurRadius: 12.r, // مقلل من 20
                      offset: Offset(0, 7.h), // مقلل من 12
                      spreadRadius: 2.r, // مقلل من 3
                    ),
                    BoxShadow(
                      color: widget.theme.primaryColor.withValues(alpha: 0.2),
                      blurRadius: 7.r, // مقلل من 12
                      offset: Offset(0, 4.h), // مقلل من 6
                    ),
                  ]
                  : [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.2),
                      blurRadius: 7.r, // مقلل من 12
                      offset: Offset(0, 4.h), // مقلل من 6
                    ),
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 4.r, // مقلل من 6
                      offset: Offset(0, 2.h), // مقلل من 3
                    ),
                  ],
        ),
        child: Material(
          elevation: 0,
          borderRadius: BorderRadius.circular(12.r),
          color: Colors.transparent,
          child: Stack(
            children: [
              // الخلفية الأساسية مع الصورة
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child:
                      widget.product.imageUrl != null &&
                              widget.product.imageUrl!.isNotEmpty
                          ? CachedNetworkImage(
                            imageUrl: widget.product.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) => Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.grey.shade300,
                                        Colors.grey.shade400,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.inventory_2,
                                      color: Colors.white,
                                      size: 18, // مقلل من 30
                                    ),
                                  ),
                                ),
                            errorWidget:
                                (context, url, error) => Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.grey.shade300,
                                        Colors.grey.shade400,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.inventory_2,
                                      color: Colors.white,
                                      size: 18, // مقلل من 30
                                    ),
                                  ),
                                ),
                          )
                          : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.grey.shade300,
                                  Colors.grey.shade400,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.inventory_2,
                                color: Colors.white,
                                size: 18, // مقلل من 30
                              ),
                            ),
                          ),
                ),
              ),

              // طبقة التدرج للنص
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.6),
                        Colors.black.withValues(alpha: 0.85),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.5, 0.8, 1.0],
                    ),
                  ),
                ),
              ),

              // إطار الاختيار الاحترافي مع تأثيرات متقدمة
              if (showAsSelected)
                Positioned.fill(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOutBack,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: widget.theme.primaryColor,
                        width: 2.5.w, // زيادة العرض للتأكيد
                      ),
                      boxShadow: [
                        // ظل داخلي متوهج
                        BoxShadow(
                          color: widget.theme.primaryColor.withValues(
                            alpha: 0.4,
                          ),
                          blurRadius: 6.r,
                          spreadRadius: -1.r,
                          offset: Offset(0, 0),
                        ),
                        // ظل خارجي ناعم
                        BoxShadow(
                          color: widget.theme.primaryColor.withValues(
                            alpha: 0.3,
                          ),
                          blurRadius: 10.r,
                          spreadRadius: 1.5.r,
                          offset: Offset(0, 3.h),
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.r),
                        gradient: LinearGradient(
                          colors: [
                            widget.theme.primaryColor.withValues(alpha: 0.1),
                            widget.theme.primaryColor.withValues(alpha: 0.05),
                            Colors.transparent,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                ),

              // علامة الاختيار المحسنة مع انيميشن ناعم
              if (showAsSelected)
                Positioned(
                  top: 4.h,
                  right: 4.w,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.elasticOut,
                    scale: showAsSelected ? 1.1 : 0.0, // زيادة الحجم للتأكيد
                    child: Container(
                      padding: EdgeInsets.all(2.r),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: widget.theme.primaryColor.withValues(
                              alpha: 0.4,
                            ),
                            blurRadius: 4.r,
                            offset: Offset(0, 1.h),
                          ),
                        ],
                      ),
                      child: Container(
                        width: 16.w, // مناسب للحجم الصغير
                        height: 16.h,
                        decoration: BoxDecoration(
                          color: widget.theme.primaryColor,
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              widget.theme.primaryColor,
                              widget.theme.primaryColor.withValues(alpha: 0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 10.sp, // مناسب للحجم
                        ),
                      ),
                    ),
                  ),
                ),

              // النص في الأسفل
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(6.r), // مقلل من 12
                  child: Text(
                    widget.product.nameAr,
                    style: TextStyle(
                      fontSize: 8.sp, // مقلل من 14 واستخدام ScreenUtil
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.8),
                          offset: Offset(0.5.w, 0.5.h), // مقلل من Offset(1, 1)
                          blurRadius: 2.r, // مقلل من 3
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              // تأثير الإضاءة المتوهجة عند الاختيار للمنتجات
              if (showAsSelected)
                Positioned.fill(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 0.7,
                        colors: [
                          widget.theme.primaryColor.withValues(alpha: 0.25),
                          widget.theme.primaryColor.withValues(alpha: 0.12),
                          widget.theme.primaryColor.withValues(alpha: 0.04),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.3, 0.6, 1.0],
                      ),
                      boxShadow: [
                        // تأثير توهج خارجي للمنتجات
                        BoxShadow(
                          color: widget.theme.primaryColor.withValues(
                            alpha: 0.3,
                          ),
                          blurRadius: 15.r,
                          spreadRadius: 3.r,
                          offset: Offset(0, 0),
                        ),
                      ],
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
