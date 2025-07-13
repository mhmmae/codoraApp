import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // لاستخدام HapticFeedback
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart'; // لتنسيق الأرقام بالفواصل
import 'dart:math' as math;

import '../../../Model/SellerModel.dart';

import '../controllers/retail_cart_controller.dart';
import '../controllers/store_products_controller.dart';
import '../widgets/promotional_banner.dart';
import '../widgets/store_header.dart';
import '../widgets/morphing_filter_hub.dart';
import 'retail_cart_page.dart'; // إضافة import لصفحة السلة

/// مدير cache الصور المحسن
class ImageCacheManager {
  static final Map<String, Widget> _imageCache = {};

  static Widget getCachedImage(
    String imageUrl, {
    required double width,
    required double height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    // فحص القيم للتأكد من صحتها وتجنب Infinity أو NaN
    final double safeWidth = (width.isFinite && width > 0) ? width : 100.0;
    final double safeHeight = (height.isFinite && height > 0) ? height : 100.0;

    final cacheKey = '${imageUrl}_${safeWidth}_${safeHeight}';

    if (_imageCache.containsKey(cacheKey)) {
      return _imageCache[cacheKey]!;
    }

    // حساب أبعاد cache آمنة
    final int safeCacheWidth = (safeWidth * 2).clamp(50, 500).round();
    final int safeCacheHeight = (safeHeight * 2).clamp(50, 500).round();
    final int safeDiskWidth = (safeWidth * 3).clamp(100, 800).round();
    final int safeDiskHeight = (safeHeight * 3).clamp(100, 800).round();

    final widget = CachedNetworkImage(
      imageUrl: imageUrl,
      width: safeWidth,
      height: safeHeight,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 100),
      memCacheWidth: safeCacheWidth,
      memCacheHeight: safeCacheHeight,
      maxWidthDiskCache: safeDiskWidth,
      maxHeightDiskCache: safeDiskHeight,
      placeholder:
          (context, url) =>
              placeholder ??
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: safeWidth,
                  height: safeHeight,
                  color: Colors.white,
                ),
              ),
      errorWidget:
          (context, url, error) =>
              errorWidget ??
              Container(
                width: safeWidth,
                height: safeHeight,
                color: Colors.grey[200],
                child: Icon(
                  Icons.broken_image_outlined,
                  color: Colors.grey[400],
                  size: math.min(safeWidth, safeHeight) * 0.5,
                ),
              ),
    );

    _imageCache[cacheKey] = widget;
    return widget;
  }

  static void clearCache() {
    _imageCache.clear();
  }
}

class StoreProductsPage extends StatefulWidget {
  final EnhancedCategoryFilterController categoryFilterController = Get.put(
    EnhancedCategoryFilterController(),
  );
  StoreProductsPage({super.key});

  @override
  State<StoreProductsPage> createState() => _StoreProductsPageState();
}

