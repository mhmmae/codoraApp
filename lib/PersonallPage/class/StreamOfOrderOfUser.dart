// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// import '../../Model/ModelOrder.dart';
// import '../../TheOrder/ViewOeder/GetX/GetGoTOMapDilyvery.dart';
// import '../../XXX/XXXFirebase.dart';
// import '../../googleMap/googleMap.dart';
//
// class Streamoforderofuser extends StatelessWidget {
//   Streamoforderofuser({super.key});
//
//   CollectionReference TheOrder = FirebaseFirestore.instance.collection('order');
//
//   @override
//   Widget build(BuildContext context) {
//     double hi = MediaQuery.of(context).size.height;
//     double wi = MediaQuery.of(context).size.width;
//     return FutureBuilder<DocumentSnapshot>(
//       future: TheOrder.doc(FirebaseAuth.instance.currentUser!.uid).get(),
//       builder:
//           (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
//         if (snapshot.hasError) {
//           return Text("Something went wrong");
//         }
//
//         if (snapshot.hasData && !snapshot.data!.exists) {
//           return Text("");
//         }
//
//         if (snapshot.connectionState == ConnectionState.done) {
//           ModleOrder order = ModleOrder.fromMap(  snapshot.data!.data() as Map<String, dynamic>);
//
//           return snapshot.data!.exists
//               ? Container(
//                   height: order.Delivery ? hi / 3.5 : hi / 4.5,
//                   width: wi,
//                   color: Colors.transparent,
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 2),
//                         child: Container(
//                           decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(5),
//                               border: Border.all(
//                                   color: order.RequestAccept
//                                       ? Colors.green
//                                       : Colors.red,
//                                   width: 2)),
//                           child: Column(
//                             children: [
//
//                               Container(
//                                   width: wi / 3.20,
//                                   height: hi / 6.3,
//                                   decoration:  BoxDecoration(
//                                       color: Colors.black12,
//
//                                       image: DecorationImage(
//                                         fit: BoxFit.cover,
//                                           image: AssetImage(ImageX.imageofColok)))),
//                               Padding(
//                                 padding: EdgeInsets.symmetric(horizontal: 2),
//                                 child: order.Delivery
//                                     ? SizedBox(
//                                         height: hi / 18,
//                                         width: wi / 3.25,
//                                         child: Text(
//                                           'تم تجهيز الطلب',
//                                           style: TextStyle(
//                                               fontSize: wi / 30,
//                                               color: Colors.green),
//                                         ))
//                                     : order.RequestAccept
//                                         ? SizedBox(
//                                             height: hi / 18,
//                                             width: wi / 3.25,
//                                             child: Text(
//                                               'يتم الان تجهيز طلبك',
//                                               style:
//                                                   TextStyle(fontSize: wi / 37),
//                                             ))
//                                         : SizedBox(
//                                             height: hi / 18,
//                                             width: wi / 3.25,
//                                             child: Text(
//                                                 'الرجاء الانتظار يتم قبول الطلب',
//                                                 style: TextStyle(
//                                                     fontSize: wi / 40))),
//                               )
//                             ],
//                           ),
//                         ),
//                       ),
//                       Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 2),
//                         child: GetBuilder<Getgotomapdilyvery>(
//                             init: Getgotomapdilyvery(),
//                             builder: (logic) {
//                               return GestureDetector(
//                                 onTap: () async {
//                                   if (order.Delivery == true) {
//                                     if (order.doneDelivery == false) {
//                                       await logic.IconMarckt();
//                                       await Navigator.push(
//                                         context,
//                                         MaterialPageRoute(
//                                           builder: (context) => googleMap(
//                                             idDilivery: false,
//                                             longitude: order.longitude,
//                                             latitude: order.latitude,
//                                             markerDelivery:
//                                                 logic.markerDelivery,
//                                             markerUser: logic.markerUser,
//                                           ),
//                                         ),
//                                       );
//                                     }
//                                   }
//                                 },
//                                 child: Container(
//                                   decoration: BoxDecoration(
//                                       borderRadius: BorderRadius.circular(5),
//                                       border: Border.all(
//                                           color: order.Delivery
//                                               ? Colors.green
//                                               : Colors.red,
//                                           width: 2)),
//                                   child: Column(
//                                     children: [
//                                       Container(
//                                           width: wi / 3.25,
//                                           height: hi / 6.3,
//                                           decoration: BoxDecoration(
//                                               color: Colors.black12,
//                                               image: DecorationImage(
//                                                   fit: BoxFit.cover,
//
//                                                   image: AssetImage(
//                                                       ImageX.imageofdilivery)))),
//                                       Padding(
//                                           padding: EdgeInsets.symmetric(
//                                               horizontal: 2),
//                                           child: order.doneDelivery
//                                               ? SizedBox(
//                                                   height: hi / 18,
//                                                   width: wi / 3.55,
//                                                   child: Text(
//                                                     'شكرا لآختيارك متجرنا',
//                                                     style: TextStyle(
//                                                         fontSize: wi / 37,
//                                                         color: Colors.green),
//                                                   ))
//                                               : order.Delivery
//                                                   ? SizedBox(
//                                                       height: hi / 15,
//                                                       width: wi / 3.25,
//                                                       child: Text(
//                                                         'الطلب في طريقه اليك (اضغط على الصورة لعرض الخريطة)',
//                                                         style: TextStyle(
//                                                             fontSize: wi / 50,
//                                                             color:
//                                                                 Colors.green),
//                                                       ))
//                                                   : order.RequestAccept
//                                                       ? SizedBox(
//                                                           height: hi / 18,
//                                                           width: wi / 3.25,
//                                                           child: Text(
//                                                             'يتم الان تجهيز طلبك',
//                                                             style: TextStyle(
//                                                                 fontSize:
//                                                                     wi / 37),
//                                                           ))
//                                                       : SizedBox(
//                                                           height: hi / 18,
//                                                           width: wi / 3.25,
//                                                           child: Text(
//                                                               'الرجاء الانتظار يتم قبول الطلب',
//                                                               style: TextStyle(
//                                                                   fontSize: wi /
//                                                                       40))))
//                                     ],
//                                   ),
//                                 ),
//                               );
//                             }),
//                       ),
//                       Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 2),
//                         child: Container(
//                           decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(5),
//                               border: Border.all(
//                                   color: order.doneDelivery
//                                       ? Colors.green
//                                       : Colors.red,
//                                   width: 2)),
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.start,
//                             children: [
//                               Container(
//                                   width: wi / 3.40,
//                                   height: hi / 6.3,
//                                   decoration: BoxDecoration(
//                                       color: Colors.black12,
//                                       image: DecorationImage(
//                                           fit: BoxFit.cover,
//
//                                           image: AssetImage(
//                                               ImageX.imageofDiliveryDone)))),
//                               Padding(
//                                   padding: EdgeInsets.symmetric(horizontal: 2),
//                                   child: order.doneDelivery
//                                       ? SizedBox(
//                                           height: hi / 18,
//                                           width: wi / 3.55,
//                                           child: Text(
//                                             'اضغط لعرض قائمة المشتريات',
//                                             style: TextStyle(
//                                                 color: Colors.green,
//                                                 fontSize: wi / 37),
//                                           ))
//                                       : order.Delivery
//                                           ? SizedBox(
//                                               height: hi / 12,
//                                               width: wi / 3.55,
//                                               child: Text(
//                                                 'الطلب في طريقه اليك ',
//                                                 style: TextStyle(
//                                                     fontSize: wi / 30,
//                                                     color: Colors.green),
//                                               ))
//                                           : order.RequestAccept
//                                               ? SizedBox(
//                                                   height: hi / 18,
//                                                   width: wi / 3.55,
//                                                   child: Text(
//                                                     'يتم الان تجهيز طلبك',
//                                                     style: TextStyle(
//                                                         fontSize: wi / 37),
//                                                   ))
//                                               : SizedBox(
//                                                   height: hi / 18,
//                                                   width: wi / 3.55,
//                                                   child: Text(
//                                                       'الرجاء الانتظار يتم قبول الطلب',
//                                                       style: TextStyle(
//                                                           fontSize: wi / 40))))
//                             ],
//                           ),
//                         ),
//                       )
//                     ],
//                   ),
//                 )
//               : Container(
//                   height: hi / 3,
//                   width: wi,
//                   color: Colors.red,
//                 );
//         }
//
//         return Text("");
//       },
//     );
//   }
// }



























