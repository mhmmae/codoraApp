// company_registration_binding.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:codora/%D8%A7%D9%84%D9%83%D9%88%D8%AF%20%D8%A7%D9%84%D8%AE%D8%A7%D8%B5%20%D8%A8%D8%AA%D8%B7%D8%A8%D9%8A%D9%82%20%D8%A7%D9%84%D8%AA%D9%88%D8%B5%D9%8A%D9%84/%D8%A7%D9%84%D9%83%D9%88%D8%AF%20%D8%A7%D9%84%D8%AE%D8%A7%D8%B5%20%D8%A8%D8%B9%D8%A7%D9%85%D9%84/AvailableTasksController.dart';
import 'package:codora/%D8%A7%D9%84%D9%83%D9%88%D8%AF%20%D8%A7%D9%84%D8%AE%D8%A7%D8%B5%20%D8%A8%D8%AA%D8%B7%D8%A8%D9%8A%D9%82%20%D8%A7%D9%84%D8%AA%D9%88%D8%B5%D9%8A%D9%84/%D8%A7%D9%84%D9%83%D9%88%D8%AF%20%D8%A7%D9%84%D8%AE%D8%A7%D8%B5%20%D8%A8%D8%B9%D8%A7%D9%85%D9%84/DeliveryNavigationController.dart';
import 'package:codora/%D8%A7%D9%84%D9%83%D9%88%D8%AF%20%D8%A7%D9%84%D8%AE%D8%A7%D8%B5%20%D8%A8%D8%AA%D8%B7%D8%A8%D9%8A%D9%82%20%D8%A7%D9%84%D8%AA%D9%88%D8%B5%D9%8A%D9%84/%D8%A7%D9%84%D9%83%D9%88%D8%AF%20%D8%A7%D9%84%D8%AE%D8%A7%D8%B5%20%D8%A8%D8%B9%D8%A7%D9%85%D9%84/DriverDashboardController.dart';
import 'package:codora/%D8%A7%D9%84%D9%83%D9%88%D8%AF%20%D8%A7%D9%84%D8%AE%D8%A7%D8%B5%20%D8%A8%D8%AA%D8%B7%D8%A8%D9%8A%D9%82%20%D8%A7%D9%84%D8%AA%D9%88%D8%B5%D9%8A%D9%84/%D8%A7%D9%84%D9%83%D9%88%D8%AF%20%D8%A7%D9%84%D8%AE%D8%A7%D8%B5%20%D8%A8%D8%B9%D8%A7%D9%85%D9%84/MyTasksController.dart';
import 'package:codora/%D8%A7%D9%84%D9%83%D9%88%D8%AF%20%D8%A7%D9%84%D8%AE%D8%A7%D8%B5%20%D8%A8%D8%AA%D8%B7%D8%A8%D9%8A%D9%82%20%D8%A7%D9%84%D8%AA%D9%88%D8%B5%D9%8A%D9%84/%D8%A7%D9%84%D9%83%D9%88%D8%AF%20%D8%A7%D9%84%D8%AE%D8%A7%D8%B5%20%D8%A8%D9%85%D8%B4%D8%B1%D9%81%20%D8%A7%D9%84%D8%AA%D9%88%D8%B5%D9%8A%D9%84/AssignTaskController.dart';
import 'package:codora/%D8%A7%D9%84%D9%83%D9%88%D8%AF%20%D8%A7%D9%84%D8%AE%D8%A7%D8%B5%20%D8%A8%D8%AA%D8%B7%D8%A8%D9%8A%D9%82%20%D8%A7%D9%84%D8%AA%D9%88%D8%B5%D9%8A%D9%84/%D8%A7%D9%84%D9%83%D9%88%D8%AF%20%D8%A7%D9%84%D8%AE%D8%A7%D8%B5%20%D8%A8%D9%85%D8%B4%D8%B1%D9%81%20%D8%A7%D9%84%D8%AA%D9%88%D8%B5%D9%8A%D9%84/CompanyActiveTasksTrackingController.dart';
import 'package:codora/%D8%A7%D9%84%D9%83%D9%88%D8%AF%20%D8%A7%D9%84%D8%AE%D8%A7%D8%B5%20%D8%A8%D8%AA%D8%B7%D8%A8%D9%8A%D9%82%20%D8%A7%D9%84%D8%AA%D9%88%D8%B5%D9%8A%D9%84/%D8%A7%D9%84%D9%83%D9%88%D8%AF%20%D8%A7%D9%84%D8%AE%D8%A7%D8%B5%20%D8%A8%D9%85%D8%B4%D8%B1%D9%81%20%D8%A7%D9%84%D8%AA%D9%88%D8%B5%D9%8A%D9%84/CompanyAdminDashboardController.dart';
import 'package:codora/%D8%A7%D9%84%D9%83%D9%88%D8%AF%20%D8%A7%D9%84%D8%AE%D8%A7%D8%B5%20%D8%A8%D8%AA%D8%B7%D8%A8%D9%8A%D9%82%20%D8%A7%D9%84%D8%AA%D9%88%D8%B5%D9%8A%D9%84/%D8%A7%D9%84%D9%83%D9%88%D8%AF%20%D8%A7%D9%84%D8%AE%D8%A7%D8%B5%20%D8%A8%D9%85%D8%B4%D8%B1%D9%81%20%D8%A7%D9%84%D8%AA%D9%88%D8%B5%D9%8A%D9%84/CompanyDriversListScreen.dart';
import 'package:codora/%D8%A7%D9%84%D9%83%D9%88%D8%AF%20%D8%A7%D9%84%D8%AE%D8%A7%D8%B5%20%D8%A8%D8%AA%D8%B7%D8%A8%D9%8A%D9%82%20%D8%A7%D9%84%D8%AA%D9%88%D8%B5%D9%8A%D9%84/%D8%A7%D9%84%D9%83%D9%88%D8%AF%20%D8%A7%D9%84%D8%AE%D8%A7%D8%B5%20%D8%A8%D9%85%D8%B4%D8%B1%D9%81%20%D8%A7%D9%84%D8%AA%D9%88%D8%B5%D9%8A%D9%84/CompanyReportsController.dart';
import 'package:codora/%D8%A7%D9%84%D9%83%D9%88%D8%AF%20%D8%A7%D9%84%D8%AE%D8%A7%D8%B5%20%D8%A8%D8%AA%D8%B7%D8%A8%D9%8A%D9%82%20%D8%A7%D9%84%D8%AA%D9%88%D8%B5%D9%8A%D9%84/%D8%A7%D9%84%D9%83%D9%88%D8%AF%20%D8%A7%D9%84%D8%AE%D8%A7%D8%B5%20%D8%A8%D9%85%D8%B4%D8%B1%D9%81%20%D8%A7%D9%84%D8%AA%D9%88%D8%B5%D9%8A%D9%84/CompanyTaskClaimController.dart';
import 'package:codora/%D8%A7%D9%84%D9%83%D9%88%D8%AF%20%D8%A7%D9%84%D8%AE%D8%A7%D8%B5%20%D8%A8%D8%AA%D8%B7%D8%A8%D9%8A%D9%82%20%D8%A7%D9%84%D8%AA%D9%88%D8%B5%D9%8A%D9%84/%D8%A7%D9%84%D9%83%D9%88%D8%AF%20%D8%A7%D9%84%D8%AE%D8%A7%D8%B5%20%D8%A8%D9%85%D8%B4%D8%B1%D9%81%20%D8%A7%D9%84%D8%AA%D9%88%D8%B5%D9%8A%D9%84/CompanyTaskHistoryController.dart';
import 'package:codora/%D8%A7%D9%84%D9%83%D9%88%D8%AF%20%D8%A7%D9%84%D8%AE%D8%A7%D8%B5%20%D8%A8%D8%AA%D8%B7%D8%A8%D9%8A%D9%82%20%D8%A7%D9%84%D8%AA%D9%88%D8%B5%D9%8A%D9%84/%D8%A7%D9%84%D9%83%D9%88%D8%AF%20%D8%A7%D9%84%D8%AE%D8%A7%D8%B5%20%D8%A8%D9%85%D8%B4%D8%B1%D9%81%20%D8%A7%D9%84%D8%AA%D9%88%D8%B5%D9%8A%D9%84/CompanyTasksPendingDriverController.dart';
import 'package:codora/%D8%A7%D9%84%D9%83%D9%88%D8%AF%20%D8%A7%D9%84%D8%AE%D8%A7%D8%B5%20%D8%A8%D8%AA%D8%B7%D8%A8%D9%8A%D9%82%20%D8%A7%D9%84%D8%AA%D9%88%D8%B5%D9%8A%D9%84/%D8%A7%D9%84%D9%83%D9%88%D8%AF%20%D8%A7%D9%84%D8%AE%D8%A7%D8%B5%20%D8%A8%D9%85%D8%B4%D8%B1%D9%81%20%D8%A7%D9%84%D8%AA%D9%88%D8%B5%D9%8A%D9%84/DeliveryTaskDetailsAdminController.dart';
import 'package:codora/%D8%A7%D9%84%D9%83%D9%88%D8%AF%20%D8%A7%D9%84%D8%AE%D8%A7%D8%B5%20%D8%A8%D8%AA%D8%B7%D8%A8%D9%8A%D9%82%20%D8%A7%D9%84%D8%AA%D9%88%D8%B5%D9%8A%D9%84/%D8%A7%D9%84%D9%83%D9%88%D8%AF%20%D8%A7%D9%84%D8%AE%D8%A7%D8%B5%20%D8%A8%D9%85%D8%B4%D8%B1%D9%81%20%D8%A7%D9%84%D8%AA%D9%88%D8%B5%D9%8A%D9%84/DriverApplicationReviewController.dart';
import 'package:codora/%D8%A7%D9%84%D9%83%D9%88%D8%AF%20%D8%A7%D9%84%D8%AE%D8%A7%D8%B5%20%D8%A8%D8%AA%D8%B7%D8%A8%D9%8A%D9%82%20%D8%A7%D9%84%D8%AA%D9%88%D8%B5%D9%8A%D9%84/%D8%A7%D9%84%D9%83%D9%88%D8%AF%20%D8%A7%D9%84%D8%AE%D8%A7%D8%B5%20%D8%A8%D9%85%D8%B4%D8%B1%D9%81%20%D8%A7%D9%84%D8%AA%D9%88%D8%B5%D9%8A%D9%84/FullDriverProfileAdminController.dart';
import 'package:codora/%D8%A7%D9%84%D9%83%D9%88%D8%AF%20%D8%A7%D9%84%D8%AE%D8%A7%D8%B5%20%D8%A8%D8%AA%D8%B7%D8%A8%D9%8A%D9%82%20%D8%A7%D9%84%D8%AA%D9%88%D8%B5%D9%8A%D9%84/%D8%A7%D9%84%D9%83%D9%88%D8%AF%20%D8%A7%D9%84%D8%AE%D8%A7%D8%B5%20%D8%A8%D9%85%D8%B4%D8%B1%D9%81%20%D8%A7%D9%84%D8%AA%D9%88%D8%B5%D9%8A%D9%84/TasksNeedingInterventionController.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'الكود الخاص بمشرف التوصيل/CompanyRegistrationController.dart';
import 'الكود الخاص بعامل/DriverProfileSetupController.dart';
import 'الكود الخاص بمشرف التوصيل/PendingCompaniesController.dart';
// import 'path_to_controller/company_registration_controller.dart';

class CompanyRegistrationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CompanyRegistrationController>(() => CompanyRegistrationController());
    Get.lazyPut(()=>DriverProfileSetupController());
    Get.lazyPut(()=>PendingCompaniesController());
  }
}



class CompanyAdminDashboardBinding extends Bindings {
  @override
  void dependencies() {
    debugPrint("[BINDING] CompanyAdminDashboardBinding dependencies() called.");

    String companyIdToPass = "";
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      // الافتراض: UID الخاص بالمستخدم الحالي هو نفسه companyId للشركة التي يديرها.
      companyIdToPass = currentUser.uid;
      debugPrint("[BINDING] Company ID for Dashboard determined from FirebaseAuth UID: $companyIdToPass");
    } else {
      // هذا السيناريو يعني أن المستخدم غير مسجل دخوله ويحاول الوصول إلى لوحة تحكم المشرف
      // يجب أن يتم التعامل مع هذا بواسطة Route Guards أو في _initializeCompanyIdAndLoadData بالمتحكم.
      debugPrint("[BINDING] CRITICAL: Current user is null in CompanyAdminDashboardBinding. Company ID will be empty.");
      // يمكن توجيهه لشاشة تسجيل الدخول من هنا إذا أردت، أو ترك المتحكم يتعامل معها.
      // مثال:
      // WidgetsBinding.instance.addPostFrameCallback((_) {
      //   Get.offAllNamed(AppRoutes.LOGIN); // افترض وجود مسار LOGIN
      // });
    }

