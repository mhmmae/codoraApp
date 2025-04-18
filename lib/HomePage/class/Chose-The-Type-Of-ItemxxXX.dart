//
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// import '../../XXX/XXXFirebase.dart';
//
// class ChoseTheTypeOfItem extends StatelessWidget {
//    const ChoseTheTypeOfItem({super.key,});
//
//
//
//   @override
//   Widget build(BuildContext context) {
//     double hi = MediaQuery.of(context).size.height;
//     double wi = MediaQuery.of(context).size.width;
//     return  GetBuilder<Getchosethetypeofitem>(init: Getchosethetypeofitem(),builder: (val){
//       return ListView(
//         shrinkWrap: true,
//         physics: const NeverScrollableScrollPhysics(),
//         children: [
//           Container(height: hi/16,decoration: BoxDecoration(
//               border: Border.symmetric(horizontal: BorderSide(color: Colors.black))
//           ),
//             child: ListView.builder(itemCount: val.TheWher.length,shrinkWrap: true,scrollDirection: Axis.horizontal
//                 ,itemBuilder: (context,index){
//
//
//
//
//               List<Icon> icon = [Icon(Icons.phone_android,size: wi/22,),Icon(Icons.phone_android,size: wi/22),Icon(Icons.phone_android,size: wi/22),Icon(Icons.headphones,size: wi/22),Icon(Icons.tab),Icon(Icons.javascript,size: wi/22),
//                     Icon(Icons.kayaking,size: wi/22),Icon(Icons.update,size: wi/22),Icon(Icons.label_important,size: wi/22),Icon(Icons.yard,size: wi/22),];
//
//
//
//                   return Padding(
//                     padding:  const EdgeInsets.symmetric(horizontal: 5),
//                     child: GestureDetector(onTap: (){
//
//                       val.update();
//                       val.TheChosen = val.TheWher[index];
//
//
//
//                     },child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//
//
//                         Container(decoration: BoxDecoration(
//                             color: val.TheChosen != val.TheWher[index]? Colors.black12:Colors.deepPurpleAccent,
//                             borderRadius: BorderRadius.circular(16),
//                             border: Border.all(color: Colors.black)
//                         ),
//                           width: wi/3,height: hi/22,
//                           child: Padding(
//                             padding: const EdgeInsets.symmetric(horizontal: 9),
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//
//                                 icon[index],
//                                 SizedBox(width: wi/80,),
//                                 Text(val.text[index],style: TextStyle(fontSize: wi/40),),
//                               ],
//                             ),
//                           ),),
//                       ],
//                     )),
//                   );
//                 }),
//           ),
//
//         ],
//       );
//     });
//
//
//   }
//
// }
// مكتبات Flutter و GetX الضرورية

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../Model/ModelItem.dart';
import '../../Model/ModelOfferItem.dart';
import '../../XXX/XXXFirebase.dart';
import '../../addItem/addNewItem/class/ClassOfAddItem.dart';
import '../../addItem/addNewItem/class/getAddManyImage.dart';
import '../../bottonBar/botonBar.dart'; // هنا يمكنك استبدال XXX بالمسار الصحيح
import 'dart:typed_data';


// الكلاس المسؤول عن اختيار نوع العنصر
class ChoseTheTypeOfItem extends StatelessWidget {
  const ChoseTheTypeOfItem({super.key});

