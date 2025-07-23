import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';

import '../../XXX/xxx_firebase.dart';
import '../الكود الخاص بعامل/DeliveryDriverModel.dart';
import 'CompanyAdminDashboardController.dart';
import 'CompanyDriversListScreen.dart';
import '../../Model/DeliveryTaskModel.dart';
import 'TasksNeedingInterventionController.dart';

// استورد نماذجك، ثوابتك، مساراتك، ومتحكمات أخرى
// ... (FirebaseX, DeliveryTaskModel, DeliveryDriverModel, DriverApplicationStatus, DeliveryTaskStatus, AppRoutes, ...)
// ... (TasksNeedingInterventionController, CompanyAdminDashboardController, CompanyDriversListController)

// --- مثال enum للفرز إذا لم يكن معرفًا ---
enum DriverSortOptionForAssignment { distanceAsc, nameAsc }
// ---

class AssignTaskController extends GetxController {
  final String taskId;
  final String companyId;
  final String? initialOrderIdForDisplay;
  final bool isReassignment;

  AssignTaskController({
    required this.taskId,
    required this.companyId,
    this.initialOrderIdForDisplay,
    this.isReassignment = false,
  });

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance; // للمشرف إذا لزم الأمر

  final Rxn<DeliveryTaskModel> taskDetails = Rxn<DeliveryTaskModel>(null);
  // قائمة السائقين الأصلية المتاحة (تُستخدم داخليًا)
  final RxList<DeliveryDriverModel> _originalAvailableDrivers = <DeliveryDriverModel>[].obs;
  // القائمة التي تُعرض للمستخدم (تحتوي على السائق والمسافة)
  final RxList<Map<String, dynamic>> displayDriversList = <Map<String, dynamic>>[].obs;

  final RxBool isLoadingTask = true.obs;
  final RxBool isLoadingDrivers = true.obs; // لتحميل قائمة السائقين
  final RxBool isAssigning = false.obs;    // عند الضغط على زر "تعيين"
  final RxString errorMessage = ''.obs;

  GoogleMapController? mapController;
  final RxSet<Marker> mapMarkers = <Marker>{}.obs; // ماركرات لموقع الاستلام والتسليم، والسائقين

  final TextEditingController driverSearchController = TextEditingController();
  final RxString driverSearchQuery = ''.obs;
  Timer? _searchDebounce;

  final Rx<DriverSortOptionForAssignment> currentSortOption = DriverSortOptionForAssignment.distanceAsc.obs;

