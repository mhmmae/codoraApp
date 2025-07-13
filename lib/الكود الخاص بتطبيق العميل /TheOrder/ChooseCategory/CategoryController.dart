// controllers/category_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../Model/category_model.dart';


class CategoryController extends GetxController {
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
      debugPrint("Fetched ${categories.length} active categories.");

    } catch (e) {
      debugPrint("Error fetching categories: $e");
      error.value = "خطأ في تحميل الأقسام: $e"; // <<-- تعريب
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
}