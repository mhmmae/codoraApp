


import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchAndDeleteController extends GetxController {
  // حقل البحث
  final searchController = TextEditingController();

  // قائمة الاقتراحات والنتائج
  final suggestions = <String>[].obs;
  final foundCodes = <Map<String, dynamic>>[].obs;

  // حالة التحميل
  final isLoading = false.obs;

  // جلب الاقتراحات بناءً على الاستعلام الجزئي للكود
  Future<void> fetchSuggestions(String query) async {
    try {
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('codes')
          .where('code', isGreaterThanOrEqualTo: query)
          .where('code', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      suggestions.clear();
      for (var doc in querySnapshot.docs) {
        suggestions.add(doc['code'] as String);
      }
    } catch (e) {
      Get.snackbar("خطأ", "حدث خطأ أثناء جلب الاقتراحات: $e",
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  // البحث عن الكود المحدد
  Future<void> searchByCode(String code) async {
    try {
      isLoading.value = true;
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('codes')
          .where('code', isEqualTo: code)
          .get();

      foundCodes.clear();
      for (var doc in querySnapshot.docs) {
        foundCodes.add(doc.data() as Map<String, dynamic>);
      }

      if (foundCodes.isEmpty) {
        Get.snackbar("تنبيه", "لم يتم العثور على أي مستند يحتوي على الكود.",
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar("خطأ", "حدث خطأ أثناء البحث: $e",
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  // حذف كل المستندات المتشابهة بناءً على uidCologe
  Future<void> deleteByUidCologe(String uidCologe) async {
    try {
      isLoading.value = true;
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('codes')
          .where('uidCologe', isEqualTo: uidCologe)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
      foundCodes.clear();
      Get.snackbar("نجاح",
          "تم حذف جميع المستندات المرتبطة بـ UID: $uidCologe بنجاح!",
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar("خطأ", "حدث خطأ أثناء الحذف: $e",
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
