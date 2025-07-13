import 'package:cloud_firestore/cloud_firestore.dart';

class SequentialBarcodeModel {
  final String id;
  final String productId;
  final String productName;
  final String sequentialBarcode;
  final String mainProductBarcode;
  final String sellerId;
  final DateTime createdAt;
  final bool isPrinted;
  final bool isUsed;
  final DateTime? usedAt;
  final String? usedBy;
  final String? saleId;

  const SequentialBarcodeModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.sequentialBarcode,
    required this.mainProductBarcode,
    required this.sellerId,
    required this.createdAt,
    required this.isPrinted,
    required this.isUsed,
    this.usedAt,
    this.usedBy,
    this.saleId,
  });

  factory SequentialBarcodeModel.fromMap(Map<String, dynamic> map, String documentId) {
    return SequentialBarcodeModel(
      id: documentId,
      productId: map['productId'] as String? ?? '',
      productName: map['productName'] as String? ?? '',
      sequentialBarcode: map['sequentialBarcode'] as String? ?? '',
      mainProductBarcode: map['mainProductBarcode'] as String? ?? '',
      sellerId: map['sellerId'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPrinted: map['isPrinted'] as bool? ?? false,
      isUsed: map['isUsed'] as bool? ?? false,
      usedAt: (map['usedAt'] as Timestamp?)?.toDate(),
      usedBy: map['usedBy'] as String?,
      saleId: map['saleId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'sequentialBarcode': sequentialBarcode,
      'mainProductBarcode': mainProductBarcode,
      'sellerId': sellerId,
      'createdAt': Timestamp.fromDate(createdAt),
      'isPrinted': isPrinted,
      'isUsed': isUsed,
      'usedAt': usedAt != null ? Timestamp.fromDate(usedAt!) : null,
      'usedBy': usedBy,
      'saleId': saleId,
    };
  }

  SequentialBarcodeModel copyWith({
    String? id,
    String? productId,
    String? productName,
    String? sequentialBarcode,
    String? mainProductBarcode,
    String? sellerId,
    DateTime? createdAt,
    bool? isPrinted,
    bool? isUsed,
    DateTime? usedAt,
    String? usedBy,
    String? saleId,
  }) {
    return SequentialBarcodeModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      sequentialBarcode: sequentialBarcode ?? this.sequentialBarcode,
      mainProductBarcode: mainProductBarcode ?? this.mainProductBarcode,
      sellerId: sellerId ?? this.sellerId,
      createdAt: createdAt ?? this.createdAt,
      isPrinted: isPrinted ?? this.isPrinted,
      isUsed: isUsed ?? this.isUsed,
      usedAt: usedAt ?? this.usedAt,
      usedBy: usedBy ?? this.usedBy,
      saleId: saleId ?? this.saleId,
    );
  }

  @override
  String toString() {
    return 'SequentialBarcodeModel(id: $id, productId: $productId, sequentialBarcode: $sequentialBarcode, isPrinted: $isPrinted, isUsed: $isUsed)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is SequentialBarcodeModel &&
        other.id == id &&
        other.sequentialBarcode == sequentialBarcode;
  }

  @override
  int get hashCode {
    return id.hashCode ^ sequentialBarcode.hashCode;
  }
} 