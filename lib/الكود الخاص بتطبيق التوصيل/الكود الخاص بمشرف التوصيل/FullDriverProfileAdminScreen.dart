// FullDriverProfileAdminScreen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import 'CompanyAdminDashboardController.dart';
import '../../Model/DeliveryTaskModel.dart';
import 'FullDriverProfileAdminController.dart'; // لتنسيق التواريخ
// استورد المتحكم والنماذج
// import 'full_driver_profile_admin_controller.dart';
// import '../models/DeliveryDriverModel.dart'; // للتأكد من وجوده والـ enum
// import '../models/DeliveryTaskModel.dart';


// ودجة لعرض الحالة مع أيقونة ولون
// In FullDriverProfileAdminScreen.dart _buildDriverStatusChipForProfile
Widget _buildDriverStatusChipForProfile(DriverApplicationStatus status, BuildContext context) {
  String text; IconData icon; Color bgColor; Color fgColor;
  switch (status) {
    case DriverApplicationStatus.approved:
      text = "معتمد بالشركة"; icon = Icons.verified_user_outlined; bgColor = Colors.teal.shade50; fgColor = Colors.teal.shade700; break;
    case DriverApplicationStatus.pending:
      text = "طلب انضمام معلق"; icon = Icons.hourglass_top_rounded; bgColor = Colors.amber.shade50; fgColor = Colors.amber.shade800; break;
    case DriverApplicationStatus.rejected:
      text = "طلب مرفوض من الشركة"; icon = Icons.do_not_disturb_on_outlined; bgColor = Colors.red.shade50; fgColor = Colors.red.shade700; break;
    case DriverApplicationStatus.suspended:
      text = "حساب مُعلق"; icon = Icons.pause_circle_outline_rounded; bgColor = Colors.orange.shade100; fgColor = Colors.orange.shade800; break;
    case DriverApplicationStatus.removed_by_company: // <--- حالة جديدة
      text = "تمت إزالته من الشركة"; icon = Icons.person_remove_alt_1_outlined; bgColor = Colors.blueGrey.shade100; fgColor = Colors.blueGrey.shade700; break;
    default:
      text = status.toString().split('.').last.replaceAll('_', ' '); icon = Icons.help_outline; bgColor = Colors.grey.shade200; fgColor = Colors.black54;
  }
  return Chip(avatar: Icon(icon, color: fgColor, size:18), label: Text(text, style: TextStyle(color: fgColor, fontWeight: FontWeight.w500, fontSize: 12)), backgroundColor: bgColor, padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4));
}


// دالة لعرض حالة التوفر الفعلية للسائق
Widget _buildDriverAvailabilityChip(String availabilityStatus, BuildContext context) {
  final availabilityInfo = getDriverAvailabilityVisuals(availabilityStatus, context); // استخدم الدالة من CompanyDriversListScreen أو عرفها هنا
  return Chip(
    avatar: Icon(availabilityInfo['icon'], color: availabilityInfo['color'], size: 18),
    label: Text(availabilityInfo['text'], style: TextStyle(color: availabilityInfo['color'], fontSize: 12, fontWeight: FontWeight.w500)),
    backgroundColor: (availabilityInfo['color'] as Color).withOpacity(0.15),
    shape: StadiumBorder(),
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  );
}
// --- تحتاج لتعريف getDriverAvailabilityVisuals هنا أو استيرادها ---
Map<String, dynamic> getDriverAvailabilityVisuals(String statusKey, BuildContext context) {
  final theme = Theme.of(context);
  switch (statusKey.toLowerCase()) {
    case "online_available": return {"text": "متوفر", "color": Colors.green.shade600, "icon": Icons.wifi_rounded};
    case "on_task": return {"text": "في مهمة", "color": Colors.orange.shade700, "icon": Icons.delivery_dining_rounded};
    case "offline": return {"text": "غير متوفر", "color": Colors.red.shade500, "icon": Icons.wifi_off_rounded};
    default: return {"text": statusKey, "color": Colors.grey, "icon": Icons.help_outline};
  }
}
// ------------------------------------------------------------

