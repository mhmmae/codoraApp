// import 'dart:io';
//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_nav_bar/google_nav_bar.dart';
//
// import '../HomePage/home/home.dart';
// import '../PersonallPage/PersonallPae.dart';
// import '../TheOrder/ViewOeder/Order.dart';
// import '../XXX/XXXFirebase.dart';
// import '../chat/chat1/Chat.dart';
// import '../chat/chatMember/chatMember.dart';
// import '../theـchosen/theـchosen.dart';
// import 'Get2/Get2.dart';
//
//
// class bottonBar extends StatelessWidget {
//   int? theIndex = 0;
//
//   bottonBar({super.key, this.theIndex});
//
//   final Stream<QuerySnapshot> cardItem = FirebaseFirestore.instance
//       .collection('the-chosen').doc(FirebaseAuth.instance.currentUser!.uid).collection(FirebaseX.appName)
//       .snapshots();
//
//   List<Widget> ListOfPage = <Widget>[
//
//
//     Home(),
//     TheChosen(uid: FirebaseX.UIDOfWnerApp),
//     ViewOrder(uid: FirebaseAuth.instance.currentUser!.uid),
//
//     FirebaseAuth.instance.currentUser!.email == FirebaseX.EmailOfWnerApp
//         ? member()
//         : chat(uid: FirebaseX.UIDOfWnerApp),
//
//     const personallPage()
//   ];
//   List<Widget> ListOfPage1 = <Widget>[
//
//
//     Home(),
//     TheChosen(uid: FirebaseX.UIDOfWnerApp),
//     // ViewOeder(),
//
//     FirebaseAuth.instance.currentUser!.email == FirebaseX.EmailOfWnerApp
//         ? member()
//         : chat(uid: FirebaseX.UIDOfWnerApp),
//
//     const personallPage()
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     double hi = MediaQuery.of(context).size.height;
//     double wi = MediaQuery.of(context).size.width;
//     return Scaffold(
//
//
//       bottomNavigationBar:
//
//       GetBuilder<Get2>(init: Get2(), builder: (logic) {
//         return FirebaseAuth.instance.currentUser!.email == FirebaseX.EmailOfWnerApp?SizedBox(
//           height: Platform.isIOS? hi/12 : hi/16,
//           width: wi,
//           child: Column(
//             children: [
//               Container(
//                 child: GNav(selectedIndex: theIndex!,
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     padding: EdgeInsets.all(wi / 60),
//                     iconSize: wi / 17,
//
//                     activeColor: Colors.blueAccent,
//
//
//                     onTabChange: (val) {
//                       theIndex = val;
//                       logic.update();
//                     },
//                     tabs:  [
//                       GButton(icon: Icons.home,iconSize: wi/17,
//                         text: 'home',
//                         textStyle: TextStyle(
//                             fontSize:  Platform.isAndroid? wi / 39:wi/29, color: Colors.blueAccent),),
//                       GButton(icon: Icons.card_travel,
//                         text: 'card',
//                         textStyle: TextStyle(
//                             fontSize:  Platform.isAndroid? wi / 39:wi/29, color: Colors.blueAccent),
//                         leading: Padding(
//                           padding: const EdgeInsets.only(right: 15),
//                           child: StreamBuilder<QuerySnapshot>(
//                             stream: cardItem,
//                             builder: (BuildContext context,
//                                 AsyncSnapshot<QuerySnapshot> snapshot) {
//                               if (snapshot.hasError) {
//                                 return Text('Something went wrong');
//                               }
//
//                               if (snapshot.connectionState ==
//                                   ConnectionState.waiting) {
//                                 return Text('');
//                               }
//
//                               return GestureDetector(
//                                 // onTap: (){
//                                 //   Navigator.push(context, MaterialPageRoute(builder: (context)=> theChosen()));
//                                 // },
//                                 child: Row(children: [
//                                   snapshot.data!.docs.isNotEmpty
//                                       ? Container(
//                                       width: wi / 11,
//                                       height: hi / 23,
//                                       decoration: BoxDecoration(
//                                         color: Colors.blueGrey,
//                                         borderRadius: BorderRadius.circular(15),
//                                       ),
//                                       child: Center(
//                                           child: Badge(
//                                             largeSize: wi / 12,
//                                             child: Icon(
//                                               Icons.card_travel_sharp,
//                                               size: wi / 17,
//                                             ),
//                                           )))
//                                       : Icon(
//                                     Icons.card_travel_sharp,size: wi/17,
//                                   )
//                                 ]),
//                               );
//                             },
//                           ),
//                         ),),
//                      GButton(icon: Icons.add_reaction_outlined,iconSize: wi/17,
//                         text: 'order',
//                         textStyle: TextStyle(
//                             fontSize:  Platform.isAndroid? wi / 39:wi/29, color: Colors.blueAccent),),
//                       GButton(icon: Icons.mail,iconSize: wi/17,
//                         text: 'Messege',
//                         textStyle: TextStyle(
//                             fontSize:  Platform.isAndroid? wi / 39:wi/29, color: Colors.blueAccent),),
//                       GButton(icon: Icons.person,iconSize: wi/17,
//                         text: 'personal page',
//                         textStyle: TextStyle(
//                             fontSize: Platform.isAndroid? wi / 39:wi/29, color: Colors.blueAccent),),
//                     ]),
//               ),
//
//             ],
//           ),
//         ):SizedBox(
//           height: Platform.isIOS? hi/12 : hi/16,
//           width: wi,
//           child: Column(
//             children: [
//               Container(
//                 child: GNav(selectedIndex: theIndex!,
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     padding: EdgeInsets.all(wi / 60),
//                     iconSize: wi / 17,
//
//                     activeColor: Colors.blueAccent,
//
//
//                     onTabChange: (val) {
//                       theIndex = val;
//                       logic.update();
//                     },
//                     tabs:  [
//                       GButton(icon: Icons.home,iconSize: wi/17,
//                         text: 'home',
//                         textStyle: TextStyle(
//                             fontSize:  Platform.isAndroid? wi / 39:wi/29, color: Colors.blueAccent),),
//                       GButton(icon: Icons.card_travel,
//                         text: 'card',
//                         textStyle: TextStyle(
//                             fontSize:  Platform.isAndroid? wi / 39:wi/29, color: Colors.blueAccent),
//                         leading: Padding(
//                           padding: const EdgeInsets.only(right: 15),
//                           child: StreamBuilder<QuerySnapshot>(
//                             stream: cardItem,
//                             builder: (BuildContext context,
//                                 AsyncSnapshot<QuerySnapshot> snapshot) {
//                               if (snapshot.hasError) {
//                                 return Text('Something went wrong');
//                               }
//
//                               if (snapshot.connectionState ==
//                                   ConnectionState.waiting) {
//                                 return Text('');
//                               }
//
//                               return GestureDetector(
//                                 // onTap: (){
//                                 //   Navigator.push(context, MaterialPageRoute(builder: (context)=> theChosen()));
//                                 // },
//                                 child: Row(children: [
//                                   snapshot.data!.docs.isNotEmpty
//                                       ? Container(
//                                       width: wi / 11,
//                                       height: hi / 23,
//                                       decoration: BoxDecoration(
//                                         color: Colors.blueGrey,
//                                         borderRadius: BorderRadius.circular(15),
//                                       ),
//                                       child: Center(
//                                           child: Badge(
//                                             largeSize: wi / 12,
//                                             child: Icon(
//                                               Icons.card_travel_sharp,
//                                               size: wi / 17,
//                                             ),
//                                           )))
//                                       : Icon(
//                                     Icons.card_travel_sharp,size: wi/17,
//                                   )
//                                 ]),
//                               );
//                             },
//                           ),
//                         ),),
//                       // GButton(icon: Icons.add_reaction_outlined,iconSize: wi/17,
//                       //   text: 'order',
//                       //   textStyle: TextStyle(
//                       //       fontSize:  Platform.isAndroid? wi / 39:wi/29, color: Colors.blueAccent),),
//                       GButton(icon: Icons.mail,iconSize: wi/17,
//                         text: 'Messege',
//                         textStyle: TextStyle(
//                             fontSize:  Platform.isAndroid? wi / 39:wi/29, color: Colors.blueAccent),),
//                       GButton(icon: Icons.person,iconSize: wi/17,
//                         text: 'personal page',
//                         textStyle: TextStyle(
//                             fontSize: Platform.isAndroid? wi / 39:wi/29, color: Colors.blueAccent),),
//                     ]),
//               ),
//
//             ],
//           ),
//         );
//       }),
//
//
//       body: GetBuilder<Get2>(init: Get2(),builder: (logic) {
//         return  FirebaseAuth.instance.currentUser!.email == FirebaseX.EmailOfWnerApp? ListOfPage.elementAt(theIndex!):ListOfPage1.elementAt(theIndex!);
//       }),
//
//     );
//   }
// }
//
//
// // ^^^^^^^^^^^^^^^^^
//










