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

  /// دالة محسنة لتحويل صورة من الأصول إلى Uint8List مع معالجة شاملة للأخطاء
  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    try {
      debugPrint("🖼️ جاري تحميل الصورة من: $path");

      // التحقق من وجود الصورة أولاً
      ByteData? data;
      try {
        data = await rootBundle.load(path);
        debugPrint(
          "✅ تم تحميل بيانات الصورة بنجاح، الحجم: ${data.lengthInBytes} bytes",
        );
      } catch (e) {
        debugPrint("❌ الصورة غير موجودة في المسار: $path");
        debugPrint("🔄 سيتم إنشاء marker افتراضي...");
        return await _createDefaultMarkerImage(width);
      }

      // التحقق من صحة البيانات
      if (data.lengthInBytes == 0) {
        debugPrint("❌ الصورة فارغة");
        return await _createDefaultMarkerImage(width);
      }

      // تحويل البيانات إلى Uint8List
      final Uint8List imageBytes = data.buffer.asUint8List();

      // التحقق من صحة تنسيق الصورة
      if (!_isValidImageFormat(imageBytes)) {
        debugPrint("❌ تنسيق الصورة غير مدعوم");
        return await _createDefaultMarkerImage(width);
      }

      // محاولة إنشاء Codec مع معالجة محسنة للأخطاء
      ui.Codec? codec;
      try {
        codec = await ui.instantiateImageCodec(imageBytes, targetWidth: width);
        debugPrint("✅ تم إنشاء codec بنجاح");
      } catch (codecError) {
        debugPrint("❌ فشل في إنشاء codec: $codecError");
        return await _createDefaultMarkerImage(width);
      }

      // الحصول على الإطار الأول من الصورة
      ui.FrameInfo? frameInfo;
      try {
        frameInfo = await codec.getNextFrame();
        debugPrint("✅ تم الحصول على frame بنجاح");
      } catch (frameError) {
        debugPrint("❌ فشل في الحصول على frame: $frameError");
        codec.dispose();
        return await _createDefaultMarkerImage(width);
      }

      // تحويل الصورة إلى ByteData
      ByteData? byteData;
      try {
        byteData = await frameInfo.image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        debugPrint("✅ تم تحويل الصورة إلى ByteData بنجاح");
      } catch (conversionError) {
        debugPrint("❌ فشل في تحويل الصورة: $conversionError");
        frameInfo.image.dispose();
        codec.dispose();
        return await _createDefaultMarkerImage(width);
      }

      if (byteData == null) {
        debugPrint("❌ فشل في تحويل الصورة إلى ByteData");
        frameInfo.image.dispose();
        codec.dispose();
        return await _createDefaultMarkerImage(width);
      }

      final Uint8List result = byteData.buffer.asUint8List();
      debugPrint(
        "✅ تم تحويل الصورة بنجاح، الحجم النهائي: ${result.length} bytes",
      );

      // تنظيف الذاكرة
      frameInfo.image.dispose();
      codec.dispose();

      return result;
    } catch (e, stackTrace) {
      debugPrint("❌ خطأ عام في تحميل الصورة من $path: $e");
      debugPrint("📍 Stack trace: $stackTrace");
      return await _createDefaultMarkerImage(width);
    }
  }

  /// التحقق من صحة تنسيق الصورة
  bool _isValidImageFormat(Uint8List bytes) {
    if (bytes.length < 4) return false;

    // فحص PNG signature
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      debugPrint("✅ تم التعرف على تنسيق PNG");
      return true;
    }

    // فحص JPEG signature
    if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
      debugPrint("✅ تم التعرف على تنسيق JPEG");
      return true;
    }

    // فحص WebP signature
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      debugPrint("✅ تم التعرف على تنسيق WebP");
      return true;
    }

    debugPrint("❌ تنسيق صورة غير مدعوم");
    return false;
  }

  /// إنشاء صورة marker افتراضية في حالة فشل تحميل الصورة الأصلية
  Future<Uint8List> _createDefaultMarkerImage(int size) async {
    try {
      debugPrint("🔄 إنشاء صورة marker افتراضية...");

      // إنشاء مسطح رسم
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      // رسم خلفية بيضاء
      final Paint backgroundPaint =
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.fill;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
        backgroundPaint,
      );

      // رسم دائرة ملونة كـ marker
      final Paint circlePaint =
          Paint()
            ..color = const Color(0xFF667EEA)
            ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(size / 2, size / 2), size / 3, circlePaint);

      // رسم نقطة بيضاء في المنتصف
      final Paint centerPaint =
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(size / 2, size / 2), size / 6, centerPaint);

      // رسم حدود
      final Paint borderPaint =
          Paint()
            ..color = Colors.grey.shade300
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0;

      canvas.drawCircle(Offset(size / 2, size / 2), size / 3, borderPaint);

      // تحويل الرسم إلى صورة
      final ui.Picture picture = recorder.endRecording();
      final ui.Image image = await picture.toImage(size, size);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      // تنظيف الذاكرة
      picture.dispose();
      image.dispose();

      if (byteData != null) {
        debugPrint("✅ تم إنشاء الصورة الافتراضية بنجاح");
        return byteData.buffer.asUint8List();
      } else {
        throw Exception("فشل في إنشاء الصورة الافتراضية");
      }
    } catch (e) {
      debugPrint("❌ خطأ في إنشاء الصورة الافتراضية: $e");

      // إرجاع أبسط marker ممكن - صورة PNG بسيطة مكتوبة يدوياً
      return _createMinimalMarker();
    }
  }

  /// إنشاء أبسط marker ممكن كـ fallback نهائي
  Uint8List _createMinimalMarker() {
    // PNG صغير أحمر بسيط (16x16 pixels) - مُولّد يدوياً
    return Uint8List.fromList([
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
      0x00,
      0x00,
      0x00,
      0x0D,
      0x49,
      0x48,
      0x44,
      0x52,
      0x00,
      0x00,
      0x00,
      0x10,
      0x00,
      0x00,
      0x00,
      0x10,
      0x08,
      0x02,
      0x00,
      0x00,
      0x00,
      0x90,
      0x91,
      0x68,
      0x36,
      0x00,
      0x00,
      0x00,
      0x3C,
      0x49,
      0x44,
      0x41,
      0x54,
      0x28,
      0xCF,
      0x63,
      0xF8,
      0x0F,
      0x00,
      0x01,
      0x01,
      0x01,
      0x00,
      0x18,
      0xDD,
      0x8D,
      0xB4,
      0x1C,
      0x00,
      0x00,
      0x00,
      0x00,
      0x49,
      0x45,
      0x4E,
      0x44,
      0xAE,
      0x42,
      0x60,
      0x82,
    ]);
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
      QuerySnapshot chosenSnapshot =
          await FirebaseFirestore.instance
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
            middleText:
                'تم رفض أذونات الموقع بشكل دائم. يرجى التحقق من الإعدادات.',
            textCancel: 'رجوع',
          );
          isLoading.value = false;
          update();
          return;
        }

        // جلب رمز المستخدم (token) من مجموعة التطبيق في Firestore
        DocumentSnapshot tokenSnapshot =
            await FirebaseFirestore.instance
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
        Get.to(
          () => GoogleMapOrder(
            initialLongitude: longitude!,
            initialLatitude: latitude!,
            markerIconBytes: markerUser!,
            tokenUser: tokenSnapshot.get('token'),
          ),
        );
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
          middleTextStyle: TextStyle(fontSize: 16, color: Colors.black87),
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
        icon: const Icon(Icons.error_outline, color: Colors.white),
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
