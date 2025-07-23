
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart'; // <--- استيراد fl_chart

import '../../XXX/xxx_firebase.dart';
import '../../routes/app_routes.dart';
import '../الكود الخاص بمشرف التوصيل/DeliveryTaskDetailsForAdminScreen.dart';
import '../../Model/DeliveryTaskModel.dart';
import 'DriverDashboardController.dart';
import 'ProcessedTaskForDriverDisplay.dart'; // <--- استيراد responsive_framework

// استورد المتحكم، النماذج، AppRoutes، و utils/status_visuals.dart
// import 'driver_dashboard_controller.dart';
// import '../models/DeliveryDriverModel.dart';
// import '../models/DeliveryTaskModel.dart';
// import '../routes/app_routes.dart';
// import '../utils/status_visuals.dart'; // لـ getDriverAvailabilityVisuals

// (تعريف مؤقت لـ getDriverAvailabilityVisuals إذا لم تكن مستوردة)
Map<String, dynamic> getDriverAvailabilityVisuals(String statusKey, BuildContext context) { /* ... */ return {"text": statusKey, "color": Colors.grey, "icon": Icons.help}; }


class DriverDashboardScreen extends GetView<DriverDashboardController> {
  const DriverDashboardScreen({super.key});

  Widget _buildProfileHeader(BuildContext context, DriverDashboardController controller) { // تمرير controller
    final theme = Theme.of(context);
    return Obx(() { // الاستماع للتغيرات في currentDriver و isLoadingDriverProfile
      if (controller.isLoadingDriverProfile.value && controller.currentDriver.value == null) {
        // عرض هيكل بسيط أثناء التحميل الأولي
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              CircleAvatar(radius: 28, backgroundColor: Colors.grey.shade300),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 100, height: 18, color: Colors.grey.shade300), // Placeholder للاسم
                    const SizedBox(height: 4),
                    Container(width: 60, height: 14, color: Colors.grey.shade200),  // Placeholder للتقييم
                  ],
                ),
              ),
              Icon(Icons.edit_note_rounded, color: Colors.grey.shade300, size: 26),
            ],
          ),
        );
      }

      if (controller.driverProfileError.value.isNotEmpty && controller.currentDriver.value == null) {
        return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(children: [
              Icon(Icons.error_outline, color: Colors.red.shade300, size:30),
              SizedBox(width:10),
              Expanded(child: Text(controller.driverProfileError.value, style:TextStyle(color:Colors.red.shade700)))
            ])
        );
      }

      if (controller.currentDriver.value == null) {
        // هذا يعني أن التحميل انتهى ولم يتم العثور على ملف أو هناك خطأ آخر لم يُعين لـ driverProfileError
        return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("تعذر تحميل معلومات الملف الشخصي.", style: TextStyle(color: Colors.orange))
        );
      }

      // إذا تم تحميل بيانات السائق بنجاح
      final driver = controller.currentDriver.value!; // الآن يمكننا استخدام ! بأمان

      return Material( // لإضافة تأثير splash عند النقر
        color: Colors.transparent, // جعل Material شفاف
        child: InkWell(
          onTap: controller.goToProfileEdit, // <--- استدعاء الدالة في المتحكم
          borderRadius: BorderRadius.circular(12), // لنطاق تأثير النقر
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30, // زيادة طفيفة في الحجم
                  backgroundColor: theme.colorScheme.surfaceContainerHighest, // لون خلفية يتناسب مع الثيم
                  backgroundImage: driver.profileImageUrl != null && driver.profileImageUrl!.isNotEmpty
                      ? CachedNetworkImageProvider(driver.profileImageUrl!) // استخدم CachedNetworkImage
                      : null,
                  child: (driver.profileImageUrl == null || driver.profileImageUrl!.isEmpty)
                      ? Icon(Icons.person_rounded, size: 32, color: theme.colorScheme.onSurfaceVariant)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver.name.isNotEmpty ? driver.name : "اسم السائق", // قيمة افتراضية إذا كان الاسم فارغًا
                        style: Get.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.star_rounded, color: Colors.amber.shade600, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            "${driver.averageRating.toStringAsFixed(1)} (${NumberFormat.compact(locale: 'ar_SA').format(driver.numberOfRatings)} تقييم)",
                            style: Get.textTheme.bodyMedium?.copyWith(color: Colors.blueGrey.shade700),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container( // لتوفير خلفية بسيطة للأيقونة لجعلها أوضح
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
                        shape: BoxShape.circle
                    ),
                    child: Icon(Icons.arrow_forward_ios_rounded, color: theme.primaryColor, size: 20)
                ),
              ],
            ),
          ),
        ),
      );
    });
  }


  Widget _buildAvailabilityToggle(BuildContext context) {
    final theme = Theme.of(context);
    // قائمة الخيارات المعروضة للمستخدم
    final Map<String, String> availabilityOptionsDisplay = {
      "online_available": "متوفر", // نص أقصر للأزرار
      "on_break": "في استراحة",    // إذا كنت ستدعم هذه الحالة
      "offline": "غير متوفر",
    };
    // ترتيب العرض، تأكد أنه يطابق availabilityOptions في المتحكم إذا كنت تعتمد عليها
    final List<String> displayOrderKeys = controller.availabilityOptions; // استخدم القائمة من المتحكم

    return Obx(() {
      if (controller.currentDriver.value == null) { // إذا لم يتم تحميل بيانات السائق بعد
        return const SizedBox(height: 60, child: Center(child: Text("جاري تحميل حالة التوفر...")));
      }
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("حالة التوفر:", style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            LayoutBuilder(
                builder: (context, constraints) {
                  bool useVerticalLayout = constraints.maxWidth < 360; //  عرض أقل = تخطيط عمودي

                  return ToggleButtons(
                    direction: useVerticalLayout ? Axis.vertical : Axis.horizontal,
                    isSelected: displayOrderKeys.map((statusKey) => controller.availabilityStatusString.value == statusKey).toList(),
                    onPressed: (int index) {
                      // لا تسمح بالضغط إذا كان السائق في مهمة و availabilityStatusString هي on_task بالفعل
                      // أو إذا كان لا يزال يحمل currentTaskId
                      if (controller.availabilityStatusString.value == "on_task" &&
                          displayOrderKeys[index] != "on_task") { // إذا كان في مهمة ويحاول تغييرها لشيء آخر
                        Get.snackbar(
                            "لا يمكن التغيير",
                            "يجب إكمال مهمتك الحالية أولاً أو تغيير حالتك إلى 'غير متوفر' بعد إنهائها.",
                            backgroundColor: Colors.orange.shade300,
                            duration: Duration(seconds: 4)
                        );
                        return;
                      }
                      controller.updateAvailabilityStatus(displayOrderKeys[index]);
                    },
                    borderRadius: BorderRadius.circular(25.0),
                    selectedBorderColor: theme.primaryColorDark.withOpacity(0.8),
                    selectedColor: Colors.white,
                    fillColor: theme.primaryColor,
                    color: theme.primaryColorDark,
                    borderWidth: 1.5, // حدود أوضح قليلاً
                    constraints: BoxConstraints(
                      minHeight: 42.0,
                      //  للتأكد من أن الأزرار تملأ العرض المتاح في حالة التخطيط الأفقي
                      minWidth: useVerticalLayout
                          ? constraints.maxWidth - 4 //  مع هامش صغير
                          : (constraints.maxWidth - (2 * (displayOrderKeys.length - 1))) / displayOrderKeys.length - 4, // ناقص مسافة الفواصل
                    ),
                    children: displayOrderKeys.map((statusKey) {
                      // افترض أن لديك getDriverAvailabilityVisuals(String statusKey, BuildContext context)
                      final visuals = getDriverAvailabilityVisuals(statusKey, context);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0), // تباعد أفضل للنص
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(visuals['icon'], size: 18,
                                color: controller.availabilityStatusString.value == statusKey ? Colors.white : visuals['color']
                            ),
                            const SizedBox(width: 6),
                            Text(availabilityOptionsDisplay[statusKey] ?? statusKey, style: TextStyle(fontSize: 12.5, fontWeight: controller.availabilityStatusString.value == statusKey ? FontWeight.bold : FontWeight.normal)),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                }
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPerformanceSummaryCard(BuildContext context, DriverDashboardController controller) { // تمرير controller
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.compactCurrency(locale: 'ar_SA', symbol: FirebaseX.currency, decimalDigits: 0);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Obx(() { // مراقبة حالات التحميل والخطأ والبيانات
          if (controller.isLoadingPerformanceSummary.value && controller.completedTasksTodayCount.value == 0) { // التحميل الأولي
            return const SizedBox(height: 280, child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)));
          }
          if (controller.performanceSummaryError.value.isNotEmpty) {
            return SizedBox(height: 280, child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(controller.performanceSummaryError.value, style: TextStyle(color:Colors.red.shade700)),
              SizedBox(height:8), TextButton(onPressed: controller.fetchPerformanceSummary, child:Text("إعادة المحاولة"))
            ])));
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("ملخص الأداء", style: Get.textTheme.titleLarge?.copyWith(color: theme.primaryColorDark, fontWeight: FontWeight.w600)),
              const Divider(height: 18, thickness: 0.5),
              Row(
                children: [
                  // استخدام _buildStatItemSmall الذي أنشأناه سابقًا
                  _buildStatItemSmall("مهام مكتملة اليوم", controller.completedTasksTodayCount.value.toString(), Icons.check_circle_outline, Colors.green.shade600, context, onTap: controller.goToMyTasksHistory),
                  const SizedBox(width: 12),
                  _buildStatItemSmall("أرباح اليوم (تقريبي)", currencyFormat.format(controller.earningsTodayAmount.value), Icons.account_balance_wallet_outlined, Colors.blue.shade700, context, onTap: controller.goToEarnings),
                ],
              ),
              const SizedBox(height: 20),
              Text("المهام المكتملة - آخر 7 أيام", style: Get.textTheme.titleMedium?.copyWith(color: theme.primaryColorDark.withOpacity(0.9), fontWeight:FontWeight.w500)),
              const SizedBox(height: 10),
              // التأكد من أن _buildWeeklyTasksChart تستخدم controller
              _buildWeeklyTasksChart(context, controller), // الرسم البياني للمهام الأسبوعية
            ],
          );
        }),
      ),
    );
  }


  Widget _buildStatItemSmall(String label, String value, IconData icon, Color color, BuildContext context, {VoidCallback? onTap}){
    final theme = Theme.of(context);
    return Expanded(
        child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withOpacity(0.2), width: 0.8)
              ),
              child: Column(
                  children: [
                    Icon(icon, size: 28, color: color),
                    const SizedBox(height:6),
                    Text(value, style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color), textAlign: TextAlign.center),
                    const SizedBox(height:2),
                    Text(label, style: Get.textTheme.bodySmall?.copyWith(color:Colors.grey.shade700, fontSize: 11), textAlign: TextAlign.center, maxLines:1, overflow: TextOverflow.ellipsis),
                  ]
              ),
            )
        )
    );
  }
  // --- ويدجت لرسم بياني باستخدام fl_chart ---
  // In DriverDashboardScreen.dart

