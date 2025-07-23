import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../addItem/addItem.dart'; // <-- استيراد شاشة إضافة المنتج
import '../../controllers/orders_controller.dart';
import '../../controllers/seller_main_controller.dart';
import '../../controllers/sales_analytics_controller.dart';
import 'sales_details_page.dart';

class SellerDashboardPage extends StatelessWidget {
  const SellerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    // الحصول على متحكم الطلبات
    final OrdersController ordersController = Get.find<OrdersController>();
    // إنشاء متحكم المبيعات
    final SalesAnalyticsController salesController = Get.put(
      SalesAnalyticsController(),
    );

    // مثال مبدئي لمحتوى لوحة التحكم
    // سنستخدم GridView لترتيب البطاقات بشكل متجاوب
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: GridView.count(
        crossAxisCount: _calculateCrossAxisCount(context),
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
        childAspectRatio: 1.1, // نسبة العرض إلى الارتفاع لتجنب الـ overflow
        children: <Widget>[
          _buildDashboardCard(
            context: context,
            icon: Icons.add_shopping_cart, // أيقونة مناسبة لإضافة منتج
            title: 'إضافة منتج جديد',
            value: 'بدء الإضافة', // نص وصفي للبطاقة
            color: Colors.blueAccent, // لون مميز للبطاقة
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddItem(),
                ), // الانتقال إلى شاشة AddItem
              );
            },
          ),
          // بطاقة الطلبات الجديدة مع Badge
          Obx(
            () => _buildDashboardCard(
              context: context,
              icon: Icons.shopping_cart_checkout,
              title: 'الطلبات الجديدة',
              value:
                  ordersController.newOrdersCount.value
                      .toString(), // العدد الفعلي من المتحكم
              color:
                  ordersController.newOrdersCount.value > 0
                      ? Colors.orange
                      : Colors.grey,
              onTap: () {
                // الانتقال إلى تبويب الطلبات
                final mainController = Get.find<SellerMainController>();
                mainController.changePageIndex(2);
              },
              showBadge: ordersController.newOrdersCount.value > 0,
              badgeCount: ordersController.newOrdersCount.value,
            ),
          ),

          _buildDashboardCard(
            context: context,
            icon: Icons.store_mall_directory,
            title: 'السوق - متاجر الجملة',
            value: 'تصفح',
            color: Colors.indigo,
            onTap: () {
              // الانتقال إلى تبويب السوق
              final mainController = Get.find<SellerMainController>();
              mainController.changePageIndex(3);
            },
          ),

          // بطاقة المبيعات التفاعلية
          Obx(
            () => _buildDashboardCard(
              context: context,
              icon: Icons.attach_money,
              title: 'إجمالي المبيعات (اليوم)',
              value:
                  salesController.isLoading.value
                      ? 'جارٍ التحميل...'
                      : '${salesController.totalDailyRevenue.value.toStringAsFixed(0)} د.ع',
              color: Colors.green,
              onTap: () {
                Get.to(() => const SalesDetailsPage());
              },
            ),
          ),
          _buildDashboardCard(
            context: context,
            icon: Icons.inventory_2,
            title: 'المنتجات المتاحة',
            value: '24', // قيمة وهمية
            color: Colors.purple,
          ),
          _buildDashboardCard(
            context: context,
            icon: Icons.trending_up,
            title: 'نمو المبيعات',
            value: '+15%', // قيمة وهمية
            color: Colors.teal,
          ),
          _buildDashboardCard(
            context: context,
            icon: Icons.star_rate,
            title: 'تقييم المتجر',
            value: '4.8', // قيمة وهمية
            color: Colors.amber,
          ),

          // بطاقة السوق الجديدة
        ],
      ),
    );
  }

  // دالة لحساب عدد الأعمدة بناءً على عرض الشاشة
  int _calculateCrossAxisCount(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1200.w) {
      return 4; // شاشات كبيرة جداً
    } else if (screenWidth > 800.w) {
      return 3; // شاشات كبيرة (تابلت أفقي، سطح مكتب)
    } else if (screenWidth > 600.w) {
      return 2; // شاشات متوسطة (تابلت عمودي)
    } else {
      return 2; // شاشات صغيرة (هاتف)
    }
  }

  // دالة لبناء كل بطاقة في لوحة التحكم
  Widget _buildDashboardCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    VoidCallback? onTap,
    bool showBadge = false,
    int badgeCount = 0,
  }) {
    return Card(
      elevation: 4.h,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: InkWell(
        onTap: onTap, // للانتقال إلى تفاصيل عند النقر (اختياري)
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.all(12.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // تقليل حجم الـ Column
            children: <Widget>[
              // أيقونة مع Badge اختياري
              Flexible(
                child:
                    showBadge && badgeCount > 0
                        ? Badge(
                          label: Text(
                            badgeCount.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: Colors.red,
                          child: Icon(icon, size: 32.sp, color: color),
                        )
                        : Icon(icon, size: 32.sp, color: color),
              ),
              SizedBox(height: 8.h),
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(height: 4.h),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
