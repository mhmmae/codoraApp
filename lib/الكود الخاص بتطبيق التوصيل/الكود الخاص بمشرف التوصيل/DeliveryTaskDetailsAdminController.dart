import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:codora/Model/model_user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; // For Colors and Icons
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../XXX/xxx_firebase.dart';
import '../../routes/app_routes.dart';
import '../الكود الخاص بعامل/DeliveryDriverModel.dart';
import 'CompanyActiveTasksTrackingController.dart';
import 'CompanyAdminDashboardController.dart';
import '../../Model/DeliveryTaskModel.dart';
import '../../Model/SellerModel.dart'; // لرسم المسارات

class DeliveryTaskDetailsAdminController extends GetxController {
  final String taskId;
  DeliveryTaskDetailsAdminController({required this.taskId});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Rxn<DeliveryTaskModel> task = Rxn<DeliveryTaskModel>(null);
  final Rxn<DeliveryDriverModel> driver = Rxn<DeliveryDriverModel>(null);
  final Rxn<SellerModel> seller = Rxn<SellerModel>(null); // اسم كلاس البائع قد يكون مختلفًا
  final Rxn<UserModel> buyer = Rxn<UserModel>(null);   // اسم كلاس المشتري قد يكون مختلفًا

  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  GoogleMapController? mapController;
  final RxSet<Marker> markers = <Marker>{}.obs;
  final RxSet<Polyline> polylines = <Polyline>{}.obs;

  @override
  void onInit() {
    super.onInit();
    if (taskId.isEmpty) {
      errorMessage.value = "خطأ: معرف المهمة مفقود.";
      isLoading.value = false;
      return;
    }
    fetchTaskDetails();
  }

