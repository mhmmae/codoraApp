


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// ودجة عرض قائمة المنتجات في الطلب (من مجموعة "TheOrder")
/// حيث يتم استخدام FutureBuilder لجلب بيانات الطلب ومن ثم FutureBuilder إضافي لاسترجاع تفاصيل المنتج.
class StreamOrderOfUser extends StatelessWidget {
  final String uid;

  const StreamOrderOfUser({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    // الحصول على أبعاد الشاشة
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;

    // الاستعلام لجلب بيانات الطلب من مجموعة "TheOrder" لمستند الطلب (uid)
    final Future<QuerySnapshot> orderFuture = FirebaseFirestore.instance
        .collection('orders')
        .doc(uid)
        .collection('OrderItems')
        .get();

    return FutureBuilder<QuerySnapshot>(
      future: orderFuture,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("حدث خطأ أثناء جلب البيانات"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs;
        if (docs == null || docs.isEmpty) {
          return const Center(child: Text("لا توجد بيانات للطلب"));
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final DocumentSnapshot document = docs[index];
            final Map<String, dynamic> data =
            document.data()! as Map<String, dynamic>;
            // استعلام لجلب تفاصيل المنتج، بناءً على ما إذا كان المنتج عرضاً (offer) أم لا.
            final Future<DocumentSnapshot> productFuture =
            (data['isOfer'] as bool? ?? false)
                ? FirebaseFirestore.instance
                .collection('Itemoffer')
                .doc(data['uidItem'])
                .get()
                : FirebaseFirestore.instance
                .collection('Item')
                .doc(data['uidItem'])
                .get();
            return FutureBuilder<DocumentSnapshot>(
              future: productFuture,
              builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> productSnapshot) {
                if (productSnapshot.hasError) {
                  return const Center(child: Text("حدث خطأ أثناء جلب بيانات المنتج"));
                }
                if (productSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                // الحصول على البيانات باستخدام data() وإجراء cast على النتيجة
                final Map<String, dynamic>? rawData =
                productSnapshot.data?.data() as Map<String, dynamic>?;
                if (rawData == null) {
                  return const Center(child: Text("لا توجد بيانات للمنتج"));
                }
                final Map<String, dynamic> productData = rawData;
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Colors.black),
                    ),
                    child: ListTile(
                      minLeadingWidth: width / 7,
                      leading: Container(
                        height: height / 10,
                        width: width / 7,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: Colors.black),
                          image: DecorationImage(
                            fit: BoxFit.cover,
                            image: NetworkImage(productData['url']),
                          ),
                        ),
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            productData['nameOfItem'],
                            style: TextStyle(fontSize: width / 35),
                          ),
                          SizedBox(height: height / 80),
                          Text(
                            'السعر: ${productData['priceOfItem'].toString()}',
                            style: TextStyle(fontSize: width / 35),
                          ),
                        ],
                      ),
                      trailing: Container(
                        width: width / 4,
                        alignment: Alignment.center,
                        child: Text(
                          'العدد: ${data['number'].toString()}',
                          style: TextStyle(fontSize: width / 38, color: Colors.red),
                        ),
                      ),
                    ),
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
