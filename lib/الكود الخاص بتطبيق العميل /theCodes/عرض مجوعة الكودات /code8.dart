// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// import 'code7.dart';
// import 'code9.dart';
//
// /// Controller لإدارة حالة الشاشة واستخلاص الأكواد والحفظ
// class AddCodesFromImageController extends GetxController {
//   // المعطيات القادمة من الصفحة السابقة
//   final String codeName;
//   final String abbreviation;
//   final int maxDigits;
//
//   AddCodesFromImageController({
//     required this.codeName,
//     required this.abbreviation,
//     required this.maxDigits,
//   });
//
//   // المتغيرات التي تراقب الحالة
//   Rx<File?> image = Rx<File?>(null);
//   RxList<String> extractedNumbers = <String>[].obs;
//   RxBool isExtracting = false.obs;
//   RxBool isSaving = false.obs;
//
//   final ImagePicker _picker = ImagePicker();
//
//   /// اختيار الصورة من المعرض واستدعاء عملية الاستخلاص
//   Future<void> pickImage(String codeName,String abbreviation,int maxDigits,) async {
//     final XFile? pickedFile =
//     await _picker.pickImage(source: ImageSource.gallery);
//     if (pickedFile != null) {
//       image.value = File(pickedFile.path);
//       extractedNumbers.clear();
//       await processImage(File(pickedFile.path));
//       Get.to(AddCodesFromImageScreen(codeName: codeName,abbreviation: abbreviation,maxDigits: maxDigits,));
//     } else {
//       Get.snackbar("تنبيه", "لم يتم اختيار صورة");
//     }
//   }
//
//
//   /// استخدام ML Kit لاستخلاص النص من الصورة ثم استخراج التسلسلات الرقمية
//   Future<void> processImage(File imageFile) async {
//     isExtracting.value = true;
//     final InputImage inputImage = InputImage.fromFile(imageFile);
//     // نفترض هنا أن النص مكتوب بلغة لاتينية
//     final textRecognizer =
//     TextRecognizer(script: TextRecognitionScript.latin);
//
//     try {
//       final RecognizedText recognizedText =
//       await textRecognizer.processImage(inputImage);
//       String fullText = recognizedText.text;
//       // استخراج كل التسلسلات الرقمية باستخدام RegExp
//       RegExp regExp = RegExp(r'\d+');
//       final List<String> numbers = regExp
//           .allMatches(fullText)
//           .map((m) => m.group(0)!)
//           .where((number) => number.length <= maxDigits)
//           .toList();
//
//       extractedNumbers.assignAll(numbers);
//     } catch (e) {
//       Get.snackbar("خطأ", "حدث خطأ أثناء معالجة الصورة: $e");
//     } finally {
//       textRecognizer.close();
//       isExtracting.value = false;
//     }
//   }
//
//   /// عرض Dialog يحتوي على الأكواد المستخرجة
//   void showExtractedCodesDialog() {
//     Get.defaultDialog(
//       title: "الأكواد المستخرجة",
//       content: extractedNumbers.isNotEmpty
//           ? SingleChildScrollView(
//         child: Text(
//           extractedNumbers.join(', '),
//           textAlign: TextAlign.center,
//           style: const TextStyle(fontSize: 16),
//         ),
//       )
//           : const Text("لا توجد أكواد مستخرجة"),
//       confirm: ElevatedButton(
//         onPressed: () => Get.back(),
//         child: const Text("حسناً"),
//       ),
//     );
//   }
//
//   /// حفظ الأكواد في Firestore مع المعطيات الواردة والوقت الحالي
//   Future<void> saveCodes() async {
//     if (extractedNumbers.isEmpty) {
//       Get.snackbar("تنبيه", "لا توجد أرقام مستخرجة للحفظ");
//       return;
//     }
//     isSaving.value = true;
//     try {
//       for (String number in extractedNumbers) {
//         await FirebaseFirestore.instance.collection('codes').add({
//           'number': number,
//           'codeName': codeName,
//           'abbreviation': abbreviation,
//           'timestamp': FieldValue.serverTimestamp(),
//         });
//       }
//       Get.snackbar("نجاح", "تم حفظ الأكواد بنجاح!");
//       extractedNumbers.clear();
//       image.value = null;
//     } catch (e) {
//       Get.snackbar("خطأ", "حدث خطأ أثناء حفظ الأكواد: $e");
//     } finally {
//       isSaving.value = false;
//     }
//   }
// }


