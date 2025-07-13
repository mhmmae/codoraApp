import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
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
      final itemsSnapshot = await FirebaseFirestore.instance
          .collection('orders')
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
        final collectionName = isOffer 
            ? FirebaseX.offersCollection 
            : FirebaseX.itemsCollection;
        
        final productDoc = await FirebaseFirestore.instance
            .collection(collectionName)
            .doc(itemId)
            .get();
        
        if (productDoc.exists) {
          final productData = productDoc.data()!;
          final price = (productData['priceOfItem'] as num?)?.toDouble() ?? 0.0;
          final itemTotal = price * quantity;
          total += itemTotal;
          
          items.add({
            'name': productData['nameOfItem'] ?? 'منتج غير معروف',
            'price': price,
            'quantity': quantity,
            'total': itemTotal,
            'imageUrl': productData['url'] ?? '',
            'isOffer': isOffer,
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
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // App Bar متحرك
          _buildAnimatedAppBar(size),
          
          // محتوى الصفحة
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // معلومات العميل
                      _buildCustomerInfo(size),
                      const SizedBox(height: 24),
                      
                      // معلومات الطلب
                      _buildOrderInfo(size),
                      const SizedBox(height: 24),
                      
                      // قائمة المنتجات
                      _buildProductsList(size),
                      const SizedBox(height: 24),
                      
                      // ملخص السعر
                      _buildPriceSummary(size),
                      const SizedBox(height: 32),
                      
                      // أزرار الإجراءات
                      _buildActionButtons(size),
                      const SizedBox(height: 32),
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
  Widget _buildAnimatedAppBar(Size size) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      stretch: true,
      backgroundColor: Theme.of(context).primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'معاينة الطلب',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.7),
              ],
            ),
          ),
          child: Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.receipt_long,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'طلب #${widget.orderData['numberOfOrder']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
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
  Widget _buildCustomerInfo(Size size) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // صورة العميل
          Hero(
            tag: 'user_${widget.orderId}',
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  width: 3,
                ),
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: NetworkImage(widget.userData['url'] ?? ''),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // معلومات العميل
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userData['name'] ?? 'عميل',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }

  /// بناء معلومات الطلب
  Widget _buildOrderInfo(Size size) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.1),
            Colors.blue.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem(
                icon: Icons.calendar_today,
                label: 'التاريخ',
                value: GetDateToText().dateToText(widget.orderData['timeOrder']),
                color: Colors.blue,
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.grey[300],
              ),
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
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  /// بناء قائمة المنتجات
  Widget _buildProductsList(Size size) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'المنتجات المطلوبة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_orderItems.length} منتج',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (_isLoading)
          Center(
            child: Container(
              padding: const EdgeInsets.all(40),
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
                final animation = Tween<double>(
                  begin: 0.0,
                  end: 1.0,
                ).animate(
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
                    child: _buildProductItem(item, size),
                  ),
                );
              },
            );
          }),
      ],
    );
  }

  /// بناء عنصر منتج
  Widget _buildProductItem(Map<String, dynamic> item, Size size) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // صورة المنتج
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                fit: BoxFit.cover,
                image: NetworkImage(item['imageUrl']),
              ),
            ),
            child: item['isOffer']
                ? Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'عرض',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // معلومات المنتج
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shopping_cart,
                        size: 16,
                        color: Colors.orange[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'الكمية المطلوبة: ${item['quantity']}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'السعر: ${item['price']} ${FirebaseX.currency}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          // السعر الإجمالي للمنتج
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${item['total']} ${FirebaseX.currency}',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// بناء ملخص السعر
  Widget _buildPriceSummary(Size size) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.1),
            Colors.green.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'المجموع الكلي',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: _totalPrice),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Text(
                    '${value.toStringAsFixed(0)} ${FirebaseX.currency}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          // يمكن إضافة تفاصيل أخرى مثل رسوم التوصيل هنا
        ],
      ),
    );
  }

  /// بناء أزرار الإجراءات
  Widget _buildActionButtons(Size size) {
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
        const SizedBox(width: 16),
        // زر القبول
        Expanded(
          flex: 2,
          child: _buildAnimatedButton(
            onPressed: _isLoading
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
            height: 56,
            decoration: BoxDecoration(
              gradient: isGradient && !isOutlined
                  ? LinearGradient(
                      colors: [color, color.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isOutlined ? null : (isGradient ? null : color),
              borderRadius: BorderRadius.circular(16),
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
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        color: isOutlined ? color : Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: TextStyle(
                          color: isOutlined ? color : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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
      
      // إغلاق الصفحة والعودة
      Get.back();
      Get.back(); // للعودة من bottom sheet أيضاً إذا كان مفتوحاً
      
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

  /// عرض حوار الرفض
  void _showRejectDialog() {
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
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
} 