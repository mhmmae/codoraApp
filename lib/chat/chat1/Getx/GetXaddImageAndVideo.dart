
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:get_thumbnail_video/index.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

import '../../../XXX/XXXFirebase.dart';
import '../../../bottonBar/botonBar.dart';
import '../../../controler/local-notification-onroller.dart';
import '../Chat.dart';
import '../class/viewImageToSent.dart';
import '../class/viewVideoToSent.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';


class GetxAddImageAndVideo extends GetxController{
  String uid;
  File? Thumbnail;
  bool isSend =false;


  GetxAddImageAndVideo({required this.uid});


  takeImage(
      ImageSource source
      )async{
    final ImagePicker imagePicker = ImagePicker();

    final XFile? imagex =await imagePicker.pickImage(source:source ,);

    if(imagex != null){
      return imagex.readAsBytes();
    }


  }

  void takeCamera()async{
    Uint8List img = await takeImage(ImageSource.camera);
    Get.to(Viewimage(uint8list: img,uid: uid,));
  

  }
  void takeGallery()async{
    Uint8List img = await takeImage(ImageSource.gallery);

    Get.to(Viewimage(uint8list: img,uid: uid,));

  

  }


  addImageAndVideo(double hi1,double wi1,BuildContext context){
    showModalBottomSheet<ImageSource>(context: context, builder: (BuildContext context){
      return  Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(onTap: (){
            takeGallery();
          },
            child: Container(width: wi1/3.5,height: hi1/3,color: Colors.transparent
            ,child: Column(
              children: [
                SizedBox(height: hi1/40,),
                Container(width:wi1/4.8,height: hi1/10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  color: Colors.black26,
                ),
                  child: Icon(Icons.image,size: wi1/10,),

                ),
                Align(alignment: Alignment.center,child: Container(width: wi1/4.5,height: hi1/20,color: Colors.transparent,child: Align(alignment: Alignment.center,child: Text('صور')),))
              ],
            ),),
          ),


          SizedBox(width: hi1/70,),


















          GestureDetector(onTap: (){
            choosVideo();
          },
            child: Container(width: wi1/3.5,height: hi1/3,color: Colors.transparent
              ,child: Column(
                children: [
                  SizedBox(height: hi1/40,),
                  Container(width:wi1/4.8,height: hi1/10,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      color: Colors.black26,
                    ),
                    child: Icon(Icons.video_collection,size: wi1/10,),

                  ),
                  Align(alignment: Alignment.center,child: Container(width: wi1/4.5,height: hi1/20,color: Colors.transparent,child: Align(alignment: Alignment.center,child: Text('فيديو')),))
                ],
              ),),
          ),





          SizedBox(width: hi1/70,),



















          GestureDetector(onTap: (){
            takeCamera();
          },
            child: Container(width: wi1/3.5,height: hi1/3,color: Colors.transparent
              ,child: Column(
                children: [
                  SizedBox(height: hi1/40,),
                  Container(width:wi1/4.8,height: hi1/10,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      color: Colors.black26,
                    ),
                    child: Icon(Icons.camera_alt,size: wi1/10,),

                  ),
                  Align(alignment: Alignment.center,child: Container(width: wi1/4.5,height: hi1/20,color: Colors.transparent,child: Align(alignment: Alignment.center,child: Text('كامرة')),))
                ],
              ),),
          )

        ],
      );
    });
  }


  // =====================================================================================================================================================================
// =====================================================================================================================================================================
// =====================================================================================================================================================================

  FirebaseStorage firebaseStorage = FirebaseStorage.instance;

  sendImageInGhat(Uint8List uint8list,BuildContext context)async{
    try{
      final uid1 = Uuid().v1();
      isSend =true;
      update();

      Reference storge =  firebaseStorage.ref(FirebaseX.StorgeApp).child(Uuid().v1());
      UploadTask uploadTask =storge.putData(uint8list);
      TaskSnapshot taskSnapshot =await uploadTask;
      String url =await taskSnapshot.ref.getDownloadURL();




        await FirebaseFirestore.instance.collection('Chat')
            .doc(FirebaseAuth.instance.currentUser!.uid).collection('chat')
            .doc(uid).collection('messages').doc(uid1).set({
          'sender':FirebaseAuth.instance.currentUser!.uid,
          'resiveID':uid,
          'message':url,
          'time':DateTime.now(),
          'uidMassege' : uid1,
          'type':'img',
          'isRead' :false

          // 'isRead' :false

        }).then((value) => FirebaseFirestore.instance.collection('Chat')
            .doc(FirebaseAuth.instance.currentUser!.uid).collection('chat')
            .doc(uid).set({
          'sender':uid,
          'resiveID':FirebaseAuth.instance.currentUser!.uid,
          'message':url,
          'time':DateTime.now(),
          'type':'img',
          'isRead' :false

          // 'isRead' :false



        }));





        await FirebaseFirestore.instance.collection('Chat')
            .doc(uid).collection('chat')
            .doc(FirebaseAuth.instance.currentUser!.uid).collection('messages').doc(uid1).set({
          'sender':FirebaseAuth.instance.currentUser!.uid,
          'resiveID':uid,
          'message':url,
          'time':DateTime.now(),
          'uidMassege' : uid1,
          'type':'img',


        }).then((value) => FirebaseFirestore.instance.collection('Chat')
            .doc(uid).collection('chat')
            .doc(FirebaseAuth.instance.currentUser!.uid).set({
          'sender':FirebaseAuth.instance.currentUser!.uid,
          'resiveID':uid,
          'message':url,
          'time':DateTime.now(),
          'type':'img',



        }));


      FirebaseFirestore.instance.collection(FirebaseX.collectionApp).doc(FirebaseAuth.instance.currentUser!.uid).get().then((name)async{
        FirebaseFirestore.instance.collection(FirebaseX.collectionApp).doc(uid).get().then((uid)async{
          await localNotification.sendNotificationMessageToUser(uid.get('token'), name.get('name'), 'لديك صورة ', uid.toString(), 'image', '');
        } );
      } );

      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=>bottonBar(theIndex: 2,)), (rute)=>false);










    }


    catch(e){

      print('111111111111111111111111111111111111');
      print(e);
      print('111111111111111111111111111111111111');

    }
  }

