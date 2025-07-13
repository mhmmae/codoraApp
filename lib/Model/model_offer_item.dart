import 'package:cloud_firestore/cloud_firestore.dart';

import '../XXX/xxx_firebase.dart'; // للتحقق من التساوي (Equatable) إذا رغبت


// استخدم Equatable لتبسيط المقارنة والتضمين في المجموعات/الخرائط
class OfferModel /*extends Equatable*/ {
  final String id; // معرف مستند العرض نفسه
  final String name;
  final String? description;
  final double price;      // السعر المخفض
  final double oldPrice;   // السعر الأصلي
  final int rate;       // نسبة الخصم
  final String? imageUrl;
  final List<String> manyImages;
  final String? videoUrl;
  final String uidAdd;    // معرف المستخدم الذي أضاف العرض
  final String appName;
  
  // حقول بلد المنشأ
  final String? countryOfOrigin; // المفتاح (مثل 'AF', 'US')
  final String? countryOfOriginAr; // الاسم العربي (مثل 'أفغانستان', 'الولايات المتحدة')
  final String? countryOfOriginEn; // الاسم الإنجليزي (مثل 'Afghanistan', 'United States')
  final String? itemCondition; // original, commercial
  final int? qualityGrade; // 1-10
  // ---!!! الحقل الجديد الاختياري !!!---
  final String? originalItemId; // <-- إضافة هنا (معرف المنتج الأصلي)
  // -----------------------------------
  final bool isOffer = true; // خاصية ثابتة لتمييز العروض

  // الحقول الجديدة
  final double? costPrice; // سعر التكلفة
  final String? addedBySellerType; // نوع البائع
  final String? mainProductBarcode; // الباركود الرئيسي للمنتج
  final List<String>? productBarcodes; // قائمة باركودات المنتج
  final int? quantity; // كمية المنتج
  final int? quantityPerCarton; // كمية المنتج في الكارتونة الواحدة (للبائع الجملة فقط)
  final double? suggestedRetailPrice; // السعر المقترح للبائع المفرد (للبائع الجملة فقط)

