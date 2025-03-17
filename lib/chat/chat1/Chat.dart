import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../XXX/XXXFirebase.dart';
import '../../bottonBar/botonBar.dart';
import 'class/FuctionOfMasageSendAndWhrit.dart';
import 'class/StreamGetMasageList.dart';


class chat extends StatelessWidget {
  chat({super.key,required this.uid});


  TextEditingController Maseage= TextEditingController();
  String uid;


  @override
  Widget build(BuildContext context) {

    double hi = MediaQuery.of(context).size.height;
    double wi = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 1,


        actions: [ GestureDetector(onTap: ()async{
        },
          child: Padding(
            padding: const EdgeInsets.only(right: 13),
            child: Container(width: wi/10,height: wi/10,
              decoration: BoxDecoration(
                  color: Colors.white70,
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(16)
              ),child: Icon(Icons.call),),
          ),
        )],
        leadingWidth: wi/2,
        leading:Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 10),
          child: Row(
            children: [
              FirebaseAuth.instance.currentUser!.email ==FirebaseX.EmailOfWnerApp?
              GestureDetector(onTap: (){
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=>bottonBar(theIndex: 3,)), (rute)=>false);

              },child: SizedBox(width: wi/7,height: hi/18,child: Icon(Icons.arrow_back,size: wi/10,))):const SizedBox(width: 0.0001,),
              SizedBox(width: wi/30,),
              Text(FirebaseX.appName,style: TextStyle(fontSize: wi/25,color: Colors.black,fontWeight: FontWeight.w800),),
            ],
          ),
        ) ,
      ),


      // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
      // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
      // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


      body:
      // Stack(
      //   children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
              // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
              // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^



              Streamgetmasagelist(uid: uid,),



              // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
              // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
              // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
              // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


              Fuctionofmasagesendandwhrit(Maseage: Maseage,uid: uid,),







            ],
          ),

          // GetBuilder<Getxsendmassage>(init: Getxsendmassage(Maseage: Maseage, uid: uid),builder: (val){
          //   return val.isRecord ==true? Positioned(bottom: hi/14,right: wi/40,child: Container(width: wi/5,height: hi/20,decoration: BoxDecoration(
          //     color: Colors.redAccent,
          //     borderRadius: BorderRadius.circular(7)
          //   ),
          //     child: Center(child: Row(
          //       mainAxisAlignment: MainAxisAlignment.center,
          //       children: [
          //         Text('${val.minut}',style: TextStyle(color: Colors.white70),),
          //         Text(':',style: TextStyle(color: Colors.white70),),
          //
          //         Text('${val.second}',style: TextStyle(color: Colors.white70),),
          //       ],
          //     )),
          //   )): Container() ;
          //
          // }),
          // GetBuilder<Getxsendmassage>(init: Getxsendmassage(Maseage: Maseage, uid: uid),builder: (val){
          //   return  val.isdelete == true ? Positioned(bottom: hi/14,right: wi/1.9,child: Container(width: wi/5,height: hi/20,decoration: BoxDecoration(
          //       color: Colors.black45,
          //       borderRadius: BorderRadius.circular(7)
          //   ),
          //     child: Center(child:Icon(Icons.delete_forever,color: Colors.redAccent,size: wi/15,)),
          //   )): Container() ;
          //
          // })
      //
      //   ],
      // ),

    );
  }
}
