import 'dart:typed_data';

import 'package:get/get.dart';

import '../Chose-The-Type-Of-Itemxx.dart';
import '../video/Getx/GetChooseVideo.dart';
import 'class/getAddManyImage.dart';

class InformationBinding extends Bindings {
  final Uint8List imageBytes;
  final String itemType;
  InformationBinding({required this.imageBytes, required this.itemType});

  @override
  void dependencies() {
    // استخدام tag إذا لزم الأمر
    final String tag = 'add_$itemType';
    // lazyPut أفضل هنا
    Get.lazyPut<Getinformationofitem1>(
            () => Getinformationofitem1(uint8list: imageBytes, TypeItem: itemType),
        tag: tag,
        fenix: true // إعادة إنشائه إذا تم حذفه
    );
    // حقن المتحكمات الأخرى المطلوبة هنا أيضاً (مثل GetChooseVideo)
    Get.lazyPut(() => GetChooseVideo(), fenix: true);
    Get.lazyPut(() => GetAddManyImage(), fenix: true); // إذا لم يكن static

  }
}