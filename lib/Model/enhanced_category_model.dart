import 'package:cloud_firestore/cloud_firestore.dart';

class EnhancedCategoryModel {
  final String id;
  final String nameAr;     // الاسم بالعربي
  final String nameEn;     // الاسم بالإنجليزي
  final String nameKu;     // الاسم بالكردي
  final String? imageUrl;  // رابط الصورة
  final int order;         // ترتيب الظهور
  final bool isActive;     // هل القسم مفعل
  final String? parentId;  // معرف القسم الأب (null للأقسام الرئيسية)
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  // إضافة حقول جديدة لتحسين النظام
  final String? iconName;   // اسم الأيقونة
  final String? color;      // لون القسم
  final bool isForOriginalProducts; // هل القسم خاص بالمنتجات الأصلية
  final bool isForCommercialProducts; // هل القسم خاص بالمنتجات التجارية

  // قائمة الأقسام الفرعية (تُحمل بشكل منفصل)
  List<EnhancedCategoryModel> subCategories;

  EnhancedCategoryModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.nameKu,
    this.imageUrl,
    this.order = 0,
    this.isActive = true,
    this.parentId,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.subCategories = const [],
    this.iconName,
    this.color,
    this.isForOriginalProducts = true,
    this.isForCommercialProducts = true,
  });

  // تحويل من Firestore
  factory EnhancedCategoryModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return EnhancedCategoryModel(
      id: snapshot.id,
      nameAr: data['nameAr'] as String? ?? 'قسم غير معروف',
      nameEn: data['nameEn'] as String? ?? 'Unknown Category',
      nameKu: data['nameKu'] as String? ?? 'پۆلی نەناسراو',
      imageUrl: data['imageUrl'] as String?,
      order: (data['order'] as num?)?.toInt() ?? 999,
      isActive: data['isActive'] as bool? ?? true,
      parentId: data['parentId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] as String? ?? 'system',
      subCategories: [], // سيتم تحميلها بشكل منفصل
      iconName: data['iconName'] as String?,
      color: data['color'] as String?,
      isForOriginalProducts: data['isForOriginalProducts'] as bool? ?? true,
      isForCommercialProducts: data['isForCommercialProducts'] as bool? ?? true,
    );
  }

  // تحويل إلى Map للحفظ في Firestore
  Map<String, dynamic> toMap() {
    return {
      'nameAr': nameAr,
      'nameEn': nameEn,
      'nameKu': nameKu,
      'imageUrl': imageUrl,
      'order': order,
      'isActive': isActive,
      'parentId': parentId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'iconName': iconName,
      'color': color,
      'isForOriginalProducts': isForOriginalProducts,
      'isForCommercialProducts': isForCommercialProducts,
    };
  }

  // نسخ مع تعديل
  EnhancedCategoryModel copyWith({
    String? id,
    String? nameAr,
    String? nameEn,
    String? nameKu,
    String? imageUrl,
    int? order,
    bool? isActive,
    String? parentId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    List<EnhancedCategoryModel>? subCategories,
    String? iconName,
    String? color,
    bool? isForOriginalProducts,
    bool? isForCommercialProducts,
  }) {
    return EnhancedCategoryModel(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      nameKu: nameKu ?? this.nameKu,
      imageUrl: imageUrl ?? this.imageUrl,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      parentId: parentId ?? this.parentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      subCategories: subCategories ?? this.subCategories,
      iconName: iconName ?? this.iconName,
      color: color ?? this.color,
      isForOriginalProducts: isForOriginalProducts ?? this.isForOriginalProducts,
      isForCommercialProducts: isForCommercialProducts ?? this.isForCommercialProducts,
    );
  }

  // التحقق من كون القسم رئيسي
  bool get isMainCategory => parentId == null;

  // التحقق من كون القسم فرعي
  bool get isSubCategory => parentId != null;

  // التحقق من إمكانية استخدام القسم لنوع المنتج المحدد
  bool canBeUsedForProductType(String? productType) {
    if (productType == null) return true;

    switch (productType.toLowerCase()) {
      case 'original':
        return isForOriginalProducts;
      case 'commercial':
        return isForCommercialProducts;
      default:
        return true;
    }
  }

  // الحصول على اسم القسم حسب اللغة
  String getNameByLanguage(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'ar':
        return nameAr;
      case 'en':
        return nameEn;
      case 'ku':
        return nameKu;
      default:
        return nameAr; // افتراضي
    }
  }

  // الحصول على المسار الكامل للقسم (للأقسام الفرعية)
  String getFullPath() {
    if (isMainCategory) {
      return nameAr;
    } else {
      return nameAr; // يمكن تطويرها لإضافة مسار القسم الأب
    }
  }

  @override
  String toString() {
    return 'EnhancedCategoryModel(id: $id, nameAr: $nameAr, nameEn: $nameEn, nameKu: $nameKu, isMainCategory: $isMainCategory)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EnhancedCategoryModel &&
        other.id == id &&
        other.nameAr == nameAr &&
        other.nameEn == nameEn &&
        other.nameKu == nameKu;
  }

  @override
  int get hashCode {
    return id.hashCode ^ nameAr.hashCode ^ nameEn.hashCode ^ nameKu.hashCode;
  }
}

