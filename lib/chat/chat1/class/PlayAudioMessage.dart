// import 'package:audioplayers/audioplayers.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// import '../Getx/GetxAudioPlay.dart';
//
//
// class VoiceMessageTile extends StatelessWidget {
//   VoiceMessageTile({super.key, required this.urlAudio});
//
//   String urlAudio;
//
//   bool isplay = false;
//   final AudioPlayer audioPlayer = AudioPlayer();
//   Duration duration = Duration();
//   Duration possion = Duration();
//   int The = 0;
//
//
//
//
//
//   String formatTime(Duration duration) {
//     String toDights(int n) => n.toString().padLeft(2, '0');
//     final houre = toDights(duration.inHours);
//     final minutes = toDights(duration.inMinutes.remainder(60));
//     final second = toDights(duration.inSeconds.remainder(60));
//
//     return [if (duration.inHours > 0) houre, minutes, second].join(':');
//   }
//
//
//
//
//
//
//
//   void plauOrPause() async {
//     if (isplay) {
//       print('===================================11');
//
//
//       await audioPlayer.pause();
//       isplay = false;
//     }
//     else {
//       isplay = true;
//       The = 0;
//       await audioPlayer.play(UrlSource(urlAudio));
//       print('ssfsfsf1111111111111111111111');
//     }
//
//     print(isplay);
//   }
//
//   void seekToPossion(double second) async {
//     final newPosion = Duration(seconds: second.toInt());
//     await audioPlayer.seek(newPosion);
//     await audioPlayer.resume();
//     print("//////////////d///////////////h/////////////////////////////");
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     double hi = MediaQuery.of(context).size.height;
//     double wi = MediaQuery.of(context).size.width;
//
//     return GetBuilder<VoiceMessageController>(
//       init: VoiceMessageController(), initState: (VoiceMessageController) {
//
//     }, builder: (logic) {
//       if (The == 0) {
//         The++;
//         audioPlayer.onPlayerStateChanged.listen((event) {
//           if (event == PlayerState.playing) {
//             isplay = true;
//             logic.update();
//             print(
//                 'playing======================================================1');
//           }
//           else if (event == PlayerState.paused) {
//             isplay = false;
//             logic.update();
//             print(
//                 'paused======================================================1');
//           }
//           else if (event == PlayerState.completed) {
//             isplay = false;
//             possion = Duration.zero;
//             duration = Duration.zero;
//             print(
//                 'completed======================================================1');
//             print('1======================================================1');
//             logic.update();
//           }
//         });
//
//
//         audioPlayer.onPositionChanged.listen((Newpossion) {
//           print(
//               'Newpossion======================================================1');
//
//           logic.update();
//
//           possion = Newpossion;
//         });
//         audioPlayer.onDurationChanged.listen((NewDuration) {
//           print(
//               'NewDuration======================================================1');
//
//           logic.update();
//
//           duration = NewDuration;
//         });
//       }
//
//       return Container(height: hi/16,
//
//           margin: EdgeInsets.symmetric(vertical: 2),
//           padding: EdgeInsets.all(2),
//           decoration: BoxDecoration(
//             color: Colors.transparent,
//             borderRadius: BorderRadius.circular(15),
//           ),
//           child: Row(
//             children: [
//               CircleAvatar(
//                 radius: 19,
//                 backgroundColor: isplay? Colors.black38:Colors.black54,
//                 child: GestureDetector(
//                   onTap: () {
//                     plauOrPause();
//
//
//
//                   },
//                   child: Container(
//                     child: Icon(isplay
//                         ? Icons.pause
//                         : Icons.play_arrow),
//                   ),
//                 ),
//               )
//
//               ,
//               Expanded(
//                 child: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 2),
//                     child: Slider(
//                       value: possion.inSeconds.toDouble(),
//                       min: 0.0,
//                       max: duration.inSeconds.toDouble()
//                       ,
//                       onChanged: seekToPossion
//                       ,
//                       activeColor: Colors.black26,)
//                 ),
//               ),
//               Text(formatTime(duration - possion),
//               style: TextStyle(fontSize: wi/37),),
//             ],
//           )
//
//       );
//     },);
//   }
//
// }












import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Getx/GetxAudioPlay.dart';

class VoiceMessageTile extends StatelessWidget {
  final String urlAudio; // رابط الصوت
  VoiceMessageTile({super.key, required this.urlAudio});

  final AudioPlayer audioPlayer = AudioPlayer(); // مشغل الصوت
  bool isPlaying = false; // حالة التشغيل
  Duration duration = Duration.zero; // مدة الصوت
  Duration position = Duration.zero; // موضع التشغيل الحالي

  /// تنسيق الوقت لعرضه على الشاشة
  String formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return [if (duration.inHours > 0) hours, minutes, seconds].join(':');
  }

  /// تشغيل أو إيقاف الصوت
  void playOrPause() async {
    if (isPlaying) {
      await audioPlayer.pause();
    } else {
      await audioPlayer.play(UrlSource(urlAudio));
    }
    isPlaying = !isPlaying;
  }

  /// الانتقال إلى موضع معين
  void seekToPosition(double seconds) async {
    final newPosition = Duration(seconds: seconds.toInt());
    await audioPlayer.seek(newPosition);
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return GetBuilder<VoiceMessageController>(
      init: VoiceMessageController(),
      builder: (logic) {
        // استماع للأحداث عند بدء التشغيل أو الانتهاء
        audioPlayer.onPlayerStateChanged.listen((event) {
          isPlaying = event == PlayerState.playing;
          logic.update(); // تحديث الواجهة
        });

        // استماع لموضع التشغيل الحالي
        audioPlayer.onPositionChanged.listen((newPosition) {
          position = newPosition;
          logic.update();
        });

        // استماع لمدة الصوت
        audioPlayer.onDurationChanged.listen((newDuration) {
          duration = newDuration;
          logic.update();
        });

        return Container(
          height: 60,
          margin: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              // زر التشغيل أو الإيقاف
              GestureDetector(
                onTap: playOrPause,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: isPlaying ? Colors.green : Colors.red,
                  child: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                ),
              ),
              // شريط التحكم
              Expanded(
                child: Slider(
                  value: position.inSeconds.toDouble(),
                  min: 0,
                  max: duration.inSeconds.toDouble(),
                  onChanged: (value) {
                    seekToPosition(value);
                  },
                  activeColor: Colors.blue,
                ),
              ),
              // عرض الوقت المتبقي
              Text(
                formatTime(duration - position),
                style: TextStyle(fontSize: screenWidth / 30),
              ),
            ],
          ),
        );
      },
    );
  }
}


