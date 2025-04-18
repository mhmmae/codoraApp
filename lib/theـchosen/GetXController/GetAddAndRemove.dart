//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:get/get.dart';
//
// import '../../XXX/XXXFirebase.dart';
//
// class GetAddAndRemove extends GetxController{
//   int number=0;
//   int price =0;
//   int total =0;
//   int totalPriceOfItem =0;
//   int totalPriceOfofferItem = 0;
//   int totalPrice =0;
//   int PriceOfItem=0;
//   int PriceOfofferItem = 0;
//
//
//   @override
//   void onInit() async{
//
//     FirebaseFirestore.instance
//         .collection('the-chosen').doc(FirebaseAuth.instance.currentUser!.uid).collection(FirebaseX.appName)
//         .get()
//         .then((QuerySnapshot querySnapshot) {
//       querySnapshot.docs.forEach((doc1) async{
//        await FirebaseFirestore.instance
//             .collection('Item')
//             .doc(doc1["uidItem"])
//             .get()
//             .then((DocumentSnapshot documentSnapshotItem) {
//
//
//
//
//                 if(documentSnapshotItem.exists){
//
//                     PriceOfItem = documentSnapshotItem.get('priceOfItem') * doc1["number"];
//                    totalPriceOfItem +=PriceOfItem;
//
//
//
//
//
//
//                 }
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//         });
//
//
//
//       await  FirebaseFirestore.instance
//             .collection('Itemoffer')
//             .doc(doc1["uidItem"])
//             .get()
//             .then((DocumentSnapshot documentSnapshotofferItem) {
//
//               if(documentSnapshotofferItem.exists){
//                   PriceOfofferItem = documentSnapshotofferItem.get('priceOfItem') * doc1["number"];
//                 totalPriceOfofferItem += PriceOfofferItem;
//
//
//
//
//
//
//               }
//
//
//
//
//
//
//         });
//
//        total = totalPriceOfofferItem +totalPriceOfItem;
//        update();
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//       });
//     });
//
//     // TODO: implement onInit
//     super.onInit();
//   }
//   @override
//   void dispose() {
//      number=0;
//      price =0;
//      total =0;
//      totalPriceOfItem =0;
//     // TODO: implement dispose
//     super.dispose();
//   }
//
//
//
//   // addItem2() {
//   //
//   //   try {
//   //     number++;
//   //
//   //     if (number == 1) {
//   //       FirebaseFirestore.instance.collection('the-chosen').doc(uidOfDoc).set({
//   //         'uidUser': FirebaseAuth.instance.currentUser!.uid,
//   //         'uidItem': uidItem,
//   //         'uidOfDoc': uidOfDoc,
//   //         'number': number
//   //       });
//   //     } if (number > 1) {
//   //       FirebaseFirestore.instance
//   //           .collection('the-chosen')
//   //           .doc(uidOfDoc)
//   //           .set({
//   //         'uidUser': FirebaseAuth.instance.currentUser!.uid,
//   //         'uidItem': uidItem,
//   //         'uidOfDoc':uidOfDoc,
//   //         'number': number
//   //       });
//   //     }
//   //
//   //     update();
//   //
//   //
//   //
//   //
//   //   } catch (e) {}
//   // }
// }





































import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../XXX/XXXFirebase.dart';

/// يتحكم هذا المتحكم في إضافة وحذف العناصر من السلة وحساب الأسعار الإجمالية.
/// يعتمد على خريطة لتخزين الكميات الحالية لكل مستند ويستخدم استعلامات متوازية (Future.wait)
/// للحصول على الأسعار من مجموعتي "Item" و"Itemoffer".
class GetAddAndRemove extends GetxController {
  // يخزن الكميات الحالية لكل مستند باستخدام uidOfDoc كمفتاح
  final Map<String, int> _itemQuantities = {};

  // متغيرات Rx لمتابعة التحديثات في الأسعار
  RxInt total = 0.obs;
  RxInt totalPriceOfItem = 0.obs;
  RxInt totalPriceOfofferItem = 0.obs;
  RxInt totalPrice = 0.obs;

