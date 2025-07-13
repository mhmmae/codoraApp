
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../../Model/model_the_chosen.dart';
import '../../../XXX/xxx_firebase.dart'; // For Color

// تأكد من المسار الصحيح

class AddRemoveController extends GetxController {
  final RxInt number = 0.obs;
  final String docId; // هذا هو المعرف الفريد الذي ننشئه للـ Widget وليس ID المنتج نفسه
  final String uidItem; // هذا هو معرف المنتج الفعلي
  final bool isOffer;
  final RxBool isAnimating = false.obs;
  final String uidAdd; // هذا هو معرف المنتج الفعلي


  final String? _userId = FirebaseAuth.instance.currentUser?.uid;
  final String _appName = FirebaseX.appName; // تأكد أن هذا معرف في XXXFirebase
  DocumentReference? _itemDocRef;

  // استخدام `tag` للتأكد من العثور على الـ controller الصحيح
  AddRemoveController({
    required this.docId,
    required this.uidItem,
    required this.uidAdd,

    required this.isOffer,
  }) {
    _initializeDocRef();
    debugPrint("AddRemoveCtrl Init: Tag/DocID: $docId for item $uidItem");
  }

  void _initializeDocRef() {
    if (_userId != null) {
      // المسار الصحيح في Firestore: collections -> users -> userId -> chosenCollectionName -> chosenItemDocId
      _itemDocRef = FirebaseFirestore.instance
          .collection(FirebaseX.chosenCollection) // 'the-chosen' مثلاً
          .doc(_userId)
          .collection(_appName) // اسم التطبيق أو مجموعة ثابتة
          .doc(docId); // المعرف الفريد لهذا الـ Widget
    } else {
      debugPrint("AddRemoveCtrl Init Error: User not logged in.");
      _showSnackbar("يرجى تسجيل الدخول أولاً", Colors.orange); // <<-- تعريب
    }
  }

  @override
  void onInit() {
    super.onInit();
    fetchInitialNumber();
  }

  @override
  void onClose() {
    debugPrint("AddRemoveController disposed for Tag/DocID: $docId");
    super.onClose();
  }

  Future<void> fetchInitialNumber() async {
    if (_itemDocRef == null) return;
    try {
      final doc = await _itemDocRef!.get();
      if (doc.exists) {
        // تأكد من أن الحقل اسمه 'number' ونوعه int
        number.value = (doc.data() as Map<String, dynamic>?)?['number'] as int? ?? 0;
      } else {
        number.value = 0;
      }
      debugPrint("AddRemoveCtrl Initial Num ($docId): ${number.value}");
    } catch (e) {
      debugPrint('AddRemoveCtrl Fetch Error ($docId): $e');
      number.value = 0; // إعادة التعيين في حالة الخطأ
    }
  }

  Future<void> addItem() async {
    if (_itemDocRef == null) return _showSnackbar("يرجى تسجيل الدخول أولاً", Colors.red); // <<-- تعريب

    number.value++; // زيادة العدد محليًا أولاً للتحديث الفوري للواجهة
    final model = ModelTheChosen(
        isOfer: isOffer, // استخدم isOffer من المعامل
        number: number.value,
        uidOfDoc: docId, // هذا معرف الـ Widget/Controller Tag
        uidItem: uidItem, // معرف المنتج الفعلي
        uidUser: _userId!,
        uidAdd: uidAdd

    );

    try {
      // استخدام `set` مع `SetOptions(merge: true)` أكثر أمانًا ليقوم بإنشاء المستند أو تحديثه
      await _itemDocRef!.set(model.toMap(), SetOptions(merge: true));
      debugPrint("AddRemoveCtrl Item Added/Updated ($docId), count: ${number.value}");
    } catch (e) {
      number.value--; // إعادة القيمة في حالة فشل الحفظ
      _showSnackbar("خطأ في تحديث السلة", Colors.red); // <<-- تعريب
      debugPrint('Add Item Error ($docId): $e');
    }finally {
      // ---!!! إيقاف التحريك بعد فترة قصيرة !!!---
      // تأخير بسيط لجعل الحركة مرئية ثم إيقافها
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!isClosed) { // التأكد أن المتحكم لا يزال موجوداً
          isAnimating.value = false;
        }
      });
      // ---------------------------------------
    }
  }

  Future<void> removeItem() async {
    if (_itemDocRef == null) return _showSnackbar("يرجى تسجيل الدخول أولاً", Colors.red); // <<-- تعريب
    if (number.value <= 0) return; // لا تفعل شيئاً إذا كان العدد صفرًا

    final prevNum = number.value;
    number.value--; // تقليل العدد محليًا أولاً

    try {
      if (number.value == 0) {
        // إذا أصبح العدد صفرًا، احذف المستند
        await _itemDocRef!.delete();
        debugPrint("AddRemoveCtrl Item Removed ($docId)");
      } else {
        // إذا كان لا يزال أكبر من صفر، قم بتحديث العدد فقط
        await _itemDocRef!.update({
          'number': number.value,
          'timestamp': FieldValue.serverTimestamp(), // تحديث الوقت أيضاً
        });
        debugPrint("AddRemoveCtrl Item Count Decreased ($docId), count: ${number.value}");
      }
    } catch (e) {
      number.value = prevNum; // إعادة القيمة في حالة فشل الحذف/التحديث
      _showSnackbar("خطأ في تحديث السلة", Colors.red); // <<-- تعريب
      debugPrint('Remove Item Error ($docId): $e');
    }
  }

  void _showSnackbar(String msg, Color bg) {
    if (Get.isSnackbarOpen) Get.back(); // إغلاق الـ snackbar الحالي إذا كان مفتوحًا
    Get.snackbar(
      "تنبيه", // <<-- تعريب
      msg,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: bg,
      colorText: Colors.white,
      margin: const EdgeInsets.all(10),
      borderRadius: 8,
      duration: const Duration(seconds: 2),
    );
  }
}