import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

import '../HomePage/home/home.dart';
import '../PersonallPage/PersonallPae.dart';
import '../Services/الصفحة الرئيسية/ServicesPage.dart';
import '../TheOrder/ViewOeder/Order.dart';
import '../XXX/XXXFirebase.dart';
import '../aaa.dart';
import '../chat/chat1/Chat.dart';
import '../chat/chatMember/chatMember.dart';
import '../theـchosen/theـchosen.dart';
import 'Get2/Get2.dart';

class BottomBar extends StatelessWidget {
  int? theIndex = 0;

  BottomBar({super.key, this.theIndex});

  final Stream<QuerySnapshot> cardItem = FirebaseFirestore.instance
      .collection('the-chosen')
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .collection(FirebaseX.appName)
      .snapshots();

  final List<Widget> listOfPagesAdmin = <Widget>[
    Home(),
    Servicespage(),
    TheChosen(uid: FirebaseX.UIDOfWnerApp),
    ViewOrder(uid: FirebaseAuth.instance.currentUser!.uid),
    MemberScreen(),
    const personallPage(),
  ];

  final List<Widget> listOfPagesUser = <Widget>[
    Home(),
    Servicespage(),
    TheChosen(uid: FirebaseX.UIDOfWnerApp),
    ChatScreen(uid: FirebaseX.UIDOfWnerApp),
    const personallPage(),
  ];

