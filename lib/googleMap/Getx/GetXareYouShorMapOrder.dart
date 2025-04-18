//
// import 'dart:math';
//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// import '../../Model/ModelOrder.dart';
// import '../../Model/ModelTheOrderList.dart';
// import '../../XXX/XXXFirebase.dart';
// import '../../bottonBar/botonBar.dart';
// import '../../controler/local-notification-onroller.dart';
// import '../../theـchosen/GetXController/GetAddAndRemove.dart';
//
// class Getxareyoushormaporder extends GetxController{
//   double longitude;
//   double latitude;
//   String tokenUser;
//
//   Getxareyoushormaporder({required this.latitude,required this.longitude,required this.tokenUser});
//   bool isloding =false;
//   String generateRandomNumber() {
//     Random random = Random();
//     List<int> digits = List.generate(10, (index) => index);
//     digits.shuffle(random);
//     String randomNumber = digits.take(10).join();
//     return randomNumber;
//   }
//
//
//   areYouShor(double CancellingOrder, double SendTheRequest, double sure,
//       double backingDown, double SizedBox1, BuildContext context) async {
//     try {
//       return showDialog<void>(
//           barrierDismissible: true, context: context,
//           builder: (BuildContext context) {
//             return AlertDialog(
//               actions: [
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 8),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       GestureDetector(
//                           onTap: () {
//                             Navigator.pushAndRemoveUntil( context,
//                                 MaterialPageRoute(
//                                     builder: (context) => BottomBar(theIndex: 1,)), (rule)=>false);
//                           },
//                           child: Text(
//                             'الغاء الطلب',
//                             style: TextStyle(
//                                 color: Colors.redAccent,
//                                 fontSize: CancellingOrder,
//                                 fontWeight: FontWeight.w600),
//                           )),
//                       SizedBox(
//                         width: SizedBox1,
//                       ),
//                       GetBuilder<GetAddAndRemove>(init: GetAddAndRemove(),builder: (val){
//                         return GestureDetector(
//                             onTap: () async {
//
//
//                               try {
//
//                                 update();
//                                 isloding = true;
//                                 String randomNumber = generateRandomNumber();
//
//
//
//
//                                 await FirebaseFirestore.instance
//                                     .collection('the-chosen').doc(FirebaseAuth.instance.currentUser!.uid).collection(FirebaseX.appName)
//                                     .get()
//                                     .then((QuerySnapshot querySnapshot) {
//                                   querySnapshot.docs.forEach((doc) async {
//
//
//
//                                     ModleTheOrderList modleTheOrderList = ModleTheOrderList(uidUser: doc['uidUser'],
//                                         uidItem: doc['uidItem'], uidOfDoc: doc['uidOfDoc'], number: doc['number'], isOfer: doc['isOfer'],appName: FirebaseX.appName);
//
//                                     await FirebaseFirestore.instance
//                                         .collection('order')
//                                         .doc(FirebaseAuth
//                                         .instance.currentUser!.uid)
//                                         .collection('TheOrder')
//                                         .doc(doc['uidOfDoc'])
//
//
//                                         .set(modleTheOrderList.toMap()).then((value) async {
//
//
//                                       ModleOrder modleOrder =ModleOrder(uidUser:  FirebaseAuth.instance.currentUser!.uid, appName: FirebaseX.appName, longitude: longitude, latitude: latitude,
//                                         Delivery: false, doneDelivery: false, RequestAccept: false,timeOrder:DateTime.now(),nmberOfOrder: randomNumber.toString(),totalPriceOfOrder: val.total.value );
//
//
//                                       await FirebaseFirestore.instance
//                                           .collection('order')
//                                           .doc(FirebaseAuth
//                                           .instance.currentUser!.uid)
//                                       // .collection('location')
//                                       // .doc(FirebaseAuth.instance.currentUser!.uid)
//                                           .set(modleOrder.toMap()
//                                         //     {
//                                         //   'longitude': longitude,
//                                         //   'latitude': latitude,
//                                         //   'RequestAccept': false,
//                                         //   'Delivery': false,
//                                         //   'doneDelivery': false,
//                                         //   // 'orderUid': uidNew,
//                                         //   'uidUser': FirebaseAuth
//                                         //       .instance.currentUser!.uid,
//                                         //   'timeOrder': DateTime.now(),
//                                         //   'appName': 'oscare'
//                                         // }
//                                       );
//                                     }).then((value) async {
//                                       await FirebaseFirestore.instance
//                                           .collection('the-chosen').doc(FirebaseAuth.instance.currentUser!.uid).collection(FirebaseX.appName)
//                                           .doc(doc['uidOfDoc'])
//                                           .delete().then((vala){
//                                         FirebaseFirestore.instance.collection(FirebaseX.collectionApp).doc(FirebaseAuth.instance.currentUser!.uid).get().then((send)async{
//
//                                           await FirebaseFirestore.instance.collection(FirebaseX.collectionApp).doc(FirebaseX.UIDOfWnerApp).get().then((token1)async{
//
//                                             await  localNotification.sendNotificationMessageToUser(token1.get('token'), send.get('name'), 'لديك طلب شراء',
//                                                 FirebaseAuth.instance.currentUser!.uid, 'order',send.get('url')
//                                             );
//                                           });
//
//
//
//
//                                         });
//
//                                       });
//
//                                       isloding = false;
//                                       update();
//
//                                       Navigator.push(
//                                           context,
//                                           MaterialPageRoute(
//                                               builder: (context) =>
//                                                   BottomBar(
//                                                     theIndex: 0,
//                                                   )));
//                                     });
//                                   });
//                                 });
//                               } catch (e) {}
//                             },
//                             child: Text(
//                               'ارسال الطلب',
//                               style: TextStyle(
//                                   color: Colors.blueAccent,
//                                   fontSize: SendTheRequest,
//                                   fontWeight: FontWeight.w700),
//                             ));
//                       },),
//
//                     ],
//                   ),
//                 )
//               ],
//               title: isloding
//                   ? Center(child: CircularProgressIndicator())
//                   : Text(
//                 'هل انت متآكد من ارسال الطلب',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: sure),
//               ),
//               content: Text(
//                 'لا يمكن التراجع عن ارسال الطلب   ',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: backingDown, color: Colors.green),
//               ),
//             );
//           });
//     } catch (e) {}
//   }
// }


import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../Model/ModelOrder.dart';
import '../../Model/ModelTheOrderList.dart';
import '../../XXX/XXXFirebase.dart';
import '../../bottonBar/botonBar.dart';
import '../../controler/local-notification-onroller.dart';
import '../../theـchosen/GetXController/GetAddAndRemove.dart';

class GetxAreYouSureMapOrder extends GetxController {
  // المتغيرات الأساسية
  double longitude; // خط الطول
  double latitude; // خط العرض
  String tokenUser; // رمز المستخدم
  bool isLoading = false; // حالة التحميل

  GetxAreYouSureMapOrder({
    required this.latitude,
    required this.longitude,
    required this.tokenUser,
  });

  /// توليد رقم عشوائي
  String generateRandomNumber() {
    Random random = Random();
    List<int> digits = List.generate(10, (index) => index);
    digits.shuffle(random);
    String randomNumber = digits.take(10).join();
    return randomNumber;
  }

  /// عرض نافذة تأكيد إرسال الطلب
  Future<void> showConfirmationDialog(double cancelFontSize,
      double sendFontSize,
      double titleFontSize,
      double contentFontSize,
      double spacing,
      BuildContext context,) async {
    try {
      return showDialog<void>(
        barrierDismissible: false, // منع الإغلاق بالنقر خارج النافذة
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: isLoading
                ? Column(
              children: [
                const CircularProgressIndicator(
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 20),
                Text(
                  'جاري إرسال الطلب...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    color: Colors.blueGrey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
                : Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 32,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'هل انت متأكد من إرسال الطلب؟',
                    style: TextStyle(
                      fontSize: titleFontSize,
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            content: Text(
              'لا يمكن التراجع عن إرسال الطلب بعد تأكيده.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: contentFontSize,
                color: Colors.grey,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // زر إلغاء الطلب
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context); // إغلاق النافذة
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'إلغاء الطلب',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: cancelFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // زر إرسال الطلب
                  GetBuilder<GetAddAndRemove>(init: GetAddAndRemove(),builder: (logic) {
                          return  GestureDetector(
                            onTap: () async {
                              await _sendOrder(logic, context, sendFontSize);// بدء التحميل




                              Navigator.pop(context); // إغلاق النافذة
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تم إرسال الطلب بنجاح!'),
                                  duration: Duration(seconds: 2),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                            child:  isLoading == true ? CircularProgressIndicator():  Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 20,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'إرسال الطلب',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: sendFontSize,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        })

                  ],
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print("خطأ أثناء عرض النافذة: $e");
    }
  }

  /// إرسال الطلب إلى Firebase
  Future<void> _sendOrder(GetAddAndRemove val, BuildContext context,
      double sendFontSize) async {
    try {
      isLoading = true; // بدء التحميل
      update();
      await Future.delayed(
          const Duration(seconds: 3)); // محاكاة الإرسال

      String randomNumber = generateRandomNumber(); // توليد رقم الطلب

      // جلب البيانات من المجموعة "the-chosen"
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('the-chosen')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection(FirebaseX.appName)
          .get();

      for (var doc in querySnapshot.docs) {
        // إنشاء نموذج الطلب الفردي
        ModleTheOrderList modleTheOrderList = ModleTheOrderList(
          uidUser: doc['uidUser'],
          uidItem: doc['uidItem'],
          uidOfDoc: doc['uidOfDoc'],
          number: doc['number'],
          isOfer: doc['isOfer'],
          appName: FirebaseX.appName,
        );

        // تخزين الطلب في المجموعة "order"
        await FirebaseFirestore.instance
            .collection('order')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection('TheOrder')
            .doc(doc['uidOfDoc'])
            .set(modleTheOrderList.toMap());

        // إنشاء النموذج الرئيسي للطلب
        ModleOrder modleOrder = ModleOrder(
          uidUser: FirebaseAuth.instance.currentUser!.uid,
          appName: FirebaseX.appName,
          longitude: longitude,
          latitude: latitude,
          Delivery: false,
          doneDelivery: false,
          RequestAccept: false,
          timeOrder: DateTime.now(),
          nmberOfOrder: randomNumber,
          totalPriceOfOrder: val.total.value,
        );

        // تخزين النموذج الرئيسي في "order"
        await FirebaseFirestore.instance
            .collection('order')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .set(modleOrder.toMap());

        // حذف المستند من "the-chosen"
        await FirebaseFirestore.instance
            .collection('the-chosen')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection(FirebaseX.appName)
            .doc(doc['uidOfDoc'])
            .delete();

        // إرسال الإشعارات
        await _sendNotification(doc);
      }

      isLoading = false; // انتهاء التحميل
      update();

      // الانتقال إلى الشاشة الرئيسية
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BottomBar(theIndex: 0),
        ),
      );

    } catch (e) {
      print("خطأ أثناء إرسال الطلب: $e");
      isLoading = false;
      update();
    }
  }

  /// إرسال الإشعارات
  Future<void> _sendNotification(QueryDocumentSnapshot doc) async {
    try {
      // جلب بيانات المستخدم والإشعارات
      DocumentSnapshot send = await FirebaseFirestore.instance
          .collection(FirebaseX.collectionApp)
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();

      DocumentSnapshot token1 = await FirebaseFirestore.instance
          .collection(FirebaseX.collectionApp)
          .doc(FirebaseX.UIDOfWnerApp)
          .get();

      await LocalNotification.sendNotificationToUser(
        token: token1.get('token'),
        title: send.get('name'),
        body: 'لديك طلب شراء',
        uid: FirebaseAuth.instance.currentUser!.uid,
        type: 'order',
        image: send.get('url'),




      );
    } catch (e) {
      print("خطأ أثناء إرسال الإشعار: $e");
    }
  }
}
