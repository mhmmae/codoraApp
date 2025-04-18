//
// import 'dart:io';
//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// // import 'package:flutter_image_compress/flutter_image_compress.dart';
// import 'package:get/get.dart';
// import 'package:get_thumbnail_video/index.dart';
// import 'package:image_picker/image_picker.dart';
// // import 'package:image_picker/image_picker.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:uuid/uuid.dart';
// import 'package:video_player/video_player.dart';
//
// import '../../../XXX/XXXFirebase.dart';
// import '../../../bottonBar/botonBar.dart';
// import '../../../controler/local-notification-onroller.dart';
// import '../Chat.dart';
// import '../class/viewImageToSent.dart';
// import '../class/viewVideoToSent.dart';
// import 'package:get_thumbnail_video/video_thumbnail.dart';
//
//
// class GetxAddImageAndVideo extends GetxController{
//   String uid;
//   File? Thumbnail;
//   bool isSend =false;
//
//
//   GetxAddImageAndVideo({required this.uid});
//
//
//   takeImage(
//       ImageSource source
//       )async{
//     final ImagePicker imagePicker = ImagePicker();
//
//     final XFile? imagex =await imagePicker.pickImage(source:source ,);
//
//     if(imagex != null){
//       return imagex.readAsBytes();
//     }
//
//
//   }
//
//   void takeCamera()async{
//     Uint8List img = await takeImage(ImageSource.camera);
//     Get.to(ViewImage(imageData: img,uid: uid,));
//
//
//   }
//   void takeGallery()async{
//     Uint8List img = await takeImage(ImageSource.gallery);
//
//     Get.to(ViewImage(imageData: img,uid: uid,));
//
//
//
//   }
//
//
//   addImageAndVideo(double hi1,double wi1,BuildContext context){
//     showModalBottomSheet<ImageSource>(context: context, builder: (BuildContext context){
//       return  Row(
//         mainAxisAlignment: MainAxisAlignment.end,
//         children: [
//           GestureDetector(onTap: (){
//             takeGallery();
//           },
//             child: Container(width: wi1/3.5,height: hi1/3,color: Colors.transparent
//             ,child: Column(
//               children: [
//                 SizedBox(height: hi1/40,),
//                 Container(width:wi1/4.8,height: hi1/10,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(100),
//                   color: Colors.black26,
//                 ),
//                   child: Icon(Icons.image,size: wi1/10,),
//
//                 ),
//                 Align(alignment: Alignment.center,child: Container(width: wi1/4.5,height: hi1/20,color: Colors.transparent,child: Align(alignment: Alignment.center,child: Text('صور')),))
//               ],
//             ),),
//           ),
//
//
//           SizedBox(width: hi1/70,),
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
//           GestureDetector(onTap: (){
//             choosVideo();
//           },
//             child: Container(width: wi1/3.5,height: hi1/3,color: Colors.transparent
//               ,child: Column(
//                 children: [
//                   SizedBox(height: hi1/40,),
//                   Container(width:wi1/4.8,height: hi1/10,
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(100),
//                       color: Colors.black26,
//                     ),
//                     child: Icon(Icons.video_collection,size: wi1/10,),
//
//                   ),
//                   Align(alignment: Alignment.center,child: Container(width: wi1/4.5,height: hi1/20,color: Colors.transparent,child: Align(alignment: Alignment.center,child: Text('فيديو')),))
//                 ],
//               ),),
//           ),
//
//
//
//
//
//           SizedBox(width: hi1/70,),
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
//           GestureDetector(onTap: (){
//             takeCamera();
//           },
//             child: Container(width: wi1/3.5,height: hi1/3,color: Colors.transparent
//               ,child: Column(
//                 children: [
//                   SizedBox(height: hi1/40,),
//                   Container(width:wi1/4.8,height: hi1/10,
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(100),
//                       color: Colors.black26,
//                     ),
//                     child: Icon(Icons.camera_alt,size: wi1/10,),
//
//                   ),
//                   Align(alignment: Alignment.center,child: Container(width: wi1/4.5,height: hi1/20,color: Colors.transparent,child: Align(alignment: Alignment.center,child: Text('كامرة')),))
//                 ],
//               ),),
//           )
//
//         ],
//       );
//     });
//   }
//
//
//   // =====================================================================================================================================================================
// // =====================================================================================================================================================================
// // =====================================================================================================================================================================
//
//   FirebaseStorage firebaseStorage = FirebaseStorage.instance;
//
//   sendImageInGhat(Uint8List uint8list,BuildContext context)async{
//     try{
//       final uid1 = Uuid().v1();
//       isSend =true;
//       update();
//
//       Reference storge =  firebaseStorage.ref(FirebaseX.StorgeApp).child(Uuid().v1());
//       UploadTask uploadTask =storge.putData(uint8list);
//       TaskSnapshot taskSnapshot =await uploadTask;
//       String url =await taskSnapshot.ref.getDownloadURL();
//
//
//
//
//         await FirebaseFirestore.instance.collection('Chat')
//             .doc(FirebaseAuth.instance.currentUser!.uid).collection('chat')
//             .doc(uid).collection('messages').doc(uid1).set({
//           'sender':FirebaseAuth.instance.currentUser!.uid,
//           'resiveID':uid,
//           'message':url,
//           'time':DateTime.now(),
//           'uidMassege' : uid1,
//           'type':'img',
//           'isRead' :false
//
//           // 'isRead' :false
//
//         }).then((value) => FirebaseFirestore.instance.collection('Chat')
//             .doc(FirebaseAuth.instance.currentUser!.uid).collection('chat')
//             .doc(uid).set({
//           'sender':uid,
//           'resiveID':FirebaseAuth.instance.currentUser!.uid,
//           'message':url,
//           'time':DateTime.now(),
//           'type':'img',
//           'isRead' :false
//
//           // 'isRead' :false
//
//
//
//         }));
//
//
//
//
//
//         await FirebaseFirestore.instance.collection('Chat')
//             .doc(uid).collection('chat')
//             .doc(FirebaseAuth.instance.currentUser!.uid).collection('messages').doc(uid1).set({
//           'sender':FirebaseAuth.instance.currentUser!.uid,
//           'resiveID':uid,
//           'message':url,
//           'time':DateTime.now(),
//           'uidMassege' : uid1,
//           'type':'img',
//
//
//         }).then((value) => FirebaseFirestore.instance.collection('Chat')
//             .doc(uid).collection('chat')
//             .doc(FirebaseAuth.instance.currentUser!.uid).set({
//           'sender':FirebaseAuth.instance.currentUser!.uid,
//           'resiveID':uid,
//           'message':url,
//           'time':DateTime.now(),
//           'type':'img',
//
//
//
//         }));
//
//
//       FirebaseFirestore.instance.collection(FirebaseX.collectionApp).doc(FirebaseAuth.instance.currentUser!.uid).get().then((name)async{
//         FirebaseFirestore.instance.collection(FirebaseX.collectionApp).doc(uid).get().then((uid)async{
//           await LocalNotification.sendNotificationToUser(token: uid.get('token'),title:  name.get('name'), body: 'لديك صورة ',uid:  uid.toString(),type:  'image',image:  '');
//         } );
//       } );
//
//       Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=>BottomBar(theIndex: 2,)), (rute)=>false);
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
//     }
//
//
//     catch(e){
//
//       print('111111111111111111111111111111111111');
//       print(e);
//       print('111111111111111111111111111111111111');
//
//     }
//   }
//
// // =====================================================================================================================================================================
// // =====================================================================================================================================================================
// // =====================================================================================================================================================================
//
//   String? url1 ;
//   VideoPlayerController? videoController;
//   String? imgUrl;
//
//
//   Future<File> getVideoThumbnail (String url) async {
//
//     var thumbTempPath = await VideoThumbnail.thumbnailFile(
//       video: url,
//       thumbnailPath: (await getTemporaryDirectory()).path,
//       imageFormat: ImageFormat.PNG,
//       maxHeight: 64, // specify the height of the thumbnail, let the width auto-scaled to keep the source aspect ratio
//       quality: 100, // you can change the thumbnail quality here
//     );
//     File file= File(thumbTempPath.path);
//     return file;
//   }
//
//   videoPicker()async{
//     XFile? video;
//     ImagePicker imagePicker =ImagePicker();
//     video =await imagePicker.pickVideo(source: ImageSource.gallery,maxDuration:Duration(seconds: 10) );
//
//     if(video !=null){
//
//       return video.path;
//     }
//
//
//   }
//
//   initVideo()async{
//     videoController =VideoPlayerController.file(File(url1!))..initialize().then((fff){
//       update();
//       videoController!.play();
//     });
//   }
//
//   Future<void> choosVideo()async{
//     url1 =await videoPicker();
//     Thumbnail= await getVideoThumbnail(url1!);
//
//     await initVideo();
//     if(url1 !=null){
//       Get.to(ViewVideo(uid: uid,videoURL: url1!,));
//     }
//
//
//
//
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
//   deletVideo(BuildContext context){
//
//     Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=>ChatScreen(uid: uid,)), (rute)=>false);
//     videoController!.dispose();
//     url1 = null;
//     update();
//
//   }
//
//
//   sendVideoInGhat(String url14,BuildContext context)async{
//     try{
//       isSend =true;
//
//       update();
//       final uid1 = Uuid().v1();
//
//
//
//
//
//
//       Reference storage = FirebaseStorage.instance.ref('video').child('StoreImage${DateTime.now()}');
//       UploadTask uploadTask = storage.putFile(File(url1!));
//       TaskSnapshot snapshot = await uploadTask;
//       imgUrl =await snapshot.ref.getDownloadURL();
//
//
//       Reference storge =  firebaseStorage.ref(FirebaseX.StorgeApp).child(Uuid().v1());
//       UploadTask uploadTask1 =storge.putFile(Thumbnail!);
//       TaskSnapshot taskSnapshot =await uploadTask1;
//       String thumbnail =await taskSnapshot.ref.getDownloadURL();
//
//
//
//
//
//       await FirebaseFirestore.instance.collection('Chat')
//           .doc(FirebaseAuth.instance.currentUser!.uid).collection('chat')
//           .doc(uid).collection('messages').doc(uid1).set({
//         'sender':FirebaseAuth.instance.currentUser!.uid,
//         'resiveID':uid,
//         'message':imgUrl,
//         'time':DateTime.now(),
//         'uidMassege' : uid1,
//         'type':'video',
//         'isRead' :false,
//         'Thumbnail':thumbnail
//
//
//         // 'isRead' :false
//
//       }).then((value) => FirebaseFirestore.instance.collection('Chat')
//           .doc(FirebaseAuth.instance.currentUser!.uid).collection('chat')
//           .doc(uid).set({
//         'sender':uid,
//         'resiveID':FirebaseAuth.instance.currentUser!.uid,
//         'message':imgUrl,
//         'time':DateTime.now(),
//         'type':'video',
//         'isRead' :false,
//         'Thumbnail':thumbnail
//
//
//         // 'isRead' :false
//
//
//
//       }));
//
//
//
//
//
//       await FirebaseFirestore.instance.collection('Chat')
//           .doc(uid).collection('chat')
//           .doc(FirebaseAuth.instance.currentUser!.uid).collection('messages').doc(uid1).set({
//         'sender':FirebaseAuth.instance.currentUser!.uid,
//         'resiveID':uid,
//         'message':imgUrl,
//         'time':DateTime.now(),
//         'uidMassege' : uid1,
//         'type':'video',
//         'Thumbnail':thumbnail
//
//
//
//       }).then((value) => FirebaseFirestore.instance.collection('Chat')
//           .doc(uid).collection('chat')
//           .doc(FirebaseAuth.instance.currentUser!.uid).set({
//         'sender':FirebaseAuth.instance.currentUser!.uid,
//         'resiveID':uid,
//         'message':imgUrl,
//         'time':DateTime.now(),
//         'type':'video',
//         'Thumbnail':thumbnail
//
//
//
//
//       }));
//       FirebaseFirestore.instance.collection(FirebaseX.collectionApp).doc(FirebaseAuth.instance.currentUser!.uid).get().then((name)async{
//         FirebaseFirestore.instance.collection(FirebaseX.collectionApp).doc(uid).get().then((uid)async{
//           await LocalNotification.sendNotificationToUser(token: uid.get('token'),title:  name.get('name'),body:  'لديك رسالة ',uid:  uid.toString(),type:  'video',image:  '');
//         } );
//       } );
//
//
//       Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=>ChatScreen(uid: uid,)), (rute)=>false);
//       videoController!.dispose();
//       url1 = null;
//       update();
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
//     }
//
//
//     catch(e){
//
//       print('111111111111111111111111111111111111');
//       print(e);
//       print('111111111111111111111111111111111111');
//
//     }
//   }
//
//
//   @override
//   void onClose() {
//   // تنظيف الموارد هنا
//   super.onClose();
//   }
//
//
//
//
// }































