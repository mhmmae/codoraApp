// import 'package:flutter/material.dart';
//
// import 'class/SendAndTotalPrice.dart';
// import 'class/StreamListOfItem.dart';
//
// class theChosen extends StatelessWidget {
//    theChosen({super.key,required this.uid});
//    String uid;
//
//   @override
//   Widget build(BuildContext context) {
//     double hi = MediaQuery.of(context).size.height;
//     double wi = MediaQuery.of(context).size.width;
//
//     return Scaffold(
//         extendBodyBehindAppBar: true,
//         body: Column(children: [
//           Container(
//             height: hi / 8,
//             color: Colors.white10,
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20),
//               child: Column(
//                 children: [
//                   SizedBox(
//                     height: hi / 20,
//                   ),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Row(
//                         children: [
//                           SizedBox(
//                             width: wi / 18,
//                           ),
//                           Text(
//                             'card',
//                             style: TextStyle(fontSize: wi / 20),
//                           )
//                         ],
//                       ),
//                       Icon(
//                         Icons.dehaze_rounded,
//                         size: wi / 14,
//                       )
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           Container(
//               decoration: BoxDecoration(
//                   border: Border.all(color: Colors.black),
//                   color: Colors.black12,
//                   borderRadius: BorderRadius.circular(15)),
//               height: hi / 1.70,
//               child: ListView(
//                 shrinkWrap: true,
//                 primary: true,
//                 children: [
//
//                   StreamListOfItem()
//
//                 ],
//               )),
//           // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--------------------^^^^^^^^^^^^^^^^^^^^^^
//           // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--------------------^^^^^^^^^^^^^^^^^^^^^^
//           // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--------------------^^^^^^^^^^^^^^^^^^^^^^
//           SendAndTotalPrice(uid: uid,)
//         ]));
//   }
// }


























import 'package:flutter/material.dart';

import 'class/SendAndTotalPrice.dart';
import 'class/StreamListOfItem.dart';

/// شاشة عرض السلة (The Chosen Items)
/// تُظهر الشريط العلوي مع عنوان "Card"، قسم عرض قائمة العناصر الموجودة في السلة،
/// وقسم عرض إجمالي السعر وزر "إرسال الطلب".
class TheChosen extends StatelessWidget {
  final String uid;

  const TheChosen({Key? key, required this.uid}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // الحصول على أبعاد الشاشة لاستخدامها في تحديد أحجام العناصر
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;

    return Scaffold(
      // تمديد التخطيط خلف AppBar (إذا كان هناك أي AppBar مضاف لاحقاً)
      extendBodyBehindAppBar: true,
      body: Column(
        children: [
          // القسم العلوي: شريط العنوان
          Container(
            height: height / 8,
            color: Colors.white10,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                SizedBox(height: height / 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // عرض عنوان "Card" مع مسافة بادئة
                    Row(
                      children: [
                        SizedBox(width: width / 18),
                        Text(
                          'Card',
                          style: TextStyle(fontSize: width / 20),
                        ),
                      ],
                    ),
                    // أيقونة القائمة
                    Icon(
                      Icons.dehaze_rounded,
                      size: width / 14,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // قسم عرض قائمة العناصر (السلة)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              color: Colors.black12,
              borderRadius: BorderRadius.circular(15),
            ),
            height: height / 1.80,
            child: ListView(
              shrinkWrap: true,
              primary: true,
              children:  [
                // ودجة عرض قائمة العناصر من السلة
                StreamListOfItem(),
              ],
            ),
          ),
          // قسم عرض إجمالي السعر وزر إرسال الطلب
          SendAndTotalPrice(uid: uid),
        ],
      ),
    );
  }
}

