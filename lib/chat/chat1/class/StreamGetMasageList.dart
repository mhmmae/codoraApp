import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../TheOrder/ViewOeder/GetX/GetDateToText.dart';
import 'PlayAudioMessage.dart';
import 'ViewImageFromChat.dart';
import 'ViewVideoFromGhat.dart';

class Streamgetmasagelist extends StatelessWidget {
  Streamgetmasagelist({super.key, required this.uid});

  String uid;
  int num = 0;

  // AudioPlayer audioPlayer = AudioPlayer();
  // Duration duration = Duration();
  // Duration posstion =Duration();

  @override
  Widget build(BuildContext context) {
    double hi = MediaQuery.of(context).size.height;
    double wi = MediaQuery.of(context).size.width;
    return Expanded(
      flex: 5,
      child: Container(
          width: wi,
          height: hi / 1.6,
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
            builder:
                (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasError) {
                return Text('Something went wrong');
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return Text("Loading");
              }


              sss() {


                FirebaseFirestore.instance.collection('Chat').doc(uid ).collection('chat').doc(FirebaseAuth.instance.currentUser!.uid).update({
                  'isRead': true
                });
                FirebaseFirestore.instance.collection('Chat').doc(uid)
                    .collection('chat').doc(
                    FirebaseAuth.instance.currentUser!.uid)
                    .collection('messages').where('isRead', isEqualTo: false)
                    .get()
                    .then((QuerySnapshot querySnapshot) {
                  for (var doc in querySnapshot.docs) {
                    print('23322222222222222221121111111111111111111');

                    FirebaseFirestore.instance.collection('Chat').doc(uid)
                        .collection('chat').doc(FirebaseAuth.instance
                        .currentUser!.uid)
                        .collection('messages').doc(doc['uidMassege'])
                        .update({
                      'isRead': true
                    });
                  }
                  print('22222222222222221121111111111111111111');
                });
              }


              return ListView.builder(reverse: true,


                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot data = snapshot.data!.docs[snapshot.data!
                        .docs.length - (index + 1)];
                    bool isMe = FirebaseAuth.instance.currentUser!.uid ==
                        data['sender'];


                    sss();


                    return data['type'] == 'text' ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Align(
                        alignment:
                        isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          child: Padding(
                            padding: isMe
                                ? const EdgeInsets.only(
                                left: 80, bottom: 4, top: 4)
                                : const EdgeInsets.only(
                                right: 80, bottom: 4, top: 4),
                            child: Container(
                              decoration: BoxDecoration(
                                  borderRadius: isMe ? const BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                      topRight: Radius.circular(0),
                                      bottomLeft: Radius.circular(10),
                                      bottomRight: Radius.circular(10)) :
                                  const BorderRadius.only(
                                      topLeft: Radius.circular(0),
                                      topRight: Radius.circular(10),
                                      bottomLeft: Radius.circular(10),
                                      bottomRight: Radius.circular(10)),
                                  color: isMe
                                      ? Colors.greenAccent
                                      : Colors.black12),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    Align(
                                      alignment: isMe
                                          ? Alignment.topRight
                                          : Alignment.bottomLeft,
                                      child: Text(
                                        data['message'],
                                        style: TextStyle(fontSize: wi / 30),
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment: isMe
                                          ? MainAxisAlignment.start
                                          : MainAxisAlignment.end,
                                      children: [


                                        GetBuilder<Getdatetotext>(
                                            init: Getdatetotext(),
                                            builder: (val) {
                                              return Text(val.dateTimeToText(
                                                  data['time']),
                                                style: TextStyle(
                                                    fontSize: wi / 44),);
                                            }),
                                        isMe
                                            ? data['isRead'] == false ? Icon(
                                            Icons.done_all) : Icon(
                                          Icons.done_all,
                                          color: Colors.blueAccent,)
                                            : Container(),

                                      ],
                                    )

                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    )


                        : data['type'] == 'video' ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Container(

                          child: Padding(padding: isMe
                              ?  EdgeInsets.only(
                              left: wi/2, bottom: 4, top: 4)
                              :  EdgeInsets.only(
                              right: wi/2, bottom: 4, top: 4),


                            child: Container(
                              decoration: BoxDecoration(
                                  borderRadius: isMe ? const BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                      topRight: Radius.circular(0),
                                      bottomLeft: Radius.circular(10),
                                      bottomRight: Radius.circular(10)) :
                                  const BorderRadius.only(
                                      topLeft: Radius.circular(0),
                                      topRight: Radius.circular(10),
                                      bottomLeft: Radius.circular(10),
                                      bottomRight: Radius.circular(10)),
                                  color: isMe
                                      ? Colors.greenAccent
                                      : Colors.black12),


                              child: Padding(padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [

                                    GestureDetector(
                                      onTap: () {
                                        Get.to(Viewvideofromghat(
                                          uid: data["sender"],
                                          url12: data["message"],));
                                      },
                                      child: Stack(
                                        children: [
                                          Container(
                                            width: wi / 2, height: hi / 3
                                            , decoration: BoxDecoration(
                                              borderRadius: BorderRadius
                                                  .circular(
                                                  7),
                                              image: DecorationImage(
                                                  fit: BoxFit.cover,
                                                  image: NetworkImage(
                                                      data["Thumbnail"]))
                                          ),),


                                          Positioned(top: 0,
                                              left: 0,
                                              right: 0,
                                              bottom: 0,
                                              child: Icon(Icons.play_circle,
                                                size: wi / 10,
                                                color: Colors.black38,))

                                        ],
                                      ),
                                    ),

                                    Row(
                                      mainAxisAlignment: isMe
                                          ? MainAxisAlignment.start
                                          : MainAxisAlignment.end,
                                      children: [


                                        GetBuilder<Getdatetotext>(
                                            init: Getdatetotext(),
                                            builder: (val) {
                                              return Text(val.dateTimeToText(
                                                  data['time']),
                                                style: TextStyle(
                                                    fontSize: wi / 44),);
                                            }),
                                        isMe
                                            ? data['isRead'] == false ? Icon(
                                            Icons.done_all) : Icon(
                                          Icons.done_all,
                                          color: Colors.blueAccent,)
                                            : Container(),

                                      ],
                                    )
                                  ],
                                )
                                ,),

                            ),)
                      ),
                    )


                        : data['type'] == 'audio' ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Container(

                              child: Padding(padding: isMe
                                  ?  EdgeInsets.only(
                                  left:wi/7, bottom: 4, top: 4)
                                  :  EdgeInsets.only(
                                  right: wi/7, bottom: 4, top: 4),


                                child: Container(
                                  height: hi/9,width: wi,
                                  decoration: BoxDecoration(
                                      borderRadius: isMe ? const BorderRadius
                                          .only(
                                          topLeft: Radius.circular(10),
                                          topRight: Radius.circular(0),
                                          bottomLeft: Radius.circular(10),
                                          bottomRight: Radius.circular(10)) :
                                      const BorderRadius.only(
                                          topLeft: Radius.circular(0),
                                          topRight: Radius.circular(10),
                                          bottomLeft: Radius.circular(10),
                                          bottomRight: Radius.circular(10)),
                                      color: isMe
                                          ? Colors.greenAccent
                                          : Colors.black12),


                                  child: Padding(
                                    padding: const EdgeInsets.all(2),
                                    child: Column(
                                      children: [

                                        VoiceMessageTile(
                                          urlAudio: data["message"],),
                                        Row(
                                          mainAxisAlignment: isMe
                                              ? MainAxisAlignment.start
                                              : MainAxisAlignment.end,
                                          children: [



                                            GetBuilder<Getdatetotext>(
                                                init: Getdatetotext(),
                                                builder: (val) {
                                                  return Text(
                                                    val.dateTimeToText(
                                                        data['time']),
                                                    style: TextStyle(
                                                        fontSize: wi / 44),);
                                                }),
                                            isMe
                                                ? data['isRead'] == false
                                                ? Icon(
                                                Icons.done_all)
                                                : Icon(
                                              Icons.done_all,
                                              color: Colors.blueAccent,)
                                                : Container(),


                                          ],
                                        ),

                                      ],
                                    )
                                    ,),

                                ),)
                          ),
                        )


                        : data['type'] == 'img' ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Container(

                          child: Padding(padding: isMe
                              ?  EdgeInsets.only(
                              left: wi/2, bottom: 4, top: 4)
                              :  EdgeInsets.only(
                              right: wi/2, bottom: 4, top: 4),


                            child: Container(
                              decoration: BoxDecoration(
                                  borderRadius: isMe ? const BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                      topRight: Radius.circular(0),
                                      bottomLeft: Radius.circular(10),
                                      bottomRight: Radius.circular(10)) :
                                  const BorderRadius.only(
                                      topLeft: Radius.circular(0),
                                      topRight: Radius.circular(10),
                                      bottomLeft: Radius.circular(10),
                                      bottomRight: Radius.circular(10)),
                                  color: isMe
                                      ? Colors.greenAccent
                                      : Colors.black12),


                              child: Padding(padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [

                                    GestureDetector(
                                      onTap: () {
                                        Get.to(Viewimagefromchat(
                                          uid: data["sender"],
                                          uint8list: data["message"],));
                                      },
                                      child: Container(
                                        width: wi / 2, height: hi / 3
                                        , decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                              7),
                                          image: DecorationImage(
                                              fit: BoxFit.cover,
                                              image: NetworkImage(
                                                  data["message"]))
                                      ),),
                                    ),

                                    Row(
                                      mainAxisAlignment: isMe
                                          ? MainAxisAlignment.start
                                          : MainAxisAlignment.end,
                                      children: [


                                        GetBuilder<Getdatetotext>(
                                            init: Getdatetotext(),
                                            builder: (val) {
                                              return Text(val.dateTimeToText(
                                                  data['time']),
                                                style: TextStyle(
                                                    fontSize: wi / 44),);
                                            }),
                                        isMe
                                            ? data['isRead'] == false ? Icon(
                                            Icons.done_all) : Icon(
                                          Icons.done_all,
                                          color: Colors.blueAccent,)
                                            : Container(),

                                      ],
                                    )
                                  ],
                                )
                                ,),

                            ),)
                      ),
                    ) : Container();
                  });
            },
          )),
    );
  }
}
