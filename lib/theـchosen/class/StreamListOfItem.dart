import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../XXX/XXXFirebase.dart';
import '../GetXController/GetAddAndRemove.dart';
import 'BosAddAndRemove.dart';

class Streamlistofitem extends StatelessWidget {
  Streamlistofitem({super.key});

  final Stream<QuerySnapshot> cardItem = FirebaseFirestore.instance
      .collection('the-chosen')
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .collection(FirebaseX.appName)
  // .where('uidUser', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
      .snapshots();


  ItemUid(String ItemUid2) {
    return FirebaseFirestore.instance
        .collection('Item')
        .doc(ItemUid2)
        .get();
  }


  ItemOferUid(String ItemUid2) {
    return FirebaseFirestore.instance
        .collection('Itemoffer')
        .doc(ItemUid2)
        .get();
  }


  DeleteItem(String uidDoc) {
    return FirebaseFirestore.instance.collection('the-chosen').doc(
        FirebaseAuth.instance.currentUser!.uid)
        .collection(FirebaseX.appName)
        .doc(uidDoc)
        .delete();
  }


  @override
  Widget build(BuildContext context) {
    double hi = MediaQuery
        .of(context)
        .size
        .height;
    double wi = MediaQuery
        .of(context)
        .size
        .width;
    return SizedBox(


      height: hi / 2,
      child: StreamBuilder<QuerySnapshot>(
          stream: cardItem,
          builder: (BuildContext context,
              AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return Text('Something went wrong');
            }

            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return Text('loading');
            }

            return snapshot.data!.docs.isNotEmpty
                ? ListView(
              shrinkWrap: true,
              primary: true,

              children: snapshot.data!.docs
                  .map((DocumentSnapshot document) {
                Map<String, dynamic> data3 = document
                    .data()! as Map<String, dynamic>;
                return FutureBuilder<DocumentSnapshot>(
                  future: data3['isOfer'] == false
                      ? ItemUid(data3['uidItem'])
                      : ItemOferUid(data3['uidItem']),
                  builder: (BuildContext context,
                      AsyncSnapshot<DocumentSnapshot>
                      snapshot) {
                    if (snapshot.hasError) {
                      return Text("Something went wrong");
                    }

                    if (snapshot.hasData &&
                        !snapshot.data!.exists) {
                      return Text(
                          "Document does not exist");
                    }

                    if (snapshot.connectionState ==
                        ConnectionState.done) {
                      Map<String, dynamic> data =
                      snapshot.data!.data()
                      as Map<String, dynamic>;


                      return
                        Padding(padding: EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                          child: Container(
                            width: double.infinity,
                            height: hi / 8,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.black38)
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    SizedBox(width: wi / 46,),
                                    Padding(
                                      padding: const EdgeInsets.all(1),
                                      child: Container(
                                        height: hi / 10.6, width: wi / 5,
                                        decoration: BoxDecoration(
                                            image: DecorationImage(
                                                fit: BoxFit.cover,
                                                image: NetworkImage(data['url'])
                                            )
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: wi / 26,),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment
                                            .spaceBetween,
                                        children: [
                                          Text(data['nameOfItem'],
                                            style: TextStyle(
                                                fontSize: wi / 30),),
                                          Text(data['priceOfItem'].toString(),
                                            style: TextStyle(
                                                fontSize: wi / 35),)
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment
                                        .spaceBetween,
                                    children: [

                                      GetBuilder<GetAddAndRemove>(init: GetAddAndRemove(),
                                          builder: (logic) {
                                            return GestureDetector(
                                                onTap: () async{
                                                  DeleteItem(data3['uidOfDoc']
                                                      .toString());
                                                  logic.total=0;
                                                  logic.number=0;
                                                  logic.totalPriceOfItem=0;
                                                  logic.price=0;
                                                  logic.totalPriceOfofferItem=0;
                                                  logic.totalPrice=0;
                                                  await Future.delayed(Duration(milliseconds: 100));

                                                  logic.onInit();
                                                  logic.update();
                                                },
                                                child: Icon(
                                                  Icons.delete_forever,
                                                  color: Colors.red,));
                                          }),
                                      Row(
                                        children: [
                                          addAndRemoe2(number: data3['number'],
                                            uidItem: data3['uidItem'],
                                            uidOfDoc: data3['uidOfDoc'],
                                            isOfer: data3['isOfer'],),
                                          SizedBox(width: wi / 15,)
                                        ],
                                      )
                                    ],
                                  ),
                                ),


                              ],
                            ),
                          ),);
                    }

                    return Text("loading");
                  },
                );
              }).toList(),
            )
                : Center(child: Text('لا يوجد منتجات '),);
          }),

    );
  }
}
