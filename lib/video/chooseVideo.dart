import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '../XXX/XXXFirebase.dart';
import 'Getx/GetChooseVideo.dart';

class Choosevideo extends StatelessWidget {
  const Choosevideo({super.key});


  @override
  Widget build(BuildContext context) {
    double hi = MediaQuery.of(context).size.height;
    double wi = MediaQuery.of(context).size.width;
    return GetBuilder<Getchoosevideo>(init: Getchoosevideo(),builder: (logic) {
      return logic.url != null
            ?
        logic.videoController!.value.isInitialized ? Stack(
          children: [
            GestureDetector(onTap: (){
              logic.playAndSTOP();
            },
              child: Container(width: wi,height: hi/2,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black,width: 2),
                  borderRadius: BorderRadius.circular(6)
                ),
                child: AspectRatio(
                  aspectRatio: logic.videoController!.value.aspectRatio,
                  child: VideoPlayer(logic.videoController!),),
              ),
            ),



            Positioned(top: 30,bottom: 30,left: 30,right: 30,child: logic.videoController!.value.isPlaying ?Container()
                :Container(height: hi/20,width: wi/30,alignment: Alignment.center,child: Container(decoration: BoxDecoration(color: Colors.white,borderRadius: BorderRadius.circular(20)),width: wi/9,height: hi/18,child: Icon(Icons.play_arrow,size: 30,color: Colors.black,)),),),

            Positioned(bottom: 0,right: 0,left: 0,child: VideoProgressIndicator(logic.videoController!,allowScrubbing: true,),),

            GestureDetector(onTap: (){logic.deletVideo();},child: Container(color: Colors.transparent,width: wi/8,height: hi/16,child: Icon(Icons.dangerous,size: wi/10,color: Colors.red,),))

          ],
        )











            : Align(alignment: Alignment.bottomRight,
          child: GestureDetector(onTap: (){logic.choosVideo();},
            child: Container(height: hi/10, width: wi/4, decoration: BoxDecoration(
                image: DecorationImage(
                    image: AssetImage(ImageX.ImageAddVodioItem)
                )
            ),),
          ),
        )
            : Align(alignment: Alignment.bottomRight,
              child: GestureDetector(onTap: (){logic.choosVideo();},
                child: Container(height: hi/10, width: wi/4, decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(ImageX.ImageAddVodioItem)
                        )
                      ),),
              ),
            );

    });
  }
}

