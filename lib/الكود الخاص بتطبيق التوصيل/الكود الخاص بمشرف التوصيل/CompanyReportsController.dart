import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // For DateRange
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../XXX/xxx_firebase.dart';
import '../../Model/DeliveryTaskModel.dart';
import 'DriverPerformanceData.dart'; // لتنسيق التواريخ والأرقام

// استورد النماذج والثوابت
// import 'path_to_models/DeliveryTaskModel.dart';
// import 'path_to_models/DeliveryDriverModel.dart';
// import 'path_to_constants/FirebaseX.dart';

// --- تعريفات مؤقتة ---
// ... (نماذج DeliveryTaskModel, DeliveryDriverModel, FirebaseX, Enums) ...
// افترض أن DeliveryTaskModel يحتوي على actualPickupTime, deliveryConfirmationTime, deliveryFee, status
// وأن DeliveryDriverModel يحتوي على name
// --- نهاية التعريفات ---
enum DriverSortOption {
  completedTasksDesc,
  completedTasksAsc,
  avgTimeDesc, // (الأسرع أولاً)
  avgTimeAsc,  // (الأبطأ أولاً)
  // يمكنك إضافة المزيد: distanceDesc, distanceAsc, feesDesc, feesAsc
  nameAsc
}
class CompanyReportsController extends GetxController {
  final String companyId;
  CompanyReportsController({required this.companyId});
  final RxList<DriverPerformanceData> driverPerformanceList = <DriverPerformanceData>[].obs;
  final Rx<DriverSortOption> selectedDriverSortOption = DriverSortOption.completedTasksDesc.obs; // للفرز

  final RxMap<String, int> taskStatusDistribution = <String, int>{}.obs;
  final RxMap<String, int> failureReasonsDistribution = <String, int>{}.obs;
  final RxString averageTimeToPickup = 'N/A'.obs;
  final RxString averageTimeFromPickupToDelivery = 'N/A'.obs;

