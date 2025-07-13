import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../bottonBar/botonBar.dart';
import 'getPage1.dart';

class BarcodeScannerPage extends StatelessWidget {
  BarcodeScannerPage({super.key});

  // إنشاء المتحكم باستخدام Get.put
  final BarcodeController controller = Get.put(BarcodeController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: (){
            controller.zoomTimer?.cancel(); // إلغاء المؤقت هنا أيضًا لضمان الإيقاف
            Get.offAll(() => BottomBar(initialIndex: 2) );
            },
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(Icons.backspace_outlined),
          ),
        ),
        title: const Text("قراءة الباركود"),
      ),
      body: Obx(
            () => Transform.scale(
          scale: controller.zoomScale.value,
          alignment: Alignment.center,
          child: MobileScanner(
            onDetect: (capture) {
              controller.onDetect(capture, context);
            },
          ),
        ),
      ),
    );
  }
}