class _StoreProductsPageState extends State<StoreProductsPage> {
  @override
  void initState() {
    super.initState();
    print('🔧 [INIT] بدء تهيئة صفحة المنتجات');

    // Ensure the main product controller always starts with 'الكل' (all)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('⏰ [INIT] تنفيذ addPostFrameCallback');

      if (Get.isRegistered<StoreProductsController>()) {
        final controller = Get.find<StoreProductsController>();
        controller.selectedCategory.value = 'الكل';
        print('📂 [INIT] تم تعيين التصنيف إلى "الكل"');

        // إعداد مراقب لتحديث فلاتر الأقسام عند تغيير المنتجات
        ever(controller.allProducts, (_) {
          // تحديث فلاتر الأقسام عند تغيير المنتجات
          if (mounted) {
            widget.categoryFilterController.clearProductCountCache();
            widget.categoryFilterController.update();
            debugPrint('🔄 تم تحديث فلاتر الأقسام بعد تغيير المنتجات');
          }
        });
      }

      // التأكد من تهيئة RetailCartController
      if (Get.isRegistered<RetailCartController>()) {
        final cartController = Get.find<RetailCartController>();
        print('🛒 [INIT] تم العثور على RetailCartController');
        print('📊 [INIT] إجمالي المتاجر: ${cartController.totalStoresCount}');
        debugPrint(
          '🛒 تم تهيئة RetailCartController - إجمالي المتاجر: ${cartController.totalStoresCount}',
        );
      } else {
        print('⚠️ [INIT] لم يتم العثور على RetailCartController');
      }
    });
  }

  bool showMorphingFilter = false;

  @override
  Widget build(BuildContext context) {
    print('🚀 [STORE-PAGE] بدء عرض صفحة منتجات المتجر');
    print('✅ [FILTERS-RESTORED] تم إعادة تفعيل جميع الفلاتر');

    final dynamic args = Get.arguments;
    final SellerModel store;

    if (args is SellerModel) {
      store = args;
    } else if (args is Map<String, dynamic> && args.containsKey('store')) {
      store = args['store'] as SellerModel;
    } else {
      Get.back();
      return const Scaffold(
        body: Center(child: Text('خطأ في تحميل بيانات المتجر')),
      );
    }

    return GetBuilder<StoreProductsController>(
      init: StoreProductsController(store: store),
      builder:
          (controller) => Stack(
            children: [
              Scaffold(
                backgroundColor: const Color(0xFFF8FAFC),
                body: SafeArea(
                  child: Row(
                    children: [
                      _buildSideFilterPanel(controller),
                      Expanded(
                        child: ListView(
                          children: [
                            StoreHeader(
                              store: store,
                              onFilterPressed: () {
                                setState(() => showMorphingFilter = true);
                              },
                            ),
                            if (!showMorphingFilter)
                              _buildCategoriesWidget(
                                widget.categoryFilterController,
                              ),
                            const PromotionalBanner(),
                            // تم إلغاء أزرار التبديل بين طرق العرض
                            _buildProductsList(controller),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                bottomNavigationBar: _buildBottomNavigationWidget(controller),
              ),
              if (showMorphingFilter)
                MorphingFilterHub(
                  controller: controller,
                  onClose: () => setState(() => showMorphingFilter = false),
                ),
            ],
          ),
    );
  }

  Widget _buildCategoriesWidget(EnhancedCategoryFilterController controller) {
    return GetBuilder<EnhancedCategoryFilterController>(
      builder:
          (controller) => Obx(() {
            if (controller.isLoading.value) {
              return _buildCategoriesShimmer();
            }

            // الحصول على الأقسام التي تحتوي على منتجات فقط
            final categoriesWithProducts =
                controller.getMainCategoriesWithProducts();

            if (categoriesWithProducts.isEmpty) {
              return const Center(
                child: Text('لا توجد أقسام رئيسية تحتوي على منتجات'),
              );
            }

            return Container(
              height: 90.h, // تقليل الارتفاع لجعل الفلاتر أصغر
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(), // إضافة فيزياء مرنة
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                itemCount:
                    categoriesWithProducts.length + 1, // +1 for 'All' category
                itemBuilder: (context, index) {
                  // 'All' category button
                  if (index == 0) {
                    return _buildAllCategoryItem(controller);
                  }

                  // Other categories (only those with products)
                  final category = categoriesWithProducts[index - 1];
                  return _buildCategoryItem(category, controller, index);
                },
              ),
            );
          }),
    );
  }

  /// بناء عنصر "الكل" مع تصميم جديد محسن
  Widget _buildAllCategoryItem(EnhancedCategoryFilterController controller) {
    return Obx(() {
      final isSelected = controller.selectedMainCategoryId.value.isEmpty;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: isSelected ? 85.w : 75.w, // تغيير العرض حسب الاختيار
        height: isSelected ? 85.h : 75.h, // تغيير الارتفاع حسب الاختيار
        margin: EdgeInsets.symmetric(horizontal: 6.w),
        child: GestureDetector(
          onTap: () => _selectCategory(controller, '', 'الكل'),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // الخلفية مع التدرج والحدود
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient:
                      isSelected
                          ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(context).primaryColor,
                              Theme.of(context).primaryColor.withOpacity(0.8),
                            ],
                          )
                          : LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.grey[100]!, Colors.grey[50]!],
                          ),
                  borderRadius: BorderRadius.circular(isSelected ? 20.r : 16.r),
                  border: Border.all(
                    color:
                        isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey[300]!,
                    width: isSelected ? 3.0 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          isSelected
                              ? Theme.of(context).primaryColor.withOpacity(0.4)
                              : Colors.grey.withOpacity(0.2),
                      spreadRadius: isSelected ? 3 : 1,
                      blurRadius: isSelected ? 15 : 8,
                      offset: Offset(0, isSelected ? 8 : 4),
                    ),
                  ],
                ),
              ),

              // الأيقونة الرئيسية
              Positioned(
                top: 8.h,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.all(isSelected ? 8.w : 6.w),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? Colors.white.withOpacity(0.2)
                            : Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.dashboard_rounded,
                    size: isSelected ? 24.sp : 20.sp,
                    color:
                        isSelected
                            ? Colors.white
                            : Theme.of(context).primaryColor,
                  ),
                ),
              ),

              // النص في الأسفل
              Positioned(
                bottom: 6.h,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: isSelected ? 12.sp : 10.sp,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.black87,
                    shadows:
                        isSelected
                            ? [
                              Shadow(
                                offset: const Offset(0, 1),
                                blurRadius: 2,
                                color: Colors.black.withOpacity(0.3),
                              ),
                            ]
                            : null,
                  ),
                  child: const Text('الكل'),
                ),
              ),

              // مؤشر الاختيار
              if (isSelected)
                Positioned(
                  top: 4.h,
                  right: 4.w,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 8.w,
                    height: 8.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  /// بناء عنصر القسم مع تصميم جديد محسن
  Widget _buildCategoryItem(
    CategoryModel category,
    EnhancedCategoryFilterController controller,
    int index,
  ) {
    return Obx(() {
      final isSelected = controller.selectedMainCategoryId.value == category.id;
      final productCount = controller.getProductCountForCategory(category.id);

      return AnimatedContainer(
        duration: Duration(milliseconds: 300 + (index * 50)), // تأثير متتالي
        curve: Curves.easeOutBack,
        width: isSelected ? 85.w : 75.w, // تغيير العرض حسب الاختيار
        height: isSelected ? 85.h : 75.h, // تغيير الارتفاع حسب الاختيار
        margin: EdgeInsets.symmetric(horizontal: 6.w),
        child: GestureDetector(
          onTap:
              () => _selectCategory(controller, category.id, category.nameAr),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // الصورة الخلفية تملأ كامل الـ widget
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(isSelected ? 20.r : 16.r),
                  border: Border.all(
                    color:
                        isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey[300]!,
                    width: isSelected ? 3.0 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          isSelected
                              ? Theme.of(context).primaryColor.withOpacity(0.4)
                              : Colors.grey.withOpacity(0.2),
                      spreadRadius: isSelected ? 3 : 1,
                      blurRadius: isSelected ? 15 : 8,
                      offset: Offset(0, isSelected ? 8 : 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(isSelected ? 18.r : 14.r),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // الصورة الأساسية
                      ImageCacheManager.getCachedImage(
                        category.imageUrl ?? '',
                        width:
                            isSelected
                                ? 85.w
                                : 75.w, // استخدام قيم محددة بدلاً من infinity
                        height:
                            isSelected
                                ? 85.h
                                : 75.h, // استخدام قيم محددة بدلاً من infinity
                        fit: BoxFit.cover,
                        placeholder: Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            color: Colors.white,
                            child: Icon(
                              Icons.category_outlined,
                              color: Colors.grey[400],
                              size: 32.sp,
                            ),
                          ),
                        ),
                        errorWidget: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.grey[300]!, Colors.grey[400]!],
                            ),
                          ),
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: Colors.grey[600],
                            size: 32.sp,
                          ),
                        ),
                      ),

                      // طبقة شفافة للتحكم في السطوع
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        decoration: BoxDecoration(
                          gradient:
                              isSelected
                                  ? LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Theme.of(
                                        context,
                                      ).primaryColor.withOpacity(0.3),
                                      Theme.of(
                                        context,
                                      ).primaryColor.withOpacity(0.6),
                                    ],
                                  )
                                  : LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.1),
                                      Colors.black.withOpacity(0.4),
                                    ],
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // اسم القسم في الأسفل
              Positioned(
                bottom: 6.h,
                left: 4.w,
                right: 4.w,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: isSelected ? 11.sp : 9.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: const Offset(0, 1),
                        blurRadius: 3,
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ],
                  ),
                  child: Text(
                    category.nameAr,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              // عداد المنتجات في الأعلى
              Positioned(
                top: 4.h,
                right: 4.w,
                child: AnimatedScale(
                  scale: isSelected ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? Colors.white
                              : Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '$productCount',
                      style: TextStyle(
                        color:
                            isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.white,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              // مؤشر الاختيار
              if (isSelected)
                Positioned(
                  top: 4.h,
                  left: 4.w,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 8.w,
                    height: 8.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  /// بناء شيمر للتحميل
  Widget _buildCategoriesShimmer() {
    return Container(
      height: 90.h, // تحديث الارتفاع ليتماشى مع التصميم الجديد
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: 75.w,
              height: 75.h,
              margin: EdgeInsets.symmetric(horizontal: 6.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
          );
        },
      ),
    );
  }

  /// تحديد القسم مع التحديث اللحظي المحسن والتفاعل
  void _selectCategory(
    EnhancedCategoryFilterController controller,
    String categoryId,
    String categoryName,
  ) {
    // تأثير اهتزاز خفيف للتأكيد
    HapticFeedback.lightImpact();

    // تحديث فوري للقسم المختار مع إجبار التحديث
    controller.selectedMainCategoryId.value = categoryId;
    controller.update(); // إجبار تحديث الـ controller

    // تحديث فوري للحالة المحلية
    setState(() {
      // هذا يضمن إعادة بناء الواجهة فوراً
    });

    // مزامنة مع controller الرئيسي
    if (Get.isRegistered<StoreProductsController>()) {
      final prodController = Get.find<StoreProductsController>();
      prodController.selectedCategory.value =
          categoryId.isEmpty ? 'الكل' : categoryId;
      prodController.applyFilters();
    }

    // تم إلغاء إشعار تغيير الفلتر الرئيسي حسب طلب المستخدم
    // No notification when changing main category filter
  }
}

Widget _buildProductsList(StoreProductsController controller) {
  return Obx(() {
    if (controller.isLoading.value) {
      return Center(
        child: CircularProgressIndicator(color: const Color(0xFF6366F1)),
      );
    }

    if (controller.filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80.sp,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16.h),
            Text(
              'لا توجد منتجات',
              style: TextStyle(fontSize: 18.sp, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final categoryFilter = Get.find<EnhancedCategoryFilterController>();
    final selectedCategoryId = categoryFilter.selectedMainCategoryId.value;
    final selectedCategoryNameAr =
        categoryFilter.mainCategories
            .firstWhereOrNull((cat) => cat.id == selectedCategoryId)
            ?.nameAr;

    final List<Map<String, dynamic>> displayedProducts;
    if (selectedCategoryId.isEmpty) {
      // عرض جميع المنتجات عند عدم اختيار قسم
      displayedProducts = controller.filteredProducts;
    } else {
      // فلترة المنتجات حسب القسم المختار
      displayedProducts =
          controller.filteredProducts.where((product) {
            try {
              // دعم جميع طرق الحفظ: بالمعرف أو بالاسم العربي
              final productMainCategoryId =
                  product['mainCategoryId']?.toString() ?? '';
              final productMainCategoryNameAr =
                  product['mainCategoryNameAr']?.toString() ?? '';
              final productSelectedMainCategoryNameAr =
                  product['selectedMainCategoryNameAr']?.toString() ?? '';

              // مطابقة بالمعرف أولاً (الطريقة المفضلة)
              if (productMainCategoryId.isNotEmpty &&
                  productMainCategoryId == selectedCategoryId) {
                return true;
              }

              // مطابقة بالاسم العربي (للتوافق مع المنتجات القديمة)
              if (selectedCategoryNameAr != null &&
                  selectedCategoryNameAr.isNotEmpty) {
                if (productMainCategoryNameAr == selectedCategoryNameAr) {
                  return true;
                }
                if (productSelectedMainCategoryNameAr ==
                    selectedCategoryNameAr) {
                  return true;
                }
              }

              return false;
            } catch (e) {
              debugPrint('❌ خطأ في فلترة المنتج: ${product['id']} - $e');
              return false; // في حالة الخطأ، إخفاء المنتج
            }
          }).toList();
    }

    if (displayedProducts.isEmpty && selectedCategoryId.isNotEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 50.h),
          child: Text(
            'لا توجد منتجات في هذا القسم حالياً',
            style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
          ),
        ),
      );
    }

    // دائمًا عرض المنتجات بشكل شبكة فقط
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(16.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
      ),
      itemCount: displayedProducts.length,
      itemBuilder: (context, index) {
        final product = displayedProducts[index];
        return _buildProductCard(product, controller);
      },
    );
  });
}

Widget _buildAdvancedFilters(StoreProductsController controller) {
  return Obx(
    () => Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'فلاتر متقدمة',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: controller.selectedCountry.value,
                  items:
                      controller.countryOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                  onChanged: (newValue) {
                    controller.selectedCountry.value = newValue!;
                  },
                  decoration: InputDecoration(
                    labelText: 'بلد المنشأ',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: controller.selectedQuality.value,
                  items:
                      controller.qualityOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                  onChanged: (newValue) {
                    controller.selectedQuality.value = newValue!;
                  },
                  decoration: InputDecoration(
                    labelText: 'جودة المنتج',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          DropdownButtonFormField<String>(
            value: controller.selectedProductType.value,
            items:
                controller.productTypeOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
            onChanged: (newValue) {
              controller.selectedProductType.value = newValue!;
            },
            decoration: InputDecoration(
              labelText: 'نوع المنتج',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildViewToggle(StoreProductsController controller) {
  return Obx(
    () => Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildViewIcon(controller, Icons.grid_view, ProductViewType.grid),
          SizedBox(width: 8.w),
          _buildViewIcon(controller, Icons.view_list, ProductViewType.list),
          SizedBox(width: 8.w),
          _buildViewIcon(
            controller,
            Icons.view_compact,
            ProductViewType.compact,
          ),
        ],
      ),
    ),
  );
}

Widget _buildViewIcon(
  StoreProductsController controller,
  IconData icon,
  ProductViewType viewType,
) {
  final bool isSelected = controller.productViewType.value == viewType;
  return IconButton(
    icon: Icon(icon, color: isSelected ? Get.theme.primaryColor : Colors.grey),
    onPressed: () => controller.changeViewType(viewType),
  );
}

Widget _buildProductListView(
  List<Map<String, dynamic>> products,
  StoreProductsController controller,
) {
  return ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    padding: EdgeInsets.symmetric(horizontal: 16.w),
    itemCount: products.length,
    itemBuilder: (context, index) {
      final product = products[index];
      return _buildProductListCard(product, controller);
    },
  );
}

Widget _buildProductCompactView(
  List<Map<String, dynamic>> products,
  StoreProductsController controller,
) {
  return GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    padding: EdgeInsets.all(16.w),
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3, // More items in a row
      childAspectRatio: 0.8, // Adjust aspect ratio for compact view
      crossAxisSpacing: 10.w,
      mainAxisSpacing: 10.h,
    ),
    itemCount: products.length,
    itemBuilder: (context, index) {
      final product = products[index];
      return _buildProductCompactCard(product, controller);
    },
  );
}

