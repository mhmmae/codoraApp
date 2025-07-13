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

  const GoogleMapView({
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
                          initialIndex: isDelivery ? 2 : 3, // تحديد تبويب العودة
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
