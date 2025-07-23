import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/brand_filter_controller.dart';
import '../controllers/barcode_filter_controller.dart';
import 'brand_filter_widget.dart';

class AnimatedFilterContainer extends StatefulWidget {
  final bool isVisible;
  final VoidCallback onClose;

  const AnimatedFilterContainer({
    super.key,
    required this.isVisible,
    required this.onClose,
  });

  @override
  State<AnimatedFilterContainer> createState() =>
      _AnimatedFilterContainerState();
}

class _AnimatedFilterContainerState extends State<AnimatedFilterContainer>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(AnimatedFilterContainer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _fadeController.forward();
        _slideController.forward();
      } else {
        _fadeController.reverse();
        _slideController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(20),
            shadowColor: theme.primaryColor.withValues(alpha: 0.3),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.cardColor,
                    theme.cardColor.withValues(alpha: 0.95),
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Header مع انيميشن
                  _buildAnimatedHeader(theme),

                  const SizedBox(height: 20),

                  // محتوى الفلاتر
                  const BrandFilterWidget(),

                  const SizedBox(height: 16),

                  // أزرار التحكم
                  _buildControlButtons(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader(ThemeData theme) {
    return Row(
      children: [
        // أيقونة متحركة
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 800),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.primaryColor,
                      theme.primaryColor.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(Icons.tune, color: Colors.white, size: 28),
              ),
            );
          },
        ),

        const SizedBox(width: 16),

        // النص مع تأثير الكتابة
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'فلاتر البحث المتقدمة',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
              Text(
                'اختر الفلتر المناسب لك',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textTheme.bodyMedium?.color?.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
            ],
          ),
        ),

        // زر الإغلاق مع انيميشن
        InkWell(
          onTap: widget.onClose,
          borderRadius: BorderRadius.circular(25),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(
              Icons.keyboard_arrow_up,
              color: theme.primaryColor,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlButtons(ThemeData theme) {
    final brandCtrl = Get.find<BrandFilterController>();
    final barcodeCtrl = Get.find<BarcodeFilterController>();

    return Row(
      children: [
        // زر مسح جميع الفلاتر
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              brandCtrl.deactivateBrandModeAndClearMemory();
              barcodeCtrl.clearCurrentBarcode();
            },
            icon: Icon(Icons.clear_all),
            label: Text('مسح الكل'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.primaryColor,
              side: BorderSide(
                color: theme.primaryColor.withValues(alpha: 0.3),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // زر إغلاق الفلاتر
        Expanded(
          child: ElevatedButton.icon(
            onPressed: widget.onClose,
            icon: Icon(Icons.check),
            label: Text('تطبيق'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
