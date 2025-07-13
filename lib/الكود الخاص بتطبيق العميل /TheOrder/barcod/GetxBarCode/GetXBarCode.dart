






import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';

import '../../../../XXX/xxx_firebase.dart';
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
      // debugPrint(up);
      await _stopScannerAndNavigate(context);
      return;
    }
    if(up ==0){
      startProcessing(); // بدء المعالجة

      try {
        up++;
        // debugPrint(up);
        debugPrint('2222222211111111111111111111111111111111');
        debugPrint('33333333111111111111111111111111111111112');
        debugPrint('44444444111111111111111111111111111111113');
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
          debugPrint('555555555511111111111111111111111111111111');
          debugPrint('66666666666111111111111111111111111111111112');
          debugPrint('777777777711111111111111111111111111113');
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
    debugPrint('88888885511111111111111111111111111111111');
    debugPrint('8899999996111111111111111111111111111111112');
    debugPrint('700000001111111111111111111111111113');
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
    await LocalNotification.sendNotificationMessageToUser(
     to:  userSnapshot.get('token'),
     title:  FirebaseX.appName,
      body: 'شكرا لاختياركم متجرنا',
     uid:  FirebaseAuth.instance.currentUser!.uid,
      type: 'Done',
     image:  '',
    );
    await controller?.stop();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => BottomBar(initialIndex: 2)),
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
          await LocalNotification.sendNotificationMessageToUser(
           to:  uidSnapshot.get('token'),
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
            MaterialPageRoute(builder: (context) => BottomBar(initialIndex: 2)),
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
              MaterialPageRoute(builder: (context) => BottomBar(initialIndex: 2)),
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
              MaterialPageRoute(builder: (context) => BottomBar(initialIndex: 2)),
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
      // debugPrint(up);
      debugPrint('عملية قراءة الباركود متكررة، إيقاف الماسح والانتقال...');
      await controller?.stop();
      await controller?.dispose();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => BottomBar(initialIndex: 2)),
            (route) => false,
      );
    }


  }

  @override
  void onClose() async {
    debugPrint('تحرير موارد الماسح...');
    await controller?.stop();
    await controller?.dispose();
    super.onClose();
  }
}
