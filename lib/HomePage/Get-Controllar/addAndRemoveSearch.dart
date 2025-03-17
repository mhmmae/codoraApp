
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../Model/ModelTheChosen.dart';
import '../../XXX/XXXFirebase.dart';

class GetaddAndRemoveSearch extends GetxController{
  int number = 0;
  final uuid =Uuid().v1();
  addItem(String uid,String uidItem) {
    try {
      number++;
      if (number == 1) {
        ModelTheChosen modelTheChosen =ModelTheChosen(isOfer: false, number: number, uidOfDoc: uid, uidItem: uidItem, uidUser: FirebaseAuth.instance.currentUser!.uid);
        FirebaseFirestore.instance.collection('the-chosen').doc(FirebaseAuth.instance.currentUser!.uid).collection(FirebaseX.appName).doc(uid).set(modelTheChosen.toMap());
      }
      if (number > 1) {
        ModelTheChosen modelTheChosen =ModelTheChosen(isOfer: false, number: number, uidOfDoc: uid, uidItem: uidItem, uidUser: FirebaseAuth.instance.currentUser!.uid);

        FirebaseFirestore.instance
            .collection('the-chosen')
            .doc(FirebaseAuth.instance.currentUser!.uid).collection(FirebaseX.appName)
            .doc(uid)
            .set(modelTheChosen.toMap());
      }

      update();
    } catch (e) {
      print('111111111111122222221111111111111111');
      print(e);
      print('111111111111122222221111111111111111');
    }
  }




//   ^^^^^^^^^^^^^^^---------------------^^^^^^^^^^^^^^^^^^^^^^^------------------^^^^^^^^^^^^
  //   ^^^^^^^^^^^^^^^---------------------^^^^^^^^^^^^^^^^^^^^^^^------------------^^^^^^^^^^^^
//   ^^^^^^^^^^^^^^^---------------------^^^^^^^^^^^^^^^^^^^^^^^------------------^^^^^^^^^^^^



  removeItem(String uid,String uidItem) {
    try {
      if (number == 1) {
        FirebaseFirestore.instance
            .collection('the-chosen')
            .doc(FirebaseAuth.instance.currentUser!.uid).collection(FirebaseX.appName)
            .doc(uid)
            .delete();
      }
      if (number > 0) {
        number--;
        ModelTheChosen modelTheChosen =ModelTheChosen(isOfer: false, number: number, uidOfDoc: uid, uidItem: uidItem, uidUser: FirebaseAuth.instance.currentUser!.uid);

        FirebaseFirestore.instance
            .collection('the-chosen')
            .doc(FirebaseAuth.instance.currentUser!.uid).collection(FirebaseX.appName)
            .doc(uid)
            .update(modelTheChosen.toMap());
      }

      update();
    } catch (e) {
      print('111111111111122222221111111111111111');
      print(e);
      print('111111111111122222221111111111111111');
    }
  }

}