import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; // لـ Color، IconData
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../XXX/xxx_firebase.dart';
import '../../routes/app_routes.dart';
import '../الكود الخاص بمشرف التوصيل/CompanyDriversListScreen.dart';
import '../../Model/DeliveryTaskModel.dart';
import 'DeliveryDriverModel.dart';
import 'DriverLocationService.dart';
import 'ProcessedTaskForDriverDisplay.dart'; //  تأكد من إضافة الحزمة


class DriverDashboardController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String driverId; // سيتم تهيئته من FirebaseAuth في onReady
  DriverDashboardController({required this.driverId});
  final RxInt availableTasksForDriverCount = 0.obs;
  final RxBool isLoadingAvailableTasks = true.obs; //  كان اسمه isLoadingAvailableTasksCount
  StreamSubscription? _availableTasksCountSubscription; //  إذا أردت تحديثًا حيًا للعدد
  final Rxn<ProcessedTaskForDriverDisplay> processedActiveTaskForDashboard = Rxn<ProcessedTaskForDriverDisplay>(null); // <--- **** هذا هو التعريف المطلوب ****
  final RxString etaForDashboardActiveTask = "".obs;

  // --- بيانات السائق الحالية ---
  final Rxn<DeliveryDriverModel> currentDriver = Rxn<DeliveryDriverModel>(null);
  final RxBool isLoadingDriverProfile = true.obs;
  final RxString driverProfileError = ''.obs;

  // --- حالة التوفر ---
  final RxString availabilityStatusString = "offline".obs;
  final List<String> availabilityOptions = ["online_available", "on_break", "offline"]; // "on_break" اختياري

  // --- ملخص الأداء اليومي/الأسبوعي ---
  final RxInt completedTasksTodayCount = 0.obs;
  final RxDouble earningsTodayAmount = 0.0.obs;
  final RxList<BarChartGroupData> weeklyTasksBarData = <BarChartGroupData>[].obs; // للرسم البياني للمهام الأسبوعية
  final RxBool isLoadingPerformanceSummary = true.obs;
  final RxString performanceSummaryError = ''.obs;

  // --- المهمة النشطة ---
  final Rxn<DeliveryTaskModel> activeTaskDetails = Rxn<DeliveryTaskModel>(null);
  final RxBool isLoadingActiveTask = true.obs; // يبدأ true حتى يتم التحقق
  StreamSubscription? _activeTaskSubscription;

  // --- المهام المتاحة (إذا كان نظام التقاط) ---
  final RxInt availablePickupTasksCount = 0.obs;
  final RxBool isLoadingAvailableTasksCount = true.obs; // للعدد فقط

  StreamSubscription? _driverProfileSubscription;
  Timer? _performanceRefreshTimer; // لتحديث الأداء بشكل دوري (اختياري)

  final RxDouble maxWeeklyTaskCountForChart = 5.0.obs; //  قيمة مبدئية لـ maxY
  final Rxn<LatLng> _currentDriverLocationForDashboardProcessing = Rxn<LatLng>(null);
  StreamSubscription? _driverLocationSubForDashboard; // <--- اشتراك منفصل لموقع السائق هنا

  @override
  void onReady() {
    super.onReady();
    debugPrint("[DRIVER_DASH_CTRL] onReady called.");
    driverId = _auth.currentUser?.uid ?? "";

    if (driverId.isEmpty) { // أضفت علامة التعجب هنا بناءً على تعريف driverId كـ late String
      // أو يمكنك جعله String? والتحقق من null كما فعلت
      //  final localDriverId = _auth.currentUser?.uid;
      //  if (localDriverId == null || localDriverId.isEmpty) { ... }
      //  driverId = localDriverId; // ثم عيّن للمتغير العضو
      debugPrint("[DRIVER_DASH_CTRL] CRITICAL: Driver ID is empty in onReady. User might not be logged in.");
      // ... (نفس معالجة الخطأ) ...
      driverProfileError.value = "لم يتم تسجيل الدخول بشكل صحيح.";
      return;
    }
    refreshAllData(showMainLoader: true); // عرض مؤشر التحميل الرئيسي عند أول تحميل
    _subscribeToDriverLocationForDashboard(); // <--- دالة جديدة للاشتراك في موقع السائق

    debugPrint("[DRIVER_DASH_CTRL] Initializing for driver ID: $driverId");
    subscribeToDriverProfile();
    fetchPerformanceSummary();
    fetchAvailableTasksCount();
    // استمع للتغييرات في المهمة النشطة وموقع السائق لإعادة معالجة بيانات العرض
    ever(activeTaskDetails, _processActiveTaskForDashboardDisplay, condition: ()=> activeTaskDetails.value != null || processedActiveTaskForDashboard.value != null);
    ever(_currentDriverLocationForDashboardProcessing, _processActiveTaskForDashboardDisplay, condition: ()=> activeTaskDetails.value != null); // فقط إذا كانت هناك مهمة نشطة بالفعل

    // بدء مؤقت لتحديث الأداء كل 5 دقائق مثلاً (اختياري)
    _performanceRefreshTimer?.cancel(); // ألغِ أي مؤقت قديم قبل بدء واحد جديد
    _performanceRefreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      // --- التعديل هنا ---
      //  تحقق مما إذا كان المتحكم لا يزال في الذاكرة (لم يتم التخلص منه)
      //  وأن المسار الحالي هو مسار لوحة تحكم السائق
      if (Get.isRegistered<DriverDashboardController>() && // تأكد أن المتحكم لا يزال "حيًا"
          Get.currentRoute == AppRoutes.DRIVER_DASHBOARD) { // <--- تحقق من المسار الحالي
        debugPrint("[DRIVER_DASH_CTRL] Timer: Refreshing performance summary on dashboard.");
        fetchPerformanceSummary(); // قم بالتحديث
      } else {
        // إذا لم نعد في شاشة الداشبورد أو تم التخلص من المتحكم، أوقف المؤقت
        debugPrint("[DRIVER_DASH_CTRL] Timer: Not on dashboard or controller disposed. Stopping timer.");
        timer.cancel();
        _performanceRefreshTimer = null; // أعد تعيينه إلى null
      }
      // -------------------
    });

    subscribeToAvailableTasksCountForDriver();


  }





  void _subscribeToDriverLocationForDashboard() { // <--- **الدالة المطلوبة**
    if (driverId.isEmpty) return;
    _driverLocationSubForDashboard?.cancel();
    _driverLocationSubForDashboard = _firestore
        .collection(FirebaseX.deliveryDriversCollection).doc(driverId)
        .snapshots() // يمكنك جعل هذا الاشتراك أقل تواترًا إذا كان يؤثر على الأداء
    // أو الاستماع فقط للحقل 'currentLocation'
        .listen((doc) {
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['currentLocation'] is GeoPoint) {
          final GeoPoint loc = data['currentLocation'];
          _currentDriverLocationForDashboardProcessing.value = LatLng(loc.latitude, loc.longitude);
          debugPrint("[DASH_CTRL_LOC_SUB] Dashboard location updated: ${_currentDriverLocationForDashboardProcessing.value}");
        } else {
          _currentDriverLocationForDashboardProcessing.value = null;
          debugPrint("[DASH_CTRL_LOC_SUB] Dashboard location is null in Firestore or invalid type.");
        }
      } else {
        _currentDriverLocationForDashboardProcessing.value = null;
      }
    }, onError: (e){
      debugPrint("Error in _subscribeToDriverLocationForDashboard: $e");
      _currentDriverLocationForDashboardProcessing.value = null;
    });
  }



  Future<void> refreshAllData({bool showMainLoader = true}) async {
    // إذا كان companyId (الذي هو driverId هنا) غير متاح في البداية، onReady ستعالجه
    if (driverId.isEmpty) {
      debugPrint("[DRIVER_DASH_CTRL - REFRESH] Cannot refresh, driverId is null or empty.");
      return;
    }
    if (showMainLoader) {
      // إذا كان هذا هو التحميل الأولي، يمكنك استخدام مؤشر تحميل عام شامل
      // ولكن بما أن كل دالة جلب لها مؤشر تحميل خاص بها، هذا قد لا يكون ضروريًا
      // ما لم تكن تريد إظهار شيء واحد يغطي كل شيء في البداية.
      //isLoadingDriverProfile.value = true; // كمثال، أو مؤشر عام جديد
    }
    debugPrint("[DRIVER_DASH_CTRL - REFRESH] Refreshing all dashboard data...");

    // 1. إعادة الاشتراك/تحديث ملف السائق (ومنه المهمة النشطة)
    subscribeToDriverProfile(); // هذه تبدأ استماعًا حيًا وستُحدّث currentDriver و activeTaskDetails

    // 2. جلب/تحديث ملخص الأداء (الذي هو get())
    await fetchPerformanceSummary();

    // 3. إعادة الاشتراك/تحديث عدد المهام المتاحة (إذا كانت اشتراكًا حيًا)
    subscribeToAvailableTasksCountForDriver();

    // يمكنك هنا إيقاف أي مؤشر تحميل عام إذا كنت قد بدأته
    if (showMainLoader) {
      //isLoadingDriverProfile.value = false;
    }
    debugPrint("[DRIVER_DASH_CTRL - REFRESH] All data refresh process initiated.");
  }

  void subscribeToAvailableTasksCountForDriver() {
    if (driverId.isEmpty || currentDriver.value?.approvedCompanyId == null || currentDriver.value!.approvedCompanyId!.isEmpty) {
      availableTasksForDriverCount.value = 0;
      isLoadingAvailableTasks.value = false;
      return;
    }
    isLoadingAvailableTasks.value = true;
    final companyIdForDriver = currentDriver.value!.approvedCompanyId!;
    debugPrint("[DRIVER_DASH_CTRL] Subscribing to available tasks count for driver in company $companyIdForDriver");

    _availableTasksCountSubscription?.cancel();
    _availableTasksCountSubscription = _firestore
        .collection(FirebaseX.deliveryTasksCollection)
        .where('assignedCompanyId', isEqualTo: companyIdForDriver)
    // --- الحالة التي تعني أن المهمة متاحة ليقبلها سائقو الشركة ---
        .where('status', isEqualTo: deliveryTaskStatusToString(DeliveryTaskStatus.available_for_company_drivers)) //  <---  اسم حالة جديد مقترح
    // --------------------------------------------------------------
        .where('assignedToDriverId', isNull: true) // لم يتم التقاطها بعد
        .snapshots()
        .listen((snapshot) {
      availableTasksForDriverCount.value = snapshot.docs.length;
      isLoadingAvailableTasks.value = false; // انتهى التحميل الأولي للعدد
      debugPrint("[DRIVER_DASH_CTRL] LIVE Available tasks count for driver: ${availableTasksForDriverCount.value}");
    }, onError: (e) {
      debugPrint("[DRIVER_DASH_CTRL] Error listening to available tasks count: $e");
      availableTasksForDriverCount.value = 0;
      isLoadingAvailableTasks.value = false;
    });
  }

  void subscribeToDriverProfile() {
    if (driverId.isEmpty) {
      debugPrint("[DRIVER_DASH_CTRL] Cannot subscribe to driver profile, driverId is empty.");
      driverProfileError.value = "معرف السائق غير متوفر.";
      isLoadingDriverProfile.value = false;
      return;
    }

    isLoadingDriverProfile.value = true;
    driverProfileError.value = ''; // مسح أي خطأ سابق
    _driverProfileSubscription?.cancel(); // إلغاء الاشتراك القديم إن وجد
    debugPrint("[DRIVER_DASH_CTRL] Subscribing to driver profile for: $driverId");

    _driverProfileSubscription = _firestore
        .collection(FirebaseX.deliveryDriversCollection) // تأكد أن هذا اسم المجموعة الصحيح
        .doc(driverId)
        .snapshots() // للاستماع الحي للتحديثات
        .listen((docSnapshot) {
      if (docSnapshot.exists && docSnapshot.data() != null) {
        try {
          currentDriver.value = DeliveryDriverModel.fromMap(docSnapshot.data()!, docSnapshot.id);
          availabilityStatusString.value = currentDriver.value!.availabilityStatus; // مزامنة مع Firestore
          driverProfileError.value = ''; // مسح الخطأ عند النجاح
          debugPrint("[DRIVER_DASH_CTRL] Driver profile updated: ${currentDriver.value?.name}, Rating: ${currentDriver.value?.averageRating}, Status: ${currentDriver.value?.availabilityStatus}, TaskID: ${currentDriver.value?.currentFocusedTaskId}");

          // --- (منطق تحديث خدمة الموقع والمهمة النشطة يبقى كما هو من الرد السابق) ---
          final locationService = Get.find<DriverLocationService>();
          if (currentDriver.value!.availabilityStatus == "online_available" || currentDriver.value!.availabilityStatus == "on_task") {
            if(!locationService.isServiceActive) locationService.startLocationUpdates();
          } else {
            if(locationService.isServiceActive) locationService.stopLocationUpdates();
          }

          final activeTaskVal = activeTaskDetails.value;
          final currentDriverTaskVal = currentDriver.value?.currentFocusedTaskId;
          if (currentDriverTaskVal != null && currentDriverTaskVal.isNotEmpty) {
            if (activeTaskVal == null || activeTaskVal.taskId != currentDriverTaskVal) {
              fetchActiveTaskDetails(currentDriverTaskVal);
            }
          } else if (activeTaskVal != null) {
            activeTaskDetails.value = null;
            isLoadingActiveTask.value = false;
          } else {
            isLoadingActiveTask.value = false;
          }
          // -------------------------------------------------------------------

        } catch (e,s) {
          debugPrint("[DRIVER_DASH_CTRL] Error parsing driver profile data: $e\n$s");
          driverProfileError.value = "خطأ في تنسيق بيانات الملف الشخصي.";
          currentDriver.value = null; // مسح البيانات عند خطأ البارسنج
        }
      } else {
        debugPrint("[DRIVER_DASH_CTRL] Driver profile document not found for $driverId. User might need to complete registration.");
        driverProfileError.value = "لم يتم العثور على ملف السائق. يرجى إكمال عملية التسجيل أو الاتصال بالدعم.";
        currentDriver.value = null; // لا يوجد ملف شخصي
        Get.find<DriverLocationService>().stopLocationUpdates();
      }
      isLoadingDriverProfile.value = false; // تم الانتهاء من محاولة الجلب/التحديث
    }, onError: (error, stackTrace) {
      debugPrint("[DRIVER_DASH_CTRL] Error listening to driver profile: $error\n$stackTrace");
      driverProfileError.value = "فشل تحميل تحديثات الملف الشخصي: $error";
      currentDriver.value = null;
      isLoadingDriverProfile.value = false;
    });
  }

  Future<void> updateAvailabilityStatus(String newStatus) async {
    if (driverId.isEmpty || currentDriver.value == null) {
      debugPrint("[AVAIL_STATUS] Cannot update: driverId or currentDriver is null.");
      return;
    }

    // --- تحقق مما إذا كان السائق يحاول أن يصبح "متوفر" ولديه مهمة نشطة ---
    if (newStatus == "online_available" &&
        currentDriver.value!.currentFocusedTaskId != null &&
        currentDriver.value!.currentFocusedTaskId!.isNotEmpty &&
        // تحقق أيضًا من حالة المهمة النشطة الفعلية إذا أردت المزيد من الدقة
        // (مثلاً، لا تسمح إذا كانت الحالة "out_for_delivery")
        // حاليًا، أي currentTaskId غير فارغ سيُعتبر مهمة نشطة
        (currentDriver.value!.availabilityStatus == "on_task" || activeTaskDetails.value != null && activeTaskDetails.value!.status != DeliveryTaskStatus.delivered /* وأي حالات نهائية أخرى */)) {
      Get.snackbar(
          "مهمة نشطة",
          "لديك مهمة (${activeTaskDetails.value?.orderId ?? currentDriver.value!.currentFocusedTaskId?.substring(0,6)}) لم تكتمل بعد. يجب إكمالها أو إلغاؤها أولاً.",
          backgroundColor: Colors.orange.shade700,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
          snackPosition: SnackPosition.BOTTOM
      );
      // أعد الواجهة إلى الحالة الفعلية المخزنة للسائق، لأننا لن نغيرها
      // availabilityStatusString.value = currentDriver.value!.availabilityStatus; //  <-- لا تفعل هذا هنا، لأن currentDriver.value نفسه سيتحدث من الـ stream إذا فشل التحديث
      return;
    }
    // ---------------------------------------------------------------------

    final String oldStatusForRollback = availabilityStatusString.value; // احتفظ بالحالة القديمة
    availabilityStatusString.value = newStatus; // تحديث الواجهة فورًا للتجاوب السريع
    debugPrint("[AVAIL_STATUS] UI updated to: $newStatus. Attempting Firestore update for driver $driverId.");

    try {
      await _firestore.collection(FirebaseX.deliveryDriversCollection).doc(driverId).update({
        'availabilityStatus': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint("[AVAIL_STATUS] Firestore availability status successfully updated to: $newStatus for driver $driverId.");
      // لا حاجة لتحديث currentDriver.value يدويًا هنا،
      // لأن اشتراك subscribeToDriverProfile سيستمع للتغيير من Firestore ويقوم بتحديثه.
      // وأيضًا DriverLocationService يجب أن تستمع لهذا التغيير وتتصرف.
      Get.snackbar("تم تحديث الحالة", "حالة التوفر لديك الآن: ${getDriverAvailabilityVisuals(newStatus, Get.context!)['text']}", // استخدم getDriverAvailabilityVisuals للترجمة
          backgroundColor: Colors.green, colorText: Colors.white, duration: Duration(seconds:2), snackPosition: SnackPosition.BOTTOM);

    } catch (e) {
      debugPrint("[AVAIL_STATUS] Error updating availability status in Firestore: $e");
      Get.snackbar("خطأ", "فشل تحديث حالة التوفر. حاول مرة أخرى.", backgroundColor: Colors.red.shade400);
      availabilityStatusString.value = oldStatusForRollback; // أعد الحالة للسابقة عند الخطأ
    }
  }


  // In DriverDashboardController.dart

  Future<void> fetchPerformanceSummary() async {
    if (driverId.isEmpty) {
      performanceSummaryError.value = "معرف السائق غير متوفر لجلب ملخص الأداء.";
      isLoadingPerformanceSummary.value = false;
      return;
    }

    isLoadingPerformanceSummary.value = true;
    performanceSummaryError.value = '';
    debugPrint("[DRIVER_DASH_CTRL] Fetching performance summary for driver $driverId");

    try {
      DateTime now = DateTime.now();
      // بداية اليوم الحالي (00:00:00)
      DateTime startOfToday = DateTime(now.year, now.month, now.day);
      // نهاية اليوم الحالي (23:59:59) - لجعل استعلام "أكبر من أو يساوي بداية اليوم وأصغر من بداية الغد" أكثر دقة
      DateTime endOfTodayForQuery = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);


      // --- 1. إحصائيات اليوم (المهام المكتملة اليوم وأرباح اليوم) ---
      debugPrint("[DRIVER_DASH_CTRL] Fetching today's tasks (status: delivered, confirmed after: $startOfToday)");
      final todayTasksSnapshot = await _firestore
          .collection(FirebaseX.deliveryTasksCollection)
          .where('assignedToDriverId', isEqualTo: driverId)
          .where('status', isEqualTo: deliveryTaskStatusToString(DeliveryTaskStatus.delivered))
          .where('deliveryConfirmationTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
          .where('deliveryConfirmationTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfTodayForQuery)) // <---  استعلام أكثر دقة لليوم
          .get();

      completedTasksTodayCount.value = todayTasksSnapshot.docs.length;
      double todayTotalEarnings = 0;
      for (var doc in todayTasksSnapshot.docs) {
        final taskDataMap = doc.data(); // cast to Map
        todayTotalEarnings += (taskDataMap['deliveryFee'] as num?)?.toDouble() ?? 0.0;
      }
      earningsTodayAmount.value = todayTotalEarnings;
      debugPrint("[DRIVER_DASH_CTRL] Today's performance: ${completedTasksTodayCount.value} tasks, ${earningsTodayAmount.value} ${FirebaseX.currency}");


      // --- 2. إحصائيات الأسبوع الحالي للمهام المكتملة (للرسم البياني) ---
      // سنقوم بجلب بيانات الأيام السبعة الماضية بما فيها اليوم الحالي.
      // سنقوم بفرز الأعمدة لتبدأ من أقدم يوم (يسار) إلى أحدث يوم (يمين).
      List<BarChartGroupData> tempWeeklyBars = [];
      double currentMaxTasksInWeek = 0;
      List<String> dayLabels = []; // لتخزين تسميات الأيام للرسم البياني

      // لتحديد أيام الأسبوع (الاثنين = 1 ... الأحد = 7)
      // final int todayWeekday = now.weekday;

      // حلقة لآخر 7 أيام (اليوم هو i=0)
      for (int i = 6; i >= 0; i--) { // من 6 (قبل 6 أيام) إلى 0 (اليوم)
        DateTime dayToFetch = DateTime(now.year, now.month, now.day - i);
        DateTime startOfDay = DateTime(dayToFetch.year, dayToFetch.month, dayToFetch.day);
        DateTime endOfDay = DateTime(dayToFetch.year, dayToFetch.month, dayToFetch.day, 23, 59, 59, 999);

        // إضافة تسمية اليوم
        // يمكنك استخدام DateFormat لتنسيق أفضل إذا أردت (مثلاً، "15/3")
        dayLabels.add(DateFormat('E', 'ar_SA').format(dayToFetch)); // مثال: "إث", "ثل" (الاختصار العربي ليوم الأسبوع)


        debugPrint("[DRIVER_DASH_CTRL] Fetching tasks for day: ${DateFormat('yyyy-MM-dd').format(dayToFetch)}");
        QuerySnapshot dayTasksSnapshot = await _firestore
            .collection(FirebaseX.deliveryTasksCollection)
            .where('assignedToDriverId', isEqualTo: driverId)
            .where('status', isEqualTo: deliveryTaskStatusToString(DeliveryTaskStatus.delivered))
            .where('deliveryConfirmationTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('deliveryConfirmationTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
            .get();

        double tasksCountForDay = dayTasksSnapshot.docs.length.toDouble();
        if (tasksCountForDay > currentMaxTasksInWeek) {
          currentMaxTasksInWeek = tasksCountForDay;
        }

        // قيمة x ستكون ترتيب اليوم في العرض (0 = أقدم يوم, 6 = اليوم)
        // أو يمكنك استخدام dayToFetch.weekday إذا كنت تريد الأعمدة تمثل أيام الأسبوع بترتيبها القياسي
        tempWeeklyBars.add(BarChartGroupData(
          x: 6 - i, //  بحيث يكون 0 هو أقدم يوم, و 6 هو أحدث يوم (اليوم)
          barRods: [
            BarChartRodData(
              toY: tasksCountForDay,
              width: 18, // يمكنك تعديل عرض الشريط
              color: Get.theme.primaryColor.withOpacity(0.8), // استخدام لون الثيم
              borderRadius: const BorderRadius.all(Radius.circular(5)),
            )
          ],
        ));
      }

      weeklyTasksBarData.assignAll(tempWeeklyBars);
      // إذا لم تكن هناك مهام على الإطلاق، maxWeeklyTaskCountForChart سيكون 0.
      // يجب أن يكون له قيمة دنيا ليعمل الرسم البياني (مثلاً 5)
      maxWeeklyTaskCountForChart.value = currentMaxTasksInWeek < 5 && currentMaxTasksInWeek > 0 ? 5.0 : (currentMaxTasksInWeek == 0 ? 5.0 : currentMaxTasksInWeek) ;
      debugPrint("[DRIVER_DASH_CTRL] Weekly tasks bar data prepared. Bars: ${weeklyTasksBarData.length}, MaxY for chart: ${maxWeeklyTaskCountForChart.value}");

    } catch (e, s) {
      debugPrint("[DRIVER_DASH_CTRL] Error fetching performance summary: $e\n$s");
      performanceSummaryError.value = "فشل تحميل ملخص الأداء: ${e.toString()}";
      // مسح القيم عند الخطأ
      completedTasksTodayCount.value = 0;
      earningsTodayAmount.value = 0.0;
      weeklyTasksBarData.clear();
      maxWeeklyTaskCountForChart.value = 5.0; // إعادة للقيمة الافتراضية
    } finally {
      isLoadingPerformanceSummary.value = false;
    }
  }



  void fetchActiveTaskDetails(String taskIdFromProfile) async {
    if (taskIdFromProfile.isEmpty) {
      activeTaskDetails.value = null;
      isLoadingActiveTask.value = false;
      return;
    }
    debugPrint("[DRIVER_DASH_CTRL] Subscribing to active task: $taskIdFromProfile");
    isLoadingActiveTask.value = true;
    _activeTaskSubscription?.cancel(); // إلغاء الاشتراك القديم أولاً
    _activeTaskSubscription = _firestore
        .collection(FirebaseX.deliveryTasksCollection)
        .doc(taskIdFromProfile)
        .snapshots()
        .listen((taskDoc) {
      if (taskDoc.exists && taskDoc.data() != null) {
        activeTaskDetails.value = DeliveryTaskModel.fromFirestore(taskDoc);
        debugPrint("[DRIVER_DASH_CTRL] Active task (${activeTaskDetails.value?.orderId}) details updated. Status: ${activeTaskDetails.value?.status}");

        // التحقق مما إذا كانت المهمة قد وصلت إلى حالة نهائية
        final status = activeTaskDetails.value?.status;
        if (status == DeliveryTaskStatus.delivered ||
            status == DeliveryTaskStatus.delivery_failed ||
            status == DeliveryTaskStatus.returned_to_seller ||
            status.toString().toLowerCase().contains("cancel")) {
          debugPrint("[DRIVER_DASH_CTRL] Active task $taskIdFromProfile reached final state. Attempting to clear from profile.");
          _clearActiveTaskFromDriverProfileIfMatches(taskIdFromProfile);
        }
      } else {
        debugPrint("[DRIVER_DASH_CTRL] Active task $taskIdFromProfile no longer exists or data is null.");
        activeTaskDetails.value = null;
        _clearActiveTaskFromDriverProfileIfMatches(taskIdFromProfile); //  امسحها من ملف السائق
      }
      isLoadingActiveTask.value = false;
    }, onError: (error, stack) {
      debugPrint("[DRIVER_DASH_CTRL] Error listening to active task $taskIdFromProfile: $error\n$stack");
      activeTaskDetails.value = null;
      isLoadingActiveTask.value = false;
    });
  }

  Future<void> _clearActiveTaskFromDriverProfileIfMatches(String taskIdEnded) async {
    if (currentDriver.value == null) return;
    // امسح فقط إذا كانت المهمة الحالية في ملف السائق هي نفسها المهمة التي انتهت
    if (currentDriver.value!.currentFocusedTaskId == taskIdEnded) {
      debugPrint("[DRIVER_DASH_CTRL] Clearing $taskIdEnded from driver $driverId's currentTask, setting to online_available.");
      try {
        await _firestore.collection(FirebaseX.deliveryDriversCollection).doc(driverId).update({
          'currentTaskId': FieldValue.delete(),
          'availabilityStatus': "online_available", // الحالة الافتراضية بعد انتهاء مهمة
        });
        //  ملاحظة: اشتراك subscribeToDriverProfile سيقوم بتحديث currentDriver.value و availabilityStatusString.value
      } catch (e) {
        debugPrint("[DRIVER_DASH_CTRL] Error clearing task from driver profile: $e");
      }
    }
  }


  Future<void> fetchAvailableTasksCount() async {
    if (currentDriver.value?.approvedCompanyId == null || currentDriver.value!.approvedCompanyId!.isEmpty) {
      availablePickupTasksCount.value = 0; isLoadingAvailableTasksCount.value = false; return;
    }
    isLoadingAvailableTasksCount.value = true;
    try { /* ... (نفس كود جلب العدد من الرد السابق، باستخدام الحالات الصحيحة) ... */
      final List<String> statusesAvailableForDriverPickup = [
        deliveryTaskStatusToString(DeliveryTaskStatus.ready_for_driver_offers_narrow),
        deliveryTaskStatusToString(DeliveryTaskStatus.ready_for_driver_offers_wide),
      ];
      final snapshot = await _firestore.collection(FirebaseX.deliveryTasksCollection)
          .where('assignedCompanyId', isEqualTo: currentDriver.value!.approvedCompanyId)
          .where('status', whereIn: statusesAvailableForDriverPickup)
          .where('assignedToDriverId', isNull: true)
          .count().get();
      availablePickupTasksCount.value = snapshot.count ?? 0;
    } catch (e) { availablePickupTasksCount.value = 0; debugPrint("Error fetching available tasks count: $e");}
    finally { isLoadingAvailableTasksCount.value = false; }
  }





  void _processActiveTaskForDashboardDisplay(_) { //  البارامتر "_" يشير إلى أننا لا نستخدم القيمة الممررة من ever() مباشرة
    final DeliveryTaskModel? task = activeTaskDetails.value;
    final LatLng? driverLoc = _currentDriverLocationForDashboardProcessing.value;

    // لا تقم بالمعالجة إذا لم تكن هناك مهمة نشطة أو إذا كان السائق ليس في حالة "on_task"
    if (task == null || availabilityStatusString.value != "on_task") {
      processedActiveTaskForDashboard.value = null;
      etaForDashboardActiveTask.value = "";
      if (task == null && (currentDriver.value?.currentFocusedTaskId?.isNotEmpty ?? false)){
        debugPrint("[DASH_CTRL_PROCESS] No active task details available yet, but driver has a focused task. Waiting for task data.");
      } else if (task != null && availabilityStatusString.value != "on_task"){
        debugPrint("[DASH_CTRL_PROCESS] Driver is not 'on_task' (currently ${availabilityStatusString.value}). Clearing active task display for dashboard.");
      } else {
        debugPrint("[DASH_CTRL_PROCESS] No active task or driver not 'on_task'. Clearing dashboard display.");
      }
      return;
    }

    debugPrint("[DASH_CTRL_PROCESS] Processing active task ${task.orderIdShort} for dashboard display.");

    // استدعاء دالة مساعدة لتحديد نوع الوجهة والاسم والإحداثيات
    Map<String, dynamic> nextPointInfo = _getNextActionPointDashboard(task);

    double distanceKm = -1.0;
    String distanceText = "جاري حساب المسافة...";
    String calculatedEta = "";

    if (driverLoc != null && nextPointInfo['latlng'] != null) {
      final LatLng destinationLatLng = nextPointInfo['latlng'] as LatLng;
      distanceKm = Geolocator.distanceBetween(
        driverLoc.latitude,
        driverLoc.longitude,
        destinationLatLng.latitude,
        destinationLatLng.longitude,
      ) / 1000.0;

      if (distanceKm < 0) distanceKm = 0; //  ضمان عدم وجود قيم سالبة

      if (distanceKm < 0.01) { // أقل من 10 أمتار، اعتبره "قريب جدًا" أو "وصلت"
        distanceText = "أقل من 10 م";
        calculatedEta = "وصلت تقريبًا";
      } else if (distanceKm < 1.0) {
        distanceText = "${(distanceKm * 1000).toStringAsFixed(0)} م";
      } else {
        distanceText = "${distanceKm.toStringAsFixed(1)} كم";
      }

      // حساب ETA المبدئي (نفس المنطق الذي استخدمناه سابقًا)
      if (distanceKm >= 0.01) { // فقط إذا كانت هناك مسافة فعلية
        // افترض متوسط سرعة للسائق، مثلاً 2.5 إلى 3.5 دقيقة لكل كيلومتر في المدينة
        double estimatedMinutes = distanceKm * 3.0; //  متوسط 3 دقائق/كم
        if (estimatedMinutes < 1) {
          calculatedEta = "~ أقل من دقيقة";
        } else if (estimatedMinutes < 60) {
          calculatedEta = "~ ${estimatedMinutes.round()} دقيقة";
        } else {
          calculatedEta = "~ ${NumberFormat('0.#', 'ar').format(estimatedMinutes / 60)} س";
        }
      }
    } else if (nextPointInfo['latlng'] == null) { // إذا لم يكن هناك إحداثيات للوجهة
      distanceText = "الوجهة غير محددة";
      calculatedEta = "";
    } else if (driverLoc == null){ //  إذا كان موقع السائق غير متاح بعد
      distanceText = "تحديد موقعك..."; // أو رسالة مناسبة
      calculatedEta = "";
    }

    etaForDashboardActiveTask.value = calculatedEta; // تحديث متغير ETA المنفصل

    processedActiveTaskForDashboard.value = ProcessedTaskForDriverDisplay(
      task: task,
      distanceToNextPointKm: distanceKm,
      distanceDisplay: distanceText,
      nextActionLatLng: nextPointInfo['latlng'] as LatLng? ?? task.pickupLatLng!, // fallback إذا كانت null
      nextActionType: nextPointInfo['type'] as String, // هذا يُستخدم داخليًا بواسطة nextPointInfo ولكن قد لا يُستخدم في taskDisplayType
      nextActionName: nextPointInfo['name'] as String,
      taskDisplayType: nextPointInfo['display_type'] as String, //  مهم جدًا للـ switch case في الواجهة
      destinationHubName: task.isHubToHubTransfer ? (task.destinationHubName ?? task.buyerName) : null,
      // isConsolidatable و consolidatableTasksCount ليست ضرورية جدًا للعرض المباشر في بطاقة الداشبورد المفردة
      isConsolidatable: false, // أو يمكن حسابها إذا أردت عرض (+X طلبات أخرى) هنا أيضًا
      consolidatableTasksCount: 0,
      // buyerIdForConsolidation: null, // ليس ضروريًا هنا
    );

    debugPrint("[DASH_CTRL_PROCESS] Finished processing. ETA: ${etaForDashboardActiveTask.value}. Processed task order: ${processedActiveTaskForDashboard.value?.task.orderIdShort}");
  }

  Map<String, dynamic> _getNextActionPointDashboard(DeliveryTaskModel task) {
    LatLng nextLatLng;
    String actionName = "وجهة غير محددة";
    String displayType = "unknown_display"; // لتصنيف العرض في الواجهة
    String internalType = "unknown_action"; // للعمليات الداخلية إذا احتجت للتمييز الدقيق

    final currentStatus = task.status;

    if (task.isHubToHubTransfer == true) {
      displayType = "hub_to_hub";
      if (currentStatus == DeliveryTaskStatus.driver_assigned || currentStatus == DeliveryTaskStatus.en_route_to_pickup) {
        nextLatLng = task.pickupLatLng!; // المقر المصدر
        actionName = task.originHubName ?? task.sellerName ?? "مقر الانطلاق (نقل)";
        internalType = "pickup_origin_hub";
      } else { // (picked_up_from_origin_hub, en_route_to_destination_hub, at_destination_hub)
        nextLatLng = task.deliveryLatLng!; // المقر الوجهة
        actionName = task.destinationHubName ?? task.buyerName ?? "مقر الوصول (نقل)";
        internalType = "delivery_destination_hub";
      }
    } else { // ليست مهمة نقل (إما بائع->مشترٍ أو مقر->مشترٍ لميل أخير)
      if (currentStatus == DeliveryTaskStatus.driver_assigned || currentStatus == DeliveryTaskStatus.en_route_to_pickup) {
        nextLatLng = task.pickupLatLng!;
        actionName = task.sellerName ?? task.sellerShopName ?? "نقطة الاستلام";
        // التمييز بين استلام من بائع أو مقر لميل أخير
        if (task.originHubName != null || (task.sellerName != null && task.sellerName!.toLowerCase().contains("مقر"))) {
          displayType = "pickup_hub_for_last_mile";
          internalType = "pickup_hub_for_last_mile";
        } else {
          displayType = "pickup_seller";
          internalType = "pickup_seller";
        }
      } else { // (picked_up_from_seller/hub, out_for_delivery_to_buyer, at_buyer_location)
        nextLatLng = task.deliveryLatLng!;
        actionName = task.buyerName ?? "المشتري";
        displayType = "delivery_buyer";
        internalType = "delivery_buyer";
      }
    }
    return {
      'latlng': nextLatLng,
      'name': actionName,
      'display_type': displayType, // هذا ما ستستخدمه ودجة الداشبورد في الـ switch
      'type': internalType, // هذا يمكن أن يكون أكثر تفصيلاً إذا احتجت
      // isConsolidatable, etc. غير ضرورية هنا لهذه الدالة المساعدة البسيطة للداشبورد
    };
  }


  // --- Navigation --- (تأكد أن أسماء المسارات صحيحة AppRoutes.*)
  void goToProfileEdit() {
    if (driverId.isEmpty) {
      Get.snackbar("خطأ", "معرف السائق غير متوفر.");
      return;
    }
    debugPrint("[DRIVER_DASH_CTRL] Navigating to profile edit for driver: $driverId");
    // تأكد أن AppRoutes.DRIVER_PROFILE_EDIT معرف وأن الـ Binding يتوقع 'driverId' كـ argument
    Get.toNamed(AppRoutes.DRIVER_PROFILE_EDIT, arguments: {'driverId': driverId});
  }
  void goToActiveTaskDetails() {
    if (activeTaskDetails.value != null) {
      Get.toNamed(AppRoutes.DRIVER_DELIVERY_NAVIGATION, arguments: {'taskId': activeTaskDetails.value!.taskId});
    } else { Get.snackbar("لا توجد مهمة", "ليس لديك مهمة نشطة حاليًا."); }
  }
  void goToAvailableTasks() => Get.toNamed(AppRoutes.DRIVER_AVAILABLE_TASKS);
  void goToMyTasksHistory() => Get.toNamed(AppRoutes.DRIVER_MY_TASKS);
  void goToEarnings() => Get.toNamed(AppRoutes.DRIVER_EARNINGS);



  @override
  void onClose() {
    _driverProfileSubscription?.cancel();
    _activeTaskSubscription?.cancel();
    _performanceRefreshTimer?.cancel();
    _availableTasksCountSubscription?.cancel();
    _driverLocationSubForDashboard?.cancel(); // <--- **لا تنسَ هذا**
    debugPrint("[DRIVER_DASH_CTRL] Controller for driver $driverId closed and resources disposed.");
    super.onClose();
  }
}