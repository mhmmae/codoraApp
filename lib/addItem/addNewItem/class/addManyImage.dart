import 'package:codora/XXX/XXXFirebase.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'getAddManyImage.dart';

class addManyImage extends StatelessWidget {
   addManyImage({super.key});

  @override
  Widget build(BuildContext context) {
    double hi = MediaQuery.of(context).size.height;
    double wi = MediaQuery.of(context).size.width;
    return GetBuilder<getAddManyImage>(init:getAddManyImage() ,builder: (val){
      return val.isAddImage == false? GestureDetector(
        onTap: ()async{

        try {
          await val.processImages();
        } catch (e) {
          print("حدث خطأ أثناء معالجة الصور: $e");
          // أضف رسالة Toast أو Snackbar لتنبيه المستخدم
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("تعذر تحميل الصور! حاول مرة أخرى.")),
          );
        }
      },
        child: Container(width: wi/6,height: hi/13,decoration:BoxDecoration(
          image:DecorationImage(
            fit: BoxFit.cover,
            image:AssetImage(ImageX.ImageAddImage)
          )
        )),
      ):Column(
        children: [
          GestureDetector(
            onTap: (){
              val.isAddImage = false;
              getAddManyImage.allBytes.clear();
              val.update();
            },
            child: Container(
              alignment: Alignment.topLeft,
              child: Icon(Icons.close),
            ),
          ),
          SizedBox(width:wi,height:hi/5,
          child:getAddManyImage.allBytes.isNotEmpty ? ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: getAddManyImage.allBytes.length,
            itemBuilder: (context,index){
              return   Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: wi/4,height: hi/10,
                    decoration:BoxDecoration(
                      border:Border.all(color:Colors.black87),
                        borderRadius:BorderRadius.circular(15),
                        image:DecorationImage(
                          fit: BoxFit.cover,
                            image:MemoryImage(getAddManyImage.allBytes[index])
                        )
                    )
                ),
              );
            },



          ) :Container()
          ),
        ],
      );
    },);
  }
}
