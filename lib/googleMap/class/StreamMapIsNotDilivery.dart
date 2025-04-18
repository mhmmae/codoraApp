// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
//
// import '../../XXX/XXXFirebase.dart';
// import '../Getx/GetInfowUser.dart';
//
// class StreammapisNotdilivery extends StatelessWidget {
//   StreammapisNotdilivery({super.key,
//     required this.latitude,
//     required this.longitude,
//     required this.isdilivery, this.markerUser, this.markerDelivery});
//
//   double latitude;
//   double longitude;
//   bool isdilivery;
//   Uint8List? markerUser;
//   Uint8List? markerDelivery;
//
//   @override
//   Widget build(BuildContext context) {
//     double hi = MediaQuery
//         .of(context)
//         .size
//         .height;
//     double wi = MediaQuery
//         .of(context)
//         .size
//         .width;
//     return FutureBuilder<DocumentSnapshot>(
//       future: FirebaseFirestore.instance.collection(FirebaseX.collectionApp)
//           .doc(FirebaseAuth.instance.currentUser!.uid)
//           .get(),
//       builder: (BuildContext context,
//           AsyncSnapshot<DocumentSnapshot> snapshot) {
//         if (snapshot.hasError) {
//           return Text('Something went wrong');
//         }
//
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Text('SomDQDething went wrong');
//         }
//
//         Map<String, dynamic> data11 = snapshot.data!.data() as Map<
//             String,
//             dynamic>;
//
//
//         return data11[FirebaseX.DeliveryUid] != null ? StreamBuilder<
//             DocumentSnapshot>(
//           stream: FirebaseFirestore.instance.collection('DeliveryUser')
//               .doc(data11[FirebaseX.DeliveryUid])
//               .snapshots(),
//           builder: (BuildContext context,
//               AsyncSnapshot<DocumentSnapshot> snapshot) {
//             if (snapshot.hasError) {
//               return Text('Something went wrong');
//             }
//
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return Text("Loading");
//             }
//             Map<String, dynamic> data13 = snapshot.data!.data() as Map<
//                 String,
//                 dynamic>;
//
//
//             // controller2?.animateCamera(CameraUpdate.newLatLng(data13['latitudeDelivery'] == null ?const LatLng(0, 0) :LatLng(data13['latitudeDelivery'], data13['longitudeDelivery'])));
//
//
//             return GetBuilder<GetInfowUser>( init: GetInfowUser(userId: data11[FirebaseX.DeliveryUid],latitude: 0,longitude: 0),
//                 builder: (logic12) {
//
//
//                   Set<Marker> MANY = <Marker>{
//                     longitude.isNaN ? Marker(
//                         markerId: MarkerId('1'), position: LatLng(0, 0))
//                         : Marker(markerId: MarkerId('1'),
//                         position: LatLng(latitude, longitude),
//                         icon: BitmapDescriptor.bytes(markerUser!)),
//
//                   };
//                   MANY.add(Marker(markerId: MarkerId('3'),
//                       onTap: () {
//                         if (logic12.isDeliveryGetUserInformation == false) {
//                           logic12.isDeliveryGetUserInformation = true;
//                           print(
//                               'false/////////////////////////////////////////////');
//                           logic12.onInit();
//                           logic12.update();
//                         }
//                       },
//                       position: LatLng(data13['latitudeDelivery'],
//                           data13['longitudeDelivery']),
//                       draggable: true,
//                       icon: BitmapDescriptor.bytes(markerDelivery!)));
//               return Stack(
//                 // shrinkWrap: true,
//                 // physics: const NeverScrollableScrollPhysics(),
//                   children: [
//                     SizedBox(
//                       height: hi, width: wi,
//                       child: GoogleMap(
//                         mapType: MapType.hybrid,
//                         markers: MANY,
//
//
//                         initialCameraPosition: CameraPosition(
//                             target: LatLng(data13['latitudeDelivery'],
//                                 data13['longitudeDelivery']), zoom: 17),
//                         onMapCreated: (controller) {
//                           // controller2 = controller;
//                         },
//                       ),
//                     ),
//
//                     logic12.isDeliveryGetUserInformation ? Positioned(
//                         top: hi / 2.75,
//                         bottom: hi / 2.75,
//                         right: wi / 6,
//                         left: wi / 6,
//                         child: Container(
//                           width: wi / 8,
//                           height: hi / 7,
//                           decoration: BoxDecoration(
//                             color: Colors.white70,
//                             borderRadius: BorderRadius.circular(7),
//                           ),
//                           child: Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Column(
//
//                                 children: [
//
//
//
//                                   Row(
//                                     mainAxisAlignment: MainAxisAlignment
//                                         .spaceBetween,
//                                     children: [
//                                       Container(),
//
//
//                                       GestureDetector(
//                                         onTap: () {
//                                           if (logic12
//                                               .isDeliveryGetUserInformation ==
//                                               true) {
//                                             logic12
//                                                 .isDeliveryGetUserInformation =
//                                             false;
//                                             print(
//                                                 'true/////////////////////////////////////////////');
//
//                                             logic12.update();
//                                           }
//                                         },
//                                         child: SizedBox(
//                                           width: wi / 10,
//                                           height: hi / 23,
//                                           child: Icon(Icons.dangerous),
//                                         ),
//
//                                       ),
//
//
//                                     ],
//                                   ),
//                                   SizedBox(
//                                     height: hi/50,
//                                   ),
//
//
//                                   Row(
//                                     mainAxisAlignment: MainAxisAlignment
//                                         .spaceBetween,
//                                     children: [
//                                       Container(
//                                           width: wi / 4,
//                                           height: hi / 7,
//                                           decoration: BoxDecoration(
//                                               borderRadius: BorderRadius
//                                                   .circular(7),
//
//                                               image: DecorationImage(
//                                                   image:
//                                                   logic12.urlOfUser !=
//                                                       null
//                                                       ? NetworkImage(
//                                                       logic12
//                                                           .urlOfUser!)
//                                                       : AssetImage(
//                                                       ImageX
//                                                           .ImageOfPerson),
//                                                   fit: BoxFit.cover)
//                                           )
//                                       ),
//                                       Column(
//                                         children: [
//                                           Container(
//                                             width: wi / 3.5,
//                                             decoration: BoxDecoration(
//                                                 color: Colors.black12,
//                                                 borderRadius: BorderRadius
//                                                     .circular(16),
//                                                 border: Border.all(
//                                                     color: Colors
//                                                         .black)),
//                                             child: Column(
//                                               mainAxisAlignment: MainAxisAlignment
//                                                   .end,
//                                               children: [
//                                                 Center(
//                                                     child: Text(
//                                                       'اسم المستخدم',
//                                                       style: TextStyle(
//                                                           fontSize: wi /
//                                                               70),
//                                                     )),
//                                                 Center(
//                                                     child: Text(
//                                                         logic12.name !=
//                                                             null
//                                                             ? logic12
//                                                             .name!
//                                                             : '',
//                                                         style: TextStyle(
//                                                             fontSize: wi /
//                                                                 65))),
//                                                 SizedBox(
//                                                   height: hi / 100,
//                                                 )
//                                               ],
//                                             ),
//                                           ),
//                                           SizedBox(
//                                             height: hi / 100,
//                                           ),
//                                           Container(
//                                             width: wi / 3.5,
//                                             decoration: BoxDecoration(
//                                                 color: Colors.black12,
//                                                 borderRadius: BorderRadius
//                                                     .circular(16),
//                                                 border: Border.all(
//                                                     color: Colors
//                                                         .black)),
//                                             child: Column(
//                                               mainAxisAlignment: MainAxisAlignment
//                                                   .end,
//                                               children: [
//                                                 Center(
//                                                     child: Text(
//                                                       'ايميل المستخدم',
//                                                       style: TextStyle(
//                                                           fontSize: wi /
//                                                               70),
//                                                     )),
//                                                 Center(
//                                                     child: Text(logic12
//                                                         .email != null
//                                                         ? logic12
//                                                         .email!
//                                                         : '',
//                                                         style: TextStyle(
//                                                             fontSize: wi /
//                                                                 70))),
//                                                 SizedBox(
//                                                   height: hi / 100,
//                                                 )
//                                               ],
//                                             ),
//                                           ),
//                                           SizedBox(
//                                             height: hi / 100,
//                                           ),
//                                           Container(
//                                             width: wi / 3.5,
//                                             decoration: BoxDecoration(
//                                                 color: Colors.black12,
//                                                 borderRadius: BorderRadius
//                                                     .circular(16),
//                                                 border: Border.all(
//                                                     color: Colors
//                                                         .black)),
//                                             child: Column(
//                                               mainAxisAlignment: MainAxisAlignment
//                                                   .end,
//                                               children: [
//                                                 Center(
//                                                     child: Text(
//                                                       'رقم هاتف المستخدم',
//                                                       style: TextStyle(
//                                                           fontSize: wi /
//                                                               70),
//                                                     )),
//                                                 Center(
//                                                     child: Text(logic12
//                                                         .phoneNumber !=
//                                                         null
//                                                         ? logic12
//                                                         .phoneNumber!
//                                                         : '',
//                                                         style: TextStyle(
//                                                             fontSize: wi /
//                                                                 65))),
//                                                 SizedBox(
//                                                   height: hi / 100,
//                                                 )
//                                               ],
//                                             ),
//                                           ),
//                                         ],
//                                       )
//                                     ],
//                                   ),
//
//
//                                 ]
//                            ),
//                           ),
//                         )
//                     ) : Container()
//
//
//                   ]
//               );
//             });
//           },
//         ): Center(child: Container(child: Text('لا يوجد منتجات')
//         ,
//         )
//         );
//       },
//     );
//   }
// }





















