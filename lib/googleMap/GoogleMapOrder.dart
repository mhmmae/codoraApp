// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:get/get.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
//
// import '../bottonBar/botonBar.dart';
// import 'Getx/GetXareYouShorMapOrder.dart';
//
// class GoogleMapOrder extends StatelessWidget {
//   double longitude;
//   double latitude;
//   String tokenUser;
//
//   Uint8List marker;
//
//   GoogleMapOrder({super.key, required this.longitude, required this.latitude, required this.marker,required this.tokenUser});
//
//   late StreamSubscription<Position> positionStream;
//
//
//
//   GoogleMapController? controller2;
//
//   @override
//   Widget build(BuildContext context) {
//     double hi = MediaQuery.of(context).size.height;
//     double wi = MediaQuery.of(context).size.width;
//
//     return Scaffold(
//         body:
//         Stack(
//           children: [
//             GetBuilder<GetxAreYouSureMapOrder>(init: GetxAreYouSureMapOrder(
//                 longitude: longitude, latitude: latitude,tokenUser: tokenUser), builder: (logic) {
//               List<Marker> markers = [
//                 Marker(markerId: MarkerId('1'),
//                     position: LatLng(logic.latitude, logic.longitude),icon: BitmapDescriptor.bytes(marker))
//               ];
//               return logic.isLoading
//                   ? const Align(
//                   alignment: Alignment.center,
//                   child: CircularProgressIndicator()) : GoogleMap(
//                 mapType: MapType.hybrid,
//                 markers: markers.toSet(),
//                 onTap: (LatLng) {
//
//                   logic.longitude = LatLng.longitude;
//                   logic.latitude = LatLng.latitude;
//                   logic.update();
//                 },
//                 initialCameraPosition: CameraPosition(
//                     target: LatLng(logic.latitude, logic.longitude),
//                     zoom: 17),
//                 onMapCreated: (controller) {
//                   controller2 = controller;
//                 },
//               );
//             }),
//             Positioned(
//                 top: hi / 17,
//                 left: wi / 20,
//                 child: GestureDetector(
//                   onTap: () {
//                     Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (context) =>
//                                 BottomBar(
//                                   theIndex: 0,
//                                 )));
//                   },
//                   child: Container(
//                     width: wi / 4,
//                     height: hi / 22,
//                     decoration: BoxDecoration(
//                         border: Border.all(color: Colors.black),
//                         borderRadius: BorderRadius.only(
//                             topRight: Radius.circular(15),
//                             bottomRight: Radius.circular(15),
//                             topLeft: Radius.circular(200),
//                             bottomLeft: Radius.circular(200)),
//                         color: Colors.red),
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 10),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Icon(
//                             Icons.home,
//                             size: wi / 17,
//                           ),
//                           Icon(
//                             Icons.arrow_back,
//                             size: wi / 13,
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 )),
//             GetBuilder<GetxAreYouSureMapOrder>(init: GetxAreYouSureMapOrder(latitude: latitude,longitude: longitude,tokenUser: tokenUser),
//               assignId: true,
//               builder: (logic) {
//                 return Positioned(
//                     bottom: hi / 70,
//                     right: wi / 60,
//                     left: wi / 60,
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 90),
//                       child: GestureDetector(
//                         onTap: () {
//                           logic.showConfirmationDialog(
//                               wi / 30, wi / 25, wi / 27, wi / 30, wi / 60,
//                               context);
//                         },
//                         child: Container(
//                           width: wi,
//                           height: hi / 14,
//                           decoration: BoxDecoration(
//                               color: Colors.deepPurpleAccent,
//                               borderRadius: BorderRadius.circular(15)),
//                           child: Center(
//                               child: Text(
//                                 'ارسال الطلب',
//                                 style: TextStyle(fontSize: wi / 20),
//                               )),
//                         ),
//                       ),
//                     ));
//               },
//             )
//           ],
//         ));
//   }
// }












import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../bottonBar/botonBar.dart';
import 'Getx/GetXareYouShorMapOrder.dart';

class GoogleMapOrder extends StatelessWidget {
  final double longitude; // خط الطول
  final double latitude; // خط العرض
  final String tokenUser; // رمز المستخدم
  final Uint8List marker; // صورة العلامة (Marker)

  GoogleMapOrder({
    super.key,
    required this.longitude,
    required this.latitude,
    required this.marker,
    required this.tokenUser,
  });

  GoogleMapController? controller; // التحكم في الخرائط

  @override
  Widget build(BuildContext context) {
    double hi = MediaQuery.of(context).size.height; // ارتفاع الشاشة
    double wi = MediaQuery.of(context).size.width; // عرض الشاشة

    return Scaffold(
      body: Stack(
        children: [
          // عرض خريطة Google
          GetBuilder<GetxAreYouSureMapOrder>(
            init: GetxAreYouSureMapOrder(
              longitude: longitude,
              latitude: latitude,
              tokenUser: tokenUser,
            ),
            builder: (logic) {
              List<Marker> markers = [
                Marker(
                  markerId: const MarkerId('1'),
                  position: LatLng(logic.latitude, logic.longitude),
                  icon: BitmapDescriptor.bytes(marker),
                ),
              ];

              return logic.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : GoogleMap(
                mapType: MapType.hybrid,
                markers: markers.toSet(),
                onTap: (LatLng position) {
                  logic.longitude = position.longitude;
                  logic.latitude = position.latitude;
                  logic.update();
                },
                initialCameraPosition: CameraPosition(
                  target: LatLng(logic.latitude, logic.longitude),
                  zoom: 17,
                ),
                onMapCreated: (controller) {
                  this.controller = controller;
                },
              );
            },
          ),

          // زر الرجوع إلى الصفحة الرئيسية
          Positioned(
            top: hi / 17,
            left: wi / 20,
            child: GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => BottomBar(theIndex: 0)),
                );
              },
              child: _buildReturnButton(wi, hi),
            ),
          ),

          // زر إرسال الطلب
          GetBuilder<GetxAreYouSureMapOrder>(
            init: GetxAreYouSureMapOrder(
              latitude: latitude,
              longitude: longitude,
              tokenUser: tokenUser,
            ),
            builder: (logic) {
              return Positioned(
                bottom: hi / 30,
                left: wi / 20,
                right: wi / 20,
                child: GestureDetector(
                  onTap: () {
                    logic.showConfirmationDialog(
                      wi / 30, // حجم النص للإلغاء
                      wi / 25, // حجم النص للإرسال
                      wi / 27, // حجم العنوان
                      wi / 30, // حجم النص للمحتوى
                      wi / 60, // المسافة بين العناصر
                      context,
                    );
                  },
                  child: _buildSendButton(wi, hi),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// زر العودة إلى الصفحة الرئيسية
  Widget _buildReturnButton(double wi, double hi) {
    return Container(
      width: wi / 4,
      height: hi / 22,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(15),
          bottomRight: Radius.circular(15),
          topLeft: Radius.circular(200),
          bottomLeft: Radius.circular(200),
        ),
        color: Colors.red,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              Icons.home,
              size: wi / 17,
              color: Colors.white,
            ),
            Icon(
              Icons.arrow_back,
              size: wi / 13,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  /// زر إرسال الطلب
  Widget _buildSendButton(double wi, double hi) {
    return Container(
      width: wi,
      height: hi / 14,
      decoration: BoxDecoration(
        color: Colors.deepPurpleAccent,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Center(
        child: Text(
          'ارسال الطلب',
          style: TextStyle(
            fontSize: wi / 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
