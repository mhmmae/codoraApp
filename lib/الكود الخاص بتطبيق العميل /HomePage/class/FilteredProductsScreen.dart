import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../controllers/filters_display_controller.dart';
import 'ProductGridWidget.dart';
import '../../../XXX/xxx_firebase.dart';

/// صفحة عرض المنتجات المفلترة حسب الفلتر المحدد
class FilteredProductsScreen extends StatelessWidget {
  final String filterKey;
  final String filterTitle;
  final String filterSubtitle;
  final FilterType filterType;

  const FilteredProductsScreen({
    super.key,
    required this.filterKey,
    required this.filterTitle,
    required this.filterSubtitle,
    required this.filterType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              filterTitle,
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            Text(
              filterSubtitle,
              style: TextStyle(
                fontSize: 12.sp,
                color: theme.appBarTheme.foregroundColor?.withOpacity(0.7),
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
        actions: [
          // مؤشر نوع الفلتر
          Container(
            margin: EdgeInsets.only(right: 16.w, top: 8.h, bottom: 8.h),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: filterType.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: filterType.color.withOpacity(0.3),
                width: 1.w,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(filterType.icon, color: filterType.color, size: 16.sp),
                SizedBox(width: 6.w),
                Text(
                  filterType.displayName,
                  style: TextStyle(
                    color: filterType.color,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // يمكن إضافة منطق إعادة التحميل هنا
          await Future.delayed(const Duration(seconds: 1));
        },
        child: ListView(
          children: [
            // معلومات الفلتر
            Container(
              margin: EdgeInsets.all(16.w),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: filterType.color.withOpacity(0.2),
                  width: 1.w,
                ),
                boxShadow: [
                  BoxShadow(
                    color: filterType.color.withOpacity(0.1),
                    blurRadius: 10.r,
                    offset: Offset(0, 4.h),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48.w,
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: filterType.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      filterType.icon,
                      color: filterType.color,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'عرض منتجات: $filterTitle',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.titleMedium?.color,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'الفئة: $filterSubtitle',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: theme.textTheme.bodySmall?.color
                                ?.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 8.h),

            // ويدجت المنتجات مع الفلتر المحدد
            ProductGridWidgetOption(
              selectedSubtypeKey: _convertFilterKeyForProductGrid(),
            ),

            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  /// تحويل مفتاح الفلتر لتناسب ProductGridWidget
  String _convertFilterKeyForProductGrid() {
    // إرجاع نفس مفتاح الفلتر، حيث أن ProductGridWidget يدعم بالفعل:
    // - sub_categoryId للأقسام الفرعية
    // - original_company_companyId للشركات
    // - original_product_productId للمنتجات
    return filterKey;
  }
}
