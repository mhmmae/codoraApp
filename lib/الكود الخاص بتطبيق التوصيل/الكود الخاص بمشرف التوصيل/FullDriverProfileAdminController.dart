// FullDriverProfileAdminController.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // For Get.defaultDialog context if needed
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../XXX/xxx_firebase.dart';
import '../الكود الخاص بعامل/DeliveryDriverModel.dart';
import 'CompanyAdminDashboardController.dart';
import 'CompanyDriversListScreen.dart';
import 'DeliveryTaskModel.dart';

class FullDriverProfileAdminController extends GetxController {
  final String driverId; // يتم تمريرها من الـ Binding
  FullDriverProfileAdminController({required this.driverId});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Rxn<DeliveryDriverModel> driverProfile = Rxn<DeliveryDriverModel>(null);
  final RxList<DeliveryTaskModel> completedTasks = <DeliveryTaskModel>[].obs;
  final RxList<DeliveryTaskModel> ongoingOrFailedTasks = <DeliveryTaskModel>[].obs; // مهام حالية أو فاشلة

  final RxBool isLoadingProfile = true.obs;
  final RxBool isLoadingTasks = false.obs; // يبدأ false، يتم تفعيله عند جلب المهام
  final RxString errorMessage = ''.obs;

  // للتحكم في حقل سبب التعليق/الرفض
  final TextEditingController statusReasonController = TextEditingController();


  @override
  void onInit() {
    super.onInit();
    if (driverId.isEmpty) {
      errorMessage.value = "خطأ: لم يتم توفير معرف السائق.";
      isLoadingProfile.value = false;
      debugPrint("[FULL_DRIVER_PROFILE_CTRL] Error: Driver ID is empty in onInit.");
      return;
    }
    fetchAllDriverData();
  }

  Future<void> fetchAllDriverData() async {
    isLoadingProfile.value = true; // التحميل الشامل عند جلب كل شيء
    await Future.wait([
      fetchDriverFullProfile(),
      fetchDriverTaskHistory(), // يمكنك تقسيمها إذا أردت
    ]);
    isLoadingProfile.value = false;
  }


  Future<void> fetchDriverFullProfile() async {
    // isLoadingProfile.value = true; // إذا كنت تجلبها بشكل منفصل
    errorMessage.value = '';
    try {
      debugPrint("[FULL_DRIVER_PROFILE_CTRL] Fetching profile for driver: $driverId");
      DocumentSnapshot doc = await _firestore
          .collection(FirebaseX.deliveryDriversCollection)
          .doc(driverId)
          .get();

      if (doc.exists && doc.data() != null) {
        driverProfile.value = DeliveryDriverModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        debugPrint("[FULL_DRIVER_PROFILE_CTRL] Profile fetched: ${driverProfile.value?.name}");
      } else {
        throw Exception("لم يتم العثور على ملف السائق بالمعرف: $driverId");
      }
    } catch (e, s) {
      debugPrint("[FULL_DRIVER_PROFILE_CTRL] Error fetching driver profile: $e\n$s");
      errorMessage.value = "خطأ في جلب ملف السائق: ${e.toString()}";
    } finally {
      // isLoadingProfile.value = false; // إذا كنت تجلبها بشكل منفصل
    }
  }

