


import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Controller لتحويل الطوابع الزمنية (Timestamp) من Firebase Firestore إلى نصوص منصقة.
/// يُمكن استخدام هذه الدوال لعرض التاريخ والوقت بشكل مناسب داخل التطبيق.
class GetDateToText extends GetxController {
  /// يحول الـ [timeStamp] المُستلم من Firestore إلى نص بالتنسيق "hh:mm a / dd-MM-yyyy".
  ///
  /// مثال:
  ///   إذا كان timeStamp يمثل تاريخ "2023-10-05 13:30:00"، سيُرجع النص "01:30 PM / 05-10-2023".
  String dateToText(Timestamp timeStamp) {
    // تحويل الـ Timestamp إلى DateTime باستخدام الثواني.
    final DateTime dateTime =
    DateTime.fromMillisecondsSinceEpoch(timeStamp.seconds * 1000);
    // صياغة التاريخ والوقت بالتنسيق المطلوب.
    return DateFormat('hh:mm a / dd-MM-yyyy').format(dateTime);
  }

  /// يحول الـ [timeStamp] المُستلم من Firestore إلى نص يظهر الوقت فقط بالتنسيق "hh:mm a".
  ///
  /// مثال:
  ///   إذا كان timeStamp يمثل تاريخ "2023-10-05 13:30:00"، سيُرجع النص "01:30 PM".
  String dateTimeToText(Timestamp timeStamp) {
    final DateTime dateTime =
    DateTime.fromMillisecondsSinceEpoch(timeStamp.seconds * 1000);
    return DateFormat('hh:mm a').format(dateTime);
  }
}