// =====================================================================================================================================================================
// =====================================================================================================================================================================
// =====================================================================================================================================================================

  String? url1 ;
  VideoPlayerController? videoController;
  String? imgUrl;


  Future<File> getVideoThumbnail (String url) async {

    var thumbTempPath = await VideoThumbnail.thumbnailFile(
      video: url,
      thumbnailPath: (await getTemporaryDirectory()).path,
      imageFormat: ImageFormat.PNG,
      maxHeight: 64, // specify the height of the thumbnail, let the width auto-scaled to keep the source aspect ratio
      quality: 100, // you can change the thumbnail quality here
    );
    File file= File(thumbTempPath.path);
    return file;
  }

  videoPicker()async{
    XFile? video;
    ImagePicker imagePicker =ImagePicker();
    video =await imagePicker.pickVideo(source: ImageSource.gallery,maxDuration:Duration(seconds: 10) );

    if(video !=null){

      return video.path;
    }


  }

  initVideo()async{
    videoController =VideoPlayerController.file(File(url1!))..initialize().then((fff){
      update();
      videoController!.play();
    });
  }

  Future<void> choosVideo()async{
    url1 =await videoPicker();
    Thumbnail= await getVideoThumbnail(url1!);

    await initVideo();
    if(url1 !=null){
      Get.to(Viewvideo(uid: uid,url12: url1!,));
    }




  }




  playAndSTOP(){
    videoController!.value.isPlaying ?  videoController!.pause(): videoController!.play();
    update();
  }


  deletVideo(BuildContext context){
    videoController!.dispose();
    url1 = null;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=>chat(uid: uid,)), (rute)=>false);
    update();

  }


  sendVideoInGhat(String url14,BuildContext context)async{
    try{
      isSend =true;

      update();
      final uid1 = Uuid().v1();






      Reference storage = FirebaseStorage.instance.ref('video').child('StoreImage${DateTime.now()}');
      UploadTask uploadTask = storage.putFile(File(url1!));
      TaskSnapshot snapshot = await uploadTask;
      imgUrl =await snapshot.ref.getDownloadURL();


      Reference storge =  firebaseStorage.ref(FirebaseX.StorgeApp).child(Uuid().v1());
      UploadTask uploadTask1 =storge.putFile(Thumbnail!);
      TaskSnapshot taskSnapshot =await uploadTask1;
      String thumbnail =await taskSnapshot.ref.getDownloadURL();





      await FirebaseFirestore.instance.collection('Chat')
          .doc(FirebaseAuth.instance.currentUser!.uid).collection('chat')
          .doc(uid).collection('messages').doc(uid1).set({
        'sender':FirebaseAuth.instance.currentUser!.uid,
        'resiveID':uid,
        'message':imgUrl,
        'time':DateTime.now(),
        'uidMassege' : uid1,
        'type':'video',
        'isRead' :false,
        'Thumbnail':thumbnail


        // 'isRead' :false

      }).then((value) => FirebaseFirestore.instance.collection('Chat')
          .doc(FirebaseAuth.instance.currentUser!.uid).collection('chat')
          .doc(uid).set({
        'sender':uid,
        'resiveID':FirebaseAuth.instance.currentUser!.uid,
        'message':imgUrl,
        'time':DateTime.now(),
        'type':'video',
        'isRead' :false,
        'Thumbnail':thumbnail


        // 'isRead' :false



      }));





      await FirebaseFirestore.instance.collection('Chat')
          .doc(uid).collection('chat')
          .doc(FirebaseAuth.instance.currentUser!.uid).collection('messages').doc(uid1).set({
        'sender':FirebaseAuth.instance.currentUser!.uid,
        'resiveID':uid,
        'message':imgUrl,
        'time':DateTime.now(),
        'uidMassege' : uid1,
        'type':'video',
        'Thumbnail':thumbnail



      }).then((value) => FirebaseFirestore.instance.collection('Chat')
          .doc(uid).collection('chat')
          .doc(FirebaseAuth.instance.currentUser!.uid).set({
        'sender':FirebaseAuth.instance.currentUser!.uid,
        'resiveID':uid,
        'message':imgUrl,
        'time':DateTime.now(),
        'type':'video',
        'Thumbnail':thumbnail




      }));
      FirebaseFirestore.instance.collection(FirebaseX.collectionApp).doc(FirebaseAuth.instance.currentUser!.uid).get().then((name)async{
        FirebaseFirestore.instance.collection(FirebaseX.collectionApp).doc(uid).get().then((uid)async{
          await localNotification.sendNotificationMessageToUser(uid.get('token'), name.get('name'), 'لديك رسالة ', uid.toString(), 'video', '');
        } );
      } );

      videoController!.dispose();
      url1 = null;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=>chat(uid: uid,)), (rute)=>false);
      update();











    }


    catch(e){

      print('111111111111111111111111111111111111');
      print(e);
      print('111111111111111111111111111111111111');

    }
  }


}