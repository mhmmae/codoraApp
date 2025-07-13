





import 'package:flutter/material.dart';
import 'class/SfBarcodeGenerator.dart';
import 'class/StreamOrderOfUser.dart';

/// شاشة عرض طلبات المستخدم.
/// تعرض قائمة المنتجات المختارة من الطلب مع رمز QR يعرض معرف المستخدم.
/// تمّ تصميم الواجهة باستخدام AppBar مخصص وبناء قائمة مرتبة.
class OrderOfUser extends StatelessWidget {
  final String uid;

  const OrderOfUser({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    // الحصول على أبعاد الشاشة
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: SizedBox(
            height: height / 28,
            width: width / 9,
            child: Icon(
              Icons.backspace,
              size: width / 18,
              color: Colors.blueAccent,
            ),
          ),
        ),
        title: Text(
          'طلب المستخدم',
          style: TextStyle(fontSize: width / 25),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          // عرض قائمة المنتجات في الطلب
          StreamOrderOfUser(uid: uid),
          SizedBox(height: height / 25),
          // عرض رمز QR باستخدام Syncfusion Barcode Generator
          Center(child: SfBarcodeGenerator2(uid: uid)),
        ],
      ),
    );
  }
}
