
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../Model/ModelTheChosen.dart';
import '../../XXX/XXXFirebase.dart';
import '../Get-Controllar/Get-BoxAddAndRemover.dart';


class BoxAddAndRemove extends StatelessWidget {
  BoxAddAndRemove({
    super.key,
    required this.uidItem,
    required this.Name,
    required this.price,
  });

  String uidItem;
  String price;
  String Name;
  final uuid = Uuid().v1();
  int number = 0;

  @override
  Widget build(BuildContext context) {
    double hi = MediaQuery.of(context).size.height;
    double wi = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
          width: double.infinity,
          decoration: BoxDecoration(

              borderRadius: BorderRadius.circular(15), color: Colors.black12),
          child: Column(
            children: [
              SizedBox(
                height: hi / 100,
              ),
              Center(
                  child: Text(
                    Name,
                    style: TextStyle(fontSize: wi / 35),
                  )),
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
                  child: Divider(
                    height: 5,
                  )),
              Container(
                decoration:
                BoxDecoration(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: GetBuilder<GetBoxAddAndRemove>(
                      init: GetBoxAddAndRemove(),
                      builder: (val) {
                        return Row(
                          children: [
                            SizedBox(
                              width: wi / 90,
                            ),

                            GestureDetector(
                              onTap: () {

                                  try {

                                    number++;
                                    if (number == 1) {
      ModelTheChosen modelTheChosen =ModelTheChosen(isOfer: false, number: number, uidOfDoc: uuid, uidItem: uidItem, uidUser: FirebaseAuth.instance.currentUser!.uid);

                                      FirebaseFirestore.instance.collection('the-chosen')
                                          .doc(FirebaseAuth.instance.currentUser!.uid).collection(FirebaseX.appName)
                                          .doc(uuid).set(modelTheChosen.toMap());
                                    }
                                    if (number > 1) {
        ModelTheChosen modelTheChosen =ModelTheChosen(isOfer: false, number: number, uidOfDoc: uuid, uidItem: uidItem, uidUser: FirebaseAuth.instance.currentUser!.uid);

                                      FirebaseFirestore.instance
                                          .collection('the-chosen')
                                          .doc(FirebaseAuth.instance.currentUser!.uid).collection(FirebaseX.appName)
                                          .doc(uuid)
                                          .set(modelTheChosen.toMap());
                                    }
                                    val.update();

                                  } catch (e) {
                                    print('111111111111122222221111111111111111');
                                    print(e);
                                    print('111111111111122222221111111111111111');
                                  }

                              },
                              child: Container(
                                  width: wi / 15,
                                  height: hi / 25,
                                  color: Colors.transparent,
                                  child: Icon(
                                    Icons.add,
                                    size: wi / 17,
                                  )),
                            ),
                            SizedBox(
                              width: wi / 70,
                            ),
                            // GetBuilder<GetHome>(init: GetHome(),builder: (val){
                            //   return
                            // }),
                            Text(
                              '$number',
                              style: TextStyle(fontSize: wi / 27),
                            ),
                            SizedBox(
                              width: wi / 70,
                            ),
                            GestureDetector(
                              child: Container(
                                  width: wi / 15,
                                  height: hi / 25,
                                  color: Colors.transparent,
                                  child: Icon(
                                    Icons.remove,
                                    size: wi / 17,
                                  )),
                              onTap: () {
                                try {
                                  if (number == 1) {
                                    FirebaseFirestore.instance
                                        .collection('the-chosen')
                                        .doc(FirebaseAuth.instance.currentUser!.uid).collection(FirebaseX.appName)
                                        .doc(uuid)
                                        .delete();
                                  }
                                  if (number > 0) {
                                    number--;
                                    ModelTheChosen modelTheChosen =ModelTheChosen(isOfer: false, number: number, uidOfDoc: uuid, uidItem: uidItem, uidUser: FirebaseAuth.instance.currentUser!.uid);

                                    FirebaseFirestore.instance
                                        .collection('the-chosen')
                                        .doc(FirebaseAuth.instance.currentUser!.uid).collection(FirebaseX.appName)
                                        .doc(uuid)
                                        .update(modelTheChosen.toMap());
                                  }

                                  val.update();
                                } catch (e) {
                                  print('111111111111122222221111111111111111');
                                  print(e);
                                  print('111111111111122222221111111111111111');
                                }

                              },
                            )
                          ],
                        );
                      }),
                ),
              ),
            ],
          )),
    );
  }
}