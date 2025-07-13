


import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:crypto/crypto.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'; // لاستخدام kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../../XXX/xxx_firebase.dart';
import '../../../bottonBar/botonBar.dart';
import '../../InfomationUser/informationUser.dart';

/// Controller شامل لإدارة تسجيل الدخول باستخدام مزودي المصادقة المتعددين.
/// يعتمد على GetX لتحديث الحالة وإدارة التنقل دون استخدام BuildContext عبر الفجوات غير المتزامنة.
class SignInController extends GetxController {
  /// حالة التحميل لتحديث الواجهة تلقائيًا.
  final RxBool isLoading = false.obs;

  /// مؤشر لتحديد ما إذا كانت هذه أول مرة لتسجيل الدخول.
  bool isFirstTime;

  /// المتحكمات الخاصة بنصوص البريد الإلكتروني وكلمة المرور.
  final TextEditingController emailController;
  final TextEditingController passwordController;

  /// المثيل الخاص بـ FirebaseAuth.
  final FirebaseAuth auth = FirebaseAuth.instance;

  SignInController({
    required this.isFirstTime,
    required this.emailController,
    required this.passwordController,
  });

  // -----------------------------------------------------------
  // دالة مساعدة لعرض رسالة الخطأ باستخدام Get.defaultDialog
  // -----------------------------------------------------------
  void showError(String message) {
    Get.defaultDialog(
      title: "خطأ",
      middleText: message,
      textConfirm: "موافق",
      onConfirm: () => Get.back(), // يغلق الحوار
      barrierDismissible: true,
    );
  }

  // -----------------------------------------------------------
  // الدوال المساعدة المشتركة
  // -----------------------------------------------------------

