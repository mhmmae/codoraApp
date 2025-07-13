// my_tasks_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart'; // إذا احتجت لتنسيق تواريخ هنا

// استورد المتحكم والنماذج وأي ودجات مساعدة
import '../../routes/app_routes.dart';
import '../الكود الخاص بمشرف التوصيل/DeliveryTaskDetailsForAdminScreen.dart';
import '../الكود الخاص بمشرف التوصيل/DeliveryTaskModel.dart';
import 'MyTasksController.dart';
import 'ProcessedTaskForDriverDisplay.dart';

// (افترض أن ProcessedTaskForDriverDisplay مُعرّف في MyTasksController أو ملف منفصل)

class MyTasksScreen extends GetView<MyTasksController> {
  const MyTasksScreen({super.key});

  // --- ويدجت بناء بطاقة المهمة للتبويب النشط ---
  Widget _buildActiveTaskCard(ProcessedTaskForDriverDisplay processedTask, BuildContext context) {
    final theme = Theme.of(context);
    final task = processedTask.task; // المهمة الأصلية
    final bool isFocused = controller.focusedTaskId.value == task.taskId;

    return Card(
      elevation: isFocused ? 4.0 : 2.0,
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
          side: isFocused ? BorderSide(color: theme.primaryColorDark, width: 1.5) : BorderSide(color: theme.dividerColor.withOpacity(0.7), width: 0.7)
      ),
      color: isFocused ? theme.primaryColor.withOpacity(0.07) : theme.cardColor,
      child: InkWell(
        onTap: () {
          // إذا لم تكن هي المركزة، قم بالتركيز والانتقال
          // إذا كانت مركزة بالفعل، يمكنك إما الانتقال مباشرة أو عدم فعل شيء (حسب تفضيلك)
          controller.setFocusOnTaskAndNavigate(task.taskId);
        },
        borderRadius: BorderRadius.circular(10.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          processedTask.nextActionType == "pickup" ? Icons.storefront_outlined : Icons.person_pin_circle_outlined,
                          color: processedTask.nextActionType == "pickup" ? Colors.blue.shade700 : Colors.green.shade700,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            processedTask.nextActionType == "pickup"
                                ? "استلام من: ${processedTask.nextActionName}"
                                : "تسليم إلى: ${processedTask.nextActionName}",
                            style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isFocused)
                    Chip(
                      label: Text("الوجهة الحالية", style: TextStyle(fontSize: 10, color: Colors.white)),
                      backgroundColor: theme.primaryColorDark,
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                      visualDensity: VisualDensity.compact,
                    )
                ],
              ),
              const SizedBox(height: 4),
              Text("طلب: ${task.orderIdShort}", style: Get.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700)),

              const Divider(height: 15),
              Row(
                children: [
                  Icon(Icons.social_distance_rounded, size: 18, color: Colors.orange.shade700),
                  const SizedBox(width: 6),
                  Text(
                    "المسافة التقريبية: ",
                    style: Get.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    processedTask.distanceDisplay, //  المسافة من ProcessedTaskForDriverDisplay
                    style: Get.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Center(
                child: ElevatedButton.icon(
                  icon: Icon(isFocused ? Icons.navigation_rounded : Icons.play_circle_outline_rounded, size: 18),
                  label: Text(isFocused ? "متابعة التنقل" : "بدء هذه المهمة"),
                  onPressed: () => controller.setFocusOnTaskAndNavigate(task.taskId),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: isFocused ? Colors.green.shade600 : theme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- ويدجت بناء بطاقة لسجل المهام (كما في CompanyTaskHistoryScreen أو أبسط) ---
  Widget _buildHistoryTaskCard(DeliveryTaskModel task, BuildContext context) {
    // ... (تصميم مشابه لبطاقة السجل في CompanyTaskHistoryScreen، يمكنك نسخها وتعديلها إذا لزم الأمر)
    // أو أبسط من ذلك، مع التركيز على وقت الاكتمال، الرسوم (إذا كانت ستعرض للسائق)، الحالة النهائية.
    final theme = Theme.of(context);
    //  يمكنك الحصول على معلومات الحالة من `getTaskStatusVisuals` إذا أردت
    final statusVisuals = getTaskStatusVisuals(task.status, context);
    final DateFormat historyDateFormat = DateFormat('yyyy/MM/dd hh:mm a', 'ar');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: ListTile(
        leading: Icon(statusVisuals['icon'], color: statusVisuals['color'], size: 28),
        title: Text("طلب: ${task.orderIdShort}"),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("الحالة: ${statusVisuals['text']}"),
            Text("بتاريخ: ${historyDateFormat.format((task.deliveryConfirmationTime ?? task.updatedAt ?? task.createdAt).toDate())}"),
            if(task.deliveryFee != null && task.deliveryFee! > 0)
              Text("الرسوم: ${NumberFormat.compactCurrency(locale: 'ar_SA', symbol: "د.ع").format(task.deliveryFee)}", style: TextStyle(color:Colors.teal.shade700)),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
        onTap: () {
          // (اختياري) الانتقال لشاشة تفاصيل المهمة (قد تكون للقراءة فقط للسجل)
          Get.toNamed(AppRoutes.DRIVER_DELIVERY_NAVIGATION.replaceFirst(':taskId', task.taskId), arguments: {'taskId': task.taskId});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // controller سيكون متاحًا لأن هذه GetView
    return Scaffold(
      appBar: AppBar(
        title: const Text("مهامي اليومية"),
        bottom: TabBar(
          controller: controller.tabController, // استخدام الـ TabController من المتحكم
          tabs: const [
            Tab(icon: Icon(Icons.map_outlined), text: "الخريطة والوجهات"),
            Tab(icon: Icon(Icons.list_alt_rounded), text: "قائمة المهام"),
            Tab(icon: Icon(Icons.history_rounded), text: "سجل المهام"), // تبويب جديد
          ],
          onTap: (index){ //  لإعلام المتحكم بالتبويب المختار إذا لم يكن يستخدم listener
            controller.selectedTabIndex.value = index;
            if (index == 0) { // إذا تم اختيار تبويب الخريطة
              controller.onDriverMapCreated(controller.driverTasksMapController!); // قد تحتاج لإعادة رسم الماركرات أو الكاميرا
            }
          },
        ),
        actions: [
          Obx(() { // لعرض مؤشر التحديث أو زر التحديث
            bool isLoadingData = (controller.selectedTabIndex.value == 0 || controller.selectedTabIndex.value == 1) // التبويب النشط (قائمة أو خريطة)
                ? controller.isLoadingActiveTasks.value
                : controller.isLoadingHistory.value; // تبويب السجل
            if (isLoadingData) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
              );
            }
            return IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () {
                if (controller.selectedTabIndex.value == 0 || controller.selectedTabIndex.value == 1) {
                  controller.subscribeToActiveAssignedTasks(); // مع `_processAndDisplayTasks`
                } else {
                  controller.fetchCompletedTasksHistory(isInitialFetch: true);
                }
              },
              tooltip: "تحديث البيانات",
            );
          })
        ],
      ),
      body: TabBarView(
        controller: controller.tabController,
        physics: const NeverScrollableScrollPhysics(), // لمنع التمرير الأفقي للـ TabBarView
        children: [
          // --- 1. تبويب الخريطة ---
          Obx(() {
            if (controller.isLoadingActiveTasks.value && controller.processedDriverTasks.isEmpty) {
              return const Center(child: Text("جاري تحميل مواقع المهام على الخريطة..."));
            }
            // (اختياري) رسالة إذا لم يكن هناك موقع سائق أو مهام
            return GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: CameraPosition(
                target: controller.currentDriverMapPosition.value ?? const LatLng(33.3152, 44.3661), // بغداد كافتراضي
                zoom: 12.0,
              ),
              markers: controller.driverViewMapMarkers.value, // <--- استخدام ماركرات السائق هنا
              onMapCreated: controller.onDriverMapCreated,   // <--- استخدام دالة onMapCreated الصحيحة
              myLocationButtonEnabled: true, // زر "موقعي" على الخريطة
              myLocationEnabled: false,      // موقع السائق يعرض كماركر مخصص
              zoomControlsEnabled: true,
              padding: EdgeInsets.only(bottom: Get.height * 0.08), // ترك مساحة إذا كان هناك أزرار عائمة
            );
          }),

          // --- 2. تبويب قائمة المهام النشطة ---
          Obx(() {
            if (controller.isLoadingActiveTasks.value && controller.processedDriverTasks.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.activeTasksError.value.isNotEmpty) {
              return Center(child: Text(controller.activeTasksError.value, style: const TextStyle(color: Colors.red)));
            }
            if (controller.processedDriverTasks.isEmpty) {
              return const Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_turned_in_outlined, size: 60, color: Colors.grey),
                        SizedBox(height: 10),
                        Text("لا توجد مهام نشطة لديك حاليًا.", style: TextStyle(fontSize: 16, color: Colors.grey))
                      ]));
            }
            return ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 70), // مساحة لـ FAB أو أزرار سفلية أخرى
              itemCount: controller.processedDriverTasks.length,
              itemBuilder: (ctx, index) => _buildActiveTaskCard(controller.processedDriverTasks[index], ctx),
            );
          }),

          // --- 3. تبويب سجل المهام ---
          Obx(() {
            // (كود تبويب السجل مشابه لما كان في CompanyTaskHistoryScreen، باستخدام controller.completedTasksHistory)
            if (controller.isLoadingHistory.value && controller.completedTasksHistory.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.historyError.value.isNotEmpty && controller.completedTasksHistory.isEmpty) {
              return Center(child: Text(controller.historyError.value, style:const TextStyle(color:Colors.red)));
            }
            if (controller.completedTasksHistory.isEmpty) {
              return const Center(child: Text("لا يوجد سجل مهام مكتملة.", style:TextStyle(color:Colors.grey, fontSize: 16)));
            }
            return ListView.builder(
              padding: const EdgeInsets.only(top:8, bottom:16),
              // (منطق pagination إذا طبقته للسجل)
              itemCount: controller.completedTasksHistory.length + (controller.hasMoreHistoryTasks.value ? 1 : 0),
              itemBuilder: (ctx, index){
                if (index == controller.completedTasksHistory.length && controller.hasMoreHistoryTasks.value) {
                  // يمكن تمرير scrollController للـ ListView لمراقبة نهاية القائمة
                  // واستدعاء controller.loadMoreHistory()
                  WidgetsBinding.instance.addPostFrameCallback((_) { // للتأكد أن البناء اكتمل
                    if (!controller.isLoadingMoreHistory.value) controller.loadMoreHistory();
                  });
                  return const Padding(padding: EdgeInsets.all(12.0), child:Center(child:SizedBox(width:24, height:24, child:CircularProgressIndicator(strokeWidth:2.5))));
                }
                if(index >= controller.completedTasksHistory.length) return SizedBox.shrink();
                return _buildHistoryTaskCard(controller.completedTasksHistory[index], ctx);
              },
            );
          }),
        ],
      ),
    );
  }
}