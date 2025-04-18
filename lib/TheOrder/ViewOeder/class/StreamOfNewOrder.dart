// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// import '../../../XXX/XXXFirebase.dart';
// import '../GetX/GetDateToText.dart';
// import '../GetX/GetRequest.dart';
//
// class Streamofneworder extends StatelessWidget {
//    Streamofneworder({super.key});
//   bool isloding =false;
//
//
//   @override
//   Widget build(BuildContext context) {
//     double hi = MediaQuery.of(context).size.height;
//     double wi = MediaQuery.of(context).size.width;
//     return FutureBuilder<QuerySnapshot>(
//       future: FirebaseFirestore.instance.collection('order').where('appName' ,isEqualTo: FirebaseX.appName).get(),
//       builder:
//           (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
//
//         if (snapshot.hasError) {
//           return Text("Something went wrong");
//         }
//
//
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator(),);
//         }
//
//
//
//         return ListView(
//             shrinkWrap: true,
//             children: snapshot.data!.docs.map((DocumentSnapshot document){
//               Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
//               return FutureBuilder<DocumentSnapshot>(
//                 future: FirebaseFirestore.instance.collection(FirebaseX.collectionApp).doc(data['uidUser']).get(),
//                 builder:
//                     (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
//
//                   if (snapshot.hasError) {
//                     return Text("Something went wrong");
//                   }
//
//                   if (snapshot.hasData && !snapshot.data!.exists) {
//                     return Text("Document does not exist");
//                   }
//
//                   if (snapshot.connectionState == ConnectionState.done) {
//                     Map<String, dynamic> data1 = snapshot.data!.data() as Map<String, dynamic>;
//                     return Padding(
//                       padding: const EdgeInsets.all(8.0),
//                       child: Column(
//                         children: [
//                           Align(alignment: Alignment.topRight,child: Row(
//                             mainAxisAlignment: MainAxisAlignment.end,
//                             children: [
//                               GetBuilder<GetDateToText>(init: GetDateToText(),builder: (val){
//                                 return Text(val.dateToText(data['timeOrder']),style: TextStyle(fontSize: wi/44),);
//                               }),
//                               SizedBox(width: wi/70,)
//                             ],
//                           )) ,
//                           ListTile(
//                               minTileHeight: hi/10,
//                               minLeadingWidth: wi/7,
//                               leading: Container(height: hi/10,width: wi/7,decoration: BoxDecoration(
//                                   borderRadius: BorderRadius.circular(5),
//                                   border: Border.all(color: Colors.black),
//                                   image: DecorationImage(
//                                       fit: BoxFit.cover,
//                                       image: NetworkImage(data1['url'])
//                                   )                            ),
//                               ),
//
//                               title: Column(
//
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Row(
//                                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                     children: [
//                                       Text(data1['name'],style: TextStyle(fontSize: wi/33),),
//
//
//
//
//
//
//                                     ],
//                                   ),
//                                   SizedBox(height: hi/80,),
//                                   Text(data1['phneNumber'],style: TextStyle(fontSize: wi/44))
//                                 ],
//                               ),
//
//
//                               trailing: SizedBox(
//
//                                 width: wi/3.7,
//                                 height: hi/12,
//                                 child: Row(
//                                   children: [
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//                                     GetBuilder<Getrequest>(init: Getrequest(),builder: (val){
//                                       return  GestureDetector(
//                                         onTap: (){
//                                           val.RequestRejection(data['uidUser'],wi,context);
//                                         },
//                                         child: !data['Delivery'] ? Container(
//                                           width: wi/8,height: hi/12,
//                                           decoration: BoxDecoration(
//                                               color: Colors.black12,
//                                               border: Border.all(color: Colors.black),
//                                               borderRadius: BorderRadius.circular(10)
//                                           ),
//                                           child: Icon(Icons.dangerous_rounded,size: wi/14,color: Colors.red,),
//                                         ):SizedBox(width: wi/8,height: hi/12,),
//                                       );
//                                     }),
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//                                     SizedBox(width: wi/50,),
//                                    GetBuilder<Getrequest>(init: Getrequest(),builder: (val){
//                                      return GestureDetector(
//                                        onTap: (){
//                                          isloding = true;
//                                          val.update();
//
//                                          val.RequestAccept(data['uidUser']);
//                                        },
//                                        child: isloding == false ? data['RequestAccept']==false? Badge(
//                                          smallSize: wi/30,
//
//                                          isLabelVisible: true,
//                                          child: Container(
//                                            width: wi/8,height: hi/12,
//                                            decoration: BoxDecoration(color: Colors.black12,
//                                                border: Border.all(color: Colors.black),
//                                                borderRadius: BorderRadius.circular(10)
//                                            ),
//                                            child: Icon(Icons.done,size: wi/14,color: Colors.green,),
//                                          ),
//                                        ):Container(
//                                          width: wi/8,height: hi/12,
//                                          decoration: BoxDecoration(color: Colors.black12,
//                                              border: Border.all(color: Colors.black),
//                                              borderRadius: BorderRadius.circular(10)
//                                          ),
//                                          child: Icon(Icons.done,size: wi/14,color: Colors.green,),
//                                        ):CircularProgressIndicator(),
//                                      );
//                                    })
//                                   ],
//                                 ),
//                               ),
//                               shape: RoundedRectangleBorder(
//                                   side: const BorderSide(color: Colors.black),
//                                   borderRadius: BorderRadius.circular(10)
//                               )
//                           ),
//                           SizedBox(height: hi/50,)
//                         ],
//                       ),
//                     );
//                   }
//
//                   return const Center(child: CircularProgressIndicator(),);
//                 },
//               );
//             }).toList()
//         );
//       },
//     );
//   }
// }































import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../XXX/XXXFirebase.dart';
import '../GetX/GetDateToText.dart';
import '../GetX/GetRequest.dart';

/// ودجة عرض قائمة الطلبات الجديدة للمستخدم.
/// تقوم الودجة باسترجاع الطلبات من Firestore وعرضها باستخدام ListView.builder،
/// مع استخدام FutureBuilders منفصلة لجلب بيانات كل مستخدم متصل بالطلب.
/// يتم تحديث الواجهة وإظهار رسائل الخطأ إذا حدث أي خلل أثناء تحميل البيانات.
class StreamOfNewOrder extends StatelessWidget {
  const StreamOfNewOrder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // الحصول على أبعاد الشاشة
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;

    // استعلام جلب الطلبات التي تحمل قيمة appName معينة
    final Future<QuerySnapshot> ordersFuture = FirebaseFirestore.instance
        .collection('order')
        .where('appName', isEqualTo: FirebaseX.appName)
        .get();

    return FutureBuilder<QuerySnapshot>(
      future: ordersFuture,
      builder: (context, ordersSnapshot) {
        if (ordersSnapshot.hasError) {
          return const Center(
              child: Text("حدث خطأ أثناء جلب الطلبات. الرجاء المحاولة مرة أخرى"));
        }
        if (ordersSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (ordersSnapshot.data == null || ordersSnapshot.data!.docs.isEmpty) {
          return const Center(child: Text("لا توجد بيانات للطلب"));
        }

        // قائمة المستندات المأخوذة من Firestore
        final List<QueryDocumentSnapshot> ordersDocs = ordersSnapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: ordersDocs.length,
          itemBuilder: (context, index) {
            final DocumentSnapshot orderDoc = ordersDocs[index];
            final Map<String, dynamic> orderData =
            orderDoc.data()! as Map<String, dynamic>;

            // جلب بيانات المستخدم المتصل بالطلب
            final Future<DocumentSnapshot> userFuture =
            FirebaseFirestore.instance
                .collection(FirebaseX.collectionApp)
                .doc(orderData['uidUser'])
                .get();

            return FutureBuilder<DocumentSnapshot>(
              future: userFuture,
              builder: (context, userSnapshot) {
                if (userSnapshot.hasError) {
                  return const Center(
                      child: Text("حدث خطأ أثناء جلب بيانات المستخدم"));
                }
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                // التأكد من وجود بيانات المستخدم
                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return const Center(child: Text("المستخدم غير موجود"));
                }

                final Map<String, dynamic> userData =
                userSnapshot.data!.data()! as Map<String, dynamic>;

                // بناء بطاقة الطلب باستخدام Card و ListTile
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      // عرض التاريخ في أعلى البطاقة مع المحاذاة لليمين
                      Align(
                        alignment: Alignment.topRight,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            GetBuilder<GetDateToText>(
                              init: GetDateToText(),
                              builder: (dateController) {
                                return Text(
                                  dateController.dateToText(orderData['timeOrder']),
                                  style: TextStyle(fontSize: width / 44),
                                );
                              },
                            ),
                            SizedBox(width: width / 70),
                          ],
                        ),
                      ),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(color: Colors.black),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          minTileHeight: height / 10,
                          minLeadingWidth: width / 7,
                          // عرض صورة المنتج باستخدام NetworkImage من بيانات المستخدم
                          leading: Container(
                            height: height / 10,
                            width: width / 7,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: Colors.black),
                              image: DecorationImage(
                                fit: BoxFit.cover,
                                image: NetworkImage(userData['url']),
                              ),
                            ),
                          ),
                          // عرض اسم المنتج والسعر
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userData['name'],
                                style: TextStyle(fontSize: width / 43),
                              ),
                              SizedBox(height: height / 90),
                              Text(
                                ' ${userData['phneNumber'].toString()}',
                                style: TextStyle(fontSize: width / 45),
                              ),
                            ],
                          ),
                          // عرض العدد وخيارات التفاعل (مثل قبول أو رفض الطلب)
                          trailing: Container(
                            width: width / 3.5,
                            height: height / 12,
                            child: Row(
                              children: [
                                // زر رفض الطلب باستخدام GetRequest
                                GetBuilder<Getrequest>(
                                  init: Getrequest(),
                                  builder: (reqController) {
                                    return GestureDetector(
                                        onTap: () {
                                      reqController.RequestRejection(
                                          orderData['uidUser'], width, context);
                                    },
                                    child: !orderData['Delivery']
                                    ? Container(
                                    width: width / 8,
                                    height: height / 12,
                                    decoration: BoxDecoration(
                                    color: Colors.black12,
                                    border: Border.all(color: Colors.black),
                                    borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                    Icons.dangerous_rounded,
                                    size: width / 14,
                                    color: Colors.red,
                                    ),
                                    )
                                        : SizedBox(
                                    width: width / 9,
                                    height: height / 12,
                                    )
                                     );
                                  },
                                ),
                                SizedBox(width: width / 50),
                                // زر قبول الطلب using GetRequest
                                GetBuilder<Getrequest>(
                                  init: Getrequest(),
                                  builder: (reqController) {
                                    return GestureDetector(
                                      onTap: () {
                                        reqController.RequestAccept(orderData['uidUser']);
                                      },
                                      child: orderData['RequestAccept'] == false
                                          ? Badge(
                                        smallSize: width / 30,
                                        isLabelVisible: true,

                                        child: Container(
                                          width: width / 9,
                                          height: height / 12,
                                          decoration: BoxDecoration(
                                            color: Colors.black12,
                                            border: Border.all(color: Colors.black),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            Icons.done,
                                            size: width / 14,
                                            color: Colors.green,
                                          ),
                                        ),
                                      )
                                          : Container(
                                        width: width / 8,
                                        height: height / 12,
                                        decoration: BoxDecoration(
                                          color: Colors.black12,
                                          border: Border.all(color: Colors.black),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          Icons.done,
                                          size: width / 14,
                                          color: Colors.green,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: height / 50),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
