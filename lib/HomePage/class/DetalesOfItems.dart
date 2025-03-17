import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '../../bottonBar/botonBar.dart';
import '../../chat/chat1/class/ViewImageFromChat.dart';
import '../../chat/chat1/class/ViewVideoFromGhat.dart';
import '../Get-Controllar/GetVideoFromFirebase.dart';
import 'addAndRemoveSearch.dart';

class DetalesOfItems extends StatelessWidget {
  DetalesOfItems(
      {super.key, this.url, required this.images,this.priceOfItem, this.descriptionOfItem, this.nameOfItem, this.uid, required this.isOffer, this.VideoURL,required this.typeItem,required this.rate });

  String? descriptionOfItem;
  String? nameOfItem;
  int? priceOfItem;
  String? url;
  String? uid;
  int number1 = 0;
  int? total1;
  bool isOffer;
  String typeItem;
  int rate;
  List<dynamic> images=[];

  String? VideoURL;


  @override
  Widget build(BuildContext context) {
    double hi = MediaQuery
        .of(context)
        .size
        .height;
    double wi = MediaQuery
        .of(context)
        .size
        .width;
    return Scaffold(
      body: ListView(
        children: [
          SizedBox(height: hi / 120,),
          Row(
            children: [
              SizedBox(width: wi / 30,),
              GetBuilder<GetVideoFromFirebase>(init: GetVideoFromFirebase(VideoURL: VideoURL!),builder: (logic) {
                return GestureDetector(onTap: () async{
                 await logic.videoController!.dispose();
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=>bottonBar(theIndex: 0,)), (rute)=>false);
                }, child: Container(child: Row(
                  children: [
                    Icon(Icons.arrow_back, size: wi / 15,),
                    SizedBox(width: wi / 50,),
                    Text('رجوع'),
                    SizedBox(width: wi / 50,),
                  ],
                )));
              }),


            ],
          ),
          Column(
            children: [
              SizedBox(height: hi / 100),
              Row(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: wi / 50,
                      ),
                      GestureDetector(
                        onTap: (){
                          Navigator.push(context, MaterialPageRoute(builder: (context)=>Viewimagefromchat(uint8list: url!,uid:uid!,)));
                        },
                        child: Container(
                          height: hi / 4,
                          width: wi / 2,
                          decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.black),
                              image: DecorationImage(
                                  fit: BoxFit.cover,
                                  image: NetworkImage(url!))),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: wi / 30,
                  ),
                  Column(
                    children: [
                      Container(
                        width: wi / 2.5,
                        decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.black)),
                        child:

                        Center(
                            child: Text(nameOfItem!,
                                style: TextStyle(fontSize: wi / 30))),


                      ),
                      SizedBox(
                        height: hi / 100,
                      ),
                      Container(
                        width: wi / 2.5,
                        decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.black)),
                        child:
                        Center(
                            child: Text('$priceOfItem',
                                style: TextStyle(fontSize: wi / 30))),

                      ),
                      SizedBox(
                        height: hi / 100,
                      ),
                      typeItem != '' ? Container(
                        width: wi / 2.5,
                        decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.black)),
                        child:

