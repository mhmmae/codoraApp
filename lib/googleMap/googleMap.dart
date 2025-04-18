// import 'dart:typed_data';
//
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// import '../TheOrder/ViewOeder/GetX/GetGoTOMapDilyvery.dart';
// import '../bottonBar/botonBar.dart';
// import 'class/StreamMapIsDilivery.dart';
// import 'class/StreamMapIsNotDilivery.dart';
//
// class googleMap extends StatelessWidget {
//   bool idDilivery;
//   double latitude;
//   double longitude;
//
//   googleMap({super.key,
//     required this.idDilivery,
//     required this.longitude,
//     required this.latitude,
//     this.markerUser,
//     this.markerDelivery});
//
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
//     return Scaffold(
//         body: Stack(
//           children: [
//             idDilivery
//             // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//             // ---------------------------------------------------------------------------------------------------------------
//             // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//                 ? StreamMapIsDelivery(
//                 isDelivery: idDilivery,
//                 latitude: latitude,
//                 longitude: longitude,
//                 markerUser: markerUser,
//                 markerDelivery: markerDelivery)
//             // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//             // ---------------------------------------------------------------------------------------------------------------
//             // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//                 : StreamMapIsNotDelivery(
//                 isDelivery: idDilivery,
//                 latitude: latitude,
//                 longitude: longitude,
//                 markerUser: markerUser,
//                 markerDelivery: markerDelivery),
//
//             // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//             // ---------------------------------------------------------------------------------------------------------------
//             // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//             Positioned(
//                 top: hi / 17,
//                 left: wi / 20,
//                 child: GetBuilder<GetGoToMapDelivery>(init: GetGoToMapDelivery(),builder: (logic) {
//                   return GestureDetector(
//                     onTap: () {
//                       logic.isLoading= false;
//                       Navigator.pushAndRemoveUntil(
//                           context,
//                           MaterialPageRoute(
//                               builder: (context) =>
//                                   BottomBar(
//                                     theIndex: idDilivery ? 2 : 3,
//                                   )), (rute) => false);
//                     },
//                     child: Container(
//                       width: wi / 4,
//                       height: hi / 22,
//                       decoration: BoxDecoration(
//                           border: Border.all(color: Colors.black),
//                           borderRadius: BorderRadius.only(
//                               topRight: Radius.circular(15),
//                               bottomRight: Radius.circular(15),
//                               topLeft: Radius.circular(200),
//                               bottomLeft: Radius.circular(200)),
//                           color: Colors.red),
//                       child: Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 10),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Icon(
//                               Icons.home,
//                               size: wi / 17,
//                             ),
//                             Icon(
//                               Icons.arrow_back,
//                               size: wi / 13,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   );
//                 })),
//           ],
//         ));
//   }
// }






















import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../TheOrder/ViewOeder/GetX/GetGoTOMapDilyvery.dart';
import '../bottonBar/botonBar.dart';
import 'class/StreamMapIsDilivery.dart';
import 'class/StreamMapIsNotDilivery.dart';

class GoogleMapView extends StatelessWidget {
  final bool isDelivery; // حالة التوصيل (توصيل أو غير توصيل)
  final double latitude; // إحداثيات خط العرض
  final double longitude; // إحداثيات خط الطول
  final Uint8List? markerUser; // صورة العلامة الخاصة بالمستخدم
  final Uint8List? markerDelivery; // صورة العلامة الخاصة بالتوصيل

  GoogleMapView({
    super.key,
    required this.isDelivery,
    required this.latitude,
    required this.longitude,
    this.markerUser,
    this.markerDelivery,
  });

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height; // ارتفاع الشاشة
    double screenWidth = MediaQuery.of(context).size.width; // عرض الشاشة

    return Scaffold(
      body: Stack(
        children: [
          // عرض الخريطة بناءً على حالة التوصيل
          isDelivery
              ? StreamMapIsDelivery(
            isDelivery: isDelivery,
            latitude: latitude,
            longitude: longitude,
            markerUser: markerUser,
            markerDelivery: markerDelivery,
          )
              : StreamMapIsNotDelivery(
            isDelivery: isDelivery,
            latitude: latitude,
            longitude: longitude,
            markerUser: markerUser,
            markerDelivery: markerDelivery,
          ),

          // زر الرجوع إلى الصفحة الرئيسية
          Positioned(
            top: screenHeight / 17,
            left: screenWidth / 20,
            child: GetBuilder<GetGoToMapDelivery>(
              init: GetGoToMapDelivery(),
              builder: (logic) {
                return GestureDetector(
                  onTap: () {
                    logic.isLoading = false;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BottomBar(
                          theIndex: isDelivery ? 2 : 3, // تحديد تبويب العودة
                        ),
                      ),
                          (route) => false,
                    );
                  },
                  child: _buildReturnButton(screenWidth, screenHeight),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// إنشاء زر العودة إلى الصفحة الرئيسية
  Widget _buildReturnButton(double screenWidth, double screenHeight) {
    return Container(
      width: screenWidth / 4,
      height: screenHeight / 22,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(15),
          bottomRight: Radius.circular(15),
          topLeft: Radius.circular(200),
          bottomLeft: Radius.circular(200),
        ),
        color: Colors.red, // لون الزر
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              Icons.home,
              size: screenWidth / 17,
              color: Colors.white,
            ),
            Icon(
              Icons.arrow_back,
              size: screenWidth / 13,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
