import 'dart:async'; // For Timer if needed for auto-refresh
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../XXX/xxx_firebase.dart';
import '../../routes/app_routes.dart';
import '../الكود الخاص بعامل/DeliveryDriverModel.dart';
import 'DeliveryTaskModel.dart';
import 'DriverMapInfoDialog.dart';

// In DeliveryDriverModel.dart (أو ملف enums الخاص بك)

// ... (imports if any) ...

enum DriverApplicationStatus {
  pending,         // طلب معلق، ينتظر مراجعة الشركة
  approved,        // وافقت عليه الشركة، يمكنه العمل
  rejected,        // رفضت الشركة طلب انضمامه
  suspended,       // تم تعليقه مؤقتًا من قبل الشركة
  removed_by_company // تمت إزالته من الشركة (لم يعد تابعًا لها)
}

String driverApplicationStatusToString(DriverApplicationStatus status) {
  return status.toString().split('.').last;
}

DriverApplicationStatus stringToDriverApplicationStatus(String? statusStr) {
  if (statusStr == null || statusStr.isEmpty) {
    return DriverApplicationStatus.pending; // أو أي حالة افتراضية تراها مناسبة
  }
  return DriverApplicationStatus.values.firstWhere(
          (e) => e.toString().split('.').last.toLowerCase() == statusStr.toLowerCase(), // مقارنة غير حساسة لحالة الأحرف
      orElse: () {
        debugPrint("Warning: Unknown DriverApplicationStatus string '$statusStr', defaulting to pending.");
        return DriverApplicationStatus.pending; // قيمة افتراضية عند عدم تطابق
      }
  );
}

// ... (باقي كلاس DeliveryDriverModel إذا كان الـ enum معرفًا هنا) ...
// تأكد أن أي استخدام لـ stringToDriverApplicationStatus في fromMap
// وأن أي استخدام لـ driverApplicationStatusToString في toMap
// يعكس هذه التغييرات (على الرغم من أن الدوال نفسها لا تحتاج لتغيير كبير بسبب .values و .toString().split)