                        Center(
                            child: Text(typeItem,
                                style: TextStyle(fontSize: wi / 30))),

                      ): rate !=0?Container(
                        width: wi / 2.5,
                        decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.black)),
                        child:

                        Center(
                            child: Text('$rate% off',
                                style: TextStyle(fontSize: wi / 30))),

                      )  :Container()
                    ],
                  )
                ],
              ),
            ],
          ),
          VideoURL != 'noVideo' ? Divider():Container(),

          SizedBox(height: hi / 70,),

          VideoURL != 'noVideo' ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: GetBuilder<GetVideoFromFirebase>(
                init: GetVideoFromFirebase(VideoURL: VideoURL!),
                builder: (logic) {
                  return SizedBox(width: wi,
                      height: hi / 2.5,
                      child: logic.videoController!.value.isInitialized ? Stack(
                        children: [
                          GestureDetector(onTap: () {
                            logic.playAndSTOP();
                          },
                            child: Container(width: wi, height: hi / 2.5,
                              decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Colors.black, width: 2),
                                  borderRadius: BorderRadius.circular(6)
                              ),
                              child: AspectRatio(
                                aspectRatio: logic.videoController!.value
                                    .aspectRatio,
                                child: VideoPlayer(logic.videoController!),),
                            ),
                          ),


                          Positioned(
                            top: 30,
                            bottom: 30,
                            left: 30,
                            right: 30,
                            child: logic.videoController!.value.isPlaying
                                ? Container()
                                : Container(height: hi / 20,
                              width: wi / 30,
                              alignment: Alignment.center,
                              child: Container(decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20)),
                                  width: wi / 9,
                                  height: hi / 18,
                                  child: Icon(Icons.play_arrow, size: 30,
                                    color: Colors.black,)),),),

                          Positioned(bottom: 0, right: 0, left: 0,child: VideoProgressIndicator(logic
                              .videoController!, allowScrubbing: true,),),

                          Positioned(right: 5, bottom: 5,child: GestureDetector(
                            onTap:()async{
                              await logic.videoController!.dispose();
                              Navigator.push(context, MaterialPageRoute(builder: (context)=>Viewvideofromghat(uid: uid!,url12: VideoURL!,)));

                            },
                            child: Container(decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(12)
                            ), child: Icon(Icons.fullscreen, size: wi / 11,
                              color: Colors.white,)),
                          ),),

                          GestureDetector(onTap: () {
                            logic.vois();
                          }, child: Container(color: Colors.transparent,
                            width: wi / 8,
                            height: hi / 16,
                            child: logic.valum == 0 ? Icon(
                              Icons.record_voice_over_rounded, size: wi / 10,
                              color: Colors.blue,)
                                : Icon(Icons.voice_over_off, size: wi / 10,
                              color: Colors.blue,),))

                        ],
                      ) : Center(child: CircularProgressIndicator())
                  );
                }),
          ) : Container(),

































          Divider(),
          Container(


            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Text(descriptionOfItem!, style: TextStyle(
                    fontSize: wi / 28
                ),),
              ),
            ),
          ),

          SizedBox(height: hi / 17,),

          Divider(),
          Container(
            width:wi,
            height:hi/6,
            child:ListView.builder(
              itemCount: images.length,
              scrollDirection:Axis.horizontal,
              itemBuilder:(context,index){
                return Padding(
                  padding: const EdgeInsets.all(7),
                  child: GestureDetector(
                    onTap: (){

                      Navigator.push(context, MaterialPageRoute(builder: (context)=>Viewimagefromchat(uint8list: images[index],uid:uid!,)));
                    },
                    child: Container(
                      width: wi/2.5,
                      height: hi/6,

                      decoration: BoxDecoration(
                      image:DecorationImage(
                        image:NetworkImage(images[index]),
                        fit:BoxFit.cover
                      ),
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.black),


                    )
                    )
                  ),
                );

              }
            )
          ),
          Divider(),


          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    addAndRemoveSearch(
                      uidItem: uid!,
                      hi5: hi / 20,
                      wi5: wi / 10,
                      wi4: wi / 20,
                      wi3: wi / 50,
                      wi2: wi / 25,
                      isOfeer: isOffer,),

                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                            builder: (context) => bottonBar(theIndex: 1,)));
                      },
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.black)
                        ),
                        width: wi / 2.7, height: hi / 20,
                        child: Center(child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(Icons.card_travel, size: wi / 20,),

                              Text('اذهب الى العربة',
                                style: TextStyle(fontSize: wi / 40),),
                            ],
                          ),
                        )),
                      ),
                    )


                  ]

              )


          ),
          SizedBox(height: hi / 30,),



        ],
      ),

    );
  }
}
