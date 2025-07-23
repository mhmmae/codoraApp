import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
// للحصول على companyId إذا لزم الأمر
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../XXX/xxx_firebase.dart';
import '../../routes/app_routes.dart';
import '../../Model/DeliveryTaskModel.dart';

class TasksNeedingInterventionController extends GetxController {
  final String companyId; // يتم تمريرها من الـ Binding
  TasksNeedingInterventionController({required this.companyId});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxList<DeliveryTaskModel> tasksNeedingReassignment = <DeliveryTaskModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  StreamSubscription? _tasksSubscription;

  @override
  void onInit() {
    super.onInit();
    if (companyId.isEmpty) {
      errorMessage.value = "خطأ: معرف الشركة غير متوفر لعرض المهام.";
      isLoading.value = false;
      return;
    }
    subscribeToTasksNeedingReassignment();
  }

  void subscribeToTasksNeedingReassignment() { // أو يمكنك تسميتها subscribeToTasksAwaitingAssignment
    if (companyId.isEmpty) {
      errorMessage.value = "خطأ: معرف الشركة مطلوب لجلب المهام التي تحتاج تعيين.";
      isLoading.value = false;
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';
    debugPrint("[INTERVENTION_CTRL] Subscribing to tasks awaiting driver assignment for company: $companyId");

    _tasksSubscription?.cancel(); // إلغاء أي اشتراك سابق مهم جدًا

    // --- تحديد الحالات التي يجب أن تظهر في هذه الشاشة ---
    final List<String> targetStatusesForIntervention = [
      deliveryTaskStatusToString(DeliveryTaskStatus.pending_driver_assignment),
      deliveryTaskStatusToString(DeliveryTaskStatus.ready_for_driver_offers_wide),
      // إذا أضفت حالات أخرى تحتاج تدخل مشرف لتعيين سائق، أضفها هنا
    ];
    // ----------------------------------------------------

    _tasksSubscription = _firestore
        .collection(FirebaseX.deliveryTasksCollection)
        .where('assignedCompanyId', isEqualTo: companyId)
    // --- استخدام whereIn للتحقق من عدة حالات ---
        .where('status', whereIn: targetStatusesForIntervention)
    // ----------------------------------------
    // ترتيب المهام: الأقدم أولاً لإعطائها الأولوية في التعيين
        .orderBy('createdAt', descending: false)
        .snapshots()
        .listen((snapshot) {
      debugPrint("[INTERVENTION_CTRL] Received ${snapshot.docs.length} tasks in target statuses.");
      try {
        final tasks = snapshot.docs
            .map((doc) => DeliveryTaskModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
            .toList();
        tasksNeedingReassignment.assignAll(tasks);
      } catch (e,s){ //  معالجة خطأ محتمل أثناء fromFirestore
        debugPrint("[INTERVENTION_CTRL] Error parsing tasks from snapshot: $e\n$s");
        errorMessage.value = "خطأ في تنسيق بيانات المهام الواردة.";
        tasksNeedingReassignment.clear();
      } finally {
        isLoading.value = false; //  يتم تعيينه false حتى لو كان هناك خطأ في البارسنج
      }
    }, onError: (error, stackTrace) {
      debugPrint("[INTERVENTION_CTRL] Error listening to tasks awaiting assignment: $error\n$stackTrace");
      errorMessage.value = "خطأ في الاستماع لتحديثات المهام: $error";
      tasksNeedingReassignment.clear();
      isLoading.value = false;
    });
  }

// In TasksNeedingInterventionController.dart
  void goToReassignTaskScreen(String taskIdForReassign, String orderIdForReassign) {
    debugPrint("[INTERVENTION_CTRL] Navigating to assign screen for task: $taskIdForReassign, order: $orderIdForReassign, company: $companyId");
    Get.toNamed(
        AppRoutes.ADMIN_ASSIGN_TASK.replaceFirst(':taskId', taskIdForReassign), // استبدل :taskId في المسار
        arguments: {
          'orderId': orderIdForReassign, // للعرض في شاشة التعيين
          'isReassignment': true,
          'companyId': companyId // مرر companyId الخاص بالشركة الحالية
        }
    );
  }

  @override
  void onClose() {
    _tasksSubscription?.cancel();
    debugPrint("[INTERVENTION_CTRL] Controller closed and task subscription cancelled.");
    super.onClose();
  }
}