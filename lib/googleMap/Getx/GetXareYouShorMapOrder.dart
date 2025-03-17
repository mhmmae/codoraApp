
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

class Getxareyoushormaporder extends GetxController{
  double longitude;
  double latitude;
  String tokenUser;

  Getxareyoushormaporder({required this.latitude,required this.longitude,required this.tokenUser});
  bool isloding =false;
  String generateRandomNumber() {
    Random random = Random();
    List<int> digits = List.generate(10, (index) => index);
    digits.shuffle(random);
    String randomNumber = digits.take(10).join();
    return randomNumber;
  }


  areYouShor(double CancellingOrder, double SendTheRequest, double sure,
      double backingDown, double SizedBox1, BuildContext context) async {
    try {
      return showDialog<void>(
          barrierDismissible: true, context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              actions: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                          onTap: () {
                            Navigator.pushAndRemoveUntil( context,
                                MaterialPageRoute(
                                    builder: (context) => bottonBar(theIndex: 1,)), (rule)=>false);
                          },
                          child: Text(
                            'الغاء الطلب',
                            style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: CancellingOrder,
                                fontWeight: FontWeight.w600),
                          )),
                      SizedBox(
                        width: SizedBox1,
                      ),
                      GetBuilder<GetAddAndRemove>(init: GetAddAndRemove(),builder: (val){
                        return GestureDetector(
                            onTap: () async {


                              try {

                                update();
                                isloding = true;
                                String randomNumber = generateRandomNumber();




                                await FirebaseFirestore.instance
                                    .collection('the-chosen').doc(FirebaseAuth.instance.currentUser!.uid).collection(FirebaseX.appName)
                                    .get()
                                    .then((QuerySnapshot querySnapshot) {
                                  querySnapshot.docs.forEach((doc) async {



                                    ModleTheOrderList modleTheOrderList = ModleTheOrderList(uidUser: doc['uidUser'],
                                        uidItem: doc['uidItem'], uidOfDoc: doc['uidOfDoc'], number: doc['number'], isOfer: doc['isOfer'],appName: FirebaseX.appName);

                                    await FirebaseFirestore.instance
                                        .collection('order')
                                        .doc(FirebaseAuth
                                        .instance.currentUser!.uid)
                                        .collection('TheOrder')
                                        .doc(doc['uidOfDoc'])


                                        .set(modleTheOrderList.toMap()).then((value) async {


                                      ModleOrder modleOrder =ModleOrder(uidUser:  FirebaseAuth.instance.currentUser!.uid, appName: FirebaseX.appName, longitude: longitude, latitude: latitude,
                                        Delivery: false, doneDelivery: false, RequestAccept: false,timeOrder:DateTime.now(),nmberOfOrder: randomNumber.toString(),totalPriceOfOrder: val.total );


                                      await FirebaseFirestore.instance
                                          .collection('order')
                                          .doc(FirebaseAuth
                                          .instance.currentUser!.uid)
                                      // .collection('location')
                                      // .doc(FirebaseAuth.instance.currentUser!.uid)
                                          .set(modleOrder.toMap()
                                        //     {
                                        //   'longitude': longitude,
                                        //   'latitude': latitude,
                                        //   'RequestAccept': false,
                                        //   'Delivery': false,
                                        //   'doneDelivery': false,
                                        //   // 'orderUid': uidNew,
                                        //   'uidUser': FirebaseAuth
                                        //       .instance.currentUser!.uid,
                                        //   'timeOrder': DateTime.now(),
                                        //   'appName': 'oscare'
                                        // }
                                      );
                                    }).then((value) async {
                                      await FirebaseFirestore.instance
                                          .collection('the-chosen').doc(FirebaseAuth.instance.currentUser!.uid).collection(FirebaseX.appName)
                                          .doc(doc['uidOfDoc'])
                                          .delete().then((vala){
                                        FirebaseFirestore.instance.collection(FirebaseX.collectionApp).doc(FirebaseAuth.instance.currentUser!.uid).get().then((send)async{
                                          
                                          await FirebaseFirestore.instance.collection(FirebaseX.collectionApp).doc(FirebaseX.UIDOfWnerApp).get().then((token1)async{

                                            await  localNotification.sendNotificationMessageToUser(token1.get('token'), send.get('name'), 'لديك طلب شراء',
                                                FirebaseAuth.instance.currentUser!.uid, 'order',send.get('url')
                                            );
                                          });

                                          


                                        });

                                      });

                                      isloding = false;
                                      update();

                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  bottonBar(
                                                    theIndex: 0,
                                                  )));
                                    });
                                  });
                                });
                              } catch (e) {}
                            },
                            child: Text(
                              'ارسال الطلب',
                              style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: SendTheRequest,
                                  fontWeight: FontWeight.w700),
                            ));
                      },),

                    ],
                  ),
                )
              ],
              title: isloding
                  ? Center(child: CircularProgressIndicator())
                  : Text(
                'هل انت متآكد من ارسال الطلب',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: sure),
              ),
              content: Text(
                'لا يمكن التراجع عن ارسال الطلب   ',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: backingDown, color: Colors.green),
              ),
            );
          });
    } catch (e) {}
  }
}