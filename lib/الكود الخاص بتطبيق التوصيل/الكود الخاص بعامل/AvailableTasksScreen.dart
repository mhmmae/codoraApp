// In AvailableTasksScreen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../XXX/xxx_firebase.dart';
import '../الكود الخاص بمشرف التوصيل/DeliveryTaskModel.dart';
import 'AvailableTasksController.dart';
// import 'available_tasks_controller.dart';
// import '../models/DeliveryTaskModel.dart';
// import '../utils/status_visuals.dart';

// (دالة getTaskStatusVisuals كما هي من قبل)

class AvailableTasksScreen extends GetView<AvailableTasksController> {
  const AvailableTasksScreen({super.key});

  Widget _buildAvailableTaskCard(Map<String, dynamic> taskDataMap, BuildContext context) {
    final DeliveryTaskModel task = taskDataMap['task'] as DeliveryTaskModel;
    final double distanceMeters = taskDataMap['distanceMeters'] as double;
    final theme = Theme.of(context);

    String distanceToPickupStr = "المسافة للاستلام: غير معروف";
    if(distanceMeters >=0){
      if(distanceMeters < 1000) {
        distanceToPickupStr = "يبعد للاستلام: ${distanceMeters.toStringAsFixed(0)} م";
      } else {
        distanceToPickupStr = "يبعد للاستلام: ${(distanceMeters/1000).toStringAsFixed(1)} كم";
      }
    }

    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("طلب جديد: ${task.orderId.length > 8 ? '${task.orderId.substring(0,8)}...' : task.orderId}",
                style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.primaryColor)),
            const Divider(height:12),
            Text("من: ${task.sellerName ?? 'بائع غير محدد'}", style: Get.textTheme.bodyMedium),
            if (task.pickupAddressText != null) Text(task.pickupAddressText!, style: Get.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
            const SizedBox(height: 5),
            Text("إلى: ${task.buyerName ?? 'مشتري غير محدد'}", style: Get.textTheme.bodyMedium),
            if (task.deliveryAddressText != null) Text(task.deliveryAddressText!, style: Get.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Text(distanceToPickupStr, style: Get.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("رسوم التوصيل: ${task.deliveryFee != null ? NumberFormat.currency(locale: 'ar_SA', symbol: FirebaseX.currency, decimalDigits:0).format(task.deliveryFee) : 'N/A'}",
                    style: Get.textTheme.bodySmall?.copyWith(fontWeight:FontWeight.bold)),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text("قبول المهمة"),
                  onPressed: () => controller.acceptTask(task),
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)
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
    // Binding سيوفر driverId و companyId و initialDriverLocation
    return Scaffold(
      appBar: AppBar(
        title: const Text("المهام المتاحة لشركتك"),
        // يمكنك إضافة أيقونات للفلترة أو الفرز هنا
        actions: [
          Obx(()=> IconButton(
              icon: Icon(controller.currentSortBy.value == "distance" ? Icons.sort_by_alpha_rounded : Icons.social_distance_rounded),
              tooltip: controller.currentSortBy.value == "distance" ? "فرز أبجدي (حاليًا بالأقرب)" : "فرز حسب الأقرب (حاليًا أبجدي)",
              onPressed: () => controller.updateSortBy(controller.currentSortBy.value == "distance" ? "newest" : "distance")
          )),
          TextField(
            controller: controller.driverSearchController,
            // <--- استخدم الاسم الصحيح هنا
            decoration: InputDecoration(
              hintText: "ابحث برقم الطلب، اسم البائع...",
              // ...
            ),
          ),
          IconButton(
              icon: Icon(Icons.filter_list_alt),
              tooltip: "فلترة المسافة",
              onPressed: () async {
                double currentMax = controller.maxDistanceFilterKm.value;
                double? newMax = await Get.dialog<double>(
                    AlertDialog(
                      title: Text("فلترة حسب المسافة للاستلام"),
                      content: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text("اعرض المهام التي تبعد حتى ${currentMax.toStringAsFixed(0)} كم"),
                        Slider(
                          value: currentMax,
                          min: 1, max: 50, divisions: 49,
                          label: "${currentMax.round()} كم",
                          onChanged: (val) { /* يمكنك تحديث قيمة مؤقتة هنا إذا أردت رؤيتها تتغير أثناء السحب */ },
                          onChangeEnd: (val) => currentMax = val, // تحديث عند انتهاء السحب
                        )
                      ]),
                      actions: [TextButton(child:Text("إلغاء"), onPressed:()=> Get.back()), ElevatedButton(child:Text("تطبيق"), onPressed:()=> Get.back(result:currentMax)) ],
                    )
                );
                if (newMax != null) controller.updateMaxDistanceFilter(newMax);
              }
          ),

          Obx(() => (controller.isLoading.value)
              ? const Padding(padding: EdgeInsets.all(16), child:SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)))
              : IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: controller.subscribeToCompanyAvailableTasks, tooltip: "تحديث"))
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.tasksToDisplayWithDistance.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.errorMessage.value.isNotEmpty) {
          return Center(child: Padding(padding:const EdgeInsets.all(16),child:Column(mainAxisSize:MainAxisSize.min, children:[Text(controller.errorMessage.value, style: const TextStyle(color: Colors.red)), SizedBox(height:10), ElevatedButton(onPressed: controller.subscribeToCompanyAvailableTasks, child: Text("إعادة المحاولة"))])));
        }
        if (controller.tasksToDisplayWithDistance.isEmpty) {
          return const Center(
              child: Padding(padding: EdgeInsets.all(20.0), child: Column( mainAxisAlignment: MainAxisAlignment.center, children:[
                Icon(Icons.no_transfer_rounded, size:70, color:Colors.grey), SizedBox(height:16),
                Text("لا توجد مهام متاحة لك حاليًا تطابق معايير الفلترة. حاول توسيع نطاق البحث أو تحقق لاحقًا.", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey))
              ]))
          );
        }
        return RefreshIndicator(
          onRefresh: () async => controller.subscribeToCompanyAvailableTasks(),
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            itemCount: controller.tasksToDisplayWithDistance.length,
            itemBuilder: (context, index) {
              final taskData = controller.tasksToDisplayWithDistance[index];
              return _buildAvailableTaskCard(taskData, context);
            },
          ),
        );
      }),
    );
  }
}