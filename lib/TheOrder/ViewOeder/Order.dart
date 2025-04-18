// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// import '../../XXX/XXXFirebase.dart';
// import '../barcod/GetxBarCode/GetXBarCode.dart';
// import '../barcod/barcode.dart';
// import 'GetX/GetGoTOMapDilyvery.dart';
// import 'class/Drawer.dart';
// import 'class/StreamOfNewOrder.dart';
//
// class ViewOeder extends StatelessWidget {
//    const ViewOeder({super.key});
//
//
//   @override
//   Widget build(BuildContext context) {
//     double hi = MediaQuery
//         .of(context)
//         .size
//         .height;
//     double wi = MediaQuery
//         .of(context)
//         .size
//         .width;
//     return Scaffold(
//       appBar: AppBar(
//         leadingWidth: wi / 4,
//         leading: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             SizedBox(
//               width: wi / 50,
//             ),
//             // {{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
//             // {{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
//             // {{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
//             GetBuilder<GetxBarcode>(init: GetxBarcode(),builder: (logic) {
//               return GestureDetector(
//                 onTap: () {
//                   logic.up =0;
//                   Navigator.push(context,
//                       MaterialPageRoute(builder: (context) => BarcodeScannerScreen()));
//                 },
//                 child: SizedBox(
//                   height: hi / 18,
//                   width: wi / 7,
//                   child: SizedBox(
//                     width: wi / 20,
//                     height: hi / 30,
//                     child: Icon(
//                       Icons.document_scanner,
//                       size: wi / 14,
//                     ),
//                   ),
//                 ),
//               );
//             }),
//             // {{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
//             // {{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
//             // {{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
//
//             GetBuilder<GetGoToMapDelivery>(
//               init: GetGoToMapDelivery(),
//
//               builder: (val) {
//                 return val.numberOfMaps >= 1 ? GestureDetector(
//                   onTap: () async {
//                     await val.loadMarkers();
//                     await val.send();
//                   },
//                   child:val.isLoading? SizedBox(width: wi / 20,
//                       height: hi / 30,child: CircularProgressIndicator())
//                       : SizedBox(
//                           width: wi / 20,
//                           height: hi / 30,
//                           child: Badge(
//                             smallSize: 10,
//                             label: Text('${val.numberOfMaps}'),
//                             textStyle: TextStyle(fontSize: 6),
//                             child: Icon(
//                               Icons.map,
//                               size: wi / 12,
//                             ),
//                           ),
//
//
//                   )
//                 ):SizedBox(
//                   width: wi / 20,
//                   height: hi / 30,
//
//                     child: Icon(
//                       Icons.map,
//                       size: wi / 12,
//                     ),
//
//
//
//                 );
//               },
//             ),
//           ],
//         ),
//         // {{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
//         // {{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
//         // {{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
//         centerTitle: true,
//         title: Text(
//           'طلبات الشراء',
//           style: TextStyle(fontSize: wi / 25),
//         ),
//       ),
//       // {{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
//       // {{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
//       // {{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
//
//
//       endDrawer:Drawer2(),
//
//
//
//       // {{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
//       // {{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
//       // {{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
//
//       body: Column(
//         children: [
//           SizedBox(
//             height: hi / 45,
//           ),
//
//
//           // {{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
//           // {{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
//           // {{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
//
//
//          Streamofneworder(),
//         ],
//       ),
//     );
//   }
// }
//



















import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../bottonBar/botonBar.dart';
import '../barcod/GetxBarCode/GetXBarCode.dart';
import '../barcod/barcode.dart';
import 'GetX/GetGoTOMapDilyvery.dart';
import 'class/Drawer.dart';
import 'class/StreamOfNewOrder.dart';

/// شاشة عرض طلبات الشراء للمستخدم.
/// تعرض هذه الشاشة قائمة الطلبات وتحتوي على أزرار للتفاعل مع عملية مسح الباركود
/// وخدمة التوصيل عبر الخريطة.
class ViewOrder extends StatelessWidget {
  final String uid;

  const ViewOrder({Key? key, required this.uid}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // الحصول على أبعاد الشاشة لضبط الأحجام نسبياً
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        // تخصيص عرض الleading لتوفير مساحة لأزرار التفاعل
        leadingWidth: width / 4,
        leading: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // مسافة بادئة
            SizedBox(width: width / 50),
            // زر لمسح الباركود
            GetBuilder<GetxBarcode>(
              init: GetxBarcode(),
              builder: (barcodeController) {
                return GestureDetector(
                  onTap: () {
                    // إعادة ضبط متغير العملية (up) لتفعيل المسح جديداً
                    barcodeController.up = 0;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BarcodeScannerScreen(),
                      ),
                    );
                  },
                  child: SizedBox(
                    height: height / 18,
                    width: width / 7,
                    child: Center(
                      child: Icon(
                        Icons.document_scanner,
                        size: width / 12,
                        color: Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
            // زر عرض الخريطة (التوصيل)
            GetBuilder<GetGoToMapDelivery>(
              init: GetGoToMapDelivery(),
              builder: (mapController) {
                if (mapController.numberOfMaps >= 1) {
                  return GestureDetector(
                    onTap: () async {
                      await mapController.loadMarkers();
                      await mapController.send();
                    },
                    child: mapController.isLoading
                        ? SizedBox(
                      width: width / 20,
                      height: height / 30,
                      child: const CircularProgressIndicator(
                        color: Colors.black45,
                      ),
                    )
                        : SizedBox(
                      width: width / 20,
                      height: height / 30,
                      child: Badge(
                        smallSize: 10,
                        label: Text(
                          '${mapController.numberOfMaps}',
                          style: const TextStyle(fontSize: 6),
                        ),
                        child: Icon(
                          Icons.map,
                          size: width / 12,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  );
                } else {
                  return SizedBox(
                    width: width / 20,
                    height: height / 30,
                    child: Icon(
                      Icons.map,
                      size: width / 12,
                      color: Colors.white,
                    ),
                  );
                }
              },
            ),
          ],
        ),
        centerTitle: true,
        title: Text(
          'طلبات الشراء',
          style: TextStyle(fontSize: width / 25,color: Colors.black54),
        ),
      ),
      // قائمة جانبية (Drawer) مخصصة
      endDrawer: const Drawer2(),
      // محتوى الشاشة: قائمة الطلبات
      body: Column(
        children: [
          SizedBox(height: height / 45),
          // استخدام Expanded لملء باقي المساحة المتاحة لعرض قائمة الطلبات
          const Expanded(child: StreamOfNewOrder()),
        ],
      ),
    );
  }
}