  /// دالة لحساب الأسعار الإجمالية بشكل متوازي مع استرجاع بيانات كلا المجموعتين
  Future<void> calculateTotals() async {
    final String userId = FirebaseAuth.instance.currentUser!.uid;
    try {
      totalPriceOfItem.value = 0;
      totalPriceOfofferItem.value = 0;

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('the-chosen')
          .doc(userId)
          .collection(FirebaseX.appName)
          .get();

      // قائمة لتخزين Future العمليات الخاصة بجلب الأسعار
      List<Future<void>> priceFutures = [];

      for (var doc in querySnapshot.docs) {
        // تحويل البيانات إلى Map والتحقق من كونها غير null
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;
        // الحصول على الكمية مع القيمة الافتراضية 0 في حال كانت null
        int itemCount = data['number'] as int? ?? 0;
        // الحصول على uidItem مع التحقق من عدم كونها فارغة
        final uidItem = data['uidItem'] as String? ?? "";
        if (uidItem.isEmpty) continue;

        // تخزين الكمية محلياً لتسهيل الحصول عليها لاحقاً
        _itemQuantities[doc.id] = itemCount;

        // عملية جلب بيانات المنتج من مجموعتي "Item" و"Itemoffer" بشكل متوازي
        priceFutures.add(
          Future.wait([
            FirebaseFirestore.instance.collection('Item').doc(uidItem).get(),
            FirebaseFirestore.instance.collection('Itemoffer').doc(uidItem).get(),
          ]).then((List<DocumentSnapshot> snapshots) {
            final productSnapshot = snapshots[0];
            final offerSnapshot = snapshots[1];
            int priceNormal = 0;
            int priceOffer = 0;

            // قراءة السعر من مجموعة المنتجات الأساسية إذا كانت موجودة
            if (productSnapshot.exists) {
              try {
                priceNormal = productSnapshot.get('priceOfItem') as int;
              } catch (e) {
                print("Error parsing normal item price: $e");
              }
            }
            // قراءة السعر من مجموعة العروض إذا كانت موجودة
            if (offerSnapshot.exists) {
              try {
                priceOffer = offerSnapshot.get('priceOfItem') as int;
              } catch (e) {
                print("Error parsing offer item price: $e");
              }
            }

            // تحديث الإجماليات بناءً على الكمية
            totalPriceOfItem.value += priceNormal * itemCount;
            totalPriceOfofferItem.value += priceOffer * itemCount;
          }),
        );
      }

      // الانتظار حتى يتم الانتهاء من جميع عمليات الجلب
      await Future.wait(priceFutures);
      total.value = totalPriceOfItem.value + totalPriceOfofferItem.value;
      update();
      print('    await calculateTotals()222222222222222');
    } catch (e) {
      print("Error calculating totals: $e");
      rethrow;
    }
  }

  /// تحدث الأسعار الإجمالية بعد أي تغيير في السلة
  Future<void> refreshTotals() async {
    print('refreshTotals11111111111111111111111');
    await calculateTotals();
    update();

  }

  /// دالة لزيادة كمية عنصر معين.
  /// تُحدِّث قاعدة البيانات وتعيد حساب الإجماليات.
  Future<void> incrementItem({
    required String uidItem,
    required String uidOfDoc,
    required bool isOfer,
  }) async {
    final String userId = FirebaseAuth.instance.currentUser!.uid;
    final docRef = FirebaseFirestore.instance
        .collection('the-chosen')
        .doc(userId)
        .collection(FirebaseX.appName)
        .doc(uidOfDoc);

    int currentCount = _itemQuantities[uidOfDoc] ?? 0;
    currentCount++;
    _itemQuantities[uidOfDoc] = currentCount;

    // تحديث Firestore باستخدام set (insert/update)
    await docRef.set({
      'uidUser': userId,
      'uidItem': uidItem,
      'uidOfDoc': uidOfDoc,
      'number': currentCount,
      'isOfer': isOfer,
    });

    await refreshTotals();
    update();
  }

  /// دالة لتقليل كمية عنصر معين.
  /// إذا كانت الكمية 1 أو أقل، يتم حذف السجل.
  Future<void> decrementItem({
    required String uidItem,
    required String uidOfDoc,
    required bool isOfer,
  }) async {
    final String userId = FirebaseAuth.instance.currentUser!.uid;
    final docRef = FirebaseFirestore.instance
        .collection('the-chosen')
        .doc(userId)
        .collection(FirebaseX.appName)
        .doc(uidOfDoc);

    int currentCount = _itemQuantities[uidOfDoc] ?? 0;

    if (currentCount <= 1) {
      await docRef.delete();
      _itemQuantities[uidOfDoc] = 0;
    } else {
      currentCount--;
      _itemQuantities[uidOfDoc] = currentCount;
      await docRef.update({
        'uidUser': userId,
        'uidItem': uidItem,
        'uidOfDoc': uidOfDoc,
        'number': currentCount,
        'isOfer': isOfer,
      });
    }
    await refreshTotals();
    update();
  }

  /// دالة لاسترجاع الكمية الحالية لمستند معين بناءً على uidOfDoc.
  int getCurrentItemCount(String uidOfDoc) {
    return _itemQuantities[uidOfDoc] ?? 0;
  }

  @override
  void onInit() {
    super.onInit();
    update();
    // تحديث الأسعار عند بدء تهيئة المتحكم
    refreshTotals();
    update();
  }

  @override
  void dispose() {
    update();
    _itemQuantities.clear();
    total.value = 0;
    totalPriceOfItem.value = 0;
    totalPriceOfofferItem.value = 0;
    totalPrice.value = 0;
    super.dispose();
  }
}
