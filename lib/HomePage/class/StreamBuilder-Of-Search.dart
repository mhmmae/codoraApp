
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../XXX/XXXFirebase.dart';
import 'DetalesOfItems.dart';
import 'addAndRemoveSearch.dart';

class StreamBuilderOfSearch extends StatelessWidget {
   StreamBuilderOfSearch({super.key,required this.search});
   TextEditingController search;

  @override
  Widget build(BuildContext context) {
    double hi = MediaQuery.of(context).size.height;
    double wi = MediaQuery.of(context).size.width;
    return Column(
      children: [
        SizedBox(height: hi/40,),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('Item').where('appName',isEqualTo: FirebaseX.appName).orderBy('nameOfItem')
              .startAt([search.text]).endAt(['${search.text}\uf8ff']).snapshots(),

          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return Text('Something went wrong');
            }


            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            return ListView(
              shrinkWrap: true,
              children: snapshot.data!.docs.map((DocumentSnapshot document) {
                Map<String, dynamic> dede = document.data()! as Map<String, dynamic>;

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                        borderRadius: BorderRadius.circular(16)
                    ),
                    child: ListTile(

                      leading: GestureDetector(
                        onTap: (){
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) =>
                                  DetalesOfItems(url: dede['url'],
                                    rate: 0,
                                    images: dede["manyImages"]??'',
                                    typeItem:dede['typeItem'] ,
                                    priceOfItem: dede['priceOfItem'],
                                    nameOfItem: dede['nameOfItem'],
                                    descriptionOfItem: dede['descriptionOfItem'],
                                    uid: dede['uid'],
                                    isOffer: false,
                                    VideoURL: dede['videoURL'],
                                  )));
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                              color: Colors.black12
                          ),
                          height: hi/15,width: wi/6,
                          child: Image.network(dede['url'],fit: BoxFit.cover,),
                        ),
                      ),
                      title: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Text(dede['nameOfItem'],style: TextStyle(fontSize:wi/33),),
                          SizedBox(height: hi/70,),
                          Text(' ${dede['priceOfItem'].toString()} : السعر    ',style: TextStyle(fontSize:wi/33),),

                        ],
                      ),
                      trailing: SizedBox(height: hi/28,width: wi/3.3,
                          child: Center(
                              child: addAndRemoveSearch(uidItem: dede['uid'],isOfeer: false,wi4: wi/25,))),


                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