  Future<void> fetchDriverTaskHistory() async {
    isLoadingTasks.value = true;
    try {
      debugPrint("[FULL_DRIVER_PROFILE_CTRL] Fetching task history for driver: $driverId");
      // جلب المهام المكتملة
      final snapshotCompleted = await _firestore
          .collection(FirebaseX.deliveryTasksCollection)
          .where('assignedToDriverId', isEqualTo: driverId)
          .where('status', isEqualTo: deliveryTaskStatusToString(DeliveryTaskStatus.delivered))
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();
      completedTasks.assignAll(
          snapshotCompleted.docs.map((doc) => DeliveryTaskModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>)).toList()
      );
      debugPrint("[FULL_DRIVER_PROFILE_CTRL] Fetched ${completedTasks.length} completed tasks.");

      // جلب المهام الأخرى (الحالية، الفاشلة، الملغاة من قبل السائق - إذا أردت)
      final snapshotOthers = await _firestore
          .collection(FirebaseX.deliveryTasksCollection)
          .where('assignedToDriverId', isEqualTo: driverId)
          .where('status', whereNotIn: [deliveryTaskStatusToString(DeliveryTaskStatus.delivered)])
          .orderBy('createdAt', descending: true)
          .limit(10) // مثال
          .get();
      ongoingOrFailedTasks.assignAll(
          snapshotOthers.docs.map((doc) => DeliveryTaskModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>)).toList()
      );
      debugPrint("[FULL_DRIVER_PROFILE_CTRL] Fetched ${ongoingOrFailedTasks.length} other tasks.");

    } catch (e, s) {
      debugPrint("[FULL_DRIVER_PROFILE_CTRL] Error fetching task history: $e\n$s");
      // يمكنك عرض رسالة خطأ بسيطة للمستخدم إذا فشل جلب المهام
    } finally {
      isLoadingTasks.value = false;
    }
  }

  // دالة لتغيير حالة حساب السائق (معتمد، معلق، محذوف من الشركة)
  Future<void> updateDriverAccountStatus(DriverApplicationStatus newStatus, {String? reason}) async {
    if (driverProfile.value == null) return;

    // استخدام مؤشر تحميل مؤقت للفعل
    final RxBool isUpdatingStatus = true.obs;
    Get.dialog(Obx(()=> isUpdatingStatus.value ? Center(child: CircularProgressIndicator()) : SizedBox.shrink()), barrierDismissible: false);


    try {
      Map<String, dynamic> updateData = {
        'applicationStatus': driverApplicationStatusToString(newStatus),
        'applicationStatusUpdatedAt': FieldValue.serverTimestamp(),
        // يمكن أيضًا تحديث updatedAt العام للمستند
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (newStatus == DriverApplicationStatus.approved) {
        updateData['rejectionReason'] = FieldValue.delete(); // إزالة سبب الرفض
        // approvedCompanyId يجب أن يكون موجودًا بالفعل إذا وصل لهذه المرحلة كسائق للشركة
      } else if (newStatus == DriverApplicationStatus.suspended || newStatus == DriverApplicationStatus.rejected) {
        if (reason != null && reason.isNotEmpty) {
          updateData['rejectionReason'] = reason; // يمكن استخدام نفس الحقل لسبب التعليق أو الرفض
        }
        if(newStatus == DriverApplicationStatus.rejected){ // عند الرفض الكامل من الشركة
          updateData['approvedCompanyId'] = FieldValue.delete(); // إزالة من الشركة
          updateData['availabilityStatus'] = "offline"; // جعله أوفلاين
          updateData['currentTaskId'] = FieldValue.delete(); // مسح المهمة الحالية
        }
      } else if (newStatus == DriverApplicationStatus.removed_by_company) {
        updateData['approvedCompanyId'] = FieldValue.delete(); // إزالة الارتباط بالشركة
        updateData['rejectionReason'] = reason ?? "تمت الإزالة بواسطة إدارة الشركة";
        updateData['availabilityStatus'] = "offline";
        updateData['currentTaskId'] = FieldValue.delete();
      }


      await _firestore
          .collection(FirebaseX.deliveryDriversCollection)
          .doc(driverId)
          .update(updateData);

      // تحديث الملف الشخصي محليًا لتعكس التغيير فورًا
      await fetchDriverFullProfile();
      // أيضًا، قد تحتاج لإعلام CompanyDriversListController بتحديث هذا السائق إذا كانت القائمة معروضة

      if (Get.isRegistered<CompanyDriversListController>()) {
        final listController = Get.find<CompanyDriversListController>();
        // تأكد أن السائق الذي تم تعديله هو جزء من نفس companyId الخاص بـ listController
        if (driverProfile.value != null && listController.companyId == driverProfile.value!.approvedCompanyId) {
          // إذا تمت إزالة السائق من الشركة، فقد لا تحتاج لتحديثه هنا لأنه سيختفي من القائمة تلقائيًا
          // عند إعادة تحميل القائمة، لكن إذا غيرت حالته (مثل معلق)، هذا جيد.
          // إذا كان status هو removed_by_company، ربما الأفضل هو listController.fetchCompanyDrivers()
          if (newStatus != DriverApplicationStatus.removed_by_company &&
              newStatus != DriverApplicationStatus.rejected) { // لا تحاول تحديثه في القائمة إذا تم رفضه/إزالته، دعه يُحذف عند إعادة الجلب
            await listController.updateDriverInListAfterEdit(driverId); // <--- استخدم الاسم الصحيح للدالة
          } else {
            await listController.fetchCompanyDrivers(showLoadingIndicator: false); // إذا أُزيل/رُفض، أعد جلب الكل
          }

        } else if (driverProfile.value != null &&
            (newStatus == DriverApplicationStatus.removed_by_company || newStatus == DriverApplicationStatus.rejected) &&
            listController.companyId == driverProfile.value!.approvedCompanyId /* كان approvedCompanyId قبل الحذف */ ) {
          // إذا تمت إزالته/رفضه وكان في السابق يتبع هذه الشركة، أعد جلب القائمة لإزالته
          await listController.fetchCompanyDrivers(showLoadingIndicator: false);
        }
      }


      Get.back(); // أغلق مؤشر التحميل
      Get.snackbar("تم التحديث", "تم تحديث حالة السائق بنجاح.",
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e, s) {
      if(Get.isDialogOpen ?? false) Get.back(); // أغلق مؤشر التحميل
      debugPrint("[FULL_DRIVER_PROFILE_CTRL] Error updating driver status: $e\n$s");
      Get.snackbar("خطأ", "فشل تحديث حالة السائق: ${e.toString()}", backgroundColor: Colors.red);
    } finally {
      isUpdatingStatus.value = false; // للتأكد فقط إذا لم يتم إغلاق الحوار لسبب ما
    }
  }



  // In FullDriverProfileAdminController.dart

// In FullDriverProfileAdminController.dart

// ... (imports and other controller parts) ...

  Future<String?> _navigateToReassignTaskScreen(BuildContext context, DeliveryTaskModel taskToReassign, String currentCompanyId) async {
    debugPrint("[DRIVER_MGMT] Navigating to reassign task: ${taskToReassign.taskId}");
    // افترض أن لديك شاشة/مسار لاختيار سائق
    // ستحتاج هذه الشاشة للوصول إلى قائمة السائقين المتوفرين للشركة الحالية
    // ويمكنها إرجاع UID السائق المختار.
    // Get.to(() => ReassignDriverScreen(task: taskToReassign, companyId: currentCompanyId));
    // أو باستخدام مسار مسمى:
    final dynamic result = await Get.toNamed(
        '/admin/reassign-task/${taskToReassign.taskId}', // مرر taskId
        arguments: {'companyId': currentCompanyId} // مرر companyId كـ argument
    );
    if (result is String && result.isNotEmpty) {
      return result; // UID للسائق الجديد
    }
    return null;
  }


  Future<void> removeDriverFromCompany(BuildContext context, String driverUid, String driverName, String currentCompanyId, {String? reason}) async {
    DeliveryTaskModel? activeTask;
    String? activeTaskId = driverProfile.value?.currentFocusedTaskId;

    if (activeTaskId != null && activeTaskId.isNotEmpty) {
      try {
        DocumentSnapshot taskDoc = await _firestore.collection(FirebaseX.deliveryTasksCollection).doc(activeTaskId).get();
        if (taskDoc.exists) {
          activeTask = DeliveryTaskModel.fromFirestore(taskDoc as DocumentSnapshot<Map<String, dynamic>>);
        }
      } catch (e) { /* ... */ }
    }

    bool shouldProceedWithRemoval = false;
    String? newDriverIdForActiveTask; // لتخزين UID السائق الجديد إذا تم اختياره

    // --- بناء قائمة الأزرار للحوار ---
    List<Widget> dialogActions = [];
    dialogActions.add(TextButton(onPressed: () => Get.back(result: {'proceed': false}), child: const Text("إلغاء")));
    dialogActions.add(ElevatedButton(
      onPressed: () => Get.back(result: {'proceed': true, 'reassignNow': false}), // المتابعة بدون إعادة تعيين الآن
      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade300),
      child: const Text("تأكيد الإزالة (بدون إعادة تعيين المهمة)"),
    ));

    // أضف زر إعادة التعيين فقط إذا كانت هناك مهمة نشطة بالفعل وتحتاج لتدخل
    bool isActiveTaskNeedingReassignment = activeTask != null &&
        (activeTask.status == DeliveryTaskStatus.en_route_to_pickup ||
            activeTask.status == DeliveryTaskStatus.picked_up_from_seller ||
            activeTask.status == DeliveryTaskStatus.out_for_delivery_to_buyer ||
            activeTask.status == DeliveryTaskStatus.at_buyer_location ||
            activeTask.status == DeliveryTaskStatus.driver_assigned);

    if (isActiveTaskNeedingReassignment) {
      dialogActions.add(ElevatedButton(
        onPressed: () async {
          Get.back(result: {'proceed': true, 'reassignNow': true}); // أغلق الحوار الأول بنية إعادة التعيين
        },
        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade600),
        child: const Text("إزالة وإعادة تعيين المهمة الآن"),
      ));
    }

    // --- عرض الحوار ---
    final dynamic dialogResult = await Get.dialog<Map<String, bool>>(
      AlertDialog(
        title: Text("تأكيد إزالة السائق: $driverName"),
        content: SingleChildScrollView( // لتجنب overflow إذا كان النص طويلاً
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("هل أنت متأكد من إزالة هذا السائق من شركتك؟ سيتم تغيير حالته إلى 'مُزال من الشركة' وسيتم تسجيل هذا الإجراء."),
              if (isActiveTaskNeedingReassignment) ...[
                const Divider(height: 20),
                Text("تنبيه: هذا السائق لديه مهمة نشطة حاليًا!", style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                Text("المهمة: ${activeTask.orderId}"),
                Text("الحالة: ${deliveryTaskStatusToString(activeTask.status).replaceAll('_', ' ')}"),
                const SizedBox(height: 10),
                const Text("إذا اخترت 'إزالة وإعادة تعيين المهمة الآن'، سيتم نقلك لاختيار سائق بديل."),
                const Text("إذا اخترت 'تأكيد الإزالة فقط'، ستصبح المهمة غير معينة وتحتاج لتدخل يدوي لاحقًا."),
              ] else if (activeTask != null) ...[ // <--- استخدم `...` هنا أيضًا إذا كان هناك أكثر من widget
                // أو ضع الويدجتات مباشرة بدون `...` إذا كانت جزءًا من القائمة
                const Divider(height: 20),
                Text("معلومة: السائق مرتبط بالمهمة ${activeTask.orderId} (حالة: ${deliveryTaskStatusToString(activeTask.status).replaceAll('_', ' ')}). سيتم فك ارتباطه منها إذا استمرت الإزالة."),
              ]
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: dialogActions,
      ),
      barrierDismissible: false,
    );

    if (dialogResult == null || dialogResult['proceed'] != true) {
      debugPrint("[DRIVER_MGMT] Driver removal cancelled or dialog dismissed.");
      return; // المستخدم ألغى
    }

    bool reassignNow = dialogResult['reassignNow'] ?? false;

    if (reassignNow && activeTask != null) {
      newDriverIdForActiveTask = await _navigateToReassignTaskScreen(context, activeTask, currentCompanyId);
      if (newDriverIdForActiveTask == null) {
        debugPrint("[DRIVER_MGMT] Reassignment cancelled by admin. Proceeding with unassigning task only.");
        // المستخدم ألغى اختيار سائق جديد، المهمة ستصبح غير معينة
        // أو يمكنك عرض رسالة "يجب اختيار سائق أو إلغاء الإزالة" وإيقاف العملية هنا.
        // حاليًا، سنفترض أننا سنجعلها غير معينة.
        // Get.snackbar("تنبيه", "تم إلغاء اختيار سائق بديل. المهمة ستصبح غير معينة.", duration: Duration(seconds: 4));
      } else {
        debugPrint("[DRIVER_MGMT] New driver selected for active task: $newDriverIdForActiveTask");
      }
    }

    // ----- بدء عملية الإزالة الفعلية والمعاملة -----
    final RxBool isProcessingRemoval = true.obs;
    Get.dialog(Obx(() => isProcessingRemoval.value ? const Center(child: CircularProgressIndicator()) : const SizedBox.shrink()), barrierDismissible: false);

    try {
      await _firestore.runTransaction((transaction) async {
        DocumentReference driverDocRef = _firestore.collection(FirebaseX.deliveryDriversCollection).doc(driverUid);
        // ... (تحديث مستند السائق كما كان: status, approvedCompanyId=delete, currentTaskId=delete, availabilityStatus=offline, reason)
        Map<String, dynamic> driverUpdateData = { /* ... نفس بيانات تحديث السائق ... */
          'applicationStatus': driverApplicationStatusToString(DriverApplicationStatus.removed_by_company),
          'approvedCompanyId': FieldValue.delete(), 'currentTaskId': FieldValue.delete(),
          'availabilityStatus': "offline", 'applicationStatusUpdatedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (reason != null && reason.isNotEmpty) driverUpdateData['rejectionReason'] = reason;
        transaction.update(driverDocRef, driverUpdateData);


        // معالجة المهمة النشطة
        if (activeTask != null) {
          DocumentReference activeTaskDocRef = _firestore.collection(FirebaseX.deliveryTasksCollection).doc(activeTask.taskId);
          Map<String, dynamic> taskUpdateData = {
            'updatedAt': FieldValue.serverTimestamp(),
            'taskNotesInternal': FieldValue.arrayUnion(["${DateFormat('yy/MM/dd hh:mm', 'ar').format(DateTime.now())}: تم إلغاء تعيين السائق $driverName ($driverUid)."])
          };

          if (newDriverIdForActiveTask != null && newDriverIdForActiveTask.isNotEmpty) {
            // تم اختيار سائق جديد
            DocumentSnapshot newDriverDoc = await transaction.get(_firestore.collection(FirebaseX.deliveryDriversCollection).doc(newDriverIdForActiveTask));
            String newDriverName = newDriverDoc.exists ? (newDriverDoc.data() as Map<String,dynamic>)['name'] ?? 'سائق بديل' : 'سائق بديل';

            taskUpdateData.addAll({
              'assignedToDriverId': newDriverIdForActiveTask,
              'driverName': newDriverName,
              // 'driverPhoneNumber': (newDriverDoc.data() as Map<String,dynamic>)['phoneNumber'], // إذا أردت
              'status': deliveryTaskStatusToString(DeliveryTaskStatus.driver_assigned), // أو en_route_to_pickup مباشرة
              'taskNotesInternal': FieldValue.arrayUnion(["  -> تمت إعادة التعيين إلى $newDriverName ($newDriverIdForActiveTask)."]),
            });
            // يجب تحديث مستند السائق الجديد أيضًا ليصبح on_task و currentTaskId
            transaction.update(_firestore.collection(FirebaseX.deliveryDriversCollection).doc(newDriverIdForActiveTask), {
              'currentTaskId': activeTask.taskId,
              'availabilityStatus': 'on_task'
            });

          } else {
            // لم يتم اختيار سائق جديد، اجعل المهمة غير معينة
            taskUpdateData.addAll({
              'assignedToDriverId': FieldValue.delete(),
              'driverName': FieldValue.delete(),
              'driverPhoneNumber': FieldValue.delete(),
              // --- التعديل الرئيسي هنا ---
              'status': deliveryTaskStatusToString(DeliveryTaskStatus.pending_driver_assignment),
              // --------------------------
              'taskNotesInternal': FieldValue.arrayUnion(["  -> المهمة الآن تنتظر تعيين سائق جديد من الشركة."]),
            });
          }
          transaction.update(activeTaskDocRef, taskUpdateData);
        }
      });

      if (Get.isDialogOpen ?? false) Get.back(); // أغلق مؤشر التحميل

      // ... (تحديث الواجهات المحلية و Snackbar كما كان) ...
      await fetchDriverFullProfile();
      // ... (باقي التحديثات والرسائل)
      Get.snackbar("تمت الإزالة", "تمت إزالة السائق $driverName. ${activeTask != null ? (newDriverIdForActiveTask != null ? 'وتمت إعادة تعيين مهمته.' : 'مهمته الآن تحتاج لتدخل.') : ''}",
          backgroundColor: Colors.orange.shade700, colorText: Colors.white, duration: const Duration(seconds: 4)

    );



      if (activeTask != null && newDriverIdForActiveTask == null) { // إذا كانت هناك مهمة وأصبحت تحتاج تدخل
        final result = await Get.defaultDialog<bool>(
            title: "مهمة تحتاج تدخل",
            middleText: "تم إلغاء تعيين السائق $driverName من المهمة ${activeTask.orderId}. هذه المهمة تحتاج الآن لإعادة تعيين. هل تريد الانتقال إلى قائمة المهام التي تحتاج تدخل؟",
            textConfirm: "نعم، انتقل",
            textCancel: "لاحقًا",
            confirmTextColor: Colors.white,
            onConfirm: () => Get.back(result: true),
            onCancel: () => Get.back(result: false)
        );
        if (result == true) {
          Get.toNamed('/admin/intervention-tasks');
        }
      }


    }  catch (e, s) {
    if (Get.isDialogOpen ?? false) Get.back(); // أغلق مؤشر التحميل
    debugPrint("[DRIVER_MGMT] Error removing driver $driverUid from company: $e\n$s");
    Get.snackbar("خطأ", "فشل إزالة السائق: ${e.toString()}", backgroundColor: Colors.red.shade700);
    } finally {
    isProcessingRemoval.value = false; // للتأكد من إيقاف أي مؤشر تحميل خاص بهذه العملية
    // حالات التحميل العامة للملف الشخصي يجب أن يتم تحديثها بواسطة fetchDriverFullProfile
    }
  }
  // Future<void> _sendNotificationToDriver(String driverUid, DriverApplicationStatus status, String driverName, {String? reason}) async {
  //   // ... (الكود السابق للإشعارات) ...
  //   if (title.isNotEmpty) { // تأكد أن title ليس فارغًا (لم يتم تعيينه للحالات الجديدة بعد)
  //     if (status == DriverApplicationStatus.approved) { /* ... */ }
  //     else if (status == DriverApplicationStatus.rejected) { /* ... */ }
  //     else if (status == DriverApplicationStatus.suspended) {
  //       title = "تحديث حالة حسابك";
  //       body = "مرحباً ${driverName}, تم تعليق حسابك في شركتنا مؤقتًا. السبب: ${reason ?? 'غير محدد'}.";
  //     }
  //     else if (status == DriverApplicationStatus.removed_by_company) {
  //       title = "تحديث هام بخصوص حسابك";
  //       body = "نأسف لإبلاغك، ${driverName}, بأنه قد تم إزالتك من فريق التوصيل لشركتنا. السبب: ${reason ?? 'غير محدد'}.";
  //     }
  //
  //     if (title.isNotEmpty) { // تحقق مرة أخرى بعد تعيين title
  //       // ... (منطق إرسال الإشعار الفعلي)
  //       debugPrint("[DRIVER_NOTIF] Sent status(${driverApplicationStatusToString(status)}) notification to driver $driverUid: $title");
  //     }
  //   }
  //   // ...
  // }





  void showChangeStatusDialog(BuildContext context) {
    if(driverProfile.value == null) return;

    final List<DriverApplicationStatus> possibleStatuses = [
      DriverApplicationStatus.approved,
      DriverApplicationStatus.suspended,
      DriverApplicationStatus.removed_by_company // أو "rejected" إذا كان هذا هو المعنى
    ];
    DriverApplicationStatus selectedNewStatus = driverProfile.value!.applicationStatus; // ابدأ بالحالة الحالية
    statusReasonController.clear();


    Get.defaultDialog(
      title: "تغيير حالة السائق: ${driverProfile.value!.name}",
      titleStyle: Get.textTheme.titleLarge,
      contentPadding: const EdgeInsets.all(20),
      content: StatefulBuilder( // استخدام StatefulBuilder لتحديث محتوى الحوار
          builder: (BuildContext context, StateSetter setStateDialog) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("الحالة الحالية: ${driverApplicationStatusToString(driverProfile.value!.applicationStatus).replaceAll('_', ' ')}", style: Get.textTheme.bodyLarge),
                const SizedBox(height: 15),
                Text("اختر الحالة الجديدة:", style: Get.textTheme.titleSmall),
                DropdownButtonFormField<DriverApplicationStatus>(
                  value: selectedNewStatus,
                  items: possibleStatuses.map((status) {
                    return DropdownMenuItem<DriverApplicationStatus>(
                      value: status,
                      child: Text(driverApplicationStatusToString(status).replaceAll('_', ' ')),
                    );
                  }).toList(),
                  onChanged: (DriverApplicationStatus? newValue) {
                    if (newValue != null) {
                      setStateDialog(() { // تحديث حالة الحوار فقط
                        selectedNewStatus = newValue;
                      });
                    }
                  },
                  decoration: InputDecoration(border: OutlineInputBorder()),
                ),
                if (selectedNewStatus == DriverApplicationStatus.suspended ||
                    selectedNewStatus == DriverApplicationStatus.removed_by_company ||
                    selectedNewStatus == DriverApplicationStatus.rejected) ...[ // إذا كانت الحالة تتطلب سببًا
                  const SizedBox(height: 15),
                  TextField(
                    controller: statusReasonController,
                    decoration: InputDecoration(
                      labelText: "سبب ${driverApplicationStatusToString(selectedNewStatus).replaceAll('_', ' ')} (اختياري للتعليق)",
                      hintText: "أدخل السبب هنا...",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ],
            );
          }
      ),
      confirm: ElevatedButton(
        onPressed: () {
          if(selectedNewStatus == driverProfile.value!.applicationStatus){
            Get.back(); // لا تغيير
            return;
          }
          // تحقق إضافي إذا كان السبب مطلوبًا
          if ((selectedNewStatus == DriverApplicationStatus.rejected || selectedNewStatus == DriverApplicationStatus.removed_by_company) && statusReasonController.text.trim().isEmpty){
            Get.snackbar("مطلوب", "يرجى إدخال سبب الرفض/الإزالة.", backgroundColor: Colors.orange, snackPosition: SnackPosition.TOP);
            return;
          }
          Get.back(); // أغلق حوار الاختيار
          updateDriverAccountStatus(selectedNewStatus, reason: statusReasonController.text.trim());
        },
        child: Text("حفظ التغييرات"),
      ),
      cancel: TextButton(onPressed: () => Get.back(), child: Text("إلغاء")),
    );
  }


  @override
  void onClose() {
    statusReasonController.dispose();
    super.onClose();
  }
}