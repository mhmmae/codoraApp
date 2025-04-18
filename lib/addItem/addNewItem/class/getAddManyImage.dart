
//
// import 'dart:io';
//
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:get/get.dart';
// import 'package:image_picker/image_picker.dart';
//  import 'dart:typed_data';
// import 'package:flutter_image_compress/flutter_image_compress.dart';
//
//
//
// class GetAddManyImage extends GetxController{
//
//
// bool isAddImage = false;
//
// bool isProcessing = false;
//
//
//   static List<String> manyImageUrls = [];
//
//   static List<Uint8List> allBytes =[];
//   void startProcessing() {
//   isProcessing = true;
//   update();
//   }
//
//   void stopProcessing() {
//   isProcessing = false;
//   update();
//   }
//
//
//
//   Future<Uint8List> xFileToUint8List(XFile xFile) async {
//   File file = File(xFile.path); // تحويل XFile إلى File
//   Uint8List bytes = await file.readAsBytes(); // قراءة البيانات الخام كـ Uint8List
//   return bytes;
//   }
//
//   Future<List<XFile>> pickImages() async {
//   final ImagePicker picker = ImagePicker();
//   final List<XFile>? images = await picker.pickMultiImage(limit: 7); // اختيار عدة صور
//
//   // إذا لم يتم اختيار أي صور، إرجاع قائمة فارغة
//   return images ?? [];
//   }
//
//
//
// Future<Uint8List?> compressImage(Uint8List imageData) async {
//   try {
//     return await FlutterImageCompress.compressWithList(
//       imageData,
//       minWidth: 800, // العرض الأدنى
//       minHeight: 800, // الطول الأدنى
//       quality: 85, // مستوى الجودة (0-100)
//     );
//   } catch (e) {
//     print("خطأ أثناء ضغط الصورة: $e");
//     return null;
//   }
// }
//
//
//   Future<void> processImages() async {
//     final List<XFile> images = await pickImages();
//
//     if (images.isNotEmpty) {
//        allBytes = []; // قائمة لتخزين البيانات لجميع الصور
//
//        // إضافة منطق معالجة الصور هنا
//        await Future.delayed(const Duration(seconds: 3)); // محاكاة وقت المعالجة
//        isAddImage = true;
//        update();
//
//       for (XFile image in images) {
//         Uint8List bytes = await xFileToUint8List(image);
//         Uint8List? compressedBytes = await compressImage(bytes);
//         if (compressedBytes != null) {
//           allBytes.add(compressedBytes);
//         }// تحويل الصورة إلى Uint8List
//         // allBytes.add(bytes); // إضافة البيانات إلى القائمة
//         print(isAddImage);
//
//       }
//       isAddImage = true;
//       update();
//
//
//       // عرض جميع الصور أو معالجتها دفعة واحدة
//       print("تم معالجة عدد ${allBytes.length} من الصور.");
//     } else {
//       print("لم يتم اختيار أي صور.");
//     }
//   }
//
//
//
//
//
//
// static Future<void> saveManyImage(List<Uint8List> images)async{
//   for (var image in images) {
//     Reference storage = FirebaseStorage.instance.ref('video').child('StoreManyImage${DateTime.now().microsecondsSinceEpoch}');
//     UploadTask uploadTask = storage.putData(image);
//     TaskSnapshot snapshot = await uploadTask;
//     String imgUrl =await snapshot.ref.getDownloadURL();
//     manyImageUrls.add(imgUrl);
//   }
//
//
//
//
//
//
// }
//
//
//
//
//
//
//
//
//
// }
//
//




import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class GetAddManyImage extends GetxController {
  // حالة إضافة الصور
  bool isAddImage = false;

  // حالة معالجة الصور
  bool isProcessing = false;

  // قائمة لتخزين روابط الصور على Firebase
  static List<String> manyImageUrls = [];

  // قائمة لتخزين بيانات الصور كـ Uint8List
  static List<Uint8List> allBytes = [];

  /// بدء عملية معالجة الصور
  void startProcessing() {
    isProcessing = true;
    update();
  }

  /// إنهاء عملية معالجة الصور
  void stopProcessing() {
    isProcessing = false;
    update();
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
    final List<XFile>? images =
    await picker.pickMultiImage(limit: 7); // اختيار ما يصل إلى 7 صور
    return images ?? []; // إذا لم يتم اختيار أي صور، إرجاع قائمة فارغة
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
      print("خطأ أثناء ضغط الصورة: $e");
      return null;
    }
  }

  /// معالجة الصور (اختيار + ضغط + تخزين)
  Future<void> processImages() async {
    final List<XFile> images = await pickImages(); // اختيار الصور

    if (images.isNotEmpty) {
      startProcessing(); // بدء شريط التقدم
      allBytes.clear(); // إعادة تعيين القائمة

      for (XFile image in images) {
        try {
          Uint8List bytes = await xFileToUint8List(image); // تحويل الصورة
          Uint8List? compressedBytes = await compressImage(bytes); // ضغط الصورة
          if (compressedBytes != null) {
            allBytes.add(compressedBytes); // إضافة الصورة المضغوطة
          }
        } catch (e) {
          print("خطأ أثناء معالجة الصورة: $e");
        }
      }

      isAddImage = true;
      stopProcessing(); // إنهاء شريط التقدم
      update();
      print("تم معالجة عدد ${allBytes.length} من الصور.");
    } else {
      stopProcessing();
      print("لم يتم اختيار أي صور.");
    }
  }

  /// حفظ الصور على Firebase وتوليد روابطها
  static Future<void> saveManyImage(List<Uint8List> images) async {
    for (var image in images) {
      try {
        Reference storage = FirebaseStorage.instance
            .ref('images')
            .child('StoreManyImage${DateTime.now().microsecondsSinceEpoch}');
        UploadTask uploadTask = storage.putData(image); // رفع الصورة
        TaskSnapshot snapshot = await uploadTask;
        String imgUrl = await snapshot.ref.getDownloadURL(); // توليد الرابط
        manyImageUrls.add(imgUrl); // إضافة الرابط إلى القائمة
      } catch (e) {
        print("خطأ أثناء رفع الصورة إلى Firebase: $e");
      }
    }
    print("تم رفع جميع الصور. عدد الروابط: ${manyImageUrls.length}");
  }
}




