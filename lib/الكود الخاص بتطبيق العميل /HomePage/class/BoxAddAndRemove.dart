import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../XXX/xxx_firebase.dart';
import '../Get-Controllar/Get-BoxAddAndRemover.dart'; // استورد المتحكم الصحيح

class BoxAddAndRemove extends StatelessWidget {
  final String uidItem;
  final double price; // يجب أن يكون السعر double
  final String name; // يبدو أن الاسم لا يستخدم هنا، يمكن إزالته إذا لم يكن ضرورياً
  final bool isOffer; // استخدام isOffer
  final String uidAdd;


  // معرف فريد لكل مثيل widget لربطه بمثيل controller خاص به
  final String _instanceDocId = const Uuid().v4();

  BoxAddAndRemove({
    super.key,
    required this.uidItem,
    required this.uidAdd,

    required this.price, // تأكد أنك تمرر double
    required this.name, //
    this.isOffer = false, // قيمة افتراضية
  });

  // دالة مساعدة لبناء أزرار التحكم
  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required BuildContext context,
    required double iconSize,
    required AddRemoveController controller, // استمر في استقبال المتحكم
    required bool isAddButton,
    bool isDisabled = false,
  }) {
    final theme = Theme.of(context);

    // ---!!! اقرأ القيمة مباشرة هنا !!!---
    // Obx الخارجي سيضمن إعادة البناء عند تغير isAnimating.value
    final bool isCurrentlyAnimating = isAddButton && controller.isAnimating.value;
    final Color currentIconColor = isCurrentlyAnimating
        ? (theme.colorScheme.secondary ?? theme.colorScheme.primary) // استخدم لون ثانوي أو أساسي
        : (isDisabled ? theme.disabledColor : theme.colorScheme.primary);
    // ------------------------------------

    // ---!!! أزل Obx من هنا !!!---
    return AnimatedScale(
      // --- استخدم المتغير المحسوب ---
        scale: isCurrentlyAnimating ? 1.3 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: InkWell(
            onTap: isDisabled ? null : onPressed,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
                padding: const EdgeInsets.all(5.0),
                // --- استخدم المتغير المحسوب ---
                child: Icon( icon, size: iconSize, color: currentIconColor )
            )
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    final wi = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);

    // تحديد أحجام الخطوط والأيقونات النسبية
    final double priceFontSize = wi / 30; // لحجم خط السعر
    final double numberFontSize = wi / 28; // لحجم خط الرقم
    final double defaultIconSize = wi / 18; // <-- كان هذا معرفًا باسم `iconSiz` خطأً

    // استخدم نفس AddRemoveController، واربطه باستخدام tag الفريد instanceDocId
    final AddRemoveController controller = Get.put(
      AddRemoveController(
        docId: _instanceDocId, // معرف المثيل لهذا العنصر في السلة
        uidItem: uidItem,     // معرف المنتج الفعلي
        isOffer: isOffer,
        uidAdd: uidAdd
      ),
      tag: _instanceDocId,     // ربط Widget بـ Controller
      permanent: false,       // احذفه عند إزالة الـ Widget
    );

    return Column(
      mainAxisSize: MainAxisSize.min, // اجعل العمود يأخذ أقل ارتفاع ممكن
      children: [
        // عرض السعر بالعملة
        Text(
          '$price ${FirebaseX.currency}', // افترض أن FirebaseX.currency معرفة
          style: TextStyle(
            fontSize: priceFontSize,
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6), // مسافة بين السعر والأزرار

        // صف الأزرار والرقم
        Obx(() => Row( // Obx هنا لمراقبة العدد لتحديث حالة الأزرار
          mainAxisAlignment: MainAxisAlignment.spaceEvenly, // توزيع المسافات بالتساوي
          children: [
            // زر الإزالة
            _buildActionButton(
              icon: Icons.remove_circle_outline,
              onPressed: controller.number.value > 0 ? controller.removeItem : null,
              isDisabled: controller.number.value <= 0,
              context: context,
              iconSize: defaultIconSize,
              controller: controller, // <-- تمرير المتحكم
              isAddButton: false, // ليس زر الإضافة
            ),

            // الرقم الحالي (مع التأكد من عدم عرض قيم سالبة)
            SizedBox(
              width: wi / 12, // عرض ثابت لضمان عدم تغير تخطيط الصف
              child: Center(
                child: Text(
                  '${controller.number.value < 0 ? 0 : controller.number.value}',
                  style: TextStyle(fontSize: numberFontSize, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // زر الإضافة
            _buildActionButton(
              icon: Icons.add_circle_outline,
              onPressed: controller.addItem,
              isDisabled: false,
              context: context,
              iconSize: defaultIconSize,
              controller: controller, // <-- تمرير المتحكم
              isAddButton: true, // <--- تحديد أنه زر الإضافة
            ),
          ],
        )),
      ],
    );
  }
}