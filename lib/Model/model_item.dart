import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../XXX/xxx_firebase.dart'; // لـ FieldValue

class ItemModel /*extends Equatable*/ {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final List<String> manyImages;
  final String? videoUrl;

  // خاصية مساعدة للحصول على قائمة الصور
  List<String> get images => manyImages;
  final String typeItem;
  final String? itemCondition;
  final int? qualityGrade;
  final String? countryOfOrigin; // المفتاح (مثل 'AF', 'US')
  final String?
  countryOfOriginAr; // الاسم العربي (مثل 'أفغانستان', 'الولايات المتحدة')
  final String?
  countryOfOriginEn; // الاسم الإنجليزي (مثل 'Afghanistan', 'United States')
  final String uidAdd;
  final String appName;
  final bool isOffer = false;

  final double? costPrice;
  final String? addedBySellerType;
  final String? productBarcode;
  final String? mainProductBarcode; // الباركود الرئيسي للمنتج
  final List<String>? productBarcodes; // قائمة باركودات المنتج
  final int? quantity; // كمية المنتج
  final int? reservedQuantity; // الكمية المحجوزة (في السلات غير المؤكدة)
  final int? minStockLevel; // الحد الأدنى للمخزون (تنبيه عند الوصول إليه)
  final int? maxOrderQuantity; // الحد الأقصى للطلب في المرة الواحدة
  final bool? isTrackingInventory; // هل يتم تتبع المخزون لهذا المنتج
  final DateTime? lastStockUpdate; // آخر تحديث للمخزون
  final int?
  quantityPerCarton; // كمية المنتج في الكارتونة الواحدة (للبائع الجملة فقط)
  final double?
  suggestedRetailPrice; // السعر المقترح للبائع المفرد (للبائع الجملة فقط)

  // إضافة حقول الأقسام المنفصلة
  final String? mainCategoryId;
  final String? subCategoryId;

  // أسماء الفئات متعددة اللغات
  final String? mainCategoryNameAr;
  final String? mainCategoryNameEn;
  final String? subCategoryNameAr;
  final String? subCategoryNameEn;

  // معلومات المنتج الأصلي (للربط بالمنتجات الأصلية)
  final String? originalProductId;
  final String? originalCompanyId;