Widget _buildProductListCard(
  Map<String, dynamic> product,
  StoreProductsController controller,
) {
  // Implementation for list view card with more details
  return Card(
    margin: EdgeInsets.symmetric(vertical: 8.h),
    child: Padding(
      padding: EdgeInsets.all(8.w),
      child: Row(
        children: [
          // Image
          SizedBox(width: 10.w),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['nameOfItem'] ?? 'اسم غير متوفر',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                Text('بلد الصنع: ${product['countryOfOrigin'] ?? 'غير محدد'}'),
                SizedBox(height: 4.h),
                Text('الجودة: ${product['qualityGrade'] ?? 'غير محدد'}'),
                SizedBox(height: 8.h),
                _buildPrice(product, controller),
              ],
            ),
          ),
          // Add to cart or Notify me button
          (product['quantity'] as int? ?? 0) > 0
              ? IconButton(
                icon: Icon(
                  Icons.add_shopping_cart,
                  color: Get.theme.primaryColor,
                ),
                onPressed: () {
                  if (controller.isCartProcessing) return;
                  controller.setProcessingCart(true);

                  try {
                    debugPrint(
                      '🛒 محاولة إضافة منتج للسلة من ListView: ${product['id']}',
                    );
                    Get.find<RetailCartController>().addToCart(
                      product,
                      controller.store,
                    );
                    debugPrint('✅ تمت إضافة المنتج للسلة بنجاح من ListView');
                  } catch (e) {
                    debugPrint(
                      '❌ خطأ أثناء إضافة المنتج للسلة من ListView: $e',
                    );
                  }

                  controller.setProcessingCart(false);
                },
              )
              : TextButton(
                onPressed: () {
                  controller.requestStockNotification(product['id']);
                },
                child: Text('علمني عند التوفر'),
              ),
        ],
      ),
    ),
  );
}

Widget _buildProductCompactCard(
  Map<String, dynamic> product,
  StoreProductsController controller,
) {
  // Implementation for compact view card
  return Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStockIndicator(product),
        Expanded(
          child: Center(
            child: Text(
              product['nameOfItem'] ?? '',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(8.w),
          child: _buildPrice(product, controller),
        ),
      ],
    ),
  );
}

Widget _buildPrice(
  Map<String, dynamic> product,
  StoreProductsController controller,
) {
  final double originalPrice =
      double.tryParse(product['priceOfItem']?.toString() ?? '0') ?? 0.0;
  final double discountedPrice = controller.getDiscountedPrice(originalPrice);
  final bool hasDiscount = discountedPrice < originalPrice;

  return hasDiscount
      ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\$${discountedPrice.toStringAsFixed(2)}',
            style: TextStyle(
              color: Get.theme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '\$${originalPrice.toStringAsFixed(2)}',
            style: TextStyle(
              decoration: TextDecoration.lineThrough,
              color: Colors.grey,
            ),
          ),
        ],
      )
      : Text(
        '\$${originalPrice.toStringAsFixed(2)}',
        style: TextStyle(fontWeight: FontWeight.bold),
      );
}