    Get.lazyPut<CompanyAdminDashboardController>(
          () => CompanyAdminDashboardController(currentCompanyId: companyIdToPass),
      // fenix: true // يمكنك استخدام fenix: true إذا كنت تريد أن يبقى المتحكم حتى لو تم إزالة المسار،
      // ولكنه قد لا يكون ضروريًا للوحة التحكم التي يتم الدخول إليها بشكل متكرر.
      // اتركه false (الافتراضي) لـ GetX ليقوم بالتخلص منه عند إزالة المسAR.
    );
    debugPrint("[BINDING] CompanyAdminDashboardController lazyPut scheduled with companyId: '$companyIdToPass'");
  }
}


class MyTasksBinding extends Bindings {
  @override
  void dependencies() {
    final String driverId = FirebaseAuth.instance.currentUser?.uid ?? "";
    if(driverId.isEmpty){
      debugPrint("MyTasksBinding: CRITICAL - DriverId is empty. Cannot init MyTasksController.");
    }
    Get.lazyPut<MyTasksController>(() => MyTasksController(driverId: driverId));
  }
}
class AvailableTasksBinding extends Bindings {
  @override
  void dependencies() {
    final String driverId = FirebaseAuth.instance.currentUser?.uid ?? "";
    // للحصول على companyId و initialDriverLocation، نحتاج لجلب ملف السائق
    // هذا سيجعل الـ Binding غير متزامن، أو أن المتحكم هو من يجلب هذه التفاصيل.
    // الأفضل: المتحكم يجلب هذه التفاصيل إذا لم تُمرر.
    // سنمرر فقط driverId.

    Get.lazyPut<AvailableTasksController>(() {
      // جلب companyId والموقع الأولي هنا غير مثالي للـ binding لأنه async
      // لذا، دع المتحكم يجلبهم في onInit إذا لم يكونوا موجودين كـ arguments.
      // إذا كان DriverDashboardController موجودًا ومسجلاً، يمكننا محاولة جلبهم منه.
      String companyIdFromDashboard = "";
      GeoPoint? initialLocationFromDashboard;

      if (Get.isRegistered<DriverDashboardController>()){
        final dashCtrl = Get.find<DriverDashboardController>();
        if(dashCtrl.currentDriver.value != null){
          companyIdFromDashboard = dashCtrl.currentDriver.value!.approvedCompanyId ?? "";
          initialLocationFromDashboard = dashCtrl.currentDriver.value!.currentLocation;
        }
      }
      // إذا لم نحصل عليها من الداشبورد، سيتعامل المتحكم مع جلبها.
      return AvailableTasksController(
          driverId: driverId,
          driverCompanyId: companyIdFromDashboard, // يمكن أن تكون فارغة وسيجلبها المتحكم
          initialDriverLocation: initialLocationFromDashboard // يمكن أن تكون null
      );
    });
  }
}