class FullDriverProfileAdminScreen extends GetView<FullDriverProfileAdminController> {
  const FullDriverProfileAdminScreen({super.key, required String driverId}) : _driverId = driverId;
  final String _driverId; // يُستخدم فقط إذا لم يتمكن Binding من توفير المتحكم مباشرةً


  Widget _buildInfoCard({required String title, required List<Widget> children, required BuildContext context}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Get.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).primaryColorDark)),
            const Divider(height: 20, thickness: 0.5),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value, IconData icon, {Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor ?? Colors.grey.shade700),
          const SizedBox(width: 12),
          Text("$label: ", style: Get.textTheme.titleSmall?.copyWith(fontWeight:FontWeight.w500, color: Colors.blueGrey.shade700)),
          Expanded(child: Text(value ?? "غير متوفر", style: Get.textTheme.bodyLarge?.copyWith(color: Colors.black87, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    // يتم إنشاء المتحكم عبر الـ Binding الذي يستقبل _driverId
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.driverProfile.value?.name ?? "ملف السائق...")),
        actions: [ IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: controller.fetchAllDriverData, tooltip: "تحديث البيانات") ],
      ),
      body: Obx(() {
        if (controller.isLoadingProfile.value && controller.driverProfile.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.errorMessage.value.isNotEmpty && controller.driverProfile.value == null) {
          return Center(
              child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.error_outline, color: Colors.red, size: 40), SizedBox(height:10),
                Text("خطأ: ${controller.errorMessage.value}", style: TextStyle(color: Colors.red.shade700), textAlign: TextAlign.center),
                SizedBox(height:10),
                ElevatedButton(onPressed: controller.fetchAllDriverData, child: Text("إعادة المحاولة"))
              ]))
          );
        }
        if (controller.driverProfile.value == null) {
          return const Center(child: Text("لم يتم العثور على بيانات السائق. قد يكون المعرف غير صالح أو تم حذف السائق."));
        }

        final driver = controller.driverProfile.value!;
        final theme = Theme.of(context);

        return RefreshIndicator( // للسحب للتحديث
          onRefresh: controller.fetchAllDriverData,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // --- قسم المعلومات الشخصية والعامة ---
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 65,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: driver.profileImageUrl != null && driver.profileImageUrl!.isNotEmpty
                              ? CachedNetworkImageProvider(driver.profileImageUrl!) : null,
                          child: (driver.profileImageUrl == null || driver.profileImageUrl!.isEmpty)
                              ? Icon(Icons.person_sharp, size: 70, color: Colors.grey.shade600) : null,
                        ),
                        // يمكنك وضع أيقونة حالة التوفر هنا
                        Positioned(
                          bottom: 0, right: 0,
                          child: _buildDriverAvailabilityChip(driver.availabilityStatus, context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(driver.name, style: Get.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    _buildDriverStatusChipForProfile(driver.applicationStatus, context),
                    if(driver.applicationStatus == DriverApplicationStatus.rejected || driver.applicationStatus == DriverApplicationStatus.suspended)
                      if(driver.rejectionReason != null && driver.rejectionReason!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text("السبب: ${driver.rejectionReason}", style: TextStyle(fontSize: 12, color: Colors.red.shade700, fontStyle: FontStyle.italic), textAlign: TextAlign.center),
                        ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- بطاقة المعلومات الأساسية ---
              _buildInfoCard(
                title: "معلومات الاتصال والتقييم", context: context,
                children: [
                  _buildInfoRow("المعرف (UID)", driver.uid, Icons.fingerprint_rounded),
                  _buildInfoRow("رقم الهاتف", driver.phoneNumber, Icons.phone_iphone_rounded),
                  _buildInfoRow("البريد الإلكتروني (إذا كان متاحًا)", driver.fcmToken != null ? "لديه توكن إشعارات" : "لا يوجد توكن", Icons.email_outlined), // مثال إذا كنت تخزن الإيميل
                  _buildInfoRow("التقيیم", "${driver.averageRating.toStringAsFixed(1)} نجوم (${driver.numberOfRatings} تقييم)", Icons.star_half_rounded, iconColor: Colors.amber.shade700),
                  _buildInfoRow("تاريخ التسجيل", DateFormat('EEEE، d MMMM yyyy', 'ar').format(driver.createdAt.toDate()), Icons.calendar_month_rounded),
                  if(driver.applicationStatusUpdatedAt != null)
                    _buildInfoRow("آخر تحديث للحالة", DateFormat('yyyy/MM/dd hh:mm a', 'ar').format(driver.applicationStatusUpdatedAt!.toDate()), Icons.update_rounded),

                ],
              ),

              // --- بطاقة معلومات المركبة ---
              _buildInfoCard(
                title: "معلومات المركبة", context: context,
                children: [
                  _buildInfoRow("نوع المركبة", driver.vehicleType, driver.vehicleType.toLowerCase().contains("دراجة") ? Icons.pedal_bike_rounded : Icons.local_shipping_rounded ),
                  _buildInfoRow("رقم اللوحة", driver.vehiclePlateNumber, Icons.onetwothree_rounded),
                ],
              ),
              const SizedBox(height: 16),
              // --- زر إدارة حالة السائق ---
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.admin_panel_settings_rounded),
                  label: const Text("إدارة حالة السائق"),
                  onPressed: () => controller.showChangeStatusDialog(context),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: theme.colorScheme.onSecondary,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12)
                  ),
                ),
              ),


              const SizedBox(height: 24),
              // --- قسم سجل المهام ---
              Text("سجل التوصيلات (${controller.completedTasks.length + controller.ongoingOrFailedTasks.length})",
                  style: Get.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).primaryColorDark)),
              const Divider(height: 16, thickness: 0.5),
              Obx(() {
                if (controller.isLoadingTasks.value) {
                  return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(strokeWidth: 2)));
                }
                if (controller.completedTasks.isEmpty && controller.ongoingOrFailedTasks.isEmpty) {
                  return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text("لا توجد مهام مسجلة لهذا السائق.")));
                }
                // عرض المهام الحالية/الفاشلة أولاً ثم المكتملة
                List<DeliveryTaskModel> allTasksToShow = [...controller.ongoingOrFailedTasks, ...controller.completedTasks];

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: allTasksToShow.length,
                  itemBuilder: (context, index) {
                    final task = allTasksToShow[index];
                    // استخدم ودجة عرض المهمة التي صممناها سابقًا أو واحدة مبسطة
                    return ListTile(
                      dense: true,
                      leading: Icon(
                          task.status == DeliveryTaskStatus.delivered ? Icons.check_circle_outline_rounded : (task.status == DeliveryTaskStatus.delivery_failed || task.status.toString().contains("cancelled") ? Icons.error_outline_rounded : Icons.pending_actions_rounded),
                          color: task.status == DeliveryTaskStatus.delivered ? Colors.green : (task.status == DeliveryTaskStatus.delivery_failed || task.status.toString().contains("cancelled") ? Colors.red : Colors.orange)
                      ),
                      title: Text("مهمة للطلب: ${task.orderId.length > 8 ? '${task.orderId.substring(0,8)}...' : task.orderId}"),
                      subtitle: Text("الحالة: ${deliveryTaskStatusToString(task.status).replaceAll('_', ' ')} - بتاريخ: ${DateFormat('yy/MM/dd hh:mm', 'ar').format(task.createdAt.toDate())}"),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      onTap: () {
                        Get.toNamed('/admin/task-details/${task.taskId}');
                      },
                    );
                  },
                  separatorBuilder: (context, index) => const Divider(height:1, indent: 16, endIndent: 16, thickness: 0.5),
                );
              }),
            ],
          ),
        );
      }),
    );
  }
}