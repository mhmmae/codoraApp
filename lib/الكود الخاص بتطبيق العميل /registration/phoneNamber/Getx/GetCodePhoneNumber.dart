
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
      // في بيئة التطوير، يمكننا استخدام أرقام هواتف وهمية للاختبار
      // Firebase يدعم test phone numbers في console
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phneNumber,
        timeout: const Duration(seconds: 90),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // يمكن تنفيذ منطق تلقائي عند إكمال التحقق.
          // على سبيل المثال، يمكن محاولة تسجيل الدخول تلقائيًا.
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
            Get.snackbar(
              'تأكيد تلقائي',
              'تم التحقق بشكل تلقائي.',
              backgroundColor: Colors.greenAccent,
              colorText: Colors.black,
            );
            await _completeRegistration();
          } catch (e) {
            debugPrint('Error in automatic verification: $e');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          // عرض خطأ باستخدام حوار Get.defaultDialog
          String errorMessage = 'حدث خطأ أثناء إرسال رمز التحقق.';

          // معالجة رسائل خطأ محددة
          if (e.code == 'invalid-phone-number') {
            errorMessage =
                'رقم الهاتف غير صحيح. الرجاء التحقق من الرقم والمحاولة مرة أخرى.';
          } else if (e.code == 'too-many-requests') {
            errorMessage =
                'تم إرسال الكثير من الطلبات. الرجاء الانتظار والمحاولة لاحقاً.';
          } else if (e.code == 'quota-exceeded') {
            errorMessage =
                'تم تجاوز الحد المسموح من الرسائل. الرجاء المحاولة لاحقاً.';
          } else if (e.code == 'web-context-cancelled') {
            errorMessage = 'تم إلغاء عملية التحقق. الرجاء المحاولة مرة أخرى.';
          } else if (e.code == 'captcha-check-failed') {
            errorMessage = 'فشل في التحقق الأمني. الرجاء المحاولة مرة أخرى.';
          }

          debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');

          Get.defaultDialog(
            title: 'خطأ في التحقق',
            middleText: errorMessage,
            textConfirm: 'حسنًا',
            onConfirm: () => Get.back(),
            barrierDismissible: true,
          );
        },
        codeSent: (String verificationId, int? resendToken) async {
          this.verificationId = verificationId;
          Get.snackbar(
            'تم الإرسال',
            'تم إرسال رمز التحقق إلى رقم الهاتف المحدد',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          this.verificationId = verificationId;
        },
      );
    } catch (e) {
      correct.value = false;
      update();
      debugPrint('Phone Auth Error: $e');
      Get.defaultDialog(
        title: 'خطأ',
        middleText:
            'حدث خطأ أثناء طلب رمز التحقق. الرجاء التأكد من اتصال الإنترنت والمحاولة مرة أخرى.',
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
      String smsCode =
          c1.text + c2.text + c3.text + c4.text + c5.text + c6.text;

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
      await FirebaseAuth.instance.signInWithCredential(credential);

      // إذا نجح التسجيل، نكمل التسجيل
      await _completeRegistration();
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
      } else if (e.code == 'session-expired') {
        Get.defaultDialog(
          title: 'انتهت صلاحية الجلسة',
          middleText: 'انتهت صلاحية رمز التحقق. الرجاء طلب رمز جديد.',
          textConfirm: 'موافق',
          onConfirm: () {
            Get.back();
            phoneAuthCode(); // إعادة إرسال الكود
          },
        );
      }
    } catch (e) {
      Get.defaultDialog(
        title: 'خطأ',
        middleText: 'حدث خطأ أثناء التحقق: ${e.toString()}',
        textConfirm: 'موافق',
        onConfirm: () => Get.back(),
      );
    } finally {
      isLoading.value = false;
      update();
    }
  }

  /// دالة لإكمال التسجيل بعد التحقق من الهاتف
  Future<void> _completeRegistration() async {
    try {
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
        password: pssworAndEmail ? password : 'noPassword',
        email: email,
        name: name,
        appName: FirebaseX.appName,
      );

      await FirebaseFirestore.instance
          .collection(FirebaseX.collectionApp)
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .set(modelUser.toMap());

      // التنقل إلى الشاشة الرئيسية.
      Get.offAll(() => BottomBar(initialIndex: 0));
    } catch (e) {
      Get.defaultDialog(
        title: 'خطأ في حفظ البيانات',
        middleText: 'حدث خطأ أثناء حفظ بياناتك. الرجاء المحاولة مرة أخرى.',
        textConfirm: 'موافق',
        onConfirm: () => Get.back(),
      );
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