class DeliveryNavigationBinding extends Bindings {
  @override
  void dependencies() {
    // طريقة للحصول على taskId:
    // الطريقة 1: من Get.parameters (إذا كان المسار هو /driver/task/navigation/:taskId)
    String taskIdFromParams = Get.parameters['taskId'] ?? '';

    // الطريقة 2: من Get.arguments (إذا مررتها كـ argument عند استدعاء Get.toNamed)
    String taskIdFromArgs = "";
    if (Get.arguments is Map && Get.arguments['taskId'] != null) {
      taskIdFromArgs = Get.arguments['taskId'] as String;
    } else if (Get.arguments is String) { // إذا مررت الـ taskId مباشرة كـ argument
      taskIdFromArgs = Get.arguments as String;
    }


    final String taskIdToUse = taskIdFromParams.isNotEmpty ? taskIdFromParams : taskIdFromArgs;

    if (taskIdToUse.isEmpty) {
      debugPrint("DeliveryNavigationBinding: CRITICAL - TaskId is empty! Cannot initialize controller.");
      // يمكنك هنا التعامل مع الخطأ، مثل التوجيه أو عرض رسالة.
      // Get.offAllNamed(AppRoutes.DRIVER_DASHBOARD);
      // throw Exception("Task ID is required for DeliveryNavigationScreen");
    }

    debugPrint("DeliveryNavigationBinding: Initializing controller with TaskId: $taskIdToUse");
    Get.lazyPut<DeliveryNavigationController>(
          () => DeliveryNavigationController(taskId: taskIdToUse),
    );
  }
}




