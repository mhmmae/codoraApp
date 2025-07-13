import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart'; // <--- استيراد مكتبة الرسوم البيانية

import '../../XXX/xxx_firebase.dart';
import 'CompanyReportsController.dart';
import 'DeliveryTaskDetailsForAdminScreen.dart';
import 'DeliveryTaskModel.dart';
import 'DriverPerformanceData.dart'; // إذا كنت ستعرض Heatmap على GoogleMap

// ... (استيراد المتحكم والنماذج و utils/status_visuals.dart) ...

class CompanyReportsScreen extends GetView<CompanyReportsController> {
  const CompanyReportsScreen({super.key});

  // (نسخ _buildReportCard, _buildKPIWidget, _buildStatItem من الرد السابق)

  // --- ويدجت لجدول أداء السائقين مع الفرز ---
  Widget _buildDriverPerformanceTable() {
    return Obx(() {
      if (controller.driverPerformanceList.isEmpty) {
        return const Padding(padding: EdgeInsets.all(16.0), child:Center(child: Text("لا توجد بيانات أداء للسائقين لهذه الفترة.", style: TextStyle(fontStyle: FontStyle.italic))));
      }
      // يجب أن يكون DriverSortOption معرفًا ويمكن الوصول إليه هنا
      // final Map<DriverSortOption, String> sortOptionsDisplay = {
      //   DriverSortOption.completedTasksDesc: "الأكثر إنجازًا للمهام",
      //   DriverSortOption.avgTimeDesc: "الأسرع (متوسط وقت أقل)",
      //   // ...
      // };

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- اختيار طريقة الفرز ---
          // PopupMenuButton<DriverSortOption>(
          //   onSelected: controller.changeDriverSortOption,
          //   itemBuilder: // ...
          //   child: Obx(()=> Chip(label: Text("فرز حسب: ${sortOptionsDisplay[controller.selectedDriverSortOption.value]}"))),
          // ),
          SingleChildScrollView( // لجعل الجدول أفقيًا قابل للتمرير إذا كانت الأعمدة كثيرة
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 18.0,
              headingRowHeight: 40,
              dataRowMinHeight: 48,
              dataRowMaxHeight: 56,
              columns: const [
                DataColumn(label: Text('السائق', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('مهام مكتملة', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                DataColumn(label: Text('متوسط وقت التوصيل', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('إجمالي مسافة (كم)', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                DataColumn(label: Text('رسوم محصلة', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                DataColumn(label: Text('التقييم', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
              ],
              rows: controller.driverPerformanceList.map((driverData) {
                return DataRow(cells: [
                  DataCell(Row(children: [
                    // CircleAvatar(radius:12, backgroundImage: driverData.driverProfileImageUrl!=null? NetworkImage(driverData.driverProfileImageUrl!) : null),
                    // SizedBox(width:5),
                    Text(driverData.driverName.length > 15 ? '${driverData.driverName.substring(0,12)}...' : driverData.driverName)
                  ])),
                  DataCell(Text(driverData.completedTasks.toString())),
                  DataCell(Text(driverData.averageDeliveryTimeFormatted)),
                  DataCell(Text((driverData.totalDistanceCoveredKm ?? 0.0).toStringAsFixed(1))),
                  DataCell(Text(NumberFormat.compactCurrency(locale:'ar_SA', symbol: FirebaseX.currency, decimalDigits:0).format(driverData.totalFeesGenerated))),
                  DataCell(Text("${driverData.driverOverallRating.toStringAsFixed(1)} ⭐")),
                ]);
              }).toList(),
            ),
          ),
        ],
      );
    });
  }
// يمكن وضعها كدالة خاصة داخل CompanyReportsScreen أو في ملف utils





  // يمكن وضعها كدالة خاصة داخل CompanyReportsScreen أو في ملف utils
// وتعتمد على controller من CompanyReportsController

  Widget _buildKPIWidget(BuildContext context, CompanyReportsController controller) {
    final formatter = NumberFormat.compactCurrency(locale: 'ar_SA', symbol: FirebaseX.currency, decimalDigits: 0); // لرسوم التوصيل
    final percentageFormatter = NumberFormat("##0.0# '%'", "ar_SA"); // لتنسيق النسبة المئوية

    // يمكنك هنا تحديد KPIs لفترة المقارنة أيضًا إذا كان وضع المقارنة مفعلًا
    bool comparisonMode = controller.showComparison.value && controller.comparisonDateRange.value != null;

    return Column(
      children: [
        Row(
          children: [
            _buildStatItem(
                "المهام المكتملة",
                controller.totalCompletedTasks.value.toString(),
                Icons.playlist_add_check_circle_outlined,
                Colors.green.shade700,
                onTap: () { /* انتقل إلى قائمة المهام المكتملة المفصلة */ }
            ),
            const SizedBox(width: 10),
            _buildStatItem(
              "نسبة النجاح",
              percentageFormatter.format(controller.successRatePercentage.value / 100), // تقسم على 100 لأن NumberFormat يتوقع قيمة بين 0 و 1 للنسبة المئوية
              Icons.pie_chart_rounded,
              Colors.blue.shade700,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildStatItem(
              "إجمالي رسوم التوصيل",
              formatter.format(controller.totalDeliveryFeesCollected.value),
              Icons.monetization_on_outlined,
              Colors.teal.shade700,
            ),
            const SizedBox(width: 10),
            _buildStatItem(
              "متوسط وقت التوصيل",
              controller.averageDeliveryTimeText.value,
              Icons.timer_rounded,
              Colors.purple.shade600,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildStatItem(
              "متوسط وقت (التعيين للاستلام)", // KPI جديد
              controller.averageTimeToPickup.value,
              Icons.transfer_within_a_station, // أيقونة مختلفة
              Colors.indigo.shade500,
            ),
            const SizedBox(width: 10),
            // يمكنك إضافة متوسط تقييم السائقين هنا إذا جلبته
            // _buildStatItem("متوسط تقييم السائقين", "${controller.averageDriverRatingForCompany.value.toStringAsFixed(1)} ⭐", Icons.stars_rounded, Colors.amber.shade700),
            Expanded(child: SizedBox()), // عنصر فارغ ليأخذ المساحة إذا لم يكن هناك KPI رابع
          ],
        ),

        // --- KPIs لفترة المقارنة (إذا كانت مفعلة) ---
        if (comparisonMode) ...[
          Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
            child: Text(
              "مقارنة مع الفترة: ${DateFormat('d/M/yy', 'ar').format(controller.comparisonDateRange.value!.start)} - ${DateFormat('d/M/yy', 'ar').format(controller.comparisonDateRange.value!.end)}",
              style: Get.textTheme.titleSmall?.copyWith(color: Colors.orange.shade800, fontWeight: FontWeight.w600),
            ),
          ),
          Row(
            children: [
              _buildStatItem(
                "مهام مكتملة (مقارنة)",
                controller.prevPeriodCompletedTasks.value.toString(),
                Icons.history_toggle_off_outlined, // أيقونة مختلفة للمقارنة
                Colors.blueGrey.shade600,
              ),
              const SizedBox(width: 10),
              _buildStatItem(
                "رسوم توصيل (مقارنة)",
                formatter.format(controller.prevPeriodDeliveryFees.value),
                Icons.trending_down_rounded, // أو trending_up
                Colors.blueGrey.shade600,
              ),
            ],
          ),
          // ... يمكنك إضافة المزيد من KPIs المقارنة بنفس الطريقة
        ]
      ],
    );
  }















  Widget _buildStatItem(
      String label,
      String value,
      IconData icon,
      Color color, {
        String? unit, // وحدة اختيارية بجانب القيمة (مثل "كم", "%")
        TextStyle? valueStyle,
        TextStyle? labelStyle,
        double iconSize = 28.0,
        VoidCallback? onTap, // لجعلها قابلة للنقر
      }) {
    final effectiveValueStyle = valueStyle ?? Get.textTheme.titleLarge?.copyWith(
      color: color,
      fontWeight: FontWeight.bold,
      fontSize: 20, // حجم خط أكبر قليلاً للقيمة
    );
    final effectiveLabelStyle = labelStyle ?? Get.textTheme.bodySmall?.copyWith(
      color: color.withOpacity(0.85), // شفافية طفيفة للlabel
      fontSize: 12.5,
    );

    return Expanded( // لجعل العناصر تأخذ مساحات متساوية في الصف
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10), // لنطاق النقر
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08), // لون خلفية خفيف جداً
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3), width: 0.8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: iconSize, color: color),
              const SizedBox(height: 8),
              Row( // لوضع القيمة والوحدة بجانب بعضهما
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline, // لمحاذاة الخط الأساسي
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(value, style: effectiveValueStyle, textAlign: TextAlign.center),
                  if (unit != null && unit.isNotEmpty) const SizedBox(width: 2),
                  if (unit != null && unit.isNotEmpty)
                    Text(unit, style: effectiveLabelStyle?.copyWith(fontSize: effectiveValueStyle?.fontSize != null ? effectiveValueStyle!.fontSize! * 0.7 : 10)), // وحدة أصغر قليلاً
                ],
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: effectiveLabelStyle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- ويدجت لرسم بياني شريطي لأداء السائقين (باستخدام fl_chart) ---
  Widget _buildDriverPerformanceBarChart(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      if (controller.driverPerformanceList.isEmpty) return const SizedBox.shrink();

      // تحديد أي مقياس ستعرضه في الرسم البياني (مثلاً، عدد المهام المكتملة)
      List<BarChartGroupData> barGroups = [];
      // عرض أفضل 5 سائقين مثلاً
      List<DriverPerformanceData> topDrivers = controller.driverPerformanceList.take(5).toList();

      for (int i = 0; i < topDrivers.length; i++) {
        final driver = topDrivers[i];
        barGroups.add(
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: driver.completedTasks.toDouble(),
                  color: theme.primaryColor.withOpacity(0.7 + (i*0.05).clamp(0,0.3)), // ألوان متفاوتة قليلاً
                  width: 20, // عرض الشريط
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
                ),
              ],
              // showingTooltipIndicators: [0], // إذا أردت عرض tooltip
            )
        );
      }

      if(barGroups.isEmpty) return Center(child: Text("لا توجد بيانات كافية للرسم البياني.", style: TextStyle(fontStyle: FontStyle.italic)));

      return SizedBox(
        height: 280,
        child: Padding(
          padding: const EdgeInsets.only(top: 16.0, right:8.0),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: (controller.driverPerformanceList.isNotEmpty ? controller.driverPerformanceList.map((d) => d.completedTasks).reduce(max).toDouble() : 10.0) * 1.2, // حد أقصى للمحور Y
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  // getTooltipColor: Colors.blueGrey,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final driver = topDrivers[group.x.toInt()];
                    return BarTooltipItem(
                      '${driver.driverName}\n',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      children: <TextSpan>[
                        TextSpan(
                          text: "المهام: ${rod.toY.round().toString()}",
                          style: TextStyle(color: Colors.yellow.shade200, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    );
                  },
                ),
                touchCallback: (FlTouchEvent event, barTouchResponse) { /* ... */ },
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < topDrivers.length) {
                        // --- التعديل هنا ---
                        final String driverNameToDisplay = topDrivers[index].driverName; // استخدم driverName
                        // ------------------
                        return Padding(
                            padding: const EdgeInsets.only(top:6.0),
                            child:Text(
                                driverNameToDisplay.length > 7 ? '${driverNameToDisplay.substring(0,6)}...' : driverNameToDisplay,
                                style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 10)
                            )
                        );
                      }
                      return const Text(''); // إرجاع ويدجت فارغة إذا لم يكن الفهرس صالحًا
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: (controller.driverPerformanceList.isNotEmpty ? (controller.driverPerformanceList.map((d) => d.completedTasks).reduce(max) / 5).ceilToDouble().clamp(1, double.infinity) : 2) , // فواصل ديناميكية للمحور Y
                      getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 10))
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: barGroups,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false, // لا ترسم خطوط الشبكة العمودية
                horizontalInterval: (controller.driverPerformanceList.isNotEmpty ? (controller.driverPerformanceList.map((d) => d.completedTasks).reduce(max) / 5).ceilToDouble().clamp(1, double.infinity) : 2),
                getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade300, strokeWidth: 0.5),
              ),
            ),
          ),
        ),
      );
    });
  }


  // --- ويدجت لرسم بياني دائري لتوزيع حالات المهام ---
  // In CompanyReportsScreen.dart

