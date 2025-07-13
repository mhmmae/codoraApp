
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../bottonBar/botonBar.dart';
import 'code4.dart';

class ViewImageCode extends StatelessWidget {
  final Uint8List imageData; // الصورة كـ Uint8List
  final String uuid;

  const ViewImageCode({super.key, required this.imageData,required this.uuid});

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    // استخدام GetBuilder لربط الحالة مع TextController
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.8,
              maxScale: 4.0,
              child: Container(
                width: screenWidth,
                height: screenHeight,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: MemoryImage(imageData),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          // زر الإرسال أسفل الشاشة
          GetBuilder<TextController>(
            init: TextController(numberOfCode: 10),
            builder: (logic) {
              return Positioned(
                bottom: screenHeight / 45,
                right: screenWidth / 25,
                child: GestureDetector(
                  onTap: () => logic.sendImage(uuid),
                  child: logic.isSending.value
                      ? const CircularProgressIndicator(strokeWidth: 5)
                      : Container(
                    height: screenHeight / 17,
                    width: screenWidth / 8.5,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Icon(
                      Icons.send,
                      size: screenWidth / 17,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
          // زر الإغلاق أعلى الشاشة
          Positioned(
            top: screenHeight / 35,
            right: screenWidth / 27,
            child: GestureDetector(
              onTap: () {
                Get.offAll(() => BottomBar(initialIndex: 2));
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
