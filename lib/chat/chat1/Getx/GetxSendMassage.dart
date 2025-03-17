
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../XXX/XXXFirebase.dart';
import '../../../controler/local-notification-onroller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import 'UploadVoisMessage.dart';




class Getxsendmassage extends GetxController{
  TextEditingController Maseage =TextEditingController();
  String uid;
  TextEditingController TheMesage =TextEditingController();
  BuildContext? context;
  bool isKeyboardVisible = false;

  // =========================================================

  bool isGren =true;
  bool isyellow=false;

  bool isRecord = false;
  bool _isCancelled = false;

  bool? isShowSindingButton;
  bool? isSindingAudio;
  bool? isdelete =false;
  String? filePath ;
  String? audioPath;
  final recored = AudioRecorder();
 late Timer? timer;
  int TheTimeOfMessage = 0;
  int minut = 0;
  int second = 0;
  Offset _startOffset = Offset(0, 0);
  Offset _currentOffset = Offset(0, 0);
  final uid12 = Uuid().v1();

  bool isSending = false;

  Getxsendmassage({required this.Maseage,required this.uid,this.context});




  isGrend()async{
    bool hasPermission = await Permission.microphone.isGranted;
    final state = await Permission.microphone.request();

    if(state == PermissionStatus.granted){
      hasPermission = true;

    }else{
      hasPermission = false;

    }
    return hasPermission;
  }



  void update1(LongPressMoveUpdateDetails details,double wii) {

    if(Maseage.text.isEmpty){
    _currentOffset = details.globalPosition;
    if (_currentOffset.dx - _startOffset.dx < -wii / 6) {
      print('2222222222222222222222222');

      isdelete = true;
      isGren = false;
      isyellow = false;


      update();
    }
    if (_currentOffset.dx - _startOffset.dx < -wii / 8) {
      if (_currentOffset.dx - _startOffset.dx > -wii / 6) {

        isdelete = false;
        isGren = false;
        isyellow = true;
        update();
      }
    }
    if (_currentOffset.dx - _startOffset.dx < -wii / 10) {
      if (_currentOffset.dx - _startOffset.dx > -wii / 8) {

        isGren = true;
        isyellow = false;


        update();
      }
    }
  }


  }





 void stopRecord(LongPressEndDetails details,double wii)async {

   if(Maseage.text.isEmpty){


     if (_currentOffset.dx == 0.0) {

     isSending = true;


     print(-wii / 6);
     timer!.cancel();
     isdelete = false;
     minut = 0;
     second = 0;
     await recored.stop();
     isRecord = false;
     isSindingAudio = false;

     update();

     if(TheTimeOfMessage >0){

       await uplodeVoisMessage().upLodeMessageVoisToFirebse(uid, filePath!);
       TheTimeOfMessage = 0;
       isSending = false;
       update();


     }


   }

   if (_currentOffset.dx - _startOffset.dx < -wii / 1000000000) {
     if (_currentOffset.dx - _startOffset.dx > -wii / 6) {

       isSending = true;

       timer!.cancel();

       isdelete = false;
       minut = 0;
       second = 0;
        await recored.stop();
       isRecord = false;
       isSindingAudio = false;
       // filePath = finalPath1!;
       update();

       if(TheTimeOfMessage >0){
         print(';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;');
        await uplodeVoisMessage().upLodeMessageVoisToFirebse(uid, filePath!);
         TheTimeOfMessage = 0;
               isSending = false;
               update();














       }
     }
   }









   // مسح

   if (_currentOffset.dx - _startOffset.dx < -wii / 6 &&
       _currentOffset.dx != 0.0) {
     timer!.cancel();


     TheTimeOfMessage = 0;
     isdelete = false;
     minut = 0;
     second = 0;
     await recored.stop();
     isRecord = false;
     isSindingAudio = false;
     update();
   }
 }


  }