  // --- بيانات الخريطة الحرارية ---
  final RxList<LatLng> pickupHeatmapPoints = <LatLng>[].obs;
  final RxList<LatLng> deliveryHeatmapPoints = <LatLng>[].obs;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- حالات التحميل والخطأ ---
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // --- فلتر النطاق الزمني ---
  final Rx<DateTimeRange> selectedDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 6)), // آخر 7 أيام افتراضيًا
    end: DateTime.now(),
  ).obs;
  // (اختياري) لتتبع النطاق الزمني المقارن
  final Rxn<DateTimeRange> comparisonDateRange = Rxn<DateTimeRange>(null);


  // --- KPIs ---
  final RxInt totalCompletedTasks = 0.obs;
  final RxDouble totalDeliveryFeesCollected = 0.0.obs; // رسوم التوصيل التي حصلتها الشركة
  final RxString averageDeliveryTimeText = 'N/A'.obs;
  final RxDouble successRatePercentage = 0.0.obs;
  final RxDouble averageCompanyRating = 0.0.obs; // إذا كان للشركة تقييم عام
  final RxDouble averageDriverRatingForCompany = 0.0.obs; // متوسط تقييم سائقي هذه الشركة

  // --- أداء السائقين ---

  // totalDeliveryFeesCollected موجودة في KPIs
  // يمكنك إضافة صافي الربح إذا كان لديك تكاليف مسجلة

  // --- بيانات للخريطة الحرارية (قائمة بالإحداثيات) ---
  // RxList<LatLng> pickupHeatmapPoints = <LatLng>[].obs;
  // RxList<LatLng> deliveryHeatmapPoints = <LatLng>[].obs;

  // --- متغيرات لحساب المقارنات ---
  final RxBool showComparison = false.obs; // للتحكم في عرض بيانات المقارنة
  // (KPIs للمقارنة)
  final RxInt prevPeriodCompletedTasks = 0.obs;
  final RxDouble prevPeriodDeliveryFees = 0.0.obs; // <--- استخدم 0.0 لجعلها double

  // --- حالات التحميل والخطأ ---

  Future<void> pickDateRange(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTimeRange initialRange = selectedDateRange.value ??
        DateTimeRange( // قيمة افتراضية إذا لم يتم تحديد نطاق بعد
          start: now.subtract(const Duration(days: 29)), // آخر 30 يومًا
          end: now,
        );

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: initialRange,
      firstDate: DateTime(now.year - 5, now.month, now.day), // اسمح باختيار حتى 5 سنوات للخلف
      lastDate: now, // لا تسمح باختيار تاريخ مستقبلي
      locale: const Locale('ar', 'SA'), // لتقويم عربي
      helpText: 'اختر نطاق التاريخ للتقارير',
      cancelText: 'إلغاء',
      confirmText: 'موافق',
      errorFormatText: 'تنسيق التاريخ غير صالح',
      errorInvalidText: 'خارج النطاق المسموح به',
      errorInvalidRangeText: 'نطاق التاريخ غير صالح',
      fieldStartHintText: 'تاريخ البدء',
      fieldEndHintText: 'تاريخ الانتهاء',
      fieldStartLabelText: 'من تاريخ',
      fieldEndLabelText: 'إلى تاريخ',
      builder: (context, child) { // لتطبيق الثيم على المنتقي
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white, // لون النص على التحديد الأساسي
              surface: Theme.of(context).cardColor, // لون خلفية المنتقي
              onSurface: Theme.of(context).textTheme.bodyLarge?.color, // لون النص العادي
            ),
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary), // ألوان الأزرار
            appBarTheme: AppBarTheme( // لتخصيص شريط المنتقي العلوي
                backgroundColor: Theme.of(context).primaryColor,
                iconTheme: IconThemeData(color: Colors.white),
                titleTextStyle: TextStyle(color: Colors.white, fontSize: 18)
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDateRange.value) {
      debugPrint("[REPORTS_CTRL] Custom date range picked: ${picked.start} - ${picked.end}");
      // استدعاء updateDateRange سيقوم بتحديث selectedDateRange.value
      // وبسبب ever(selectedDateRange, ...) سيتم استدعاء loadAllReportData() تلقائيًا
      updateDateRange(picked);
    } else {
      debugPrint("[REPORTS_CTRL] Custom date range picking cancelled or unchanged.");
    }
  }

  // --- بيانات التقارير المحسوبة ---
  // KPIs
  final RxDouble totalDeliveryFees = 0.0.obs;
  final RxString averageDeliveryTime = ''.obs; // سيكون "XX دقيقة" أو "YY ساعة"
  final RxDouble successRate = 0.0.obs; // نسبة مئوية

  // Driver Performance
  // كل عنصر: {'driverId': '...', 'driverName': '...', 'completedTasks': 0, 'avgTimeSeconds': 0}

  // Task Analysis
  // مفتاح هو stringToDeliveryTaskStatus, القيمة هي العدد


  @override
  void onInit() {
    super.onInit();
    if (companyId.isEmpty) {
      errorMessage.value = "خطأ: معرف الشركة مطلوب لعرض التقارير.";
      return;
    }
    // ربط مستمع لتغيير النطاق الزمني لإعادة جلب التقارير
    ever(selectedDateRange, (_) =>fetchAllReports());
    fetchAllReports(); // الجلب الأولي
  }

  void updateDateRange(DateTimeRange newRange) {
    selectedDateRange.value = newRange;
    // يمكنك هنا تعيين comparisonDateRange تلقائيًا (مثلاً، نفس المدة السابقة)
    // أو السماح للمستخدم باختياره بشكل منفصل
    comparisonDateRange.value = null; // مسح المقارنة عند تغيير النطاق الرئيسي
    showComparison.value = false;
  }
  void setDateRangeToToday() => updateDateRange(DateTimeRange(start: DateTime.now().copyWith(hour: 0, minute: 0, second: 0), end: DateTime.now()));

