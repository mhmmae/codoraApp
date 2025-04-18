// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// import '../../XXX/XXXFirebase.dart';
// import '../../widget/TextFormFiled.dart';
// import '../Get-Controllar/GetStreamBuildBoxOfItem.dart';
// import 'BoxAddAndRemove.dart';
// import 'DetalesOfItems.dart';
//
// class StreamBuilderBoxOfItem extends StatelessWidget {
//   StreamBuilderBoxOfItem({super.key, this.TheChosen});
//
//   String? TheChosen;
//
//   final nameOfItem = TextEditingController();
//   int? priceUpdate;
//   bool nameOfItemisTrue = false;
//   bool priceOfItem = false;
//
//   final Stream<QuerySnapshot> ItemStream =
//       FirebaseFirestore.instance
//           .collection('Item')
//           .where('appName', isEqualTo: FirebaseX.appName)
//           .snapshots();
//
//   Stream<QuerySnapshot> ItemStreamChosen() {
//     return FirebaseFirestore.instance
//         .collection('Item')
//         .where('appName', isEqualTo: FirebaseX.appName)
//         .where('typeItem', isEqualTo: TheChosen)
//         .snapshots();
//   }
//
//   //   FirebaseFirestore.instance.collection('Item').doc(uidItem).update({
//   //                  "nameOfItem":''
//   //                });
//
//   void _showContextMenu(
//     BuildContext context,
//     Offset position,
//     String uidItem,
//     double wi,
//     double hi,
//   ) async {
//     if (FirebaseAuth.instance.currentUser!.email != FirebaseX.EmailOfWnerApp) {
//       nameOfItemisTrue = false;
//       priceOfItem = false;
//       final RenderBox overlay =
//           Overlay.of(context).context.findRenderObject() as RenderBox;
//       await showMenu(
//         context: context,
//         position: RelativeRect.fromRect(
//           position & Size(wi, hi), // حجم الزر الذي تم الضغط عليه
//           Offset.zero & overlay.size, // حجم الشاشة
//         ),
//         items: <PopupMenuEntry>[
//           PopupMenuItem(
//             child: GetBuilder<GetStreamBuildOfItem>(
//               init: GetStreamBuildOfItem(),
//               builder: (logic) {
//                 return nameOfItemisTrue && !priceOfItem
//                     ? TextFormFiled2(
//                       controller: nameOfItem,
//                       borderRadius: 6,
//                       // focusNode: logic.focusNode,
//                       label: 'تغيير اسم المنتج',
//                       obscure: false,
//                       wight: wi / 1.8,
//                       height: hi / 15,
//                       fontSize: wi / 33,
//                     )
//                     : !nameOfItemisTrue && priceOfItem
//                     ? TextFormFiled2(
//                       controller: nameOfItem,
//                       borderRadius: 6,
//
//                       // focusNode: logic.focusNode,
//                       label: 'تغيير سعر المنتج',
//                       obscure: false,
//                       wight: wi / 1.8,
//                       textInputType2: TextInputType.number,
//                       height: hi / 15,
//                       fontSize: wi / 33,
//                     )
//                     : ListTile(
//                       leading: Icon(Icons.edit),
//                       title: Text('تغيير اسم المنتج'),
//                       onTap: () {
//                         logic.update();
//                         nameOfItemisTrue = true;
//
//                         // نفذ ما تريده عند اختيار "تعديل"
//                       },
//                     );
//               },
//             ),
//           ),
//           PopupMenuItem(
//             child: GetBuilder<GetStreamBuildOfItem>(
//               init: GetStreamBuildOfItem(),
//               builder: (logic1) {
//                 return nameOfItemisTrue || priceOfItem
//                     ? Container()
//                     : ListTile(
//                       leading: Icon(Icons.edit),
//                       title: Text('تغير سعر المنتج'),
//                       onTap: () {
//                         priceOfItem = true;
//                         logic1.update();
//                       },
//                     );
//               },
//             ),
//           ),
//           PopupMenuItem(
//             child: GetBuilder<GetStreamBuildOfItem>(
//               init: GetStreamBuildOfItem(),
//               builder: (logic2) {
//                 return nameOfItemisTrue && !priceOfItem
//                     ? GestureDetector(
//                       onTap: () async {
//                         await FirebaseFirestore.instance
//                             .collection('Item')
//                             .doc(uidItem)
//                             .update({"nameOfItem": nameOfItem.text});
//                         nameOfItem.clear();
//
//                         priceOfItem = false;
//
//                         nameOfItemisTrue = false;
//                         logic2.update();
//                         Navigator.pop(context);
//                       },
//                       child: Container(
//                         width: wi / 1.8,
//                         height: hi / 15,
//
//                         decoration: BoxDecoration(
//                           color: Colors.deepPurple,
//                           borderRadius: BorderRadius.circular(7),
//                         ),
//                         child: Center(child: Text('تغيير الاسم')),
//                       ),
//                     )
//                     : !nameOfItemisTrue && priceOfItem
//                     ? GestureDetector(
//                       onTap: () {
//                         int priceOfItem1 = int.parse(nameOfItem.text);
//
//                         FirebaseFirestore.instance
//                             .collection('Item')
//                             .doc(uidItem)
//                             .update({"priceOfItem": priceOfItem1});
//                         nameOfItem.clear();
//
//                         priceOfItem = false;
//                         nameOfItemisTrue = false;
//                         logic2.update();
//                         Navigator.pop(context);
//                       },
//                       child: Container(
//                         width: wi / 1.8,
//                         height: hi / 15,
//
//                         decoration: BoxDecoration(
//                           color: Colors.deepPurple,
//                           borderRadius: BorderRadius.circular(7),
//                         ),
//                         child: Center(child: Text('تغيير السعر')),
//                       ),
//                     )
//                     : ListTile(
//                       leading: Icon(Icons.delete),
//                       title: Text('حذف المنتج'),
//                       onTap: () {
//                         Get.defaultDialog(
//                           title: 'هل انت متآكد من حذف المنتج',
//                           titleStyle: TextStyle(fontSize: wi / 20),
//                           middleText: '',
//
//                           textCancel: 'الغاء',
//                           onCancel: () {
//                             Navigator.pop(context);
//                           },
//
//                           textConfirm: 'نعم',
//                           onConfirm: () {
//                             FirebaseFirestore.instance
//                                 .collection('Item')
//                                 .doc(uidItem)
//                                 .delete();
//
//                             priceOfItem = false;
//                             nameOfItemisTrue = false;
//                             logic2.update();
//                             Navigator.pop(context);
//                           },
//                         );
//                       },
//                     );
//               },
//             ),
//           ),
//         ],
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     double hi = MediaQuery.of(context).size.height;
//     double wi = MediaQuery.of(context).size.width;
//     return StreamBuilder<QuerySnapshot>(
//       stream:
//           TheChosen == null
//               ? ItemStream
//               : TheChosen == 'all'
//               ? ItemStream
//               : ItemStreamChosen(),
//
//       builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
//         if (snapshot.hasError) {
//           return Text('Something went wrong');
//         }
//
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: Text("Loading"));
//         }
//
//         return Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 7),
//           child: GridView.builder(
//             gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 3,
//               childAspectRatio:
//                   wi <= 449
//                       ? wi / 910
//                       : wi <= 550
//                       ? wi / 850
//                       : wi <= 650
//                       ? wi / 800
//                       : wi <= 750
//                       ? wi / 750
//                       : wi <= 388
//                       ? wi / 950
//                       : wi <= 350
//                       ? wi / 1000
//                       : wi <= 800
//                       ? wi / 900
//                       : wi <= 850
//                       ? wi / 950
//                       : wi / 700,
//               crossAxisSpacing: hi / 150,
//               mainAxisSpacing: hi / 150,
//             ),
//             primary: false,
//             itemCount: snapshot.data!.docs.length,
//             itemBuilder: (context, index) {
//               DocumentSnapshot dede = snapshot.data!.docs[index];
//               return Container(
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(15),
//                 ),
//                 child: Column(
//                   children: [
//                     GestureDetector(
//                       onLongPressStart: (LongPressStartDetails details) {
//                         _showContextMenu(
//                           context,
//                           details.globalPosition,
//                           dede['uid'],
//                           wi,
//                           hi,
//                         );
//                       },
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder:
//                                 (context) => DetalesOfItems(
//                                   url: dede['url'],
//                                   rate: 0,
//                                   images: dede["manyImages"] ?? '',
//                                   typeItem: dede['typeItem'],
//                                   priceOfItem: dede['priceOfItem'],
//                                   nameOfItem: dede['nameOfItem'],
//                                   descriptionOfItem: dede['descriptionOfItem'],
//                                   uid: dede['uid'],
//                                   isOffer: false,
//                                   VideoURL: dede['videoURL'],
//                                 ),
//                           ),
//                         );
//                       },
//
//                       child: Container(
//                         height: hi / 8,
//                         width: wi / 4,
//                         padding: EdgeInsets.only(
//                           top: 2,
//                           left: 2,
//                           right: 10,
//                           bottom: 2,
//                         ),
//
//                         decoration: BoxDecoration(
//                           image: DecorationImage(
//                             fit: BoxFit.cover,
//                             image: NetworkImage(dede['url']),
//                           ),
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(15),
//                         ),
//
//                         child:
//                             dede['videoURL'] != 'noVideo'
//                                 ? Align(
//                                   alignment: Alignment.topLeft,
//                                   child: Container(
//                                     decoration: BoxDecoration(
//                                       color: Colors.red,
//                                       borderRadius: BorderRadius.circular(12),
//                                     ),
//                                     child: Icon(
//                                       Icons.videocam_rounded,
//                                       size: 10,
//                                     ),
//                                   ),
//                                 )
//                                 : null,
//                       ),
//                     ),
//                     BoxAddAndRemove(
//                       uidItem: dede['uid'],
//                       price: dede['priceOfItem'].toString(),
//                       Name: dede['nameOfItem'],
//                     ),
//                   ],
//                 ),
//               );
//             },
//             shrinkWrap: true,
//           ),
//         );
//       },
//     );
//   }
// }



























