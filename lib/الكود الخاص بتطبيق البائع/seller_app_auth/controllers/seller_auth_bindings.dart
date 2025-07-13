import 'package:codora/%D8%A7%D9%84%D9%83%D9%88%D8%AF%20%D8%A7%D9%84%D8%AE%D8%A7%D8%B5%20%D8%A8%D8%AA%D8%B7%D8%A8%D9%8A%D9%82%20%D8%A7%D9%84%D8%A8%D8%A7%D8%A6%D8%B9/seller_app_auth/controllers/seller_auth_controller.dart';
import 'package:get/get.dart';

import '../../addItem/addNewItem/CategoryController1.dart';
import '../../controllers/orders_controller.dart';
import 'SellerRegistrationController.dart';

class SellerAuthBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SellerAuthController>(() => SellerAuthController());
    Get.lazyPut(()=>SellerRegistrationController());
    Get.lazyPut(() => CategoryController1(), fenix: true);
    Get.lazyPut(()=>OrdersController(), fenix: true);


  }
} 