import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../XXX/XXXFirebase.dart';
import '../Getx/GetInfowUser.dart';

class StreamMapIsNotDelivery extends StatelessWidget {
  StreamMapIsNotDelivery({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.isDelivery,
    this.markerUser,
    this.markerDelivery,
  });

  // المتغيرات الأساسية
  final double latitude; // خط العرض
  final double longitude; // خط الطول
  final bool isDelivery; // حالة التوصيل
  final Uint8List? markerUser; // العلامة الخاصة بالمستخدم
  final Uint8List? markerDelivery; // العلامة الخاصة بالتوصيل

  @override
  Widget build(BuildContext context) {
    double hi = MediaQuery.of(context).size.height; // ارتفاع الشاشة
    double wi = MediaQuery.of(context).size.width; // عرض الشاشة

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection(FirebaseX.collectionApp)
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get(),
      builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('حدث خطأ أثناء استرجاع البيانات.'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        Map<String, dynamic> data11 = snapshot.data!.data() as Map<String, dynamic>;

        // إذا كان هناك UID خاص بالتوصيل
        return data11[FirebaseX.DeliveryUid] != null
            ? StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('DeliveryUser')
              .doc(data11[FirebaseX.DeliveryUid])
              .snapshots(),
          builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('حدث خطأ أثناء استرجاع بيانات التوصيل.'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            Map<String, dynamic> data13 =
            snapshot.data!.data() as Map<String, dynamic>;

            return GetBuilder<GetInfowUser>(
              init: GetInfowUser(
                userId: data11[FirebaseX.DeliveryUid],
                latitude: 0,
                longitude: 0,
              ),
              builder: (logic12) {
                // إنشاء علامات (Markers) للخريطة
                Set<Marker> markers = <Marker>{
                  longitude.isNaN
                      ? Marker(
                    markerId: const MarkerId('1'),
                    position: const LatLng(0, 0),
                  )
                      : Marker(
                    markerId: const MarkerId('1'),
                    position: LatLng(latitude, longitude),
                    icon: BitmapDescriptor.bytes(markerUser!),
                  ),
                  Marker(
                    markerId: const MarkerId('3'),
                    position: LatLng(
                      data13['latitudeDelivery'],
                      data13['longitudeDelivery'],
                    ),
                    icon: BitmapDescriptor.bytes(markerDelivery!),
                    draggable: true,
                    onTap: () {
                      if (!logic12.isDeliveryGetUserInformation) {
                        logic12.isDeliveryGetUserInformation = true;
                        logic12.update();
                      }
                    },
                  ),
                };

                return Stack(
                  children: [
                    // عرض الخريطة
                    SizedBox(
                      height: hi,
                      width: wi,
                      child: GoogleMap(
                        mapType: MapType.hybrid,
                        markers: markers,
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                            data13['latitudeDelivery'],
                            data13['longitudeDelivery'],
                          ),
                          zoom: 17,
                        ),
                      ),
                    ),

                    // عرض معلومات المستخدم عند الضغط على Marker
                    if (logic12.isDeliveryGetUserInformation)
                      Positioned(
                        top: hi / 2.75,
                        bottom: hi / 2.75,
                        right: wi / 6,
                        left: wi / 6,
                        child: _buildUserInfoContainer(logic12, hi, wi),
                      ),
                  ],
                );
              },
            );
          },
        )
            : const Center(
          child: Text('لا يوجد منتجات.'),
        );
      },
    );
  }

  /// بناء واجهة عرض معلومات المستخدم
  Widget _buildUserInfoContainer(GetInfowUser logic12, double hi, double wi) {
    return Container(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(),
                GestureDetector(
                  onTap: () {
                    if (logic12.isDeliveryGetUserInformation) {
                      logic12.isDeliveryGetUserInformation = false;
                      logic12.update();
                    }
                  },
                  child: SizedBox(
                    width: wi / 10,
                    height: hi / 23,
                    child: const Icon(Icons.close),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // عرض الصورة وبيانات المستخدم
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildUserImage(logic12, wi, hi),
                _buildUserDetails(logic12, wi, hi),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// بناء واجهة الصورة الشخصية للمستخدم
  Widget _buildUserImage(GetInfowUser logic12, double wi, double hi) {
    return Container(
      width: wi / 4,
      height: hi / 7,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        image: DecorationImage(
          image: logic12.urlOfUser != null
              ? NetworkImage(logic12.urlOfUser!)
              : const AssetImage('assets/images/default_person.png')
          as ImageProvider,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  /// بناء تفاصيل المستخدم
  Widget _buildUserDetails(GetInfowUser logic12, double wi, double hi) {
    return Column(
      children: [
        _buildUserDataRow('اسم المستخدم', logic12.name ?? '', wi, hi),
        _buildUserDataRow('البريد الإلكتروني', logic12.email ?? '', wi, hi),
        _buildUserDataRow('رقم الهاتف', logic12.phoneNumber ?? '', wi, hi),
      ],
    );
  }

  /// بناء صف لعرض بيانات المستخدم
  Widget _buildUserDataRow(String title, String value, double wi, double hi) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Container(
        width: wi / 3.5,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Center(child: Text(title, style: TextStyle(fontSize: wi / 70))),
            Center(child: Text(value, style: TextStyle(fontSize: wi / 65))),
            SizedBox(height: hi / 100),
          ],
        ),
      ),
    );
  }
}

