//
// import 'dart:io';
//
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:get/get.dart';
// import 'package:image_picker/image_picker.dart';
// // import 'package:image_picker/image_picker.dart';
// import 'package:video_player/video_player.dart';
//
// class Getchoosevideo1 extends GetxController{
//   String? url;
//   VideoPlayerController? videoController;
//   String? imgUrl;
//
//
//   deletVideo(){
//     videoController!.dispose();
//     url =null;
//     update();
//   }
//
//
//   playAndSTOP(){
//     videoController!.value.isPlaying ?  videoController!.pause(): videoController!.play();
//     update();
//   }
//   videoPicker()async{
//     XFile? video;
//     ImagePicker imagePicker =ImagePicker();
//     video =await imagePicker.pickVideo(source: ImageSource.gallery,maxDuration:Duration(seconds: 10) );
//
//     if(video !=null){
//       return video.path;
//     }
//
//
//   }
//
//
//   Future<void> choosVideo()async{
//     url = await videoPicker();
//     print('1111111111111111111111111111');
//
//     await initVideo();
//   }
//   initVideo()async{
//     videoController =VideoPlayerController.file(File(url!))..initialize().then((fff){
//       update();
//       videoController!.play();
//     });
//   }
//
//   Future<void> save1()async{
//     Reference storage = FirebaseStorage.instance.ref('video').child('StoreImage${DateTime.now()}');
//     UploadTask uploadTask = storage.putFile(File(url!));
//     TaskSnapshot snapshot = await uploadTask;
//      imgUrl =await snapshot.ref.getDownloadURL();
//
//      await videoController!.dispose();
//     url =null;
//
//
//
//   }
//
// }



import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:video_compress/video_compress.dart';

class GetChooseVideo extends GetxController {
  String? videoUrl; // مسار الفيديو الأصلي
  String? uploadedVideoUrl; // رابط الفيديو المرفوع
  double? uploadProgress; // نسبة التقدم للرفع
  VideoPlayerController? videoController; // متحكم تشغيل الفيديو
  bool isLoading = false; // للتحكم بالتحميل أثناء العمليات

  /// حذف الفيديو وتحرير الموارد
  void deleteVideo() {
    if (videoController != null) {
      videoController!.dispose();
      videoController = null;
      videoUrl = null;
      update();
    }
  }

  /// تشغيل أو إيقاف الفيديو
  void togglePlayPause() {
    if (videoController != null) {
      videoController!.value.isPlaying
          ? videoController!.pause()
          : videoController!.play();
      update();
    }
  }
  /// اختيار الفيديو من المعرض
  Future<void> pickVideo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 10),
    );

    if (video != null) {
      videoUrl = video.path;
      await initializeVideo();
    } else {
      Get.snackbar(
        'اختيار الفيديو',
        'لم يتم اختيار أي فيديو.',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// ضغط الفيديو لتحسين حجمه قبل رفعه
  Future<void> compressVideo() async {
    if (videoUrl != null) {
      Get.snackbar(
        'ضغط الفيديو',
        'جاري ضغط الفيديو، الرجاء الانتظار...',
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      final MediaInfo? compressedVideo = await VideoCompress.compressVideo(
        videoUrl!,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false, // احتفظ بالملف الأصلي
      );

      if (compressedVideo != null) {
        videoUrl = compressedVideo.path; // تحديث المسار للفيديو المضغوط
        Get.snackbar(
          'ضغط الفيديو',
          'تم ضغط الفيديو بنجاح!',
          backgroundColor: Colors.greenAccent,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        update();
      } else {
        Get.snackbar(
          'ضغط الفيديو',
          'فشل في ضغط الفيديو.',
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  /// تهيئة متحكم تشغيل الفيديو
  Future<void> initializeVideo() async {
    if (videoUrl != null) {
      videoController = VideoPlayerController.file(File(videoUrl!))
        ..initialize().then((_) {
          videoController!.play();
          update();
        }).catchError((e) {
          Get.snackbar(
            'خطأ تشغيل الفيديو',
            e.toString(),
            backgroundColor: Colors.redAccent,
            colorText: Colors.white,
          );
        });
    }
  }

  /// رفع الفيديو مع شريط التقدم
  Future<void> saveVideoToFirebase() async {
    if (videoUrl != null) {
      try {
        await compressVideo();
        Reference storage = FirebaseStorage.instance
            .ref('videos')
            .child('video_${DateTime.now().millisecondsSinceEpoch}.mp4');
        UploadTask uploadTask = storage.putFile(File(videoUrl!));

        // مراقبة تقدم الرفع
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          uploadProgress =
              (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
          update();
        });

        TaskSnapshot snapshot = await uploadTask;
        uploadedVideoUrl = await snapshot.ref.getDownloadURL();
        deleteVideo(); // تحرير الموارد

        Get.snackbar(
          'نجاح',
          'تم رفع الفيديو بنجاح!',
          backgroundColor: Colors.greenAccent,
          colorText: Colors.white,
        );
      } catch (e) {
        Get.snackbar(
          'خطأ أثناء الرفع',
          e.toString(),
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } else {
      Get.snackbar(
        'رفع الفيديو',
        'لا يوجد فيديو لرفعه.',
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
    }
  }
}
