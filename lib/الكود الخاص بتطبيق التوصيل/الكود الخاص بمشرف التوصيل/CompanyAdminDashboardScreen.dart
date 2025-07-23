import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // للخريطة
import 'package:cached_network_image/cached_network_image.dart';

import '../الكود الخاص بعامل/DeliveryDriverModel.dart';
import 'CompanyAdminDashboardController.dart';
import '../../Model/DeliveryTaskModel.dart';


class CompanyAdminDashboardScreen extends GetView<CompanyAdminDashboardController> {
  const CompanyAdminDashboardScreen({super.key});

  Widget _buildStatCard(String title, RxInt count, IconData icon, Color color, {VoidCallback? onTap}) {
    return Expanded(
      child: Card(
        elevation: 2.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 30, color: color),
                const SizedBox(height: 8),
                Obx(() => Text(count.value.toString(), style: Get.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: color))),
                const SizedBox(height: 4),
                Text(title, textAlign: TextAlign.center, style: Get.textTheme.bodySmall?.copyWith(color: Colors.blueGrey.shade700)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShortcutButton(String title, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 20),
      label: Text(title, style: TextStyle(fontSize: 13)),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        // backgroundColor: Get.theme.colorScheme.secondaryContainer,
        // foregroundColor: Get.theme.colorScheme.onSecondaryContainer
      ),
    );
  }

  Widget _buildDriverApplicationCard(DeliveryDriverModel driverApp) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: driverApp.profileImageUrl != null ? CachedNetworkImageProvider(driverApp.profileImageUrl!) : null,
          child: driverApp.profileImageUrl == null ? const Icon(Icons.person) : null,
        ),
        title: Text(driverApp.name),
        subtitle: Text("نوع المركبة: ${driverApp.vehicleType}"),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: (){
          Get.snackbar("تفاصيل الطلب", "عرض تفاصيل طلب السائق ${driverApp.name} (لم تنفذ بعد).");
          // يمكنك عرض حوار بتفاصيل السائق وأزرار قبول/رفض هنا مباشرة
          // أو الانتقال إلى شاشة مراجعة طلبات السائقين مع تمرير هذا السائق
          // controller.goToDriverApplications(); // وتمرير ID الطلب مثلاً
        },
      ),
    );
  }

  Widget _buildCriticalTaskCard(DeliveryTaskModel task) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: Colors.orange.shade50,
      child: ListTile(
        leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
        title: Text("طلب رقم: ${task.orderId.length > 10 ? '${task.orderId.substring(0,10)}...' : task.orderId}"),
        subtitle: Text("من: ${task.sellerName} إلى: ${task.buyerName}\nالحالة: ${task.status}"), // ترجم الحالات
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: (){
          // Get.to(()=> TaskDetailsScreen(taskId: task.taskId));
          Get.toNamed('/admin/task-details/${task.taskId}');
        },
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    // Get.put(CompanyAdminDashboardController()); //  ضع هذا في Binding خاص بمسار هذه الشاشة

    if (!controller.companyIdAvailable.value && !controller.isLoadingDashboard.value) { // تأكد أنه ليس في حالة تحميل عام
      return Scaffold(
          appBar: AppBar(title: Text("لوحة تحكم الشركة")),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                "خطأ: لا يمكن عرض لوحة التحكم. لم يتم تحديد شركة لهذا الحساب الإداري. يرجى التأكد من تسجيل الدخول بحساب مشرف شركة صالح أو تسجيل شركة جديدة.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red.shade700, fontSize: 16),
              ),
            ),
          )
      );
    }


    return Scaffold(
      appBar: AppBar(
        title: const Text("لوحة تحكم الشركة"),
        // يمكن إضافة أيقونة ملف الشركة هنا للانتقال لإعدادات الشركة
        // actions: [ IconButton(icon: Icon(Icons.storefront_outlined), onPressed: () => controller.goToCompanySettings())],
      ),
      body: Obx(() { // يراقب isLoadingDashboard
        if (controller.isLoadingDashboard.value && controller.driversOnlineAvailable.value == 0 ) { //  فقط إذا كانت كل البيانات لم تحمل بعد
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: controller.fetchAllDashboardData,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- قسم الإحصائيات السريعة ---
                Text("نظرة عامة على السائقين", style: Get.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildStatCard("متوفرون", controller.driversOnlineAvailable, Icons.event_available_outlined, Colors.green.shade600),
                    const SizedBox(width: 8),
                    _buildStatCard("في مهمة", controller.driversOnTask, Icons.delivery_dining_outlined, Colors.orange.shade700),
                    const SizedBox(width: 8),
                    _buildStatCard("غير متوفرين", controller.driversOffline, Icons.power_settings_new_outlined, Colors.red.shade600),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatCard("مهام اليوم", controller.totalTasksTodayForCompany, Icons.assignment_turned_in_outlined, Colors.blue.shade700, onTap: (){ /* Go to daily tasks list */ }),
                    const SizedBox(width: 8),
                    _buildStatCard("مكتملة اليوم", controller.completedTasksTodayForCompany, Icons.task_alt_outlined, Colors.teal.shade600, onTap: (){ /* Go to completed tasks list */}),
                    const SizedBox(width: 8),

                    _buildShortcutButton(
                        "مهام تحتاج تدخل (${controller.tasksNeedingInterventionCount.value})",
                        Icons.build_circle_outlined,
                        controller.goToInterventionTasks // الدالة التي تنقل إلى شاشة التدخل
                    ),
                    _buildStatCard(
                        "مهام تحتاج تعيين سائق",
                        controller.tasksPendingDriverAssignmentCount,
                        Icons.person_search_outlined,
                        Colors.blueAccent, // أو لون آخر
                        onTap: controller.goToTasksPendingDriverAssignment
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: controller.goToDriverApplications,
                  child: Card(
                      color: Get.theme.colorScheme.tertiaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("طلبات انضمام سائقين جديدة", style: Get.textTheme.titleMedium?.copyWith(color: Get.theme.colorScheme.onTertiaryContainer)),
                            Obx(() => CircleAvatar(
                              radius: 14,
                              backgroundColor: controller.pendingDriverApplications.value > 0 ? Colors.red : Colors.grey,
                              child: Text(controller.pendingDriverApplications.value.toString(), style: TextStyle(color: Colors.white, fontSize: 12, fontWeight:FontWeight.bold)),
                            )),
                          ],
                        ),
                      )),
                ),

                const SizedBox(height: 20),
                // --- قسم الخريطة المصغرة ---
                Text("تتبع السائقين (مصغر)", style: Get.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Obx((){
                  if(controller.isLoadingMapData.value){
                    return SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
                  }
                  if(controller.driverLocationMarkers.isEmpty){
                    return SizedBox(height: 200, child: Center(child: Text("لا يوجد سائقون نشطون حاليًا لعرضهم على الخريطة.")));
                  }
                  return SizedBox(
                    height: 200, // ارتفاع الخريطة المصغرة
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: GoogleMap(
                        onMapCreated: controller.onMiniMapCreated,
                        initialCameraPosition: const CameraPosition(
                          target: LatLng(33.3152, 44.3661), // موقع افتراضي لوسط بغداد أو شركتك
                          zoom: 9.0,
                        ),
                        markers: Set<Marker>.from(controller.driverLocationMarkers),
                        myLocationButtonEnabled: false,
                        myLocationEnabled: false, // لا تعرض موقع المشرف هنا
                        mapToolbarEnabled: false,
                        onTap: (_) => controller.goToFullMapView(), // النقر على الخريطة المصغرة يفتح الخريطة الكاملة
                      ),
                    ),
                  );
                }),
                Align(alignment: Alignment.centerLeft, child: TextButton(onPressed: controller.goToFullMapView, child: Text("عرض الخريطة الكاملة"))),


                const SizedBox(height: 20),
                // --- قسم المهام الحرجة ---
                Text("المهام الحرجة/المتأخرة", style: Get.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Obx(() {
                  if(controller.isLoadingCriticalTasks.value){
                    return const Center(child: LinearProgressIndicator());
                  }
                  if (controller.criticalTasksForCompany.isEmpty) {
                    return const Text("لا توجد مهام حرجة حاليًا.", style: TextStyle(color: Colors.grey));
                  }
                  return Column(children: controller.criticalTasksForCompany.map(_buildCriticalTaskCard).toList());
                }),


                const SizedBox(height: 20),
                // --- قسم أحدث طلبات انضمام السائقين ---
                Text("أحدث طلبات الانضمام", style: Get.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Obx(() {
                  if(controller.isLoadingDriverApps.value){
                    return const Center(child: LinearProgressIndicator());
                  }
                  if (controller.latestDriverApplications.isEmpty) {
                    return const Text("لا توجد طلبات انضمام جديدة.", style: TextStyle(color: Colors.grey));
                  }
                  return Column(children: controller.latestDriverApplications.map(_buildDriverApplicationCard).toList());
                }),


                const SizedBox(height: 20),
                // --- قسم الإشعارات ---
                // Text("تنبيهات الشركة", style: Get.textTheme.titleLarge),
                // Obx(() => ListView.builder( ... controller.companyNotifications ... )),

                const SizedBox(height: 24),
                // --- قسم الاختصارات السريعة ---
                Text("إجراءات سريعة", style: Get.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildShortcutButton("إدارة السائقين", Icons.people_alt_outlined, controller.goToManageDrivers),
                    _buildShortcutButton("تعيين المهام", Icons.add_task_outlined, controller.goToAssignTasks),
                    _buildShortcutButton("طلبات الانضمام", Icons.person_add_alt_1, controller.goToDriverApplications),
                    _buildShortcutButton("التقارير", Icons.bar_chart_outlined, controller.goToReports),
                  ],
                )
              ],
            ),
          ),
        );
      }),
    );
  }
}


