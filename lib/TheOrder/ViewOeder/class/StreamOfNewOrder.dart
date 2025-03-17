import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../XXX/XXXFirebase.dart';
import '../GetX/GetDateToText.dart';
import '../GetX/GetRequest.dart';

class Streamofneworder extends StatelessWidget {
   Streamofneworder({super.key});
  bool isloding =false;


  @override
  Widget build(BuildContext context) {
    double hi = MediaQuery.of(context).size.height;
    double wi = MediaQuery.of(context).size.width;
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('order').where('appName' ,isEqualTo: FirebaseX.appName).get(),
      builder:
          (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {

        if (snapshot.hasError) {
          return Text("Something went wrong");
        }


        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(),);
        }



        return ListView(
            shrinkWrap: true,
            children: snapshot.data!.docs.map((DocumentSnapshot document){
              Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection(FirebaseX.collectionApp).doc(data['uidUser']).get(),
                builder:
                    (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {

                  if (snapshot.hasError) {
                    return Text("Something went wrong");
                  }

                  if (snapshot.hasData && !snapshot.data!.exists) {
                    return Text("Document does not exist");
                  }

                  if (snapshot.connectionState == ConnectionState.done) {
                    Map<String, dynamic> data1 = snapshot.data!.data() as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Align(alignment: Alignment.topRight,child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              GetBuilder<Getdatetotext>(init: Getdatetotext(),builder: (val){
                                return Text(val.dateToText(data['timeOrder']),style: TextStyle(fontSize: wi/44),);
                              }),
                              SizedBox(width: wi/70,)
                            ],
                          )) ,
                          ListTile(
                              minTileHeight: hi/10,
                              minLeadingWidth: wi/7,
                              leading: Container(height: hi/10,width: wi/7,decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(color: Colors.black),
                                  image: DecorationImage(
                                      fit: BoxFit.cover,
                                      image: NetworkImage(data1['url'])
                                  )                            ),
                              ),

                              title: Column(

                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(data1['name'],style: TextStyle(fontSize: wi/33),),






                                    ],
                                  ),
                                  SizedBox(height: hi/80,),
                                  Text(data1['phneNumber'],style: TextStyle(fontSize: wi/44))
                                ],
                              ),


                              trailing: SizedBox(

                                width: wi/3.7,
                                height: hi/12,
                                child: Row(
                                  children: [







































                                    GetBuilder<Getrequest>(init: Getrequest(),builder: (val){
                                      return  GestureDetector(
                                        onTap: (){
                                          val.RequestRejection(data['uidUser'],wi,context);
                                        },
                                        child: !data['Delivery'] ? Container(
                                          width: wi/8,height: hi/12,
                                          decoration: BoxDecoration(
                                              color: Colors.black12,
                                              border: Border.all(color: Colors.black),
                                              borderRadius: BorderRadius.circular(10)
                                          ),
                                          child: Icon(Icons.dangerous_rounded,size: wi/14,color: Colors.red,),
                                        ):SizedBox(width: wi/8,height: hi/12,),
                                      );
                                    }),










































                                    SizedBox(width: wi/50,),
                                   GetBuilder<Getrequest>(init: Getrequest(),builder: (val){
                                     return GestureDetector(
                                       onTap: (){
                                         isloding = true;
                                         val.update();

                                         val.RequestAccept(data['uidUser']);
                                       },
                                       child: isloding == false ? data['RequestAccept']==false? Badge(
                                         smallSize: wi/30,

                                         isLabelVisible: true,
                                         child: Container(
                                           width: wi/8,height: hi/12,
                                           decoration: BoxDecoration(color: Colors.black12,
                                               border: Border.all(color: Colors.black),
                                               borderRadius: BorderRadius.circular(10)
                                           ),
                                           child: Icon(Icons.done,size: wi/14,color: Colors.green,),
                                         ),
                                       ):Container(
                                         width: wi/8,height: hi/12,
                                         decoration: BoxDecoration(color: Colors.black12,
                                             border: Border.all(color: Colors.black),
                                             borderRadius: BorderRadius.circular(10)
                                         ),
                                         child: Icon(Icons.done,size: wi/14,color: Colors.green,),
                                       ):CircularProgressIndicator(),
                                     );
                                   })
                                  ],
                                ),
                              ),
                              shape: RoundedRectangleBorder(
                                  side: const BorderSide(color: Colors.black),
                                  borderRadius: BorderRadius.circular(10)
                              )
                          ),
                          SizedBox(height: hi/50,)
                        ],
                      ),
                    );
                  }

                  return const Center(child: CircularProgressIndicator(),);
                },
              );
            }).toList()
        );
      },
    );
  }
}
