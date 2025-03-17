import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../bottonBar/botonBar.dart';
import 'GetxBarCode/GetXBarCode.dart';
import 'ScannedBarcodeLabel.dart';
import 'ScannerErrorWidget.dart';

class barcode extends StatefulWidget {
  const barcode({super.key});

  @override
  State<barcode> createState() => _barcodeState();
}

class _barcodeState extends State<barcode> {

  final MobileScannerController controller = MobileScannerController();

  final PageController pageController = PageController();


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
    return Scaffold(
      appBar: AppBar(leading: GestureDetector(onTap: () async {
        await controller.stop();
        Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (context) => bottonBar(theIndex: 2,)), (rule)=> false);
      },
          child: SizedBox(height: hi / 50,
              width: wi / 20,
              child: Icon(Icons.backspace, size: wi / 15,))),
        title: Text('ماسح الباركود', style: TextStyle(fontSize: wi / 25),),
        centerTitle: true,),
      backgroundColor: Colors.black,
      body: GetBuilder<Getxbarcode>(init: Getxbarcode(controller: controller),builder: (logic) {
        return PageView(
          controller: pageController,
          onPageChanged: (index) async {
            // Stop the camera view for the current page,
            // and then restart the camera for the new page.
            await controller.stop();

            // When switching pages, add a delay to the next start call.
            // Otherwise the camera will start before the next page is displayed.
            await Future.delayed(const Duration(seconds: 1, milliseconds: 500));

            if (!mounted) {
              return;
            }
            controller.stop().then((val) {
              unawaited(controller.start());
            });
          },
          children: [
            _BarcodeScannerPage(controller: controller),
             SizedBox(),
            _BarcodeScannerPage(controller: controller),
            _BarcodeScannerPage(controller: controller),
          ],
        );
      }),
    );
  }

  @override
  Future<void> dispose() async {
    pageController.dispose();

    super.dispose();
    await controller.dispose();
  }
}

class _BarcodeScannerPage extends StatelessWidget {
  const _BarcodeScannerPage({required this.controller});

  final MobileScannerController controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MobileScanner(
          controller: controller,
          fit: BoxFit.contain,
          errorBuilder: (context, error, child) {
            return ScannerErrorWidget(error: error);
          },
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            alignment: Alignment.bottomCenter,
            height: 100,
            color: Colors.black.withOpacity(0.4),
            child: Center(
              child: ScannedBarcodeLabel(
                barcodes: controller.barcodes, controller: controller,),
            ),
          ),
        ),
      ],
    );
  }
}
