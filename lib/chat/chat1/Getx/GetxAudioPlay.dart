


import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';


class VoiceMessageController extends GetxController {

  final AudioPlayer audioPlayer = AudioPlayer();
   RxBool isPlaying =false.obs;
  Duration duration = Duration();
  Duration possion = Duration();
    // String url1 ;

  void playVoiceMessage1(String url) async {







    if (isPlaying.value) {
       await audioPlayer.pause();
       isPlaying.value = false;
       update();

    } else {
       await audioPlayer.play(UrlSource(url));
       isPlaying.value = true;
       update();


    }
    isPlaying.value = !isPlaying.value;
    update();
  }


  // int? playingIndex;
  //
  //
  // void playPauseAudio(int index) async {
  //   if (playingIndex != null) {
  //     await audioPlayer.pause();
  //     voiceMessages[playingIndex!].isPlaying = false;
  //   }
  //
  //   if (playingIndex == index) {
  //
  //       playingIndex = null;
  //     return;
  //   }
  //
  //   await audioPlayer.play(UrlSource(voiceMessages[index].url));
  //   update();
  //     playingIndex = index;
  //     voiceMessages[index].isPlaying = true;
  //
  //   audioPlayer.onPlayerComplete.listen((event) {
  //       voiceMessages[index].isPlaying = false;
  //       playingIndex = null;
  //   });
  // }














  void seekToPossion(double second) async{
    final newPosion = Duration(seconds: second.toInt());
    await audioPlayer.seek(newPosion);
    await audioPlayer.resume();
    print("//////////////d///////////////h/////////////////////////////");



  }








  @override
  void onInit() {
    audioPlayer.onPlayerStateChanged.listen((event){
      if(event == PlayerState.playing){
        isPlaying.value = true;
        // update();

      }
     else if(event == PlayerState.paused){
      isPlaying.value = false;
      // update();

      }
     else if(event == PlayerState.completed){
        isPlaying.value = false;
        possion = Duration.zero;
        print('======================================================1');
        print('1======================================================1');






         update();

      }
    });



    audioPlayer.onPositionChanged.listen((Newpossion){
      update();

    possion = Newpossion;
    });
    audioPlayer.onDurationChanged.listen((NewDuration){
      update();

    duration = NewDuration;
    });


    // TODO: implement onInit
    super.onInit();
  }

  @override
  void onClose() {
    audioPlayer.dispose();
    super.onClose();
  }
}