// In DriverDashboardScreen.dart

  Widget _buildWeeklyTasksChart(BuildContext context, DriverDashboardController controller) { // تمرير controller
    final theme = Theme.of(context);
    final DateFormat dayFormatter = DateFormat('E', 'ar_SA'); //  لعرض اسم اليوم المختصر

    return Obx(() { // لمراقبة weeklyTasksBarData و maxWeeklyTaskCountForChart
      if (controller.weeklyTasksBarData.isEmpty && !controller.isLoadingPerformanceSummary.value) {
        return Container(
          height: 180,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.grey.shade100.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8)
          ),
          child: Center(child: Text("لا توجد بيانات مهام مكتملة لعرضها في الرسم البياني الأسبوعي.", textAlign: TextAlign.center, style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade600, fontSize: 13))),
        );
      }
      // لا تعرض الرسم البياني أثناء التحميل الأولي إذا كانت البيانات لا تزال فارغة
      if (controller.isLoadingPerformanceSummary.value && controller.weeklyTasksBarData.isEmpty) {
        return SizedBox(height:180, child: Center(child: Text("تحميل بيانات الرسم...", style: TextStyle(color:Colors.grey.shade600))));
      }


      final List<BarChartGroupData> chartData = controller.weeklyTasksBarData.toList(); // الحصول على نسخة
      final double maxYValue = controller.maxWeeklyTaskCountForChart.value;

      return SizedBox(
        height: 190,
        child: Padding(
          padding: const EdgeInsets.only(top: 10.0, right: 10.0, left: 0.0), // تعديل الـ padding
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxYValue, // استخدام maxY المحسوب
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipBorderRadius: BorderRadius.circular(8), // استخدم BorderRadius.circular()
                  getTooltipColor: (BarChartGroupData group) { // دالة لإرجاع لون الخلفية
                    return Colors.blueGrey.shade800.withOpacity(0.9); // لون ثابت هنا
                  },
                  tooltipPadding: const EdgeInsets.all(8),
                  tooltipMargin: 10,
                  getTooltipItem: (BarChartGroupData group, int groupIndex, BarChartRodData rod, int rodIndex) {
                    //  قيمة x تمثل ترتيب اليوم (0 للأقدم، 6 لليوم)
                    //  يجب الحصول على التاريخ الفعلي لذلك اليوم لعرض اسم اليوم الصحيح
                    DateTime dayForTooltip = DateTime.now().subtract(Duration(days: 6 - group.x.toInt()));
                    String dayName = dayFormatter.format(dayForTooltip);

                    return BarTooltipItem(
                      '$dayName\n',
                      TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      children: <TextSpan>[
                        TextSpan(
                          text: "${rod.toY.round().toString()} ${rod.toY.round() == 1 ? 'مهمة' : (rod.toY.round() >=2 && rod.toY.round()<=10 ? 'مهام' : 'مهمة')}", // معالجة الجمع
                          style: TextStyle(color: Colors.yellow.shade200, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30, // مساحة للأرقام
                    interval: maxYValue > 0 ? (maxYValue / (maxYValue >= 10 ? 5 : (maxYValue >= 3 ? 2 : 1))).ceilToDouble().clamp(1, double.infinity) : 1,
                    getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(left:4.0), // إبعاد الأرقام قليلاً عن المحور
                        child: Text( NumberFormat('0', 'ar').format(value.toInt()), style: TextStyle(fontSize: 9.5, color: Colors.grey.shade700))
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) { // قيمة x هي 0 إلى 6
                      final DateTime day = DateTime.now().subtract(Duration(days: 6 - value.toInt()));
                      final String dayText = dayFormatter.format(day); //  الاثنين، الثلاثاء...
                      return SideTitleWidget(meta: meta, space: 5, child: Text(dayText, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 9.5, color: Colors.black54)));
                    },
                    reservedSize: 24,
                    interval: 1, // لعرض كل يوم
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: chartData,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxYValue > 0 ? (maxYValue / (maxYValue >= 10 ? 5 : (maxYValue >= 3 ? 2 : 1))).ceilToDouble().clamp(1, double.infinity) : 1,
                getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade300.withOpacity(0.4), strokeWidth: 0.7, dashArray: [3,3]),
              ),
            ),
          ),
        ),
      );
    });
  }
  // -----------------------------------







  Widget _buildCurrentActiveTaskSummaryCard(BuildContext context) {
    final theme = Theme.of(context);

    // استخدام Obx للاستماع إلى processedActiveTaskForDashboard ومتغيرات أخرى
    return Obx(() {
      final ProcessedTaskForDriverDisplay? processedTask = controller.processedActiveTaskForDashboard.value;

      // شروط عرض ودجة التحميل:
      // 1. إذا كان `isLoadingActiveTask` صحيحًا (من المتحكم الرئيسي `activeTaskDetails`).
      // 2. و `processedActiveTaskForDashboard` لا يزال null (لم تتم معالجته بعد).
      // 3. و هناك بالفعل `currentFocusedTaskId` في ملف السائق (يعني نتوقع مهمة).
      if (controller.isLoadingActiveTask.value &&
          processedTask == null &&
          (controller.currentDriver.value?.currentFocusedTaskId?.isNotEmpty ?? false) ) {
        return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            elevation: 2,
            child: Padding(
                padding: const EdgeInsets.all(24.0), // Padding أكبر للتحميل
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5)),
                      const SizedBox(width: 16),
                      Text("جاري تحميل مهمتك النشطة...", style: Get.textTheme.bodyLarge?.copyWith(color: Colors.blueGrey))
                    ]
                )
            )
        );
      }

      // إذا لم تكن هناك مهمة نشطة معالجة أو السائق ليس في حالة "on_task"
      if (processedTask == null || controller.availabilityStatusString.value != "on_task") {
        return const SizedBox.shrink(); // لا تعرض شيئًا
      }

      // --- الآن لدينا processedTask، يمكننا بناء البطاقة ---
      final DeliveryTaskModel task = processedTask.task; // المهمة الأصلية
      final bool isActuallyFocusedTask = controller.currentDriver.value?.currentFocusedTaskId == task.taskId; // تحقق إضافي من التركيز الفعلي

      IconData cardIcon;
      String cardTitle;
      Color iconColor;
      String actionButtonText = "متابعة المهمة"; // نص الزر الافتراضي

      // --- **نفس منطق الـ SWITCH CASE الذي استخدمناه في MyTasksScreen._buildActiveTaskCard** ---
      // هذا يضمن تناسق المعلومات والأيقونات بين الشاشتين لنفس نوع المهمة.
      switch (processedTask.taskDisplayType) {
        case "pickup_hub_for_last_mile":
          cardIcon = Icons.meeting_room_outlined;
          cardTitle = "استلام من مقر: ${processedTask.nextActionName}";
          iconColor = Colors.teal.shade700; // استخدام لون أغمق وأكثر وضوحًا
          actionButtonText = "متابعة الاستلام من المقر";
          break;
        case "hub_to_hub":
          cardIcon = Icons.transfer_within_a_station_rounded;
          // تحديد النص بناءً على حالة المهمة داخل مهمة النقل
          if (task.status == DeliveryTaskStatus.driver_assigned ||
              task.status == DeliveryTaskStatus.en_route_to_pickup) { // pickup هنا يعني المقر المصدر
            cardTitle = "نقل من مقر: ${task.originHubName ?? processedTask.nextActionName}";
          } else { // يفترض أنه متجه للمقر الوجهة
            cardTitle = "نقل إلى مقر: ${task.destinationHubName ?? processedTask.nextActionName}";
          }
          iconColor = Colors.purple.shade700;
          actionButtonText = "متابعة النقل";
          break;
        case "pickup_seller":
          cardIcon = Icons.storefront_sharp; // أيقونة أكثر وضوحًا للبائع
          cardTitle = "استلام من بائع: ${processedTask.nextActionName}";
          iconColor = Colors.blue.shade700;
          actionButtonText = "متابعة الاستلام";
          break;
        case "delivery_buyer":
        default:
          cardIcon = Icons.person_pin_circle_sharp; // أيقونة أكثر وضوحًا للمشتري
          cardTitle = "تسليم إلى: ${processedTask.nextActionName}";
          iconColor = Colors.green.shade700;
          actionButtonText = "متابعة التسليم";
          // عرض عدد الطلبات الأخرى إذا كان تسليمًا مجمعًا
          if (processedTask.isConsolidatable && processedTask.consolidatableTasksCount > 0) {
            cardTitle += " (+${NumberFormat.compact(locale: 'ar').format(processedTask.consolidatableTasksCount)} طلبات أخرى)";
          }
          break;
      }
      // --- نهاية الـ SWITCH CASE ---

      final statusVisuals = getTaskStatusVisuals(task.status, context); // لجلب معلومات الحالة المرئية

      return Card(
        elevation: 3.0, // ظل أوضح قليلاً
        margin: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0), // هوامش قياسية
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
            side: BorderSide(color: iconColor.withOpacity(0.5), width: 1.0) // إطار بلون الأيقونة
        ),
        color: iconColor.withOpacity(0.06), // لون خلفية خفيف جدًا بناءً على نوع المهمة
        child: InkWell(
          onTap: controller.goToActiveTaskDetails, // الدالة للانتقال لشاشة الملاحة
          borderRadius: BorderRadius.circular(11.0),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 14.0, 16.0, 16.0), // padding متوازن
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- الصف العلوي: الأيقونة، عنوان المهمة، وحالة المهمة ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                        radius: 20, // حجم الأيقونة
                        backgroundColor: iconColor.withOpacity(0.2),
                        child: Icon(cardIcon, color: iconColor, size: 22)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(cardTitle,
                            style: Get.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600, fontSize: 15.5,
                                color: theme.textTheme.titleLarge?.color?.withOpacity(0.95)),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2)),
                    // عرض حالة المهمة الفعلية
                    Chip(
                      label: Text(statusVisuals['text'], style: TextStyle(color:statusVisuals['textColor'], fontSize:10, fontWeight:FontWeight.w500)),
                      avatar: Icon(statusVisuals['icon'], color: statusVisuals['textColor'], size:14),
                      backgroundColor: (statusVisuals['color'] as Color).withOpacity(0.8),
                      padding: const EdgeInsets.symmetric(horizontal:5, vertical:0),
                      labelPadding: const EdgeInsets.only(left:2, right:4), // تقليل padding للـ chip
                      visualDensity: VisualDensity.compact,
                    )
                  ],
                ),
                const SizedBox(height: 6),
                // --- الصف الثاني: رقم الطلب المرجعي ---
                Padding(
                  padding: const EdgeInsets.only(right: 52), //  محاذاة مع بداية النص أعلاه (بعد الأيقونة)
                  child: Text("الطلب: ${task.orderIdShort}",
                      style: Get.textTheme.bodySmall?.copyWith(color: Colors.blueGrey.shade700, fontSize: 12)),
                ),
                const Divider(height: 20, thickness: 0.35, endIndent: 10, indent:10),

                // --- الصف الثالث: المسافة والوقت المقدر (إذا توفر) ---
                if(processedTask.distanceToNextPointKm >= 0)
                  Padding(
                    padding: const EdgeInsets.only(left:0, right: 0, bottom: 10),
                    child: Row(
                        children: [
                          Icon(Icons.route_outlined, size:16, color:Colors.blueGrey.shade700),
                          SizedBox(width:6),
                          Text(processedTask.distanceDisplay, style:Get.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, fontSize:12.5)),

                          // --- **التعديل هنا** ---
                          if(controller.etaForDashboardActiveTask.value.isNotEmpty && // استخدم متغير الداشبورد
                              processedTask.distanceToNextPointKm > 0.03)
                            Text("  •  ${controller.etaForDashboardActiveTask.value}", // استخدم متغير الداشبورد
                                style:Get.textTheme.bodyMedium?.copyWith(fontSize:12.5, color:Colors.orange.shade900)),
                          // --- **نهاية التعديل** ---
                        ]
                    ),
                  ),
                const SizedBox(height: 18), // زيادة المسافة قبل الزر

                // --- الزر الرئيسي للانتقال للمهمة ---
                Center(
                  child: ElevatedButton.icon(
                      icon: const Icon(Icons.arrow_forward_rounded, size: 20), // أيقونة انتقال أوضح
                      label: Text(actionButtonText, style: const TextStyle(fontSize: 13.5, fontWeight:FontWeight.bold)),
                      onPressed: controller.goToActiveTaskDetails,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: iconColor.withOpacity(0.9), // لون الزر يتناسب مع نوع المهمة
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10), // padding للزر
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))
                      )),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }



  Widget _buildAvailableTasksAction(BuildContext context){
    final theme = Theme.of(context);
    // هذا القسم يظهر فقط إذا كان نظامك يعتمد على التقاط السائق للمهام
    // وإذا كان السائق متوفرًا حاليًا (online_available)
    return Obx((){
      if(controller.availabilityStatusString.value != "online_available" ||
          (controller.currentDriver.value?.approvedCompanyId ?? "").isEmpty ) {
        return const SizedBox.shrink();
      }
      return Card(
          elevation: 1.5,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: InkWell(
              onTap: controller.goToAvailableTasks,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal:16.0, vertical: 12.0),
                  child: Row(
                      children: [
                        Icon(Icons.explore_off_outlined, size:30, color: theme.colorScheme.secondary),
                        const SizedBox(width:12),
                        Expanded(child: Text("المهام الجديدة المتاحة", style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500))),
                        Obx(()=> controller.isLoadingAvailableTasksCount.value
                            ? const SizedBox(width:20, height:20, child:CircularProgressIndicator(strokeWidth:2))
                            : CircleAvatar(
                          radius:14,
                          backgroundColor: controller.availablePickupTasksCount.value > 0 ? theme.primaryColor : Colors.grey.shade400,
                          child: Text(controller.availablePickupTasksCount.value.toString(), style:const TextStyle(color:Colors.white, fontSize:11, fontWeight:FontWeight.bold)),
                        )
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade400, size:18)
                      ]
                  )
              )
          )
      );
    });
  }




  @override
  Widget build(BuildContext context) {
    // لتهيئة responsive_framework (توضع في GetMaterialApp أو أعلى ويدجت)
    // لكن إذا لم تكن هناك، لن تعمل ResponsiveValue بشكل صحيح
    // سأفترض أنك ستقوم بتهيئة هذا بشكل صحيح.

    return Scaffold(
      backgroundColor: Theme.of(context).canvasColor, // أو لون خلفية مخصص
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoadingDriverProfile.value && controller.currentDriver.value == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.currentDriver.value == null && !controller.isLoadingDriverProfile.value) {
            return Center(child: Padding(padding: const EdgeInsets.all(20),
                child: Text(controller.driverProfileError.value.isNotEmpty ? controller.driverProfileError.value : "فشل تحميل بيانات السائق. حاول مرة أخرى.",
                    textAlign: TextAlign.center, style: TextStyle(color:Colors.red.shade600)) ));
          }

          return   RefreshIndicator(
              onRefresh: () async {
            await controller.fetchPerformanceSummary();
            await controller.fetchAvailableTasksCount();
            // subscribeToDriverProfile هو stream، سيتحدث بنفسه.
            // أو يمكنك استدعاء controller.refreshAllData() إذا كانت موجودة
          },
          child: ListView( //  استخدم ListView مباشرة
          padding: const EdgeInsets.only(bottom: 20),
          children: [
          _buildProfileHeader(context, controller), //  مرر controller إذا لم تكن هذه GetView
          _buildAvailabilityToggle(context), // مرر controller
            _buildCurrentActiveTaskSummaryCard(context), // <--- استدعاء الودجة الجديدة هنا

            _buildPerformanceSummaryCard(context, controller), // مرر controller

            _buildAvailableTasksAction(context), // يفترض أنها تستخدم controller من GetView

          const Divider(indent:16, endIndent:16, height: 25, thickness:0.5),
          Padding(
          padding: const EdgeInsets.symmetric(horizontal:16.0,  vertical: 8.0),
          child: Text("خيارات إضافية:", style:Get.textTheme.titleMedium?.copyWith(color: Theme.of(context).primaryColorDark, fontWeight: FontWeight.w600))
          ),
          _buildNavigationButtonsGrid(context,controller), // هذه الدالة ستستخدم rf.ResponsiveValue داخليًا
            ],
          )
          );
        }),
      ),
    );
  }