Widget _buildSideFilterPanel(StoreProductsController controller) {
  return Obx(
    () => AnimatedContainer(
      duration: Duration(milliseconds: 300),
      width: controller.showFilters.value ? 250.w : 0,
      color: Colors.white,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الفلاتر',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.h),
              // Price Range
              Text('نطاق السعر'),
              RangeSlider(
                values: controller.priceRange.value,
                min: controller.minPrice.value,
                max: controller.maxPrice.value,
                divisions: ((controller.maxPrice.value -
                            controller.minPrice.value) /
                        10)
                    .round()
                    .clamp(1, 1000),
                labels: RangeLabels(
                  controller.priceRange.value.start.round().toString(),
                  controller.priceRange.value.end.round().toString(),
                ),
                onChanged: (values) => controller.setPriceRange(values),
              ),
              SizedBox(height: 16.h),
              // ... تم حذف فلتر بلد الصنع هنا لأن الفلتر الاحترافي موجود في MorphingFilterHub ...
              // Quality Grade
              Text('aaدرجة الجودة'),
              DropdownButtonFormField<String>(
                value:
                    controller.selectedQuality.value.isEmpty
                        ? null
                        : controller.selectedQuality.value,
                items:
                    controller.qualityOptions.map((String quality) {
                      return DropdownMenuItem<String>(
                        value: quality,
                        child: Text(quality),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  controller.setQuality(newValue ?? '');
                },
                decoration: InputDecoration(labelText: 'درجة الجودة'),
              ),
              SizedBox(height: 16.h),
              // On Offer
              Row(
                children: [
                  Text('المنتجات التي عليها عروض'),
                  Switch(
                    value: controller.filterOnOffer.value,
                    onChanged: (value) => controller.toggleOnOffer(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildStockIndicator(Map<String, dynamic> product) {
  final int quantity = product['quantity'] as int? ?? 0;
  if (quantity == 0) {
    return Text(
      'نفذت الكمية',
      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
    );
  } else if (quantity < 5) {
    return Text(
      'باقي $quantity قطع فقط!',
      style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
    );
  } else {
    return SizedBox.shrink(); // No indicator if stock is sufficient
  }
}

Widget _buildProductCard(
  Map<String, dynamic> product,
  StoreProductsController controller,
) {
  final String productId = product['id'] ?? '';
  final double originalPrice =
      double.tryParse(product['priceOfItem']?.toString() ?? '0') ?? 0.0;
  final double discountedPrice = controller.getDiscountedPrice(originalPrice);
  final bool hasDiscount = discountedPrice < originalPrice;

  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16.r),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8.r,
          offset: Offset(0, 4.h),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // صورة المنتج مع أيقونات المفضلة والمقارنة
        Stack(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // تأثير اهتزاز خفيف عند عرض التفاصيل
                  HapticFeedback.selectionClick();
                  controller.showProductDetails(product);
                },
                borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                splashColor: Colors.grey.withOpacity(0.2),
                highlightColor: Colors.grey.withOpacity(0.1),
                child: Container(
                  height: 120.h,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16.r),
                    ),
                    child: Stack(
                      children: [
                        CachedNetworkImage(
                          imageUrl: _getProductImageUrl(product),
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => Container(
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.image,
                                  color: Colors.grey[400],
                                  size: 40.sp,
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => Container(
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.grey[400],
                                  size: 40.sp,
                                ),
                              ),
                        ),
                        // تقييم المنتج على الصورة
                        Positioned(
                          bottom: 8.h,
                          left: 8.w,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 12.sp,
                                ),
                                SizedBox(width: 2.w),
                                Text(
                                  controller
                                      .getProductRating(productId)
                                      .toStringAsFixed(1),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 2.w),
                                Text(
                                  '(${controller.getReviewsCount(productId)})',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 8.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // أيقونة المفضلة مع تفاعل محسن
            Positioned(
              top: 8.h,
              right: 8.w,
              child: GetBuilder<StoreProductsController>(
                id: 'favorites_$productId',
                builder:
                    (controller) => Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          // تأثير اهتزاز للتأكيد
                          HapticFeedback.lightImpact();
                          controller.toggleFavorite(productId);
                        },
                        borderRadius: BorderRadius.circular(20.r),
                        splashColor: Colors.red.withOpacity(0.3),
                        highlightColor: Colors.red.withOpacity(0.1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.all(6.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4.r,
                                offset: Offset(0, 2.h),
                              ),
                            ],
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              controller.isFavorite(productId)
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              key: ValueKey(controller.isFavorite(productId)),
                              color:
                                  controller.isFavorite(productId)
                                      ? Colors.red
                                      : Colors.grey[600],
                              size: 18.sp,
                            ),
                          ),
                        ),
                      ),
                    ),
              ),
            ),
            // أيقونة المقارنة - تحت أيقونة المفضلة في الجهة اليمنى مع تفاعل محسن
            Positioned(
              top: 50.h, // تحت أيقونة المفضلة
              right: 8.w, // نفس محاذاة المفضلة
              child: GetBuilder<StoreProductsController>(
                id: 'compare_$productId', // معرف مخصص لكل منتج
                builder:
                    (controller) => Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          // تأثير اهتزاز للتأكيد
                          HapticFeedback.lightImpact();
                          if (controller.isInCompare(productId)) {
                            controller.removeFromCompare(product);
                          } else {
                            controller.addToCompare(product);
                          }
                        },
                        borderRadius: BorderRadius.circular(20.r),
                        splashColor: const Color(0xFF10B981).withOpacity(0.3),
                        highlightColor: const Color(
                          0xFF10B981,
                        ).withOpacity(0.1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.all(6.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4.r,
                                offset: Offset(0, 2.h),
                              ),
                            ],
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              controller.isInCompare(productId)
                                  ? Icons.compare_arrows
                                  : Icons.compare_arrows_outlined,
                              key: ValueKey(controller.isInCompare(productId)),
                              color:
                                  controller.isInCompare(productId)
                                      ? const Color(
                                        0xFF10B981,
                                      ) // أخضر عند الإضافة
                                      : Colors.grey[600],
                              size: 18.sp,
                            ),
                          ),
                        ),
                      ),
                    ),
              ),
            ),
            // عرض كمية المنتج المتاحة - أسفل زر المقارنة مقابل التقييم
            Positioned(
              top: 92.h, // أسفل زر المقارنة
              right: 8.w, // نفس محاذاة المقارنة
              child: GetBuilder<RetailCartController>(
                id: 'cart_$productId',
                builder: (cartController) {
                  final int originalQuantity =
                      (product['quantity'] as int?) ?? 0;
                  final int quantityInCart = cartController.getQuantity(
                    productId,
                  );
                  final int availableQuantity =
                      originalQuantity - quantityInCart;

                  // تغيير لون المؤشر حسب الكمية المتاحة
                  Color quantityColor;
                  if (availableQuantity == 0) {
                    quantityColor = Colors.red;
                  } else if (availableQuantity <= 5) {
                    quantityColor = Colors.orange;
                  } else {
                    quantityColor = Colors.green;
                  }

                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 3.h,
                    ),
                    decoration: BoxDecoration(
                      color: quantityColor.withOpacity(0.9),
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
                          availableQuantity == 0
                              ? Icons.inventory_2_outlined
                              : Icons.inventory_2,
                          color: Colors.white,
                          size: 10.sp,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          availableQuantity == 0
                              ? 'نفدت'
                              : '$availableQuantity',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // شارة الخصم
            if (hasDiscount)
              Positioned(
                top: 8.h,
                left: 50.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red, Colors.orange],
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    '${((originalPrice - discountedPrice) / originalPrice * 100).round()}%',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        // معلومات المنتج
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(9.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['nameOfItem'] ?? '',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8.h),
                // السعر وزر الكارتونة في نفس الصف
                GetBuilder<RetailCartController>(
                  id: 'cart_$productId',
                  builder: (cartController) {
                    final quantityInCart = cartController.getQuantity(
                      productId,
                    );
                    final int? quantityPerCarton =
                        product['quantityPerCarton'] as int?;
                    final int originalQuantity =
                        (product['quantity'] as int?) ?? 0;
                    final int availableQuantity =
                        originalQuantity - quantityInCart;

                    // تحديد ما إذا كان زر الكارتونة سيظهر
                    final bool showCartonButton =
                        quantityInCart > 0 &&
                        quantityPerCarton != null &&
                        quantityPerCarton > 0 &&
                        availableQuantity >= quantityPerCarton;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // عرض السعر مع التحكم في النص حسب وجود زر الكارتونة
                        Expanded(
                          flex:
                              showCartonButton
                                  ? 2
                                  : 3, // تقليل المساحة عند وجود زر الكارتونة
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (hasDiscount) ...[
                                Text(
                                  '${_formatPrice(originalPrice)} ريال',
                                  style: TextStyle(
                                    fontSize: 9.sp,
                                    color: Colors.grey[500],
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow
                                          .ellipsis, // إضافة ... عند الفيض
                                ),
                                Text(
                                  '${_formatPrice(discountedPrice)} ريال',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow
                                          .ellipsis, // إضافة ... عند الفيض
                                ),
                              ] else ...[
                                Text(
                                  '${_formatPrice(originalPrice)} ريال',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF6366F1),
                                  ),
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow
                                          .ellipsis, // إضافة ... عند الفيض
                                ),
                              ],
                            ],
                          ),
                        ),
                        // مساحة صغيرة بين السعر وزر الكارتونة
                        if (showCartonButton) SizedBox(width: 4.w),
                        // زر الكارتونة على الجانب الأيسر مع عرض الكمية والتفاعل المحسن
                        if (showCartonButton)
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                // تأثير اهتزاز خفيف للكارتونة
                                HapticFeedback.lightImpact();

                                if (controller.isCartProcessing) return;

                                controller.setProcessingCart(true);
                                try {
                                  final newQuantity =
                                      quantityInCart + quantityPerCarton;
                                  cartController.updateQuantity(
                                    productId,
                                    newQuantity,
                                  );
                                  cartController.update(['cart_$productId']);
                                } catch (e) {
                                  debugPrint(
                                    '❌ [ERROR] خطأ في إضافة الكارتونة: $e',
                                  );
                                } finally {
                                  controller.setProcessingCart(false);
                                }
                              },
                              borderRadius: BorderRadius.circular(8.r),
                              splashColor: const Color(
                                0xFF10B981,
                              ).withOpacity(0.3),
                              highlightColor: const Color(
                                0xFF10B981,
                              ).withOpacity(0.1),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF10B981),
                                      Color(0xFF059669),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(8.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF10B981,
                                      ).withOpacity(0.3),
                                      blurRadius: 4.r,
                                      offset: Offset(0, 2.h),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // أيقونة مع النص
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.add_box,
                                          color: Colors.white,
                                          size: 10.sp,
                                        ),
                                        SizedBox(width: 2.w),
                                        Text(
                                          'كارتونة',
                                          style: TextStyle(
                                            fontSize: 7.sp,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // عرض الكمية
                                    Text(
                                      '+$quantityPerCarton',
                                      style: TextStyle(
                                        fontSize: 6.sp,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                SizedBox(height: 4.h),
                // أزرار السلة - بدون Expanded لتجنب التداخل
                _buildCartButtons(productId, controller),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildCartButtons(String productId, StoreProductsController controller) {
  return GetBuilder<RetailCartController>(
    id: 'cart_$productId', // معرف فريد لكل منتج
    builder: (cartController) {
      final quantityInCart = cartController.getQuantity(productId);

      if (quantityInCart > 0) {
        // عرض أزرار التحكم في الكمية مع تقريب المسافات
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 15.w),
          child: Container(
            width: double.infinity, // العرض الكامل
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // زر الإزالة
                _buildQuantityButton(
                  icon: Icons.remove,
                  color: const Color(0xFFEF4444), // أحمر للإزالة
                  onTap: () {
                    if (controller.isCartProcessing) return;

                    controller.setProcessingCart(true);
                    debugPrint('🔒 [DEBUG] تأمين المعالجة');

                    try {
                      final newQuantity = quantityInCart - 1;
                      debugPrint('📉 [DEBUG] الكمية الجديدة: $newQuantity');

                      cartController.updateQuantity(productId, newQuantity);
                      debugPrint('✅ [DEBUG] تم استدعاء updateQuantity');

                      // إجبار تحديث UI
                      cartController.update(['cart_$productId']);
                      debugPrint('🔄 [DEBUG] تم إرسال update signal للتقليل');
                    } catch (e, stackTrace) {
                      debugPrint('❌ [ERROR] خطأ في تقليل الكمية: $e');
                      debugPrint('📍 [ERROR] Stack trace: $stackTrace');
                    } finally {
                      controller.setProcessingCart(false);
                      debugPrint('🔓 [DEBUG] إلغاء تأمين المعالجة');
                    }
                  },
                ),
                // عرض الكمية مع الانيميشن
                Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: 4.w,
                  ), // مسافة قليلة بين الأزرار
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (
                      Widget child,
                      Animation<double> animation,
                    ) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: Text(
                      '$quantityInCart',
                      key: ValueKey<int>(
                        quantityInCart,
                      ), // مفتاح ضروري لـ AnimatedSwitcher
                      style: TextStyle(
                        fontSize: 14.sp, // حجم أكبر قليلاً
                        fontWeight: FontWeight.w900, // أكثر سمكاً
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                  ),
                ),
                // زر الإضافة
                _buildQuantityButton(
                  icon: Icons.add,
                  color: const Color(0xFF059669), // أخضر للإضافة
                  onTap: () {
                    debugPrint('➕ [DEBUG] تم الضغط على زر الإضافة');
                    debugPrint('🆔 [DEBUG] معرف المنتج: $productId');
                    debugPrint('📊 [DEBUG] الكمية الحالية: $quantityInCart');

                    if (controller.isCartProcessing) {
                      debugPrint(
                        '⚠️ [WARNING] العملية قيد التنفيذ - تجاهل الضغطة',
                      );
                      return;
                    }

                    // التحقق من الكمية المتاحة قبل الإضافة
                    final product = controller.filteredProducts.firstWhere(
                      (p) => p['id'] == productId,
                      orElse: () => <String, dynamic>{},
                    );
                    final int originalQuantity =
                        (product['quantity'] as int?) ?? 0;
                    final int availableQuantity =
                        originalQuantity - quantityInCart;

                    if (availableQuantity <= 0) {
                      Get.snackbar(
                        'تنبيه',
                        'لا توجد كمية متاحة من هذا المنتج',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.orange,
                        colorText: Colors.white,
                        duration: const Duration(seconds: 2),
                      );
                      return;
                    }

                    controller.setProcessingCart(true);
                    debugPrint('🔒 [DEBUG] تأمين المعالجة');

                    try {
                      final newQuantity = quantityInCart + 1;
                      debugPrint('📈 [DEBUG] الكمية الجديدة: $newQuantity');

                      cartController.updateQuantity(productId, newQuantity);
                      debugPrint('✅ [DEBUG] تم استدعاء updateQuantity');

                      // إجبار تحديث UI
                      cartController.update(['cart_$productId']);
                      debugPrint('🔄 [DEBUG] تم إرسال update signal للإضافة');
                    } catch (e, stackTrace) {
                      debugPrint('❌ [ERROR] خطأ في زيادة الكمية: $e');
                      debugPrint('📍 [ERROR] Stack trace: $stackTrace');
                    } finally {
                      controller.setProcessingCart(false);
                      debugPrint('🔓 [DEBUG] إلغاء تأمين المعالجة');
                    }
                  },
                ),
              ],
            ),
          ),
        );
      } else {
        // التحقق من الكمية المتاحة قبل عرض زر الإضافة
        final int originalQuantity =
            (controller.filteredProducts.firstWhere(
                  (p) => p['id'] == productId,
                  orElse: () => {},
                )['quantity']
                as int?) ??
            0;
        final int quantityInCart = cartController.getQuantity(productId);
        final int availableQuantity = originalQuantity - quantityInCart;

        // إذا نفدت الكمية، عرض رسالة
        if (availableQuantity <= 0) {
          return Container(
            width: double.infinity, // العرض الكامل
            height: 35.h,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey[400]!),
            ),
            child: Center(
              child: Text(
                'نفدت الكمية',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }

        // زر "أضف للسلة" بالعرض الكامل مع تأثيرات التفاعل
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // تأثير اهتزاز متوسط للضغط
              HapticFeedback.mediumImpact();

              debugPrint('🔘 [DEBUG] تم الضغط على زر أضف للسلة');
              debugPrint('🆔 [DEBUG] معرف المنتج: $productId');
              debugPrint(
                '⏸️ [DEBUG] حالة المعالجة: isProcessingCart = ${controller.isCartProcessing}',
              );

              if (controller.isCartProcessing) {
                debugPrint(
                  '⚠️ [WARNING] العملية قيد التنفيذ بالفعل - تجاهل الضغطة',
                );
                return;
              }

              controller.setProcessingCart(true);
              debugPrint(
                '🔒 [DEBUG] تم تأمين المعالجة: isProcessingCart = true',
              );

              try {
                debugPrint('🔍 [DEBUG] البحث عن المنتج في filteredProducts...');
                debugPrint(
                  '📊 [DEBUG] عدد المنتجات المفلترة: ${controller.filteredProducts.length}',
                );

                final product = controller.filteredProducts.firstWhere(
                  (p) => p['id'] == productId,
                  orElse: () => <String, dynamic>{},
                );

                debugPrint(
                  '✅ [DEBUG] نتيجة البحث: ${product.isNotEmpty ? 'تم العثور على المنتج' : 'لم يتم العثور على المنتج'}',
                );

                if (product.isNotEmpty) {
                  debugPrint('📝 [DEBUG] بيانات المنتج:');
                  debugPrint('   - الاسم: ${product['nameOfItem']}');
                  debugPrint('   - السعر: ${product['priceOfItem']}');
                  debugPrint('   - المعرف: ${product['id']}');

                  debugPrint('🏪 [DEBUG] بيانات المتجر:');
                  debugPrint('   - اسم المتجر: ${controller.store.shopName}');
                  debugPrint('   - معرف المتجر: ${controller.store.uid}');

                  debugPrint('📞 [DEBUG] استدعاء cartController.addToCart...');

                  cartController.addToCart(product, controller.store);

                  debugPrint('✅ [SUCCESS] تم استدعاء addToCart بنجاح');

                  // إجبار تحديث UI
                  debugPrint('🔄 [DEBUG] إجبار تحديث UI...');
                  cartController.update(['cart_$productId']);
                  debugPrint('✅ [DEBUG] تم إرسال update signal');
                } else {
                  debugPrint('❌ [ERROR] المنتج غير موجود أو بياناته ناقصة');
                  debugPrint('🔍 [DEBUG] البحث في جميع المنتجات...');
                  final allProducts = controller.allProducts;
                  final foundInAll = allProducts.any(
                    (p) => p['id'] == productId,
                  );
                  debugPrint('📊 [DEBUG] موجود في allProducts: $foundInAll');
                }
              } catch (e, stackTrace) {
                debugPrint('❌ [ERROR] خطأ أثناء إضافة المنتج للسلة: $e');
                debugPrint('📍 [ERROR] Stack trace:');
                debugPrint(stackTrace.toString());
              } finally {
                controller.setProcessingCart(false);
                debugPrint(
                  '🔓 [DEBUG] تم إلغاء تأمين المعالجة: isProcessingCart = false',
                );
              }
            },
            borderRadius: BorderRadius.circular(12.r),
            splashColor: const Color(0xFF6366F1).withOpacity(0.3),
            highlightColor: const Color(0xFF6366F1).withOpacity(0.1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity, // العرض الكامل
              height: 20.h, // ارتفاع مناسب
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF6366F1), // Primary color
                    Color(0xFF8B5CF6), // Secondary color
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                    blurRadius: 8.r,
                    offset: Offset(0, 4.h),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_shopping_cart,
                    color: Colors.white,
                    size: 16.sp,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    'أضف للسلة',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    },
  );
}

