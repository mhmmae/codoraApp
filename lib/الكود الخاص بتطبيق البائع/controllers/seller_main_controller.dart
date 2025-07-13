import 'package:get/get.dart';

class SellerMainController extends GetxController {
  // مثال: متغير لتتبع الصفحة النشطة في القائمة الجانبية
  var selectedPageIndex = 0.obs;

  void changePageIndex(int index) {
    selectedPageIndex.value = index;
  }

  // يمكنك إضافة المزيد من المتغيرات والدوال هنا لإدارة حالة الواجهة الرئيسية للبائع
} 