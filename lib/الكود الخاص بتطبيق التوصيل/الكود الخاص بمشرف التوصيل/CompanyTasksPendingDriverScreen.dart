import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'CompanyTasksPendingDriverController.dart';
import '../../Model/DeliveryTaskModel.dart';
// استورد المتحكم والنماذج
// ...

class CompanyTasksPendingDriverScreen extends GetView<CompanyTasksPendingDriverController> {
  const CompanyTasksPendingDriverScreen({super.key});

// In CompanyTasksPendingDriverScreen.dart

  Widget _buildTaskToAssignCard(DeliveryTaskModel task, BuildContext context) {
    final theme = Theme.of(context);
    // تحديد إذا كانت المهمة تحتاج لتدخل عاجل (بناءً على حالتها أو وقت إنشائها)
    bool isUrgentOrOverdue = task.status == DeliveryTaskStatus.ready_for_driver_offers_wide ||
        (DateTime.now().difference(task.createdAt.toDate()).inHours > 2); // مثال: عاجلة إذا مر أكثر من ساعتين ولم تُعيّن

    return Card(
      elevation: isUrgentOrOverdue ? 3 : 2,
      margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      color: isUrgentOrOverdue ? Colors.red.shade50 : theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: isUrgentOrOverdue ? BorderSide(color: Colors.red.shade300, width: 1) : BorderSide(color: theme.dividerColor.withOpacity(0.5), width: 0.5),
      ),
      child: InkWell( // لجعل البطاقة بأكملها قابلة للنقر (اختياري)
        onTap: () => controller.navigateToAssignScreen(task),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text("طلب: ${task.orderId.length > 8 ? '${task.orderId.substring(0,8)}...' : task.orderId}",
                        style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: isUrgentOrOverdue ? Colors.red.shade700 : null)),
                  ),
                  // شريحة صغيرة لتوضيح حالة المهمة ( pending_driver_assignment أو ready_for_driver_offers_wide )
                  Chip(
                    label: Text(
                        task.status == DeliveryTaskStatus.ready_for_driver_offers_wide ? "تحتاج تعيين (مهلة ضيقة انتهت)" : "تنتظر تعيين سائق",
                        style: TextStyle(fontSize:10, color:Colors.white, fontWeight: FontWeight.w500)
                    ),
                    backgroundColor: isUrgentOrOverdue ? Colors.red.shade600 : Colors.blueGrey.shade400,
                    padding: EdgeInsets.symmetric(horizontal:6, vertical:0),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  )
                ],
              ),
              const SizedBox(height: 6),
              _buildDetailRowSmall(Icons.store_mall_directory_outlined, "البائع", task.sellerName ?? task.sellerShopName ?? 'غير محدد'),
              _buildDetailRowSmall(Icons.person_pin_circle_outlined, "المشتري", task.buyerName ?? 'غير محدد'),
              if(task.province != null && task.province!.isNotEmpty)
                _buildDetailRowSmall(Icons.public_outlined, "المحافظة", task.province),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("وقت الإنشاء: ${DateFormat('dd/MM hh:mm a', 'ar').format(task.createdAt.toDate())}", style: Get.textTheme.bodySmall?.copyWith(color:Colors.grey.shade700, fontSize: 11)),
                  ElevatedButton.icon(
                    icon: Icon(Icons.assignment_ind_outlined, size: 18),
                    label: const Text("تعيين سائق"),
                    onPressed: () => controller.navigateToAssignScreen(task), // <-- التأكد من هذا الاستدعاء
                    style: ElevatedButton.styleFrom(
                        backgroundColor: isUrgentOrOverdue ? theme.colorScheme.error : theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

// ودجة مساعدة مصغرة لعرض التفاصيل
  Widget _buildDetailRowSmall(IconData icon, String label, String? value) {
    if (value == null || value.isEmpty) return SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text("$label: ", style: Get.textTheme.bodySmall?.copyWith(color: Colors.grey.shade800)),
          Expanded(child: Text(value, style: Get.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    // الـ Binding سيقوم بتمرير companyId
    return Scaffold(
      appBar: AppBar(
        title: const Text("مهام تنتظر تعيين سائق"),
        actions: [
          Obx(() => controller.isLoading.value && controller.tasksToAssign.isEmpty
              ? Padding(
            // --- تأكد من وجود هذا السطر ---
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0), // أو أي قيمة padding مناسبة
            // ------------------------------
            child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white70,
                )),
          )
              : IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: controller.subscribeToTasksToAssign,
            tooltip: "تحديث قائمة المهام",
          ))
        ],      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.tasksToAssign.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.errorMessage.value.isNotEmpty) {
          return Center(child: Text(controller.errorMessage.value, style: TextStyle(color:Colors.red)));
        }
        if (controller.tasksToAssign.isEmpty) {
          return const Center(child: Text("لا توجد مهام تحتاج لتعيين سائق حاليًا.", style: TextStyle(fontSize: 16, color: Colors.grey)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: controller.tasksToAssign.length,
          itemBuilder: (context, index) {
            final task = controller.tasksToAssign[index];
            return _buildTaskToAssignCard(task, context);
          },
        );
      }),
    );
  }
}