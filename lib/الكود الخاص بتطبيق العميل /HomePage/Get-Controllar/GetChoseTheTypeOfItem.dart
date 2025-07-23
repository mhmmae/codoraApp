import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GetChoseTheTypeOfItem extends GetxController {
  static const Map<String, String> filterOptions = {
    'all': 'الكل', 'New Phone': 'هاتف جديد', 'Used phone': 'هاتف مستعمل',
    'Phone charger': 'شواحن', 'Headphones': 'سماعات', 'Tablet': 'أجهزة لوحية',
  };
  List<String> get filterKeys => filterOptions.keys.toList();
  String getDisplayText(String key) => filterOptions[key] ?? key;
  final RxString selectedFilterKey = 'all'.obs;

  void updateSelection(String newKey) {
    if (filterOptions.containsKey(newKey)) {
      if (selectedFilterKey.value != newKey) {
        selectedFilterKey.value = newKey;
        debugPrint("تم تحديث فلتر المنتجات إلى: $newKey");
      }
    } else { debugPrint("المفتاح '$newKey' غير صالح."); }
  }

  @override
  void onInit() { super.onInit(); debugPrint("GetChoseTheTypeOfItem (Filter Controller) Initialized."); }
}



// متحكم لاختيار النوع الفرعي عند إضافة منتج جديد
class AddItemSubtypeController extends GetxController {
  // بيانات ثابتة للأنواع الفرعية عند الإضافة



  // الحالة: المفتاح المختار (يمكن أن يكون null)
  final RxnString selectedSubtypeKey = RxnString(null);

  // تحديث الاختيار
  void selectSubtype(String? newSubtypeKey) {
    selectedSubtypeKey.value = newSubtypeKey;
    debugPrint("تم اختيار النوع الفرعي للإضافة: ${selectedSubtypeKey.value ?? 'لا شيء'}");
  }
  // مسح الاختيار
  void clearSelection() => selectedSubtypeKey.value = null;

  @override
  void onInit() { super.onInit(); debugPrint("AddItemSubtypeController Initialized."); }
  @override
  void onClose() { debugPrint("AddItemSubtypeController closed."); super.onClose();}
}