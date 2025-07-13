
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import 'code8.dart';

// الشاشة الأولى: شبكة عرض لمجموعات الأكواد
class CodeGroupsGridScreen extends StatelessWidget {
  const CodeGroupsGridScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("مجموعات الأكواد"),
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('codeGroups').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // ثلاث أعمدة لكل صف
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.0, // خلايا مربعة
              ),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                // تحويل بيانات الوثيقة إلى Map
                final data = docs[index].data() as Map<String, dynamic>;
                final String codeName = data['codeName'] ?? '';
                final String imageUrl = data['imageUrl'] ?? '';
                final String abbreviation = data['abbreviation'] ?? '';
                final int maxNumber = data['sequenceNumber'] ?? '';

                // تغليف الحاوية باستخدام InkWell لتفعيل النقر
                return GetBuilder<TextControllerCode>(init: TextControllerCode(),builder: (logic) {
                  return InkWell(
                    onTap: () {

                      final uidCologe  = Uuid().v4();

                      // الانتقال إلى شاشة التفاصيل مع تمرير البيانات (ميتا بدون الصورة)
                      logic.extractImageAndNavigate(uidCologe,codeName,maxNumber,abbreviation);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[300],
                        image: imageUrl.isNotEmpty
                            ? DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        )
                            : null,
                      ),
                      child: Stack(
                        children: [
                          // تراكب أسود بنصف شفافية لظهور النص
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 4),
                              decoration: const BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                              ),
                              child: Text(
                                codeName,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                });
              },
            ),
          );
        },
      ),
    );
  }
}
//
// class AddCodesFromImageScreen extends StatefulWidget {
//   final String codeName;
//   final String abbreviation;
//   final int maxDigits; // المعلمة التي تحدد الحد الأقصى لعدد الأحرف لكل رقم
//
//   const AddCodesFromImageScreen({
//     Key? key,
//     required this.codeName,
//     required this.abbreviation,
//     required this.maxDigits,
//   }) : super(key: key);
//
//   @override
//   _AddCodesFromImageScreenState createState() =>
//       _AddCodesFromImageScreenState();
// }
//
// class _AddCodesFromImageScreenState extends State<AddCodesFromImageScreen> {
//   File? _image;
//   List<String> extractedNumbers = [];
//   bool isExtracting = false;
//   bool isSaving = false;
//
//   final ImagePicker _picker = ImagePicker();
//
//   /// اختيار الصورة من المعرض واستدعاء دالة معالجة الصورة لاستخلاص الأرقام
//   Future<void> pickImage() async {
//     final XFile? pickedFile = await _picker.pickImage(
//         source: ImageSource.gallery);
//     if (pickedFile != null) {
//       setState(() {
//         _image = File(pickedFile.path);
//         extractedNumbers = [];
//       });
//       await processImage(File(pickedFile.path));
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("لم يتم اختيار صورة")),
//       );
//     }
//   }
//
//   /// معالجة الصورة باستخدام ML Kit واستخلاص جميع التسلسلات الرقمية باستخدام RegExp
//   Future<void> processImage(File imageFile) async {
//     setState(() {
//       isExtracting = true;
//     });
//     final InputImage inputImage = InputImage.fromFile(imageFile);
//     // نفترض هنا أن النص المكتوب بلغة لاتينية
//     final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
//
//     try {
//       final RecognizedText recognizedText = await textRecognizer.processImage(
//           inputImage);
//       String fullText = recognizedText.text;
//       // استخراج كل التسلسلات الرقمية باستخدام RegExp
//       RegExp regExp = RegExp(r'\d+');
//       final Iterable<RegExpMatch> matches = regExp.allMatches(fullText);
//       // نضيف خطوة تصفية بحيث لا يتم قبول رقم يزيد عدده عن maxDigits
//       final List<String> numbers = matches
//           .map((m) => m.group(0)!)
//           .where((number) => number.length <= widget.maxDigits)
//           .toList();
//
//       setState(() {
//         extractedNumbers = numbers;
//       });
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("حدث خطأ أثناء معالجة الصورة: $e")),
//       );
//     } finally {
//       textRecognizer.close();
//       setState(() {
//         isExtracting = false;
//       });
//     }
//   }
//
//   /// دالة عرض DefaultDialog تحتوي على الأكواد المستخرجة
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
//         onPressed: () => saveCodes(),
//         child: const Text("حسناً"),
//       ),
//     );
//   }
//
//   /// دالة الحفظ (يمكن استخدامها أو تعديلها حسب الحاجة)
//   Future<void> saveCodes() async {
//     if (extractedNumbers.isEmpty) {
//       ScaffoldMessenger.of(context)
//           .showSnackBar(
//           const SnackBar(content: Text("لا توجد أرقام مستخرجة للحفظ")));
//       return;
//     }
//     setState(() {
//       isSaving = true;
//     });
//     try {
//       for (String number in extractedNumbers) {
//         await FirebaseFirestore.instance.collection('codes').add({
//           'number': number,
//           'codeName': widget.codeName,
//           'abbreviation': widget.abbreviation,
//           'timestamp': FieldValue.serverTimestamp(),
//         });
//       }
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("تم حفظ الأكواد بنجاح!")),
//       );
//       setState(() {
//         extractedNumbers = [];
//         _image = null;
//       });
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("حدث خطأ أثناء حفظ الأكواد: $e")),
//       );
//     } finally {
//       setState(() {
//         isSaving = false;
//       });
//     }
//   }
//
//   @override
//   void dispose() {
//     // هنا لا حاجة لاستدعاء dispose للمتحكمات الخارجية مثل ImagePicker
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // إذا لم تُختَر صورة بعد، يتم عرض زر اختيار الصورة
//     if (_image == null) {
//       return Scaffold(
//         appBar: AppBar(
//           title: const Text("إضافة أكواد من الصورة"),
//           backgroundColor: Colors.blueAccent,
//         ),
//         body: Center(
//           child: ElevatedButton.icon(
//             icon: const Icon(Icons.image),
//             label: const Text("اختر صورة"),
//             onPressed: pickImage,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.blueAccent,
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//             ),
//           ),
//         ),
//       );
//     }
//
//     // عند وجود الصورة، يتم عرضها بملء الشاشة مع أيقونة إرسال في الزاوية السفلية
//     return Scaffold(
//       body: Stack(
//         fit: StackFit.expand,
//         children: [
//           // عرض الصورة كخلفية كاملة، يمكنك استخدام BoxFit.cover أو BoxFit.contain حسب الرغبة
//           Image.file(
//             _image!,
//             fit: BoxFit.contain,
//           ),
//           // طبقة تظليل خفيفة لتحسين وضوح العناصر الموضوعة فوق الصورة
//           Container(
//             color: Colors.black.withOpacity(0.3),
//           ),
//           // أيقونة إرسال تظهر في الزاوية السفلية
//           Positioned(
//             bottom: 30,
//             right: 30,
//             child: FloatingActionButton(
//               backgroundColor: Colors.blueAccent,
//               child: const Icon(Icons.send, size: 32),
//               onPressed: showExtractedCodesDialog,
//             ),
//           ),
//           // مؤشر دوران أثناء استخراج الأكواد (إذا كانت العملية جارية)
//           if (isExtracting)
//             const Center(
//               child: CircularProgressIndicator(
//                 color: Colors.white,
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
