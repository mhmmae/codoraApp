// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// import '../../../TheOrder/ViewOeder/GetX/GetDateToText.dart';
// import 'PlayAudioMessage.dart';
// import 'ViewImageFromChat.dart';
// import 'ViewVideoFromGhat.dart';
//
// class Streamgetmasagelist extends StatelessWidget {
//   Streamgetmasagelist({super.key, required this.uid});
//
//   String uid;
//   int num = 0;
//
//   // AudioPlayer audioPlayer = AudioPlayer();
//   // Duration duration = Duration();
//   // Duration posstion =Duration();
//
//   @override
//   Widget build(BuildContext context) {
//     double hi = MediaQuery.of(context).size.height;
//     double wi = MediaQuery.of(context).size.width;
//     return Expanded(
//       flex: 5,
//       child: Container(
//           width: wi,
//           height: hi / 1.6,
//           color: Colors.white,
//           child: StreamBuilder<QuerySnapshot>(
//             stream: FirebaseFirestore.instance
//                 .collection('Chat')
//                 .doc(FirebaseAuth.instance.currentUser!.uid)
//                 .collection('chat')
//                 .doc(uid)
//                 .collection('messages')
//                 .orderBy('time')
//                 .snapshots(),
//             builder:
//                 (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
//               if (snapshot.hasError) {
//                 return Text('Something went wrong');
//               }
//
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return Text("Loading");
//               }
//
//
//               sss() {
//
//
//                 FirebaseFirestore.instance.collection('Chat').doc(uid ).collection('chat').doc(FirebaseAuth.instance.currentUser!.uid).update({
//                   'isRead': true
//                 });
//                 FirebaseFirestore.instance.collection('Chat').doc(uid)
//                     .collection('chat').doc(
//                     FirebaseAuth.instance.currentUser!.uid)
//                     .collection('messages').where('isRead', isEqualTo: false)
//                     .get()
//                     .then((QuerySnapshot querySnapshot) {
//                   for (var doc in querySnapshot.docs) {
//                     print('23322222222222222221121111111111111111111');
//
//                     FirebaseFirestore.instance.collection('Chat').doc(uid)
//                         .collection('chat').doc(FirebaseAuth.instance
//                         .currentUser!.uid)
//                         .collection('messages').doc(doc['uidMassege'])
//                         .update({
//                       'isRead': true
//                     });
//                   }
//                   print('22222222222222221121111111111111111111');
//                 });
//               }
//
//
//               return ListView.builder(reverse: true,
//
//
//                   itemCount: snapshot.data!.docs.length,
//                   itemBuilder: (context, index) {
//                     DocumentSnapshot data = snapshot.data!.docs[snapshot.data!
//                         .docs.length - (index + 1)];
//                     bool isMe = FirebaseAuth.instance.currentUser!.uid ==
//                         data['sender'];
//
//
//                     sss();
//
//
//                     return data['type'] == 'text' ? Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 8),
//                       child: Align(
//                         alignment:
//                         isMe ? Alignment.centerRight : Alignment.centerLeft,
//                         child: Container(
//                           child: Padding(
//                             padding: isMe
//                                 ? const EdgeInsets.only(
//                                 left: 80, bottom: 4, top: 4)
//                                 : const EdgeInsets.only(
//                                 right: 80, bottom: 4, top: 4),
//                             child: Container(
//                               decoration: BoxDecoration(
//                                   borderRadius: isMe ? const BorderRadius.only(
//                                       topLeft: Radius.circular(10),
//                                       topRight: Radius.circular(0),
//                                       bottomLeft: Radius.circular(10),
//                                       bottomRight: Radius.circular(10)) :
//                                   const BorderRadius.only(
//                                       topLeft: Radius.circular(0),
//                                       topRight: Radius.circular(10),
//                                       bottomLeft: Radius.circular(10),
//                                       bottomRight: Radius.circular(10)),
//                                   color: isMe
//                                       ? Colors.greenAccent
//                                       : Colors.black12),
//                               child: Padding(
//                                 padding: const EdgeInsets.all(8.0),
//                                 child: Column(
//                                   children: [
//                                     Align(
//                                       alignment: isMe
//                                           ? Alignment.topRight
//                                           : Alignment.bottomLeft,
//                                       child: Text(
//                                         data['message'],
//                                         style: TextStyle(fontSize: wi / 30),
//                                       ),
//                                     ),
//                                     Row(
//                                       mainAxisAlignment: isMe
//                                           ? MainAxisAlignment.start
//                                           : MainAxisAlignment.end,
//                                       children: [
//
//
//                                         GetBuilder<GetDateToText>(
//                                             init: GetDateToText(),
//                                             builder: (val) {
//                                               return Text(val.dateTimeToText(
//                                                   data['time']),
//                                                 style: TextStyle(
//                                                     fontSize: wi / 44),);
//                                             }),
//                                         isMe
//                                             ? data['isRead'] == false ? Icon(
//                                             Icons.done_all) : Icon(
//                                           Icons.done_all,
//                                           color: Colors.blueAccent,)
//                                             : Container(),
//
//                                       ],
//                                     )
//
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     )
//
//
//                         : data['type'] == 'video' ? Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 8),
//                       child: Container(
//
//                           child: Padding(padding: isMe
//                               ?  EdgeInsets.only(
//                               left: wi/2, bottom: 4, top: 4)
//                               :  EdgeInsets.only(
//                               right: wi/2, bottom: 4, top: 4),
//
//
//                             child: Container(
//                               decoration: BoxDecoration(
//                                   borderRadius: isMe ? const BorderRadius.only(
//                                       topLeft: Radius.circular(10),
//                                       topRight: Radius.circular(0),
//                                       bottomLeft: Radius.circular(10),
//                                       bottomRight: Radius.circular(10)) :
//                                   const BorderRadius.only(
//                                       topLeft: Radius.circular(0),
//                                       topRight: Radius.circular(10),
//                                       bottomLeft: Radius.circular(10),
//                                       bottomRight: Radius.circular(10)),
//                                   color: isMe
//                                       ? Colors.greenAccent
//                                       : Colors.black12),
//
//
//                               child: Padding(padding: const EdgeInsets.all(8.0),
//                                 child: Column(
//                                   children: [
//
//                                     GestureDetector(
//                                       onTap: () {
//                                         Get.to(ViewVideoFromChat(
//                                           uid: data["sender"],
//                                           videoURL: data["message"],));
//                                       },
//                                       child: Stack(
//                                         children: [
//                                           Container(
//                                             width: wi / 2, height: hi / 3
//                                             , decoration: BoxDecoration(
//                                               borderRadius: BorderRadius
//                                                   .circular(
//                                                   7),
//                                               image: DecorationImage(
//                                                   fit: BoxFit.cover,
//                                                   image: NetworkImage(
//                                                       data["Thumbnail"]))
//                                           ),),
//
//
//                                           Positioned(top: 0,
//                                               left: 0,
//                                               right: 0,
//                                               bottom: 0,
//                                               child: Icon(Icons.play_circle,
//                                                 size: wi / 10,
//                                                 color: Colors.black38,))
//
//                                         ],
//                                       ),
//                                     ),
//
//                                     Row(
//                                       mainAxisAlignment: isMe
//                                           ? MainAxisAlignment.start
//                                           : MainAxisAlignment.end,
//                                       children: [
//
//
//                                         GetBuilder<GetDateToText>(
//                                             init: GetDateToText(),
//                                             builder: (val) {
//                                               return Text(val.dateTimeToText(
//                                                   data['time']),
//                                                 style: TextStyle(
//                                                     fontSize: wi / 44),);
//                                             }),
//                                         isMe
//                                             ? data['isRead'] == false ? Icon(
//                                             Icons.done_all) : Icon(
//                                           Icons.done_all,
//                                           color: Colors.blueAccent,)
//                                             : Container(),
//
//                                       ],
//                                     )
//                                   ],
//                                 )
//                                 ,),
//
//                             ),)
//                       ),
//                     )
//
//
//                         : data['type'] == 'audio' ? Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 8),
//                           child: Container(
//
//                               child: Padding(padding: isMe
//                                   ?  EdgeInsets.only(
//                                   left:wi/7, bottom: 4, top: 4)
//                                   :  EdgeInsets.only(
//                                   right: wi/7, bottom: 4, top: 4),
//
//
//                                 child: Container(
//                                   height: hi/9,width: wi,
//                                   decoration: BoxDecoration(
//                                       borderRadius: isMe ? const BorderRadius
//                                           .only(
//                                           topLeft: Radius.circular(10),
//                                           topRight: Radius.circular(0),
//                                           bottomLeft: Radius.circular(10),
//                                           bottomRight: Radius.circular(10)) :
//                                       const BorderRadius.only(
//                                           topLeft: Radius.circular(0),
//                                           topRight: Radius.circular(10),
//                                           bottomLeft: Radius.circular(10),
//                                           bottomRight: Radius.circular(10)),
//                                       color: isMe
//                                           ? Colors.greenAccent
//                                           : Colors.black12),
//
//
//                                   child: Padding(
//                                     padding: const EdgeInsets.all(2),
//                                     child: Column(
//                                       children: [
//
//                                         VoiceMessageTile(
//                                           urlAudio: data["message"],),
//                                         Row(
//                                           mainAxisAlignment: isMe
//                                               ? MainAxisAlignment.start
//                                               : MainAxisAlignment.end,
//                                           children: [
//
//
//
//                                             GetBuilder<GetDateToText>(
//                                                 init: GetDateToText(),
//                                                 builder: (val) {
//                                                   return Text(
//                                                     val.dateTimeToText(
//                                                         data['time']),
//                                                     style: TextStyle(
//                                                         fontSize: wi / 44),);
//                                                 }),
//                                             isMe
//                                                 ? data['isRead'] == false
//                                                 ? Icon(
//                                                 Icons.done_all)
//                                                 : Icon(
//                                               Icons.done_all,
//                                               color: Colors.blueAccent,)
//                                                 : Container(),
//
//
//                                           ],
//                                         ),
//
//                                       ],
//                                     )
//                                     ,),
//
//                                 ),)
//                           ),
//                         )
//
//
//                         : data['type'] == 'img' ? Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 2),
//                       child: Container(
//
//                           child: Padding(padding: isMe
//                               ?  EdgeInsets.only(
//                               left: wi/2, bottom: 4, top: 4)
//                               :  EdgeInsets.only(
//                               right: wi/2, bottom: 4, top: 4),
//
//
//                             child: Container(
//                               decoration: BoxDecoration(
//                                   borderRadius: isMe ? const BorderRadius.only(
//                                       topLeft: Radius.circular(10),
//                                       topRight: Radius.circular(0),
//                                       bottomLeft: Radius.circular(10),
//                                       bottomRight: Radius.circular(10)) :
//                                   const BorderRadius.only(
//                                       topLeft: Radius.circular(0),
//                                       topRight: Radius.circular(10),
//                                       bottomLeft: Radius.circular(10),
//                                       bottomRight: Radius.circular(10)),
//                                   color: isMe
//                                       ? Colors.greenAccent
//                                       : Colors.black12),
//
//
//                               child: Padding(padding: const EdgeInsets.all(8.0),
//                                 child: Column(
//                                   children: [
//
//                                     GestureDetector(
//                                       onTap: () {
//                                         Get.to(Viewimagefromchat(
//                                           uid: data["sender"],
//                                           uint8list: data["message"],));
//                                       },
//                                       child: Container(
//                                         width: wi / 2, height: hi / 3
//                                         , decoration: BoxDecoration(
//                                           borderRadius: BorderRadius.circular(
//                                               7),
//                                           image: DecorationImage(
//                                               fit: BoxFit.cover,
//                                               image: NetworkImage(
//                                                   data["message"]))
//                                       ),),
//                                     ),
//
//                                     Row(
//                                       mainAxisAlignment: isMe
//                                           ? MainAxisAlignment.start
//                                           : MainAxisAlignment.end,
//                                       children: [
//
//
//                                         GetBuilder<GetDateToText>(
//                                             init: GetDateToText(),
//                                             builder: (val) {
//                                               return Text(val.dateTimeToText(
//                                                   data['time']),
//                                                 style: TextStyle(
//                                                     fontSize: wi / 44),);
//                                             }),
//                                         isMe
//                                             ? data['isRead'] == false ? Icon(
//                                             Icons.done_all) : Icon(
//                                           Icons.done_all,
//                                           color: Colors.blueAccent,)
//                                             : Container(),
//
//                                       ],
//                                     )
//                                   ],
//                                 )
//                                 ,),
//
//                             ),)
//                       ),
//                     ) : Container();
//                   });
//             },
//           )),
//     );
//   }
// }


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../TheOrder/ViewOeder/GetX/GetDateToText.dart';
import 'PlayAudioMessage.dart';
import 'ViewImageFromChat.dart';
import 'ViewVideoFromGhat.dart';