//
// import 'dart:io';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:get/get.dart';
// import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:uuid/uuid.dart';
//
// import '../../bottonBar/botonBar.dart';
// import '../اضافة كودات الرابعة/code.dart';
// import 'code9.dart';
//
// class TextControllerCode extends GetxController {
//   // حالة التجهيز والإرسال
//   RxBool isSending = false.obs;
//   RxBool isLoading = false.obs;
//   int? NumberOfCode ;
//   final String? codeName;
//   final String? abbreviation;
//
//   TextControllerCode({ this.NumberOfCode, this.abbreviation, this.codeName});
//
//   // الصورة المختارة
//   XFile? image;
//
//   /// دالة لاختيار الصورة من المعرض وعرضها للمستخدم (مع استخدام Uint8List)
//   Future<void> extractImageAndNavigate(String uuid,) async {
//     try {
//       isLoading.value = true;
//       final picker = ImagePicker();
//       image = await picker.pickImage(source: ImageSource.gallery);
//
//       if (image != null) {
//         final file = File(image!.path);
//         final uint8list = await file.readAsBytes();
//         // الانتقال إلى صفحة معاينة الصورة مع عرضها باستخدام Uint8List
//         Get.to(() => AddCodesFromImageScreen(imageData: uint8list,uuid: uuid,));
//       } else {
//         Get.snackbar("تنبيه", "لم يتم اختيار صورة");
//       }
//     } catch (e) {
//       debugPrint('Error in extractImageAndNavigate: $e');
//       Get.snackbar("خطأ", "حدث خطأ أثناء اختيار الصورة");
//     } finally {
//       isLoading.value = false;
//     }
//   }
//
//
//
//
//   Future<void> sendImage(String uuid) async {
//     if (image == null) {
//       Get.snackbar("تنبيه", "لا يوجد صورة مختارة");
//       return;
//     }
//     try {
//
//       isSending.value = true;
//       update();
//
//       // إنشاء InputImage من ملف الصورة المختارة
//       final inputImage = InputImage.fromFile(File(image!.path));
//       final textRecognizer = TextRecognizer();
//       final RecognizedText recognizedText =
//       await textRecognizer.processImage(inputImage);
//       await textRecognizer.close();
//
//       // عدد الأحرف المطلوب لكل كود (مثلاً 10)
//       final int requiredCodeLength = NumberOfCode!;
//
//       // قوائم لتجميع الأكواد الصحيحة والخاطئة
//       List<String> validCodes = [];
//       List<String> invalidCodes = [];
//
//       // استخراج الأكواد من النصوص
//       for (TextBlock block in recognizedText.blocks) {
//         for (TextLine line in block.lines) {
//           final extractedText = line.text.trim();
//           if (_isNumber(extractedText)) {
//             if (extractedText.length == requiredCodeLength) {
//               if (!validCodes.contains(extractedText)) {
//                 validCodes.add(extractedText);
//               }
//             } else {
//               if (!invalidCodes.contains(extractedText)) {
//                 invalidCodes.add(extractedText);
//               }
//             }
//           }
//         }
//       }
//
//       if (validCodes.isEmpty && invalidCodes.isEmpty) {
//         Get.snackbar("تنبيه", "لم يتم استخراج أي أكواد");
//         return;
//       }
//
//       // متغير لتحديد مدة تفعيل البث الرقمي مع القيمة الافتراضية "شهر"
//       // String selectedDuration = "m";
//       // قائمة الخيارات الخاصة بمدة التفعيل
//       // List<String> durationOptions = ["m", "3m",'6m', "9m", "12m"];
//       String selectedDuration = "month";
//
//       final List<Map<String, String>> durationOptions = [
//         {"ar": "شهر", "en": "month"},
//         {"ar": "ثلاثة أشهر", "en": "three months"},
//         {"ar": "ستة أشهر", "en": "six months"},
//         {"ar": "تسعة أشهر", "en": "nine months"},
//         {"ar": "سنة", "en": "year"}
//       ];
//
//
//       // عرض نافذة تأكيد تحتوي على القسمين (الأكواد الصحيحة والخاطئة) مع اختيار مدة التفعيل
//       bool? confirmed = await Get.defaultDialog<bool>(
//         title: "اكواد ${(validCodes.length)}تأكيد حفظ",
//         content: StatefulBuilder(builder: (context, setState) {
//           return SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // قسم الأكواد الصحيحة
//                 Center(
//                   child: const Text(
//                     "الأكواد الصحيحة:",
//                     style: TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                 ),
//                 validCodes.isNotEmpty
//                     ? Center(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: validCodes
//                         .map((code) => Text(
//                       code,
//                       style: const TextStyle(color: Colors.green),
//                     ))
//                         .toList(),
//                   ),
//                 )
//                     : Center(child: const Text("لا توجد أكواد صحيحة")),
//                 const Divider(),
//                 // قسم الأكواد الخاطئة
//                 Center(
//                   child: const Text(
//                     "الأكواد الخاطئة:",
//                     style: TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                 ),
//                 invalidCodes.isNotEmpty
//                     ? Center(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: invalidCodes
//                         .map((code) => Text(
//                       code,
//                       style: const TextStyle(color: Colors.red),
//                     ))
//                         .toList(),
//                   ),
//                 )
//                     : Center(child: const Text("لا توجد أكواد خاطئة")),
//                 const Divider(),
//                 // اختيار مدة تفعيل البث الرقمي
//                 Center(
//                   child: const Text(
//                     "مدة تفعيل الكود:",
//                     style: TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                 ),
//                 Center(
//                   child: DropdownButton<String>(
//                     value: selectedDuration,
//                     items: durationOptions
//                         .map((option) => DropdownMenuItem<String>(
//                       value: option,
//                       child: Text(option),
//                     ))
//                         .toList(),
//                     onChanged: (newValue) {
//                       if (newValue != null) {
//                         setState(() {
//
//                         selectedDuration = newValue;
//                         });
//                       }
//                     },
//                   ),
//                 ),
//                 Center(
//                   child: const Text(
//                     'المحافظة',
//                     style: TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                 ),
//
//               ],
//             ),
//           );
//         }),
//         textConfirm: "حفظ",
//         textCancel: "إلغاء",
//         confirmTextColor: Colors.white,
//         onConfirm: () {
//
//
//           Get.back(result: true);
//
//         },
//         onCancel: () {
//           Get.back(result: false);
//         },
//       );
//
//       if (confirmed == true) {
//         // حفظ الأكواد الصحيحة إلى Firebase مع إضافة مدة التفعيل فقط
//         for (String code in validCodes) {
//           final uid = Uuid().v4();
//           await FirebaseFirestore.instance.collection('codes').doc(uid).set({
//             'code': code,
//             'codeName':codeName,
//             'abbreviation':abbreviation,
//             'duration': selectedDuration, // حفظ مدة التفعيل المُختارة فقط
//             'isRUN':false,
//             'is4':false,
//             'uid':uid,
//             'uidCologe':uuid,
//             'timestamp': FieldValue.serverTimestamp(),
//           });
//         }
//         Get.snackbar("تم حفظ","عدد ${(validCodes.length)}"
//             "المدة ${(selectedDuration)}"
//             "المكان ${()}");
//         Get.offAll(() => BottomBar(theIndex: 2));
//       } else {
//         Get.snackbar("تنبيه", "تم إلغاء عملية الحفظ");
//       }
//     } catch (e) {
//       debugPrint('Error in sendImage: $e');
//       Get.snackbar("خطأ", "فشل استخراج الأكواد. الرجاء إعادة المحاولة.");
//     } finally {
//       isSending.value = false;
//       update();
//     }
//   }
//
//
//
//   /// دالة التحقق مما إذا كان النص يحتوي على أرقام فقط
//   bool _isNumber(String text) {
//     final regex = RegExp(r'^\d+$');
//     return regex.hasMatch(text);
//   }
// }





