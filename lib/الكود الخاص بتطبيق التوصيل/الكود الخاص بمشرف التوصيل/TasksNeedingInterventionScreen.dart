import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../Model/DeliveryTaskModel.dart';
import 'TasksNeedingInterventionController.dart'; // لتنسيق التاريخ

// استورد المتحكم والنموذج
// import 'tasks_needing_intervention_controller.dart';
// import '../models/DeliveryTaskModel.dart'; // للتأكد من وجود enum DeliveryTaskStatus


class TasksNeedingInterventionScreen extends GetView<TasksNeedingInterventionController> {
  const TasksNeedingInterventionScreen({super.key});

  Widget _buildTaskInterventionCard(DeliveryTaskModel task, BuildContext context) {
    return Card(
      elevation: 2.5,
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 7.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("طلب رقم: ${task.orderId.length > 10 ? '${task.orderId.substring(0,10)}...' : task.orderId}",
                      style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Chip(
                    label: Text("تحتاج تدخل", style: TextStyle(color: Colors.white, fontSize: 11)),
                    backgroundColor: Colors.deepOrange.shade400,
                    avatar: Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    visualDensity: VisualDensity.compact,
                  )
                ]
            ),

            const Divider(height: 16),
            Row(children: [const Icon(Icons.storefront, size: 18, color: Colors.grey), const SizedBox(width: 6), Text("البائع: ${task.sellerName ?? 'غير محدد'}")],),
            const SizedBox(height: 4),
            Row(children: [const Icon(Icons.person_pin_outlined, size: 18, color: Colors.grey), const SizedBox(width: 6),Text("المشتري: ${task.buyerName ?? 'غير محدد'}")],),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey), const SizedBox(width: 6),
              Text("أُنشئت المهمة: ${DateFormat('yyyy/MM/dd hh:mm a', 'ar').format(task.createdAt.toDate())}", style: Get.textTheme.bodySmall),
            ],),
            // يمكنك إضافة آخر ملاحظة من 'taskNotesInternal' هنا إذا أردت
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.person_add_alt_1_outlined, size: 20),
                label: const Text("إعادة تعيين لسائق"),
                onPressed: () {
                  controller.goToReassignTaskScreen(task.taskId, task.orderId);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    // Get.put(TasksNeedingInterventionController(companyId: "YOUR_COMPANY_ID")); // Binding

    if (controller.companyId.isEmpty && !controller.isLoading.value) {
      return Scaffold(
          appBar: AppBar(title: const Text("مهام تحتاج تدخل")),
          body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                    controller.errorMessage.value.isNotEmpty
                        ? controller.errorMessage.value // استخدم رسالة الخطأ من المتحكم
                        : "خطأ فادح: لم يتمكن التطبيق من تحديد الشركة الحالية.", // رسالة احتياطية
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 16)
                ),
              )
          )
      );
    }


    return Scaffold(
      appBar: AppBar(
        title: const Text("مهام تحتاج تدخل/إعادة تعيين"),
        actions: [
          Obx(() => controller.isLoading.value && controller.tasksNeedingReassignment.isEmpty // فقط إذا كان التحميل أولي
              ? const Padding(padding: EdgeInsets.all(16), child: SizedBox(width:20, height:20, child:CircularProgressIndicator(strokeWidth: 2, color:Colors.white)))
              : IconButton(icon: const Icon(Icons.refresh), onPressed: controller.subscribeToTasksNeedingReassignment, tooltip: "تحديث")
          )
        ],
      ),
      body: Obx(() {
        // --- نعرض مؤشر التحميل إذا كان isLoading صحيحًا *والقائمة لا تزال فارغة*
        // هذا يمنع ظهور مؤشر التحميل فوق القائمة عند تحديثها بـ snapshots()
        if (controller.isLoading.value && controller.tasksNeedingReassignment.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        // --- نعرض رسالة الخطأ إذا كانت موجودة *والقائمة فارغة*
        if (controller.errorMessage.value.isNotEmpty && controller.tasksNeedingReassignment.isEmpty) {
          return Center(
              child: Padding(padding: const EdgeInsets.all(16),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(controller.errorMessage.value, style: TextStyle(color: Colors.red.shade700)),
                    const SizedBox(height:10),
                    ElevatedButton(onPressed: controller.subscribeToTasksNeedingReassignment, child: const Text("إعادة المحاولة"))
                  ])));
        }
        // --- إذا كانت القائمة فارغة بعد التحميل (ولا يوجد خطأ) ---
        if (controller.tasksNeedingReassignment.isEmpty && !controller.isLoading.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.playlist_add_check_circle_outlined, size: 70, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text("لا توجد مهام تحتاج إلى تدخل حاليًا.", style: TextStyle(fontSize: 17, color: Colors.grey)),
              ],
            ),
          );
        }
        // --- إذا كانت هناك مهام ---
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 16),
          itemCount: controller.tasksNeedingReassignment.length,
          itemBuilder: (context, index) {
            final task = controller.tasksNeedingReassignment[index];
            return _buildTaskInterventionCard(task, context); // دالة بناء البطاقة
          },
        );
      }),
    );
  }
// يمكنك إضافة دالة مساعدة للتحقق من companyId هنا إذا لم يكن المتحكم قد فعل ذلك بالفعل
// bool companyIdWasSuccessfullyIdentifiedInParent() {
//    if(Get.isRegistered<CompanyAdminDashboardController>()){
//        return Get.find<CompanyAdminDashboardController>().companyIdAvailable.value;
//    }
//    return Get.find<TasksNeedingInterventionController>().companyId.isNotEmpty; // يعتمد على كيفية تمريره
// }
}