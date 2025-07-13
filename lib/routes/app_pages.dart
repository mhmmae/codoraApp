import 'package:get/get.dart';
import '../الكود الخاص بتطبيق البائع/ui/pages/retail_cart_page.dart';
import '../الكود الخاص بتطبيق البائع/ui/pages/location_picker_page.dart';
import '../الكود الخاص بتطبيق البائع/ui/pages/order_confirmation_page.dart';
import '../الكود الخاص بتطبيق البائع/ui/pages/enhanced_orders_page.dart';
import '../الكود الخاص بتطبيق البائع/ui/pages/store_map_page.dart';
import '../الكود الخاص بتطبيق البائع/ui/seller_main_screen.dart';
import '../الكود الخاص بتطبيق البائع/ui/controllers/retail_cart_controller.dart';
import '../الكود الخاص بتطبيق البائع/ui/controllers/location_picker_controller.dart';
import '../الكود الخاص بتطبيق البائع/ui/controllers/order_confirmation_controller.dart';
import '../الكود الخاص بتطبيق البائع/ui/controllers/enhanced_orders_controller.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = [
    GetPage(
      name: AppRoutes.retailCart,
      page: () => const RetailCartPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<RetailCartController>(() => RetailCartController());
      }),
    ),
    GetPage(
      name: AppRoutes.locationPicker,
      page: () => const LocationPickerPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<LocationPickerController>(() => LocationPickerController());
      }),
    ),
    GetPage(
      name: AppRoutes.orderConfirmation,
      page: () => const OrderConfirmationPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<OrderConfirmationController>(() => OrderConfirmationController());
      }),
    ),
    GetPage(
      name: AppRoutes.enhancedOrders,
      page: () => const EnhancedOrdersPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<EnhancedOrdersController>(() => EnhancedOrdersController());
      }),
    ),
    GetPage(
      name: AppRoutes.sellerMain,
      page: () => SellerMainScreen(),
    ),
    GetPage(
      name: AppRoutes.storeMap,
      page: () => const StoreMapPage(),
    ),
  ];
} 