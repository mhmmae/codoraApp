
//
//
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// import '../GetXController/GetAddAndRemove.dart';
// import '../GetXController/GetSendandtotalprice.dart';
//
// class Sendandtotalprice extends StatelessWidget {
//   String uid;
//    Sendandtotalprice({super.key,required this.uid});
//
//
//
//    // Getsendandtotalprice controller = Get.put(Getsendandtotalprice());
//
//      @override
//   Widget build(BuildContext context) {
//     double hi = MediaQuery.of(context).size.height;
//     double wi = MediaQuery.of(context).size.width;
//     return
//       Container(
//         width: double.infinity,
//         height: hi/5.23,
//         color: Colors.white10,
//         child: Column(
//           children: [
//             SizedBox(
//               height: 2,
//             ),
//             Padding(
//               padding:  EdgeInsets.symmetric(horizontal: wi/20),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     'total:',
//                     style: TextStyle(
//                         fontSize: wi/18, color: Colors.deepPurpleAccent),
//                   ),
//                   Row(
//                     children: [
//                       GetBuilder<GetAddAndRemove>(init: GetAddAndRemove(),builder: (val){
//                         return Text('${val.total}',style: TextStyle(
//                             fontSize: wi/25, color: Colors.deepPurpleAccent),);
//                       },),
//
//
//                       SizedBox(width: 8,),
//                       Text(
//                         'iq',
//                         style: TextStyle(
//                             fontSize: wi/30, color: Colors.green),
//                       ),
//                     ],
//                   )
//                 ],
//               ),
//             ),
//             SizedBox(
//               height: hi/50,
//             ),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 90),
//
//               child: GetBuilder<Getsendandtotalprice>(init: Getsendandtotalprice(uid:uid ),builder: (val){
//                 return val.isLoding? const CircularProgressIndicator() : GestureDetector(
//                   onTap: ()async{
//                   await  val.send();
//                     },
//                   child: Container(
//                     width: double.infinity,
//                     height: hi/14,
//                     decoration: BoxDecoration(
//                         color: Colors.deepPurpleAccent,
//                         borderRadius: BorderRadius.circular(15)),
//                     child: Center(child: Text('ارسال الطلب',style: TextStyle(fontSize: wi/20),)),
//                   ),
//                 );
//               },)
//             ),
//           ],
//
//         ),
//       );
//   }
// }























import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../GetXController/GetAddAndRemove.dart';
import '../GetXController/GetSendandtotalprice.dart';

/// ودجة عرض لإجمالي السعر مع زر إرسال الطلب.
/// تستخدم هذه الودجة متحكمي GetAddAndRemove (لعرض إجمالي السعر) و
/// Getsendandtotalprice (لتنفيذ إرسال الطلب).
class SendAndTotalPrice extends StatelessWidget {
  final String uid;

  const SendAndTotalPrice({Key? key, required this.uid}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // الحصول على أبعاد الشاشة
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      height: height / 5.23,
      color: Colors.white10,
      padding: EdgeInsets.symmetric(vertical: height * 0.02),
      child: Column(
        children: [
          // عرض إجمالي السعر في السلة
          Padding(
            padding: EdgeInsets.symmetric(horizontal: width / 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total:',
                  style: TextStyle(
                    fontSize: width / 18,
                    color: Colors.deepPurpleAccent,
                  ),
                ),
                Row(
                  children: [
                    GetBuilder<GetAddAndRemove>(
                      // استخدام المتحكم لعرض السعر الإجمالي
                      init: GetAddAndRemove(),
                      builder: (controller) {
                        return Text(
                          '${controller.total.value}',
                          style: TextStyle(
                            fontSize: width / 25,
                            color: Colors.deepPurpleAccent,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'IQ',
                      style: TextStyle(
                        fontSize: width / 30,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // زر إرسال الطلب
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 90),
            child: GetBuilder<GetSendAndTotalPrice>(
              init: GetSendAndTotalPrice(uid: uid),
              builder: (controller) {
                return controller.isLoading.value
                    ? const CircularProgressIndicator()
                    : GestureDetector(
                  onTap: () async {
                    try {
                      // تنفيذ عملية ارسال الطلب
                      await controller.send();
                    } catch (e) {
                      Get.snackbar(
                        'خطأ',
                        'حدث خطأ أثناء إرسال الطلب: $e',
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                      );
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: height / 14,
                    decoration: BoxDecoration(
                      color: Colors.deepPurpleAccent,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Text(
                        'ارسال الطلب',
                        style: TextStyle(
                          fontSize: width / 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
