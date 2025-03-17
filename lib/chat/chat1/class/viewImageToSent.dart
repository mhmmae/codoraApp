import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../bottonBar/botonBar.dart';
import '../Getx/GetXaddImageAndVideo.dart';

class Viewimage extends StatelessWidget {
  Viewimage({super.key,
    required this.uint8list,
    required this.uid,
  });

  Uint8List uint8list;
  String uid;

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
        body: Stack(
          children: [

            Container(
              decoration: BoxDecoration(
                  image: DecorationImage(
                      fit: BoxFit.fill,
                      image: MemoryImage(
                        uint8list,
                      ))),
            ),
            GetBuilder<GetxAddImageAndVideo>( init: GetxAddImageAndVideo(uid: uid),builder: (logic) {
              return Positioned(
                  bottom: hi / 45,
                  right: wi / 25,
                  child: GestureDetector(
                      onTap: () {
                        logic.sendImageInGhat(uint8list, context);
                        // val.update();

                      },
                      child: logic.isSend
                          ? CircularProgressIndicator(strokeWidth: 10,)
                          : Container(
                          height: hi / 17,
                          width: wi / 8.5,
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.black, width: 2),
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(100)),
                          child: Icon(
                            Icons.send,
                            size: wi / 17,
                            color: Colors.black,
                          )),
                    )
                  );
            }),
            Positioned(
                top: hi / 35,
                right: wi / 27,
                child: GestureDetector(onTap: () {
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=>bottonBar(theIndex: 2,)), (rute)=>false);
                },
                  child: Container(
                      height: hi / 17,
                      width: wi / 8.5,
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 2),
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(100)),
                      child: Icon(
                        Icons.cancel,
                        size: wi / 12.5,
                        color: Colors.white,
                      )),
                )),


          ],


        )
    );
  }
}
