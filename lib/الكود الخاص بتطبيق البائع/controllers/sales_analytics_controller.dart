import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../XXX/xxx_firebase.dart';
import '../../../Model/sales_analytics_model.dart';

/// متحكم تحليل المبيعات للبائع
class SalesAnalyticsController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // حالة التحميل
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // بيانات المبيعات
  final RxList<SalesAnalyticsModel> dailySales = <SalesAnalyticsModel>[].obs;
  final RxList<SalesAnalyticsModel> weeklySales = <SalesAnalyticsModel>[].obs;
  final RxList<SalesAnalyticsModel> monthlySales = <SalesAnalyticsModel>[].obs;
  final RxList<SalesAnalyticsModel> yearlySales = <SalesAnalyticsModel>[].obs;

  // ملخص المبيعات
  final Rx<DailySalesSummary?> todaySummary = Rx<DailySalesSummary?>(null);
  final RxDouble totalDailyRevenue = 0.0.obs;
  final RxDouble totalDailyProfit = 0.0.obs;
  final RxInt totalDailyOrders = 0.obs;
  final RxInt completedDailyOrders = 0.obs;

  // فلترة البيانات
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxString selectedPeriod = 'today'.obs; // today, week, month, year

  // معرف البائع الحالي
  String? get currentSellerId => _auth.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    _loadTodaySales();
  }

  /// تحميل مبيعات اليوم
  Future<void> _loadTodaySales() async {
    if (currentSellerId == null) return;

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final DateTime today = DateTime.now();
      final DateTime startOfDay = DateTime(today.year, today.month, today.day);
      final DateTime endOfDay = DateTime(
        today.year,
        today.month,
        today.day,
        23,
        59,
        59,
      );

      await _loadSalesForPeriod(startOfDay, endOfDay, 'today');
      await _calculateDailySummary();
    } catch (e) {
      errorMessage.value = 'فشل في تحميل بيانات المبيعات: $e';
      debugPrint('خطأ في تحميل مبيعات اليوم: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// تحميل المبيعات لفترة معينة
  Future<void> _loadSalesForPeriod(
    DateTime startDate,
    DateTime endDate,
    String period,
  ) async {
    if (currentSellerId == null) return;

    try {
      // جلب الطلبات من Firestore
      final QuerySnapshot ordersSnapshot =
          await _firestore
              .collection('orders')
              .where('appName', isEqualTo: FirebaseX.appName)
              .where('uidAdd', isEqualTo: currentSellerId)
              .where(
                'timeOrder',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
              )
              .where(
                'timeOrder',
                isLessThanOrEqualTo: Timestamp.fromDate(endDate),
              )
              .orderBy('timeOrder', descending: true)
              .get();

      List<SalesAnalyticsModel> salesList = [];

      for (QueryDocumentSnapshot orderDoc in ordersSnapshot.docs) {
        final orderData = orderDoc.data() as Map<String, dynamic>;

        try {
          // جلب بيانات المشتري
          final buyerId = orderData['uidUser'] as String;
          final buyerDoc =
              await _firestore
                  .collection(FirebaseX.collectionApp)
                  .doc(buyerId)
                  .get();

          final buyerData =
              buyerDoc.exists
                  ? (buyerDoc.data() as Map<String, dynamic>)
                  : <String, dynamic>{};

          // جلب عناصر الطلب
          final itemsSnapshot =
              await _firestore
                  .collection('orders')
                  .doc(orderDoc.id)
                  .collection('OrderItems')
                  .get();

          List<OrderItemAnalytics> orderItems = [];
          double totalProfit = 0.0;

          for (QueryDocumentSnapshot itemDoc in itemsSnapshot.docs) {
            final itemData = itemDoc.data() as Map<String, dynamic>;

            // جلب تفاصيل المنتج لحساب التكلفة والربح
            final productData = await _getProductDetails(
              itemData['uidItem'] as String,
              itemData['isOfer'] as bool? ?? false,
            );

            if (productData != null) {
              final quantity = (itemData['number'] as num?)?.toInt() ?? 1;
              final unitPrice =
                  (productData['priceOfItem'] as num?)?.toDouble() ?? 0.0;
              final unitCost =
                  (productData['cost'] as num?)?.toDouble() ??
                  unitPrice * 0.7; // افتراض التكلفة 70%

              final orderItem = OrderItemAnalytics(
                itemId: itemData['uidItem'] as String,
                itemName: productData['nameOfItem'] ?? 'منتج غير معروف',
                itemImageUrl: productData['url'],
                quantity: quantity,
                unitPrice: unitPrice,
                unitCost: unitCost,
                isOffer: itemData['isOfer'] as bool? ?? false,
              );

              orderItems.add(orderItem);
              totalProfit += orderItem.itemProfit;
            }
          }

          // جلب معلومات التوصيل
          final deliveryInfo = await _getDeliveryInfo(orderDoc.id);

          final salesRecord = SalesAnalyticsModel(
            orderId: orderDoc.id,
            buyerId: buyerId,
            buyerName: buyerData['name'] ?? 'عميل غير معروف',
            buyerPhoneNumber: buyerData['phneNumber'],
            buyerImageUrl: buyerData['url'],
            totalAmount:
                (orderData['totalPriceOfOrder'] as num?)?.toDouble() ?? 0.0,
            sellerProfit: totalProfit,
            orderDate: (orderData['timeOrder'] as Timestamp).toDate(),
            deliveryDate: deliveryInfo['deliveryDate'],
            orderStatus: _getOrderStatus(orderData),
            deliveryTaskId: deliveryInfo['deliveryTaskId'],
            driverName: deliveryInfo['driverName'],
            driverPhoneNumber: deliveryInfo['driverPhoneNumber'],
            deliveryStatus: deliveryInfo['deliveryStatus'] ?? 'pending',
            paymentMethod: orderData['paymentMethod'] ?? 'cash_on_delivery',
            items: orderItems,
            deliveryAddress:
                orderData['shopAddressText'] ?? orderData['address'],
            deliveryFee: deliveryInfo['deliveryFee'],
          );

          salesList.add(salesRecord);
        } catch (e) {
          debugPrint('خطأ في معالجة الطلب ${orderDoc.id}: $e');
          continue;
        }
      }

      // تحديث القوائم حسب الفترة
      switch (period) {
        case 'today':
          dailySales.value = salesList;
          break;
        case 'week':
          weeklySales.value = salesList;
          break;
        case 'month':
          monthlySales.value = salesList;
          break;
        case 'year':
          yearlySales.value = salesList;
          break;
      }
    } catch (e) {
      errorMessage.value = 'فشل في تحميل البيانات: $e';
      debugPrint('خطأ في تحميل المبيعات: $e');
    }
  }

  /// جلب تفاصيل المنتج
  Future<Map<String, dynamic>?> _getProductDetails(
    String itemId,
    bool isOffer,
  ) async {
    try {
      final collection = isOffer ? 'Itemoffer' : 'Item';
      final productDoc =
          await _firestore.collection(collection).doc(itemId).get();

      if (productDoc.exists) {
        return productDoc.data() as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('خطأ في جلب تفاصيل المنتج $itemId: $e');
    }
    return null;
  }

  /// جلب معلومات التوصيل
  Future<Map<String, dynamic>> _getDeliveryInfo(String orderId) async {
    try {
      final deliverySnapshot =
          await _firestore
              .collection(FirebaseX.deliveryTasksCollection)
              .where('orderId', isEqualTo: orderId)
              .limit(1)
              .get();

      if (deliverySnapshot.docs.isNotEmpty) {
        final deliveryData = deliverySnapshot.docs.first.data();
        return {
          'deliveryTaskId': deliverySnapshot.docs.first.id,
          'deliveryStatus': deliveryData['status'] ?? 'pending',
          'driverName': deliveryData['driverName'],
          'driverPhoneNumber': deliveryData['driverPhoneNumber'],
          'deliveryFee': (deliveryData['deliveryFee'] as num?)?.toDouble(),
          'deliveryDate':
              deliveryData['deliveryConfirmationTime'] != null
                  ? (deliveryData['deliveryConfirmationTime'] as Timestamp)
                      .toDate()
                  : null,
        };
      }
    } catch (e) {
      debugPrint('خطأ في جلب معلومات التوصيل للطلب $orderId: $e');
    }

    return {'deliveryStatus': 'pending', 'deliveryFee': 0.0};
  }

  /// تحديد حالة الطلب
  String _getOrderStatus(Map<String, dynamic> orderData) {
    if (orderData['RequestAccept'] == true) {
      if (orderData['Ready'] == true) {
        return 'ready';
      }
      return 'accepted';
    }
    return 'pending';
  }

  /// حساب ملخص المبيعات اليومية
  Future<void> _calculateDailySummary() async {
    final sales = dailySales;

    if (sales.isEmpty) {
      totalDailyRevenue.value = 0.0;
      totalDailyProfit.value = 0.0;
      totalDailyOrders.value = 0;
      completedDailyOrders.value = 0;
      return;
    }

    double revenue = 0.0;
    double profit = 0.0;
    int completed = 0;

    for (final sale in sales) {
      revenue += sale.totalAmount;
      profit += sale.sellerProfit;
      if (sale.isDelivered) completed++;
    }

    totalDailyRevenue.value = revenue;
    totalDailyProfit.value = profit;
    totalDailyOrders.value = sales.length;
    completedDailyOrders.value = completed;

    // إنشاء ملخص يومي
    todaySummary.value = DailySalesSummary(
      date: DateTime.now(),
      totalOrders: sales.length,
      completedOrders: completed,
      pendingOrders: sales.length - completed,
      totalRevenue: revenue,
      totalProfit: profit,
      averageOrderValue: sales.isNotEmpty ? revenue / sales.length : 0.0,
      topBuyerIds: _getTopBuyerIds(sales),
    );
  }

  /// الحصول على أفضل المشترين
  List<String> _getTopBuyerIds(List<SalesAnalyticsModel> sales) {
    Map<String, double> buyerTotals = {};

    for (final sale in sales) {
      buyerTotals[sale.buyerId] =
          (buyerTotals[sale.buyerId] ?? 0) + sale.totalAmount;
    }

    final sortedBuyers =
        buyerTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return sortedBuyers.take(5).map((e) => e.key).toList();
  }

  /// تحميل مبيعات فترة محددة
  Future<void> loadSalesForPeriod(String period) async {
    selectedPeriod.value = period;
    isLoading.value = true;

    try {
      DateTime startDate, endDate;
      final now = DateTime.now();

      switch (period) {
        case 'today':
          startDate = DateTime(now.year, now.month, now.day);
          endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'week':
          startDate = now.subtract(Duration(days: now.weekday - 1));
          startDate = DateTime(startDate.year, startDate.month, startDate.day);
          endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'month':
          startDate = DateTime(now.year, now.month, 1);
          endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
          break;
        case 'year':
          startDate = DateTime(now.year, 1, 1);
          endDate = DateTime(now.year, 12, 31, 23, 59, 59);
          break;
        default:
          return;
      }

      await _loadSalesForPeriod(startDate, endDate, period);

      if (period == 'today') {
        await _calculateDailySummary();
      }
    } catch (e) {
      errorMessage.value = 'فشل في تحميل بيانات الفترة: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// تحديث البيانات
  Future<void> refreshSalesData() async {
    await loadSalesForPeriod(selectedPeriod.value);
  }

  /// الحصول على المبيعات الحالية حسب الفترة المحددة
  List<SalesAnalyticsModel> get currentSales {
    switch (selectedPeriod.value) {
      case 'today':
        return dailySales;
      case 'week':
        return weeklySales;
      case 'month':
        return monthlySales;
      case 'year':
        return yearlySales;
      default:
        return dailySales;
    }
  }

  /// تصفية المبيعات حسب حالة التوصيل
  List<SalesAnalyticsModel> getSalesByDeliveryStatus(String status) {
    return currentSales.where((sale) => sale.deliveryStatus == status).toList();
  }

  /// تصفية المبيعات حسب المشتري
  List<SalesAnalyticsModel> getSalesByBuyer(String buyerId) {
    return currentSales.where((sale) => sale.buyerId == buyerId).toList();
  }

  /// حساب إجمالي المبيعات للفترة الحالية
  double get currentPeriodRevenue {
    return currentSales.fold(0.0, (sum, sale) => sum + sale.totalAmount);
  }

  /// حساب إجمالي الأرباح للفترة الحالية
  double get currentPeriodProfit {
    return currentSales.fold(0.0, (sum, sale) => sum + sale.sellerProfit);
  }

  /// حساب متوسط قيمة الطلب
  double get averageOrderValue {
    final sales = currentSales;
    return sales.isNotEmpty ? currentPeriodRevenue / sales.length : 0.0;
  }
}