class CompanyAdminDashboardController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late String currentCompanyId; // سيتم تعيينه في onInit
  CompanyAdminDashboardController({required this.currentCompanyId});
 final RxInt tasksPendingDriverAssignmentCount = 0.obs;
  StreamSubscription? _driverStatsSubscription;
  StreamSubscription? _pendingDriverAppsCountSubscription; // مثال لاشتراك آخر
  StreamSubscription? _latestDriverAppsSubscription;    // مثال لاشتراك آخر
  // الإحصائيات
  final RxInt driversOnlineAvailable = 0.obs;
  final RxInt driversOnTask = 0.obs;
  final RxInt driversOffline = 0.obs;
  final RxInt totalTasksTodayForCompany = 0.obs;
  final RxInt completedTasksTodayForCompany = 0.obs;
  final RxInt pendingDriverApplications = 0.obs;
 final RxInt tasksNeedingInterventionCount = 0.obs; // يجب أن يكون موجودًا بالفعل

  // الخريطة
  final RxList<Marker> driverLocationMarkers = <Marker>[].obs;
  final RxList<DeliveryDriverModel> activeDriversForMap = <DeliveryDriverModel>[].obs;
  GoogleMapController? miniMapController;
  final RxBool isLoadingMapData = true.obs;

  // المهام
  final RxList<DeliveryTaskModel> criticalTasksForCompany = <DeliveryTaskModel>[].obs;
  final RxBool isLoadingCriticalTasks = true.obs;
  final RxList<DeliveryDriverModel> latestDriverApplications = <DeliveryDriverModel>[].obs;
  final RxBool isLoadingDriverApps = true.obs;

  final RxBool isLoadingDashboard = true.obs;
  final RxBool companyIdAvailable = false.obs; // لتتبع ما إذا تم تحديد CompanyId بنجاح

  void goToInterventionTasks() {
    debugPrint("[DASHBOARD_CTRL] Navigating to Intervention Tasks Screen. Target Route: ${AppRoutes.TASKS_NEEDING_INTERVENTION}");
    Get.toNamed(AppRoutes.TASKS_NEEDING_INTERVENTION); // <--- استخدام AppRoutes هنا
  }

  @override
  void onInit() {
    super.onInit();
    _initializeCompanyIdAndLoadData();
  }

  Future<void> _initializeCompanyIdAndLoadData() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint("[DASHBOARD_CTRL] User not logged in. Cannot determine company ID.");
      isLoadingDashboard.value = false;
      companyIdAvailable.value = false;
      Get.snackbar("خطأ مصادقة", "الرجاء تسجيل الدخول كمشرف شركة.", duration: Duration(seconds: 5));
      // يمكنك هنا توجيه المستخدم إلى شاشة تسجيل الدخول Get.offAllNamed('/login');
      return;
    }

    // الافتراض: UID الخاص بالمستخدم الحالي هو companyId
    currentCompanyId = currentUser.uid;
    companyIdAvailable.value = true;
    debugPrint("[DASHBOARD_CTRL] Company ID set to current user UID: $currentCompanyId");

    //  // بديل: إذا كان companyId يُخزن في مستند مستخدم المشرف
    //  try {
    //    DocumentSnapshot userDoc = await _firestore.collection(FirebaseX.usersCollection).doc(currentUser.uid).get();
    //    if (userDoc.exists && userDoc.data() != null) {
    //      currentCompanyId = (userDoc.data() as Map<String, dynamic>)['managingCompanyId'] as String?;
    //      if (currentCompanyId != null && currentCompanyId!.isNotEmpty) {
    //        companyIdAvailable.value = true;
    //        debugPrint("[DASHBOARD_CTRL] Company ID fetched from user doc: $currentCompanyId");
    //      } else {
    //        throw Exception("managingCompanyId is null or empty in user document.");
    //      }
    //    } else {
    //      throw Exception("Admin user document not found or has no data.");
    //    }
    //  } catch (e) {
    //    debugPrint("[DASHBOARD_CTRL] Critical Error: Could not determine Company ID for admin ${currentUser.uid}. Error: $e");
    //    isLoadingDashboard.value = false;
    //    companyIdAvailable.value = false;
    //    Get.snackbar("خطأ تهيئة", "لا يمكن تحديد الشركة المرتبطة بهذا الحساب.", duration: Duration(seconds: 7));
    //    return;
    //  }

    // إذا تم تحديد CompanyId بنجاح، ابدأ في جلب البيانات
    if (companyIdAvailable.value) {
      subscribeToLiveStats(); // <--- دالة جديدة لبدء جميع الاشتراكات الحية

      await fetchAllDashboardData();
    }
  }


  void subscribeToLiveStats() {
    if (!companyIdAvailable.value) return;
    debugPrint("[DASHBOARD_CTRL] Initializing live subscriptions for company: $currentCompanyId");
    _driverStatsSubscription?.cancel();
    _pendingDriverAppsCountSubscription?.cancel();
    _latestDriverAppsSubscription?.cancel();
    // يمكنك إضافة المزيد من إلغاء الاشتراكات هنا

    subscribeToDriverStats(); // تبدأ الاستماع لإحصائيات السائقين
    subscribeToPendingDriverApplicationsCount(); // تبدأ الاستماع لعدد طلبات الانضمام
    subscribeToLatestDriverApplicationsList(); // تبدأ الاستماع لأحدث طلبات الانضمام
    // لا تحتاج لـ await هنا لأن هذه دوال void تبدأ استماعًا في الخلفية
  }



