//
// import 'dart:async';
// import 'dart:io';
//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
// import 'package:uuid/uuid.dart';
//
// import '../../../Model/model_user.dart';
// import '../../../XXX/xxx_firebase.dart';
// import '../../../bottonBar/botonBar.dart';
//
// class Getcodephonenumber extends GetxController{
//
//   TextEditingController c1 = TextEditingController();
//   TextEditingController c2 = TextEditingController();
//   TextEditingController c3 = TextEditingController();
//   TextEditingController c4 = TextEditingController();
//   TextEditingController c5 = TextEditingController();
//   TextEditingController c6 = TextEditingController();
//   String phneNumber;
//   bool pssworAndEmail;
//   Uint8List imageUser;
//   String Name;
//   String Email;
//   String password;
//
//
//
//   Getcodephonenumber({required this.c1,required this.c2,required this.c3,required this.c4,
//   required this.c5,required this.c6,required this.phneNumber,required this.pssworAndEmail,required this.imageUser,
//   required this.Name,required this.password,required this.Email});
//
//   bool correct1 =true;
//
//   int connter =100;
//   late Timer timer1;
//
//   String? verifidCodeSent;
//
//   bool isLoding =false;
//
//
//   void startTimer(){
//     timer1= Timer.periodic(const Duration(seconds: 1), (timer) {
//
//         if(connter>0){
//           connter--;
//         }else{
//           timer.cancel();
//         }
//         update();
//
//     });
//   }
//
//   Future<void> phoneAuthCode() async{
//
//     try{
//       await FirebaseAuth.instance.verifyPhoneNumber(
//         phoneNumber: phneNumber,
//         timeout: const Duration(seconds: 90),
//         verificationCompleted: (PhoneAuthCredential credential) {
//           debugPrint('111111111111111111111111111111111');
//           debugPrint('111111111111111111111111111111111');
//           debugPrint('111111111111111111111111111111111');
//
//         },
//         verificationFailed: (FirebaseAuthException e) {
//
//
//           debugPrint('22222222222222222222222222222222222');
//           debugPrint(e);
//           debugPrint('22222222222222222222222222222222222');
//           debugPrint('22222222222222222222222222222222222');
//
//
//
//         },
//         codeSent: (String verificationId, int? resendToken) async{
//
//           verifidCodeSent = verificationId;
//         },
//         codeAutoRetrievalTimeout: (String verificationId) {
//           verifidCodeSent = verificationId;
//         },
//       );
//     }catch(e){
//
//         correct1 =false;
//         update();
//     }
//
//   }
//
//   void sentCode(BuildContext context)async{
//     try{
//         isLoding=true;
//         update();
//       String smsCode = c1.text + c2.text + c3.text + c4.text + c5.text + c6.text;
//       debugPrint(smsCode);
//
//       PhoneAuthCredential credential = PhoneAuthProvider
//           .credential(verificationId: verifidCodeSent!, smsCode: smsCode);
//       if(smsCode == credential.smsCode || smsCode != credential.smsCode){
//
//         // await FirebaseAuth.instance.signInWithCredential(credential).then((value)async{
//
//         if(pssworAndEmail = true){
//
//           //
//           // await FirebaseAuth.instance.signInWithEmailAndPassword(
//           //      email: widget.Email, password: widget.password).then((value) async{
//
//           Reference stprge=   FirebaseStorage.instance.ref(FirebaseX.StorgeApp).child(const Uuid().v1());
//           UploadTask upload =  stprge.putData(imageUser);
//           TaskSnapshot task = await upload;
//           String url22 = await task.ref.getDownloadURL();
//           if(Platform.isIOS){
//             await  FirebaseMessaging.instance.getAPNSToken().then((token)async{
//               ModelUser modelUser =ModelUser(url: url22, uid: FirebaseAuth.instance.currentUser!.uid,
//                   token: token.toString(), phneNumber: phneNumber, password: password, email: Email, name: Name, appName: FirebaseX.appName);
//
//               await FirebaseFirestore.instance.collection(FirebaseX.collectionApp).doc(FirebaseAuth.instance.currentUser!.uid).set(modelUser.toMap()
//
//               ).then((value)async {
//
//
//                 Navigator.push(
//                     context, MaterialPageRoute(builder: (context) => bottonBar(theIndex: 0,)));
//
//
//               });
//
//
//             });
//           }else{
//             await  FirebaseMessaging.instance.getToken().then((token)async{
//               ModelUser modelUser =ModelUser(url: url22, uid: FirebaseAuth.instance.currentUser!.uid,
//                   token: token.toString(), phneNumber: phneNumber, password: password, email: Email, name: Name, appName: FirebaseX.appName);
//
//               await FirebaseFirestore.instance.collection(FirebaseX.collectionApp).doc(FirebaseAuth.instance.currentUser!.uid).set(modelUser.toMap()
//
//               ).then((value)async {
//
//
//                 Navigator.push(
//                     context, MaterialPageRoute(builder: (context) => bottonBar(theIndex: 0,)));
//
//
//               });
//
//
//             });
//           }
//
//
//
//
//         }else{
//           debugPrint('//////////////////////q//////q///////q////q///q/////q///');
//
//
//           Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) =>  bottonBar()),(rute)=>false);
//
//
//         }
//
//
//
//
//
//         // });
//       }
//
//
//
//     }on FirebaseAuthException catch (e){
//       if(e.code == 'invalid-verification-code'){
//           correct1 =false;
//           isLoding =false;
//           update();
//       }
//     }
//     catch(e){
//       debugPrint('3333333333333333333333333333333333');
//       debugPrint(e);
//
//       debugPrint('3333333333333333333333333333333333');
//
//     }
//   }
//   @override
//   void onInit() {
//     startTimer();
//     phoneAuthCode();
//     // TODO: implement onInit
//     super.onInit();
//   }
//   @override
//   void dispose() {
//     c1.dispose();
//     c2.dispose();
//     c3.dispose();
//     c4.dispose();
//     c5.dispose();
//     c6.dispose();
//     timer1.cancel();
//     // TODO: implement dispose
//     super.dispose();
//   }
//
//
//
//
// }



























