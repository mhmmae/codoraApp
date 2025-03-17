
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Streamorderofuser extends StatelessWidget {
  String uid;
   Streamorderofuser({super.key,required this.uid});

  @override
  Widget build(BuildContext context) {
    double hi = MediaQuery.of(context).size.height;
    double wi = MediaQuery.of(context).size.width;
    return FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection('order').doc(uid.toString()).collection('TheOrder').get(),
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
              physics: NeverScrollableScrollPhysics(),


              children: snapshot.data!.docs.map((DocumentSnapshot document){
                Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
                return FutureBuilder<DocumentSnapshot>(
                  future: data['isOfer'] == false ? FirebaseFirestore.instance.collection('Item').doc(data['uidItem']).get(): FirebaseFirestore.instance.collection('Itemoffer').doc(data['uidItem']).get(),
                  builder:
                      (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {

                    if (snapshot.hasError) {
                      return Center(child: Text("Something went wrong"));
                    }

                    if (snapshot.connectionState ==ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(),);
                    }

                    if (snapshot.connectionState == ConnectionState.done) {
                      Map<String, dynamic> data1 = snapshot.data!.data() as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ListTile(
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
                                Text(data1['nameOfItem'],style: TextStyle(fontSize: wi/35),),
                                SizedBox(height: hi/80,),
                                Text(' السعر:${data1['priceOfItem'].toString()} ',style: TextStyle(fontSize: wi/35),)
                              ],
                            ),
                            trailing: SizedBox(
                              width: wi/4,
                              height: hi/10,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(' (${data['number'].toString()}): العدد',style: TextStyle(fontSize: wi/38,color: Colors.red),)

                                ],
                              ),
                            ),


                            shape: RoundedRectangleBorder(
                                side: BorderSide(color: Colors.black),
                                borderRadius: BorderRadius.circular(10)
                            )
                        ),
                      );
                    }

                    return const Center(child: Text(''));
                  },
                );
              }).toList()
          );
        },
      );
  }
}
