import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../Model/enhanced_category_model.dart';

/// Controller محسن لإدارة الفئات مع الفلترة المتقدمة
class EnhancedCategoryController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // حالات التحميل
  final RxBool isLoading = false.obs;
  final RxBool isLoadingSubCategories = false.obs;
  
  // قوائم الفئات
  final RxList<EnhancedCategoryModel> mainCategories = <EnhancedCategoryModel>[].obs;
  final RxList<EnhancedCategoryModel> subCategories = <EnhancedCategoryModel>[].obs;
  final RxList<EnhancedCategoryModel> allCategories = <EnhancedCategoryModel>[].obs;
  
  // الفئة المختارة حالياً
  final Rx<EnhancedCategoryModel?> selectedMainCategory = Rx<EnhancedCategoryModel?>(null);
  final Rx<EnhancedCategoryModel?> selectedSubCategory = Rx<EnhancedCategoryModel?>(null);
  
  @override
  void onInit() {
    super.onInit();
    loadMainCategories();
  }
  
  /// تحميل جميع الأقسام الرئيسية
  Future<void> loadMainCategories() async {
    try {
      isLoading.value = true;
      
      final QuerySnapshot snapshot = await _firestore
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .where('parentId', isNull: true) // الأقسام الرئيسية فقط
          .orderBy('order', descending: false)
          .get();
      
      final List<EnhancedCategoryModel> categories = snapshot.docs
          .map((doc) => EnhancedCategoryModel.fromSnapshot(
              doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
      
      mainCategories.value = categories;
      allCategories.addAll(categories);
      
      debugPrint('✅ تم تحميل ${categories.length} قسم رئيسي');
    } catch (e) {
      debugPrint('❌ خطأ في تحميل الأقسام الرئيسية: $e');
      Get.snackbar(
        'خطأ', 
        'فشل في تحميل الأقسام الرئيسية', 
        snackPosition: SnackPosition.BOTTOM
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  /// تحميل الأقسام الفرعية لقسم رئيسي محدد
  Future<void> loadSubCategories(String mainCategoryId) async {
    try {
      isLoadingSubCategories.value = true;
      subCategories.clear();
      
      final QuerySnapshot snapshot = await _firestore
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .where('parentId', isEqualTo: mainCategoryId)
          .orderBy('order', descending: false)
          .get();
      
      final List<EnhancedCategoryModel> categories = snapshot.docs
          .map((doc) => EnhancedCategoryModel.fromSnapshot(
              doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
      
      subCategories.value = categories;
      
      debugPrint('✅ تم تحميل ${categories.length} قسم فرعي للقسم: $mainCategoryId');
    } catch (e) {
      debugPrint('❌ خطأ في تحميل الأقسام الفرعية: $e');
      Get.snackbar(
        'خطأ', 
        'فشل في تحميل الأقسام الفرعية', 
        snackPosition: SnackPosition.BOTTOM
      );
    } finally {
      isLoadingSubCategories.value = false;
    }
  }
  
  /// تحميل فئة محددة بالمعرف
  Future<EnhancedCategoryModel?> loadCategoryById(String categoryId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('categories')
          .doc(categoryId)
          .get();
      
      if (doc.exists) {
        return EnhancedCategoryModel.fromSnapshot(
            doc as DocumentSnapshot<Map<String, dynamic>>);
      }
      return null;
    } catch (e) {
      debugPrint('❌ خطأ في تحميل الفئة: $e');
      return null;
    }
  }
  
  /// فلترة الأقسام الرئيسية حسب نوع المنتج
  List<EnhancedCategoryModel> getFilteredMainCategories(String? productType) {
    if (productType == null) return mainCategories;
    
    return mainCategories
        .where((category) => category.canBeUsedForProductType(productType))
        .toList();
  }
  
  /// فلترة الأقسام الفرعية حسب نوع المنتج
  List<EnhancedCategoryModel> getFilteredSubCategories(String? productType) {
    if (productType == null) return subCategories;
    
    return subCategories
        .where((category) => category.canBeUsedForProductType(productType))
        .toList();
  }
  
  /// البحث في الفئات
  Future<List<EnhancedCategoryModel>> searchCategories(String query, {String? productType}) async {
    try {
      final String lowerQuery = query.toLowerCase();
      
      // البحث في الفئات المحملة محلياً أولاً
      List<EnhancedCategoryModel> localResults = allCategories
          .where((category) {
            final bool matchesQuery = category.nameAr.toLowerCase().contains(lowerQuery) ||
                category.nameEn.toLowerCase().contains(lowerQuery) ||
                category.nameKu.toLowerCase().contains(lowerQuery);
            
            final bool matchesProductType = productType == null || 
                category.canBeUsedForProductType(productType);
            
            return matchesQuery && matchesProductType;
          })
          .toList();
      
      if (localResults.isNotEmpty) {
        return localResults;
      }
      
      // إذا لم توجد نتائج محلية، ابحث في قاعدة البيانات
      final QuerySnapshot snapshot = await _firestore
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .get();
      
      final List<EnhancedCategoryModel> allDbCategories = snapshot.docs
          .map((doc) => EnhancedCategoryModel.fromSnapshot(
              doc as DocumentSnapshot<Map<String, dynamic>>))
          .where((category) {
            final bool matchesQuery = category.nameAr.toLowerCase().contains(lowerQuery) ||
                category.nameEn.toLowerCase().contains(lowerQuery) ||
                category.nameKu.toLowerCase().contains(lowerQuery);
            
            final bool matchesProductType = productType == null || 
                category.canBeUsedForProductType(productType);
            
            return matchesQuery && matchesProductType;
          })
          .toList();
      
      return allDbCategories;
    } catch (e) {
      debugPrint('❌ خطأ في البحث: $e');
      return [];
    }
  }
  
  /// إضافة فئة جديدة
  Future<bool> addCategory(EnhancedCategoryModel category) async {
    try {
      await _firestore
          .collection('categories')
          .doc(category.id)
          .set(category.toMap());
      
      // إضافة للقائمة المحلية
      if (category.isMainCategory) {
        mainCategories.add(category);
      } else {
        subCategories.add(category);
      }
      allCategories.add(category);
      
      Get.snackbar(
        'نجح', 
        'تم إضافة الفئة بنجاح', 
        snackPosition: SnackPosition.BOTTOM
      );
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في إضافة الفئة: $e');
      Get.snackbar(
        'خطأ', 
        'فشل في إضافة الفئة', 
        snackPosition: SnackPosition.BOTTOM
      );
      return false;
    }
  }
  
  /// تحديث فئة موجودة
  Future<bool> updateCategory(EnhancedCategoryModel category) async {
    try {
      await _firestore
          .collection('categories')
          .doc(category.id)
          .update(category.toMap());
      
      // تحديث القوائم المحلية
      _updateLocalCategory(category);
      
      Get.snackbar(
        'نجح', 
        'تم تحديث الفئة بنجاح', 
        snackPosition: SnackPosition.BOTTOM
      );
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في تحديث الفئة: $e');
      Get.snackbar(
        'خطأ', 
        'فشل في تحديث الفئة', 
        snackPosition: SnackPosition.BOTTOM
      );
      return false;
    }
  }
  
  /// حذف فئة
  Future<bool> deleteCategory(String categoryId) async {
    try {
      // التحقق من وجود أقسام فرعية
      final QuerySnapshot subCategoriesSnapshot = await _firestore
          .collection('categories')
          .where('parentId', isEqualTo: categoryId)
          .get();
      
      if (subCategoriesSnapshot.docs.isNotEmpty) {
        Get.snackbar(
          'تحذير', 
          'لا يمكن حذف قسم يحتوي على أقسام فرعية', 
          snackPosition: SnackPosition.BOTTOM
        );
        return false;
      }
      
      // حذف الفئة
      await _firestore
          .collection('categories')
          .doc(categoryId)
          .delete();
      
      // إزالة من القوائم المحلية
      _removeLocalCategory(categoryId);
      
      Get.snackbar(
        'نجح', 
        'تم حذف الفئة بنجاح', 
        snackPosition: SnackPosition.BOTTOM
      );
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في حذف الفئة: $e');
      Get.snackbar(
        'خطأ', 
        'فشل في حذف الفئة', 
        snackPosition: SnackPosition.BOTTOM
      );
      return false;
    }
  }
  
  /// تحديث فئة في القوائم المحلية
  void _updateLocalCategory(EnhancedCategoryModel updatedCategory) {
    // تحديث في القائمة الرئيسية
    if (updatedCategory.isMainCategory) {
      final index = mainCategories.indexWhere((cat) => cat.id == updatedCategory.id);
      if (index != -1) {
        mainCategories[index] = updatedCategory;
      }
    } else {
      final index = subCategories.indexWhere((cat) => cat.id == updatedCategory.id);
      if (index != -1) {
        subCategories[index] = updatedCategory;
      }
    }
    
    // تحديث في القائمة الشاملة
    final allIndex = allCategories.indexWhere((cat) => cat.id == updatedCategory.id);
    if (allIndex != -1) {
      allCategories[allIndex] = updatedCategory;
    }
  }
  
  /// إزالة فئة من القوائم المحلية
  void _removeLocalCategory(String categoryId) {
    mainCategories.removeWhere((cat) => cat.id == categoryId);
    subCategories.removeWhere((cat) => cat.id == categoryId);
    allCategories.removeWhere((cat) => cat.id == categoryId);
  }
  
  /// إعادة تحميل جميع البيانات
  Future<void> refreshData() async {
    allCategories.clear();
    subCategories.clear();
    await loadMainCategories();
  }
  
  /// تنظيف البيانات عند إنهاء Controller
  @override
  void onClose() {
    mainCategories.clear();
    subCategories.clear();
    allCategories.clear();
    super.onClose();
  }
} 