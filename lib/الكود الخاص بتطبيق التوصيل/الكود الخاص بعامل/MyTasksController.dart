import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // For LatLng
import '../../XXX/xxx_firebase.dart';
import '../../routes/app_routes.dart';
import '../الكود الخاص بمشرف التوصيل/DeliveryTaskModel.dart';
import 'ProcessedTaskForDriverDisplay.dart';
// استورد نماذجك، ثوابتك، مساراتك
// import 'path_to_models/DeliveryTaskModel.dart';
// import 'path_to_models/DeliveryDriverModel.dart';
// import 'path_to_constants/FirebaseX.dart';
// import 'path_to_routes/AppRoutes.dart';

// --- (نماذج مؤقتة، استبدلها بملفاتك) ---
// ... (DeliveryTaskModel, DeliveryDriverModel, FirebaseX, Enums, AppRoutes)
// DeliveryTaskModel يجب أن يحتوي على الحقول التي ستعرضها (orderId, sellerName, buyerName, status, createdAt, deliveryConfirmationTime, deliveryFee)
// DeliveryDriverModel يجب أن يحتوي على currentTaskId
// ---

class MyTasksController extends GetxController with GetSingleTickerProviderStateMixin { // GetSingleTickerProviderStateMixin لـ TabController
  final String driverId; // UID للسائق الحالي، يتم تمريره من Binding
  // String? currentDriverCompanyId; // إذا كنت ستحتاج لفلترة المهام المنتهية حسب الشركة التي كانت المهمة لها (أقل شيوعًا)

  MyTasksController({required this.driverId});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance; // إذا احتجت لـ currentUser

  // --- لحالات التبويبات ---
  late TabController tabController;
  final RxInt selectedTabIndex = 0.obs; // 0 للمهام الحالية، 1 لسجل المهام

  // --- للمهام الحالية/النشطة (Assigned & In-Progress) ---
  final RxList<DeliveryTaskModel> activeAssignedTasks = <DeliveryTaskModel>[].obs;
  final RxBool isLoadingActiveTasks = true.obs;
  final RxString activeTasksError = ''.obs;
  StreamSubscription? _activeTasksSubscription;
  final RxnString focusedTaskId = RxnString(null); // لتحديد المهمة التي يركز عليها السائق (كانت currentTaskId في driverModel)

  // --- لسجل المهام (المنتهية) ---
  final RxList<DeliveryTaskModel> completedTasksHistory = <DeliveryTaskModel>[].obs;
  final RxBool isLoadingHistory = true.obs;
  final RxString historyError = ''.obs;
  final int _historyTasksPerPage = 10;
  DocumentSnapshot? _lastHistoryDocument;
  final RxBool isLoadingMoreHistory = false.obs;
  final RxBool hasMoreHistoryTasks = true.obs;
  final RxMap<String, List<DeliveryTaskModel>> tasksGroupedByBuyer = <String, List<DeliveryTaskModel>>{}.obs;

  // (اختياري) فلاتر لسجل المهام
  final Rxn<DateTimeRange> historyDateRangeFilter = Rxn<DateTimeRange>(null);
  final Rxn<DeliveryTaskStatus> historyStatusFilter = Rxn<DeliveryTaskStatus>(null);
  final Rxn<LatLng> currentDriverMapPosition = Rxn<LatLng>(null);
  StreamSubscription? _driverProfileSubscriptionForLocation; // للاستماع لتحديثات موقع السائق

  // --- جديد: القائمة النهائية التي ستُعرض في الواجهة ---
  final RxList<ProcessedTaskForDriverDisplay> processedDriverTasks = <ProcessedTaskForDriverDisplay>[].obs;

