import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';

import '../../XXX/xxx_firebase.dart';
import '../../routes/app_routes.dart';
import '../الكود الخاص بمشرف التوصيل/DeliveryTaskModel.dart'; // لحساب المسافة وفلترتها
// ... (imports أخرى)

// افترض أن DeliveryDriverModel لديك بها approvedCompanyId و currentLocation
// و DeliveryTaskModel بها pickupLocationGeoPoint و province

class AvailableTasksController extends GetxController {
  final String driverId;
  final String driverCompanyId; // يتم تمريرها من Binding أو الحصول عليها من ملف السائق
  final GeoPoint? initialDriverLocation; //  لتسريع حساب المسافة الأولي

  AvailableTasksController({required this.driverId, required this.driverCompanyId, this.initialDriverLocation});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxList<DeliveryTaskModel> availableTasks = <DeliveryTaskModel>[].obs;
  final RxList<Map<String,dynamic>> tasksToDisplayWithDistance = <Map<String,dynamic>>[].obs; // للتخزين مع المسافة
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;
  StreamSubscription? _tasksSubscription;
  final RxString taskSearchQuery = ''.obs; // المتغير Rx الذي يستمع إليه Obx للبحث

  // فلاتر
  final RxDouble maxDistanceFilterKm = 10.0.obs; // مثال: فلتر مسافة افتراضي 10 كم
  final RxString currentSortBy = "distance".obs; // "distance", "newest"
  final TextEditingController driverSearchController = TextEditingController(); // لحقل البحث عن المهام (وليس السائقين)
  Timer? _searchDebounce; // للـ debounce