import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../Model/ModelOrder.dart';
import '../../TheOrder/ViewOeder/GetX/GetGoTOMapDilyvery.dart';
import '../../XXX/XXXFirebase.dart';
import '../../googleMap/googleMap.dart';

/// ويدجت رئيسية تتحمل عملية جلب معلومات الطلب وعرض حالة الطلب للمستخدم
class UserOrderStream extends StatelessWidget {
  UserOrderStream({Key? key}) : super(key: key);

  /// مجموعة طلبات Firebase
  final CollectionReference orders =
  FirebaseFirestore.instance.collection('order');

  @override
  Widget build(BuildContext context) {
    final double hi = MediaQuery.of(context).size.height;
    final double wi = MediaQuery.of(context).size.width;

    return FutureBuilder<DocumentSnapshot>(
      future: orders.doc(FirebaseAuth.instance.currentUser!.uid).get(),
      builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        // معالجة الأخطاء
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "حدث خطأ أثناء جلب البيانات. الرجاء المحاولة مرة أخرى.",
              textAlign: TextAlign.center,
            ),
          );
        }

        // عرض مؤشر الانتظار أثناء التحميل
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // التحقق من وجود البيانات
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(
            child: Text("لا توجد طلبات حالياً."),
          );
        }

        try {
          // معالجة بيانات الطلب وتحويلها إلى نموذج
          final ModleOrder order = ModleOrder.fromMap(
              snapshot.data!.data() as Map<String, dynamic>);

          // بناء واجهة عرض الطلب بناءً على حالة الطلب
          return Container(
            height: order.Delivery ? hi / 3.5 : hi / 4.5,
            width: wi,
            color: Colors.transparent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // القسم الأيسر: عرض صورة مع معلومات حالة تجهيز الطلب
                OrderStatusLeftSection(
                  order: order,
                  hi: hi,
                  wi: wi,
                ),
                // القسم الأيمن: عرض تفاصيل حالة التسليم مع إمكانية التفاعل (مثل فتح الخريطة أو قائمة المشتريات)
                OrderStatusRightSection(
                  order: order,
                  hi: hi,
                  wi: wi,
                ),

              ],
            ),
          );
        } catch (e) {
          // التقاط الأخطاء أثناء معالجة البيانات
          return Center(
            child: Text(
              "حدث خطأ أثناء معالجة البيانات: $e",
              textAlign: TextAlign.center,
            ),
          );
        }
      },
    );
  }
}

