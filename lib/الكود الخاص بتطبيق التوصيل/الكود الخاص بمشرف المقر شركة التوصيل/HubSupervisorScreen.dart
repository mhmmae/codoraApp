// hub_supervisor_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../الكود الخاص بمشرف التوصيل/DeliveryTaskModel.dart';
import 'HubSupervisorController.dart';

// افترض استيراد المتحكم والنموذج


class HubSupervisorScreen extends GetView<HubSupervisorController> {
  const HubSupervisorScreen({super.key});

  // ودجة لبناء بطاقة لكل شحنة واصلة للمقر
  Widget _buildTaskAtHubCard(DeliveryTaskModel task, BuildContext context) {
    final theme = Theme.of(context);
    // Obx هنا ليست ضرورية إذا كانت البطاقة تُعاد بناؤها بواسطة Obx للـ ListView.builder
    // ولكن إبقاؤها هنا يجعل البطاقة تتفاعل بشكل فردي مع تغيير حالة isSelected.
    return Obx(() {
      final bool isSelected = controller.isTaskSelectedForConsolidation(task.taskId);
      return Card(
        elevation: isSelected ? 3.5 : 1.8,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10), // تعديل طفيف للهامش
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // زيادة دائرية الحواف
            side: BorderSide(
                color: isSelected ? theme.primaryColorDark : Colors.grey.shade300,
                width: isSelected ? 1.8 : 0.8)), // إطار أوضح قليلاً للمحدد
        color: isSelected ? theme.primaryColor.withOpacity(0.08) : theme.cardColor, // لون خلفية مميز للمحدد
        child: InkWell(
          onTap: () => controller.toggleTaskForConsolidation(task),
          borderRadius: BorderRadius.circular(11), // ليتناسب مع البطاقة
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0), // تعديل padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start, // محاذاة جيدة إذا كان العنوان طويلاً
                  children: [
                    Expanded(
                      child: Text(
                        "طلب ${task.orderIdShort} (لـ: ${task.buyerName ?? 'مشتري غير معروف'})",
                        style: Get.textTheme.titleMedium?.copyWith( // استخدام titleMedium لتمييز أكبر
                            fontWeight: FontWeight.bold, // خط أعرض
                            color: isSelected ? theme.primaryColorDark : null),
                        maxLines: 2, // السماح بسطرين
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // تحسين بسيط لشكل الـ Checkbox، جعله أصغر قليلاً
                    Transform.scale(
                      scale: 0.85,
                      child: Checkbox(
                        value: isSelected,
                        onChanged: (bool? val) => controller.toggleTaskForConsolidation(task),
                        activeColor: theme.primaryColorDark,
                        visualDensity: VisualDensity.compact,
                        side: WidgetStateBorderSide.resolveWith( //  تغيير لون الإطار للـ checkbox غير المحدد
                              (states) {
                            if (states.contains(WidgetState.selected)) {
                              return BorderSide(color: theme.primaryColorDark, width: 2);
                            }
                            return BorderSide(color: Colors.grey.shade400, width: 1.5);
                          },
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 4), // تقليل المسافة
                Row( // عرض معلومات البائع في صف
                  children: [
                    Icon(Icons.storefront, size: 15, color: Colors.blueGrey.shade700),
                    const SizedBox(width: 5),
                    Expanded(child: Text("من البائع: ${task.sellerShopName ?? task.sellerName ?? 'غير محدد'}", style: Get.textTheme.bodySmall?.copyWith(color: Colors.blueGrey.shade700, fontSize:11.5))),
                  ],
                ),
                Row( // عرض المحافظة في صف
                  children: [
                    Icon(Icons.public_rounded, size: 15, color: Colors.teal.shade700),
                    const SizedBox(width: 5),
                    Text("محافظة المشتري: ${task.province ?? 'غير محددة'}", style: Get.textTheme.bodySmall?.copyWith(color: Colors.teal.shade700, fontSize:11.5, fontWeight:FontWeight.w500)),
                  ],
                ),
                if(task.hubDropOffTime != null) // التأكد من أن الوقت موجود
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row( // عرض وقت الوصول للمقر
                      children: [
                        Icon(Icons.watch_later_outlined, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 5),
                        Text("وصلت للمقر: ${DateFormat('dd/MM hh:mm a','ar').format(task.hubDropOffTime!.toDate())}", style: Get.textTheme.labelSmall?.copyWith(fontSize:10.5)),
                      ],
                    ),
                  ),
                const SizedBox(height: 6),
                // (اختياري) يمكنك إضافة ملخص صغير للمنتجات إذا كان itemsSummary كبيرًا جدًا للعرض الكامل
                if(task.itemsSummary != null && task.itemsSummary!.isNotEmpty)
                  Text(
                      task.itemsSummary!.length == 1
                          ? "تحتوي على: ${task.itemsSummary!.first['itemName'] ?? 'منتج واحد'}"
                          : "تحتوي على ${task.itemsSummary!.length} منتجات مختلفة.",
                      style: const TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic, color: Colors.black54)
                  )
              ],
            ),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // companyId و hubId و hubName يجب أن يتم تمريرها للمتحكم عبر الـ Binding
    // بناءً على المستخدم الذي سجل الدخول.
    final theme = Theme.of(context);

    if(controller.hubId.isEmpty && !controller.isLoadingTasksAtHub.value){
      return Scaffold(appBar:
      AppBar(title:Text("إدارة مقر الشركة")),

          body: Center(child:Text(controller.tasksAtHubError.value.isNotEmpty ? controller.tasksAtHubError.value : "لم يتم تحديد مقر لهذا المشرف.",
              style:TextStyle(color:Colors.red.shade600))));
    }


    return Scaffold(
      appBar: AppBar(
        title: Text("إدارة شحنات مقر: ${controller.hubName}"),
        actions: [
          Obx(() {
            final String statusText = controller.connectionStatus.value;
            // تحديد حالة الاتصال بشكل أكثر دقة (تعتمد على القيمة من المكتبة)
            bool isEffectivelyConnected = controller.selectedPrinterDevice.value != null &&
                !controller.isConnectingToPrinter.value &&
                (statusText.toLowerCase().contains("connected") || statusText.startsWith("متصل"));


            if (controller.isConnectingToPrinter.value) {
              return const Padding(
                  padding: EdgeInsets.symmetric(horizontal:16.0, vertical:18.0),
                  child: SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white70, strokeWidth: 2)));
            }
            return IconButton(
              icon: Icon(isEffectivelyConnected ? Icons.bluetooth_connected_rounded : Icons.print_outlined, // تغيير أيقونة "غير متصل"
                  color: isEffectivelyConnected ? Colors.lightGreenAccent.shade200 : Colors.white.withOpacity(0.8)),
              tooltip: isEffectivelyConnected
                  ? "متصل بالطابعة: ${controller.selectedPrinterDevice.value?.name ?? ''}\n($statusText)"
                  : (statusText == "غير متصل" || statusText.toLowerCase().contains("none")
                  ? "الاتصال بطابعة بلوتوث"
                  : "حالة الطابعة: $statusText"),
              onPressed: () {
                if (isEffectivelyConnected) { // إذا كان متصلاً بالفعل
                  Get.defaultDialog(
                      title: "إدارة اتصال الطابعة",
                      titleStyle: Get.textTheme.titleLarge,
                      middleText: "الطابعة '${controller.selectedPrinterDevice.value?.name}' متصلة حاليًا.",
                      actions: [
                        TextButton(
                            onPressed: (){
                              Get.back(); // أغلق حوار التأكيد
                              controller.disconnectPrinter(); // اقطع الاتصال
                            },
                            child: const Text("قطع الاتصال", style:TextStyle(color: Colors.redAccent))
                        ),
                        const SizedBox(width:8),
                        TextButton(
                            onPressed: (){
                              Get.back(); // أغلق الحوار الحالي
                              controller.scanAndSelectPrinter(); // ابدأ عملية مسح جديدة لاختيار طابعة أخرى
                            },
                            child: const Text("البحث عن/تغيير الطابعة")
                        ),
                        const SizedBox(width:8),
                        ElevatedButton(onPressed: ()=>Get.back(), child: Text("إبقاء الاتصال"))
                      ],
                      barrierDismissible: true
                  );
                } else { // إذا لم يكن متصلاً
                  controller.scanAndSelectPrinter(); // ابدأ عملية المسح والاختيار والاتصال
                }
              },
            );
          }),
          // ,
          Obx(()=> controller.isLoadingTasksAtHub.value
              ? const Padding(padding: EdgeInsets.all(16), child: SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2, color:Colors.white)))
              : IconButton(icon: const Icon(Icons.refresh), onPressed: controller.subscribeToTasksAtHub)
          )
        ],
      ),
      body: Column(
        children: [
          // --- منطقة التحكم في التجميع ---
          Obx(() {
            if (controller.selectedTasksForConsolidation.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text("حدد الشحنات (لنفس المشتري) من القائمة أدناه لتجميعها.", style:TextStyle(color:Colors.blueGrey, fontStyle: FontStyle.italic), textAlign: TextAlign.center,),
              );
            }
            final buyerNameToDisplay = controller.selectedTasksForConsolidation.first.buyerName ?? controller.currentConsolidationBuyerId.value;
            return Card(
              margin: const EdgeInsets.fromLTRB(10, 10, 10, 6), // تعديل الهوامش
              elevation: 2.5,
              color: theme.colorScheme.primaryContainer.withOpacity(0.7), // لون أكثر هدوءًا
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  children: [
                    if (controller.isProcessingAction.value) // مؤشر تحميل عام إذا كان أي إجراء تجميع قيد التنفيذ
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Row(mainAxisAlignment:MainAxisAlignment.center, children: [SizedBox(width:18, height:18,child:CircularProgressIndicator(strokeWidth:2)), SizedBox(width:10),Text("جاري المعالجة...", style:TextStyle(fontSize:13))]),
                      )
                    else
                      Text(
                          controller.selectedTasksForConsolidation.isEmpty // رسالة مختلفة إذا لم يتم التحديد
                              ? "اختر شحنات أولاً..."
                              : "تجميع (${controller.selectedTasksForConsolidation.length}) شحنة للمشتري: \"$buyerNameToDisplay\"",
                          style:Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        TextButton.icon(
                            icon: const Icon(Icons.clear_all_rounded, size:18),
                            label: const Text("مسح التحديد", style:TextStyle(fontSize:12)),
                            onPressed: controller.isProcessingAction.value ? null : controller.clearConsolidationSelection,
                            style: TextButton.styleFrom(foregroundColor: theme.textTheme.bodySmall?.color)
                        ),
                        const Spacer(),
                        // زر التوصيل للمشتري (الميل الأخير)
                        Obx(() {
                          final bool thisButtonLoading = controller.isProcessingAction.value && !controller.transferToAnotherHubForButtonState.value;
                          return ElevatedButton.icon(
                            icon: thisButtonLoading
                                ? const SizedBox(width:16, height:16, child: CircularProgressIndicator(color:Colors.white, strokeWidth:1.8))
                                : const Icon(Icons.local_shipping, size:18),
                            label: const Text("للمشتري"),
                            onPressed: controller.isProcessingAction.value || controller.selectedTasksForConsolidation.isEmpty ? null : () async {
                              controller.transferToAnotherHubForButtonState.value = false;
                              await controller.createConsolidatedPackageAndNextTask(context, transferToAnotherHub: false);
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal:16, vertical:9),
                              backgroundColor: thisButtonLoading ? Colors.grey : theme.primaryColor,
                            ),
                          );
                        }),
                        const SizedBox(width:8),
                        // زر النقل لمقر آخر
                        Obx(() {
                          final bool thisButtonLoading = controller.isProcessingAction.value && controller.transferToAnotherHubForButtonState.value;
                          return OutlinedButton.icon(
                            icon: thisButtonLoading
                                ? const SizedBox(width:16, height:16, child: CircularProgressIndicator(strokeWidth:1.8))
                                : const Icon(Icons.transfer_within_a_station, size:18),
                            label: const Text("لمقر آخر"),
                            onPressed: controller.isProcessingAction.value || controller.selectedTasksForConsolidation.isEmpty ? null : () async {
                              controller.transferToAnotherHubForButtonState.value = true;
                              await controller.createConsolidatedPackageAndNextTask(context, transferToAnotherHub: true);
                            },
                            style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal:16, vertical:9),
                                foregroundColor: thisButtonLoading ? Colors.grey : theme.colorScheme.secondary,
                                side: BorderSide(color:thisButtonLoading ? Colors.grey.shade300 : theme.colorScheme.secondary.withOpacity(0.7))
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          // -----------------------------
          Expanded(
            child: Obx(() {
              if (controller.isLoadingTasksAtHub.value && controller.tasksAtHubAwaitingProcessing.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.tasksAtHubError.value.isNotEmpty) {
                return Center(child: Text(controller.tasksAtHubError.value, style:const TextStyle(color: Colors.red)));
              }
              if (controller.tasksAtHubAwaitingProcessing.isEmpty) {
                return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children:[
                        Icon(Icons.inbox_rounded, size:60, color: Colors.grey), SizedBox(height:10),
                        Text("لا توجد شحنات واصلة تنتظر المعالجة في هذا المقر حاليًا.", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color:Colors.grey)),
                      ]),
                    )
                );
              }
              return RefreshIndicator( //  إضافة RefreshIndicator هنا
                onRefresh: () async => controller.subscribeToTasksAtHub(),
                child: ListView.builder(
                  padding: const EdgeInsets.only(top:6, bottom: 20), // تقليل padding العلوي
                  itemCount: controller.tasksAtHubAwaitingProcessing.length,
                  itemBuilder: (ctx, index) {
                    final task = controller.tasksAtHubAwaitingProcessing[index];
                    return _buildTaskAtHubCard(task, ctx); // استخدام البطاقة المُحسَّنة
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