// In CompanyAdminDashboardController.dart

  Future<bool> fetchTasksNeedingInterventionCount() async {
    if (!companyIdAvailable.value) {
      debugPrint("[DASHBOARD_CTRL] Cannot fetch intervention task count, company ID not available.");
      tasksNeedingInterventionCount.value = 0;
      return false;
    }

    debugPrint("[DASHBOARD_CTRL] Fetching count of tasks for potential (re)assignment by company: $currentCompanyId");
    try {
      // --- تحديد الحالات التي تتطلب تدخل المشرف للتعيين ---
      final List<String> statusesRequiringAssignment = [
        deliveryTaskStatusToString(DeliveryTaskStatus.pending_driver_assignment), // تنتظر تعيين سائق من الشركة
        deliveryTaskStatusToString(DeliveryTaskStatus.ready_for_driver_offers_wide), // انتهت مهلة العرض الضيق، وقد تحتاج لتعيين يدوي
        // يمكنك إضافة حالات أخرى هنا إذا لزم الأمر،
        // مثل حالة مخصصة "driver_unassigned_needs_action" إذا أردت
      ];
      // --------------------------------------------------

      final aggregateQuerySnapshot = await _firestore
          .collection(FirebaseX.deliveryTasksCollection)
          .where('assignedCompanyId', isEqualTo: currentCompanyId)
      // --- استخدام whereIn للتحقق من عدة حالات ---
          .where('status', whereIn: statusesRequiringAssignment)
      // ----------------------------------------
          .count()
          .get();

      tasksNeedingInterventionCount.value = aggregateQuerySnapshot.count ?? 0;
      debugPrint("[DASHBOARD_CTRL] Count of tasks for potential (re)assignment: ${tasksNeedingInterventionCount.value}");
      return true;
    } catch (e, s) {
      debugPrint("[DASHBOARD_CTRL] Error fetching tasks for (re)assignment count: $e\n$s");
      tasksNeedingInterventionCount.value = 0;
      return false;
    }
  }

  Future<void> fetchAllDashboardData() async {
    if (!companyIdAvailable.value) return; // لا تفعل شيئًا إذا لم يكن companyId متاحًا

    isLoadingDashboard.value = true;
    debugPrint("[DASHBOARD_CTRL] Fetching all dashboard data for company: $currentCompanyId");
    try {
      _driverStatsSubscription?.cancel();
      //  ... إلغاء اشتراكات أخرى ...

      //  بدء الاشتراكات الجديدة
      subscribeToDriverStats(); // <---  استدعاء دالة الاشتراك
      // استخدام Future.wait لتحسين الأداء إذا لم تكن هناك تبعيات صارمة بين الدوال
      final results = await Future.wait([
        // fetchDriverStats(), // <--- تم نقله إلى subscribeToDriverStats()
        fetchTaskStatsToday(),
        fetchTasksPendingDriverAssignmentCount(),
        // fetchPendingDriverApplicationsCount(), // <--- تم نقله للاشتراك
        fetchActiveDriversForMap(), // هذا لا يزال get() حاليًا
        fetchCriticalTasks(),
        // fetchLatestDriverApplicationsList(), // <--- تم نقله للاشتراك
        fetchTasksNeedingInterventionCount(),
      ], eagerError: false);
      // يمكنك التحقق من نتائج results إذا كنت تريد معالجة أخطاء فردية
      // results[0] سيكون نتيجة fetchDriverStats, وهكذا.
      bool anyError = results.any((result) => result == false); // افترض أن الدوال تعيد bool
      if(anyError) {
        debugPrint("[DASHBOARD_CTRL] One or more dashboard data fetches failed.");
        // Get.snackbar("تحذير", "فشل تحميل بعض بيانات لوحة التحكم. قد تكون البيانات غير مكتملة.");
      } else {
        debugPrint("[DASHBOARD_CTRL] All dashboard data fetched successfully.");
      }

    } catch (e,s){ // هذا الـ catch لالتقاط أخطاء لم يتم التقاطها داخل Future.wait
      debugPrint("[DASHBOARD_CTRL] General error during fetchAllDashboardData: $e\n$s");
      Get.snackbar("خطأ", "فشل تحميل بيانات لوحة التحكم بالكامل.", duration: Duration(seconds: 4));
    } finally {
      isLoadingDashboard.value = false;
    }
  }
  void subscribeToDriverStats() { // اسم جديد للدلالة على أنها stream
    if (!companyIdAvailable.value) return;
    debugPrint("[DASHBOARD_CTRL] Subscribing to driver stats for company: $currentCompanyId");
    _driverStatsSubscription = _firestore
        .collection(FirebaseX.deliveryDriversCollection)
        .where('approvedCompanyId', isEqualTo: currentCompanyId)
        .where('applicationStatus', whereIn: [
      driverApplicationStatusToString(DriverApplicationStatus.approved),
      driverApplicationStatusToString(DriverApplicationStatus.suspended),
    ])
        .snapshots() // <--- استخدام snapshots() للاستماع الحي
        .listen((snapshot) {
      int online = 0;
      int onTask = 0;
      int offline = 0;
      for (var doc in snapshot.docs) {
        // لا حاجة لتحويل لـ DeliveryDriverModel كاملاً إذا احتجت فقط لـ availabilityStatus
        final status = doc.data()['availabilityStatus'] as String?;
        if (status == "online_available") {
          online++;
        } else if (status == "on_task") onTask++;
        else offline++;
      }
      driversOnlineAvailable.value = online;
      driversOnTask.value = onTask;
      driversOffline.value = offline;
      debugPrint("[DASHBOARD_CTRL] LIVE Driver Stats Updated: Online=$online, OnTask=$onTask, Offline=$offline");
    }, onError: (error, stackTrace) {
      debugPrint("[DASHBOARD_CTRL] Error listening to driver stats: $error\n$stackTrace");
      // يمكنك تعيين قيم افتراضية أو عرض خطأ في الواجهة
      driversOnlineAvailable.value = 0; driversOnTask.value = 0; driversOffline.value = 0;
    });
  }


  void subscribeToPendingDriverApplicationsCount() async {
    if (!companyIdAvailable.value) return;
    debugPrint("[DASHBOARD_CTRL] Subscribing to pending driver applications count...");
    _pendingDriverAppsCountSubscription = _firestore
        .collection(FirebaseX.deliveryDriversCollection)
        .where('requestedCompanyId', isEqualTo: currentCompanyId)
        .where('applicationStatus', isEqualTo: driverApplicationStatusToString(DriverApplicationStatus.pending))
        .snapshots() // <--- استماع للتغييرات في عدد المستندات
        .listen((snapshot) {
      pendingDriverApplications.value = snapshot.docs.length; // أو snapshot.size
      debugPrint("[DASHBOARD_CTRL] LIVE Pending Driver Applications Count: ${pendingDriverApplications.value}");
    }, onError: (e,s) {
      debugPrint("[DASHBOARD_CTRL] Error listening to pending driver apps count: $e\n$s");
      pendingDriverApplications.value = 0;
    });
  }

