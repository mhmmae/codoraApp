
import 'package:flutter/foundation.dart';

class ModelTheChosen /*extends Equatable*/ {
  final bool isOfer;
  final int number;
  final String uidItem; // معرف المنتج الأصلي
  final String uidOfDoc; // معرف مستند الاختيار هذا
  final String uidUser; // معرف المستخدم
  final String uidAdd; // معرف المستخدم

  const ModelTheChosen({
    required this.isOfer,
    required this.number,
    required this.uidOfDoc,
    required this.uidItem,
    required this.uidAdd,
    required this.uidUser,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'isOfer': isOfer,
      'number': number,
      'uidItem': uidItem,
      'uidAdd': uidAdd,

      'uidOfDoc': uidOfDoc,
      'uidUser': uidUser,
      // يمكنك إضافة timestamp هنا أيضًا إذا أردت معرفة متى تم آخر تعديل
      // 'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  factory ModelTheChosen.fromMap(Map<String, dynamic> map) {
    // التحقق من وجود الحقول الأساسية قبل التحويل
    if (!map.containsKey('number') || !map.containsKey('uidItem') || !map.containsKey('uidUser')) {
      // يمكنك رمي Exception أو إرجاع قيمة null أو نموذج افتراضي مع قيم خاطئة للإشارة للخطأ
      debugPrint("Error: Missing required fields in ModelTheChosen.fromMap data: $map");
      // return null; or throw FormatException('...');
      // إرجاع نموذج بقيم واضحة للخطأ
      return ModelTheChosen(isOfer: false, number: -1, uidOfDoc: 'error', uidItem: 'error',uidAdd: 'error', uidUser: 'error');
    }

    return ModelTheChosen(
      isOfer: map['isOfer'] as bool? ?? false,
      number: (map['number'] as num?)?.toInt() ?? 0,
      // uidOfDoc قد لا يكون دائمًا مخزنًا في المستند نفسه، بل هو معرف المستند
      uidOfDoc: map['uidOfDoc'] as String? ?? '',
      uidAdd: map['uidAdd'] as String? ?? '',

      uidItem: map['uidItem'] as String? ?? '',
      uidUser: map['uidUser'] as String? ?? '',
    );
  }

/*@override
  List<Object?> get props => [isOfer, number, uidItem, uidOfDoc, uidUser];*/
}