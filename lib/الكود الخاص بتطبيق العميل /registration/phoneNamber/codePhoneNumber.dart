//
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
// import 'Getx/GetCodePhoneNumber.dart'; // تأكد من المسار الصحيح
// import 'TextFomeFildeCodePhone.dart';   // widget مُخصص لإدخال رقم واحد
//
// class CodePhonePage1 extends StatelessWidget {
//   CodePhonePage1({
//     super.key,
//     required this.phneNumber,
//     required this.imageUser,
//     required this.name,
//     required this.email,
//     required this.password,
//     required this.passwordAndEmail,
//   });
//
//   final String phneNumber;
//   final Uint8List imageUser;
//   final String name;
//   final String email;
//   final String password;
//   final bool passwordAndEmail;
//
//   // متحكمات الحقول الخاصة بكل رقم في رمز التحقق (يفضل أن يتم تقييدها لأرقام واحدة)
//   final TextEditingController c1 = TextEditingController();
//   final TextEditingController c2 = TextEditingController();
//   final TextEditingController c3 = TextEditingController();
//   final TextEditingController c4 = TextEditingController();
//   final TextEditingController c5 = TextEditingController();
//   final TextEditingController c6 = TextEditingController();
//
//   @override
//   Widget build(BuildContext context) {
//     // حساب أبعاد الشاشة لاستخدامها في التصميم
//     double hi = MediaQuery.of(context).size.height;
//     double wi = MediaQuery.of(context).size.width;
//
//     return Scaffold(
//       body: SingleChildScrollView(
//         child: GetBuilder<GetCodePhoneNumber>(
//           // يتم حقن الـ Controller مع تمرير كافة القيم المطلوبة
//           init: GetCodePhoneNumber(
//             password: password,
//             phneNumber: phneNumber,
//             pssworAndEmail: passwordAndEmail,
//             name: name,
//             imageUser: imageUser,
//             email: email,
//             c1: c1,
//             c2: c2,
//             c3: c3,
//             c4: c4,
//             c5: c5,
//             c6: c6,
//           ),
//           builder: (logic) {
//             return Column(
//               children: [
//                 SizedBox(height: hi / 4.5),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 3),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     children: [
//                       // في كل حقل نقوم بتمرير متحكم النص والخواص (first, last)
//                       CodeInputField(
//                         first: true,
//                         last: false,
//                         controller: c1,
//                         correct: logic.correct.value,
//                       ),
//                       CodeInputField(
//                         first: false,
//                         last: false,
//                         controller: c2,
//                         correct: logic.correct.value,
//                       ),
//                       CodeInputField(
//                         first: false,
//                         last: false,
//                         controller: c3,
//                         correct: logic.correct.value,
//                       ),
//                       CodeInputField(
//                         first: false,
//                         last: false,
//                         controller: c4,
//                         correct: logic.correct.value,
//                       ),
//                       CodeInputField(
//                         first: false,
//                         last: false,
//                         controller: c5,
//                         correct: logic.correct.value,
//                       ),
//                       // في الحقل الأخير يتم تمرير callback لإرسال الكود بعد التأكد من اكتمال الإدخال
//                       CodeInputField(
//                         first: false,
//                         last: true,
//                         controller: c6,
//                         correct: logic.correct.value,
//                         onSendCode: () {
//                           // يمكن استبدال طباعة الـ print بـ Get.defaultDialog داخل الـ Controller إذا أردت
//                           try {
//                             logic.sendCode();
//                           } catch (e) {
//                             // عرض رسالة خطأ استخدام Get.defaultDialog عند حدوث استثناء
//                             Get.defaultDialog(
//                               title: 'خطأ',
//                               middleText: 'حدث خطأ أثناء إرسال الكود. الرجاء المحاولة مرة أخرى.',
//                               textConfirm: 'موافق',
//                               onConfirm: () => Get.back(),
//                             );
//                           }
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//                 SizedBox(height: hi / 10),
//                 // قسم إعادة إرسال الكود مع عد تنازلي
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 15),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       GestureDetector(
//                         onTap: () async {
//                           try {
//                             await logic.phoneAuthCode();
//                           } catch (e) {
//                             Get.defaultDialog(
//                               title: 'خطأ',
//                               middleText:
//                               'لم نستطع إعادة إرسال الكود. الرجاء التأكد من اتصالك بالشبكة والمحاولة مرة أخرى.',
//                               textConfirm: 'موافق',
//                               onConfirm: () => Get.back(),
//                             );
//                           }
//                         },
//                         child: Container(
//                           padding: EdgeInsets.symmetric(horizontal: 8),
//                           decoration: BoxDecoration(
//                             border: Border.all(color: Colors.blueAccent),
//                             borderRadius: BorderRadius.circular(15),
//                             color: Colors.black12,
//                           ),
//                           child: Text(
//                             'إعادة إرسال الكود',
//                             style: TextStyle(
//                               color: Colors.blueAccent,
//                               fontSize: wi / 19,
//                               fontWeight: FontWeight.w900,
//                             ),
//                           ),
//                         ),
//                       ),
//                       // عرض العداد التنازلي (مثلاً لتحديد مدة إعادة إرسال الكود)
//                       Text(
//                         logic.counter.value.toString(),
//                         style: TextStyle(color: Colors.black, fontSize: wi / 15),
//                       ),
//                     ],
//                   ),
//                 ),
//                 // عرض مؤشر التحميل (CircularProgressIndicator) إذا كانت العملية جارية
//                 if (logic.isLoading.value)
//                   Center(
//                     child: CircularProgressIndicator(),
//                   ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
