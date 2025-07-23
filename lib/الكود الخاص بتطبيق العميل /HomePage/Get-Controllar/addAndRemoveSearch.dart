
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
// تأكد من استيراد الـ Controller الصحيح
import 'Get-BoxAddAndRemover.dart'; // <-- قم بتغيير المسار إذا لزم الأمر

class AddAndRemoveSearchWidget extends StatelessWidget {
  final String uidItem; // معرف المنتج الفعلي
  final bool isOffer;
  final String uidAdd; // معرف المنتج الفعلي

  // أحجام افتراضية يمكن تخصيصها
  final double? buttonHeight;
  final double? buttonWidth;
  final double? iconSize;
  final double? spacing;
  final double? numberFontSize;

  // معرف فريد لكل مثيل من هذه الويدجت لربطه بمثيل Controller خاص به
  // يجب أن يكون final ويُهيأ مرة واحدة لكل widget instance
  final String _instanceDocId = const Uuid().v4();

  AddAndRemoveSearchWidget({
    super.key,
    required this.uidItem,
    required this.uidAdd,
    required this.isOffer, // <-- استخدام isOffer
    this.buttonHeight,
    this.buttonWidth,
    this.iconSize,
    this.spacing,
    this.numberFontSize,
  }) {
    // Debugging: تأكد من أن كل مثيل يحصل على ID فريد
    // debugPrint("Creating AddAndRemoveSearchWidget with instanceId: $_instanceDocId for item: $uidItem");
  }

  // دالة مساعدة لبناء الأزرار
  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required BuildContext context,
    required double defaultHeight,
    required double defaultWidth,
    required double defaultIconSize,
    bool isDisabled = false,
  }) {
    final theme = Theme.of(context);
    final Color bgColor = isDisabled
        ? Colors.grey.withOpacity(0.1)
        : theme.colorScheme.primary.withOpacity(0.08);
    final Color borderColor =
    isDisabled ? Colors.grey.withOpacity(0.3) : theme.dividerColor;
    final Color iconColor =
    isDisabled ? theme.disabledColor : theme.colorScheme.primary;

    return InkWell(
      onTap: isDisabled ? null : onPressed,
      borderRadius: BorderRadius.circular(16), // Make InkWell ripple circular
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(16),
        ),
        height: buttonHeight ?? defaultHeight,
        width: buttonWidth ?? defaultWidth,
        child: Center(child: Icon(icon, size: iconSize ?? defaultIconSize, color: iconColor)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double hi = MediaQuery.of(context).size.height;
    final double wi = MediaQuery.of(context).size.width;
    final ThemeData theme = Theme.of(context);

    // القيم الافتراضية للأحجام
    final double dBH = hi * 0.05;
    final double dBW = wi * 0.09; // زيادة العرض قليلاً
    final double dIS = wi * 0.055; // زيادة حجم الأيقونة قليلاً
    final double dSp = wi * 0.015;
    final double dNFS = wi * 0.045; // زيادة حجم خط الرقم قليلاً

    // حقن/إيجاد الـ Controller باستخدام ה-tag الفريد _instanceDocId
    // permanent: false يعني أنه سيتم حذفه عند إزالة الـ widget
    final AddRemoveController controller = Get.put(
      AddRemoveController(
          docId: _instanceDocId, // استخدام معرف الـ Widget كـ Firestore doc ID لهذه الحالة
          uidItem: uidItem,
          uidAdd: uidAdd,// معرف المنتج
          isOffer: isOffer),     // حالة العرض
      tag: _instanceDocId,       // ربط الـ Controller بالـ Widget باستخدام الـ Tag
      permanent: false,
    );

    // استخدام Obx لمراقبة controller.number.value وتحديث الأزرار
    return Obx(() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min, // تأخذ أقل مساحة ممكنة
        children: [
          // زر الإضافة
          _buildActionButton(
            icon: Icons.add_circle_outline,
            onPressed: controller.addItem, // استدعاء دالة الإضافة
            context: context,
            defaultHeight: dBH, defaultWidth: dBW, defaultIconSize: dIS,
          ),
          SizedBox(width: spacing ?? dSp),
          // عرض العدد الحالي
          Container(
            constraints: BoxConstraints(minWidth: wi * 0.07), // ضمان وجود مساحة للرقم
            alignment: Alignment.center,
            child: Text(
              // التأكد من عدم عرض قيمة سالبة
              '${controller.number.value < 0 ? 0 : controller.number.value}',
              style: TextStyle(
                fontSize: numberFontSize ?? dNFS,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: spacing ?? dSp),
          // زر الإزالة (مع التحقق من number > 0 لتمكينه)
          _buildActionButton(
            icon: Icons.remove_circle_outline,
            onPressed: controller.number.value > 0 ? controller.removeItem : null,
            isDisabled: controller.number.value <= 0, // تعطيل الزر إذا كان العدد 0 أو أقل
            context: context,
            defaultHeight: dBH, defaultWidth: dBW, defaultIconSize: dIS,
          ),
        ],
      ),
    ));
  }
}

// ------------------------------------------
// ملاحظة: احذف الملفات القديمة GetAddAndRemoveSearch.dart و GetBoxAddAndRemover.dart
// واستبدل استيراداتها بـ AddRemoveController.dart
// وتأكد من أن BoxAddAndRemove يستخدم AddRemoveController بنفس الطريقة.
// ------------------------------------------