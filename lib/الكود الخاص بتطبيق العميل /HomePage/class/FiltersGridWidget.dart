import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math';

import '../controllers/filters_display_controller.dart';
import 'FilteredProductsScreen.dart';

/// ويدجت لعرض جميع الفلاتر بدلاً من المنتجات
class FiltersGridWidget extends StatelessWidget {
  const FiltersGridWidget({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('🟢 🚨 CRITICAL: FiltersGridWidget.build() STARTED');
    debugPrint(
      '🟢 🚨 CRITICAL: This message should appear if widget is being built',
    );
    debugPrint('🟢 FiltersGridWidget - تم بناء الويدجت!');
    debugPrint('🟢 محاولة إنشاء FiltersDisplayController...');

    final controller = Get.put(FiltersDisplayController());
    debugPrint('🟢 FiltersDisplayController - تم إنشاء الـ controller بنجاح');
    debugPrint('🟢 isLoading: ${controller.isLoading.value}');
    debugPrint('🟢 allFilters count: ${controller.allFilters.length}');

    final theme = Theme.of(context);

    return Obx(() {
      debugPrint('🟦 FiltersGridWidget Obx - إعادة بناء');
      debugPrint('🟦 isLoading: ${controller.isLoading.value}');
      debugPrint('🟦 allFilters count: ${controller.allFilters.length}');

      if (controller.isLoading.value) {
        debugPrint('🟦 عرض شاشة التحميل');
        return _buildLoadingGrid(context);
      }

      if (controller.allFilters.isEmpty) {
        debugPrint('🟦 عرض شاشة فارغة');
        return _buildEmptyState(context, theme);
      }

      debugPrint('🟦 عرض المحتوى الرئيسي');

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 7.w),
        child: _buildMixedFiltersAndProductsLayout(context, controller, theme),
      );
    });
  }

  /// بناء التخطيط المختلط للفلاتر والمنتجات
  Widget _buildMixedFiltersAndProductsLayout(
    BuildContext context,
    FiltersDisplayController controller,
    ThemeData theme,
  ) {
    // الحصول على الفلاتر التي تحتوي على منتجات فقط
    final validFilters =
        controller.allFilters
            .where(
              (filter) =>
                  filter.productCount != null && filter.productCount! > 0,
            )
            .toList();

    if (validFilters.isEmpty) {
      debugPrint('🟦 لا توجد فلاتر صالحة للعرض');
      return _buildEmptyState(context, theme);
    }

    // خلط الفلاتر عشوائياً
    final shuffledFilters = List<FilterItemModel>.from(validFilters)..shuffle();

    // بناء العرض المختلط
    return _buildMixedContent(context, controller, shuffledFilters, theme);
  }

  /// بناء المحتوى المختلط (فلاتر ومنتجات)
  Widget _buildMixedContent(
    BuildContext context,
    FiltersDisplayController controller,
    List<FilterItemModel> shuffledFilters,
    ThemeData theme,
  ) {
    final List<Widget> mixedContent = [];
    final random = Random();

    int currentIndex = 0;
    int sectionNumber = 1;

    while (currentIndex < shuffledFilters.length) {
      // تحديد عدد الفلاتر في هذا القسم (7-10)
      final filtersInSection = min(
        7 + random.nextInt(4), // 7-10 فلاتر
        shuffledFilters.length - currentIndex,
      );

      // إضافة قسم الفلاتر
      final sectionFilters =
          shuffledFilters.skip(currentIndex).take(filtersInSection).toList();

      mixedContent.add(
        _buildFiltersSection(context, sectionFilters, sectionNumber, theme),
      );

      currentIndex += filtersInSection;

      // إضافة قسم المنتجات إذا لم نصل للنهاية ولدينا منتجات
      if (currentIndex < shuffledFilters.length &&
          controller.randomProducts.isNotEmpty) {
        mixedContent.add(_buildProductsSection(context, controller, theme));
      }

      sectionNumber++;
    }

    // إذا لم يتم عرض المنتجات بعد، عرضها في النهاية
    if (controller.randomProducts.isNotEmpty &&
        !mixedContent.any(
          (widget) => widget.key?.toString().contains('products') ?? false,
        )) {
      mixedContent.add(_buildProductsSection(context, controller, theme));
    }

    return Column(children: mixedContent);
  }

  /// بناء قسم الفلاتر مع رقم القسم
  Widget _buildFiltersSection(
    BuildContext context,
    List<FilterItemModel> sectionFilters,
    int sectionNumber,
    ThemeData theme,
  ) {
    return Container(
      key: ValueKey('filters_section_$sectionNumber'),
      margin: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان القسم
          if (sectionNumber > 1) // لا نعرض عنوان للقسم الأول
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: theme.primaryColor.withOpacity(0.3),
                    width: 1.w,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size: 16.sp,
                      color: theme.primaryColor,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'مجموعة الفلاتر $sectionNumber',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: theme.primaryColor,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        '${sectionFilters.length}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // الفلاتر نفسها
          _buildCustomFilterLayout(context, sectionFilters, theme),
        ],
      ),
    );
  }

  /// بناء قسم المنتجات
  Widget _buildProductsSection(
    BuildContext context,
    FiltersDisplayController controller,
    ThemeData theme,
  ) {
    return Container(
      key: const ValueKey('products_section'),
      margin: EdgeInsets.only(bottom: 20.h),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ],
      ),
    );
  }

  /// بناء تخطيط مخصص للفلاتر
  Widget _buildCustomFilterLayout(
    BuildContext context,
    List<FilterItemModel> filters,
    ThemeData theme,
  ) {
    List<Widget> rows = [];
    int i = 0;

    while (i < filters.length) {
      final filter = filters[i];
      bool needsFullWidth =
          filter.type == FilterType.mainCategory ||
          filter.type == FilterType.company;

      if (needsFullWidth) {
        // إضافة فلتر بعرض كامل
        rows.add(
          Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: _buildFullWidthFilterCard(context, filter, theme),
          ),
        );
        i++;
      } else {
        // التحقق من وجود فلتر آخر يمكن دمجه
        if (i + 1 < filters.length) {
          final nextFilter = filters[i + 1];
          bool nextNeedsFullWidth =
              nextFilter.type == FilterType.mainCategory ||
              nextFilter.type == FilterType.company;

          if (!nextNeedsFullWidth) {
            // دمج فلترين جنباً إلى جنب
            rows.add(
              Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildHalfWidthFilterCard(context, filter, theme),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: _buildHalfWidthFilterCard(
                        context,
                        nextFilter,
                        theme,
                      ),
                    ),
                  ],
                ),
              ),
            );
            i += 2; // تخطي الفلترين
          } else {
            // عرض فلتر واحد فقط
            rows.add(
              Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildHalfWidthFilterCard(context, filter, theme),
                    ),
                    Expanded(child: Container()), // مساحة فارغة
                  ],
                ),
              ),
            );
            i++;
          }
        } else {
          // آخر عنصر
          rows.add(
            Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: Row(
                children: [
                  Expanded(
                    child: _buildHalfWidthFilterCard(context, filter, theme),
                  ),
                  Expanded(child: Container()), // مساحة فارغة
                ],
              ),
            ),
          );
          i++;
        }
      }
    }

    return Column(children: rows);
  }

  /// بناء بطاقة الفلتر بالعرض الكامل (للأقسام الرئيسية والشركات)
  Widget _buildFullWidthFilterCard(
    BuildContext context,
    FilterItemModel filter,
    ThemeData theme,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _navigateToFilteredProducts(filter),
        borderRadius: BorderRadius.circular(20.r),
        child: SizedBox(
          height: 120.h,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // الصورة تملأ كامل البطاقة
              _buildFilterImage(filter),

              // طبقة تدرج لتحسين وضوح النص
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                    ],
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                  ),
                ),
              ),

              // اسم الفلتر مع أنيميشن جميل على الجهة اليمنى
              Positioned(
                right: 20.w,
                top: 0,
                bottom: 0,
                child: SizedBox(
                  width: 250.w,
                  child: Center(
                    child: TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 800),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset((1 - value) * 30, 0),
                          child: Opacity(
                            opacity: value,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20.w,
                                vertical: 12.h,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.95),
                                    Colors.white.withOpacity(0.85),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(25.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 15.r,
                                    offset: Offset(0, 5.h),
                                  ),
                                ],
                                border: Border.all(
                                  color: filter.type.color.withOpacity(0.4),
                                  width: 2.w,
                                ),
                              ),
                              child: Text(
                                filter.title,
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  letterSpacing: 0.5,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // عدد المنتجات على الجهة اليسرى السفلى
              if (filter.productCount != null && filter.productCount! > 0)
                Positioned(
                  left: 16.w,
                  bottom: 16.h,
                  child: TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 600),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                filter.type.color,
                                filter.type.color.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20.r),
                            boxShadow: [
                              BoxShadow(
                                color: filter.type.color.withOpacity(0.4),
                                blurRadius: 8.r,
                                offset: Offset(0, 3.h),
                              ),
                            ],
                          ),
                          child: Text(
                            '${filter.productCount}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// بناء بطاقة الفلتر بالعرض النصفي (للأقسام الفرعية والمنتجات)
  Widget _buildHalfWidthFilterCard(
    BuildContext context,
    FilterItemModel filter,
    ThemeData theme,
  ) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _navigateToFilteredProducts(filter),
        borderRadius: BorderRadius.circular(16.r),
        child: SizedBox(
          height: 160.h,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // الصورة تملأ كامل البطاقة
              _buildFilterImage(filter),

              // طبقة تدرج لتحسين وضوح النص
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.7),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              // اسم الفلتر في وسط الصورة مع أنيميشن جميل
              Center(
                child: TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 1000),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.8 + (value * 0.2),
                      child: Opacity(
                        opacity: value,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.95),
                                Colors.white.withOpacity(0.88),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20.r),
                            boxShadow: [
                              BoxShadow(
                                color: filter.type.color.withOpacity(0.3),
                                blurRadius: 12.r,
                                offset: Offset(0, 4.h),
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 6.r,
                                offset: Offset(0, 2.h),
                              ),
                            ],
                            border: Border.all(
                              color: filter.type.color.withOpacity(0.5),
                              width: 2.w,
                            ),
                          ),
                          child: Text(
                            filter.title,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // عدد المنتجات على الجهة اليسرى السفلى
              if (filter.productCount != null && filter.productCount! > 0)
                Positioned(
                  left: 8.w,
                  bottom: 8.h,
                  child: TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 800),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, (1 - value) * 20),
                        child: Opacity(
                          opacity: value,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  filter.type.color,
                                  filter.type.color.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(15.r),
                              boxShadow: [
                                BoxShadow(
                                  color: filter.type.color.withOpacity(0.4),
                                  blurRadius: 6.r,
                                  offset: Offset(0, 2.h),
                                ),
                              ],
                            ),
                            child: Text(
                              '${filter.productCount}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// بناء صورة الفلتر
  Widget _buildFilterImage(FilterItemModel filter) {
    return filter.imageUrl != null && filter.imageUrl!.isNotEmpty
        ? CachedNetworkImage(
          imageUrl: filter.imageUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildImagePlaceholder(filter),
          errorWidget: (context, url, error) => _buildImagePlaceholder(filter),
        )
        : _buildImagePlaceholder(filter);
  }

  /// بناء placeholder للصورة
  Widget _buildImagePlaceholder(FilterItemModel filter) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            filter.type.color.withOpacity(0.2),
            filter.type.color.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          filter.type.icon,
          size: 40.sp,
          color: filter.type.color.withOpacity(0.6),
        ),
      ),
    );
  }

  /// الانتقال إلى صفحة المنتجات المفلترة
  void _navigateToFilteredProducts(FilterItemModel filter) {
    Get.to(
      () => FilteredProductsScreen(
        filterKey: filter.filterKey,
        filterTitle: filter.title,
        filterSubtitle: filter.subtitle,
        filterType: filter.type,
      ),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 300),
    );
  }

  /// بناء شبكة التحميل
  Widget _buildLoadingGrid(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 7.w),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          children: [
            // فلتر بعرض كامل
            Container(
              height: 120.h,
              margin: EdgeInsets.only(bottom: 10.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
              ),
            ),
            // صف من فلترين نصفيين
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 160.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Container(
                    height: 160.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            // فلتر بعرض كامل آخر
            Container(
              height: 120.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء حالة فارغة
  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_alt_off_outlined,
              size: 60.sp,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16.h),
            Text(
              'لا توجد فلاتر متاحة',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'تأكد من وجود أقسام وشركات مفعلة',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed:
                  () => Get.find<FiltersDisplayController>().refreshFilters(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
