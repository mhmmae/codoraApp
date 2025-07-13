import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../Model/company_model.dart';

/// كنترولر البحث من خلال البراند والشركات المصنعة
class BrandFilterController extends GetxController with GetSingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // حالة النظام
  final RxBool isBrandModeActive = false.obs;
  final RxBool isLoading = false.obs;
  
  // بيانات الشركات والمنتجات
  final RxList<CompanyModel> companies = <CompanyModel>[].obs;
  final RxList<CompanyProductModel> selectedCompanyProducts = <CompanyProductModel>[].obs;
  
  // الاختيارات الحالية
  final Rxn<CompanyModel> selectedCompany = Rxn<CompanyModel>();
  final Rxn<CompanyProductModel> selectedCompanyProduct = Rxn<CompanyProductModel>();
  
  // متغيرات لحفظ الاختيارات السابقة
  CompanyModel? _lastSelectedCompany;
  CompanyProductModel? _lastSelectedCompanyProduct;
  
  // كنترولرات الانيميشن
  late AnimationController animationController;
  late Animation<double> slideAnimation;
  late Animation<double> fadeAnimation;
  late Animation<double> scaleAnimation;
  
  @override
  void onInit() {
    super.onInit();
    _initAnimations();
    loadCompanies();
  }
  
  @override
  void onClose() {
    debugPrint('🔄 إغلاق BrandFilterController...');
    
    // مسح جميع المعلومات من الذاكرة عند إتلاف الكنترولر
    clearAllMemoryData();
    
    // التخلص من الانيميشن
    animationController.dispose();
    
    debugPrint('✅ تم إغلاق BrandFilterController وتنظيف الذاكرة');
    super.onClose();
  }
  
  /// تهيئة الانيميشن
  void _initAnimations() {
    animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOutCubic,
    ));
    
    fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));
    
    scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
    ));
  }
  
  /// تحميل قائمة الشركات من Firebase
  Future<void> loadCompanies() async {
    try {
      isLoading.value = true;
      
      final QuerySnapshot snapshot = await _firestore
          .collection('brand_companies')
          .where('isActive', isEqualTo: true)
          .orderBy('nameAr')
          .get();
      
      final List<CompanyModel> loadedCompanies = [];
      
      for (final doc in snapshot.docs) {
        final company = CompanyModel.fromFirestore(doc);
        
        // تحميل منتجات كل شركة
        final companyProducts = await _loadProductsForCompany(company.id);
        
        // إنشاء شركة مع منتجاتها
        final companyWithProducts = CompanyModel(
          id: company.id,
          nameAr: company.nameAr,
          nameEn: company.nameEn,
          logoUrl: company.logoUrl,
          description: company.description,
          country: company.country,
          isActive: company.isActive,
          createdBy: company.createdBy,
          createdAt: company.createdAt,
          updatedAt: company.updatedAt,
          products: companyProducts,
        );
        
        loadedCompanies.add(companyWithProducts);
      }
      
      companies.value = loadedCompanies;
      debugPrint('تم تحميل ${companies.length} شركة للبراند فلتر');
    } catch (e) {
      debugPrint('خطأ في تحميل الشركات: $e');
      Get.snackbar(
        'خطأ',
        'فشل في تحميل الشركات: ${e.toString()}',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  /// تحميل منتجات شركة معينة
  Future<List<CompanyProductModel>> _loadProductsForCompany(String companyId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('company_products')
          .where('companyId', isEqualTo: companyId)
          .where('isActive', isEqualTo: true)
          .orderBy('nameAr')
          .get();
      
      return snapshot.docs
          .map((doc) => CompanyProductModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('خطأ في تحميل منتجات الشركة $companyId: $e');
      return [];
    }
  }
  
  /// تفعيل نمط البراند مع الانيميشن
  Future<void> activateBrandMode() async {
    if (isBrandModeActive.value) return;
    
    debugPrint('🔄 تفعيل نمط البراند...');
    debugPrint('📊 عدد الشركات المحملة: ${companies.length}');
    debugPrint('🏢 الشركة المختارة حالياً: ${selectedCompany.value?.nameAr ?? 'لا شيء'}');
    debugPrint('💾 آخر شركة محفوظة: ${_lastSelectedCompany?.nameAr ?? 'لا شيء'}');
    
    isBrandModeActive.value = true;
    
    // تحميل البيانات إذا كانت فارغة أو استعادة الاختيارات السابقة
    if (companies.isEmpty) {
      debugPrint('🔄 إعادة تحميل البيانات بعد مسح الذاكرة...');
      await loadCompanies();
    } else if (_lastSelectedCompany != null) {
      debugPrint('🔄 استعادة الاختيار السابق...');
      selectedCompany.value = _lastSelectedCompany;
      selectedCompanyProduct.value = _lastSelectedCompanyProduct;
      selectedCompanyProducts.value = _lastSelectedCompany!.products;
      
      debugPrint('✅ تم استعادة الشركة: ${_lastSelectedCompany!.nameAr}');
      debugPrint('✅ عدد المنتجات المستعادة: ${_lastSelectedCompany!.products.length}');
    }
    
    await animationController.forward();
    update(); // إضافة update لتحديث GetBuilder
    
    debugPrint('✅ تم تفعيل نمط البراند بنجاح');
  }
  
  /// إلغاء تفعيل نمط البراند مع الانيميشن
  Future<void> deactivateBrandMode() async {
    if (!isBrandModeActive.value) return;
    
    debugPrint('🔄 إغلاق نمط البراند...');
    
    // حفظ الاختيارات الحالية قبل مسحها
    _lastSelectedCompany = selectedCompany.value;
    _lastSelectedCompanyProduct = selectedCompanyProduct.value;
    
    debugPrint('💾 حفظ الشركة المختارة: ${_lastSelectedCompany?.nameAr ?? 'لا شيء'}');
    debugPrint('💾 حفظ المنتج المختار: ${_lastSelectedCompanyProduct?.nameAr ?? 'لا شيء'}');
    
    await animationController.reverse();
    isBrandModeActive.value = false;
    
    // إعادة تعيين الاختيارات المرئية فقط (مع الحفاظ على النسخة المحفوظة)
    selectedCompany.value = null;
    selectedCompanyProduct.value = null;
    selectedCompanyProducts.clear();
    
    update(); // إضافة update لتحديث GetBuilder
    
    debugPrint('✅ تم إغلاق نمط البراند مع حفظ الاختيارات');
  }
  
  /// إلغاء تفعيل نمط البراند مع مسح جميع المعلومات من الذاكرة
  Future<void> deactivateBrandModeAndClearMemory() async {
    if (!isBrandModeActive.value) return;
    
    debugPrint('🔄 إغلاق نمط البراند مع مسح جميع المعلومات...');
    
    await animationController.reverse();
    isBrandModeActive.value = false;
    
    // مسح جميع المعلومات من الذاكرة
    clearAllMemoryData();
    
    update(); // إضافة update لتحديث GetBuilder
    
    debugPrint('✅ تم إغلاق نمط البراند مع مسح جميع المعلومات من الذاكرة');
  }
  
  /// مسح جميع المعلومات من الذاكرة
  void clearAllMemoryData() {
    debugPrint('🗑️ مسح جميع المعلومات من الذاكرة...');
    
    // مسح الاختيارات الحالية
    selectedCompany.value = null;
    selectedCompanyProduct.value = null;
    selectedCompanyProducts.clear();
    
    // مسح الاختيارات المحفوظة
    _lastSelectedCompany = null;
    _lastSelectedCompanyProduct = null;
    
    // مسح قائمة الشركات المحملة
    companies.clear();
    
    // إعادة تعيين حالة التحميل
    isLoading.value = false;
    
    debugPrint('✅ تم مسح جميع المعلومات من الذاكرة');
    debugPrint('📊 عدد الشركات المتبقية: ${companies.length}');
    debugPrint('🏢 الشركة المختارة: ${selectedCompany.value?.nameAr ?? 'لا شيء'}');
    debugPrint('💾 الشركة المحفوظة: ${_lastSelectedCompany?.nameAr ?? 'لا شيء'}');
    
    update();
  }
  
  /// اختيار شركة
  void selectCompany(CompanyModel company) {
    debugPrint('🎯 اختيار الشركة: ${company.nameAr}');
    debugPrint('   - معرف الشركة: ${company.id}');
    debugPrint('   - عدد المنتجات: ${company.products.length}');
    
    selectedCompany.value = company;
    selectedCompanyProduct.value = null; // إعادة تعيين المنتج المختار
    selectedCompanyProducts.value = company.products;
    
    debugPrint('✅ تم تحديث الاختيار - الشركة المختارة: ${selectedCompany.value?.nameAr}');
    debugPrint('✅ عدد المنتجات في القائمة: ${selectedCompanyProducts.length}');
    

    
    update(); // إضافة update لتحديث GetBuilder
  }
  
  /// اختيار منتج من الشركة
  void selectCompanyProduct(CompanyProductModel product) {
    selectedCompanyProduct.value = product;
    debugPrint('تم اختيار المنتج: ${product.nameAr}');
    

    
    update(); // إضافة update لتحديث GetBuilder
  }
  
  /// الحصول على مفتاح الفلتر الحالي
  String getFilterKey() {
    if (!isBrandModeActive.value) return 'all';
    
    if (selectedCompanyProduct.value != null) {
      // فلترة حسب منتج الشركة المحدد
      return 'original_product_${selectedCompanyProduct.value!.id}';
    } else if (selectedCompany.value != null) {
      // فلترة حسب الشركة المحددة
      return 'original_company_${selectedCompany.value!.id}';
    }
    
    return 'original_brands';
  }
  
  /// وصف الفلتر الحالي
  String getFilterDescription() {
    if (!isBrandModeActive.value) return 'جميع المنتجات';
    
    if (selectedCompanyProduct.value != null) {
      return 'منتجات ${selectedCompanyProduct.value!.nameAr}';
    } else if (selectedCompany.value != null) {
      return 'منتجات شركة ${selectedCompany.value!.nameAr}';
    }
    
    return 'البحث بالبراند';
  }
  
  /// التحقق من وجود فلتر نشط
  bool get hasActiveFilter => isBrandModeActive.value && 
      (selectedCompany.value != null || selectedCompanyProduct.value != null);

  /// مسح جميع الاختيارات (للاستخدام عند التبديل لطريقة بحث أخرى)
  void clearAllSelections() {
    debugPrint('🗑️ مسح جميع اختيارات البراند...');
    
    selectedCompany.value = null;
    selectedCompanyProduct.value = null;
    selectedCompanyProducts.clear();
    
    // مسح الاختيارات المحفوظة أيضاً
    _lastSelectedCompany = null;
    _lastSelectedCompanyProduct = null;
    
    debugPrint('✅ تم مسح جميع الاختيارات');
    update();
  }
} 