import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../الكود الخاص بعامل/DeliveryDriverModel.dart';
import 'AssignTaskController.dart';
import 'DeliveryTaskDetailsForAdminScreen.dart';
import '../../Model/DeliveryTaskModel.dart';
// استورد المتحكم والنماذج ودالة الحالة
// import 'assign_task_controller.dart';
// import '../models/DeliveryTaskModel.dart';
// import '../models/DeliveryDriverModel.dart';
// import '../utils/status_visuals.dart'; // لـ getDriverAvailabilityVisuals

// دالة مساعدة لعرض بطاقة تفاصيل المهمة بشكل جميل (يمكن تحسينها أكثر)
Widget _buildAssignTaskSummaryCard(DeliveryTaskModel task, String? orderIdForDisplay, BuildContext context) {
  final theme = Theme.of(context);
  // يمكنك استخدام getTaskStatusVisuals هنا لعرض الحالة بشكل أفضل
  final statusVisuals = getTaskStatusVisuals(task.status, context);


  return Card(
    elevation: 2,
    margin: const EdgeInsets.symmetric(horizontal:12.0, vertical: 8.0),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    child: Padding(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("مهمة للطلب: ${orderIdForDisplay ?? task.orderId.substring(0,task.orderId.length > 8 ? 8: task.orderId.length)}${task.orderId.length > 8 ? '...' : ''}",
                  style: Get.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.primaryColorDark)),
              Chip( // شريحة حالة المهمة
                avatar: Icon(statusVisuals['icon'], color: statusVisuals['textColor'], size: 16),
                label: Text(statusVisuals['text'], style: TextStyle(color: statusVisuals['textColor'], fontSize: 11, fontWeight: FontWeight.w500)),
                backgroundColor: statusVisuals['color'],
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )
            ],
          ),
          const Divider(height:16),
          Row(children: [ const Icon(Icons.storefront, size: 18, color: Colors.blueGrey), const SizedBox(width: 8), Expanded(child: Text("من: ${task.sellerName ?? 'بائع غير محدد'}", style: Get.textTheme.bodyLarge))]),
          if(task.pickupAddressText != null) Padding(padding: const EdgeInsets.only(left:26, top:2), child: Text(task.pickupAddressText!, style: Get.textTheme.bodySmall?.copyWith(color:Colors.grey.shade700))),
          const SizedBox(height: 8),
          Row(children: [ const Icon(Icons.person_pin_circle_sharp, size: 18, color: Colors.blueGrey), const SizedBox(width: 8),Expanded(child:Text("إلى: ${task.buyerName ?? 'مشتري غير محدد'}", style: Get.textTheme.bodyLarge))]),
          if(task.deliveryAddressText != null) Padding(padding: const EdgeInsets.only(left:26, top:2), child: Text(task.deliveryAddressText!, style: Get.textTheme.bodySmall?.copyWith(color:Colors.grey.shade700))),
          // يمكنك إضافة المزيد من التفاصيل إذا أردت، مثل ملخص المنتجات
        ],
      ),
    ),
  );
}

// In AssignTaskToDriverScreen.dart

Widget _buildDriverToAssignTile(Map<String, dynamic> driverDataMap, AssignTaskController controller, BuildContext context) {
  // --- استخراج كائن السائق والمسافة من الـ Map ---
  final DeliveryDriverModel driver = driverDataMap['driver'] as DeliveryDriverModel;
  final double distanceMeters = driverDataMap['distanceMeters'] as double;
  // -----------------------------------------------

  final theme = Theme.of(context);
  String distanceString = "الموقع/المسافة غير معروفة";
  if (distanceMeters >= 0) {
    if (distanceMeters == 0 && driver.currentLocation != null) {
      distanceString = "قريب جدًا";
    } else if (distanceMeters < 1000) {
      distanceString = "${distanceMeters.toStringAsFixed(0)} م";
    } else {
      distanceString = "${(distanceMeters / 1000).toStringAsFixed(1)} كم";
    }
  }

  return Card(
    elevation: 1.8,
    margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 4.0),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: theme.colorScheme.secondaryContainer,
        backgroundImage: driver.profileImageUrl != null && driver.profileImageUrl!.isNotEmpty
            ? CachedNetworkImageProvider(driver.profileImageUrl!) : null,
        child: (driver.profileImageUrl == null || driver.profileImageUrl!.isEmpty)
            ? Icon(Icons.delivery_dining_sharp, size: 26, color: theme.colorScheme.onSecondaryContainer) : null,
      ),
      title: Text(driver.name, style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("المركبة: ${driver.vehicleType}", style: Get.textTheme.bodySmall?.copyWith(fontSize: 12.5)),
          Text("المسافة للاستلام: $distanceString", style: Get.textTheme.bodySmall?.copyWith(color: theme.primaryColor, fontWeight: FontWeight.w500, fontSize: 12)),
        ],
      ),
      trailing: Obx(() => controller.isAssigning.value
          ? const Padding(padding: EdgeInsets.all(10.0), child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)))
          : ElevatedButton(
        onPressed: () {
          Get.defaultDialog(
              title: "تأكيد التعيين",
              middleText: "هل أنت متأكد من تعيين هذه المهمة للسائق ${driver.name}؟\n(مسافة الاستلام: $distanceString)",
              textConfirm: "نعم، تعيين الآن",
              textCancel: "إلغاء",
              confirmTextColor: Colors.white,
              buttonColor: theme.primaryColor,
              onConfirm: () { Get.back(); controller.assignTaskToSelectedDriver(driver.uid, driver.name); }
          );
        },
        style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7), // تعديل padding الزر
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold) // تعديل حجم الخط
        ),
        child: const Text("اختر"), // نص أقصر للزر
      )
      ),
      onTap: () {
        if (driver.currentLocation != null && controller.mapController != null) {
          controller.mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(LatLng(driver.currentLocation!.latitude, driver.currentLocation!.longitude), 15.5)
          );
        } else {
          Get.snackbar("تنبيه", "موقع هذا السائق غير متوفر حاليًا على الخريطة.", snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds:2));
        }
      },
    ),
  );
}


