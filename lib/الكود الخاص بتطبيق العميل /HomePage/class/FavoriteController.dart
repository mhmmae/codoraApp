import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../../XXX/xxx_firebase.dart';


class FavoriteController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // دالة للتحقق مما إذا كان المنتج في المفضلة (تُرجع Stream للحالة التفاعلية)
  Stream<bool> isFavoriteStream(String productId) {
    final User? user = _auth.currentUser;
    if (user == null || productId.isEmpty) {
      return Stream.value(false); // المستخدم غير مسجل أو ID المنتج غير صالح
    }
    // الاستماع لوجود المستند في المجموعة الفرعية favorites
    return _firestore
        .collection(FirebaseX.usersCollection)
        .doc(user.uid)
        .collection(FirebaseX.favoritesSubcollection)
        .doc(productId) // استخدم ID المنتج كمعرف للمستند في المفضلة
        .snapshots()
        .map((snapshot) => snapshot.exists) // true إذا كان المستند موجودًا
        .handleError((error) { // معالجة الأخطاء
      debugPrint("Error checking favorite status for $productId: $error");
      return false; // افتراض أنه ليس في المفضلة عند حدوث خطأ
    });
  }






  // ---!!! (جديد) دالة Stream لجلب قائمة معرفات المفضلة !!!---
  Stream<QuerySnapshot<Map<String, dynamic>>> getFavoritesStream() {
    final User? user = _auth.currentUser;
    if (user == null) {
      // إرجاع ستريم فارغ إذا لم يكن المستخدم مسجلًا
      return Stream.empty();
    }
    // الاستماع للمجموعة الفرعية favorites للمستخدم الحالي
    return _firestore
        .collection(FirebaseX.usersCollection)
        .doc(user.uid)
        .collection(FirebaseX.favoritesSubcollection)
    // يمكنك إضافة orderBy هنا إذا حفظت timestamp
    // .orderBy('addedAt', descending: true)
        .snapshots();
  }





  // دالة لتبديل حالة المفضلة (إضافة أو إزالة)
  Future<void> toggleFavorite(String productId, bool isCurrentlyFavorite) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      _showSnackbar("خطأ", "يجب تسجيل الدخول لإضافة للمفضلة.", Colors.orange);
      return;
    }
    if (productId.isEmpty) {
      debugPrint("Error toggling favorite: Product ID is empty.");
      return;
    }

    // الحصول على مرجع المستند في المفضلة
    final DocumentReference favoriteRef = _firestore
        .collection(FirebaseX.usersCollection)
        .doc(user.uid)
        .collection(FirebaseX.favoritesSubcollection)
        .doc(productId); // استخدم ID المنتج كمعرف لمستند المفضلة

    try {
      if (isCurrentlyFavorite) {
        // --- إذا كان في المفضلة، قم بإزالته ---
        debugPrint("Removing item $productId from favorites for user ${user.uid}");
        await favoriteRef.delete();
        _showSnackbar("المفضلة", "تمت الإزالة من المفضلة.", Colors.grey);
      } else {
        // --- إذا لم يكن في المفضلة، قم بإضافته ---
        debugPrint("Adding item $productId to favorites for user ${user.uid}");
        // إضافة timestamp لمعرفة وقت الإضافة (اختياري)
        await favoriteRef.set({
          'productId': productId, // يمكنك إضافة تفاصيل المنتج الأخرى إذا أردت
          'addedAt': FieldValue.serverTimestamp(),
        });
        _showSnackbar("المفضلة", "تمت الإضافة إلى المفضلة بنجاح.", Colors.green);
      }
    } catch (e) {
      debugPrint("Error toggling favorite for $productId: $e");
      _showSnackbar("خطأ", "حدث خطأ أثناء تحديث المفضلة.", Colors.red);
    }
  }

  // دالة مساعدة لعرض Snackbar (يفضل وجود دالة مركزية للـ Snackbar)
  void _showSnackbar(String title, String message, Color backgroundColor) {
    if (Get.isSnackbarOpen) Get.closeCurrentSnackbar(); // إغلاق الحالي
    Get.snackbar(title, message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: backgroundColor,
        colorText: Colors.white,
        margin: const EdgeInsets.all(10), borderRadius: 8);
  }
}