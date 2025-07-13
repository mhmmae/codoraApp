
import 'package:flutter/material.dart';

import 'enhanced_orders_view.dart';

/// شاشة عرض طلبات الشراء للمستخدم.
/// تعرض هذه الشاشة قائمة الطلبات وتحتوي على أزرار للتفاعل مع عملية مسح الباركود
/// وخدمة التوصيل عبر الخريطة.
class ViewOrder extends StatelessWidget {
  final String uid;

  const ViewOrder({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    // الحصول على أبعاد الشاشة لضبط الأحجام نسبياً
    final double height = MediaQuery.of(context).size.height;

    return Scaffold(
      // appBar: AppBar(
      //   // تخصيص عرض الleading لتوفير مساحة لأزرار التفاعل
      //   leadingWidth: width / 4,
      //   leading: Row(
      //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //     children: [
      //       // مسافة بادئة
      //       SizedBox(width: width / 50),
      //       // زر لمسح الباركود
      //       GetBuilder<GetxBarcode>(
      //         init: GetxBarcode(),
      //         builder: (barcodeController) {
      //           return GestureDetector(
      //             onTap: () {
      //               // إعادة ضبط متغير العملية (up) لتفعيل المسح جديداً
      //               barcodeController.up = 0;
      //               Navigator.push(
      //                 context,
      //                 MaterialPageRoute(
      //                   builder: (context) => BarcodeScannerScreen(),
      //                 ),
      //               );
      //             },
      //             child: SizedBox(
      //               height: height / 18,
      //               width: width / 7,
      //               child: Center(
      //                 child: Icon(
      //                   Icons.document_scanner,
      //                   size: width / 12,
      //                   color: Colors.black,
      //                 ),
      //               ),
      //             ),
      //           );
      //         },
      //       ),
      //       // زر عرض الخريطة (التوصيل)
      //       GetBuilder<GetGoToMapDelivery>(
      //         init: GetGoToMapDelivery(),
      //         builder: (mapController) {
      //           if (mapController.numberOfMaps >= 1) {
      //             return GestureDetector(
      //               onTap: () async {
      //                 await mapController.loadMarkers();
      //                 await mapController.send();
      //               },
      //               child: mapController.isLoading
      //                   ? SizedBox(
      //                 width: width / 20,
      //                 height: height / 30,
      //                 child: const CircularProgressIndicator(
      //                   color: Colors.black45,
      //                 ),
      //               )
      //                   : SizedBox(
      //                 width: width / 20,
      //                 height: height / 30,
      //                 child: Badge(
      //                   smallSize: 10,
      //                   label: Text(
      //                     '${mapController.numberOfMaps}',
      //                     style: const TextStyle(fontSize: 6),
      //                   ),
      //                   child: Icon(
      //                     Icons.map,
      //                     size: width / 12,
      //                     color: Colors.black,
      //                   ),
      //                 ),
      //               ),
      //             );
      //           } else {
      //             return SizedBox(
      //               width: width / 20,
      //               height: height / 30,
      //               child: Icon(
      //                 Icons.map,
      //                 size: width / 12,
      //                 color: Colors.white,
      //               ),
      //             );
      //           }
      //         },
      //       ),
      //     ],
      //   ),
      //   centerTitle: true,
      //   title: Text(
      //     'طلبات الشراء',
      //     style: TextStyle(fontSize: width / 25,color: Colors.black54),
      //   ),
      // ),
      // قائمة جانبية (Drawer) مخصصة
      // محتوى الشاشة: قائمة الطلبات المحسنة
      body: Column(
        children: [
          SizedBox(height: height / 45),
          // استخدام Expanded لملء باقي المساحة المتاحة لعرض قائمة الطلبات
          Expanded(child: EnhancedOrdersView()),
        ],
      ),
    );
  }
}