  @override
  Widget build(BuildContext context) {
    double hi = MediaQuery.of(context).size.height;
    double wi = MediaQuery.of(context).size.width;

    // استخدام GetBuilder لإدارة الحالة
    return GetBuilder<Getchosethetypeofitem>(
      init: Getchosethetypeofitem(),
      builder: (controller) {
        return ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(), // تعطيل التمرير
          children: [
            // حاوية تحتوي على عناصر يتم عرضها أفقياً
            Container(
              height: hi / 16,
              decoration: const BoxDecoration(
                border: Border.symmetric(horizontal: BorderSide(color: Colors.black)),
              ),
              child: ListView.builder(
                itemCount: controller.TheWher.length,
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  // لائحة أيقونات العنصر
                  List<Icon> icons = [
                    Icon(Icons.phone_android, size: wi / 22),
                    Icon(Icons.headphones, size: wi / 22),
                    Icon(Icons.tab, size: wi / 22),
                  ];

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: GestureDetector(
                      onTap: () {
                        controller.update(); // تحديث الحالة
                        controller.TheChosen = controller.TheWher[index];
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: controller.TheChosen != controller.TheWher[index]
                              ? Colors.black12
                              : Colors.deepPurpleAccent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black),
                        ),
                        width: wi / 3,
                        height: hi / 22,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 9),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              icons[index % icons.length], // اختيار الأيقونة بالدور
                              SizedBox(width: wi / 80),
                              Text(
                                controller.text[index],
                                style: TextStyle(fontSize: wi / 40),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// الكلاس المسؤول عن إدارة البيانات باستخدام GetX
class Getinformationofitem extends GetxController {
  Getinformationofitem({required this.uint8list,required this.TypeItem,required this.descriptionOfItem,
    required this.nameOfItem,required this.oldPrice,required this.priceOfItem,required this.rate,required this.globalKey,});
  // المتغيرات العامة
  String TheChosen ='' ;
  late String TypeItem;
  static bool isSend = false;

  // الحقول النصية
   TextEditingController nameOfItem = TextEditingController();
   TextEditingController priceOfItem = TextEditingController();
   TextEditingController descriptionOfItem = TextEditingController();
   TextEditingController rate = TextEditingController();
   TextEditingController oldPrice = TextEditingController();

  // Firebase
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage firebaseStorage = FirebaseStorage.instance;

  // مفتاح للتحقق من صحة الحقول
   GlobalKey<FormState> globalKey = GlobalKey<FormState>();
  late final Uint8List uint8list;

  // القوائم
  List<String> TheWher = ['Phone charger', 'New Phone', 'Used phone'];
  List<String> text = ['شاحن هاتف', 'هاتف جديد', 'هاتف مستعمل'];
  List<Icon> icon = [
    Icon(Icons.phone_android),
    Icon(Icons.phone_android),
    Icon(Icons.phone_android),

  ];

  // الوظيفة التي تحفظ البيانات
  Future<void> saveData(String videoURL, BuildContext context) async {
    try {
      if(globalKey.currentState!.validate()){

        print(videoURL);
        print(descriptionOfItem.text);
        print(nameOfItem.text);
        print(TypeItem);

        print( GetAddManyImage.manyImageUrls);
        print(  ClassOfAddItem.chosenItem.toString());
        print('2323232323232323232323232');




        // إنشاء معرف فريد لكل عنصر باستخدام UUID
        final uid2 = Uuid().v4();

        // رفع البيانات إلى Firebase Storage
        Reference storage = firebaseStorage.ref(FirebaseX.StorgeApp).child(uid2);
        UploadTask uploadTask = storage.putData(uint8list);
        TaskSnapshot taskSnapshot = await uploadTask;

        // جلب رابط التنزيل للملف المرفوع
        String url = await taskSnapshot.ref.getDownloadURL();

        // التحقق من نوع العنصر المختار
        if (TypeItem == 'Item') {
          print(' // التحقق من نوع العنصر المختار');
          if (ClassOfAddItem.chosenItem!.isEmpty ||ClassOfAddItem.chosenItem =='') {
            isSend = false;
            update();
            // عرض مربع حوار إذا لم يتم اختيار النوع
            Get.defaultDialog(
              title: 'قم باختيار نوع الإضافة',
              cancel: const Text('إلغاء'),
            );
            return; // إيقاف العملية إذا لم يتم اختيار النوع
          }

          // تحويل السعر إلى عدد صحيح
          int priceOfItem1 = int.parse(priceOfItem.text);

          // إنشاء نموذج للعنصر وإرساله إلى Firebase
          ModelItem modelItem = ModelItem(
            uid: uid2,
            url: url,
            videoURL: videoURL,
            descriptionOfItem: descriptionOfItem.text,
            nameOfItem: nameOfItem.text,
            priceOfItem: priceOfItem1,
            isOfer: false,
            manyImages: GetAddManyImage.manyImageUrls ,
            appName: FirebaseX.appName,
            typeItem: ClassOfAddItem.chosenItem.toString(),
          );
          print(priceOfItem1);
          print(uid2);
          print(url);
          print("788787878787878787878787");

          // رفع البيانات إلى مجموعة Firestore
          await firestore.collection(TypeItem).doc(uid2).set(modelItem.toMap()).then((_) {
            update(); // تحديث الحالة
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => BottomBar(theIndex: 2)),
                  (route) => false,
            );
          });
        } else {
          // إذا كان نوع العنصر عرضًا (Offer)
          int oldPrice1 = int.parse(oldPrice.text);
          int priceOfItem1 = int.parse(priceOfItem.text);
          int rate1 = int.parse(rate.text);

          // إنشاء نموذج لعنصر العرض
          ModelOfferItem modelOfferItem = ModelOfferItem(
            appName: FirebaseX.appName,
            isOfer: true,
            priceOfItem: priceOfItem1,
            nameOfItem: nameOfItem.text,
            descriptionOfItem: descriptionOfItem.text,
            manyImages: GetAddManyImage.manyImageUrls,
            videoURL: videoURL,
            url: url,
            uid: uid2,
            rate: rate1,
            oldPrice: oldPrice1,
          );

          // رفع بيانات العرض إلى Firestore
          await firestore.collection(TypeItem).doc(uid2).set(modelOfferItem.toMap()).then((_) {
            update(); // تحديث الحالة
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => BottomBar(theIndex: 2)),
                  (route) => false,
            );
          });
        }

      }

    } catch (e) {
      // تسجيل الأخطاء باستخدام debugPrint
      debugPrint('خطأ أثناء حفظ البيانات: $e');
    }
  }

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    isSend = false;
    update();
  }
  @override
  void onClose() {
    // TODO: implement onClose
    super.onClose();
    isSend = false;
    update();
  }

}