  /// توليد سلسلة عشوائية (nonce)، بطول 32 حرفًا افتراضيًا.
  String generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  /// ترجيع قيمة SHA-256 للسلسلة (hex).
  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// دالة مشتركة للتحقق من وجود سجل المستخدم في Firestore.
  /// إذا كان السجل موجودًا يتم تحديث توكن Firebase Messaging ثم الانتقال إلى الشاشة الرئيسية.
  /// وإلا يتم توجيه المستخدم لإكمال بياناته في شاشة InformationUser.
  Future<void> handleUserNavigation() async {
    final docRef = FirebaseFirestore.instance
        .collection(FirebaseX.collectionApp)
        .doc(auth.currentUser!.uid);
    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      final token = await FirebaseMessaging.instance.getToken();
      await docRef.update({'token': token.toString()});
      Get.offAll(() => BottomBar(initialIndex: 0,));
    } else {
      Get.to(() => InformationUser(
        email: auth.currentUser!.email ?? '',
        password: 'NO PASSWORD',
        passwordAndEmail: true,
      ));
    }
  }

  /// دالة موحدة لمعالجة أخطاء FirebaseAuth.
  void handleFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        showError('يوجد حساب مسجل بنفس البريد الإلكتروني ولكن بمصادقة مختلفة.');
        break;
      case 'invalid-credential':
        showError('الاعتماديات غير صحيحة أو منتهية الصلاحية.');
        break;
      case 'operation-not-allowed':
        showError('عملية تسجيل الدخول غير مفعلة لهذا النوع من الحسابات.');
        break;
      case 'user-disabled':
        showError('تم تعطيل حساب المستخدم.');
        break;
      case 'user-not-found':
        showError('لم يتم العثور على مستخدم بهذا البريد.');
        break;
      case 'wrong-password':
        showError('كلمة المرور المدخلة غير صحيحة.');
        break;
      default:
        showError('حدث خطأ غير معروف: ${e.message}');
    }
  }

  // -----------------------------------------------------------
  // طرق تسجيل الدخول المختلفة
  // -----------------------------------------------------------

  /// تسجيل الدخول باستخدام Google.
  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;
      final googleUser = await GoogleSignIn(
          // scopes:
      // [
      //   'email',
      //   'https://www.googleapis.com/auth/contacts.readonly',
      // ]
      ).signIn();
      if (googleUser == null) return; // في حال إلغاء تسجيل الدخول

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await auth.signInWithCredential(credential);
      await handleUserNavigation();
    } on FirebaseAuthException catch (e) {
      handleFirebaseAuthError(e);
    } catch (e) {
      showError('خطأ أثناء تسجيل الدخول بواسطة Google: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// تسجيل الدخول باستخدام Facebook لنظام Android.
  Future<UserCredential?> signInWithFacebookForAndroid() async {
    try {
      isLoading.value = true;
      final result = await FacebookAuth.instance.login(permissions: ['public_profile', 'email']);
      if (result.status == LoginStatus.success && result.accessToken != null) {
        final credential = FacebookAuthProvider.credential(result.accessToken!.tokenString);
        final userCredential = await auth.signInWithCredential(credential);
        await handleUserNavigation();
        return userCredential;
      }
    } on FirebaseAuthException catch (e) {
      handleFirebaseAuthError(e);
    } catch (e) {
      showError('خطأ أثناء تسجيل الدخول بواسطة Facebook (Android): $e');
    } finally {
      isLoading.value = false;
    }
    return null;
  }

  /// تسجيل الدخول باستخدام Facebook لنظام iOS.
  Future<UserCredential?> signInWithFacebookForiOS() async {
    try {
      isLoading.value = true;
      final rawNonce = generateNonce();
      final nonce = sha256ofString(rawNonce);

      final loginResult = await FacebookAuth.instance.login(
        loginTracking: LoginTracking.limited,
        nonce: nonce,
      );

      if (loginResult.accessToken == null) {
        throw Exception(loginResult.message);
      }

      OAuthCredential facebookCredential;
      if (Platform.isIOS) {
        switch (loginResult.accessToken!.type) {
          case AccessTokenType.classic:
            final token = loginResult.accessToken as ClassicToken;
            facebookCredential = FacebookAuthProvider.credential(token.authenticationToken!);
            break;
          case AccessTokenType.limited:
            final token = loginResult.accessToken as LimitedToken;
            facebookCredential = OAuthCredential(
              providerId: 'facebook.com',
              signInMethod: 'oauth',
              idToken: token.tokenString,
              rawNonce: rawNonce,
            );
            break;
          default:
            throw Exception('نوع التوكن غير معروف.');
        }
      } else {
        facebookCredential = FacebookAuthProvider.credential(loginResult.accessToken!.tokenString);
      }

      final userCredential = await auth.signInWithCredential(facebookCredential);
      await handleUserNavigation();
      return userCredential;
    } on FirebaseAuthException catch (e) {
      handleFirebaseAuthError(e);
    } catch (e) {
      showError('خطأ أثناء تسجيل الدخول بواسطة Facebook (iOS): $e');
    } finally {
      isLoading.value = false;
    }
    return null;
  }

  /// تسجيل الدخول باستخدام Apple.
  Future<void> signInWithApple() async {
    try {
      isLoading.value = true;
      final appleCred = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final oauthCred = OAuthProvider('apple.com').credential(
        accessToken: appleCred.authorizationCode,
        idToken: appleCred.identityToken,
      );
      await auth.signInWithCredential(oauthCred);
      await handleUserNavigation();
    } on FirebaseAuthException catch (e) {
      handleFirebaseAuthError(e);
    } catch (e) {
      showError('خطأ أثناء تسجيل الدخول بواسطة Apple: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// تسجيل الدخول باستخدام Yahoo.
  Future<UserCredential?> signInWithYahoo() async {
    final yahooProvider = YahooAuthProvider();
    try {
      isLoading.value = true;
      late UserCredential userCredential;
      if (kIsWeb) {
        userCredential = await auth.signInWithPopup(yahooProvider);
      } else {
        userCredential = await auth.signInWithProvider(yahooProvider);
      }
      await handleUserNavigation();
      return userCredential;
    } on FirebaseAuthException catch (e) {
      handleFirebaseAuthError(e);
    } catch (e) {
      showError('خطأ أثناء تسجيل الدخول بواسطة Yahoo: $e');
    } finally {
      isLoading.value = false;
    }
    return null;
  }

  /// تسجيل الدخول باستخدام Microsoft.
  Future<UserCredential?> signInWithMicrosoft() async {
    final microsoftProvider = MicrosoftAuthProvider();
    try {
      isLoading.value = true;
      late UserCredential userCredential;
      if (kIsWeb) {
        userCredential = await auth.signInWithPopup(microsoftProvider);
      } else {
        userCredential = await auth.signInWithProvider(microsoftProvider);
      }
      await handleUserNavigation();
      return userCredential;
    } on FirebaseAuthException catch (e) {
      handleFirebaseAuthError(e);
    } catch (e) {
      showError('خطأ أثناء تسجيل الدخول بواسطة Microsoft: $e');
    } finally {
      isLoading.value = false;
    }
    return null;
  }

  /// تسجيل الدخول بواسطة البريد الإلكتروني وكلمة المرور.
  Future<void> signInWithEmail(GlobalKey<FormState> formKey) async {
    if (!formKey.currentState!.validate()) return;
    try {
      isLoading.value = true;
      final userCredential = await auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      if (userCredential.user?.emailVerified ?? false) {
        final docSnapshot = await FirebaseFirestore.instance
            .collection(FirebaseX.collectionApp)
            .doc(auth.currentUser!.uid)
            .get();
        if (docSnapshot.exists) {
          final token = await FirebaseMessaging.instance.getToken();
          await FirebaseFirestore.instance
              .collection(FirebaseX.collectionApp)
              .doc(auth.currentUser!.uid)
              .update({'token': token.toString()});
          Get.offAll(() => BottomBar(initialIndex: 0));
        } else {
          Get.to(() => InformationUser(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
            passwordAndEmail: true,
          ));
        }
      } else {
        await Get.dialog(AlertDialog(
          title: Text('قم بالتحقق من الآيميل'),
          content: Text('اذهب إلى البريد الوارد لتفعيل حسابك.'),
          actions: [
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                isFirstTime = false;
                Get.back();
              },
            )
          ],
        ));
        return;
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        await Get.dialog(AlertDialog(
          title: Text('الايميل غير صحيح'),
          content: Text('هذا الايميل غير موجود.'),
          actions: [
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                isFirstTime = false;
                Get.back();
              },
            )
          ],
        ));
      } else if (e.code == 'wrong-password') {
        await Get.dialog(AlertDialog(
          title: Text('الايميل أو الرمز السري خطأ'),
          content: Text('حاول مرة أخرى.'),
          actions: [
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                isFirstTime = false;
                Get.back();
              },
            )
          ],
        ));
      } else {
        showError('خطأ أثناء تسجيل الدخول بواسطة البريد الإلكتروني: ${e.message}');
      }
    } catch (e) {
      showError('خطأ غير معروف أثناء تسجيل الدخول بواسطة البريد الإلكتروني: $e');
    } finally {
      isLoading.value = false;
    }
  }





  @override
  void onInit() async{
    // TODO: implement onInit
    super.onInit();
    if(isFirstTime){
      await Get.dialog(AlertDialog(
        title: Text('قم بالتحقق من الآيميل'),
        content: Text('اذهب إلى البريد الوارد لتفعيل حسابك.'),
        actions: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              isFirstTime = false;
              Get.back();
            },
          )
        ],
      ));

    }
  }


}