import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../XXX/XXXFirebase.dart';
import '../../widget/TextFormFiled.dart';
import '../Get-Controllar/GetStreamBuildBoxOfItem.dart';
import 'BoxAddAndRemove.dart';
import 'DetalesOfItems.dart';

class StreamBuilderBoxOfItem extends StatelessWidget {
  StreamBuilderBoxOfItem({super.key, this.TheChosen});

  final String? TheChosen;
  final TextEditingController nameOfItem = TextEditingController();
  bool isNameChange = false; // للتحكم بعرض حقل تعديل الاسم
  bool isPriceChange = false; // للتحكم بعرض حقل تعديل السعر

  /// دالة تبني Stream لاسترجاع كل العناصر من Firestore بناءً على اسم التطبيق
  Stream<QuerySnapshot> _itemStream() =>
      FirebaseFirestore.instance
          .collection('Item')
          .where('appName', isEqualTo: FirebaseX.appName)
          .snapshots();

  /// دالة تبني Stream لاسترجاع العناصر بناءً على نوع المنتج (فلترة)
  Stream<QuerySnapshot> _filteredItemStream() =>
      FirebaseFirestore.instance
          .collection('Item')
          .where('appName', isEqualTo: FirebaseX.appName)
          .where('typeItem', isEqualTo: TheChosen)
          .snapshots();

