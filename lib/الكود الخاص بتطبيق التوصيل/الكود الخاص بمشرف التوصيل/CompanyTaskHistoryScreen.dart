import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'CompanyTaskHistoryController.dart';
import 'DeliveryTaskDetailsForAdminScreen.dart';
import '../../Model/DeliveryTaskModel.dart';
// استورد المتحكم والنماذج وأي أدوات مساعدة (مثل getTaskStatusVisuals)
// import 'company_task_history_controller.dart';
// import '../models/DeliveryTaskModel.dart';
// import '../models/DeliveryDriverModel.dart';
// import '../utils/status_visuals.dart'; // افترض وجود هذا الملف


class CompanyTaskHistoryScreen extends GetView<CompanyTaskHistoryController> {
  const CompanyTaskHistoryScreen({super.key});

  Widget _buildTaskHistoryCard(DeliveryTaskModel task, BuildContext context) {
    final statusVisuals = getTaskStatusVisuals(task.status, context); // استخدم دالة عرض الحالة

    return Card(
        elevation: 1.5,
        margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: InkWell(
            onTap: () => controller.navigateToTaskDetails(task.taskId),
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
                          style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    Chip(
                      avatar: Icon(statusVisuals['icon'], color: statusVisuals['textColor'], size: 15),
                      label: Text(statusVisuals['text'], style: TextStyle(color: statusVisuals['textColor'], fontSize: 10.5, fontWeight: FontWeight.w500)),
                      backgroundColor: statusVisuals['color'],
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                    if (task.driverName != null && task.driverName!.isNotEmpty)
                      Padding( // إضافة Padding هنا
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: [
                            Icon(Icons.person_pin_circle_outlined, size: 16, color: Colors.blueGrey.shade700),
                            const SizedBox(width: 6),
                            Text("السائق: ${task.driverName}", style: Get.textTheme.bodySmall?.copyWith(color: Colors.blueGrey.shade700)),
                          ],
                        ),
                      )
                    else if (task.assignedToDriverId != null && task.assignedToDriverId!.isNotEmpty) // إذا لم يوجد اسم، اعرض الـ ID
                      Padding( // إضافة Padding هنا
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: [
                            Icon(Icons.badge_outlined, size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Text("معرف السائق: ${task.assignedToDriverId!.length > 10 ? '${task.assignedToDriverId!.substring(0,10)}...' : task.assignedToDriverId}",
                                style: Get.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                    // -----

    Text("البائع: ${task.sellerName ?? 'غير محدد'}", style: Get.textTheme.bodySmall),
    Text("المشتري: ${task.buyerName ?? 'غير محدد'}", style: Get.textTheme.bodySmall),
    const SizedBox(height: 6),
    Align(
    alignment: Alignment.centerLeft,
    child: Text(
    // استخدم updatedTime إذا كان متاحًا ويعكس الاكتمال/الإلغاء، وإلا createdAt
    "التاريخ: ${DateFormat('yyyy/MM/dd hh:mm a', 'ar').format((task.updatedAt ?? task.createdAt).toDate())}",
    style: Get.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600, fontSize: 11),
    ),
    ),
    ],
    ),
    ),
    ),
    );
  }


  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 6.0,
        children: [
          // --- فلتر التاريخ ---
          Obx(() => ActionChip(
              avatar: Icon(Icons.date_range_outlined, size: 18, color: controller.selectedDateRange.value != null ? Get.theme.colorScheme.onPrimaryContainer : null),
              label: Text(controller.selectedDateRange.value != null
                  ? "${DateFormat('yy/M/d','ar').format(controller.selectedDateRange.value!.start)} - ${DateFormat('yy/M/d','ar').format(controller.selectedDateRange.value!.end)}"
                  : "فلترة بالتاريخ"),
              onPressed: () => controller.pickDateRange(Get.context!),
              backgroundColor: controller.selectedDateRange.value != null ? Get.theme.colorScheme.primaryContainer : null,
              labelStyle: TextStyle(fontSize:12, color: controller.selectedDateRange.value != null ? Get.theme.colorScheme.onPrimaryContainer : null)
          )),
          if(controller.selectedDateRange.value != null)
            InkWell(onTap: controller.clearDateFilter, child: Icon(Icons.clear, size:18, color: Colors.grey)),

          // --- فلتر السائق (Dropdown) ---
          Obx(()=> controller.isLoadingDriversForFilter.value
              ? const Chip(label:Text("تحميل السائقين.."), avatar: SizedBox(width:12, height:12,child:CircularProgressIndicator(strokeWidth:1.5)))
              : (controller.companyDriversForFilter.isEmpty ? SizedBox.shrink() : PopupMenuButton<String?>(
            initialValue: controller.selectedDriverId.value,
            onSelected: controller.onDriverFilterChanged,
            tooltip: "فلترة حسب السائق",
            child: Chip(
              avatar: Icon(Icons.person_search_outlined, size:18, color: controller.selectedDriverId.value != null ? Get.theme.colorScheme.onSecondaryContainer: null),
              label: Text(
                  controller.selectedDriverId.value != null
                      ? controller.companyDriversForFilter.firstWhereOrNull((d) => d.uid == controller.selectedDriverId.value)?.name ?? "اختر سائق"
                      : "فلترة بالسائق",
                  style: TextStyle(fontSize:12, color: controller.selectedDriverId.value != null ? Get.theme.colorScheme.onSecondaryContainer : null)
              ),
              backgroundColor: controller.selectedDriverId.value != null ? Get.theme.colorScheme.secondaryContainer : null,
            ),
            itemBuilder: (BuildContext context) {
              List<PopupMenuEntry<String?>> items = [
                const PopupMenuItem<String?>(value: "all_drivers_filter_key", child: Text("كل السائقين"))
              ];
              items.addAll(controller.companyDriversForFilter.map((driver) {
                return PopupMenuItem<String?>(value: driver.uid, child: Text(driver.name));
              }).toList());
              return items;
            },
          ))
          ),

          // --- فلتر حالة المهمة (Dropdown) ---
          PopupMenuButton<DeliveryTaskStatus?>( // النوع هنا هو DeliveryTaskStatus? للسماح بـ null (الكل)
            initialValue: controller.selectedTaskStatus.value,
            onSelected: controller.onStatusFilterChanged, // هذه الدالة يجب أن تقبل DeliveryTaskStatus?
            tooltip: "فلترة حسب حالة المهمة",
            child: Chip(
              avatar: Icon(
                Icons.list_alt_rounded, // أيقونة مختلفة قليلاً للحالة
                size: 18,
                color: controller.selectedTaskStatus.value != null ? Get.theme.colorScheme.onTertiaryContainer : Colors.grey.shade600,
              ),
              label: Obx(() => Text(
                controller.selectedTaskStatus.value != null
                    ? getTaskStatusVisuals(controller.selectedTaskStatus.value!, Get.context!)['text'] as String? ?? 'اختر حالة' // Cast و fallback
                    : "فلترة بالحالة",
                style: TextStyle(
                  fontSize: 12,
                  color: controller.selectedTaskStatus.value != null ? Get.theme.colorScheme.onTertiaryContainer : Colors.grey.shade700,
                ),
              )),
              backgroundColor: controller.selectedTaskStatus.value != null
                  ? Get.theme.colorScheme.tertiaryContainer.withOpacity(0.8)
                  : Colors.grey.shade200,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ),
            itemBuilder: (BuildContext context) {
              List<PopupMenuEntry<DeliveryTaskStatus?>> items = [
                const PopupMenuItem<DeliveryTaskStatus?>(
                  value: null, // القيمة null لتمثيل "كل الحالات (الأرشيف)"
                  child: Text("كل الحالات (الأرشيف)"),
                )
              ];

              // --- الحالات التي تهم في الأرشيف ---
              // استخدم قيم enum الصحيحة
              final List<DeliveryTaskStatus> archiveStatuses = [
                DeliveryTaskStatus.delivered,
                DeliveryTaskStatus.delivery_failed,
                DeliveryTaskStatus.returned_to_seller,
                DeliveryTaskStatus.cancelled_by_seller,
                DeliveryTaskStatus.cancelled_by_buyer,
                DeliveryTaskStatus.cancelled_by_company_admin,
                DeliveryTaskStatus.cancelled_by_platform_admin,
                // أضف أي حالات "نهائية" أخرى تعتبرها جزءًا من الأرشيف
              ];
              // -------------------------------------

              items.addAll(archiveStatuses.map((status) {
                // تأكد أن getTaskStatusVisuals معرفة بشكل صحيح وتقبل DeliveryTaskStatus
                final visuals = getTaskStatusVisuals(status, context);
                return PopupMenuItem<DeliveryTaskStatus?>(
                    value: status,
                    child: Row( // عرض الأيقونة مع النص
                      children: [
                        Icon(visuals['icon'] as IconData?, color: visuals['textColor'] as Color?, size: 18),
                        SizedBox(width: 8),
                        Text(visuals['text'] as String? ?? 'حالة غير معروفة'), // Cast و fallback
                      ],
                    )
                );
              }).toList());
              return items;
            },
          ),
          if (controller.selectedDateRange.value != null || controller.selectedDriverId.value != null || controller.selectedTaskStatus.value != null || controller.historySearchController.text.isNotEmpty)
            ActionChip(label: Text("مسح كل الفلاتر", style:TextStyle(fontSize:11)), avatar: Icon(Icons.clear_all, size:16), onPressed: controller.clearAllFilters, visualDensity: VisualDensity.compact),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    // Get.put(CompanyTaskHistoryController(companyId: "YOUR_COMPANY_ID")); // أو Binding
    final ScrollController scrollControllerForPagination = ScrollController();

    // إضافة مستمع لـ scrollController لـ pagination
    scrollControllerForPagination.addListener(() {
      if (scrollControllerForPagination.position.pixels >= scrollControllerForPagination.position.maxScrollExtent - 200 && // قبل نهاية القائمة بـ 200 بكسل
          !controller.isLoadingMore.value &&
          controller.hasMoreTasks.value) {
        debugPrint("[TASK_HISTORY_UI] Reached end of list, loading more tasks...");
        controller.loadMoreTasks();
      }
    });


    return Scaffold(
      appBar: AppBar(
        title: const Text("سجل المهام للشركة"),
        actions: [
          Obx(() => (controller.isLoading.value && controller.tasksNeedingReassignment.isEmpty) // فقط عند التحميل الأولي والفارغ
              ? const Padding(padding: EdgeInsets.all(16), child: SizedBox(width:20, height:20, child:CircularProgressIndicator(strokeWidth: 2, color:Colors.white)))
              : IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: controller.resetAndFetchHistory, tooltip: "تحديث السجل")
          )
        ],
      ),
      body: Column(
        children: [
          // --- شريط البحث ---
          Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 10.0, 12.0, 5.0),
            child: TextField(
              controller: controller.historySearchController,
              decoration: InputDecoration(
                hintText: "ابحث برقم الطلب، اسم البائع/المشتري...",
                prefixIcon: const Icon(Icons.search, size: 22, color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: Theme.of(context).primaryColor, width:1.5)),
                filled: true,
                fillColor: Theme.of(context).canvasColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                suffixIcon: Obx(() => controller.historySearchQuery.value.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear, size:20, color: Colors.grey), onPressed: (){ controller.historySearchController.clear(); FocusScope.of(context).unfocus();})
                    : const SizedBox.shrink()),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          // --- ودجة الفلاتر ---
          Obx(() => _buildFilterChips()), // Obx لمراقبةisLoadingDriversForFilter


          // --- قائمة المهام ---
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.tasksNeedingReassignment.isEmpty) { // التحميل الأولي
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.errorMessage.value.isNotEmpty && controller.tasksNeedingReassignment.isEmpty) {
                return Center(child: Padding(padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, children:[ Text(controller.errorMessage.value, style: TextStyle(color: Colors.red)), SizedBox(height:10), ElevatedButton(onPressed: controller.resetAndFetchHistory, child: Text("إعادة المحاولة"))])));
              }
              if (controller.tasksNeedingReassignment.isEmpty) {
                return Center(
                    child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history_toggle_off_rounded, size: 70, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                  controller.historySearchQuery.value.isNotEmpty || controller.selectedDateRange.value != null || controller.selectedDriverId.value != null || controller.selectedTaskStatus.value != null
                                      ? "لا توجد مهام تطابق معايير الفلترة/البحث الحالية."
                                      : "لا يوجد سجل مهام لهذه الشركة بعد.",
                                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.grey))
                            ]))
                );
              }
              return RefreshIndicator( // للسحب للتحديث (يعيد تحميل الدفعة الأولى)
                onRefresh: () => controller.resetAndFetchHistory(),
                child: ListView.builder(
                  controller: scrollControllerForPagination, // لـ pagination
                  padding: const EdgeInsets.only(bottom: 16, top: 4),
                  itemCount: controller.tasksNeedingReassignment.length + (controller.hasMoreTasks.value ? 1 : 0), // +1 لمؤشر التحميل المزيد
                  itemBuilder: (context, index) {
                    if (index == controller.tasksNeedingReassignment.length && controller.hasMoreTasks.value) {
                      return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2.5)));
                    }
                    if(index >= controller.tasksNeedingReassignment.length) return SizedBox.shrink(); // احتياطي

                    final task = controller.tasksNeedingReassignment[index];
                    return _buildTaskHistoryCard(task, context);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}