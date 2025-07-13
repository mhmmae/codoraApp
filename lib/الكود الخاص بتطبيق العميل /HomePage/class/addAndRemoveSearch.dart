import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

// ---!!! 1. استيراد المتحكم الصحيح !!!---
// تأكد من أن المسار إلى ملف AddRemoveController.dart صحيح
import '../Get-Controllar/Get-BoxAddAndRemover.dart'; // <-- غيّر المسار إذا لزم الأمر

/// Widget لعرض أزرار الإضافة والإزالة مع عرض العدد الحالي
class AddAndRemoveSearchWidget extends StatelessWidget {
  /// معرّف العنصر (المنتج) الفعلي
  final String uidItem;
  /// حالة العرض (عرض أم منتج عادي)
  // ---!!! 2. توحيد اسم المعامل إلى isOffer !!!---
  final bool isOffer;
  /// إعدادات حجم العناصر اختيارية
  final double? buttonHeight; // استخدام أسماء واضحة بدلاً من hi5/wi5
  final double? buttonWidth;
  final double? iconSize;
  final double? spacing;
  final double? numberFontSize;
  final String uidAdd;


  /// معرف فريد لمثيل هذه الـ Widget والمستند المرتبط بها في Firestore
  final String _instanceDocId = const Uuid().v4(); // استخدام v4 هو الأكثر شيوعًا الآن

  AddAndRemoveSearchWidget({
    super.key,
    required this.uidItem,
    required this.uidAdd,

    required this.isOffer, // <-- استخدام isOffer هنا أيضاً
    this.buttonHeight,
    this.buttonWidth,
    this.iconSize,
    this.spacing,
    this.numberFontSize,
  });

  @override
  Widget build(BuildContext context) {
    // الحصول على أبعاد الشاشة والثيم لاستخدامها في التصميم الافتراضي
    double hi = MediaQuery.of(context).size.height;
    double wi = MediaQuery.of(context).size.width;
    ThemeData theme = Theme.of(context);

    // ---!!! 3. استخدام AddRemoveController بدلاً من GetAddAndRemoveSearch !!!---
    // حقن الـ Controller الخاص بهذا العنصر باستخدام tag فريد
    final AddRemoveController controller = Get.put(
      AddRemoveController(
        docId: _instanceDocId, // استخدام المعرف الفريد كـ docId لهذه النسخة من الويدجت
        uidItem: uidItem,      // تمرير معرف المنتج
        isOffer: isOffer, // تمرير حالة العرض
        uidAdd: uidAdd
      ),
      tag: _instanceDocId,     // استخدام Tag لربط الويدجت بالمتحكم الخاص بها
      permanent: false,         // احذف المتحكم عند إزالة الويدجت
    );

    // القيم الافتراضية للأحجام إذا لم يتم توفيرها
    final double defaultButtonHeight = buttonHeight ?? hi * 0.05;
    final double defaultButtonWidth = buttonWidth ?? wi * 0.09;
    final double defaultIconSize = iconSize ?? wi * 0.055;
    final double defaultSpacing = spacing ?? wi * 0.015;
    final double defaultNumberFontSize = numberFontSize ?? wi * 0.045;

    // ---!!! 4. استخدام Obx لمراقبة controller.number.value لتحديث الواجهة !!!---
    return Obx(() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min, // ليأخذ أقل عرض ممكن
        children: [
          // زر الإضافة
          _buildActionButton(
            icon: Icons.add_circle_outline,
            // ---!!! 5. استدعاء دوال AddRemoveController التي لا تأخذ معاملات !!!---
            onPressed: controller.addItem,
            context: context,
            theme: theme,
            height: defaultButtonHeight,
            width: defaultButtonWidth,
            iconSize: defaultIconSize,
          ),
          SizedBox(width: defaultSpacing),

          // عرض العدد الحالي
          Container(
            constraints: BoxConstraints(minWidth: wi * 0.07),
            alignment: Alignment.center,
            child: Text(
              '${controller.number.value < 0 ? 0 : controller.number.value}',
              style: TextStyle(
                  fontSize: defaultNumberFontSize,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color),
            ),
          ),
          SizedBox(width: defaultSpacing),

          // زر الإزالة (مع تمكين/تعطيل بناءً على العدد)
          _buildActionButton(
            icon: Icons.remove_circle_outline,
            // ---!!! 5. استدعاء دوال AddRemoveController التي لا تأخذ معاملات !!!---
            onPressed: controller.number.value > 0 ? controller.removeItem : null,
            isDisabled: controller.number.value <= 0, // التعطيل عند الصفر
            context: context,
            theme: theme,
            height: defaultButtonHeight,
            width: defaultButtonWidth,
            iconSize: defaultIconSize,
          ),
        ],
      ),
    ));
  }

  // دالة مساعدة لبناء أزرار الـ InkWell
  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required BuildContext context,
    required ThemeData theme,
    required double height,
    required double width,
    required double iconSize,
    bool isDisabled = false,
  }) {
    final Color bgColor = isDisabled
        ? Colors.grey.withOpacity(0.1)
        : theme.colorScheme.primary.withOpacity(0.08);
    final Color borderColor =
    isDisabled ? Colors.grey.withOpacity(0.3) : theme.dividerColor;
    final Color iconColor =
    isDisabled ? theme.disabledColor : theme.colorScheme.primary;

    return InkWell(
      onTap: isDisabled ? null : onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(16),
        ),
        height: height,
        width: width,
        child: Center(
            child: Icon(icon, size: iconSize, color: iconColor)),
      ),
    );
  }
}