
import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../Model/ModelUser.dart';
import '../../../XXX/XXXFirebase.dart';
import '../../../bottonBar/botonBar.dart';

class Getcodephonenumber extends GetxController{

  TextEditingController c1 = TextEditingController();
  TextEditingController c2 = TextEditingController();
  TextEditingController c3 = TextEditingController();
  TextEditingController c4 = TextEditingController();
  TextEditingController c5 = TextEditingController();
  TextEditingController c6 = TextEditingController();
  String phneNumber;
  bool pssworAndEmail;
  Uint8List imageUser;
  String Name;
  String Email;
  String password;



  Getcodephonenumber({required this.c1,required this.c2,required this.c3,required this.c4,
  required this.c5,required this.c6,required this.phneNumber,required this.pssworAndEmail,required this.imageUser,
  required this.Name,required this.password,required this.Email});

  bool correct1 =true;

  int connter =100;
  late Timer timer1;

  String? verifidCodeSent;

  bool isLoding =false;


  void startTimer(){
    timer1= Timer.periodic(const Duration(seconds: 1), (timer) {

        if(connter>0){
          connter--;
        }else{
          timer.cancel();
        }
        update();

    });
  }

  void phoneAuthCode() async{

    try{
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phneNumber,
        timeout: const Duration(seconds: 90),
        verificationCompleted: (PhoneAuthCredential credential) {
          print('111111111111111111111111111111111');
          print('111111111111111111111111111111111');
          print('111111111111111111111111111111111');

        },
        verificationFailed: (FirebaseAuthException e) {


          print('22222222222222222222222222222222222');
          print(e);
          print('22222222222222222222222222222222222');
          print('22222222222222222222222222222222222');



        },
        codeSent: (String verificationId, int? resendToken) async{

          verifidCodeSent = verificationId;
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          verifidCodeSent = verificationId;
        },
      );
    }catch(e){

        correct1 =false;
        update();
    }

  }

  void sentCode(BuildContext context)async{
    try{
        isLoding=true;
        update();
      String smsCode = c1.text + c2.text + c3.text + c4.text + c5.text + c6.text;
      print(smsCode);

      PhoneAuthCredential credential = PhoneAuthProvider
          .credential(verificationId: verifidCodeSent!, smsCode: smsCode);
      if(smsCode == credential.smsCode || smsCode != credential.smsCode){

        // await FirebaseAuth.instance.signInWithCredential(credential).then((value)async{

        if(pssworAndEmail = true){

          //
          // await FirebaseAuth.instance.signInWithEmailAndPassword(
          //      email: widget.Email, password: widget.password).then((value) async{

          Reference stprge=   FirebaseStorage.instance.ref(FirebaseX.StorgeApp).child(const Uuid().v1());
          UploadTask upload =  stprge.putData(imageUser);
          TaskSnapshot task = await upload;
          String url22 = await task.ref.getDownloadURL();
          if(Platform.isIOS){
            await  FirebaseMessaging.instance.getAPNSToken().then((token)async{
              ModelUser modelUser =ModelUser(url: url22, uid: FirebaseAuth.instance.currentUser!.uid,
                  token: token.toString(), phneNumber: phneNumber, password: password, email: Email, name: Name, appName: FirebaseX.appName);

              await FirebaseFirestore.instance.collection(FirebaseX.collectionApp).doc(FirebaseAuth.instance.currentUser!.uid).set(modelUser.toMap()
              //     {
              //   'url':url22 ,
              //   'phneNumber': phneNumber ,
              //   'name' : Name ,
              //   'password': password ,
              //   'email' : Email ,
              //   'uid':FirebaseAuth.instance.currentUser!.uid,
              //   'token':token.toString()
              //
              //
              //
              //
              //
              //
              // }
              ).then((value)async {


                Navigator.push(
                    context, MaterialPageRoute(builder: (context) => bottonBar(theIndex: 0,)));


              });


            });
          }else{
            await  FirebaseMessaging.instance.getToken().then((token)async{
              ModelUser modelUser =ModelUser(url: url22, uid: FirebaseAuth.instance.currentUser!.uid,
                  token: token.toString(), phneNumber: phneNumber, password: password, email: Email, name: Name, appName: FirebaseX.appName);

              await FirebaseFirestore.instance.collection(FirebaseX.collectionApp).doc(FirebaseAuth.instance.currentUser!.uid).set(modelUser.toMap()
              //     {
              //   'url':url22 ,
              //   'phneNumber': phneNumber ,
              //   'name' : Name ,
              //   'password': password ,
              //   'email' : Email ,
              //   'uid':FirebaseAuth.instance.currentUser!.uid,
              //   'token':token.toString()
              //
              //
              //
              //
              //
              //
              // }
              ).then((value)async {


                Navigator.push(
                    context, MaterialPageRoute(builder: (context) => bottonBar(theIndex: 0,)));


              });


            });
          }

          // await  FirebaseMessaging.instance.getToken().then((token)async{
          //   await FirebaseFirestore.instance.collection('user').doc(FirebaseAuth.instance.currentUser!.uid).set({
          //     'url':url22 ,
          //     'phneNumber': widget.phneNumber ,
          //     'name' : widget.Name ,
          //     'password': widget.password ,
          //     'email' : widget.Email ,
          //     'uid':FirebaseAuth.instance.currentUser!.uid,
          //     'token':token.toString()
          //
          //
          //
          //
          //
          //
          //   }).then((value)async {
          //
          //
          //     Navigator.push(
          //         context, MaterialPageRoute(builder: (context) =>const bottonBar()));
          //
          //
          //   });
          //
          //
          // });



          // });



        }else{
          print('//////////////////////q//////q///////q////q///q/////q///');


          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) =>  bottonBar()),(rute)=>false);


        }





        // });
      }



    }on FirebaseAuthException catch (e){
      if(e.code == 'invalid-verification-code'){
          correct1 =false;
          isLoding =false;
          update();
      }
    }
    catch(e){
      print('3333333333333333333333333333333333');
      print(e);

      print('3333333333333333333333333333333333');

    }
  }
  @override
  void onInit() {
    startTimer();
    phoneAuthCode();
    // TODO: implement onInit
    super.onInit();
  }
  @override
  void dispose() {
    c1.dispose();
    c2.dispose();
    c3.dispose();
    c4.dispose();
    c5.dispose();
    c6.dispose();
    timer1.cancel();
    // TODO: implement dispose
    super.dispose();
  }




}