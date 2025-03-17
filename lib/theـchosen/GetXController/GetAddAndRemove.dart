
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../XXX/XXXFirebase.dart';

class GetAddAndRemove extends GetxController{
  int number=0;
  int price =0;
  int total =0;
  int totalPriceOfItem =0;
  int totalPriceOfofferItem = 0;
  int totalPrice =0;
  int PriceOfItem=0;
  int PriceOfofferItem = 0;


  @override
  void onInit() async{

    FirebaseFirestore.instance
        .collection('the-chosen').doc(FirebaseAuth.instance.currentUser!.uid).collection(FirebaseX.appName)
        .get()
        .then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc1) async{
       await FirebaseFirestore.instance
            .collection('Item')
            .doc(doc1["uidItem"])
            .get()
            .then((DocumentSnapshot documentSnapshotItem) {




                if(documentSnapshotItem.exists){

                    PriceOfItem = documentSnapshotItem.get('priceOfItem') * doc1["number"];
                   totalPriceOfItem +=PriceOfItem;






                }















        });



      await  FirebaseFirestore.instance
            .collection('Itemoffer')
            .doc(doc1["uidItem"])
            .get()
            .then((DocumentSnapshot documentSnapshotofferItem) {

              if(documentSnapshotofferItem.exists){
                  PriceOfofferItem = documentSnapshotofferItem.get('priceOfItem') * doc1["number"];
                totalPriceOfofferItem += PriceOfofferItem;






              }






        });

       total = totalPriceOfofferItem +totalPriceOfItem;
       update();



















      });
    });

    // TODO: implement onInit
    super.onInit();
  }
  @override
  void dispose() {
     number=0;
     price =0;
     total =0;
     totalPriceOfItem =0;
    // TODO: implement dispose
    super.dispose();
  }



  // addItem2() {
  //
  //   try {
  //     number++;
  //
  //     if (number == 1) {
  //       FirebaseFirestore.instance.collection('the-chosen').doc(uidOfDoc).set({
  //         'uidUser': FirebaseAuth.instance.currentUser!.uid,
  //         'uidItem': uidItem,
  //         'uidOfDoc': uidOfDoc,
  //         'number': number
  //       });
  //     } if (number > 1) {
  //       FirebaseFirestore.instance
  //           .collection('the-chosen')
  //           .doc(uidOfDoc)
  //           .set({
  //         'uidUser': FirebaseAuth.instance.currentUser!.uid,
  //         'uidItem': uidItem,
  //         'uidOfDoc':uidOfDoc,
  //         'number': number
  //       });
  //     }
  //
  //     update();
  //
  //
  //
  //
  //   } catch (e) {}
  // }
}