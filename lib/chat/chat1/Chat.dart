// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// import '../../XXX/XXXFirebase.dart';
// import '../../bottonBar/botonBar.dart';
// import 'Getx/GetxSendMassage.dart';
// import 'class/FuctionOfMasageSendAndWhrit.dart';
// import 'class/StreamGetMasageList.dart';
//
//
// class chat extends StatelessWidget {
//   chat({super.key,required this.uid});
//
//
//   TextEditingController Maseage= TextEditingController();
//   String uid;
//
//
//   @override
//   Widget build(BuildContext context) {
//
//     double hi = MediaQuery.of(context).size.height;
//     double wi = MediaQuery.of(context).size.width;
//     return Scaffold(
//       backgroundColor: Colors.white,
//       extendBodyBehindAppBar: true,
//       appBar: AppBar(
//         elevation: 1,
//
//
//         actions: [ GestureDetector(onTap: ()async{
//         },
//           child: Padding(
//             padding: const EdgeInsets.only(right: 13),
//             child: Container(width: wi/10,height: wi/10,
//               decoration: BoxDecoration(
//                   color: Colors.white70,
//                   border: Border.all(color: Colors.black),
//                   borderRadius: BorderRadius.circular(16)
//               ),child: Icon(Icons.call),),
//           ),
//         )],
//         leadingWidth: wi/2,
//         leading:Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 10),
//           child: Row(
//             children: [
//               FirebaseAuth.instance.currentUser!.email ==FirebaseX.EmailOfWnerApp?
//               GestureDetector(onTap: (){
//                 Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=>BottomBar(theIndex: 3,)), (rute)=>false);
//
//               },child: SizedBox(width: wi/7,height: hi/18,child: Icon(Icons.arrow_back,size: wi/10,))):const SizedBox(width: 0.0001,),
//               SizedBox(width: wi/30,),
//               Text(FirebaseX.appName,style: TextStyle(fontSize: wi/25,color: Colors.black,fontWeight: FontWeight.w800),),
//             ],
//           ),
//         ) ,
//       ),
//
//
//       // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//       // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//       // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//
//
//       body:
//       Stack(
//         children: [
//           Column(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//
//               // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//               // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//               // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//
//
//
//               Streamgetmasagelist(uid: uid,),
//
//
//
//               // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//               // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//               // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//               // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//
//
//               Fuctionofmasagesendandwhrit(Maseage: Maseage,uid: uid,),
//
//
//
//
//
//
//
//             ],
//           ),
//
//           GetBuilder<Getxsendmassage>(init: Getxsendmassage(Maseage: Maseage, uid: uid),builder: (val){
//             return val.isRecord ==true? Positioned(bottom: hi/14,right: wi/40,child: Container(width: wi/5,height: hi/20,decoration: BoxDecoration(
//               color: Colors.redAccent,
//               borderRadius: BorderRadius.circular(7)
//             ),
//               child: Center(child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text('${val.minut}',style: TextStyle(color: Colors.white70),),
//                   Text(':',style: TextStyle(color: Colors.white70),),
//
//                   Text('${val.second}',style: TextStyle(color: Colors.white70),),
//                 ],
//               )),
//             )): Container() ;
//
//           }),
//           GetBuilder<Getxsendmassage>(init: Getxsendmassage(Maseage: Maseage, uid: uid),builder: (val){
//             return  val.isdelete == true ? Positioned(bottom: hi/14,right: wi/1.9,child: Container(width: wi/5,height: hi/20,decoration: BoxDecoration(
//                 color: Colors.black45,
//                 borderRadius: BorderRadius.circular(7)
//             ),
//               child: Center(child:Icon(Icons.delete_forever,color: Colors.redAccent,size: wi/15,)),
//             )): Container() ;
//
//           })
//
//         ],
//       ),
//
//     );
//   }
// }





































import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../XXX/XXXFirebase.dart';
import '../../bottonBar/botonBar.dart';
import 'Getx/GetxSendMassage.dart';
import 'class/FuctionOfMasageSendAndWhrit.dart';
import 'class/StreamGetMasageList.dart';

class ChatScreen extends StatelessWidget {
  ChatScreen({super.key, required this.uid});

  final TextEditingController messageController = TextEditingController(); // متحكم في النص
  final String uid; // معرف المستخدم الحالي

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context, screenWidth, screenHeight),
      body: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // عرض قائمة الرسائل
              StreamGetMessageList(uid: uid),

              // واجهة إرسال الرسائل
              FunctionOfMessagesSendAndWrite(
                messageController: messageController,
                uid: uid,
              ),
            ],
          ),

          // عرض واجهة التسجيل (Recording)
          GetBuilder<GetxSendMessage>(
            init: GetxSendMessage(messageController: messageController, uid: uid),
            builder: (logic) {
              return logic.isRecord
                  ? Positioned(
                bottom: screenHeight / 14,
                right: screenWidth / 40,
                child: _buildRecordingContainer(logic, screenWidth, screenHeight),
              )
                  : Container();
            },
          ),

          // عرض واجهة الحذف (Delete)
          GetBuilder<GetxSendMessage>(
            init: GetxSendMessage(messageController: messageController, uid: uid),
            builder: (logic) {
              return logic.isDelete == true
                  ? Positioned(
                bottom: screenHeight / 14,
                right: screenWidth / 2,
                child: _buildDeleteContainer(screenWidth, screenHeight),
              )
                  : Container();
            },
          ),
        ],
      ),
    );
  }

  /// إنشاء AppBar
  AppBar _buildAppBar(BuildContext context, double screenWidth, double screenHeight) {
    return AppBar(
      elevation: 1,
      actions: [
        GestureDetector(
          onTap: () async {
            // يمكنك إضافة منطق آخر هنا لإجراء المكالمات
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 13),
            child: Container(
              width: screenWidth / 10,
              height: screenWidth / 10,
              decoration: BoxDecoration(
                color: Colors.white70,
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.call),
            ),
          ),
        ),
      ],
      leadingWidth: screenWidth / 2,
      leading: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            FirebaseAuth.instance.currentUser!.email == FirebaseX.EmailOfWnerApp
                ? GestureDetector(
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => BottomBar(theIndex: 3)),
                      (route) => false,
                );
              },
              child: SizedBox(
                width: screenWidth / 7,
                height: screenHeight / 18,
                child: Icon(Icons.arrow_back, size: screenWidth / 10),
              ),
            )
                : const SizedBox(width: 0.0001),
            SizedBox(width: screenWidth / 30),
            Text(
              FirebaseX.appName,
              style: TextStyle(
                fontSize: screenWidth / 25,
                color: Colors.black,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// واجهة تسجيل الرسائل الصوتية
  Widget _buildRecordingContainer(GetxSendMessage logic, double screenWidth, double screenHeight) {
    return Container(
      width: screenWidth / 5,
      height: screenHeight / 20,
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${logic.minutes}', style: const TextStyle(color: Colors.white70)),
            const Text(':', style: TextStyle(color: Colors.white70)),
            Text('${logic.seconds}', style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  /// واجهة حذف الرسائل
  Widget _buildDeleteContainer(double screenWidth, double screenHeight) {
    return Container(
      width: screenWidth / 5,
      height: screenHeight / 20,
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Center(
        child: Icon(
          Icons.delete_forever,
          color: Colors.redAccent,
          size: screenWidth / 15,
        ),
      ),
    );
  }
}
