import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../XXX/XXXFirebase.dart';
import '../Getx/GetInfowUser.dart';

class StreammapisNotdilivery extends StatelessWidget {
  StreammapisNotdilivery({super.key,
    required this.latitude,
    required this.longitude,
    required this.isdilivery, this.markerUser, this.markerDelivery});

  double latitude;
  double longitude;
  bool isdilivery;
  Uint8List? markerUser;
  Uint8List? markerDelivery;

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
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection(FirebaseX.collectionApp)
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get(),
      builder: (BuildContext context,
          AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.hasError) {
          return Text('Something went wrong');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text('SomDQDething went wrong');
        }

        Map<String, dynamic> data11 = snapshot.data!.data() as Map<
            String,
            dynamic>;


        return data11[FirebaseX.DeliveryUid] != null ? StreamBuilder<
            DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('DeliveryUser')
              .doc(data11[FirebaseX.DeliveryUid])
              .snapshots(),
          builder: (BuildContext context,
              AsyncSnapshot<DocumentSnapshot> snapshot) {
            if (snapshot.hasError) {
              return Text('Something went wrong');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text("Loading");
            }
            Map<String, dynamic> data13 = snapshot.data!.data() as Map<
                String,
                dynamic>;


            // controller2?.animateCamera(CameraUpdate.newLatLng(data13['latitudeDelivery'] == null ?const LatLng(0, 0) :LatLng(data13['latitudeDelivery'], data13['longitudeDelivery'])));


            return GetBuilder<getInfowUser>( init: getInfowUser(userId: data11[FirebaseX.DeliveryUid],latitude: 0,longitude: 0),
                builder: (logic12) {


                  Set<Marker> MANY = <Marker>{
                    longitude.isNaN ? Marker(
                        markerId: MarkerId('1'), position: LatLng(0, 0))
                        : Marker(markerId: MarkerId('1'),
                        position: LatLng(latitude, longitude),
                        icon: BitmapDescriptor.bytes(markerUser!)),

                  };
                  MANY.add(Marker(markerId: MarkerId('3'),
                      onTap: () {
                        if (logic12.isDilveyGetUserInformaion == false) {
                          logic12.isDilveyGetUserInformaion = true;
                          print(
                              'false/////////////////////////////////////////////');
                          logic12.onInit();
                          logic12.update();
                        }
                      },
                      position: LatLng(data13['latitudeDelivery'],
                          data13['longitudeDelivery']),
                      draggable: true,
                      icon: BitmapDescriptor.bytes(markerDelivery!)));
              return Stack(
                // shrinkWrap: true,
                // physics: const NeverScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: hi, width: wi,
                      child: GoogleMap(
                        mapType: MapType.hybrid,
                        markers: MANY,


                        initialCameraPosition: CameraPosition(
                            target: LatLng(data13['latitudeDelivery'],
                                data13['longitudeDelivery']), zoom: 17),
                        onMapCreated: (controller) {
                          // controller2 = controller;
                        },
                      ),
                    ),

                    logic12.isDilveyGetUserInformaion ? Positioned(
                        top: hi / 2.75,
                        bottom: hi / 2.75,
                        right: wi / 6,
                        left: wi / 6,
                        child: Container(
                          width: wi / 8,
                          height: hi / 7,
                          decoration: BoxDecoration(
                            color: Colors.white70,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(

                                children: [



                                  Row(
                                    mainAxisAlignment: MainAxisAlignment
                                        .spaceBetween,
                                    children: [
                                      Container(),


                                      GestureDetector(
                                        onTap: () {
                                          if (logic12
                                              .isDilveyGetUserInformaion ==
                                              true) {
                                            logic12
                                                .isDilveyGetUserInformaion =
                                            false;
                                            print(
                                                'true/////////////////////////////////////////////');

                                            logic12.update();
                                          }
                                        },
                                        child: SizedBox(
                                          width: wi / 10,
                                          height: hi / 23,
                                          child: Icon(Icons.dangerous),
                                        ),

                                      ),


                                    ],
                                  ),
                                  SizedBox(
                                    height: hi/50,
                                  ),


                                  Row(
                                    mainAxisAlignment: MainAxisAlignment
                                        .spaceBetween,
                                    children: [
                                      Container(
                                          width: wi / 4,
                                          height: hi / 7,
                                          decoration: BoxDecoration(
                                              borderRadius: BorderRadius
                                                  .circular(7),

                                              image: DecorationImage(
                                                  image:
                                                  logic12.urlOfUser !=
                                                      null
                                                      ? NetworkImage(
                                                      logic12
                                                          .urlOfUser!)
                                                      : AssetImage(
                                                      ImageX
                                                          .ImageOfPerson),
                                                  fit: BoxFit.cover)
                                          )
                                      ),
                                      Column(
                                        children: [
                                          Container(
                                            width: wi / 3.5,
                                            decoration: BoxDecoration(
                                                color: Colors.black12,
                                                borderRadius: BorderRadius
                                                    .circular(16),
                                                border: Border.all(
                                                    color: Colors
                                                        .black)),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment
                                                  .end,
                                              children: [
                                                Center(
                                                    child: Text(
                                                      'اسم المستخدم',
                                                      style: TextStyle(
                                                          fontSize: wi /
                                                              70),
                                                    )),
                                                Center(
                                                    child: Text(
                                                        logic12.name !=
                                                            null
                                                            ? logic12
                                                            .name!
                                                            : '',
                                                        style: TextStyle(
                                                            fontSize: wi /
                                                                65))),
                                                SizedBox(
                                                  height: hi / 100,
                                                )
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                            height: hi / 100,
                                          ),
                                          Container(
                                            width: wi / 3.5,
                                            decoration: BoxDecoration(
                                                color: Colors.black12,
                                                borderRadius: BorderRadius
                                                    .circular(16),
                                                border: Border.all(
                                                    color: Colors
                                                        .black)),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment
                                                  .end,
                                              children: [
                                                Center(
                                                    child: Text(
                                                      'ايميل المستخدم',
                                                      style: TextStyle(
                                                          fontSize: wi /
                                                              70),
                                                    )),
                                                Center(
                                                    child: Text(logic12
                                                        .email != null
                                                        ? logic12
                                                        .email!
                                                        : '',
                                                        style: TextStyle(
                                                            fontSize: wi /
                                                                70))),
                                                SizedBox(
                                                  height: hi / 100,
                                                )
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                            height: hi / 100,
                                          ),
                                          Container(
                                            width: wi / 3.5,
                                            decoration: BoxDecoration(
                                                color: Colors.black12,
                                                borderRadius: BorderRadius
                                                    .circular(16),
                                                border: Border.all(
                                                    color: Colors
                                                        .black)),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment
                                                  .end,
                                              children: [
                                                Center(
                                                    child: Text(
                                                      'رقم هاتف المستخدم',
                                                      style: TextStyle(
                                                          fontSize: wi /
                                                              70),
                                                    )),
                                                Center(
                                                    child: Text(logic12
                                                        .phneNumber !=
                                                        null
                                                        ? logic12
                                                        .phneNumber!
                                                        : '',
                                                        style: TextStyle(
                                                            fontSize: wi /
                                                                65))),
                                                SizedBox(
                                                  height: hi / 100,
                                                )
                                              ],
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),


                                ]
                           ),
                          ),
                        )
                    ) : Container()


                  ]
              );
            });
          },
        ): Center(child: Container(child: Text('لا يوجد منتجات')
        ,
        )
        );
      },
    );
  }
}
