//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:uuid/uuid.dart';
//
// import '../../Model/ModelTheChosen.dart';
// import '../../XXX/XXXFirebase.dart';
// import '../Get-Controllar/Get-BoxAddAndRemover.dart';
//
//
// class BoxAddAndRemove extends StatelessWidget {
//   BoxAddAndRemove({
//     super.key,
//     required this.uidItem,
//     required this.Name,
//     required this.price,
//   });
//
//   String uidItem;
//   String price;
//   String Name;
//   final uuid = Uuid().v1();
//   int number = 0;
//
//   @override
//   Widget build(BuildContext context) {
//     double hi = MediaQuery.of(context).size.height;
//     double wi = MediaQuery.of(context).size.width;
//     return Padding(
//       padding: const EdgeInsets.all(8.0),
//       child: Container(
//           width: double.infinity,
//           decoration: BoxDecoration(
//
//               borderRadius: BorderRadius.circular(15), color: Colors.black12),
//           child: Column(
//             children: [
//               SizedBox(
//                 height: hi / 100,
//               ),
//               Center(
//                   child: Text(
//                     Name,
//                     style: TextStyle(fontSize: wi / 35),
//                   )),
//               SizedBox(
//                 height: hi / 55,
//                 child: Divider(),
//               ),
//               Text(
//                 price,
//                 style: TextStyle(fontSize: wi / 35),
//               ),
//               SizedBox(
//                   height: hi / 65,
//                   child: Divider(
//                     height: 5,
//                   )),
//               Container(
//                 decoration:
//                 BoxDecoration(borderRadius: BorderRadius.circular(15)),
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 10),
//                   child: GetBuilder<GetBoxAddAndRemove>(
//                       init: GetBoxAddAndRemove(),
//                       builder: (val) {
//                         return Row(
//                           children: [
//                             SizedBox(
//                               width: wi / 90,
//                             ),
//
//                             GestureDetector(
//                               onTap: () {
//
//                                   try {
//
//                                     number++;
//                                     if (number == 1) {
//       ModelTheChosen modelTheChosen =ModelTheChosen(isOfer: false, number: number, uidOfDoc: uuid, uidItem: uidItem, uidUser: FirebaseAuth.instance.currentUser!.uid);
//
//                                       FirebaseFirestore.instance.collection('the-chosen')
//                                           .doc(FirebaseAuth.instance.currentUser!.uid).collection(FirebaseX.appName)
//                                           .doc(uuid).set(modelTheChosen.toMap());
//                                     }
//                                     if (number > 1) {
//         ModelTheChosen modelTheChosen =ModelTheChosen(isOfer: false, number: number, uidOfDoc: uuid, uidItem: uidItem, uidUser: FirebaseAuth.instance.currentUser!.uid);
//
//                                       FirebaseFirestore.instance
//                                           .collection('the-chosen')
//                                           .doc(FirebaseAuth.instance.currentUser!.uid).collection(FirebaseX.appName)
//                                           .doc(uuid)
//                                           .set(modelTheChosen.toMap());
//                                     }
//                                     val.update();
//
//                                   } catch (e) {
//                                     print('111111111111122222221111111111111111');
//                                     print(e);
//                                     print('111111111111122222221111111111111111');
//                                   }
//
//                               },
//                               child: Container(
//                                   width: wi / 15,
//                                   height: hi / 25,
//                                   color: Colors.transparent,
//                                   child: Icon(
//                                     Icons.add,
//                                     size: wi / 17,
//                                   )),
//                             ),
//                             SizedBox(
//                               width: wi / 70,
//                             ),
//                             // GetBuilder<GetHome>(init: GetHome(),builder: (val){
//                             //   return
//                             // }),
//                             Text(
//                               '$number',
//                               style: TextStyle(fontSize: wi / 27),
//                             ),
//                             SizedBox(
//                               width: wi / 70,
//                             ),
//                             GestureDetector(
//                               child: Container(
//                                   width: wi / 15,
//                                   height: hi / 25,
//                                   color: Colors.transparent,
//                                   child: Icon(
//                                     Icons.remove,
//                                     size: wi / 17,
//                                   )),
//                               onTap: () {
//                                 try {
//                                   if (number == 1) {
//                                     FirebaseFirestore.instance
//                                         .collection('the-chosen')
//                                         .doc(FirebaseAuth.instance.currentUser!.uid).collection(FirebaseX.appName)
//                                         .doc(uuid)
//                                         .delete();
//                                   }
//                                   if (number > 0) {
//                                     number--;
//                                     ModelTheChosen modelTheChosen =ModelTheChosen(isOfer: false, number: number, uidOfDoc: uuid, uidItem: uidItem, uidUser: FirebaseAuth.instance.currentUser!.uid);
//
//                                     FirebaseFirestore.instance
//                                         .collection('the-chosen')
//                                         .doc(FirebaseAuth.instance.currentUser!.uid).collection(FirebaseX.appName)
//                                         .doc(uuid)
//                                         .update(modelTheChosen.toMap());
//                                   }
//
//                                   val.update();
//                                 } catch (e) {
//                                   print('111111111111122222221111111111111111');
//                                   print(e);
//                                   print('111111111111122222221111111111111111');
//                                 }
//
//                               },
//                             )
//                           ],
//                         );
//                       }),
//                 ),
//               ),
//             ],
//           )),
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../Get-Controllar/Get-BoxAddAndRemover.dart';

