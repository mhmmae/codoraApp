import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

// ---!!! استيراد الـ Controller الصحيح (AddRemoveController) !!!---
import '../../../XXX/xxx_firebase.dart';
import '../Get-Controllar/Get-BoxAddAndRemover.dart'; // <-- اضبط المسار إذا كان مختلفاً

// ملاحظة: تم حذف الاستيراد غير المستخدم لـ Get-BoxAddAndRemover.dart

class BoxAddAndRemove extends StatelessWidget {
  final String uidItem;
  final int price; // السعر يجب أن يكون int
  final String name; // اسم المنتج
  final bool isOffer;
  final String uidAdd;


  // معرف فريد للمستند الخاص بهذه الويدجت في Firestore (للسلة)
  final String _instanceDocId = const Uuid().v4();

  BoxAddAndRemove({
    super.key,
    required this.uidItem,
    required this.uidAdd,
    required this.price,
    required this.name, // مطلوب لـ AddRemoveController غالباً أو لنموذج السلة
    this.isOffer = false, // قيمة افتراضية false
  });

  // ---!!! تعديل اسم المعامل هنا وفي الاستدعاءات !!!---
  Widget _buildActionButton({
    required IconData icon,
    VoidCallback? onPressed,
    required BuildContext c, // 'context' بدلاً من 'c' لزيادة الوضوح
    required double iconSize, // <-- تغيير اسم المعامل من 'is'
    bool isDisabled = false,
  }) {
    final theme = Theme.of(c);
    return InkWell(
        onTap: isDisabled ? null : onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: Icon(icon,
                size: iconSize, // <-- استخدام اسم المعامل الصحيح
                color: isDisabled ? theme.disabledColor : theme.colorScheme.primary)));
  }

  @override
  Widget build(BuildContext context) {
    final wi = MediaQuery.of(context).size.width;
    final th = Theme.of(context); // theme

    // تحديد أحجام نسبية للعناصر
    final double priceFontSize = wi / 30; // لحجم خط السعر
    final double numberFontSize = wi / 28; // لحجم خط الرقم
    // ---!!! تعديل اسم المتغير هنا وفي الاستدعاءات !!!---
    final double defaultIconSize = wi / 18; // <-- حجم الأيقونة الافتراضي

    // استخدام AddRemoveController وربطه بـ Tag فريد
    final AddRemoveController controller = Get.put(
        AddRemoveController(
          docId: _instanceDocId, // المعرف الفريد لهذا العنصر في واجهة السلة
          uidItem: uidItem,      // معرف المنتج
          isOffer: isOffer,
          uidAdd: uidAdd
          // يمكن إضافة name و price هنا إذا كان المتحكم يحتاجها أو يحفظها مباشرة
        ),
        tag: _instanceDocId, // الربط
        permanent: false // يتم حذفه عند إزالة الـ Widget
    );

    return Column(mainAxisSize: MainAxisSize.min, children: [
      // عرض السعر
      Text(
        // التأكد من وجود قيمة معرفة في FirebaseX.currency
        '$price ${FirebaseX.currency ?? 'ريال'}', // إضافة قيمة افتراضية للعملة
        style: TextStyle(
            fontSize: priceFontSize,
            fontWeight: FontWeight.bold,
            color: th.primaryColor),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 6), // مسافة

      // صف أزرار الإضافة والإزالة والرقم
      Obx(() => Row( // مراقبة العدد لتحديث حالة الزر
          mainAxisAlignment: MainAxisAlignment.spaceEvenly, // توزيع العناصر
          children: [
            // زر الإزالة
            _buildActionButton(
                icon: Icons.remove_circle_outline,
                onPressed: controller.number.value > 0 ? controller.removeItem : null,
                isDisabled: controller.number.value <= 0, // تعطيل الزر إذا كان العدد 0
                c: context, // تمرير السياق
                // ---!!! استخدام اسم المعامل الصحيح هنا !!!---
                iconSize: defaultIconSize // <-- تمرير حجم الأيقونة
            ),
            // الرقم الحالي
            SizedBox(
              width: wi / 12, // تحديد عرض لضمان الثبات
              child: Center(
                  child: Text(
                    // تأكد من عدم عرض قيمة سالبة
                      '${controller.number.value < 0 ? 0 : controller.number.value}',
                      style: TextStyle(fontSize: numberFontSize, fontWeight: FontWeight.bold))),
            ),
            // زر الإضافة
            _buildActionButton(
                icon: Icons.add_circle_outline,
                onPressed: controller.addItem,
                isDisabled: false, // زر الإضافة ممكن دائماً
                c: context, // تمرير السياق
                // ---!!! استخدام اسم المعامل الصحيح هنا !!!---
                iconSize: defaultIconSize // <-- تمرير حجم الأيقونة
            ),
          ]
      )),
    ]);
  }
}