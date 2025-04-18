// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// import '../../XXX/XXXFirebase.dart';
// import '../GetXController/GetAddAndRemove.dart';
// import 'BosAddAndRemove.dart';
//
// class Streamlistofitem extends StatelessWidget {
//   Streamlistofitem({super.key});
//
//   final Stream<QuerySnapshot> cardItem = FirebaseFirestore.instance
//       .collection('the-chosen')
//       .doc(FirebaseAuth.instance.currentUser!.uid)
//       .collection(FirebaseX.appName)
//   // .where('uidUser', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
//       .snapshots();
//
//
//   ItemUid(String ItemUid2) {
//     return FirebaseFirestore.instance
//         .collection('Item')
//         .doc(ItemUid2)
//         .get();
//   }
//
//
//   ItemOferUid(String ItemUid2) {
//     return FirebaseFirestore.instance
//         .collection('Itemoffer')
//         .doc(ItemUid2)
//         .get();
//   }
//
//
//   DeleteItem(String uidDoc) {
//     return FirebaseFirestore.instance.collection('the-chosen').doc(
//         FirebaseAuth.instance.currentUser!.uid)
//         .collection(FirebaseX.appName)
//         .doc(uidDoc)
//         .delete();
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     double hi = MediaQuery
//         .of(context)
//         .size
//         .height;
//     double wi = MediaQuery
//         .of(context)
//         .size
//         .width;
//     return SizedBox(
//
//
//       height: hi / 2,
//       child: StreamBuilder<QuerySnapshot>(
//           stream: cardItem,
//           builder: (BuildContext context,
//               AsyncSnapshot<QuerySnapshot> snapshot) {
//             if (snapshot.hasError) {
//               return Text('Something went wrong');
//             }
//
//             if (snapshot.connectionState ==
//                 ConnectionState.waiting) {
//               return Text('loading');
//             }
//
//             return snapshot.data!.docs.isNotEmpty
//                 ? ListView(
//               shrinkWrap: true,
//               primary: true,
//
//               children: snapshot.data!.docs
//                   .map((DocumentSnapshot document) {
//                 Map<String, dynamic> data3 = document
//                     .data()! as Map<String, dynamic>;
//                 return FutureBuilder<DocumentSnapshot>(
//                   future: data3['isOfer'] == false
//                       ? ItemUid(data3['uidItem'])
//                       : ItemOferUid(data3['uidItem']),
//                   builder: (BuildContext context,
//                       AsyncSnapshot<DocumentSnapshot>
//                       snapshot) {
//                     if (snapshot.hasError) {
//                       return Text("Something went wrong");
//                     }
//
//                     if (snapshot.hasData &&
//                         !snapshot.data!.exists) {
//                       return Text(
//                           "Document does not exist");
//                     }
//
//                     if (snapshot.connectionState ==
//                         ConnectionState.done) {
//                       Map<String, dynamic> data =
//                       snapshot.data!.data()
//                       as Map<String, dynamic>;
//
//
//                       return
//                         Padding(padding: EdgeInsets.symmetric(
//                             horizontal: 10, vertical: 4),
//                           child: Container(
//                             width: double.infinity,
//                             height: hi / 8,
//                             decoration: BoxDecoration(
//                                 color: Colors.white,
//                                 borderRadius: BorderRadius.circular(15),
//                                 border: Border.all(color: Colors.black38)
//                             ),
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 Row(
//                                   children: [
//                                     SizedBox(width: wi / 46,),
//                                     Padding(
//                                       padding: const EdgeInsets.all(1),
//                                       child: Container(
//                                         height: hi / 10.6, width: wi / 5,
//                                         decoration: BoxDecoration(
//                                             image: DecorationImage(
//                                                 fit: BoxFit.cover,
//                                                 image: NetworkImage(data['url'])
//                                             )
//                                         ),
//                                       ),
//                                     ),
//                                     SizedBox(width: wi / 26,),
//                                     Padding(
//                                       padding: const EdgeInsets.symmetric(
//                                           vertical: 12),
//                                       child: Column(
//                                         mainAxisAlignment: MainAxisAlignment
//                                             .spaceBetween,
//                                         children: [
//                                           Text(data['nameOfItem'],
//                                             style: TextStyle(
//                                                 fontSize: wi / 30),),
//                                           Text(data['priceOfItem'].toString(),
//                                             style: TextStyle(
//                                                 fontSize: wi / 35),)
//                                         ],
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 Padding(
//                                   padding: const EdgeInsets.symmetric(
//                                       vertical: 12),
//                                   child: Column(
//                                     mainAxisAlignment: MainAxisAlignment
//                                         .spaceBetween,
//                                     children: [
//
//                                       GetBuilder<GetAddAndRemove>(init: GetAddAndRemove(),
//                                           builder: (logic) {
//                                             return GestureDetector(
//                                                 onTap: () async{
//                                                   DeleteItem(data3['uidOfDoc']
//                                                       .toString());
//                                                   logic.total=0;
//                                                   logic.number=0;
//                                                   logic.totalPriceOfItem=0;
//                                                   logic.price=0;
//                                                   logic.totalPriceOfofferItem=0;
//                                                   logic.totalPrice=0;
//                                                   await Future.delayed(Duration(milliseconds: 100));
//
//                                                   logic.onInit();
//                                                   logic.update();
//                                                 },
//                                                 child: Icon(
//                                                   Icons.delete_forever,
//                                                   color: Colors.red,));
//                                           }),
//                                       Row(
//                                         children: [
//                                           AddAndRemove(
//                                             // number: data3['number'],
//                                             uidItem: data3['uidItem'],
//                                             uidOfDoc: data3['uidOfDoc'],
//                                             isOfer: data3['isOfer'],),
//                                           SizedBox(width: wi / 15,)
//                                         ],
//                                       )
//                                     ],
//                                   ),
//                                 ),
//
//
//                               ],
//                             ),
//                           ),);
//                     }
//
//                     return Text("loading");
//                   },
//                 );
//               }).toList(),
//             )
//                 : Center(child: Text('لا يوجد منتجات '),);
//           }),
//
//     );
//   }
// }


























// stream_list_of_item.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../XXX/XXXFirebase.dart';
import '../GetXController/GetAddAndRemove.dart';
import 'BosAddAndRemove.dart';

/// ودجة لعرض العناصر في السلة (البطاقة) باستخدام Stream من Firestore.
/// تقوم الودجة بالاستماع إلى تغييرات المستندات في مجموعة السلة لجلب بيانات كل منتج،
/// ثم تعرض تفاصيل المنتج مع أزرار لتعديل الكمية (زيادة/نقصان) وحذف المنتج.
class StreamListOfItem extends StatelessWidget {
  StreamListOfItem({Key? key}) : super(key: key);

  // Stream لجلب بيانات المنتجات الموجودة في السلة (the-chosen).
  final Stream<QuerySnapshot> cardItemStream = FirebaseFirestore.instance
      .collection('the-chosen')
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .collection(FirebaseX.appName)
      .snapshots();

  /// دالة لاسترجاع بيانات المنتج من مجموعة "Item" باستخدام معرف المنتج.
  Future<DocumentSnapshot> fetchItem(String itemUid) {
    return FirebaseFirestore.instance.collection('Item').doc(itemUid).get();
  }

  /// دالة لاسترجاع بيانات المنتج من مجموعة "Itemoffer" باستخدام معرف المنتج.
  Future<DocumentSnapshot> fetchItemOffer(String itemUid) {
    return FirebaseFirestore.instance.collection('Itemoffer').doc(itemUid).get();
  }

  /// دالة لحذف عنصر من السلة باستخدام معرف المستند.
  Future<void> deleteCartItem(String uidDoc) async {
    await FirebaseFirestore.instance
        .collection('the-chosen')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection(FirebaseX.appName)
        .doc(uidDoc)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final double hi = MediaQuery.of(context).size.height;
    final double wi = MediaQuery.of(context).size.width;

    return SizedBox(
      height: hi / 2,
      child: StreamBuilder<QuerySnapshot>(
        stream: cardItemStream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          // معالجة الخطأ أثناء جلب البيانات.
          if (snapshot.hasError) {
            return Center(
                child: Text('حدث خطأ أثناء جلب البيانات. الرجاء المحاولة مرة أخرى'));
          }
          // عرض حالة الانتظار أثناء التحميل.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: Text('جار التحميل...'));
          }
          // التحقق من وجود مستندات.
          if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('لا يوجد منتجات.'));
          }

          // بناء قائمة العناصر باستخدام بيانات المستندات.
          return ListView(
            shrinkWrap: true,
            primary: true,
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              // تحويل بيانات المستند إلى خريطة مع التحقق من null-safety.
              final dataMap = document.data() as Map<String, dynamic>?;
              if (dataMap == null) {
                return const SizedBox();
              }
              // استخراج الحقول الأساسية مع تحديد القيم الافتراضية.
              final bool isOffer = dataMap['isOfer'] as bool? ?? false;
              final String uidItem = dataMap['uidItem'] as String? ?? "";
              final String uidOfDoc = dataMap['uidOfDoc'] as String? ?? "";
              final int number = dataMap['number'] as int? ?? 0;

              // تحديد الدالة المناسبة لاسترجاع بيانات المنتج (عادية أو عرض).
              Future<DocumentSnapshot> productFuture =
              isOffer ? fetchItemOffer(uidItem) : fetchItem(uidItem);

              return FutureBuilder<DocumentSnapshot>(
                future: productFuture,
                builder: (BuildContext context,
                    AsyncSnapshot<DocumentSnapshot> productSnapshot) {
                  if (productSnapshot.hasError) {
                    return Center(child: Text("حدث خطأ أثناء جلب تفاصيل المنتج"));
                  }
                  if (productSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: Text("جار التحميل..."));
                  }
                  if (!productSnapshot.hasData ||
                      !productSnapshot.data!.exists) {
                    return Center(child: Text("المنتج غير موجود"));
                  }
                  // استخراج بيانات المنتج مع التحقق من null.
                  final productData =
                  productSnapshot.data!.data() as Map<String, dynamic>?;
                  if (productData == null) return const SizedBox();

                  final String imageUrl = productData['url'] as String? ?? "";
                  final String nameOfItem =
                      productData['nameOfItem'] as String? ?? "";
                  final dynamic priceDynamic = productData['priceOfItem'];
                  final String priceOfItemStr = priceDynamic != null
                      ? priceDynamic.toString()
                      : "";

                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: Container(
                      width: double.infinity,
                      height: hi / 8,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.black38),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // الجانب الأيسر: عرض صورة المنتج وتفاصيله.
                          Row(
                            children: [
                              SizedBox(width: wi / 46),
                              Padding(
                                padding: const EdgeInsets.all(1),
                                child: Container(
                                  height: hi / 10.6,
                                  width: wi / 5,
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      fit: BoxFit.cover,
                                      image: NetworkImage(imageUrl),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: wi / 26),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Column(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nameOfItem,
                                      style: TextStyle(fontSize: wi / 30),
                                    ),
                                    Text(
                                      priceOfItemStr,
                                      style: TextStyle(fontSize: wi / 35),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // الجانب الأيمن: عرض إجراءات حذف المنتج وتعديل الكمية.
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Column(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                // زر حذف المنتج باستخدام GetBuilder لتحديث الحالة.
                                GetBuilder<GetAddAndRemove>(
                                  init: GetAddAndRemove(),
                                  builder: (logic) {
                                    return GestureDetector(
                                      onTap: () async {
                                        try {
                                          await deleteCartItem(uidOfDoc);
                                          // إعادة تعيين بيانات المتحكم لتحديث الأسعار.
                                          logic.total.value = 0;
                                          logic.totalPriceOfItem.value = 0;
                                          logic.totalPriceOfofferItem.value = 0;
                                          logic.totalPrice.value = 0;
                                          await Future.delayed(
                                              Duration(milliseconds: 100));
                                          logic.onInit();
                                          logic.update();
                                        } catch (e) {
                                          Get.snackbar(
                                            'خطأ',
                                            'حدث خطأ أثناء حذف المنتج: $e',
                                            backgroundColor: Colors.red,
                                            colorText: Colors.white,
                                          );
                                        }
                                      },
                                      child: const Icon(
                                        Icons.delete_forever,
                                        color: Colors.red,
                                      ),
                                    );
                                  },
                                ),
                                // عرض عناصر تعديل الكمية باستخدام ودجة AddAndRemove.
                                Row(
                                  children: [
                                    AddAndRemove(
                                      uidItem: uidItem,
                                      uidOfDoc: uidOfDoc,
                                      isOfer: isOffer,
                                      number: number,
                                    ),
                                    SizedBox(width: wi / 15),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