  const ItemModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    this.manyImages = const [],
    this.videoUrl,
    required this.typeItem,
    this.itemCondition,
    this.qualityGrade,
    this.countryOfOrigin,
    this.countryOfOriginAr,
    this.countryOfOriginEn,
    required this.uidAdd,
    required this.appName,
    this.costPrice,
    this.addedBySellerType,
    this.productBarcode,
    this.mainProductBarcode,
    this.productBarcodes,
    this.quantity,
    this.reservedQuantity,
    this.minStockLevel,
    this.maxOrderQuantity,
    this.isTrackingInventory,
    this.lastStockUpdate,
    this.quantityPerCarton,
    this.suggestedRetailPrice,
    this.mainCategoryId,
    this.subCategoryId,
    this.mainCategoryNameAr,
    this.mainCategoryNameEn,
    this.subCategoryNameAr,
    this.subCategoryNameEn,
    this.originalProductId,
    this.originalCompanyId,
  });

  factory ItemModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ItemModel(
      id: documentId,
      name: map['nameOfItem'] as String? ?? 'منتج غير مسمى',
      description: map['descriptionOfItem'] as String?,
      price: (map['priceOfItem'] as num?)?.toDouble() ?? 0.0,
      imageUrl: map['url'] as String?,
      manyImages: List<String>.from(map['manyImages'] ?? []),
      videoUrl:
          map['videoURL'] == 'noVideo' ? null : map['videoURL'] as String?,
      typeItem: map['typeItem'] as String? ?? 'غير محدد',
      itemCondition: map['itemCondition'] as String?,
      qualityGrade: (map['qualityGrade'] as num?)?.toInt(),
      countryOfOrigin: map['countryOfOrigin'] as String?,
      countryOfOriginAr: map['countryOfOriginAr'] as String?,
      countryOfOriginEn: map['countryOfOriginEn'] as String?,
      uidAdd: map['uidAdd'] as String? ?? '',
      appName: map['appName'] as String? ?? FirebaseX.appName,
      costPrice: (map['costPrice'] as num?)?.toDouble(),
      addedBySellerType: map['addedBySellerType'] as String?,
      productBarcode: map['productBarcode'] as String?,
      mainProductBarcode: map['mainProductBarcode'] as String?,
      productBarcodes: List<String>.from(map['productBarcodes'] ?? []),
      quantity: (map['quantity'] as num?)?.toInt(),
      reservedQuantity: (map['reservedQuantity'] as num?)?.toInt(),
      minStockLevel: (map['minStockLevel'] as num?)?.toInt(),
      maxOrderQuantity: (map['maxOrderQuantity'] as num?)?.toInt(),
      isTrackingInventory: map['isTrackingInventory'] as bool?,
      lastStockUpdate:
          map['lastStockUpdate'] != null
              ? (map['lastStockUpdate'] as Timestamp).toDate()
              : null,
      quantityPerCarton: (map['quantityPerCarton'] as num?)?.toInt(),
      suggestedRetailPrice: (map['suggestedRetailPrice'] as num?)?.toDouble(),
      mainCategoryId: map['mainCategoryId'] as String?,
      subCategoryId: map['subCategoryId'] as String?,
      mainCategoryNameAr: map['mainCategoryNameAr'] as String?,
      mainCategoryNameEn: map['mainCategoryNameEn'] as String?,
      subCategoryNameAr: map['subCategoryNameAr'] as String?,
      subCategoryNameEn: map['subCategoryNameEn'] as String?,
      originalProductId: map['originalProductId'] as String?,
      originalCompanyId: map['originalCompanyId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nameOfItem': name,
      'descriptionOfItem': description,
      'priceOfItem': price,
      'url': imageUrl,
      'manyImages': manyImages,
      'videoURL': videoUrl ?? 'noVideo',
      'typeItem': typeItem,
      'itemCondition': itemCondition,
      'qualityGrade': qualityGrade,
      'countryOfOrigin': countryOfOrigin,
      'countryOfOriginAr': countryOfOriginAr,
      'countryOfOriginEn': countryOfOriginEn,
      'uidAdd': uidAdd,
      'appName': appName,
      'isOfer': isOffer,
      'timestamp': FieldValue.serverTimestamp(),
      'costPrice': costPrice,
      'addedBySellerType': addedBySellerType,
      'productBarcode': productBarcode,
      'mainProductBarcode': mainProductBarcode,
      'productBarcodes': productBarcodes ?? [],
      'quantity': quantity,
      'reservedQuantity': reservedQuantity,
      'minStockLevel': minStockLevel,
      'maxOrderQuantity': maxOrderQuantity,
      'isTrackingInventory': isTrackingInventory,
      'lastStockUpdate':
          lastStockUpdate != null ? Timestamp.fromDate(lastStockUpdate!) : null,
      'quantityPerCarton': quantityPerCarton,
      'suggestedRetailPrice': suggestedRetailPrice,
      'mainCategoryId': mainCategoryId,
      'subCategoryId': subCategoryId,
      'mainCategoryNameAr': mainCategoryNameAr,
      'mainCategoryNameEn': mainCategoryNameEn,
      'subCategoryNameAr': subCategoryNameAr,
      'subCategoryNameEn': subCategoryNameEn,
      'originalProductId': originalProductId,
      'originalCompanyId': originalCompanyId,
    };
  }

  /// دوال مساعدة لإدارة المخزون

  /// الحصول على الكمية المتاحة للطلب
  int get availableQuantity {
    if ((isTrackingInventory ?? true) == false) {
      return 999999; // كمية غير محدودة إذا لم يتم تتبع المخزون
    }
    final currentStock = quantity ?? 0;
    final reserved = reservedQuantity ?? 0;
    return (currentStock - reserved).clamp(0, currentStock);
  }

  /// التحقق من وجود مخزون كافي
  bool hasStock([int requestedQuantity = 1]) {
    return availableQuantity >= requestedQuantity;
  }

  /// التحقق من انخفاض المخزون
  bool get isLowStock {
    if (minStockLevel == null) return false;
    return availableQuantity <= minStockLevel!;
  }

  /// التحقق من نفاد المخزون
  bool get isOutOfStock {
    return availableQuantity <= 0;
  }

  /// التحقق من تجاوز الحد الأقصى للطلب
  bool exceedsMaxOrder(int requestedQuantity) {
    if (maxOrderQuantity == null) return false;
    return requestedQuantity > maxOrderQuantity!;
  }

  /// الحصول على حالة المخزون كنص
  String get stockStatus {
    if (isOutOfStock) return 'نفدت الكمية';
    if (isLowStock) return 'كمية قليلة';
    return 'متوفر';
  }

  /// الحصول على لون حالة المخزون
  Color get stockStatusColor {
    if (isOutOfStock) return Colors.red;
    if (isLowStock) return Colors.orange;
    return Colors.green;
  }

  /*@override // إذا استخدمت Equatable
  List<Object?> get props => [
        id, name, description, price, imageUrl, manyImages, videoUrl,
        typeItem, itemCondition, qualityGrade, countryOfOrigin, uidAdd, appName,
        isOffer, costPrice, addedBySellerType
      ];*/
}
