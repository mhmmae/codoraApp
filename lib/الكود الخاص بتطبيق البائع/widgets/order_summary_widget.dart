import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/orders_controller.dart';

/// Widget لعرض ملخص سريع للطلبات
/// يمكن استخدامه في أماكن مختلفة في التطبيق
class OrderSummaryWidget extends StatelessWidget {
  final bool showTitle;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const OrderSummaryWidget({
    super.key,
    this.showTitle = true,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<OrdersController>(
      init: OrdersController(),
      builder: (controller) {
        return Container(
          margin: margin ?? const EdgeInsets.all(8.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showTitle) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.shopping_cart_checkout_rounded,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'الطلبات الجديدة',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    
                    // عرض إحصائيات الطلبات
                    Obx(() => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatItem(
                          context,
                          'طلبات جديدة',
                          controller.newOrdersCount.value.toString(),
                          Colors.orange,
                        ),
                        _buildStatItem(
                          context,
                          'قيد المراجعة',
                          '0', // يمكن إضافة هذه الحالة لاحقاً
                          Colors.blue,
                        ),
                        _buildStatItem(
                          context,
                          'مكتملة اليوم',
                          '0', // يمكن إضافة هذه الحالة لاحقاً
                          Colors.green,
                        ),
                      ],
                    )),
                    
                    if (controller.newOrdersCount.value > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Text(
                          'لديك ${controller.newOrdersCount.value} طلب${controller.newOrdersCount.value > 1 ? 'ات' : ''} جديد${controller.newOrdersCount.value > 1 ? 'ة' : ''} في انتظار المراجعة',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// بناء عنصر إحصائية واحد
  Widget _buildStatItem(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
} 