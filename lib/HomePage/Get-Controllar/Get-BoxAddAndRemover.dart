//
// import 'dart:io';
//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_native_splash/flutter_native_splash.dart';
// import 'package:get/get.dart';
//
// import '../../Model/ModelTheChosen.dart';
// import '../../XXX/XXXFirebase.dart';
//
// class GetBoxAddAndRemove extends GetxController{
//   int number =0;
//
//
//
//   addItem2(String uid,String uidItem,) {
//     try {
//
//       number++;
//       if (number == 1) {
//         ModelTheChosen modelTheChosen =ModelTheChosen(isOfer: false, number: number, uidOfDoc: uid, uidItem: uidItem, uidUser: FirebaseAuth.instance.currentUser!.uid);
//
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
//       update();
//
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
// update();
//     } catch (e) {
//       print('111111111111122222221111111111111111');
//       print(e);
//       print('111111111111122222221111111111111111');
//     }
//   }
//
//   @override
//   void onInit() {
//
//
//     FirebaseFirestore.instance
//         .collection(FirebaseX.collectionApp)
//         .doc(FirebaseAuth.instance.currentUser!.uid)
//         .get()
//         .then((DocumentSnapshot documentSnapshot) {
//       if (documentSnapshot.exists) {
//
//         if(Platform.isIOS){
//           FirebaseMessaging.instance.getAPNSToken().then((val){
//             print('hhhhhhhhhhhhhhhhhhhhhhhhhh');
//
//             print(val);
//
//             if(documentSnapshot.get('token') != val ){
//               FirebaseFirestore.instance
//                   .collection(FirebaseX.collectionApp)
//                   .doc(FirebaseAuth.instance.currentUser!.uid).update({
//                 'token': val.toString()
//               });
//
//             }
//           });
//
//         }else{
//           FirebaseMessaging.instance.getToken().then((val){
//             print('hhhhhhhhhhhhhhhhhhhhhhhhhh');
//
//             print(val);
//
//             if(documentSnapshot.get('token') != val ){
//               FirebaseFirestore.instance
//                   .collection(FirebaseX.collectionApp)
//                   .doc(FirebaseAuth.instance.currentUser!.uid).update({
//                 'token': val.toString()
//               });
//
//             }
//           });
//
//         }
//
//
//
//       }
//     });
//     // TODO: implement onInit
//     super.onInit();
//   }
//
// }
















import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../Model/ModelTheChosen.dart';
import '../../XXX/XXXFirebase.dart';

class GetBoxAddAndRemove extends GetxController {
  // معرّف المستند الخاص بالعنصر في Firestore
  final String docId;
  // معرّف العنصر (المنتج)
  final String uidItem;
  // الحصول على معرف المستخدم الحالي لتقليل الاستدعاءات المتكررة للمصادقة
  final String _userId = FirebaseAuth.instance.currentUser!.uid;

  // استخدام RxInt لمراقبة عدد العناصر بشكل تلقائي
  var number = 0.obs;

  GetBoxAddAndRemove({required this.docId, required this.uidItem});

  /// الحصول على مرجع المستند داخل مجموعة 'the-chosen'
  DocumentReference get docRef => FirebaseFirestore.instance
      .collection('the-chosen')
      .doc(_userId)
      .collection(FirebaseX.appName)
      .doc(docId);

  /// دالة لإضافة عنصر:
  /// - تزيد العدد وتقوم بتحديث أو إنشاء المستند في Firestore
  Future<void> addItem() async {
    try {
      number.value++; // زيادة العدد
      // إنشاء النموذج باستخدام البيانات الحالية
      final model = ModelTheChosen(
        isOfer: false,
        number: number.value,
        uidOfDoc: docId,
        uidItem: uidItem,
        uidUser: _userId,
      );
      // استخدام set لإضافة أو تحديث البيانات
      await docRef.set(model.toMap());
    } catch (e) {
      print('خطأ في إضافة العنصر: $e');
    }
  }

  /// دالة لإزالة عنصر:
  /// - تقلل العدد وتقوم بتحديث المستند أو حذفه إذا وصل العدد إلى صفر
  Future<void> removeItem() async {
    try {
      if (number.value > 0) {
        number.value--; // تقليل العدد
        if (number.value == 0) {
          // حذف المستند إذا لم يتبقَ عناصر
          await docRef.delete();
        } else {
          // تحديث المستند بالعدد الجديد
          final model = ModelTheChosen(
            isOfer: false,
            number: number.value,
            uidOfDoc: docId,
            uidItem: uidItem,
            uidUser: _userId,
          );
          await docRef.update(model.toMap());
        }
      }
    } catch (e) {
      print('خطأ في إزالة العنصر: $e');
    }
  }
}