  Future<void> fetchTaskDetails() async {
    isLoading.value = true;
    errorMessage.value = '';
    debugPrint("[TASK_DETAILS_ADMIN] Fetching task: $taskId");
    try {
      DocumentSnapshot<Map<String, dynamic>> taskDoc = await _firestore
          .collection(FirebaseX.deliveryTasksCollection)
          .doc(taskId)
          .get(); // Cast هنا مباشرة

      if (!taskDoc.exists || taskDoc.data() == null) {
        throw Exception("المهمة بالمعرف $taskId غير موجودة أو لا تحتوي على بيانات.");
      }
      task.value = DeliveryTaskModel.fromFirestore(taskDoc);
      debugPrint("[TASK_DETAILS_ADMIN] Task data fetched. Status: ${task.value?.status}");

      // --- جلب البيانات المرتبطة باستخدام Future.wait ---
      List<Future> futures = [];
      if (task.value?.assignedToDriverId != null && task.value!.assignedToDriverId!.isNotEmpty) {
        futures.add(_fetchDriverDetails(task.value!.assignedToDriverId!));
      }
      if (task.value?.sellerId != null && task.value!.sellerId.isNotEmpty) {
        futures.add(_fetchSellerDetails(task.value!.sellerId)); // اسم الكولكشن للبائعين
      }
      if (task.value?.buyerId != null && task.value!.buyerId.isNotEmpty) {
        futures.add(_fetchBuyerDetails(task.value!.buyerId)); // اسم الكولكشن للمستخدمين/المشترين
      }
      if (futures.isNotEmpty) {
        await Future.wait(futures);
      }
      // --------------------------------------------
      _setupMapMarkersAndRoute();

    } catch (e, s) {
      debugPrint("[TASK_DETAILS_ADMIN] Error fetching task details: $e\n$s");
      errorMessage.value = "خطأ في جلب تفاصيل المهمة: ${e.toString()}";
      task.value = null; driver.value = null; seller.value = null; buyer.value = null; // مسح البيانات عند الخطأ
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchDriverDetails(String driverId) async {
    try {
      DocumentSnapshot driverDoc = await _firestore.collection(FirebaseX.deliveryDriversCollection).doc(driverId).get();
      if (driverDoc.exists && driverDoc.data() != null) {
        driver.value = DeliveryDriverModel.fromMap(driverDoc.data() as Map<String,dynamic>, driverDoc.id);
        debugPrint("[TASK_DETAILS_ADMIN] Fetched driver: ${driver.value?.name}");
      } else {
        debugPrint("[TASK_DETAILS_ADMIN] Driver with ID $driverId not found.");
      }
    } catch (e) { debugPrint("[TASK_DETAILS_ADMIN] Error fetching driver $driverId: $e"); }
  }

  Future<void> _fetchSellerDetails(String sellerId) async {
    try {
      DocumentSnapshot sellerDoc = await _firestore.collection(FirebaseX.collectionSeller).doc(sellerId).get(); // استخدم collectionSeller
      if (sellerDoc.exists && sellerDoc.data() != null) {
        seller.value = SellerModel.fromMap(sellerDoc.data() as Map<String,dynamic>, sellerDoc.id);
        debugPrint("[TASK_DETAILS_ADMIN] Fetched seller: ${seller.value?.shopName}");
      } else {
        debugPrint("[TASK_DETAILS_ADMIN] Seller with ID $sellerId not found.");
      }
    } catch (e) { debugPrint("[TASK_DETAILS_ADMIN] Error fetching seller $sellerId: $e"); }
  }

  Future<void> _fetchBuyerDetails(String buyerId) async {
    try {
      DocumentSnapshot buyerDoc = await _firestore.collection(FirebaseX.usersCollection).doc(buyerId).get(); // استخدم usersCollection
      if (buyerDoc.exists && buyerDoc.data() != null) {
        buyer.value = UserModel.fromMap(buyerDoc.data() as Map<String,dynamic>, buyerDoc.id);
        debugPrint("[TASK_DETAILS_ADMIN] Fetched buyer: ${buyer.value?.name}");
      } else {
        debugPrint("[TASK_DETAILS_ADMIN] Buyer with ID $buyerId not found.");
      }
    } catch (e) { debugPrint("[TASK_DETAILS_ADMIN] Error fetching buyer $buyerId: $e");}
  }


  void _setupMapMarkersAndRoute() {
    // ... (نفس دالة _setupMapMarkersAndRoute من الرد السابق، مع التأكد من استخدام task.value، driver.value، إلخ) ...
    // والتأكد من استخدام pickupLocationGeoPoint و deliveryLocationGeoPoint
    if (task.value == null) return;
    Set<Marker> newMarkers = {};
    List<LatLng> polylineCoordinates = [];

    final currentTaskStatus = task.value!.status; // لتسهيل الوصول

    // ماركر الاستلام (البائع)
    final sellerGeoPoint = task.value!.pickupLocationGeoPoint;
    if (sellerGeoPoint != null) {
      final pickupLatLng = LatLng(sellerGeoPoint.latitude, sellerGeoPoint.longitude);
      newMarkers.add(Marker(
          markerId: MarkerId('pickup_${task.value!.taskId}'),
          position: pickupLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
          infoWindow: InfoWindow(title: "نقطة الاستلام", snippet: seller.value?.shopName ?? task.value!.sellerName ?? 'البائع')
      ));
      // أضف نقطة الاستلام أولاً للمسار
      if(currentTaskStatus == DeliveryTaskStatus.en_route_to_pickup ||
          currentTaskStatus == DeliveryTaskStatus.driver_assigned) { // إذا كان السائق سيتجه للاستلام
        polylineCoordinates.add(pickupLatLng); // ستكون هي الوجهة
      } else if (polylineCoordinates.isEmpty && currentTaskStatus != DeliveryTaskStatus.delivered){ // كنقطة بداية إذا لم يتم الاستلام بعد
        polylineCoordinates.add(pickupLatLng);
      }
    }

    // ماركر السائق الحالي
    final driverModel = driver.value; // قد يكون null إذا لم يتم تعيين سائق بعد
    if (driverModel != null && driverModel.currentLocation != null) {
      final driverLatLng = LatLng(driverModel.currentLocation!.latitude, driverModel.currentLocation!.longitude);
      newMarkers.add(Marker(
          markerId: MarkerId('driver_${driverModel.uid}'),
          position: driverLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(title: "السائق: ${driverModel.name}", snippet: "الحالة: ${driverModel.availabilityStatus.replaceAll('_',' ')}"),
          zIndex: 1 // ليكون فوق خط المسار إذا تداخل
      ));
      // أضف موقع السائق الحالي إلى المسار
      polylineCoordinates.add(driverLatLng);
    }

    // ماركر التسليم (المشتري)
    final buyerGeoPoint = task.value!.deliveryLocationGeoPoint;
    if (buyerGeoPoint != null) {
      final deliveryLatLng = LatLng(buyerGeoPoint.latitude, buyerGeoPoint.longitude);
      newMarkers.add(Marker(
          markerId: MarkerId('delivery_${task.value!.taskId}'),
          position: deliveryLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(title: "نقطة التسليم", snippet: buyer.value?.name ?? task.value!.buyerName ?? 'المشتري')
      ));
      // أضف نقطة التسليم في نهاية المسار
      polylineCoordinates.add(deliveryLatLng);
    }

    markers.assignAll(newMarkers);
    polylines.clear();

    if (polylineCoordinates.length >= 2) {
      // فرز مبسط: (بائع) -> (سائق إذا كان بعد الاستلام) -> (مشتري)
      // هذا يتطلب ترتيب النقاط في polylineCoordinates بشكل صحيح
      List<LatLng> sortedRoutePoints = [];
      if(sellerGeoPoint != null) sortedRoutePoints.add(LatLng(sellerGeoPoint.latitude, sellerGeoPoint.longitude));

      if (driverModel != null && driverModel.currentLocation != null &&
          (currentTaskStatus == DeliveryTaskStatus.picked_up_from_seller ||
              currentTaskStatus == DeliveryTaskStatus.out_for_delivery_to_buyer ||
              currentTaskStatus == DeliveryTaskStatus.at_buyer_location) ) {
        sortedRoutePoints.add(LatLng(driverModel.currentLocation!.latitude, driverModel.currentLocation!.longitude));
      }
      if(buyerGeoPoint != null) sortedRoutePoints.add(LatLng(buyerGeoPoint.latitude, buyerGeoPoint.longitude));

      // إزالة النقاط المكررة (إذا كان السائق في نفس موقع البائع أو المشتري)
      List<LatLng> uniqueRoutePoints = [];
      if (sortedRoutePoints.isNotEmpty) {
        uniqueRoutePoints.add(sortedRoutePoints.first);
        for (int i = 1; i < sortedRoutePoints.length; i++) {
          if (sortedRoutePoints[i].latitude != sortedRoutePoints[i-1].latitude ||
              sortedRoutePoints[i].longitude != sortedRoutePoints[i-1].longitude) {
            uniqueRoutePoints.add(sortedRoutePoints[i]);
          }
        }
      }


      if (uniqueRoutePoints.length >= 2) {
        polylines.assignAll({
          Polyline(
            polylineId: PolylineId('route_${task.value!.taskId}'),
            points: uniqueRoutePoints,
            color: Colors.lightBlueAccent.shade400,
            width: 5,
            patterns: [PatternItem.dot, PatternItem.gap(12)],
          )
        });
      }
    }
    debugPrint("[TASK_DETAILS_ADMIN] Map updated. Markers: ${markers.length}, Polylines: ${polylines.length}");
    _fitMapToMarkersIfReady();
  }


  // ... (onMapCreated, _fitMapToMarkersIfReady, _boundsFromMarkersList كما هي من قبل) ...

  // --- دوال الإجراءات ---
  Future<void> reassignTaskToNewDriver() async {
    if (task.value == null) return;
    debugPrint("[TASK_DETAILS_ADMIN] Initiating reassignment for task: ${task.value!.taskId}");
    // انتقل إلى شاشة تعيين/إعادة تعيين المهمة، مرر companyId الخاص بهذه المهمة
    final String? taskCompanyId = task.value!.assignedCompanyId;
    if(taskCompanyId == null || taskCompanyId.isEmpty) {
      Get.snackbar("خطأ", "لم يتم تحديد شركة لهذه المهمة. لا يمكن إعادة التعيين.", backgroundColor: Colors.red);
      return;
    }

    Get.toNamed(
        AppRoutes.ADMIN_ASSIGN_TASK.replaceFirst(':taskId', task.value!.taskId),
        arguments: {
          'orderId': task.value!.orderId,
          'isReassignment': true,
          'companyId': taskCompanyId // مرر companyId الخاص بالمهمة
        }
    )?.then((result){
      // إذا عادت شاشة إعادة التعيين بنتيجة، قم بتحديث التفاصيل
      if(result == true || (result is Map && result['assigned'] == true)){
        fetchTaskDetails();
        // أبلغ لوحة التحكم لتحديث قوائمها
        if(Get.isRegistered<CompanyAdminDashboardController>()) Get.find<CompanyAdminDashboardController>().fetchAllDashboardData();
      }
    });
  }
final FirebaseAuth _auth = FirebaseAuth.instance;
  Future<void> cancelTaskByAdmin(BuildContext context) async { // Context لعرض حوار السبب
    if (task.value == null) return;
    final reasonController = TextEditingController();
    bool? confirmed = await Get.defaultDialog<bool>(
      title: "تأكيد إلغاء المهمة",
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        // استخدام orderId من task.value بدلاً من محاولة الوصول لـ task.value.orderId مباشرة في السلسلة
        // لأن task.value يمكن أن يكون null إذا فشل الجلب الأولي.
        // لكننا تحققنا منه في السطر الأول من الدالة.
        Text("هل أنت متأكد من إلغاء المهمة للطلب رقم: #${task.value!.orderId.length > 6 ? '${task.value!.orderId.substring(0,6)}...' : task.value!.orderId}?"),
        SizedBox(height:10),
        TextField(controller: reasonController, decoration: InputDecoration(labelText:"سبب الإلغاء (اختياري)", border:OutlineInputBorder()))
      ]),
      textConfirm: "نعم، إلغاء المهمة",
      textCancel: "تراجع",
      confirmTextColor: Colors.white,
      onConfirm: () => Get.back(result: true),
      onCancel: () => Get.back(result: false),
      buttonColor: Colors.red.shade400, // يمكنك جعله من theme.colorScheme.error
    );

    if (confirmed == true) {
      isLoading.value = true;
      try {
        // --- التعديل هنا ---
        final newStatus = DeliveryTaskStatus.cancelled_by_company_admin; // <--- افترض أن هذا هو مشرف الشركة
        // أو إذا كان مشرف المنصة هو من يقوم بالإلغاء:
        // final newStatus = DeliveryTaskStatus.cancelled_by_platform_admin;
        // -------------------

        // معرفة من قام بالإلغاء (المشرف الحالي)
        String cancellerEntityType = "company_admin"; // أو "platform_admin"
        String cancellerEntityId = _auth.currentUser?.uid ?? "unknown_admin"; // UID للمشرف الحالي


        await _firestore.collection(FirebaseX.deliveryTasksCollection).doc(taskId).update({
          'status': deliveryTaskStatusToString(newStatus), // <--- استخدام الحالة الصحيحة
          'updatedAt': FieldValue.serverTimestamp(),
          'failureOrCancellationReason': reasonController.text.trim().isNotEmpty ? reasonController.text.trim() : 'تم الإلغاء بواسطة المشرف',
          'cancelledByEntityType': cancellerEntityType, //  <--- تسجيل من قام بالإلغاء
          'cancelledByEntityId': cancellerEntityId,   //  <--- معرف من قام بالإلغاء
          // (اختياري) يمكنك أيضًا مسح معلومات السائق إذا كان معينًا
          // 'assignedToDriverId': FieldValue.delete(),
          // 'driverName': FieldValue.delete(),
          'taskNotesInternal': FieldValue.arrayUnion(["${DateFormat('yy/MM/dd hh:mm','ar').format(DateTime.now())}: تم إلغاء المهمة بواسطة $cancellerEntityType ($cancellerEntityId). السبب: ${reasonController.text.trim().isNotEmpty ? reasonController.text.trim() : 'غير محدد'}"])
        });

        // تحديث الحالة محليًا في المتحكم
        DocumentSnapshot<Map<String, dynamic>> updatedTaskDoc = await _firestore
            .collection(FirebaseX.deliveryTasksCollection)
            .doc(taskId)
            .get();
        if(updatedTaskDoc.exists && updatedTaskDoc.data() != null) {
          task.value = DeliveryTaskModel.fromFirestore(updatedTaskDoc);
        } else {
          task.value = null; // أو التعامل مع حالة الحذف إذا كان هذا ممكنًا
        }


        Get.snackbar("تم الإلغاء", "تم إلغاء المهمة بنجاح.", backgroundColor: Colors.orange.shade700, colorText: Colors.white);

        // إرسال إشعارات للسائق (إذا كان معينًا)، البائع، والمشتري لإبلاغهم بالإلغاء
        // _sendCancellationNotifications(task.value, reasonController.text.trim());

        // تحديث لوحة التحكم والقوائم الأخرى
        if(Get.isRegistered<CompanyAdminDashboardController>()) Get.find<CompanyAdminDashboardController>().fetchAllDashboardData();
        if(Get.isRegistered<CompanyActiveTasksTrackingController>()) {
          // إذا كانت هذه المهمة في قائمة المهام النشطة، يجب أن تختفي منها
          Get.find<CompanyActiveTasksTrackingController>().subscribeToActiveTasks(); // إعادة بناء الاشتراك
        }


      } catch(e,s) {
        debugPrint("Error cancelling task $taskId by admin: $e\n$s");
        Get.snackbar("خطأ", "فشل إلغاء المهمة: ${e.toString()}", backgroundColor: Colors.red.shade400);
      } finally {
        isLoading.value = false;
      }
    }
  }