class StreamGetMessageList extends StatelessWidget {
  final String uid;

  StreamGetMessageList({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery
        .of(context)
        .size
        .height;
    final double screenWidth = MediaQuery
        .of(context)
        .size
        .width;

    return Expanded(
      flex: 5,
      child: Container(
        width: screenWidth,
        height: screenHeight / 1.6,
        color: Colors.white,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Chat')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .collection('chat')
              .doc(uid)
              .collection('messages')
              .orderBy('time')
              .snapshots(),
          builder: (BuildContext context,
              AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('حدث خطأ أثناء تحميل الرسائل.'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            return GetBuilder<StreamGGetmasagelist>(init: StreamGGetmasagelist(uid: uid),builder: (logic) {
              return ListView.builder(
                reverse: true,
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final DocumentSnapshot data = snapshot.data!.docs[snapshot
                      .data!.docs.length - (index + 1)];
                  final bool isMe = FirebaseAuth.instance.currentUser!.uid ==
                      data['sender'];

                  return _buildMessageTile(
                      data, isMe, screenWidth, screenHeight);
                },
              );
            });
          },
        ),
      ),
    );
  }

  /// تحديث حالة الرسائل إلى "مقروءة"
  // void markMessagesAsRead() {
  //   FirebaseFirestore.instance
  //       .collection('Chat')
  //       .doc(uid)
  //       .collection('chat')
  //       .doc(FirebaseAuth.instance.currentUser!.uid)
  //       .update({'isRead': true});
  //
  //   FirebaseFirestore.instance
  //       .collection('Chat')
  //       .doc(uid)
  //       .collection('chat')
  //       .doc(FirebaseAuth.instance.currentUser!.uid)
  //       .collection('messages')
  //       .where('isRead', isEqualTo: false)
  //       .get()
  //       .then((QuerySnapshot querySnapshot) {
  //     for (var doc in querySnapshot.docs) {
  //       FirebaseFirestore.instance
  //           .collection('Chat')
  //           .doc(uid)
  //           .collection('chat')
  //           .doc(FirebaseAuth.instance.currentUser!.uid)
  //           .collection('messages')
  //           .doc(doc['uidMassege'])
  //           .update({'isRead': true});
  //     }
  //   });
  // }


