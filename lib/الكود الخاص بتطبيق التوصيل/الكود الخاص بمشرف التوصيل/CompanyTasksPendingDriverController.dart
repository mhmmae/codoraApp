import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../XXX/xxx_firebase.dart';
import '../../routes/app_routes.dart';
import 'DeliveryTaskModel.dart';
// استورد النماذج، الثوابت، والمسارات
// ...

class CompanyTasksPendingDriverController extends GetxController {
  final String companyId;
  CompanyTasksPendingDriverController({required this.companyId});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RxList<DeliveryTaskModel> tasksToAssign = <DeliveryTaskModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  StreamSubscription? _tasksSubscription;

  @override
  void onInit() {
    super.onInit();
    if (companyId.isEmpty) { /* ... معالجة الخطأ ... */ return; }
    subscribeToTasksToAssign();
  }

  void subscribeToTasksToAssign() {
    isLoading.value = true;
    errorMessage.value = '';
    _tasksSubscription?.cancel(); // ألغِ أي اشتراك سابق

    List<String> targetStatuses = [
      deliveryTaskStatusToString(DeliveryTaskStatus.pending_driver_assignment),
      deliveryTaskStatusToString(DeliveryTaskStatus.ready_for_driver_offers_wide), // المهام التي انتهت مهلتها وتحتاج تدخل
    ];

    _tasksSubscription = _firestore
        .collection(FirebaseX.deliveryTasksCollection)
        .where('assignedCompanyId', isEqualTo: companyId)
        .where('status', whereIn: targetStatuses)
        .orderBy('createdAt', descending: false) // الأقدم أولاً (لإعطائها الأولوية)
        .snapshots()
        .listen((snapshot) {
      final tasks = snapshot.docs
          .map((doc) => DeliveryTaskModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
      tasksToAssign.assignAll(tasks);
      isLoading.value = false;
      debugPrint("[TASKS_TO_ASSIGN_CTRL] Found ${tasks.length} tasks needing driver assignment for company $companyId.");
    }, onError: (error) {
      errorMessage.value = "خطأ جلب المهام: $error";
      isLoading.value = false;
    });
  }

  void navigateToAssignScreen(DeliveryTaskModel task) {
    if (task.taskId.isEmpty) {
      Get.snackbar("خطأ", "معرف المهمة مفقود، لا يمكن المتابعة للتعيين.");
      return;
    }
    debugPrint("[TASKS_TO_ASSIGN_CTRL] Navigating to assign screen for task: ${task.taskId}, order: ${task.orderId}, company: $companyId");
    Get.toNamed(
        AppRoutes.ADMIN_ASSIGN_TASK.replaceFirst(':taskId', task.taskId), // <--- استبدال :taskId بالـ ID الفعلي
        arguments: {
          'orderId': task.orderId,        // للعرض في شاشة التعيين
          'isReassignment': false,      // هذا تعيين أولي، وليس إعادة تعيين
          'companyId': companyId,    // مرر companyId للمتحكم الجديد AssignTaskController
          // يمكنك تمرير المزيد من تفاصيل المهمة هنا إذا احتجت إليها مباشرة في شاشة التعيين
          // بدلاً من أن يقوم AssignTaskController بجلبها مرة أخرى، لكن جلبها هناك يضمن حداثتها.
          // 'taskPickupAddress': task.pickupAddressText,
          // 'taskDeliveryAddress': task.deliveryAddressText,
        }
    )?.then((resultFromAssignScreen) {
      // إذا عادت شاشة التعيين بنتيجة (مثلاً، تم التعيين بنجاح)
      // قد تحتاج لتحديث هذه القائمة (tasksToAssign) إذا لم يكن الاستماع حيًا كافيًا
      if (resultFromAssignScreen == true || (resultFromAssignScreen is Map && resultFromAssignScreen['assigned'] == true)) {
        debugPrint("[TASKS_TO_ASSIGN_CTRL] Task ${task.taskId} likely assigned. Refreshing list (if not live).");
        // إذا كان subscribeToTasksToAssign يستخدم snapshots()، ستُحدّث القائمة تلقائيًا.
        // إذا كان يستخدم get()، ستحتاج لاستدعاء subscribeToTasksToAssign() أو دالة تحديث.
        // حاليًا، مع snapshots()، يجب أن تُحدّث تلقائيًا.
        // يمكنك إضافة fetch يدوي هنا كاحتياط إذا لزم الأمر.
      }
    });
  }

  @override
  void onClose() {
    _tasksSubscription?.cancel();
    super.onClose();
  }
}