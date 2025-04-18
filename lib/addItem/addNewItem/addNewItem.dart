// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'informationOFItem.dart';
//
// class viewImage extends StatelessWidget {
//   viewImage({
//     super.key,
//     required this.uint8list,
//     required this.TypeItem,
//   });
//
//   Uint8List uint8list;
//   String TypeItem;
//
//   @override
//   Widget build(BuildContext context) {
//     double hi = MediaQuery.of(context).size.height;
//     double wi = MediaQuery.of(context).size.width;
//     return Scaffold(
//       body: Stack(
//         children: [
//           Container(
//             decoration: BoxDecoration(
//                 image: DecorationImage(
//                     fit: BoxFit.fill,
//                     image: MemoryImage(
//                       uint8list,
//                     ))),
//           ),
//           Positioned(
//               bottom: hi / 12,
//               right: wi / 12,
//               child: GestureDetector(
//                 onTap: () {
//                   Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                           builder: (context) => InformationOfItem(
//                                 TypeItem: TypeItem,
//                                 uint8list: uint8list,
//                               )));
//                 },
//                 child: Container(
//                     height: hi / 12,
//                     width: wi / 5,
//                     decoration: BoxDecoration(
//                         border: Border.all(color: Colors.blueAccent, width: 2),
//                         color: Colors.white70,
//                         borderRadius: BorderRadius.circular(10)),
//                     child: Icon(
//                       Icons.send,
//                       size: 45,
//                       color: Colors.blueAccent,
//                     )),
//               )),
//           Positioned(
//               bottom: hi / 12,
//               left: wi / 12,
//               child: GestureDetector(onTap: (){
//                 Navigator.pop(context);
//               },
//                 child: Container(
//                     height: hi / 12,
//                     width: wi / 5,
//                     decoration: BoxDecoration(
//                         border: Border.all(color: Colors.red, width: 2),
//                         color: Colors.white70,
//                         borderRadius: BorderRadius.circular(10)),
//                     child: Icon(
//                       Icons.keyboard_backspace_sharp,
//                       size: 45,
//                       color: Colors.red,
//                     )),
//               )),
//
//
//         ],
//       ),
//     );
//   }
// }














import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'informationOFItem.dart';

class ViewImage extends StatelessWidget {
  ViewImage({
    super.key,
    required this.uint8list,
    required this.TypeItem,
  });

  final Uint8List uint8list; // جعل المتغير final
  final String TypeItem; // جعل المتغير final

  @override
  Widget build(BuildContext context) {
    double hi = MediaQuery.of(context).size.height;
    double wi = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          // خلفية الصورة المتناسقة
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.cover, // تنسيق الصورة بشكل احترافي
                  image: MemoryImage(uint8list),
                ),
              ),
            ),
          ),
          // زر إرسال
          Positioned(
            bottom: hi / 12,
            right: wi / 12,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InformationOfItem(
                      TypeItem: TypeItem,
                      uint8list: uint8list,
                    ),
                  ),
                );
              },
              child: Container(
                height: hi / 12,
                width: wi / 5,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blueAccent, width: 2),
                  color: Colors.white.withBlue(3),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.send,
                  size: 45,
                  color: Colors.blueAccent,
                ),
              ),
            ),
          ),
          // زر العودة
          Positioned(
            bottom: hi / 12,
            left: wi / 12,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                height: hi / 12,
                width: wi / 5,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red, width: 2),
                  color: Colors.white.withAlpha(6),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.shade50,
                      blurRadius: 8,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.keyboard_backspace_sharp,
                  size: 45,
                  color: Colors.red,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