class BoxAddAndRemove extends StatelessWidget {
  // معرّف العنصر (المنتج) الذي سيتم التعامل معه
  final String uidItem;
  // السعر المعروض
  final String price;
  // الاسم المعروض للعنصر
  final String name;
  // معرف فريد للمستند يتم إنشاؤه باستخدام مكتبة Uuid
  final String uuid = const Uuid().v1();

  BoxAddAndRemove({
    Key? key,
    required this.uidItem,
    required this.name,
    required this.price,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // الحصول على أبعاد الشاشة لتحديد مقاسات العناصر
    final double hi = MediaQuery.of(context).size.height;
    final double wi = MediaQuery.of(context).size.width;

    // حقن الـ Controller الخاص بهذا العنصر باستخدام tag فريد (هنا يتم استخدام uuid)
    final GetBoxAddAndRemove controller = Get.put(
      GetBoxAddAndRemove(docId: uuid, uidItem: uidItem),
      tag: uuid,
    );

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.black12,
        ),
        child: Column(
          children: [
            SizedBox(height: hi / 100), // مسافة علوية
            Center(
              child: Text(
                name,
                style: TextStyle(fontSize: wi / 35),
              ),
            ),
            SizedBox(
              height: hi / 55,
              child: Divider(),
            ),
            Text(
              price,
              style: TextStyle(fontSize: wi / 35),
            ),
            SizedBox(
              height: hi / 65,
              child: Divider(height: 5),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    SizedBox(width: wi / 90),
                    // أيقونة الإضافة: عند الضغط تُستدعى دالة addItem في الـ Controller
                    GestureDetector(
                      onTap: () async {
                        await controller.addItem();
                      },
                      child: Container(
                        width: wi / 15,
                        height: hi / 25,
                        color: Colors.transparent,
                        child: Icon(
                          Icons.add,
                          size: wi / 17,
                        ),
                      ),
                    ),
                    SizedBox(width: wi / 70),
                    // عرض العدد الحالي باستخدام Obx لمراقبة المتغير [number] تلقائيًا
                    Obx(() => Text(
                      '${controller.number.value}',
                      style: TextStyle(fontSize: wi / 27),
                    )),
                    SizedBox(width: wi / 70),
                    // أيقونة الحذف: عند الضغط تُستدعى دالة removeItem في الـ Controller
                    GestureDetector(
                      onTap: () async {
                        await controller.removeItem();
                      },
                      child: Container(
                        width: wi / 15,
                        height: hi / 25,
                        color: Colors.transparent,
                        child: Icon(
                          Icons.remove,
                          size: wi / 17,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
