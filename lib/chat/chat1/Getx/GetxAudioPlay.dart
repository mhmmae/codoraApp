
//
//
// import 'package:audioplayers/audioplayers.dart';
// import 'package:get/get.dart';
//
//
// class VoiceMessageController extends GetxController {
//
//   final AudioPlayer audioPlayer = AudioPlayer();
//    RxBool isPlaying =false.obs;
//   Duration duration = Duration();
//   Duration possion = Duration();
//     // String url1 ;
//
//   void playVoiceMessage1(String url) async {
//
//
//
//
//
//
//
//     if (isPlaying.value) {
//        await audioPlayer.pause();
//        isPlaying.value = false;
//        update();
//
//     } else {
//        await audioPlayer.play(UrlSource(url));
//        isPlaying.value = true;
//        update();
//
//
//     }
//     isPlaying.value = !isPlaying.value;
//     update();
//   }
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//   void seekToPossion(double second) async{
//     final newPosion = Duration(seconds: second.toInt());
//     await audioPlayer.seek(newPosion);
//     await audioPlayer.resume();
//     print("//////////////d///////////////h/////////////////////////////");
//
//
//
//   }
//
//
//
//
//
//
//
//
//   @override
//   void onInit() {
//     audioPlayer.onPlayerStateChanged.listen((event){
//       if(event == PlayerState.playing){
//         isPlaying.value = true;
//         // update();
//
//       }
//      else if(event == PlayerState.paused){
//       isPlaying.value = false;
//       // update();
//
//       }
//      else if(event == PlayerState.completed){
//         isPlaying.value = false;
//         possion = Duration.zero;
//         print('======================================================1');
//         print('1======================================================1');
//
//
//
//
//
//
//          update();
//
//       }
//     });
//
//
//
//     audioPlayer.onPositionChanged.listen((Newpossion){
//       update();
//
//     possion = Newpossion;
//     });
//     audioPlayer.onDurationChanged.listen((NewDuration){
//       update();
//
//     duration = NewDuration;
//     });
//
//
//     // TODO: implement onInit
//     super.onInit();
//   }
//
//   @override
//   void onClose() {
//     audioPlayer.dispose();
//     super.onClose();
//   }
// }

















import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';

class VoiceMessageController extends GetxController {
  final AudioPlayer audioPlayer = AudioPlayer(); // مشغل الصوت
  RxBool isPlaying = false.obs; // حالة التشغيل
  Duration duration = Duration.zero; // مدة الصوت
  Duration position = Duration.zero; // موضع التشغيل الحالي

  /// تشغيل أو إيقاف الصوت
  void togglePlayPause(String url) async {
    if (isPlaying.value) {
      await audioPlayer.pause();
      isPlaying.value = false;
    } else {
      await audioPlayer.play(UrlSource(url));
      isPlaying.value = true;
    }
  }

  /// الانتقال إلى موضع معين
  void seekToPosition(double seconds) async {
    final newPosition = Duration(seconds: seconds.toInt());
    await audioPlayer.seek(newPosition);
  }

  @override
  void onInit() {
    super.onInit();

    // تحديث الحالة عند تغيير حالة التشغيل
    audioPlayer.onPlayerStateChanged.listen((event) {
      isPlaying.value = event == PlayerState.playing;
      if (event == PlayerState.completed) {
        position = Duration.zero; // إعادة الموضع إلى البداية
        update();
      }
    });

    // تحديث الحالة عند تغيير موضع التشغيل
    audioPlayer.onPositionChanged.listen((newPosition) {
      position = newPosition;
      update();
    });

    // تحديث الحالة عند تغيير مدة الصوت
    audioPlayer.onDurationChanged.listen((newDuration) {
      duration = newDuration;
      update();
    });
  }

  @override
  void onClose() {
    audioPlayer.dispose(); // تنظيف الموارد عند الإغلاق
    super.onClose();
  }
}