import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_thumbnail_video/index.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'package:get_thumbnail_video/video_thumbnail.dart';
import '../../../XXX/XXXFirebase.dart';
import '../../../controler/local-notification-onroller.dart';
import '../Chat.dart';
import '../class/viewImageToSent.dart';
import '../class/viewVideoToSent.dart';
import '../../../bottonBar/botonBar.dart';

class GetxAddImageAndVideo extends GetxController {
  final String uid;
  bool isSending = false;
  File? thumbnail;
  String? videoUrl;
  VideoPlayerController? videoController;

  GetxAddImageAndVideo({required this.uid});

  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;

  /// التقاط الصور بالكاميرا أو المعرض
  Future<Uint8List?> _pickImage(ImageSource source) async {
    final ImagePicker imagePicker = ImagePicker();
    final XFile? imageFile = await imagePicker.pickImage(source: source);
    return imageFile?.readAsBytes();
  }

  /// التقاط صورة بالكاميرا
  Future<void> takeCamera() async {
    final Uint8List? img = await _pickImage(ImageSource.camera);
    if (img != null) {
      Get.to(ViewImage(imageData: img, uid: uid));
    }
  }

  /// التقاط صورة من المعرض
  Future<void> takeGallery() async {
    final Uint8List? img = await _pickImage(ImageSource.gallery);
    if (img != null) {
      Get.to(ViewImage(imageData: img, uid: uid));
    }
  }

