//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
//
// import '../../XXX/XXXFirebase.dart';
// import 'DetalesOfItems.dart';
// import 'addAndRemoveSearch.dart';
//
// class StreamBuilderOfSearch extends StatelessWidget {
//    StreamBuilderOfSearch({super.key,required this.search});
//    TextEditingController search;
//
//   @override
//   Widget build(BuildContext context) {
//     double hi = MediaQuery.of(context).size.height;
//     double wi = MediaQuery.of(context).size.width;
//     return Column(
//       children: [
//         SizedBox(height: hi/40,),
//         StreamBuilder<QuerySnapshot>(
//           stream: FirebaseFirestore.instance.collection('Item').where('appName',isEqualTo: FirebaseX.appName).orderBy('nameOfItem')
//               .startAt([search.text]).endAt(['${search.text}\uf8ff']).snapshots(),
//
//           builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
//             if (snapshot.hasError) {
//               return Text('Something went wrong');
//             }
//
//
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const Center(child: CircularProgressIndicator());
//             }
//
//             return ListView(
//               shrinkWrap: true,
//               children: snapshot.data!.docs.map((DocumentSnapshot document) {
//                 Map<String, dynamic> dede = document.data()! as Map<String, dynamic>;
//
//                 return Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: Container(
//                     decoration: BoxDecoration(
//                         border: Border.all(color: Colors.black),
//                         borderRadius: BorderRadius.circular(16)
//                     ),
//                     child: ListTile(
//
//                       leading: GestureDetector(
//                         onTap: (){
//                           Navigator.push(context,
//                               MaterialPageRoute(builder: (context) =>
//                                   DetalesOfItems(url: dede['url'],
//                                     rate: 0,
//                                     images: dede["manyImages"]??'',
//                                     typeItem:dede['typeItem'] ,
//                                     priceOfItem: dede['priceOfItem'],
//                                     nameOfItem: dede['nameOfItem'],
//                                     descriptionOfItem: dede['descriptionOfItem'],
//                                     uid: dede['uid'],
//                                     isOffer: false,
//                                     VideoURL: dede['videoURL'],
//                                   )));
//                         },
//                         child: Container(
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(15),
//                               color: Colors.black12
//                           ),
//                           height: hi/15,width: wi/6,
//                           child: Image.network(dede['url'],fit: BoxFit.cover,),
//                         ),
//                       ),
//                       title: Column(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//
//                           Text(dede['nameOfItem'],style: TextStyle(fontSize:wi/33),),
//                           SizedBox(height: hi/70,),
//                           Text(' ${dede['priceOfItem'].toString()} : السعر    ',style: TextStyle(fontSize:wi/33),),
//
//                         ],
//                       ),
//                       trailing: SizedBox(height: hi/28,width: wi/3.3,
//                           child: Center(
//                               child: addAndRemoveSearch(uidItem: dede['uid'],isOfeer: false,wi4: wi/25,))),
//
//
//                     ),
//                   ),
//                 );
//               }).toList(),
//             );
//           },
//         ),
//       ],
//     );
//   }
// }



























import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../XXX/XXXFirebase.dart';
import 'DetalesOfItems.dart';
import 'addAndRemoveSearch.dart';

class StreamBuilderOfSearch extends StatelessWidget {
  /// متحكم النص الخاص بعملية البحث (يجب أن يكون نهائيًا لتقليل إعادة البناء)
  final TextEditingController search;

  StreamBuilderOfSearch({Key? key, required this.search}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // الحصول على أبعاد الشاشة لتحديد أحجام العناصر بناءً عليها
    final double hi = MediaQuery.of(context).size.height;
    final double wi = MediaQuery.of(context).size.width;

    return Column(
      children: [
        // مساحة علوية بسيطة
        SizedBox(height: hi / 40),
        // استخدام StreamBuilder لعرض نتائج البحث من Firestore
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Item')
              .where('appName', isEqualTo: FirebaseX.appName)
              .orderBy('nameOfItem')
              .startAt([search.text])
              .endAt(['${search.text}\uf8ff'])
              .snapshots(),
          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            // التحقق من وجود خطأ أثناء جلب البيانات
            if (snapshot.hasError) {
              return const Center(child: Text('حدث خطأ'));
            }

            // عرض مؤشر التحميل أثناء انتظار البيانات
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // في حال عدم وجود بيانات
            if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('لا توجد نتائج'));
            }

            // استخدام ListView.builder لتحسين الأداء عند بناء القائمة (تُبنى العناصر عند الحاجة فقط)
            return ListView.builder(
              physics: const NeverScrollableScrollPhysics(), // يتم التحكم بالتمرير بواسطة العنصر الأب
              shrinkWrap: true,
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                DocumentSnapshot document = snapshot.data!.docs[index];
                // تحويل البيانات إلى خريطة للسهولة
                Map<String, dynamic> dede = document.data()! as Map<String, dynamic>;

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      // صورة العنصر مع إمكانية النقر للوصول إلى تفاصيل المنتج
                      leading: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailsOfItem(
                                url: dede['url'],
                                rate: 0,
                                images: dede["manyImages"] ?? '',
                                typeItem: dede['typeItem'],
                                priceOfItem: dede['priceOfItem'],
                                nameOfItem: dede['nameOfItem'],
                                descriptionOfItem: dede['descriptionOfItem'],
                                uid: dede['uid'],
                                isOffer: false,
                                videoURL: dede['videoURL'],
                              ),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Colors.black12,
                          ),
                          height: hi / 15,
                          width: wi / 6,
                          child: Image.network(
                            dede['url'],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      // محتوى النص الخاص بالعنصر مثل الاسم والسعر
                      title: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dede['nameOfItem'],
                            style: TextStyle(fontSize: wi / 33),
                          ),
                          SizedBox(height: hi / 70),
                          Text(
                            '${dede['priceOfItem'].toString()} : السعر',
                            style: TextStyle(fontSize: wi / 33),
                          ),
                        ],
                      ),
                      // زر إضافة/إزالة المنتج (يتم تمرير البيانات لهذا العنصر)
                      trailing: SizedBox(
                        height: hi / 28,
                        width: wi / 3.3,
                        child: Center(
                          child: AddAndRemoveSearchWidget(
                            uidItem: dede['uid'],
                            isOfeer: false,
                            wi4: wi / 25,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

