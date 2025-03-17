
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

class Getchoosevideo extends GetxController{
  String? url;
  VideoPlayerController? videoController;
  String? imgUrl;


  deletVideo(){
    videoController!.dispose();
    url =null;
    update();
  }


  playAndSTOP(){
    videoController!.value.isPlaying ?  videoController!.pause(): videoController!.play();
    update();
  }
  videoPicker()async{
    XFile? video;
    ImagePicker imagePicker =ImagePicker();
    video =await imagePicker.pickVideo(source: ImageSource.gallery,maxDuration:Duration(seconds: 10) );

    if(video !=null){
      return video.path;
    }


  }


  Future<void> choosVideo()async{
    url = await videoPicker();
    print('1111111111111111111111111111');

    await initVideo();
  }
  initVideo()async{
    videoController =VideoPlayerController.file(File(url!))..initialize().then((fff){
      update();
      videoController!.play();
    });
  }

  Future<void> save1()async{
    Reference storage = FirebaseStorage.instance.ref('video').child('StoreImage${DateTime.now()}');
    UploadTask uploadTask = storage.putFile(File(url!));
    TaskSnapshot snapshot = await uploadTask;
     imgUrl =await snapshot.ref.getDownloadURL();

     await videoController!.dispose();
    url =null;



  }

}