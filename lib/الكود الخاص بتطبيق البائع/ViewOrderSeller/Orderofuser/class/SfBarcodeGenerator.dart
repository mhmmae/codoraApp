




import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_barcodes/barcodes.dart';

/// ودجة تولد رمز QR باستخدام مكتبة Syncfusion Barcode Generator.
/// يتم عرض قيمة [uid] كنص مع رمز QR مُولد.
class SfBarcodeGenerator2 extends StatelessWidget {
  final String uid;

  const SfBarcodeGenerator2({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    // الحصول على أبعاد الشاشة لاستخدامها في تحديد حجم رمز الباركود
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;
    return SizedBox(
      height: height * 0.3,
      width: width * 0.5,
      child: SfBarcodeGenerator(
        value: uid,
        symbology: QRCode(),
        showValue: true,
      ),
    );
  }
}
