//
//
//
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:video_player/video_player.dart';
//
// import '../Getx/GetXaddImageAndVideo.dart';
//
// class Viewvideo extends StatelessWidget {
//   String uid;
//   String url12;
//   Viewvideo({super.key,required this.uid,required this.url12,});
//
//   @override
//   Widget build(BuildContext context) {
//     double hi = MediaQuery.of(context).size.height;
//     double wi = MediaQuery.of(context).size.width;
//     return GetBuilder<GetxAddImageAndVideo>(init: GetxAddImageAndVideo(uid:uid ),builder: (logic) {
//       return logic.url1 != null
//           ?
//       logic.videoController!.value.isInitialized ? Stack(
//         children: [
//           GestureDetector(onTap: (){
//             logic.playAndSTOP();
//           },
//             child: Container(width: wi,height: hi,
//               decoration: BoxDecoration(
//                   border: Border.all(color: Colors.black,width: 2),
//                   borderRadius: BorderRadius.circular(6)
//               ),
//               child: AspectRatio(
//                 aspectRatio: logic.videoController!.value.aspectRatio,
//                 child: VideoPlayer(logic.videoController!),),
//             ),
//           ),
//
//
//
//           Positioned(top: 30,bottom: 30,left: 30,right: 30,child:  logic.videoController!.value.isPlaying ?Container()
//               :Container(height: hi/20,width: wi/30,alignment: Alignment.center,child: Container(decoration: BoxDecoration(color: Colors.white,borderRadius: BorderRadius.circular(20)),width: wi/9,height: hi/18,child: Icon(Icons.play_arrow,size: 30,color: Colors.black,)),),),
//
//           Positioned(bottom: 0,right: 0,left: 0,child: VideoProgressIndicator(logic.videoController!,allowScrubbing: true,),),
//
//           Positioned(top: hi/20,left: wi/7,child: GestureDetector(onTap: (){logic.deletVideo(context);},child: Container(color: Colors.transparent,width: wi/8,height: hi/16,child: Icon(Icons.dangerous,size: wi/10,color: Colors.red,),))),
//
//
//
//          Positioned(bottom: hi/20,right: wi/7,child: GestureDetector(onTap: (){logic.sendVideoInGhat(logic.url1!, context);
//
//            },child: logic.isSend  ?CircularProgressIndicator(strokeWidth: wi/10,): Container(color: Colors.transparent,width: wi/8,height: hi/16,child: Icon(Icons.send,size: wi/10,color: Colors.red,),))),
//
//
//
//
//
//         ],
//       )
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
//           : Align(alignment: Alignment.bottomRight,
//         child: GestureDetector(onTap: (){logic.choosVideo();},
//           child: Center(
//             child: CircularProgressIndicator()
//           ),
//         ),
//       )
//           : Align(alignment: Alignment.bottomRight,
//         child: GestureDetector(onTap: (){logic.choosVideo();},
//           child: Center(
//             child: CircularProgressIndicator()
//           ),
//         ),
//       );
//
//     });
//   }
// }


















import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../Getx/GetXaddImageAndVideo.dart';

class ViewVideo extends StatelessWidget {
  final String uid;
  final String videoURL;

  ViewVideo({super.key, required this.uid, required this.videoURL});

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return GetBuilder<GetxAddImageAndVideo>(
      init: GetxAddImageAndVideo(uid: uid),
      builder: (logic) {
        if (logic.videoController == null || !logic.videoController!.value.isInitialized) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: GestureDetector(
                onTap: () {
                  logic.pickVideo(); // اختيار فيديو جديد
                },
                child: logic.videoController == null
                    ? const CircularProgressIndicator() // مؤشر التحميل
                    : const Text(
                  'فشل تحميل الفيديو',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              GestureDetector(
                onTap: () {
                  logic.playAndSTOP(); // تشغيل أو إيقاف الفيديو
                },
                child: Container(
                  width: screenWidth,
                  height: screenHeight,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: AspectRatio(
                    aspectRatio: logic.videoController!.value.aspectRatio,
                    child: VideoPlayer(logic.videoController!),
                  ),
                ),
              ),

              // زر تشغيل الفيديو إذا كان متوقفاً
              if (!logic.videoController!.value.isPlaying)
                Positioned(
                  top: screenHeight / 2.5,
                  left: screenWidth / 2.5,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    width: screenWidth / 10,
                    height: screenHeight / 18,
                    child: const Icon(
                      Icons.play_arrow,
                      size: 30,
                      color: Colors.black,
                    ),
                  ),
                ),

              // مؤشر تقدم الفيديو
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: VideoProgressIndicator(
                  logic.videoController!,
                  allowScrubbing: true, // تمكين السحب لتقديم الفيديو
                  colors: VideoProgressColors(
                    playedColor: Colors.red,
                    bufferedColor: Colors.grey,
                    backgroundColor: Colors.black,
                  ),
                ),
              ),

              // زر حذف الفيديو
              Positioned(
                top: screenHeight / 20,
                left: screenWidth / 7,
                child: GestureDetector(
                  onTap: () {
                    logic.deletVideo(context); // حذف الفيديو
                  },
                  child: Container(
                    color: Colors.transparent,
                    width: screenWidth / 8,
                    height: screenHeight / 16,
                    child: const Icon(
                      Icons.delete_forever,
                      size: 40,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),

              // زر إرسال الفيديو
              Positioned(
                bottom: screenHeight / 20,
                right: screenWidth / 7,
                child: GestureDetector(
                  onTap: () {
                    logic.sendVideo(context); // إرسال الفيديو
                  },
                  child: logic.isSending
                      ? const CircularProgressIndicator(strokeWidth: 5) // مؤشر انتظار أثناء الإرسال
                      : Container(
                    color: Colors.transparent,
                    width: screenWidth / 8,
                    height: screenHeight / 16,
                    child: const Icon(
                      Icons.send,
                      size: 40,
                      color: Colors.green,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

