
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../XXX/XXXFirebase.dart';
import '../../../bottonBar/botonBar.dart';
import '../../../controler/local-notification-onroller.dart';
import '../../Orderofuser/OrderOfUser.dart';

class Getrequest extends GetxController{
  bool isloding2= false;


  Future<void> RequestAccept(String uidOfOrder)async{

    await FirebaseFirestore.instance.collection('order').doc(uidOfOrder).get(

    ).then((notification){
      if(notification.get('RequestAccept')) {
        Get.to(Orderofuser(uid: uidOfOrder,));

      }else{
        FirebaseFirestore.instance.collection(FirebaseX.collectionApp).doc(uidOfOrder).get().then((uid)async{
          localNotification.sendNotificationMessageToUser(uid.get('token'), FirebaseX.appName, 'تم قبول طلب الشراء يتم تجهيز الطلب', uidOfOrder, 'AcceptTheRequest', '');
          await FirebaseFirestore.instance.collection('order').doc(uidOfOrder).update({
            'RequestAccept': true
          });

          Get.to(Orderofuser(uid: uidOfOrder,));
        });
      }





  });
        }



  Future<void> RequestRejection(String uidOfOrder,double size,BuildContext context)async{
    showDialog<void>(barrierDismissible: true,context: context, builder: (BuildContext context){
      return AlertDialog(
        actions: [
            Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(onTap: ()async{
                  isloding2 = true;
                  update();
                  await FirebaseFirestore.instance.collection('order').doc(uidOfOrder).delete().then((val){
                    FirebaseFirestore.instance
                        .collection('order')
                        .doc(uidOfOrder).collection('TheOrder')
                        .get()
                        .then((QuerySnapshot querySnapshot) {
                      querySnapshot.docs.forEach((doc1) async{
                        await FirebaseFirestore.instance.collection('order').doc(uidOfOrder).collection('TheOrder').doc(doc1['uidOfDoc']).delete().then((val)async{

                            await  FirebaseFirestore.instance.collection(FirebaseX.collectionApp).doc(uidOfOrder).get().then((uid)async{
                              await  localNotification.sendNotificationMessageToUser(uid.get('token'), FirebaseX.appName, 'تم الغاء الطلب', uidOfOrder, 'RequestRejected', '');

                              Get.to(bottonBar(theIndex: 2,));
                            });

                        }

                       );

                      });
                    });
                  });




                },child: isloding2 == true ? CircularProgressIndicator() : Icon(Icons.done,color: Colors.green,size: size/15,)
                ),




                GestureDetector(onTap: (){
                  Navigator.pop(context,true);
                },child: Icon(Icons.close,color: Colors.red,size: size/17,)),
              ],
            ),
          )
        ],
        title: Text('انت متآكد من حذف الطلب',textAlign: TextAlign.center,),
        content: Text('لا يمكن التراجع اذا وافقت',textAlign: TextAlign.center),

      );});

  }
}