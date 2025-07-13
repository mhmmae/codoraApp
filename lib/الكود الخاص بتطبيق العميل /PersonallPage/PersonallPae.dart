//
// import 'package:flutter/material.dart';
//
// import 'class/ClassOfSetingOfPeronall.dart';
// import 'class/StreamOfOrderOfUser.dart';
// import 'class/StreamOfiNformtionOfUSER.dart';
//
// class personallPage extends StatelessWidget {
//   const personallPage({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     double hi = MediaQuery.of(context).size.height;
//     double wi = MediaQuery.of(context).size.width;
//     return Scaffold(
//       body: ListView(
//         shrinkWrap: true,
//         children: [
//           UserInformationStream(),
//           SizedBox(height: hi / 70,),
//           Divider(),
//           UserOrderStream(),
//           PersonalSettings()
//         ],
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';

// تعديل مسارات الاستيراد لتناسب مشروعك
// import 'class/ClassOfSetingOfPeronall.dart';
// import 'class/StreamOfOrderOfUser.dart';
// import 'class/StreamOfiNformtionOfUSER.dart';

// استخدم الأسماء/المسارات التي ستعتمدها
import '../TheOrder/ViewOeder/GetX/GetGoTOMapDilyvery.dart';
import 'ClassOfSetingOfPeronall.dart';
import 'OrderDetailsPage.dart';
import 'UserInformationStream.dart';
// أو personal_settings_widget.dart
// أو user_order_status_widget.dart
// أو user_information_widget.dart
import 'package:get/get.dart'; // لاستخدام Get.put إذا لم يكن Controllers مسجلة


class PersonallPage extends StatefulWidget { // تحويله إلى StatefulWidget لتهيئة Controllers
  const PersonallPage({super.key});

  @override
  State<PersonallPage> createState() => _PersonallPageState();
}

class _PersonallPageState extends State<PersonallPage> {

  @override
  void initState() {
    super.initState();
    // تسجيل GetX controllers إذا لم يتم تسجيلهم في مستوى أعلى (مثل main.dart أو binding)
    // هذا يضمن أن الـ controller متاح عند بناء الويدجات التي تستخدمه
    // إذا كانت الويدجات الفرعية هي التي تستخدم Get.put، يمكن تركها هناك.
    // ولكن لـ GetGoToMapDelivery، من الأفضل التأكد من وجوده.
    Get.put(GetGoToMapDelivery(), permanent: true); // permanent إذا كنت تريده متاحًا دائمًا
  }

  @override
  Widget build(BuildContext context) {
    // double hi = MediaQuery.of(context).size.height; // غير مستخدم مباشرة هنا الآن
    // double wi = MediaQuery.of(context).size.width; // غير مستخدم مباشرة هنا الآن
    return Scaffold(
      // appBar: AppBar(title: const Text("الملف الشخصي"), centerTitle: true,), //  يمكن إضافة AppBar إذا رغبت
      body: SafeArea( // استخدام SafeArea لتجنب تداخل الواجهة مع مناطق النظام
        child: ListView(
          // shrinkWrap: true, //  يفضل تجنبها إذا لم تكن ضرورية داخل ListView آخر
          padding: const EdgeInsets.symmetric(vertical: 8.0), // إضافة بعض التباعد العمودي
          children:  [ // يمكن جعلها const لأن الويدجات بداخلها أصبحت const أو تعتمد على BuildContext
            UserInformationStream(),
            Divider(thickness: 1, indent: 16, endIndent: 16, height: 25), // فاصل مرئي أكثر وضوحًا
            UserOrderStream(),
            Divider(thickness: 1, indent: 16, endIndent: 16, height: 25),
            PersonalSettings(),
            SizedBox(height: 20), // مسافة في الأسفل
          ],
        ),
      ),
    );
  }
}