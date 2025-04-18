//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
//
//
// import '../../XXX/XXXFirebase.dart';
// import '../../controler/local-notification-onroller.dart';
// import 'DetalesOfItems.dart';
//
// class StreambuilderBoxOfOfferItem extends StatelessWidget {
//    StreambuilderBoxOfOfferItem({super.key,required this.pageController});
//    PageController pageController;
//
//
//   final Stream<QuerySnapshot> ItemofferStream =
//   FirebaseFirestore.instance.collection('Itemoffer').where('appName',isEqualTo: FirebaseX.appName).snapshots();
//
//
//
//
//   @override
//   Widget build(BuildContext context) {
//     double hi = MediaQuery.of(context).size.height;
//     double wi = MediaQuery.of(context).size.width;
//     return StreamBuilder<QuerySnapshot>(
//       stream: ItemofferStream,
//       builder:
//           (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
//         if (snapshot.hasError) {
//           return Text('Something went wrong');
//         }
//
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }
//
//
//         return SizedBox(
//           height: hi/3,
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 12),
//             child: PageView.builder(
//               controller: pageController,
//               itemCount: snapshot.data!.docs.length,
//               scrollDirection: Axis.horizontal,
//               itemBuilder: (context, index) {
//                 DocumentSnapshot dede = snapshot.data!.docs[index];
//
//                 return Container(
//                   decoration: BoxDecoration(
//                       border: Border.all(color: Colors.black),
//                       borderRadius: BorderRadius.circular(15)
//                   ),
//                   child: Column(
//                     children: [
//                       Container(
//
//                         decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.only(
//                                 topLeft: Radius.circular(12),
//                                 topRight: Radius.circular(12))),
//                         width: double.infinity,
//                         height: hi/28,
//                         child: Center(
//                             child: Text(
//                               dede['nameOfItem'],
//                               style: TextStyle(
//                                   color: Colors.black,
//                                   fontSize: wi/35,
//                                   fontWeight: FontWeight.w500,
//                                   fontStyle: FontStyle.italic),
//                             )),
//                       ),
//                       Row(
//                         children: [
//                           Container(
//                             width: wi/3.3,
//                             height: hi/3.4,
//                             decoration: BoxDecoration(
//                                 color: Colors.transparent,
//                                 borderRadius: BorderRadius.only(
//                                     bottomLeft: Radius.circular(12))),
//                             child: Column(
//                               children: [
//                                 Container(
//                                   color: Colors.transparent,
//                                   width: double.infinity,
//                                   height: hi/10,
//                                   child: Center(
//                                       child: Padding(
//                                         padding: const EdgeInsets.only(left: 8),
//                                         child: Text(
//                                           '${dede['rate'].toString()}% Off ',
//                                           style: TextStyle(
//                                               color: Colors.black,
//                                               fontSize: wi/25,
//                                               fontWeight: FontWeight.bold,
//                                               fontStyle: FontStyle.italic),
//                                         ),
//                                       )),
//                                 ),
//                                 Container(
//                                   color: Colors.transparent,
//                                   width: double.infinity,
//                                   height: hi/12,
//                                   child: Center(
//                                       child: Text(
//                                         dede['oldPrice'].toString(),
//                                         style: TextStyle(
//                                             decorationColor: Colors.redAccent,
//                                           decorationThickness: 2,
//                                           decoration: TextDecoration.lineThrough,
//                                             color: Colors.black,
//                                             fontSize: wi/30,
//                                             fontWeight: FontWeight.bold,
//                                             fontStyle: FontStyle.italic),
//                                       )),
//                                 ),
//                                 GestureDetector(
//                                   onTap: ()async{
//
//                                     Navigator.push(context, MaterialPageRoute(builder: (context)=>DetalesOfItems(url:dede['url'] ,priceOfItem:  dede['priceOfItem'],
//                                         typeItem: '',rate: dede['rate'],images: dede["manyImages"]??'',
//                                         nameOfItem: dede['nameOfItem'],descriptionOfItem: dede['descriptionOfItem'],uid:dede['uid'] ,isOffer: true,VideoURL: dede['videoURL']
//                                     )));
//
//
//
//
//
//
//
//
//                                   },
//                                   child: Padding(
//                                     padding: const EdgeInsets.all(8.0),
//                                     child: Container(
//                                       decoration: BoxDecoration(
//                                           color: Colors.blueAccent,
//                                           borderRadius: BorderRadius.circular(16)
//                                       ),
//
//                                       width: double.infinity,
//                                       height: hi/12.4,
//                                       child:  Center(
//                                           child: Text(
//                                             dede['priceOfItem'].toString(),
//                                             style: TextStyle(
//                                                 color: Colors.black,
//                                                 fontSize: wi/30,
//                                                 fontWeight: FontWeight.bold,
//                                                 fontStyle: FontStyle.italic),
//                                           )),
//                                     ),
//                                   ),
//                                 )
//                               ],
//                             ),
//                           ),
//                           Expanded(
//                             child: GestureDetector(
//                               onTap: (){
//                                 Navigator.push(context, MaterialPageRoute(builder: (context)=>DetalesOfItems(url:dede['url'] ,priceOfItem:  dede['priceOfItem'],
//                                   typeItem: '',rate: dede['rate'],images: dede["manyImages"]??'',
//                                   nameOfItem: dede['nameOfItem'],descriptionOfItem: dede['descriptionOfItem'],uid:dede['uid'] ,isOffer: true,VideoURL: dede['videoURL']
//                                 )));
//                               },
//                               child: Container(
//                                 decoration: BoxDecoration(
//                                   color: Colors.white,
//                                   borderRadius: BorderRadius.only(
//                                     topLeft: Radius.circular(12),
//                                       bottomRight: Radius.circular(12)),
//                                   image: DecorationImage(
//                                     fit: BoxFit.cover,
//                                     image: NetworkImage(dede['url']),
//                                   ),
//                                 ),
//                                 width: wi/2,
//                                 height:hi/3.4,
//                                 child: dede['videoURL'] !='noVideo'? Align(alignment: Alignment.topRight,
//                                     child: Container(decoration: BoxDecoration(color: Colors.red,borderRadius: BorderRadius.circular(12)),child: Icon(Icons.videocam_rounded,size: 15,),)):null,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             ),
//           ),
//         );
//       },
//     )
//     ;
//   }
// }












