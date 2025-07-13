import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../GetXController/GetAddAndRemove.dart';
import '../theme/cart_theme.dart';

/// ودجة محسنة لعرض أزرار زيادة ونقصان الكمية مع عرض القيمة الحالية.
/// يتم تمرير معرف المستند وعنصر السلة وحالة العرض (isOfer).
class AddAndRemove extends StatefulWidget {
  final String uidOfDoc;
  final String uidItem;
  final bool isOfer;
  final int number;
  final String uidAdd;

  const AddAndRemove({
    super.key,
    required this.uidItem,
    required this.uidOfDoc,
    required this.isOfer,
    required this.number,
    required this.uidAdd,
  });

  @override
  State<AddAndRemove> createState() => _AddAndRemoveState();
}

class _AddAndRemoveState extends State<AddAndRemove>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: CartTheme.quickAnimationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _animateButton() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    // الحصول على أبعاد الشاشة
    final double hi = MediaQuery.of(context).size.height;
    final double wi = MediaQuery.of(context).size.width;

    // استخدام GetBuilder لمراقبة حالة المتحكم GetAddAndRemove
    return GetBuilder<GetAddAndRemove>(
      builder: (controller) {
        return AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(CartTheme.borderRadius),
                  border: Border.all(
                    color: CartTheme.primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // زر النقصان
                    _buildQuantityButton(
                      icon: Icons.remove_rounded,
                      onTap: () => _decrementQuantity(controller),
                      enabled: widget.number > 1,
                      isDecrement: true,
                    ),
                    // عرض الكمية الحالية
                    _buildQuantityDisplay(wi),
                    // زر الزيادة
                    _buildQuantityButton(
                      icon: Icons.add_rounded,
                      onTap: () => _incrementQuantity(controller),
                      enabled: true,
                      isDecrement: false,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// بناء زر الكمية
  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool enabled,
    required bool isDecrement,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled && !_isLoading ? onTap : null,
        borderRadius: BorderRadius.circular(CartTheme.smallBorderRadius),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: enabled 
                ? (isDecrement 
                    ? CartTheme.errorColor.withOpacity(0.1)
                    : CartTheme.primaryColor.withOpacity(0.1))
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(CartTheme.smallBorderRadius),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      CartTheme.primaryColor,
                    ),
                  ),
                )
              : Icon(
                  icon,
                  size: 18,
                  color: enabled
                      ? (isDecrement 
                          ? CartTheme.errorColor
                          : CartTheme.primaryColor)
                      : Colors.grey[400],
                ),
        ),
      ),
    );
  }

  /// بناء عرض الكمية
  Widget _buildQuantityDisplay(double wi) {
    return Container(
      constraints: const BoxConstraints(minWidth: 40),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        '${widget.number}',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: wi / 24,
          fontWeight: FontWeight.w600,
          color: CartTheme.textGrey,
        ),
      ),
    );
  }

  /// زيادة الكمية
  Future<void> _incrementQuantity(GetAddAndRemove controller) async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    _animateButton();
    
    try {
      await controller.incrementItem(
        uidItem: widget.uidItem,
        uidOfDoc: widget.uidOfDoc,
        isOfer: widget.isOfer,
        uidAdd: widget.uidAdd,
      );
      
      // إشعار بصري للنجاح
      _showSuccessFeedback();
    } catch (e) {
      _showErrorSnackbar('حدث خطأ أثناء زيادة الكمية: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// نقصان الكمية
  Future<void> _decrementQuantity(GetAddAndRemove controller) async {
    if (_isLoading || widget.number <= 1) return;
    
    setState(() => _isLoading = true);
    _animateButton();
    
    try {
      await controller.decrementItem(
        uidItem: widget.uidItem,
        uidOfDoc: widget.uidOfDoc,
        isOfer: widget.isOfer,
        uidAdd: widget.uidAdd,
      );
      
      // إشعار بصري للنجاح
      _showSuccessFeedback();
    } catch (e) {
      _showErrorSnackbar('حدث خطأ أثناء تقليل الكمية: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// عرض إشعار الخطأ
  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'خطأ',
      message,
      backgroundColor: CartTheme.errorColor,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: CartTheme.smallBorderRadius,
      icon: const Icon(
        Icons.error_outline,
        color: Colors.white,
      ),
    );
  }

  /// عرض تأثير بصري للنجاح
  void _showSuccessFeedback() {
    // يمكن إضافة تأثير بصري هنا مثل اهتزاز خفيف أو لون مؤقت
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم تحديث الكمية بنجاح'),
          backgroundColor: CartTheme.successColor,
          duration: const Duration(milliseconds: 1000),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CartTheme.smallBorderRadius),
          ),
        ),
      );
    }
  }
}
















