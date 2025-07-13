import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/seller_main_controller.dart';
import '../controllers/orders_controller.dart';
import './pages/seller_dashboard_page.dart';
import './pages/order_management_page.dart';
import './pages/wholesale_market_page.dart';

class SellerMainScreen extends StatelessWidget {
  const SellerMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // استخدام Get.put لإنشاء أو إيجاد نسخة من المتحكم
    final SellerMainController controller = Get.put(SellerMainController());
    final OrdersController ordersController = Get.put(OrdersController());

    // لتحديد ما إذا كنا على منصة سطح مكتب (تقريبي)
    final bool isDesktop = MediaQuery.of(context).size.width >= 600.w;

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(_getPageTitle(controller.selectedPageIndex.value))), // عنوان متغير
        // إظهار زر القائمة (ハンバーガーメニュー) فقط على الشاشات الأصغر
        leading: isDesktop
            ? null // لا يوجد زر قائمة على سطح المكتب إذا كان الـ Drawer دائم الظهور
            : Builder(
                builder: (context) => IconButton(
                  icon: Icon(Icons.menu, size: 24.sp),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
      ),
      // استخدام Row لتضمين الـ Drawer الدائم على الشاشات الكبيرة
      body: Row(
        children: [
          if (isDesktop)
            // القائمة الجانبية الدائمة للشاشات الكبيرة
            _buildPermanentDrawer(controller, ordersController),
          // محتوى الصفحة الرئيسي يتوسع ليملأ المساحة المتبقية
          Expanded(
            child: Obx(() => _getSelectedPage(controller.selectedPageIndex.value)),
          ),
        ],
      ),
      // القائمة الجانبية المنزلقة للشاشات الصغيرة
      drawer: isDesktop ? null : _buildDrawer(controller, ordersController),
    );
  }

  // دالة لبناء القائمة الجانبية (سواء منزلقة أو دائمة)
  Widget _buildDrawerContent(SellerMainController controller, OrdersController ordersController) {
    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        Container(
          height: 140.h, // تقليل الارتفاع
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(Get.context!).primaryColor,
                Theme.of(Get.context!).primaryColor.withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(12.w), // تقليل الـ padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 25.r, // تقليل حجم الأيقونة
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Icon(
                      Icons.person,
                      size: 25.sp,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 6.h), // تقليل المسافة
                  Text(
                    'لوحة تحكم البائع',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp, // تقليل حجم الخط
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'إدارة شاملة لأعمالك',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 11.sp, // تقليل حجم الخط
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // أمثلة لعناصر القائمة مع تحسينات التصميم
        Padding(
          padding: EdgeInsets.symmetric(vertical: 4.h),
          child: ListTile(
            leading: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: controller.selectedPageIndex.value == 0 
                    ? Theme.of(Get.context!).primaryColor.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.dashboard,
                size: 20.sp,
                color: controller.selectedPageIndex.value == 0
                    ? Theme.of(Get.context!).primaryColor
                    : Colors.grey[600],
              ),
            ),
            title: Text(
              'لوحة التحكم',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: controller.selectedPageIndex.value == 0
                    ? FontWeight.w600
                    : FontWeight.normal,
                color: controller.selectedPageIndex.value == 0
                    ? Theme.of(Get.context!).primaryColor
                    : Colors.grey[800],
              ),
            ),
            selected: controller.selectedPageIndex.value == 0,
            onTap: () {
              controller.changePageIndex(0);
              if (!isDesktopFixed()) Get.back(); // أغلق الـ Drawer على الجوال
            },
          ),
        ),
        
        Padding(
          padding: EdgeInsets.symmetric(vertical: 2.h),
          child: ListTile(
            leading: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: controller.selectedPageIndex.value == 1 
                    ? Theme.of(Get.context!).primaryColor.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 20.sp,
                color: controller.selectedPageIndex.value == 1
                    ? Theme.of(Get.context!).primaryColor
                    : Colors.grey[600],
              ),
            ),
            title: Text(
              'المنتجات',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: controller.selectedPageIndex.value == 1
                    ? FontWeight.w600
                    : FontWeight.normal,
                color: controller.selectedPageIndex.value == 1
                    ? Theme.of(Get.context!).primaryColor
                    : Colors.grey[800],
              ),
            ),
            selected: controller.selectedPageIndex.value == 1,
            onTap: () {
              controller.changePageIndex(1);
              if (!isDesktopFixed()) Get.back();
            },
          ),
                 ),
         
         // عنصر الطلبات مع Badge محسن
         Padding(
           padding: EdgeInsets.symmetric(vertical: 2.h),
           child: Obx(() => ListTile(
             leading: Container(
               padding: EdgeInsets.all(8.w),
               decoration: BoxDecoration(
                 color: controller.selectedPageIndex.value == 2 
                     ? Theme.of(Get.context!).primaryColor.withOpacity(0.1)
                     : Colors.transparent,
                 borderRadius: BorderRadius.circular(8.r),
               ),
               child: _buildOrdersIconWithBadge(ordersController, controller),
             ),
             title: Text(
               'الطلبات',
               style: TextStyle(
                 fontSize: 16.sp,
                 fontWeight: controller.selectedPageIndex.value == 2
                     ? FontWeight.w600
                     : FontWeight.normal,
                 color: controller.selectedPageIndex.value == 2
                     ? Theme.of(Get.context!).primaryColor
                     : Colors.grey[800],
               ),
             ),
             selected: controller.selectedPageIndex.value == 2,
             onTap: () {
               controller.changePageIndex(2);
               if (!isDesktopFixed()) Get.back();
             },
           )),
         ),
         
         // عنصر السوق الجديد
         Padding(
           padding: EdgeInsets.symmetric(vertical: 2.h),
           child: ListTile(
             leading: Container(
               padding: EdgeInsets.all(8.w),
               decoration: BoxDecoration(
                 color: controller.selectedPageIndex.value == 3 
                     ? Theme.of(Get.context!).primaryColor.withOpacity(0.1)
                     : Colors.transparent,
                 borderRadius: BorderRadius.circular(8.r),
               ),
               child: Icon(
                 Icons.store_mall_directory,
                 size: 20.sp,
                 color: controller.selectedPageIndex.value == 3
                     ? Theme.of(Get.context!).primaryColor
                     : Colors.grey[600],
               ),
             ),
             title: Text(
               'السوق',
               style: TextStyle(
                 fontSize: 16.sp,
                 fontWeight: controller.selectedPageIndex.value == 3
                     ? FontWeight.w600
                     : FontWeight.normal,
                 color: controller.selectedPageIndex.value == 3
                     ? Theme.of(Get.context!).primaryColor
                     : Colors.grey[800],
               ),
             ),
             selected: controller.selectedPageIndex.value == 3,
             onTap: () {
               controller.changePageIndex(3);
               if (!isDesktopFixed()) Get.back();
             },
           ),
         ),
        
        // فاصل محسن
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Divider(
            thickness: 1.h,
            color: Colors.grey[300],
          ),
        ),
        
                 Padding(
           padding: EdgeInsets.symmetric(vertical: 4.h),
           child: ListTile(
             leading: Container(
               padding: EdgeInsets.all(8.w),
               decoration: BoxDecoration(
                 color: controller.selectedPageIndex.value == 4 
                     ? Theme.of(Get.context!).primaryColor.withOpacity(0.1)
                     : Colors.transparent,
                 borderRadius: BorderRadius.circular(8.r),
               ),
               child: Icon(
                 Icons.settings,
                 size: 20.sp,
                 color: controller.selectedPageIndex.value == 4
                     ? Theme.of(Get.context!).primaryColor
                     : Colors.grey[600],
               ),
             ),
             title: Text(
               'الإعدادات',
               style: TextStyle(
                 fontSize: 16.sp,
                 fontWeight: controller.selectedPageIndex.value == 4
                     ? FontWeight.w600
                     : FontWeight.normal,
                 color: controller.selectedPageIndex.value == 4
                     ? Theme.of(Get.context!).primaryColor
                     : Colors.grey[800],
               ),
             ),
             selected: controller.selectedPageIndex.value == 4,
             onTap: () {
               controller.changePageIndex(4);
               if (!isDesktopFixed()) Get.back();
             },
           ),
         ),
        
        Padding(
          padding: EdgeInsets.symmetric(vertical: 4.h),
          child: ListTile(
            leading: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.logout,
                size: 20.sp,
                color: Colors.red[600],
              ),
            ),
            title: Text(
              'تسجيل الخروج',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.red[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              // منطق تسجيل الخروج
              // FirebaseAuth.instance.signOut();
              // Get.offAll(() => SignInScreen()); // أو شاشة الدخول المناسبة
              debugPrint("تسجيل الخروج");
            },
          ),
        ),
        
        // مساحة إضافية في النهاية
        SizedBox(height: 20.h),
      ],
    );
  }

  /// بناء أيقونة الطلبات مع Badge
  Widget _buildOrdersIconWithBadge(OrdersController ordersController, SellerMainController controller) {
    return Badge(
      isLabelVisible: ordersController.newOrdersCount.value > 0,
      label: Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Text(
          ordersController.newOrdersCount.value.toString(),
          style: TextStyle(
            color: Colors.white,
            fontSize: 10.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      child: Icon(
        Icons.shopping_cart_checkout_rounded,
        size: 20.sp,
        color: controller.selectedPageIndex.value == 2
            ? Theme.of(Get.context!).primaryColor
            : Colors.grey[600],
      ),
    );
  }

  // بناء Drawer منزلق للشاشات الصغيرة
  Widget _buildDrawer(SellerMainController controller, OrdersController ordersController) {
    return Drawer(
      child: _buildDrawerContent(controller, ordersController),
    );
  }

  // بناء Drawer دائم الظهور للشاشات الكبيرة
  Widget _buildPermanentDrawer(SellerMainController controller, OrdersController ordersController) {
    return Container(
      width: 250.w, // عرض ثابت للقائمة الجانبية الدائمة
      decoration: BoxDecoration(
        color: Get.theme.canvasColor, // لون خلفية القائمة
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 1.r,
            blurRadius: 3.r,
            offset: Offset(0, 3.h), // changes position of shadow
          ),
        ],
      ),
      child: _buildDrawerContent(controller, ordersController),
    );
  }

  // دالة لتحديد الـ Widget الذي سيُعرض بناءً على الفهرس المختار
  Widget _getSelectedPage(int index) {
    switch (index) {
      case 0: // لوحة التحكم
        return const SellerDashboardPage();
      case 1: // المنتجات
        // هنا يجب أن تعرض واجهة إدارة المنتجات
        // مثال: return ProductManagementScreen();
        return Center(
          child: Text(
            'محتوى صفحة المنتجات',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      case 2: // الطلبات
        return const OrderManagementPage(); // استخدام الصفحة الجديدة
      case 3: // السوق - متاجر الجملة
        return const WholesaleMarketPage(); // الصفحة الجديدة للسوق
      case 4: // الإعدادات
        return Center(
          child: Text(
            'محتوى صفحة الإعدادات',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      default:
        return Center(
          child: Text(
            'صفحة غير معروفة',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
    }
  }

  // دالة لتحديد عنوان الصفحة بناءً على الفهرس المختار
  String _getPageTitle(int index) {
    switch (index) {
      case 0:
        return 'لوحة التحكم';
      case 1:
        return 'إدارة المنتجات';
      case 2:
        return 'إدارة الطلبات';
      case 3:
        return 'السوق - متاجر الجملة';
      case 4:
        return 'الإعدادات';
      default:
        return 'تطبيق البائع';
    }
  }

  // دالة مساعدة لتحديد ما إذا كان العرض الحالي هو لسطح مكتب مع Drawer دائم
  // يجب أن يكون السياق (context) متاحًا، أو استخدام Get.context إذا كان ذلك مناسبًا
  bool isDesktopFixed() {
    if (Get.context == null) return false; // احتياطي
    return MediaQuery.of(Get.context!).size.width >= 600.w;
  }
} 