// controllers/category_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../Model/category_model.dart';

class CategoryController1 extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RxList<CategoryModel> categories = <CategoryModel>[].obs; // قائمة الأقسام التفاعلية
  final RxBool isLoading = true.obs; // حالة التحميل
  final RxString error = ''.obs; // <-- ''.obs هي اختصار لـ RxString('')

  // مفتاح فلتر "الكل"
  static const String allFilterKey = 'all';
  // اختيار الفلتر الحالي (يبدأ بـ "الكل")
  final RxString selectedCategoryKey = allFilterKey.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCategories(); // جلب الأقسام عند تهيئة المتحكم
  }

  // جلب الأقسام النشطة مرتبة من Firestore
  Future<void> fetchCategories() async {
    if (isLoading.value) return; // تجنب التحميل المتعدد
    
    isLoading.value = true;
    error.value = '';
    try {
      final snapshot = await _firestore
          .collection('categories') // اسم المجموعة
          .where('isActive', isEqualTo: true) // جلب النشطة فقط
          .orderBy('order', descending: false) // الترتيب حسب الحقل order
          .get();

      final fetchedCategories = snapshot.docs
          .map((doc) => CategoryModel.fromSnapshot(doc))
          .toList();
      
      categories.assignAll(fetchedCategories); // تحديث القائمة التفاعلية
      debugPrint("تم جلب ${categories.length} قسم نشط");

      // إذا كانت القائمة فارغة، أظهر رسالة خاصة
      if (categories.isEmpty) {
        error.value = "لا توجد أقسام نشطة في قاعدة البيانات";
      }

    } catch (e) {
      debugPrint("خطأ في جلب الأقسام: $e");
      error.value = "خطأ في تحميل الأقسام";
    } finally {
      isLoading.value = false;
    }
  }

  // دالة لتحديث الفئة المختارة
  void selectCategory(String key) {
    debugPrint('999999999999999999999999999');
    // لا نتحقق هنا من صحة المفتاح لأنه يأتي من قائمة تم جلبها
    if (selectedCategoryKey.value != key) {
      selectedCategoryKey.value = key;
      update();
      debugPrint("Category filter selected: $key");
      // يجب أن يكون ProductGridWidget يستمع لهذا التغيير (عبر Get.find لهذا المتحكم)
    }
  }

  // إعادة تعيين للفلتر الافتراضي ("الكل")
  void resetFilter() {
    selectCategory(allFilterKey);
  }

  // دالة للحصول على اسم القسم بالإنجليزية
  String getCategoryNameEn(String categoryId) {
    try {
      final category = categories.firstWhere(
        (cat) => cat.id == categoryId,
        orElse: () => CategoryModel(id: '', nameEn: '', nameAr: '', order: 0, isActive: false),
      );
      return category.nameEn;
    } catch (e) {
      debugPrint("Error getting category name: $e");
      return '';
    }
  }
}