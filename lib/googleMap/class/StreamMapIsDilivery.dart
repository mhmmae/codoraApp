import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../TheOrder/ViewOeder/GetX/GetDateToText.dart';
import '../../TheOrder/barcod/GetxBarCode/GetXBarCode.dart';
import '../../TheOrder/barcod/barcode.dart';
import '../../XXX/XXXFirebase.dart';
import '../Getx/GetInfowUser.dart';
import '../Getx/GetStreamMapIsDilivery.dart';

class Streammapisdilivery extends StatelessWidget {
  Streammapisdilivery({super.key,
    required this.latitude,
    required this.longitude,
    required this.isdilivery, this.markerUser, this.markerDelivery});

  double latitude;
  double longitude;
  bool isdilivery;
  Uint8List? markerUser;
  Uint8List? markerDelivery;

  final Stream<QuerySnapshot> DeliveryUser = FirebaseFirestore.instance
      .collection('DeliveryUser')
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .collection('DeliveryUID')
      .snapshots();

  void sss() {
    print('/////////////////////////////////////////////');
  }


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
    return GetBuilder<Getstreammapisdilivery>(
        init: Getstreammapisdilivery(
          idDilivery: isdilivery,
          latitude: latitude,
          longitude: longitude,
        ),
        builder: (logic) {
          return SizedBox(width: wi,height: hi,
            child: StreamBuilder<QuerySnapshot>(
              stream: DeliveryUser,
              builder:
                  (BuildContext context,
                  AsyncSnapshot<QuerySnapshot<Object?>> snapshot) {
                if (snapshot.hasError) {
                  return Text('Something went wrong');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Text("Loading");
                }
                Set<Marker> MANY = <Marker>{
                  longitude.isNaN
                      ? Marker(markerId: MarkerId('1'), position: LatLng(0, 0))
                      : Marker(
                      markerId: MarkerId('1'),
                      position: LatLng(latitude, longitude),
                      icon: BitmapDescriptor.bytes(markerDelivery!)
                  ),
                };

                return  ListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: snapshot.data!.docs.map((
                        DocumentSnapshot document) {
                      Map<String, dynamic> user =
                      document.data()! as Map<String, dynamic>;
                      // MANY.add(Marker(
                      //     markerId: MarkerId(user['orderUid']),
                      //     position: LatLng(user['latitude'], user['longitude']),
                      //     onTap: () {
                      //       if (logic12.isDilveyGetUserInformaion == false) {
                      //         logic12.isDilveyGetUserInformaion = true;
                      //         print(
                      //             'false/////////////////////////////////////////////');
                      //         logic12.onInit();
                      //         logic12.update();
                      //       }
                      //     },
                      //
                      //     draggable: true,
                      //     icon: BitmapDescriptor.bytes(markerUser!)));

                      return GetBuilder<getInfowUser>(init: getInfowUser(userId: user['orderUid'],
                        longitude:  user['longitude'],latitude: user['latitude']
                      ),builder: (logic12) {

                        print('rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr');
                        print('qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq');


                        MANY.add(Marker(
                            markerId: MarkerId(user['orderUid']),
                            position: LatLng(user['latitude'], user['longitude']),

                            onTap: () {
                              if (logic12.isDilveyGetUserInformaion == false) {
                                logic12.isDilveyGetUserInformaion = true;
                                print(
                                    'false/////////////////////////////////////////////');
                                logic12.onInit();
                                logic12.update();
                              }
                            },

                            draggable: true,
                            icon: BitmapDescriptor.bytes(markerUser!)));

                        return Stack(
                          children: [
                            SizedBox(
                                height: hi,
                                width: wi,
                                child: GoogleMap(
                                  mapType: MapType.normal,
                                  markers: MANY,
                                  initialCameraPosition: CameraPosition(
                                      target: LatLng(
                                          logic.latitude, logic.longitude),
                                      zoom: 17),
                                  onMapCreated: (controller) {
                                    logic.controller2 = controller;
                                  },
                                )),
                              logic12.isDilveyGetUserInformaion
                                  ? Positioned(
                                      top: hi / 4,
                                      bottom: hi / 4,
                                      right: wi / 6,
                                      left: wi / 6,
                                      child: Container(
                                        width: wi / 5,
                                        height: hi / 5,
                                        decoration: BoxDecoration(
                                          color: Colors.white70,
                                          borderRadius: BorderRadius.circular(7),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: ListView(
                                              shrinkWrap: true,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    GetBuilder<Getxbarcode>(
                                                        init: Getxbarcode(),
                                                        builder: (logic) {
                                                          return GestureDetector(
                                                            onTap: () {
                                                              logic.up = 0;
                                                              Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                      builder:
                                                                          (context) =>
                                                                              barcode()));
                                                            },
                                                            child: Container(
                                                              decoration: BoxDecoration(
                                                                  color: Colors
                                                                      .redAccent,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              6)),
                                                              height: hi / 18,
                                                              width: wi / 7,
                                                              child: Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .symmetric(
                                                                        horizontal:
                                                                            3),
                                                                child: SizedBox(
                                                                  width: wi / 20,
                                                                  height: hi / 30,
                                                                  child: Icon(
                                                                    Icons
                                                                        .document_scanner,
                                                                    size: wi / 14,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        }),

                                                    // =========================================
                                                    // =========================================
                                                    // =========================================
                                                    // =========================================

                                                    GestureDetector(
                                                      onTap: () {
                                                        if (logic12
                                                                .isDilveyGetUserInformaion ==
                                                            true) {
                                                          logic12.isDilveyGetUserInformaion =
                                                              false;
                                                          print(
                                                              'true/////////////////////////////////////////////');

                                                          logic12.update();
                                                        }
                                                      },
                                                      child: SizedBox(
                                                        width: wi / 10,
                                                        height: hi / 23,
                                                        child:
                                                            Icon(Icons.dangerous),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Container(
                                                        width: wi / 4,
                                                        height: hi / 7,
                                                        decoration: BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(7),
                                                            image: DecorationImage(
                                                                image: logic12
                                                                            .urlOfUser !=
                                                                        null
                                                                    ? NetworkImage(
                                                                        logic12
                                                                            .urlOfUser!)
                                                                    : AssetImage(
                                                                        ImageX
                                                                            .ImageOfPerson),
                                                                fit: BoxFit
                                                                    .cover))),
                                                    Column(
                                                      children: [
                                                        Container(
                                                          width: wi / 3.5,
                                                          decoration: BoxDecoration(
                                                              color:
                                                                  Colors.black12,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          16),
                                                              border: Border.all(
                                                                  color: Colors
                                                                      .black)),
                                                          child: Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .end,
                                                            children: [
                                                              Center(
                                                                  child: Text(
                                                                'اسم المستخدم',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        wi / 70),
                                                              )),
                                                              Center(
                                                                  child: Text(
                                                                      logic12.name !=
                                                                              null
                                                                          ? logic12
                                                                              .name!
                                                                          : '',
                                                                      style: TextStyle(
                                                                          fontSize:
                                                                              wi /
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
                                                              color:
                                                                  Colors.black12,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          16),
                                                              border: Border.all(
                                                                  color: Colors
                                                                      .black)),
                                                          child: Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .end,
                                                            children: [
                                                              Center(
                                                                  child: Text(
                                                                'ايميل المستخدم',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        wi / 70),
                                                              )),
                                                              Center(
                                                                  child: Text(
                                                                      logic12.email !=
                                                                              null
                                                                          ? logic12
                                                                              .email!
                                                                          : '',
                                                                      style: TextStyle(
                                                                          fontSize:
                                                                              wi /
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
                                                              color:
                                                                  Colors.black12,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          16),
                                                              border: Border.all(
                                                                  color: Colors
                                                                      .black)),
                                                          child: Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .end,
                                                            children: [
                                                              Center(
                                                                  child: Text(
                                                                'رقم هاتف المستخدم',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        wi / 70),
                                                              )),
                                                              Center(
                                                                  child: Text(
                                                                      logic12.phneNumber !=
                                                                              null
                                                                          ? logic12
                                                                              .phneNumber!
                                                                          : '',
                                                                      style: TextStyle(
                                                                          fontSize:
                                                                              wi /
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
                                                Divider(),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Container(
                                                      width: wi / 3.5,
                                                      decoration: BoxDecoration(
                                                          color: Colors.black12,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(16),
                                                          border: Border.all(
                                                              color:
                                                                  Colors.black)),
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment.end,
                                                        children: [
                                                          Center(
                                                              child: Text(
                                                            'رقم الطلب',
                                                            style: TextStyle(
                                                                fontSize:
                                                                    wi / 70),
                                                          )),
                                                          Center(
                                                              child: Text(
                                                                  user[
                                                                      'nmberOfOrder'],
                                                                  style: TextStyle(
                                                                      fontSize: wi /
                                                                          55))),
                                                          SizedBox(
                                                            height: hi / 100,
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                    Container(
                                                      width: wi / 3.5,
                                                      decoration: BoxDecoration(
                                                          color: Colors.black12,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(16),
                                                          border: Border.all(
                                                              color:
                                                                  Colors.black)),
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment.end,
                                                        children: [
                                                          Center(
                                                              child: Text(
                                                            'المبلغ الكلي',
                                                            style: TextStyle(
                                                                fontSize:
                                                                    wi / 70),
                                                          )),
                                                          Center(
                                                              child: Container(
                                                            decoration: BoxDecoration(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            9),
                                                                color: Colors
                                                                    .greenAccent),
                                                            child: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          6),
                                                              child: Text(
                                                                  '${user['totalPriceOfOrder']}',
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          wi / 54,
                                                                      color: Colors
                                                                          .black)),
                                                            ),
                                                          )),
                                                          SizedBox(
                                                            height: hi / 100,
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(
                                                  height: hi / 100,
                                                ),
                                                Container(
                                                  width: wi / 3.5,
                                                  decoration: BoxDecoration(
                                                      color: Colors.black12,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              16),
                                                      border: Border.all(
                                                          color: Colors.black)),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      Center(
                                                          child: Text(
                                                        ':المكان',
                                                        style: TextStyle(
                                                            fontSize: wi / 60),
                                                      )),
                                                      Center(
                                                          child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                              logic12.Administrative ==
                                                                      null
                                                                  ? ''
                                                                  : logic12
                                                                      .Administrative!,
                                                              style: TextStyle(
                                                                  fontSize:
                                                                      wi / 45)),
                                                          Text('/',
                                                              style: TextStyle(
                                                                  fontSize:
                                                                      wi / 55)),
                                                          Text(
                                                              logic12.nameOfgovernorate ==
                                                                      null
                                                                  ? ''
                                                                  : logic12
                                                                      .nameOfgovernorate!,
                                                              style: TextStyle(
                                                                  fontSize:
                                                                      wi / 45)),
                                                          Text('/',
                                                              style: TextStyle(
                                                                  fontSize:
                                                                      wi / 55)),
                                                          Text(
                                                              logic12.nameOfContry ==
                                                                      null
                                                                  ? ''
                                                                  : logic12
                                                                      .nameOfContry!,
                                                              style: TextStyle(
                                                                  fontSize:
                                                                      wi / 45)),
                                                        ],
                                                      )),
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
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              16),
                                                      border: Border.all(
                                                          color: Colors.black)),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      Center(
                                                          child: Text(
                                                        'وقت الطلب:',
                                                        style: TextStyle(
                                                            fontSize: wi / 60),
                                                      )),
                                                      Center(
                                                          child: GetBuilder<
                                                                  Getdatetotext>(
                                                              init:
                                                                  Getdatetotext(),
                                                              builder: (val) {
                                                                return Text(
                                                                  val.dateToText(user[
                                                                      'timeOrder']),
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          wi /
                                                                              55),
                                                                );
                                                              })),
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
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              16),
                                                      border: Border.all(
                                                          color: Colors.black)),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      Center(
                                                          child: Text(
                                                        ':طريقة الدفع',
                                                        style: TextStyle(
                                                            fontSize: wi / 60),
                                                      )),
                                                      Center(
                                                          child: Container(
                                                              decoration: BoxDecoration(
                                                                  color: Colors
                                                                      .redAccent,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              9)),
                                                              child: Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .symmetric(
                                                                        horizontal:
                                                                            6),
                                                                child: Text(
                                                                    'عند الآستلام',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            wi /
                                                                                45)),
                                                              ))),
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
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              16),
                                                      border: Border.all(
                                                          color: Colors.black)),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      Center(
                                                          child: Text(
                                                        ':ملاحظات',
                                                        style: TextStyle(
                                                            fontSize: wi / 60),
                                                      )),
                                                      Center(
                                                          child: Text(
                                                              'ujhgjhljhfblwjkebljbegkner;gjner;gneroigerg[oierh[oijt[iohj',
                                                              style: TextStyle(
                                                                  fontSize:
                                                                      wi / 55))),
                                                      SizedBox(
                                                        height: hi / 100,
                                                      )
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: hi / 100,
                                                ),
                                              ]),
                                        ),
                                      ))
                                  : Container()
                            ],
                        );
                      });
                    }).toList(),
                  );

              },
            ),
          );
        });
  }
}

