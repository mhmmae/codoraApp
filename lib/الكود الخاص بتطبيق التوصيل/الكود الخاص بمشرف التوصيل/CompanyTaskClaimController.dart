// In CompanyTaskClaimController.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../XXX/xxx_firebase.dart';
import 'CompanyAdminDashboardController.dart';
import 'CompanyTasksPendingDriverController.dart';
import 'DeliveryTaskModel.dart';

class CompanyTaskClaimController extends GetxController {
  final String companyId;
  final String companyName; // اسم الشركة (يُجلب في Binding)
  final double? companyBaseDeliveryFee; // <-- يتم تمريره من الـ Binding
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxList<DeliveryTaskModel> availableTasksToClaim = <DeliveryTaskModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;
  final RxMap<String, bool> claimingTaskMap = <String, bool>{}.obs; // taskId -> isClaiming
  StreamSubscription? _tasksSubscription;

  CompanyTaskClaimController({
    required this.companyId,
    required this.companyName, // اجعله مطلوبًا
    this.companyBaseDeliveryFee, // يمكن أن يكون اختياريًا هنا مع قيمة افتراضية إذا لم يُمرر
  });
  @override
  void onInit() {
    super.onInit();
    if (companyId.isEmpty) {
      errorMessage.value = "خطأ: معرف الشركة غير متوفر.";
      isLoading.value = false;
      return;
    }
    subscribeToAvailableTasks();
  }
  void subscribeToAvailableTasks() {
    isLoading.value = true;
    errorMessage.value = '';
    _tasksSubscription?.cancel();
    debugPrint("[TASK_CLAIM_CTRL] Subscribing to tasks for company $companyId to potentially claim.");

    _tasksSubscription = _firestore
        .collection(FirebaseX.deliveryTasksCollection)
    // الحالة الأولية للمهمة بعد موافقة البائع
        .where('status', isEqualTo: deliveryTaskStatusToString(DeliveryTaskStatus.company_pickup_request))
    // (اختياري) يمكنك إضافة فلتر حسب المحافظة إذا كان company_pickup_request عامًا
    // .where('province', whereIn: companyProfile.serviceProvinces) // إذا كانت الشركة تخدم محافظات معينة
    // (اختياري) يمكنك أيضًا استبعاد المهام التي انتهت صلاحيتها إذا كان هناك وقت انتهاء للمطالبة
        .orderBy('createdAt', descending: true) // الأحدث أولاً
        .snapshots()
        .listen((snapshot) {
      debugPrint("[TASK_CLAIM_CTRL] Received ${snapshot.docs.length} tasks with status 'company_pickup_request'.");
      final tasks = snapshot.docs
          .map((doc) => DeliveryTaskModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
      // فلتر إضافي إذا كانت المهام عامة وتحتاج لتحديد ما إذا كانت الشركة مؤهلة (مثلاً بناءً على نوع الطرد أو منطقة الخدمة)
      // .where((task) => _isCompanyEligibleForTask(task))
          .toList();
      availableTasksToClaim.assignAll(tasks);
      isLoading.value = false;
    }, onError: (error, stackTrace) {
      debugPrint("[TASK_CLAIM_CTRL] Error listening to available tasks: $error\n$stackTrace");
      errorMessage.value = "خطأ في جلب المهام المتاحة: $error";
      isLoading.value = false;
    });
  }


  Future<void> claimTask(DeliveryTaskModel taskToClaim) async {
    if (companyId.isEmpty) {       Get.snackbar("خطأ", "معرف الشركة غير صالح للمطالبة بالمهمة.");
    return; }
    claimingTaskMap[taskToClaim.taskId] = true;

    try {
      await _firestore.runTransaction((transaction) async {
        DocumentReference taskDocRef = _firestore.collection(FirebaseX.deliveryTasksCollection).doc(taskToClaim.taskId);
        DocumentSnapshot taskSnapshot = await transaction.get(taskDocRef);

        if (!taskSnapshot.exists) {          throw FirebaseException(plugin: "App", code: "TASK_NOT_FOUND", message: "المهمة لم تعد متوفرة.");
        }
        final currentTaskData = taskSnapshot.data() as Map<String, dynamic>;

        if (currentTaskData['assignedCompanyId'] != null) {
          throw FirebaseException(plugin: "App", code: "ALREADY_CLAIMED_BY_YOU", message: "لقد طالبت بهذه المهمة بالفعل.");
        }
        if(stringToDeliveryTaskStatus(currentTaskData['status']) != DeliveryTaskStatus.company_pickup_request){
          throw FirebaseException(plugin: "App", code: "TASK_ALREADY_CLAIMED", message: "عذراً، شركة أخرى طالبت بهذه المهمة للتو.");

        }

        // --- تحديد رسوم التوصيل ---
        double? feeToSet = companyBaseDeliveryFee;
        // إذا كانت المهمة نفسها لديها رسوم توصيل محددة مسبقًا (ربما من البائع أو كتقدير أولي)
        // يمكنك هنا وضع منطق لتحديد أي رسوم يجب استخدامها (رسوم الشركة أم رسوم المهمة)
        // للتبسيط، سنفترض أن رسوم الشركة هي التي تُعتمد عند المطالبة.
        if (taskToClaim.deliveryFee != null && taskToClaim.deliveryFee! > 0 && feeToSet == null) {
          // إذا لم يكن للشركة رسوم أساسية، ولكن المهمة لديها رسوم، يمكن استخدامها
          // feeToSet = taskToClaim.deliveryFee;
          // أو يمكنك عرض تنبيه بأن الشركة يجب أن تحدد رسومها.
          // حاليًا، سنعتمد بشكل أساسي على رسوم الشركة.
        }
        if (feeToSet == null) {
          debugPrint("Warning: Company base delivery fee is null for task ${taskToClaim.taskId}. Delivery fee in task will not be updated by company claim.");
          // قد ترغب في عدم تحديث deliveryFee إذا لم يكن لدى الشركة رسوم أساسية
          // أو يمكنك تعيين قيمة افتراضية أو رمي استثناء إذا كانت الرسوم إلزامية.
        }
        // -----------------------------

        transaction.update(taskDocRef, {
          'assignedCompanyId': companyId,
          'assignedCompanyName': companyName,
          'status': deliveryTaskStatusToString(DeliveryTaskStatus.pending_driver_assignment),
          'claimedByCompanyAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          // --- تحديث رسوم التوصيل في المهمة برسوم الشركة ---
          if (feeToSet != null) 'deliveryFee': feeToSet, // <-- تحديث هنا
          // -----------------------------------------------
        });
      });

      debugPrint("[TASK_CLAIM_CTRL] Task ${taskToClaim.taskId} successfully claimed by company $companyId.");
      Get.snackbar("تمت المطالبة بنجاح!", "المهمة #${taskToClaim.orderId.substring(0,6)}... أصبحت ضمن مهام شركتك. يمكنك الآن تعيين سائق لها.",
          backgroundColor: Colors.green, colorText: Colors.white, duration: const Duration(seconds: 4));

      // إزالة المهمة من القائمة المحلية (الـ Stream سيفعل ذلك تلقائيًا بسبب تغيير الحالة)
      // availableTasksToClaim.removeWhere((task) => task.taskId == taskToClaim.taskId);

      // يمكنك إبلاغ المتحكمات الأخرى إذا لزم الأمر
      if (Get.isRegistered<CompanyTasksPendingDriverController>() && Get.find<CompanyTasksPendingDriverController>().companyId == companyId) {
        // Get.find<CompanyTasksPendingDriverController>().subscribeToTasksToAssign(); // لتحديث قائمته
      }
      if (Get.isRegistered<CompanyAdminDashboardController>() && Get.find<CompanyAdminDashboardController>().currentCompanyId == companyId) {
        // Get.find<CompanyAdminDashboardController>().fetchAllDashboardData(); // تحديث لوحة التحكم
      }

    } on FirebaseException catch(fe) {
      debugPrint("[TASK_CLAIM_CTRL] Firebase error claiming task ${taskToClaim.taskId}: ${fe.code} - ${fe.message}");
      Get.snackbar("فشل المطالبة", fe.message ?? "لم نتمكن من المطالبة بهذه المهمة. حاول مرة أخرى.", backgroundColor: Colors.orange); }
    catch (e, s) {
      debugPrint("[TASK_CLAIM_CTRL] Error claiming task ${taskToClaim.taskId}: $e\n$s");
      Get.snackbar("خطأ", "فشل المطالبة بالمهمة: ${e.toString()}", backgroundColor: Colors.red);
    }
    finally { claimingTaskMap[taskToClaim.taskId] = false; }
  }
// ... (باقي المتحكم)
}