// In CompanyReportsController.dart

  Future<void> fetchAllReports() async {
    if (companyId.isEmpty) return;
    isLoading.value = true;
    errorMessage.value = '';
    _resetReportValues();
    debugPrint("[REPORTS_CTRL] Loading reports for $companyId from ${selectedDateRange.value.start} to ${selectedDateRange.value.end}");

    try {
      // 1. جلب وحساب المهام للفترة الرئيسية
      final List<DeliveryTaskModel> mainPeriodTasks = await _fetchTasksForPeriod(selectedDateRange.value);
      if (mainPeriodTasks.isNotEmpty) {
        // --- التعديل هنا: تمرير isMainPeriod ---
        _calculateKPIs(mainPeriodTasks, isMainPeriod: true); // <--- isMainPeriod: true
        // --------------------------------------
        await _calculateDriverPerformance(mainPeriodTasks);
        _calculateTaskAnalysis(mainPeriodTasks);
        _populateHeatmapData(mainPeriodTasks);
      } else {
        debugPrint("[REPORTS_CTRL] No tasks found for the main period.");
        // لا حاجة لـ _resetReportValues هنا إذا كان قد تم في بداية الدالة
        // ولكن تأكد أن القيم تعرض "N/A" أو 0 بشكل صحيح
      }

      // 2. (اختياري) جلب وحساب المهام لفترة المقارنة إذا تم تحديدها
      if (showComparison.value && comparisonDateRange.value != null) {
        debugPrint("[REPORTS_CTRL] Loading reports for comparison period: ${comparisonDateRange.value!.start} to ${comparisonDateRange.value!.end}");
        final List<DeliveryTaskModel> comparisonPeriodTasks = await _fetchTasksForPeriod(comparisonDateRange.value!);
        if (comparisonPeriodTasks.isNotEmpty) {
          // --- التعديل هنا: تمرير isMainPeriod ---
          _calculateKPIs(comparisonPeriodTasks, isMainPeriod: false); // <--- isMainPeriod: false
          // ---------------------------------------
        } else {
          debugPrint("[REPORTS_CTRL] No tasks found for the comparison period.");
          // إعادة تعيين قيم المقارنة فقط إذا لم تكن هناك بيانات
          prevPeriodCompletedTasks.value = 0;
          prevPeriodDeliveryFees.value = 0.0;
          // ... مسح باقي قيم KPIs المقارنة
        }
      } else if (!showComparison.value) { // إذا تم إلغاء تفعيل المقارنة، امسح قيم المقارنة
        prevPeriodCompletedTasks.value = 0;
        prevPeriodDeliveryFees.value = 0.0;
      }

    } catch (e, s) {
      debugPrint("[REPORTS_CTRL] Error loading all reports: $e\n$s");
      errorMessage.value = "فشل تحميل التقارير: ${e.toString()}";
      _resetReportValues(); // إعادة تعيين كل شيء عند الخطأ العام
    } finally {
      isLoading.value = false;
    }
  }




  Future<void> loadAllReportData() async {
    if (companyId.isEmpty) return;
    isLoading.value = true;
    errorMessage.value = '';
    _resetReportValues(); // مسح القيم القديمة قبل الجلب

    try {

      debugPrint("[REPORTS_CTRL] Loading reports for $companyId ...");
      final List<DeliveryTaskModel> mainPeriodTasks = await _fetchTasksForPeriod(selectedDateRange.value);
      if (mainPeriodTasks.isNotEmpty) {
        _calculateKPIs(mainPeriodTasks, isMainPeriod: true);
        await _calculateDriverPerformance(mainPeriodTasks); // ستحسب المسافة هنا
        _calculateTaskAnalysis(mainPeriodTasks);
        _populateHeatmapData(mainPeriodTasks); // <--- إضافة هنا
      } else { _resetReportValues(resetMainOnly: true); }


      // 2. (اختياري) جلب المهام لفترة المقارنة إذا تم تحديدها
      if (showComparison.value && comparisonDateRange.value != null) {
        debugPrint("[REPORTS_CTRL] Loading reports for comparison period: ${comparisonDateRange.value!.start} to ${comparisonDateRange.value!.end}");
        final List<DeliveryTaskModel> comparisonPeriodTasks = await _fetchTasksForPeriod(comparisonDateRange.value!);
        if(comparisonPeriodTasks.isNotEmpty){
          _calculateKPIs(comparisonPeriodTasks, isMainPeriod: false); // لحساب prevPeriod...
        } else {
          debugPrint("[REPORTS_CTRL] No tasks found for the comparison period.");
        }
      }

    } catch (e, s) {
      debugPrint("[REPORTS_CTRL] Error loading all reports: $e\n$s");
      errorMessage.value = "فشل تحميل التقارير: ${e.toString()}";
    } finally {
      isLoading.value = false;
    }
  }

  void _resetReportValues({bool resetMainOnly = false, bool resetComparisonOnly = false}){
    if(resetMainOnly || (!resetComparisonOnly && !resetMainOnly)){
      totalCompletedTasks.value = 0; totalDeliveryFeesCollected.value = 0.0;
      averageDeliveryTimeText.value = 'N/A'; successRatePercentage.value = 0.0;
      driverPerformanceList.clear(); taskStatusDistribution.clear(); failureReasonsDistribution.clear();
      averageTimeToPickup.value = 'N/A'; averageTimeFromPickupToDelivery.value = 'N/A';
      pickupHeatmapPoints.clear(); deliveryHeatmapPoints.clear();
    }
    if(resetComparisonOnly || (!resetComparisonOnly && !resetMainOnly)){
      prevPeriodCompletedTasks.value = 0; prevPeriodDeliveryFees.value = 0.0;
    }
  }

  Future<List<DeliveryTaskModel>> _fetchTasksForPeriod(DateTimeRange period) async {
    DateTime endDateForQuery = DateTime(period.end.year, period.end.month, period.end.day, 23, 59, 59);
    final QuerySnapshot tasksSnapshot = await _firestore
        .collection(FirebaseX.deliveryTasksCollection)
        .where('assignedCompanyId', isEqualTo: companyId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(period.start)) // أو 'deliveryConfirmationTime' إذا كان هو التاريخ المرجعي
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDateForQuery))
        .orderBy('createdAt', descending: true) // الأحدث أولاً للعرض، لكن الحسابات قد لا تهتم بالترتيب
        .get();
    return tasksSnapshot.docs.map((doc) => DeliveryTaskModel.fromFirestore(doc as DocumentSnapshot<Map<String,dynamic>>)).toList();
  }


  void _calculateKPIs(List<DeliveryTaskModel> tasks, {required bool isMainPeriod}) {
    int completed = 0; double fees = 0.0;
    int totalDeliveryDurationSeconds = 0; int tasksCountForAvgDeliveryTime = 0;
    int consideredForSuccessRate = 0;
    // --- جديد لحساب وقت (التعيين -> الاستلام) ---
    int totalAssignToPickupDurationSeconds = 0; int tasksCountForAssignToPickupTime = 0;
    // --- جديد لحساب المسافة الإجمالية ---
    double totalDistanceOfCompletedTasksKm = 0.0;

    for (var task in tasks) {
      if (task.status == DeliveryTaskStatus.delivered ||
          task.status == DeliveryTaskStatus.delivery_failed ||
          task.status.toString().toLowerCase().contains("cancel")) {
        consideredForSuccessRate++;
      }

      if (task.status == DeliveryTaskStatus.delivered) {
        completed++;
        fees += task.deliveryFee ?? 0.0;
        totalDistanceOfCompletedTasksKm += task.distanceTravelledKm ?? 0.0; // <-- جمع المسافات

        // حساب متوسط وقت التوصيل (استلام -> تسليم مؤكد)
        if (task.actualPickupTime != null && task.deliveryConfirmationTime != null) {
          final duration = task.deliveryConfirmationTime!.toDate().difference(task.actualPickupTime!.toDate());
          if (duration.inSeconds > 0) {
            totalDeliveryDurationSeconds += duration.inSeconds;
            tasksCountForAvgDeliveryTime++;
          }
        }

        // حساب وقت (التعيين -> الاستلام)
        if (task.assignTimeToDriver != null && task.actualPickupTime != null) { // <-- استخدام الحقول الجديدة
          final duration = task.actualPickupTime!.toDate().difference(task.assignTimeToDriver!.toDate());
          if (duration.inSeconds > 0 && duration.inHours < 24) { // تجاهل القيم غير المنطقية
            totalAssignToPickupDurationSeconds += duration.inSeconds;
            tasksCountForAssignToPickupTime++;
          }
        }
      }
    }

    if (isMainPeriod) {
      totalCompletedTasks.value = completed;
      totalDeliveryFeesCollected.value = fees;
      // averageTaskDistanceKm.value = completed > 0 ? totalDistanceOfCompletedTasksKm / completed : 0.0; // <-- متوسط المسافة لكل مهمة مكتملة

      if (tasksCountForAvgDeliveryTime > 0) {
        averageDeliveryTimeText.value = _formatDurationFromSeconds(totalDeliveryDurationSeconds / tasksCountForAvgDeliveryTime);
      } else { averageDeliveryTimeText.value = "N/A"; }

      // --- تحديث متوسط وقت التعيين للاستلام ---
      if (tasksCountForAssignToPickupTime > 0) {
        averageTimeToPickup.value = _formatDurationFromSeconds(totalAssignToPickupDurationSeconds / tasksCountForAssignToPickupTime);
      } else { averageTimeToPickup.value = "N/A"; }
      // ---------------------------------------

      if (consideredForSuccessRate > 0) {
        successRatePercentage.value = (completed / consideredForSuccessRate) * 100.0;
      } else { successRatePercentage.value = 0.0; }

    } else { // فترة المقارنة
      prevPeriodCompletedTasks.value = completed;
      prevPeriodDeliveryFees.value = fees;
      // يمكنك إضافة حسابات المقارنة الأخرى هنا أيضًا
    }
    debugPrint("[REPORTS_CTRL] KPIs Calculated. AvgTimeToPickup: ${averageTimeToPickup.value}");
  }




  String _formatDurationFromSeconds(double avgSeconds) {
    if (avgSeconds.isNaN || avgSeconds.isInfinite || avgSeconds <= 0) return "N/A";
    int totalMinutes = (avgSeconds / 60).round();
    if (totalMinutes < 1) return "< 1 دقيقة";
    if (totalMinutes < 60) return "$totalMinutes دقيقة";
    int hours = (totalMinutes / 60).floor();
    int minutes = totalMinutes % 60;
    return "$hours ساعة و $minutes دقيقة";
  }




  Future<void> _calculateDriverPerformance(List<DeliveryTaskModel> tasks) async {
    // ... (المنطق السابق، مع التأكد من أن DriverPerformanceData تُجمع فيها `distanceTravelledKm` لكل سائق)
    Map<String, dynamic> driverStatsAggregator = {};
    // ... (جلب أسماء السائقين driverDetailsMap)
    // ... (حلقة for task in tasks) ...
    // داخل الحلقة، عند تجميع بيانات السائق:
    // driverStatsAggregator[driverId]!['totalDistanceKm'] += task.distanceTravelledKm ?? 0.0; // <--- جمع المسافات
    // ...
    // عند إنشاء DriverPerformanceData:
    // totalDistanceCoveredKm: entry.value['totalDistanceKm'], // <--- تمريرها للنموذج
    // ...
    // فرز القائمة driverPerformanceList بناءً على selectedDriverSortOption.value
    _sortDriverPerformanceList(); // دالة جديدة للفرز
  }


  void _sortDriverPerformanceList() {
    List<DriverPerformanceData> currentList = List.from(driverPerformanceList);
    switch (selectedDriverSortOption.value) {
      case DriverSortOption.completedTasksDesc:
        currentList.sort((a, b) => b.completedTasks.compareTo(a.completedTasks));
        break;
      case DriverSortOption.completedTasksAsc:
        currentList.sort((a, b) => a.completedTasks.compareTo(b.completedTasks));
        break;
      case DriverSortOption.avgTimeDesc: // الأسرع (وقت أقل) يجب أن يظهر أولاً
        currentList.sort((a,b) => a.averageDeliveryTimeSeconds.compareTo(b.averageDeliveryTimeSeconds)); // ASC للوقت الأقل
        break;
      case DriverSortOption.avgTimeAsc: // الأبطأ
        currentList.sort((a,b) => b.averageDeliveryTimeSeconds.compareTo(a.averageDeliveryTimeSeconds)); // DESC للوقت الأكبر
        break;
    // أضف حالات فرز أخرى (مثل المسافة، الرسوم)
      case DriverSortOption.nameAsc:
        currentList.sort((a,b)=> a.driverName.compareTo(b.driverName));
        break;
    }
    driverPerformanceList.assignAll(currentList);
  }

  void changeDriverSortOption(DriverSortOption newOption){
    selectedDriverSortOption.value = newOption;
    _sortDriverPerformanceList(); // أعد الفرز بعد تغيير الخيار
  }
  void _populateHeatmapData(List<DeliveryTaskModel> tasks) {
    List<LatLng> newPickupPoints = [];
    List<LatLng> newDeliveryPoints = [];
    for (var task in tasks) {
      if (task.pickupLocationGeoPoint != null) {
        newPickupPoints.add(LatLng(task.pickupLocationGeoPoint!.latitude, task.pickupLocationGeoPoint!.longitude));
      }
      if (task.deliveryLocationGeoPoint != null) {
        newDeliveryPoints.add(LatLng(task.deliveryLocationGeoPoint!.latitude, task.deliveryLocationGeoPoint!.longitude));
      }
    }
    pickupHeatmapPoints.assignAll(newPickupPoints);
    deliveryHeatmapPoints.assignAll(newDeliveryPoints);
    debugPrint("[REPORTS_CTRL] Heatmap data populated. Pickups: ${pickupHeatmapPoints.length}, Deliveries: ${deliveryHeatmapPoints.length}");
  }

  void _calculateTaskAnalysis(List<DeliveryTaskModel> tasks) {
    Map<String, int> statusDist = {};
    Map<String, int> failureDist = {}; // يجب أن تكون هذه معرفة
    int timeToPickupSecondsTotal = 0; int timeToPickupCount = 0;
    int pickupToDeliverySecondsTotal = 0; int pickupToDeliveryCount = 0;

    for (var task in tasks) {
      String statusStr = deliveryTaskStatusToString(task.status);
      taskStatusDistribution[statusStr] = (taskStatusDistribution[statusStr] ?? 0) + 1;

      // --- استخدام failureOrCancellationReason ---
      if ((task.status == DeliveryTaskStatus.delivery_failed || task.status.toString().toLowerCase().contains("cancel")) &&
          task.failureOrCancellationReason != null && task.failureOrCancellationReason!.isNotEmpty) {
        failureDist[task.failureOrCancellationReason!] = (failureDist[task.failureOrCancellationReason!] ?? 0) + 1;
      }
      // ------------------------------------------

      if (task.assignTimeToDriver != null && task.actualPickupTime != null) {
        final duration = task.actualPickupTime!.toDate().difference(task.assignTimeToDriver!.toDate());
        if(duration.inSeconds >=0 && duration.inHours < 24) { timeToPickupSecondsTotal += duration.inSeconds; timeToPickupCount++; }
      }
      if (task.actualPickupTime != null && task.deliveryConfirmationTime != null) {
        final duration = task.deliveryConfirmationTime!.toDate().difference(task.actualPickupTime!.toDate());
        if(duration.inSeconds >=0 && duration.inHours < 48) { pickupToDeliverySecondsTotal += duration.inSeconds; pickupToDeliveryCount++; }
      }
    }
    // taskStatusDistribution.assignAll(statusDist); //  يتم تحديثه مباشرة
    failureReasonsDistribution.assignAll(failureDist);
    averageTimeToPickup.value = timeToPickupCount > 0 ? _formatDurationFromSeconds(timeToPickupSecondsTotal / timeToPickupCount) : "N/A";
    averageTimeFromPickupToDelivery.value = pickupToDeliveryCount > 0 ? _formatDurationFromSeconds(pickupToDeliverySecondsTotal / pickupToDeliveryCount) : "N/A";
    debugPrint("[REPORTS_CTRL] Task Analysis: StatusDist=${taskStatusDistribution.value}, FailureReasons=$failureReasonsDistribution, AvgAssignToPickup=${averageTimeToPickup.value}");
  }

