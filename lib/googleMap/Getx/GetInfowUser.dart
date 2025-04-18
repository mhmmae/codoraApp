//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:get/get.dart';
//
// import '../../XXX/XXXFirebase.dart';
//
// class getInfowUser extends GetxController{
//
//   String userId;
//   String? urlOfUser;
//   String? email;
//   String? name;
//   String? phneNumber;
//   String? DeliveryUidOscar1;
//   double latitude;
//   double longitude;
//   String? nameOfContry;
//   String? nameOfgovernorate;
//   String? Administrative;
//
//   bool isDilveyGetUserInformaion = false;
//
//
//
//   getInfowUser({ required this.userId,  required this.latitude,  required this.longitude});
//
//   void getGeoCoding()async{
//     List<Placemark>? placemarks = await placemarkFromCoordinates(latitude, longitude);
//       nameOfContry = placemarks.first.country;
//       nameOfgovernorate =placemarks.first.locality;
//       Administrative = placemarks.first.subAdministrativeArea;
//
//      update();
//
//
//   }
//
//   @override
//   void onInit() {
//     FirebaseFirestore.instance
//         .collection(FirebaseX.collectionApp)
//         .doc(userId)
//         .get()
//         .then((DocumentSnapshot documentSnapshot) {
//       if (documentSnapshot.exists) {
//        urlOfUser = documentSnapshot.get('url');
//        email = documentSnapshot.get('email');
//        name = documentSnapshot.get('name');
//        phneNumber =documentSnapshot.get('phneNumber');
//        DeliveryUidOscar1 = documentSnapshot.get('DeliveryUidOscar1');
//        update();
//
//       } else {
//
//       }
//     });
//
//    if(longitude !=0 ){
//      getGeoCoding();
//    }
//
//     // TODO: implement onInit
//     super.onInit();
//   }
//
// }











import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import '../../XXX/XXXFirebase.dart';

class GetInfowUser extends GetxController {
  // المتغيرات الأساسية
  final String userId; // معرف المستخدم
  final double latitude; // خط العرض
  final double longitude; // خط الطول

  // معلومات إضافية للمستخدم
  String? urlOfUser; // صورة المستخدم
  String? email; // البريد الإلكتروني
  String? name; // اسم المستخدم
  String? phoneNumber; // رقم الهاتف
  String? deliveryUidOscar1; // معرف التوصيل

  // معلومات جغرافية
  String? nameOfCountry; // اسم الدولة
  String? nameOfGovernorate; // اسم المحافظة
  String? administrativeArea; // المنطقة الإدارية

  // حالة عرض المعلومات
  bool isDeliveryGetUserInformation = false;

  // البناء
  GetInfowUser({
    required this.userId,
    required this.latitude,
    required this.longitude,
  });

  /// جلب معلومات الموقع باستخدام Geocoding
  Future<void> getGeoCoding() async {
    try {
      List<Placemark>? placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        nameOfCountry = placemarks.first.country; // اسم الدولة
        nameOfGovernorate = placemarks.first.locality; // اسم المحافظة
        administrativeArea = placemarks.first.subAdministrativeArea; // المنطقة الإدارية
        update(); // تحديث الحالة
      }
    } catch (e) {
      print("خطأ أثناء جلب معلومات الموقع: $e");
    }
  }

  /// جلب بيانات المستخدم من Firebase
  Future<void> fetchUserData() async {
    try {
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection(FirebaseX.collectionApp)
          .doc(userId)
          .get();

      if (documentSnapshot.exists) {
        urlOfUser = documentSnapshot.get('url'); // صورة المستخدم
        email = documentSnapshot.get('email'); // البريد الإلكتروني
        name = documentSnapshot.get('name'); // اسم المستخدم
        phoneNumber = documentSnapshot.get('phneNumber'); // رقم الهاتف
        deliveryUidOscar1 = documentSnapshot.get('DeliveryUidOscar1'); // معرف التوصيل
        update(); // تحديث الحالة
      } else {
        print("المستند غير موجود في Firebase.");
      }
    } catch (e) {
      print("خطأ أثناء جلب بيانات المستخدم: $e");
    }
  }

  /// يتم تنفيذ هذه الوظائف عند تشغيل التحكم
  @override
  void onInit() {
    super.onInit();
    print("onInit: بدء جلب البيانات.");

    // جلب بيانات المستخدم
    fetchUserData();

    // جلب معلومات الموقع
    if (longitude != 0) {
      getGeoCoding();
    }
  }
}