  @override
  void onInit() {
    super.onInit();
    if (driverId.isEmpty || driverCompanyId.isEmpty) {
      errorMessage.value = "خطأ: معلومات السائق أو الشركة غير كاملة.";
      isLoading.value = false;
      return;
    }
    // مستمعات للفلاتر لإعادة بناء القائمة
    everAll([maxDistanceFilterKm, currentSortBy], (_) => _filterAndSortTasksToDisplay());
    subscribeToCompanyAvailableTasks();
    driverSearchController.addListener(() { //  إذا كان اسم المتحكم النصي هو taskSearchController، عدله هنا أيضًا
      _searchDebounce?.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 450), () { // تأخير أطول قليلاً
        if (taskSearchQuery.value != driverSearchController.text.trim()) { //  وtaskSearchController هنا
          taskSearchQuery.value = driverSearchController.text.trim(); // و taskSearchController هنا
          // _filterAndSortTasksToDisplay()  سيتم استدعاؤه بسبب ever()
        }
      });
    });
    ever(taskSearchQuery, (_) => _filterAndSortTasksToDisplay()); // البحث يُشغل الفلترة
    // -------------------------

    everAll([maxDistanceFilterKm, currentSortBy], (_) => _filterAndSortTasksToDisplay());
    subscribeToCompanyAvailableTasks();

  }

  void subscribeToCompanyAvailableTasks() {
    isLoading.value = true;
    errorMessage.value = '';
    _tasksSubscription?.cancel();
    debugPrint("[AVAIL_TASKS_CTRL] Subscribing to available tasks for company $driverCompanyId");

    _tasksSubscription = _firestore
        .collection(FirebaseX.deliveryTasksCollection)
        .where('assignedCompanyId', isEqualTo: driverCompanyId)
    // --- الحالة الجديدة التي تمثل أن المهمة متاحة لعمال الشركة ---
        .where('status', isEqualTo: deliveryTaskStatusToString(DeliveryTaskStatus.available_for_company_drivers))
    // ---------------------------------------------------------------
        .where('assignedToDriverId', isNull: true) //  لم يتم التقاطها بعد
        .orderBy('createdAt', descending: true) // الأحدث أولاً (يمكن تعديله)
        .snapshots()
        .listen((snapshot) async {
      debugPrint("[AVAIL_TASKS_CTRL] Received ${snapshot.docs.length} available tasks.");
      final tasks = snapshot.docs
          .map((doc) => DeliveryTaskModel.fromFirestore(doc as DocumentSnapshot<Map<String,dynamic>>))
          .toList();
      availableTasks.assignAll(tasks);
      await _filterAndSortTasksToDisplay(); // حساب المسافات والفرز
      isLoading.value = false;
    }, onError: (error) { /* ... */ });
  }


  Future<void> _filterAndSortTasksToDisplay() async {
    isLoading.value = true; // إظهار تحميل أثناء الفلترة/الفرز إذا كانت العمليات معقدة
    List<Map<String,dynamic>> processedTasks = [];
    GeoPoint? currentDriverLoc = initialDriverLocation; // استخدام الموقع الأولي إذا مررناه
    if (taskSearchQuery.value.isNotEmpty) { // استخدم taskSearchQuery.value هنا
      String query = taskSearchQuery.value.toLowerCase();
      List<DeliveryTaskModel> tasksToFilterTextually = availableTasks.toList(); // ابدأ بقائمة المهام الأصلية لهذه الدفعة
      // أو إذا كنت تجلب كل شيء في availableTasks دفعة واحدة
      // بدون pagination في subscribe، فهذا جيد.

      //  نفترض أن `taskDataMap` هو `Map<String,dynamic>` الذي يحتوي على `DeliveryTaskModel`
      //  إذا كان `processedTasks` قد تم ملؤه بالفعل بالمسافات، فالفلترة يجب أن تتم عليه
      //  حالياً، `availableTasks` هي القائمة الأصلية. سنقوم بالفلترة عليها ثم حساب المسافات.

      List<DeliveryTaskModel> textFilteredTasks = availableTasks.where((task) {
        return (task.orderId.toLowerCase().contains(query)) ||
            (task.sellerName?.toLowerCase().contains(query) ?? false) ||
            (task.buyerName?.toLowerCase().contains(query) ?? false) ||
            (task.pickupAddressText?.toLowerCase().contains(query) ?? false) ||
            (task.deliveryAddressText?.toLowerCase().contains(query) ?? false) ||
            (task.taskId.toLowerCase().contains(query));
      }).toList();
      // الآن، `textFilteredTasks` هي التي يجب أن نحسب لها المسافات ونفرزها
      processedTasks.clear(); // امسحها قبل إعادة ملئها
      GeoPoint? currentDriverLoc = initialDriverLocation;
      // ... (جلب موقع السائق الحالي إذا لزم الأمر، كما كان) ...

      for (var task in textFilteredTasks) { // <-- استخدم textFilteredTasks هنا
        double distanceMeters = -1.0;
        if (currentDriverLoc != null && task.pickupLocationGeoPoint != null) {
          distanceMeters = Geolocator.distanceBetween(
              currentDriverLoc.latitude, currentDriverLoc.longitude,
              task.pickupLocationGeoPoint!.latitude, task.pickupLocationGeoPoint!.longitude);
        }
        //  طبق فلتر المسافة
        if (distanceMeters < 0 || (distanceMeters / 1000) <= maxDistanceFilterKm.value) {
          processedTasks.add({'task': task, 'distanceMeters': distanceMeters});
        }
      }
    } else { // لا يوجد بحث نصي، استخدم كل المهام المتاحة للفلترة بالمسافة
      GeoPoint? currentDriverLoc = initialDriverLocation;
      // ... (جلب موقع السائق الحالي) ...
      for (var task in availableTasks) {
        double distanceMeters = -1.0;
        if (currentDriverLoc != null && task.pickupLocationGeoPoint != null) {
          /* ... حساب المسافة ... */
        }
        if (distanceMeters < 0 ||
            (distanceMeters / 1000) <= maxDistanceFilterKm.value) {
          processedTasks.add({'task': task, 'distanceMeters': distanceMeters});
        }
      }
    }
    // جلب موقع السائق الحالي إذا لم يكن لدينا أو إذا أردنا تحديثه (يمكن تعطيل هذا إذا كان التحديث متكررًا جدًا)
    if (currentDriverLoc == null){
      try {
        DocumentSnapshot driverDoc = await _firestore.collection(FirebaseX.deliveryDriversCollection).doc(driverId).get();
        if(driverDoc.exists) currentDriverLoc = (driverDoc.data() as Map<String,dynamic>)['currentLocation'] as GeoPoint?;
      } catch(e) {debugPrint("Error fetching driver location for distance: $e");}
    }


    for (var task in availableTasks) {
      double distanceMeters = -1.0; // المسافة إلى نقطة الاستلام
      if (currentDriverLoc != null && task.pickupLocationGeoPoint != null) {
        distanceMeters = Geolocator.distanceBetween(
            currentDriverLoc.latitude, currentDriverLoc.longitude,
            task.pickupLocationGeoPoint!.latitude, task.pickupLocationGeoPoint!.longitude
        );
      }

      // تطبيق فلتر المسافة
      if (distanceMeters < 0 || (distanceMeters / 1000) <= maxDistanceFilterKm.value) {
        processedTasks.add({'task': task, 'distanceMeters': distanceMeters});
      }
    }

    // الفرز
    processedTasks.sort((a,b){
      if(currentSortBy.value == "distance"){
        double distA = a['distanceMeters'] as double;
        double distB = b['distanceMeters'] as double;
        if (distA < 0 && distB < 0) return 0;
        if (distA < 0) return 1;
        if (distB < 0) return -1;
        return distA.compareTo(distB);
      } else { // "newest"
        return (b['task'] as DeliveryTaskModel).createdAt.compareTo((a['task'] as DeliveryTaskModel).createdAt);
      }
    });
    tasksToDisplayWithDistance.assignAll(processedTasks);
    isLoading.value = false;
    debugPrint("[AVAIL_TASKS_CTRL] Tasks filtered and sorted. Displaying: ${tasksToDisplayWithDistance.length}");
  }

  void updateMaxDistanceFilter(double newMaxKm){
    maxDistanceFilterKm.value = newMaxKm;
  }
  void updateSortBy(String newSort){
    currentSortBy.value = newSort;
  }


  Future<void> acceptTask(DeliveryTaskModel taskToAccept) async {
    // Get.dialog(Center(child:CircularProgressIndicator()), barrierDismissible: false);
    debugPrint("[AVAIL_TASKS_CTRL] Driver $driverId attempting to accept task: ${taskToAccept.taskId}");
    // تأكد من أن السائق ما زال متوفرًا (online_available) قبل قبول المهمة
    DocumentSnapshot driverSnap = await _firestore.collection(FirebaseX.deliveryDriversCollection).doc(driverId).get();
    if(!driverSnap.exists || (driverSnap.data() as Map<String,dynamic>)['availabilityStatus'] != "online_available"){
      // if(Get.isDialogOpen ?? false) Get.back();
      Get.snackbar("غير متوفر", "يجب أن تكون في حالة 'متوفر' لقبول المهام.", backgroundColor: Colors.orange);
      return;
    }


    try {
      await _firestore.runTransaction((transaction) async {
        DocumentReference taskDocRef = _firestore.collection(FirebaseX.deliveryTasksCollection).doc(taskToAccept.taskId);
        DocumentReference driverDocRef = _firestore.collection(FirebaseX.deliveryDriversCollection).doc(driverId);

        DocumentSnapshot taskSnapshotInTx = await transaction.get(taskDocRef);
        if (!taskSnapshotInTx.exists) throw FirebaseException(plugin:"App", code:"TASK_GONE", message:"المهمة لم تعد متوفرة.");

        final currentTaskData = taskSnapshotInTx.data() as Map<String, dynamic>;
        // التحقق الحاسم: هل المهمة لا تزال متاحة ولم يأخذها أحد وحالتها صحيحة؟
        if (currentTaskData['assignedToDriverId'] != null) {
          throw FirebaseException(plugin:"App", code:"TASK_TAKEN", message:"عذرًا، هذه المهمة تم التقاطها بواسطة سائق آخر.");
        }
        if (stringToDeliveryTaskStatus(currentTaskData['status']) != DeliveryTaskStatus.available_for_company_drivers &&
            stringToDeliveryTaskStatus(currentTaskData['status']) != DeliveryTaskStatus.ready_for_driver_offers_narrow && // إذا كنت ستدعمها هنا
            stringToDeliveryTaskStatus(currentTaskData['status']) != DeliveryTaskStatus.ready_for_driver_offers_wide
        ) {
          throw FirebaseException(plugin:"App", code:"TASK_STATUS_INVALID", message:"حالة المهمة تغيرت، لم تعد متاحة للقبول.");
        }

        // 1. تحديث مستند المهمة
        transaction.update(taskDocRef, {
          'assignedToDriverId': driverId,
          'driverName': (driverSnap.data() as Map<String,dynamic>)['name'] ?? 'سائق', // اسم السائق من ملفه
          'status': deliveryTaskStatusToString(DeliveryTaskStatus.driver_assigned), //  أو en_route_to_pickup إذا بدأ فورًا
          'assignTimeToDriver': FieldValue.serverTimestamp(), // وقت تعيينها لهذا السائق
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 2. تحديث مستند السائق
        transaction.update(driverDocRef, {
          'currentTaskId': taskToAccept.taskId, //  تحديد المهمة الحالية
          'availabilityStatus': "on_task",      //  السائق الآن في مهمة
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      // if(Get.isDialogOpen ?? false) Get.back(); //  أغلق مؤشر التحميل
      Get.snackbar("تم قبول المهمة!", "تم قبول المهمة بنجاح. يمكنك الآن البدء بها.",
          backgroundColor: Colors.green, colorText: Colors.white);

      // إرسال إشعار لمشرف الشركة بأن السائق X قبل المهمة Y
      // await NotificationService.notifyCompanyAdminDriverAcceptedTask(driverCompanyId, driverId, taskToAccept.taskId);

      // الانتقال إلى شاشة التنقل للمهمة المقبولة
      Get.offNamed(AppRoutes.DRIVER_DELIVERY_NAVIGATION.replaceFirst(':taskId', taskToAccept.taskId),
          arguments: {'taskId': taskToAccept.taskId});
      //  (Get.offNamed لإزالة شاشة المهام المتاحة من المكدس)

    } on FirebaseException catch(fe) {
      // if(Get.isDialogOpen ?? false) Get.back();
      debugPrint("[AVAIL_TASKS_CTRL] Firebase error accepting task ${taskToAccept.taskId}: ${fe.code} - ${fe.message}");
      Get.snackbar("فشل القبول", fe.message ?? "لم نتمكن من قبول المهمة. قد تكون أُخذت أو تغيرت حالتها.", backgroundColor: Colors.orange, duration: Duration(seconds:4));
      // قم بتحديث القائمة لإزالة المهمة إذا لم تعد متاحة
      subscribeToCompanyAvailableTasks();
    }
    catch (e, s) {
      // if(Get.isDialogOpen ?? false) Get.back();
      debugPrint("[AVAIL_TASKS_CTRL] General error accepting task ${taskToAccept.taskId}: $e\n$s");
      Get.snackbar("خطأ", "فشل قبول المهمة: ${e.toString()}", backgroundColor: Colors.red);
    }
  }


  @override
  void onClose() {
    _tasksSubscription?.cancel();
    driverSearchController.dispose();
    _searchDebounce?.cancel();
    debugPrint("[AVAIL_TASKS_CTRL] Controller closed.");
    super.onClose();
  }
}