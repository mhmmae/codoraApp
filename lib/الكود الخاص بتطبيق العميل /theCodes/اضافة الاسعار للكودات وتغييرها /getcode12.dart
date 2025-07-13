import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PricingControllerCode extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
   String? codeName;

  PricingControllerCode({required this.codeName});

  final List<Map<String, String>> durations = [
    {"ar": "شهر", "en": "month"},
    {"ar": "ثلاثة أشهر", "en": "three months"},
    {"ar": "ستة أشهر", "en": "six months"},
    {"ar": "تسعة أشهر", "en": "nine months"},
    {"ar": "سنة", "en": "year"}
  ];

  var selectedDurationArabic = "شهر".obs;
  var selectedDurationEnglish = "month".obs;
  var priceController = "".obs;
  var isLoading = false.obs;

  final TextEditingController textEditingController = TextEditingController();

  @override
  void onInit() {
    super.onInit();

    // Sync the TextEditingController with the priceController observable
    priceController.listen((value) {
      textEditingController.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    });

    fetchPrice();
  }

  Future<void> fetchPrice() async {
    try {
      isLoading.value = true;

      DocumentSnapshot<Map<String, dynamic>> doc =
          await _firestore.collection("pricing").doc(codeName).get();

      if (doc.exists) {
        double price = doc.data()?[selectedDurationEnglish.value] ?? 0.0;
        priceController.value = price.toString();
      } else {
        priceController.value = "";
        Get.snackbar("تنبيه", "لا يوجد سعر محفوظ لهذه المدة.",
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar("خطأ", "حدث خطأ أثناء جلب السعر: $e",
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> savePrice() async {
    try {
      double price = double.tryParse(priceController.value) ?? 0.0;

      if (price <= 0) {
        Get.snackbar("خطأ", "يرجى إدخال سعر صالح.",
            snackPosition: SnackPosition.BOTTOM);
        return;
      }

      await _firestore.collection("pricing").doc(codeName).set({
        selectedDurationEnglish.value: price,
      }, SetOptions(merge: true));



      Get.snackbar("نجاح", "تم حفظ السعر بنجاح!",
          snackPosition: SnackPosition.BOTTOM);

    } catch (e) {
      Get.snackbar("خطأ", "حدث خطأ أثناء حفظ السعر: $e",
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  void onClose() {
    textEditingController.dispose();
    super.onClose();
  }
}