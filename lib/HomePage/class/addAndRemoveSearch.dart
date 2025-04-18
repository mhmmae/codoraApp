//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:uuid/uuid.dart';
//
// import '../../Model/ModelTheChosen.dart';
// import '../../XXX/XXXFirebase.dart';
// import '../Get-Controllar/addAndRemoveSearch.dart';
//
// class addAndRemoveSearch extends StatelessWidget {
//   addAndRemoveSearch({super.key,this.hi5,this.wi5,this.wi2,this.wi3,this.wi4,required this.uidItem,required this.isOfeer});
//   String uidItem;
//   double? hi5;
//   double? wi5;
//   double? wi2;
//   double? wi3;
//   double? wi4;
//   bool isOfeer;
//   // ^^^^^^^^^---------^^^^^^^^^^----------^^^^^^^^^^^-----------^^^^^^^
//   int number = 0;
//   final uuid =Uuid().v1();
//   @override
//   Widget build(BuildContext context) {
//     double hi = MediaQuery.of(context).size.height;
//     double wi = MediaQuery.of(context).size.width;
//
//
//     return GetBuilder<GetaddAndRemoveSearch>(init: GetaddAndRemoveSearch(),
//       builder: (val){
//         return        Padding(
//           padding: EdgeInsets.symmetric(horizontal: 1),
//           child: Row(
//             children: [
//               GestureDetector(
//                 onTap: (){
//                   try {
//                     number++;
//                     if (number == 1) {
//                       ModelTheChosen modelTheChosen =ModelTheChosen(isOfer: isOfeer, number: number, uidOfDoc: uuid, uidItem: uidItem, uidUser: FirebaseAuth.instance.currentUser!.uid);
//
//                       FirebaseFirestore.instance.collection('the-chosen').doc(FirebaseAuth.instance.currentUser!.uid).collection(FirebaseX.appName).doc(uuid).set(modelTheChosen.toMap());
//                     }
//                     if (number > 1) {
//                       ModelTheChosen modelTheChosen =ModelTheChosen(isOfer: isOfeer, number: number, uidOfDoc: uuid, uidItem: uidItem, uidUser: FirebaseAuth.instance.currentUser!.uid);
//
//                       FirebaseFirestore.instance
//                           .collection('the-chosen')
//                           .doc(FirebaseAuth.instance.currentUser!.uid).collection(FirebaseX.appName)
//                           .doc(uuid)
//                           .set(modelTheChosen.toMap());
//                     }
//
//                     val.update();
//                   } catch (e) {
//                     print('111111111111122222221111111111111111');
//                     print(e);
//                     print('111111111111122222221111111111111111');
//                   }
//
//                 },
//                 child: Container(decoration: BoxDecoration(
//                       color: Colors.black12,
//                       border: Border.all(color: Colors.black26),
//                       borderRadius: BorderRadius.circular(16)
//                   ),height:hi5 ==null ? hi/15  :hi/20,width: wi5 == null ? wi/13 :wi/9 ,child: Center(child: Icon(Icons.add,size: wi2 ?? wi/25 ,)),
//                 ),
//               ),
//               SizedBox(width:wi3 ?? wi/45 ,),
//               Text('$number',style: TextStyle(fontSize:wi4 ?? wi/20 ),),
//               SizedBox(width: wi3 ?? wi/45,),
//
//
//               GestureDetector(
//                 onTap: (){
//
//                   try {
//                     if (number == 1) {
//                       FirebaseFirestore.instance
//                           .collection('the-chosen')
//                           .doc(FirebaseAuth.instance.currentUser!.uid).collection(FirebaseX.appName)
//                           .doc(uuid)
//                           .delete();
//                     }
//                     if (number > 0) {
//                       number--;
//                       ModelTheChosen modelTheChosen =ModelTheChosen(isOfer: isOfeer, number: number, uidOfDoc: uuid, uidItem: uidItem, uidUser: FirebaseAuth.instance.currentUser!.uid);
//
//                       FirebaseFirestore.instance
//                           .collection('the-chosen')
//                           .doc(FirebaseAuth.instance.currentUser!.uid).collection(FirebaseX.appName)
//                           .doc(uuid)
//                           .update(modelTheChosen.toMap());
//                     }
//
//                     val.update();
//                   } catch (e) {
//                     print('111111111111122222221111111111111111');
//                     print(e);
//                     print('111111111111122222221111111111111111');
//                   }
//                 },
//                 child: Container(decoration: BoxDecoration(
//                       color: Colors.black12,
//                       border: Border.all(color: Colors.black26),
//                       borderRadius: BorderRadius.circular(16)
//                   ),height:hi5 ==null ? hi/15 :hi/20,width: wi5 ==null ? wi/13 :wi/9 ,child: Center(child: Icon(Icons.remove,size:wi2 ?? wi/25 ,)),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//
//     );
//   }
// }
















import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../Get-Controllar/addAndRemoveSearch.dart';

/// Widget لعرض أزرار الإضافة والإزالة مع عرض العدد الحالي
/// تم تحسين الاسم ليتبع توصيات Dart (تبدأ الحروف بكبيرة)
class AddAndRemoveSearchWidget extends StatelessWidget {
  /// معرّف العنصر (المنتج)
  final String uidItem;
  /// حالة العرض (عرض أم منتج عادي)
  final bool isOfeer;
  /// إعدادات حجم العناصر اختيارية
  final double? hi5;
  final double? wi5;
  final double? wi2;
  final double? wi3;
  final double? wi4;

  /// إنشاء معرف فريد للمستند باستخدام مكتبة Uuid
  final String uuid = const Uuid().v1();

  AddAndRemoveSearchWidget({
    Key? key,
    required this.uidItem,
    required this.isOfeer,
    this.hi5,
    this.wi5,
    this.wi2,
    this.wi3,
    this.wi4,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // الحصول على أبعاد الشاشة لاستخدامها في التصميم
    double hi = MediaQuery.of(context).size.height;
    double wi = MediaQuery.of(context).size.width;

    // حقن الـ Controller الخاص بهذا العنصر باستخدام tag فريد (هنا: uuid)
    final GetAddAndRemoveSearch controller = Get.put(
      GetAddAndRemoveSearch(),
      tag: uuid,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Row(
        children: [
          // زر الإضافة
          GestureDetector(
            onTap: () async {
              await controller.addItem(uuid,uidItem,isOfeer);
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black12,
                border: Border.all(color: Colors.black26),
                borderRadius: BorderRadius.circular(16),
              ),
              height: hi5 ?? hi / 15,
              width: wi5 ?? wi / 13,
              child: Center(
                child: Icon(
                  Icons.add,
                  size: wi2 ?? wi / 25,
                ),
              ),
            ),
          ),
          SizedBox(width: wi3 ?? wi / 45),
          // عرض العدد الحالي باستخدام Obx للتفاعل مع تغيرات Rx
          Obx(() => Text(
            '${controller.number.value}',
            style: TextStyle(fontSize: wi4 ?? wi / 20),
          )),
          SizedBox(width: wi3 ?? wi / 45),
          // زر الإزالة
          GestureDetector(
            onTap: () async {
              await controller.removeItem(uuid,uidItem,isOfeer);
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black12,
                border: Border.all(color: Colors.black26),
                borderRadius: BorderRadius.circular(16),
              ),
              height: hi5 ?? hi / 15,
              width: wi5 ?? wi / 13,
              child: Center(
                child: Icon(
                  Icons.remove,
                  size: wi2 ?? wi / 25,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

