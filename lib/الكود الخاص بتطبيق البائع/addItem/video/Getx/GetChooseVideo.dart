


import 'dart:io';
import 'dart:typed_data'; // لاستخدام Uint8List
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_thumbnail_video/index.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart'; // لضغط الفيديو
import 'package:uuid/uuid.dart';

import '../../../../XXX/xxx_firebase.dart';

class GetChooseVideo extends GetxController {
  final ImagePicker picker = ImagePicker();
  File? file; // اجعله File بدلاً من String لتسهيل الضغط والمعالجة
  Uint8List? uint8list; // لتخزين الصورة المصغرة

  // --- لا نستخدم uploadedVideoUrl كحالة تفاعلية هنا ---
  // --- سنرفع ونرجع الرابط عند الطلب في saveVideo ---
  // RxnString uploadedVideoUrl = RxnString(null);
  // ---

  RxBool isVideoLoading = false.obs; // لتتبع عملية الاختيار/الضغط/الرفع
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // اختيار فيديو
  Future<void> getVideo(BuildContext context) async {
    isVideoLoading.value = true; // بدء التحميل
    file = null; // مسح الملف القديم
    uint8list = null; // مسح الصورة المصغرة القديمة
    update(); // تحديث الواجهة لإزالة الفيديو القديم

    try {
      final XFile? xFile = await picker.pickVideo(source: ImageSource.gallery);
      if (xFile != null) {
        file = File(xFile.path); // تخزين الملف
        await _generateThumbnail(file!.path); // توليد الصورة المصغرة
        debugPrint("Video selected: ${file!.path}");
      } else {
        debugPrint("No video selected.");
      }
    } catch (e) {
      debugPrint("Error picking video: $e");
      Get.snackbar("خطأ", "لم يتم اختيار الفيديو: $e", colorText: Colors.white, backgroundColor: Colors.red);
    } finally {
      isVideoLoading.value = false; // إيقاف التحميل
      update(); // تحديث لعرض الصورة المصغرة أو لا
    }
  }

  // توليد صورة مصغرة
  Future<void> _generateThumbnail(String path) async {
    debugPrint("Generating thumbnail for: $path");
    try {
      uint8list = await VideoThumbnail.thumbnailData(
        video: path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 200, // حجم مناسب للصورة المصغرة
        quality: 50, // جودة أقل للصورة المصغرة
      );
      debugPrint("Thumbnail generated successfully.");
    } catch (e) {
      debugPrint("Error generating thumbnail: $e");
      uint8list = null; // لا يوجد صورة مصغرة في حالة الخطأ
    }
    // لا تحتاج لـ update() هنا إذا كان uint8list مراقبًا بواسطة Obx/GetBuilder
    update(); // تحديث احتياطي
  }


  // --- دالة جديدة لضغط الفيديو ورفعه وإرجاع الرابط ---
  // تستقبل ID المنتج لإنشاء مسار منظم
  Future<String?> compressAndUploadVideo(String parentId) async {
    if (file == null) {
      debugPrint("No video file to upload.");
      return null; // أو إرجاع 'noVideo'
    }

    isVideoLoading.value = true; // إظهار مؤشر الرفع/الضغط
    String? finalVideoUrl;

    try {
      debugPrint("Compressing video: ${file!.path}");
      // --- ضغط الفيديو ---
      MediaInfo? mediaInfo = await VideoCompress.compressVideo(
        file!.path,
        quality: VideoQuality.MediumQuality, // اختر الجودة المناسبة
        deleteOrigin: false, // لا تحذف الملف الأصلي
        includeAudio: true,
      );

      if (mediaInfo?.file == null) {
        debugPrint("Video compression failed or returned null.");
        throw Exception("فشل ضغط الفيديو");
      }
      File compressedFile = mediaInfo!.file!;
      debugPrint("Video compressed successfully: ${compressedFile.path}");
      // --- رفع الفيديو المضغوط ---
      final videoName = 'video_${const Uuid().v4()}.mp4'; // اسم فريد
      final Reference storageRef = _storage
          .ref(FirebaseX.StorgeApp)
          .child('item_videos') // مجلد للفيديوهات
          .child(parentId)      // ID المنتج/العرض
          .child(videoName);

      debugPrint("Uploading compressed video to: ${storageRef.fullPath}");
      UploadTask uploadTask = storageRef.putFile(compressedFile);
      TaskSnapshot snapshot = await uploadTask;
      finalVideoUrl = await snapshot.ref.getDownloadURL(); // الحصول على الرابط
      debugPrint("Video uploaded successfully: $finalVideoUrl");

      // (اختياري) حذف الملف المضغوط المؤقت بعد الرفع
      compressedFile.delete().catchError((e) {
        debugPrint("Error deleting compressed file: $e");
        return compressedFile; // إرجاع الملف نفسه في حالة الخطأ
      });

    } catch (e) {
      debugPrint("Error during video compression/upload: $e");
      Get.snackbar("خطأ رفع الفيديو", "حدث خطأ: $e", colorText: Colors.white, backgroundColor: Colors.red);
      finalVideoUrl = null; // أو يمكنك إرجاع قيمة تشير للخطأ
    } finally {
      isVideoLoading.value = false; // إيقاف مؤشر التحميل
      // لا تقم بمسح file أو uint8list هنا، قد يحتاجهما المستخدم
    }
    return finalVideoUrl;
  }
  // ------------------------------------------------------


  // حذف الفيديو المختار محليًا
  void deleteVideo() {
    file = null;
    uint8list = null;
    // uploadedVideoUrl.value = null; // لا يوجد سبب لتخزين الرابط هنا بعد الآن
    update();
    debugPrint("Selected video cleared.");
  }
}



