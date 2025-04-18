
//
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:video_player/video_player.dart';
//
// class GetVideoFromFirebase123 extends GetxController{
//   VideoPlayerController? videoController;
//
//   String VideoURL;
//   double valum =0;
//   bool isfull =true;
//   GetVideoFromFirebase123({required this.VideoURL});
//
//
//   deletVideo(BuildContext context){
//     videoController!.dispose();
//     VideoURL = '';
//     Navigator.pop(context);
//     update();
//
//   }
//
//   vois(){
//     if(valum ==0){
//       videoController!.setVolume(100);
//       update();
//       valum =100;
//
//     }else{
//       videoController!.setVolume(0);
//       update();
//       valum =0;
//
//     }
//   }
//
//
//
//
//   playAndSTOP(){
//     videoController!.value.isPlaying ?  videoController!.pause(): videoController!.play();
//     update();
//   }
//
//
//
//   @override
//   void onInit() {
//     videoController =VideoPlayerController.networkUrl(Uri.parse(VideoURL));
//     videoController!.setLooping(true);
//     videoController!.setVolume(100);
//     videoController!.initialize().then((val){
//       update();
//       videoController!.play();
//     });
//     // TODO: implement onInit
//     super.onInit();
//   }
//
//   @override
//   void dispose() {
//     videoController!.dispose();
//     // TODO: implement dispose
//     super.dispose();
//   }
// }














import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class GetVideoFromFirebase123 extends GetxController {
  VideoPlayerController? videoController; // للتحكم في الفيديو
  final String videoURL; // رابط الفيديو
  double volume = 0; // مستوى الصوت
  bool isFullScreen = true; // حالة الشاشة الكاملة

  GetVideoFromFirebase123({required this.videoURL});

  /// حذف الفيديو وإزالة الموارد
  void deleteVideo(BuildContext context) {
    Navigator.pop(context); // العودة للشاشة السابقة
    videoController?.dispose(); // التخلص من الموارد
    update(); // تحديث الحالة

  }

  /// تغيير حالة الصوت
  void toggleVolume() {
    if (volume == 0) {
      videoController?.setVolume(1); // تعيين مستوى الصوت إلى أعلى قيمة
      volume = 1; // تحديث المتغير
    } else {
      videoController?.setVolume(0); // كتم الصوت
      volume = 0; // تحديث المتغير
    }
    update();
  }

  /// تشغيل وإيقاف الفيديو
  void playAndStop() {
    if (videoController?.value.isPlaying == true) {
      videoController?.pause(); // إيقاف الفيديو
    } else {
      videoController?.play(); // تشغيل الفيديو
    }
    update();
  }

  @override
  void onInit() {
    super.onInit();
    videoController = VideoPlayerController.networkUrl(Uri.parse(videoURL));
      videoController!.setLooping(true); // تكرار الفيديو
    videoController!.setVolume(1); // تعيين مستوى الصوت
    videoController!.initialize().then((_) {
        update(); // تحديث الحالة عند اكتمال التهيئة
        videoController?.play(); // تشغيل الفيديو تلقائيًا
      });
  }

  @override
  void dispose() {
    if (videoController != null) {
      videoController?.dispose(); // إزالة الموارد
      videoController = null; // تعيين videoController إلى null
    }

    super.dispose();
  }
}
