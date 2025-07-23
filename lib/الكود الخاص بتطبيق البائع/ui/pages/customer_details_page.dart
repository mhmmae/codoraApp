import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/sales_analytics_controller.dart';
import '../../../Model/sales_analytics_model.dart';

/// صفحة تفاصيل العميل مع سجل المشتريات
class CustomerDetailsPage extends StatelessWidget {
  final String customerId;
  final String customerName;

  const CustomerDetailsPage({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  Widget build(BuildContext context) {
    final SalesAnalyticsController salesController =
        Get.find<SalesAnalyticsController>();
    final customerSales = salesController.getSalesByBuyer(customerId);

    // حساب إحصائيات العميل
    final totalOrders = customerSales.length;
    final totalSpent = customerSales.fold(
      0.0,
      (sum, sale) => sum + sale.totalAmount,
    );
    final totalProfit = customerSales.fold(
      0.0,
      (sum, sale) => sum + sale.sellerProfit,
    );
    final averageOrder = totalOrders > 0 ? totalSpent / totalOrders : 0.0;
    final completedOrders =
        customerSales.where((sale) => sale.isDelivered).length;
    final completionRate =
        totalOrders > 0 ? (completedOrders / totalOrders) * 100 : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'تفاصيل العميل',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18.sp,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // معلومات العميل الأساسية
            _buildCustomerHeader(
              customerName,
              customerSales.isNotEmpty ? customerSales.first : null,
            ),

            // إحصائيات العميل
            _buildCustomerStats(
              totalOrders,
              totalSpent,
              totalProfit,
              averageOrder,
              completionRate,
            ),

            // سجل المشتريات
            _buildPurchaseHistory(customerSales),
          ],
        ),
      ),
    );
  }

  /// بناء رأس معلومات العميل
  Widget _buildCustomerHeader(
    String customerName,
    SalesAnalyticsModel? latestSale,
  ) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          children: [
            // صورة العميل
            CircleAvatar(
              radius: 50.r,
              backgroundImage:
                  latestSale?.buyerImageUrl != null
                      ? NetworkImage(latestSale!.buyerImageUrl!)
                      : null,
              backgroundColor: Colors.white.withOpacity(0.2),
              child:
                  latestSale?.buyerImageUrl == null
                      ? Icon(Icons.person, size: 50.sp, color: Colors.white)
                      : null,
            ),
            SizedBox(height: 16.h),

            // اسم العميل
            Text(
              customerName,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),

            // رقم الهاتف إذا متوفر
            if (latestSale?.buyerPhoneNumber != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.phone,
                    color: Colors.white.withOpacity(0.9),
                    size: 16.sp,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    latestSale!.buyerPhoneNumber!,
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),

            SizedBox(height: 8.h),

            // تاريخ آخر طلب
            if (latestSale != null)
              Text(
                'آخر طلب: ${DateFormat('dd/MM/yyyy').format(latestSale.orderDate)}',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// بناء إحصائيات العميل
  Widget _buildCustomerStats(
    int totalOrders,
    double totalSpent,
    double totalProfit,
    double averageOrder,
    double completionRate,
  ) {
    return Container(
      margin: EdgeInsets.all(16.w),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'إحصائيات العميل',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E7D32),
                ),
              ),
              SizedBox(height: 16.h),

              // الصف الأول من الإحصائيات
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'إجمالي الطلبات',
                      totalOrders.toString(),
                      Icons.shopping_cart,
                      const Color(0xFF1976D2),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildStatCard(
                      'إجمالي المبلغ',
                      '${NumberFormat('#,###').format(totalSpent)} د.ع',
                      Icons.attach_money,
                      const Color(0xFF388E3C),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // الصف الثاني من الإحصائيات
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'متوسط الطلب',
                      '${NumberFormat('#,###').format(averageOrder)} د.ع',
                      Icons.calculate,
                      const Color(0xFF7B1FA2),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildStatCard(
                      'نسبة الإكمال',
                      '${completionRate.toStringAsFixed(1)}%',
                      Icons.check_circle,
                      const Color(0xFFFF9800),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // بطاقة الأرباح
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  children: [
                    Icon(Icons.trending_up, color: Colors.white, size: 24.sp),
                    SizedBox(height: 8.h),
                    Text(
                      'إجمالي الأرباح من العميل',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${NumberFormat('#,###').format(totalProfit)} د.ع',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// بناء بطاقة إحصائية
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24.sp),
          SizedBox(height: 8.h),
          Text(
            title,
            style: TextStyle(fontSize: 12.sp, color: color),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// بناء سجل المشتريات
  Widget _buildPurchaseHistory(List<SalesAnalyticsModel> sales) {
    return Container(
      margin: EdgeInsets.all(16.w),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.history,
                    color: const Color(0xFF2E7D32),
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'سجل المشتريات (${sales.length})',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              if (sales.isEmpty)
                _buildEmptyPurchaseHistory()
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sales.length,
                  separatorBuilder: (context, index) => SizedBox(height: 12.h),
                  itemBuilder: (context, index) {
                    final sale = sales[index];
                    return _buildPurchaseCard(sale);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// بناء حالة فارغة لسجل المشتريات
  Widget _buildEmptyPurchaseHistory() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(40.w),
      child: Column(
        children: [
          Icon(
            Icons.shopping_basket_outlined,
            size: 64.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'لا توجد مشتريات',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'لم يقم العميل بأي عملية شراء بعد',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// بناء بطاقة مشترى واحدة
  Widget _buildPurchaseCard(SalesAnalyticsModel sale) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس البطاقة
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  'طلب #${sale.orderId.substring(0, 8)}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('dd/MM/yyyy').format(sale.orderDate),
                style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // تفاصيل الطلب
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المبلغ الإجمالي',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${NumberFormat('#,###').format(sale.totalAmount)} د.ع',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1976D2),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الربح',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${NumberFormat('#,###').format(sale.sellerProfit)} د.ع',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF388E3C),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // معلومات إضافية
          Row(
            children: [
              _buildInfoChip(
                '${sale.items.length} منتج',
                Icons.inventory_2,
                const Color(0xFF7B1FA2),
              ),
              SizedBox(width: 8.w),
              _buildDeliveryStatusChip(sale.deliveryStatus),
              if (sale.driverName != null) ...[
                SizedBox(width: 8.w),
                _buildInfoChip(
                  sale.driverName!,
                  Icons.delivery_dining,
                  const Color(0xFFFF9800),
                ),
              ],
            ],
          ),

          // عرض المنتجات
          if (sale.items.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Text(
              'المنتجات:',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8.h),
            ...sale.items
                .take(3)
                .map(
                  (item) => Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Text(
                      '• ${item.itemName} (${item.quantity})',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
            if (sale.items.length > 3)
              Text(
                '... و ${sale.items.length - 3} منتجات أخرى',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ],
      ),
    );
  }

  /// بناء شريحة معلومات
  Widget _buildInfoChip(String text, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12.sp),
          SizedBox(width: 4.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 10.sp,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// بناء شريحة حالة التوصيل
  Widget _buildDeliveryStatusChip(String status) {
    Color color;
    String statusText;
    IconData icon;

    switch (status) {
      case 'delivered':
        color = const Color(0xFF388E3C);
        statusText = 'تم التوصيل';
        icon = Icons.check_circle;
        break;
      case 'pending':
      case 'company_pickup_request':
        color = const Color(0xFFFF9800);
        statusText = 'في الانتظار';
        icon = Icons.hourglass_empty;
        break;
      default:
        color = const Color(0xFF1976D2);
        statusText = 'قيد التوصيل';
        icon = Icons.local_shipping;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12.sp),
          SizedBox(width: 4.w),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 10.sp,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
