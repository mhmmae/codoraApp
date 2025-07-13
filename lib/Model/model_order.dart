import 'package:cloud_firestore/cloud_firestore.dart'; // لاستخدام Timestamp
import 'package:flutter/foundation.dart';

@immutable
class OrderModel { // تم تغيير الاسم إلى OrderModel
  final bool delivery;
  final bool requestAccept;
  final bool doneDelivery;
  final String appName;
  final String uidUser;
  final GeoPoint location; // تم تغيير latitude/longitude إلى location كـ GeoPoint
  final DateTime timeOrder;
  final String numberOfOrder; // تم تعديل التهجئة من nmberOfOrder
  final int totalPriceOfOrder;
  final String uidAdd;

  const OrderModel({
    required this.uidUser,
    required this.uidAdd,
    required this.appName,
    required this.location,
    required this.delivery,
    required this.doneDelivery,
    required this.numberOfOrder,
    required this.totalPriceOfOrder,
    required this.requestAccept,
    required this.timeOrder,
  });

  // خصائص للوصول للـ latitude و longitude للتوافق العكسي
  double get latitude => location.latitude;
  double get longitude => location.longitude;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'Delivery': delivery,
      'numberOfOrder': numberOfOrder,
      'totalPriceOfOrder': totalPriceOfOrder,
      'RequestAccept': requestAccept,
      'doneDelivery': doneDelivery,
      'appName': appName,
      'uidUser': uidUser,
      'uidAdd': uidAdd,
      'location': location, // حفظ الموقع كـ GeoPoint
      // للتوافق مع الكود القديم، نحفظ أيضاً latitude و longitude منفصلين
      'latitude': location.latitude,
      'longitude': location.longitude,
      'timeOrder': Timestamp.fromDate(timeOrder), // تخزين كـ Timestamp
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    // محاولة قراءة الموقع كـ GeoPoint أولاً، ثم كـ latitude/longitude منفصلين للتوافق العكسي
    GeoPoint location;
    if (map['location'] is GeoPoint) {
      location = map['location'] as GeoPoint;
    } else if (map['latitude'] != null && map['longitude'] != null) {
      location = GeoPoint(
        (map['latitude'] as num).toDouble(),
        (map['longitude'] as num).toDouble(),
      );
    } else {
      location = const GeoPoint(0.0, 0.0); // قيمة افتراضية
    }

    return OrderModel(
      uidUser: map['uidUser'] ?? '',
      uidAdd: map['uidAdd'] ?? '',
      totalPriceOfOrder: (map['totalPriceOfOrder'] ?? 0).toInt(),
      appName: map['appName'] ?? '',
      location: location,
      delivery: map['Delivery'] ?? false,
      doneDelivery: map['doneDelivery'] ?? false,
      numberOfOrder: map['nmberOfOrder'] ?? map['numberOfOrder'] ?? '', // التعامل مع التهجئة القديمة
      requestAccept: map['RequestAccept'] ?? false,
      timeOrder: map['timeOrder'] is Timestamp
          ? (map['timeOrder'] as Timestamp).toDate()
          : DateTime.tryParse(map['timeOrder'].toString()) ?? DateTime.now(), // معالجة Timestamp
    );
  }

// يمكنك إضافة copyWith, toString, ==, hashCode إذا لزم الأمر
}