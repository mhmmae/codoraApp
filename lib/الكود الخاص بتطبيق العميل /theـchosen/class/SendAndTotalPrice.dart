import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../GetXController/GetAddAndRemove.dart';
import '../GetXController/GetSendandtotalprice.dart';

/// ودجة عرض لإجمالي السعر مع زر إرسال الطلب.
/// تستخدم هذه الودجة متحكمي GetAddAndRemove (لعرض إجمالي السعر) و
/// Getsendandtotalprice (لتنفيذ إرسال الطلب).
class SendAndTotalPrice extends StatefulWidget {
  final String uid;

  const SendAndTotalPrice({super.key, required this.uid});

  @override
  State<SendAndTotalPrice> createState() => _SendAndTotalPriceState();
}

class _SendAndTotalPriceState extends State<SendAndTotalPrice>
    with TickerProviderStateMixin {
  late GetAddAndRemove controller;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // تهيئة الأنيميشن
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
    
    // الحصول على controller والتأكد من وجوده
    controller = Get.find<GetAddAndRemove>();
    
    // إعادة حساب الأسعار عند تحميل الويدج
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('🔥 SendAndTotalPrice initState: refreshing totals...');
      controller.refreshTotals();
      
      // بدء الأنيميشن
      _slideController.forward();
      _pulseController.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SendAndTotalPrice oldWidget) {
    super.didUpdateWidget(oldWidget);
    // إعادة حساب الأسعار عند تحديث widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('🔥 SendAndTotalPrice didUpdateWidget: refreshing totals...');
      controller.refreshTotals();
    });
  }

  @override
  Widget build(BuildContext context) {
    // الحصول على أبعاد الشاشة
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // قسم تفاصيل الفاتورة المضغوط
                      _buildCompactBillDetails(width),
                      // قسم زر الإرسال المضغوط
                      _buildCompactSubmitSection(height, width),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// بناء قسم تفاصيل الفاتورة المضغوط والمحسن
  Widget _buildCompactBillDetails(double width) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[50]!,
            Colors.grey[100]!,
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // عنوان مضغوط أكثر
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF667EEA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: Color(0xFF667EEA),
                  size: 14,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'إجمالي الطلب',
                style: TextStyle(
                  fontSize: width / 30,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // الإجمالي مع أنيميشن
          Obx(() {
            final formattedPrice = _formatPrice(controller.total.value);
            return AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: _buildAnimatedTotalRow(formattedPrice, width),
                );
              },
            );
          }),
        ],
      ),
    );
  }

  /// تنسيق الأرقام مع الفواصل
  String _formatPrice(int price) {
    final formatter = NumberFormat('#,###');
    return formatter.format(price);
  }

  /// بناء صف الإجمالي المحسن مع أنيميشن - مضغوط أكثر
  Widget _buildAnimatedTotalRow(String formattedPrice, double width) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF667EEA),
            Color(0xFF764BA2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'الإجمالي:',
            style: TextStyle(
              fontSize: width / 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Row(
            children: [
              Text(
                formattedPrice,
                style: TextStyle(
                  fontSize: width / 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'IQ',
                style: TextStyle(
                  fontSize: width / 32,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// بناء قسم زر الإرسال المضغوط والمحسن
  Widget _buildCompactSubmitSection(double height, double width) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GetBuilder<GetSendAndTotalPrice>(
        init: GetSendAndTotalPrice(uid: widget.uid),
        builder: (submitController) {
          return Obx(() => AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            child: submitController.isLoading.value
                ? _buildLoadingButton(width)
                : _buildSubmitButton(submitController, width),
          ));
        },
      ),
    );
  }

  /// بناء زر الإرسال المحسن - مضغوط أكثر
  Widget _buildSubmitButton(GetSendAndTotalPrice submitController, double width) {
    return ElevatedButton(
      onPressed: () async {
        try {
          await submitController.send();
        } catch (e) {
          Get.snackbar(
            'خطأ',
            'حدث خطأ أثناء إرسال الطلب: $e',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF667EEA),
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: const Color(0xFF667EEA).withOpacity(0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Icon(
              Icons.send_rounded,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'إرسال الطلب',
            style: TextStyle(
              fontSize: width / 28,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// بناء زر التحميل المحسن - مضغوط أكثر
  Widget _buildLoadingButton(double width) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            const Color(0xFF667EEA).withOpacity(0.7),
            const Color(0xFF764BA2).withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'جاري الإرسال...',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: width / 30,
            ),
          ),
        ],
      ),
    );
  }
}
