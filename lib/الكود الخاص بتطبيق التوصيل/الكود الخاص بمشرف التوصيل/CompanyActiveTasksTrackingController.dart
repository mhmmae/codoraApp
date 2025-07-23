import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // For BitmapDescriptor and potentially custom icons
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../../XXX/xxx_firebase.dart';
import '../الكود الخاص بعامل/DeliveryDriverModel.dart';
import 'DeliveryTaskDetailsForAdminScreen.dart';
import '../../Model/DeliveryTaskModel.dart';

// استورد نماذجك وثوابتك
// import 'path_to_models/DeliveryTaskModel.dart';
// import 'path_to_models/DeliveryDriverModel.dart'; // لجلب موقع السائق
// import 'path_to_constants/FirebaseX.dart';

// --- تعريفات مؤقتة (استبدلها بملفاتك الفعلية) ---
// ... (النماذج و FirebaseX كما في الردود السابقة) ...
// --- نهاية التعريفات المؤقتة ---

class CompanyActiveTasksTrackingController extends GetxController {
  final String companyId;
  CompanyActiveTasksTrackingController({required this.companyId});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // قائمة المهام النشطة حاليًا لهذه الشركة
  final RxList<DeliveryTaskModel> activeTasks = <DeliveryTaskModel>[].obs;
  // قاموس لتخزين معلومات السائقين المرتبطين بالمهام النشطة (لتجنب جلب متكرر)
  final RxMap<String, DeliveryDriverModel> taskDrivers = <String, DeliveryDriverModel>{}.obs;
  final RxBool companyIdWasSuccessfullyIdentified = false.obs;

  // لحالة التحميل العامة وعرض الخريطة
  final RxBool isLoadingTasks = true.obs;
  final RxBool isLoadingMap = true.obs; // لتحميل الخريطة الأولي
  final RxString errorMessage = ''.obs;

  // للخريطة
  GoogleMapController? mapController;
  final RxSet<Marker> taskMarkers = <Marker>{}.obs; // ماركرات لمواقع الاستلام والتسليم والسائقين
  final RxSet<Polyline> taskPolylines = <Polyline>{}.obs; // مسارات المهام

  StreamSubscription? _activeTasksSubscription;
  final Map<String, StreamSubscription?> _driverLocationSubscriptions = {}; // لتتبع مواقع السائقين بشكل حي


  @override
  void onInit() {
    super.onInit();
    if (companyId.isEmpty) {
      errorMessage.value = "خطأ: معرف الشركة غير متوفر لتتبع المهام.";
      isLoadingTasks.value = false;
      isLoadingMap.value = false;
      return;
    }
    _initializeAndLoadData();
  }
  Future<void> _initializeAndLoadData() async {
    // بما أن companyId الآن يتم تمريرها عبر المُنشئ (من الـ Binding)
    // يمكننا التحقق منها مباشرة.
    if (companyId.isEmpty) {
      debugPrint("[ACTIVE_TASKS_CTRL] Error: Company ID received via constructor is empty.");
      errorMessage.value = "خطأ: لم يتم توفير معرّف شركة صالح للمتابعة.";
      isLoadingTasks.value = false;
      isLoadingMap.value = false;
      companyIdWasSuccessfullyIdentified.value = false; // تأكيد أنه غير متاح
      update(); // لتحديث الواجهة فورًا
      return;
    }

    // إذا وصلنا إلى هنا، فإن companyId متاح وصالح
    companyIdWasSuccessfullyIdentified.value = true;
    debugPrint("[ACTIVE_TASKS_CTRL] Company ID '$companyId' is available. Subscribing to tasks.");
    update(); // لتحديث الواجهة إذا كان companyId متاحًا

    subscribeToActiveTasks(); // ابدأ في جلب البيانات
  }