  @override
  Widget build(BuildContext context) {
    double hi = MediaQuery.of(context).size.height;
    double wi = MediaQuery.of(context).size.width;
    final bool isAdmin = FirebaseAuth.instance.currentUser!.email == FirebaseX.EmailOfWnerApp;

    return Scaffold(
      bottomNavigationBar: GetBuilder<Get2>(
        init: Get2(),
        builder: (logic) {
          return SizedBox(
            height: Platform.isIOS ? hi / 14 : hi / 16,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: isAdmin ? GNav(
                selectedIndex: theIndex!,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                padding: EdgeInsets.symmetric(horizontal: wi / 60, vertical: 10),
                iconSize: wi / 17,
                activeColor: Colors.blueAccent,
                tabBackgroundColor: Colors.blueAccent.withOpacity(0.1),
                color: Colors.grey,
                gap: 8,
                onTabChange: (val) {
                  theIndex = val;
                  logic.update();
                },
                tabs: [
                  GButton(
                    icon: Icons.home,
                    text: 'Home',
                    textStyle: TextStyle(fontSize: wi / 39, color: Colors.blueAccent),
                  ),
                  GButton(
                    icon: Icons.code,
                    text: 'Service',
                    textStyle: TextStyle(fontSize: wi / 39, color: Colors.blueAccent),
                  ),
                  GButton(
                    icon: Icons.card_travel,
                    text: 'Card',
                    textStyle: TextStyle(fontSize: wi / 39, color: Colors.blueAccent),
                    leading: StreamBuilder<QuerySnapshot>(
                      stream: cardItem,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return CircularProgressIndicator(strokeWidth: 2);
                        }
                        if (snapshot.hasError) {
                          return const Icon(Icons.error, color: Colors.red);
                        }
                        return Row(children: [
                                  snapshot.data!.docs.isNotEmpty
                                      ? Container(
                                      width: wi / 11,
                                      height: hi / 23,
                                      decoration: BoxDecoration(
                                        color: Colors.blueGrey,
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Center(
                                          child: Badge(
                                            largeSize: wi / 12,
                                            child: Icon(
                                              Icons.card_travel_sharp,
                                              size: wi / 17,
                                            ),
                                          )))
                                      : Icon(
                                    Icons.card_travel_sharp,size: wi/17,
                                  )
                                ]);
                      },
                    ),
                  ),


                  GButton(icon: Icons.add_reaction_outlined,iconSize: wi/17,
                        text: 'order',
                        textStyle: TextStyle(
                            fontSize:  Platform.isAndroid? wi / 39:wi/29, color: Colors.blueAccent),),





                  GButton(
                    icon: Icons.mail,
                    text: 'Message',
                    textStyle: TextStyle(fontSize: wi / 39, color: Colors.blueAccent),
                  ),
                  GButton(
                    icon: Icons.person,
                    text: 'Profile',
                    textStyle: TextStyle(fontSize: wi / 39, color: Colors.blueAccent),
                  ),
                ],
              ):
              GNav(
                selectedIndex: theIndex!,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                padding: EdgeInsets.symmetric(horizontal: wi / 60, vertical: 10),
                iconSize: wi / 17,
                activeColor: Colors.blueAccent,
                tabBackgroundColor: Colors.blueAccent.withOpacity(0.1),
                color: Colors.grey,
                gap: 8,
                onTabChange: (val) {
                  theIndex = val;
                  logic.update();
                },
                tabs: [
                  GButton(
                    icon: Icons.home,
                    text: 'Home',
                    textStyle: TextStyle(fontSize: wi / 39, color: Colors.blueAccent),
                  ),
                  GButton(
                    icon: Icons.code,
                    text: 'Service',
                    textStyle: TextStyle(fontSize: wi / 39, color: Colors.blueAccent),
                  ),
                  GButton(
                    icon: Icons.card_travel,
                    text: 'Card',
                    textStyle: TextStyle(fontSize: wi / 39, color: Colors.blueAccent),
                    leading: StreamBuilder<QuerySnapshot>(
                      stream: cardItem,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return CircularProgressIndicator(strokeWidth: 2);
                        }
                        if (snapshot.hasError) {
                          return const Icon(Icons.error, color: Colors.red);
                        }
                        return Row(children: [
                          snapshot.data!.docs.isNotEmpty
                              ? Container(
                              width: wi / 11,
                              height: hi / 23,
                              decoration: BoxDecoration(
                                color: Colors.blueGrey,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Center(
                                  child: Badge(
                                    largeSize: wi / 12,
                                    child: Icon(
                                      Icons.card_travel_sharp,
                                      size: wi / 17,
                                    ),
                                  )))
                              : Icon(
                            Icons.card_travel_sharp,size: wi/17,
                          )
                        ]);
                      },
                    ),
                  ),


                  // GButton(icon: Icons.add_reaction_outlined,iconSize: wi/17,
                  //   text: 'order',
                  //   textStyle: TextStyle(
                  //       fontSize:  Platform.isAndroid? wi / 39:wi/29, color: Colors.blueAccent),),





                  GButton(
                    icon: Icons.mail,
                    text: 'Message',
                    textStyle: TextStyle(fontSize: wi / 39, color: Colors.blueAccent),
                  ),
                  GButton(
                    icon: Icons.person,
                    text: 'Profile',
                    textStyle: TextStyle(fontSize: wi / 39, color: Colors.blueAccent),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      body: GetBuilder<Get2>(
        init: Get2(),
        builder: (logic) {
          return IndexedStack(
            index: theIndex!,
            children: isAdmin ? listOfPagesAdmin : listOfPagesUser,
          );
        },
      ),

    );
  }
}