/// ويدجت تعرض القسم الأيسر لحالة الطلب، مثل صورة الطلب ونص حالة التجهيز.
///
/// تُحدد هذه الودجت واجهة القسم بناءً على:
/// - إذا كان الطلب قد تم تسليمه بالفعل.
/// - إذا كان الطلب قيد المعالجة أو في انتظار القبول.
class OrderStatusLeftSection extends StatelessWidget {
  final ModleOrder order;
  final double hi;
  final double wi;

  const OrderStatusLeftSection({
    Key? key,
    required this.order,
    required this.hi,
    required this.wi,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // تحديد لون الحدود بناءً على حالة قبول الطلب
    Color borderColor = order.RequestAccept ? Colors.green : Colors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Column(
          children: [
            // صورة الطلب (مثلاً صورة رمزية أو صورة من الأصول)
            Container(
              width: wi / 3.20,
              height: hi / 6.3,
              decoration: BoxDecoration(
                color: Colors.black12,
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: NetworkImage(ImageX.imageofColok),
                ),
              ),
            ),
            // عرض نص حالة الطلب بناءً على الشروط المختلفة
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _buildOrderProcessingText(context),
            ),
          ],
        ),
      ),
    );
  }

  /// تقوم هذه الدالة بتوليد النص المناسب بناءً على حالة الطلب
  Widget _buildOrderProcessingText(BuildContext context) {
    if (order.doneDelivery) {
      // حالة انتهاء التسليم
      return SizedBox(
        height: hi / 18,
        width: wi / 3.25,
        child: Text(
          'تمت عملية التسليم بنجاح',
          style: TextStyle(fontSize: wi / 37, color: Colors.green),
          textAlign: TextAlign.center,
        ),
      );
    } else if (order.Delivery) {
      // حالة الطلب في طريقه إليك مع إشارة بأنه يمكن الضغط لعرض الخريطة
      return SizedBox(
        height: hi / 15,
        width: wi / 3.25,
        child: Text(
          'الطلب في طريقه إليك ',
          style: TextStyle(fontSize: wi / 50, color: Colors.green),
          textAlign: TextAlign.center,
        ),
      );
    } else if (order.RequestAccept) {
      // حالة تجهيز الطلب
      return SizedBox(
        height: hi / 18,
        width: wi / 3.25,
        child: Text(
          'يتم الآن تجهيز طلبك',
          style: TextStyle(fontSize: wi / 37),
          textAlign: TextAlign.center,
        ),
      );
    } else {
      // الحالة الافتراضية عند انتظار قبول الطلب
      return SizedBox(
        height: hi / 18,
        width: wi / 3.25,
        child: Text(
          'الرجاء الانتظار، يتم قبول الطلب',
          style: TextStyle(fontSize: wi / 40),
          textAlign: TextAlign.center,
        ),
      );
    }
  }
}

