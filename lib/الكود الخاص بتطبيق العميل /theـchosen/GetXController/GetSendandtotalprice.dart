




import 'dart:async';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';

import '../../../XXX/xxx_firebase.dart';
import '../../googleMap/GoogleMapOrder.dart';

/// يتحكم هذا المتحكم في إرسال الطلب وحساب الأسعار الإجمالية (كما في سياق التطبيق).
/// يقوم باستيراد صورة من الأصول لتحويلها إلى Marker على الخريطة، ويتحقق من صلاحيات وخدمات الموقع،
/// ثم ينتقل إلى شاشة الخريطة مع تمرير بيانات الموقع والرمز الخاص بالمستخدم.
class GetSendAndTotalPrice extends GetxController {
  final String uid; // معرّف المستخدم من قاعدة البيانات
  // حالة التحميل (يمكن متابعة التغييرات باستخدام RxBool)
  RxBool isLoading = false.obs;

  // المتغير الذي سيحمل بيانات صورة Marker بشكل Uint8List لاستخدامها على الخريطة.
  Uint8List? markerUser;

  // اشتراك في خدمة الموقع (يمكن استخدامه لاحقاً إذا أردت متابعة تحديث الموقع بشكل مستمر)
  late StreamSubscription<Position> positionStream;

  GetSendAndTotalPrice({required this.uid});

  /// دالة لتحويل صورة من الأصول (assets) إلى Uint8List بحيث يمكن استخدامها كرسم (marker) على الخريطة.
  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    // تحميل بيانات الصورة من الأصول
    ByteData data = await rootBundle.load(path);
    // إنشاء Codec لتعديل حجم الصورة
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    // الحصول على الإطار الأول من الصورة (frame)
    ui.FrameInfo fi = await codec.getNextFrame();
    // تحويل الصورة إلى Uint8List بصيغة PNG
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }

  /// دالة placeholder (قيد التطوير) لمعالجة منطق عرض أيقونة (marker) على الخريطة.
  Future<void> iconMarket() async {
    // TODO: تنفيذ منطق تحديد وعرض Marker على الخريطة إذا تطلب الأمر.
  }

  /// دالة إرسال الطلب:
  /// - تتحقق أولاً من وجود منتجات في السلة.
  /// - تقوم بتحميل صورة الماركر (Marker) من الأصول.
  /// - تتحقق من تفعيل خدمة الموقع وصلاحياته.
  /// - تحصل على الموقع الحالي للمستخدم.
  /// - تحصل على رمز المستخدم (token) من Firestore.
  /// - تنتقل إلى شاشة GoogleMapOrder مع تمرير الإحداثيات، الماركر، ورمز المستخدم.
  Future<void> send() async {
    try {
      // بدء حالة التحميل
      isLoading.value = true;
      update();

      // تحميل الماركر من الأصول (يستخدم ImageX.ImageHome من إعدادات المشروع)
      markerUser = await getBytesFromAsset(ImageX.ImageHome, 60);
      update();

      // جلب بيانات السلة من Firestore (the-chosen)
      QuerySnapshot chosenSnapshot = await FirebaseFirestore.instance
          .collection('the-chosen')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection(FirebaseX.appName)
          .get();

      // التأكد من وجود عناصر في السلة
      if (chosenSnapshot.docs.isNotEmpty) {
        double? longitude;
        double? latitude;

        // التحقق من تفعيل خدمة الموقع على الجهاز
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          // عرض رسالة تنبيه إذا كانت خدمة الموقع غير مفعلة
          Get.defaultDialog(
            title: 'خدمة الموقع',
            middleText: 'الرجاء تفعيل خدمة الموقع',
            textCancel: 'رجوع',
          );
          isLoading.value = false;
          update();
          return;
        }

        // التحقق من أذونات الموقع
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            Get.defaultDialog(
              title: 'أذونات الموقع',
              middleText: 'تم رفض أذونات الموقع',
              textCancel: 'رجوع',
            );
            isLoading.value = false;
            update();
            return;
          }
        }
        if (permission == LocationPermission.deniedForever) {
          Get.defaultDialog(
            title: 'أذونات الموقع',
            middleText: 'تم رفض أذونات الموقع بشكل دائم. يرجى التحقق من الإعدادات.',
            textCancel: 'رجوع',
          );
          isLoading.value = false;
          update();
          return;
        }

        // جلب رمز المستخدم (token) من مجموعة التطبيق في Firestore
        DocumentSnapshot tokenSnapshot = await FirebaseFirestore.instance
            .collection(FirebaseX.collectionApp)
            .doc(uid)
            .get();

        // الحصول على الموقع الحالي للمستخدم
        Position position = await Geolocator.getCurrentPosition();
        latitude = position.latitude;
        longitude = position.longitude;
        update();

        // الانتقال إلى شاشة الخريطة مع تمرير البيانات المطلوبة:
        // - الإحداثيات: latitude و longitude
        // - صورة الماركر للمستخدم
        // - رمز المستخدم (token)
        Get.to(() => GoogleMapOrder(
          initialLongitude: longitude!,
          initialLatitude: latitude!,
          markerIconBytes: markerUser!,
          tokenUser: tokenSnapshot.get('token'),
        ));
      } else {
        // إذا كانت السلة فارغة (أي لم يتم اختيار أي منتج)، يتم عرض رسالة للمستخدم.
        Get.defaultDialog(
          title: "تنبيه",
          titleStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.redAccent,
          ),
          middleText: "يرجى اختيار منتج من القائمة أولاً.",
          middleTextStyle: TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
          textCancel: "رجوع",
          cancelTextColor: Colors.black54,
          barrierDismissible: false,
          radius: 12,
          backgroundColor: Colors.white,
          buttonColor: Colors.redAccent,
          // يمكنك إضافة callback عند الضغط على زر الرجوع إذا رغبت
          onCancel: () {
            // تنفيذ أي إجراء عند إلغاء عملية التنبيه
          },
          // يمكن أيضاً إضافة أيقونة أو عناصر إضافية إذا رغبت:
          // titlePadding: EdgeInsets.only(top: 16, bottom: 8),
          // contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        );

      }
    } catch (e) {
      // التقاط أي أخطاء تحدث أثناء عملية الإرسال وعرض رسالة تنبيه للمستخدم
      Get.snackbar(
        'حدث خطأ',
        'تعذر إرسال الطلب. يرجى التأكد من اتصالك بالإنترنت وحاول مرة أخرى.\nتفاصيل الخطأ: $e',
        icon: const Icon(
          Icons.error_outline,
          color: Colors.white,
        ),
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 10,
        duration: const Duration(seconds: 4),
      );

    } finally {
      // إعادة تعيين حالة التحميل وتحديث الواجهة
      isLoading.value = false;
      update();
    }
  }
}
