import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../Model/model_user.dart';
import '../../XXX/xxx_firebase.dart';

// تأكد من استيراد UserModel و FirebaseX بشكل صحيح
// import '../../Model/model_user.dart'; // المسار القديم
// import '../../XXX/xxx_firebase.dart'; // المسار القديم


class UserInformationStream extends StatelessWidget {
  const UserInformationStream({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Center(child: Text("المستخدم غير مسجل الدخول."));
    }

    final CollectionReference users =
    FirebaseFirestore.instance.collection(FirebaseX.collectionApp);

    return FutureBuilder<DocumentSnapshot>(
      future: users.doc(currentUser.uid).get(),
      builder:
          (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.hasError) {
          return const Center(
              child: Text("حدث خطأ أثناء جلب بيانات المستخدم."));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text("بيانات المستخدم غير موجودة."));
        }

        try {
          final Map<String, dynamic> userDataMap = snapshot.data!.data()! as Map<String, dynamic>;
          final String userId = snapshot.data!.id; // معرف المستند
          final UserModel userDataObject;
          userDataObject = UserModel.fromMap(userDataMap, userId);

          return Padding(
            padding: EdgeInsets.symmetric(vertical: screenHeight / 50),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth / 50),
                  child: Container(
                    height: screenHeight / 4.5, // تعديل طفيف للارتفاع
                    width: screenWidth / 2.2,  // تعديل طفيف للعرض
                    decoration: BoxDecoration(
                      color: Colors.grey[200], // لون خلفية احتياطي
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7), // للمطابقة مع الحاوية
                      child: CachedNetworkImage(
                        imageUrl: userDataObject.url,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator.adaptive()),
                        errorWidget: (context, url, error) =>
                        const Icon(Icons.person, size: 50, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: screenWidth / 30),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.start, // محاذاة العناصر للأعلى
                    children: [
                      _buildUserInfoTile(
                        label: "الاسم",
                        value: userDataObject.name,
                        icon: Icons.person_outline,
                        screenWidth: screenWidth,
                      ),
                      SizedBox(height: screenHeight / 80),
                      _buildUserInfoTile(
                        label: "البريد الإلكتروني",
                        value: userDataObject.email,
                        icon: Icons.email_outlined,
                        screenWidth: screenWidth,
                        valueFontSize: screenWidth / 32, // لجعله مناسبا أكثر إذا كان الايميل طويلا
                      ),
                      SizedBox(height: screenHeight / 80),
                      _buildUserInfoTile(
                        label: "رقم الهاتف",
                        value: userDataObject.phoneNumber, // استخدم الاسم المصحح
                        icon: Icons.phone_outlined,
                        screenWidth: screenWidth,
                        valueFontSize: screenWidth / 32,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: screenWidth / 50), // لإضافة هامش على اليمين
              ],
            ),
          );
        } catch (e) {
          return Center(
              child: Text("حدث خطأ في معالجة البيانات: ${e.toString()}"));
        }
      },
    );
  }

  Widget _buildUserInfoTile({
    required String label,
    required String value,
    required IconData icon,
    required double screenWidth,
    double? valueFontSize,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
          color: Colors.grey.shade100, // لون خلفية أفتح
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            )
          ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // محاذاة النص لليمين
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end, // محاذاة الأيقونة والعنوان لليمين
            children: [
              Text(
                label,
                style: TextStyle(
                    fontSize: screenWidth / 28, fontWeight: FontWeight.w600, color: Colors.black87),
                textAlign: TextAlign.right,
              ),
              const SizedBox(width: 8),
              Icon(icon, size: screenWidth / 20, color: Colors.blueGrey),

            ],
          ),
          const SizedBox(height: 6),
          Container(
            alignment: Alignment.centerRight, // محاذاة القيمة لليمين
            child: Text(
              value,
              style: TextStyle(fontSize: valueFontSize ?? screenWidth / 26, color: Colors.black54),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis, // لعرض نقاط في حالة النص الطويل
              maxLines: 2, // السماح بسطرين كحد أقصى
            ),
          ),
        ],
      ),
    );
  }
}