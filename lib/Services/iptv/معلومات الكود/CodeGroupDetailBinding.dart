import 'package:get/get.dart';

import '../عرض كل انواع الكودات /CodeGroupsController.dart';
import 'CodeRequestController.dart';
// استورد كلا الكنترولرين (تأكد من المسارات الصحيحة)

class CodeGroupDetailBinding extends Bindings {
  @override
  void dependencies() {
    // استخدام Get.find للعثور على النسخة الموجودة بالفعل من CodeGroupsController
    // والتي تم إنشاؤها في الشاشة السابقة
    // ملاحظة: تأكد أن CodeGroupsController معرف كـ permanent أو باستخدام Get.put في مكان ما قبل الانتقال لهذه الشاشة
    Get.find<CodeGroupsController>();

    // استخدام lazyPut لإنشاء CodeRequestController فقط عند الحاجة إليه لأول مرة
    Get.lazyPut<CodeRequestController>(() => CodeRequestController());
  }
}