// Similar to AddRemoveController, consider merging if functionality is identical.
class GetBoxAddAndRemove extends GetxController {
  final RxInt number = 0.obs;
  final String docId; final String uidItem; final bool isOffer; final String uidAdd;
  final String? _userId = FirebaseAuth.instance.currentUser?.uid; final String _appName = FirebaseX.appName; DocumentReference? _itemDocRef;

  GetBoxAddAndRemove({required this.docId, required this.uidItem,required this.uidAdd, required this.isOffer}) { _initializeDocRef(); debugPrint("GetBoxAddRemove Init: $docId"); }

  void _initializeDocRef() { if (_userId != null) { _itemDocRef = FirebaseFirestore.instance.collection(FirebaseX.chosenCollection).doc(_userId).collection(_appName).doc(docId); } else { debugPrint("GetBoxAddRemove Init Err: No User"); } }

  @override
  void onInit() { super.onInit(); fetchInitialNumber(); }

  Future<void> fetchInitialNumber() async { if (_itemDocRef == null) return; try { final d = await _itemDocRef!.get(); number.value = d.exists ? ((d.data() as Map?)?['number'] as int? ?? 0) : 0; debugPrint("Box Initial Num ($docId): ${number.value}"); } catch (e) { debugPrint('Box Fetch Err ($docId): $e'); number.value = 0; } }

  Future<void> addItem() async { if (_itemDocRef == null) return _showErrorSnackbar("لم تسجل الدخول"); number.value++; final m = ModelTheChosen(isOfer: isOffer,uidAdd:uidAdd , number: number.value, uidOfDoc: docId, uidItem: uidItem, uidUser: _userId!); try { await _itemDocRef!.set(m.toMap()); debugPrint("Box Item Added ($docId)"); } catch (e) { number.value--; _showErrorSnackbar("خطأ السلة"); debugPrint('Box Add Err ($docId): $e'); } } // <<-- تعريب

  Future<void> removeItem() async { if (_itemDocRef == null) return _showErrorSnackbar("لم تسجل الدخول"); if (number.value <= 0) return; final p = number.value; number.value--; try { if (number.value == 0) { await _itemDocRef!.delete(); debugPrint("Box Item Removed ($docId)"); } else { await _itemDocRef!.update({'number': number.value}); debugPrint("Box Item Updated ($docId)"); } } catch (e) { number.value = p; _showErrorSnackbar("خطأ السلة"); debugPrint('Box Remove Err ($docId): $e'); } } // <<-- تعريب

  void _showErrorSnackbar(String message) { if (Get.isSnackbarOpen) return; Get.snackbar("خطأ", message, snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white); } // <<-- تعريب

  @override
  void onClose() { debugPrint("GetBoxAddAndRemove disposed: $docId"); super.onClose(); }
}