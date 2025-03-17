
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
// import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../XXX/XXXFirebase.dart';
import '../../../bottonBar/botonBar.dart';
import '../../InfomationUser/informationUser.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';


class Getsignin extends GetxController{
  bool isLosing =false;
 bool isFirstTime ;
  final FirebaseAuth auth = FirebaseAuth.instance;

  TextEditingController  Email =TextEditingController();
  TextEditingController Password =TextEditingController();

  Getsignin({required this.isFirstTime,required this.Email,required this.Password});


  Future<void> signInWithGoogle(BuildContext context) async {
    try{



        isLosing =true;
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
      return  FirebaseAuth.instance.signInWithCredential(credential).then((value) {
        FirebaseFirestore.instance
            .collection(FirebaseX.collectionApp)

            .doc(FirebaseAuth.instance.currentUser!.uid)
            .get()
            .then((DocumentSnapshot documentSnapshot) async{
          if (documentSnapshot.exists) {

              isLosing =false;
            update();
            await Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=> bottonBar(theIndex: 0,)), (rute)=>false);


          }else {

              isLosing =false;
            update();
            await Get.to(InformationUser(
              email: FirebaseAuth.instance.currentUser!.email.toString(),
              password: 'NO PASSWORD',
              passwordAndEmail: false,
            ));
          }
        });

      });

    }on FirebaseAuthException catch (e) {
      // معالجة الأخطاء
      switch (e.code) {
        case 'account-exists-with-different-credential':
          print('The account already exists with a different credential.');
          break;
        case 'invalid-credential':
          print('Error occurred while accessing credentials. Try again.');
          break;
        case 'operation-not-allowed':
          print('Operation not allowed. Please enable Google sign-in in the Firebase console.');
          break;
        case 'user-disabled':
          print('The user has been disabled.');
          break;
        case 'user-not-found':
          print('No user found for that email.');
          break;
        case 'wrong-password':
          print('Wrong password provided.');
          break;
        default:
          print('An undefined Error happened.');
      }
    }catch(e){
      print('7777777777777777777777777777777777777777777777777734');
      print(e);
      print('77777777777777777777777777777777777777777777777777');


      isLosing =false;
     update();

    }

  }










  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

  // التسجيل لنظام android
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\




  Future<UserCredential?> signInWithFacebookForandroid(BuildContext context) async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(permissions: ['public_profile', 'email']);
      if (result.status == LoginStatus.success && result.accessToken != null) {
        // Create a credential from the access token
        final OAuthCredential credential = FacebookAuthProvider.credential(result.accessToken!.tokenString);
        // Once signed in, return the UserCredential
        final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

        final documentSnapshot = await FirebaseFirestore.instance
            .collection(FirebaseX.collectionApp)
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .get();

        if (documentSnapshot.exists) {
          isLosing = false;
          update();
          await Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => bottonBar(theIndex: 0,)),
                  (route) => false
          );
        } else {
          isLosing = false;
          update();
          await Get.to(InformationUser(
            email: FirebaseAuth.instance.currentUser!.email.toString(),
            password: 'NO PASSWORD',
            passwordAndEmail: false,
          ));
        }

        return userCredential;
      }
    } on FirebaseAuthException catch (e) {
      // معالجة الأخطاء
      switch (e.code) {
        case 'account-exists-with-different-credential':
          print('An account already exists with the same email address but different sign-in credentials.');
          break;
        case 'invalid-credential':
          print('The credential is invalid or expired.');
          break;
        case 'operation-not-allowed':
          print('This type of account is not enabled.');
          break;
        case 'user-disabled':
          print('The user account has been disabled.');
          break;
        case 'user-not-found':
          print('No user found for the provided email.');
          break;
        case 'wrong-password':
          print('The password is invalid for the provided email.');
          break;
        default:
          print('An unknown error occurred.');
      }
    } catch (e) {
      print('An unknown error occurred: $e');
    }

    return null;
  }

  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

  // التسجيل لنظام الios
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

  String generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Returns the sha256 hash of [input] in hex notation.
  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<UserCredential?> signInWithFacebookForios(BuildContext context) async {
    try{


      final rawNonce = generateNonce();
      final nonce = sha256ofString(rawNonce);
      // Trigger the sign-in flow
      final LoginResult loginResult = await FacebookAuth.instance
          .login(
        loginTracking: LoginTracking.limited,
        nonce: nonce,
      )
          .catchError((onError) {
        if (kDebugMode) {
          //print(onError);
        }
        throw Exception(onError.message);
      });

      if (loginResult.accessToken == null) {
        throw Exception(loginResult.message);
      }
      // Create a credential from the access token
      OAuthCredential facebookAuthCredential;

      print("tokenType${loginResult.accessToken!.type}");

      if (Platform.isIOS) {
        switch (loginResult.accessToken!.type) {
          case AccessTokenType.classic:
            final token = loginResult.accessToken as ClassicToken;
            facebookAuthCredential = FacebookAuthProvider.credential(
              token.authenticationToken!,
            );
            break;
          case AccessTokenType.limited:
            final token = loginResult.accessToken as LimitedToken;
            facebookAuthCredential = OAuthCredential(
              providerId: 'facebook.com',
              signInMethod: 'oauth',
              idToken: token.tokenString,
              rawNonce: rawNonce,
            );
            break;
        }
      } else {
        facebookAuthCredential = FacebookAuthProvider.credential(
          loginResult.accessToken!.tokenString,
        );
      }

      // Once signed in, return the UserCredential
      return FirebaseAuth.instance.signInWithCredential(facebookAuthCredential).then((val){
        FirebaseFirestore.instance
            .collection(FirebaseX.collectionApp)

            .doc(FirebaseAuth.instance.currentUser!.uid)
            .get()
            .then((DocumentSnapshot documentSnapshot) async{
          if (documentSnapshot.exists) {

            isLosing =false;
            update();
            await Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=> bottonBar(theIndex: 0,)), (rute)=>false);


          }else {

            isLosing =false;
            update();
            await Get.to(InformationUser(
              email: FirebaseAuth.instance.currentUser!.email.toString(),
              password: 'NO PASSWORD',
              passwordAndEmail: false,
            ));
          }
        });
        return null;
      });
    }on FirebaseAuthException catch (e) {
      // معالجة الأخطاء
      switch (e.code) {
        case 'account-exists-with-different-credential':
          print('An account already exists with the same email address but different sign-in credentials.') ;
          break;
        case 'invalid-credential':
         print('The credential is invalid or expired.') ;
          break;
        case 'operation-not-allowed':
          print('This type of account is not enabled.');
          break;
        case 'user-disabled':
          print('The user account has been disabled.') ;
          break;
        case 'user-not-found':
          print('No user found for the provided email.') ;
          break;
        case 'wrong-password':
          print('The password is invalid for the provided email.') ;
          break;
        default:
          print('An unknown error occurred.') ;
      }
    }
    return null;

  }
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  //
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

  Future<void> signInWithApple(BuildContext context) async {
    try {
      final apple = await SignInWithApple.getAppleIDCredential(scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName
      ] );

      final OAuthCredential = OAuthProvider('apple.com');
      final craedentail = OAuthCredential.credential(
          accessToken: apple.authorizationCode,
          idToken: apple.identityToken
      );



      await auth.signInWithCredential(craedentail).then((val){
        FirebaseFirestore.instance
            .collection(FirebaseX.collectionApp)

            .doc(FirebaseAuth.instance.currentUser!.uid)
            .get()
            .then((DocumentSnapshot documentSnapshot) async{
          if (documentSnapshot.exists) {

            isLosing =false;
            update();
            await Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=> bottonBar(theIndex: 0,)), (rute)=>false);


          }else {

            isLosing =false;
            update();
            await Get.to(InformationUser(
              email: FirebaseAuth.instance.currentUser!.email.toString(),
              password: 'NO PASSWORD',
              passwordAndEmail: false,
            ));
          }
        });
      });


    }on FirebaseAuthException catch (e) {
      // معالجة الأخطاء
      switch (e.code) {
        case 'account-exists-with-different-credential':
          print('An account already exists with the same email address but different sign-in credentials.') ;
          break;
        case 'invalid-credential':
          print('The credential is invalid or expired.') ;
          break;
        case 'operation-not-allowed':
          print('This type of account is not enabled.');
          break;
        case 'user-disabled':
          print('The user account has been disabled.') ;
          break;
        case 'user-not-found':
          print('No user found for the provided email.') ;
          break;
        case 'wrong-password':
          print('The password is invalid for the provided email.') ;
          break;
        default:
          print('An unknown error occurred.') ;
      }
    } catch (e) {
      print('Error during sign in with Apple: $e');
      rethrow;
    }
  }
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

  Future<UserCredential?> signInWithYahoo(BuildContext context) async {
    final yahooProvider = YahooAuthProvider();

    try {

      if (kIsWeb) {
        return await auth.signInWithPopup(yahooProvider).then((val){
          FirebaseFirestore.instance
              .collection(FirebaseX.collectionApp)

              .doc(FirebaseAuth.instance.currentUser!.uid)
              .get()
              .then((DocumentSnapshot documentSnapshot) async{
            if (documentSnapshot.exists) {

              isLosing =false;
              update();
              await Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=> bottonBar(theIndex: 0,)), (rute)=>false);


            }else {

              isLosing =false;
              update();
              await Get.to(InformationUser(
                email: FirebaseAuth.instance.currentUser!.email.toString(),
                password: 'NO PASSWORD',
                passwordAndEmail: false,
              ));
            }
          });
          return null;
        });



      } else {
        return await auth.signInWithProvider(yahooProvider).then((val){
          FirebaseFirestore.instance
              .collection(FirebaseX.collectionApp)

              .doc(FirebaseAuth.instance.currentUser!.uid)
              .get()
              .then((DocumentSnapshot documentSnapshot) async{
            if (documentSnapshot.exists) {

              isLosing =false;
              update();
              await Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=> bottonBar(theIndex: 0,)), (rute)=>false);


            }else {

              isLosing =false;
              update();
              await Get.to(InformationUser(
                email: FirebaseAuth.instance.currentUser!.email.toString(),
                password: 'NO PASSWORD',
                passwordAndEmail: false,
              ));
            }
          });
          return null;
        });
      }
    }on FirebaseAuthException catch (e) {
      // معالجة الأخطاء
      switch (e.code) {
        case 'account-exists-with-different-credential':
          print('An account already exists with the same email address but different sign-in credentials.') ;
          break;
        case 'invalid-credential':
          print('The credential is invalid or expired.') ;
          break;
        case 'operation-not-allowed':
          print('This type of account is not enabled.');
          break;
        case 'user-disabled':
          print('The user account has been disabled.') ;
          break;
        case 'user-not-found':
          print('No user found for the provided email.') ;
          break;
        case 'wrong-password':
          print('The password is invalid for the provided email.') ;
          break;
        default:
          print('An unknown error occurred.') ;
      }
    } catch (e) {
      print('Error signing in with Yahoo: $e');
      rethrow;
    }
    return null;
  }



  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\




  Future<UserCredential?> signInWithMicrosoft(BuildContext context) async {
    try{
      final microsoftProvider = MicrosoftAuthProvider();
      if (kIsWeb) {


        return await FirebaseAuth.instance.signInWithPopup(microsoftProvider).then((val){
          FirebaseFirestore.instance
              .collection(FirebaseX.collectionApp)

              .doc(FirebaseAuth.instance.currentUser!.uid)
              .get()
              .then((DocumentSnapshot documentSnapshot) async{
            if (documentSnapshot.exists) {

              isLosing =false;
              update();
              await Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=> bottonBar(theIndex: 0,)), (rute)=>false);


            }else {

              isLosing =false;
              update();
              await Get.to(InformationUser(
                email: FirebaseAuth.instance.currentUser!.email.toString(),
                password: 'NO PASSWORD',
                passwordAndEmail: false,
              ));
            }
          });
          return null;
        });



      } else {
        return await FirebaseAuth.instance.signInWithProvider(microsoftProvider).then((val){
          FirebaseFirestore.instance
              .collection(FirebaseX.collectionApp)

              .doc(FirebaseAuth.instance.currentUser!.uid)
              .get()
              .then((DocumentSnapshot documentSnapshot) async{
            if (documentSnapshot.exists) {

              isLosing =false;
              update();
              await Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=> bottonBar(theIndex: 0,)), (rute)=>false);


            }else {

              isLosing =false;
              update();
              await Get.to(InformationUser(
                email: FirebaseAuth.instance.currentUser!.email.toString(),
                password: 'NO PASSWORD',
                passwordAndEmail: false,
              ));
            }
          });
          return null;
        });
      }

    }on FirebaseAuthException catch (e) {
      // معالجة الأخطاء
      switch (e.code) {
        case 'account-exists-with-different-credential':
          print('An account already exists with the same email address but different sign-in credentials.') ;
          break;
        case 'invalid-credential':
          print('The credential is invalid or expired.') ;
          break;
        case 'operation-not-allowed':
          print('This type of account is not enabled.');
          break;
        case 'user-disabled':
          print('The user account has been disabled.') ;
          break;
        case 'user-not-found':
          print('No user found for the provided email.') ;
          break;
        case 'wrong-password':
          print('The password is invalid for the provided email.') ;
          break;
        default:
          print('An unknown error occurred.') ;
      }
    }
    return null;



  }


  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\





  Intention() async {

    try{
      Future.delayed(Duration(seconds: 2), () {
        if (isFirstTime == true ) {
          return Get.defaultDialog(title:'قم بالتحقق من الآيميل ' );
            // showDialog<void>(barrierDismissible: true,context: context, builder: (BuildContext context){
            // return AlertDialog(
            //   actions: [
            //     IconButton(onPressed: (){
            //
            //         isFirstTime =false;
            //      update();
            //       Navigator.pop(context,true);
            //
            //     }, icon: Icon(Icons.close))
            //   ],
            //   title: Text('قم بالتحقق من الآيميل '),
            //   content: Text('آذهب الى البريد الوارد'),
            // );});
        }else{ return null;}

      });



    }catch(e){
      print('777777777777777777777777777');
      print(e);
      print('777777777777777777777777777');

    }
  }








  Future<void> signIn(BuildContext context ,GlobalKey<FormState> globalKey)async{
    if(globalKey.currentState!.validate()){
      try{
        print('777777777777777777777');




        isLosing =true;
        update();

        await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: Email.text,
            password: Password.text
        ).then((value){
          if(value.user!.emailVerified) {
            FirebaseFirestore.instance
                .collection(FirebaseX.collectionApp)
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .get()
                .then((DocumentSnapshot documentSnapshot) async{
              if (documentSnapshot.exists) {
                await  FirebaseMessaging.instance.getToken().then((val)async{

                  await  FirebaseFirestore.instance.collection(FirebaseX.collectionApp).doc(FirebaseAuth.instance.currentUser!.uid).update({
                    'token':val.toString()
                  }).then((val){
                    Get.to(bottonBar(theIndex: 0,));
                  });
                });


                print(documentSnapshot.data());

              }else{
                Get.to(InformationUser(
                  email: Email.text,
                  password: Password.text,
                  passwordAndEmail: true,
                ));

              }
            });
          }

          else{

            isLosing=false;
            update();
            print('111111111111111111emailVerified');
            return
              showDialog<void>(barrierDismissible: true,context: context, builder: (BuildContext context){
                return AlertDialog(
                  actions: [
                    IconButton(onPressed: (){

                      isFirstTime =false;

                      Navigator.pop(context,true);

                    }, icon: Icon(Icons.close))
                  ],
                  title: Text('قم بالتحقق من الآيميل '),
                  content: Text('آذهب الى البريد الوارد'),
                );});

          }

        });



      }on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {

          isLosing=false;
          update();
          print('111111111111111111user-not-found');
          return
            showDialog<void>(barrierDismissible: true,context: context, builder: (BuildContext context){
              return AlertDialog(
                actions: [
                  IconButton(onPressed: (){

                    isFirstTime =false;
                    update();
                    Navigator.pop(context,true);

                  }, icon: Icon(Icons.close))
                ],
                title: Text('الايميل غير صحيح'),
                content: Text('هذا الايميل غير موجود'),
              );});
        } else if (e.code == 'wrong-password') {
          isLosing=false;
          update();
          print('111111111111111111user-not-found');
          return
            showDialog<void>(barrierDismissible: true,context: context, builder: (BuildContext context){
              return AlertDialog(
                actions: [
                  IconButton(onPressed: (){
                    isFirstTime =false;
                    update();
                    Navigator.pop(context,true);

                  }, icon: Icon(Icons.close))
                ],
                title: Text('الايميل او الرمز السري خطاء'),
                content: Text('حاول مرة اخرى'),
              );});

        }
      }catch(e){
        print('2222222222222222222222222222');
        print(e.toString());
        print('2222222222222222222222222222');

      }

    }

  }



}