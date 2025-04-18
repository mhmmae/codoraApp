// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:get/get.dart';
// import 'package:get/get_state_manager/get_state_manager.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';
// import 'package:uuid/uuid.dart';
// import '../../../XXX/XXXFirebase.dart';
// import '../../../bottonBar/botonBar.dart';
// import '../../../controler/local-notification-onroller.dart';
//
// class Getxbarcode extends GetxController{
//   int up=0 ;
//   bool isloding = false;
//
//   MobileScannerController? controller;
//   Getxbarcode({ this.controller});
//
//
//
//   BarCodeScanner(List<Barcode> scannedBarcodes,BuildContext context)async{
//     if(up ==0){
//      up++;
//
//
//       final  DeliveryUserisExiste = FirebaseFirestore.instance
//         .collection('DeliveryUser').doc(FirebaseAuth.instance.currentUser!.uid).collection('DeliveryUID').doc(scannedBarcodes.first.rawValue);
//     DeliveryUserisExiste.get().then((val) async{
//       if(val.exists){
//
//         update();
//         final uuid =Uuid().v1();
//
//         final DocumentReference<Map<String, dynamic>> order1 = FirebaseFirestore.instance
//             .collection('order').doc(scannedBarcodes.first.rawValue);
//         final TheOrder = FirebaseFirestore.instance
//             .collection('order').doc(scannedBarcodes.first.rawValue).collection('TheOrder').where('uidUser',isEqualTo: scannedBarcodes.first.rawValue);
//
//
//
//
//
//         final DocumentReference<Map<String, dynamic>> DeliveryUser = FirebaseFirestore.instance
//             .collection('DeliveryUser').doc(FirebaseAuth.instance.currentUser!.uid).collection('DeliveryUID').doc(scannedBarcodes.first.rawValue);
//         final  theSales = FirebaseFirestore.instance
//             .collection('theSales').doc(uuid);
//
//
//
//
//         order1.get().then((order)async{
//
//           await DeliveryUser.get().then((DeliveryUser1)async{
//             TheOrder.get().then((QuerySnapshot querySnapshot)async{
//               querySnapshot.docs.forEach((doc) async {
//                 await FirebaseFirestore.instance
//                     .collection('theSales').doc(uuid).collection('theSalesItem').doc(doc['uidOfDoc']).set({
//                   'isOfer':doc['isOfer'],
//                   'number':doc['number'],
//                   'uidItem':doc['uidItem'],
//                   'uidOfDoc':doc['uidOfDoc'],
//                   'uidUser':doc['uidUser'],
//
//                   'appName':FirebaseX.appName,
//
//
//
//
//                 });
//
//
//               });
//               await theSales.set({
//                 'DeliveryUid': DeliveryUser1.get('DeliveryUid'),
//                 'orderUidUser':DeliveryUser1.get('orderUid'),
//                 'timeDeliveryOrder':DeliveryUser1.get('timeOrder'),
//                 'timeOrderDone':DateTime.now(),
//                 'nmberOfOrder':DeliveryUser1.get('nmberOfOrder'),
//                 'totalPriceOfOrder':DeliveryUser1.get('totalPriceOfOrder'),
//                 'latitude':DeliveryUser1.get('latitude'),
//                 'longitude':DeliveryUser1.get('longitude'),
//                 'timeOrder':order.get('timeOrder'),
//                 'uidOfDoc':uuid,
//                 'appName':FirebaseX.appName,
//
//
//               });
//
//             }).then((dele)async{
//               await  DeliveryUser.delete();
//               await  order1.delete();
//               await  FirebaseFirestore.instance.collection('order').doc(scannedBarcodes.first.rawValue).collection('TheOrder').get().then((value) {
//                 for (DocumentSnapshot students in value.docs){
//                   students.reference.delete();
//                 }
//               }).then((done)async{
//                 final DocumentReference<Map<String, dynamic>> user = FirebaseFirestore.instance
//                     .collection(FirebaseX.collectionApp).doc(scannedBarcodes.first.rawValue);
//
//
//
//                 await user.update({
//
//                   FirebaseX.DeliveryUid :'',
//
//
//
//
//
//                 });
//                 await  FirebaseFirestore.instance.collection(FirebaseX.collectionApp).doc(scannedBarcodes.first.rawValue).get().then((uid)async{
//                   await  localNotification.sendNotificationMessageToUser(uid.get('token'), FirebaseX.appName, 'شكرا لاختياركم متجرنا', FirebaseAuth.instance.currentUser!.uid, 'Done', '');
//                   await controller?.stop();
//
//
//
//                   await  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => bottonBar(theIndex: 2,)),(rute)=>false);
//                 });
//
//
//
//
//               });
//             });
//
//           });
//
//
//
//
//
//
//         });
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//       }else {
//
//         final order1 = FirebaseFirestore.instance
//             .collection('order').doc(scannedBarcodes.first.rawValue);
//
//
//         final DocumentReference<Map<String, dynamic>> user = FirebaseFirestore.instance
//             .collection(FirebaseX.collectionApp).doc(scannedBarcodes.first.rawValue);
//
//
//
//         await user.update({
//
//           FirebaseX.DeliveryUid :FirebaseAuth.instance.currentUser!.uid,
//
//
//
//
//
//         });
//
//
//
//         order1.get().then((DocumentSnapshot documentSnapshot)async {
//           if (documentSnapshot.exists) {
//             await order1.update({
//               'Delivery' : true
//             }).then((val)async{
//               final DocumentReference<Map<String, dynamic>> DeliveryUser = FirebaseFirestore.instance
//                   .collection('DeliveryUser').doc(FirebaseAuth.instance.currentUser!.uid).collection('DeliveryUID').doc(documentSnapshot.get('uidUser'));
//
//               await DeliveryUser.set({
//
//                 'latitude': documentSnapshot.get('latitude'),
//                 'longitude': documentSnapshot.get('longitude'),
//                 'nmberOfOrder':documentSnapshot.get('nmberOfOrder'),
//                 'totalPriceOfOrder':documentSnapshot.get('totalPriceOfOrder'),
//                 'DeliveryUid':FirebaseAuth.instance.currentUser!.uid,
//                 'appName' :FirebaseX.appName,
//                 // 'uidUser':documentSnapshot.get('uidUser'),
//                 'orderUid': scannedBarcodes.first.rawValue,
//                 'timeOrder':DateTime.now()
//
//               }).then((val)async{
//
//                 FirebaseFirestore.instance
//                     .collection(FirebaseX.collectionApp)
//                     .doc(FirebaseAuth.instance.currentUser!.uid)
//                     .get()
//                     .then((DocumentSnapshot documentSnapshot) async{
//                   await  FirebaseFirestore.instance.collection(FirebaseX.collectionApp).doc(scannedBarcodes.first.rawValue).get().then((uid)async{
//                     await  localNotification.sendNotificationMessageToUser(uid.get('token'), FirebaseX.appName, 'طلبك الان في الطريق', FirebaseAuth.instance.currentUser!.uid, 'ScanerBarCode', '');
//                   });
//                   if (documentSnapshot.exists) {
//                     await controller?.stop();
//
//
//
//
//                     Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => bottonBar(theIndex: 2,)),(rute)=>false);
//
//                   }else{
//                     final DocumentReference<Map<String, dynamic>> DeliveryUser1 = FirebaseFirestore.instance
//                         .collection('DeliveryUser').doc(FirebaseAuth.instance.currentUser!.uid);
//
//
//
//
//
//
//
//                     await DeliveryUser1.get().then((deliveryUser1)async{
//                       if(deliveryUser1.exists){
//
//                         await controller?.stop();
//
//
//
//
//                         await  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => bottonBar(theIndex: 2,)),(rute)=>false);
//
//                       }else {
//
//
//                         await Geolocator.getCurrentPosition().then((value12)async{
//                           print('2222222222222222222222');
//                           print(value12.longitude);
//                           print(value12.latitude);
//
//
//                           await DeliveryUser1.set({
//
//                             // 'UidDeliveryUser' :FirebaseAuth.instance.currentUser!.uid,
//                             'latitudeDelivery' :value12.latitude.toDouble(),
//                             'longitudeDelivery' : value12.longitude.toDouble()
//
//
//
//                           });
//
//
//                           await controller?.stop();
//
//
//
//
//                           await  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => bottonBar(theIndex: 2,)),(rute)=>false);
//
//
//                         }
//
//                         );
//
//
//
//                       }
//
//
//
//
//                     });
//
//                   }
//                 });
//
//
//
//
//
//               });
//
//             });
//
//
//
//           }
//
//         });
//
//       }
//     });
//
//
//
//     }else{
//       print(up);
//
//
//       await controller?.stop().then((ca){
//         print('camera Stop/////////////////////////////////////////////////');
//         print('camera Stop/////////////////////////////////////////////////');
//       });
//
//
//
//       await  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => bottonBar(theIndex: 2,)),(rute)=>false);
//
//     }
//   }
//   @override
//   void onClose() async{
//     print('/////////////////////////////////////////////////////////////////////');
//     await controller?.stop();
//     await controller?.dispose();
//
//     // TODO: implement onClose
//     super.onClose();
//   }
//
//
//
//
//
// }




























