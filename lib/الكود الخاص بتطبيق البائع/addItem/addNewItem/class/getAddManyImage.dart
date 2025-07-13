import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../../../../XXX/xxx_firebase.dart';


class GetAddManyImage extends GetxController {
  final RxList<Uint8List> selectedImageBytes = <Uint8List>[].obs; // <--- استخدم RxList هنا

  // --- لا نستخدم قوائم static ---
  // static List<String> manyImageUrls = [];
  // static List<Uint8List> allBytes = [];
  // ---

  final RxBool isProcessing = false.obs; // حالة المعالجة

  // --- إزالة isAddImage، الاعتماد على selectedImageBytes.isNotEmpty ---
  // bool isAddImage = false;
  // ---

  // وظيفة لإزالة صورة
  void removeImageAt(int index) {
    if (index >= 0 && index < selectedImageBytes.length) {
      selectedImageBytes.removeAt(index);
      debugPrint("Removed image at index $index");
    }
  }

  // إعادة تعيين الحالة
  void reset() {
    selectedImageBytes.clear();
    isProcessing.value = false;
    debugPrint("AddManyImage controller reset.");
  }

  /// تحويل XFile إلى Uint8List
  Future<Uint8List> xFileToUint8List(XFile xFile) async {
    File file = File(xFile.path); // تحويل XFile إلى File
    Uint8List bytes = await file.readAsBytes(); // قراءة البيانات الخام كـ Uint8List
    return bytes;
  }

  /// اختيار عدة صور باستخدام ImagePicker
  Future<List<XFile>> pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images =
    await picker.pickMultiImage(limit: 7); // اختيار ما يصل إلى 7 صور
    return images; // إذا لم يتم اختيار أي صور، إرجاع قائمة فارغة
  }

  /// ضغط الصورة لتقليل حجمها
  Future<Uint8List?> compressImage(Uint8List imageData) async {
    try {
      return await FlutterImageCompress.compressWithList(
        imageData,
        minWidth: 800, // العرض الأدنى
        minHeight: 800, // الطول الأدنى
        quality: 85, // مستوى الجودة (0-100)
      );
    } catch (e) {
      debugPrint("خطأ أثناء ضغط الصورة: $e");
      return null;
    }
  }

  /// معالجة الصور (اختيار + ضغط + تخزين)
  // معالجة واختيار الصور وتحديث الحالة التفاعلية
  Future<void> processAndSelectImages() async {
    final List<XFile> images = await pickImages();
    if (images.isNotEmpty) {
      isProcessing.value = true;
      List<Uint8List> tempBytes = []; // قائمة مؤقتة لتجنب تحديث الواجهة لكل صورة
      for (XFile image in images) {
        try {
          Uint8List bytes = await xFileToUint8List(image);
          Uint8List? compressedBytes = await compressImage(bytes);
          if (compressedBytes != null) { tempBytes.add(compressedBytes); }
        } catch (e) { debugPrint("Error processing single image: $e"); }
      }
      // --- تحديث القائمة التفاعلية مرة واحدة ---
      selectedImageBytes.assignAll(tempBytes);
      // ---
      isProcessing.value = false;
      debugPrint("Processed ${selectedImageBytes.length} images.");
    } else { debugPrint("No images selected."); }
  }

  // --- دالة الرفع الآن ترجع قائمة الروابط ---
  Future<List<String>> uploadAndGetUrls(String parentId) async {
    if (selectedImageBytes.isEmpty) return []; // لا صور للرفع

    List<String> uploadedUrls = [];
    isProcessing.value = true; // يمكنك إظهار مؤشر تحميل مختلف للرفع

    try {
      for (int i = 0; i < selectedImageBytes.length; i++) {
        final imageBytes = selectedImageBytes[i];
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final imageName = 'image_${i}_$timestamp.jpg'; // اسم ملف فريد
        // مسار أكثر تنظيماً: اسم المجموعة / معرف العنصر / الصور المتعددة / اسم الصورة
        final Reference storageRef = FirebaseStorage.instance
            .ref(FirebaseX.StorgeApp) // تأكد من تعريف هذا
            .child('item_images')     // اسم مجلد رئيسي
            .child(parentId)         // ID المنتج/العرض
            .child('additional')     // مجلد للصور الإضافية
            .child(imageName);

        debugPrint("Uploading image ${i+1} to: ${storageRef.fullPath}");
        UploadTask uploadTask = storageRef.putData(imageBytes);
        TaskSnapshot snapshot = await uploadTask;
        String imgUrl = await snapshot.ref.getDownloadURL();
        uploadedUrls.add(imgUrl);
        debugPrint("Uploaded image ${i+1}, URL: $imgUrl");
      }
    } catch (e) {
      debugPrint("Error during multi-image upload: $e");
      Get.snackbar("خطأ رفع", "حدث خطأ أثناء رفع بعض الصور الإضافية.", colorText: Colors.white, backgroundColor: Colors.red);
      // يمكنك اختيار إرجاع القائمة الجزئية أو قائمة فارغة للإشارة للخطأ
      // return [];
    } finally {
      isProcessing.value = false; // إيقاف مؤشر الرفع
    }

    debugPrint("Finished uploading ${uploadedUrls.length} images.");
    return uploadedUrls; // إرجاع قائمة الروابط
  }
}




