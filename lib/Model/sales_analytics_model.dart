import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج لتحليل المبيعات
class SalesAnalyticsModel {
  final String orderId;
  final String buyerId;
  final String buyerName;
  final String? buyerPhoneNumber;
  final String? buyerImageUrl;
  final double totalAmount;
  final double sellerProfit;
  final DateTime orderDate;
  final DateTime? deliveryDate;
  final String orderStatus;
  final String? deliveryTaskId;
  final String? driverName;
  final String? driverPhoneNumber;
  final String deliveryStatus;
  final String paymentMethod;
  final List<OrderItemAnalytics> items;
  final String? deliveryAddress;
  final double? deliveryFee;

  SalesAnalyticsModel({
    required this.orderId,
    required this.buyerId,
    required this.buyerName,
    this.buyerPhoneNumber,
    this.buyerImageUrl,
    required this.totalAmount,
    required this.sellerProfit,
    required this.orderDate,
    this.deliveryDate,
    required this.orderStatus,
    this.deliveryTaskId,
    this.driverName,
    this.driverPhoneNumber,
    required this.deliveryStatus,
    required this.paymentMethod,
    required this.items,
    this.deliveryAddress,
    this.deliveryFee,
  });

  /// حساب الربح الصافي (بعد خصم رسوم التوصيل)
  double get netProfit => sellerProfit - (deliveryFee ?? 0);

  /// حساب هامش الربح كنسبة مئوية
  double get profitMargin =>
      totalAmount > 0 ? (sellerProfit / totalAmount) * 100 : 0;

