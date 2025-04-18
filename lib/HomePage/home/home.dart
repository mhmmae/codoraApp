//
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../../XXX/XXXFirebase.dart';
// import '../../widget/TextFormFiled.dart';
// import '../Get-Controllar/GetSerchController.dart';
// import '../class/Chose-The-Type-Of-ItemxxXX.dart';
// import '../class/StreamBuilder-Box-Of-Item.dart';
// import '../class/StreamBuilder-Box-Of-offer-Item.dart';
// import '../class/StreamBuilder-Of-Search.dart';
//
//
//
// class Home extends StatelessWidget {
//    Home({super.key});
//    TextEditingController search = TextEditingController();
//
//
//
//
//    @override
//   Widget build(BuildContext context) {
//     double hi = MediaQuery.of(context).size.height;
//     double wi = MediaQuery.of(context).size.width;
//
//     return Scaffold(
//
//
//         extendBodyBehindAppBar: true,
//         backgroundColor: Colors.white,
//         appBar: AppBar(
//           elevation: 0,
//           leadingWidth: wi / 1.25,
//           leading: Padding(
//               padding: const EdgeInsets.only(left: 10, top: 0),
//               child:GetBuilder<GetSearchController>(
//                   init: GetSearchController()
//                   , builder: (vall) {
//                 return TextFormFiled2(
//                   wight: wi / 1.25,
//                   fontSize: hi / 60,
//                   height: hi / 40,
//                   borderRadius: 12,
//                   controller: search,
//                   OnChange: (val) async {
//                     vall.update();
//
//
//                   },
//                   validator: (val) {
//                     if (val == null) {
//                       return 'Eimpety';
//                     }
//                     return null;
//                   },
//                   label: 'Search ',
//                   obscure: false,
//                 );
//               })
//           ),
//
//         ),
//
//         body:  GetBuilder<GetSearchController>(
//             init: GetSearchController()
//             , builder: (vall) {
//           return search.text.isEmpty ?ListView(
//             children: [
//               SizedBox(
//                 height: hi / 50,
//               ),
//
//
//               StreambuilderBoxOfOfferItem(pageController: vall.pageController,),
//
//
//               SizedBox(
//                 height: hi / 22,
//               ),
//
//               GetBuilder<Getchosethetypeofitem>(
//                   init: Getchosethetypeofitem(), builder: (val) {
//                 return ChoseTheTypeOfItem();
//               }),
//
//
//               SizedBox(
//                 height: hi / 40,
//               ),
//
//
//               GetBuilder<Getchosethetypeofitem>(
//                   init: Getchosethetypeofitem(), builder: (val) {
//                 return StreamBuilderBoxOfItem(TheChosen: val.TheChosen);
//               })
//
//
//             ],
//
//
//           ):StreamBuilderOfSearch(search: search,);
//         }
//
//
//         )
//     );
//   }
// }
//
//
//
//
//


import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../XXX/XXXFirebase.dart';
import '../../widget/TextFormFiled.dart';
import '../Get-Controllar/GetSerchController.dart';
import '../class/Chose-The-Type-Of-ItemxxXX.dart';
import '../class/StreamBuilder-Box-Of-Item.dart';
import '../class/StreamBuilder-Box-Of-offer-Item.dart';
import '../class/StreamBuilder-Of-Search.dart';

class Home extends StatelessWidget {
  Home({Key? key}) : super(key: key);

  // أدوات النص الخاصة بالبحث؛ يجب Dispose إذا كانت تستخدم في StatefulWidget.
  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // تأكد من أن الـ GetX Controllers موجودة بالفعل (سيُنشَئون مرة واحدة)
    final GetSearchController searchCtrl = Get.put(GetSearchController());
    final Getchosethetypeofitem typeCtrl = Get.put(Getchosethetypeofitem());

    // أبعاد الشاشة لتحديد القياسات
    final double hi = MediaQuery.of(context).size.height;
    final double wi = MediaQuery.of(context).size.width;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        // تحديد عرض المساحة المخصصة للـ AppBar
        leadingWidth: wi / 1.25,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10, top: 0),
          child: GetBuilder<GetSearchController>(
            builder: (controller) {
              return TextFormFiled2(
                // عرض الحقل بناءً على العرض المحدد
                width: wi / 1.25,
                fontSize: hi / 60,
                height: hi / 40,
                borderRadius: 12,
                controller: searchController,
                onChange: (val) {
                  // عند كل تغيير في النص، يتم تحديث الحالة
                  // (يمكن أيضاً تحديث متغير بحث داخل الـ Controller إذا رغبت)
                  controller.update();
                },
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Empty';
                  }
                  return null;
                },
                label: 'Search',
                obscure: false,
              );
            },
          ),
        ),
      ),
      body: GetBuilder<GetSearchController>(
        builder: (controller) {
          // عرض المحتوى الأساسي في حال كان حقل البحث فارغًا،
          // وإلا عرض نتائج البحث باستخدام StreamBuilderOfSearch.
          if (searchController.text.isEmpty) {
            return ListView(
              children: [
                SizedBox(height: hi / 50),
                // عرض عناصر العروض (Offer Items) باستخدام StreamBuilderBoxOfOfferItem
                StreambuilderBoxOfOfferItem(pageController: controller.pageController),
                SizedBox(height: hi / 22),
                // عرض قسم اختيار نوع السلعة
                GetBuilder<Getchosethetypeofitem>(
                  builder: (_) => const ChoseTheTypeOfItem(),
                ),
                SizedBox(height: hi / 40),
                // عرض العناصر بناءً على النوع المختار
                GetBuilder<Getchosethetypeofitem>(
                  builder: (typeController) => StreamBuilderBoxOfItem(
                    TheChosen: typeController.TheChosen,
                  ),
                ),
              ],
            );
          } else {
            return StreamBuilderOfSearch(search: searchController);
          }
        },
      ),
    );
  }
}