String _getProductImageUrl(Map<String, dynamic> product) {
  try {
    final manyImages = product['manyImages'] as List<dynamic>? ?? [];
    if (manyImages.isNotEmpty) {
      final imageUrl = manyImages.first.toString();
      if (imageUrl.isNotEmpty && imageUrl != 'null') {
        return imageUrl;
      }
    }

    final singleUrl = product['url']?.toString();
    if (singleUrl != null && singleUrl.isNotEmpty && singleUrl != 'null') {
      return singleUrl;
    }

    return '';
  } catch (e) {
    debugPrint('خطأ في الحصول على صورة المنتج: $e');
    return '';
  }
}

// وظيفة تنسيق الأسعار بالفواصل
String _formatPrice(double price) {
  final formatter = NumberFormat('#,###', 'ar');
  return formatter.format(price.toInt());
}

// وظائف مساعدة للمقارنة المطورة
Widget _buildQuickActionButton({
  required IconData icon,
  required String label,
  required Color color,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12.r),
    child: Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
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
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

Widget _buildVerticalComparisonView(StoreProductsController controller) {
  return SingleChildScrollView(
    padding: EdgeInsets.all(16.w),
    child: Column(
      children:
          controller.compareProducts.map((product) {
            return Container(
              margin: EdgeInsets.only(bottom: 16.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15.r,
                    offset: Offset(0, 5.h),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // صورة المنتج مع تقييم
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20.r),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: _getProductImageUrl(product),
                          height: 180.h,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => Container(
                                height: 180.h,
                                color: Colors.grey[200],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: const Color(0xFF6366F1),
                                  ),
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => Container(
                                height: 180.h,
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 50.sp,
                                ),
                              ),
                        ),
                      ),
                      // شارة الأفضل
                      if (_isBestProduct(product, controller))
                        Positioned(
                          top: 12.h,
                          right: 12.w,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.amber, Colors.orange],
                              ),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  color: Colors.white,
                                  size: 16.sp,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  'الأفضل',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // زر الحذف
                      Positioned(
                        top: 12.h,
                        left: 12.w,
                        child: InkWell(
                          onTap: () => controller.removeFromCompare(product),
                          child: Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16.sp,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // تفاصيل المنتج
                  Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // اسم المنتج
                        Text(
                          product['nameOfItem'] ?? 'غير محدد',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F2937),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 12.h),
                        // جدول المقارنة
                        _buildComparisonTable(product),
                        SizedBox(height: 16.h),
                        // السعر
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF6366F1).withOpacity(0.1),
                                const Color(0xFF8B5CF6).withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'السعر:',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                '${_formatPrice((product['priceOfItem'] as num?)?.toDouble() ?? 0)} ريال',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF6366F1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    ),
  );
}

Widget _buildHorizontalComparisonView(StoreProductsController controller) {
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: EdgeInsets.all(16.w),
    child: Row(
      children:
          controller.compareProducts.map((product) {
            return Container(
              width: 280.w,
              margin: EdgeInsets.only(right: 16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15.r,
                    offset: Offset(0, 5.h),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // صورة مصغرة
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20.r),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: _getProductImageUrl(product),
                          height: 1200.h,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      if (_isBestProduct(product, controller))
                        Positioned(
                          top: 8.h,
                          right: 8.w,
                          child: Container(
                            padding: EdgeInsets.all(6.w),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Icon(
                              Icons.star,
                              color: Colors.white,
                              size: 16.sp,
                            ),
                          ),
                        ),
                    ],
                  ),
                  // تفاصيل مختصرة
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(12.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['nameOfItem'] ?? 'غير محدد',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Spacer(),
                          _buildCompactComparisonInfo(product),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    ),
  );
}

Widget _buildComparisonTable(Map<String, dynamic> product) {
  return Column(
    children: [
      _buildComparisonRow(
        'الجودة',
        '${product['qualityGrade'] ?? 'غير محدد'}',
        Icons.star,
      ),
      _buildComparisonRow(
        'بلد الصنع',
        '${product['countryOfOriginAr'] ?? 'غير محدد'}',
        Icons.flag,
      ),
      _buildComparisonRow(
        'المخزون',
        '${product['quantity'] ?? 0} قطعة',
        Icons.inventory,
      ),
      _buildComparisonRow(
        'حالة المنتج',
        '${product['itemCondition'] ?? 'جديد'}',
        Icons.info,
      ),
    ],
  );
}

Widget _buildComparisonRow(String title, String value, IconData icon) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: 4.h),
    child: Row(
      children: [
        Icon(icon, size: 16.sp, color: Colors.grey[600]),
        SizedBox(width: 8.w),
        Text(
          '$title:',
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
        ),
        Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
      ],
    ),
  );
}

Widget _buildCompactComparisonInfo(Map<String, dynamic> product) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '${_formatPrice((product['priceOfItem'] as num?)?.toDouble() ?? 0)} ريال',
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF6366F1),
        ),
      ),
      SizedBox(height: 4.h),
      Text(
        'جودة: ${product['qualityGrade'] ?? 'غير محدد'}',
        style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
      ),
      Text(
        'مخزون: ${product['quantity'] ?? 0}',
        style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
      ),
    ],
  );
}

bool _isBestProduct(
  Map<String, dynamic> product,
  StoreProductsController controller,
) {
  if (controller.compareProducts.isEmpty) return false;

  // المنتج الأفضل = أقل سعر + أعلى جودة + أكبر مخزون
  double bestScore = 0;
  double currentScore = 0;

  for (var p in controller.compareProducts) {
    double price = (p['priceOfItem'] as num?)?.toDouble() ?? 0;
    int quality = (p['qualityGrade'] as num?)?.toInt() ?? 0;
    int stock = (p['quantity'] as num?)?.toInt() ?? 0;

    // حساب النقاط (كلما قل السعر وزادت الجودة والمخزون، زادت النقاط)
    double score = (quality * 2) + (stock * 0.1) - (price * 0.001);

    if (p['id'] == product['id']) {
      currentScore = score;
    }
    if (score > bestScore) {
      bestScore = score;
    }
  }

  return currentScore == bestScore;
}

