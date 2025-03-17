import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerScreen extends StatefulWidget {
  @override
  _ImagePickerScreenState createState() => _ImagePickerScreenState();
}

class _ImagePickerScreenState extends State<ImagePickerScreen> {
  List<Uint8List> allBytes = []; // قائمة لتخزين الصور المحولة

  Future<Uint8List> xFileToUint8List(XFile xFile) async {
    File file = File(xFile.path); // تحويل XFile إلى File
    Uint8List bytes = await file.readAsBytes(); // قراءة البيانات الخام كـ Uint8List
    return bytes;
  }

  Future<List<XFile>> pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? images = await picker.pickMultiImage(); // اختيار عدة صور

    return images ?? [];
  }

  Future<void> processImages() async {
    final List<XFile> images = await pickImages();

    if (images.isNotEmpty) {
      List<Uint8List> newBytes = []; // قائمة مؤقتة

      for (XFile image in images) {
        Uint8List bytes = await xFileToUint8List(image); // تحويل الصور
        newBytes.add(bytes);
      }

      setState(() {
        allBytes = newBytes; // تحديث البيانات
      });

      print("تم معالجة عدد ${allBytes.length} من الصور.");
    } else {
      print("لم يتم اختيار أي صور.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("اختيار الصور"),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: processImages, // استدعاء عملية اختيار الصور
            child: Text("اختر الصور"),
          ),
          Expanded(
            child: allBytes.isNotEmpty
                ? ListView.builder(
              itemCount: allBytes.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.memory(
                    allBytes[index], // عرض الصورة من Uint8List
                    fit: BoxFit.cover,
                    height: 200,
                  ),
                );
              },
            )
                : Center(child: Text("لم يتم اختيار أي صور.")),
          ),
        ],
      ),
    );
  }
}