  /// إنشاء البلاط الخاص بالرسالة
  Widget _buildMessageTile(DocumentSnapshot data, bool isMe, double screenWidth,
      double screenHeight) {
    switch (data['type']) {
      case 'text':
        return _buildTextMessage(data, isMe, screenWidth);
      case 'video':
        return _buildVideoMessage(data, isMe, screenWidth, screenHeight);
      case 'audio':
        return _buildAudioMessage(data, isMe, screenWidth, screenHeight);
      case 'img':
        return _buildImageMessage(data, isMe, screenWidth, screenHeight);
      default:
        return const SizedBox();
    }
  }

  /// عرض الرسالة النصية
  Widget _buildTextMessage(DocumentSnapshot data, bool isMe,
      double screenWidth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: isMe
              ? EdgeInsets.only(
              left: screenWidth / 7, bottom: 4, top: 4)
              : EdgeInsets.only(
              right: screenWidth / 7, bottom: 4, top: 4),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: isMe
                  ? const BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              )
                  : const BorderRadius.only(
                topRight: Radius.circular(10),
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
              color: isMe ? Colors.greenAccent : Colors.black12,
            ),
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Text(data['message'],
                    style: TextStyle(fontSize: screenWidth / 30)),
                _buildMessageFooter(data, isMe, screenWidth),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// عرض الرسالة الصوتية
  Widget _buildAudioMessage(DocumentSnapshot data, bool isMe,
      double screenWidth, double screenHeight) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: isMe
              ? EdgeInsets.only(
              left: screenWidth / 7, bottom: 4, top: 4)
              : EdgeInsets.only(
              right: screenWidth / 7, bottom: 4, top: 4),
          child: Container(
            height: screenHeight / 9,
            decoration: BoxDecoration(
              borderRadius: isMe
                  ? const BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              )
                  : const BorderRadius.only(
                topRight: Radius.circular(10),
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
              color: isMe ? Colors.greenAccent : Colors.black12,
            ),
            padding: const EdgeInsets.all(2.4),
            child: Column(
              children: [
                VoiceMessageTile(urlAudio: data['message']),
                _buildMessageFooter(data, isMe, screenWidth),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// عرض الرسالة الفيديو
  Widget _buildVideoMessage(DocumentSnapshot data, bool isMe,
      double screenWidth, double screenHeight) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onTap: () =>
              Get.to(ViewVideoFromChat(
                  uid: data['sender'], videoURL: data['message'])),
          child: Padding(
            padding: isMe
                ? EdgeInsets.only(
                left: screenWidth / 7, bottom: 4, top: 4)
                : EdgeInsets.only(
                right: screenWidth / 7, bottom: 4, top: 4),
            child: Container(
              width: screenWidth / 2,
              height: screenHeight / 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: NetworkImage(data['Thumbnail']),
                ),
              ),
              child: const Icon(
                  Icons.play_circle, size: 40, color: Colors.black38),
            ),
          ),
        ),
      ),
    );
  }

  /// عرض الرسالة الصورية
  Widget _buildImageMessage(DocumentSnapshot data, bool isMe,
      double screenWidth, double screenHeight) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onTap: () =>
              Get.to(ViewImageFromChat(
                  uid: data['sender'], imageUrl: data['message'])),
          child: Padding(
            padding: isMe
                ? EdgeInsets.only(
                left: screenWidth / 7, bottom: 4, top: 4)
                : EdgeInsets.only(
                right: screenWidth / 7, bottom: 4, top: 4),
            child: Container(
              width: screenWidth / 2,
              height: screenHeight / 3.5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: NetworkImage(data['message']),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// إضافة تفاصيل الرسالة (مثل الوقت وحالة القراءة)
  Widget _buildMessageFooter(DocumentSnapshot data, bool isMe,
      double screenWidth) {
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: [
        GetBuilder<GetDateToText>(
          init: GetDateToText(),
          builder: (val) =>
              Text(
                val.dateTimeToText(data['time']),
                style: TextStyle(fontSize: screenWidth / 44),
              ),
        ),
        if (isMe)
          Icon(
            Icons.done_all,
            color: data['isRead'] ? Colors.blueAccent : null,
          ),
      ],
    );
  }
}


