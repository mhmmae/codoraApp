import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import '../../controllers/orders_controller.dart';
import '../../utils/barcode_helper.dart';
import '../../../XXX/xxx_firebase.dart';
import '../../ViewOrderSeller/GetDateToText.dart';
import 'order_preview_page.dart';

/// واجهة عرض الطلبات الاحترافية مع أنيميشن متقدم
class ProfessionalOrdersPage extends StatefulWidget {
  const ProfessionalOrdersPage({super.key});

  @override
  State<ProfessionalOrdersPage> createState() => _ProfessionalOrdersPageState();
}

class _ProfessionalOrdersPageState extends State<ProfessionalOrdersPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late TabController _tabController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // إعداد متحكمات الأنيميشن
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _tabController = TabController(length: 3, vsync: this);

    // إعداد الأنيميشن
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // بدء الأنيميشن
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  /// تحديد نوع الطلب (جملة أو تجزئة)
  Map<String, dynamic> _getOrderTypeInfo(Map<String, dynamic> orderData) {
    final orderType = orderData['orderType'] ?? '';
    final buyerType = orderData['buyerType'] ?? '';
    final source = orderData['source'] ?? '';

    // تحديد نوع الطلب
    bool isRetail = false;

    // طلبات التجزئة من تطبيق العميل
    if (orderType == 'retail' ||
        buyerType == 'customer' ||
        source == 'customer_app' ||
        orderType == 'customer_order') {
      isRetail = true;
    }
    // طلبات الجملة من تطبيق البائع
    else if (orderType == 'wholesale' ||
        buyerType == 'retailer' ||
        source == 'seller_app' ||
        orderType == 'wholesale_to_retail') {
      isRetail = false;
    }
    // افتراضي: إذا لم نتمكن من تحديد النوع نعتبره تجزئة
    else {
      isRetail = true;
    }

    if (isRetail) {
      return {
        'type': 'retail',
        'label': 'تجزئة',
        'icon': Icons.person,
        'color': Colors.blue,
        'bgColor': Colors.blue.withOpacity(0.1),
        'borderColor': Colors.blue.withOpacity(0.3),
        'description': 'طلب من العميل',
      };
    } else {
      return {
        'type': 'wholesale',
        'label': 'جملة',
        'icon': Icons.business,
        'color': Colors.orange,
        'bgColor': Colors.orange.withOpacity(0.1),
        'borderColor': Colors.orange.withOpacity(0.3),
        'description': 'طلب من البائع',
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersController = Get.put(OrdersController());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header مع أنيميشن
            _buildAnimatedHeader(ordersController),

            // TabBar احترافي
            _buildProfessionalTabBar(ordersController),

            // محتوى الطلبات
            Expanded(
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOrdersSection(
                        ordersController.newOrdersList,
                        OrderStatus.pending,
                        Colors.blue,
                      ),
                      _buildOrdersSection(
                        ordersController.acceptedOrdersList,
                        OrderStatus.accepted,
                        Colors.orange,
                      ),
                      _buildOrdersSection(
                        ordersController.readyOrdersList,
                        OrderStatus.readyForPickup,
                        Colors.green,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء الهيدر المتحرك
  Widget _buildAnimatedHeader(OrdersController controller) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10.r,
              offset: Offset(0, 5.h),
            ),
          ],
        ),
        child: Column(
          children: [
            // إحصائيات سريعة
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                  controller.newOrdersCount,
                  'جديد',
                  Colors.blue,
                  Icons.new_releases,
                ),
                _buildStatCard(
                  controller.acceptedOrdersCount,
                  'قيد التحضير',
                  Colors.orange,
                  Icons.restaurant,
                ),
                _buildStatCard(
                  controller.readyOrdersCount,
                  'جاهز',
                  Colors.green,
                  Icons.check_circle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// بناء بطاقة الإحصائيات
  Widget _buildStatCard(RxInt count, String label, Color color, IconData icon) {
    return Obx(
      () => ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15.r),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24.sp),
              SizedBox(width: 8.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder: (
                      Widget child,
                      Animation<double> animation,
                    ) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(scale: animation, child: child),
                      );
                    },
                    child: Text(
                      '${count.value}',
                      key: ValueKey<int>(count.value),
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: color.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// بناء TabBar احترافي
  Widget _buildProfessionalTabBar(OrdersController controller) {
    return Container(
      margin: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.r,
            offset: Offset(0, 5.h),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
              blurRadius: 8.r,
              offset: Offset(0, 3.h),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        tabs: [
          _buildAnimatedTab('جديد', controller.newOrdersCount, Colors.blue),
          _buildAnimatedTab(
            'قيد التحضير',
            controller.acceptedOrdersCount,
            Colors.orange,
          ),
          _buildAnimatedTab('جاهز', controller.readyOrdersCount, Colors.green),
        ],
      ),
    );
  }

  /// بناء تاب متحرك
  Widget _buildAnimatedTab(String label, RxInt count, Color color) {
    return Tab(
      child: Obx(
        () => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: TextStyle(fontSize: 10.sp)),
              if (count.value > 0) ...[
                // SizedBox(width: 1.w),
                AnimatedScale(
                  scale: count.value > 0 ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      '${count.value}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// بناء قسم الطلبات
  Widget _buildOrdersSection(
    RxList<QueryDocumentSnapshot> ordersList,
    OrderStatus status,
    Color accentColor,
  ) {
    final ordersController = Get.find<OrdersController>();

    return Obx(() {
      if (ordersList.isEmpty) {
        return _buildEmptyState(status, accentColor);
      }

      return RefreshIndicator(
        onRefresh: () => ordersController.refreshOrders(),
        color: accentColor,
        child: ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: ordersList.length,
          itemBuilder: (context, index) {
            final orderDoc = ordersList[index];
            final orderData = orderDoc.data() as Map<String, dynamic>;

            return AnimatedBuilder(
              animation: _scaleController,
              builder: (context, child) {
                final delay = index * 0.1;
                final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _scaleController,
                    curve: Interval(
                      delay,
                      delay + 0.5,
                      curve: Curves.easeOutBack,
                    ),
                  ),
                );

                return Transform.scale(
                  scale: animation.value,
                  child: _buildProfessionalOrderCard(
                    orderDoc,
                    orderData,
                    status,
                    accentColor,
                  ),
                );
              },
            );
          },
        ),
      );
    });
  }

  /// بناء بطاقة طلب احترافية
  Widget _buildProfessionalOrderCard(
    QueryDocumentSnapshot orderDoc,
    Map<String, dynamic> orderData,
    OrderStatus status,
    Color accentColor,
  ) {
    // تحديد نوع الطلب
    final orderTypeInfo = _getOrderTypeInfo(orderData);
    final typeColor = orderTypeInfo['color'] as Color;
    final typeBgColor = orderTypeInfo['bgColor'] as Color;
    final typeBorderColor = orderTypeInfo['borderColor'] as Color;

    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance
              .collection(FirebaseX.collectionApp)
              .doc(orderData['uidUser'])
              .get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;

        return Container(
          margin: EdgeInsets.only(bottom: 16.h),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            elevation: 2,
            shadowColor: typeColor.withOpacity(0.2),
            child: InkWell(
              borderRadius: BorderRadius.circular(20.r),
              onTap:
                  () =>
                      _showOrderDetails(orderDoc, orderData, userData, status),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: typeBorderColor, width: 2.w),
                  // إضافة تدرج لوني خفيف
                  gradient: LinearGradient(
                    colors: [typeBgColor, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    // شريط علوي لنوع الطلب
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        vertical: 8.h,
                        horizontal: 16.w,
                      ),
                      decoration: BoxDecoration(
                        color: typeColor,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(18.r),
                          topRight: Radius.circular(18.r),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            orderTypeInfo['icon'] as IconData,
                            color: Colors.white,
                            size: 18.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            orderTypeInfo['label'] as String,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '• ${orderTypeInfo['description']}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Header مع معلومات الطلب
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(18.r),
                          bottomRight: Radius.circular(18.r),
                        ),
                      ),
                      child: Row(
                        children: [
                          // صورة المستخدم مع أنيميشن
                          Hero(
                            tag: 'user_${orderDoc.id}',
                            child: Container(
                              width: 60.w,
                              height: 60.h,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: typeColor,
                                  width: 3.w,
                                ),
                                image: DecorationImage(
                                  fit: BoxFit.cover,
                                  image: NetworkImage(userData['url'] ?? ''),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          // معلومات العميل
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userData['name'] ?? 'عميل',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                SizedBox(height: 4.h),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.phone,
                                      size: 14.sp,
                                      color: Colors.grey[600],
                                    ),
                                    SizedBox(width: 4.w),
                                    Flexible(
                                      child: Text(
                                        userData['phneNumber'] ?? 'غير محدد',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: Colors.grey[600],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // التاريخ والوقت
                          GetBuilder<GetDateToText>(
                            init: GetDateToText(),
                            builder:
                                (dateController) => Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                    vertical: 6.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: typeColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20.r),
                                    border: Border.all(
                                      color: typeColor.withOpacity(0.3),
                                      width: 1.w,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 14.sp,
                                        color: typeColor,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        dateController.dateToText(
                                          orderData['timeOrder'],
                                        ),
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          color: typeColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ),
                    // أزرار الإجراءات
                    _buildActionSection(
                      orderDoc.id,
                      orderData,
                      userData,
                      status,
                      typeColor, // استخدام لون نوع الطلب بدلاً من accentColor
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// بناء قسم الإجراءات
  Widget _buildActionSection(
    String orderId,
    Map<String, dynamic> orderData,
    Map<String, dynamic> userData,
    OrderStatus status,
    Color accentColor,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          if (status == OrderStatus.pending) ...[
            Expanded(
              child: _buildAnimatedButton(
                onPressed: () => _showRejectDialog(orderId),
                label: 'رفض',
                icon: Icons.close,
                color: Colors.red,
                isOutlined: true,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              flex: 2,
              child: _buildAnimatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  // الانتقال إلى صفحة معاينة الطلب
                  Get.to(
                    () => OrderPreviewPage(
                      orderId: orderId,
                      orderData: orderData,
                      userData: userData,
                    ),
                    transition: Transition.rightToLeft,
                    duration: const Duration(milliseconds: 300),
                  );
                },
                label: 'معاينة الطلب',
                icon: Icons.visibility,
                color: Colors.blue,
              ),
            ),
          ] else if (status == OrderStatus.accepted) ...[
            Expanded(
              child: _buildAnimatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  // الانتقال إلى صفحة معاينة الطلب
                  Get.to(
                    () => OrderPreviewPage(
                      orderId: orderId,
                      orderData: orderData,
                      userData: userData,
                    ),
                    transition: Transition.rightToLeft,
                    duration: const Duration(milliseconds: 300),
                  );
                },
                label: 'معاينة الطلب',
                icon: Icons.visibility,
                color: Colors.blue,
                isOutlined: true,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              flex: 2,
              child: _buildAnimatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _showReadyConfirmDialog(orderId);
                },
                label: 'جاهز للاستلام',
                icon: Icons.inventory_2,
                color: Colors.orange,
              ),
            ),
          ] else if (status == OrderStatus.readyForPickup) ...[
            Expanded(
              child: Column(
                children: [
                  // زر معاينة الطلب
                  _buildAnimatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      // الانتقال إلى صفحة معاينة الطلب
                      Get.to(
                        () => OrderPreviewPage(
                          orderId: orderId,
                          orderData: orderData,
                          userData: userData,
                        ),
                        transition: Transition.rightToLeft,
                        duration: const Duration(milliseconds: 300),
                      );
                    },
                    label: 'معاينة الطلب',
                    icon: Icons.visibility,
                    color: Colors.blue,
                    isOutlined: true,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'في انتظار عامل التوصيل',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  // QR Code
                  GestureDetector(
                    onTap:
                        () => BarcodeHelper.showBarcodeDialog(
                          context,
                          orderData['numberOfOrder'].toString(),
                          'طلب من ${userData['name'] ?? 'عميل'}',
                        ),
                    child: Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.withOpacity(0.15),
                            Colors.green.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.qr_code_2,
                            color: Colors.green[700],
                            size: 40.sp,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'عرض رمز QR للتسليم',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 16.sp,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'اطلب من عامل التوصيل مسح الرمز',
                            style: TextStyle(
                              color: Colors.green[600],
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// بناء زر متحرك
  Widget _buildAnimatedButton({
    required VoidCallback onPressed,
    required String label,
    required IconData icon,
    required Color color,
    bool isOutlined = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: isOutlined ? Colors.transparent : color,
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              border: isOutlined ? Border.all(color: color, width: 1.5) : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isOutlined ? color : Colors.white,
                  size: 16.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  label,
                  style: TextStyle(
                    color: isOutlined ? color : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// عرض تفاصيل الطلب
  void _showOrderDetails(
    QueryDocumentSnapshot orderDoc,
    Map<String, dynamic> orderData,
    Map<String, dynamic> userData,
    OrderStatus status,
  ) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25.r),
            topRight: Radius.circular(25.r),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'تفاصيل الطلب',
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20.h),
            // يمكنك إضافة المزيد من التفاصيل هنا
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  /// حوار الرفض
  void _showRejectDialog(String orderId) {
    HapticFeedback.mediumImpact();
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange[700]),
            SizedBox(width: 8.w),
            Text('تأكيد رفض الطلب', style: TextStyle(fontSize: 18.sp)),
          ],
        ),
        content: Text(
          'هل أنت متأكد من رفض هذا الطلب؟\nلا يمكن التراجع عن هذا الإجراء.',
          style: TextStyle(height: 1.5, fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('إلغاء', style: TextStyle(fontSize: 14.sp)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.find<OrdersController>().rejectOrder(orderId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            ),
            child: Text(
              'رفض الطلب',
              style: TextStyle(color: Colors.white, fontSize: 14.sp),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  /// حوار تأكيد الطلب الجاهز
  void _showReadyConfirmDialog(String orderId) {
    HapticFeedback.mediumImpact();
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delivery_dining,
                color: Colors.orange[700],
                size: 24.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Text('تأكيد جاهزية الطلب', style: TextStyle(fontSize: 18.sp)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'هل أنت متأكد من انتهاء تجهيز الطلب؟',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'سيتم إشعار عامل التوصيل تلقائياً لاستلام الطلب',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'إلغاء',
              style: TextStyle(color: Colors.grey[600], fontSize: 14.sp),
            ),
          ),
          SizedBox(width: 8.w),
          ElevatedButton(
            onPressed: () async {
              HapticFeedback.mediumImpact();
              Get.back();

              try {
                await Get.find<OrdersController>().markOrderReady(orderId);

                // إشعار إضافي لاستدعاء عامل التوصيل
                Get.snackbar(
                  '🚚 تم استدعاء عامل التوصيل',
                  'تم إشعار عامل التوصيل لاستلام الطلب',
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  colorText: Colors.blue,
                  duration: const Duration(seconds: 4),
                  icon: const Icon(Icons.delivery_dining, color: Colors.blue),
                );
              } catch (e) {
                Get.snackbar(
                  '❌ خطأ',
                  'فشل في تحديث حالة الطلب',
                  backgroundColor: Colors.red.withOpacity(0.1),
                  colorText: Colors.red,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            ),
            child: Text(
              'نعم، الطلب جاهز',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  /// حالة فارغة
  Widget _buildEmptyState(OrderStatus status, Color color) {
    final Map<OrderStatus, Map<String, dynamic>> emptyStateData = {
      OrderStatus.pending: {
        'icon': Icons.inbox_outlined,
        'title': 'لا توجد طلبات جديدة',
        'subtitle': 'ستظهر الطلبات الجديدة هنا',
      },
      OrderStatus.accepted: {
        'icon': Icons.restaurant_menu,
        'title': 'لا توجد طلبات قيد التحضير',
        'subtitle': 'ابدأ بقبول الطلبات الجديدة',
      },
      OrderStatus.readyForPickup: {
        'icon': Icons.inventory_2_outlined,
        'title': 'لا توجد طلبات جاهزة',
        'subtitle': 'قم بتجهيز الطلبات المقبولة',
      },
    };

    final data = emptyStateData[status]!;

    return Center(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(seconds: 2),
              builder: (context, value, child) {
                return Transform.rotate(
                  angle: value * 2 * math.pi,
                  child: Icon(
                    data['icon'],
                    size: 80.sp,
                    color: color.withOpacity(0.3),
                  ),
                );
              },
            ),
            SizedBox(height: 20.h),
            Text(
              data['title'],
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              data['subtitle'],
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
