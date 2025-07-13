import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../Model/enhanced_category_model.dart';

class CategoriesManagementController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // القوائم التفاعلية
  final RxList<EnhancedCategoryModel> mainCategories = <EnhancedCategoryModel>[].obs;
  final RxList<EnhancedCategoryModel> allCategories = <EnhancedCategoryModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadCategories();
  }

  /// تحميل جميع الأقسام من Firestore
  Future<void> loadCategories() async {
    try {
      isLoading(true);
      
      final snapshot = await _firestore
          .collection('categories')
          .orderBy('order')
          .get();

      final List<EnhancedCategoryModel> categories = snapshot.docs
          .map((doc) => EnhancedCategoryModel.fromSnapshot(doc))
          .toList();

      allCategories.assignAll(categories);
      
      // فصل الأقسام الرئيسية والفرعية
      final List<EnhancedCategoryModel> mainCats = [];
      
      for (var category in categories) {
        if (category.isMainCategory) {
          // البحث عن الأقسام الفرعية لهذا القسم الرئيسي
          final subCats = categories
              .where((cat) => cat.parentId == category.id)
              .toList();
          
          mainCats.add(category.copyWith(subCategories: subCats));
        }
      }
      
      mainCategories.assignAll(mainCats);
      
      debugPrint('Categories loaded successfully: ${allCategories.length} total, ${mainCategories.length} main categories');
      
    } catch (e) {
      debugPrint('Error loading categories: $e');
      Get.snackbar(
        '❌ خطأ',
        'فشل في تحميل الأقسام: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading(false);
    }
  }

  /// إضافة قسم جديد (رئيسي أو فرعي)
  Future<bool> addCategory(EnhancedCategoryModel category) async {
    try {
      isLoading(true);
      
      // التحقق من عدم تكرار الاسم
      final duplicateCheck = await _firestore
          .collection('categories')
          .where('nameAr', isEqualTo: category.nameAr)
          .where('parentId', isEqualTo: category.parentId)
          .get();
      
      if (duplicateCheck.docs.isNotEmpty) {
        Get.snackbar(
          '⚠️ تحذير',
          'يوجد قسم بنفس الاسم في نفس المستوى',
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
        return false;
      }

      // إضافة القسم
      await _firestore.collection('categories').add(category.toMap());
      
      // إعادة تحميل الأقسام
      await loadCategories();
      
      Get.snackbar(
        '✅ تم بنجاح',
        'تم إضافة القسم "${category.nameAr}" بنجاح',
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );
      
      return true;
      
    } catch (e) {
      Get.snackbar(
        '❌ خطأ',
        'فشل في إضافة القسم: ${e.toString()}',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return false;
    } finally {
      isLoading(false);
    }
  }

  /// تحديث قسم
  Future<bool> updateCategory(EnhancedCategoryModel category) async {
    try {
      isLoading(true);
      
      await _firestore
          .collection('categories')
          .doc(category.id)
          .update(category.copyWith(updatedAt: DateTime.now()).toMap());
      
      // إعادة تحميل الأقسام
      await loadCategories();
      
      Get.snackbar(
        '✅ تم التحديث',
        'تم تحديث القسم "${category.nameAr}" بنجاح',
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );
      
      return true;
      
    } catch (e) {
      Get.snackbar(
        '❌ خطأ',
        'فشل في تحديث القسم: ${e.toString()}',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return false;
    } finally {
      isLoading(false);
    }
  }

  /// حذف قسم
  Future<bool> deleteCategory(String categoryId) async {
    try {
      isLoading(true);
      
      // التحقق من وجود أقسام فرعية
      final subCategoriesSnapshot = await _firestore
          .collection('categories')
          .where('parentId', isEqualTo: categoryId)
          .get();
      
      if (subCategoriesSnapshot.docs.isNotEmpty) {
        Get.snackbar(
          '⚠️ تحذير',
          'لا يمكن حذف القسم لأنه يحتوي على أقسام فرعية',
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
        return false;
      }
      
      // حذف القسم
      await _firestore.collection('categories').doc(categoryId).delete();
      
      // إعادة تحميل الأقسام
      await loadCategories();
      
      Get.snackbar(
        '✅ تم الحذف',
        'تم حذف القسم بنجاح',
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );
      
      return true;
      
    } catch (e) {
      Get.snackbar(
        '❌ خطأ',
        'فشل في حذف القسم: ${e.toString()}',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return false;
    } finally {
      isLoading(false);
    }
  }

  /// رفع صورة إلى Firebase Storage
  Future<String?> uploadCategoryImage(File imageFile, String categoryName) async {
    try {
      final String fileName = 'category_${DateTime.now().millisecondsSinceEpoch}_$categoryName.jpg';
      final Reference storageRef = _storage.ref().child('categories/$fileName');
      
      final UploadTask uploadTask = storageRef.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
      
    } catch (e) {
      Get.snackbar(
        '❌ خطأ في رفع الصورة',
        'فشل في رفع الصورة: ${e.toString()}',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return null;
    }
  }

  /// الحصول على الأقسام الفرعية لقسم معين
  List<EnhancedCategoryModel> getSubCategories(String parentId) {
    return allCategories
        .where((category) => category.parentId == parentId)
        .toList();
  }

  /// الحصول على قسم بالمعرف
  EnhancedCategoryModel? getCategoryById(String id) {
    return allCategories.firstWhereOrNull((category) => category.id == id);
  }

  /// البحث في الأقسام
  List<EnhancedCategoryModel> searchCategories(String query) {
    if (query.isEmpty) return allCategories;
    
    return allCategories.where((category) {
      return category.nameAr.toLowerCase().contains(query.toLowerCase()) ||
             category.nameEn.toLowerCase().contains(query.toLowerCase()) ||
             category.nameKu.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  /// تغيير ترتيب الأقسام
  Future<void> reorderCategories(List<EnhancedCategoryModel> categories) async {
    try {
      isLoading(true);
      
      final batch = _firestore.batch();
      
      for (int i = 0; i < categories.length; i++) {
        final docRef = _firestore.collection('categories').doc(categories[i].id);
        batch.update(docRef, {
          'order': i + 1,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
      
      await batch.commit();
      await loadCategories();
      
      Get.snackbar(
        '✅ تم التحديث',
        'تم تحديث ترتيب الأقسام بنجاح',
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );
      
    } catch (e) {
      Get.snackbar(
        '❌ خطأ',
        'فشل في تحديث الترتيب: ${e.toString()}',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      isLoading(false);
    }
  }
} 