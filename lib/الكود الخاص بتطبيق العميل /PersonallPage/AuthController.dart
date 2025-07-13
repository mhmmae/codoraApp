import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// افترض أن لديك شاشة تسجيل دخول
// import '../auth/login_page.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // دالة لتسجيل الخروج
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      // يمكنك الانتقال إلى شاشة تسجيل الدخول بعد تسجيل الخروج
      // Get.offAll(() => LoginPage()); //  افترض وجود LoginPage
      Get.snackbar("تم بنجاح", "تم تسجيل الخروج.", snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar("خطأ", "فشل تسجيل الخروج: ${e.toString()}",
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  // دالة لحذف الحساب
  Future<void> deleteAccount() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        //  قد تحتاج إلى إعادة المصادقة قبل الحذف
        // await user.reauthenticateWithCredential(...);
        await user.delete();
        // Get.offAll(() => LoginPage()); // افترض وجود LoginPage
        Get.snackbar("تم بنجاح", "تم حذف الحساب.", snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar("خطأ", "فشل حذف الحساب: ${e.toString()}",
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}