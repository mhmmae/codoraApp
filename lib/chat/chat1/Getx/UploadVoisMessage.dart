

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../../../XXX/XXXFirebase.dart';
import '../../../controler/local-notification-onroller.dart';

class uplodeVoisMessage {

  String? audioPath;




  upLodeMessageVoisToFirebse(String uid,String filePath)async{

    try{

      if (filePath.isNotEmpty) {
        final uid1 = Uuid().v1();


        File file = File(filePath);
        if (file.existsSync()) {


          Reference storage =  FirebaseStorage.instance.ref('audio').child(uid1);
          UploadTask uploadTask = storage.putFile(File(filePath));
          TaskSnapshot snapshot = await uploadTask;
          audioPath = await snapshot.ref.getDownloadURL();





          await FirebaseFirestore.instance.collection('Chat')
              .doc(FirebaseAuth.instance.currentUser!.uid).collection('chat')
              .doc(uid).collection('messages').doc(uid1).set({
            'sender':FirebaseAuth.instance.currentUser!.uid,
            'resiveID':uid,
            'message':audioPath,
            'time':DateTime.now(),
            'uidMassege' : uid1,
            'type':'audio',
            'isRead' :false,


            // 'isRead' :false

          }).then((value) => FirebaseFirestore.instance.collection('Chat')
              .doc(FirebaseAuth.instance.currentUser!.uid).collection('chat')
              .doc(uid).set({
            'sender':uid,
            'resiveID':FirebaseAuth.instance.currentUser!.uid,
            'message':audioPath,
            'time':DateTime.now(),
            'type':'audio',
            'isRead' :false,


            // 'isRead' :false



          }));





          await FirebaseFirestore.instance.collection('Chat')
              .doc(uid).collection('chat')
              .doc(FirebaseAuth.instance.currentUser!.uid).collection('messages').doc(uid1).set({
            'sender':FirebaseAuth.instance.currentUser!.uid,
            'resiveID':uid,
            'message':audioPath,
            'time':DateTime.now(),
            'uidMassege' : uid1,
            'type':'audio',



          }).then((value) => FirebaseFirestore.instance.collection('Chat')
              .doc(uid).collection('chat')
              .doc(FirebaseAuth.instance.currentUser!.uid).set({
            'sender':FirebaseAuth.instance.currentUser!.uid,
            'resiveID':uid,
            'message':audioPath,
            'time':DateTime.now(),
            'type':'audio',




          })).then((message)async{
            FirebaseFirestore.instance.collection(FirebaseX.collectionApp).doc(FirebaseAuth.instance.currentUser!.uid).get().then((name)async{
              FirebaseFirestore.instance.collection(FirebaseX.collectionApp).doc(uid).get().then((uid)async{
                await localNotification.sendNotificationMessageToUser(uid.get('token'), name.get('name'), 'رسالة صوتية', uid.toString(), 'audio', '');
              } );
            } );
           
          });
          
        } else {
          print('File does not exist at the specified path: $filePath');
        }
      }








    }catch(e){
      print(e);

    }

  }

}