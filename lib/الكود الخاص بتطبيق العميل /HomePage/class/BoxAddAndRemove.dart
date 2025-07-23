import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../XXX/xxx_firebase.dart';
import '../Get-Controllar/Get-BoxAddAndRemover.dart'; // استورد المتحكم الصحيح

class BoxAddAndRemove extends StatelessWidget {
  final String uidItem;
  final double price; // يجب أن يكون السعر double
  final String
  name; // يبدو أن الاسم لا يستخدم هنا، يمكن إزالته إذا لم يكن ضرورياً
  final bool isOffer; // استخدام isOffer
  final String uidAdd;

  // معرف فريد لكل مثيل widget لربطه بمثيل controller خاص به
  final String _instanceDocId = const Uuid().v4();

  BoxAddAndRemove({
    super.key,
    required this.uidItem,
    required this.uidAdd,

    required this.price, // تأكد أنك تمرر double
    required this.name, //
    this.isOffer = false, // قيمة افتراضية
  });

  // دالة مساعدة لبناء أزرار التحكم
  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required BuildContext context,
    required double iconSize,
    required AddRemoveController controller, // استمر في استقبال المتحكم
    required bool isAddButton,
    bool isDisabled = false,
  }) {
    final theme = Theme.of(context);

    // ---!!! اقرأ القيمة مباشرة هنا !!!---
    // Obx الخارجي سيضمن إعادة البناء عند تغير isAnimating.value
    final bool isCurrentlyAnimating =
        isAddButton && controller.isAnimating.value;
    final Color currentIconColor =
        isCurrentlyAnimating
            ? theme
                .colorScheme
                .secondary // استخدم لون ثانوي
            : (isDisabled ? theme.disabledColor : theme.colorScheme.primary);
    // ------------------------------------

    // ---!!! أزل Obx من هنا !!!---
    return AnimatedScale(
      // --- استخدم المتغير المحسوب ---
      scale: isCurrentlyAnimating ? 1.3 : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      child: InkWell(
        onTap: isDisabled ? null : onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          // --- استخدم المتغير المحسوب ---
          child: Icon(icon, size: iconSize, color: currentIconColor),
        ),
      ),
    );
  }

  // دالة لتنسيق السعر مع فاصلة للآلاف وإزالة الأصفار غير الضرورية
  String _formatPrice(double price) {
    String priceString;
    if (price == price.toInt()) {
      priceString = price.toInt().toString();
    } else {
      priceString = price.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
    }

    // إضافة فاصلة للآلاف
    final parts = priceString.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? '.${parts[1]}' : '';

    // إضافة فاصلة كل ثلاث خانات من اليمين
    String formattedInteger = '';
    for (int i = integerPart.length - 1; i >= 0; i--) {
      formattedInteger = integerPart[i] + formattedInteger;
      if ((integerPart.length - i) % 3 == 0 && i != 0) {
        formattedInteger = ',$formattedInteger';
      }
    }

    return formattedInteger + decimalPart;
  }

  @override
  Widget build(BuildContext context) {
    final wi = MediaQuery.of(context).size.width;
    final hi = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);

    // تحديد أحجام الخطوط والأيقونات النسبية (تقليل 10%)
    final double priceFontSize =
        wi / 40; // تقليل من wi/30 إلى wi/33 (تقليل 10%)
    final double numberFontSize =
        wi / 25; // تقليل من wi/28 إلى wi/31 (تقليل 10%)
    final double defaultIconSize =
        wi / 25; // تقليل من wi/18 إلى wi/20 (تقليل 10%)

    // استخدم نفس AddRemoveController، واربطه باستخدام tag الفريد instanceDocId
    final AddRemoveController controller = Get.put(
      AddRemoveController(
        docId: _instanceDocId, // معرف المثيل لهذا العنصر في السلة
        uidItem: uidItem, // معرف المنتج الفعلي
        isOffer: isOffer,
        uidAdd: uidAdd,
      ),
      tag: _instanceDocId, // ربط Widget بـ Controller
      permanent: false, // احذفه عند إزالة الـ Widget
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // عرض السعر بالعملة مع تنسيق محسن وتصميم جميل
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.primaryColor.withOpacity(0.1),
                theme.primaryColor.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: theme.primaryColor.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withOpacity(0.1),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.attach_money_rounded,
                size: priceFontSize * 0.8,
                color: theme.primaryColor,
              ),
              Text(
                _formatPrice(price),
                style: TextStyle(
                  fontSize: priceFontSize,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(width: 4),
              Text(
                FirebaseX.currency,
                style: TextStyle(
                  fontSize: priceFontSize * 0.75,
                  fontWeight: FontWeight.w600,
                  color: theme.primaryColor.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 3),

        // العرض الشرطي: زر "إضافة إلى السلة" أو أزرار التحكم
        Obx(() {
          final bool hasItems = controller.number.value > 0;

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            child:
                hasItems
                    ? _buildQuantityControls(
                      context,
                      controller,
                      wi,
                      hi,
                      theme,
                      numberFontSize,
                      defaultIconSize,
                    )
                    : _buildAddToCartButton(context, controller, wi, hi, theme),
          );
        }),
      ],
    );
  }

  // بناء زر "إضافة إلى السلة"
  Widget _buildAddToCartButton(
    BuildContext context,
    AddRemoveController controller,
    double wi,
    double hi,
    ThemeData theme,
  ) {
    return SizedBox(
      key: const ValueKey('add_to_cart'),
      width: wi * 0.315, // تقليل من 0.35 إلى 0.315 (تقليل 10%)
      height: hi * 0.0230, // تقليل من 32 إلى 29 (تقليل 10%)
      child: ElevatedButton(
        onPressed: controller.addItem,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: theme.primaryColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_shopping_cart_rounded,
              size: 14, // تقليل من 16 إلى 14 (تقليل 10% تقريباً)
            ),
            SizedBox(width: 4),
            Text(
              'أضف للسلة',
              style: TextStyle(
                fontSize: wi / 39, // تقليل من wi/35 إلى wi/39 (تقليل 10%)
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // بناء أزرار التحكم بالكمية
  Widget _buildQuantityControls(
    BuildContext context,
    AddRemoveController controller,
    double wi,
    double hi,
    ThemeData theme,
    double numberFontSize,
    double defaultIconSize,
  ) {
    return Container(
      key: const ValueKey('quantity_controls'),
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: theme.primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.min,
        children: [
          // زر الإزالة
          _buildActionButton(
            icon: Icons.remove_circle_outline,
            onPressed:
                controller.number.value > 0 ? controller.removeItem : null,
            isDisabled: controller.number.value <= 0,
            context: context,
            iconSize: defaultIconSize * 0.8,
            controller: controller,
            isAddButton: false,
          ),

          // الرقم الحالي
          Container(
            width: wi * 0.045, // تقليل من 0.35 إلى 0.315 (تقليل 10%)
            height: hi * 0.0230, // تقليل من 32 إلى 29 (تقليل 10%)
            margin: EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${controller.number.value < 0 ? 0 : controller.number.value}',
                style: TextStyle(
                  fontSize: numberFontSize * 0.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // زر الإضافة
          _buildActionButton(
            icon: Icons.add_circle_outline,
            onPressed: controller.addItem,
            isDisabled: false,
            context: context,
            iconSize: defaultIconSize * 0.8,
            controller: controller,
            isAddButton: true,
          ),
        ],
      ),
    );
  }
}