// In DriverDashboardScreen.dart

// تأكد من استيراد هذه الحزم في أعلى الملف:
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:responsive_framework/responsive_framework.dart' as rf; // <--- مع الاسم المستعار
// import '../routes/app_routes.dart'; // <--- لأسماء المسارات
// import 'driver_dashboard_controller.dart'; // <--- المتحكم

  Widget _buildNavigationButtonsGrid(BuildContext context, DriverDashboardController controller) {
    final theme = Theme.of(context);

    List<Map<String, dynamic>> navItems = [
      { "label": "مهامي", "icon": Icons.list_alt_rounded, "routeName": AppRoutes.DRIVER_MY_TASKS, },
      {
        "label": "المهام المتاحة", "icon": Icons.explore_outlined,
        "routeName": AppRoutes.DRIVER_AVAILABLE_TASKS,
        "isVisible": () => controller.availabilityStatusString.value == "online_available" &&
            (controller.currentDriver.value?.approvedCompanyId ?? "").isNotEmpty,
      },
      { "label": "الأرباح", "icon": Icons.account_balance_wallet_outlined, "routeName": AppRoutes.DRIVER_EARNINGS, },
      {
        "label": "الملف الشخصي", "icon": Icons.person_outline_rounded,
        "routeName": AppRoutes.DRIVER_PROFILE_EDIT,
        "arguments": {'driverId': controller.driverId}
      },
      // يمكنك إضافة المزيد هنا
    ];

    List<Map<String, dynamic>> visibleNavItems = navItems.where((item) {
      if (item['isVisible'] is Function) {
        return (item['isVisible'] as Function)();
      }
      return true;
    }).toList();

    // --- تحديد عدد الأعمدة بناءً على عرض الشاشة باستخدام ScreenUtil ---
    // هذه مجرد نقطة بداية، يمكنك تعديل قيم العرض لتناسب تصميمك
    int crossAxisCount = 2; // الافتراضي للهواتف الصغيرة
    double screenWidth = ScreenUtil().screenWidth; // احصل على عرض الشاشة من ScreenUtil

    if (screenWidth >= 1200) { // DESKTOP (مثال)
      crossAxisCount = 4; // أو 5
    } else if (screenWidth >= 700) { // TABLET (مثال)
      crossAxisCount = 3;
    }
    //  else { crossAxisCount = 2; } // للهواتف (افتراضي)

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h), // استخدم .w و .h
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 12.h, right: 2.w),
            child: Text(
              "أدوات ووصول سريع:",
              style: Get.textTheme.titleMedium?.copyWith(
                color: theme.primaryColorDark,
                fontWeight: FontWeight.w600,
                fontSize: 16.sp, // استخدام .sp لحجم الخط
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visibleNavItems.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount, // عدد الأعمدة المحسوب
              crossAxisSpacing: 12.w, // مسافة أفقية نسبية
              mainAxisSpacing: 12.h,   // مسافة عمودية نسبية
              childAspectRatio: 1.5,    // نسبة العرض إلى الارتفاع (يمكنك تجربتها، 1.5 تجعل العرض أكبر قليلاً)
              // مثال: إذا كان الزر مربعًا تقريبًا childAspectRatio: 1.0 أو 1.1
              // إذا كان أعرض: 1.5, 1.6
              // إذا كان أطول: 0.8, 0.7
            ),
            itemBuilder: (context, index) {
              var item = visibleNavItems[index];
              return Card(
                elevation: 2.0.sp, // الظل يمكن أن يكون نسبيًا أيضًا
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r), // نصف قطر نسبي
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: item['routeName'] != null
                      ? () {
                    final route = item['routeName'] as String;
                    final args = item['arguments'] as Map<String, dynamic>?;
                    String processedRoute = route;
                    //  تبسيط منطق استبدال البارامتر (يفترض أن البارامترات هي الجزء الأخير بعد :)
                    if (route.contains(":")) {
                      args?.forEach((key, value) { // هذا بسيط، قد تحتاج لمنطق أكثر قوة إذا كانت البارامترات متعددة ومعقدة
                        if(route.contains(":$key")){
                          processedRoute = route.replaceFirst(":$key", value.toString());
                        }
                      });
                      // إذا كان لا يزال يحتوي على ':' بعد المعالجة، قد يعني أن argument مفقود
                      if(processedRoute.contains(":")){
                        debugPrint("Warning: Route $processedRoute still contains parameters after processing arguments. Navigating with original route and args.");
                        Get.toNamed(route, arguments: args); // ارجع للطريقة الأصلية إذا فشل الاستبدال المعقد
                        return;
                      }
                    }
                    Get.toNamed(processedRoute, arguments: (args != null && route == processedRoute) ? args : null ); //  مرر args فقط إذا لم يتم استبدال البارامتر في المسار
                  }
                      : (item['onTap'] as VoidCallback?),
                  borderRadius: BorderRadius.circular(12.r),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        size: 30.sp, // حجم أيقونة نسبي
                        color: theme.primaryColorDark,
                      ),
                      SizedBox(height: 8.h), // مسافة نسبية
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: Text(
                          item['label'] as String,
                          textAlign: TextAlign.center,
                          style: Get.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 12.sp, // حجم خط نسبي
                            color: theme.textTheme.bodyLarge?.color?.withOpacity(0.9),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

}