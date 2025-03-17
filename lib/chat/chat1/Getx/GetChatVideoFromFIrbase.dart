

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class GetVideoFromFirebase123 extends GetxController{
  VideoPlayerController? videoController;

  String VideoURL;
  double valum =0;
  bool isfull =true;
  GetVideoFromFirebase123({required this.VideoURL});


  deletVideo(BuildContext context){
    videoController!.dispose();
    VideoURL = '';
    Navigator.pop(context);
    update();

  }

  vois(){
    if(valum ==0){
      videoController!.setVolume(100);
      update();
      valum =100;

    }else{
      videoController!.setVolume(0);
      update();
      valum =0;

    }
  }




  playAndSTOP(){
    videoController!.value.isPlaying ?  videoController!.pause(): videoController!.play();
    update();
  }



  @override
  void onInit() {
    videoController =VideoPlayerController.networkUrl(Uri.parse(VideoURL));
    videoController!.setLooping(true);
    videoController!.setVolume(100);
    videoController!.initialize().then((val){
      update();
      videoController!.play();
    });
    // TODO: implement onInit
    super.onInit();
  }

  @override
  void dispose() {
    videoController!.dispose();
    // TODO: implement dispose
    super.dispose();
  }
}