import 'package:flutter/material.dart';
import 'package:get/get.dart';



import '../../HomePage/Get-Controllar/GetChoseTheTypeOfItem.dart';
import '../../HomePage/Get-Controllar/GetSerchController.dart';
import '../../HomePage/class/FavoriteController.dart';
import '../../HomePage/class/OffersCarouselWidget.dart';
import '../../TheOrder/ChooseCategory/CategoryController.dart';
import '../../bottonBar/Get2/Get2.dart';

import 'ChatService.dart';
import 'GlobalMessageListenerService.dart';
import 'LocalDatabaseService2GetxService.dart';
import 'MessageRepository.dart';
import 'StorageService.dart';

class InitialBindings extends Bindings {
  @override
  void dependencies() async{
    // Get.lazyPut(()=>CompanyRegistrationController());
    // Get.lazyPut(()=>DriverProfileSetupController());
    // Get.lazyPut(()=>PendingCompaniesController());
    // // Get.lazyPut<CompanyAdminDashboardController>(() => CompanyAdminDashboardController());
    //
    // // ///===================================================
    // Get.lazyPut<SellerRegistrationController>(() => SellerRegistrationController());
    // ======================================================
    // تسجيل الخدمات المطلوبة في التطبيق
    Get.lazyPut(() => ChatService(), fenix: true); // fenix: true تجعلها تعيش حتى لو أُزيلت الصفحة المرتبطة بها (مفيد للخدمات)
    Get.lazyPut(() => StorageService(), fenix: true);
    Get.lazyPut(() => MessageRepository(), fenix: true); // Repository يعتمد على الخدمات أعلاه
    Get.lazyPut(() => GetSearchController(), fenix: true);
    Get.lazyPut(() => GetChoseTheTypeOfItem(), fenix: true);
    Get.lazyPut(() => FavoriteController());
    Get.lazyPut(() => CategoryController());
    Get.lazyPut(() => OffersCarouselController()); // تسجيل متحكم العروض
    Get.lazyPut(() => Get2(), fenix: true); // أو Get.put(Get2(), permanent: true);

    Get.put(GlobalMessageListenerService(), permanent: true);
    debugPrint("[Bindings] GlobalMessageListenerService registered.");

    await Get.putAsync<LocalDatabaseService>(() async {
      final service = LocalDatabaseService();
      await service.init();

      return service;
    }, permanent: true);


    // يمكنك تسجيل متحكمات عامة هنا أيضاً
    // Get.lazyPut(() => AuthController());
  }
}