// دالة لتمكين/تعطيل وضع المقارنة واختيار فترة المقارنة
  Future<void> toggleComparisonModeAndPickDate(BuildContext context) async {
    if(showComparison.value){ // إذا كان وضع المقارنة مفعل، قم بإلغائه
      showComparison.value = false;
      comparisonDateRange.value = null;
      // إعادة حساب القيم بدون مقارنة (أو مسح قيم المقارنة)
      prevPeriodCompletedTasks.value = 0;
      // ...
      // لا حاجة لـ loadAllReportData() هنا إذا كنا فقط نلغي المقارنة
      // إلا إذا كانت القيم الرئيسية يجب أن تُحسب بدون المقارنة
      return;
    }

    final DateTimeRange? pickedComparisonRange = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange( // اقترح فترة قبل الفترة الحالية
        start: selectedDateRange.value.start.subtract(Duration(days: selectedDateRange.value.duration.inDays)),
        end: selectedDateRange.value.start.subtract(Duration(days: 1)),
      ),
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime.now().subtract(Duration(days:1)), // لا يمكن أن تتداخل مع الفترة الحالية
      locale: const Locale('ar', 'SA'),
    );

    if (pickedComparisonRange != null) {
      // تحقق من عدم التداخل مع الفترة الرئيسية
      if (pickedComparisonRange.end.isBefore(selectedDateRange.value.start) ||
          pickedComparisonRange.start.isAfter(selectedDateRange.value.end)) {
        comparisonDateRange.value = pickedComparisonRange;
        showComparison.value = true;
        loadAllReportData(); // أعد تحميل كل شيء مع فترة المقارنة
      } else {
        Get.snackbar("خطأ في النطاق", "فترة المقارنة لا يمكن أن تتداخل مع الفترة الرئيسية المحددة.");
      }
    }
  }

  void _calculateTaskStatusDistribution(List<DeliveryTaskModel> tasks) {
    Map<String, int> distribution = {};
    for (var task in tasks) {
      // استخدام toString لـ enum للحصول على اسم الحالة
      String statusString = deliveryTaskStatusToString(task.status);
      distribution[statusString] = (distribution[statusString] ?? 0) + 1;
    }
    taskStatusDistribution.assignAll(distribution);
    debugPrint("[REPORTS_CTRL] Task Status Distribution: $taskStatusDistribution");
  }

  // يمكنك إضافة دوال أخرى لتقارير محددة

  @override
  void onClose() {
    debugPrint("[REPORTS_CTRL] Controller closed.");
    super.onClose();
  }
}