import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج المنتج الأصلي مع معلومات الأقسام المنفصلة
class OriginalProductModel {
  final String id;
  final String productName;
  final String companyId;
  final String companyName;
  final String? companyBrand;
  final String? imageUrl;
  final List<String> additionalImages;
  final String? description;
  final String? barcode;
  final Map<String, dynamic> specifications;
  
  // معلومات الأقسام المنفصلة
  final String? mainCategoryId;
  final String? subCategoryId;
  final String? mainCategoryNameEn;
  final String? subCategoryNameEn;
  final String? mainCategoryNameAr;
  final String? subCategoryNameAr;
  
  // معلومات إضافية
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  const OriginalProductModel({
    required this.id,
    required this.productName,
    required this.companyId,
    required this.companyName,
    this.companyBrand,
    this.imageUrl,
    this.additionalImages = const [],
    this.description,
    this.barcode,
    this.specifications = const {},
    this.mainCategoryId,
    this.subCategoryId,
    this.mainCategoryNameEn,
    this.subCategoryNameEn,
    this.mainCategoryNameAr,
    this.subCategoryNameAr,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  /// إنشاء من Firestore document
  factory OriginalProductModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    
    return OriginalProductModel(
      id: snapshot.id,
      productName: data['productName'] as String? ?? 'منتج غير معروف',
      companyId: data['companyId'] as String? ?? '',
      companyName: data['companyName'] as String? ?? 'شركة غير معروفة',
      companyBrand: data['companyBrand'] as String?,
      imageUrl: data['imageUrl'] as String?,
      additionalImages: List<String>.from(data['additionalImages'] ?? []),
      description: data['description'] as String?,
      barcode: data['barcode'] as String?,
      specifications: Map<String, dynamic>.from(data['specifications'] ?? {}),
      mainCategoryId: data['mainCategoryId'] as String?,
      subCategoryId: data['subCategoryId'] as String?,
      mainCategoryNameEn: data['mainCategoryNameEn'] as String?,
      subCategoryNameEn: data['subCategoryNameEn'] as String?,
      mainCategoryNameAr: data['mainCategoryNameAr'] as String?,
      subCategoryNameAr: data['subCategoryNameAr'] as String?,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] as String? ?? 'system',
    );
  }

  /// إنشاء من Map
  factory OriginalProductModel.fromMap(Map<String, dynamic> map, String documentId) {
    return OriginalProductModel(
      id: documentId,
      productName: map['productName'] as String? ?? 'منتج غير معروف',
      companyId: map['companyId'] as String? ?? '',
      companyName: map['companyName'] as String? ?? 'شركة غير معروفة',
      companyBrand: map['companyBrand'] as String?,
      imageUrl: map['imageUrl'] as String?,
      additionalImages: List<String>.from(map['additionalImages'] ?? []),
      description: map['description'] as String?,
      barcode: map['barcode'] as String?,
      specifications: Map<String, dynamic>.from(map['specifications'] ?? {}),
      mainCategoryId: map['mainCategoryId'] as String?,
      subCategoryId: map['subCategoryId'] as String?,
      mainCategoryNameEn: map['mainCategoryNameEn'] as String?,
      subCategoryNameEn: map['subCategoryNameEn'] as String?,
      mainCategoryNameAr: map['mainCategoryNameAr'] as String?,
      subCategoryNameAr: map['subCategoryNameAr'] as String?,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: map['createdBy'] as String? ?? 'system',
    );
  }

  /// تحويل إلى Map للحفظ في Firestore
  Map<String, dynamic> toMap() {
    return {
      'productName': productName,
      'companyId': companyId,
      'companyName': companyName,
      'companyBrand': companyBrand,
      'imageUrl': imageUrl,
      'additionalImages': additionalImages,
      'description': description,
      'barcode': barcode,
      'specifications': specifications,
      'mainCategoryId': mainCategoryId,
      'subCategoryId': subCategoryId,
      'mainCategoryNameEn': mainCategoryNameEn,
      'subCategoryNameEn': subCategoryNameEn,
      'mainCategoryNameAr': mainCategoryNameAr,
      'subCategoryNameAr': subCategoryNameAr,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
    };
  }

  /// نسخ مع تعديل
  OriginalProductModel copyWith({
    String? id,
    String? productName,
    String? companyId,
    String? companyName,
    String? companyBrand,
    String? imageUrl,
    List<String>? additionalImages,
    String? description,
    String? barcode,
    Map<String, dynamic>? specifications,
    String? mainCategoryId,
    String? subCategoryId,
    String? mainCategoryNameEn,
    String? subCategoryNameEn,
    String? mainCategoryNameAr,
    String? subCategoryNameAr,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return OriginalProductModel(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      companyBrand: companyBrand ?? this.companyBrand,
      imageUrl: imageUrl ?? this.imageUrl,
      additionalImages: additionalImages ?? this.additionalImages,
      description: description ?? this.description,
      barcode: barcode ?? this.barcode,
      specifications: specifications ?? this.specifications,
      mainCategoryId: mainCategoryId ?? this.mainCategoryId,
      subCategoryId: subCategoryId ?? this.subCategoryId,
      mainCategoryNameEn: mainCategoryNameEn ?? this.mainCategoryNameEn,
      subCategoryNameEn: subCategoryNameEn ?? this.subCategoryNameEn,
      mainCategoryNameAr: mainCategoryNameAr ?? this.mainCategoryNameAr,
      subCategoryNameAr: subCategoryNameAr ?? this.subCategoryNameAr,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  /// الحصول على المسار الكامل للقسم
  String get categoryPath {
    if (mainCategoryNameAr != null && subCategoryNameAr != null) {
      return '$mainCategoryNameAr > $subCategoryNameAr';
    } else if (subCategoryNameAr != null) {
      return subCategoryNameAr!;
    } else if (mainCategoryNameAr != null) {
      return mainCategoryNameAr!;
    }
    return 'غير محدد';
  }

  /// التحقق من وجود معلومات الأقسام
  bool get hasCategoryInfo {
    return mainCategoryId != null && subCategoryId != null;
  }

  /// التحقق من وجود مواصفات
  bool get hasSpecifications {
    return specifications.isNotEmpty;
  }

  /// الحصول على أول صورة متاحة
  String? get primaryImageUrl {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return imageUrl;
    }
    if (additionalImages.isNotEmpty) {
      return additionalImages.first;
    }
    return null;
  }

  @override
  String toString() {
    return 'OriginalProductModel(id: $id, productName: $productName, companyName: $companyName, categoryPath: $categoryPath)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OriginalProductModel &&
        other.id == id &&
        other.productName == productName &&
        other.companyId == companyId;
  }

  @override
  int get hashCode {
    return id.hashCode ^ productName.hashCode ^ companyId.hashCode;
  }
} 