class DriverDashboardBinding extends Bindings {
  @override
  void dependencies() {
    debugPrint("[BINDING] DriverDashboardBinding dependencies() called.");

    // في معظم الحالات، سائق التوصيل يسجل دخوله بحسابه الخاص
    // ويكون الـ UID الخاص به من FirebaseAuth هو نفسه driverId.
    String driverIdToPass = "";
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      driverIdToPass = currentUser.uid;
      debugPrint("[BINDING] Driver ID for Dashboard determined from FirebaseAuth UID: $driverIdToPass");
    } else {
      // هذا السيناريو يعني أن المستخدم يحاول الوصول إلى لوحة تحكم السائق وهو غير مسجل الدخول.
      // يجب أن يتم التعامل مع هذا بواسطة Route Guards في GetX (وسيط توجيه)
      // أو أن المتحكم سيفشل في التهيئة ويعرض رسالة خطأ.
      debugPrint("[BINDING] CRITICAL: Current user is null in DriverDashboardBinding. Driver ID will be empty.");
      // هنا لا يتم توجيه، بل سيتم تمرير driverId فارغ والمتحكم يجب أن يتعامل معه
    }

    Get.lazyPut<DriverDashboardController>(
          () => DriverDashboardController(driverId: driverIdToPass),
      // fenix: true; //  قد ترغب في جعل لوحة التحكم تعيش لفترة أطول،
      //  لكن عادةً ما يكون lazyPut كافيًا وسيُعاد إنشاؤه إذا تم الانتقال إليه مرة أخرى.
    );
    debugPrint("[BINDING] DriverDashboardController lazyPut scheduled with driverId: '$driverIdToPass'");
  }
}

class TasksNeedingInterventionBinding extends Bindings {
  @override
  void dependencies() {
    String companyIdToUse = "";
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      companyIdToUse = currentUser.uid; // افترض أن UID هو companyId
      debugPrint("[INTERVENTION_BINDING] Using current user UID as companyId: $companyIdToUse");
    } else {
      // إذا لم يكن هناك مستخدم مسجل دخوله، يجب أن يتم التعامل مع هذا قبل الانتقال إلى هنا
      // أو أن يتم تمرير companyId كبارامتر
      debugPrint("[INTERVENTION_BINDING] CRITICAL: Current user is null, companyId will be empty.");
      // في هذه الحالة، onInit في المتحكم سيعرض خطأ.
    }

    // إذا كنت تمرر companyId كبارامتر للمسار
    // if (Get.parameters.containsKey('companyId')) {
    //   companyIdToUse = Get.parameters['companyId']!;
    // } else if (companyIdToUse.isEmpty) {
    //   // Handle case where it's not in parameters and also not from currentUser
    //   debugPrint("[INTERVENTION_BINDING] Error: companyId not found in parameters and user is null.");
    // }

    Get.lazyPut<TasksNeedingInterventionController>(
          () => TasksNeedingInterventionController(companyId: companyIdToUse),
    );
  }
}


class FullDriverProfileAdminBinding extends Bindings {
  @override
  void dependencies() {
    // يجب أن يكون المسار مُعرفًا ليقبل بارامتر 'driverId'
    // مثال للمسار في GetMaterialApp: GetPage(name: '/admin/driver-profile/:driverId', ...)
    final String driverId = Get.parameters['driverId'] ?? ''; // الحصول على الـ ID من بارامترات المسار
    if (driverId.isEmpty) {
      debugPrint("FullDriverProfileAdminBinding: Error - driverId is empty. Cannot initialize controller properly.");
      // يمكنك هنا رمي استثناء أو التعامل معه بطريقة أخرى
      // Get.snackbar("خطأ", "لم يتم العثور على معرف السائق.");
      // من الأفضل أن تقوم الـ Route Guard بمنع الوصول إذا كان الـ ID غير صالح
    }
    Get.lazyPut<FullDriverProfileAdminController>(
          () => FullDriverProfileAdminController(driverId: driverId),
    );
  }
}

// delivery_task_details_admin_binding.dart
class DeliveryTaskDetailsAdminBinding extends Bindings {
  @override
  void dependencies() {
    final String taskId = Get.parameters['taskId']!;
    Get.lazyPut<DeliveryTaskDetailsAdminController>(() => DeliveryTaskDetailsAdminController(taskId: taskId));
  }
}

