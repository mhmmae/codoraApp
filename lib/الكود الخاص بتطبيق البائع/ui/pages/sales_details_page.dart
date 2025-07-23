import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/sales_analytics_controller.dart';
import '../../../Model/sales_analytics_model.dart';
import 'customer_details_page.dart';
import 'top_customers_page.dart';

/// صفحة تفاصيل المبيعات للبائع
class SalesDetailsPage extends StatelessWidget {
  const SalesDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final SalesAnalyticsController controller = Get.put(
      SalesAnalyticsController(),
    );

    // متغير لحالة إظهار/إخفاء ملخص المبيعات والفلاتر
    final RxBool showSummaryAndFilters = false.obs;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'تفاصيل المبيعات',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.people, color: Colors.white),
            onPressed: () => Get.to(() => const TopCustomersPage()),
            tooltip: 'أفضل العملاء',
          ),
          Obx(
            () => IconButton(
              icon: Icon(
                showSummaryAndFilters.value
                    ? Icons.visibility_off
                    : Icons.analytics,
                color: Colors.white,
              ),
              onPressed: () => showSummaryAndFilters.toggle(),
              tooltip:
                  showSummaryAndFilters.value ? 'إخفاء الملخص' : 'إظهار الملخص',
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
            ),
          );
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
                SizedBox(height: 16.h),
                Text(
                  controller.errorMessage.value,
                  style: TextStyle(fontSize: 16.sp, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed:
                      () => controller.loadSalesForPeriod(
                        controller.selectedPeriod.value,
                      ),
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ملخص المبيعات وفلاتر الفترة الزمنية (مخفية افتراضياً)
                Obx(() {
                  if (!showSummaryAndFilters.value) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    children: [
                      // ملخص المبيعات
                      _buildSalesSummaryCard(controller),
                      SizedBox(height: 20.h),

                      // فلاتر الفترة الزمنية
                      _buildPeriodFilters(controller),
                      SizedBox(height: 20.h),
                    ],
                  );
                }),

                // قائمة المبيعات التفصيلية
                _buildSalesDetailsList(controller),
              ],
            ),
          ),
        );
      }),
    );
  }

  /// بناء بطاقة ملخص المبيعات
  Widget _buildSalesSummaryCard(SalesAnalyticsController controller) {
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
                Icon(Icons.trending_up, color: Colors.white, size: 24.sp),
                SizedBox(width: 8.w),
                Text(
                  'ملخص المبيعات - ${_getPeriodTitle(controller.selectedPeriod.value)}',
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
                    'إجمالي المبيعات',
                    '${NumberFormat('#,###').format(controller.currentPeriodRevenue)} د.ع',
                    Icons.attach_money,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildSummaryItem(
                    'صافي الربح',
                    '${NumberFormat('#,###').format(controller.currentPeriodProfit)} د.ع',
                    Icons.account_balance_wallet,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'عدد الطلبات',
                    '${controller.currentSales.length}',
                    Icons.shopping_cart,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildSummaryItem(
                    'متوسط الطلب',
                    '${NumberFormat('#,###').format(controller.averageOrderValue)} د.ع',
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

  /// بناء عنصر ملخص المبيعات
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

  /// بناء فلاتر الفترة الزمنية
  Widget _buildPeriodFilters(SalesAnalyticsController controller) {
    final periods = [
      {'key': 'today', 'title': 'اليوم', 'icon': Icons.today},
      {'key': 'week', 'title': 'هذا الأسبوع', 'icon': Icons.date_range},
      {'key': 'month', 'title': 'هذا الشهر', 'icon': Icons.calendar_month},
      {'key': 'year', 'title': 'هذا العام', 'icon': Icons.calendar_today},
    ];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Container(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'اختر الفترة الزمنية',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2E7D32),
              ),
            ),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children:
                  periods.map((period) {
                    final isSelected =
                        controller.selectedPeriod.value == period['key'];
                    return GestureDetector(
                      onTap:
                          () => controller.loadSalesForPeriod(
                            period['key'] as String,
                          ),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? const Color(0xFF2E7D32)
                                  : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color:
                                isSelected
                                    ? const Color(0xFF2E7D32)
                                    : Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              period['icon'] as IconData,
                              size: 16.sp,
                              color:
                                  isSelected
                                      ? Colors.white
                                      : const Color(0xFF2E7D32),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              period['title'] as String,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                color:
                                    isSelected
                                        ? Colors.white
                                        : const Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء قائمة تفاصيل المبيعات
  Widget _buildSalesDetailsList(SalesAnalyticsController controller) {
    final sales = controller.currentSales;

    if (sales.isEmpty) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Container(
          padding: EdgeInsets.all(40.w),
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, size: 64.sp, color: Colors.grey[400]),
              SizedBox(height: 16.h),
              Text(
                'لا توجد مبيعات في الفترة المحددة',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'ابدأ ببيع منتجاتك لرؤية التفاصيل هنا',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تفاصيل المبيعات (${sales.length} طلب)',
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
          itemCount: sales.length,
          separatorBuilder: (context, index) => SizedBox(height: 12.h),
          itemBuilder: (context, index) {
            final sale = sales[index];
            return _buildSaleCard(sale);
          },
        ),
      ],
    );
  }

  /// بناء بطاقة مبيعة واحدة
  Widget _buildSaleCard(SalesAnalyticsModel sale) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: InkWell(
        onTap: () => _showSaleDetails(sale),
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // معلومات المشتري
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Get.to(
                        () => CustomerDetailsPage(
                          customerId: sale.buyerId,
                          customerName: sale.buyerName,
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 24.r,
                      backgroundImage:
                          sale.buyerImageUrl != null
                              ? NetworkImage(sale.buyerImageUrl!)
                              : null,
                      backgroundColor: const Color(0xFF2E7D32),
                      child:
                          sale.buyerImageUrl == null
                              ? Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 24.sp,
                              )
                              : null,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Get.to(
                          () => CustomerDetailsPage(
                            customerId: sale.buyerId,
                            customerName: sale.buyerName,
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  sale.buyerName,
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2E7D32),
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 12.sp,
                                color: Colors.grey[400],
                              ),
                            ],
                          ),
                          if (sale.buyerPhoneNumber != null)
                            Text(
                              sale.buyerPhoneNumber!,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        DateFormat('dd/MM/yyyy').format(sale.orderDate),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        DateFormat('HH:mm').format(sale.orderDate),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // معلومات المبيعات
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      'إجمالي المبلغ',
                      '${NumberFormat('#,###').format(sale.totalAmount)} د.ع',
                      Icons.attach_money,
                      const Color(0xFF1976D2),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _buildInfoChip(
                      'الربح',
                      '${NumberFormat('#,###').format(sale.sellerProfit)} د.ع',
                      Icons.trending_up,
                      const Color(0xFF388E3C),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),

              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      'عدد المنتجات',
                      '${sale.items.length} منتج',
                      Icons.inventory_2,
                      const Color(0xFF7B1FA2),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _buildDeliveryStatusChip(sale.deliveryStatus),
                  ),
                ],
              ),

              // معلومات التوصيل إذا وجدت
              if (sale.driverName != null) ...[
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.delivery_dining,
                        color: Colors.blue,
                        size: 16.sp,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'عامل التوصيل: ${sale.driverName}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.blue[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// بناء شريحة المعلومات
  Widget _buildInfoChip(
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
        crossAxisAlignment: CrossAxisAlignment.center,
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
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: color,
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
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 14.sp),
              SizedBox(width: 4.w),
              Text(
                'حالة التوصيل',
                style: TextStyle(fontSize: 10.sp, color: color),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// عرض تفاصيل المبيعة
  void _showSaleDetails(SalesAnalyticsModel sale) {
    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(maxHeight: Get.height * 0.8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
        ),
        child: Column(
          children: [
            // مقبض السحب
            Container(
              margin: EdgeInsets.only(top: 12.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),

            // العنوان
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'تفاصيل الطلب',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // المحتوى
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // معلومات المشتري
                    _buildDetailSection('معلومات المشتري', [
                      _buildDetailRow('الاسم', sale.buyerName),
                      if (sale.buyerPhoneNumber != null)
                        _buildDetailRow('رقم الهاتف', sale.buyerPhoneNumber!),
                      _buildDetailRow(
                        'تاريخ الطلب',
                        DateFormat('dd/MM/yyyy HH:mm').format(sale.orderDate),
                      ),
                    ]),

                    SizedBox(height: 20.h),

                    // معلومات المالية
                    _buildDetailSection('المعلومات المالية', [
                      _buildDetailRow(
                        'إجمالي المبلغ',
                        '${NumberFormat('#,###').format(sale.totalAmount)} د.ع',
                      ),
                      _buildDetailRow(
                        'ربح البائع',
                        '${NumberFormat('#,###').format(sale.sellerProfit)} د.ع',
                      ),
                      _buildDetailRow(
                        'هامش الربح',
                        '${sale.profitMargin.toStringAsFixed(1)}%',
                      ),
                      if (sale.deliveryFee != null)
                        _buildDetailRow(
                          'رسوم التوصيل',
                          '${NumberFormat('#,###').format(sale.deliveryFee)} د.ع',
                        ),
                      _buildDetailRow(
                        'صافي الربح',
                        '${NumberFormat('#,###').format(sale.netProfit)} د.ع',
                      ),
                    ]),

                    SizedBox(height: 20.h),

                    // معلومات التوصيل
                    if (sale.driverName != null)
                      _buildDetailSection('معلومات التوصيل', [
                        _buildDetailRow(
                          'حالة التوصيل',
                          _getDeliveryStatusText(sale.deliveryStatus),
                        ),
                        _buildDetailRow('عامل التوصيل', sale.driverName!),
                        if (sale.driverPhoneNumber != null)
                          _buildDetailRow(
                            'هاتف السائق',
                            sale.driverPhoneNumber!,
                          ),
                        if (sale.deliveryDate != null)
                          _buildDetailRow(
                            'تاريخ التوصيل',
                            DateFormat(
                              'dd/MM/yyyy HH:mm',
                            ).format(sale.deliveryDate!),
                          ),
                        if (sale.deliveryAddress != null)
                          _buildDetailRow(
                            'عنوان التوصيل',
                            sale.deliveryAddress!,
                          ),
                      ]),

                    SizedBox(height: 20.h),

                    // قائمة المنتجات
                    _buildDetailSection(
                      'المنتجات (${sale.items.length})',
                      sale.items.map((item) => _buildProductRow(item)).toList(),
                    ),

                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  /// بناء قسم التفاصيل
  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2E7D32),
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  /// بناء صف التفاصيل
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              '$label:',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// بناء صف المنتج
  Widget _buildProductRow(OrderItemAnalytics item) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          // صورة المنتج
          Container(
            width: 50.w,
            height: 50.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.r),
              color: Colors.grey[200],
              image:
                  item.itemImageUrl != null
                      ? DecorationImage(
                        image: NetworkImage(item.itemImageUrl!),
                        fit: BoxFit.cover,
                      )
                      : null,
            ),
            child:
                item.itemImageUrl == null
                    ? Icon(
                      Icons.shopping_bag,
                      color: Colors.grey[400],
                      size: 24.sp,
                    )
                    : null,
          ),
          SizedBox(width: 12.w),

          // تفاصيل المنتج
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Text(
                      'الكمية: ${item.quantity}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'السعر: ${NumberFormat('#,###').format(item.unitPrice)} د.ع',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Text(
                  'الربح: ${NumberFormat('#,###').format(item.itemProfit)} د.ع',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFF388E3C),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// الحصول على عنوان الفترة
  String _getPeriodTitle(String period) {
    switch (period) {
      case 'today':
        return 'اليوم';
      case 'week':
        return 'هذا الأسبوع';
      case 'month':
        return 'هذا الشهر';
      case 'year':
        return 'هذا العام';
      default:
        return 'اليوم';
    }
  }

  /// الحصول على نص حالة التوصيل
  String _getDeliveryStatusText(String status) {
    switch (status) {
      case 'delivered':
        return 'تم التوصيل';
      case 'pending':
      case 'company_pickup_request':
        return 'في انتظار التوصيل';
      case 'driver_assigned':
        return 'تم تعيين سائق';
      case 'en_route_to_pickup':
        return 'في الطريق للاستلام';
      case 'picked_up_from_seller':
        return 'تم الاستلام من البائع';
      case 'out_for_delivery_to_buyer':
        return 'في الطريق للتوصيل';
      default:
        return 'غير محدد';
    }
  }
}
