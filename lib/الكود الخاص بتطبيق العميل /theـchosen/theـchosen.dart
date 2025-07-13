import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'class/SendAndTotalPrice.dart';
import 'class/StreamListOfItem.dart';
import 'GetXController/GetAddAndRemove.dart';

/// شاشة عرض السلة (The Chosen Items)
/// تُظهر الشريط العلوي مع عنوان "السلة"، قسم عرض قائمة العناصر الموجودة في السلة،
/// وقسم عرض إجمالي السعر وزر "إرسال الطلب".
class TheChosen extends StatefulWidget {
  final String uid;

  const TheChosen({super.key, required this.uid});

  @override
  State<TheChosen> createState() => _TheChosenState();
}

class _TheChosenState extends State<TheChosen> 
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  late GetAddAndRemove controller;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  bool get wantKeepAlive => false; // لا نريد الاحتفاظ بالصفحة حية لضمان إعادة البناء

  @override
  void initState() {
    super.initState();
    
    // تهيئة الأنيميشن
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    // تهيئة GetAddAndRemove controller إذا لم يكن موجوداً
    if (!Get.isRegistered<GetAddAndRemove>()) {
      Get.put(GetAddAndRemove(), permanent: true);
    }
    controller = Get.find<GetAddAndRemove>();
    
    // إعادة حساب الأسعار عند دخول الصفحة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('🔄 TheChosen initState: refreshing totals on page load');
      controller.refreshTotals();
      
      // بدء الأنيميشن
      _fadeController.forward();
      Future.delayed(const Duration(milliseconds: 200), () {
        _slideController.forward();
      });
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TheChosen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // إعادة حساب الأسعار عند تحديث widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('🔄 TheChosen didUpdateWidget: refreshing totals');
      controller.refreshTotals();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // مطلوب للـ AutomaticKeepAliveClientMixin

    // الحصول على أبعاد الشاشة لاستخدامها في تحديد أحجام العناصر
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8F9FA),
              Color(0xFFE9ECEF),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // القسم العلوي: شريط العنوان المحسن
              FadeTransition(
                opacity: _fadeAnimation,
                child: _buildModernHeader(height, width),
              ),
              
              // المحتوى الرئيسي مع تخطيط محسن
              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildMainContent(height, width),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// بناء المحتوى الرئيسي مع تخطيط محسن
  Widget _buildMainContent(double height, double width) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // قسم عرض قائمة العناصر (السلة) - زيادة الحجم
          Expanded(
            flex: 7, // زيادة من 5 إلى 7 (70% من المساحة المتاحة)
            child: _buildCartItemsSection(width),
          ),
          
          const SizedBox(height: 8),
          
          // قسم عرض إجمالي السعر وزر إرسال الطلب - تقليل الحجم
          Expanded(
            flex: 3, // تقليل من 5 إلى 3 (30% من المساحة المتاحة)
            child: SendAndTotalPrice(uid: widget.uid),
          ),
        ],
      ),
    );
  }

  /// بناء الشريط العلوي المحسن والمضغوط - تقليل بنسبة 37%
  Widget _buildModernHeader(double height, double width) {
    return Container(
      height: height * 0.076, // تقليل من 0.12 إلى 0.076 (تقليل بنسبة 37%)
      margin: const EdgeInsets.all(12), // تقليل المارجن أيضاً
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF667EEA),
            Color(0xFF764BA2),
          ],
        ),
        borderRadius: BorderRadius.circular(16), // تقليل البوردر ريديوس
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.3),
            blurRadius: 12, // تقليل البلور
            offset: const Offset(0, 3), // تقليل الأوفست
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // تقليل البادينج
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6), // تقليل البادينج
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.shopping_cart_rounded,
                    color: Colors.white,
                    size: 18, // تقليل حجم الأيقونة
                  ),
                ),
                const SizedBox(width: 8), // تقليل المسافة
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'سلة التسوق',
                      style: TextStyle(
                        fontSize: width / 22, // تقليل حجم الخط
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Obx(() => Text(
                      '${controller.totalCartItemCount.value} منتج',
                      style: TextStyle(
                        fontSize: width / 36, // تقليل حجم الخط
                        color: Colors.white70,
                      ),
                    )),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(6), // تقليل البادينج
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: Colors.white,
                size: 16, // تقليل حجم الأيقونة
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء قسم عناصر السلة المحسن والمضغوط مع أنيميشن احترافي
  Widget _buildCartItemsSection(double width) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.2),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutCubic,
      )),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _fadeController,
          curve: Interval(0.3, 1.0, curve: Curves.easeInOut),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                spreadRadius: 3,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: const Color(0xFF667EEA).withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: -5,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                // عنوان القسم مع أنيميشن
                _buildAnimatedSectionHeader(width),
                // قائمة المنتجات مع أنيميشن
                Expanded(
                  child: _buildAnimatedProductsList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// بناء عنوان القسم مع أنيميشن
  Widget _buildAnimatedSectionHeader(double width) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-0.3, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Interval(0.4, 0.8, curve: Curves.easeOutBack),
      )),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.grey[50]!,
              Colors.grey[100]!,
              Colors.grey[50]!,
            ],
          ),
          border: Border(
            bottom: BorderSide(
              color: const Color(0xFF667EEA).withOpacity(0.1),
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            // أيقونة مع أنيميشن دوران
            AnimatedBuilder(
              animation: _slideController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _slideController.value * 0.5,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF667EEA),
                          Color(0xFF764BA2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF667EEA).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.shopping_bag_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            // النص مع أنيميشن تدرج
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 600),
              style: TextStyle(
                fontSize: width / 26,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              child: const Text('المنتجات المختارة'),
            ),
            const Spacer(),
            // عداد المنتجات مع أنيميشن
            Obx(() => AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: child,
                  );
                },
                child: Text(
                  '${controller.totalCartItemCount.value}',
                  key: ValueKey(controller.totalCartItemCount.value),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  /// بناء قائمة المنتجات مع أنيميشن
  Widget _buildAnimatedProductsList() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.1),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey('products_list_${DateTime.now().millisecondsSinceEpoch}'),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.grey[50]!.withOpacity(0.3),
            ],
          ),
        ),
        child: StreamListOfItem(),
      ),
    );
  }
}