void _sortCompareProducts(StoreProductsController controller) {
  Get.dialog(
    AlertDialog(
      title: Text('ترتيب المنتجات'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.arrow_upward),
            title: Text('حسب السعر (الأقل أولاً)'),
            onTap: () {
              controller.compareProducts.sort((a, b) {
                double priceA = (a['priceOfItem'] as num?)?.toDouble() ?? 0;
                double priceB = (b['priceOfItem'] as num?)?.toDouble() ?? 0;
                return priceA.compareTo(priceB);
              });
              Get.back();
              _showCompareDialog(controller);
            },
          ),
          ListTile(
            leading: Icon(Icons.star),
            title: Text('حسب الجودة (الأعلى أولاً)'),
            onTap: () {
              controller.compareProducts.sort((a, b) {
                int qualityA = (a['qualityGrade'] as num?)?.toInt() ?? 0;
                int qualityB = (b['qualityGrade'] as num?)?.toInt() ?? 0;
                return qualityB.compareTo(qualityA);
              });
              Get.back();
              _showCompareDialog(controller);
            },
          ),
        ],
      ),
    ),
  );
}

void _showCompareStatistics(StoreProductsController controller) {
  double avgPrice = 0;
  double minPrice = double.infinity;
  double maxPrice = 0;
  int totalStock = 0;

  for (var product in controller.compareProducts) {
    double price = (product['priceOfItem'] as num?)?.toDouble() ?? 0;
    int stock = (product['quantity'] as num?)?.toInt() ?? 0;

    avgPrice += price;
    totalStock += stock;
    if (price < minPrice) minPrice = price;
    if (price > maxPrice) maxPrice = price;
  }

  avgPrice /= controller.compareProducts.length;

  Get.dialog(
    AlertDialog(
      title: Text('إحصائيات المقارنة'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatRow(
            'متوسط السعر',
            '${_formatPrice(avgPrice)} ريال',
            Icons.analytics,
          ),
          _buildStatRow(
            'أقل سعر',
            '${_formatPrice(minPrice)} ريال',
            Icons.trending_down,
          ),
          _buildStatRow(
            'أعلى سعر',
            '${_formatPrice(maxPrice)} ريال',
            Icons.trending_up,
          ),
          _buildStatRow('إجمالي المخزون', '$totalStock قطعة', Icons.inventory),
        ],
      ),
      actions: [TextButton(onPressed: () => Get.back(), child: Text('إغلاق'))],
    ),
  );
}

void _addBestProductToCart(StoreProductsController controller) {
  if (controller.compareProducts.isEmpty) return;

  Map<String, dynamic>? bestProduct;
  double bestScore = double.negativeInfinity;

  for (var product in controller.compareProducts) {
    double price = (product['priceOfItem'] as num?)?.toDouble() ?? 0;
    int quality = (product['qualityGrade'] as num?)?.toInt() ?? 0;
    int stock = (product['quantity'] as num?)?.toInt() ?? 0;

    double score = (quality * 2) + (stock * 0.1) - (price * 0.001);

    if (score > bestScore) {
      bestScore = score;
      bestProduct = product;
    }
  }

  if (bestProduct != null) {
    try {
      Get.find<RetailCartController>().addToCart(bestProduct, controller.store);
      Get.back();
      Get.snackbar(
        'تم بنجاح',
        'تم إضافة أفضل منتج للسلة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        icon: Icon(Icons.check_circle, color: Colors.white),
      );
    } catch (e) {
      debugPrint('خطأ في إضافة المنتج: $e');
    }
  }
}

void _shareComparison(StoreProductsController controller) {
  // يمكن تطوير هذه الوظيفة لمشاركة نتائج المقارنة
  Get.snackbar(
    'قريباً',
    'ميزة مشاركة المقارنة ستكون متاحة قريباً',
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: const Color(0xFF6366F1),
    colorText: Colors.white,
  );
}

Widget _buildQuantityButton({
  required IconData icon,
  required Color color,
  required VoidCallback onTap,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () {
        // تأثير اهتزاز للتأكيد
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(8.r),
      splashColor: color.withOpacity(0.3),
      highlightColor: color.withOpacity(0.1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 28.w, // حجم أكبر قليلاً لتحسين التفاعل
        height: 20.h, // حجم أكبر قليلاً لتحسين التفاعل
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8.r),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 6.r,
              offset: Offset(0, 3.h),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 16.sp, // حجم مناسب للأيقونة
        ),
      ),
    ),
  );
}

Widget _buildStatRow(String title, String value, IconData icon) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: 8.h),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFF6366F1), size: 20.sp),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            title,
            style: TextStyle(fontSize: 14.sp, color: const Color(0xFF1F2937)),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF6366F1),
          ),
        ),
      ],
    ),
  );
}

