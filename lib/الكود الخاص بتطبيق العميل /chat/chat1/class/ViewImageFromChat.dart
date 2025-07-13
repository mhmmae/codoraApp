


import 'package:flutter/material.dart';

class ViewImageFromChat extends StatelessWidget {
  const ViewImageFromChat({
    super.key,
    required this.imageUrl,
    required this.uid,
  });

  final String imageUrl; // رابط الصورة
  final String uid; // معرف المستخدم

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black, // خلفية داكنة لتحسين العرض
      body: Stack(
        children: [
          // عرض الصورة مع دعم التناسق
          InteractiveViewer(
            // إضافة إمكانية التكبير والتصغير للصورة
            panEnabled: true,
            minScale: 0.8,
            maxScale: 4.0,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.contain, // الحفاظ على تناسق الصورة داخل الشاشة
                    image: NetworkImage(imageUrl),
                  ),
                ),
                width: screenWidth,
                height: screenHeight,
              ),
            ),
          ),

          // زر الإغلاق أعلى الصورة
          Positioned(
            top: screenHeight / 35,
            right: screenWidth / 27,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context); // إغلاق الشاشة
              },
              child: Container(
                height: screenHeight / 17,
                width: screenWidth / 8.5,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Icon(
                  Icons.cancel,
                  size: screenWidth / 12.5,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