import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../bottonBar/botonBar.dart';
import 'code9.dart';

class TextControllerCode extends GetxController {
  // حالة التجهيز والإرسال
  RxBool isSending = false.obs;
  RxBool isLoading = false.obs;

  // عدد الأحرف المطلوبة لكل كود
  int? numberOfCode;

  // معلومات الكود

  // الصورة المختارة
  XFile? image;


  /// اختيار الصورة من المعرض
  Future<void> extractImageAndNavigate(String uuid,String codeName,int maxNumber,String abbreviation) async {
    try {
      isLoading.value = true;
      final picker = ImagePicker();
      image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        final file = File(image!.path);
        final uint8list = await file.readAsBytes();
        Get.to(() => AddCodesFromImageScreen(abbreviation:abbreviation,imageData: uint8list, uuid: uuid,codeName1: codeName,maxNumber: maxNumber,));
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

  /// إرسال الصورة ومعالجة النصوص
  Future<void> sendImage(String uuid,String codeName1,int maxNumber,String abbreviation) async {
    if (image == null) {
      Get.snackbar("تنبيه", "لا يوجد صورة مختارة");
      return;
    }
    try {
      isSending.value = true;
      update();

      // إنشاء InputImage من ملف الصورة
      final inputImage = InputImage.fromFile(File(image!.path));
      final textRecognizer = TextRecognizer();
      final recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      // قوائم الأكواد
      List<String> validCodes = [];
      List<String> invalidCodes = [];

      // استخراج الأكواد من النصوص
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          final extractedText = line.text.trim();
          if (_isNumber(extractedText)) {
            if (extractedText.length == maxNumber) {
              if (!validCodes.contains(extractedText)) {
                validCodes.add(extractedText);
              }
            } else {
              if (!invalidCodes.contains(extractedText)) {
                invalidCodes.add(extractedText);
              }
            }
          }
        }
      }

      if (validCodes.isEmpty && invalidCodes.isEmpty) {
        Get.snackbar("تنبيه", "لم يتم استخراج أي أكواد");
        return;
      }

      // خيارات مدة التفعيل
      String selectedDuration = "month";
      final List<Map<String, String>> durationOptions = [
        {"ar": "شهر", "en": "month"},
        {"ar": "ثلاثة أشهر", "en": "three months"},
        {"ar": "ستة أشهر", "en": "six months"},
        {"ar": "تسعة أشهر", "en": "nine months"},
        {"ar": "سنة", "en": "year"}
      ];
      // عرض نافذة التأكيد
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
                  durationOptions,
                  selectedDuration,
                      (newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedDuration = newValue;
                      });
                    }
                  },
                ),
              ],
            ),
          );
        }),
        textConfirm: "حفظ",
        textCancel: "إلغاء",
        confirmTextColor: Colors.white,
        onConfirm: () {
          Get.back(result: true);
        },
        onCancel: () {
          Get.back(result: false);
        },
      );

      if (confirmed == true) {
        // حفظ الأكواد الصحيحة إلى Firestore
        for (String code in validCodes) {
          final uid = Uuid().v4();
          await FirebaseFirestore.instance.collection('codes').doc(uid).set({
            'code': code,
            'codeName': codeName1,
            'abbreviation': abbreviation,
            'duration': selectedDuration,
            'isRUN': false,
            'is4': false,
            'uid': uid,
            'uidCologe': uuid,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }

        Get.snackbar("تم الحفظ", "تم حفظ ${validCodes.length} أكواد بنجاح");
        Get.offAll(() => BottomBar(initialIndex: 2));
      } else {
        Get.snackbar("تنبيه", "تم إلغاء عملية الحفظ");
      }
    } catch (e) {
      debugPrint('Error in sendImage: $e');
      Get.snackbar("خطأ", "فشل استخراج الأكواد. الرجاء إعادة المحاولة.");
    } finally {
      isSending.value = false;
      update();
    }
  }

  /// التحقق مما إذا كان النص يحتوي على أرقام فقط
  bool _isNumber(String text) {
    final regex = RegExp(r'^\d+$');
    return regex.hasMatch(text);
  }

  /// بناء قسم الأكواد
  Widget _buildCodeSection(String title, List<String> codes, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        codes.isNotEmpty
            ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: codes.map((code) => Text(code, style: TextStyle(color: color))).toList(),
        )
            : const Text("لا توجد أكواد"),
      ],
    );
  }

  /// بناء قسم القائمة المنسدلة
  /// Building the dropdown section
  Widget _buildDropdownSection(
      String title,
      List<Map<String, String>> items,
      String selectedValue,
      ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        DropdownButton<String>(
          value: items.firstWhere((item) => item['en'] == selectedValue)['ar'],
          items: items
              .map((item) => DropdownMenuItem<String>(
            value: item['ar'],
            child: Text(item['ar']!),
          ))
              .toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              final selectedItem =
              items.firstWhere((item) => item['ar'] == newValue);
              onChanged(selectedItem['en']);
            }
          },
        ),
      ],
    );
  }
}

