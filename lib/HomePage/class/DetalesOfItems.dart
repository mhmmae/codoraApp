// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:video_player/video_player.dart';
//
// import '../../bottonBar/botonBar.dart';
// import '../../chat/chat1/class/ViewImageFromChat.dart';
// import '../../chat/chat1/class/ViewVideoFromGhat.dart';
// import '../Get-Controllar/GetVideoFromFirebase.dart';
// import 'addAndRemoveSearch.dart';
//
// class DetalesOfItems extends StatelessWidget {
//   DetalesOfItems(
//       {super.key, this.url, required this.images,this.priceOfItem, this.descriptionOfItem, this.nameOfItem, this.uid, required this.isOffer, this.VideoURL,required this.typeItem,required this.rate });
//
//   String? descriptionOfItem;
//   String? nameOfItem;
//   int? priceOfItem;
//   String? url;
//   String? uid;
//   int number1 = 0;
//   int? total1;
//   bool isOffer;
//   String typeItem;
//   int rate;
//   List<dynamic> images=[];
//
//   String? VideoURL;
//
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
//       body: ListView(
//         children: [
//           SizedBox(height: hi / 120,),
//           Row(
//             children: [
//               SizedBox(width: wi / 30,),
//               GetBuilder<GetVideoFromFirebase>(init: GetVideoFromFirebase(VideoURL: VideoURL!),builder: (logic) {
//                 return GestureDetector(onTap: () async{
//                  await logic.videoController!.dispose();
//                   Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=>bottonBar(theIndex: 0,)), (rute)=>false);
//                 }, child: Container(child: Row(
//                   children: [
//                     Icon(Icons.arrow_back, size: wi / 15,),
//                     SizedBox(width: wi / 50,),
//                     Text('رجوع'),
//                     SizedBox(width: wi / 50,),
//                   ],
//                 )));
//               }),
//
//
//             ],
//           ),
//           Column(
//             children: [
//               SizedBox(height: hi / 100),
//               Row(
//                 children: [
//                   Row(
//                     children: [
//                       SizedBox(
//                         width: wi / 50,
//                       ),
//                       GestureDetector(
//                         onTap: (){
//                           Navigator.push(context, MaterialPageRoute(builder: (context)=>Viewimagefromchat(uint8list: url!,uid:uid!,)));
//                         },
//                         child: Container(
//                           height: hi / 4,
//                           width: wi / 2,
//                           decoration: BoxDecoration(
//                               color: Colors.black12,
//                               borderRadius: BorderRadius.circular(6),
//                               border: Border.all(color: Colors.black),
//                               image: DecorationImage(
//                                   fit: BoxFit.cover,
//                                   image: NetworkImage(url!))),
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(
//                     width: wi / 30,
//                   ),
//                   Column(
//                     children: [
//                       Container(
//                         width: wi / 2.5,
//                         decoration: BoxDecoration(
//                             color: Colors.black12,
//                             borderRadius: BorderRadius.circular(16),
//                             border: Border.all(color: Colors.black)),
//                         child:
//
//                         Center(
//                             child: Text(nameOfItem!,
//                                 style: TextStyle(fontSize: wi / 30))),
//
//
//                       ),
//                       SizedBox(
//                         height: hi / 100,
//                       ),
//                       Container(
//                         width: wi / 2.5,
//                         decoration: BoxDecoration(
//                             color: Colors.black12,
//                             borderRadius: BorderRadius.circular(16),
//                             border: Border.all(color: Colors.black)),
//                         child:
//                         Center(
//                             child: Text('$priceOfItem',
//                                 style: TextStyle(fontSize: wi / 30))),
//
//                       ),
//                       SizedBox(
//                         height: hi / 100,
//                       ),
//                       typeItem != '' ? Container(
//                         width: wi / 2.5,
//                         decoration: BoxDecoration(
//                             color: Colors.black12,
//                             borderRadius: BorderRadius.circular(16),
//                             border: Border.all(color: Colors.black)),
//                         child:
//
//                         Center(
//                             child: Text(typeItem,
//                                 style: TextStyle(fontSize: wi / 30))),
//
//                       ): rate !=0?Container(
//                         width: wi / 2.5,
//                         decoration: BoxDecoration(
//                             color: Colors.black12,
//                             borderRadius: BorderRadius.circular(16),
//                             border: Border.all(color: Colors.black)),
//                         child:
//
//                         Center(
//                             child: Text('$rate% off',
//                                 style: TextStyle(fontSize: wi / 30))),
//
//                       )  :Container()
//                     ],
//                   )
//                 ],
//               ),
//             ],
//           ),
//           VideoURL != 'noVideo' ? Divider():Container(),
//
//           SizedBox(height: hi / 70,),
//
//           VideoURL != 'noVideo' ? Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: GetBuilder<GetVideoFromFirebase>(
//                 init: GetVideoFromFirebase(VideoURL: VideoURL!),
//                 builder: (logic) {
//                   return SizedBox(width: wi,
//                       height: hi / 2.5,
//                       child: logic.videoController!.value.isInitialized ? Stack(
//                         children: [
//                           GestureDetector(onTap: () {
//                             logic.playAndSTOP();
//                           },
//                             child: Container(width: wi, height: hi / 2.5,
//                               decoration: BoxDecoration(
//                                   border: Border.all(
//                                       color: Colors.black, width: 2),
//                                   borderRadius: BorderRadius.circular(6)
//                               ),
//                               child: AspectRatio(
//                                 aspectRatio: logic.videoController!.value
//                                     .aspectRatio,
//                                 child: VideoPlayer(logic.videoController!),),
//                             ),
//                           ),
//
//
//                           Positioned(
//                             top: 30,
//                             bottom: 30,
//                             left: 30,
//                             right: 30,
//                             child: logic.videoController!.value.isPlaying
//                                 ? Container()
//                                 : Container(height: hi / 20,
//                               width: wi / 30,
//                               alignment: Alignment.center,
//                               child: Container(decoration: BoxDecoration(
//                                   color: Colors.white,
//                                   borderRadius: BorderRadius.circular(20)),
//                                   width: wi / 9,
//                                   height: hi / 18,
//                                   child: Icon(Icons.play_arrow, size: 30,
//                                     color: Colors.black,)),),),
//
//                           Positioned(bottom: 0, right: 0, left: 0,child: VideoProgressIndicator(logic
//                               .videoController!, allowScrubbing: true,),),
//
//                           Positioned(right: 5, bottom: 5,child: GestureDetector(
//                             onTap:()async{
//                               await logic.videoController!.dispose();
//                               Navigator.push(context, MaterialPageRoute(builder: (context)=>Viewvideofromghat(uid: uid!,url12: VideoURL!,)));
//
//                             },
//                             child: Container(decoration: BoxDecoration(
//                                 color: Colors.black,
//                                 borderRadius: BorderRadius.circular(12)
//                             ), child: Icon(Icons.fullscreen, size: wi / 11,
//                               color: Colors.white,)),
//                           ),),
//
//                           GestureDetector(onTap: () {
//                             logic.vois();
//                           }, child: Container(color: Colors.transparent,
//                             width: wi / 8,
//                             height: hi / 16,
//                             child: logic.valum == 0 ? Icon(
//                               Icons.record_voice_over_rounded, size: wi / 10,
//                               color: Colors.blue,)
//                                 : Icon(Icons.voice_over_off, size: wi / 10,
//                               color: Colors.blue,),))
//
//                         ],
//                       ) : Center(child: CircularProgressIndicator())
//                   );
//                 }),
//           ) : Container(),
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
//           Divider(),
//           Container(
//
//
//             alignment: Alignment.topRight,
//             child: Padding(
//               padding: const EdgeInsets.all(10),
//               child: Directionality(
//                 textDirection: TextDirection.ltr,
//                 child: Text(descriptionOfItem!, style: TextStyle(
//                     fontSize: wi / 28
//                 ),),
//               ),
//             ),
//           ),
//
//           SizedBox(height: hi / 17,),
//
//           Divider(),
//           Container(
//             width:wi,
//             height:hi/6,
//             child:ListView.builder(
//               itemCount: images.length,
//               scrollDirection:Axis.horizontal,
//               itemBuilder:(context,index){
//                 return Padding(
//                   padding: const EdgeInsets.all(7),
//                   child: GestureDetector(
//                     onTap: (){
//
//                       Navigator.push(context, MaterialPageRoute(builder: (context)=>Viewimagefromchat(uint8list: images[index],uid:uid!,)));
//                     },
//                     child: Container(
//                       width: wi/2.5,
//                       height: hi/6,
//
//                       decoration: BoxDecoration(
//                       image:DecorationImage(
//                         image:NetworkImage(images[index]),
//                         fit:BoxFit.cover
//                       ),
//                       color: Colors.black12,
//                       borderRadius: BorderRadius.circular(6),
//                       border: Border.all(color: Colors.black),
//
//
//                     )
//                     )
//                   ),
//                 );
//
//               }
//             )
//           ),
//           Divider(),
//
//
//           Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20),
//               child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     addAndRemoveSearch(
//                       uidItem: uid!,
//                       hi5: hi / 20,
//                       wi5: wi / 10,
//                       wi4: wi / 20,
//                       wi3: wi / 50,
//                       wi2: wi / 25,
//                       isOfeer: isOffer,),
//
//                     GestureDetector(
//                       onTap: () {
//                         Navigator.push(context, MaterialPageRoute(
//                             builder: (context) => bottonBar(theIndex: 1,)));
//                       },
//                       child: Container(
//                         decoration: BoxDecoration(
//                             color: Colors.black26,
//                             borderRadius: BorderRadius.circular(16),
//                             border: Border.all(color: Colors.black)
//                         ),
//                         width: wi / 2.7, height: hi / 20,
//                         child: Center(child: Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 10),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               Icon(Icons.card_travel, size: wi / 20,),
//
//                               Text('اذهب الى العربة',
//                                 style: TextStyle(fontSize: wi / 40),),
//                             ],
//                           ),
//                         )),
//                       ),
//                     )
//
//
//                   ]
//
//               )
//
//
//           ),
//           SizedBox(height: hi / 30,),
//
//
//
//         ],
//       ),
//
//     );
//   }
// }


























import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

// استيرادات الواجهات المخصصة
import '../../bottonBar/botonBar.dart';
import '../../chat/chat1/class/ViewImageFromChat.dart';
import '../../chat/chat1/class/ViewVideoFromGhat.dart';
import 'addAndRemoveSearch.dart';

class DetailsItemController extends GetxController {
  final String? videoURL;
  VideoPlayerController? videoController;
  RxBool isPlaying = false.obs;
  RxDouble volume = 1.0.obs;

  DetailsItemController({this.videoURL});

  @override
  void onInit() {
    super.onInit();
    if (videoURL != null && videoURL != 'noVideo') {
      // استخدام networkUrl بدلاً من network
      videoController = VideoPlayerController.networkUrl(Uri.parse(videoURL!))
        ..initialize().then((_) {
          update(); // تحديث الواجهة بعد التهيئة
        });
    }
  }

  void playAndStop() {
    if (videoController != null && videoController!.value.isInitialized) {
      if (videoController!.value.isPlaying) {
        videoController!.pause();
        isPlaying.value = false;
      } else {
        videoController!.play();
        isPlaying.value = true;
      }
      update();
    }
  }

  void toggleVolume() {
    if (volume.value == 0) {
      videoController?.setVolume(1.0);
      volume.value = 1.0;
    } else {
      videoController?.setVolume(0.0);
      volume.value = 0.0;
    }
    update();
  }

  @override
  void onClose() {
    videoController?.dispose();
    super.onClose();
  }
}


/// Widget يعرض تفاصيل العنصر باستخدام GetX Controller لإدارة حالة الفيديو
class DetailsOfItem extends StatelessWidget {
  final String? descriptionOfItem;
  final String? nameOfItem;
  final int? priceOfItem;
  final String? url;
  final String? uid;
  final bool isOffer;
  final String typeItem;
  final int rate;
  final List<dynamic> images;
  final String? videoURL;

  DetailsOfItem({
    Key? key,
    required this.images,
    required this.isOffer,
    required this.typeItem,
    required this.rate,
    this.descriptionOfItem,
    this.nameOfItem,
    this.priceOfItem,
    this.url,
    this.uid,
    this.videoURL,
  }) : super(key: key) {
    // تسجيل الـ Controller في حالة تواجد رابط فيديو صالح
    if (videoURL != null && videoURL != 'noVideo') {
      Get.put(DetailsItemController(videoURL: videoURL));
    }
  }

  @override
  Widget build(BuildContext context) {
    // الحصول على أبعاد الشاشة
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(nameOfItem ?? ''),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: width / 15),
          onPressed: () {
            // حذف الـ Controller قبل الرجوع إن وُجد
            if (videoURL != null && videoURL != 'noVideo') {
              Get.delete<DetailsItemController>();
            }
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => BottomBar(theIndex: 0)),
                  (route) => false,
            );
          },
        ),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(vertical: height / 120),
        children: [
          // القسم الرئيسي مع الصورة والمعلومات الأساسية
          _buildMainDetailsSection(context, width, height),
          // عرض الفيديو إذا وُجد رابط فيديو صالح
          if (videoURL != null && videoURL != 'noVideo') ...[
            Divider(),
            SizedBox(height: height / 70),
            _buildVideoSection(context, width, height),
          ],
          Divider(),
          _buildDescriptionSection(width),
          SizedBox(height: height / 17),
          Divider(),
          _buildImagesListSection(context, width, height),
          Divider(),
          _buildActionSection(context, width, height),
          SizedBox(height: height / 30),
        ],
      ),
    );
  }

  /// يعرض القسم الرئيسي للمعلومات (صورة العنصر، الاسم، السعر والنوع/التخفيض)
  Widget _buildMainDetailsSection(BuildContext context, double width, double height) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width / 30),
      child: Row(
        children: [
          // عرض الصورة الرئيسية مع إمكانية النقر للعرض الكامل
          GestureDetector(
            onTap: () {
              if (url != null && uid != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ViewImageFromChat(imageUrl: url!, uid: uid!),
                  ),
                );
              }
            },
            child: Container(
              height: height / 4,
              width: width / 2,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.black),
                image: url != null
                    ? DecorationImage(
                  fit: BoxFit.cover,
                  image: NetworkImage(url!),
                )
                    : null,
              ),
            ),
          ),
          SizedBox(width: width / 30),
          // عرض المعلومات الإضافية
          Column(
            children: [
              _buildInfoBox(width, height, nameOfItem ?? '', width / 30),
              SizedBox(height: height / 100),
              _buildInfoBox(width, height, priceOfItem != null ? '$priceOfItem' : '', width / 30),
              SizedBox(height: height / 100),
              typeItem.isNotEmpty
                  ? _buildInfoBox(width, height, typeItem, width / 30)
                  : (rate != 0
                  ? _buildInfoBox(width, height, '$rate% off', width / 30)
                  : Container()),
            ],
          )
        ],
      ),
    );
  }

  /// ويدجت مساعدة لعرض مربع يحتوي على نص مع تباعد وتنسيق مناسب
  Widget _buildInfoBox(double width, double height, String content, double fontSize) {
    return Container(
      width: width / 2.5,
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black),
      ),
      padding: EdgeInsets.all(8),
      child: Center(
        child: Text(content, style: TextStyle(fontSize: fontSize)),
      ),
    );
  }

  /// يعرض قسم الفيديو مع ربطه بالـ GetX Controller لإدارة الحالة
  Widget _buildVideoSection(BuildContext context, double width, double height) {
    return GetBuilder<DetailsItemController>(
      builder: (controller) {
        if (controller.videoController != null &&
            controller.videoController!.value.isInitialized) {
          return SizedBox(
            width: width,
            height: height / 2.5,
            child: Stack(
              children: [
                GestureDetector(
                  onTap: controller.playAndStop,
                  child: Container(
                    width: width,
                    height: height / 2.5,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: AspectRatio(
                      aspectRatio: controller.videoController!.value.aspectRatio,
                      child: VideoPlayer(controller.videoController!),
                    ),
                  ),
                ),
                // عرض أيقونة التشغيل حين يكون الفيديو متوقفاً
                if (!controller.videoController!.value.isPlaying)
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      width: width / 9,
                      height: height / 18,
                      child: Icon(Icons.play_arrow, size: 30, color: Colors.black),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: VideoProgressIndicator(controller.videoController!, allowScrubbing: true),
                ),
                // زر تكبير الفيديو (fullscreen)
                Positioned(
                  right: 5,
                  bottom: 5,
                  child: GestureDetector(
                    onTap: () {
                      controller.videoController?.dispose();
                      if (uid != null && videoURL != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ViewVideoFromChat(uid: uid!, videoURL: videoURL!)),
                        );
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.fullscreen, size: width / 11, color: Colors.white),
                    ),
                  ),
                ),
                // المكان الذي تحتاج فيه لأي جزء يعتمد على Rx يمكنك وضعه داخل Obx أيضًا
                Positioned(
                  top: 0,
                  left: 0,
                  child: buildVolumeIcon(width),
                ),
              ],
            ),
          );
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  // دالة مساعدة لإنشاء أيقونة تغيير الصوت بشكل تفاعلي
  Widget buildVolumeIcon(double width) {
    final controller = Get.find<DetailsItemController>();
    return Obx(() {
      return GestureDetector(
        onTap: () {
          // عند الضغط، يتم تبديل مستوى الصوت
          controller.toggleVolume();
        },
        child: controller.volume.value == 0
            ? Icon(
          Icons.record_voice_over_rounded,
          size: width / 10,
          color: Colors.blue,
        )
            : Icon(
          Icons.voice_over_off,
          size: width / 10,
          color: Colors.blue,
        ),
      );
    });
  }




  /// يعرض قسم الوصف للنص مع تحديد اتجاه النص
  Widget _buildDescriptionSection(double width) {
    return Container(
      alignment: Alignment.topRight,
      padding: const EdgeInsets.all(10),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Text(
          descriptionOfItem ?? '',
          style: TextStyle(fontSize: width / 28),
        ),
      ),
    );
  }

  /// يعرض قائمة الصور الإضافية أفقيًا مع إمكانية عرض الصورة عند النقر
  Widget _buildImagesListSection(BuildContext context, double width, double height) {
    return Container(
      width: width,
      height: height / 6,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(7),
            child: GestureDetector(
              onTap: () {
                if (uid != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ViewImageFromChat(imageUrl: images[index], uid: uid!),
                    ),
                  );
                }
              },
              child: Container(
                width: width / 2.5,
                height: height / 6,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(6),
                  image: DecorationImage(
                    image: NetworkImage(images[index]),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// يعرض قسم الإجراءات مثل إضافة العنصر للسلة
  Widget _buildActionSection(BuildContext context, double width, double height) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AddAndRemoveSearchWidget(
            uidItem: uid ?? '',
            hi5: height / 20,
            wi5: width / 10,
            wi4: width / 20,
            wi3: width / 50,
            wi2: width / 25,
            isOfeer: isOffer,
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => BottomBar(theIndex: 1)));
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black),
              ),
              width: width / 2.7,
              height: height / 20,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.card_travel, size: width / 20),
                      Text('اذهب الى العربة', style: TextStyle(fontSize: width / 40)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
