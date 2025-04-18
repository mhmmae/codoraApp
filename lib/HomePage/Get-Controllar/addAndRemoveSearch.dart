//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:get/get.dart';
// import 'package:uuid/uuid.dart';
//
// import '../../Model/ModelTheChosen.dart';
// import '../../XXX/XXXFirebase.dart';
//
// class GetaddAndRemoveSearch extends GetxController{
//   int number = 0;
//   final uuid =Uuid().v1();
//   addItem(String uid,String uidItem) {
//     try {
//       number++;
//       if (number == 1) {
//         ModelTheChosen modelTheChosen =ModelTheChosen(isOfer: false, number: number, uidOfDoc: uid, uidItem: uidItem, uidUser: FirebaseAuth.instance.currentUser!.uid);
//         FirebaseFirestore.instance.collection('the-chosen').doc(FirebaseAuth.instance.currentUser!.uid).collection(FirebaseX.appName).doc(uid).set(modelTheChosen.toMap());
//       }
//       if (number > 1) {
//         ModelTheChosen modelTheChosen =ModelTheChosen(isOfer: false, number: number, uidOfDoc: uid, uidItem: uidItem, uidUser: FirebaseAuth.instance.currentUser!.uid);
//
//         FirebaseFirestore.instance
//             .collection('the-chosen')
//             .doc(FirebaseAuth.instance.currentUser!.uid).collection(FirebaseX.appName)
//             .doc(uid)
//             .set(modelTheChosen.toMap());
//       }
//
//       update();
//     } catch (e) {
//       print('111111111111122222221111111111111111');
//       print(e);
//       print('111111111111122222221111111111111111');
//     }
//   }
//
//
//
//
// //   ^^^^^^^^^^^^^^^---------------------^^^^^^^^^^^^^^^^^^^^^^^------------------^^^^^^^^^^^^
//   //   ^^^^^^^^^^^^^^^---------------------^^^^^^^^^^^^^^^^^^^^^^^------------------^^^^^^^^^^^^
// //   ^^^^^^^^^^^^^^^---------------------^^^^^^^^^^^^^^^^^^^^^^^------------------^^^^^^^^^^^^
//
//
//
//   removeItem(String uid,String uidItem) {
//     try {
//       if (number == 1) {
//         FirebaseFirestore.instance
//             .collection('the-chosen')
//             .doc(FirebaseAuth.instance.currentUser!.uid).collection(FirebaseX.appName)
//             .doc(uid)
//             .delete();
//       }
//       if (number > 0) {
//         number--;
//         ModelTheChosen modelTheChosen =ModelTheChosen(isOfer: false, number: number, uidOfDoc: uid, uidItem: uidItem, uidUser: FirebaseAuth.instance.currentUser!.uid);
//
//         FirebaseFirestore.instance
//             .collection('the-chosen')
//             .doc(FirebaseAuth.instance.currentUser!.uid).collection(FirebaseX.appName)
//             .doc(uid)
//             .update(modelTheChosen.toMap());
//       }
//
//       update();
//     } catch (e) {
//       print('111111111111122222221111111111111111');
//       print(e);
//       print('111111111111122222221111111111111111');
//     }
//   }
//
// }






import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../Model/ModelTheChosen.dart';
import '../../XXX/XXXFirebase.dart';

/// Controller لإضافة وإزالة العناصر من Firestore
class GetAddAndRemoveSearch extends GetxController {
  /// المتغير المسؤول عن تخزين عدد العناصر (باستخدام Rx لتحديث واجهة المستخدم تلقائيًا)
  final RxInt number = 0.obs;

  /// معرف المستخدم الحالي (تخزينه مرة واحدة يقلل من الاستدعاءات المتكررة)
  final String _userId = FirebaseAuth.instance.currentUser!.uid;

  /// دالة لإضافة عنصر إلى Firestore.
  ///
  /// [uid] هو معرف المستند المراد استخدامه كـ docId.
  /// [uidItem] هو معرف العنصر (مثلاً معرف المنتج).
  /// تزيد قيمة [number] ويتم إنشاء/تحديث المستند باستخدام البيانات الحالية.
  Future<void> addItem(String uid, String uidItem,bool isOfer) async {
    try {
      // زيادة العدد
      number.value++;

      // إنشاء نموذج البيانات باستخدام القيمة الحالية
      final ModelTheChosen model = ModelTheChosen(
        isOfer: isOfer,
        number: number.value,
        uidOfDoc: uid,
        uidItem: uidItem,
        uidUser: _userId,
      );

      // إنشاء أو تحديث المستند في مجموعة Firestore المحددة
      await FirebaseFirestore.instance
          .collection('the-chosen')
          .doc(_userId)
          .collection(FirebaseX.appName)
          .doc(uid)
          .set(model.toMap());

      // إعلام الـ GetX بتحديث الحالة
      update();
    } catch (e) {
      print('خطأ في إضافة العنصر: $e');
    }
  }

  /// دالة لإزالة عنصر من Firestore.
  ///
  /// [uid] هو معرف المستند المُستخدم في Firestore.
  /// [uidItem] هو معرف العنصر.
  /// إذا كان عدد العناصر يساوي 1 يتم حذف المستند وإعادة تعيين العدد إلى 0،
  /// وإذا كان العدد أكبر من 1 يتم تقليل العدد وتحديث المستند.
  Future<void> removeItem(String uid, String uidItem,bool isOfer) async {
    try {
      // الخروج في حال عدم وجود عناصر
      if (number.value <= 0) return;

      if (number.value == 1) {
        // إذا كان العدد 1: حذف المستند وإعادة تعيين العدد إلى 0
        await FirebaseFirestore.instance
            .collection('the-chosen')
            .doc(_userId)
            .collection(FirebaseX.appName)
            .doc(uid)
            .delete();
        number.value = 0;
      } else {
        // إذا كان العدد أكبر من 1: تقليل العدد وتحديث المستند
        number.value--;
        final ModelTheChosen model = ModelTheChosen(
          isOfer: isOfer,
          number: number.value,
          uidOfDoc: uid,
          uidItem: uidItem,
          uidUser: _userId,
        );
        await FirebaseFirestore.instance
            .collection('the-chosen')
            .doc(_userId)
            .collection(FirebaseX.appName)
            .doc(uid)
            .update(model.toMap());
      }

      // إعلام GetX بتحديث الحالة
      update();
    } catch (e) {
      print('خطأ في إزالة العنصر: $e');
    }
  }
}