// In CompanyReportsScreen.dart, inside _buildTaskStatusPieChart

  Widget _buildTaskStatusPieChart(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      if (controller.taskStatusDistribution.isEmpty) {
        return const Center(child: Text("لا توجد بيانات لتوزيع الحالات.", style: TextStyle(fontStyle: FontStyle.italic)));
      }

      int totalTasksInDistribution = controller.taskStatusDistribution.values.fold(0, (prev, element) => prev + element);
      if (totalTasksInDistribution == 0) { // معالجة حالة أن جميع القيم صفر
        return const Center(child: Text("لا توجد مهام لعرضها في الرسم البياني.", style: TextStyle(fontStyle: FontStyle.italic)));
      }

      double radius = 90;

      // الخطوة 1: الحصول على الإدخالات كقائمة وفرزها
      List<MapEntry<String, int>> sortedEntries = controller.taskStatusDistribution.entries.toList();
      sortedEntries.sort((a, b) => b.value.compareTo(a.value)); // فرز تنازلي حسب العدد

      // الخطوة 2: تحويل الإدخالات المفرزة إلى List<PieChartSectionData> باستخدام map
      final List<PieChartSectionData> sections = sortedEntries
          .asMap() // للحصول على الفهرس بسهولة
          .entries
          .map((indexedEntry) {
        final int index = indexedEntry.key;
        final MapEntry<String, int> entry = indexedEntry.value; // الآن entry هو MapEntry<String, int>
        final String statusKey = entry.key;
        final int count = entry.value;

        final percentage = (count / totalTasksInDistribution * 100);
        final visuals = getTaskStatusVisuals(stringToDeliveryTaskStatus(statusKey), context);

        return PieChartSectionData(
          color: (visuals['color'] as Color?)?.withOpacity(0.7 + (index * 0.05).clamp(0,0.3)) ?? theme.primaryColor, // ألوان متفاوتة قليلاً
          value: count.toDouble(),
          title: '${percentage.toStringAsFixed(percentage < 10 ? 1 : 0)}%', // منزلة عشرية واحدة إذا كانت النسبة صغيرة
          radius: radius - (index * 2.5).clamp(0,15), // تعديل طفيف لنصف القطر
          titlePositionPercentageOffset: 0.6, // لضبط موضع النص داخل الشريحة
          titleStyle: TextStyle(
            fontSize: 10 + (percentage > 20 ? 2:0) - (percentage < 8 ? 1:0),
            fontWeight: FontWeight.bold,
            color: Colors.white, // لون أبيض للنص على الخلفيات الملونة
            shadows: const [Shadow(color: Colors.black54, blurRadius: 1.5, offset: Offset(0,1))],
          ),
          // يمكنك إبقاء الشارة أو إزالتها إذا كان الرسم البياني مزدحمًا
          // badgeWidget: Chip( /* ... */ ),
          // badgePositionPercentageOffset: 1.1 + (index * 0.07).clamp(0,0.35),
        );
      }).toList();

      if (sections.isEmpty) {
        return const Center(child: Text("لا توجد بيانات كافية لعرض الرسم البياني.", style: TextStyle(fontStyle: FontStyle.italic)));
      }

      return SizedBox(
        height: 250, // يمكنك تعديل الارتفاع
        child: PieChart(
          PieChartData(
            pieTouchData: PieTouchData(
              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                //  التعامل مع تفاعلات اللمس إذا أردت
                //  if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                //    // touchedIndex = -1; // لم يتم لمس أي قسم
                //    return;
                //  }
                //  // touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                //  // يمكنك هنا تحديث حالة ما لعرض تفاصيل إضافية عن القسم الملموس
              },
            ),
            borderData: FlBorderData(show: false),
            sectionsSpace: 2, // مسافة بين الأقسام
            centerSpaceRadius: 40, // اجعلها أصغر قليلاً لعرض النسب
            sections: sections,
            startDegreeOffset: -90, // لبدء الرسم من الأعلى
          ),
          // يمكنك إضافة خيارات إضافية لـ PieChart هنا
        ),
      );
    });
  }
  // --- ودجة لعرض بيانات الخريطة الحرارية (حالياً كنص) ---
  Widget _buildHeatmapSection() {
    return Obx(() {
      if (controller.pickupHeatmapPoints.isEmpty && controller.deliveryHeatmapPoints.isEmpty) {
        return const Text("لا توجد بيانات مواقع لعرض الخريطة الحرارية.", style: TextStyle(fontStyle: FontStyle.italic));
      }
      // لعرضها فعليًا كخريطة حرارية، ستحتاج لدمج GoogleMap هنا
      // مع تراكب مخصص (HeatmapTileProvider) أو استخدام حزمة مخصصة إذا وجدت.
      // حاليًا، سنعرض عدد النقاط فقط.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("نقاط الاستلام للخريطة الحرارية: ${controller.pickupHeatmapPoints.length} نقطة"),
          Text("نقاط التسليم للخريطة الحرارية: ${controller.deliveryHeatmapPoints.length} نقطة"),
          const SizedBox(height: 8),
          const Text("(تحذير: عرض الخريطة الحرارية الفعلي يتطلب تنفيذًا متقدمًا)", style: TextStyle(fontSize: 11, color: Colors.orange)),
          // مثال: يمكنك استخدام GoogleMap مع تلوين الماركرات بناءً على الكثافة بشكل مبدئي
          // أو استخدام حزمة مثل heatmap_flutter (إذا كانت مناسبة لحالتك)
          /*
            if(controller.pickupHeatmapPoints.isNotEmpty){
                SizedBox(height:200, child: GoogleMap(
                    initialCameraPosition: CameraPosition(target:controller.pickupHeatmapPoints.first, zoom:7),
                    markers: controller.pickupHeatmapPoints.map((e) => Marker(markerId: MarkerId(e.toString()), position:e, icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta))).toSet(),
                ))
            }
            */
        ],
      );
    });
  }
  Widget _buildReportCard({
    required String title,          // عنوان البطاقة (مطلوب)
    required Widget content,        // المحتوى الرئيسي للبطاقة (مطلوب)
    IconData? titleIcon,           // أيقونة اختيارية بجانب العنوان
    Color? iconColor,              // لون الأيقونة (إذا لم يكن من الثيم)
    Color? cardBackgroundColor,    // لون خلفية البطاقة (اختياري)
    Widget? topRightAction,        // ويدجت اختيارية للزاوية العلوية اليمنى (مثل زر "عرض الكل")
    EdgeInsetsGeometry? contentPadding, // لتخصيص padding المحتوى
    bool initiallyExpanded = true, // هل تكون البطاقة مفتوحة (إذا كانت قابلة للطي)
    bool isCollapsible = false,     // هل يمكن طي/فتح البطاقة
  }) {
    final theme = Theme.of(Get.context!); // استخدام Get.context! آمن هنا إذا كانت ضمن شاشة GetView

    // لون الأيقونة الافتراضي من الثيم إذا لم يتم توفيره
    final Color effectiveIconColor = iconColor ?? theme.colorScheme.primary;
    // لون الخلفية الافتراضي
    final Color effectiveCardBackgroundColor = cardBackgroundColor ?? theme.cardTheme.color ?? theme.cardColor;

    Widget titleWidget = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              if (titleIcon != null)
                Icon(titleIcon, size: 24, color: effectiveIconColor),
              if (titleIcon != null) const SizedBox(width: 10),
              Flexible( // لجعل النص يلتف إذا كان طويلاً
                child: Text(
                  title,
                  style: Get.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface, // لون نص يتناسب مع خلفية البطاقة
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (topRightAction != null) topRightAction,
      ],
    );

    Widget cardContent = Padding(
      padding: contentPadding ?? const EdgeInsets.only(top: 12.0, left: 4.0, right: 4.0, bottom: 4.0), // تعديل padding الافتراضي
      child: content,
    );

    // الهيكل الأساسي للبطاقة
    Widget baseCard = Card(
      elevation: 1.5,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        // side: BorderSide(color: theme.dividerColor.withOpacity(0.5), width: 0.5) // إطار خفيف إذا أردت
      ),
      color: effectiveCardBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // لجعل المحتوى يملأ العرض
          children: [
            titleWidget,
            const Divider(height: 20, thickness: 0.5, color: Colors.black12), // فاصل أنظف
            cardContent,
          ],
        ),
      ),
    );

    // إذا كانت البطاقة قابلة للطي، استخدم ExpansionTile
    if (isCollapsible) {
      return Card( // بطاقة خارجية لـ ExpansionTile ليبقى الشكل متناسقًا
        elevation: 1.5,
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        color: effectiveCardBackgroundColor,
        clipBehavior: Clip.antiAlias, // لمنع تجاوز محتوى ExpansionTile للحدود الدائرية
        child: ExpansionTile(
          key: PageStorageKey(title), // للمحافظة على حالة التوسيع/الطي عند التمرير
          backgroundColor: effectiveCardBackgroundColor, // لون الخلفية عند الفتح
          collapsedBackgroundColor: effectiveCardBackgroundColor,
          iconColor: theme.colorScheme.onSurfaceVariant,
          collapsedIconColor: theme.colorScheme.onSurfaceVariant,
          shape: const Border(), // إزالة الإطار الافتراضي لـ ExpansionTile
          title: titleWidget,
          initiallyExpanded: initiallyExpanded,
          childrenPadding: contentPadding ?? const EdgeInsets.fromLTRB(16.0, 0, 16.0, 12.0),
          // لا حاجة لـ Divider هنا لأن ExpansionTile لديها فاصلها الخاص (بشكل ضمني)
          children: <Widget>[content], // المحتوى داخل قائمة children
        ),
      );
    }

    return baseCard; // إذا لم تكن قابلة للطي
  }



  @override
  Widget build(BuildContext context) {
    // ... (appBar and initial Obx for loading/error) ...
    final theme = Theme.of(context); // تأكد من وجود هذا إذا كنت تستخدمه
    final NumberFormat currencyFormatter = NumberFormat.compactCurrency(locale: 'ar_SA', symbol: FirebaseX.currency, decimalDigits: 0);
    final DateFormat dateTimeFormatter = DateFormat('EEEE، dd MMMM yyyy - hh:mm a', 'ar');
    final DateFormat shortDateFormatter = DateFormat('d/M/yy', 'ar'); // تنسيق قصير لعرض النطاقات
    final DateFormat longDateTimeFormatter = DateFormat('EEEE، dd MMMM yyyy - hh:mm a', 'ar'); // تنسيق طويل

    return Scaffold(
      appBar: AppBar(
        title: const Text("تقارير أداء الشركة"),
        actions: [
          // --- زر لإظهار مؤشر التحميل العام ---
          Obx(() {
            if (controller.isLoading.value) { // عرض مؤشر تحميل إذا كان أي من العمليات الرئيسية جاري
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 18.0), // تعديل padding ليتناسب مع حجم AppBar
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white70)), // لون أفتح ليظهر على خلفية AppBar
              );
            }
            return const SizedBox.shrink(); // لا تعرض شيئًا إذا لم يكن هناك تحميل
          }),

          // --- PopupMenuButton لاختيار نطاق التاريخ ---
          PopupMenuButton<String>(
            icon: const Icon(Icons.calendar_month_outlined), // أيقونة أوضح للتقويم
            tooltip: "اختيار فترة التقرير",
            onSelected: (String value) {
              DateTime now = DateTime.now();
              DateTime startOfToday = DateTime(now.year, now.month, now.day);
              DateTime startOfThisWeek = now.subtract(Duration(days: now.weekday - 1)).copyWith(hour:0, minute:0, second:0, millisecond:0); // الاثنين
              DateTime startOfThisMonth = DateTime(now.year, now.month, 1);

              switch (value) {
                case 'today':
                  controller.updateDateRange(DateTimeRange(start: startOfToday, end: now));
                  break;
                case 'yesterday':
                  final yesterday = now.subtract(const Duration(days: 1));
                  controller.updateDateRange(DateTimeRange(start: yesterday.copyWith(hour:0,minute:0,second:0), end: yesterday.copyWith(hour:23,minute:59,second:59)));
                  break;
                case 'this_week':
                // السبت هو نهاية الأسبوع عادة في العديد من السياقات العربية
                  DateTime endOfThisWeek = startOfThisWeek.add(const Duration(days: 6)).copyWith(hour:23,minute:59,second:59);
                  if(startOfThisWeek.isAfter(now)) startOfThisWeek = startOfThisWeek.subtract(Duration(days:7)); // إذا بدأ الأسبوع في المستقبل (يحدث في بداية الأسبوع)
                  if(endOfThisWeek.isAfter(now)) endOfThisWeek = now;

                  controller.updateDateRange(DateTimeRange(start: startOfThisWeek, end: endOfThisWeek));
                  break;
                case 'last_week':
                  DateTime endOfLastWeek = startOfThisWeek.subtract(const Duration(days: 1)).copyWith(hour:23,minute:59,second:59);
                  DateTime startOfLastWeek = endOfLastWeek.subtract(const Duration(days: 6)).copyWith(hour:0,minute:0,second:0);
                  controller.updateDateRange(DateTimeRange(start: startOfLastWeek, end: endOfLastWeek));
                  break;
                case 'this_month':
                  controller.updateDateRange(DateTimeRange(start: startOfThisMonth, end: now));
                  break;
                case 'last_month':
                  DateTime firstDayOfThisMonth = DateTime(now.year, now.month, 1);
                  DateTime endOfLastMonth = firstDayOfThisMonth.subtract(const Duration(days: 1)).copyWith(hour:23,minute:59,second:59);
                  DateTime startOfLastMonth = DateTime(endOfLastMonth.year, endOfLastMonth.month, 1);
                  controller.updateDateRange(DateTimeRange(start: startOfLastMonth, end: endOfLastMonth));
                  break;
                case 'this_year':
                  controller.updateDateRange(DateTimeRange(start: DateTime(now.year, 1, 1), end: now));
                  break;
                case 'custom':
                // هذه الدالة ستعرض DateRangePicker وتستدعي controller.updateDateRange بالنتيجة
                  controller.pickDateRange(context);
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(value: 'today', child: Text('اليوم')),
              const PopupMenuItem<String>(value: 'yesterday', child: Text('الأمس')),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(value: 'this_week', child: Text('هذا الأسبوع')),
              const PopupMenuItem<String>(value: 'last_week', child: Text('الأسبوع الماضي')),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(value: 'this_month', child: Text('هذا الشهر')),
              const PopupMenuItem<String>(value: 'last_month', child: Text('الشهر الماضي')),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(value: 'this_year', child: Text('هذه السنة')),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(value: 'custom', child: Text('نطاق مخصص...')),
            ],
          ),
          // --- نهاية PopupMenuButton ---

          // --- IconButton لتفعيل/إلغاء وضع المقارنة ---
          Obx(() => IconButton(
            icon: Icon(
              controller.showComparison.value
                  ? Icons.compare_arrows_sharp // أيقونة مختلفة إذا كانت المقارنة مفعلة
                  : Icons.compare_outlined,
            ),
            tooltip: controller.showComparison.value
                ? "إلغاء وضع المقارنة"
                : "مقارنة مع فترة أخرى",
            onPressed: () {
              // تأكد أن controller.selectedDateRange.value ليست null قبل محاولة المقارنة
              if(controller.selectedDateRange.value == null && !controller.showComparison.value){
                Get.snackbar("تنبيه", "يرجى تحديد النطاق الزمني الرئيسي أولاً قبل تفعيل المقارنة.",
                    snackPosition: SnackPosition.BOTTOM, duration: Duration(seconds: 3));
                return;
              }
              controller.toggleComparisonModeAndPickDate(context);
            },
          )),
          // --- نهاية IconButton ---

          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: controller.loadAllReportData, tooltip: "تحديث البيانات") // زر تحديث عام
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.totalCompletedTasks.value == 0 && !controller.showComparison.value) {
          // اعرض مؤشر التحميل فقط إذا كان هذا هو الجلب الأولي ولم يتم تحميل أي بيانات بعد
          return const Center(child: CircularProgressIndicator());
        }

        // --- معالجة الخطأ ---
        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline_rounded, color: theme.colorScheme.error, size: 50),
                  const SizedBox(height: 12),
                  Text(
                    "فشل تحميل التقارير",
                    style: Get.textTheme.titleLarge?.copyWith(color: theme.colorScheme.error),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    controller.errorMessage.value, // رسالة الخطأ من المتحكم
                    textAlign: TextAlign.center,
                    style: Get.textTheme.bodyMedium?.copyWith(color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text("إعادة المحاولة"),
                      onPressed: controller.loadAllReportData,
                      style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.errorContainer, foregroundColor: theme.colorScheme.onErrorContainer)
                  ),
                ],
              ),
            ),
          );
        }

        String dateRangeText = "الفترة: ${shortDateFormatter.format(controller.selectedDateRange.value.start)} - ${shortDateFormatter.format(controller.selectedDateRange.value.end)}";
        String comparisonDateRangeText = "";
        if (controller.showComparison.value && controller.comparisonDateRange.value != null) {
          comparisonDateRangeText = "(مقارنة مع: ${shortDateFormatter.format(controller.comparisonDateRange.value!.start)} - ${shortDateFormatter.format(controller.comparisonDateRange.value!.end)})";
        }

        return RefreshIndicator(
          onRefresh: controller.loadAllReportData,
          child: ListView(
            padding: const EdgeInsets.all(12.0),
            children: [
              Center(
                  child: Column(
                    children: [
                      Text(dateRangeText, style: Get.textTheme.titleSmall?.copyWith(color: Colors.blueGrey.shade800, fontWeight: FontWeight.w500)),
                      if (controller.showComparison.value && comparisonDateRangeText.isNotEmpty)
                        Text(comparisonDateRangeText, style: Get.textTheme.labelMedium?.copyWith(color: Colors.orange.shade800)),
                    ],
                  )
              ),
              const SizedBox(height: 12),

              // --- استدعاء دوال بناء بطاقات التقارير ---
              _buildReportCard(
                title: "المؤشرات الرئيسية (KPIs)",
                content: _buildKPIWidget(context, controller), // مرر المتحكم هنا
                titleIcon: Icons.insights_rounded,
                iconColor: theme.primaryColor,
                isCollapsible: true,
                initiallyExpanded: true,
              ),

              if (controller.showComparison.value)
                _buildReportCard(
                  title: "KPIs (فترة المقارنة)",
                  content: _buildKPIWidget(context, controller), // _buildKPIWidget يجب أن تتعامل مع عرض بيانات المقارنة
                  titleIcon: Icons.compare_arrows_rounded,
                  iconColor: Colors.orange.shade800,
                  isCollapsible: true,
                  initiallyExpanded: true, // اجعلها مفتوحة عند تفعيل المقارنة
                ),

              _buildReportCard(
                title: "أداء السائقين",
                content: Column(children: [
                  _buildDriverPerformanceTable(), // تأكد من وجود هذه الدالة
                  const SizedBox(height: 16),
                  _buildDriverPerformanceBarChart(context), // تأكد من وجود هذه الدالة
                ]),
                titleIcon: Icons.groups_2_outlined, // أيقونة مختلفة
                iconColor: Colors.teal.shade700,
                topRightAction: TextButton(
                  onPressed: () { Get.snackbar("قريبًا", "سيتم فتح قائمة أداء جميع السائقين المفصلة."); },
                  child: Text("عرض الكل", style: TextStyle(fontSize: 12, color: theme.primaryColor)),
                ),
                isCollapsible: true,
              ),

              _buildReportCard(
                title: "تحليل المهام",
                content: Column( /* ... محتوى تحليل المهام كما في الرد السابق ... */
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("توزيع حالات المهام:", style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    _buildTaskStatusPieChart(context), // تأكد من وجودها
                    const SizedBox(height: 16),
                    Text("أسباب فشل/إلغاء (الأكثر شيوعًا):", style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    Obx((){ /* ... عرض أسباب الفشل ... */
                      if(controller.failureReasonsDistribution.isEmpty) return const Padding(padding: EdgeInsets.symmetric(vertical:8.0), child:Text(" لا توجد أسباب مسجلة.", style:TextStyle(fontStyle:FontStyle.italic, color: Colors.grey)));
                      return Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: controller.failureReasonsDistribution.entries.map((e) => Padding(
                              padding: const EdgeInsets.only(top: 2.0, right:8.0),
                              child: Text("• ${e.key}: ${e.value} مرة", style: Get.textTheme.bodyMedium),
                            )).toList()
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    _buildDetailItem(Icons.transfer_within_a_station_rounded, "متوسط وقت (التعيين للاستلام)", controller.averageTimeToPickup.value, context, iconColor: Colors.indigo.shade400), // استخدام _buildDetailItem هنا
                    _buildDetailItem(Icons.history_edu_outlined, "متوسط وقت (الاستلام للتسليم)", controller.averageTimeFromPickupToDelivery.value, context, iconColor: Colors.cyan.shade700), // تم تغيير الأيقونة
                  ],
                ),
                titleIcon: Icons.analytics_outlined,
                iconColor: Colors.purple.shade700,
                isCollapsible: true,
                initiallyExpanded: false,
              ),

              _buildReportCard(
                title: "التحليل الجغرافي (نقاط مبدئية)",
                content: _buildHeatmapSection(), // تأكد من وجودها
                titleIcon: Icons.map_outlined, // أيقونة أفضل
                iconColor: Colors.lightBlue.shade700,
                isCollapsible: true,
                initiallyExpanded: false,
              ),
            ],
          ),
        );
      }),
    );
  }



  // يمكن وضعها كدالة خاصة داخل CompanyReportsScreen أو DeliveryTaskDetailsForAdminScreen أو في ملف utils

  Widget _buildDetailItem(
      IconData icon,
      String label,
      String? value,
      BuildContext context, { // لا حاجة لتمرير context إذا كنت ستستخدم Get.textTheme أو theme.of(context)
        Color? iconColor,
        VoidCallback? onValueTap,      // لجعل القيمة قابلة للنقر
        bool isEmphasized = false,     // لتمييز قيمة معينة
        TextStyle? labelStyleOverride,
        TextStyle? valueStyleOverride,
        MainAxisAlignment rowMainAxisAlignment = MainAxisAlignment.start,
      }) {
    final theme = Theme.of(context); // أو Get.theme إذا كنت تفضل
    final String displayValue = value ?? 'غير متوفر';

    // تحديد الأنماط الافتراضية والمخصصة
    final TextStyle defaultLabelStyle = Get.textTheme.bodyLarge!.copyWith(
      color: Colors.blueGrey.shade800,
      fontWeight: FontWeight.w500,
    );
    final TextStyle defaultValueStyle = Get.textTheme.bodyLarge!.copyWith(
      color: onValueTap != null ? theme.colorScheme.primary : (isEmphasized ? theme.colorScheme.error : Colors.black87),
      fontWeight: isEmphasized ? FontWeight.w600 : FontWeight.normal,
      decoration: onValueTap != null ? TextDecoration.underline : TextDecoration.none,
    );

    final TextStyle effectiveLabelStyle = labelStyleOverride ?? defaultLabelStyle;
    final TextStyle effectiveValueStyle = valueStyleOverride ?? defaultValueStyle;


    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // محاذاة جيدة للنصوص متعددة الأسطر
        mainAxisAlignment: rowMainAxisAlignment,
        children: [
          Icon(icon, size: 20, color: iconColor ?? theme.colorScheme.secondary.withOpacity(0.9)),
          const SizedBox(width: 10),
          Text("$label: ", style: effectiveLabelStyle),
          // استخدام Flexible أو Expanded إذا كان النص طويلاً جدًا ويمكن أن يسبب overflow
          Expanded(
            child: InkWell(
              onTap: onValueTap,
              child: Text(
                displayValue,
                style: effectiveValueStyle,
                // overflow: TextOverflow.ellipsis, // يمكنك إضافتها إذا لزم الأمر
                // maxLines: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }






}

// --- قم بتعريف CompanyReportsBinding ---
// class CompanyReportsBinding extends Bindings { /* ... */ }