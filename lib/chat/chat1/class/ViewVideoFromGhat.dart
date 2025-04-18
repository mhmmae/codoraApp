
//
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:video_player/video_player.dart';
//
// import '../Getx/GetChatVideoFromFIrbase.dart';
//
// class Viewvideofromghat extends StatelessWidget {
//   String uid;
//   String url12;
//   Viewvideofromghat({super.key,required this.uid,required this.url12,});
//
//   @override
//   Widget build(BuildContext context) {
//     double hi = MediaQuery.of(context).size.height;
//     double wi = MediaQuery.of(context).size.width;
//     return GetBuilder<GetVideoFromFirebase123>(init: GetVideoFromFirebase123(VideoURL: url12),builder: (logic) {
//       return logic.videoController != null
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
//           Positioned(top: 30,bottom: 30,left: 30,right: 30,child: logic.videoController!.value.isPlaying ?Container()
//               :Container(height: hi/20,width: wi/30,alignment: Alignment.center,child: Container(decoration: BoxDecoration(color: Colors.white,borderRadius: BorderRadius.circular(20)),width: wi/9,height: hi/18,child: Icon(Icons.play_arrow,size: 30,color: Colors.black,)),),),
//
//           Positioned(bottom: 0,right: 0,left: 0,child: VideoProgressIndicator(logic.videoController!,allowScrubbing: true,),),
//
//
//           Positioned(
//               top: hi / 35,
//               right: wi / 27,
//               child: GestureDetector(onTap: ()async{
//                 await logic.videoController!.dispose();
//                 Navigator.pop(context);
//                 logic.update();},
//                 child: Container(
//                     height: hi / 17,
//                     width: wi / 8.5,
//                     decoration: BoxDecoration(
//                         border: Border.all(color: Colors.black, width: 2),
//                         color: Colors.black87,
//                         borderRadius: BorderRadius.circular(100)),
//                     child: Icon(
//                       Icons.cancel,
//                       size: wi/12.5,
//                       color: Colors.white,
//                     )),
//               )),
//
//
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
//         child: GestureDetector(onTap: (){},
//           child: Center(
//               child: CircularProgressIndicator()
//           ),
//         ),
//       )
//           : Align(alignment: Alignment.bottomRight,
//         child: GestureDetector(onTap: (){},
//           child: Center(
//               child: CircularProgressIndicator()
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

import '../Getx/GetChatVideoFromFIrbase.dart';

class ViewVideoFromChat extends StatelessWidget {
  final String uid; // معرف المستخدم
  final String videoURL; // رابط الفيديو

  ViewVideoFromChat({super.key, required this.uid, required this.videoURL});

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return GetBuilder<GetVideoFromFirebase123>(
      init: GetVideoFromFirebase123(videoURL: videoURL),
      builder: (logic) {
        return logic.videoController != null
            ? logic.videoController!.value.isInitialized
            ? Stack(
          children: [
            GestureDetector(
              onTap: () => logic.playAndStop(),
              child: Container(
                width: screenWidth,
                height: screenHeight,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: AspectRatio(
                  aspectRatio: logic.videoController!.value.aspectRatio,
                  child: VideoPlayer(logic.videoController!),
                ),
              ),
            ),
            if (!logic.videoController!.value.isPlaying)
              Positioned(
                top: screenHeight / 2.5,
                left: screenWidth / 2.5,
                child: Container(
                  width: screenWidth / 9,
                  height: screenHeight / 18,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    size: 30,
                    color: Colors.black,
                  ),
                ),
              ),
            Positioned(
              bottom: 0,
              right: 0,
              left: 0,
              child: VideoProgressIndicator(
                logic.videoController!,
                allowScrubbing: true, // السماح بتقديم الفيديو
              ),
            ),
            Positioned(
              top: screenHeight / 35,
              right: screenWidth / 27,
              child: GestureDetector(
                onTap: () {
                  logic.deleteVideo(context); // حذف الفيديو
                },
                child: Container(
                  width: screenWidth / 8.5,
                  height: screenHeight / 17,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 2),
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Icon(
                    Icons.cancel,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        )
            : const Center(child: CircularProgressIndicator())
            : const Center(child: CircularProgressIndicator());
      },
    );
  }
}