  // --- جديد: ماركرات الخريطة ---
  final RxSet<Marker> driverViewMapMarkers = <Marker>{}.obs; // ماركرات لعرضها في واجهة السائق
  GoogleMapController? driverTasksMapController; // للتحكم في الخريطة الخاصة بواجهة مهام السائق



  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);
    tabController.addListener(() {
      if (selectedTabIndex.value != tabController.index) {
        selectedTabIndex.value = tabController.index;
        if (tabController.index == 0) {
          //  subscribeToActiveAssignedTasks()  سيعمل ويحدث كل شيء
        } else if (tabController.index == 1) {
          // إذا كانت البيانات لم تُحمل بعد للسجل أو تريد تحديثها عند اختيار التبويب
          if (completedTasksHistory.isEmpty && hasMoreHistoryTasks.value) {
            fetchCompletedTasksHistory(isInitialFetch: true);
          }
        }
      }
    });

    if (driverId.isEmpty) {
      activeTasksError.value = "خطأ: معرف السائق مفقود.";
      historyError.value = "خطأ: معرف السائق مفقود."; // إذا كان لديك تبويب تاريخ
      isLoadingActiveTasks.value = false;
      isLoadingHistory.value = false;
      return;
    }

    _loadFocusedTaskIdFromDriverProfile();      // كما كان
    _subscribeToDriverLocationAndFocusedTask(); // <--- دالة جديدة للاستماع لموقع السائق وحالته
    subscribeToActiveAssignedTasks();         // كما كان، ولكنه سيستدعي المعالجة الآن
    fetchCompletedTasksHistory(isInitialFetch: true); // لجلب أول دفعة من السجل
  }


  // --- دالة جديدة للاستماع لتحديثات موقع السائق و focusedTaskId ---
  void _subscribeToDriverLocationAndFocusedTask() {
    _driverProfileSubscriptionForLocation?.cancel();
    _driverProfileSubscriptionForLocation = _firestore
        .collection(FirebaseX.deliveryDriversCollection)
        .doc(driverId)
        .snapshots()
        .listen((driverDoc) {
      if (driverDoc.exists && driverDoc.data() != null) {
        final driverDataMap = driverDoc.data()!;
        // تحديث موقع السائق الحالي للخريطة
        final GeoPoint? loc = driverDataMap['currentLocation'] as GeoPoint?;
        if (loc != null) {
          currentDriverMapPosition.value = LatLng(loc.latitude, loc.longitude);
        } else {
          currentDriverMapPosition.value = null; // إذا لم يكن هناك موقع
        }

        // تحديث focusedTaskId إذا تغير من مكان آخر (مثل شاشة الملاحة عند إنهاء مهمة)
        final String? newFocusedId = driverDataMap['currentFocusedTaskId'] as String?;
        if (focusedTaskId.value != newFocusedId) {
          focusedTaskId.value = newFocusedId;
        }

        // بمجرد تحديث موقع السائق، قد نحتاج لإعادة حساب المسافات للمهام النشطة
        // وربما إعادة بناء ماركرات الخريطة
        //  _processAndDisplayTasks(); // <--- سيتم استدعاؤها عندما تتغير activeAssignedTasks أيضًا
        // إعادة بناء ماركرات الخريطة (بما فيها موقع السائق)
        _buildMapMarkers();
        // يمكن أيضًا استدعاء _processAndDisplayTasks() إذا كان التحديث للموقع فقط يؤثر على الترتيب المعروض

      } else {
        currentDriverMapPosition.value = null;
        focusedTaskId.value = null;
      }
    }, onError: (error) {
      debugPrint("MyTasksController: Error listening to driver location/focus: $error");
      currentDriverMapPosition.value = null;
    });
  }





  Future<void> _loadFocusedTaskIdFromDriverProfile() async {
    try {
      DocumentSnapshot driverDoc = await _firestore.collection(FirebaseX.deliveryDriversCollection).doc(driverId).get();
      if(driverDoc.exists && driverDoc.data() != null){
        focusedTaskId.value = (driverDoc.data() as Map<String,dynamic>)['currentTaskId'] as String?;
        debugPrint("[MY_TASKS_CTRL] Initial focused task ID: ${focusedTaskId.value}");
      }
    } catch(e){
      debugPrint("[MY_TASKS_CTRL] Error loading focused task ID: $e");
    }
  }

  void subscribeToActiveAssignedTasks() {
    isLoadingActiveTasks.value = true;
    activeTasksError.value = '';
    _activeTasksSubscription?.cancel();
    debugPrint("[MY_TASKS_CTRL] Subscribing to active/assigned tasks for driver $driverId");

    final List<String> activeStatuses = [ // الحالات التي تعتبر "نشطة" أو "معينة تنتظر البدء"
      deliveryTaskStatusToString(DeliveryTaskStatus.driver_assigned),
      deliveryTaskStatusToString(DeliveryTaskStatus.en_route_to_pickup),
      deliveryTaskStatusToString(DeliveryTaskStatus.picked_up_from_seller),
      deliveryTaskStatusToString(DeliveryTaskStatus.out_for_delivery_to_buyer),
      deliveryTaskStatusToString(DeliveryTaskStatus.at_buyer_location),
    ];

    _activeTasksSubscription = _firestore
        .collection(FirebaseX.deliveryTasksCollection)
        .where('assignedToDriverId', isEqualTo: driverId)
        .where('status', whereIn: activeStatuses)
        .orderBy('createdAt', descending: true) // يمكنك تغيير الترتيب
        .snapshots()
        .listen((snapshot) {
      final tasks = snapshot.docs
          .map((doc) => DeliveryTaskModel.fromFirestore(doc as DocumentSnapshot<Map<String,dynamic>>))
          .toList();
      activeAssignedTasks.assignAll(tasks);
      _updateTasksGroupedByBuyer();

      _processAndDisplayTasks();
      isLoadingActiveTasks.value = false;
      debugPrint("[MY_TASKS_CTRL] Active/assigned tasks updated. Count: ${activeAssignedTasks.length}");
    }, onError: (error) {
      _updateTasksGroupedByBuyer();

      activeTasksError.value = "خطأ في تحميل المهام الحالية: $error";
      isLoadingActiveTasks.value = false;
    });
  }


  void _updateTasksGroupedByBuyer() {
    Map<String, List<DeliveryTaskModel>> newGrouping = {};
    for (var task in activeAssignedTasks) {
      // فقط قم بتجميع المهام التي قد تكون جزءًا من تسليم مجمع لمشترٍ
      if (task.status == DeliveryTaskStatus.picked_up_from_seller ||
          task.status == DeliveryTaskStatus.out_for_delivery_to_buyer ||
          task.status == DeliveryTaskStatus.at_buyer_location) {
        if (task.buyerId.isNotEmpty) {
          newGrouping.putIfAbsent(task.buyerId, () => []).add(task);
        }
      }
    }
    tasksGroupedByBuyer.assignAll(newGrouping); // تحديث المتغير العضو RxMap
    debugPrint("[MyTasksCtrl] tasksGroupedByBuyer updated. Groups: ${tasksGroupedByBuyer.length}");
  }


  void _processAndDisplayTasks() {
    if (currentDriverMapPosition.value == null && activeAssignedTasks.isNotEmpty) {
      // إذا لم يكن لدينا موقع السائق بعد، لا يمكننا حساب المسافات أو الترتيب بدقة.
      // يمكن عرض المهام بدون مسافات مؤقتًا، أو الانتظار.
      // للتبسيط الآن، سننتظر حتى يتوفر موقع السائق أو نعرضها بدون مسافات.
      debugPrint("MyTasksController: Driver location not yet available. Skipping task processing or distances will be N/A.");
      // إذا أردت معالجتها بدون مسافات (أو مع مسافة -1):
      // processedDriverTasks.assignAll(
      //   activeAssignedTasks.map((task) {
      //     final nextPointInfo = _getNextActionPoint(task);
      //     return ProcessedTaskForDriverDisplay(
      //       task: task,
      //       distanceToNextPointKm: -1,
      //       distanceDisplay: "جاري تحديد المسافة...",
      //       nextActionLatLng: nextPointInfo['latlng'],
      //       nextActionType: nextPointInfo['type'],
      //       nextActionName: nextPointInfo['name'],
      //     );
      //   }).toList()
      // );
      // _buildMapMarkers(); // حدث الماركرات بدون ماركر سائق
      // return;
    }
    List<ProcessedTaskForDriverDisplay> tempProcessedList = [];
    //
    // for (var task in activeAssignedTasks) {
    //   if (task.status == DeliveryTaskStatus.picked_up_from_seller ||
    //       task.status == DeliveryTaskStatus.out_for_delivery_to_buyer ||
    //       task.status == DeliveryTaskStatus.at_buyer_location) {
    //     if (task.buyerId.isNotEmpty) { // تحقق إضافي بسيط
    //       tasksGroupedByBuyer.putIfAbsent(task.buyerId, () => []).add(task);
    //     }
    //   }
    // }

    for (var task in activeAssignedTasks) {
      double distanceKm = -1.0;
      String distanceText = "المسافة غير متوفرة";

      Map<String, dynamic> nextPointInfo = _getNextActionPoint(task); // لا تحتاج لتمرير tasksGroupedByBuyer هنا

      if (currentDriverMapPosition.value != null && nextPointInfo['latlng'] != null) {
        distanceKm = Geolocator.distanceBetween(
          currentDriverMapPosition.value!.latitude,
          currentDriverMapPosition.value!.longitude,
          (nextPointInfo['latlng'] as LatLng).latitude,
          (nextPointInfo['latlng'] as LatLng).longitude,
        ) / 1000.0;

        if (distanceKm < 0) distanceKm = 0;

        if (distanceKm < 1.0) {
          distanceText = "${(distanceKm * 1000).toStringAsFixed(0)} م";
        } else {
          distanceText = "${distanceKm.toStringAsFixed(1)} كم";
        }
      } else if (nextPointInfo['latlng'] == null) {
        distanceText = "وجهة غير محددة للمسافة";
      }

      tempProcessedList.add(ProcessedTaskForDriverDisplay(
        task: task,
        distanceToNextPointKm: distanceKm,
        distanceDisplay: distanceText,
        nextActionLatLng: nextPointInfo['latlng'] as LatLng,
        nextActionType: nextPointInfo['type'] as String,
        nextActionName: nextPointInfo['name'] as String,
        isConsolidatable: nextPointInfo['is_consolidatable_for_buyer'] as bool? ?? false,
        consolidatableTasksCount: nextPointInfo['consolidatable_tasks_count'] as int? ?? 0,
        buyerIdForConsolidation: nextPointInfo['buyer_id_for_consolidation'] as String?,
        taskDisplayType: nextPointInfo['display_type'] as String,
        destinationHubName: task.isHubToHubTransfer ? task.destinationHubName : null,
      ));
    }








    // الترتيب: الأقرب أولاً. المهام التي لا يمكن حساب مسافتها تُوضع في النهاية.
    tempProcessedList.sort((a, b) {
      if (a.distanceToNextPointKm < 0 && b.distanceToNextPointKm < 0) return 0; // كلاهما بدون مسافة
      if (a.distanceToNextPointKm < 0) return 1; // a بدون مسافة، يذهب للنهاية
      if (b.distanceToNextPointKm < 0) return -1; // b بدون مسافة، يذهب للنهاية
      return a.distanceToNextPointKm.compareTo(b.distanceToNextPointKm);
    });

    processedDriverTasks.assignAll(tempProcessedList);
    _buildMapMarkers(); // تحديث ماركرات الخريطة بعد معالجة كل المهام
  }

  // --- دالة مساعدة لتحديد نقطة العمل التالية واسمها ---
  Map<String, dynamic> _getNextActionPoint(DeliveryTaskModel task) {
    LatLng nextLatLng;
    String actionType = "unknown_task_type";
    String actionName = "وجهة غير محددة";
    String displayTypeForCard = "unknown"; // للعرض في بطاقة MyTasksScreen
    bool isConsolidatableForBuyer = false;
    int consolidatableCount = 0;
    String? buyerIdForConsGroup;

    final currentStatus = task.status;

    if (task.isHubToHubTransfer == true) {
      displayTypeForCard = "hub_to_hub";
      if (currentStatus == DeliveryTaskStatus.driver_assigned ||
          currentStatus == DeliveryTaskStatus.en_route_to_pickup) {
        nextLatLng = task.pickupLatLng!; // موقع المقر المصدر
        actionType = "pickup_origin_hub"; // نوع خاص للاستلام من مقر (لشحنة نقل)
        actionName = task.originHubName ?? task.sellerName ?? "مقر الانطلاق (نقل)";
      } else { // (picked_up_from_seller/origin_hub, out_for_delivery/en_route_to_dest_hub, at_buyer_location/at_dest_hub)
        nextLatLng = task.deliveryLatLng!; // موقع المقر الوجهة
        actionType = "delivery_destination_hub"; // نوع خاص للتسليم لمقر (لشحنة نقل)
        actionName = task.destinationHubName ?? task.buyerName ?? "مقر الوصول (نقل)";
      }
    } else { // مهمة عادية (بائع -> مشترٍ) أو ميل أخير (مقر -> مشترٍ)
      if (currentStatus == DeliveryTaskStatus.driver_assigned ||
          currentStatus == DeliveryTaskStatus.en_route_to_pickup) {
        nextLatLng = task.pickupLatLng!;
        // هل المصدر مقر أم بائع؟ يمكن التحقق من sellerId إذا كان يتبع نمط hubId
        // أو إذا كان هناك حقل إضافي مثل task.pickupType = 'hub'/'seller'
        // للتبسيط الآن، نفترض أن sellerName سيعكس ذلك (مثل "مقر: X" أو "بائع: Y")
        if (task.sellerName != null && task.sellerName!.toLowerCase().contains("مقر")) { // افتراض بسيط للتمييز
          actionType = "pickup_hub_for_last_mile"; // استلام من مقر لمهمة ميل أخير
          displayTypeForCard = "pickup_hub_last_mile";
        } else {
          actionType = "pickup_seller";
          displayTypeForCard = "pickup_seller";
        }
        actionName = task.sellerName ?? task.sellerShopName ?? "نقطة الاستلام";

      } else if (currentStatus == DeliveryTaskStatus.picked_up_from_seller || // أو picked_up_from_hub
          currentStatus == DeliveryTaskStatus.out_for_delivery_to_buyer ||
          currentStatus == DeliveryTaskStatus.at_buyer_location) {
        nextLatLng = task.deliveryLatLng!;
        actionType = "delivery_buyer";
        actionName = task.buyerName ?? "المشتري";
        displayTypeForCard = "delivery_buyer";

        // منطق التجميع للمشتري يبقى كما هو
        final List<DeliveryTaskModel>? tasksForThisBuyer = tasksGroupedByBuyer[task.buyerId];
        if (tasksForThisBuyer != null && tasksForThisBuyer.length > 1) {
          isConsolidatableForBuyer = true;
          consolidatableCount = tasksForThisBuyer.length - 1;
          buyerIdForConsGroup = task.buyerId;
        }
      } else {
        nextLatLng = task.pickupLatLng!; // Fallback
        actionName = task.sellerName ?? "نقطة انطلاق";
        displayTypeForCard = "pickup_seller"; // Fallback
      }
    }
    return { /* ... (نفس الـ return map) */
      'latlng': nextLatLng, 'type': actionType, 'name': actionName,
      'display_type': displayTypeForCard,
      'is_consolidatable_for_buyer': isConsolidatableForBuyer,
      'consolidatable_tasks_count': consolidatableCount,
      'buyer_id_for_consolidation': buyerIdForConsGroup,
    };
  }



  void _buildMapMarkers() {
    Set<Marker> newMarkers = {};

    // إضافة ماركر السائق
    if (currentDriverMapPosition.value != null) {
      newMarkers.add(Marker(
          markerId: MarkerId('driver_location_$driverId'), // <--- تنبيه: تم تغيير الاسم هنا ليستخدم driverId
          position: currentDriverMapPosition.value!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange), // لون مميز للسائق
          infoWindow: const InfoWindow(title: "موقعك الحالي"),
          zIndex: 2 // ليكون فوق ماركرات المهام
      ));
    }

    // إضافة ماركرات لنقاط الاستلام/التسليم للمهام النشطة (المعروضة)
    for (var processedTaskItem in processedDriverTasks) { // <--- التكرار على processedDriverTasks
      final task = processedTaskItem.task;
      final nextActionInfo = _getNextActionPoint(task); // لتحديد إذا كانت النقطة استلام أم تسليم

      if (nextActionInfo['type'] == "pickup") {
        newMarkers.add(Marker(
            markerId: MarkerId('pickup_${task.taskId}'),
            position: task.pickupLatLng!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
            infoWindow: InfoWindow(
                title: "استلام من: ${task.sellerName ?? task.sellerShopName ?? 'البائع'}",
                snippet: "طلب: ${task.orderIdShort} - ${processedTaskItem.distanceDisplay}" // <--- المسافة من هنا
            ),
            onTap: () {
              setFocusOnTaskAndNavigate(task.taskId);
            }
        ));
        // (اختياري) إذا أردت عرض ماركر التسليم حتى لو لم تكن الوجهة الحالية، أضفه هنا بأيقونة مختلفة
        //  if (task.status == DeliveryTaskStatus.driver_assigned || task.status == DeliveryTaskStatus.en_route_to_pickup) {
        //   newMarkers.add(Marker(
        //     markerId: MarkerId('delivery_dim_${task.taskId}'),
        //     position: task.deliveryLatLng,
        //     icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen), // أو أيقونة باهتة
        //     alpha: 0.6,
        //     infoWindow: InfoWindow(title: "تسليم إلى: ${task.buyerName ?? 'المشتري'}", snippet: "(وجهة تالية)"),
        //   ));
        // }

      } else if (nextActionInfo['type'] == "delivery") {
        // نعرض فقط ماركر التسليم كوجهة رئيسية
        newMarkers.add(Marker(
            markerId: MarkerId('delivery_${task.taskId}'),
            position: task.deliveryLatLng!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(
                title: "تسليم إلى: ${task.buyerName ?? 'المشتري'}",
                snippet: "طلب: ${task.orderIdShort} - ${processedTaskItem.distanceDisplay}" // <--- المسافة من هنا
            ),
            onTap: () {
              setFocusOnTaskAndNavigate(task.taskId);
            }
        ));
        // ماركر الاستلام (البائع) يمكن أن يعرض كمعلومة تاريخية أو لا يعرض
        //  newMarkers.add(Marker(
        //    markerId: MarkerId('pickup_done_${task.taskId}'),
        //    position: task.pickupLatLng,
        //    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
        //    alpha: 0.5, // شفاف
        //    infoWindow: InfoWindow(title: "تم الاستلام من: ${task.sellerName ?? 'البائع'}"),
        //  ));
      }
    }
    driverViewMapMarkers.assignAll(newMarkers); // تحديث قائمة ماركرات الواجهة

    // (اختياري) تحديث كاميرا الخريطة لتشمل جميع الماركرات
    _fitMapToMarkersIfAny();
  }



  void _fitMapToMarkersIfAny() {
    if (driverTasksMapController != null && driverViewMapMarkers.isNotEmpty) {
      if (driverViewMapMarkers.length == 1) { // إذا كان ماركر السائق هو الوحيد
        driverTasksMapController!.animateCamera(
          CameraUpdate.newLatLngZoom(driverViewMapMarkers.first.position, 15.0), // زوم جيد لماركر واحد
        );
      } else {
        try {
          LatLngBounds bounds = _boundsFromMarkersList(driverViewMapMarkers.toList());
          driverTasksMapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 70.0)); // 70 padding
        } catch (e) {
          debugPrint("Error fitting map to bounds in MyTasks: $e");
          if (currentDriverMapPosition.value != null) {
            driverTasksMapController!.animateCamera(CameraUpdate.newLatLngZoom(currentDriverMapPosition.value!, 15.0));
          } else if(driverViewMapMarkers.isNotEmpty) { // Fallback to first task marker if driver loc is null
            driverTasksMapController!.animateCamera(CameraUpdate.newLatLngZoom(driverViewMapMarkers.first.position, 13.0));
          }
        }
      }
    }
  }





  LatLngBounds _boundsFromMarkersList(List<Marker> markers) {
    if (markers.isEmpty) {
      // قيمة افتراضية إذا لم تكن هناك ماركرات (مثلاً، موقع افتراضي أو حدود واسعة جدًا)
      // أو يمكنك رمي خطأ إذا كنت تتوقع دائمًا وجود ماركرات
      return LatLngBounds(
        southwest: const LatLng(33.0, 44.0), // مثال لوسط العراق
        northeast: const LatLng(34.0, 45.0),
      );
    }

    // --- التصحيح هنا ---
    double minLat = markers.first.position.latitude;
    double maxLat = markers.first.position.latitude;
    double minLng = markers.first.position.longitude;
    double maxLng = markers.first.position.longitude;
    // --- نهاية التصحيح ---

    for (Marker marker in markers) {
      final lat = marker.position.latitude;
      final lng = marker.position.longitude;

      minLat = lat < minLat ? lat : minLat;
      maxLat = lat > maxLat ? lat : maxLat;
      minLng = lng < minLng ? lng : minLng;
      maxLng = lng > maxLng ? lng : maxLng;
    }

    // لتجنب الخطأ إذا كانت جميع النقاط متطابقة (minLat == maxLat)
    // أو إذا كان هناك ماركر واحد فقط
    if (minLat == maxLat) {
      maxLat = minLat + 0.005; // زيادة طفيفة للحدود
      minLat = minLat - 0.005;
    }
    if (minLng == maxLng) {
      maxLng = minLng + 0.005;
      minLng = minLng - 0.005;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }



  void onDriverMapCreated(GoogleMapController controller) { // <--- اسم جديد لتجنب التعارض
    driverTasksMapController = controller;
    _fitMapToMarkersIfAny(); // محاولة تحديث الكاميرا بعد إنشاء الخريطة
  }







  Future<void> fetchCompletedTasksHistory({bool isInitialFetch = false}) async {
    if (isLoadingMoreHistory.value || (!isInitialFetch && !hasMoreHistoryTasks.value)) return;

    if (isInitialFetch) {
      isLoadingHistory.value = true;
      _lastHistoryDocument = null;
      hasMoreHistoryTasks.value = true;
      completedTasksHistory.clear(); // امسح القائمة عند الجلب الأولي
    } else {
      isLoadingMoreHistory.value = true;
    }
    historyError.value = '';
    debugPrint("[MY_TASKS_CTRL] Fetching task history. Initial: $isInitialFetch. After: ${_lastHistoryDocument?.id}");

    try {
      Query query = _firestore
          .collection(FirebaseX.deliveryTasksCollection)
          .where('assignedToDriverId', isEqualTo: driverId);

      // حالات السجل النهائية
      final List<String> finalStatuses = [
        deliveryTaskStatusToString(DeliveryTaskStatus.delivered),
        deliveryTaskStatusToString(DeliveryTaskStatus.delivery_failed),
        deliveryTaskStatusToString(DeliveryTaskStatus.returned_to_seller),
        deliveryTaskStatusToString(DeliveryTaskStatus.cancelled_by_seller),
        deliveryTaskStatusToString(DeliveryTaskStatus.cancelled_by_buyer),
        deliveryTaskStatusToString(DeliveryTaskStatus.cancelled_by_company_admin),
        deliveryTaskStatusToString(DeliveryTaskStatus.cancelled_by_platform_admin),
      ];

      if (historyStatusFilter.value != null) { // إذا كان هناك فلتر حالة محدد للسجل
        query = query.where('status', isEqualTo: deliveryTaskStatusToString(historyStatusFilter.value!));
      } else { // وإلا جلب جميع الحالات النهائية
        query = query.where('status', whereIn: finalStatuses);
      }

      if (historyDateRangeFilter.value != null) {
        DateTime endDateForQuery = DateTime(historyDateRangeFilter.value!.end.year, historyDateRangeFilter.value!.end.month, historyDateRangeFilter.value!.end.day, 23, 59, 59);
        query = query.where('deliveryConfirmationTime', isGreaterThanOrEqualTo: Timestamp.fromDate(historyDateRangeFilter.value!.start)); // أو createdAt/updatedAt
        query = query.where('deliveryConfirmationTime', isLessThanOrEqualTo: Timestamp.fromDate(endDateForQuery));
      }
      // الأحدث أولاً للسجل
      query = query.orderBy('deliveryConfirmationTime', descending: true) // أو createdAt إذا لم يكن deliveryConfirmationTime موجودًا دائمًا
          .orderBy('createdAt', descending: true); // فرز ثانوي

      if (_lastHistoryDocument != null && !isInitialFetch) {
        query = query.startAfterDocument(_lastHistoryDocument!);
      }
      query = query.limit(_historyTasksPerPage);

      final snapshot = await query.get();
      final newTasks = snapshot.docs
          .map((doc) => DeliveryTaskModel.fromFirestore(doc as DocumentSnapshot<Map<String,dynamic>>))
          .toList();

      if (newTasks.length < _historyTasksPerPage) hasMoreHistoryTasks.value = false;
      if (snapshot.docs.isNotEmpty) _lastHistoryDocument = snapshot.docs.last;

      if (isInitialFetch) {
        completedTasksHistory.assignAll(newTasks);
      } else {
        completedTasksHistory.addAll(newTasks);
      }
      debugPrint("[MY_TASKS_CTRL] Fetched ${newTasks.length} history tasks. Total: ${completedTasksHistory.length}. HasMore: ${hasMoreHistoryTasks.value}");

    } catch (e,s) {
      debugPrint("[MY_TASKS_CTRL] Error fetching task history: $e\n$s");
      historyError.value = "فشل جلب سجل المهام: $e";
    } finally {
      if (isInitialFetch) isLoadingHistory.value = false;
      isLoadingMoreHistory.value = false;
    }
  }

  void loadMoreHistory() {
    if (!isLoadingMoreHistory.value && hasMoreHistoryTasks.value) {
      fetchCompletedTasksHistory(isInitialFetch: false);
    }
  }

  // دالة لتحديد المهمة التي سيركز عليها السائق وينتقل لها
  Future<void> setFocusOnTaskAndNavigate(String taskIdToFocus) async {
    final ProcessedTaskForDriverDisplay? taskToProcess = processedDriverTasks.firstWhereOrNull((pt) => pt.task.taskId == taskIdToFocus);
    if (taskToProcess == null) {
      Get.snackbar("خطأ", "المهمة المحددة غير موجودة للمعالجة."); return;
    }
    if (driverId.isEmpty) { Get.snackbar("خطأ", "معرف السائق غير متوفر."); return; }

    List<String>? consolidatedTaskIdsToSend; // القائمة التي سترسل
    bool isPartOfConsolidationGroup = false;

    // --- منطق تحديد المهام المجمعة ---
    // هذا الشرط يعني: إذا كانت المهمة الحالية (التي نقر عليها) هي لتسليم لمشترٍ
    // وهناك مهام أخرى مسجلة لنفس هذا المشتري (حسب buyerIdForConsolidation)
    // وحالة هذه المهام الأخرى تسمح بالتسليم أيضًا.
    if (taskToProcess.taskDisplayType == "delivery_buyer" && // تأكد أنها مهمة تسليم للمشتري
        taskToProcess.isConsolidatable && // إذا كان قد تم تحديدها كجزء من مجموعة محتملة
        taskToProcess.buyerIdForConsolidation != null) {

      isPartOfConsolidationGroup = true; // المهمة الرئيسية هي جزء من مجموعة
      // جلب كل المهام الصالحة للتسليم لنفس المشتري من القائمة الأصلية (activeAssignedTasks)
      consolidatedTaskIdsToSend = activeAssignedTasks
          .where((originalTask) =>
      originalTask.buyerId == taskToProcess.buyerIdForConsolidation &&
          (originalTask.status == DeliveryTaskStatus.picked_up_from_seller ||
              originalTask.status == DeliveryTaskStatus.out_for_delivery_to_buyer ||
              originalTask.status == DeliveryTaskStatus.at_buyer_location)
      )
          .map((t) => t.taskId)
          .toSet() // استخدام Set لإزالة أي تكرار محتمل في IDs (غير مرجح لكنه آمن)
          .toList();

      // تأكد من أن المهمة الرئيسية (taskIdToFocus) موجودة في القائمة إذا لم تكن already هناك
      if (!consolidatedTaskIdsToSend.contains(taskIdToFocus)) {
        consolidatedTaskIdsToSend.insert(0, taskIdToFocus); // ضعها في البداية
      }

      debugPrint("[MyTasksCtrl] Navigating with consolidated tasks for buyer ${taskToProcess.buyerIdForConsolidation}: $consolidatedTaskIdsToSend. Main Task ID: $taskIdToFocus");
    } else if (taskToProcess.taskDisplayType == "delivery_buyer") {
      // إذا كانت مهمة تسليم عادية (ليست جزءًا من مجموعة معلنة في processedTask)،
      // لكن لا يزال من الممكن أن تكون الوحيدة لذاك المشتري في هذه اللحظة
      // isPartOfConsolidationGroup يبقى false، consolidatedTaskIdsToSend سيكون null أو يحتوي على taskIdToFocus فقط
      consolidatedTaskIdsToSend = [taskIdToFocus]; // على الأقل المهمة نفسها
      debugPrint("[MyTasksCtrl] Navigating for single delivery task (not flagged as consolidatable group): $taskIdToFocus");
    }
    // (إذا كانت مهمة استلام أو نقل لمقر، isPartOfConsolidationGroup و consolidatedTaskIdsToSend سيكونان null/false)
    // ... (منطق تحديث Firestore للسائق والانتقال)
    try {
      await _firestore.collection(FirebaseX.deliveryDriversCollection).doc(driverId).update({
        'currentFocusedTaskId': taskIdToFocus,
        'availabilityStatus': 'on_task',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      focusedTaskId.value = taskIdToFocus;

      Get.toNamed(
          AppRoutes.DRIVER_DELIVERY_NAVIGATION.replaceFirst(':taskId', taskIdToFocus),
          arguments: {
            'taskId': taskIdToFocus,
            'consolidatedTaskIds': consolidatedTaskIdsToSend, // مررها حتى لو كانت تحتوي على ID واحد أو null
            'mainTaskIsConsolidatedGroupMember': isPartOfConsolidationGroup, // أو اسم أوضح مثل isPartOfBuyerConsolidation
          }
      );
    } catch (e) {
      debugPrint("MyTasksController: Error setting focused task $taskIdToFocus: $e");
      Get.snackbar("خطأ", "فشل في بدء/متابعة المهمة: ${e.toString()}", backgroundColor: Colors.red);
    }
  }

  void navigateToTaskDetails(String taskIdForDetails) {
    Get.toNamed(AppRoutes.DRIVER_DELIVERY_NAVIGATION.replaceFirst(':taskId', taskIdForDetails),
        arguments: {'taskId': taskIdForDetails});
  }


  @override
  void onClose() {
    tabController.dispose();
    _activeTasksSubscription?.cancel();
    _driverProfileSubscriptionForLocation?.cancel(); // <--- إلغاء الاشتراك الجديد
    driverTasksMapController?.dispose();             // <--- تخلص من متحكم الخريطة
    // ... (إلغاء اشتراكات السجل ومسح الفلاتر إذا كانت مستخدمة)
    debugPrint("[MyTasksController] Controller closed.");
    super.onClose();
  }
}