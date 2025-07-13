import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'CompanyTaskClaimController.dart';
import 'DeliveryTaskModel.dart';
// استورد المتحكم والنماذج ودالة الحالة
// import 'company_task_claim_controller.dart';
// import '../models/DeliveryTaskModel.dart';
// import '../utils/status_visuals.dart';

class CompanyTaskClaimScreen extends GetView<CompanyTaskClaimController> {
  const CompanyTaskClaimScreen({super.key});

  Widget _buildAvailableTaskCard(DeliveryTaskModel task, BuildContext context) {
    final theme = Theme.of(context);
    // يمكنك حساب المسافة من مقر الشركة إلى موقع الاستلام إذا أردت
    // final double distanceToPickup = calculateDistance(...);

    return Card(
      elevation: 2.5,
      margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("طلب جديد للطلب رقم: ${task.orderId.length > 8 ? '${task.orderId.substring(0,8)}...' : task.orderId}",
                style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.primaryColorDark)),
            const SizedBox(height: 6),
            Text("من البائع: ${task.sellerName ?? task.sellerShopName ?? 'غير محدد'}", style: Get.textTheme.bodyMedium),
            if (task.pickupAddressText != null && task.pickupAddressText!.isNotEmpty)
              Text("عنوان الاستلام: ${task.pickupAddressText}", style: Get.textTheme.bodySmall?.copyWith(color: Colors.blueGrey)),
            const SizedBox(height: 4),
            Text("إلى المشتري: ${task.buyerName ?? 'غير محدد'}", style: Get.textTheme.bodyMedium),
            if (task.deliveryAddressText != null && task.deliveryAddressText!.isNotEmpty)
              Text("عنوان التسليم: ${task.deliveryAddressText}", style: Get.textTheme.bodySmall?.copyWith(color: Colors.blueGrey)),
            const SizedBox(height: 8),
            if(task.province != null) Text("المحافظة: ${task.province}", style: Get.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("وقت الطلب: ${DateFormat('hh:mm a', 'ar').format(task.createdAt.toDate())}", style: Get.textTheme.bodySmall),
                Obx(() => controller.claimingTaskMap[task.taskId] == true
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5))
                    : ElevatedButton.icon(
                  icon: const Icon(Icons.handshake_outlined, size: 18),
                  label: const Text("المطالبة بالمهمة"),
                  onPressed: () => controller.claimTask(task),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)
                  ),
                ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    // الـ Binding سيمرر companyId, companyName, companyBaseDeliveryFee للمتحكم
    return Scaffold(
      appBar: AppBar(
        title: const Text("المهام المتاحة للمطالبة بها"),
        actions: [
          Obx(() => controller.isLoading.value && controller.availableTasksToClaim.isEmpty
              ? const Padding(padding: EdgeInsets.all(16), child: SizedBox(width:20, height:20, child:CircularProgressIndicator(strokeWidth: 2, color:Colors.white)))
              : IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: controller.subscribeToAvailableTasks, tooltip: "تحديث القائمة")
          )
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.availableTasksToClaim.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.errorMessage.value.isNotEmpty) {
          return Center(child: Padding(padding: const EdgeInsets.all(16), child: Column(mainAxisSize:MainAxisSize.min, children: [Text(controller.errorMessage.value, style: const TextStyle(color: Colors.red)), const SizedBox(height:10), ElevatedButton(onPressed: controller.subscribeToAvailableTasks, child:const Text("إعادة المحاولة"))])));
        }
        if (controller.availableTasksToClaim.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.playlist_add_check, size: 70, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                      "لا توجد مهام توصيل جديدة متاحة لشركتك للمطالبة بها في الوقت الحالي. سيتم إشعارك عند توفر مهام جديدة.",
                      textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.grey)
                  ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => controller.subscribeToAvailableTasks(), // سيعيد بناء الاشتراك
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            itemCount: controller.availableTasksToClaim.length,
            itemBuilder: (context, index) {
              final task = controller.availableTasksToClaim[index];
              return _buildAvailableTaskCard(task, context);
            },
          ),
        );
      }),
    );
  }
}