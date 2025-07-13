import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:math' as math;

import '../controllers/orders_controller.dart';
import '../utils/barcode_helper.dart';
import 'GetDateToText.dart';
import '../../XXX/xxx_firebase.dart';
import '../ui/pages/order_preview_page.dart';

/// واجهة عرض الطلبات المحسنة مع نظام الحالات المتعددة وأنيميشن احترافي
class EnhancedOrdersView extends StatefulWidget {
  const EnhancedOrdersView({super.key});

  @override
  State<EnhancedOrdersView> createState() => _EnhancedOrdersViewState();
}

class _EnhancedOrdersViewState extends State<EnhancedOrdersView>
    with TickerProviderStateMixin {
  late AnimationController _mainAnimationController;
  late AnimationController _tabAnimationController;
  late AnimationController _statsAnimationController;
  late TabController _tabController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  
  // للأنيميشن الفردي للبطاقات
  final List<AnimationController> _cardControllers = [];
  final Map<String, AnimationController> _buttonAnimations = {};

  @override
  void initState() {
    super.initState();
    
    // إعداد متحكمات الأنيميشن الرئيسية
    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _tabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _statsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _tabController = TabController(length: 3, vsync: this);
    
    // إعداد الأنيميشن
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutBack),
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
    ));
    
    // بدء الأنيميشن
    _mainAnimationController.forward();
    _tabAnimationController.forward();
    _statsAnimationController.forward();
    
    // إضافة listener للتبويبات
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        HapticFeedback.selectionClick();
      }
    });
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _tabAnimationController.dispose();
    _statsAnimationController.dispose();
    _tabController.dispose();
    for (var controller in _cardControllers) {
      controller.dispose();
    }
    _buttonAnimations.forEach((_, controller) {
      controller.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersController = Get.put(OrdersController());
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // شريط الإحصائيات العلوي
          _buildAnimatedStatsBar(ordersController, width),
          
          // شريط التبويب المحسن
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildProfessionalTabBar(ordersController, width),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // محتوى التبويبات
          Expanded(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOrdersList(
                    ordersController.newOrdersList,
                    OrderStatus.pending,
                    width,
                    height,
                    const Color(0xFF2196F3), // أزرق
                  ),
                  _buildOrdersList(
                    ordersController.acceptedOrdersList,
                    OrderStatus.accepted,
                    width,
                    height,
                    const Color(0xFFFF9800), // برتقالي
                  ),
                  _buildOrdersList(
                    ordersController.readyOrdersList,
                    OrderStatus.readyForPickup,
                    width,
                    height,
                    const Color(0xFF4CAF50), // أخضر
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// بناء شريط الإحصائيات المتحرك
  Widget _buildAnimatedStatsBar(OrdersController controller, double width) {
    return AnimatedBuilder(
      animation: _statsAnimationController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor.withOpacity(0.1),
                Theme.of(context).primaryColor.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                controller.newOrdersCount,
                'جديد',
                Icons.fiber_new,
                const Color(0xFF2196F3),
                0.0,
              ),
              _buildVerticalDivider(),
              _buildStatItem(
                controller.acceptedOrdersCount,
                'قيد التحضير',
                Icons.restaurant,
                const Color(0xFFFF9800),
                0.2,
              ),
              _buildVerticalDivider(),
              _buildStatItem(
                controller.readyOrdersCount,
                'جاهز',
                Icons.check_circle,
                const Color(0xFF4CAF50),
                0.4,
              ),
            ],
          ),
        );
      },
    );
  }

  /// بناء عنصر إحصائي واحد
  Widget _buildStatItem(
    RxInt count,
    String label,
    IconData icon,
    Color color,
    double delay,
  ) {
    return Obx(() {
      final animation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _statsAnimationController,
        curve: Interval(delay, delay + 0.5, curve: Curves.elasticOut),
      ));
      
      return AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return Transform.scale(
            scale: animation.value,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: count.value),
                  duration: const Duration(milliseconds: 1000),
                  builder: (context, value, child) {
                    return Text(
                      '$value',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    );
                  },
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  /// فاصل عمودي
  Widget _buildVerticalDivider() {
    return Container(
      height: 50,
      width: 1,
      color: Colors.grey[300],
    );
  }

  /// بناء شريط التبويب الاحترافي
  Widget _buildProfessionalTabBar(OrdersController controller, double width) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 55,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
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
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(5),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        tabs: [
          _buildAnimatedTab('جديد', controller.newOrdersCount, const Color(0xFF2196F3)),
          _buildAnimatedTab('قيد التحضير', controller.acceptedOrdersCount, const Color(0xFFFF9800)),
          _buildAnimatedTab('جاهز', controller.readyOrdersCount, const Color(0xFF4CAF50)),
        ],
      ),
    );
  }

  /// بناء تاب متحرك
  Widget _buildAnimatedTab(String label, RxInt count, Color color) {
    return Tab(
      child: Obx(() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label),
          if (count.value > 0) ...[
            const SizedBox(width: 8),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: count.value > 0 ? 1.0 : 0.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      '${count.value}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      )),
    );
  }

  /// بناء قائمة الطلبات لكل تبويب
  Widget _buildOrdersList(
    RxList<QueryDocumentSnapshot> ordersList,
    OrderStatus status,
    double width,
    double height,
    Color accentColor,
  ) {
    final ordersController = Get.find<OrdersController>();
    
    return Obx(() {
      if (ordersList.isEmpty) {
        return _buildEmptyState(status, width, accentColor);
      }

      return RefreshIndicator(
        onRefresh: () => ordersController.refreshOrders(),
        color: accentColor,
        backgroundColor: Colors.white,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: ordersList.length,
          itemBuilder: (context, index) {
            final orderDoc = ordersList[index];
            final orderData = orderDoc.data() as Map<String, dynamic>;
            
            // إنشاء animation controller لكل بطاقة
            if (_cardControllers.length <= index) {
              final controller = AnimationController(
                duration: Duration(milliseconds: 800 + (index * 100)),
                vsync: this,
              );
              _cardControllers.add(controller);
              controller.forward();
            }
            
            return AnimatedBuilder(
              animation: _cardControllers[index],
              builder: (context, child) {
                final slideAnimation = Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _cardControllers[index],
                  curve: Curves.easeOutBack,
                ));
                
                final fadeAnimation = Tween<double>(
                  begin: 0.0,
                  end: 1.0,
                ).animate(CurvedAnimation(
                  parent: _cardControllers[index],
                  curve: Curves.easeIn,
                ));
                
                return SlideTransition(
                  position: slideAnimation,
                  child: FadeTransition(
                    opacity: fadeAnimation,
                    child: _buildProfessionalOrderCard(
                      orderDoc,
                      orderData,
                      status,
                      width,
                      height,
                      accentColor,
                    ),
                  ),
                );
              },
            );
          },
        ),
      );
    });
  }

  /// بناء بطاقة الطلب الاحترافية
  Widget _buildProfessionalOrderCard(
    QueryDocumentSnapshot orderDoc,
    Map<String, dynamic> orderData,
    OrderStatus status,
    double width,
    double height,
    Color accentColor,
  ) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection(FirebaseX.collectionApp)
          .doc(orderData['uidUser'])
          .get(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard(height);
        }

        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                _showOrderDetails(orderDoc, orderData, userData, status, accentColor);
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // رأس البطاقة
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
                          // صورة المستخدم
                          Hero(
                            tag: 'user_${orderDoc.id}',
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: accentColor.withOpacity(0.3),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: accentColor.withOpacity(0.2),
                                    blurRadius: 10,
                                  ),
                                ],
                                image: DecorationImage(
                                  fit: BoxFit.cover,
                                  image: NetworkImage(userData['url'] ?? ''),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // معلومات المستخدم
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userData['name'] ?? 'غير محدد',
                                  style: const TextStyle(
                                    fontSize: 18,
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
                                          fontSize: 14,
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
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    accentColor.withOpacity(0.15),
                                    accentColor.withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: accentColor.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    size: 16,
                                    color: accentColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    dateController.dateToText(orderData['timeOrder']),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: accentColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // أزرار الأكشن
                    _buildActionButtons(
                      context,
                      orderDoc.id,
                      orderData,
                      userData,
                      status,
                      width,
                      height,
                      accentColor,
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

  /// بناء أزرار الأكشن حسب حالة الطلب
  Widget _buildActionButtons(
    BuildContext context,
    String orderId,
    Map<String, dynamic> orderData,
    Map<String, dynamic> userData,
    OrderStatus status,
    double width,
    double height,
    Color accentColor,
  ) {

    // إنشاء animation controller للأزرار
    _buttonAnimations[orderId] ??= AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    Widget content;
    
    switch (status) {
      case OrderStatus.pending:
        content = Row(
          children: [
            // زر الرفض
            Expanded(
              child: _buildAnimatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _showRejectDialog(context, orderId);
                },
                label: 'رفض',
                icon: Icons.close,
                color: Colors.red,
                isOutlined: true,
              ),
            ),
            const SizedBox(width: 12),
            // زر معاينة الطلب
            Expanded(
              flex: 2,
              child: _buildAnimatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  // الانتقال إلى صفحة معاينة الطلب
                  _navigateToOrderPreview(orderId, orderData, userData);
                },
                label: 'معاينة الطلب',
                icon: Icons.visibility,
                color: Colors.blue,
                isGradient: true,
              ),
            ),
          ],
        );
        break;

      case OrderStatus.accepted:
        content = Row(
          children: [
            Expanded(
              child: _buildAnimatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  // الانتقال إلى صفحة معاينة الطلب
                  _navigateToOrderPreview(orderId, orderData, userData);
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
                  _showReadyConfirmDialog(context, orderId);
                },
                label: 'جاهز للاستلام',
                icon: Icons.inventory_2,
                color: Colors.orange,
                isGradient: true,
              ),
            ),
          ],
        );
        break;

      case OrderStatus.readyForPickup:
        content = Column(
          children: [
            // زر معاينة الطلب
            _buildAnimatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                // الانتقال إلى صفحة معاينة الطلب
                _navigateToOrderPreview(orderId, orderData, userData);
              },
              label: 'معاينة الطلب',
              icon: Icons.visibility,
              color: Colors.blue,
              isOutlined: true,
              isFullWidth: true,
            ),
            const SizedBox(height: 16),
            Text(
              'في انتظار عامل التوصيل',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            // QR Code
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                BarcodeHelper.showBarcodeDialog(
                  context,
                  orderData['numberOfOrder'].toString(),
                  'طلب من ${userData['name'] ?? 'عميل'}',
                );
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.withOpacity(0.15),
                      Colors.green.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.qr_code_2,
                      color: Colors.green[700],
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'عرض رمز QR للتسليم',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'اطلب من عامل التوصيل مسح الرمز',
                      style: TextStyle(
                        color: Colors.green[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
        break;

      default:
        content = const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: content,
    );
  }

  /// بناء زر متحرك احترافي
  Widget _buildAnimatedButton({
    required VoidCallback onPressed,
    required String label,
    required IconData icon,
    required Color color,
    bool isOutlined = false,
    bool isGradient = false,
    bool isFullWidth = false,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.95, end: 1.0),
      duration: const Duration(milliseconds: 200),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: isFullWidth ? double.infinity : null,
            height: 50,
            decoration: BoxDecoration(
              gradient: isGradient && !isOutlined
                  ? LinearGradient(
                      colors: [color, color.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isOutlined ? null : (isGradient ? null : color),
              borderRadius: BorderRadius.circular(15),
              border: isOutlined ? Border.all(color: color, width: 2) : null,
              boxShadow: !isOutlined
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        color: isOutlined ? color : Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: TextStyle(
                          color: isOutlined ? color : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// عرض تفاصيل الطلب
  void _showOrderDetails(
    QueryDocumentSnapshot orderDoc,
    Map<String, dynamic> orderData,
    Map<String, dynamic> userData,
    OrderStatus status,
    Color accentColor,
  ) {
    HapticFeedback.lightImpact();
    
    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // مقبض السحب
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 60,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            // محتوى التفاصيل
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'تفاصيل الطلب',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // يمكنك إضافة المزيد من التفاصيل هنا
                ],
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enterBottomSheetDuration: const Duration(milliseconds: 300),
      exitBottomSheetDuration: const Duration(milliseconds: 200),
    );
  }

  /// عرض حوار تأكيد الرفض
  void _showRejectDialog(BuildContext context, String orderId) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange[700],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'تأكيد رفض الطلب',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'هل أنت متأكد من رفض هذا الطلب؟\nلا يمكن التراجع عن هذا الإجراء.',
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
              Get.find<OrdersController>().rejectOrder(orderId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'رفض الطلب',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  /// حوار تأكيد الطلب الجاهز
  void _showReadyConfirmDialog(BuildContext context, String orderId) {
    HapticFeedback.mediumImpact();
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
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

  /// بناء بطاقة التحميل
  Widget _buildLoadingCard(double height) {
    return Container(
      height: height * 0.15,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  /// حالة القائمة الفارغة
  Widget _buildEmptyState(OrderStatus status, double width, Color color) {
    final Map<OrderStatus, Map<String, dynamic>> emptyStateData = {
      OrderStatus.pending: {
        'icon': Icons.inbox_outlined,
        'title': 'لا توجد طلبات جديدة',
        'subtitle': 'ستظهر الطلبات الجديدة هنا تلقائياً',
        'animation': 'bounce',
      },
      OrderStatus.accepted: {
        'icon': Icons.restaurant_menu,
        'title': 'لا توجد طلبات قيد التحضير',
        'subtitle': 'ابدأ بقبول الطلبات الجديدة',
        'animation': 'rotate',
      },
      OrderStatus.readyForPickup: {
        'icon': Icons.inventory_2_outlined,
        'title': 'لا توجد طلبات جاهزة',
        'subtitle': 'قم بتجهيز الطلبات المقبولة',
        'animation': 'pulse',
      },
    };

    final data = emptyStateData[status]!;

    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 800),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAnimatedEmptyIcon(
                  data['icon'],
                  color,
                  data['animation'],
                ),
                const SizedBox(height: 24),
                Text(
                  data['title'],
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data['subtitle'],
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// بناء أيقونة متحركة للحالة الفارغة
  Widget _buildAnimatedEmptyIcon(IconData icon, Color color, String animationType) {
    switch (animationType) {
      case 'bounce':
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(seconds: 2),
          curve: Curves.elasticInOut,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, math.sin(value * math.pi * 2) * 10),
              child: Icon(
                icon,
                size: 80,
                color: color.withOpacity(0.3),
              ),
            );
          },
          onEnd: () {
            setState(() {});
          },
        );
      
      case 'rotate':
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 2 * math.pi),
          duration: const Duration(seconds: 3),
          builder: (context, value, child) {
            return Transform.rotate(
              angle: value,
              child: Icon(
                icon,
                size: 80,
                color: color.withOpacity(0.3),
              ),
            );
          },
          onEnd: () {
            setState(() {});
          },
        );
      
      case 'pulse':
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.8, end: 1.2),
          duration: const Duration(seconds: 1),
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Icon(
                icon,
                size: 80,
                color: color.withOpacity(0.3),
              ),
            );
          },
          onEnd: () {
            setState(() {});
          },
        );
      
      default:
        return Icon(
          icon,
          size: 80,
          color: color.withOpacity(0.3),
        );
    }
  }

  /// الانتقال إلى صفحة معاينة الطلب
  void _navigateToOrderPreview(
    String orderId,
    Map<String, dynamic> orderData,
    Map<String, dynamic> userData,
  ) {
    HapticFeedback.lightImpact();
    
    Get.to(
      () => OrderPreviewPage(
        orderId: orderId,
        orderData: orderData,
        userData: userData,
      ),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 300),
    );
  }
}