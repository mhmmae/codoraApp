

import 'package:flutter/material.dart';

class TextFormFiled extends StatelessWidget {
  const TextFormFiled({
    super.key,
    required this.controller,
    required this.borderRadius,
    required this.label,
    this.obscure = false, // قيمة افتراضية لـ obscure
    required this.width,
    this.height,          // جعل الارتفاع اختيارياً
    required this.fontSize,
    this.validator,
    this.textInputType,
    this.onChange,
    this.focusNode,
    this.backgroundColor,
    this.hintColor,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1, // قيمة افتراضية لـ maxLines هي 1
  });

  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String label;
  final double borderRadius;
  final bool obscure;
  final double width;
  final double? height; // <--- تغيير النوع إلى اختياري
  final TextInputType? textInputType;
  final double fontSize;
  final ValueChanged<String>? onChange;
  final FocusNode? focusNode;
  final Color? backgroundColor;
  final Color? hintColor;
  final int? maxLines; // <--- يمكن أن يكون null للسماح بتمدد غير محدود
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    // تحديد ما إذا كان الحقل سيتمدد رأسياً
    // يتمدد إذا كان maxLines غير محدد (null) أو أكبر من 1، وليس حقلاً سرياً.
    final bool expands = !obscure && (maxLines == null || maxLines! > 1);

    // تحديد ارتفاع الحاوية
    // إذا كان الحقل سيتمدد، لا نحدد ارتفاعًا (null).
    // إذا كان سطراً واحداً، نستخدم الارتفاع الممرر أو ارتفاعًا افتراضيًا مناسبًا.
    final double? containerHeight = expands ? null : (height ?? 60.0); // 60 كارتفاع افتراضي لسطر واحد

    // تحديد maxLines لـ TextFormField
    // يجب أن يكون 1 دائمًا للحقول السرية
    final int effectiveMaxLines = obscure ? 1 : (maxLines ?? 1);

    return Container(
      alignment: Alignment.topCenter, // محاذاة المحتوى للأعلى عند التمدد
      width: width,
      height: containerHeight, // <--- استخدام الارتفاع المشروط
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // تعديل padding قليلاً
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey.shade100, // لون خلفية أفتح قليلاً
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.grey.shade400), // لون حد أفتح
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: textInputType,
        obscureText: obscure,
        maxLines: effectiveMaxLines, // <--- استخدام maxLines المحدد
        onChanged: onChange,
        validator: validator ??
                (value) {
              // يمكن جعل المدقق الافتراضي أكثر مرونة قليلاً
              // إذا كان الحقل متعدد الأسطر قد لا يكون مطلوباً دائماً
              // لكن سنبقيه للتبسيط الآن
              if (value == null || value.isEmpty) {
                return "هذا الحقل مطلوب";
              }
              return null;
            },
        textAlign: TextAlign.start,
        style: TextStyle(fontSize: fontSize, height: 1.4), // تعديل ارتفاع السطر للنصوص العربية
        textInputAction: expands ? TextInputAction.newline : TextInputAction.next, // السماح بسطر جديد أو الانتقال للحقل التالي
        // إخفاء لوحة المفاتيح عند النقر على "تم" (للحقول أحادية السطر)
        // أو السماح بالانتقال عند اكتمال التحرير (يمكن تخصيصه أكثر)
        onEditingComplete: () {
          FocusScope.of(context).unfocus();
        },
        decoration: InputDecoration(
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          // استخدام isDense وتحديد حشو المحتوى للتحكم أفضل بالمسافات الداخلية
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: prefixIcon != null ? 0 : 8.0), // تعديل حشو المحتوى
          border: InputBorder.none, // إزالة الحدود الداخلية للـ TextFormField
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          hintText: label,
          hintStyle: TextStyle(
            fontSize: fontSize,
            color: hintColor ?? Colors.grey.shade600, // لون أغمق للنص الإرشادي
            // fontWeight: FontWeight.bold, // قد لا تحتاج لجعل النص الإرشادي عريضاً
          ),
          // يمكنك إضافة نص مساعدة يظهر أسفل الحقل عند التركيز
          // helperText: ' ', // لمنع تغيير الحجم عند ظهور نص الخطأ
          errorStyle: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.error), // نمط لرسالة الخطأ
        ),
      ),
    );
  }
}