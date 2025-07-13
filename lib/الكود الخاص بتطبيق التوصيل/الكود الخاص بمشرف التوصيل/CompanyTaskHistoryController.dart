import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // لـ DateRangePickerDialog
import 'package:get/get.dart';

import '../../XXX/xxx_firebase.dart';
import '../../routes/app_routes.dart';
import '../الكود الخاص بعامل/DeliveryDriverModel.dart';
import 'CompanyAdminDashboardController.dart';
import 'DeliveryTaskModel.dart'; // لتنسيق التواريخ



// --- تعريفات مؤقتة (استبدلها بملفاتك الحقيقية) ---
// ... (نماذج DeliveryTaskModel, DeliveryDriverModel, FirebaseX, Enums) ...
// --- نهاية التعريفات المؤقتة ---

class CompanyTaskHistoryController extends GetxController {
  final String companyId;
  CompanyTaskHistoryController({required this.companyId});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxList<DeliveryTaskModel> tasksNeedingReassignment = <DeliveryTaskModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  // --- متغيرات الفلترة ---
  final Rxn<DateTimeRange> selectedDateRange = Rxn<DateTimeRange>(null);
  final RxnString selectedDriverId = RxnString(null); // UID للسائق المختار للفلترة
  final Rxn<DeliveryTaskStatus> selectedTaskStatus = Rxn<DeliveryTaskStatus>(null); // لفلترة حالة معينة
  StreamSubscription<QuerySnapshot>? _tasksSubscription; // <--- تغيير هنا: النوع وقابلية الـ null

  // (اختياري) قائمة بالسائقين التابعين للشركة لملء قائمة فلتر السائقين
  final RxList<DeliveryDriverModel> companyDriversForFilter = <DeliveryDriverModel>[].obs;
  final RxBool isLoadingDriversForFilter = false.obs;

  // للبحث النصي في سجل المهام (يمكن أن يبحث في orderId, buyerName, sellerName)
  final TextEditingController historySearchController = TextEditingController();
  final RxString historySearchQuery = ''.obs;
  Timer? _historySearchDebounce;

  // pagination
  final int _tasksPerPage = 15;
  DocumentSnapshot? _lastDocumentSnapshot; // لصفحات البيانات
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMoreTasks = true.obs;

