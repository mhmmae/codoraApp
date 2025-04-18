//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_sign_in/google_sign_in.dart';
//
// import '../../XXX/XXXFirebase.dart';
// import '../../bottonBar/botonBar.dart';
// import '../InfomationUser/informationUser.dart';
// import '../signin/signinPage.dart';
//
//
// class Getsignup extends GetxController{
//   TextEditingController email = TextEditingController();
//   TextEditingController password = TextEditingController();
//   // GlobalKey<FormState> globalKey = GlobalKey<FormState>();
//   bool isLoding =false;
//   Getsignup({required this.email,required this.password});
//
//
//
//
//   Future<void> SignUp(BuildContext context,GlobalKey<FormState> globalKey) async {
//     if (globalKey.currentState!.validate()) {
//       try {
//         isLoding =true;
//         update();
//
//
//         await FirebaseAuth.instance.createUserWithEmailAndPassword(
//           email: email.text,
//           password: password.text,
//         ).then((value)async{
//
//           User? user1 = FirebaseAuth.instance.currentUser;
//
//           await user1!.sendEmailVerification().then((value){
//             Navigator.push(context, MaterialPageRoute(builder: (context)=>SignInPage(isFirstTime: true,)));
//             isLoding =false;
//             update();
//
//           });
//         });
//       } on FirebaseAuthException catch (e) {
//         if (e.code == 'weak-password') {
//           return showDialog(context: context, builder: (context)=>AlertDialog(
//             actions: [
//               IconButton(onPressed: (){
//                 Navigator.of(context).pop();
//                 Navigator.of(context).pop();
//                 isLoding =false;
//                 update();
//               }, icon: Icon(Icons.close))
//             ],
//             title: Text('الباسورد ضعيف'),
//             content: Text('يجب ان يكون اكثر من 6'),
//           ));
//           print('The password provided is too weak.');
//         } else if (e.code == 'email-already-in-use') {
//           return showDialog(context: context, builder: (context)=>AlertDialog(
//             actions: [
//               IconButton(onPressed: (){
//                 Navigator.of(context).pop();
//                 isLoding =false;
//                 update();
//               }, icon: Icon(Icons.close))
//             ],
//             title: Text('الايمل موجود بالفعل'),
//             content: Text('قم بتسجيل الدخول'),
//           ));
//           print('The account already exists for that email.');
//         }
//       } catch (e) {
//         print(FirebaseAuth.instance.currentUser!.displayName);
//
//         print(e);
//         print('2222222222222222222222222222');
//
//       }
//     }
//
//
//   }
//
// }






























import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../XXX/XXXFirebase.dart';
import '../../bottonBar/botonBar.dart';
import '../InfomationUser/informationUser.dart';
import '../signin/signinPage.dart';

class GetSignup extends GetxController {
  // المتحكمات الخاصة بالنصوص يجب أن تُنشأ وتُمرَّر من الواجهة الخارجية
  final TextEditingController email;
  final TextEditingController password;

  // متغير تفاعلي لحالة التحميل
  final RxBool isLoading = false.obs;

  GetSignup({
    required this.email,
    required this.password,
  });

  /// دالة تسجيل الحساب باستخدام البريد الإلكتروني وكلمة المرور.
  /// تتحقق أولاً من صلاحية النموذج باستخدام [globalKey]، وإن كانت البيانات صحيحة يتم إنشاء الحساب،
  /// ثم إرسال رسالة التحقق على البريد الإلكتروني.
  /// عند نجاح العملية يقوم بتنقل المستخدم إلى صفحة تسجيل الدخول.
  Future<void> signUp(GlobalKey<FormState> globalKey) async {
    // التأكد من صحة النموذج قبل المتابعة.
    if (!globalKey.currentState!.validate()) return;

    try {
      isLoading.value = true;
      // إنشاء الحساب باستخدام Firebase Authentication.
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      // الحصول على المستخدم الحالي وإرسال رسالة التحقق عبر البريد الإلكتروني.
      User? user = FirebaseAuth.instance.currentUser;
      await user?.sendEmailVerification();

      // التنقل إلى صفحة تسجيل الدخول باستخدام GetX (تجنب استخدام BuildContext عبر الفجوات غير المتزامنة).
      Get.off(() => SignInPage(isFirstTime: true));
    } on FirebaseAuthException catch (e) {
      // معالجة الأخطاء بناءً على رمز الخطأ.
      isLoading.value = false;
      switch (e.code) {
        case 'weak-password':
          Get.defaultDialog(
            title: 'الباسورد ضعيف',
            middleText: 'يجب أن يكون أكثر من 6 ارقام',
            textConfirm: 'موافق',
            onConfirm: () => Get.back(),
            barrierDismissible: true,
          );
          break;
        case 'email-already-in-use':
          Get.defaultDialog(
            title: 'البريد موجود',
            middleText: 'هذا البريد مستخدم بالفعل. قم بتسجيل الدخول بدلاً من إنشاء حساب جديد.',
            textConfirm: 'موافق',
            onConfirm: () => Get.back(),
            barrierDismissible: true,
          );
          break;
        case 'invalid-email':
          Get.defaultDialog(
            title: 'البريد الإلكتروني غير صالح',
            middleText: 'يرجى إدخال بريد إلكتروني صحيح.',
            textConfirm: 'موافق',
            onConfirm: () => Get.back(),
            barrierDismissible: true,
          );
          break;
        case 'operation-not-allowed':
          Get.defaultDialog(
            title: 'عملية غير مسموح بها',
            middleText: '',
            textConfirm: 'موافق',
            onConfirm: () => Get.back(),
            barrierDismissible: true,
          );
          break;
        default:
          Get.defaultDialog(
            title: 'حدث خطأ',
            middleText: e.message ?? 'حدث خطأ غير معروف.',
            textConfirm: 'موافق',
            onConfirm: () => Get.back(),
            barrierDismissible: true,
          );
      }
    } catch (e) {
      isLoading.value = false;
      // عرض رسالة خطأ عامة عند حدوث استثناء غير متوقع.
      Get.defaultDialog(
        title: 'خطأ',
        middleText: 'حدث خطأ غير معروف: $e',
        textConfirm: 'موافق',
        onConfirm: () => Get.back(),
        barrierDismissible: true,
      );
    } finally {
      // إعادة تعيين حالة التحميل.
      isLoading.value = false;
    }
  }
}
