// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import '../../XXX/XXXFirebase.dart';
// import '../../widget/TextFormFiled.dart';
// import '../chat1/Chat.dart';
//
// class member extends StatelessWidget {
//   member({super.key});
//
//   TextEditingController searchMember = TextEditingController();
//
//
//   final Stream<QuerySnapshot> _usersStream = FirebaseFirestore.instance
//       .collection('Chat')
//       .doc(FirebaseAuth.instance.currentUser!.uid)
//       .collection('chat')
//       .orderBy('time')
//       .snapshots();
//
//
//   Stream<DocumentSnapshot> memberUid(String memberUid) {
//     return FirebaseFirestore.instance
//         .collection(FirebaseX.collectionApp)
//         .doc(memberUid)
//         .snapshots();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     double hi = MediaQuery.of(context).size.height;
//     double wi = MediaQuery.of(context).size.width;
//     return Scaffold(
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 15),
//               child: Container(
//                 child: Column(
//                   children: [
//                     SizedBox(
//                       height: hi / 15,
//                     ),
//                     Row(
//                       children: [
//                         TextFormFiled2(
//                             fontSize: wi / 22,
//                             controller: searchMember,
//                             borderRadius: 15,
//                             label: 'Search',
//                             obscure: false,
//                             width: wi / 1.3,
//                             height: hi / 17)
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             SizedBox(
//               width: wi,
//               height: hi,
//               child: StreamBuilder<QuerySnapshot>(
//                 stream: _usersStream,
//                 builder: (BuildContext context,
//                     AsyncSnapshot<QuerySnapshot> snapshot) {
//                   if (snapshot.hasError) {
//                     return Text('Something went wrong');
//                   }
//
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return Text("Loading");
//                   }
//
//                   return ListView(
//                     children:
//                         snapshot.data!.docs.map((DocumentSnapshot document) {
//                       Map<String, dynamic> chat1 =
//                           document.data()! as Map<String, dynamic>;
//                       return StreamBuilder<DocumentSnapshot>(
//                         stream: memberUid(chat1['sender']),
//                         builder: (BuildContext context,
//                             AsyncSnapshot<DocumentSnapshot> snapshot) {
//                           if (snapshot.hasError) {
//                             return Text('Something went wrong');
//                           }
//                           if (snapshot.connectionState ==
//                               ConnectionState.waiting) {
//                             return Text("Loading");
//                           }
//                           Map<String, dynamic> user =
//                               snapshot.data!.data() as Map<String, dynamic>;
//                           if (snapshot.connectionState ==
//                               ConnectionState.done) {
//                             return Text(
//                                 "Full Name: ${user['email']} ${user['name']}");
//                           }
//
//                           return ListView(
//                             shrinkWrap: true,
//                             children: [
//                               GestureDetector(
//                                 onTap: () {
//                                   FirebaseFirestore.instance.collection('Chat').doc(chat1['sender'] ).collection('chat').doc(FirebaseAuth.instance.currentUser!.uid).update({
//                                     'isRead': true
//                                   });
//                                   Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                           builder: (context) => ChatScreen(
//                                                 uid: chat1['sender'],
//                                               )));
//                                 },
//                                 child: Padding(
//                                   padding:
//                                       const EdgeInsets.symmetric(horizontal: 1),
//                                   child: Container(
//                                       decoration: BoxDecoration(
//                                           border:
//                                               Border.all(color: Colors.black),
//                                           color: Colors.black12,
//                                           borderRadius:
//                                               BorderRadius.circular(5)),
//                                       child: Stack(
//                                         children:[
//                                         ListTile(
//                                           leading: Container(
//                                             width: wi / 4.8,
//                                             height: hi / 13,
//                                             decoration: BoxDecoration(
//                                                 color: Colors.black12,
//                                                 borderRadius:
//                                                     BorderRadius.circular(5),
//                                                 border: Border.all(
//                                                     color: Colors.black,
//                                                     width: 1.5),
//                                                 image: DecorationImage(
//                                                     image: NetworkImage(
//                                                         user['url']),
//                                                     fit: BoxFit.cover)),
//                                           ),
//                                           title: Text(user['name']),
//                                           subtitle: chat1['type']=='text'? Text( chat1['message']):Row(
//                                             children: [
//                                               Icon(Icons.image),
//                                               Text('تم ارسال صورة'),
//
//                                             ],
//                                           ),
//                                         ),
//
//                                           Positioned(width: wi/27,height: hi/50,right: 0,top: 0,child: BadgeMessege( UidUserSend: chat1['sender'],) ,)
//
//                                           // chat1['isRead'] == false? Positioned(width: wi/27,height: hi/50,child: Badge(largeSize:50 ,),right: 0,top: 0,):Container()
//                                       ]
//                                       )),
//                                 ),
//                               ),
//                               SizedBox(
//                                 height: hi / 130,
//                               )
//                             ],
//                           );
//                         },
//                       );
//                     }).toList(),
//                   );
//                 },
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class BadgeMessege extends StatelessWidget {
//    BadgeMessege({super.key,required this.UidUserSend});
//    Stream<DocumentSnapshot> memberUid(String memberUid) {
//      return FirebaseFirestore.instance
//          .collection('Chat')
//          .doc(memberUid)
//          .collection('chat')
//          .doc(FirebaseAuth.instance.currentUser!.uid)
//
//
//          .snapshots();
//    }
//
//
//
//
//    String UidUserSend;
//
//
//
//    @override
//   Widget build(BuildContext context) {
//      double hi = MediaQuery.of(context).size.height;
//      double wi = MediaQuery.of(context).size.width;
//     return StreamBuilder<DocumentSnapshot>(
//       stream: memberUid(UidUserSend),
//       builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
//         if (snapshot.hasError) {
//           return Text('Something went wrong');
//         }
//
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Text("Loading");
//         }
//         Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;
//
//
//
//         return data['isRead'] == null ?Container(): data['isRead']? Container():Badge(largeSize:50 ,);
//       },
//     );
//   }
// }



















import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../XXX/XXXFirebase.dart';
import '../../widget/TextFormFiled.dart';
import '../chat1/Chat.dart';

class MemberScreen extends StatelessWidget {
  MemberScreen({super.key});

  final TextEditingController searchMember = TextEditingController();

  final Stream<QuerySnapshot> usersStream = FirebaseFirestore.instance
      .collection('Chat')
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .collection('chat')
      .orderBy('time', descending: true)
      .snapshots();

  /// جلب بيانات المستخدم
  Stream<DocumentSnapshot> memberDataStream(String memberUid) {
    return FirebaseFirestore.instance
        .collection(FirebaseX.collectionApp)
        .doc(memberUid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الأعضاء',style: TextStyle(color: Colors.black54),),

      ),
      body: Column(
        children: [
          _buildSearchBar(screenHeight, screenWidth),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: usersStream,
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('حدث خطأ أثناء تحميل البيانات.'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('لا توجد محادثات متاحة.'));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final Map<String, dynamic> chatData =
                    snapshot.data!.docs[index].data()! as Map<String, dynamic>;

                    return StreamBuilder<DocumentSnapshot>(
                      stream: memberDataStream(chatData['sender']),
                      builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> userSnapshot) {
                        if (userSnapshot.hasError) {
                          return const Center(child: Text('حدث خطأ أثناء تحميل بيانات المستخدم.'));
                        }

                        if (userSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                          return const SizedBox(); // إذا لم توجد بيانات المستخدم
                        }

                        final Map<String, dynamic> userData =
                        userSnapshot.data!.data()! as Map<String, dynamic>;

                        return _buildChatTile(
                          context,
                          chatData,
                          userData,
                          screenHeight,
                          screenWidth,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// شريط البحث
  Widget _buildSearchBar(double screenHeight, double screenWidth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 15),
        child: TextFormFiled2(
          fontSize: screenWidth / 22,
          controller: searchMember,
          borderRadius: 15,
          label: 'ابحث عن عضو',
          obscure: false,
          width: screenWidth / 1.3,
          height: screenHeight / 17,
        ),
      ),
    );
  }

  /// بطاقة المحادثة
  Widget _buildChatTile(
      BuildContext context,
      Map<String, dynamic> chatData,
      Map<String, dynamic> userData,
      double screenHeight,
      double screenWidth,
      ) {
    return GestureDetector(
      onTap: () {
        FirebaseFirestore.instance
            .collection('Chat')
            .doc(chatData['sender'])
            .collection('chat')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .update({'isRead': true});

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(uid: chatData['sender']),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black, width: 1.5),
          ),
          child: Stack(
            children: [
              ListTile(
                leading: _buildUserAvatar(userData['url'], screenWidth, screenHeight),
                title: Text(userData['name'], style: TextStyle(fontSize: screenWidth / 22)),
                subtitle: chatData['type'] == 'text'
                    ? Text(chatData['message'], style: TextStyle(fontSize: screenWidth / 24))
                    : Row(
                  children: [
                    const Icon(Icons.image, size: 16),
                    const SizedBox(width: 8),
                    Text('تم إرسال صورة', style: TextStyle(fontSize: screenWidth / 24)),
                  ],
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: BadgeMessage(UidUserSend: chatData['sender']),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// صورة المستخدم
  Widget _buildUserAvatar(String imageUrl, double screenWidth, double screenHeight) {
    return Container(
      width: screenWidth / 6,
      height: screenHeight / 11,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black, width: 1.5),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class BadgeMessage extends StatelessWidget {
  final String UidUserSend;

  BadgeMessage({super.key, required this.UidUserSend});

  Stream<DocumentSnapshot> memberUid(String memberUid) {
    return FirebaseFirestore.instance
        .collection('Chat')
        .doc(memberUid)
        .collection('chat')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: memberUid(UidUserSend),
      builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox();
        }

        final Map<String, dynamic> data = snapshot.data!.data()! as Map<String, dynamic>;
        return data['isRead'] == null || data['isRead']
            ? const SizedBox()
            : const Icon(Icons.circle, color: Colors.red, size: 16); // شارة الرسالة غير المقروءة
      },
    );
  }
}


