/// ويدجت تعرض القسم الأيمن الذي يحتوي على تفاصيل التسليم مع إمكانية التفاعل
/// مثل الضغط لعرض الخريطة أو قائمة المشتريات حسب حالة الطلب.
class OrderStatusRightSection extends StatelessWidget {
  final ModleOrder order;
  final double hi;
  final double wi;

  const OrderStatusRightSection({
    Key? key,
    required this.order,
    required this.hi,
    required this.wi,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // استخدام GetBuilder لإدارة منطق الخريطة والتفاعل معها
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: GetBuilder<GetGoToMapDelivery>(
        init: GetGoToMapDelivery(),
        builder: (logic) {
          return GestureDetector(
            onTap: () async {
              try {
                // إذا كان الطلب للتسليم ولم يكتمل التسليم بعد
                if (order.Delivery && !order.doneDelivery) {
                  await logic.loadMarkers();
                  // التنقل إلى شاشة الخريطة مع تمرير المعطيات اللازمة
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GoogleMapView(
                        isDelivery: false,
                        longitude: order.longitude,
                        latitude: order.latitude,
                        markerDelivery: logic.markerDelivery,
                        markerUser: logic.markerUser,
                      ),
                    ),
                  );
                }
              } catch (e) {
                // التعامل مع الأخطاء أثناء التفاعل وعرض رسالة للمستخدم باستخدام GetX Snackbar
                Get.snackbar(
                  'خطأ',
                  'حدث خطأ أثناء فتح الخريطة: $e',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                    color: order.Delivery ? Colors.green : Colors.red,
                    width: 2),
              ),
              child: Column(
                children: [
                  // عرض صورة توضيحية لحالة التسليم؛ تُختار الصورة بناءً على حالة التسليم
                  Container(
                    width: wi / 3.25,
                    height: hi / 6.3,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      image: DecorationImage(
                        fit: BoxFit.cover,
                        image: order.doneDelivery
                            ? NetworkImage(ImageX.imageofDiliveryDone)
                            : NetworkImage(ImageX.imageofdilivery),
                      ),
                    ),
                  ),
                  // عرض نص يوضح حالة التسليم أو يوفر تعليمات إضافية
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _buildDeliveryStatusText(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// دالة مساعدة لتوليد النص المناسب بناءً على حالة التسليم
  Widget _buildDeliveryStatusText() {
    if (order.doneDelivery) {
      return SizedBox(
        height: hi / 18,
        width: wi / 3.55,
        child: Text(
          'اضغط لعرض قائمة المشتريات',
          style: TextStyle(color: Colors.green, fontSize: wi / 37),
          textAlign: TextAlign.center,
        ),
      );
    } else if (order.Delivery) {
      return SizedBox(
        height: hi / 12,
        width: wi / 3.55,
        child: Text(
          'الطلب في طريقه إليك(اضغط على الصورة لعرض الخريطة)',
          style: TextStyle(fontSize: wi / 30, color: Colors.green),
          textAlign: TextAlign.center,
        ),
      );
    } else if (order.RequestAccept) {
      return SizedBox(
        height: hi / 18,
        width: wi / 3.55,
        child: Text(
          'يتم الآن تجهيز طلبك',
          style: TextStyle(fontSize: wi / 37),
          textAlign: TextAlign.center,
        ),
      );
    } else {
      return SizedBox(
        height: hi / 18,
        width: wi / 3.55,
        child: Text(
          'الرجاء الانتظار، يتم قبول الطلب',
          style: TextStyle(fontSize: wi / 40),
          textAlign: TextAlign.center,
        ),
      );
    }
  }
}
