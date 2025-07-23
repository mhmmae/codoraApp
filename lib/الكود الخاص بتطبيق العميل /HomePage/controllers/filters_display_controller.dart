import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../Model/company_model.dart';
import '../../../XXX/xxx_firebase.dart';
import 'enhanced_category_filter_controller.dart';

/// كونترولر لعرض جميع الفلاتر المتاحة بشكل مسطح
class FiltersDisplayController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // حالة التحميل
  final RxBool isLoading = false.obs;
  final RxBool isVisible = false.obs;

  // قوائم الفلاتر المختلطة
  final RxList<FilterItemModel> allFilters = <FilterItemModel>[].obs;

  // المنتجات العشوائية لفلتر مختار
  final RxList<Map<String, dynamic>> randomProducts =
      <Map<String, dynamic>>[].obs;
  final Rx<FilterItemModel?> selectedRandomFilter = Rx<FilterItemModel?>(null);
  final RxString selectedFilterTitle = ''.obs;
  final RxBool isLoadingProducts = false.obs;

  // cache لنتائج عداد المنتجات لتحسين الأداء
  final Map<String, int> _productCountCache = {};

  // وقت انتهاء صلاحية الـ cache (5 دقائق)
  final Duration _cacheExpiry = Duration(minutes: 5);
  DateTime? _lastCacheUpdate;

  @override
  void onInit() {
    super.onInit();
    debugPrint(
      '🎯 FiltersDisplayController.onInit() - تم تشغيل الـ controller',
    );
    loadAllFilters();
  }

  /// تحميل جميع الفلاتر وخلطها عشوائياً
  Future<void> loadAllFilters() async {
    try {
      debugPrint('🚀 FiltersDisplayController - بدء تحميل الفلاتر...');
      debugPrint('🚀 Thread: ${DateTime.now()}');
      isLoading.value = true;
      List<FilterItemModel> filters = [];

      // مسح البيانات السابقة
      allFilters.clear();
      randomProducts.clear();
      selectedRandomFilter.value = null;
      debugPrint('🧹 تم مسح البيانات السابقة');

      // تحميل جميع الفلاتر بالتوازي لتحسين الأداء
      await Future.wait([
        _loadAllCategories(filters),
        _loadBrandFilters(filters),
      ]);

      debugPrint('📊 عدد الفلاتر المحملة: ${filters.length}');

      // حساب عدد المنتجات بالتوازي
      await _calculateProductCountsConcurrently(filters);

      // إزالة الفلاتر التي لا تحتوي على منتجات
      final filtersBeforeRemoval = filters.length;
      filters.removeWhere(
        (filter) => filter.productCount == null || filter.productCount! <= 0,
      );
      final filtersAfterRemoval = filters.length;

      debugPrint(
        '🗑️ تمت إزالة ${filtersBeforeRemoval - filtersAfterRemoval} فلتر فارغ',
      );
      debugPrint('📊 الفلاتر المتبقية: $filtersAfterRemoval فلتر');

      // طباعة تفاصيل الفلاتر المتبقية
      for (int i = 0; i < filters.length && i < 5; i++) {
        final filter = filters[i];
        debugPrint(
          '📋 فلتر ${i + 1}: ${filter.title} (${filter.type}) - ${filter.productCount} منتج',
        );
      }

      // خلط الفلاتر عشوائياً
      filters.shuffle();

      allFilters.assignAll(filters);

      // تحميل منتجات عشوائية من فلتر مختار
      if (filters.isNotEmpty) {
        debugPrint('📊 بدء تحميل المنتجات العشوائية...');
        await _loadRandomProducts();
        debugPrint(
          '📊 انتهاء تحميل المنتجات العشوائية. العدد: ${randomProducts.length}',
        );
      } else {
        debugPrint('❌ لا توجد فلاتر لتحميل منتجات عشوائية منها');
      }

      debugPrint(
        '✅ تم تحميل ${allFilters.length} فلتر إجمالي (بدون الفلاتر الفارغة)',
      );
    } catch (e) {
      debugPrint('❌ خطأ في تحميل الفلاتر: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// تحميل الأقسام الرئيسية والفرعية
  Future<void> _loadAllCategories(List<FilterItemModel> filters) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _firestore
              .collection('categories')
              .where('isActive', isEqualTo: true)
              .get();

      for (var doc in snapshot.docs) {
        final category = CategoryModel.fromSnapshot(doc);

        if (category.isMainCategory) {
          // إضافة القسم الرئيسي
          filters.add(
            FilterItemModel(
              id: category.id,
              title: category.nameAr,
              subtitle: 'قسم رئيسي',
              imageUrl: category.imageUrl,
              type: FilterType.mainCategory,
              filterKey: 'main_${category.id}',
            ),
          );
        } else {
          // إضافة القسم الفرعي
          filters.add(
            FilterItemModel(
              id: category.id,
              title: category.nameAr,
              subtitle: 'قسم فرعي',
              imageUrl: category.imageUrl,
              type: FilterType.subCategory,
              filterKey: 'sub_${category.id}',
              parentId: category.parentId,
            ),
          );
        }
      }

      debugPrint('✅ تم تحميل ${snapshot.docs.length} قسم (رئيسي وفرعي)');
    } catch (e) {
      debugPrint('❌ خطأ في تحميل الأقسام: $e');
    }
  }

  /// تحميل فلاتر البراند (الشركات والمنتجات)
  Future<void> _loadBrandFilters(List<FilterItemModel> filters) async {
    try {
      // تحميل الشركات
      final QuerySnapshot companiesSnapshot =
          await _firestore
              .collection('brand_companies')
              .where('isActive', isEqualTo: true)
              .get();

      for (var companyDoc in companiesSnapshot.docs) {
        final company = CompanyModel.fromFirestore(companyDoc);

        // إضافة الشركة كفلتر
        filters.add(
          FilterItemModel(
            id: company.id,
            title: company.nameAr,
            subtitle: 'شركة مصنعة',
            imageUrl: company.logoUrl,
            type: FilterType.company,
            filterKey: 'original_company_${company.id}',
          ),
        );

        // تحميل منتجات الشركة
        final QuerySnapshot productsSnapshot =
            await _firestore
                .collection('company_products')
                .where('companyId', isEqualTo: company.id)
                .where('isActive', isEqualTo: true)
                .get();

        for (var productDoc in productsSnapshot.docs) {
          final product = CompanyProductModel.fromFirestore(productDoc);

          filters.add(
            FilterItemModel(
              id: product.id,
              title: product.nameAr,
              subtitle: 'منتج ${company.nameAr}',
              imageUrl: product.imageUrl,
              type: FilterType.product,
              filterKey: 'original_product_${product.id}',
              parentId: company.id,
              parentName: company.nameAr,
            ),
          );
        }
      }

      debugPrint(
        '✅ تم تحميل ${companiesSnapshot.docs.length} شركة مع منتجاتها',
      );
    } catch (e) {
      debugPrint('❌ خطأ في تحميل فلاتر البراند: $e');
    }
  }

  /// حساب عدد المنتجات لكل فلتر بشكل متوازي (محسن للأداء)
  Future<void> _calculateProductCountsConcurrently(
    List<FilterItemModel> filters,
  ) async {
    try {
      // تقسيم المهام إلى مجموعات للمعالجة المتوازية
      const batchSize = 10; // معالجة 10 فلاتر في المرة الواحدة

      for (int i = 0; i < filters.length; i += batchSize) {
        final endIndex =
            (i + batchSize < filters.length) ? i + batchSize : filters.length;
        final batch = filters.sublist(i, endIndex);

        // معالجة المجموعة الحالية بالتوازي
        final futures = batch.asMap().entries.map((entry) async {
          final filter = entry.value;

          int productCount = 0;
          switch (filter.type) {
            case FilterType.mainCategory:
              productCount = await _countProductsForMainCategory(filter.id);
              break;
            case FilterType.subCategory:
              productCount = await _countProductsForSubCategory(filter.id);
              break;
            case FilterType.company:
              productCount = await _countProductsForCompany(filter.id);
              break;
            case FilterType.product:
              productCount = await _countProductsForProduct(filter.id);
              break;
          }

          // تحديث الفلتر مع العدد
          return FilterItemModel(
            id: filter.id,
            title: filter.title,
            subtitle: filter.subtitle,
            imageUrl: filter.imageUrl,
            type: filter.type,
            filterKey: filter.filterKey,
            parentId: filter.parentId,
            parentName: filter.parentName,
            productCount: productCount,
          );
        });

        // انتظار انتهاء المجموعة الحالية وتحديث القائمة
        final updatedBatch = await Future.wait(futures);
        for (int j = 0; j < updatedBatch.length; j++) {
          filters[i + j] = updatedBatch[j];
        }

        // إضافة تأخير قصير لتجنب الضغط على قاعدة البيانات
        if (i + batchSize < filters.length) {
          await Future.delayed(Duration(milliseconds: 50));
        }
      }

      debugPrint('✅ تم حساب عدد المنتجات لجميع الفلاتر بشكل متوازي');
    } catch (e) {
      debugPrint('❌ خطأ في حساب عدد المنتجات المتوازي: $e');
    }
  }

  /// حساب عدد المنتجات للقسم الرئيسي
  Future<int> _countProductsForMainCategory(String categoryId) async {
    final cacheKey = 'main_$categoryId';

    // التحقق من وجود النتيجة في الـ cache
    if (_isCacheValid() && _productCountCache.containsKey(cacheKey)) {
      return _productCountCache[cacheKey]!;
    }

    try {
      final result =
          await _firestore
              .collection(FirebaseX.itemsCollection)
              .where('appName', isEqualTo: FirebaseX.appName)
              .where('mainCategoryId', isEqualTo: categoryId)
              .count()
              .get();

      final count = result.count ?? 0;
      _productCountCache[cacheKey] = count; // حفظ في الـ cache
      _updateCacheTimestamp();

      return count;
    } catch (e) {
      debugPrint('خطأ في حساب منتجات القسم الرئيسي $categoryId: $e');
      return 0;
    }
  }

  /// حساب عدد المنتجات للقسم الفرعي
  Future<int> _countProductsForSubCategory(String categoryId) async {
    final cacheKey = 'sub_$categoryId';

    if (_isCacheValid() && _productCountCache.containsKey(cacheKey)) {
      return _productCountCache[cacheKey]!;
    }

    try {
      final result =
          await _firestore
              .collection(FirebaseX.itemsCollection)
              .where('appName', isEqualTo: FirebaseX.appName)
              .where('subCategoryId', isEqualTo: categoryId)
              .count()
              .get();

      final count = result.count ?? 0;
      _productCountCache[cacheKey] = count;
      _updateCacheTimestamp();

      return count;
    } catch (e) {
      debugPrint('خطأ في حساب منتجات القسم الفرعي $categoryId: $e');
      return 0;
    }
  }

  /// حساب عدد المنتجات للشركة
  Future<int> _countProductsForCompany(String companyId) async {
    final cacheKey = 'company_$companyId';

    if (_isCacheValid() && _productCountCache.containsKey(cacheKey)) {
      return _productCountCache[cacheKey]!;
    }

    try {
      final result =
          await _firestore
              .collection(FirebaseX.itemsCollection)
              .where('appName', isEqualTo: FirebaseX.appName)
              .where('itemCondition', isEqualTo: 'original')
              .where('originalCompanyId', isEqualTo: companyId)
              .count()
              .get();

      final count = result.count ?? 0;
      _productCountCache[cacheKey] = count;
      _updateCacheTimestamp();

      return count;
    } catch (e) {
      debugPrint('خطأ في حساب منتجات الشركة $companyId: $e');
      return 0;
    }
  }

  /// حساب عدد المنتجات للمنتج الأصلي
  Future<int> _countProductsForProduct(String productId) async {
    final cacheKey = 'product_$productId';

    if (_isCacheValid() && _productCountCache.containsKey(cacheKey)) {
      return _productCountCache[cacheKey]!;
    }

    try {
      final result =
          await _firestore
              .collection(FirebaseX.itemsCollection)
              .where('appName', isEqualTo: FirebaseX.appName)
              .where('itemCondition', isEqualTo: 'original')
              .where('originalProductId', isEqualTo: productId)
              .count()
              .get();

      final count = result.count ?? 0;
      _productCountCache[cacheKey] = count;
      _updateCacheTimestamp();

      return count;
    } catch (e) {
      debugPrint('خطأ في حساب منتجات المنتج $productId: $e');
      return 0;
    }
  }

  /// التحقق من صلاحية الـ cache
  bool _isCacheValid() {
    if (_lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!) < _cacheExpiry;
  }

  /// تحديث وقت آخر تحديث للـ cache
  /// تحميل منتجات عشوائية من فلاتر عشوائية متعددة (1 من كل 7 فلاتر)
  Future<void> _loadRandomProducts() async {
    try {
      debugPrint('📊 _loadRandomProducts - بدء التنفيذ');
      debugPrint('📊 عدد الفلاتر المتاحة: ${allFilters.length}');

      if (allFilters.isEmpty) {
        debugPrint('❌ allFilters فارغة - إنهاء التنفيذ');
        return;
      }

      // تصفية الفلاتر للحصول على الفلاتر التي لديها منتجات فقط
      final filtersWithProducts =
          allFilters
              .where(
                (filter) =>
                    filter.productCount != null && filter.productCount! > 0,
              )
              .toList();

      debugPrint(
        '📊 عدد الفلاتر التي لديها منتجات: ${filtersWithProducts.length}',
      );

      if (filtersWithProducts.isEmpty) {
        debugPrint('❌ لا توجد فلاتر بها منتجات - إنهاء التنفيذ');
        return;
      }

      // إعطاء أولوية للفئات الرئيسية والفرعية
      List<FilterItemModel> priorityFilters =
          filtersWithProducts
              .where(
                (filter) =>
                    filter.type == FilterType.mainCategory ||
                    filter.type == FilterType.subCategory,
              )
              .toList();

      // إذا لم توجد فئات، استخدم جميع الفلاتر المتاحة
      final availableFilters =
          priorityFilters.isNotEmpty ? priorityFilters : filtersWithProducts;

      debugPrint('📊 عدد الفلاتر ذات الأولوية: ${availableFilters.length}');

      // حساب عدد الفلاتر المختارة (1 من كل 7)
      final totalFilters = availableFilters.length;
      final numberOfSelectedFilters = (totalFilters / 7).ceil();

      debugPrint(
        '📊 عدد الفلاتر المختارة: $numberOfSelectedFilters من أصل $totalFilters',
      );

      if (numberOfSelectedFilters == 0) {
        debugPrint('❌ لا يوجد فلاتر مختارة - إنهاء التنفيذ');
        return;
      }

      // اختيار فلاتر عشوائية
      final random = Random();
      final selectedFilters = <FilterItemModel>[];
      final usedIndices = <int>{};

      for (int i = 0; i < numberOfSelectedFilters; i++) {
        int randomIndex;
        do {
          randomIndex = random.nextInt(availableFilters.length);
        } while (usedIndices.contains(randomIndex));

        usedIndices.add(randomIndex);
        selectedFilters.add(availableFilters[randomIndex]);
      }

      debugPrint('📊 تم اختيار ${selectedFilters.length} فلتر عشوائي');

      // اختيار فلتر رئيسي واحد لعرض اسمه
      selectedRandomFilter.value = selectedFilters.first;

      // جمع منتجات من جميع الفلاتر المختارة
      final allRandomProducts = <Map<String, dynamic>>[];

      for (final filter in selectedFilters) {
        debugPrint('📊 تحميل منتجات من الفلتر: ${filter.title}');

        final products = await _loadProductsFromFilter(
          filter,
          3,
        ); // 3 منتجات من كل فلتر
        allRandomProducts.addAll(products);

        debugPrint('📊 تم تحميل ${products.length} منتج من ${filter.title}');
      }

      // خلط المنتجات عشوائياً
      allRandomProducts.shuffle();

      // تحديد عدد أقصى من المنتجات للعرض
      const maxProductsToShow = 10;
      final productsToShow =
          allRandomProducts.length > maxProductsToShow
              ? allRandomProducts.take(maxProductsToShow).toList()
              : allRandomProducts;

      randomProducts.value = productsToShow;

      debugPrint(
        '✅ تم تحميل ${randomProducts.length} منتج عشوائي من ${selectedFilters.length} فلتر',
      );

      // طباعة أسماء المنتجات للتأكد
      for (int i = 0; i < randomProducts.length && i < 3; i++) {
        debugPrint(
          '� منتج ${i + 1}: ${randomProducts[i]['name']} - السعر: ${randomProducts[i]['price']}',
        );
      }

      debugPrint('🎯 انتهاء _loadRandomProducts بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في تحميل المنتجات العشوائية: $e');
      debugPrint('❌ تفاصيل الخطأ: ${e.toString()}');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      randomProducts.value = [];
    }
  }

  /// تحميل منتجات من فلتر محدد
  Future<List<Map<String, dynamic>>> _loadProductsFromFilter(
    FilterItemModel filter,
    int limit,
  ) async {
    try {
      QuerySnapshot querySnapshot;

      // تحديد نوع الاستعلام حسب نوع الفلتر مع أسماء الحقول الصحيحة
      switch (filter.type) {
        case FilterType.mainCategory:
          querySnapshot =
              await _firestore
                  .collection('Item')
                  .where('appName', isEqualTo: 'codora')
                  .where('mainCategoryId', isEqualTo: filter.id)
                  .limit(limit)
                  .get();
          break;

        case FilterType.subCategory:
          querySnapshot =
              await _firestore
                  .collection('Item')
                  .where('appName', isEqualTo: 'codora')
                  .where('subCategoryId', isEqualTo: filter.id)
                  .limit(limit)
                  .get();
          break;

        case FilterType.company:
          // جرب البحث بنوع String أولاً
          querySnapshot =
              await _firestore
                  .collection('Item')
                  .where('appName', isEqualTo: 'codora')
                  .where('itemCondition', isEqualTo: 'original')
                  .where('originalCompanyId', isEqualTo: filter.id)
                  .limit(limit)
                  .get();

          // إذا لم نجد نتائج، جرب التحويل إلى int
          if (querySnapshot.docs.isEmpty) {
            final companyIdInt = int.tryParse(filter.id);
            if (companyIdInt != null) {
              querySnapshot =
                  await _firestore
                      .collection('Item')
                      .where('appName', isEqualTo: 'codora')
                      .where('itemCondition', isEqualTo: 'original')
                      .where('originalCompanyId', isEqualTo: companyIdInt)
                      .limit(limit)
                      .get();
            }
          }
          break;

        default:
          debugPrint('❌ نوع فلتر غير مدعوم: ${filter.type}');
          return [];
      }

      if (querySnapshot.docs.isEmpty) {
        debugPrint('❌ لم يتم العثور على منتجات للفلتر: ${filter.title}');
        return [];
      }

      // تحويل النتائج إلى قائمة منتجات
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['nameOfItem'] ?? data['productName'] ?? '',
          'price': data['suggestedRetailPrice'] ?? data['price'] ?? 0.0,
          'image': data['url'] ?? data['image'] ?? '',
          'company': data['originalCompanyId'] ?? '',
          'category': data['mainCategoryNameAr'] ?? '',
          'subcategory': data['subCategoryNameAr'] ?? '',
          'description': data['descriptionOfItem'] ?? '',
          'barcode': data['mainProductBarcode'] ?? '',
          'filterSource': filter.title, // إضافة معلومة عن مصدر الفلتر
        };
      }).toList();
    } catch (e) {
      debugPrint('❌ خطأ في تحميل منتجات الفلتر ${filter.title}: $e');
      return [];
    }
  }

  void _updateCacheTimestamp() {
    _lastCacheUpdate = DateTime.now();
  }

  /// مسح الـ cache
  void _clearCache() {
    _productCountCache.clear();
    _lastCacheUpdate = null;
  }

  /// إظهار/إخفاء عرض الفلاتر
  void toggleFiltersVisibility() {
    isVisible.value = !isVisible.value;
    debugPrint('🔄 تبديل عرض الفلاتر: ${isVisible.value ? 'مرئي' : 'مخفي'}');

    if (isVisible.value && allFilters.isEmpty) {
      loadAllFilters();
    }
  }

  /// إخفاء عرض الفلاتر
  void hideFilters() {
    isVisible.value = false;
    debugPrint('🔄 إخفاء عرض الفلاتر');
  }

  /// إعادة تحميل الفلاتر
  Future<void> refreshFilters() async {
    _clearCache(); // مسح الـ cache قبل إعادة التحميل
    await loadAllFilters();
  }

  /// البحث في الفلاتر
  List<FilterItemModel> searchFilters(String query) {
    if (query.isEmpty) return allFilters;

    return allFilters
        .where(
          (filter) =>
              filter.title.toLowerCase().contains(query.toLowerCase()) ||
              filter.subtitle.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  /// التصفية حسب نوع الفلتر
  List<FilterItemModel> getFiltersByType(FilterType type) {
    return allFilters.where((filter) => filter.type == type).toList();
  }
}

/// نموذج عنصر الفلتر
class FilterItemModel {
  final String id;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final FilterType type;
  final String filterKey;
  final String? parentId;
  final String? parentName;
  final int? productCount; // عدد المنتجات (اختياري)

  FilterItemModel({
    required this.id,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    required this.type,
    required this.filterKey,
    this.parentId,
    this.parentName,
    this.productCount,
  });

  @override
  String toString() {
    return 'FilterItemModel(id: $id, title: $title, type: $type, filterKey: $filterKey, productCount: $productCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FilterItemModel && other.id == id && other.type == type;
  }

  @override
  int get hashCode {
    return id.hashCode ^ type.hashCode;
  }
}

/// أنواع الفلاتر
enum FilterType {
  mainCategory, // قسم رئيسي
  subCategory, // قسم فرعي
  company, // شركة مصنعة
  product, // منتج من شركة
}

/// إضافة extension للحصول على وصف نوع الفلتر
extension FilterTypeExtension on FilterType {
  String get displayName {
    switch (this) {
      case FilterType.mainCategory:
        return 'قسم رئيسي';
      case FilterType.subCategory:
        return 'قسم فرعي';
      case FilterType.company:
        return 'شركة مصنعة';
      case FilterType.product:
        return 'منتج أصلي';
    }
  }

  IconData get icon {
    switch (this) {
      case FilterType.mainCategory:
        return Icons.category_rounded;
      case FilterType.subCategory:
        return Icons.category_outlined;
      case FilterType.company:
        return Icons.business_outlined;
      case FilterType.product:
        return Icons.inventory_2_outlined;
    }
  }

  Color get color {
    switch (this) {
      case FilterType.mainCategory:
        return Colors.purple;
      case FilterType.subCategory:
        return Colors.blue;
      case FilterType.company:
        return Colors.green;
      case FilterType.product:
        return Colors.orange;
    }
  }
}
