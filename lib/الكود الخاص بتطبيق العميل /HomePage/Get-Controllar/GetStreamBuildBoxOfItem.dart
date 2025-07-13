import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../XXX/xxx_firebase.dart';


class GetStreamBuildBoxOfItemController extends GetxController {
  final RxBool isEditingName = false.obs;
  final TextEditingController nameEditController = TextEditingController();
  final RxBool isEditingPrice = false.obs;
  final TextEditingController priceEditController = TextEditingController();
  final CollectionReference _itemsCollection = FirebaseFirestore.instance.collection(FirebaseX.itemsCollection);

  void startEditingName(String currentName) {
    isEditingPrice.value = false; isEditingName.value = true; nameEditController.text = currentName;
    update(['name_edit_section', 'price_edit_section']);
  }

  void startEditingPrice(String currentPrice) {
    isEditingName.value = false; isEditingPrice.value = true; priceEditController.text = currentPrice;
    update(['name_edit_section', 'price_edit_section']);
  }

  void resetEditState() {
    isEditingName.value = false; isEditingPrice.value = false;
    nameEditController.clear(); priceEditController.clear();
    // update(); // อาจจำเป็นต้องใช้ในบางกรณี
  }

  Future<void> confirmEdit(String itemId) async {
    String fieldToUpdate; dynamic newValue;
    if (isEditingName.value) {
      if (nameEditController.text.trim().isEmpty) { showSnackbar('خطأ', 'الاسم مطلوب.', Colors.orange[800]!); return; }
      fieldToUpdate = 'nameOfItem'; newValue = nameEditController.text.trim();
    } else if (isEditingPrice.value) {
      final int? parsedPrice = int.tryParse(priceEditController.text);
      if (parsedPrice == null || parsedPrice < 0) { showSnackbar('خطأ', 'السعر غير صالح.', Colors.orange[800]!); return; }
      fieldToUpdate = 'priceOfItem'; newValue = parsedPrice;
    } else { resetEditState(); update(['name_edit_section', 'price_edit_section']); return; }

    try {
      await _itemsCollection.doc(itemId).update({ fieldToUpdate: newValue, 'lastUpdated': FieldValue.serverTimestamp() });
      showSnackbar('نجاح', 'تم التحديث.', Colors.green); // <<-- تعريب
      resetEditState(); update(['name_edit_section', 'price_edit_section']);
    } catch (e) { showSnackbar('خطأ', 'فشل التحديث.', Colors.red); debugPrint("Update Error: $e"); }
  }

  void showSnackbar(String title, String message, Color backgroundColor) {
    // التحقق مما إذا كان هناك Snackbar مفتوح بالفعل وإغلاقه لتجنب التداخل
    if (Get.isSnackbarOpen) {
      Get.back();
    }
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: backgroundColor,
      colorText: Colors.white,
      margin: const EdgeInsets.all(10),
      borderRadius: 8,
      duration: const Duration(seconds: 3), // مدة عرض الرسالة
    );
  }
  void cancelEditing() {
    debugPrint("Cancelling edit state.");
    isEditingName.value = false;
    isEditingPrice.value = false;
    nameEditController.clear();    // مسح محتوى حقل الاسم
    priceEditController.clear(); // مسح محتوى حقل السعر
    // يمكنك إضافة update() إذا كنت تحتاج لتحديث واجهة GetBuilder محددة في مكان آخر
  }

  @override
  void onClose() { nameEditController.dispose(); priceEditController.dispose(); debugPrint("GetStreamBuildBoxOfItemController disposed."); super.onClose(); }
}