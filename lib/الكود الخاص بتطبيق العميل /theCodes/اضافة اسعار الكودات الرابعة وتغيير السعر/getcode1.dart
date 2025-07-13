
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PricingController extends GetxController {
  var selectedProvinceArabic = "".obs;
  var selectedProvinceEnglish = "".obs;
  var selectedDurationArabic = "شهر".obs;
  var selectedDurationEnglish = "month".obs;
  var price = 0.0.obs;
  var phoneNumber = "".obs;
  var isLoading = false.obs; // Loading state

  TextEditingController priceEditingController = TextEditingController();
  TextEditingController phoneEditingController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> fetchData(String provinceEnglish, String durationEnglish) async {
    try {
      isLoading.value = true;
      DocumentSnapshot<Map<String, dynamic>> doc = await _firestore
          .collection("pricing")
          .doc(provinceEnglish)
          .get();

      if (doc.exists) {
        price.value = doc.data()?[durationEnglish] ?? 0.0;
        phoneNumber.value = doc.data()?['phone'] ?? "";
        priceEditingController.text = price.value.toString();
        phoneEditingController.text = phoneNumber.value;
      } else {
        Get.snackbar("خطأ", "لا توجد بيانات لهذه المحافظة.",
            snackPosition: SnackPosition.BOTTOM);
        price.value = 0.0;
        phoneNumber.value = "";
        priceEditingController.text = "";
        phoneEditingController.text = "";
      }
    } catch (e) {
      Get.snackbar("خطأ", "حدث خطأ أثناء جلب البيانات: $e",
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveData(String provinceEnglish, String durationEnglish) async {
    try {
      isLoading.value = true;

      // Fetch the current data from Firestore
      DocumentSnapshot<Map<String, dynamic>> doc = await _firestore
          .collection("pricing")
          .doc(provinceEnglish)
          .get();

      double currentPrice = doc.data()?[durationEnglish] ?? 0.0;
      String currentPhoneNumber = doc.data()?['phone'] ?? "";

      double newPrice = double.tryParse(priceEditingController.text) ?? 0.0;
      String newPhoneNumber = phoneEditingController.text;

      // Check if the price or phone number has changed
      if (currentPrice != newPrice || currentPhoneNumber != newPhoneNumber) {
        // Show a confirmation dialog
        bool? confirm = await Get.defaultDialog<bool>(
          title: "تحذير",
          middleText: "تم تعديل السعر أو رقم الهاتف. هل تريد المتابعة؟",
          textCancel: "إلغاء",
          textConfirm: "متابعة",
          onConfirm: () {
            Get.back(result: true);
          },
          onCancel: () {
            Get.back(result: false);
          },
        );

        if (confirm != true) {
          isLoading.value = false;
          return; // Exit if the user cancels
        }
      }

      // Save the new data to Firestore
      await _firestore.collection("pricing").doc(provinceEnglish).set({
        durationEnglish: newPrice,
        'phone': newPhoneNumber,
      }, SetOptions(merge: true));

      Get.snackbar("نجاح", "تم حفظ البيانات بنجاح!",
          snackPosition: SnackPosition.BOTTOM);
      price.value = newPrice;
      phoneNumber.value = newPhoneNumber;
    } catch (e) {
      Get.snackbar("خطأ", "حدث خطأ أثناء حفظ البيانات: $e",
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  void updateProvince(String provinceArabic) {
    selectedProvinceArabic.value = provinceArabic;
    int index = provincesArabic.indexOf(provinceArabic);
    if (index != -1) {
      selectedProvinceEnglish.value = provincesEnglish[index];
    } else {
      selectedProvinceEnglish.value = "";
    }
  }

  void updateDuration(String durationArabic) {
    selectedDurationArabic.value = durationArabic;
    selectedDurationEnglish.value = durations.firstWhere(
          (duration) => duration['ar'] == durationArabic,
      orElse: () => {"ar": "شهر", "en": "month"},
    )['en']!;
  }

  @override
  void onInit() {
    super.onInit();
    priceEditingController.text = price.value.toString();
  }

  @override
  void onClose() {
    priceEditingController.dispose();
    phoneEditingController.dispose();
    super.onClose();
  }

  final List<String> provincesArabic = [
    "بغداد",
    "البصرة",
    "نينوى",
    "الأنبار",
    "كربلاء",
    "النجف",
    "صلاح الدين",
    "ديالى",
    "السليمانية",
    "أربيل",
    "دهوك",
    "القادسية",
    "ميسان",
    "ذي قار",
    "المثنى",
    "واسط",
    "حلبجة",
    "كركوك"
  ];

  final List<String> provincesEnglish = [
    "Baghdad",
    "Basra",
    "Nineveh",
    "Anbar",
    "Karbala",
    "Najaf",
    "Salahuddin",
    "Diyala",
    "Sulaymaniyah",
    "Erbil",
    "Dohuk",
    "Qadisiyah",
    "Maysan",
    "DhiQar",
    "Muthanna",
    "Wasit",
    "Halabja",
    "Kirkuk"
  ];

  final List<Map<String, String>> durations = [
    {"ar": "شهر", "en": "month"},
    {"ar": "ثلاثة أشهر", "en": "three months"},
    {"ar": "ستة أشهر", "en": "six months"},
    {"ar": "تسعة أشهر", "en": "nine months"},
    {"ar": "سنة", "en": "year"}
  ];
}
