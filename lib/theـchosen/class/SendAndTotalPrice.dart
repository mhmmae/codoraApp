


import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../GetXController/GetAddAndRemove.dart';
import '../GetXController/GetSendandtotalprice.dart';

class Sendandtotalprice extends StatelessWidget {
  String uid;
   Sendandtotalprice({super.key,required this.uid});



   // Getsendandtotalprice controller = Get.put(Getsendandtotalprice());

     @override
  Widget build(BuildContext context) {
    double hi = MediaQuery.of(context).size.height;
    double wi = MediaQuery.of(context).size.width;
    return
      Container(
        width: double.infinity,
        height: hi/5.23,
        color: Colors.white10,
        child: Column(
          children: [
            SizedBox(
              height: 2,
            ),
            Padding(
              padding:  EdgeInsets.symmetric(horizontal: wi/20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'total:',
                    style: TextStyle(
                        fontSize: wi/18, color: Colors.deepPurpleAccent),
                  ),
                  Row(
                    children: [
                      GetBuilder<GetAddAndRemove>(init: GetAddAndRemove(),builder: (val){
                        return Text('${val.total}',style: TextStyle(
                            fontSize: wi/25, color: Colors.deepPurpleAccent),);
                      },),


                      SizedBox(width: 8,),
                      Text(
                        'iq',
                        style: TextStyle(
                            fontSize: wi/30, color: Colors.green),
                      ),
                    ],
                  )
                ],
              ),
            ),
            SizedBox(
              height: hi/50,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 90),

              child: GetBuilder<Getsendandtotalprice>(init: Getsendandtotalprice(uid:uid ),builder: (val){
                return val.isLoding? const CircularProgressIndicator() : GestureDetector(
                  onTap: ()async{
                  await  val.send();
                    },
                  child: Container(
                    width: double.infinity,
                    height: hi/14,
                    decoration: BoxDecoration(
                        color: Colors.deepPurpleAccent,
                        borderRadius: BorderRadius.circular(15)),
                    child: Center(child: Text('ارسال الطلب',style: TextStyle(fontSize: wi/20),)),
                  ),
                );
              },)
            ),
          ],

        ),
      );
  }
}
