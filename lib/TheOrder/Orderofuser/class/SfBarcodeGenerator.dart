import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_barcodes/barcodes.dart';

class SfBarcodeGenerator2 extends StatelessWidget {
  String uid;
   SfBarcodeGenerator2({super.key,required this.uid});

  @override
  Widget build(BuildContext context) {
    double hi = MediaQuery.of(context).size.height;
    double wi = MediaQuery.of(context).size.width;
    return  SizedBox(
      height: hi/3.4,
      width: wi/2,
      child: SfBarcodeGenerator(
        value: uid,
        symbology: QRCode(),
        showValue: true,
      ),
    );
  }
}
