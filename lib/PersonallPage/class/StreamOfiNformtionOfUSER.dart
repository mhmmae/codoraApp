//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
//
// import '../../Model/ModelUser.dart';
// import '../../XXX/XXXFirebase.dart';
//
// class Streamofinformtionofuser extends StatelessWidget {
//    Streamofinformtionofuser({super.key});
//   CollectionReference users = FirebaseFirestore.instance.collection(FirebaseX.collectionApp);
//
//
//   @override
//   Widget build(BuildContext context) {
//     double hi = MediaQuery.of(context).size.height;
//     double wi = MediaQuery.of(context).size.width;
//     return   FutureBuilder<DocumentSnapshot>(
//       future: users.doc(FirebaseAuth.instance.currentUser!.uid).get(),
//       builder: (BuildContext context,
//           AsyncSnapshot<DocumentSnapshot> snapshot) {
//         if (snapshot.hasError) {
//           return Text("Something went wrong");
//         }
//
//         if (snapshot.hasData && !snapshot.data!.exists) {
//           return Text("Document does not exist");
//         }
//
//         if (snapshot.connectionState == ConnectionState.done) {
//           ModelUser UserData =ModelUser.fromMap(snapshot.data!.data() as Map<String, dynamic>);
//
//           return Column(
//             children: [
//               SizedBox(height: hi / 25),
//               Row(
//                 children: [
//                   Row(
//                     children: [
//                       SizedBox(
//                         width: wi / 50,
//                       ),
//                       Container(
//                         height: hi / 4,
//                         width: wi / 2,
//                         decoration: BoxDecoration(
//                             color: Colors.black12,
//                             borderRadius: BorderRadius.circular(6),
//                             border: Border.all(color: Colors.black),
//                             image: DecorationImage(
//                                 fit: BoxFit.cover,
//                                 image: NetworkImage(UserData.url))),
//                       ),
//                     ],
//                   ),
//                   SizedBox(
//                     width: wi / 30,
//                   ),
//                   Column(
//                     children: [
//                       Container(
//                         width: wi / 2.5,
//                         decoration: BoxDecoration(
//                             color: Colors.black12,
//                             borderRadius: BorderRadius.circular(16),
//                             border: Border.all(color: Colors.black)),
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.end,
//                           children: [
//                             Center(
//                                 child: Text(
//                                   'اسم المستخدم',
//                                   style: TextStyle(fontSize: wi / 40),
//                                 )),
//                             Center(
//                                 child: Text(UserData.name,
//                                     style: TextStyle(fontSize: wi / 40))),
//                             SizedBox(
//                               height: hi / 100,
//                             )
//                           ],
//                         ),
//                       ),
//                       SizedBox(
//                         height: hi / 100,
//                       ),
//                       Container(
//                         width: wi / 2.5,
//                         decoration: BoxDecoration(
//                             color: Colors.black12,
//                             borderRadius: BorderRadius.circular(16),
//                             border: Border.all(color: Colors.black)),
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.end,
//                           children: [
//                             Center(
//                                 child: Text(
//                                   'ايميل المستخدم',
//                                   style: TextStyle(fontSize: wi / 40),
//                                 )),
//                             Center(
//                                 child: Text(UserData.email,
//                                     style: TextStyle(fontSize: wi / 50))),
//                             SizedBox(
//                               height: hi / 100,
//                             )
//                           ],
//                         ),
//                       ),
//                       SizedBox(
//                         height: hi / 100,
//                       ),
//                       Container(
//                         width: wi / 2.5,
//                         decoration: BoxDecoration(
//                             color: Colors.black12,
//                             borderRadius: BorderRadius.circular(16),
//                             border: Border.all(color: Colors.black)),
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.end,
//                           children: [
//                             Center(
//                                 child: Text(
//                                   'رقم هاتف المستخدم',
//                                   style: TextStyle(fontSize: wi / 40),
//                                 )),
//                             Center(
//                                 child: Text(UserData.phneNumber,
//                                     style: TextStyle(fontSize: wi / 50))),
//                             SizedBox(
//                               height: hi / 100,
//                             )
//                           ],
//                         ),
//                       ),
//                     ],
//                   )
//                 ],
//               ),
//             ],
//           );
//         }
//
//         return const Align(alignment: Alignment.bottomCenter,
//             child: Center(child: CircularProgressIndicator()));
//       },
//     );
//   }
// }


















import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../Model/ModelUser.dart';
import '../../XXX/XXXFirebase.dart';

class UserInformationStream extends StatelessWidget {
   UserInformationStream({Key? key}) : super(key: key);

  // تعريف مجموعة المستندات (Collection)
  final CollectionReference users = FirebaseFirestore.instance.collection(FirebaseX.collectionApp);

  @override
  Widget build(BuildContext context) {
    // الحصول على أبعاد الشاشة
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;

    return FutureBuilder<DocumentSnapshot>(
      future: users.doc(FirebaseAuth.instance.currentUser!.uid).get(),
      builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        // في حال حدوث خطأ
        if (snapshot.hasError) {
          return const Center(child: Text("حدث خطأ ما"));
        }
        // في حال عدم وجود بيانات
        if (snapshot.hasData && !snapshot.data!.exists) {
          return const Center(child: Text("البيانات غير موجودة"));
        }
        // عند اكتمال عملية الجلب
        if (snapshot.connectionState == ConnectionState.done) {
          final ModelUser userData = ModelUser.fromMap(
              snapshot.data!.data() as Map<String, dynamic>);

          return Column(
            children: [
              SizedBox(height: height / 25),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // صورة المستخدم مع Padding
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: width / 50),
                    child: Container(
                      height: height / 4,
                      width: width / 2,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.black),
                        image: DecorationImage(
                          fit: BoxFit.cover,
                          image: NetworkImage(userData.url),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: width / 30),
                  // عمود لعرض بيانات المستخدم
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildUserInfoTile(
                          label: "الآسم",
                          value: userData.name,
                          width: width,
                          height: height,
                        ),
                        SizedBox(height: height / 100),
                        _buildUserInfoTile(
                          label: "الايميل",
                          value: userData.email,
                          width: width,
                          height: height,
                          textSize: width / 50,
                        ),
                        SizedBox(height: height / 100),
                        _buildUserInfoTile(
                          label: "رقم الهاتف ",
                          value: userData.phneNumber,
                          width: width,
                          height: height,
                          textSize: width / 50,
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ],
          );
        }
        // في حال لم تكتمل العملية بعد، عرض مؤشر تحميل
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  /// دالة مساعدة لإنشاء مظهر لمعلومات المستخدم في شكل مربع
  Widget _buildUserInfoTile({
    required String label,
    required String value,
    required double width,
    required double height,
    double? textSize,
  }) {
    return Container(
      width: width / 2.5,
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black),
      ),
      // استخدم Padding لفصل المحتوى
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: textSize ?? width / 40),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: textSize ?? width / 40),
            ),
          ],
        ),
      ),
    );
  }
}