import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../XXX/XXXFirebase.dart';
import 'DetalesOfItems.dart';

class StreambuilderBoxOfOfferItem extends StatelessWidget {
  // Constructor
  StreambuilderBoxOfOfferItem({Key? key, required this.pageController})
      : super(key: key);
  final PageController pageController;

  // Stream لجلب بيانات العروض من Firestore بناءً على appName
  final Stream<QuerySnapshot> itemOfferStream = FirebaseFirestore.instance
      .collection('Itemoffer')
      .where('appName', isEqualTo: FirebaseX.appName)
      .snapshots();

  // دالة للتنقل إلى صفحة تفاصيل العنصر لتقليل التكرار
  void _navigateToDetails(BuildContext context, DocumentSnapshot document) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => DetailsOfItem(
        url: document['url'],
        priceOfItem: document['priceOfItem'],
        typeItem: '',
        rate: document['rate'],
        images: document['manyImages'] ?? '',
        nameOfItem: document['nameOfItem'],
        descriptionOfItem: document['descriptionOfItem'],
        uid: document['uid'],
        isOffer: true,
        videoURL: document['videoURL'],
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final double hi = MediaQuery.of(context).size.height;
    final double wi = MediaQuery.of(context).size.width;

    return StreamBuilder<QuerySnapshot>(
      stream: itemOfferStream,
      builder: (context, snapshot) {
        // حالة الخطأ عند فشل جلب البيانات
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }
        // حالة الانتظار مع عرض مؤشر التحميل
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // عرض البيانات المُستلمة ضمن PageView
        return SizedBox(
          height: hi / 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: PageView.builder(
              controller: pageController,
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                DocumentSnapshot dede = snapshot.data!.docs[index];
                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      // عنوان العنصر
                      _buildTitle(dede['nameOfItem'], hi, wi),
                      // صف يحتوي على تفاصيل العرض والصورة
                      Row(
                        children: [
                          // جزء تفاصيل العرض
                          _buildOfferDetails(context, dede, hi, wi),
                          // جزء الصورة
                          _buildOfferImage(context, dede, hi, wi),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// ودجة لعرض عنوان العنصر
  Widget _buildTitle(String title, double hi, double wi) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      width: double.infinity,
      height: hi / 28,
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            color: Colors.black,
            fontSize: wi / 35,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  /// ودجة لعرض تفاصيل العرض مثل نسبة الخصم، السعر القديم والسعر الحالي مع إمكانية النقر للانتقال للتفاصيل
  Widget _buildOfferDetails(
      BuildContext context, DocumentSnapshot document, double hi, double wi) {
    return Container(
      width: wi / 3.3,
      height: hi / 3.4,
      decoration: const BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          // عرض نسبة الخصم
          Container(
            width: double.infinity,
            height: hi / 10,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  '${document['rate']}% Off',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: wi / 25,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ),
          // السعر القديم مع خط عبره
          Container(
            width: double.infinity,
            height: hi / 12,
            child: Center(
              child: Text(
                document['oldPrice'].toString(),
                style: TextStyle(
                  decoration: TextDecoration.lineThrough,
                  decorationColor: Colors.redAccent,
                  decorationThickness: 2,
                  color: Colors.black,
                  fontSize: wi / 30,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
          // السعر الحالي مع إمكانية النقر للتنقل إلى صفحة التفاصيل
          GestureDetector(
            onTap: () => _navigateToDetails(context, document),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(16),
                ),
                width: double.infinity,
                height: hi / 12.4,
                child: Center(
                  child: Text(
                    document['priceOfItem'].toString(),
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: wi / 30,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ودجة لعرض صورة العنصر، وإذا كان هناك فيديو سيتم عرض أيقونة صغيره في الزاوية
  Widget _buildOfferImage(
      BuildContext context, DocumentSnapshot document, double hi, double wi) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _navigateToDetails(context, document),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            image: DecorationImage(
              fit: BoxFit.cover,
              image: NetworkImage(document['url']),
            ),
          ),
          width: wi / 2,
          height: hi / 3.4,
          child: document['videoURL'] != 'noVideo'
              ? Align(
            alignment: Alignment.topRight,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.videocam_rounded,
                size: 15,
              ),
            ),
          )
              : null,
        ),
      ),
    );
  }
}
