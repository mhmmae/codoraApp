import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../Model/model_item.dart';
import '../../../Model/model_offer_item.dart';
import '../widgets/advanced_filter_widget.dart';

/// Controller شامل لإدارة المنتجات مع الفلترة المتقدمة
/// يدعم المنتجات الأصلية والتجارية والعروض
class ProductsFilterController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // حالات التحميل
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  
  // قوائم المنتجات
  final RxList<ItemModel> allProducts = <ItemModel>[].obs;
  final RxList<ItemModel> filteredProducts = <ItemModel>[].obs;
  final RxList<OfferModel> allOffers = <OfferModel>[].obs;
  final RxList<OfferModel> filteredOffers = <OfferModel>[].obs;
  
  // معايير الفلترة الحالية
  final Rx<FilterCriteria> currentFilter = FilterCriteria().obs;
  
  // للبحث
  final RxString searchQuery = ''.obs;
  
  // للترقيم (Pagination)
  DocumentSnapshot? lastDocument;
  final int itemsPerPage = 20;
  final RxBool hasMoreData = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadAllProducts();
    
    // مراقبة تغييرات البحث
    debounce(searchQuery, (_) => _applyFilters(), time: const Duration(milliseconds: 500));
  }

  /// تحميل جميع المنتجات (أصلية وتجارية)
  Future<void> loadAllProducts({bool refresh = false}) async {
    try {
      if (refresh) {
        isLoading.value = true;
        lastDocument = null;
        hasMoreData.value = true;
        allProducts.clear();
        filteredProducts.clear();
      } else if (isLoading.value || !hasMoreData.value) {
        return;
      }

      if (!refresh && allProducts.isNotEmpty) {
        isLoadingMore.value = true;
      } else {
        isLoading.value = true;
      }

      // إنشاء الاستعلام الأساسي
      Query query = _firestore
          .collection('items')
          .where('appName', isEqualTo: 'codora') // أو استخدم FirebaseX.appName
          .orderBy('timestamp', descending: true)
          .limit(itemsPerPage);

      // إضافة pagination إذا لم يكن refresh
      if (!refresh && lastDocument != null) {
        query = query.startAfterDocument(lastDocument!);
      }

      final QuerySnapshot snapshot = await query.get();
      
      if (snapshot.docs.isNotEmpty) {
        lastDocument = snapshot.docs.last;
        
        final List<ItemModel> newProducts = snapshot.docs
            .map((doc) => ItemModel.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList();
        
        if (refresh) {
          allProducts.value = newProducts;
        } else {
          allProducts.addAll(newProducts);
        }
        
        // التحقق من وجود المزيد من البيانات
        hasMoreData.value = snapshot.docs.length == itemsPerPage;
        
        debugPrint('✅ تم تحميل ${newProducts.length} منتج جديد');
      } else {
        hasMoreData.value = false;
        debugPrint('📝 لا توجد منتجات إضافية');
      }
      
      // تطبيق الفلترة
      _applyFilters();
      
    } catch (e) {
      debugPrint('❌ خطأ في تحميل المنتجات: $e');
      Get.snackbar(
        'خطأ', 
        'فشل في تحميل المنتجات', 
        snackPosition: SnackPosition.BOTTOM
      );
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  /// تحميل العروض
  Future<void> loadOffers() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('offers')
          .where('appName', isEqualTo: 'codora')
          .orderBy('timestamp', descending: true)
          .get();

      final List<OfferModel> offers = snapshot.docs
          .map((doc) => OfferModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      allOffers.value = offers;
      _applyOffersFilter();
      
      debugPrint('✅ تم تحميل ${offers.length} عرض');
    } catch (e) {
      debugPrint('❌ خطأ في تحميل العروض: $e');
    }
  }

  /// تطبيق الفلترة
  void applyFilter(FilterCriteria filter) {
    currentFilter.value = filter;
    _applyFilters();
    
    // تحميل العروض إذا كان الفلتر يتضمن العروض
    if (filter.hasOffers && allOffers.isEmpty) {
      loadOffers();
    }
  }

  /// البحث في المنتجات
  void searchProducts(String query) {
    searchQuery.value = query;
    // البحث سيتم تطبيقه تلقائياً عبر debounce في onInit
  }

  /// تطبيق الفلترة الداخلية
  void _applyFilters() {
    List<ItemModel> filtered = List<ItemModel>.from(allProducts);
    
    debugPrint('🔍 بدء تطبيق الفلترة على ${allProducts.length} منتج');
    if (allProducts.isNotEmpty) {
      debugPrint('عينة من المنتجات:');
      for (int i = 0; i < (allProducts.length > 3 ? 3 : allProducts.length); i++) {
        final product = allProducts[i];
        debugPrint('  - ${product.name}: mainCategoryId=${product.mainCategoryId}, subCategoryId=${product.subCategoryId}');
        debugPrint('    mainCategoryNameAr=${product.mainCategoryNameAr}, subCategoryNameAr=${product.subCategoryNameAr}');
      }
    }
    
    // فلترة حسب البحث النصي
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      filtered = filtered.where((product) {
        return product.name.toLowerCase().contains(query) ||
               (product.description?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
    
    // فلترة حسب القسم الرئيسي
    if (currentFilter.value.mainCategoryId != null && 
        currentFilter.value.mainCategoryId!.isNotEmpty) {
      final beforeCount = filtered.length;
      filtered = filtered.where((product) {
        final hasId = product.mainCategoryId == currentFilter.value.mainCategoryId;
        if (!hasId) {
          debugPrint('❌ المنتج ${product.name} لا يطابق القسم الرئيسي: منتج=${product.mainCategoryId}, فلتر=${currentFilter.value.mainCategoryId}');
        }
        return hasId;
      }).toList();
      debugPrint('🔍 فلترة القسم الرئيسي: $beforeCount → ${filtered.length}');
    }
    
    // فلترة حسب القسم الفرعي
    if (currentFilter.value.subCategoryId != null && 
        currentFilter.value.subCategoryId!.isNotEmpty) {
      final beforeCount = filtered.length;
      filtered = filtered.where((product) {
        final hasId = product.subCategoryId == currentFilter.value.subCategoryId;
        if (!hasId) {
          debugPrint('❌ المنتج ${product.name} لا يطابق القسم الفرعي: منتج=${product.subCategoryId}, فلتر=${currentFilter.value.subCategoryId}');
        }
        return hasId;
      }).toList();
      debugPrint('🔍 فلترة القسم الفرعي: $beforeCount → ${filtered.length}');
    }
    
    // فلترة حسب نوع المنتج (أصلي/تجاري)
    if (currentFilter.value.productType != null && 
        currentFilter.value.productType!.isNotEmpty) {
      filtered = filtered.where((product) {
        return product.itemCondition == currentFilter.value.productType;
      }).toList();
    }
    
    // فلترة حسب السعر
    if (currentFilter.value.minPrice != null) {
      filtered = filtered.where((product) {
        return product.price >= currentFilter.value.minPrice!;
      }).toList();
    }
    
    if (currentFilter.value.maxPrice != null) {
      filtered = filtered.where((product) {
        return product.price <= currentFilter.value.maxPrice!;
      }).toList();
    }
    
    filteredProducts.value = filtered;
    debugPrint('🔍 تم تطبيق الفلترة: ${filtered.length} منتج من أصل ${allProducts.length}');
    debugPrint('📊 معايير الفلترة المطبقة:');
    debugPrint('   - القسم الرئيسي: ${currentFilter.value.mainCategoryId ?? "غير محدد"}');
    debugPrint('   - القسم الفرعي: ${currentFilter.value.subCategoryId ?? "غير محدد"}');
    debugPrint('   - نوع المنتج: ${currentFilter.value.productType ?? "غير محدد"}');
    debugPrint('   - البحث النصي: ${searchQuery.value.isEmpty ? "غير موجود" : searchQuery.value}');
    debugPrint('   - العروض: ${currentFilter.value.hasOffers ? "نعم" : "لا"}');
    if (currentFilter.value.minPrice != null || currentFilter.value.maxPrice != null) {
      debugPrint('   - نطاق السعر: ${currentFilter.value.minPrice ?? "لا حد أدنى"} - ${currentFilter.value.maxPrice ?? "لا حد أعلى"}');
    }
    debugPrint('═══════════════════════════════════════════════════');
  }

  /// تطبيق فلترة العروض
  void _applyOffersFilter() {
    List<OfferModel> filtered = List<OfferModel>.from(allOffers);
    
    // تطبيق نفس منطق الفلترة للعروض
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      filtered = filtered.where((offer) {
        return offer.name.toLowerCase().contains(query) ||
               (offer.description?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
    
    filteredOffers.value = filtered;
  }

  /// الحصول على المنتجات الأصلية فقط
  List<ItemModel> get originalProducts {
    return filteredProducts.where((product) => 
        product.itemCondition == 'original').toList();
  }

  /// الحصول على المنتجات التجارية فقط
  List<ItemModel> get commercialProducts {
    return filteredProducts.where((product) => 
        product.itemCondition == 'commercial').toList();
  }

  /// الحصول على إحصائيات الفلترة
  Map<String, int> get filterStats {
    return {
      'total': allProducts.length,
      'filtered': filteredProducts.length,
      'original': originalProducts.length,
      'commercial': commercialProducts.length,
      'offers': filteredOffers.length,
    };
  }

  /// إعادة تعيين الفلترة
  void clearFilters() {
    currentFilter.value = FilterCriteria();
    searchQuery.value = '';
    _applyFilters();
  }

  /// تحديث المنتجات
  Future<void> refreshProducts() async {
    await loadAllProducts(refresh: true);
  }

  /// تحميل المزيد من المنتجات
  Future<void> loadMoreProducts() async {
    if (!hasMoreData.value || isLoadingMore.value) return;
    await loadAllProducts();
  }

  /// البحث المتقدم بالفئات المحسن
  Future<void> searchByCategory(String? mainCategoryId, String? subCategoryId) async {
    try {
      isLoading.value = true;
      
      debugPrint('🔍 بدء البحث بالفئة:');
      debugPrint('   - القسم الرئيسي: $mainCategoryId');
      debugPrint('   - القسم الفرعي: $subCategoryId');
      
      // إذا لم يتم تحديد أي فئة، تحميل جميع المنتجات
      if ((mainCategoryId == null || mainCategoryId.isEmpty) && 
          (subCategoryId == null || subCategoryId.isEmpty)) {
        await loadAllProducts(refresh: true);
        return;
      }
      
      Query query = _firestore.collection('ItemsData');
      
      // فلترة حسب القسم الفرعي أولاً (لأنه أكثر تحديداً)
      if (subCategoryId != null && subCategoryId.isNotEmpty) {
        query = query.where('subCategoryId', isEqualTo: subCategoryId);
      } else if (mainCategoryId != null && mainCategoryId.isNotEmpty) {
        query = query.where('mainCategoryId', isEqualTo: mainCategoryId);
      }
      
      query = query.orderBy('timestamp', descending: true).limit(itemsPerPage);
      
      final QuerySnapshot snapshot = await query.get();
      
      final List<ItemModel> categoryProducts = [];
      
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final product = ItemModel.fromMap(data, doc.id);
          categoryProducts.add(product);
        } catch (e) {
          debugPrint('❌ خطأ في تحويل المنتج ${doc.id}: $e');
        }
      }
      
      allProducts.assignAll(categoryProducts);
      _applyFilters();
      
      debugPrint('✅ تم العثور على ${categoryProducts.length} منتج في الفئة المحددة');
      
    } catch (e) {
      debugPrint('❌ خطأ في البحث بالفئة: $e');
      // في حالة الخطأ، تحميل جميع المنتجات
      await loadAllProducts(refresh: true);
    } finally {
      isLoading.value = false;
    }
  }

  /// تطبيق فلتر الأقسام المحسن
  void applyEnhancedCategoryFilter({
    String? mainCategoryId,
    String? subCategoryId,
    String? mainCategoryName,
    String? subCategoryName,
  }) {
    // تحديث معايير الفلترة
    currentFilter.value = currentFilter.value.copyWith(
      mainCategoryId: mainCategoryId,
      subCategoryId: subCategoryId,
      clearMainCategory: mainCategoryId == null || mainCategoryId.isEmpty,
      clearSubCategory: subCategoryId == null || subCategoryId.isEmpty,
    );
    
    debugPrint('🔧 تطبيق فلتر الأقسام المحسن:');
    debugPrint('   - القسم الرئيسي: $mainCategoryName ($mainCategoryId)');
    debugPrint('   - القسم الفرعي: $subCategoryName ($subCategoryId)');
    
    // إعادة تطبيق الفلترة
    _applyFilters();
  }

  @override
  void onClose() {
    allProducts.clear();
    filteredProducts.clear();
    allOffers.clear();
    filteredOffers.clear();
    super.onClose();
  }
} 