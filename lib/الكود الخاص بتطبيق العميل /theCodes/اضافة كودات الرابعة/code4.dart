import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

import '../../bottonBar/botonBar.dart';
import 'code.dart';

class TextController extends GetxController {
  RxBool isSending = false.obs;
  RxBool isLoading = false.obs;
  int numberOfCode;

  TextController({required this.numberOfCode});

  XFile? image;

  // Pick an image and navigate to the next screen
  Future<void> extractImageAndNavigate(String uuid) async {
    try {
      isLoading.value = true;
      final picker = ImagePicker();
      image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        final file = File(image!.path);
        final uint8list = await file.readAsBytes();
        Get.to(() => ViewImageCode(imageData: uint8list, uuid: uuid));
      } else {
        Get.snackbar("تنبيه", "لم يتم اختيار صورة");
      }
    } catch (e) {
      debugPrint('Error in extractImageAndNavigate: $e');
      Get.snackbar("خطأ", "حدث خطأ أثناء اختيار الصورة");
    } finally {
      isLoading.value = false;
    }
  }

  // Process the image and extract codes
  Future<void> sendImage(String uuid) async {
    if (image == null) {
      Get.snackbar("تنبيه", "لم يتم اختيار صورة");
      return;
    }
    try {
      isSending.value = true;
      update();

      final inputImage = InputImage.fromFile(File(image!.path));
      final textRecognizer = TextRecognizer();
      List<String> validCodes = [];
      List<String> invalidCodes = [];

      try {
        final recognizedText = await textRecognizer.processImage(inputImage);

        for (TextBlock block in recognizedText.blocks) {
          for (TextLine line in block.lines) {
            final extractedText = line.text.trim();
            if (_isNumber(extractedText)) {
              if (extractedText.length == 10 && !validCodes.contains(extractedText)) {
                validCodes.add(extractedText);
              } else if (!invalidCodes.contains(extractedText)) {
                invalidCodes.add(extractedText);
              }
            }
          }
        }
      } finally {
        textRecognizer.close();
      }

      if (validCodes.isEmpty && invalidCodes.isEmpty) {
        Get.snackbar("تنبيه", "لم يتم استخراج أي أكواد");
        return;
      }

      await _showConfirmationDialog(validCodes, invalidCodes, uuid);
    } catch (e) {
      debugPrint('Error in sendImage: $e');
      Get.snackbar("خطأ", "فشل في استخراج الأكواد. يرجى المحاولة مرة أخرى.");
    } finally {
      isSending.value = false;
      update();
    }
  }

  // Show confirmation dialog
  Future<void> _showConfirmationDialog(
      List<String> validCodes, List<String> invalidCodes, String uuid) async {
    String selectedDuration = "month";
    String selectedProvince = "Baghdad";
    final List<Map<String, String>> durationOptions = [
      {"ar": "شهر", "en": "month"},
      {"ar": "ثلاثة أشهر", "en": "three months"},
      {"ar": "ستة أشهر", "en": "six months"},
      {"ar": "تسعة أشهر", "en": "nine months"},
      {"ar": "سنة", "en": "year"}
    ];
    final List<Map<String, String>> iraqProvinces = [
      {"ar": "بغداد", "en": "Baghdad"},
      {"ar": "البصرة", "en": "Basra"},
      {"ar": "نينوى", "en": "Nineveh"},
      {"ar": "الأنبار", "en": "Anbar"},
      {"ar": "كربلاء", "en": "Karbala"},
      {"ar": "النجف", "en": "Najaf"},
      {"ar": "صلاح الدين", "en": "Salahuddin"},
      {"ar": "ديالى", "en": "Diyala"},
      {"ar": "السليمانية", "en": "Sulaymaniyah"},
      {"ar": "أربيل", "en": "Erbil"},
      {"ar": "دهوك", "en": "Dohuk"},
      {"ar": "القادسية", "en": "Qadisiyah"},
      {"ar": "ميسان", "en": "Maysan"},
      {"ar": "ذي قار", "en": "DhiQar"},
      {"ar": "المثنى", "en": "Muthanna"},
      {"ar": "واسط", "en": "Wasit"},
      {"ar": "حلبجة", "en": "Halabja"},
      {"ar": "كركوك", "en": "Kirkuk"},
      {"ar": "بابل", "en": "Babylon"}
    ];

    bool? confirmed = await Get.defaultDialog<bool>(
      title: "تأكيد حفظ ${validCodes.length} أكواد",
      content: StatefulBuilder(builder: (context, setState) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCodeSection("الأكواد الصحيحة:", validCodes, Colors.green),
              const Divider(),
              _buildCodeSection("الأكواد الخاطئة:", invalidCodes, Colors.red),
              const Divider(),
              _buildDropdownSection(
                "مدة التفعيل:",
                durationOptions.map((e) => e['ar']!).toList(),
                durationOptions.firstWhere((e) => e['en'] == selectedDuration)['ar']!,
                    (newValue) {
                  setState(() {
                    selectedDuration = durationOptions
                        .firstWhere((e) => e['ar'] == newValue)['en']!;
                  });
                },
              ),
              _buildDropdownSection(
                "المحافظة:",
                iraqProvinces.map((e) => e['ar']!).toList(),
                iraqProvinces.firstWhere((e) => e['en'] == selectedProvince)['ar']!,
                    (newValue) {
                  setState(() {
                    selectedProvince = iraqProvinces
                        .firstWhere((e) => e['ar'] == newValue)['en']!;
                  });
                },
              ),
            ],
          ),
        );
      }),
      textConfirm: "حفظ",
      textCancel: "إلغاء",
      confirmTextColor: Colors.white,
      onConfirm: () async {
        Get.back(result: true);
        await _saveCodes(validCodes, selectedDuration, selectedProvince, uuid);
      },
      onCancel: () => Get.back(result: false),
    );

    if (confirmed != true) {
      Get.snackbar("تنبيه", "تم إلغاء عملية الحفظ");
    }
  }

  // Save codes to Firestore
  Future<void> _saveCodes(
      List<String> validCodes, String duration, String province, String uuid) async {
    for (String code in validCodes) {
      await FirebaseFirestore.instance.collection('codes').doc().set({
        'code': code,
        'duration': duration,
        'province': province,
        'isRUN': false,
        'is4': true,
        'uidCologe': uuid,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
    Get.snackbar("تم الحفظ", "تم حفظ ${validCodes.length} أكواد بنجاح");
    Get.offAll(() => BottomBar(initialIndex: 2));
  }

  // Build code section widget
  Widget _buildCodeSection(String title, List<String> codes, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        codes.isNotEmpty
            ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: codes
              .map((code) => Text(code, style: TextStyle(color: color)))
              .toList(),
        )
            : const Text("لم يتم العثور على أكواد"),
      ],
    );
  }

  // Build dropdown section widget
  Widget _buildDropdownSection(
      String title, List<String> items, String selectedValue, ValueChanged<String?> onChanged) {
    final uniqueItems = items.toSet().toList();

    if (!uniqueItems.contains(selectedValue)) {
      selectedValue = (uniqueItems.isNotEmpty ? uniqueItems.first : null)!;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        DropdownButton<String>(
          value: selectedValue,
          items: uniqueItems
              .map((item) => DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          ))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  // Check if a string is a number
  bool _isNumber(String text) {
    final regex = RegExp(r'^\d+$');
    return regex.hasMatch(text);
  }
}