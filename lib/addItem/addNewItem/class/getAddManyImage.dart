

import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
 import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';



class getAddManyImage extends GetxController{


bool isAddImage = false;




  static List<String> manyImageUrls = [];

  static List<Uint8List> allBytes =[];




  Future<Uint8List> xFileToUint8List(XFile xFile) async {
  File file = File(xFile.path); // تحويل XFile إلى File
  Uint8List bytes = await file.readAsBytes(); // قراءة البيانات الخام كـ Uint8List
  return bytes;
  }

  Future<List<XFile>> pickImages() async {
  final ImagePicker picker = ImagePicker();
  final List<XFile>? images = await picker.pickMultiImage(limit: 7); // اختيار عدة صور

  // إذا لم يتم اختيار أي صور، إرجاع قائمة فارغة
  return images ?? [];
  }



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


  Future<void> processImages() async {
    final List<XFile> images = await pickImages();

    if (images.isNotEmpty) {
       allBytes = []; // قائمة لتخزين البيانات لجميع الصور

      for (XFile image in images) {
        Uint8List bytes = await xFileToUint8List(image);
        Uint8List? compressedBytes = await compressImage(bytes);
        if (compressedBytes != null) {
          allBytes.add(compressedBytes);
        }// تحويل الصورة إلى Uint8List
        // allBytes.add(bytes); // إضافة البيانات إلى القائمة
        print(isAddImage);

      }
      isAddImage = true;
      update();


      // عرض جميع الصور أو معالجتها دفعة واحدة
      print("تم معالجة عدد ${allBytes.length} من الصور.");
    } else {
      print("لم يتم اختيار أي صور.");
    }
  }






static Future<void> saveManyImage(List<Uint8List> images)async{
  for (var image in images) {
    Reference storage = FirebaseStorage.instance.ref('video').child('StoreManyImage${DateTime.now().microsecondsSinceEpoch}');
    UploadTask uploadTask = storage.putData(image);
    TaskSnapshot snapshot = await uploadTask;
    String imgUrl =await snapshot.ref.getDownloadURL();
    manyImageUrls.add(imgUrl);
  }






}









}






