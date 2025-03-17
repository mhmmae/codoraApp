
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';


import '../../XXX/XXXFirebase.dart';
import '../../controler/local-notification-onroller.dart';
import 'DetalesOfItems.dart';

class StreambuilderBoxOfOfferItem extends StatelessWidget {
   StreambuilderBoxOfOfferItem({super.key,required this.pageController});
   PageController pageController;


  final Stream<QuerySnapshot> ItemofferStream =
  FirebaseFirestore.instance.collection('Itemoffer').where('appName',isEqualTo: FirebaseX.appName).snapshots();




  @override
  Widget build(BuildContext context) {
    double hi = MediaQuery.of(context).size.height;
    double wi = MediaQuery.of(context).size.width;
    return StreamBuilder<QuerySnapshot>(
      stream: ItemofferStream,
      builder:
          (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Text('Something went wrong');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }


        return SizedBox(
          height: hi/3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: PageView.builder(
              controller: pageController,
              itemCount: snapshot.data!.docs.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                DocumentSnapshot dede = snapshot.data!.docs[index];

                return Container(
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(15)
                  ),
                  child: Column(
                    children: [
                      Container(

                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12))),
                        width: double.infinity,
                        height: hi/28,
                        child: Center(
                            child: Text(
                              dede['nameOfItem'],
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: wi/35,
                                  fontWeight: FontWeight.w500,
                                  fontStyle: FontStyle.italic),
                            )),
                      ),
                      Row(
                        children: [
                          Container(
                            width: wi/3.3,
                            height: hi/3.4,
                            decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(12))),
                            child: Column(
                              children: [
                                Container(
                                  color: Colors.transparent,
                                  width: double.infinity,
                                  height: hi/10,
                                  child: Center(
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 8),
                                        child: Text(
                                          '${dede['rate'].toString()}% Off ',
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: wi/25,
                                              fontWeight: FontWeight.bold,
                                              fontStyle: FontStyle.italic),
                                        ),
                                      )),
                                ),
                                Container(
                                  color: Colors.transparent,
                                  width: double.infinity,
                                  height: hi/12,
                                  child: Center(
                                      child: Text(
                                        dede['oldPrice'].toString(),
                                        style: TextStyle(
                                            decorationColor: Colors.redAccent,
                                          decorationThickness: 2,
                                          decoration: TextDecoration.lineThrough,
                                            color: Colors.black,
                                            fontSize: wi/30,
                                            fontWeight: FontWeight.bold,
                                            fontStyle: FontStyle.italic),
                                      )),
                                ),
                                GestureDetector(
                                  onTap: ()async{

                                    // Navigator.push(context, MaterialPageRoute(builder: (context)=>DetalesOfItems(url:dede['url'] ,priceOfItem:  dede['priceOfItem'],
                                    //     typeItem: '',rate: dede['rate'],
                                    //     nameOfItem: dede['nameOfItem'],descriptionOfItem: dede['descriptionOfItem'],uid:dede['uid'] ,isOffer: true,VideoURL: dede['videoURL']
                                    // )));
                                    // ============================================================================================== لا تمسح====================
                                    // ============================================================================================== لا تمسح====================
                                    // ============================================================================================== لا تمسح====================








                                    // FirebaseMessaging.instance.getToken().then((val){
                                    //   print(val);
                                    // });
                                   await localNotification.showNotofication('body', 'body', 'payload',
                                        'https://letsenhance.io/static/8f5e523ee6b2479e26ecc91b9c25261e/1015f/MainAfter.jpg');

                                    //  await localNotification.sendNotificationMessageToUser(
                                    // 'cvn7Bn1gS0iilzXWJ6_lbH:APA91bE_CqJ1iHnfD5VVkCJRimptKS1OjOY7_TV2rRTsTR1JHjp8fR3RboIRqFWynDq4A-p4pdXYMbIrkNJWSSioWBmGLzuxqvUp85JhK3sWftDeQy3V1Hk',
                                    //      'dhdh', 'body', 'sgsdg', "type", "https://letsenhance.io/static/8f5e523ee6b2479e26ecc91b9c25261e/1015f/MainAfter.jpg");
                                    //

                                    // Get.to(DetalesOfItems(url:dede['url'] ,priceOfItem:  dede['priceOfItem'],
                                    //   nameOfItem: dede['nameOfItem'],descriptionOfItem: dede['descriptionOfItem'],uid:dede['uid'] ,
                                    //   isOffer: true,VideoURL: dede['videoURL'],
                                    // ));
                                    //

                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                          color: Colors.blueAccent,
                                          borderRadius: BorderRadius.circular(16)
                                      ),

                                      width: double.infinity,
                                      height: hi/12.4,
                                      child:  Center(
                                          child: Text(
                                            dede['priceOfItem'].toString(),
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontSize: wi/30,
                                                fontWeight: FontWeight.bold,
                                                fontStyle: FontStyle.italic),
                                          )),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: (){
                                Navigator.push(context, MaterialPageRoute(builder: (context)=>DetalesOfItems(url:dede['url'] ,priceOfItem:  dede['priceOfItem'],
                                  typeItem: '',rate: dede['rate'],images: dede["manyImages"]??'',
                                  nameOfItem: dede['nameOfItem'],descriptionOfItem: dede['descriptionOfItem'],uid:dede['uid'] ,isOffer: true,VideoURL: dede['videoURL']
                                )));
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                      bottomRight: Radius.circular(12)),
                                  image: DecorationImage(
                                    fit: BoxFit.cover,
                                    image: NetworkImage(dede['url']),
                                  ),
                                ),
                                width: wi/2,
                                height:hi/3.4,
                                child: dede['videoURL'] !='noVideo'? Align(alignment: Alignment.topRight,
                                    child: Container(decoration: BoxDecoration(color: Colors.red,borderRadius: BorderRadius.circular(12)),child: Icon(Icons.videocam_rounded,size: 15,),)):null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    )
    ;
  }
}
