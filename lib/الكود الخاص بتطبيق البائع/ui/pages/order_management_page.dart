import 'package:flutter/material.dart';
import 'professional_orders_page.dart';

/// صفحة إدارة طلبات البائع
/// تعرض قائمة الطلبات وتسمح للبائع بإدارتها
class OrderManagementPage extends StatelessWidget {
  const OrderManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    // استخدام الواجهة الاحترافية الجديدة
    return const ProfessionalOrdersPage();
  }
} 