  @override
  void onInit() {
    super.onInit();
    if (companyId.isEmpty) {
      errorMessage.value = "خطأ: معرف الشركة مفقود.";
      isLoading.value = false;
      return;
    }

    historySearchController.addListener(() {
      _historySearchDebounce?.cancel();
      _historySearchDebounce = Timer(const Duration(milliseconds: 500), () {
        if(historySearchQuery.value != historySearchController.text.trim()){
          historySearchQuery.value = historySearchController.text.trim();
          resetAndFetchHistory(); // أعد الجلب مع البحث الجديد
        }
      });
    });
    // مستمعات لتغييرات الفلاتر الأخرى
    ever(selectedDateRange, (_) => resetAndFetchHistory());
    ever(selectedDriverId, (_) => resetAndFetchHistory());
    ever(selectedTaskStatus, (_) => resetAndFetchHistory());


    _fetchCompanyDriversForFilter();
    // تم تغيير استدعاء subscribeToTasksNeedingReassignment إلى fetchTaskHistory
    // لأن fetchTaskHistory الآن تقوم بالاستعلام الأولي
    // إذا كنت تريد الاستماع المستمر للتحديثات، يجب إعادة هيكلة fetchTaskHistory
    // لتستخدم snapshots() وتحديث _tasksSubscription.
    // حاليًا، سنفترض أنك تريد "جلب" قائمة، ويمكنك إضافة زر تحديث.
    // إذا أردت الاستماع الحي، سنحتاج لتعديل كبير لـ fetchTaskHistory و pagination.
    // لهذا الرد، سأفترض أننا لا نستخدم اشتراكًا حيًا للمهام التي تحتاج تدخل (لتجنب تعقيد الـ pagination مع snapshots)
    // بل نعتمد على resetAndFetchHistory.
    // لذلك، سيتم تعليق _tasksSubscription و subscribeToTasksNeedingReassignment.
    subscribeToTasksNeedingReassignment();
  }

// تم تعليق هذه الدالة مؤقتًا لصالح نظام جلب يدوي مع pagination
  // إذا أردت الاستماع الحي، يجب دمج هذا المنطق مع fetchTaskHistory أو استدعاؤه بشكل منفصل.
  void subscribeToTasksNeedingReassignment() { // يمكنك إعادة تسميتها إلى subscribeToTasksAwaitingDriver إذا كان أوضح
    if (companyId.isEmpty) { // تحقق مبكر من companyId
      errorMessage.value = "خطأ: معرف الشركة مطلوب لجلب المهام.";
      isLoading.value = false;
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';
    debugPrint("[INTERVENTION_CTRL] Subscribing to tasks awaiting driver assignment for company: $companyId");

    _tasksSubscription?.cancel(); // إلغاء أي اشتراك سابق

    // --- تحديد الحالات التي تتطلب تدخل المشرف للتعيين/إعادة التعيين ---
    final List<String> targetStatusesForIntervention = [
      deliveryTaskStatusToString(DeliveryTaskStatus.pending_driver_assignment),
      deliveryTaskStatusToString(DeliveryTaskStatus.ready_for_driver_offers_wide),
      // إذا كان لديك حالة "driver_unassigned_by_admin" أو ما شابه، يمكنك إضافتها هنا
    ];
    // ----------------------------------------------------------------

    _tasksSubscription = _firestore
        .collection(FirebaseX.deliveryTasksCollection)
        .where('assignedCompanyId', isEqualTo: companyId)
    // --- استخدام whereIn للتحقق من عدة حالات ---
        .where('status', whereIn: targetStatusesForIntervention)
    // ----------------------------------------
        .orderBy('createdAt', descending: false) // الأقدم أولاً عادةً للمهام التي تحتاج إجراء
        .snapshots()
        .listen((snapshot) {
      debugPrint("[INTERVENTION_CTRL] Received ${snapshot.docs.length} tasks awaiting driver assignment.");
      final tasks = snapshot.docs
          .map((doc) => DeliveryTaskModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
      tasksNeedingReassignment.assignAll(tasks);
      isLoading.value = false;
    }, onError: (error, stackTrace) {
      debugPrint("[INTERVENTION_CTRL] Error listening to tasks awaiting driver assignment: $error\n$stackTrace");
      errorMessage.value = "خطأ في جلب المهام التي تحتاج تعيين سائق: $error";
      tasksNeedingReassignment.clear(); // مسح القائمة عند الخطأ
      isLoading.value = false;
    });
  }
  Future<void> _fetchCompanyDriversForFilter() async {
    if (companyId.isEmpty) return;
    isLoadingDriversForFilter.value = true;
    try {
      final snapshot = await _firestore
          .collection(FirebaseX.deliveryDriversCollection)
          .where('approvedCompanyId', isEqualTo: companyId)
          .where('applicationStatus', isEqualTo: driverApplicationStatusToString(DriverApplicationStatus.approved))
          .orderBy('name')
          .get();
      companyDriversForFilter.assignAll(snapshot.docs
          .map((doc) => DeliveryDriverModel.fromMap(doc.data(), doc.id)).toList());
    } catch (e) {
      debugPrint("Error fetching drivers for filter: $e");
    } finally {
      isLoadingDriversForFilter.value = false;
    }
  }


  Future<void> resetAndFetchHistory() async { // <--- غيرت الاسم ليكون أوضح أنه جلب وليس اشتراك حي
    debugPrint("[INTERVENTION_CTRL] Filters changed or initial fetch. Resetting and fetching history.");
    _lastDocumentSnapshot = null;
    hasMoreTasks.value = true;
    tasksNeedingReassignment.clear(); // هنا اسم القائمة يجب أن يكون tasksNeedingReassignment
    await fetchTaskHistory(isInitialFetch: true); // استخدم await هنا
  }


  Future<void> fetchTaskHistory({bool isInitialFetch = false}) async { // أو fetchInterventionTasksPage
    if (!companyId.isNotEmpty) { /* ...  لا يمكن جلب بدون companyId ... */ return;} // تأكد من companyId
    if (isLoadingMore.value || (!isInitialFetch && !hasMoreTasks.value)) {
      return;
    }
    if (isInitialFetch) {
      isLoading.value = true;
      _lastDocumentSnapshot = null;
      hasMoreTasks.value = true;
      // tasksNeedingReassignment.clear(); //  امسحها عند resetAndFetchHistory بدلاً من هنا
    } else {
      isLoadingMore.value = true;
    }
    errorMessage.value = '';

    try {
      debugPrint("[INTERVENTION_CTRL/FETCH] Fetching tasks needing assignment. Initial: $isInitialFetch. AfterDoc: ${_lastDocumentSnapshot?.id}");
      Query query = _firestore.collection(FirebaseX.deliveryTasksCollection)
          .where('assignedCompanyId', isEqualTo: companyId);

      // --- تحديد الحالات الصحيحة ---
      final List<String> targetStatusesForIntervention = [
        deliveryTaskStatusToString(DeliveryTaskStatus.pending_driver_assignment),
        deliveryTaskStatusToString(DeliveryTaskStatus.ready_for_driver_offers_wide),
      ];
      query = query.where('status', whereIn: targetStatusesForIntervention); // <--- استخدام whereIn
      // --------------------------

      // --- تطبيق الفلاتر الإضافية (تاريخ، سائق - إذا كانت منطقية لهذه الشاشة) ---
      // عادةً ما تكون هذه الشاشة للمهام الحالية التي تحتاج تعيين، لذا قد لا تحتاج لفلاتر تاريخ أو سائق معين
      // ولكن إذا أضفتها، يجب أن يكون كودها هنا
      // if (selectedDateRange.value != null) { /* ... فلتر التاريخ ... */ }
      // إذا كان هناك بحث نصي، يمكنك تطبيقه كما فعلنا سابقًا
      // --------------------------------------------------------------------

      query = query.orderBy('createdAt', descending: false); // الأقدم أولاً لإعطائها أولوية

      if (_lastDocumentSnapshot != null && !isInitialFetch) {
        query = query.startAfterDocument(_lastDocumentSnapshot!);
      }
      query = query.limit(_tasksPerPage);

      final snapshot = await query.get();
      final newTasks = snapshot.docs
          .map((doc) => DeliveryTaskModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();

      if (newTasks.length < _tasksPerPage) {
        hasMoreTasks.value = false;
      }
      if (snapshot.docs.isNotEmpty) {
        _lastDocumentSnapshot = snapshot.docs.last;
      }

      List<DeliveryTaskModel> listToUpdateWith = List.from(newTasks);
      // --- تطبيق البحث النصي المحلي (إذا كنت تستخدمه) ---
      if (historySearchQuery.value.isNotEmpty) {
        String localQuery = historySearchQuery.value.toLowerCase();
        listToUpdateWith = newTasks.where((task) {
          return (task.orderId.toLowerCase().contains(localQuery)) ||
              (task.sellerName?.toLowerCase().contains(localQuery) ?? false) ||
              (task.buyerName?.toLowerCase().contains(localQuery) ?? false) ||
              (task.taskId.toLowerCase().contains(localQuery));
        }).toList();
      }
      // -------------------------------------------------

      if (isInitialFetch) {
        tasksNeedingReassignment.assignAll(listToUpdateWith);
      } else {
        tasksNeedingReassignment.addAll(listToUpdateWith);
      }
      debugPrint("[INTERVENTION_CTRL/FETCH] Fetched ${newTasks.length} (filtered to ${listToUpdateWith.length}). Total: ${tasksNeedingReassignment.length}. HasMore: ${hasMoreTasks.value}");

    } catch (e, s) {
      debugPrint("[INTERVENTION_CTRL/FETCH] Error fetching tasks: $e\n$s");
      errorMessage.value = "فشل جلب المهام: ${e.toString()}";
    } finally {
      if (isInitialFetch) isLoading.value = false;
      isLoadingMore.value = false;
    }
  }
  void _applyLocalSearchFilter(){
    if(historySearchQuery.value.isEmpty) {
      // إذا أردت إعادة عرض جميع النتائج (التي تطابق الفلاتر الأخرى) عند مسح البحث
      // يجب أن تكون taskHistory.assignAll(newTasks) قد تمت في fetchTaskHistory
      // قبل هذا، أو أن تحتفظ بنسخة غير مفلترة نصيًا
      // حاليًا، لن نفعل شيئًا هنا إذا كان البحث فارغًا لأن القائمة already فيها البيانات المفلترة
      // أو يمكنك إعادة بناء القائمة المعروضة من _allFetchedAndFilteredNonTextually (متغير جديد)
      return;
    }
    String query = historySearchQuery.value.toLowerCase();
    // نفترض أن taskHistory تحتوي على النتائج التي تطابق الفلاتر الأخرى (تاريخ، سائق، حالة)
    final List<DeliveryTaskModel> textFiltered = tasksNeedingReassignment.where((task){
      return (task.orderId.toLowerCase().contains(query)) ||
          (task.sellerName?.toLowerCase().contains(query) ?? false) ||
          (task.buyerName?.toLowerCase().contains(query) ?? false) ||
          (task.taskId.toLowerCase().contains(query)); // البحث بمعرف المهمة
    }).toList();
    tasksNeedingReassignment.assignAll(textFiltered); // استبدال taskHistory بالنتائج المفلترة نصيًا
    // هذا يعني أننا نفقد ال pagination إذا فعلنا هذا بهذه الطريقة.
    //  ل pagination مع بحث نصي، عادة تحتاج لدعم الخادم (Firestore لا يدعم search like '%..%') أو Algolia.
    //  للتبسيط، سنجعل البحث يطبق على الدفعة الحالية فقط.
    debugPrint("[TASK_HISTORY_CTRL] Applied local text search. Result count: ${tasksNeedingReassignment.length}");

  }

  void loadMoreTasks() {
    if (!isLoadingMore.value && hasMoreTasks.value) {
      fetchTaskHistory(isInitialFetch: false);
    }
  }


  Future<void> pickDateRange(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: selectedDateRange.value ??
          DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
      firstDate: DateTime(now.year - 2), // سنتين للخلف
      lastDate: now, // حتى اليوم
      locale: const Locale('ar', 'SA'), // للتقويم العربي
      builder: (context, child) { // لتطبيق الثيم على المنتقي
        return Theme(
          data: Theme.of(context).copyWith(
            // يمكنك تخصيص ألوان المنتقي هنا
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: Theme.of(context).primaryColor, // لون التحديد
                onPrimary: Colors.white, // لون النص على التحديد
              ),
              buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary)
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDateRange.value) {
      selectedDateRange.value = picked;
      // resetAndFetchHistory() سيتم استدعاؤه تلقائيًا بواسطة ever()
    }
  }

  void clearDateFilter() {
    selectedDateRange.value = null;
    // resetAndFetchHistory() سيتم استدعاؤه تلقائيًا
  }

  void onDriverFilterChanged(String? driverUid) {
    if (driverUid == "all_drivers_filter_key") { // قيمة خاصة لـ "كل السائقين"
      selectedDriverId.value = null;
    } else {
      selectedDriverId.value = driverUid;
    }
    // resetAndFetchHistory() سيتم استدعاؤه تلقائيًا
  }

  void onStatusFilterChanged(DeliveryTaskStatus? newStatus) {
    selectedTaskStatus.value = newStatus;
    // resetAndFetchHistory() سيتم استدعاؤه تلقائيًا
  }
  void clearAllFilters(){
    selectedDateRange.value = null;
    selectedDriverId.value = null;
    selectedTaskStatus.value = null;
    historySearchController.clear(); // سيؤدي لمسح historySearchQuery.value أيضًا
    // resetAndFetchHistory() سيتم استدعاؤه بسبب تغيير هذه الفلاتر.
  }


  void navigateToTaskDetails(String selectedTaskId) {
    Get.toNamed(AppRoutes.ADMIN_TASK_DETAILS.replaceFirst(':taskId', selectedTaskId));
  }

  @override
  void onClose() {
    _tasksSubscription?.cancel();
    historySearchController.dispose();
    _historySearchDebounce?.cancel();
    debugPrint("[TASK_HISTORY_CTRL] Controller closed and resources disposed.");
    super.onClose();
  }
}