  void subscribeToActiveTasks() {
    isLoadingTasks.value = true;
    debugPrint("[ACTIVE_TASKS_CTRL] Subscribing to active tasks for company: $companyId");
    if (!companyIdWasSuccessfullyIdentified.value) { // تحقق إضافي
      debugPrint("[ACTIVE_TASKS_CTRL] Cannot subscribe to tasks, companyId not identified.");
      isLoadingTasks.value = false; // تأكد من إيقاف التحميل
      return;
    }
    // حالات المهام النشطة (قد تحتاج لتعديلها حسب حالاتك)
    final List<String> activeStatuses = [
      deliveryTaskStatusToString(DeliveryTaskStatus.driver_assigned),
      deliveryTaskStatusToString(DeliveryTaskStatus.en_route_to_pickup),
      deliveryTaskStatusToString(DeliveryTaskStatus.picked_up_from_seller),
      deliveryTaskStatusToString(DeliveryTaskStatus.out_for_delivery_to_buyer),
      deliveryTaskStatusToString(DeliveryTaskStatus.at_buyer_location),
    ];

    _activeTasksSubscription = _firestore
        .collection(FirebaseX.deliveryTasksCollection)
        .where('assignedCompanyId', isEqualTo: companyId)
        .where('status', whereIn: activeStatuses) // جلب المهام بالحالات النشطة فقط
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) async {
      debugPrint("[ACTIVE_TASKS_CTRL] Received ${snapshot.docs.length} active tasks updates.");
      List<DeliveryTaskModel> newTasks = [];
      List<String> currentDriverIdsInView = []; // لتتبع السائقين الذين لديهم مهام نشطة

      for (var doc in snapshot.docs) {
        final task = DeliveryTaskModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
        newTasks.add(task);
        if (task.assignedToDriverId != null && !currentDriverIdsInView.contains(task.assignedToDriverId)) {
          currentDriverIdsInView.add(task.assignedToDriverId!);
          if (!taskDrivers.containsKey(task.assignedToDriverId)) { // إذا لم نكن قد جلبنا بيانات هذا السائق من قبل
            _fetchAndCacheDriverDetails(task.assignedToDriverId!);
          }
          // --- بدء أو التأكد من وجود اشتراك في موقع هذا السائق ---
          _subscribeToDriverLocation(task.assignedToDriverId!);
        }
      }
      activeTasks.assignAll(newTasks);
      _updateMapMarkersAndPolylines(); // تحديث الماركرات والمسارات بعد كل تحديث للمهام
      isLoadingTasks.value = false; // تم تحميل الدفعة الأولى
    }, onError: (error, stackTrace) {
      debugPrint("[ACTIVE_TASKS_CTRL] Error listening to active tasks: $error\n$stackTrace");
      errorMessage.value = "خطأ في تحديث المهام النشطة: $error";
      isLoadingTasks.value = false;
    });
  }

  Future<void> _fetchAndCacheDriverDetails(String driverId) async {
    if (taskDrivers.containsKey(driverId)) return; // تم جلبه مسبقًا
    try {
      debugPrint("[ACTIVE_TASKS_CTRL] Fetching details for driver: $driverId");
      DocumentSnapshot driverDoc = await _firestore.collection(FirebaseX.deliveryDriversCollection).doc(driverId).get();
      if (driverDoc.exists) {
        taskDrivers[driverId] = DeliveryDriverModel.fromMap(driverDoc.data() as Map<String, dynamic>, driverDoc.id);
        debugPrint("[ACTIVE_TASKS_CTRL] Cached driver: ${taskDrivers[driverId]!.name}");
        _updateMapMarkersAndPolylines(); // أعد بناء الماركرات إذا تغير موقع السائق
      }
    } catch (e) {
      debugPrint("[ACTIVE_TASKS_CTRL] Error fetching driver $driverId for caching: $e");
    }
  }

  void _subscribeToDriverLocation(String driverId) {
    // ألغِ الاشتراك القديم إذا كان موجودًا لهذا السائق لمنع التكرار
    _driverLocationSubscriptions[driverId]?.cancel();
    _driverLocationSubscriptions[driverId] = _firestore
        .collection(FirebaseX.deliveryDriversCollection)
        .doc(driverId)
        .snapshots() // استمع لتحديثات مستند السائق (التي يجب أن تشمل currentLocation)
        .listen((driverDoc) {
      if (driverDoc.exists && driverDoc.data() != null) {
        final updatedDriver = DeliveryDriverModel.fromMap(driverDoc.data()!, driverDoc.id);
        // تحديث السائق في القائمة المؤقتة لدينا
        taskDrivers[driverId] = updatedDriver;
        debugPrint("[DRIVER_LOC_SUB] Driver $driverId location updated: ${updatedDriver.currentLocation?.latitude}, ${updatedDriver.currentLocation?.longitude}");
        // أعد بناء الماركرات والمسارات
        _updateMapMarkersAndPolylines();
      }
    }, onError: (error) {
      debugPrint("[DRIVER_LOC_SUB] Error listening to driver $driverId location: $error");
    });
  }


  void _updateMapMarkersAndPolylines() {
    Set<Marker> newMarkers = {};
    Set<Polyline> newPolylines = {};

    for (var task in activeTasks) {
      DeliveryDriverModel? driver = task.assignedToDriverId != null ? taskDrivers[task.assignedToDriverId!] : null;

      // ماركر الاستلام (البائع)
      if (task.pickupLocationGeoPoint != null) {
        newMarkers.add(Marker(
            markerId: MarkerId('pickup_${task.taskId}'),
            position: LatLng(task.pickupLocationGeoPoint!.latitude, task.pickupLocationGeoPoint!.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
            infoWindow: InfoWindow(title: "استلام: ${task.sellerName ?? 'البائع'}", snippet: task.orderId)));
      }
      // ماركر التسليم (المشتري)
      if (task.deliveryLocationGeoPoint != null) {
        newMarkers.add(Marker(
            markerId: MarkerId('delivery_${task.taskId}'),
            position: LatLng(task.deliveryLocationGeoPoint!.latitude, task.deliveryLocationGeoPoint!.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(title: "تسليم: ${task.buyerName ?? 'المشتري'}", snippet: task.orderId)));
      }
      // ماركر السائق (إذا كان معينًا وله موقع)
      if (driver != null && driver.currentLocation != null) {
        newMarkers.add(Marker(
            markerId: MarkerId('driver_${driver.uid}_${task.taskId}'), // ID فريد للماركر
            position: LatLng(driver.currentLocation!.latitude, driver.currentLocation!.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            infoWindow: InfoWindow(title: driver.name, snippet: "يقوم بتوصيل الطلب: ${task.orderId.substring(0,6)}..."),
            zIndex: 2 // لجعله فوق ماركرات المهمة إذا تداخلوا
        ));

        // رسم مسار مبسط من السائق إلى وجهته التالية
        LatLng driverLatLng = LatLng(driver.currentLocation!.latitude, driver.currentLocation!.longitude);
        LatLng? nextDestinationLatLng;
        String polylineIdSuffix = "";

        // تحديد الوجهة التالية للمسار
        if (task.status == DeliveryTaskStatus.en_route_to_pickup || task.status == DeliveryTaskStatus.driver_assigned /* وهو متجه للبائع */ ) {
          if (task.pickupLocationGeoPoint != null) {
            nextDestinationLatLng = LatLng(task.pickupLocationGeoPoint!.latitude, task.pickupLocationGeoPoint!.longitude);
            polylineIdSuffix = "_to_pickup";
          }
        } else if (task.status == DeliveryTaskStatus.out_for_delivery_to_buyer ||
            task.status == DeliveryTaskStatus.picked_up_from_seller ||
            task.status == DeliveryTaskStatus.at_buyer_location) {
          if (task.deliveryLocationGeoPoint != null) {
            nextDestinationLatLng = LatLng(task.deliveryLocationGeoPoint!.latitude, task.deliveryLocationGeoPoint!.longitude);
            polylineIdSuffix = "_to_delivery";
          }
        }

        if(nextDestinationLatLng != null){
          newPolylines.add(Polyline(
            polylineId: PolylineId('route_${task.taskId}$polylineIdSuffix'),
            points: [driverLatLng, nextDestinationLatLng],
            color: Colors.blueAccent.withOpacity(0.8),
            width: 4,
          ));
        }
      }
    }
    taskMarkers.assignAll(newMarkers);
    taskPolylines.assignAll(newPolylines);
    debugPrint("[ACTIVE_TASKS_CTRL] Map updated. Markers: ${taskMarkers.length}, Polylines: ${taskPolylines.length}");
    // لا تقم بـ fitMapToMarkers هنا مباشرة في كل تحديث، قد يكون مزعجًا للمشرف
    // يمكن إضافة زر "توسيط جميع المهام"
  }


  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    isLoadingMap.value = false; // الخريطة جاهزة
    // يمكنك هنا عمل fit to bounds أولي إذا أردت
    // Future.delayed(const Duration(milliseconds: 500), () => _fitMapToAllMarkersIfAny());
  }

  void zoomToTask(DeliveryTaskModel task) {
    List<LatLng> pointsToInclude = [];
    if(task.pickupLocationGeoPoint != null) pointsToInclude.add(LatLng(task.pickupLocationGeoPoint!.latitude, task.pickupLocationGeoPoint!.longitude));
    if(task.deliveryLocationGeoPoint != null) pointsToInclude.add(LatLng(task.deliveryLocationGeoPoint!.latitude, task.deliveryLocationGeoPoint!.longitude));

    DeliveryDriverModel? driverOfTask = task.assignedToDriverId != null ? taskDrivers[task.assignedToDriverId!] : null;
    if(driverOfTask?.currentLocation != null) pointsToInclude.add(LatLng(driverOfTask!.currentLocation!.latitude, driverOfTask.currentLocation!.longitude));

    if (pointsToInclude.isEmpty || mapController == null) return;

    if (pointsToInclude.length == 1) {
      mapController!.animateCamera(CameraUpdate.newLatLngZoom(pointsToInclude.first, 15.0));
    } else {
      try {
        LatLngBounds bounds = _boundsFromLatLngList(pointsToInclude);
        mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80.0)); // 80 padding
      } catch (e) {
        debugPrint("Error zooming to task bounds: $e");
        mapController!.animateCamera(CameraUpdate.newLatLngZoom(pointsToInclude.first, 15.0));
      }
    }
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> points) {
    if (points.isEmpty) return LatLngBounds(southwest: LatLng(0,0), northeast: LatLng(0,0));
    double? x0, x1, y0, y1;
    for (LatLng point in points) {
      final lat = point.latitude; final lng = point.longitude;
      if (x0 == null) { x0 = x1 = lat; y0 = y1 = lng; }
      else {
        if (lat > x1!) x1 = lat; if (lat < x0) x0 = lat;
        if (lng > y1!) y1 = lng; if (lng < y0!) y0 = lng;
      }
    }
    return LatLngBounds(southwest: LatLng(x0!, y0!), northeast: LatLng(x1!, y1!));
  }

  void openTaskDetails(String taskIdForDetails) {
    Get.toNamed('/admin/task-details/$taskIdForDetails'); // أو أي مسار آخر لصفحة تفاصيل المهمة
    debugPrint("Navigate to details for task: $taskIdForDetails");
  }

  @override
  void onClose() {
    _activeTasksSubscription?.cancel();
    _driverLocationSubscriptions.forEach((key, subscription) {
      subscription?.cancel();
    });
    _driverLocationSubscriptions.clear();
    mapController?.dispose();
    debugPrint("[ACTIVE_TASKS_CTRL] Controller closed and subscriptions cancelled.");
    super.onClose();
  }
}