  const OfferModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.oldPrice,
    required this.rate,
    this.imageUrl,
    this.manyImages = const [],
    this.videoUrl,
    required this.uidAdd,
    required this.appName,
    this.countryOfOrigin,
    this.countryOfOriginAr,
    this.countryOfOriginEn,
    this.itemCondition,
    this.qualityGrade,
    this.originalItemId, // <-- إضافة للمعاملات (اختياري)
    this.costPrice, // سعر التكلفة
    this.addedBySellerType, // نوع البائع
    this.mainProductBarcode, // الباركود الرئيسي للمنتج
    this.productBarcodes, // قائمة باركودات المنتج
    this.quantity, // كمية المنتج
    this.quantityPerCarton, // كمية المنتج في الكارتونة الواحدة
    this.suggestedRetailPrice, // السعر المقترح للبائع المفرد
  });

  // التحويل من Map (بيانات Firestore) إلى كائن OfferModel
  factory OfferModel.fromMap(Map<String, dynamic> map, String documentId) {
    // التحويل بأمان مع التحقق من الأنواع والقيم الافتراضية
    return OfferModel(
      id: documentId, // استخدام ID المستند الممرر
      name: map['nameOfItem'] as String? ?? 'عرض بدون اسم', // اسم المنتج أو قيمة افتراضية
      description: map['descriptionOfItem'] as String?,
      price: (map['priceOfItem'] as num?)?.toDouble() ?? 0.0, // السعر الحالي للعرض
      oldPrice: (map['oldPrice'] as num?)?.toDouble() ?? 0.0, // السعر الأصلي قبل الخصم
      rate: (map['rate'] as num?)?.toInt() ?? 0,       // نسبة الخصم
      imageUrl: map['url'] as String?,                // الرابط الرئيسي للصورة
      manyImages: List<String>.from((map['manyImages'] as List<dynamic>?) ?? []), // قائمة الصور الإضافية
      // التعامل مع قيمة 'noVideo' المحتملة أو null
      videoUrl: map['videoURL'] == 'noVideo' ? null : map['videoURL'] as String?,
      uidAdd: map['uidAdd'] as String? ?? '',          // معرف المستخدم الذي أضافه
      appName: map['appName'] as String? ?? FirebaseX.appName, // اسم التطبيق مع قيمة افتراضية
      countryOfOrigin: map['countryOfOrigin'] as String?,
      countryOfOriginAr: map['countryOfOriginAr'] as String?,
      countryOfOriginEn: map['countryOfOriginEn'] as String?,
      itemCondition: map['itemCondition'] as String?,
      qualityGrade: (map['qualityGrade'] as num?)?.toInt(),
      // --- قراءة الحقل الجديد إذا كان موجودًا ---
      originalItemId: map['originalItemId'] as String?, // <-- إضافة هنا
      costPrice: (map['costPrice'] as num?)?.toDouble(), // سعر التكلفة
      addedBySellerType: map['addedBySellerType'] as String?, // نوع البائع
      mainProductBarcode: map['mainProductBarcode'] as String?, // الباركود الرئيسي للمنتج
      productBarcodes: List<String>.from(map['productBarcodes'] ?? []), // قائمة باركودات المنتج
      quantity: (map['quantity'] as num?)?.toInt(), // كمية المنتج
      quantityPerCarton: (map['quantityPerCarton'] as num?)?.toInt(), // كمية المنتج في الكارتونة الواحدة
      suggestedRetailPrice: (map['suggestedRetailPrice'] as num?)?.toDouble(), // السعر المقترح للبائع المفرد
    );
  }

  // التحويل من كائن OfferModel إلى Map (لحفظه في Firestore)
  Map<String, dynamic> toMap() {
    final mapData = <String, dynamic>{
      'nameOfItem': name,
      'descriptionOfItem': description,
      'priceOfItem': price, // سعر العرض
      'oldPrice': oldPrice,
      'rate': rate,
      'url': imageUrl,
      'manyImages': manyImages,
      'videoURL': videoUrl ?? 'noVideo', // حفظ 'noVideo' إذا كان null
      'uidAdd': uidAdd,
      'appName': appName,
      'countryOfOrigin': countryOfOrigin,
      'countryOfOriginAr': countryOfOriginAr,
      'countryOfOriginEn': countryOfOriginEn,
      'itemCondition': itemCondition,
      'qualityGrade': qualityGrade,
      'isOfer': isOffer, // التأكيد على أنه عرض
      // --- إضافة وقت إنشاء/تحديث العرض ---
      // استخدم serverTimestamp() فقط عند *إنشاء* المستند لأول مرة
      // أو أرسل null عند التحديث إذا لم ترد تغييره.
      // لإدارة التحديثات، يمكن إضافة حقل `lastUpdated` منفصل
      'timestamp': FieldValue.serverTimestamp(),
      'costPrice': costPrice, // سعر التكلفة
      'addedBySellerType': addedBySellerType, // نوع البائع
      'mainProductBarcode': mainProductBarcode, // الباركود الرئيسي للمنتج
      'productBarcodes': productBarcodes ?? [], // قائمة باركودات المنتج
      'quantity': quantity, // كمية المنتج
      'quantityPerCarton': quantityPerCarton, // كمية المنتج في الكارتونة الواحدة
      'suggestedRetailPrice': suggestedRetailPrice, // السعر المقترح للبائع المفرد
    };

    // ---!!! إضافة originalItemId فقط إذا لم يكن null !!!---
    if (originalItemId != null && originalItemId!.isNotEmpty) {
      mapData['originalItemId'] = originalItemId; // <-- إضافة هنا
    }
    // -------------------------------------------
    return mapData;
  }

/*@override // إذا استخدمت Equatable
  List<Object?> get props => [
      id,
      name,
      description,
      price,
      oldPrice,
      rate,
      imageUrl,
      // لا تضع manyImages هنا إذا أردت مقارنة العروض بدون مقارنة كل الصور
      videoUrl,
      uidAdd,
      appName,
      originalItemId, // <-- إضافة هنا لـ props
     ];*/

// @override // إذا استخدمت Equatable
// bool? get stringify => true; // لجعل debugPrint(offer) أكثر وضوحاً (اختياري)
}