 void AudioRecored(LongPressStartDetails details,double wii,BuildContext context)async{

    try{
      final Path1  = await getApplicationDocumentsDirectory();







      if(Maseage.text.isEmpty){

      _startOffset = details.globalPosition;
      print(details.globalPosition);



      final hasPermission = await isGrend();



        if(hasPermission){

            if(TheTimeOfMessage == 0){
              timer = Timer.periodic(Duration(seconds: 1), (timerr){
                TheTimeOfMessage++;
                second++;

                if(second == 60){
                  minut++;
                  second =0;
                  update();
                }
                update();
              });
            }



            filePath = '${Path1.path}/audio_record.aac';


            print(Path1.path);



           //  مهم
           //  SystemChannels.textInput.invokeMethod('TextInput.show');


            await recored.start(RecordConfig(), path: filePath!,
            // Path1.path+uid1+'.aac'
            );
            update();
            isRecord = true;
            isdelete =false;
            _isCancelled = false;


          }else{
            Get.defaultDialog(title: 'الرجاء اعطاء الاذن لآستخدام الصوت',
            textCancel: 'الغاء',
              onCancel: (){Navigator.pop(context);},
              textConfirm: 'موافق',
              onConfirm: (){
              recored.hasPermission();
              }
            );

          }












      }




    }catch(e){}



  }






  sendMessage2()async{

    try{

      if(Maseage.text.isNotEmpty){
        update();
        TheMesage.text =Maseage.text;

        Maseage.clear();
        if(TheMesage.text.isNotEmpty){
          final uid1 = Uuid().v1();
          await FirebaseFirestore.instance.collection('Chat')
              .doc(FirebaseAuth.instance.currentUser!.uid).collection('chat')
              .doc(uid).collection('messages').doc(uid1).set({
            'sender':FirebaseAuth.instance.currentUser!.uid,
            'resiveID':uid,
            'message':TheMesage.text,
            'time':DateTime.now(),
            'uidMassege' : uid1,
            'type':'text',
            'isRead' :false

            // 'isRead' :false

          }).then((value) => FirebaseFirestore.instance.collection('Chat')
              .doc(FirebaseAuth.instance.currentUser!.uid).collection('chat')
              .doc(uid).set({
            'sender':uid,
            'resiveID':FirebaseAuth.instance.currentUser!.uid,
            'message':TheMesage.text,
            'time':DateTime.now(),
            'type':'text',
            'isRead' :false

            // 'isRead' :false



          }));





          await FirebaseFirestore.instance.collection('Chat')
              .doc(uid).collection('chat')
              .doc(FirebaseAuth.instance.currentUser!.uid).collection('messages').doc(uid1).set({
            'sender':FirebaseAuth.instance.currentUser!.uid,
            'resiveID':uid,
            'message':TheMesage.text,
            'time':DateTime.now(),
            'uidMassege' : uid1,
            'type':'text',


          }).then((value) => FirebaseFirestore.instance.collection('Chat')
              .doc(uid).collection('chat')
              .doc(FirebaseAuth.instance.currentUser!.uid).set({
            'sender':FirebaseAuth.instance.currentUser!.uid,
            'resiveID':uid,
            'message':TheMesage.text,
            'time':DateTime.now(),
            'type':'text',



          }));
          FirebaseFirestore.instance.collection(FirebaseX.collectionApp).doc(FirebaseAuth.instance.currentUser!.uid).get().then((name)async{
            FirebaseFirestore.instance.collection(FirebaseX.collectionApp).doc(uid).get().then((uid)async{
              await localNotification.sendNotificationMessageToUser(uid.get('token'), name.get('name'), 'لديك رسالة ', uid.toString(), 'message', '');
            } );
          } );







        }

      }




    }


    catch(e){



    }

  }

  // +++++++++++++++_____________+++++++++++++++++____________________+++++++++++++++++++++++++++++++
  // +++++++++++++++_____________+++++++++++++++++____________________+++++++++++++++++++++++++++++++
  // +++++++++++++++_____________+++++++++++++++++____________________+++++++++++++++++++++++++++++++


 @override
  void onInit() {





   //  // TODO: implement onInit
   KeyboardVisibilityController().onChange.listen((bool visible) {
       isKeyboardVisible = visible;
       update();
       print('dddddddddddddddddddddddddddddddddddddd');
       print(isKeyboardVisible);
       print('dddddddddddddddddddddddxxddddddddddddddd');
   });


  super.onInit();
  }


}

