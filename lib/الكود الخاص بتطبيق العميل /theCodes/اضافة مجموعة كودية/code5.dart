import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class AddCodeGroupController extends GetxController {
  final TextEditingController codeNameController = TextEditingController();
  final TextEditingController abbreviationController = TextEditingController();
  final TextEditingController sequenceNumberController = TextEditingController();
  final TextEditingController definitionController = TextEditingController();

  final Rxn<XFile> selectedImage = Rxn<XFile>();
  final RxBool isUploading = false.obs;
  final RxBool isSaving = false.obs;

  final RxInt importance = 1.obs;

  Future<void> pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        selectedImage.value = image;
      } else {
        Get.snackbar("تنبيه", "لم يتم اختيار صورة");
      }
    } catch (e) {
      Get.snackbar("خطأ", "حدث خطأ أثناء اختيار الصورة: $e");
    }
  }

  Future<String?> uploadImage(File file) async {
    try {
      isUploading.value = true;
      String fileName = Uuid().v1();
      Reference storageRef = FirebaseStorage.instance.ref().child('codeGroups').child(fileName);
      UploadTask uploadTask = storageRef.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      Get.snackbar("خطأ", "فشل رفع الصورة: $e");
      return null;
    } finally {
      isUploading.value = false;
    }
  }

  Future<void> saveCodeGroup() async {
    try {
      if (codeNameController.text.trim().isEmpty ||
          abbreviationController.text.trim().isEmpty ||
          sequenceNumberController.text.trim().isEmpty ||
          definitionController.text.trim().isEmpty ||
          selectedImage.value == null) {
        Get.snackbar("تنبيه", "يرجى تعبئة جميع الحقول واختيار صورة");
        return;
      }

      isSaving.value = true;

      String? imageUrl = await uploadImage(File(selectedImage.value!.path));
      if (imageUrl == null) return;

      await FirebaseFirestore.instance.collection('codeGroups').add({
        'codeName': codeNameController.text.trim(),
        'abbreviation': abbreviationController.text.trim(),
        'sequenceNumber': int.tryParse(sequenceNumberController.text.trim()),
        'definition': definitionController.text.trim(),
        'imageUrl': imageUrl,
        'importance': importance.value,
        'timestamp': FieldValue.serverTimestamp(),
      });

      Get.snackbar("نجاح", "تم حفظ مجموعة الأكواد بنجاح!");

      codeNameController.clear();
      abbreviationController.clear();
      sequenceNumberController.clear();
      definitionController.clear();
      selectedImage.value = null;
      importance.value = 1;
    } catch (e) {
      Get.snackbar("خطأ", "حدث خطأ أثناء حفظ البيانات: $e");
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    codeNameController.dispose();
    abbreviationController.dispose();
    sequenceNumberController.dispose();
    definitionController.dispose();
    super.onClose();
  }
}