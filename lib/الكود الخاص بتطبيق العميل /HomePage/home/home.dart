import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../XXX/xxx_firebase.dart';
import '../controllers/enhanced_category_filter_controller.dart';
import '../widgets/simple_main_categories_widget.dart';
import '../controllers/brand_filter_controller.dart';
import '../controllers/barcode_filter_controller.dart';
import '../widgets/brand_filter_widget.dart';
import '../class/FiltersGridWidget.dart';
import '../controllers/filters_view_controller.dart';

import '../Get-Controllar/GetSerchController.dart';
import '../class/FavoritesScreen.dart';
import '../class/OffersCarouselWidget.dart';
import '../class/ProductGridWidget.dart';
import '../class/SearchResultsListWidget.dart';
// النظام المبسط تم حذفه واستبداله بالنظام المحسن

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // الحصول على المتحكمات (تفترض أنه تم حقنها مسبقًا)
    final GetSearchController searchCtrl = Get.find<GetSearchController>();

    // محاولة استخدام النظام الجديد، وفي حالة عدم وجوده، استخدم النظام المبسط
    try {
      Get.find<EnhancedCategoryFilterController>();
    } catch (e) {
      debugPrint("النظام الجديد غير متاح، سيتم استخدام النظام المبسط");
      Get.put(EnhancedCategoryFilterController());
    }

    final BrandFilterController brandCtrl = Get.put(BrandFilterController());
    final BarcodeFilterController barcodeCtrl = Get.put(
      BarcodeFilterController(),
    );

    // إنشاء controller منفصل لإدارة عرض الفلاتر
    final FiltersViewController filtersViewController = Get.put(
      FiltersViewController(),
    );

    // إضافة متحكم للفلاتر مع حالة الإظهار/الإخفاء
    final RxBool showFilters = false.obs;
    // إضافة متحكم منفصل لفلاتر الأقسام الرئيسية والفرعية
    final RxBool showCategoryFilters = false.obs;
    // متحكم انيميشن الإيقونات الاحترافي
    final RxBool isMenuExpanded = false.obs;

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Obx(
          () => AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -1),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.elasticOut),
                ),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: Text(
              isMenuExpanded.value ? "" : "الصفحة الرئيسية",
              key: ValueKey<bool>(isMenuExpanded.value),
              style: TextStyle(
                color: theme.textTheme.titleLarge?.color,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        backgroundColor:
            theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        elevation: theme.appBarTheme.elevation ?? 0,
        foregroundColor:
            theme.appBarTheme.foregroundColor ?? theme.colorScheme.primary,
        leading:
        // إيقونة عرض جميع الفلاتر (خارج نظام الإيقونات الرئيسي)
        Obx(
          () => Tooltip(
            message:
                filtersViewController.showFiltersGrid.value
                    ? 'إخفاء الفلاتر وعرض المنتجات'
                    : 'عرض جميع الفلاتر المتاحة',
            preferBelow: true,
            child: Container(
              margin: EdgeInsets.all(8.w),
              child: Material(
                elevation: filtersViewController.showFiltersGrid.value ? 5 : 3,
                borderRadius: BorderRadius.circular(12.r),
                shadowColor: theme.primaryColor.withOpacity(0.3),
                child: InkWell(
                  onTap: () {
                    filtersViewController.toggleFiltersView();
                  },
                  borderRadius: BorderRadius.circular(12.r),
                  splashColor: theme.primaryColor.withOpacity(0.1),
                  highlightColor: theme.primaryColor.withOpacity(0.05),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      gradient: LinearGradient(
                        colors:
                            filtersViewController.showFiltersGrid.value
                                ? [
                                  theme.primaryColor.withOpacity(0.2),
                                  theme.primaryColor.withOpacity(0.1),
                                ]
                                : [
                                  theme.primaryColor.withOpacity(0.1),
                                  theme.primaryColor.withOpacity(0.05),
                                ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color:
                            filtersViewController.showFiltersGrid.value
                                ? theme.primaryColor.withOpacity(0.4)
                                : theme.primaryColor.withOpacity(0.2),
                        width: 1.w,
                      ),
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Icon(
                          filtersViewController.showFiltersGrid.value
                              ? Icons.grid_off_rounded
                              : Icons.grid_view_rounded,
                          key: ValueKey(
                            filtersViewController.showFiltersGrid.value,
                          ),
                          color: theme.primaryColor,
                          size: 22.sp,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        actions: [
          // نظام الإيقونات الاحترافي الجديد
          _buildAdvancedIconSystem(
            context,
            theme,
            isMenuExpanded,
            showCategoryFilters,
            showFilters,
            searchCtrl,
            brandCtrl,
            barcodeCtrl,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          debugPrint("Refreshing...");
          await Future.delayed(Duration(seconds: 1));
        },
        child: ListView(
          children: [
            SizedBox(height: 12.h), // استخدام ScreenUtil بدلاً من hi / 70
            // عروض - مرر الـ pageController من searchController
            StreamBuilder(
              stream:
                  FirebaseFirestore.instance
                      .collection(FirebaseX.offersCollection)
                      .where('appName', isEqualTo: FirebaseX.appName)
                      .limit(10)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // يمكنك إرجاع شيمر أو لا شيء حسب رغبتك
                  return SizedBox.shrink();
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  // لا يوجد عروض: لا ترجع أي ويدجت (لا تأخذ أي مساحة)
                  return SizedBox.shrink();
                }
                // يوجد عروض: أظهر ويدجت العروض مع Divider
                return Column(
                  children: [
                    OffersCarouselWidget(),
                    SizedBox(height: 12.h), // استخدام ScreenUtil
                    const Divider(),
                  ],
                );
              },
            ),

            // فلاتر الأقسام الرئيسية والفرعية مع انيميشن احترافي
            Obx(
              () => AnimatedSize(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOutCubic,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  height: showCategoryFilters.value ? null : 0,
                  child:
                      showCategoryFilters.value
                          ? AnimatedOpacity(
                            duration: const Duration(milliseconds: 700),
                            opacity: showCategoryFilters.value ? 1.0 : 0.0,
                            child: TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 800),
                              tween: Tween<double>(
                                begin: 0.0,
                                end: showCategoryFilters.value ? 1.0 : 0.0,
                              ),
                              curve: Curves.elasticOut,
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: 0.8 + (0.2 * value),
                                  child: Transform.translate(
                                    offset: Offset(0, 20 * (1 - value)),
                                    child: Container(
                                      margin: EdgeInsets.symmetric(
                                        horizontal: 16.w,
                                        vertical: 8.h,
                                      ),
                                      padding: EdgeInsets.all(20.w),
                                      decoration: BoxDecoration(
                                        color: theme.cardColor,
                                        borderRadius: BorderRadius.circular(
                                          24.r,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: theme.primaryColor
                                                .withValues(alpha: 0.15),
                                            blurRadius: 25.r,
                                            offset: Offset(0, 15.h),
                                            spreadRadius: 3.r,
                                          ),
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.08,
                                            ),
                                            blurRadius: 15.r,
                                            offset: Offset(0, 8.h),
                                          ),
                                        ],
                                        border: Border.all(
                                          color: theme.primaryColor.withValues(
                                            alpha: 0.1,
                                          ),
                                          width: 1.5.w,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          // عنوان فلاتر الأقسام مع رسوم متحركة
                                          Row(
                                            children: [
                                              AnimatedContainer(
                                                duration: const Duration(
                                                  milliseconds: 600,
                                                ),
                                                width: 45.w,
                                                height: 45.h,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      theme.primaryColor,
                                                      theme.primaryColor
                                                          .withValues(
                                                            alpha: 0.7,
                                                          ),
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        15.r,
                                                      ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: theme.primaryColor
                                                          .withValues(
                                                            alpha: 0.3,
                                                          ),
                                                      blurRadius: 12.r,
                                                      offset: Offset(0, 6.h),
                                                    ),
                                                  ],
                                                ),
                                                child: Icon(
                                                  Icons.category_rounded,
                                                  color: Colors.white,
                                                  size: 26.sp,
                                                ),
                                              ),
                                              SizedBox(width: 15.w),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'فلاتر الأقسام',
                                                      style: TextStyle(
                                                        fontSize: 20.sp,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            theme.primaryColor,
                                                      ),
                                                    ),
                                                    SizedBox(height: 2.h),
                                                    Text(
                                                      'اختر القسم الرئيسي والفرعي',
                                                      style: TextStyle(
                                                        fontSize: 14.sp,
                                                        color: Colors.grey[600],
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // زر الإغلاق مع انيميشن
                                              InkWell(
                                                onTap:
                                                    () =>
                                                        showCategoryFilters
                                                            .value = false,
                                                borderRadius:
                                                    BorderRadius.circular(25.r),
                                                child: AnimatedContainer(
                                                  duration: const Duration(
                                                    milliseconds: 300,
                                                  ),
                                                  padding: EdgeInsets.all(12.w),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[100],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          25.r,
                                                        ),
                                                  ),
                                                  child: AnimatedRotation(
                                                    duration: const Duration(
                                                      milliseconds: 300,
                                                    ),
                                                    turns: 0.5,
                                                    child: Icon(
                                                      Icons.keyboard_arrow_up,
                                                      color: theme.primaryColor,
                                                      size: 24.sp,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),

                                          SizedBox(height: 20.h),

                                          // محتوى فلاتر الأقسام
                                          const SimpleMainCategoriesWidget(),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                          : const SizedBox.shrink(),
                ),
              ),
            ),

            // Divider انيميتد يظهر ويختفي مع فلاتر الأقسام
            Obx(
              () => AnimatedSize(
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeInOutCubic,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  height: showCategoryFilters.value ? null : 0,
                  child:
                      showCategoryFilters.value
                          ? AnimatedOpacity(
                            duration: const Duration(milliseconds: 800),
                            opacity: showCategoryFilters.value ? 1.0 : 0.0,
                            child: TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 900),
                              tween: Tween<double>(
                                begin: 0.0,
                                end: showCategoryFilters.value ? 1.0 : 0.0,
                              ),
                              curve: Curves.easeOutBack,
                              builder: (context, value, child) {
                                return Container(
                                  margin: EdgeInsets.symmetric(
                                    vertical: 12.h * value,
                                    horizontal: 20 * value,
                                  ),
                                  child: AnimatedContainer(
                                    duration: const Duration(
                                      milliseconds: 1000,
                                    ),
                                    width: (double.infinity) * value,
                                    child: Container(
                                      height: 2.h,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          2.r,
                                        ),
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.transparent,
                                            theme.primaryColor.withValues(
                                              alpha: 0.2 * value,
                                            ),
                                            theme.primaryColor.withValues(
                                              alpha: 0.8 * value,
                                            ),
                                            theme.primaryColor.withValues(
                                              alpha: 0.2 * value,
                                            ),
                                            Colors.transparent,
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: theme.primaryColor
                                                .withValues(alpha: 0.3 * value),
                                            blurRadius: 8.r * value,
                                            offset: Offset(0, 2.h * value),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                          : const SizedBox.shrink(),
                ),
              ),
            ),

            // الفلاتر المخفية/المظهرة مع انيميشن احترافي
            Obx(
              () => AnimatedSize(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOutCubic,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  height: showFilters.value ? null : 0,
                  child:
                      showFilters.value
                          ? AnimatedOpacity(
                            duration: const Duration(milliseconds: 600),
                            opacity: showFilters.value ? 1.0 : 0.0,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, -0.3),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: AlwaysStoppedAnimation(1.0),
                                  curve: Curves.easeOutBack,
                                ),
                              ),
                              child: Container(
                                margin: EdgeInsets.symmetric(horizontal: 16.w),
                                padding: EdgeInsets.all(16.w),
                                decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  borderRadius: BorderRadius.circular(20.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.primaryColor.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 20.r,
                                      offset: Offset(0, 10.h),
                                      spreadRadius: 2.r,
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 10.r,
                                      offset: Offset(0, 5.h),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    // عنوان القسم مع رسوم متحركة
                                    Row(
                                      children: [
                                        AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 400,
                                          ),
                                          width: 40.w,
                                          height: 40.h,
                                          decoration: BoxDecoration(
                                            color: theme.primaryColor
                                                .withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              12.r,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.filter_alt,
                                            color: theme.primaryColor,
                                            size: 24.sp,
                                          ),
                                        ),
                                        SizedBox(width: 12.w),
                                        Text(
                                          'فلاتر البحث المتقدمة',
                                          style: TextStyle(
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.bold,
                                            color: theme.primaryColor,
                                          ),
                                        ),
                                        const Spacer(),
                                        // زر الإغلاق
                                        InkWell(
                                          onTap:
                                              () => showFilters.value = false,
                                          borderRadius: BorderRadius.circular(
                                            20.r,
                                          ),
                                          child: Container(
                                            padding: EdgeInsets.all(8.w),
                                            child: Icon(
                                              Icons.keyboard_arrow_up,
                                              color: theme.primaryColor,
                                              size: 24.sp,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    SizedBox(height: 16.h),

                                    // محتوى الفلاتر
                                    const BrandFilterWidget(),
                                  ],
                                ),
                              ),
                            ),
                          )
                          : const SizedBox.shrink(),
                ),
              ),
            ),

            // Divider انيميتد يظهر ويختفي مع الفلاتر
            Obx(
              () => AnimatedSize(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOutCubic,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  height: showFilters.value ? null : 0,
                  child:
                      showFilters.value
                          ? AnimatedOpacity(
                            duration: const Duration(milliseconds: 700),
                            opacity: showFilters.value ? 1.0 : 0.0,
                            child: Container(
                              margin: EdgeInsets.symmetric(vertical: 8.h),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 800),
                                width: showFilters.value ? double.infinity : 0,
                                child: Container(
                                  height: 1.h,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        theme.primaryColor.withValues(
                                          alpha: 0.3,
                                        ),
                                        theme.primaryColor.withValues(
                                          alpha: 0.6,
                                        ),
                                        theme.primaryColor.withValues(
                                          alpha: 0.3,
                                        ),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                          : const SizedBox.shrink(),
                ),
              ),
            ),

            // ويدجت البحث من خلال البراند والباركود
            // تم نقلها للأعلى في الفلاتر المخفية
            SizedBox(height: 12.h), // استخدام ScreenUtil
            // شبكة المنتجات أو الفلاتر مع الفلترة المحسنة
            Obx(() {
              debugPrint(
                '🔴 Obx rebuild - showFiltersGrid: ${filtersViewController.showFiltersGrid.value}',
              );

              // إذا كان عرض الفلاتر مفعل، أظهر الفلاتر بدلاً من المنتجات
              if (filtersViewController.showFiltersGrid.value) {
                debugPrint('🔴 شرط الفلاتر صحيح - سيتم عرض FiltersGridWidget');
                debugPrint(
                  '🔴 🚨 CRITICAL: About to return FiltersGridWidget()',
                );
                final widget = FiltersGridWidget();
                debugPrint(
                  '🔴 🚨 CRITICAL: FiltersGridWidget created successfully',
                );
                return widget;
              }

              debugPrint('🔴 شرط الفلاتر خطأ - سيتم عرض المنتجات العادية');

              // عرض المنتجات العادي
              String filterKey = 'all_items'; // القيمة الافتراضية

              if (barcodeCtrl.hasActiveFilter) {
                filterKey = barcodeCtrl.getFilterKey();
              } else if (brandCtrl.isBrandModeActive.value) {
                filterKey = brandCtrl.getFilterKey();
              } else {
                // محاولة استخدام النظام الجديد أولاً
                try {
                  final filterCtrl =
                      Get.find<EnhancedCategoryFilterController>();
                  filterKey = filterCtrl.getFilterKey();
                } catch (e) {
                  // إذا فشل، استخدم النظام المبسط
                  try {
                    final categoryFilterCtrl =
                        Get.find<EnhancedCategoryFilterController>();
                    filterKey = categoryFilterCtrl.getFilterKey();
                  } catch (e2) {
                    // إبقاء القيمة الافتراضية
                  }
                }
              }

              final selectedSort = searchCtrl.currentSortOption.value;

              debugPrint(
                "Rebuilding Product Grid: Filter='$filterKey', Sort='${selectedSort.label}'",
              );
              debugPrint(
                "Brand Mode Active: ${brandCtrl.isBrandModeActive.value}",
              );
              debugPrint(
                "Barcode Search Active: ${barcodeCtrl.hasActiveFilter}",
              );

              return ProductGridWidgetOption(selectedSubtypeKey: filterKey);
            }),

            SizedBox(
              height: 20.h,
            ), // استخدام ScreenUtil بدلاً من القيمة الثابتة
          ],
        ),
      ),
    );
  }

  /// نظام الإيقونات الاحترافي مع انيميشن الأفعى
  Widget _buildAdvancedIconSystem(
    BuildContext context,
    ThemeData theme,
    RxBool isMenuExpanded,
    RxBool showCategoryFilters,
    RxBool showFilters,
    GetSearchController searchCtrl,
    BrandFilterController brandCtrl,
    BarcodeFilterController barcodeCtrl,
  ) {
    return Obx(
      () => AnimatedContainer(
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
        width:
            isMenuExpanded.value
                ? 320.w
                : 85.w, // زيادة العرض لاستيعاب جميع الإيقونات
        height: 50.h,
        margin: EdgeInsets.only(right: 8.w),
        child: Stack(
          children: [
            // الخلفية المتحركة المحسنة
            AnimatedPositioned(
              duration: const Duration(milliseconds: 850),
              curve: Curves.easeOutBack,
              right: 0,
              top: 0,
              bottom: 0,
              width:
                  isMenuExpanded.value
                      ? 320.w
                      : 75.w, // زيادة عرض الخلفية أيضاً
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25.r),
                  gradient: LinearGradient(
                    colors:
                        isMenuExpanded.value
                            ? [
                              theme.primaryColor.withValues(alpha: 0.08),
                              theme.primaryColor.withValues(alpha: 0.15),
                              theme.primaryColor.withValues(alpha: 0.22),
                              theme.primaryColor.withValues(alpha: 0.15),
                              theme.primaryColor.withValues(alpha: 0.08),
                            ]
                            : [
                              Colors.transparent,
                              Colors.transparent,
                              Colors.transparent,
                              Colors.transparent,
                              Colors.transparent,
                            ],
                    stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                  ),
                  border:
                      isMenuExpanded.value
                          ? Border.all(
                            color: theme.primaryColor.withValues(alpha: 0.2),
                            width: 1.w,
                          )
                          : null,
                  boxShadow:
                      isMenuExpanded.value
                          ? [
                            BoxShadow(
                              color: theme.primaryColor.withValues(alpha: 0.2),
                              blurRadius: 20.r,
                              offset: Offset(0, 8.h),
                              spreadRadius: 2.r,
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10.r,
                              offset: Offset(0, 4.h),
                            ),
                          ]
                          : [],
                ),
              ),
            ),

            // الإيقونات مع انيميشن الأفعى المحسن
            AnimatedPositioned(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOutBack,
              right: isMenuExpanded.value ? 15.w : 8.w, // تحسين الموضع
              top: 6.h,
              bottom: 6.h,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // إيقونة البحث
                  _buildSnakeIcon(
                    icon: Icons.search_rounded,
                    index: 0,
                    isExpanded: isMenuExpanded.value,
                    theme: theme,
                    onTap: () {
                      Get.to(
                        () => SearchScreen(),
                        transition: Transition.downToUp,
                      );
                    },
                    tooltip: 'البحث',
                  ),

                  // إيقونة فلاتر الأقسام
                  _buildSnakeIcon(
                    icon: Icons.category_rounded,
                    index: 1,
                    isExpanded: isMenuExpanded.value,
                    theme: theme,
                    isActive: showCategoryFilters.value,
                    onTap: () {
                      if (showCategoryFilters.value) {
                        try {
                          final EnhancedCategoryFilterController categoryCtrl =
                              Get.find<EnhancedCategoryFilterController>();
                          categoryCtrl.resetFilters();
                        } catch (e) {
                          debugPrint("تعذر العثور على متحكم فلاتر الأقسام");
                        }
                      }
                      showCategoryFilters.value = !showCategoryFilters.value;
                    },
                    tooltip: 'فلاتر الأقسام',
                  ),

                  // إيقونة الفلاتر المتقدمة
                  _buildSnakeIcon(
                    icon: Icons.tune_rounded,
                    index: 2,
                    isExpanded: isMenuExpanded.value,
                    theme: theme,
                    isActive: showFilters.value,
                    onTap: () {
                      if (showFilters.value) {
                        barcodeCtrl.clearAllNotifications();
                        if (brandCtrl.isBrandModeActive.value) {
                          brandCtrl.deactivateBrandMode();
                        }
                        if (barcodeCtrl.isBarcodeSearchActive.value) {
                          barcodeCtrl.deactivateBarcodeSearch();
                        }
                        if (barcodeCtrl.isScanning.value) {
                          barcodeCtrl.stopCameraScanning();
                        }
                        barcodeCtrl.clearCurrentBarcode();
                        brandCtrl.clearAllSelections();
                      }
                      showFilters.value = !showFilters.value;
                    },
                    tooltip: 'فلاتر البحث المتقدمة',
                  ),

                  // إيقونة المفضلة
                  _buildSnakeIcon(
                    icon: Icons.favorite_rounded,
                    index: 3,
                    isExpanded: isMenuExpanded.value,
                    theme: theme,
                    onTap: () {
                      Get.to(() => FavoritesScreen());
                    },
                    tooltip: 'المفضلة',
                  ),

                  // إيقونة الترتيب
                  _buildSnakeIcon(
                    icon: Icons.sort_rounded,
                    index: 4,
                    isExpanded: isMenuExpanded.value,
                    theme: theme,
                    onTap: () {
                      _showSortMenu(context, searchCtrl, theme);
                    },
                    tooltip: 'ترتيب حسب',
                  ),

                  // مسافة إضافية قبل الإيقونة الرئيسية
                  SizedBox(width: 10.w), // زيادة المسافة قليلاً
                  // الإيقونة الرئيسية (رأس الأفعى)
                  _buildMainIcon(isMenuExpanded, theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء إيقونة من إيقونات الأفعى
  Widget _buildSnakeIcon({
    required IconData icon,
    required int index,
    required bool isExpanded,
    required ThemeData theme,
    required VoidCallback onTap,
    required String tooltip,
    bool isActive = false,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutBack,
      tween: Tween<double>(begin: 0.0, end: isExpanded ? 1.0 : 0.0),
      builder: (context, value, child) {
        // تأكد من أن القيم في النطاق الصحيح
        final clampedValue = value.clamp(0.0, 1.0);
        final scale = (0.3 + (0.7 * clampedValue)).clamp(0.0, 1.0);
        final opacity = clampedValue;

        return Transform.scale(
          scale: scale,
          child: Transform.translate(
            offset: Offset(-30.w * (1 - clampedValue), 0),
            child: Opacity(
              opacity: opacity,
              child: Container(
                width: 38.w, // تصغير الحجم
                height: 38.h,
                margin: EdgeInsets.only(
                  right: 6.w,
                ), // تقليل المسافة بين الإيقونات
                child: Tooltip(
                  message: tooltip,
                  preferBelow: false,
                  verticalOffset: 50.h,
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(10.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 6.r,
                        offset: Offset(0, 3.h),
                      ),
                    ],
                  ),
                  textStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    elevation: isActive ? 6 : 3,
                    borderRadius: BorderRadius.circular(19.r),
                    shadowColor: theme.primaryColor.withValues(alpha: 0.25),
                    child: InkWell(
                      onTap: isExpanded ? onTap : null,
                      borderRadius: BorderRadius.circular(19.r),
                      splashColor: theme.primaryColor.withValues(alpha: 0.15),
                      highlightColor: theme.primaryColor.withValues(
                        alpha: 0.08,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOutCubic,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(19.r),
                          gradient: LinearGradient(
                            colors:
                                isActive
                                    ? [
                                      theme.primaryColor.withValues(alpha: 0.2),
                                      theme.primaryColor.withValues(
                                        alpha: 0.12,
                                      ),
                                    ]
                                    : [
                                      Colors.white.withValues(alpha: 0.12),
                                      Colors.white.withValues(alpha: 0.06),
                                    ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color:
                                isActive
                                    ? theme.primaryColor.withValues(alpha: 0.6)
                                    : theme.primaryColor.withValues(alpha: 0.2),
                            width: isActive ? 2.w : 1.w,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  isActive
                                      ? theme.primaryColor.withValues(
                                        alpha: 0.25,
                                      )
                                      : theme.primaryColor.withValues(
                                        alpha: 0.1,
                                      ),
                              blurRadius: isActive ? 8.r : 5.r,
                              offset: Offset(0, isActive ? 4.h : 2.h),
                              spreadRadius: isActive ? 0.5.r : 0,
                            ),
                            // إضافة لمعان خفيف للتأثير الجمالي
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.03),
                              blurRadius: 1.r,
                              offset: Offset(0, -1.h),
                            ),
                          ],
                        ),
                        child: Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: EdgeInsets.all(isActive ? 10.w : 9.w),
                            child: Icon(
                              icon,
                              color:
                                  isActive
                                      ? theme.primaryColor
                                      : theme.appBarTheme.foregroundColor
                                          ?.withValues(alpha: 0.8),
                              size:
                                  isActive
                                      ? 18.sp
                                      : 16.sp, // تصغير حجم الإيقونة
                            ),
                          ),
                        ),
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

  /// بناء الإيقونة الرئيسية (رأس الأفعى)
  Widget _buildMainIcon(RxBool isMenuExpanded, ThemeData theme) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeOutBack,
      tween: Tween<double>(begin: 1.0, end: isMenuExpanded.value ? 1.2 : 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 42.w, // تصغير الحجم
            height: 42.h,
            margin: EdgeInsets.only(
              left: 5.w,
            ), // زيادة المسافة قليلاً لضمان الظهور الكامل
            child: Material(
              elevation: isMenuExpanded.value ? 10 : 5,
              borderRadius: BorderRadius.circular(21.r),
              shadowColor: theme.primaryColor.withValues(alpha: 0.3),
              child: InkWell(
                onTap: () {
                  isMenuExpanded.value = !isMenuExpanded.value;
                },
                borderRadius: BorderRadius.circular(21.r),
                splashColor: Colors.white.withValues(alpha: 0.25),
                highlightColor: Colors.white.withValues(alpha: 0.08),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeInOutCubic,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(21.r),
                    gradient: LinearGradient(
                      colors:
                          isMenuExpanded.value
                              ? [
                                theme.primaryColor,
                                theme.primaryColor.withValues(alpha: 0.8),
                                theme.primaryColor.withValues(alpha: 0.65),
                              ]
                              : [
                                theme.primaryColor.withValues(alpha: 0.1),
                                theme.primaryColor.withValues(alpha: 0.15),
                                theme.primaryColor.withValues(alpha: 0.2),
                              ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: const [0.0, 0.5, 1.0],
                    ),
                    border: Border.all(
                      color:
                          isMenuExpanded.value
                              ? Colors.white.withValues(alpha: 0.25)
                              : theme.primaryColor.withValues(alpha: 0.5),
                      width: isMenuExpanded.value ? 2.w : 1.5.w,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.primaryColor.withValues(
                          alpha: isMenuExpanded.value ? 0.3 : 0.15,
                        ),
                        blurRadius: isMenuExpanded.value ? 15.r : 8.r,
                        offset: Offset(0, isMenuExpanded.value ? 6.h : 4.h),
                        spreadRadius: isMenuExpanded.value ? 1.r : 0.5.r,
                      ),
                      // ظل إضافي للعمق
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6.r,
                        offset: Offset(0, 3.h),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // خلفية مضيئة للتأثير
                      if (isMenuExpanded.value)
                        Positioned.fill(
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 350),
                            opacity: isMenuExpanded.value ? 0.12 : 0.0,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(21.r),
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.white.withValues(alpha: 0.25),
                                    Colors.transparent,
                                  ],
                                  center: const Alignment(-0.3, -0.3),
                                ),
                              ),
                            ),
                          ),
                        ),

                      // الإيقونة الرئيسية
                      Center(
                        child: AnimatedRotation(
                          duration: const Duration(milliseconds: 500),
                          turns: isMenuExpanded.value ? 0.5 : 0,
                          child: TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 350),
                            tween: Tween<double>(
                              begin: 1.0,
                              end: isMenuExpanded.value ? 1.05 : 1.0,
                            ),
                            builder: (context, iconScale, child) {
                              return Transform.scale(
                                scale: iconScale,
                                child: Icon(
                                  isMenuExpanded.value
                                      ? Icons.close_rounded
                                      : Icons.apps_rounded,
                                  color:
                                      isMenuExpanded.value
                                          ? Colors.white
                                          : theme.primaryColor,
                                  size: 22.sp, // تصغير حجم الإيقونة
                                  shadows:
                                      isMenuExpanded.value
                                          ? [
                                            Shadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.25,
                                              ),
                                              offset: const Offset(0.5, 0.5),
                                              blurRadius: 1.5,
                                            ),
                                          ]
                                          : [],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// عرض قائمة الترتيب
  void _showSortMenu(
    BuildContext context,
    GetSearchController searchCtrl,
    ThemeData theme,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            margin: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(25.r),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withValues(alpha: 0.2),
                  blurRadius: 20.r,
                  offset: Offset(0, 10.h),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50.w,
                  height: 5.h,
                  margin: EdgeInsets.only(top: 10.h),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.5.r),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    children: [
                      Text(
                        'ترتيب حسب',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                      SizedBox(height: 15.h),
                      ...SortOption.values.map(
                        (option) => Obx(
                          () => Container(
                            margin: EdgeInsets.only(bottom: 8.h),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  searchCtrl.changeSortOption(option);
                                  Navigator.pop(context);
                                },
                                borderRadius: BorderRadius.circular(15.r),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 12.h,
                                    horizontal: 16.w,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15.r),
                                    color:
                                        searchCtrl.currentSortOption.value ==
                                                option
                                            ? theme.primaryColor.withValues(
                                              alpha: 0.1,
                                            )
                                            : Colors.transparent,
                                    border: Border.all(
                                      color:
                                          searchCtrl.currentSortOption.value ==
                                                  option
                                              ? theme.primaryColor
                                              : Colors.transparent,
                                      width: 2.w,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        searchCtrl.currentSortOption.value ==
                                                option
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_unchecked,
                                        color: theme.primaryColor,
                                        size: 20.sp,
                                      ),
                                      SizedBox(width: 12.w),
                                      Text(
                                        option.label,
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight:
                                              searchCtrl
                                                          .currentSortOption
                                                          .value ==
                                                      option
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                          color:
                                              theme.textTheme.bodyLarge?.color,
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
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

// --- شاشة البحث المنفصلة (مثال بسيط) ---
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // الحصول على نفس المتحكم الرئيسي أو إنشاء متحكم بحث خاص
    final GetSearchController searchController =
        Get.find<GetSearchController>();
    // أو إنشاء واحد جديد: Get.put(SearchScreenController());

    return Scaffold(
      appBar: AppBar(
        // --- حقل البحث في AppBar ---
        title: TextField(
          controller: searchController.searchFieldController, // ربط المتحكم
          autofocus: true, // فتح لوحة المفاتيح تلقائياً
          decoration: InputDecoration(
            hintText: "ابحث عن المنتجات...", // <<-- تعريب
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey[600]),
          ),
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: 18.sp,
          ),
          onChanged: (value) {
            // قيمة البحث تتحدث تلقائياً في RxString في المتحكم بفضل المستمع
            // searchController.searchQuery.value = value; // لا حاجة لهذا السطر إذا كان المستمع يعمل
          },
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),
      body: Obx(() {
        // مراقبة searchQuery
        // --- عرض النتائج باستخدام Widget البحث ---
        return SearchResultsListWidget(
          searchQuery: searchController.searchQuery.value,
        );
      }),
    );
  }
}