// --- مثال لدالة اشتراك لأحدث طلبات الانضمام ---
  void subscribeToLatestDriverApplicationsList() async {
    if (!companyIdAvailable.value) return;
    debugPrint("[DASHBOARD_CTRL] Subscribing to latest driver applications list...");
    _latestDriverAppsSubscription = _firestore
        .collection(FirebaseX.deliveryDriversCollection)
        .where('requestedCompanyId', isEqualTo: currentCompanyId)
        .where('applicationStatus', isEqualTo: driverApplicationStatusToString(DriverApplicationStatus.pending))
        .orderBy('createdAt', descending: true)
        .limit(3)
        .snapshots()
        .listen((snapshot){
      latestDriverApplications.assignAll(snapshot.docs.map((doc) => DeliveryDriverModel.fromMap(doc.data(), doc.id)).toList());
      debugPrint("[DASHBOARD_CTRL] LIVE Latest driver applications list updated. Count: ${latestDriverApplications.length}");
    }, onError: (e,s){ /* ... */ });
  }


  Future<bool> fetchTasksPendingDriverAssignmentCount() async {
    if (!companyIdAvailable.value) return false;
    try {
      final List<String> targetStatuses = [
        deliveryTaskStatusToString(DeliveryTaskStatus.pending_driver_assignment),
        deliveryTaskStatusToString(DeliveryTaskStatus.ready_for_driver_offers_wide), // لأن هذه أيضًا تحتاج لتعيين يدوي عاجل
      ];
      final aggregateQuerySnapshot = await _firestore
          .collection(FirebaseX.deliveryTasksCollection)
          .where('assignedCompanyId', isEqualTo: currentCompanyId)
          .where('status', whereIn: targetStatuses)
          .count()
          .get();
      tasksPendingDriverAssignmentCount.value = aggregateQuerySnapshot.count ?? 0;
      debugPrint("[DASHBOARD_CTRL] Tasks Pending Driver Assignment Count: ${tasksPendingDriverAssignmentCount.value}");
      return true;
    } catch (e) {
      debugPrint("[DASHBOARD_CTRL] Error fetching tasks pending driver assignment count: $e");
      tasksPendingDriverAssignmentCount.value = 0;
      return false;
    }
  }


  // دوال الجلب مع تعديل الفلترة
  Future<bool> fetchDriverStats() async { // تعديل لترجع bool للنجاح/الفشل
    if (!companyIdAvailable.value) return false;
    try {
      final snapshot = await _firestore
          .collection(FirebaseX.deliveryDriversCollection)
          .where('approvedCompanyId', isEqualTo: currentCompanyId)
          .where('applicationStatus', isEqualTo: driverApplicationStatusToString(DriverApplicationStatus.approved))
          .get();
      // ... (نفس منطق حساب online, onTask, offline)
      int online = 0, onTask = 0, offline = 0;
      for (var doc in snapshot.docs) {
        final driver = DeliveryDriverModel.fromMap(doc.data(), doc.id);
        if (driver.availabilityStatus == "online_available") {
          online++;
        } else if (driver.availabilityStatus == "on_task") onTask++;
        else offline++;
      }
      driversOnlineAvailable.value = online;
      driversOnTask.value = onTask;
      driversOffline.value = offline;
      debugPrint("[DASHBOARD_CTRL] Driver Stats: Online=$online, OnTask=$onTask, Offline=$offline");
      return true;
    } catch (e,s) {
      debugPrint("[DASHBOARD_CTRL] Error fetching driver stats: $e\n$s");
      return false;
    }
  }

  Future<bool> fetchTaskStatsToday() async {
    if (!companyIdAvailable.value) return false;
    try {
      DateTime now = DateTime.now();
      DateTime startOfToday = DateTime(now.year, now.month, now.day);
      DateTime endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final snapshot = await _firestore
          .collection(FirebaseX.deliveryTasksCollection)
      // ***** الفلتر الهام هنا *****
          .where('assignedCompanyId', isEqualTo: currentCompanyId) // <-- افترضنا وجود هذا الحقل
          .where('createdAt', isGreaterThanOrEqualTo: startOfToday)
          .where('createdAt', isLessThanOrEqualTo: endOfToday)
          .get();

      int total = snapshot.docs.length; // جميع مهام الشركة اليوم
      int completed = 0;
      for (var doc in snapshot.docs) {
        final DocumentSnapshot<Map<String, dynamic>> taskDocument =
        doc as DocumentSnapshot<Map<String, dynamic>>;

        final task = DeliveryTaskModel.fromFirestore(taskDocument);
        // حالة "delivered" يجب أن تكون معرفة في نظام حالاتك
        if (task.status == DeliveryTaskStatus.delivered) { // <--- قارن مباشرة مع قيمة الـ enum
          completed++;
        }
      }
      totalTasksTodayForCompany.value = total;
      completedTasksTodayForCompany.value = completed;
      debugPrint("[DASHBOARD_CTRL] Task Stats Today for Company: Total=$total, Completed=$completed");
      return true;
    } catch (e,s) {
      debugPrint("[DASHBOARD_CTRL] Error fetching task stats for company: $e\n$s");
      return false;
    }
  }

  Future<bool> fetchPendingDriverApplicationsCount() async {
    if (!companyIdAvailable.value) return false;
    try {
      final snapshot = await _firestore
          .collection(FirebaseX.deliveryDriversCollection)
          .where('requestedCompanyId', isEqualTo: currentCompanyId)
          .where('applicationStatus', isEqualTo: driverApplicationStatusToString(DriverApplicationStatus.pending))
          .count().get(); // استخدام .count()
      pendingDriverApplications.value = snapshot.count ?? 0;
      debugPrint("[DASHBOARD_CTRL] Pending Driver Apps Count: ${pendingDriverApplications.value}");
      return true;
    } catch (e) {      debugPrint("[DASHBOARD_CTRL] Pending Driver Applications: ${pendingDriverApplications.value}");
    return false; }
  }

  Future<bool> fetchActiveDriversForMap() async {
    if (!companyIdAvailable.value) return false;
    isLoadingMapData.value = true;
    try {
      final snapshot = await _firestore
          .collection(FirebaseX.deliveryDriversCollection)
          .where('approvedCompanyId', isEqualTo: currentCompanyId)
          .where('applicationStatus', isEqualTo: driverApplicationStatusToString(DriverApplicationStatus.approved))
          .where('availabilityStatus', whereIn: ['online_available', 'on_task'])
          .get();

      List<Marker> newMarkers = [];
      List<DeliveryDriverModel> newActiveDrivers = [];
      for (var doc in snapshot.docs) {
        final driver = DeliveryDriverModel.fromMap(doc.data(), doc.id);
        newActiveDrivers.add(driver);
        if (driver.currentLocation != null) {
          newMarkers.add(Marker(
              markerId: MarkerId(driver.uid),
              position: LatLng(driver.currentLocation!.latitude, driver.currentLocation!.longitude),
              infoWindow: InfoWindow(title: driver.name, snippet: "الحالة: ${driver.availabilityStatus.replaceAll('_', ' ')}"), // تحسين العرض
              icon: BitmapDescriptor.defaultMarkerWithHue(driver.availabilityStatus == "on_task" ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueGreen),
              onTap: () {
                // --- هنا يتم عرض الحوار ---
                Get.dialog(
                  DriverMapInfoDialog(driver: driver),
                  barrierDismissible: true, // اسمح بالإغلاق بالنقر خارج الحوار
                );
              }
          ));
        }
      }
      // استخدام assignAll لتحديث القوائم التفاعلية
      driverLocationMarkers.assignAll(newMarkers);
      activeDriversForMap.assignAll(newActiveDrivers);
      debugPrint("[DASHBOARD_CTRL] Fetched ${activeDriversForMap.length} active drivers for map.");
      _fitMapToMarkersIfReady(); // محاولة ضبط الخريطة بعد جلب الماركرات
      return true;
    } catch (e,s) {       debugPrint("[DASHBOARD_CTRL] Error fetching active drivers for map: $e\n$s");
    return false; }
    finally { isLoadingMapData.value = false; }
  }

  Future<bool> fetchCriticalTasks() async {
    if (!companyIdAvailable.value) return false;
    isLoadingCriticalTasks.value = true;
    try {
      final now = Timestamp.now();
      // مثال لـ"متأخر": إذا مر أكثر من X وقت على estimatedDeliveryTime أو createdAt
      // final DateTime lateThreshold = DateTime.now().subtract(Duration(hours: 2)); // مثال: متأخر إذا مر ساعتين
      // final Timestamp lateTimestamp = Timestamp.fromDate(lateThreshold);

      final snapshot = await _firestore
          .collection(FirebaseX.deliveryTasksCollection)
      // ***** الفلتر الهام هنا *****
          .where('assignedCompanyId', isEqualTo: currentCompanyId) // <-- فلتر الشركة
          .where('status', whereIn: ['ready_for_pickup', 'out_for_delivery', 'assigned_to_driver'])
      // .where('estimatedDeliveryTime', isLessThan: now) // للمتأخر بناءً على وقت تقديري
      // أو .where('createdAt', isLessThan: lateTimestamp) // للمتأخر بناءً على وقت الإنشاء
          .orderBy('createdAt', descending: false) // الأقدم أولاً للمهام التي تحتاج انتباه
          .limit(5)
          .get();
      criticalTasksForCompany.assignAll(snapshot.docs.map((doc) => DeliveryTaskModel.fromFirestore(doc)).toList());
      debugPrint("[DASHBOARD_CTRL] Fetched ${criticalTasksForCompany.length} critical tasks.");
      return true;
    } catch (e) { /* ... */ return false; }
    finally { isLoadingCriticalTasks.value = false; }
  }

  Future<bool> fetchLatestDriverApplicationsList() async {
    if (!companyIdAvailable.value) return false;
    isLoadingDriverApps.value = true;
    try {
      // ... (نفس كود جلب أحدث طلبات انضمام السائقين)
      final snapshot = await _firestore
          .collection(FirebaseX.deliveryDriversCollection)
          .where('requestedCompanyId', isEqualTo: currentCompanyId)
          .where('applicationStatus', isEqualTo: driverApplicationStatusToString(DriverApplicationStatus.pending))
          .orderBy('createdAt', descending: true).limit(3).get();
      latestDriverApplications.assignAll(snapshot.docs.map((doc) => DeliveryDriverModel.fromMap(doc.data(), doc.id)).toList());
      debugPrint("[DASHBOARD_CTRL] Fetched ${latestDriverApplications.length} latest driver applications list.");
      return true;
    } catch (e,s) { debugPrint("[DASHBOARD_CTRL] Error fetching latest driver applications list: $e\n$s"); return false; }
    finally { isLoadingDriverApps.value = false; }
  }

  void onMiniMapCreated(GoogleMapController controller) {
    miniMapController = controller;
    debugPrint("[DASHBOARD_CTRL] Mini map created.");
    _fitMapToMarkersIfReady(); // حاول ضبط الخريطة عند إنشائها إذا كانت الماركرات موجودة
  }

  // دالة لمساعدة الخريطة المصغرة على عرض جميع الماركرات
  void _fitMapToMarkersIfReady() {
    // انتظر حتى يتم جلب الماركرات وإنشاء الخريطة
    if (miniMapController != null && driverLocationMarkers.isNotEmpty && !isLoadingMapData.value) {
      debugPrint("[DASHBOARD_CTRL] Fitting map to ${driverLocationMarkers.length} markers.");
      if (driverLocationMarkers.length == 1) {
        miniMapController!.animateCamera(CameraUpdate.newLatLngZoom(driverLocationMarkers.first.position, 14.5));
      } else {
        try {
          LatLngBounds bounds = _boundsFromMarkers(driverLocationMarkers.toList());
          miniMapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60.0)); // 60.0 padding
        } catch (e) { // قد يحدث خطأ إذا كانت جميع الماركرات في نفس النقطة تمامًا
          debugPrint("[DASHBOARD_CTRL] Error fitting map to bounds (possibly all markers at same point): $e");
          miniMapController!.animateCamera(CameraUpdate.newLatLngZoom(driverLocationMarkers.first.position, 14.5));
        }
      }
    } else {
      debugPrint("[DASHBOARD_CTRL] Cannot fit map to markers yet. MapCtrl: ${miniMapController!=null}, Markers: ${driverLocationMarkers.length}, LoadingMap: ${isLoadingMapData.value}");
    }
  }


  LatLngBounds _boundsFromMarkers(List<Marker> markers) {
    double? x0, x1, y0, y1;
    for (Marker marker in markers) {
      if (x0 == null) {
        x0 = x1 = marker.position.latitude;
        y0 = y1 = marker.position.longitude;
      } else {
        if (marker.position.latitude > x1!) x1 = marker.position.latitude;
        if (marker.position.latitude < x0) x0 = marker.position.latitude;
        if (marker.position.longitude > y1!) y1 = marker.position.longitude;
        if (marker.position.longitude < y0!) y0 = marker.position.longitude;
      }
    }
    return LatLngBounds(southwest: LatLng(x0!, y0!), northeast: LatLng(x1!, y1!));
  }

  // --- Navigation Methods ---
  void goToManageDrivers() {
    debugPrint("[DASHBOARD_CTRL] Navigating to Manage Drivers. Target Route: ${AppRoutes.COMPANY_DRIVERS_LIST}"); // اطبع المسار المستهدف
    // تأكد أن AppRoutes.COMPANY_DRIVERS_LIST هو بالفعل "/admin/company-drivers"
    Get.toNamed(
        AppRoutes.COMPANY_DRIVERS_LIST, // <--- استخدم الثابت هنا
        arguments: {'companyId': currentCompanyId} // هذا صحيح إذا كنت تمرر arguments
    );
  }

  void goToAssignTasks() { Get.snackbar("انتقال", "إلى صفحة تعيين المهام (لم تنفذ بعد)."); }


  void goToDriverApplications() {
    debugPrint("[DASHBOARD_CTRL] Navigating to Driver Applications. Company: $currentCompanyId");
    Get.toNamed(
      AppRoutes.DRIVER_APPLICATION_REVIEW,
      arguments: {'companyId': currentCompanyId},
    );  }

  void goToTasksPendingDriverAssignment() {
    Get.toNamed(
        AppRoutes.COMPANY_TASKS_PENDING_DRIVER, // المسار الذي عرفته
        arguments: {'companyId': currentCompanyId} // مهم: مرر companyId إذا كان Binding يعتمد عليه
    );
  }


  void goToReports() { Get.snackbar("انتقال", "إلى صفحة التقارير (لم تنفذ بعد)."); }
  void goToFullMapView() { Get.snackbar("انتقال", "إلى خريطة تتبع كاملة (لم تنفذ بعد)."); }


  @override
  void onClose() {
    miniMapController?.dispose();
    _driverStatsSubscription?.cancel();
    _pendingDriverAppsCountSubscription?.cancel();
    _latestDriverAppsSubscription?.cancel();

    debugPrint("[DASHBOARD_CTRL] Controller closed and miniMapController disposed.");
    super.onClose();
  }
}