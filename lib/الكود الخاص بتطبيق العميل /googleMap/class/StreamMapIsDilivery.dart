
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../TheOrder/barcod/barcode.dart';
import '../Getx/GetInfowUser.dart';
import '../Getx/GetStreamMapIsDilivery.dart';

class StreamMapIsDelivery extends StatelessWidget {
  StreamMapIsDelivery({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.isDelivery,
    this.markerUser,
    this.markerDelivery,
  });

  // المتغيرات الأساسية
  final double latitude; // خط العرض للموقع
  final double longitude; // خط الطول للموقع
  final bool isDelivery; // حالة التوصيل
  final Uint8List? markerUser; // صورة المستخدم كـ Marker
  final Uint8List? markerDelivery; // صورة التوصيل كـ Marker

  // استعلام بيانات Firebase
  final Stream<QuerySnapshot> deliveryUserStream = FirebaseFirestore.instance
      .collection('DeliveryUser')
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .collection('DeliveryUID')
      .snapshots();

  @override
  Widget build(BuildContext context) {
    double hi = MediaQuery
        .of(context)
        .size
        .height; // ارتفاع الشاشة
    double wi = MediaQuery
        .of(context)
        .size
        .width; // عرض الشاشة

    return GetBuilder<GetStreamMapIsDelivery>(
      init: GetStreamMapIsDelivery(
        idDelivery: isDelivery,
        latitude: latitude,
        longitude: longitude,
      ),
      builder: (logic) {
        return SizedBox(
          width: wi,
          height: hi,
          child: StreamBuilder<QuerySnapshot>(
            stream: deliveryUserStream,
            builder: (BuildContext context,
                AsyncSnapshot<QuerySnapshot> snapshot) {
              // التعامل مع الخطأ أثناء استرجاع البيانات
              if (snapshot.hasError) {
                return const Center(
                    child: Text('حدث خطأ أثناء تحميل البيانات.'));
              }

              // أثناء تحميل البيانات
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // قائمة العلامات على الخريطة
              Set<Marker> markers = <Marker>{
                longitude.isNaN
                    ? Marker(
                    markerId: const MarkerId('1'), position: const LatLng(0, 0))
                    : Marker(
                  markerId: const MarkerId('1'),
                  position: LatLng(latitude, longitude),
                  icon: BitmapDescriptor.bytes(markerDelivery!),
                ),
              };

              // عرض البيانات المسترجعة
              return Stack(
                children: snapshot.data!.docs.map((DocumentSnapshot document) {
                  Map<String, dynamic> user = document.data()! as Map<
                      String,
                      dynamic>;

                  // إضافة Marker للمستخدم
                  markers.add(
                    Marker(
                      markerId: MarkerId(user['orderUid']),
                      position: LatLng(user['latitude'], user['longitude']),
                      icon: BitmapDescriptor.bytes(markerUser!),
                      onTap: () {
                        logic.onMarkerTap(user); // التفاعل عند الضغط على Marker
                      },
                      draggable: true,
                    ),
                  );

                  return _buildUserInfoOverlay(
                      context, logic, user, markers, hi, wi);
                }).toList(),
              );
            },
          ),
        );
      },
    );
  }

  /// واجهة المستخدم لعرض بيانات الطلب
  Widget _buildUserInfoOverlay(BuildContext context,
      GetStreamMapIsDelivery logic,
      Map<String, dynamic> user,
      Set<Marker> markers,
      double hi,
      double wi,) {
    return Stack(
      children: [
        // عرض الخريطة
        GoogleMap(
          mapType: MapType.normal,
          markers: markers,
          initialCameraPosition: CameraPosition(
            target: LatLng(logic.latitude, logic.longitude),
            zoom: 17,
          ),
          onMapCreated: (controller) {
            logic.controller2 = controller;
          },
        ),

        // واجهة بيانات المستخدم عند الضغط على Marker
        if (logic.isDeliveryInfoVisible)
          Positioned(
            top: hi / 4,
            bottom: hi / 4,
            right: wi / 6,
            left: wi / 6,
            child: Container(
              width: wi / 5,
              height: hi / 5,
              decoration: BoxDecoration(
                color: Colors.white70,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildUserInfo(context, user, hi, wi),
              ),
            ),
          ),
      ],
    );
  }

  /// بناء واجهة المستخدم الخاصة بالمعلومات
  Widget _buildUserInfo(BuildContext context, Map<String, dynamic> user,
      double hi, double wi) {
    return GetBuilder<GetInfowUser>(init: GetInfowUser(userId: user['orderUid'],latitude: user['latitude'],longitude: user['longitude']),builder: (logic) {
      return ListView(
        shrinkWrap: true,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // زر المسح الضوئي (Barcode Scanner)
              GestureDetector(
                onTap: () =>
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => BarcodeScannerScreen()),
                    ),
                child: _buildButton(
                    "مسح", Colors.redAccent, Icons.document_scanner, hi, wi),
              ),
              // زر إغلاق البيانات
              GestureDetector(
                onTap: () => debugPrint("إغلاق بيانات الطلب."),
                child: _buildButton(
                    "إغلاق", Colors.blueAccent, Icons.dangerous, hi, wi),
              ),
            ],
          ),
          const Divider(),
          // بيانات المستخدم مثل الاسم، البريد، رقم الطلب
          _buildUserDataRow("اسم المستخدم", logic.name !=null ? logic.name.toString() : '', wi),
          _buildUserDataRow("البريد الإلكتروني", logic.email !=null ? logic.email.toString() : '', wi),
          _buildUserDataRow("رقم الطلب", user['nmberOfOrder'], wi),
          const Divider(),
          // السعر الإجمالي وملاحظات الطلب
          _buildUserDataRow("المبلغ الإجمالي", "${user['totalPriceOfOrder']} \$", wi),
          _buildUserDataRow("ملاحظات", user['notes'] ?? "لا توجد ملاحظات", wi),
        ],
      );
    });
  }

  /// بناء صف لعرض بيانات المستخدم
  Widget _buildUserDataRow(String title, String value, double wi) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black),
        ),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: wi / 60)),
              Text(value, style: TextStyle(fontSize: wi / 55)),
            ],
          ),
        ),
      ),
    );
  }

  /// زر مخصص لواجهة المستخدم
  Widget _buildButton(String label, Color color, IconData icon, double hi,
      double wi) {
    return Container(
      height: hi / 18,
      width: wi / 7,
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(6)),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: wi / 14, color: Colors.white),
            Text(label,
                style: TextStyle(color: Colors.white, fontSize: wi / 30)),
          ],
        ),
      ),
    );
  }
}
