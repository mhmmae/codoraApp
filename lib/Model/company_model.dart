import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyModel {
  final String id;
  final String nameAr;
  final String nameEn;
  final String? logoUrl;
  final String? description;
  final String? country; // إضافة حقل البلد
  final bool isActive;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<CompanyProductModel> products;

  const CompanyModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.logoUrl,
    this.description,
    this.country,
    this.isActive = true,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.products = const [],
  });

  factory CompanyModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CompanyModel(
      id: doc.id,
      nameAr: data['nameAr'] ?? '',
      nameEn: data['nameEn'] ?? '',
      logoUrl: data['logoUrl'],
      description: data['description'],
      country: data['country'],
      isActive: data['isActive'] ?? true,
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      products: [], // سيتم تحميل المنتجات منفصلة
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nameAr': nameAr,
      'nameEn': nameEn,
      'logoUrl': logoUrl,
      'description': description,
      'country': country,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  CompanyModel copyWith({
    String? id,
    String? nameAr,
    String? nameEn,
    String? logoUrl,
    String? description,
    String? country,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CompanyModel(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      logoUrl: logoUrl ?? this.logoUrl,
      description: description ?? this.description,
      country: country ?? this.country,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}







class CompanyProductModel {
  final String id;
  final String nameAr;
  final String nameEn;
  final String category; // الحقل القديم للتوافق مع النظام الحالي
  final String? mainCategoryId; // القسم الرئيسي الجديد
  final String? subCategoryId; // القسم الفرعي الجديد
  
  // أسماء الفئات متعددة اللغات
  final String? mainCategoryNameAr;
  final String? mainCategoryNameEn;
  final String? subCategoryNameAr;
  final String? subCategoryNameEn;
  final String? imageUrl;
  final String? description;
  final String companyId;
  final bool isActive;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final double price;

  const CompanyProductModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.category,
    this.mainCategoryId,
    this.subCategoryId,
    this.mainCategoryNameAr,
    this.mainCategoryNameEn,
    this.subCategoryNameAr,
    this.subCategoryNameEn,
    this.imageUrl,
    this.description,
    required this.companyId,
    this.isActive = true,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.price = 0.0,
  });

  factory CompanyProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CompanyProductModel(
      id: doc.id,
      nameAr: data['nameAr'] ?? '',
      nameEn: data['nameEn'] ?? '',
      category: data['category'] ?? '',
      mainCategoryId: data['mainCategoryId'],
      subCategoryId: data['subCategoryId'],
      mainCategoryNameAr: data['mainCategoryNameAr'],
      mainCategoryNameEn: data['mainCategoryNameEn'],
      subCategoryNameAr: data['subCategoryNameAr'],
      subCategoryNameEn: data['subCategoryNameEn'],
      imageUrl: data['imageUrl'],
      description: data['description'],
      companyId: data['companyId'] ?? '',
      isActive: data['isActive'] ?? true,
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nameAr': nameAr,
      'nameEn': nameEn,
      'category': category,
      'mainCategoryId': mainCategoryId,
      'subCategoryId': subCategoryId,
      'mainCategoryNameAr': mainCategoryNameAr,
      'mainCategoryNameEn': mainCategoryNameEn,
      'subCategoryNameAr': subCategoryNameAr,
      'subCategoryNameEn': subCategoryNameEn,
      'imageUrl': imageUrl,
      'description': description,
      'companyId': companyId,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'price': price,
    };
  }

  CompanyProductModel copyWith({
    String? id,
    String? nameAr,
    String? nameEn,
    String? category,
    String? mainCategoryId,
    String? subCategoryId,
    String? mainCategoryNameAr,
    String? mainCategoryNameEn,
    String? subCategoryNameAr,
    String? subCategoryNameEn,
    String? imageUrl,
    String? description,
    String? companyId,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? price,
  }) {
    return CompanyProductModel(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      category: category ?? this.category,
      mainCategoryId: mainCategoryId ?? this.mainCategoryId,
      subCategoryId: subCategoryId ?? this.subCategoryId,
      mainCategoryNameAr: mainCategoryNameAr ?? this.mainCategoryNameAr,
      mainCategoryNameEn: mainCategoryNameEn ?? this.mainCategoryNameEn,
      subCategoryNameAr: subCategoryNameAr ?? this.subCategoryNameAr,
      subCategoryNameEn: subCategoryNameEn ?? this.subCategoryNameEn,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      companyId: companyId ?? this.companyId,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      price: price ?? this.price,
    );
  }
} 