// عرض المفضلات
void _showFavoritesDialog() {
  // final controller = Get.find<StoreProductsController>();
  Get.dialog(
    Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: Get.width * 0.9,
        height: Get.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20.r,
              offset: Offset(0, 10.h),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'المنتجات المفضلة',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'اكتشف مجموعتك المميزة',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 18.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: GetBuilder<StoreProductsController>(
                id: 'favorites',
                builder: (controller) {
                  final favoriteProducts =
                      controller.allProducts
                          .where(
                            (product) =>
                                controller.isFavorite(product['id'] ?? ''),
                          )
                          .toList();

                  if (favoriteProducts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(24.w),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.favorite_border_rounded,
                              size: 60.sp,
                              color: Colors.grey[400],
                            ),
                          ),
                          SizedBox(height: 20.h),
                          Text(
                            'لا توجد منتجات مفضلة',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'ابدأ بإضافة المنتجات التي تعجبك\nبالنقر على أيقونة القلب',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[500],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Padding(
                    padding: EdgeInsets.all(16.w),
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12.w,
                        mainAxisSpacing: 12.h,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: favoriteProducts.length,
                      itemBuilder: (context, index) {
                        final product = favoriteProducts[index];
                        return _buildFavoriteProductCard(product, controller);
                      },
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

Widget _buildFavoriteProductCard(
  Map<String, dynamic> product,
  StoreProductsController controller,
) {
  final productId = product['id'] ?? '';
  final hasDiscount =
      (product['discountPercentage'] as num?)?.toDouble() != null &&
      (product['discountPercentage'] as num?)!.toDouble() > 0;
  final originalPrice = (product['priceOfItem'] as num?)?.toDouble() ?? 0.0;
  final discountPercentage =
      (product['discountPercentage'] as num?)?.toDouble() ?? 0.0;
  final finalPrice =
      hasDiscount
          ? originalPrice * (1 - discountPercentage / 100)
          : originalPrice;

  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16.r),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 8.r,
          offset: Offset(0, 2.h),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Image with Rating and Discount
        Expanded(
          flex: 3,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                child: CachedNetworkImage(
                  imageUrl: _getProductImageUrl(product),
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Container(
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.image,
                          color: Colors.grey[400],
                          size: 30.sp,
                        ),
                      ),
                  errorWidget:
                      (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.grey[400],
                          size: 30.sp,
                        ),
                      ),
                ),
              ),
              // Discount Badge
              if (hasDiscount)
                Positioned(
                  top: 8.h,
                  right: 8.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 3.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      '-${discountPercentage.toInt()}%',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              // Rating
              Positioned(
                bottom: 8.h,
                left: 8.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 10.sp),
                      SizedBox(width: 2.w),
                      Text(
                        controller
                            .getProductRating(productId)
                            .toStringAsFixed(1),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Favorite Button
              Positioned(
                top: 8.h,
                left: 8.w,
                child: GestureDetector(
                  onTap: () => controller.toggleFavorite(productId),
                  child: Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4.r,
                          offset: Offset(0, 2.h),
                        ),
                      ],
                    ),
                    child: Icon(Icons.favorite, color: Colors.red, size: 16.sp),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Product Details
        Expanded(
          flex: 2,
          child: Padding(
            padding: EdgeInsets.all(8.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Product Name
                Text(
                  product['nameOfItem'] ?? '',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 6.h),
                // Price
                if (hasDiscount)
                  Row(
                    children: [
                      Text(
                        '${_formatPrice(finalPrice)} ريال',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF6366F1),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        '${_formatPrice(originalPrice)}',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.grey[500],
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    '${_formatPrice(originalPrice)} ريال',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF6366F1),
                    ),
                  ),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      width: double.infinity,
                      height: 28.h,
                      child: ElevatedButton(
                        onPressed: () {
                          Get.back();
                          controller.showProductDetails(product);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'عرض التفاصيل',
                          style: TextStyle(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
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

/// بناء الشريط السفلي المتطور مع العناصر الخمسة
Widget _buildBottomNavigationWidget(StoreProductsController controller) {
  return Container(
    height: 70.h, // تقليل الارتفاع قليلاً
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10.r,
          offset: Offset(0, -2.h),
        ),
      ],
    ),
    child: SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 12.w,
          vertical: 4.h,
        ), // تقليل padding
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // عدد المنتجات - إظهار العدد الإجمالي للمنتجات في المتجر بدون إمكانية الضغط
            Obx(
              () => _buildBottomNavItem(
                icon: Icons.inventory_2_outlined,
                label: 'المنتجات',
                badge:
                    controller.allProducts.length
                        .toString(), // استخدام allProducts للعدد الحقيقي
                onTap: () {}, // لا يمكن الضغط
                color: const Color(0xFF6366F1),
              ),
            ),

            // المفضلة
            Obx(
              () => _buildBottomNavItem(
                icon:
                    controller.favoriteProducts.isNotEmpty
                        ? Icons.favorite
                        : Icons.favorite_border,
                label: 'المفضلة',
                badge:
                    controller.favoriteProducts.length > 0
                        ? controller.favoriteProducts.length.toString()
                        : null,
                onTap: () => _showFavoritesDialog(),
                color:
                    controller.favoriteProducts.isNotEmpty
                        ? Colors.red
                        : Colors.grey,
              ),
            ),

            // المقارنة
            Obx(
              () => _buildBottomNavItem(
                icon:
                    controller.compareProducts.isNotEmpty
                        ? Icons.compare_arrows
                        : Icons.compare_arrows_outlined,
                label: 'المقارنة',
                badge:
                    controller.compareProducts.length > 0
                        ? controller.compareProducts.length.toString()
                        : null,
                onTap: () => _showCompareDialog(controller),
                color:
                    controller.compareProducts.isNotEmpty
                        ? const Color(0xFF10B981)
                        : Colors.grey,
              ),
            ),

            // الكوبونات
            Obx(
              () => _buildBottomNavItem(
                icon:
                    controller.appliedCoupon.value.isNotEmpty
                        ? Icons.local_offer
                        : Icons.local_offer_outlined,
                label: 'كوبونات',
                badge: controller.appliedCoupon.value.isNotEmpty ? '1' : null,
                onTap: () => _showCouponsDialog(),
                color:
                    controller.appliedCoupon.value.isNotEmpty
                        ? const Color(0xFFF59E0B)
                        : Colors.grey,
              ),
            ),

            // السلة - التنقل إلى صفحة السلة RetailCartPage
            Obx(() {
              final cartController = Get.find<RetailCartController>();
              final cartCount = cartController.cartItems.length;
              return _buildBottomNavItem(
                icon:
                    cartCount > 0
                        ? Icons.shopping_cart
                        : Icons.shopping_cart_outlined,
                label: 'السلة',
                badge: cartCount > 0 ? cartCount.toString() : null,
                onTap:
                    () => Get.to(
                      () => const RetailCartPage(),
                    ), // التنقل المباشر إلى RetailCartPage
                color: cartCount > 0 ? const Color(0xFFEF4444) : Colors.grey,
              );
            }),
          ],
        ),
      ),
    ),
  );
}

/// بناء عنصر واحد في الشريط السفلي مع تأثيرات التفاعل
Widget _buildBottomNavItem({
  required IconData icon,
  required String label,
  required VoidCallback onTap,
  required Color color,
  String? badge,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () {
        // تأثير اهتزاز خفيف عند الضغط
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(12.r),
      splashColor: color.withOpacity(0.2),
      highlightColor: color.withOpacity(0.1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
          horizontal: 6.w,
          vertical: 2.h,
        ), // تقليل padding
        child: Column(
          mainAxisSize: MainAxisSize.min, // ضروري لمنع الفيض
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 20.sp, // تقليل حجم الأيقونة
                  color: color,
                ),
                if (badge != null)
                  Positioned(
                    right: -4.w, // تقليل المسافة
                    top: -4.h, // تقليل المسافة
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.all(2.w), // تقليل padding
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(
                          8.r,
                        ), // تقليل border radius
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 4.r,
                            offset: Offset(0, 2.h),
                          ),
                        ],
                      ),
                      constraints: BoxConstraints(
                        minWidth: 14.w, // تقليل الحد الأدنى للعرض
                        minHeight: 14.h, // تقليل الحد الأدنى للارتفاع
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8.sp, // تقليل حجم الخط
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 2.h), // تقليل المسافة
            Flexible(
              // إضافة Flexible لمنع فيض النص
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 9.sp, // تقليل حجم الخط
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1, // تحديد عدد الأسطر
                overflow: TextOverflow.ellipsis, // إضافة ... عند الفيض
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// عرض حوار المقارنة
/// عرض حوار المقارنة المطور والاحترافي
void _showCompareDialog(StoreProductsController controller) {
  if (controller.compareProducts.isEmpty) {
    Get.snackbar(
      'تنبيه',
      'لا توجد منتجات للمقارنة',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      icon: Icon(Icons.compare_arrows, color: Colors.white),
      borderRadius: 12.r,
      margin: EdgeInsets.all(16.w),
    );
    return;
  }

  Get.dialog(
    Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(16.w),
      child: Container(
        width: Get.width,
        height: Get.height * 0.9,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, const Color(0xFFF8FAFC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 30.r,
              offset: Offset(0, 10.h),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header متطور مع تدرج
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6366F1),
                    const Color(0xFF8B5CF6),
                    const Color(0xFFEC4899),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                    blurRadius: 15.r,
                    offset: Offset(0, 8.h),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Icon(
                      Icons.compare_arrows,
                      color: Colors.white,
                      size: 28.sp,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مقارنة المنتجات',
                          style: TextStyle(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '${controller.compareProducts.length} منتجات للمقارنة',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // أزرار التحكم السريع
            Container(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  Expanded(
                    child: _buildQuickActionButton(
                      icon: Icons.delete_sweep,
                      label: 'مسح الكل',
                      color: Colors.red,
                      onTap: () {
                        controller.clearCompare();
                        Get.back();
                      },
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildQuickActionButton(
                      icon: Icons.sort,
                      label: 'ترتيب بالسعر',
                      color: const Color(0xFF10B981),
                      onTap: () => _sortCompareProducts(controller),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildQuickActionButton(
                      icon: Icons.analytics,
                      label: 'إحصائيات',
                      color: const Color(0xFF8B5CF6),
                      onTap: () => _showCompareStatistics(controller),
                    ),
                  ),
                ],
              ),
            ),

            // جدول المقارنة الاحترافي
            Expanded(
              child:
                  controller.compareProducts.length <= 2
                      ? _buildVerticalComparisonView(controller)
                      : _buildHorizontalComparisonView(controller),
            ),

            // شريط الإجراءات السفلي
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(24.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10.r,
                    offset: Offset(0, -2.h),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _addBestProductToCart(controller),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        elevation: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star, color: Colors.white, size: 20.sp),
                          SizedBox(width: 8.w),
                          Text(
                            'إضافة الأفضل للسلة',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  ElevatedButton(
                    onPressed: () => _shareComparison(controller),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        side: BorderSide(color: const Color(0xFF6366F1)),
                      ),
                      padding: EdgeInsets.all(16.w),
                      elevation: 2,
                    ),
                    child: Icon(
                      Icons.share,
                      color: const Color(0xFF6366F1),
                      size: 20.sp,
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

// عرض الكوبونات
void _showCouponsDialog() {
  final controller = Get.find<StoreProductsController>();
  final TextEditingController couponController = TextEditingController();

  Get.bottomSheet(
    Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: Get.height * 0.8, // تحديد أقصى ارتفاع 80% من الشاشة
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'الكوبونات والخصومات',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            SizedBox(height: 20.h),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    GetBuilder<StoreProductsController>(
                      id: 'coupon',
                      builder: (controller) {
                        if (controller.appliedCoupon.value.isNotEmpty) {
                          return Container(
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: Colors.green[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 24.sp,
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'تم تطبيق الكوبون: ${controller.appliedCoupon.value}',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[700],
                                        ),
                                      ),
                                      Text(
                                        'خصم مطبق',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: Colors.green[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => controller.removeCoupon(),
                                  icon: Icon(Icons.close, color: Colors.red),
                                ),
                              ],
                            ),
                          );
                        }

                        return Column(
                          children: [
                            TextField(
                              controller: couponController,
                              decoration: InputDecoration(
                                hintText: 'أدخل رمز الكوبون',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                prefixIcon: Icon(Icons.local_offer),
                              ),
                            ),
                            SizedBox(height: 16.h),
                            ElevatedButton(
                              onPressed: () {
                                if (couponController.text.isNotEmpty) {
                                  controller.applyCoupon(couponController.text);
                                  couponController.clear();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                minimumSize: Size(double.infinity, 48.h),
                              ),
                              child: Text(
                                'تطبيق الكوبون',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      'الكوبونات المتاحة:',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    ...controller.getValidCoupons().map(
                      (coupon) => Card(
                        child: ListTile(
                          leading: Icon(
                            Icons.local_offer,
                            color: Colors.orange,
                          ),
                          title: Text(
                            coupon['code'],
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('خصم ${coupon['discount']}%'),
                          trailing: TextButton(
                            onPressed: () {
                              controller.applyCoupon(coupon['code']);
                            },
                            child: Text('تطبيق'),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    ElevatedButton(
                      onPressed: () => Get.back(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'إغلاق',
                        style: TextStyle(color: Colors.white, fontSize: 14.sp),
                      ),
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

/// Controller للفلترة المتقدمة للأقسام في تطبيق البائع
class EnhancedCategoryFilterController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // حالات التحميل
  final RxBool isLoading = false.obs;
  final RxBool isLoadingSubCategories = false.obs;
  final RxBool hasActiveFilter = false.obs;

  // الفلاتر الحالية
  final RxString selectedMainCategoryId = ''.obs;
  final RxString selectedSubCategoryId = ''.obs;
  final RxString selectedMainCategoryName = ''.obs;
  final RxString selectedSubCategoryName = ''.obs;

  // الأقسام المتاحة
  final RxList<CategoryModel> mainCategories = <CategoryModel>[].obs;
  final RxList<CategoryModel> subCategories = <CategoryModel>[].obs;
  final RxList<CategoryModel> allCategories = <CategoryModel>[].obs;

  // cache لعدد المنتجات في كل قسم لتحسين الأداء
  final Map<String, int> _productCountCache = <String, int>{};

  @override
  void onInit() {
    super.onInit();
    loadCategories();

    // مراقبة تغييرات المنتجات لإعادة حساب عدد المنتجات في الأقسام
    if (Get.isRegistered<StoreProductsController>()) {
      final productsController = Get.find<StoreProductsController>();
      ever(productsController.allProducts, (_) {
        debugPrint('🔄 تم تحديث المنتجات، إعادة بناء فلاتر الأقسام');
        clearProductCountCache(); // مسح الـ cache
        update(); // إعادة بناء Widget الخاص بالأقسام
      });
    }
  }

  /// تحميل جميع الأقسام من Firebase
  Future<void> loadCategories() async {
    try {
      isLoading.value = true;

      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _firestore
              .collection('categories')
              .where('isActive', isEqualTo: true)
              .orderBy('order', descending: false)
              .get();

      final List<CategoryModel> categories =
          snapshot.docs.map((doc) => CategoryModel.fromSnapshot(doc)).toList();

      allCategories.assignAll(categories);

      // فصل الأقسام الرئيسية والفرعية
      final List<CategoryModel> mainCats = [];

      for (var category in categories) {
        if (category.isMainCategory) {
          mainCats.add(category);
        }
      }

      mainCategories.assignAll(mainCats);

      debugPrint(
        '✅ تم تحميل ${allCategories.length} قسم إجمالي، ${mainCategories.length} قسم رئيسي',
      );
    } catch (e) {
      debugPrint('❌ خطأ في تحميل الأقسام: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// تحميل الأقسام الفرعية للقسم الرئيسي المحدد
  Future<void> loadSubCategories(String mainCategoryId) async {
    try {
      if (mainCategoryId.isEmpty) {
        subCategories.clear();
        return;
      }

      isLoadingSubCategories.value = true;

      // البحث في الأقسام المحملة بدلاً من استعلام Firebase جديد
      final List<CategoryModel> subCats =
          allCategories
              .where(
                (cat) => cat.parentId == mainCategoryId && !cat.isMainCategory,
              )
              .toList();

      subCategories.assignAll(subCats);

      debugPrint(
        '✅ تم تحميل ${subCategories.length} قسم فرعي للقسم $mainCategoryId',
      );
    } catch (e) {
      debugPrint('❌ خطأ في تحميل الأقسام الفرعية: $e');
    } finally {
      isLoadingSubCategories.value = false;
    }
  }

  /// تحديد القسم الرئيسي
  void selectMainCategory(String categoryId, String categoryName) {
    selectedMainCategoryId.value = categoryId;
    selectedMainCategoryName.value = categoryName;
    selectedSubCategoryId.value = '';
    selectedSubCategoryName.value = '';

    hasActiveFilter.value = categoryId.isNotEmpty;

    if (categoryId.isNotEmpty) {
      loadSubCategories(categoryId);
    } else {
      subCategories.clear();
    }

    debugPrint('🔍 تم اختيار القسم الرئيسي: $categoryName ($categoryId)');

    // إجبار إعادة بناء ProductGridWidget
    update();
  }

  /// تحديد القسم الفرعي
  void selectSubCategory(String categoryId, String categoryName) {
    selectedSubCategoryId.value = categoryId;
    selectedSubCategoryName.value = categoryName;
    hasActiveFilter.value = true;

    debugPrint('🔍 تم اختيار القسم الفرعي: $categoryName ($categoryId)');

    // إجبار إعادة بناء ProductGridWidget
    update();
  }

  /// إعادة تعيين الفلاتر
  void resetFilters() {
    selectedMainCategoryId.value = '';
    selectedSubCategoryId.value = '';
    selectedMainCategoryName.value = '';
    selectedSubCategoryName.value = '';
    hasActiveFilter.value = false;
    subCategories.clear();

    debugPrint('🔄 تم إعادة تعيين جميع فلاتر الأقسام');

    // إجبار إعادة بناء ProductGridWidget
    update();
  }

  /// الحصول على مفتاح الفلتر الحالي
  String getFilterKey() {
    debugPrint("🔑 getFilterKey() - تحديد مفتاح الفلتر:");
    debugPrint("   - hasActiveFilter: ${hasActiveFilter.value}");
    debugPrint(
      "   - selectedMainCategoryId: '${selectedMainCategoryId.value}'",
    );
    debugPrint("   - selectedSubCategoryId: '${selectedSubCategoryId.value}'");

    if (selectedSubCategoryId.value.isNotEmpty) {
      final result = 'sub_${selectedSubCategoryId.value}';
      debugPrint("   -> نتيجة: '$result' (قسم فرعي)");
      return result;
    } else if (selectedMainCategoryId.value.isNotEmpty) {
      final result = 'main_${selectedMainCategoryId.value}';
      debugPrint("   -> نتيجة: '$result' (قسم رئيسي)");
      return result;
    }

    debugPrint("   -> نتيجة: 'all_items' (لا يوجد فلتر)");
    return 'all_items';
  }

  /// الحصول على وصف الفلتر الحالي
  String getFilterDescription() {
    if (selectedSubCategoryName.value.isNotEmpty) {
      return selectedSubCategoryName.value;
    } else if (selectedMainCategoryName.value.isNotEmpty) {
      return selectedMainCategoryName.value;
    }
    return 'جميع المنتجات';
  }

  /// الحصول على معرف القسم المحدد (فرعي إذا موجود، وإلا رئيسي)
  String? getSelectedCategoryId() {
    if (selectedSubCategoryId.value.isNotEmpty) {
      return selectedSubCategoryId.value;
    } else if (selectedMainCategoryId.value.isNotEmpty) {
      return selectedMainCategoryId.value;
    }
    return null;
  }

  /// التحقق من وجود فلتر نشط
  bool get hasAnyActiveFilter {
    return selectedMainCategoryId.value.isNotEmpty ||
        selectedSubCategoryId.value.isNotEmpty;
  }

  /// حساب عدد المنتجات في قسم معين
  int getProductCountForCategory(String categoryId) {
    try {
      // التحقق من وجود النتيجة في الـ cache
      if (_productCountCache.containsKey(categoryId)) {
        return _productCountCache[categoryId]!;
      }

      // الحصول على StoreProductsController للوصول للمنتجات
      if (!Get.isRegistered<StoreProductsController>()) {
        debugPrint('⚠️ StoreProductsController غير مسجل');
        return 0;
      }

      final productsController = Get.find<StoreProductsController>();
      final products = productsController.allProducts;

      int count = 0;
      for (var product in products) {
        final String? mainCategoryId = product['mainCategoryId']?.toString();
        if (mainCategoryId == categoryId) {
          count++;
        }
      }

      // حفظ النتيجة في الـ cache
      _productCountCache[categoryId] = count;

      debugPrint('📊 القسم $categoryId يحتوي على $count منتج');
      return count;
    } catch (e) {
      debugPrint('❌ خطأ في حساب عدد المنتجات للقسم $categoryId: $e');
      return 0;
    }
  }

  /// مسح الـ cache عند تحديث المنتجات
  void clearProductCountCache() {
    _productCountCache.clear();
    debugPrint('🧹 تم مسح cache عدد المنتجات');
  }

  /// الحصول على الأقسام الرئيسية التي تحتوي على منتجات فقط
  List<CategoryModel> getMainCategoriesWithProducts() {
    return mainCategories.where((category) {
      final productCount = getProductCountForCategory(category.id);
      return productCount > 0;
    }).toList();
  }
}

/// نموذج الفئة المحسن
class CategoryModel {
  final String id;
  final String nameAr;
  final String nameEn;
  final String nameKu;
  final String? imageUrl;
  final String? iconName;
  final String? color;
  final int order;
  final bool isActive;
  final bool isMainCategory;
  final String? parentId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final bool isForOriginalProducts;
  final bool isForCommercialProducts;

  CategoryModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.nameKu,
    this.imageUrl,
    this.iconName,
    this.color,
    required this.order,
    required this.isActive,
    required this.isMainCategory,
    this.parentId,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.isForOriginalProducts,
    required this.isForCommercialProducts,
  });

  factory CategoryModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    return CategoryModel(
      id: snapshot.id,
      nameAr: data['nameAr'] as String? ?? 'قسم غير معروف',
      nameEn: data['nameEn'] as String? ?? 'Unknown Category',
      nameKu: data['nameKu'] as String? ?? 'پۆلی نەناسراو',
      imageUrl: data['imageUrl'] as String?,
      iconName: data['iconName'] as String?,
      color: data['color'] as String?,
      order: (data['order'] as num?)?.toInt() ?? 999,
      isActive: data['isActive'] as bool? ?? true,
      isMainCategory: data['parentId'] == null, // إذا لم يكن له والد فهو رئيسي
      parentId: data['parentId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] as String? ?? 'system',
      isForOriginalProducts: data['isForOriginalProducts'] as bool? ?? true,
      isForCommercialProducts: data['isForCommercialProducts'] as bool? ?? true,
    );
  }

  /// التحقق من إمكانية استخدام القسم لنوع المنتج المحدد
  bool canBeUsedForProductType(String? productType) {
    if (productType == null) return true;

    switch (productType.toLowerCase()) {
      case 'original':
        return isForOriginalProducts;
      case 'commercial':
        return isForCommercialProducts;
      default:
        return true;
    }
  }

  /// الحصول على اسم القسم حسب اللغة
  String getNameByLanguage(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'ar':
        return nameAr;
      case 'en':
        return nameEn;
      case 'ku':
        return nameKu;
      default:
        return nameAr; // افتراضي
    }
  }

  @override
  String toString() {
    return 'CategoryModel(id: $id, nameAr: $nameAr, isMainCategory: $isMainCategory, parentId: $parentId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryModel && other.id == id && other.nameAr == nameAr;
  }

  @override
  int get hashCode {
    return id.hashCode ^ nameAr.hashCode;
  }
}
