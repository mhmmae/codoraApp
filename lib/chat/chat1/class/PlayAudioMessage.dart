import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../Getx/GetxAudioPlay.dart';


class VoiceMessageTile extends StatelessWidget {
  VoiceMessageTile({super.key, required this.urlAudio});

  String urlAudio;

  bool isplay = false;
  final AudioPlayer audioPlayer = AudioPlayer();
  Duration duration = Duration();
  Duration possion = Duration();
  int The = 0;





  String formatTime(Duration duration) {
    String toDights(int n) => n.toString().padLeft(2, '0');
    final houre = toDights(duration.inHours);
    final minutes = toDights(duration.inMinutes.remainder(60));
    final second = toDights(duration.inSeconds.remainder(60));

    return [if (duration.inHours > 0) houre, minutes, second].join(':');
  }







  void plauOrPause() async {
    if (isplay) {
      print('===================================11');


      await audioPlayer.pause();
      isplay = false;
    }
    else {
      isplay = true;
      The = 0;
      await audioPlayer.play(UrlSource(urlAudio));
      print('ssfsfsf1111111111111111111111');
    }

    print(isplay);
  }

  void seekToPossion(double second) async {
    final newPosion = Duration(seconds: second.toInt());
    await audioPlayer.seek(newPosion);
    await audioPlayer.resume();
    print("//////////////d///////////////h/////////////////////////////");
  }


  @override
  Widget build(BuildContext context) {
    double hi = MediaQuery.of(context).size.height;
    double wi = MediaQuery.of(context).size.width;

    return GetBuilder<VoiceMessageController>(
      init: VoiceMessageController(), initState: (VoiceMessageController) {

    }, builder: (logic) {
      if (The == 0) {
        The++;
        audioPlayer.onPlayerStateChanged.listen((event) {
          if (event == PlayerState.playing) {
            isplay = true;
            logic.update();
            print(
                'playing======================================================1');
          }
          else if (event == PlayerState.paused) {
            isplay = false;
            logic.update();
            print(
                'paused======================================================1');
          }
          else if (event == PlayerState.completed) {
            isplay = false;
            possion = Duration.zero;
            duration = Duration.zero;
            print(
                'completed======================================================1');
            print('1======================================================1');
            logic.update();
          }
        });


        audioPlayer.onPositionChanged.listen((Newpossion) {
          print(
              'Newpossion======================================================1');

          logic.update();

          possion = Newpossion;
        });
        audioPlayer.onDurationChanged.listen((NewDuration) {
          print(
              'NewDuration======================================================1');

          logic.update();

          duration = NewDuration;
        });
      }

      return Container(height: hi/16,

          margin: EdgeInsets.symmetric(vertical: 2),
          padding: EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: isplay? Colors.black38:Colors.black54,
                child: GestureDetector(
                  onTap: () {
                    plauOrPause();



                  },
                  child: Container(
                    child: Icon(isplay
                        ? Icons.pause
                        : Icons.play_arrow),
                  ),
                ),
              )

              ,
              Expanded(
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Slider(
                      value: possion.inSeconds.toDouble(),
                      min: 0.0,
                      max: duration.inSeconds.toDouble()
                      ,
                      onChanged: seekToPossion
                      ,
                      activeColor: Colors.black26,)
                ),
              ),
              Text(formatTime(duration - possion),
              style: TextStyle(fontSize: wi/37),),
            ],
          )

      );
    },);
  }

}