class AssignTaskToDriverScreen extends GetView<AssignTaskController> {
  const AssignTaskToDriverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.isReassignment ? "إعادة تعيين المهمة" : "تعيين مهمة لسائق")),
        actions: [Obx(()=> controller.isLoadingTask.value || controller.isLoadingDrivers.value ? SizedBox.shrink() : IconButton(icon: Icon(Icons.refresh_rounded), onPressed: controller.fetchTaskAndAvailableDrivers, tooltip: "تحديث البيانات"))],
      ),
      body: Obx(() {
        if (controller.isLoadingTask.value) {
          return const Center(child: CircularProgressIndicator(semanticsLabel: "تحميل تفاصيل المهمة..."));
        }
        if (controller.errorMessage.value.isNotEmpty) { /* ... رسالة الخطأ ... */ }
        if (controller.taskDetails.value == null) {
          return const Center(child: Text("فشل تحميل تفاصيل المهمة."));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- الخريطة ---
            Obx(() => SizedBox(
              height: Get.height * 0.22, // قلل الارتفاع قليلاً
              child: controller.mapMarkers.isEmpty && !controller.isLoadingTask.value //  لا تعرض خريطة فارغة إذا لم تكن هناك ماركرات للمهمة
                  ? Center(child: Text("جاري تحديد مواقع المهمة...", style:TextStyle(color:Colors.grey)))
                  : GoogleMap(
                onMapCreated: controller.onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: controller.mapMarkers.isNotEmpty ? controller.mapMarkers.first.position : const LatLng(33.3, 44.3), // نقطة الاستلام أو افتراضي
                  zoom: 10.0,
                ),
                markers: controller.mapMarkers.value,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: true,
                mapToolbarEnabled: false,
              ),
            )),
            // --- تفاصيل المهمة ---
            Padding(
                padding: const EdgeInsets.symmetric(horizontal:8.0),
                child: _buildAssignTaskSummaryCard(controller.taskDetails.value!, controller.initialOrderIdForDisplay, context)
            ),

            // --- شريط البحث وخيارات الفرز للسائقين ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              child: Row(
                children: [
                  Expanded(
                    child:
                    TextField(
                      controller: controller.driverSearchController,
                      decoration: InputDecoration(
                        hintText: "ابحث عن سائق بالاسم، المركبة، أو ID...",
                        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Colors.grey),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                        contentPadding: const EdgeInsets.symmetric(horizontal:12, vertical: 8),
                        isDense: true,
                        suffixIcon: Obx(() => controller.driverSearchQuery.value.isNotEmpty
                            ? IconButton(icon: Icon(Icons.clear, size:18, color: Colors.grey), onPressed: (){ controller.driverSearchController.clear(); FocusScope.of(context).unfocus(); })
                            : const SizedBox.shrink()),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),

                  ),
                  const SizedBox(width: 8),
                  Obx(()=> PopupMenuButton<DriverSortOptionForAssignment>(
                    icon: const Icon(Icons.sort_by_alpha_rounded),
                    tooltip: "فرز السائقين",
                    initialValue: controller.currentSortOption.value,
                    onSelected: controller.changeSortOption,
                    itemBuilder: (BuildContext ctx) {
                      return DriverSortOptionForAssignment.values.map((option) {
                        String text = "";
                        switch(option){
                          case DriverSortOptionForAssignment.distanceAsc: text="الأقرب للاستلام"; break;
                          case DriverSortOptionForAssignment.nameAsc: text="الاسم (أ-ي)"; break;
                        }
                        return PopupMenuItem(value: option, child: Text(text, style:TextStyle(fontSize: 13)));
                      }).toList();
                    },
                  )),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Align(alignment:Alignment.centerRight, child: Text("اختر سائقًا من القائمة:", style: TextStyle(fontWeight: FontWeight.bold, fontSize:14))),
            ),
            Expanded(
              child: Obx(() {
                if (controller.isLoadingDrivers.value) {
                  return const Center(child: CircularProgressIndicator(strokeWidth: 3));
                }



                if (controller.displayDriversList.isEmpty) {
                  return Center(
                      child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                              controller.driverSearchQuery.value.isNotEmpty
                                  ? "لا يوجد سائقون يطابقون بحثك."
                                  : "لا يوجد سائقون متوفرون حاليًا في هذه الشركة.",
                              textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colors.blueGrey))
                      ));
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 16.0),
                  itemCount: controller.displayDriversList.length,
                  itemBuilder: (context, index) {
                    final driverData = controller.displayDriversList[index];
                    return _buildDriverToAssignTile(driverData, controller, context);
                  },
                );
              }),
            ),
          ],
        );
      }),
    );
  }
}



