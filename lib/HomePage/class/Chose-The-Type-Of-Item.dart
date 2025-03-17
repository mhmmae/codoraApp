
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../XXX/XXXFirebase.dart';

class ChoseTheTypeOfItem extends StatelessWidget {
   const ChoseTheTypeOfItem({super.key,});



  @override
  Widget build(BuildContext context) {
    double hi = MediaQuery.of(context).size.height;
    double wi = MediaQuery.of(context).size.width;
    return  GetBuilder<Getchosethetypeofitem>(init: Getchosethetypeofitem(),builder: (val){
      return ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Container(height: hi/16,decoration: BoxDecoration(
              border: Border.symmetric(horizontal: BorderSide(color: Colors.black))
          ),
            child: ListView.builder(itemCount: val.TheWher.length,shrinkWrap: true,scrollDirection: Axis.horizontal
                ,itemBuilder: (context,index){




              List<Icon> icon = [Icon(Icons.phone_android,size: wi/22,),Icon(Icons.phone_android,size: wi/22),Icon(Icons.phone_android,size: wi/22),Icon(Icons.headphones,size: wi/22),Icon(Icons.tab),Icon(Icons.javascript,size: wi/22),
                    Icon(Icons.kayaking,size: wi/22),Icon(Icons.update,size: wi/22),Icon(Icons.label_important,size: wi/22),Icon(Icons.yard,size: wi/22),];



                  return Padding(
                    padding:  const EdgeInsets.symmetric(horizontal: 5),
                    child: GestureDetector(onTap: (){

                      val.update();
                      val.TheChosen = val.TheWher[index];



                    },child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [


                        Container(decoration: BoxDecoration(
                            color: val.TheChosen != val.TheWher[index]? Colors.black12:Colors.deepPurpleAccent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.black)
                        ),
                          width: wi/3,height: hi/22,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 9),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [

                                icon[index],
                                SizedBox(width: wi/80,),
                                Text(val.text[index],style: TextStyle(fontSize: wi/40),),
                              ],
                            ),
                          ),),
                      ],
                    )),
                  );
                }),
          ),

        ],
      );
    });


  }

}
