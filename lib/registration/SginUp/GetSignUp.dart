
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../XXX/XXXFirebase.dart';
import '../../bottonBar/botonBar.dart';
import '../InfomationUser/informationUser.dart';
import '../signin/signinPage.dart';


class Getsignup extends GetxController{
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  // GlobalKey<FormState> globalKey = GlobalKey<FormState>();
  bool isLoding =false;
  Getsignup({required this.email,required this.password});


  Future<void> signInWithGoogle(BuildContext context) async {
    try{

        isLoding =true;
        update();

      List<String> scopes = <String>[
        'email',
        'https://www.googleapis.com/auth/contacts.readonly',
      ];
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication? googleAuth =
      await googleUser?.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      // Once signed in, return the UserCredential
      return await FirebaseAuth.instance.signInWithCredential(credential).then((value) {
        FirebaseFirestore.instance
            .collection(FirebaseX.collectionApp)
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .get()
            .then((DocumentSnapshot documentSnapshot) {
          if (documentSnapshot.exists) {

              isLoding =false;
              update();

              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=>bottonBar(theIndex: 0,)),(rute)=>false);
            print(documentSnapshot.data());

          }else{

              isLoding =false;
              update();

              Navigator.push(context, MaterialPageRoute(builder: (context)=>InformationUser(
              email: FirebaseAuth.instance.currentUser!.email.toString(),
              password: 'NO PASSWORD',
              passwordAndEmail: false,
            )));
          }
        });

      });

    }catch(e){
        isLoding =false;
        update();

    }

  }

  Future<void> SignUp(BuildContext context,GlobalKey<FormState> globalKey) async {
    if (globalKey.currentState!.validate()) {
      try {
        isLoding =true;
        update();


        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email.text,
          password: password.text,
        ).then((value)async{

          User? user1 = FirebaseAuth.instance.currentUser;

          await user1!.sendEmailVerification().then((value){
            Navigator.push(context, MaterialPageRoute(builder: (context)=>SignInPage(isFirstTime: true,)));
            isLoding =false;
            update();

          });
        });
      } on FirebaseAuthException catch (e) {
        if (e.code == 'weak-password') {
          return showDialog(context: context, builder: (context)=>AlertDialog(
            actions: [
              IconButton(onPressed: (){
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                isLoding =false;
                update();
              }, icon: Icon(Icons.close))
            ],
            title: Text('الباسورد ضعيف'),
            content: Text('يجب ان يكون اكثر من 6'),
          ));
          print('The password provided is too weak.');
        } else if (e.code == 'email-already-in-use') {
          return showDialog(context: context, builder: (context)=>AlertDialog(
            actions: [
              IconButton(onPressed: (){
                Navigator.of(context).pop();
                isLoding =false;
                update();
              }, icon: Icon(Icons.close))
            ],
            title: Text('الايمل موجود بالفعل'),
            content: Text('قم بتسجيل الدخول'),
          ));
          print('The account already exists for that email.');
        }
      } catch (e) {
        print(FirebaseAuth.instance.currentUser!.displayName);

        print(e);
        print('2222222222222222222222222222');

      }
    }


  }

}