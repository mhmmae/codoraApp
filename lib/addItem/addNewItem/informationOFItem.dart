import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'class/ClassOfAddItem.dart';
import 'class/ClassOfAddOferItem.dart';

class InformationOfItem extends StatelessWidget {
  InformationOfItem({
    super.key,
    required this.uint8list,
    required this.TypeItem,
  });

  String TypeItem;
  Uint8List uint8list;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Stack(
          children: [
            TypeItem == 'Item'

                ? ClassOfAddItem(
                    uint8list1: uint8list,
                    TypeItem: TypeItem,
                  )
      // =================================================================================================
      // =================================================================================================
                : ClassOfAddOfferItem(
                    uint8list1: uint8list,
                    TypeItem: TypeItem,
                  )
          ],
        ),
      ),
    );
  }
}







//
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'class/ClassOfAddItem.dart';
// import 'class/ClassOfAddOferItem.dart';
//
// class InformationOfItem extends StatelessWidget {
//   const InformationOfItem({
//     super.key,
//     required this.uint8list,
//     required this.TypeItem,
//   });
//
//   final String TypeItem;
//   final Uint8List uint8list;
//
//   @override
//   Widget build(BuildContext context) {
//     double hi = MediaQuery.of(context).size.height;
//     double wi = MediaQuery.of(context).size.width;
//
//     return
//       // Scaffold(
//       // appBar: AppBar(
//       //   title: Text(
//       //     _getTitle(),
//       //     style: TextStyle(fontSize: wi / 20),
//       //   ),
//       //   // centerTitle: true,
//       //   backgroundColor: Colors.blueAccent,
//       // ),
//       // body: Padding(
//       //   padding: EdgeInsets.symmetric(horizontal: wi / 20, vertical: hi / 50),
//       //   child: Center(
//       //     child: Container(
//       //       constraints: BoxConstraints(
//       //         maxWidth: wi * 0.9, // تقيد العرض لتجنب التجاوز
//       //         maxHeight: hi * 0.8, // تقيد الارتفاع لتجنب التجاوز
//       //       ),
//       //       padding: EdgeInsets.all(wi / 40),
//       //       decoration: BoxDecoration(
//       //         borderRadius: BorderRadius.circular(15),
//       //         color: Colors.white,
//       //         boxShadow: [
//       //           BoxShadow(
//       //             color: Colors.grey.shade400,
//       //             blurRadius: 8,
//       //             offset: const Offset(2, 2),
//       //           ),
//       //         ],
//       //       ),
//       //       child: Stack(
//       //     children: [
//       //       TypeItem == 'Item'
//       //           ? ClassOfAddItem(
//       //               uint8list1: uint8list,
//       //               TypeItem: TypeItem,
//       //             )
//       // // =================================================================================================
//       // // =================================================================================================
//       //           : Classofaddoferitem(
//       //               uint8list1: uint8list,
//       //               TypeItem: TypeItem,
//       //             );
//     //       ],
//     //     ),
//     //       ),
//     //     ),
//     //   ),
//     // );
//   }
//
//   /// دالة تُعيد العنوان بناءً على `TypeItem`
//   String _getTitle() {
//     return TypeItem == 'Item' ? "إضافة منتج" : "إضافة منتج عليه عرض";
//   }
//
//   /// دالة لتحديد العنصر المناسب بناءً على `TypeItem`
//   Widget _buildDynamicWidget() {
//     final Map<String, Widget> itemWidgets = {
//       'Item': ClassOfAddItem(
//         uint8list1: uint8list,
//         TypeItem: TypeItem,
//       ),
//       'ItemOffer': Classofaddoferitem(
//         uint8list1: uint8list,
//         TypeItem: TypeItem,
//       ),
//     };
//
//     return itemWidgets[TypeItem] ??
//         const Center(
//           child: Text(
//             "نوع العنصر غير معروف!",
//             style: TextStyle(color: Colors.red, fontSize: 16),
//           ),
//         );
//   }
// }