  @override
  void onInit() {
    super.onInit();
    if (taskId.isEmpty || companyId.isEmpty) {
      errorMessage.value = "خطأ: معرف المهمة أو الشركة مفقود.";
      isLoadingTask.value = false;
      isLoadingDrivers.value = false;
      return;
    }

    driverSearchController.addListener(() {
      _searchDebounce?.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 400), () {
        if (driverSearchQuery.value != driverSearchController.text.trim()) {
          driverSearchQuery.value = driverSearchController.text.trim();
          // _applyFiltersAndSortDrivers() سيُستدعى تلقائيًا بسبب ever()
        }
      });
    });
    // عند تغيير البحث أو خيار الفرز، أعد تطبيق الفلترة والفرز
    ever(driverSearchQuery, (_) => _applyFiltersAndSortDrivers());
    ever(currentSortOption, (_) => _applyFiltersAndSortDrivers());

    fetchTaskAndAvailableDrivers();
  }

  Future<void> fetchTaskAndAvailableDrivers() async {
    isLoadingTask.value = true;
    isLoadingDrivers.value = true; // ابدأ تحميل السائقين أيضًا
    errorMessage.value = '';
    debugPrint("[ASSIGN_TASK_CTRL] Fetching task $taskId and available drivers for company $companyId");

    try {
      // جلب تفاصيل المهمة
      DocumentSnapshot taskDoc = await _firestore.collection(FirebaseX.deliveryTasksCollection).doc(taskId).get();
      if (taskDoc.exists && taskDoc.data() != null) {
        taskDetails.value = DeliveryTaskModel.fromFirestore(taskDoc as DocumentSnapshot<Map<String,dynamic>>);
        debugPrint("[ASSIGN_TASK_CTRL] Task details fetched. Status: ${taskDetails.value?.status}");
        _updateMapMarkersForTaskAndFit(); // إعداد ماركرات المهمة وضبط الخريطة
      } else {
        throw Exception("لم يتم العثور على المهمة بالمعرف: $taskId لإجراء التعيين.");
      }
      isLoadingTask.value = false;

      // جلب السائقين المتوفرين
      debugPrint("[ASSIGN_TASK_CTRL] Fetching available drivers for company: $companyId");
      final driverSnapshot = await _firestore
          .collection(FirebaseX.deliveryDriversCollection)
          .where('approvedCompanyId', isEqualTo: companyId)
          .where('applicationStatus', isEqualTo: driverApplicationStatusToString(DriverApplicationStatus.approved))
          .where('availabilityStatus', isEqualTo: "online_available")
          .get(); // لا تقم بـ orderBy هنا إذا كان الفرز الديناميكي سيتغير

      final drivers = driverSnapshot.docs
          .map((doc) => DeliveryDriverModel.fromMap(doc.data(), doc.id))
          .toList();
      _originalAvailableDrivers.assignAll(drivers);
      _applyFiltersAndSortDrivers(); // هذا سيقوم بالفلترة والفرز وتحديث displayDriversList و ماركرات السائقين
      debugPrint("[ASSIGN_TASK_CTRL] Fetched ${_originalAvailableDrivers.length} available drivers.");

    } catch (e, s) {
      debugPrint("[ASSIGN_TASK_CTRL] Error fetching task or drivers: $e\n$s");
      errorMessage.value = "فشل جلب بيانات التعيين: ${e.toString()}";
      _originalAvailableDrivers.clear();
      displayDriversList.clear();
    } finally {
      isLoadingTask.value = false;
      isLoadingDrivers.value = false;
    }
  }

  // دالة يتم استدعاؤها عند إنشاء الخريطة من الواجهة
  void onMapCreated(GoogleMapController ctrl) {
    mapController = ctrl;
    debugPrint("[ASSIGN_TASK_CTRL] Map created for assignment screen.");
    _updateMapMarkersForTaskAndFit(); // حاول ضبط الحدود مرة أخرى إذا كانت الماركرات جاهزة
  }

  // تحديث ماركرات المهمة (الاستلام والتسليم) وضبط الخريطة
  void _updateMapMarkersForTaskAndFit() {
    if (taskDetails.value == null) return;
    Set<Marker> newTaskMarkers = {}; // ماركرات المهمة فقط

    GeoPoint? pickupGeo = taskDetails.value!.pickupLocationGeoPoint;
    GeoPoint? deliveryGeo = taskDetails.value!.deliveryLocationGeoPoint;

    if (pickupGeo != null) {
      newTaskMarkers.add(Marker(
        markerId: MarkerId('task_pickup_${taskDetails.value!.taskId}'),
        position: LatLng(pickupGeo.latitude, pickupGeo.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(title: "موقع الاستلام", snippet: taskDetails.value!.sellerName ?? "البائع"),
      ));
    }
    if (deliveryGeo != null) {
      newTaskMarkers.add(Marker(
        markerId: MarkerId('task_delivery_${taskDetails.value!.taskId}'),
        position: LatLng(deliveryGeo.latitude, deliveryGeo.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: "موقع التسليم", snippet: taskDetails.value!.buyerName ?? "المشتري"),
      ));
    }
    // لا تقم بـ mapMarkers.assignAll(newTaskMarkers) هنا مباشرة
    // لأننا نريد إضافة ماركرات السائقين لاحقًا. هذه الدالة تركز على ماركرات المهمة فقط.
    // _updateDriverMarkersOnMap هي التي ستدمجها.

    // ضبط الخريطة لتشمل هذه الماركرات الأولية
    if (mapController != null && newTaskMarkers.isNotEmpty) {
      debugPrint("[ASSIGN_TASK_CTRL] Fitting map to task markers (pickup/delivery).");
      if (newTaskMarkers.length == 1) {
        mapController!.animateCamera(CameraUpdate.newLatLngZoom(newTaskMarkers.first.position, 13.0));
      } else {
        try {
          LatLngBounds bounds = _boundsFromMarkersList(newTaskMarkers.toList());
          mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60.0));
        } catch (e) { /* ... */ }
      }
    }
    _updateDriverMarkersOnMap(); // استدعِ لتحديث ماركرات السائقين ودمجها
  }


  void _applyFiltersAndSortDrivers() {
    debugPrint("[ASSIGN_TASK_CTRL] Applying filters and sort. Search: '${driverSearchQuery.value}', Sort: '${currentSortOption.value}'");
    List<DeliveryDriverModel> tempDrivers = List.from(_originalAvailableDrivers);

    if (driverSearchQuery.value.isNotEmpty) {
      String query = driverSearchQuery.value.toLowerCase();
      tempDrivers = tempDrivers.where((driver) =>
      driver.name.toLowerCase().contains(query) ||
          driver.vehicleType.toLowerCase().contains(query) ||
          (driver.vehiclePlateNumber?.toLowerCase().contains(query) ?? false)
      ).toList();
    }

    List<Map<String, dynamic>> driversWithDataForDisplay = [];
    final pickupLocationForDistance = taskDetails.value?.pickupLocationGeoPoint;

    for (var driver in tempDrivers) {
      double distance = -1.0; // قيمة افتراضية تشير لعدم توفر الموقع أو المسافة
      if (pickupLocationForDistance != null && driver.currentLocation != null) {
        distance = Geolocator.distanceBetween(
          pickupLocationForDistance.latitude,
          pickupLocationForDistance.longitude,
          driver.currentLocation!.latitude,
          driver.currentLocation!.longitude,
        );
      }
      driversWithDataForDisplay.add({'driver': driver, 'distanceMeters': distance});
    }

    // الفرز
    driversWithDataForDisplay.sort((a, b) {
      switch(currentSortOption.value){
        case DriverSortOptionForAssignment.distanceAsc:
          double distA = a['distanceMeters'] as double;
          double distB = b['distanceMeters'] as double;
          if (distA < 0 && distB < 0) return 0;
          if (distA < 0) return 1; // السائق A بدون موقع يظهر في النهاية
          if (distB < 0) return -1; // السائق B بدون موقع يظهر في النهاية
          return distA.compareTo(distB); // الأقرب أولاً
        case DriverSortOptionForAssignment.nameAsc:
          return (a['driver'] as DeliveryDriverModel).name.toLowerCase().compareTo((b['driver'] as DeliveryDriverModel).name.toLowerCase());
      }
    });

    displayDriversList.assignAll(driversWithDataForDisplay);
    _updateDriverMarkersOnMap(); // <--- يتم استدعاؤها هنا بعد الفلترة والفرز
    debugPrint("[ASSIGN_TASK_CTRL] Display drivers list updated. Count: ${displayDriversList.length}");
  }

  // تحديث ماركرات السائقين على الخريطة (مع الاحتفاظ بماركرات المهمة)
  void _updateDriverMarkersOnMap() {
    if (taskDetails.value == null) return; // لا يمكن عرض أي شيء بدون مهمة
    Set<Marker> newCombinedMarkers = {};

    // 1. أضف ماركرات المهمة (الاستلام والتسليم)
    GeoPoint? pickupGeo = taskDetails.value!.pickupLocationGeoPoint;
    GeoPoint? deliveryGeo = taskDetails.value!.deliveryLocationGeoPoint;
    if (pickupGeo != null) {
      newCombinedMarkers.add(Marker(
        markerId: MarkerId('task_pickup_${taskDetails.value!.taskId}'), // استخدام taskId لضمان التفرد
        position: LatLng(pickupGeo.latitude, pickupGeo.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(title: "الاستلام: ${taskDetails.value!.sellerName ?? ''}"),
      ));
    }
    if (deliveryGeo != null) {
      newCombinedMarkers.add(Marker(
        markerId: MarkerId('task_delivery_${taskDetails.value!.taskId}'),
        position: LatLng(deliveryGeo.latitude, deliveryGeo.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: "التسليم: ${taskDetails.value!.buyerName ?? ''}"),
      ));
    }

    // 2. أضف ماركرات السائقين (من القائمة المفلترة displayDriversList)
    // يمكنك تحديد عدد معين من السائقين لعرضهم على الخريطة لتجنب الازدحام
    for (var driverData in displayDriversList.take(5)) { // مثال: عرض أول 5 سائقين من القائمة المفلترة
      final driver = driverData['driver'] as DeliveryDriverModel;
      final distanceMeters = driverData['distanceMeters'] as double;
      String distanceString = "الموقع غير متاح";
      if (distanceMeters >= 0) {
        distanceString = distanceMeters < 1000 ? "${distanceMeters.toStringAsFixed(0)} م" : "${(distanceMeters/1000).toStringAsFixed(1)} كم";
      }

      if (driver.currentLocation != null) {
        newCombinedMarkers.add(Marker(
            markerId: MarkerId("driver_${driver.uid}"), //  استخدم uid السائق فقط هنا لأنه فريد
            position: LatLng(driver.currentLocation!.latitude, driver.currentLocation!.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange), // لون مميز للسائقين
            infoWindow: InfoWindow(title: driver.name, snippet: "المسافة للاستلام: $distanceString"),
            onTap: (){ // عند النقر على ماركر السائق، يمكنك تمييزه في القائمة أو فعل شيء آخر
              debugPrint("Tapped on driver marker: ${driver.name}");
            }
        ));
      }
    }
    mapMarkers.assignAll(newCombinedMarkers); // تحديث المجموعة RxSet بالماركرات الجديدة
    debugPrint("[ASSIGN_TASK_CTRL] Driver and task markers updated on map. Total markers: ${mapMarkers.length}");
  }


  void changeSortOption(DriverSortOptionForAssignment option) {
    if (currentSortOption.value != option) {
      currentSortOption.value = option;
      // _applyFiltersAndSortDrivers() سيُستدعى تلقائيًا بسبب ever()
      debugPrint("[ASSIGN_TASK_CTRL] Sort option changed to: $option");
    }
  }


  LatLngBounds _boundsFromMarkersList(List<Marker> markersList) {
    if (markersList.isEmpty) return LatLngBounds(southwest: LatLng(0,0), northeast: LatLng(0,0));
    double? minLat, maxLat, minLng, maxLng;
    for (Marker markerItem in markersList) {
      final lat = markerItem.position.latitude;
      final lng = markerItem.position.longitude;
      if (minLat == null) { minLat = maxLat = lat; minLng = maxLng = lng; }
      else {
        if (lat > maxLat!) maxLat = lat; if (lat < minLat) minLat = lat;
        if (lng > maxLng!) maxLng = lng; if (lng < minLng!) minLng = lng;
      }
    }
    if (minLat == null || maxLat == null || minLng == null || maxLng == null) {
      return LatLngBounds(southwest: const LatLng(33.0, 44.0), northeast: const LatLng(34.0, 45.0));
    }
    // لتجنب خطأ إذا كانت جميع النقاط متطابقة (minLat == maxLat)
    if (minLat == maxLat) { maxLat = minLat + 0.0001; minLat = minLat - 0.0001;}
    if (minLng == maxLng) { maxLng = minLng + 0.0001; minLng = minLng - 0.0001;}

    return LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng));
  }



  Future<void> assignTaskToSelectedDriver(String selectedDriverId, String selectedDriverName) async {
    if (taskDetails.value == null) {
      Get.snackbar("خطأ", "تفاصيل المهمة غير متاحة للتعيين.", backgroundColor: Colors.red.shade300);
      return;
    }
    if (isAssigning.value) return;

    isAssigning.value = true;
    debugPrint("[ASSIGN_TASK_CTRL] Assigning task ${taskDetails.value!.taskId} to driver $selectedDriverId ($selectedDriverName) by admin.");

    // جلب آخر حالة للسائق والمهمة قبل التحديث (داخل المعاملة)
    String originalTaskStatusBeforeReassignment = deliveryTaskStatusToString(taskDetails.value!.status);
    String? previousDriverId = taskDetails.value!.assignedToDriverId;


    try {
      await _firestore.runTransaction((transaction) async {
        DocumentReference taskDocRef = _firestore.collection(FirebaseX.deliveryTasksCollection).doc(taskId);
        DocumentReference driverDocRef = _firestore.collection(FirebaseX.deliveryDriversCollection).doc(selectedDriverId);

        // التحقق من المهمة
        DocumentSnapshot currentTaskSnap = await transaction.get(taskDocRef);
        if (!currentTaskSnap.exists) throw FirebaseException(plugin: "App", code: "TASK_NOT_FOUND_IN_TX");
        Map<String, dynamic> currentTaskData = currentTaskSnap.data() as Map<String, dynamic>;

        // إذا كانت إعادة تعيين، وكان هناك سائق قديم، حرره
        if (isReassignment && previousDriverId != null && previousDriverId.isNotEmpty && previousDriverId != selectedDriverId) {
          DocumentReference previousDriverDocRef = _firestore.collection(FirebaseX.deliveryDriversCollection).doc(previousDriverId);
          transaction.update(previousDriverDocRef, {
            'currentTaskId': FieldValue.delete(),
            'availabilityStatus': "online_available", // أو حالته السابقة قبل هذه المهمة
            'updatedAt': FieldValue.serverTimestamp(),
          });
          debugPrint("[ASSIGN_TASK_TX] Previous driver $previousDriverId unassigned and status updated.");
        }


        // التحقق من السائق الجديد
        DocumentSnapshot newDriverSnap = await transaction.get(driverDocRef);
        if(!newDriverSnap.exists) throw FirebaseException(plugin: "App", code: "NEW_DRIVER_NOT_FOUND");
        Map<String,dynamic> newDriverData = newDriverSnap.data() as Map<String,dynamic>;

        if(newDriverData['availabilityStatus'] != "online_available"){
          throw FirebaseException(plugin: "App", code: "NEW_DRIVER_NOT_AVAILABLE", message: "السائق ${newDriverData['name']} لم يعد متاحًا.");
        }
        if(newDriverData['currentTaskId'] != null){
          throw FirebaseException(plugin: "App", code: "NEW_DRIVER_ON_ANOTHER_TASK", message: "السائق ${newDriverData['name']} لديه مهمة أخرى.");
        }


        // 1. تحديث مستند المهمة
        Map<String, dynamic> taskUpdateData = {
          'assignedToDriverId': selectedDriverId,
          'driverName': selectedDriverName, // يمكنك جلب الاسم الأحدث من newDriverSnap
          'driverPhoneNumber': newDriverData['phoneNumber'], // جلب من مستند السائق
          // 'assignedCompanyId': companyId, // هذا يجب أن يكون صحيحًا بالفعل
          'status': deliveryTaskStatusToString(DeliveryTaskStatus.driver_assigned), //  الحالة بعد التعيين مباشرة
          'updatedAt': FieldValue.serverTimestamp(),
          'taskNotesInternal': FieldValue.arrayUnion([
            "${DateFormat('yy/MM/dd hh:mm','ar').format(DateTime.now())}: ${isReassignment ? "إعادة تعيين" : "تعيين"} المهمة إلى السائق $selectedDriverName ($selectedDriverId) بواسطة المشرف."
          ])
        };
        transaction.update(taskDocRef, taskUpdateData);
        debugPrint("[ASSIGN_TASK_TX] Task $taskId updated for assignment to $selectedDriverId.");

        // 2. تحديث مستند السائق المختار
        transaction.update(driverDocRef, {
          'currentTaskId': taskId,
          'availabilityStatus': "on_task",
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint("[ASSIGN_TASK_TX] Driver $selectedDriverId updated to on_task for $taskId.");
      });

      Get.back(); // أغلق شاشة التعيين
      Get.snackbar("تم التعيين بنجاح", "تم تعيين المهمة بنجاح للسائق $selectedDriverName.",
          backgroundColor: Colors.green, colorText: Colors.white, duration: Duration(seconds: 3));

      // إرسال إشعار للسائق المعين (يجب أن يكون لديك توكن السائق في newDriverData)
      DocumentSnapshot driverDocForNotif = await _firestore.collection(FirebaseX.deliveryDriversCollection).doc(selectedDriverId).get();
      if (driverDocForNotif.exists) {
        String? driverToken = (driverDocForNotif.data() as Map<String,dynamic>)['fcmToken'];
        if (driverToken != null) {
          // await NotificationService.sendNewTaskNotification(driverToken, taskId, taskDetails.value?.orderId ?? '');
          debugPrint("TODO: Send New Task Notification to Driver $selectedDriverId (Token: $driverToken)");
        }
      }


      // تحديث القوائم في الشاشات السابقة
      if (isReassignment && Get.isRegistered<TasksNeedingInterventionController>()) {
        Get.find<TasksNeedingInterventionController>().subscribeToTasksNeedingReassignment();
      }
      if (Get.isRegistered<CompanyAdminDashboardController>()){
        Get.find<CompanyAdminDashboardController>().fetchAllDashboardData(); // تحديث شامل
      }
      if (Get.isRegistered<CompanyDriversListController>() && companyId == Get.find<CompanyDriversListController>().companyId){
        Get.find<CompanyDriversListController>().fetchCompanyDrivers(); // لتحديث حالة السائقين
      }

    } on FirebaseException catch (fe) {
      debugPrint("[ASSIGN_TASK] Firebase error during transaction: ${fe.code} - ${fe.message}");
      Get.snackbar("خطأ في التعيين", fe.message ?? "فشل تعيين المهمة، الحالة قد تكون تغيرت.", backgroundColor: Colors.red);
    } catch (e, s) {
      debugPrint("[ASSIGN_TASK] General error assigning task: $e\n$s");
      Get.snackbar("خطأ فادح", "فشل تعيين المهمة: ${e.toString()}", backgroundColor: Colors.red.shade400);
    } finally {
      isAssigning.value = false;
    }
  }




  @override
  void onClose() {
    driverSearchController.dispose();
    mapController?.dispose();
    _searchDebounce?.cancel();
    debugPrint("[ASSIGN_TASK_CTRL] Controller closed.");
    super.onClose();
  }
}