import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../../Model/model_user.dart';
import '../../../../XXX/xxx_firebase.dart';
import '../../../bottonBar/botonBar.dart';

class GetCodePhoneNumber extends GetxController {
  // TextEditingControllers لكل خانة من رمز التأكيد
  final TextEditingController c1;
  final TextEditingController c2;
  final TextEditingController c3;
  final TextEditingController c4;
  final TextEditingController c5;
  final TextEditingController c6;

  final String phneNumber;
  final bool pssworAndEmail;
  final Uint8List imageUser;
  final String name;
  final String email;
  final String password;


  // حالة صحة الكود
  RxBool correct = true.obs;
  // عداد إعادة إرسال الكود
  RxInt counter = 100.obs;
  late Timer _timer;
  String? verificationId;
  RxBool isLoading = false.obs;

  GetCodePhoneNumber({
    required this.c1,
    required this.c2,
    required this.c3,
    required this.c4,
    required this.c5,
    required this.c6,
    required this.phneNumber,
    required this.pssworAndEmail,
    required this.imageUser,
    required this.name,
    required this.email,
    required this.password,
  });

  /// بدء عداد إعادة إرسال الكود.
  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (counter.value > 0) {
        debugPrint(phneNumber);
        debugPrint(name);
        debugPrint(email);
        debugPrint(password);
        debugPrint(phneNumber);

        counter.value--;
      } else {
        timer.cancel();
      }
      update();
    });
  }

  /// طلب إرسال رمز التحقق عبر الهاتف باستخدام verifyPhoneNumber.
  Future<void> phoneAuthCode() async {
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phneNumber,
        timeout: const Duration(seconds: 90),
        verificationCompleted: (PhoneAuthCredential credential) {
          // يمكن تنفيذ منطق تلقائي عند إكمال التحقق.
          // على سبيل المثال، يمكن محاولة تسجيل الدخول تلقائيًا.
          Get.snackbar(
            'تأكيد تلقائي',
            'تم التحقق بشكل تلقائي.',
            backgroundColor: Colors.greenAccent,
            colorText: Colors.black,
          );
        },
        verificationFailed: (FirebaseAuthException e) {
          // عرض خطأ باستخدام حوار Get.defaultDialog
          Get.defaultDialog(
            title: 'خطأ في التحقق',
            middleText: e.message ?? 'حدث خطأ أثناء إرسال رمز التحقق.',
            textConfirm: 'حسنًا',
            onConfirm: () => Get.back(),
            barrierDismissible: true,
          );
        },
        codeSent: (String verificationId, int? resendToken) async {
          this.verificationId = verificationId;
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          this.verificationId = verificationId;
        },
      );
    } catch (e) {
      correct.value = false;
      update();
      Get.defaultDialog(
        title: 'خطأ',
        middleText: 'حدث خطأ أثناء طلب رمز التحقق. الرجاء المحاولة مرة أخرى.',
        textConfirm: 'موافق',
        onConfirm: () => Get.back(),
      );
    }
  }

  /// محاولة إرسال الكود بعد إدخال الرقم.
  Future<void> sendCode() async {
    try {
      isLoading.value = true;
      update();

      // جمع الحروف المدخلة في الخانات معاً.
      String smsCode = c1.text + c2.text + c3.text + c4.text + c5.text + c6.text;

      // التأكد من أن الكود مكون من 6 أرقام.
      if (smsCode.length != 6) {
        Get.defaultDialog(
          title: 'خطأ في الإدخال',
          middleText: 'يرجى التأكد من إدخال رمز التحقق بالكامل.',
          textConfirm: 'موافق',
          onConfirm: () => Get.back(),
        );
        isLoading.value = false;
        update();
        return;
      }

      // إنشاء الاعتماد باستخدام verificationId والرمز المدخل.
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId!,
        smsCode: smsCode,
      );

      // محاولة تسجيل الدخول باستخدام الاعتماد.
      // إذا نجح التسجيل، نستخدم المنطق التالي.
      // await FirebaseAuth.instance.signInWithCredential(credential);
      if(smsCode == credential.smsCode){

        // بناءً على حالة pssworAndEmail نقوم بالتسجيل أو تعديل بيانات المستخدم.

        // رفع الصورة إلى Firebase Storage.
        Reference storageRef = FirebaseStorage.instance
            .ref(FirebaseX.StorgeApp)
            .child(const Uuid().v1());
        UploadTask uploadTask = storageRef.putData(imageUser);
        TaskSnapshot taskSnapshot = await uploadTask;
        String downloadUrl = await taskSnapshot.ref.getDownloadURL();

        // الحصول على توكن Firebase Messaging بناءً على نوع النظام.
        String? token;
        if (Platform.isIOS) {
          token = await FirebaseMessaging.instance.getAPNSToken();
        } else {
          token = await FirebaseMessaging.instance.getToken();
        }

        // إنشاء نموذج المستخدم وإضافته إلى Firestore.
        UserModel modelUser = UserModel(
          url: downloadUrl,
          uid: FirebaseAuth.instance.currentUser!.uid,
          token: token ?? '',
          phoneNumber: phneNumber,
          password:pssworAndEmail? password:'noPassword',
          email:email ,
          name: name,
          appName: FirebaseX.appName,
        );

        await FirebaseFirestore.instance
            .collection(FirebaseX.collectionApp)
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .set(modelUser.toMap());

        // التنقل إلى الشاشة الرئيسية.
        Get.offAll(() => BottomBar(initialIndex: 0));

      }


    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-verification-code') {
        correct.value = false;
        isLoading.value = false;
        update();
        Get.defaultDialog(
          title: 'الكود غير صحيح',
          middleText: 'يرجى التأكد من الكود المدخل وإعادة المحاولة.',
          textConfirm: 'موافق',
          onConfirm: () => Get.back(),
        );
      }
    } catch (e) {
      Get.defaultDialog(
        title: 'خطأ',
        middleText: 'حدث خطأ أثناء التحقق: ',
        textConfirm: 'موافق',
        onConfirm: () => Get.back(),
      );
    } finally {
      isLoading.value = false;
      update();
    }
  }

  @override
  void onInit() {
    super.onInit();
    startTimer();
    phoneAuthCode();
  }

  @override
  void dispose() {
    c1.dispose();
    c2.dispose();
    c3.dispose();
    c4.dispose();
    c5.dispose();
    c6.dispose();
    _timer.cancel();
    super.dispose();
  }
}
