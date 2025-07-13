import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart'; // <--- إضافة استيراد GetX

// --- استيراد الكنترولر والكلاسات الفرعية ---
import '../Chose-The-Type-Of-Itemxx.dart';
import 'InformationBinding.dart';
import 'class/ClassOfAddItem.dart';
import 'class/ClassOfAddOferItem.dart'; // <--- تصحيح الاسم إذا كان Offer

class InformationOfItem extends StatelessWidget {
  final Uint8List uint8list;
  final String TypeItem;

  // استخدم const إذا لم تتغير المتغيرات
  const InformationOfItem({
    super.key,
    required this.uint8list,
    required this.TypeItem,
  });

  @override
  Widget build(BuildContext context) {
    // --- ▼▼▼ إنشاء وتسجيل الـ Controller هنا ▼▼▼ ---
    final String controllerTag = 'add_$TypeItem';
    // الآن Get.find سيعمل لأنه تم الحقن بواسطة Binding
    final Getinformationofitem1 controller = Get.find<Getinformationofitem1>(tag: controllerTag);
    // --- ▲▲▲ نهاية الإنشاء والتسجيل ▲▲▲ ---

    return Scaffold(
      // تعديل بسيط: استخدام AppBar يمكن أن يكون أفضل لتناسق الواجهة
      appBar: AppBar(
        title: Text(TypeItem == 'Item' ? "إضافة منتج جديد" : "إضافة عرض جديد"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Get.to(
                  () => InformationOfItem( // لا نمرر البيانات هنا
                uint8list: uint8list, // أو يمكن قراءتها داخل binding/controller
                TypeItem: TypeItem,
              ),
              binding: InformationBinding( // <-- استخدام الـ Binding وتمرير البيانات الأولية له
                  imageBytes: uint8list,
                  itemType: TypeItem
              ),
              // لا تنسى tag إذا كنت تستخدمه في Binding أيضاً
              // arguments: ... إذا استخدمت arguments بدل Binding params
            );
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        // لم تعد بحاجة لـ Stack هنا غالباً
        child: TypeItem == 'Item'
        // --- تمرير الـ Controller المُنشأ ---
            ? ClassOfAddItem(controller: controller)
        // ============================================================
        // ============================================================
        // --- تمرير الـ Controller المُنشأ ---
        // تأكد من أن ClassOfAddOfferItem يقبل Controller أيضاً
            : ClassOfAddOfferItem(controller: controller),
      ),
    );
  }
}