class StreamGGetmasagelist extends GetxController {
  final String uid;

  StreamGGetmasagelist({required this.uid});

  /// تحديث حالة الرسائل إلى "مقروءة" مع تسجيل وقت التحديث واستخدام العمليات غير المتزامنة بالكامل
  Future<void> markMessagesAsRead() async {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final DocumentReference userChatRef = FirebaseFirestore.instance
        .collection('Chat')
        .doc(uid)
        .collection('chat')
        .doc(currentUserId);

    try {
      // احصل على الوقت الحالي للتحديث
      final DateTime now = DateTime.now();

      // تحديث حالة "isRead" في المحادثة العامة وتسجيل وقت آخر تحديث
      await userChatRef.update({
        'isRead': true,
        'lastReadTime': now.toIso8601String(), // تخزين وقت آخر تحديث
      });

      // جلب الرسائل التي لم يتم قراءتها فقط
      final QuerySnapshot unreadMessages = await userChatRef
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .get();

      if (unreadMessages.docs.isNotEmpty) {
        // إنشاء Batch لتحديث جميع الرسائل غير المقروءة دفعة واحدة
        final WriteBatch batch = FirebaseFirestore.instance.batch();

        for (var doc in unreadMessages.docs) {
          final DocumentReference messageRef = userChatRef
              .collection('messages')
              .doc(doc['uidMassege']);
          batch.update(messageRef, {'isRead': true});
        }

        // تنفيذ التحديث دفعة واحدة
        await batch.commit();

        // سجل نجاح العملية
        print('تم تحديث حالة جميع الرسائل إلى "مقروءة".');
      } else {
        // لا توجد رسائل غير مقروءة
        print('لا توجد رسائل غير مقروءة لتحديثها.');
      }
    } catch (error) {
      // التعامل مع الخطأ
      print('حدث خطأ أثناء تحديث حالة الرسائل: $error');
    }
  }

  @override
  void onInit() {
    markMessagesAsRead();

    // TODO: implement onInit
    super.onInit();
  }
}