  /// دالة لعرض قائمة السياق التي تحتوي على خيارات تعديل أو حذف العنصر
  Future<void> _showContextMenu(
      BuildContext context, Offset position, String uidItem, double wi, double hi) async {
    // التحقق من أن المستخدم ليس صاحب التطبيق حتى يتمكن من التعديل أو الحذف
    if (FirebaseAuth.instance.currentUser!.email != FirebaseX.EmailOfWnerApp) {
      isNameChange = false;
      isPriceChange = false;
      final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

      await showMenu(
        context: context,
        position: RelativeRect.fromRect(
          position & Size(wi, hi), // حجم الزر الذي تم الضغط عليه
          Offset.zero & overlay.size, // حجم الشاشة
        ),
        items: <PopupMenuEntry>[
          PopupMenuItem(
            child: GetBuilder<GetStreamBuildOfItem>(
              init: GetStreamBuildOfItem(),
              builder: (logic) {
                return isNameChange
                    ? _textField(
                    wi, hi, 'تغيير اسم المنتج', TextInputType.text, logic)
                    : !isPriceChange
                    ? ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('تغيير اسم المنتج'),
                  onTap: () {
                    isNameChange = true;
                    logic.update();
                  },
                )
                    : _textField(
                    wi, hi, 'تغيير سعر المنتج', TextInputType.number, logic);
              },
            ),
          ),
          PopupMenuItem(
            child: GetBuilder<GetStreamBuildOfItem>(
              init: GetStreamBuildOfItem(),
              builder: (logic) {
                return !isNameChange && !isPriceChange
                    ? ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('تغير سعر المنتج'),
                  onTap: () {
                    isPriceChange = true;
                    logic.update();
                  },
                )
                    : Container();
              },
            ),
          ),
          // زر لتأكيد عملية التعديل سواء لتغيير الاسم أو السعر
          PopupMenuItem(
            child: GestureDetector(
              onTap: () async {
                await FirebaseFirestore.instance.collection('Item').doc(uidItem).update({
                  isNameChange ? "nameOfItem" : "priceOfItem":
                  isNameChange ? nameOfItem.text : int.parse(nameOfItem.text),
                });
                nameOfItem.clear();
                isNameChange = isPriceChange = false;
                Navigator.pop(context);
              },
              child: _actionButton(
                  wi, hi, isNameChange ? 'تغيير الاسم' : 'تغيير السعر'),
            ),
          ),
          // زر لحذف المنتج مع تأكيد الأمر
          PopupMenuItem(
            child: ListTile(
              leading: Icon(Icons.delete),
              title: Text('حذف المنتج'),
              onTap: () => _showDeleteDialog(context, uidItem),
            ),
          ),
        ],
      );
    }
  }

  /// دالة مساعدة لإنشاء حقل نص لتعديل الاسم أو السعر
  Widget _textField(double wi, double hi, String label, TextInputType type, GetStreamBuildOfItem logic) {
    return TextFormFiled2(
      controller: nameOfItem,
      borderRadius: 6,
      label: label,
      obscure: false,
      width: wi / 1.8,
      textInputType: type,
      height: hi / 15,
      fontSize: wi / 33,
    );
  }

  /// دالة مساعدة لإنشاء زر الإجراء (تأكيد تغيير الاسم أو السعر)
  Widget _actionButton(double wi, double hi, String text) {
    return Container(
      width: wi / 1.8,
      height: hi / 15,
      decoration: BoxDecoration(
        color: Colors.deepPurple,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Center(child: Text(text, style: TextStyle(color: Colors.white))),
    );
  }

  /// دالة لإظهار مربع حوار تأكيد حذف المنتج
  void _showDeleteDialog(BuildContext context, String uidItem) {
    Get.defaultDialog(
      title: 'هل انت متآكد من حذف المنتج',
      textConfirm: 'نعم',
      textCancel: 'الغاء',
      onConfirm: () {
        FirebaseFirestore.instance.collection('Item').doc(uidItem).delete();
        isNameChange = isPriceChange = false;
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double hi = MediaQuery.of(context).size.height;
    final double wi = MediaQuery.of(context).size.width;

    return StreamBuilder<QuerySnapshot>(
      stream: TheChosen == null || TheChosen == 'all' ? _itemStream() : _filteredItemStream(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) return Text('حدث خطأ');
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: Text("جارٍ التحميل"));

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7),
          child: GridView.builder(
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              // يمكن تحسين نسبة العرض إلى الارتفاع حسب حجم الشاشة لتقليل استهلاك الذاكرة
              childAspectRatio: wi / 800,
              crossAxisSpacing: hi / 150,
              mainAxisSpacing: hi / 150,
            ),
            itemCount: snapshot.data?.docs.length ?? 0,
            itemBuilder: (context, index) {
              DocumentSnapshot item = snapshot.data!.docs[index];
              return _buildItemCard(context, item, wi, hi);
            },
            shrinkWrap: true,
          ),
        );
      },
    );
  }

  /// دالة إنشاء البطاقة الخاصة بكل عنصر من عناصر المنتج
  Widget _buildItemCard(BuildContext context, DocumentSnapshot item, double wi, double hi) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          GestureDetector(
            onLongPressStart: (LongPressStartDetails details) {
              // عند الضغط المطول، يتم عرض قائمة السياق لإجراء التعديل أو الحذف
              _showContextMenu(context, details.globalPosition, item['uid'], wi, hi);
            },
            onTap: () {
              // الانتقال إلى صفحة تفاصيل المنتج عند الضغط على البطاقة
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailsOfItem(
                    url: item['url'],
                    rate: 0,
                    images: item["manyImages"] ?? '',
                    typeItem: item['typeItem'],
                    priceOfItem: item['priceOfItem'],
                    nameOfItem: item['nameOfItem'],
                    descriptionOfItem: item['descriptionOfItem'],
                    uid: item['uid'],
                    isOffer: false,
                    videoURL: item['videoURL'],
                  ),
                ),
              );
            },
            child: _itemImage(item, wi, hi),
          ),
          BoxAddAndRemove(
            uidItem: item['uid'],
            price: item['priceOfItem'].toString(),
            name: item['nameOfItem'],
          ),
        ],
      ),
    );
  }

  /// دالة مساعدة لبناء صورة العنصر مع عرض أيقونة الفيديو إذا وُجد
  Widget _itemImage(DocumentSnapshot item, double wi, double hi) {
    return Container(
      height: hi / 8,
      width: wi / 4,
      padding: EdgeInsets.all(2),
      decoration: BoxDecoration(
        image: DecorationImage(
          fit: BoxFit.cover,
          image: NetworkImage(item['url']),
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: item['videoURL'] != 'noVideo'
          ? Align(
        alignment: Alignment.topLeft,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child:
          Icon(Icons.videocam_rounded, size: 10, color: Colors.white),
        ),
      )
          : null,
    );
  }
}