  LatLngBounds _boundsFromMarkersList(List<Marker> markersList) { // دالة Bounds من رد سابق
    if (markersList.isEmpty) return LatLngBounds(southwest: LatLng(0,0), northeast: LatLng(0,0));
    double? x0, x1, y0, y1;
    for (Marker marker in markersList) {
      final lat = marker.position.latitude;
      final lng = marker.position.longitude;
      if (x0 == null) { x0 = x1 = lat; y0 = y1 = lng; }
      else {
        if (lat > x1!) x1 = lat; if (lat < x0) x0 = lat;
        if (lng > y1!) y1 = lng; if (lng < y0!) y0 = lng;
      }
    }
    return LatLngBounds(southwest: LatLng(x0!, y0!), northeast: LatLng(x1!, y1!));
  }

  void _fitMapToMarkersIfReady() {
    if (mapController != null && markers.isNotEmpty) {
      if (markers.length == 1) {
        mapController!.animateCamera(CameraUpdate.newLatLngZoom(markers.first.position, 14.5));
      } else {
        try {
          LatLngBounds bounds = _boundsFromMarkersList(markers.toList());
          mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 70.0)); // 70 padding
        } catch (e) {
          debugPrint("[TASK_DETAILS_ADMIN] Error fitting map to bounds: $e");
          if (markers.isNotEmpty) mapController!.animateCamera(CameraUpdate.newLatLngZoom(markers.first.position, 14.5));
        }
      }
    }
  }


  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _fitMapToMarkersIfReady();
  }




  Future<void> contactEntity(String? phoneNumber, String entityName) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      Get.snackbar("لا يوجد رقم", "لا يوجد رقم هاتف مسجل لـ $entityName.", snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        Get.snackbar("خطأ", "لا يمكن إجراء الاتصال بالرقم: $phoneNumber", snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar("خطأ", "فشل فتح تطبيق الاتصال: $e", snackPosition: SnackPosition.BOTTOM);
    }
  }

  void contactSeller() => contactEntity(seller.value?.shopPhoneNumber, seller.value?.shopName ?? "البائع");
  void contactBuyer() => contactEntity(buyer.value?.phoneNumber, buyer.value?.name ?? "المشتري");
  void contactDriver() => contactEntity(driver.value?.phoneNumber, driver.value?.name ?? "السائق");

  @override
  void onClose() {
    mapController?.dispose();
    debugPrint("[TASK_DETAILS_ADMIN] Controller closed for task $taskId.");
    super.onClose();
  }
}
