


import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'GetxBarCode/GetXBarCode.dart';
import 'ScannedBarcodeLabel.dart';
import 'ScannerErrorWidget.dart';
import '../../bottonBar/botonBar.dart';

/// الشاشة الرئيسية لمسح الباركود باستخدام الكاميرا.
/// تحتوي على AppBar شفاف وخلفية بتدرج لوني، ويتم عرض عدة صفحات
/// باستخدام PageView مع أنيميشن عند التبديل. كما يتم عرض نتيجة المسح
/// في أسفل الشاشة مع تأثير fade-in لجعل التجربة أكثر ديناميكية.
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController scannerController = MobileScannerController();
  final PageController pageController = PageController();

  @override
  Widget build(BuildContext context) {
    final double hi = MediaQuery.of(context).size.height;
    final double wi = MediaQuery.of(context).size.width;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.3),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'ماسح الباركود',
          style: TextStyle(fontSize: wi / 25),
        ),
        leading: GestureDetector(
          onTap: () async {
            await scannerController.stop();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (context) => BottomBar(initialIndex: 2)),
                  (route) => false,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(Icons.arrow_back, size: wi / 15),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.grey],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: GetBuilder<GetxBarcode>(
          init: GetxBarcode(controller: scannerController),
          builder: (barcodeController) {
            return PageView(
              controller: pageController,
              onPageChanged: (index) async {
                // عند تغيير الصفحة، نقوم بإيقاف الكاميرا ثم إعادة تشغيلها بعد تأخير بسيط
                await scannerController.stop();
                await Future.delayed(const Duration(milliseconds: 1500));
                if (!mounted) return;
                await scannerController.start();
              },
              children:  [
                _BarcodeScannerPage(controller: scannerController),
                // يمكن إضافة صفحات أخرى أو استخدام Placeholder
                SizedBox(),
                _BarcodeScannerPage(controller: scannerController),
                _BarcodeScannerPage(controller: scannerController),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    pageController.dispose();
    scannerController.dispose();
    super.dispose();
  }
}

/// صفحة المسح الفردية التي تعرض الكاميرا مع Overlay وجزء النتيجة.
/// تحتوي على إطار مسح مع حواف دائرية وخط مسح متحرك، بالإضافة إلى منطقة النتيجة
/// التي تظهر بتأثير fade-in.
class _BarcodeScannerPage extends StatefulWidget {
  const _BarcodeScannerPage({required this.controller});
  final MobileScannerController controller;

  @override
  State<_BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<_BarcodeScannerPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _scanLineAnimation;

  // متغير للتحكم في شفافية منطقة النتيجة (ScannedBarcodeLabel)
  double _bottomOpacity = 0.0;

  @override
  void initState() {
    super.initState();

    // إعداد AnimationController لحركة خط المسح
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _scanLineAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);

    // بدء أنيميشن الشفافية لمنطقة النتيجة بعد تأخير طفيف
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _bottomOpacity = 1.0;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // استخدام Stack لعرض الكاميرا مع Overlay
    return Stack(
      children: [
        // عرض الكاميرا باستخدام MobileScanner
        MobileScanner(
          controller: widget.controller,
          fit: BoxFit.cover,
          errorBuilder: (context, error) {
            return ScannerErrorWidget(error: error);
          },
        ),
        // عرض منطقة المسح (Overlay) مع إطار أبيض
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.width * 0.8,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        // خط مسح متحرك داخل منطقة المسح
        Center(
          child: AnimatedBuilder(
            animation: _scanLineAnimation,
            builder: (context, child) {
              double scanAreaHeight = MediaQuery.of(context).size.width * 0.8;
              double offsetY = _scanLineAnimation.value * scanAreaHeight - (scanAreaHeight / 2);
              return Transform.translate(
                offset: Offset(0, offsetY),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: 2,
                  color: Colors.redAccent,
                ),
              );
            },
          ),
        ),
        // منطقة عرض نتيجة الباركود مع تأثير fade-in
        Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedOpacity(
            opacity: _bottomOpacity,
            duration: const Duration(milliseconds: 800),
            child: Container(
              height: 100,
              color: Colors.black.withOpacity(0.4),
              child: Center(
                child: ScannedBarcodeLabel(
                  barcodes: widget.controller.barcodes,
                  controller: widget.controller,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
