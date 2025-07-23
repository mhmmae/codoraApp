// // مثال لاختبار نظام عرض الفلاتر الجديد
//
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// // مثال لإنشاء بيانات تجريبية للاختبار
// class FiltersTestData {
//   static const Map<String, dynamic> sampleCategory = {
//     'nameAr': 'هواتف ذكية',
//     'nameEn': 'Smartphones',
//     'nameKu': 'مۆبایل',
//     'imageUrl': 'https://example.com/smartphones.jpg',
//     'iconName': 'phone_android',
//     'color': '#2196F3',
//     'order': 1,
//     'isActive': true,
//     'parentId': 'electronics_main',
//     'createdAt': Timestamp.now(),
//     'updatedAt': Timestamp.now(),
//     'createdBy': 'system',
//     'isForOriginalProducts': true,
//     'isForCommercialProducts': true,
//   };
//
//   static const Map<String, dynamic> sampleCompany = {
//     'nameAr': 'آبل',
//     'nameEn': 'Apple',
//     'logoUrl': 'https://example.com/apple-logo.jpg',
//     'description': 'شركة آبل الأمريكية',
//     'country': 'الولايات المتحدة',
//     'isActive': true,
//     'createdBy': 'admin',
//     'createdAt': Timestamp.now(),
//     'updatedAt': Timestamp.now(),
//   };
//
//   static const Map<String, dynamic> sampleProduct = {
//     'nameAr': 'آيفون 15 برو',
//     'nameEn': 'iPhone 15 Pro',
//     'imageUrl': 'https://example.com/iphone15pro.jpg',
//     'description': 'أحدث هاتف من آبل',
//     'companyId': 'apple_company_id',
//     'isActive': true,
//     'createdBy': 'admin',
//     'createdAt': Timestamp.now(),
//     'updatedAt': Timestamp.now(),
//   };
// }
//
// // مثال لاستخدام النظام الجديد في الكود
// class ExampleUsage {
//   // 1. تفعيل عرض الفلاتر في الصفحة الرئيسية
//   static void showFiltersInHomePage() {
//     // يتم من خلال الضغط على الإيقونة الجديدة في أعلى الصفحة
//     // أو يمكن التفعيل برمجياً:
//
//     final homeController = Get.find<HomeScreenController>(); // إذا كان متاحاً
//     // homeController.showFiltersGrid.value = true;
//   }
//
//   // 2. الانتقال مباشرة لصفحة الفلاتر
//   static void openFiltersScreen() {
//     Get.to(
//       () => const FiltersDisplayScreen(),
//       transition: Transition.rightToLeft,
//       duration: const Duration(milliseconds: 300),
//     );
//   }
//
//   // 3. فتح منتجات فلتر معين
//   static void openSpecificFilter(String filterKey, String title) {
//     Get.to(
//       () => FilteredProductsScreen(
//         filterKey: filterKey,
//         filterTitle: title,
//         filterSubtitle: 'فئة محددة',
//         filterType: FilterType.subCategory,
//       ),
//     );
//   }
//
//   // 4. إعادة تحميل الفلاتر
//   static void refreshFilters() {
//     final controller = Get.find<FiltersDisplayController>();
//     controller.refreshFilters();
//   }
// }
//
// // أمثلة على مفاتيح الفلاتر المدعومة
// class FilterKeys {
//   // فلاتر الأقسام الفرعية
//   static const String smartphones = 'sub_smartphones_id';
//   static const String laptops = 'sub_laptops_id';
//   static const String tablets = 'sub_tablets_id';
//
//   // فلاتر الشركات
//   static const String appleCompany = 'original_company_apple_id';
//   static const String samsungCompany = 'original_company_samsung_id';
//   static const String huaweiCompany = 'original_company_huawei_id';
//
//   // فلاتر المنتجات الأصلية
//   static const String iphone15Pro = 'original_product_iphone15pro_id';
//   static const String galaxyS24 = 'original_product_galaxys24_id';
//   static const String macbookPro = 'original_product_macbookpro_id';
//
//   // فلاتر خاصة
//   static const String allOriginalBrands = 'original_brands';
//   static const String allItems = 'all_items';
// }
//
// // مثال لبيانات فلتر كاملة
// class SampleFilterData {
//   static final List<FilterItemModel> sampleFilters = [
//     FilterItemModel(
//       id: 'smartphones_cat',
//       title: 'هواتف ذكية',
//       subtitle: 'قسم فرعي',
//       imageUrl: 'https://example.com/smartphones.jpg',
//       type: FilterType.subCategory,
//       filterKey: 'sub_smartphones_cat',
//       parentId: 'electronics_main',
//     ),
//     FilterItemModel(
//       id: 'apple_company',
//       title: 'آبل',
//       subtitle: 'شركة مصنعة',
//       imageUrl: 'https://example.com/apple-logo.jpg',
//       type: FilterType.company,
//       filterKey: 'original_company_apple_company',
//     ),
//     FilterItemModel(
//       id: 'iphone15pro_product',
//       title: 'آيفون 15 برو',
//       subtitle: 'منتج آبل',
//       imageUrl: 'https://example.com/iphone15pro.jpg',
//       type: FilterType.product,
//       filterKey: 'original_product_iphone15pro_product',
//       parentId: 'apple_company',
//       parentName: 'آبل',
//       productCount: 15, // عدد المنتجات المتاحة
//     ),
//   ];
// }
//
// // مثال للاستماع لتغييرات الفلاتر
// class FilterChangeListener extends GetxController {
//   final FiltersDisplayController filtersController = Get.find();
//
//   @override
//   void onInit() {
//     super.onInit();
//
//     // الاستماع لتغييرات حالة الرؤية
//     filtersController.isVisible.listen((isVisible) {
//       debugPrint('🔄 حالة عرض الفلاتر تغيرت: $isVisible');
//       if (isVisible && filtersController.allFilters.isEmpty) {
//         debugPrint('📊 بدء تحميل الفلاتر...');
//       }
//     });
//
//     // الاستماع لتغييرات قائمة الفلاتر
//     filtersController.allFilters.listen((filters) {
//       debugPrint('📋 تم تحديث قائمة الفلاتر: ${filters.length} فلتر');
//       for (var filter in filters) {
//         debugPrint('   - ${filter.title} (${filter.type.displayName})');
//       }
//     });
//   }
// }
//
// // مثال لدمج النظام الجديد مع النظام الحالي
// class IntegrationExample {
//   static void handleFilterSelection(FilterItemModel filter) {
//     debugPrint('🎯 تم اختيار الفلتر: ${filter.title}');
//     debugPrint('   - النوع: ${filter.type.displayName}');
//     debugPrint('   - المفتاح: ${filter.filterKey}');
//
//     // إخفاء الفلاتر الأخرى إذا كانت مفعلة
//     try {
//       final categoryController = Get.find<EnhancedCategoryFilterController>();
//       if (filter.type != FilterType.subCategory) {
//         categoryController.resetFilters();
//       }
//     } catch (e) {
//       debugPrint('متحكم الأقسام غير متاح');
//     }
//
//     try {
//       final brandController = Get.find<BrandFilterController>();
//       if (filter.type == FilterType.subCategory) {
//         brandController.deactivateBrandMode();
//       }
//     } catch (e) {
//       debugPrint('متحكم البراند غير متاح');
//     }
//
//     // تطبيق الفلتر المحدد
//     switch (filter.type) {
//       case FilterType.subCategory:
//         _applySubCategoryFilter(filter);
//         break;
//       case FilterType.company:
//         _applyCompanyFilter(filter);
//         break;
//       case FilterType.product:
//         _applyProductFilter(filter);
//         break;
//     }
//   }
//
//   static void _applySubCategoryFilter(FilterItemModel filter) {
//     try {
//       final categoryController = Get.find<EnhancedCategoryFilterController>();
//       categoryController.selectSubCategory(filter.id, filter.title);
//     } catch (e) {
//       debugPrint('خطأ في تطبيق فلتر القسم الفرعي: $e');
//     }
//   }
//
//   static void _applyCompanyFilter(FilterItemModel filter) {
//     try {
//       final brandController = Get.find<BrandFilterController>();
//       // إيجاد الشركة وتحديدها
//       final company = brandController.companies.firstWhereOrNull(
//         (c) => c.id == filter.id,
//       );
//       if (company != null) {
//         brandController.selectCompany(company);
//       }
//     } catch (e) {
//       debugPrint('خطأ في تطبيق فلتر الشركة: $e');
//     }
//   }
//
//   static void _applyProductFilter(FilterItemModel filter) {
//     try {
//       final brandController = Get.find<BrandFilterController>();
//       // إيجاد المنتج وتحديده
//       final product = brandController.selectedCompanyProducts.firstWhereOrNull(
//         (p) => p.id == filter.id,
//       );
//       if (product != null) {
//         brandController.selectCompanyProduct(product);
//       }
//     } catch (e) {
//       debugPrint('خطأ في تطبيق فلتر المنتج: $e');
//     }
//   }
// }
