 import 'package:flutter/material.dart';

class Classofsetingofperonall extends StatelessWidget {
   const Classofsetingofperonall({super.key});

   @override
   Widget build(BuildContext context) {
     double hi = MediaQuery.of(context).size.height;
     double wi = MediaQuery.of(context).size.width;
     return Column(
       children: [
         Padding(
           padding: const EdgeInsets.symmetric(
               horizontal: 20, vertical: 10),
           child: Align(
               alignment: Alignment.topRight,
               child: Text('اعدادات عامة')),
         ),
         Padding(
           padding: const EdgeInsets.symmetric(horizontal: 3),
           child: Container(
             decoration: BoxDecoration(
                 color: Colors.black12,
                 borderRadius: BorderRadius.circular(6),
                 border: Border.all(color: Colors.black)),
             child: Column(
               children: [
                 SizedBox(
                   height: hi / 100,
                 ),
                 Container(
                   height: hi / 25,
                   decoration: BoxDecoration(),
                   child: Padding(
                     padding:
                     const EdgeInsets.symmetric(horizontal: 20),
                     child: Row(
                       mainAxisAlignment: MainAxisAlignment.end,
                       children: [
                         Text(
                           'مشاركة التطبيق',
                           style: TextStyle(fontSize: wi / 30),
                         ),
                         SizedBox(
                           width: wi / 30,
                         ),
                         Icon(Icons.share)
                       ],
                     ),
                   ),
                 ),
                 Divider(),
                 Container(
                   height: hi / 25,
                   decoration: BoxDecoration(),
                   child: Padding(
                     padding:
                     const EdgeInsets.symmetric(horizontal: 20),
                     child: Row(
                       mainAxisAlignment: MainAxisAlignment.end,
                       children: [
                         Text(
                           'قيم التطبيق',
                           style: TextStyle(fontSize: wi / 30),
                         ),
                         SizedBox(
                           width: wi / 30,
                         ),
                         Icon(Icons.star)
                       ],
                     ),
                   ),
                 ),
                 Divider(),
                 Container(
                   height: hi / 25,
                   decoration: BoxDecoration(),
                   child: Padding(
                     padding:
                     const EdgeInsets.symmetric(horizontal: 20),
                     child: Row(
                       mainAxisAlignment: MainAxisAlignment.end,
                       children: [
                         Text(
                           'تواصل مع الشركة المنفذة للتطبيق',
                           style: TextStyle(fontSize: wi / 30),
                         ),
                         SizedBox(
                           width: wi / 30,
                         ),
                         Icon(Icons.phone)
                       ],
                     ),
                   ),
                 ),
                 SizedBox(
                   height: hi / 100,
                 ),
               ],
             ),
           ),
         )
       ],
     );
   }
 }
