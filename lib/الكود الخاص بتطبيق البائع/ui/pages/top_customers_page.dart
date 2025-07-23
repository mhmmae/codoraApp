import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/sales_analytics_controller.dart';
import '../../../Model/sales_analytics_model.dart';
import 'customer_details_page.dart';

/// صفحة أفضل العملاء
class TopCustomersPage extends StatelessWidget {
  const TopCustomersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final SalesAnalyticsController salesController =
        Get.find<SalesAnalyticsController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'أفضل العملاء',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => salesController.refreshSalesData(),
          ),
        ],
      ),
      body: Obx(() {
        if (salesController.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
            ),
          );
        }

        final topCustomers = _getTopCustomers(salesController.currentSales);

        if (topCustomers.isEmpty) {
          return _buildEmptyState();
        }

        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ملخص العملاء
                _buildCustomersSummaryCard(topCustomers),
                SizedBox(height: 20.h),

                // قائمة أفضل العملاء
                _buildTopCustomersList(topCustomers),
              ],
            ),
          ),
        );
      }),
    );
  }

  /// الحصول على أفضل العملاء
  List<CustomerSummary> _getTopCustomers(List<SalesAnalyticsModel> sales) {
    Map<String, CustomerSummary> customerMap = {};

    for (final sale in sales) {
      if (customerMap.containsKey(sale.buyerId)) {
        final customer = customerMap[sale.buyerId]!;
        customerMap[sale.buyerId] = CustomerSummary(
          customerId: customer.customerId,
          customerName: customer.customerName,
          customerPhone: customer.customerPhone,
          customerImageUrl: customer.customerImageUrl,
          totalOrders: customer.totalOrders + 1,
          totalSpent: customer.totalSpent + sale.totalAmount,
          totalProfit: customer.totalProfit + sale.sellerProfit,
          lastOrderDate:
              sale.orderDate.isAfter(customer.lastOrderDate)
                  ? sale.orderDate
                  : customer.lastOrderDate,
          completedOrders:
              customer.completedOrders + (sale.isDelivered ? 1 : 0),
        );
      } else {
        customerMap[sale.buyerId] = CustomerSummary(
          customerId: sale.buyerId,
          customerName: sale.buyerName,
          customerPhone: sale.buyerPhoneNumber,
          customerImageUrl: sale.buyerImageUrl,
          totalOrders: 1,
          totalSpent: sale.totalAmount,
          totalProfit: sale.sellerProfit,
          lastOrderDate: sale.orderDate,
          completedOrders: sale.isDelivered ? 1 : 0,
        );
      }
    }

    final customers = customerMap.values.toList();
    customers.sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
    return customers;
  }

  /// بناء بطاقة ملخص العملاء
  Widget _buildCustomersSummaryCard(List<CustomerSummary> customers) {
    final totalCustomers = customers.length;
    final totalRevenue = customers.fold(
      0.0,
      (sum, customer) => sum + customer.totalSpent,
    );
    final totalProfit = customers.fold(
      0.0,
      (sum, customer) => sum + customer.totalProfit,
    );
    final averageOrderValue =
        customers.isNotEmpty
            ? customers.fold(
                  0.0,
                  (sum, customer) => sum + customer.averageOrderValue,
                ) /
                customers.length
            : 0.0;

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: const LinearGradient(
            colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.stars, color: Colors.white, size: 24.sp),
                SizedBox(width: 8.w),
                Text(
                  'ملخص أفضل العملاء',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'إجمالي العملاء',
                    totalCustomers.toString(),
                    Icons.people,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildSummaryItem(
                    'إجمالي المبيعات',
                    '${NumberFormat('#,###').format(totalRevenue)} د.ع',
                    Icons.attach_money,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'إجمالي الأرباح',
                    '${NumberFormat('#,###').format(totalProfit)} د.ع',
                    Icons.trending_up,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildSummaryItem(
                    'متوسط قيمة الطلب',
                    '${NumberFormat('#,###').format(averageOrderValue)} د.ع',
                    Icons.calculate,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// بناء عنصر الملخص
  Widget _buildSummaryItem(String title, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 16.sp),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// بناء قائمة أفضل العملاء
  Widget _buildTopCustomersList(List<CustomerSummary> customers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'أفضل العملاء (${customers.length})',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2E7D32),
          ),
        ),
        SizedBox(height: 12.h),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: customers.length,
          separatorBuilder: (context, index) => SizedBox(height: 12.h),
          itemBuilder: (context, index) {
            final customer = customers[index];
            return _buildCustomerCard(customer, index + 1);
          },
        ),
      ],
    );
  }

  /// بناء بطاقة عميل
  Widget _buildCustomerCard(CustomerSummary customer, int rank) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: InkWell(
        onTap: () {
          Get.to(
            () => CustomerDetailsPage(
              customerId: customer.customerId,
              customerName: customer.customerName,
            ),
          );
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              // رأس البطاقة
              Row(
                children: [
                  // ترتيب العميل
                  _buildRankBadge(rank),
                  SizedBox(width: 12.w),

                  // صورة العميل
                  CircleAvatar(
                    radius: 30.r,
                    backgroundImage:
                        customer.customerImageUrl != null
                            ? NetworkImage(customer.customerImageUrl!)
                            : null,
                    backgroundColor: const Color(0xFF2E7D32),
                    child:
                        customer.customerImageUrl == null
                            ? Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 30.sp,
                            )
                            : null,
                  ),
                  SizedBox(width: 12.w),

                  // معلومات العميل
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.customerName,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                        if (customer.customerPhone != null)
                          Text(
                            customer.customerPhone!,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        Text(
                          'آخر طلب: ${DateFormat('dd/MM/yyyy').format(customer.lastOrderDate)}',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // أيقونة الانتقال
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 16.sp,
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // إحصائيات العميل
              Row(
                children: [
                  Expanded(
                    child: _buildStatChip(
                      'الطلبات',
                      customer.totalOrders.toString(),
                      Icons.shopping_cart,
                      const Color(0xFF1976D2),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _buildStatChip(
                      'المبلغ الإجمالي',
                      '${NumberFormat('#,###').format(customer.totalSpent)} د.ع',
                      Icons.attach_money,
                      const Color(0xFF388E3C),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Expanded(
                    child: _buildStatChip(
                      'الأرباح',
                      '${NumberFormat('#,###').format(customer.totalProfit)} د.ع',
                      Icons.trending_up,
                      const Color(0xFF7B1FA2),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _buildStatChip(
                      'متوسط الطلب',
                      '${NumberFormat('#,###').format(customer.averageOrderValue)} د.ع',
                      Icons.calculate,
                      const Color(0xFFFF9800),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),

              // نسبة الإكمال
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color:
                      customer.completionRate >= 80
                          ? Colors.green[50]
                          : customer.completionRate >= 60
                          ? Colors.orange[50]
                          : Colors.red[50],
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      customer.completionRate >= 80
                          ? Icons.check_circle
                          : customer.completionRate >= 60
                          ? Icons.warning
                          : Icons.error,
                      color:
                          customer.completionRate >= 80
                              ? Colors.green
                              : customer.completionRate >= 60
                              ? Colors.orange
                              : Colors.red,
                      size: 16.sp,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'نسبة الإكمال: ${customer.completionRate.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color:
                            customer.completionRate >= 80
                                ? Colors.green[800]
                                : customer.completionRate >= 60
                                ? Colors.orange[800]
                                : Colors.red[800],
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

  /// بناء شارة الترتيب
  Widget _buildRankBadge(int rank) {
    Color color;
    IconData icon;

    switch (rank) {
      case 1:
        color = const Color(0xFFFFD700); // ذهبي
        icon = Icons.workspace_premium;
        break;
      case 2:
        color = const Color(0xFFC0C0C0); // فضي
        icon = Icons.workspace_premium;
        break;
      case 3:
        color = const Color(0xFFCD7F32); // برونزي
        icon = Icons.workspace_premium;
        break;
      default:
        color = const Color(0xFF2E7D32);
        icon = Icons.star;
        break;
    }

    return Container(
      width: 40.w,
      height: 40.h,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (rank <= 3)
            Icon(icon, color: Colors.white, size: 16.sp)
          else
            Text(
              rank.toString(),
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  /// بناء شريحة الإحصائيات
  Widget _buildStatChip(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 14.sp),
              SizedBox(width: 4.w),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 10.sp, color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// بناء حالة فارغة
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 100.sp, color: Colors.grey[400]),
          SizedBox(height: 24.h),
          Text(
            'لا توجد بيانات عملاء',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'ابدأ ببيع منتجاتك لبناء قاعدة عملاء',
            style: TextStyle(fontSize: 16.sp, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// نموذج ملخص العميل
class CustomerSummary {
  final String customerId;
  final String customerName;
  final String? customerPhone;
  final String? customerImageUrl;
  final int totalOrders;
  final double totalSpent;
  final double totalProfit;
  final DateTime lastOrderDate;
  final int completedOrders;

  CustomerSummary({
    required this.customerId,
    required this.customerName,
    this.customerPhone,
    this.customerImageUrl,
    required this.totalOrders,
    required this.totalSpent,
    required this.totalProfit,
    required this.lastOrderDate,
    required this.completedOrders,
  });

  /// حساب متوسط قيمة الطلب
  double get averageOrderValue =>
      totalOrders > 0 ? totalSpent / totalOrders : 0.0;

  /// حساب نسبة الإكمال
  double get completionRate =>
      totalOrders > 0 ? (completedOrders / totalOrders) * 100 : 0.0;
}
