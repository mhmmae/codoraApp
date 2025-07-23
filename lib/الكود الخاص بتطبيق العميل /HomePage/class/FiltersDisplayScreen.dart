import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../controllers/filters_display_controller.dart';
import 'FilteredProductsScreen.dart';

/// صفحة عرض جميع الفلاتر المتاحة بشكل مسطح
class FiltersDisplayScreen extends StatelessWidget {
  const FiltersDisplayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FiltersDisplayController());
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('جميع الفلاتر'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
        actions: [
          // زر إعادة التحميل
          IconButton(
            onPressed: () => controller.refreshFilters(),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'إعادة تحميل',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return _buildLoadingGrid(context);
        }

        if (controller.allFilters.isEmpty) {
          return _buildEmptyState(context, theme);
        }

        return RefreshIndicator(
          onRefresh: () => controller.refreshFilters(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // عداد الفلاتر
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  margin: EdgeInsets.only(bottom: 16.h),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: theme.primaryColor.withOpacity(0.2),
                      width: 1.w,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        color: theme.primaryColor,
                        size: 24.sp,
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'إجمالي الفلاتر المتاحة: ${controller.allFilters.length}',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // شبكة الفلاتر
                Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 12.w,
                      mainAxisSpacing: 12.h,
                    ),
                    itemCount: controller.allFilters.length,
                    itemBuilder: (context, index) {
                      final filter = controller.allFilters[index];
                      return _buildFilterCard(context, filter, theme);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  /// بناء بطاقة الفلتر
  Widget _buildFilterCard(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // منطقة الصورة
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // الصورة
                  _buildFilterImage(filter),

                  // شريط نوع الفلتر
                  Positioned(
                    top: 8.h,
                    right: 8.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: filter.type.color.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4.r,
                            offset: Offset(0, 2.h),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            filter.type.icon,
                            color: Colors.white,
                            size: 14.sp,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            filter.type.displayName,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // منطقة النص
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // العنوان الرئيسي
                    Text(
                      filter.title,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.titleMedium?.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),

                    // العنوان الفرعي
                    Text(
                      filter.subtitle,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: theme.textTheme.bodySmall?.color?.withOpacity(
                          0.7,
                        ),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // اسم الوالد إن وجد
                    if (filter.parentName != null) ...[
                      SizedBox(height: 2.h),
                      Text(
                        filter.parentName!,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: filter.type.color,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
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
          size: 48.sp,
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
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        children: [
          // placeholder للعداد
          Container(
            height: 48.h,
            margin: EdgeInsets.only(bottom: 16.h),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),

          // شبكة placeholder
          Expanded(
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 12.w,
                  mainAxisSpacing: 12.h,
                ),
                itemCount: 8,
                itemBuilder: (context, index) => _buildLoadingCard(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// بناء بطاقة تحميل
  Widget _buildLoadingCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 16.h, color: Colors.white),
                  SizedBox(height: 8.h),
                  Container(height: 12.h, width: 100.w, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
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
              size: 80.sp,
              color: Colors.grey[400],
            ),
            SizedBox(height: 24.h),
            Text(
              'لا توجد فلاتر متاحة',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'تأكد من وجود أقسام وشركات مفعلة في النظام',
              style: TextStyle(fontSize: 16.sp, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            ElevatedButton.icon(
              onPressed:
                  () => Get.find<FiltersDisplayController>().refreshFilters(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
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
