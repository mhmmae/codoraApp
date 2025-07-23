import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../controllers/orders_controller.dart';
import '../../../XXX/xxx_firebase.dart';
import '../../ViewOrderSeller/GetDateToText.dart';

/// صفحة معاينة تفاصيل الطلب قبل قبوله
class OrderPreviewPage extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> orderData;
  final Map<String, dynamic> userData;

  const OrderPreviewPage({
    super.key,
    required this.orderId,
    required this.orderData,
    required this.userData,
  });

  @override
  State<OrderPreviewPage> createState() => _OrderPreviewPageState();
}

class _OrderPreviewPageState extends State<OrderPreviewPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _itemsAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  bool _isLoading = false;
  List<Map<String, dynamic>> _orderItems = [];
  double _totalPrice = 0.0;

  /// تحديد حالة الطلب الحالية
  OrderStatus get _orderStatus {
    final statusString = widget.orderData['orderStatus'] ?? 'pending';
    switch (statusString) {
      case 'pending':
        return OrderStatus.pending;
      case 'accepted':
        return OrderStatus.accepted;
      case 'readyForPickup':
        return OrderStatus.readyForPickup;
      case 'pickedUp':
        return OrderStatus.pickedUp;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  /// تحديد نوع الطلب (جملة أو تجزئة)
  Map<String, dynamic> _getOrderTypeInfo() {
    final orderType = widget.orderData['orderType'] ?? '';
    final buyerType = widget.orderData['buyerType'] ?? '';
    final source = widget.orderData['source'] ?? '';

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
  void initState() {
    super.initState();

    // إعداد الأنيميشن
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _itemsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    // بدء الأنيميشن
    _animationController.forward();

    // جلب تفاصيل الطلب
    _loadOrderItems();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _itemsAnimationController.dispose();
    super.dispose();
  }

  /// جلب منتجات الطلب من subcollection
  Future<void> _loadOrderItems() async {
    setState(() => _isLoading = true);

    try {
      // جلب منتجات الطلب من subcollection
      final itemsSnapshot =
          await FirebaseFirestore.instance
              .collection(FirebaseX.ordersCollection)
              .doc(widget.orderId)
              .collection('OrderItems')
              .get();

      List<Map<String, dynamic>> items = [];
      double total = 0.0;

      // جلب تفاصيل كل منتج
      for (var doc in itemsSnapshot.docs) {
        final itemData = doc.data();
        final isOffer = itemData['isOfer'] ?? false;
        final itemId = itemData['uidItem'];
        final quantity = itemData['number'] ?? 1;

        // جلب معلومات المنتج من المجموعة المناسبة
        final collectionName =
            isOffer ? FirebaseX.offersCollection : FirebaseX.itemsCollection;

        final productDoc =
            await FirebaseFirestore.instance
                .collection(collectionName)
                .doc(itemId)
                .get();

        if (productDoc.exists) {
          final productData = productDoc.data()!;

          // استخدام السعر من ItemModel بشكل موحد لكلا نوعي الطلبات
          double price =
              (productData['price'] as num?)?.toDouble() ??
              (productData['priceOfItem'] as num?)?.toDouble() ??
              0.0;

          final itemTotal = price * quantity;
          total += itemTotal;

          items.add({
            'name': productData['nameOfItem'] ?? 'منتج غير معروف',
            'price': price,
            'quantity': quantity,
            'total': itemTotal,
            'imageUrl': productData['url'] ?? '',
            'isOffer': isOffer,
            'priceType': 'unified', // نوع سعر موحد
          });
        }
      }

      setState(() {
        _orderItems = items;
        _totalPrice = total;
        _isLoading = false;
      });

      // بدء أنيميشن المنتجات
      _itemsAnimationController.forward();
    } catch (e) {
      debugPrint('Error loading order items: $e');
      setState(() => _isLoading = false);
      Get.snackbar(
        'خطأ',
        'فشل في تحميل تفاصيل الطلب',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // App Bar متحرك
          _buildAnimatedAppBar(),

          // محتوى الصفحة
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // معلومات العميل
                      _buildCustomerInfo(),
                      SizedBox(height: 24.h),

                      // معلومات الطلب
                      _buildOrderInfo(),
                      SizedBox(height: 24.h),

                      // قائمة المنتجات
                      _buildProductsList(),
                      SizedBox(height: 24.h),

                      // ملخص السعر
                      _buildPriceSummary(),
                      SizedBox(height: 32.h),

                      // أزرار الإجراءات
                      _buildActionButtons(),
                      SizedBox(height: 32.h),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// بناء App Bar متحرك
  Widget _buildAnimatedAppBar() {
    final orderTypeInfo = _getOrderTypeInfo();
    final typeColor = orderTypeInfo['color'] as Color;

    return SliverAppBar(
      expandedHeight: 250.h, // زيادة الارتفاع لإضافة نوع الطلب
      floating: false,
      pinned: true,
      stretch: true,
      backgroundColor: typeColor,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'معاينة الطلب',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [typeColor, typeColor.withOpacity(0.7)],
            ),
          ),
          child: Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // شعار نوع الطلب
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2.w,
                      ),
                    ),
                    child: Icon(
                      orderTypeInfo['icon'] as IconData,
                      size: 50.sp,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // نوع الطلب
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(25.r),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.w,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          orderTypeInfo['icon'] as IconData,
                          color: Colors.white,
                          size: 16.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          orderTypeInfo['label'] as String,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '• ${orderTypeInfo['description']}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),
                  // رقم الطلب
                  Text(
                    'طلب #${widget.orderData['numberOfOrder']}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: () {
          HapticFeedback.lightImpact();
          Get.back();
        },
      ),
    );
  }

  /// بناء معلومات العميل
  Widget _buildCustomerInfo() {
    final orderTypeInfo = _getOrderTypeInfo();
    final typeColor = orderTypeInfo['color'] as Color;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: typeColor.withOpacity(0.3), width: 2.w),
        boxShadow: [
          BoxShadow(
            color: typeColor.withOpacity(0.1),
            blurRadius: 10.r,
            offset: Offset(0, 5.h),
          ),
        ],
      ),
      child: Row(
        children: [
          // صورة العميل
          Hero(
            tag: 'user_${widget.orderId}',
            child: Container(
              width: 70.w,
              height: 70.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: typeColor, width: 3.w),
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: NetworkImage(widget.userData['url'] ?? ''),
                ),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          // معلومات العميل
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userData['name'] ?? 'عميل',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                SizedBox(height: 8.h),
                // نوع الطلب في معلومات العميل
                Container(
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
                        orderTypeInfo['icon'] as IconData,
                        color: typeColor,
                        size: 16.sp,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        orderTypeInfo['label'] as String,
                        style: TextStyle(
                          color: typeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// بناء معلومات الطلب
  Widget _buildOrderInfo() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.withOpacity(0.1), Colors.blue.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.blue.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem(
                icon: Icons.calendar_today,
                label: 'التاريخ',
                value: GetDateToText().dateToText(
                  widget.orderData['timeOrder'],
                ),
                color: Colors.blue,
              ),
              Container(height: 40.h, width: 1, color: Colors.grey[300]),
              _buildInfoItem(
                icon: Icons.shopping_basket,
                label: 'عدد المنتجات',
                value: '${_orderItems.length}',
                color: Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// بناء عنصر معلومات
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24.sp),
        SizedBox(height: 4.h),
        Text(label, style: TextStyle(fontSize: 12.sp, color: Colors.grey[600])),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  /// بناء قائمة المنتجات
  Widget _buildProductsList() {
    final orderTypeInfo = _getOrderTypeInfo();
    final typeColor = orderTypeInfo['color'] as Color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'المنتجات المطلوبة',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                // شارة نوع الطلب
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15.r),
                    border: Border.all(
                      color: typeColor.withOpacity(0.3),
                      width: 1.w,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        orderTypeInfo['icon'] as IconData,
                        color: typeColor,
                        size: 12.sp,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        orderTypeInfo['label'] as String,
                        style: TextStyle(
                          color: typeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                // عدد المنتجات
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    '${_orderItems.length} منتج',
                    style: TextStyle(
                      color: typeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 16.h),

        if (_isLoading)
          Center(
            child: Container(
              padding: EdgeInsets.all(40.w),
              child: const CircularProgressIndicator(),
            ),
          )
        else
          ..._orderItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

            return AnimatedBuilder(
              animation: _itemsAnimationController,
              builder: (context, child) {
                final delay = index * 0.1;
                final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _itemsAnimationController,
                    curve: Interval(
                      delay,
                      delay + 0.5,
                      curve: Curves.easeOutBack,
                    ),
                  ),
                );

                return Transform.scale(
                  scale: animation.value,
                  child: FadeTransition(
                    opacity: animation,
                    child: _buildProductItem(item),
                  ),
                );
              },
            );
          }),
      ],
    );
  }

  /// بناء عنصر منتج
  Widget _buildProductItem(Map<String, dynamic> item) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(9.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.r,
            offset: Offset(0, 5.h),
          ),
        ],
      ),
      child: Row(
        children: [
          // صورة المنتج
          Container(
            width: 80.w,
            height: 80.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              image: DecorationImage(
                fit: BoxFit.cover,
                image: NetworkImage(item['imageUrl']),
              ),
            ),
            child:
                item['isOffer']
                    ? Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(12.r),
                            bottomLeft: Radius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          'عرض',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                    : null,
          ),
          SizedBox(width: 12.w),
          // معلومات المنتج
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'],
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                      width: 1.w,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shopping_cart,
                        size: 14.sp,
                        color: Colors.orange[700],
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'الكمية المطلوبة: ${item['quantity']}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Text(
                      'السعر: ${item['price'].toInt()} ${FirebaseX.currency}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(width: 6.w),

                    // عرض السعر الإجمالي للمنتج
                  ],
                ),
              ],
            ),
          ),
          // السعر الإجمالي للمنتج
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              '${item['total'].toInt()} ${FirebaseX.currency}',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 10.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// بناء ملخص السعر
  Widget _buildPriceSummary() {
    final orderTypeInfo = _getOrderTypeInfo();
    final typeColor = orderTypeInfo['color'] as Color;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.1),
            Colors.green.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.green.withOpacity(0.2), width: 1.w),
      ),
      child: Column(
        children: [
          // نوع الطلب في ملخص السعر
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
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
                      orderTypeInfo['icon'] as IconData,
                      color: typeColor,
                      size: 16.sp,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'طلب ${orderTypeInfo['label']} - ${orderTypeInfo['description']}',
                      style: TextStyle(
                        color: typeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'المجموع الكلي',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: _totalPrice),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Text(
                    '${value.toInt()} ${FirebaseX.currency}',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  );
                },
              ),
            ],
          ),
          SizedBox(height: 8.h),
          // يمكن إضافة تفاصيل أخرى مثل رسوم التوصيل هنا
        ],
      ),
    );
  }

  /// بناء أزرار الإجراءات
  Widget _buildActionButtons() {
    // تحديد الأزرار بناءً على حالة الطلب
    switch (_orderStatus) {
      case OrderStatus.pending:
        // الطلبات الجديدة: زر قبول وزر رفض
        return Row(
          children: [
            // زر الرفض
            Expanded(
              child: _buildAnimatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _showRejectDialog();
                },
                label: 'رفض',
                icon: Icons.close,
                color: Colors.red,
                isOutlined: true,
              ),
            ),
            SizedBox(width: 16.w),
            // زر القبول
            Expanded(
              flex: 2,
              child: _buildAnimatedButton(
                onPressed:
                    _isLoading
                        ? null
                        : () {
                          HapticFeedback.lightImpact();
                          _acceptOrder();
                        },
                label: 'قبول الطلب',
                icon: Icons.check_circle,
                color: Colors.green,
                isGradient: true,
              ),
            ),
          ],
        );

      case OrderStatus.accepted:
        // الطلبات المقبولة (قيد التحضير): زر "الطلب جاهز"
        return Row(
          children: [
            Expanded(
              child: _buildAnimatedButton(
                onPressed:
                    _isLoading
                        ? null
                        : () {
                          HapticFeedback.lightImpact();
                          _markOrderReady();
                        },
                label: 'الطلب جاهز',
                icon: Icons.check_circle_outline,
                color: Colors.blue,
                isGradient: true,
              ),
            ),
          ],
        );

      case OrderStatus.readyForPickup:
        // الطلبات الجاهزة: لا توجد أزرار
        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 24.sp),
              SizedBox(width: 8.w),
              Text(
                'الطلب جاهز للاستلام',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
            ],
          ),
        );

      default:
        // للطلبات الأخرى: لا توجد أزرار
        return const SizedBox.shrink();
    }
  }

  /// بناء زر متحرك
  Widget _buildAnimatedButton({
    required VoidCallback? onPressed,
    required String label,
    required IconData icon,
    required Color color,
    bool isOutlined = false,
    bool isGradient = false,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.95, end: 1.0),
      duration: const Duration(milliseconds: 200),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            height: 56.h,
            decoration: BoxDecoration(
              gradient:
                  isGradient && !isOutlined
                      ? LinearGradient(
                        colors: [color, color.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                      : null,
              color: isOutlined ? null : (isGradient ? null : color),
              borderRadius: BorderRadius.circular(16.r),
              border: isOutlined ? Border.all(color: color, width: 2.w) : null,
              boxShadow:
                  !isOutlined
                      ? [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 10.r,
                          offset: Offset(0, 5.h),
                        ),
                      ]
                      : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(16.r),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        color: isOutlined ? color : Colors.white,
                        size: 24.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        label,
                        style: TextStyle(
                          color: isOutlined ? color : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
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

  /// قبول الطلب
  Future<void> _acceptOrder() async {
    setState(() => _isLoading = true);

    try {
      final ordersController = Get.find<OrdersController>();
      await ordersController.acceptOrder(widget.orderId);

      // إعادة تعيين loading قبل الخروج
      setState(() => _isLoading = false);

      // إغلاق الصفحة والعودة
      Get.back();

      Get.snackbar(
        '✅ تم قبول الطلب',
        'يمكنك الآن البدء في تحضير المنتجات',
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar(
        '❌ خطأ',
        'فشل في قبول الطلب، حاول مرة أخرى',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    }
  }

  /// تحديد الطلب كجاهز للاستلام
  Future<void> _markOrderReady() async {
    setState(() => _isLoading = true);

    try {
      final ordersController = Get.find<OrdersController>();
      await ordersController.markOrderReady(widget.orderId);

      // إعادة تعيين loading قبل الخروج
      setState(() => _isLoading = false);

      // إغلاق الصفحة والعودة
      Get.back();

      Get.snackbar(
        '📦 الطلب جاهز!',
        'تم تحديد الطلب كجاهز للاستلام من قبل عامل التوصيل',
        backgroundColor: Colors.blue.withOpacity(0.1),
        colorText: Colors.blue,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar(
        '❌ خطأ',
        'فشل في تحديث حالة الطلب، حاول مرة أخرى',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    }
  }

  /// عرض حوار الرفض
  void _showRejectDialog() {
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
                Icons.warning_amber_rounded,
                color: Colors.orange[700],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('تأكيد رفض الطلب', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: const Text(
          'هل أنت متأكد من رفض هذا الطلب؟\nلا يمكن التراجع عن هذا الإجراء.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('إلغاء', style: TextStyle(color: Colors.grey[600])),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Get.back();
              final ordersController = Get.find<OrdersController>();
              ordersController.rejectOrder(widget.orderId);
              Get.back(); // إغلاق صفحة المعاينة
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
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}
