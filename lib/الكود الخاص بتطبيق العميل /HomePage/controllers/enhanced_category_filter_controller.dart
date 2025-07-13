import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Controller للفلترة المتقدمة للأقسام في تطبيق العميل
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

  @override
  void onInit() {
    super.onInit();
    loadCategories();
  }

  /// تحميل جميع الأقسام من Firebase
  Future<void> loadCategories() async {
    try {
      isLoading.value = true;
      
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .orderBy('order', descending: false)
          .get();

      final List<CategoryModel> categories = snapshot.docs
          .map((doc) => CategoryModel.fromSnapshot(doc))
          .toList();

      allCategories.assignAll(categories);
      
      // فصل الأقسام الرئيسية والفرعية
      final List<CategoryModel> mainCats = [];
      
      for (var category in categories) {
        if (category.isMainCategory) {
          mainCats.add(category);
        }
      }
      
      mainCategories.assignAll(mainCats);
      
      debugPrint('✅ تم تحميل ${allCategories.length} قسم إجمالي، ${mainCategories.length} قسم رئيسي');
      
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
      final List<CategoryModel> subCats = allCategories
          .where((cat) => cat.parentId == mainCategoryId && !cat.isMainCategory)
          .toList();

      subCategories.assignAll(subCats);
          
      debugPrint('✅ تم تحميل ${subCategories.length} قسم فرعي للقسم $mainCategoryId');
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
    debugPrint("   - selectedMainCategoryId: '${selectedMainCategoryId.value}'");
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

  factory CategoryModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
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
      isMainCategory: data['parentId'] == null,  // إذا لم يكن له والد فهو رئيسي
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
    return other is CategoryModel &&
        other.id == id &&
        other.nameAr == nameAr;
  }

  @override
  int get hashCode {
    return id.hashCode ^ nameAr.hashCode;
  }
} 