
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../XXX/XXXFirebase.dart';
import '../GetXController/GetAddAndRemove.dart';

class addAndRemoe2 extends StatelessWidget {
  addAndRemoe2({super.key,required this.uidItem,required this.uidOfDoc,required this.number,required this.isOfer});
  String uidOfDoc;
  String uidItem;
  int number;
  bool isOfer;


  @override
  Widget build(BuildContext context) {
    double hi = MediaQuery.of(context).size.height;
    double wi = MediaQuery.of(context).size.width;
    return GetBuilder<GetAddAndRemove>(init: GetAddAndRemove(),builder: (val){
      return        Padding(
        padding: EdgeInsets.symmetric(horizontal: 1),
        child: Row(
          children: [
            GestureDetector(
              onTap: ()async{

                try {
                  number++;

                  if (number == 1) {
                    FirebaseFirestore.instance.collection('the-chosen').doc(FirebaseAuth.instance.currentUser!.uid).collection(FirebaseX.appName).doc(uidOfDoc).set({
                      'uidUser': FirebaseAuth.instance.currentUser!.uid,
                      'uidItem': uidItem,
                      'uidOfDoc': uidOfDoc,
                      'number': number,
                      'isOfer' :isOfer
                    });
                  } if (number > 1) {
                    FirebaseFirestore.instance
                        .collection('the-chosen')
                        .doc(FirebaseAuth.instance.currentUser!.uid).collection(FirebaseX.appName)
                        .doc(uidOfDoc)
                        .set({
                      'uidUser': FirebaseAuth.instance.currentUser!.uid,
                      'uidItem': uidItem,
                      'uidOfDoc':uidOfDoc,
                      'number': number,
                      'isOfer' :isOfer

                    });
                  }
                  // val.total == val.total.toInt();
                  val.total=0;
                  val.number=0;
                  val.totalPriceOfItem=0;
                  val.price=0;
                  val.totalPriceOfofferItem=0;
                  val.totalPrice=0;
                  await Future.delayed(Duration(milliseconds: 100));

                  val.onInit();

                  val.update();





                } catch (e) {}


              },
              child: Container(decoration: BoxDecoration(
                    color: Colors.black12,
                    border: Border.all(color: Colors.black26),
                    borderRadius: BorderRadius.circular(16)
                ),height: hi/30,width: wi/16,child: Center(child: Icon(Icons.add,size: wi/22,)),
              ),
            ),
            SizedBox(width: wi/60,),
            Text('$number',style: TextStyle(fontSize: wi/20),),
            SizedBox(width:  wi/60,),


            GestureDetector(
              onTap: ()async{
                try {
                  if (number == 1) {
                    FirebaseFirestore.instance
                        .collection('the-chosen')
                        .doc(FirebaseAuth.instance.currentUser!.uid).collection(FirebaseX.appName)
                        .doc(uidOfDoc)
                        .delete();
                  }
                  if (number > 0) {
                    number--;
                    FirebaseFirestore.instance
                        .collection('the-chosen')
                        .doc(FirebaseAuth.instance.currentUser!.uid).collection(FirebaseX.appName)
                        .doc(uidOfDoc)
                        .update({
                      'uidUser': FirebaseAuth.instance.currentUser!.uid,
                      'uidItem': uidItem,
                      'uidOfDoc':uidOfDoc,
                      'number': number,
                      'isOfer':isOfer

                    });
                  }
                  val.total=0;
                  val.number=0;
                  val.totalPriceOfItem=0;
                  val.price=0;
                  val.totalPriceOfofferItem=0;
                  val.totalPrice=0;

                  await Future.delayed(Duration(milliseconds: 100));

                  val.onInit();

                  val.update();

                  val.update();
                } catch (e) {
                  print('111111111111122222221111111111111111');
                  print(e);
                  print('111111111111122222221111111111111111');
                }

              },
              child: Container(decoration: BoxDecoration(
                    color: Colors.black12,
                    border: Border.all(color: Colors.black26),
                    borderRadius: BorderRadius.circular(16)
                ),height: hi/30,width: wi/16,child: Center(child: Icon(Icons.remove,size:wi/22,)),
              ),
            ),
          ],
        ),
      );
    },

    );
  }
}
