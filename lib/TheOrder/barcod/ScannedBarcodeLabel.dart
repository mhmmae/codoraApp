
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'GetxBarCode/GetXBarCode.dart';

class ScannedBarcodeLabel extends StatelessWidget {
  const ScannedBarcodeLabel({
    super.key,
    required this.barcodes,
    required this.controller
  });

  final Stream<BarcodeCapture> barcodes;
  final MobileScannerController controller;


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
    return GetBuilder<Getxbarcode>(init: Getxbarcode(controller: controller),builder: (logic) {
      return StreamBuilder(
        stream: barcodes,
        builder: (context, snapshot) {
          final scannedBarcodes = snapshot.data?.barcodes ?? [];

          if (scannedBarcodes.isEmpty) {
            return Text(
              'قم بمسح باركود العميل',

              overflow: TextOverflow.fade,
              style: TextStyle(color: Colors.white, fontSize: wi / 44),
            );
          }
          else if (scannedBarcodes.isNotEmpty) {

              WidgetsBinding.instance.addPostFrameCallback((BuildContext) async {
                logic.BarCodeScanner(scannedBarcodes, context);


              });


          }

          return Text(
            scannedBarcodes.first.displayValue ?? 'No display value.',
            overflow: TextOverflow.fade,
            style: const TextStyle(color: Colors.white),
          );
        },
      );
    });
  }
}