class DriverApplicationReviewBinding extends Bindings {
  @override
  void dependencies() {
    // طريقة للحصول على companyId للمشرف الحالي
    // الطريقة الأولى: إذا كان CompanyAdminDashboardController موجودًا ويحتوي على companyId
    // تأكد أن CompanyAdminDashboardController تم وضعه (put) بشكل دائم أو يمكن الوصول إليه
    String companyIdToUse = "";
    if (Get.isRegistered<CompanyAdminDashboardController>()) {
      final dashboardCtrl = Get.find<CompanyAdminDashboardController>();
      if(dashboardCtrl.companyIdAvailable.value){
        companyIdToUse = dashboardCtrl.currentCompanyId;
      } else {
        // إذا لم يكن متاحًا من لوحة التحكم، قد يكون هذا خطأ في التدفق
        debugPrint("Error in DriverApplicationReviewBinding: CompanyId not available from DashboardController.");
        // يمكنك هنا رمي خطأ أو استخدام قيمة افتراضية إذا كان هناك منطق احتياطي
      }
    } else {
      // إذا لم يتم تسجيل CompanyAdminDashboardController
      // قد تحتاج لجلب companyId بطريقة أخرى، مثلاً من GetStorage إذا حفظته عند تسجيل الدخول
      // أو إذا كان companyId هو نفسه FirebaseAuth.instance.currentUser.uid
      companyIdToUse = FirebaseAuth.instance.currentUser?.uid ?? "";
      if(companyIdToUse.isEmpty){
        debugPrint("Error in DriverApplicationReviewBinding: Could not determine CompanyId.");
      }
    }
    Get.lazyPut<DriverApplicationReviewController>(() => DriverApplicationReviewController(companyId: companyIdToUse));
  }
}





// AssignTaskBinding.dart
class AssignTaskBinding extends Bindings {
  @override
  void dependencies() {
    final String taskIdFromRoute = Get.parameters['taskId'] ?? ''; //  يجب أن يكون اسم البارامتر في المسار هو 'taskId'
    final dynamic arguments = Get.arguments;
    final String companyIdFromArg = arguments is Map ? arguments['companyId'] as String? ?? '' : '';
    final String? orderIdForDisplayFromArg = arguments is Map ? arguments['orderId'] as String? : null;
    final bool isReassignmentFromArg = arguments is Map ? arguments['isReassignment'] as bool? ?? false : false;

    // ... (تحقق من أن taskIdFromRoute و companyIdFromArg ليستا فارغتين) ...

    Get.lazyPut<AssignTaskController>(() => AssignTaskController(
      taskId: taskIdFromRoute,
      companyId: companyIdFromArg,
      initialOrderIdForDisplay: orderIdForDisplayFromArg,
      isReassignment: isReassignmentFromArg,
    ));
  }
}




class CompanyTasksPendingDriverBinding extends Bindings {
  @override
  void dependencies() {
    String companyIdToUse = FirebaseAuth.instance.currentUser?.uid ?? ""; // افترض أن UID هو companyId
    Get.lazyPut<CompanyTasksPendingDriverController>(
          () => CompanyTasksPendingDriverController(companyId: companyIdToUse),
    );
  }
}


class CompanyTaskClaimBinding extends Bindings {
  @override
  void dependencies() {
    String companyIdToUse = FirebaseAuth.instance.currentUser?.uid ?? "";
    if (companyIdToUse.isEmpty) {
      debugPrint("CompanyTaskClaimBinding: CRITICAL - Company ID (from Auth UID) is empty.");
      // هنا يمكن توجيه المستخدم أو عرض خطأ عام قبل حتى إنشاء المتحكم
    }

    Get.lazyPut<CompanyTaskClaimController>(() => CompanyTaskClaimController(
        companyId: companyIdToUse,
        // سنقوم بإزالة companyName و companyBaseDeliveryFee من هنا،
        // وسيجلبها المتحكم في onInit الخاص به.
        companyName: "", // قيمة مؤقتة أو null إذا جعلتها Rxn
        companyBaseDeliveryFee: null
    ));
  }
}



class CompanyReportsBinding extends Bindings {
  @override
  void dependencies() {
    String companyIdToUse = "";
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      companyIdToUse = currentUser.uid; // افترض أن UID هو companyId
    } else {
      debugPrint("CompanyReportsBinding: CRITICAL - User not logged in. Company ID will be empty.");
    }
    Get.lazyPut<CompanyReportsController>(() => CompanyReportsController(companyId: companyIdToUse));
  }
}




