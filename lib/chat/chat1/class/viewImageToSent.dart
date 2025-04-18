// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
//
// import '../../../bottonBar/botonBar.dart';
// import '../Getx/GetXaddImageAndVideo.dart';
//
// class Viewimage extends StatelessWidget {
//   Viewimage({super.key,
//     required this.uint8list,
//     required this.uid,
//   });
//
//   Uint8List uint8list;
//   String uid;
//
//   @override
//   Widget build(BuildContext context) {
//     double hi = MediaQuery
//         .of(context)
//         .size
//         .height;
//     double wi = MediaQuery
//         .of(context)
//         .size
//         .width;
//     return Scaffold(
//         body: Stack(
//           children: [
//
//             Container(
//               decoration: BoxDecoration(
//                   image: DecorationImage(
//                       fit: BoxFit.fill,
//                       image: MemoryImage(
//                         uint8list,
//                       ))),
//             ),
//             GetBuilder<GetxAddImageAndVideo>( init: GetxAddImageAndVideo(uid: uid),builder: (logic) {
//               return Positioned(
//                   bottom: hi / 45,
//                   right: wi / 25,
//                   child: GestureDetector(
//                       onTap: () {
//                         logic.sendImageInGhat(uint8list, context);
//                         // val.update();
//
//                       },
//                       child: logic.isSend
//                           ? CircularProgressIndicator(strokeWidth: 10,)
//                           : Container(
//                           height: hi / 17,
//                           width: wi / 8.5,
//                           decoration: BoxDecoration(
//                               border: Border.all(color: Colors.black, width: 2),
//                               color: Colors.green,
//                               borderRadius: BorderRadius.circular(100)),
//                           child: Icon(
//                             Icons.send,
//                             size: wi / 17,
//                             color: Colors.black,
//                           )),
//                     )
//                   );
//             }),
//             Positioned(
//                 top: hi / 35,
//                 right: wi / 27,
//                 child: GestureDetector(onTap: () {
//                   Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=>BottomBar(theIndex: 2,)), (rute)=>false);
//                 },
//                   child: Container(
//                       height: hi / 17,
//                       width: wi / 8.5,
//                       decoration: BoxDecoration(
//                           border: Border.all(color: Colors.black, width: 2),
//                           color: Colors.black87,
//                           borderRadius: BorderRadius.circular(100)),
//                       child: Icon(
//                         Icons.cancel,
//                         size: wi / 12.5,
//                         color: Colors.white,
//                       )),
//                 )),
//
//
//           ],
//
//
//         )
//     );
//   }
// }




import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../bottonBar/botonBar.dart';
import '../Getx/GetXaddImageAndVideo.dart';

class ViewImage extends StatelessWidget {
  final Uint8List imageData; // الصورة بصيغة Uint8List
  final String uid;

  ViewImage({
    super.key,
    required this.imageData,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black, // خلفية داكنة لتحسين التركيز على الصورة
      body: Stack(
        children: [
          // عرض الصورة داخل الشاشة
          Center(
            child: InteractiveViewer(
              panEnabled: true, // تمكين السحب
              minScale: 0.8, // الحد الأدنى للتكبير
              maxScale: 4.0, // الحد الأقصى للتكبير
              child: Container(
                width: screenWidth,
                height: screenHeight,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: MemoryImage(imageData), // عرض الصورة باستخدام MemoryImage
                    fit: BoxFit.contain, // التناسق مع أبعاد الشاشة
                  ),
                ),
              ),
            ),
          ),

          // زر الإرسال أسفل الصورة
          GetBuilder<GetxAddImageAndVideo>(
            init: GetxAddImageAndVideo(uid: uid),
            builder: (logic) {
              return Positioned(
                bottom: screenHeight / 45,
                right: screenWidth / 25,
                child: GestureDetector(
                  onTap: () => logic.sendImage(imageData, context),
                  child: logic.isSending
                      ? const CircularProgressIndicator(strokeWidth: 5) // مؤشر انتظار أثناء الإرسال
                      : Container(
                    height: screenHeight / 17,
                    width: screenWidth / 8.5,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Icon(
                      Icons.send,
                      size: screenWidth / 17,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),

          // زر الإغلاق أعلى الشاشة
          Positioned(
            top: screenHeight / 35,
            right: screenWidth / 27,
            child: GestureDetector(
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => BottomBar(theIndex: 2)),
                      (route) => false,
                );
              },
              child: Container(
                height: screenHeight / 17,
                width: screenWidth / 8.5,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Icon(
                  Icons.cancel,
                  size: screenWidth / 12.5,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