class CompanyActiveTasksTrackingScreen extends GetView<CompanyActiveTasksTrackingController> {
  const CompanyActiveTasksTrackingScreen({super.key});
  // يفترض أن companyId تم تمريره للمتحكم عبر Binding

  // دالة مساعدة لعرض بطاقة مهمة بشكل جميل
  Widget _buildTaskCard(DeliveryTaskModel task, BuildContext context) {
    final driverForThisTask = task.assignedToDriverId != null && controller.taskDrivers.containsKey(task.assignedToDriverId!)
        ? controller.taskDrivers[task.assignedToDriverId!]
        : null; // <--- تعديل هنا للتحقق من وجود المفتاح قبل الوصول إليه
    final theme = Theme.of(context);

    // --- استخدام الدالة المركزية getTaskStatusVisuals ---
    final statusVisuals = getTaskStatusVisuals(task.status, context);
    // --------------------------------------------------

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () => controller.openTaskDetails(task.taskId),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded( // لجعل النص يلتف إذا كان طويلاً
                    child: Text(
                        "طلب رقم: ${task.orderId.length > 8 ? '${task.orderId.substring(0,8)}...' : task.orderId}",
                        style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
                    ),
                  ),
                  // استخدام الـ Chip المبني من getTaskStatusVisuals
                  Chip(
                    avatar: Icon(statusVisuals['icon'], color: statusVisuals['textColor'], size: 15),
                    label: Text(statusVisuals['text'], style: TextStyle(color: statusVisuals['textColor'], fontSize: 10.5, fontWeight: FontWeight.w500)),
                    backgroundColor: statusVisuals['color'],
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
              const Divider(height: 15, thickness: 0.5),
              if (driverForThisTask != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(children: [
                    Icon(Icons.person_pin_circle_outlined, size: 18, color: theme.primaryColor),
                    const SizedBox(width:6),
                    Text("السائق: ${driverForThisTask.name}", style: Get.textTheme.bodyMedium)
                  ]),
                ),
              Row(children: [
                Icon(Icons.storefront_outlined, size: 18, color: Colors.blueGrey),
                const SizedBox(width:6),
                Text("البائع: ${task.sellerName ?? 'غير محدد'}", style: Get.textTheme.bodyMedium)
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.person_outline_rounded, size: 18, color: Colors.blueGrey),
                const SizedBox(width:6),
                Text("المشتري: ${task.buyerName ?? 'غير محدد'}", style: Get.textTheme.bodyMedium)
              ]),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // لتوزيع العناصر
                children: [
                  Text("أنشئت: ${DateFormat('hh:mm a', 'ar').format(task.createdAt.toDate())}",
                      style: Get.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700)),
                  TextButton( // استخدام TextButton لمظهر أنظف
                    onPressed: () => controller.zoomToTask(task),
                    child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("على الخريطة"),
                          SizedBox(width:4),
                          Icon(Icons.map_outlined, size:18),
                        ]
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    // Get.put(CompanyActiveTasksTrackingController(companyId: "YOUR_COMPANY_ID_HERE")); //  عبر Binding

    if (!controller.companyIdWasSuccessfullyIdentified.value && !controller.isLoadingTasks.value) {
      return Scaffold(
          appBar: AppBar(title: const Text("تتبع المهام النشطة")),
          body: Center(
              child: Text(
                controller.errorMessage.value.isNotEmpty
                    ? controller.errorMessage.value
                    : "خطأ: معرّف الشركة غير متوفر أو غير صالح.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              )
          )
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("تتبع المهام النشطة للشركة"),
        // يمكنك إضافة فلاتر هنا إذا أردت
      ),
      body: Column(
        children: [
          // --- الخريطة ---
          Obx(() => SizedBox(
            height: Get.height * 0.45, // ارتفاع الخريطة
            child: controller.isLoadingMap.value // مؤشر تحميل للخريطة نفسها
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : GoogleMap(
              onMapCreated: controller.onMapCreated,
              initialCameraPosition: const CameraPosition(
                target: LatLng(33.3152, 44.3661), // موقع افتراضي
                zoom: 6.0, // زوم أبعد في البداية
              ),
              markers: controller.taskMarkers.value,
              polylines: controller.taskPolylines.value,
              myLocationButtonEnabled: false, // يمكن إضافته لاحقًا لتحديد موقع المشرف
              zoomControlsEnabled: true,
              mapToolbarEnabled: true, // لعرض أزرار فتح خرائط جوجل
            ),
          )),

          // --- قائمة المهام ---
          Expanded(
            child: Obx(() {
              if (controller.isLoadingTasks.value && controller.activeTasks.isEmpty) { // التحميل الأولي للقائمة
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.errorMessage.value.isNotEmpty && controller.activeTasks.isEmpty) {
                return Center(child: Text(controller.errorMessage.value, style: TextStyle(color: Colors.red)));
              }
              if (controller.activeTasks.isEmpty) {
                return const Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline_rounded, size: 60, color: Colors.green),
                          SizedBox(height: 10),
                          Text("لا توجد مهام نشطة حاليًا لشركتك.", style: TextStyle(fontSize: 16, color: Colors.grey)),
                        ]));
              }
              return ListView.builder(
                itemCount: controller.activeTasks.length,
                itemBuilder: (context, index) {
                  final task = controller.activeTasks[index];
                  return _buildTaskCard(task, context);
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}