class CompanyTaskHistoryBinding extends Bindings {
  @override
  void dependencies() {
    String companyIdToUse = "";
    // نفس منطق الحصول على companyId كما في Bindings الأخرى
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      companyIdToUse = currentUser.uid; // افتراض أن UID هو companyId
    }
    // else if (Get.isRegistered<CompanyAdminDashboardController>()) { /* ... */ }
    // else if (Get.parameters['companyId'] != null) { /* ... */ }

    if (companyIdToUse.isEmpty) {
      debugPrint("CompanyTaskHistoryBinding: CRITICAL - Company ID is empty.");
    }

    Get.lazyPut<CompanyTaskHistoryController>(
          () => CompanyTaskHistoryController(companyId: companyIdToUse),
    );
  }
}




class CompanyActiveTasksTrackingBinding extends Bindings {
  @override
  void dependencies() {
    // --- طريقة للحصول على companyId ---
    String currentCompanyIdToUse = "";

    // الخيار 1: إذا كان companyId هو UID للمشرف المسجل دخوله
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      currentCompanyIdToUse = currentUser.uid;
    } else {
      // هذا يعني أن المستخدم ليس مسجلاً دخوله، وهو أمر غير متوقع لهذه الشاشة
      debugPrint("[ACTIVE_TASKS_BINDING] Error: Current user is null. Cannot determine company ID.");
      // يمكنك هنا توجيه المستخدم إلى شاشة تسجيل الدخول أو عرض خطأ
      // حاليًا، سيتم تمرير سلسلة فارغة، والمتحكم سيعالج ذلك.
    }

    // الخيار 2: إذا كان CompanyAdminDashboardController موجودًا بالفعل و companyId تم تعيينه فيه
    // if (Get.isRegistered<CompanyAdminDashboardController>()) {
    //   final dashboardCtrl = Get.find<CompanyAdminDashboardController>();
    //   if (dashboardCtrl.companyIdAvailable.value) { // استخدم اسم المتغير الصحيح هنا
    //     currentCompanyIdToUse = dashboardCtrl.currentCompanyId;
    //   } else {
    //     debugPrint("[ACTIVE_TASKS_BINDING] Warning: CompanyId not yet available from DashboardController.");
    //   }
    // }

    // الخيار 3: إذا كنت تمرر companyId كبارامتر في المسار
    // (مثل /company/:companyId/active-tasks)
    // if (Get.parameters.containsKey('companyId')) {
    //   currentCompanyIdToUse = Get.parameters['companyId']!;
    // }

    debugPrint("[ACTIVE_TASKS_BINDING] Passing companyId to controller: '$currentCompanyIdToUse'");
    Get.lazyPut<CompanyActiveTasksTrackingController>(
            () => CompanyActiveTasksTrackingController(companyId: currentCompanyIdToUse));
  }
}

// In GetMaterialApp getPages:
// GetPage(name: '/company-registration', page: () => const CompanyRegistrationScreen(), binding: CompanyRegistrationBinding()),



class CompanyDriversListBinding extends Bindings {
@override
void dependencies() {
  String companyIdToUse = "";

  // الخيار الأفضل: الحصول على companyId من arguments عند الانتقال من Dashboard
  if (Get.arguments is Map && Get.arguments['companyId'] != null) {
    companyIdToUse = Get.arguments['companyId']!;
    debugPrint("[DRIVERS_LIST_BINDING] Company ID from arguments: $companyIdToUse");
  }
  // أو، كاحتياطي، من المستخدم الحالي (إذا كان UID هو companyId)
  else {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      companyIdToUse = currentUser.uid;
      debugPrint("[DRIVERS_LIST_BINDING] Company ID from FirebaseAuth UID: $companyIdToUse");
    } else {
      debugPrint("[DRIVERS_LIST_BINDING] CRITICAL: No companyId argument and no logged-in user.");
    }
  }
  // تجنب الاعتماد على Get.find<CompanyAdminDashboardController>() هنا
  // إذا أمكن، لأن ذلك ينشئ تبعية بين Bindings قد لا تكون ضرورية دائمًا.

  Get.lazyPut<CompanyDriversListController>(
          () => CompanyDriversListController(companyId: companyIdToUse));
}
}