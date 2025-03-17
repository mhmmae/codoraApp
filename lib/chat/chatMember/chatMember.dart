import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../XXX/XXXFirebase.dart';
import '../../widget/TextFormFiled.dart';
import '../chat1/Chat.dart';

class member extends StatelessWidget {
  member({super.key});

  TextEditingController searchMember = TextEditingController();


  final Stream<QuerySnapshot> _usersStream = FirebaseFirestore.instance
      .collection('Chat')
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .collection('chat')
      .orderBy('time')
      .snapshots();


  Stream<DocumentSnapshot> memberUid(String memberUid) {
    return FirebaseFirestore.instance
        .collection(FirebaseX.collectionApp)
        .doc(memberUid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    double hi = MediaQuery.of(context).size.height;
    double wi = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Container(
                child: Column(
                  children: [
                    SizedBox(
                      height: hi / 15,
                    ),
                    Row(
                      children: [
                        TextFormFiled2(
                            fontSize: wi / 22,
                            controller: searchMember,
                            borderRadius: 15,
                            label: 'Search',
                            obscure: false,
                            wight: wi / 1.3,
                            height: hi / 17)
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: wi,
              height: hi,
              child: StreamBuilder<QuerySnapshot>(
                stream: _usersStream,
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return Text('Something went wrong');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text("Loading");
                  }

                  return ListView(
                    children:
                        snapshot.data!.docs.map((DocumentSnapshot document) {
                      Map<String, dynamic> chat1 =
                          document.data()! as Map<String, dynamic>;
                      return StreamBuilder<DocumentSnapshot>(
                        stream: memberUid(chat1['sender']),
                        builder: (BuildContext context,
                            AsyncSnapshot<DocumentSnapshot> snapshot) {
                          if (snapshot.hasError) {
                            return Text('Something went wrong');
                          }
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Text("Loading");
                          }
                          Map<String, dynamic> user =
                              snapshot.data!.data() as Map<String, dynamic>;
                          if (snapshot.connectionState ==
                              ConnectionState.done) {
                            return Text(
                                "Full Name: ${user['email']} ${user['name']}");
                          }

                          return ListView(
                            shrinkWrap: true,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  FirebaseFirestore.instance.collection('Chat').doc(chat1['sender'] ).collection('chat').doc(FirebaseAuth.instance.currentUser!.uid).update({
                                    'isRead': true
                                  });
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => chat(
                                                uid: chat1['sender'],
                                              )));
                                },
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 1),
                                  child: Container(
                                      decoration: BoxDecoration(
                                          border:
                                              Border.all(color: Colors.black),
                                          color: Colors.black12,
                                          borderRadius:
                                              BorderRadius.circular(5)),
                                      child: Stack(
                                        children:[
                                        ListTile(
                                          leading: Container(
                                            width: wi / 4.8,
                                            height: hi / 13,
                                            decoration: BoxDecoration(
                                                color: Colors.black12,
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                                border: Border.all(
                                                    color: Colors.black,
                                                    width: 1.5),
                                                image: DecorationImage(
                                                    image: NetworkImage(
                                                        user['url']),
                                                    fit: BoxFit.cover)),
                                          ),
                                          title: Text(user['name']),
                                          subtitle: chat1['type']=='text'? Text( chat1['message']):Row(
                                            children: [
                                              Icon(Icons.image),
                                              Text('تم ارسال صورة'),

                                            ],
                                          ),
                                        ),

                                          Positioned(width: wi/27,height: hi/50,right: 0,top: 0,child: BadgeMessege( UidUserSend: chat1['sender'],) ,)

                                          // chat1['isRead'] == false? Positioned(width: wi/27,height: hi/50,child: Badge(largeSize:50 ,),right: 0,top: 0,):Container()
                                      ]
                                      )),
                                ),
                              ),
                              SizedBox(
                                height: hi / 130,
                              )
                            ],
                          );
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

class BadgeMessege extends StatelessWidget {
   BadgeMessege({super.key,required this.UidUserSend});
   Stream<DocumentSnapshot> memberUid(String memberUid) {
     return FirebaseFirestore.instance
         .collection('Chat')
         .doc(memberUid)
         .collection('chat')
         .doc(FirebaseAuth.instance.currentUser!.uid)


         .snapshots();
   }




   String UidUserSend;



   @override
  Widget build(BuildContext context) {
     double hi = MediaQuery.of(context).size.height;
     double wi = MediaQuery.of(context).size.width;
    return StreamBuilder<DocumentSnapshot>(
      stream: memberUid(UidUserSend),
      builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.hasError) {
          return Text('Something went wrong');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text("Loading");
        }
        Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;



        return data['isRead'] == null ?Container(): data['isRead']? Container():Badge(largeSize:50 ,);
      },
    );
  }
}





































