//
//
//
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
//
// class TextFomeFildeCodePhone extends StatelessWidget {
//
//   bool first;
//   bool correct;
//   bool last;
//   TextEditingController codePhone;
//   VoidCallback? sendcode;
//
//    TextFomeFildeCodePhone({super.key,required this.first,required this.last,required this.codePhone,required this.correct,this.sendcode});
//
//   @override
//   Widget build(BuildContext context) {
//     double hi = MediaQuery.of(context).size.height;
//     double wi = MediaQuery.of(context).size.width;
//     return Container(
//     decoration: BoxDecoration(
//     color: Colors.black12,
//     border: Border.all(color: correct ?Colors.greenAccent:Colors.red, width: 2),
//     borderRadius: BorderRadius.circular(15)),
//     child: TextFormField(
//       controller: codePhone,
//       onChanged: (val){
//         if(val.isNotEmpty && last == false){
//           FocusScope.of(context).nextFocus();
//
//         }else if(val.isEmpty && first ==false){
//           FocusScope.of(context).previousFocus();
//         }else if(val.isNotEmpty && first ==false && last ==true){
//           sendcode!();
//
//         }
//       },
//     style: TextStyle(fontSize: wi/16),
//     inputFormatters: [LengthLimitingTextInputFormatter(1)],
//     textAlign: TextAlign.center,
//     decoration: InputDecoration(
//     border: InputBorder.none,
//     constraints: BoxConstraints(
//     maxWidth: wi/7,
//     maxHeight: hi/9),
//
// ),
//
// keyboardType: TextInputType.number,
//
// ),
// );
//   }
// }














import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget لمدخل حرف/رقم واحد (عادةً من رمز التحقق OTP)
/// تم تعديل الاسم إلى CodeInputField لجعله أكثر وضوحاً.
/// يعتمد على خاصية [first] لتحديد إذا كان أول حقل،
/// و[correct] لتلوين الحد طبقاً لصحة المدخل،
/// و[last] لتحديد إذا كان الحقل الأخير (يستدعي sendCode عند إدخال قيمة غير فارغة).
class CodeInputField extends StatelessWidget {
  final bool first;
  final bool last;
  final bool correct;
  final TextEditingController controller;
  final VoidCallback? onSendCode;

  const CodeInputField({
    super.key,
    required this.first,
    required this.last,
    required this.controller,
    required this.correct,
    this.onSendCode,
  });

  @override
  Widget build(BuildContext context) {
    // الحصول على أبعاد الشاشة
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black12,
        border: Border.all(
          color: correct ? Colors.greenAccent : Colors.red,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextFormField(
        controller: controller,
        // عند تغيير القيمة نقوم بأخذ الإجراء المناسب
        onChanged: (val) {
          // إذا كانت القيمة غير فارغة والحقل ليس الأخير، انتقل للحقل التالي.
          if (val.isNotEmpty && !last) {
            FocusScope.of(context).nextFocus();
          }
          // إذا كانت القيمة فارغة والحقل ليس الأول، ارجع إلى الحقل السابق.
          else if (val.isEmpty && !first) {
            FocusScope.of(context).previousFocus();
          }
          // إذا كانت القيمة غير فارغة والحقل الأخير (خارج أول جهاز) يتم استدعاء onSendCode
          else if (val.isNotEmpty && !first && last) {
            if (onSendCode != null) {
              onSendCode!();
            }
          }
        },
        // تنسيق الخط بالنسبة لحجم الشاشة
        style: TextStyle(fontSize: width / 16),
        // تحديد أن الحقل يقبل حرفاً واحداً فقط وأيضاً قيود بالأرقام فقط
        inputFormatters: [
          LengthLimitingTextInputFormatter(1),
          FilteringTextInputFormatter.digitsOnly,
        ],
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          border: InputBorder.none,
          constraints: BoxConstraints(
            maxWidth: width / 7,
            maxHeight: height / 9,
          ),
        ),
        keyboardType: TextInputType.number,
      ),
    );
  }
}
