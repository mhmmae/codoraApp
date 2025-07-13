import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../Model/enhanced_category_model.dart';
import 'categories_management_controller.dart';

/// Controller للفلترة المتطورة باستخدام EnhancedCategoryModel
class EnhancedCategoryFilterController extends GetxController {
  final CategoriesManagementController _categoriesController = Get.put(CategoriesManagementController());

  // مفتاح فلتر "الكل"
  static const String allFilterKey = 'all';

  // الاختيارات الحالية
  final RxString selectedMainCategoryId = allFilterKey.obs;
  final RxString selectedSubCategoryId = allFilterKey.obs;

  // قوائم الأقسام للعرض
  List<EnhancedCategoryModel> get mainCategories => _categoriesController.mainCategories;
  List<EnhancedCategoryModel> get allCategories => _categoriesController.allCategories;

  // حالة التحميل
  bool get isLoading => _categoriesController.isLoading.value;

  // الأقسام الفرعية للقسم الرئيسي المختار
  List<EnhancedCategoryModel> get subCategoriesForSelectedMain {
    if (selectedMainCategoryId.value == allFilterKey) return [];

    return allCategories
        .where((category) =>
            category.parentId == selectedMainCategoryId.value &&
            category.isActive)
        .toList();
  }

  // الحصول على القسم الرئيسي المختار
  EnhancedCategoryModel? get selectedMainCategory {
    if (selectedMainCategoryId.value == allFilterKey) return null;
    return mainCategories.firstWhereOrNull((cat) => cat.id == selectedMainCategoryId.value);
  }

  // الحصول على القسم الفرعي المختار
  EnhancedCategoryModel? get selectedSubCategory {
    if (selectedSubCategoryId.value == allFilterKey) return null;
    return subCategoriesForSelectedMain.firstWhereOrNull((cat) => cat.id == selectedSubCategoryId.value);
  }

  @override
  void onInit() {
    super.onInit();
    // تأكد من تحميل الأقسام
    if (_categoriesController.allCategories.isEmpty) {
      _categoriesController.loadCategories();
    }
  }

  /// اختيار قسم رئيسي
  void selectMainCategory(String categoryId) {
    if (selectedMainCategoryId.value != categoryId) {
      selectedMainCategoryId.value = categoryId;
      selectedSubCategoryId.value = allFilterKey; // إعادة تعيين القسم الفرعي

      debugPrint('Selected main category: $categoryId');
      debugPrint('Available sub categories: ${subCategoriesForSelectedMain.length}');

      if (categoryId != allFilterKey) {
        final category = selectedMainCategory;
        if (category != null) {
          debugPrint('Category name: ${category.nameAr} (${category.nameEn})');
        }
      }
    }
  }

  /// اختيار قسم فرعي
  void selectSubCategory(String categoryId) {
    selectedSubCategoryId.value = categoryId;
    debugPrint('Selected sub category: $categoryId');

    if (categoryId != allFilterKey) {
      final subCategory = subCategoriesForSelectedMain.firstWhereOrNull((cat) => cat.id == categoryId);
      if (subCategory != null) {
        debugPrint('Sub category name: ${subCategory.nameAr} (${subCategory.nameEn})');
      }
    }
  }

  /// إعادة تعيين جميع الفلاتر
  void resetFilters() {
    selectedMainCategoryId.value = allFilterKey;
    selectedSubCategoryId.value = allFilterKey;
    debugPrint('All filters reset');
  }

  /// الحصول على مفتاح الفلترة للاستخدام في استعلامات قاعدة البيانات
  String getFilterKey() {
    if (selectedSubCategoryId.value != allFilterKey) {
      // إذا كان هناك قسم فرعي مختار، استخدم تنسيق: mainCategoryId_subCategoryId
      final subCategory = selectedSubCategory;
      final mainCategory = selectedMainCategory;
      if (subCategory != null && mainCategory != null) {
        final filterKey = '${mainCategory.id}_${subCategory.id}';
        debugPrint('📱 استخدام فلتر القسم الفرعي (نظام جديد): $filterKey');
        debugPrint('   القسم الرئيسي: ${mainCategory.nameAr} (${mainCategory.id})');
        debugPrint('   القسم الفرعي: ${subCategory.nameAr} (${subCategory.id})');
        return filterKey;
      }
    } else if (selectedMainCategoryId.value != allFilterKey) {
      // إذا كان هناك قسم رئيسي فقط، استخدم تنسيق: mainCategoryId_all
      final mainCategory = selectedMainCategory;
      if (mainCategory != null) {
        final filterKey = '${mainCategory.id}_all';
        debugPrint('📱 استخدام فلتر القسم الرئيسي (نظام جديد): $filterKey');
        debugPrint('   القسم الرئيسي: ${mainCategory.nameAr} (${mainCategory.id})');
        return filterKey;
      }
    }
    debugPrint('📱 استخدام فلتر الكل');
    return allFilterKey;
  }

  /// الحصول على جميع المفاتيح المحتملة للفلترة (للبحث الشامل)
  List<String> getPossibleFilterKeys() {
    final keys = <String>[];

    if (selectedSubCategoryId.value != allFilterKey) {
      final subCategory = selectedSubCategory;
      final mainCategory = selectedMainCategory;
      if (subCategory != null && mainCategory != null) {
        // إضافة مفاتيح مختلفة محتملة
        keys.addAll([
          subCategory.nameEn,
          subCategory.nameAr,
          '${mainCategory.nameEn}_${subCategory.nameEn}',
          '${mainCategory.nameAr}_${subCategory.nameAr}',
        ]);
      }
    } else if (selectedMainCategoryId.value != allFilterKey) {
      final mainCategory = selectedMainCategory;
      if (mainCategory != null) {
        keys.addAll([
          mainCategory.nameEn,
          mainCategory.nameAr,
        ]);
      }
    }

    return keys;
  }

  /// الحصول على نص وصفي للفلتر المطبق حالياً
  String getFilterDescription() {
    if (selectedSubCategoryId.value != allFilterKey) {
      final subCategory = selectedSubCategory;
      final mainCategory = selectedMainCategory;
      return 'فلترة حسب: ${mainCategory?.nameAr} > ${subCategory?.nameAr}';
    } else if (selectedMainCategoryId.value != allFilterKey) {
      final mainCategory = selectedMainCategory;
      return 'فلترة حسب: ${mainCategory?.nameAr}';
    }
    return 'عرض جميع المنتجات';
  }

  /// التحقق من وجود فلتر مطبق
  bool get hasActiveFilter =>
      selectedMainCategoryId.value != allFilterKey ||
      selectedSubCategoryId.value != allFilterKey;

  /// تحديث قائمة الأقسام
  Future<void> refreshCategories() async {
    await _categoriesController.loadCategories();
  }

  /// طباعة معلومات التشخيص
  void printDebugInfo() {
    debugPrint('=== Enhanced Category Filter Debug Info ===');
    debugPrint('Main categories count: ${mainCategories.length}');
    debugPrint('All categories count: ${allCategories.length}');
    debugPrint('Selected main category ID: ${selectedMainCategoryId.value}');
    debugPrint('Selected sub category ID: ${selectedSubCategoryId.value}');
    debugPrint('Filter key: ${getFilterKey()}');
    debugPrint('Has active filter: $hasActiveFilter');
    debugPrint('Filter description: ${getFilterDescription()}');

    if (mainCategories.isNotEmpty) {
      debugPrint('Available main categories:');
      for (final cat in mainCategories) {
        debugPrint('  - ${cat.nameAr} (${cat.nameEn}) [${cat.id}]');
      }
    }
    debugPrint('==========================================');
  }
}