  /// عرض خيارات التقاط الصور أو الفيديو
  void showMediaOptions(double screenHeight, double screenWidth, BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMediaOption(Icons.image, "صور", () => takeGallery(), screenWidth, screenHeight),
            _buildMediaOption(Icons.video_collection, "فيديو", () => pickVideo(), screenWidth, screenHeight),
            _buildMediaOption(Icons.camera_alt, "كاميرا", () => takeCamera(), screenWidth, screenHeight),
          ],
        );
      },
    );
  }

  /// إنشاء زر خيار الوسائط
  Widget _buildMediaOption(IconData icon, String label, VoidCallback onTap, double screenWidth, double screenHeight) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          SizedBox(height: screenHeight / 40),
          Container(
            width: screenWidth / 5,
            height: screenHeight / 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: Colors.black26,
            ),
            child: Icon(icon, size: screenWidth / 10),
          ),
          Text(label, style: TextStyle(fontSize: screenWidth / 30)),
        ],
      ),
    );
  }

  /// إرسال الصورة إلى Firebase
  Future<void> sendImage(Uint8List imageData, BuildContext context) async {
    try {
      isSending = true;
      update();

      final String messageId = Uuid().v1();
      final Reference storageRef = _firebaseStorage.ref().child("images").child(messageId);
      final UploadTask uploadTask = storageRef.putData(imageData);
      final TaskSnapshot snapshot = await uploadTask;
      final String imageUrl = await snapshot.ref.getDownloadURL();

      await _sendMessage(
        messageId: messageId,
        messageType: 'img',
        messageContent: imageUrl,
        context: context,
      );

      await _sendNotification(
        title: 'لديك صورة جديدة',
        body: 'تم إرسال صورة جديدة إليك',
        imageUrl: imageUrl,
        type:  'image'
      );
    } catch (e) {
      print('Error sending image: $e');
    } finally {
      isSending = false;
      update();
    }
  }

  /// التقاط الفيديو من المعرض
  Future<void> pickVideo() async {
    final ImagePicker imagePicker = ImagePicker();
    final XFile? videoFile = await imagePicker.pickVideo(source: ImageSource.gallery);
    if (videoFile != null) {
      videoUrl = videoFile.path;
      thumbnail = await _getVideoThumbnail(videoUrl!);
      await _initializeVideoController();
      Get.to(ViewVideo(uid: uid, videoURL: videoUrl!));
    }
  }

  /// إنشاء الصور المصغرة للفيديو
  Future<File> _getVideoThumbnail(String videoPath) async {
     var thumbnailPath = await VideoThumbnail.thumbnailFile(
      video: videoPath,
      thumbnailPath: (await getTemporaryDirectory()).path,
      imageFormat: ImageFormat.PNG,
      maxHeight: 128,
      quality: 75,
    );
    File file= File(thumbnailPath.path);
    return file;
  }

  /// تهيئة مشغل الفيديو
  Future<void> _initializeVideoController() async {
    videoController = VideoPlayerController.file(File(videoUrl!));
    await videoController!.initialize();
    videoController!.play();
    update();
  }

    deletVideo(BuildContext context){

    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=>ChatScreen(uid: uid,)), (rute)=>false);
    videoController!.dispose();
    videoUrl = null;
    update();

  }

    playAndSTOP(){
    videoController!.value.isPlaying ?  videoController!.pause(): videoController!.play();
    update();
  }

  /// إرسال الفيديو إلى Firebase
  Future<void> sendVideo(BuildContext context) async {
    try {
      isSending = true;
      update();

      final String messageId = Uuid().v1();
      final Reference videoRef = _firebaseStorage.ref().child("videos").child(messageId);
      final UploadTask videoUploadTask = videoRef.putFile(File(videoUrl!));
      final TaskSnapshot videoSnapshot = await videoUploadTask;
      final String videoDownloadUrl = await videoSnapshot.ref.getDownloadURL();

      final Reference thumbnailRef = _firebaseStorage.ref().child("thumbnails").child(messageId);
      final UploadTask thumbnailUploadTask = thumbnailRef.putFile(thumbnail!);
      final TaskSnapshot thumbnailSnapshot = await thumbnailUploadTask;
      final String thumbnailDownloadUrl = await thumbnailSnapshot.ref.getDownloadURL();

      await _sendMessage(
        messageId: messageId,
        messageType: 'video',
        messageContent: videoDownloadUrl,
        thumbnailUrl: thumbnailDownloadUrl,
        context: context,
      );

      await _sendNotification(
        title: 'لديك رسالة فيديو جديدة',
        body: 'تم إرسال فيديو جديد إليك',
        imageUrl: "thumbnailDownloadUrl",
        type: 'video'
      );
    } catch (e) {
      print('Error sending video: $e');
    } finally {
      isSending = false;
      update();
    }
  }

  /// إرسال الرسالة إلى Firebase
  Future<void> _sendMessage({
    required String messageId,
    required String messageType,
    required String messageContent,
    String? thumbnailUrl,
    required BuildContext context,
  }) async {
    final Map<String, dynamic> messageData = {
      'sender': FirebaseAuth.instance.currentUser!.uid,
      'resiveID': uid,
      'message': messageContent,
      'Thumbnail': thumbnailUrl,
      'type': messageType,
      'time': DateTime.now(),
      'isRead' :false,
      'messageId':messageId
    };
    final Map<String, dynamic> messageData2 = {
      'sender': uid,
      'resiveID': FirebaseAuth.instance.currentUser!.uid,
      'message': messageContent,
      'Thumbnail': thumbnailUrl,
      'type': messageType,
      'time': DateTime.now(),
      'isRead' :false,
      'messageId':messageId
    };




     await FirebaseFirestore.instance.collection('Chat')
          .doc(FirebaseAuth.instance.currentUser!.uid).collection('chat')
          .doc(uid).collection('messages').doc(messageId).set(messageData).
          then((value) => FirebaseFirestore.instance.collection('Chat')
          .doc(FirebaseAuth.instance.currentUser!.uid).collection('chat')
          .doc(uid).set(messageData2));





     await FirebaseFirestore.instance.collection('Chat')
          .doc(uid).collection('chat')
          .doc(FirebaseAuth.instance.currentUser!.uid).collection('messages').doc(messageId).set(messageData)
          .then((value) => FirebaseFirestore.instance.collection('Chat')
          .doc(uid).collection('chat')
          .doc(FirebaseAuth.instance.currentUser!.uid).set(messageData2));


    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => BottomBar(theIndex: 2)),
          (_) => false,
    );
  }

  /// إرسال الإشعار باستخدام Firebase
  Future<void> _sendNotification({
    required String title,
    required String body,
    required String imageUrl,
    required String type,
  }) async {


    try {
            FirebaseFirestore.instance.collection(FirebaseX.collectionApp).doc(FirebaseAuth.instance.currentUser!.uid).get().then((name)async{
        FirebaseFirestore.instance.collection(FirebaseX.collectionApp).doc(uid).get().then((uid)async{
          await LocalNotification.sendNotificationToUser(token: uid.get('token'),title:  name.get('name'),body:  body,uid:  uid.toString(),type:  type,image:  imageUrl);
        } );
      } );

    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  @override
  void onClose() {
    videoController?.dispose();
    super.onClose();
  }
}

