
// يمثل عنصر واحد ضمن قائمة الطلبات الكاملة
import 'package:flutter/foundation.dart';
import '../XXX/xxx_firebase.dart';

class ModelTheOrderList /*extends Equatable*/ {
  final bool isOfer;
  final int number;
  final String uidItem; // معرف المنتج/العرض الأصلي
  final String uidOfDoc; // معرف مستند هذا العنصر داخل الطلب
  final String uidUser; // معرف المستخدم صاحب الطلب
  final String appName;
  final String uidAdd;

  // final int priceAtOrderTime;
  // final String nameAtOrderTime;
  // final String itemStatus;

  const ModelTheOrderList({
    required this.uidUser,
    required this.uidItem,
    required this.uidOfDoc,
    required this.number,
    required this.isOfer,
    required this.appName,
    required this.uidAdd,

  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'isOfer': isOfer,
      'number': number,
      'uidItem': uidItem,
      'uidOfDoc': uidOfDoc,
      'uidUser': uidUser,
      'appName': appName,
      'uidAdd': uidAdd,

      // 'timestamp': FieldValue.serverTimestamp(),
    };
  }

  factory ModelTheOrderList.fromMap(Map<String, dynamic> map) {
    if (!map.containsKey('number') || !map.containsKey('uidItem') || !map.containsKey('uidUser')) {
      debugPrint("Error: Missing required fields in ModelTheOrderList.fromMap data: $map");
      return const ModelTheOrderList(uidUser: 'error', uidItem: 'error', uidOfDoc: 'error', number: -1, isOfer: false, appName: 'error',uidAdd:'error' );
    }
    return ModelTheOrderList(
      uidUser: map['uidUser'] as String? ?? '',
      uidItem: map['uidItem'] as String? ?? '',
      uidOfDoc: map['uidOfDoc'] as String? ?? '',
      number: (map['number'] as num?)?.toInt() ?? 0,
      isOfer: map['isOfer'] as bool? ?? false,
      appName: map['appName'] as String? ?? FirebaseX.appName,
      uidAdd: map['uidAdd'] as String? ?? '',

    );
  }

/*@override
  List<Object?> get props => [uidUser, uidItem, uidOfDoc, number, isOfer, appName];*/
}