  /// التحقق من حالة التوصيل
  bool get isDelivered => deliveryStatus == 'delivered';
  bool get isPending =>
      deliveryStatus == 'pending' || deliveryStatus == 'company_pickup_request';
  bool get isInProgress =>
      deliveryStatus.contains('route') || deliveryStatus.contains('pickup');

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'buyerPhoneNumber': buyerPhoneNumber,
      'buyerImageUrl': buyerImageUrl,
      'totalAmount': totalAmount,
      'sellerProfit': sellerProfit,
      'orderDate': Timestamp.fromDate(orderDate),
      'deliveryDate':
          deliveryDate != null ? Timestamp.fromDate(deliveryDate!) : null,
      'orderStatus': orderStatus,
      'deliveryTaskId': deliveryTaskId,
      'driverName': driverName,
      'driverPhoneNumber': driverPhoneNumber,
      'deliveryStatus': deliveryStatus,
      'paymentMethod': paymentMethod,
      'items': items.map((item) => item.toMap()).toList(),
      'deliveryAddress': deliveryAddress,
      'deliveryFee': deliveryFee,
    };
  }

  factory SalesAnalyticsModel.fromMap(Map<String, dynamic> map) {
    return SalesAnalyticsModel(
      orderId: map['orderId'] ?? '',
      buyerId: map['buyerId'] ?? '',
      buyerName: map['buyerName'] ?? '',
      buyerPhoneNumber: map['buyerPhoneNumber'],
      buyerImageUrl: map['buyerImageUrl'],
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      sellerProfit: (map['sellerProfit'] as num?)?.toDouble() ?? 0.0,
      orderDate: (map['orderDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deliveryDate: (map['deliveryDate'] as Timestamp?)?.toDate(),
      orderStatus: map['orderStatus'] ?? 'pending',
      deliveryTaskId: map['deliveryTaskId'],
      driverName: map['driverName'],
      driverPhoneNumber: map['driverPhoneNumber'],
      deliveryStatus: map['deliveryStatus'] ?? 'pending',
      paymentMethod: map['paymentMethod'] ?? 'cash_on_delivery',
      items:
          (map['items'] as List<dynamic>?)
              ?.map(
                (item) =>
                    OrderItemAnalytics.fromMap(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
      deliveryAddress: map['deliveryAddress'],
      deliveryFee: (map['deliveryFee'] as num?)?.toDouble(),
    );
  }

  @override
  String toString() {
    return 'SalesAnalyticsModel(orderId: $orderId, buyerName: $buyerName, totalAmount: $totalAmount, profit: $sellerProfit)';
  }
}

/// نموذج لتحليل عنصر في الطلب
class OrderItemAnalytics {
  final String itemId;
  final String itemName;
  final String? itemImageUrl;
  final int quantity;
  final double unitPrice;
  final double unitCost;
  final bool isOffer;

  OrderItemAnalytics({
    required this.itemId,
    required this.itemName,
    this.itemImageUrl,
    required this.quantity,
    required this.unitPrice,
    required this.unitCost,
    this.isOffer = false,
  });

  /// حساب إجمالي سعر العنصر
  double get totalPrice => unitPrice * quantity;

  /// حساب إجمالي التكلفة
  double get totalCost => unitCost * quantity;

  /// حساب الربح للعنصر
  double get itemProfit => totalPrice - totalCost;

  /// حساب هامش الربح للعنصر
  double get itemProfitMargin =>
      totalPrice > 0 ? (itemProfit / totalPrice) * 100 : 0;

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'itemImageUrl': itemImageUrl,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'unitCost': unitCost,
      'isOffer': isOffer,
    };
  }

  factory OrderItemAnalytics.fromMap(Map<String, dynamic> map) {
    return OrderItemAnalytics(
      itemId: map['itemId'] ?? '',
      itemName: map['itemName'] ?? '',
      itemImageUrl: map['itemImageUrl'],
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      unitCost: (map['unitCost'] as num?)?.toDouble() ?? 0.0,
      isOffer: map['isOffer'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'OrderItemAnalytics(itemName: $itemName, quantity: $quantity, profit: $itemProfit)';
  }
}

/// نموذج للملخص اليومي للمبيعات
class DailySalesSummary {
  final DateTime date;
  final int totalOrders;
  final int completedOrders;
  final int pendingOrders;
  final double totalRevenue;
  final double totalProfit;
  final double averageOrderValue;
  final List<String> topBuyerIds;

  DailySalesSummary({
    required this.date,
    required this.totalOrders,
    required this.completedOrders,
    required this.pendingOrders,
    required this.totalRevenue,
    required this.totalProfit,
    required this.averageOrderValue,
    required this.topBuyerIds,
  });

  /// حساب معدل إكمال الطلبات
  double get completionRate =>
      totalOrders > 0 ? (completedOrders / totalOrders) * 100 : 0;

  /// حساب هامش الربح اليومي
  double get profitMargin =>
      totalRevenue > 0 ? (totalProfit / totalRevenue) * 100 : 0;

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'totalOrders': totalOrders,
      'completedOrders': completedOrders,
      'pendingOrders': pendingOrders,
      'totalRevenue': totalRevenue,
      'totalProfit': totalProfit,
      'averageOrderValue': averageOrderValue,
      'topBuyerIds': topBuyerIds,
    };
  }

  factory DailySalesSummary.fromMap(Map<String, dynamic> map) {
    return DailySalesSummary(
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalOrders: (map['totalOrders'] as num?)?.toInt() ?? 0,
      completedOrders: (map['completedOrders'] as num?)?.toInt() ?? 0,
      pendingOrders: (map['pendingOrders'] as num?)?.toInt() ?? 0,
      totalRevenue: (map['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      totalProfit: (map['totalProfit'] as num?)?.toDouble() ?? 0.0,
      averageOrderValue: (map['averageOrderValue'] as num?)?.toDouble() ?? 0.0,
      topBuyerIds: List<String>.from(map['topBuyerIds'] ?? []),
    );
  }

  @override
  String toString() {
    return 'DailySalesSummary(date: $date, orders: $totalOrders, revenue: $totalRevenue, profit: $totalProfit)';
  }
}
