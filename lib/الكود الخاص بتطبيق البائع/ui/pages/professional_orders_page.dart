import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
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

  @override
  Widget build(BuildContext context) {
    final ordersController = Get.put(OrdersController());
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header مع أنيميشن
            _buildAnimatedHeader(ordersController, size),
            
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
  Widget _buildAnimatedHeader(OrdersController controller, Size size) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.all(size.width * 0.05),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
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
    return Obx(() => ScaleTransition(
      scale: _scaleAnimation,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: animation,
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    '${count.value}',
                    key: ValueKey<int>(count.value),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ));
  }

  /// بناء TabBar احترافي
  Widget _buildProfessionalTabBar(OrdersController controller) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
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
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        tabs: [
          _buildAnimatedTab('جديد', controller.newOrdersCount, Colors.blue),
          _buildAnimatedTab('قيد التحضير', controller.acceptedOrdersCount, Colors.orange),
          _buildAnimatedTab('جاهز', controller.readyOrdersCount, Colors.green),
        ],
      ),
    );
  }

  /// بناء تاب متحرك
  Widget _buildAnimatedTab(String label, RxInt count, Color color) {
    return Tab(
      child: Obx(() => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label),
            if (count.value > 0) ...[
              const SizedBox(width: 8),
              AnimatedScale(
                scale: count.value > 0 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${count.value}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      )),
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
          padding: const EdgeInsets.all(16),
          itemCount: ordersList.length,
          itemBuilder: (context, index) {
            final orderDoc = ordersList[index];
            final orderData = orderDoc.data() as Map<String, dynamic>;
            
            return AnimatedBuilder(
              animation: _scaleController,
              builder: (context, child) {
                final delay = index * 0.1;
                final animation = Tween<double>(
                  begin: 0.0,
                  end: 1.0,
                ).animate(
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
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection(FirebaseX.collectionApp)
          .doc(orderData['uidUser'])
          .get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            elevation: 2,
            shadowColor: accentColor.withOpacity(0.2),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _showOrderDetails(orderDoc, orderData, userData, status),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: accentColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    // Header مع معلومات الطلب
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accentColor.withOpacity(0.1),
                            accentColor.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          // صورة المستخدم مع أنيميشن
                          Hero(
                            tag: 'user_${orderDoc.id}',
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: accentColor.withOpacity(0.3),
                                  width: 2,
                                ),
                                image: DecorationImage(
                                  fit: BoxFit.cover,
                                  image: NetworkImage(userData['url'] ?? ''),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // معلومات العميل
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userData['name'] ?? 'عميل',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.phone,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        userData['phneNumber'] ?? 'غير محدد',
                                        style: TextStyle(
                                          fontSize: 12,
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
                          // التاريخ والوقت فقط
                          GetBuilder<GetDateToText>(
                            init: GetDateToText(),
                            builder: (dateController) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: accentColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: accentColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    dateController.dateToText(orderData['timeOrder']),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: accentColor,
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
                    _buildActionSection(orderDoc.id, orderData, userData, status, accentColor),
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
      padding: const EdgeInsets.all(16),
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
            const SizedBox(width: 12),
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
            const SizedBox(width: 12),
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
                  const SizedBox(height: 12),
                  Text(
                    'في انتظار عامل التوصيل',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // QR Code
                  GestureDetector(
                    onTap: () => BarcodeHelper.showBarcodeDialog(
                      context,
                      orderData['numberOfOrder'].toString(),
                      'طلب من ${userData['name'] ?? 'عميل'}',
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.withOpacity(0.15),
                            Colors.green.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
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
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'عرض رمز QR للتسليم',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'اطلب من عامل التوصيل مسح الرمز',
                            style: TextStyle(
                              color: Colors.green[600],
                              fontSize: 12,
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
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: isOutlined ? Border.all(color: color, width: 1.5) : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isOutlined ? color : Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isOutlined ? color : Colors.white,
                    fontWeight: FontWeight.bold,
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
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'تفاصيل الطلب',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange[700]),
            const SizedBox(width: 8),
            const Text('تأكيد رفض الطلب'),
          ],
        ),
        content: const Text(
          'هل أنت متأكد من رفض هذا الطلب؟\nلا يمكن التراجع عن هذا الإجراء.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.find<OrdersController>().rejectOrder(orderId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'رفض الطلب',
              style: TextStyle(color: Colors.white),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2,
                color: Colors.orange[700],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'تأكيد جاهزية الطلب',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'هل أنت متأكد من انتهاء تجهيز الطلب؟\n\nسوف يتم استدعاء عامل التوصيل لأخذ الطلب.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'إلغاء',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Get.back();
              Get.find<OrdersController>().markOrderReady(orderId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'نعم، الطلب جاهز',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                    size: 80,
                    color: color.withOpacity(0.3),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Text(
              data['title'],
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              data['subtitle'],
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 