import 'dart:async';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';

import '../../../XXX/XXXFirebase.dart';
import '../../../bottonBar/botonBar.dart';
import '../../../controler/local-notification-onroller.dart';

/// المتحكم الخاص بقراءة الباركود ومعالجة الطلب.
///
/// يقسم المنطق إلى جزئين باستخدام async/await:
/// 1. التحقق من وجود سجل للتوصيل في DeliveryUser.
/// 2. في حال وجود السجل يتم نقل بيانات الطلب إلى مجموعة المبيعات (theSales)
///    ويتم حذف البيانات الأصلية وتحديث بيانات المستخدم.
/// 3. في حال عدم وجود سجل، يتم تحديث الطلب ليحمل حالة التوصيل ويُنشأ سجل جديد للتوصيل.
/// كما يتم التعامل مع أخطاء العملية وإعلام المستخدم بالإشعارات المناسبة.
class GetxBarcode extends GetxController {
  int up = 0;
  bool isLoading = false;
  bool isProcessing = false;

  MobileScannerController? controller;

  GetxBarcode({this.controller});


  /// تفعيل حالة المعالجة
  void startProcessing() {
    isProcessing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      update();
    });
  }

  /// إيقاف حالة المعالجة
  void stopProcessing() {
    isProcessing = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      update();
    });
  }


  /// الدالة الأساسية لمعالجة قراءة الباركود.
  /// [scannedBarcodes]: قائمة الباركود الممسوحة.
  /// [context]: سياق الواجهة الحالي.
  Future<void> barCodeScanner(
      List<Barcode> scannedBarcodes, BuildContext context) async {
    // التحقق من عدم تكرار العملية
    if (up !=0) {
      print(up);
      await _stopScannerAndNavigate(context);
      return;
    }
    if(up ==0){
      startProcessing(); // بدء المعالجة

      try {
        up++;
        print(up);
        print('2222222211111111111111111111111111111111');
        print('33333333111111111111111111111111111111112');
        print('44444444111111111111111111111111111111113');
        // تعريف معرّف الباركود وقاعدة بيانات المستخدم
        String barcodeValue = scannedBarcodes.first.rawValue!;
        String currentUserId = FirebaseAuth.instance.currentUser!.uid;

        // مرجع سجل التوصيل
        DocumentReference deliveryUserRef = FirebaseFirestore.instance
            .collection('DeliveryUser')
            .doc(currentUserId)
            .collection('DeliveryUID')
            .doc(barcodeValue);

        DocumentSnapshot deliveryUserSnapshot = await deliveryUserRef.get();

        if (deliveryUserSnapshot.exists) {
          print('555555555511111111111111111111111111111111');
          print('66666666666111111111111111111111111111111112');
          print('777777777711111111111111111111111111113');
          // إذا كان سجل التوصيل موجودًا
          await _processExistingDelivery(barcodeValue, context);
        } else {
          // إذا لم يكن سجل التوصيل موجودًا
          await _processNewDelivery(barcodeValue, context);
        }
      } catch (e) {
        // عرض رسالة خطأ واضحة
        Get.snackbar(
          'خطأ',
          'حدث خطأ أثناء معالجة الباركود: ${e.toString()}',
          icon: const Icon(Icons.error_outline, color: Colors.white),
          backgroundColor: Colors.red.shade700,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          borderRadius: 10,
          duration: const Duration(seconds: 4),
        );
      } finally {
        stopProcessing(); // إنهاء المعالجة
      }
    }


  }

  /// دالة معالجة حالة وجود سجل التوصيل
  Future<void> _processExistingDelivery(
      String barcodeValue, BuildContext context) async {
    print('88888885511111111111111111111111111111111');
    print('8899999996111111111111111111111111111111112');
    print('700000001111111111111111111111111113');
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    // إنشاء معرّف فريد للطلب المنفذ
    String uuid = Uuid().v1();

    // تعريف مراجع Firestore المطلوبة:
    DocumentReference<Map<String, dynamic>> orderRef =
    FirebaseFirestore.instance.collection('order').doc(barcodeValue);
    Query theOrderQuery = FirebaseFirestore.instance
        .collection('order')
        .doc(barcodeValue)
        .collection('TheOrder')
        .where('uidUser', isEqualTo: barcodeValue);
    DocumentReference<Map<String, dynamic>> deliveryUserRef =
    FirebaseFirestore.instance.collection('DeliveryUser')
        .doc(currentUserId)
        .collection('DeliveryUID')
        .doc(barcodeValue);
    DocumentReference<Map<String, dynamic>> salesRef =
    FirebaseFirestore.instance.collection('theSales').doc(uuid);

    // جلب بيانات الطلب والتوصيل بالتتابع
    DocumentSnapshot orderSnapshot = await orderRef.get();
    DocumentSnapshot deliveryUserSnapshot = await deliveryUserRef.get();

    // معالجة مجموعة الطلبات (TheOrder) ونقل بياناتها إلى ventas (theSalesItem)
    QuerySnapshot theOrderSnapshot = await theOrderQuery.get();
    for (var doc in theOrderSnapshot.docs) {
      await FirebaseFirestore.instance
          .collection('theSales')
          .doc(uuid)
          .collection('theSalesItem')
          .doc(doc['uidOfDoc'])
          .set({
        'isOfer': doc['isOfer'],
        'number': doc['number'],
        'uidItem': doc['uidItem'],
        'uidOfDoc': doc['uidOfDoc'],
        'uidUser': doc['uidUser'],
        'appName': FirebaseX.appName,
      });
    }

    // حفظ بيانات الطلب الرئيسية في المجموعة "theSales"
    await salesRef.set({
      'DeliveryUid': deliveryUserSnapshot.get('DeliveryUid'),
      'orderUidUser': deliveryUserSnapshot.get('orderUid'),
      'isCode':false,
      'timeDeliveryOrder': deliveryUserSnapshot.get('timeOrder'),
      'timeOrderDone': DateTime.now(),
      'nmberOfOrder': deliveryUserSnapshot.get('nmberOfOrder'),
      'totalPriceOfOrder': deliveryUserSnapshot.get('totalPriceOfOrder'),
      'latitude': deliveryUserSnapshot.get('latitude'),
      'longitude': deliveryUserSnapshot.get('longitude'),
      'timeOrder': orderSnapshot.get('timeOrder'),
      'uidOfDoc': uuid,
      'appName': FirebaseX.appName,
    });

    // حذف بيانات الطلب والتوصيل الأصلية بعد نقلها
    await deliveryUserRef.delete();
    await orderRef.delete();
    QuerySnapshot theOrderDeleteSnapshot = await FirebaseFirestore.instance
        .collection('order')
        .doc(barcodeValue)
        .collection('TheOrder')
        .get();
    for (var doc in theOrderDeleteSnapshot.docs) {
      await doc.reference.delete();
    }

    // تحديث بيانات المستخدم لإزالة معرف التوصيل
    DocumentReference<Map<String, dynamic>> userRef = FirebaseFirestore.instance
        .collection(FirebaseX.collectionApp)
        .doc(barcodeValue);
    await userRef.update({FirebaseX.DeliveryUid: ''});

    // إرسال إشعار للمستخدم وإيقاف الماسح والانتقال للشاشة الرئيسية
    DocumentSnapshot userSnapshot = await userRef.get();
    await LocalNotification.sendNotificationToUser(
     token:  userSnapshot.get('token'),
     title:  FirebaseX.appName,
      body: 'شكرا لاختياركم متجرنا',
     uid:  FirebaseAuth.instance.currentUser!.uid,
      type: 'Done',
     image:  '',
    );
    await controller?.stop();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => BottomBar(theIndex: 2)),
          (route) => false,
    );
  }

  /// دالة معالجة حالة عدم وجود سجل توصيل حالي
  Future<void> _processNewDelivery(
      String barcodeValue, BuildContext context) async {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    DocumentReference<Map<String, dynamic>> orderRef =
    FirebaseFirestore.instance.collection('order').doc(barcodeValue);
    DocumentReference<Map<String, dynamic>> userRef =
    FirebaseFirestore.instance.collection(FirebaseX.collectionApp).doc(barcodeValue);

    // تحديث معرف التوصيل في بيانات المستخدم
    await userRef.update({FirebaseX.DeliveryUid: currentUserId});

    DocumentSnapshot orderSnapshot = await orderRef.get();
    if (orderSnapshot.exists) {
      await orderRef.update({'Delivery': true});

      DocumentReference<Map<String, dynamic>> deliveryUserDoc =
      FirebaseFirestore.instance.collection('DeliveryUser')
          .doc(currentUserId)
          .collection('DeliveryUID')
          .doc(orderSnapshot.get('uidUser'));

      await deliveryUserDoc.set({
        'latitude': orderSnapshot.get('latitude'),
        'longitude': orderSnapshot.get('longitude'),
        'nmberOfOrder': orderSnapshot.get('nmberOfOrder'),
        'totalPriceOfOrder': orderSnapshot.get('totalPriceOfOrder'),
        'DeliveryUid': currentUserId,
        'appName': FirebaseX.appName,
        'orderUid': barcodeValue,
        'timeOrder': DateTime.now(),
      });

      // تحديث حالة الطلب وإرسال إشعار للمستخدم
      await orderRef.update({'Delivery': true});
      await userRef.get().then((DocumentSnapshot userSnapshot) async {
        await FirebaseFirestore.instance.collection(FirebaseX.collectionApp)
            .doc(barcodeValue)
            .get()
            .then((uidSnapshot) async {
          await LocalNotification.sendNotificationToUser(
           token:  uidSnapshot.get('token'),
           title:  FirebaseX.appName,
           body:  'طلبك الان في الطريق',
           uid:  FirebaseAuth.instance.currentUser!.uid,
            type: 'ScanerBarCode',
            image: '',
          );
        });
        if (userSnapshot.exists) {
          await controller?.stop();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => BottomBar(theIndex: 2)),
                (route) => false,
          );
        } else {
          DocumentReference<Map<String, dynamic>> deliveryUserRoot =
          FirebaseFirestore.instance.collection('DeliveryUser').doc(currentUserId);
          DocumentSnapshot deliveryUserRootSnapshot = await deliveryUserRoot.get();
          if (deliveryUserRootSnapshot.exists) {
            await controller?.stop();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => BottomBar(theIndex: 2)),
                  (route) => false,
            );
          } else {
            Position position = await Geolocator.getCurrentPosition();
            await deliveryUserRoot.set({
              'latitudeDelivery': position.latitude.toDouble(),
              'longitudeDelivery': position.longitude.toDouble(),
            });
            await controller?.stop();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => BottomBar(theIndex: 2)),
                  (route) => false,
            );
          }
        }
      });
    }
  }

  /// دالة لإيقاف الماسح والانتقال مباشرةً إلى الصفحة الرئيسية في حال تكرار العملية (up > 0)
  Future<void> _stopScannerAndNavigate(BuildContext context) async {
    if(up==1){
      up++;
      print(up);
      print('عملية قراءة الباركود متكررة، إيقاف الماسح والانتقال...');
      await controller?.stop();
      await controller?.dispose();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => BottomBar(theIndex: 2)),
            (route) => false,
      );
    }


  }

  @override
  void onClose() async {
    print('تحرير موارد الماسح...');
    await controller?.stop();
    await controller?.dispose();
    super.onClose();
  }
}
