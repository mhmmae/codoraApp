import 'dart:async';
import 'dart:io'; // For File
import 'dart:math'; // For min/max

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; // For BuildContext for dialogs
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart'; // For DateFormat
import 'package:geolocator/geolocator.dart'; // For distance calculation, or direct position stream
import 'package:image_picker/image_picker.dart'; // For proof image
import 'package:firebase_storage/firebase_storage.dart'; // For uploading images
import 'package:url_launcher/url_launcher.dart';

import '../../XXX/xxx_firebase.dart';
import '../../routes/app_routes.dart';
import '../../Model/DeliveryCompanyModel.dart';
import '../../Model/DeliveryTaskModel.dart';
import 'DeliveryDriverModel.dart';
import 'DriverDashboardController.dart'; // To launch external map apps



class DeliveryNavigationController extends GetxController {
  final String taskId; // يتم تمريرها عند إنشاء المتحكم (من الـ Binding)
  DeliveryNavigationController({required this.taskId});

  // --- خدمات و Firebase ---
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance; // لرفع الصور
  String? get driverId => _auth.currentUser?.uid;

  // --- بيانات المهمة الحالية ---
  final Rxn<DeliveryTaskModel> taskDetails = Rxn<DeliveryTaskModel>(null);
  final RxBool isLoadingTaskData = true.obs; // لتحميل بيانات المهمة الأولية
  final RxString taskErrorMessage = ''.obs;

  // --- بيانات السائق ---
  // لا نحتاج لـ Rxn<DeliveryDriverModel> driverProfile بالكامل هنا إذا كان
  // DriverLocationService تُحدّث موقع السائق في Firestore، وسنستمع لتلك التحديثات.
  // ولكن، قد نحتاج لاسم السائق وهاتفه من ملفه الشخصي.
  final RxnString driverNameFromProfile = RxnString(null);
  final RxnString driverPhoneFromProfile = RxnString(null);
  final Rxn<DeliveryDriverModel> driverProfile = Rxn<DeliveryDriverModel>(null);
  late final String instanceId; //  لتخزين معرّف فريد لهذا المثيل من المتحكم
  final RxSet<Polyline> polylines = <Polyline>{}.obs; // <--- قم بإضافة هذا السطر
  RxnString selectedIssueTypeKey = RxnString(null); // لتخزين نوع المشكلة المختار


  // --- حالة التنقل والمراحل ---
  // لا نحتاج لـ currentStageOverride، سنعتمد على taskDetails.value.status مباشرة
  DeliveryTaskStatus get currentTaskStatus => taskDetails.value?.status ?? DeliveryTaskStatus.driver_assigned; // قيمة افتراضية آمنة

  // --- الخريطة ---
  GoogleMapController? googleMapController;
  final RxSet<Marker> mapMarkers = <Marker>{}.obs;
  final Rxn<LatLng> driverCurrentMapPosition = Rxn<LatLng>(null); // آخر موقع معروف للسائق على الخريطة
  final TextEditingController _issueReasonController = TextEditingController();

  // --- إثبات التسليم ---
  final ImagePicker _imagePicker = ImagePicker();
  final Rxn<File> _pickedProofImageFile = Rxn<File>(null); // صورة يتم اختيارها في الواجهة

  // --- حالة تحميل الإجراءات ---
  final RxBool isLoadingAction = false.obs; // تُستخدم للأزرار مثل تأكيد الاستلام/التسليم
  StreamSubscription<Position>? _directDriverPositionStream; //  مثال إذا أضفته لاحقًا

  // --- الاشتراكات ---
  StreamSubscription? _taskDetailsSubscription;
  StreamSubscription? _driverProfileSubscription; // للاستماع لموقع السائق والمهمة المركزة من ملفه
  StreamSubscription? _driverProfileSubscriptionForLocationAndFocus; // <--- هذا اسم اشتراك ملف السائق
  final RxList<Map<String, dynamic>> itemsToPickupForCurrentTask = <Map<String, dynamic>>[].obs; // قائمة بالمنتجات لمسحها [{..., 'scannedStatus': 'pending'/'scanned'}]
  final RxBool isScanningPickupItems = false.obs; // حالة تفعيل واجهة مسح المنتجات
  final RxInt scannnedItemsCount = 0.obs;         // عدد العناصر الممسوحة
  final RxInt totalItemsToScan = 0.obs;           // إجمالي العناصر للمسح لهذه المهمة


  // --- جديد: لعملية التسليم للمشتري ---
  final RxBool isScanningBuyerConfirmation = false.obs; // حالة تفعيل مسح باركود المشتري
  final Rxn<File> pickedProofImageFile = Rxn<File>(null); //  <--- تغيير هنا: تم جعلها Rxn<File>

  // --- جديد: للتحكم في تحميل رفع الصورة ---
  final RxBool isUploadingProofImage = false.obs; // <--- جديد
  final RxString currentDistanceToDestination = "".obs; // <--- جديد: لتخزين المسافة النصية
  final RxString currentEtaToDestination = "".obs;      // <--- جديد: لتخزين الوقت المقدر النصي
  final TextEditingController delayReasonController = TextEditingController(); // تأكد من تعريف هذا أيضًا
  final RxList<String> receivedConsolidatedTaskIds = <String>[].obs; // IDs المهام المجمعة المستلمة من Arguments
  final RxList<DeliveryTaskModel> currentConsolidatedTasks = <DeliveryTaskModel>[].obs; // تفاصيل المهام المجمعة الفعلية
  final RxBool isConsolidatedDeliveryMode = false.obs; // هل نحن في وضع تسليم مجمع؟
  final RxList<Map<String, dynamic>> companyHubsForSelection = <Map<String, dynamic>>[].obs;
  final RxBool isLoadingCompanyHubs = false.obs;
  final Rxn<Map<String, dynamic>> selectedHubForDropOff = Rxn<Map<String, dynamic>>(null);
  @override
  void onInit() {
    super.onInit();
    instanceId = "${Get.routing.hashCode}_${DateTime.now().millisecondsSinceEpoch}";

    debugPrint("[NAV_CTRL_INIT] Initializing for Task ID: $taskId, Driver ID: $driverId");
    if (taskId.isEmpty || driverId == null || driverId!.isEmpty) {
      taskErrorMessage.value = "خطأ فادح: معرف المهمة أو السائق مفقود.";
      isLoadingTaskData.value = false;
      _handleCriticalErrorAndGoBack(taskErrorMessage.value); // <--- استدعاء هنا
      return;
    }


    if (Get.arguments is Map) {
      final Map args = Get.arguments as Map;
      bool mainTaskIsGroup = args['mainTaskIsConsolidatedGroupMember'] as bool? ?? false;
      List<dynamic>? receivedIdsDynamic = args['consolidatedTaskIds'] as List<dynamic>?;

      if (mainTaskIsGroup && receivedIdsDynamic != null && receivedIdsDynamic.isNotEmpty) {
        isConsolidatedDeliveryMode.value = true;
        receivedConsolidatedTaskIds.assignAll(receivedIdsDynamic.map((id) => id.toString()).toList());
        debugPrint("[NAV_CTRL_INIT] Consolidated Mode ON. Main: $taskId. All in group: $receivedConsolidatedTaskIds");
      } else if (mainTaskIsGroup) { //  جاء كجزء من مجموعة لكن لا يوجد IDs أخرى (قد تكون الوحيدة)
        isConsolidatedDeliveryMode.value = true;
        receivedConsolidatedTaskIds.assignAll([taskId]);
        debugPrint("[NAV_CTRL_INIT] Consolidated Mode ON for single task $taskId (was part of group criteria).");
      } else {
        isConsolidatedDeliveryMode.value = false;
        debugPrint("[NAV_CTRL_INIT] Single Task Mode for $taskId.");
      }
    }



    refreshTaskDetails();
    _subscribeToDriverProfileUpdates(); //  للحصول على الموقع والاسم والهاتف وتغيير المهمة المركزة
  }



  final List<Map<String, String>> commonIssueTypes = [
    {'key': 'buyer_not_responding', 'display': 'المستلم لا يستجيب (هاتف/جرس)'},
    {'key': 'wrong_address', 'display': 'العنوان خاطئ أو غير مكتمل'},
    {'key': 'recipient_rejected_delivery', 'display': 'المستلم رفض استلام الشحنة'},
    {'key': 'package_damaged_at_delivery', 'display': 'الشحنة تالفة عند محاولة التسليم'},
    {'key': 'payment_issue_cod', 'display': 'مشكلة في الدفع عند الاستلام'},
    {'key': 'access_issue_delivery', 'display': 'صعوبة في الوصول لموقع التسليم'},
    {'key': 'driver_emergency_vehicle_issue', 'display': 'طارئ للسائق / مشكلة في المركبة'},
    {'key': 'other', 'display': 'مشكلة أخرى (يرجى التوضيح)'},
  ];



  Future<void> setDeliveryTargetToBuyer() async {
    if (taskDetails.value == null || driverId == null) {
      debugPrint("[NAV_CTRL_TARGET_BUYER] Aborted: Missing task details or driver ID.");
      return;
    }
    isLoadingAction.value = true;
    try {
      await _firestore.collection(FirebaseX.deliveryTasksCollection).doc(taskId).update({
        'status': deliveryTaskStatusToString(DeliveryTaskStatus.out_for_delivery_to_buyer),
        'driverPickupDecision': 'direct_delivery', // مهم لتسجيل القرار
        'hubIdDroppedOffAt': FieldValue.delete(),      //  امسح أي معلومات مقر سابقة إذا وجدت
        'hubNameDroppedOffAt': FieldValue.delete(),   //  امسح أي معلومات مقر سابقة إذا وجدت
        'hubDropOffTime': FieldValue.delete(),       //  امسح أي معلومات مقر سابقة إذا وجدت
        'updatedAt': FieldValue.serverTimestamp(),
        'taskNotesInternal': FieldValue.arrayUnion([
          "${DateFormat('yy/MM/dd hh:mm a','ar').format(DateTime.now())}: السائق ($driverId) قرر التوجه مباشرة لتسليم الطلب للمشتري."
        ])
      });
      //  سيتم تحديث واجهة المستخدم والخريطة من خلال الـ stream listener لـ taskDetails
      Get.snackbar("تم تحديد الوجهة", "أنت الآن متجه مباشرة إلى المشتري.", backgroundColor: Colors.blue, colorText: Colors.white);
    } catch (e,s) {
      debugPrint("[NAV_CTRL_TARGET_BUYER] Error updating task status to out_for_delivery: $e\n$s");
      Get.snackbar("خطأ", "فشل تحديث وجهة المهمة: ${e.toString()}", backgroundColor:Colors.red.shade300);
    } finally {
      isLoadingAction.value = false;
    }
  }






  Future<void> chooseHubForDropOff(BuildContext context) async {
    if (taskDetails.value?.assignedCompanyId == null || taskDetails.value!.assignedCompanyId!.isEmpty) {
      Get.snackbar("خطأ", "لم يتم تحديد شركة لهذه المهمة.", backgroundColor: Colors.red.shade300);
      return;
    }
    if (isLoadingCompanyHubs.value) return;

    isLoadingCompanyHubs.value = true;
    companyHubsForSelection.clear();
    selectedHubForDropOff.value = null;

    try {
      DocumentSnapshot companyDoc = await _firestore
          .collection(FirebaseX.deliveryCompaniesCollection) // اسم مجموعة الشركات
          .doc(taskDetails.value!.assignedCompanyId!)
          .get();

      if (companyDoc.exists && companyDoc.data() != null) {
        final companyData = DeliveryCompanyModel.fromMap(companyDoc.data() as Map<String,dynamic>, companyDoc.id);
        if (companyData.hubLocations != null && companyData.hubLocations!.isNotEmpty) {
          // فلترة للتأكد من أن كل "hub" يحتوي على البيانات المطلوبة
          final validHubs = companyData.hubLocations!
              .where((hub) =>
          hub['hubId'] is String && (hub['hubId'] as String).isNotEmpty &&
              hub['hubName'] is String && (hub['hubName'] as String).isNotEmpty &&
              hub['hubConfirmationBarcode'] is String && (hub['hubConfirmationBarcode'] as String).isNotEmpty &&
              hub['hubLocation'] is GeoPoint
          ).toList();

          if (validHubs.isEmpty) {
            Get.snackbar("لا توجد مقرات صالحة", "بيانات مقرات الشركة غير مكتملة أو غير صحيحة.", backgroundColor: Colors.orange.shade300, duration: Duration(seconds: 4));
            isLoadingCompanyHubs.value = false;
            return;
          }

          companyHubsForSelection.assignAll(validHubs);

          if (companyHubsForSelection.length == 1) {
            selectedHubForDropOff.value = companyHubsForSelection.first;
            debugPrint("[NAV_CTRL_HUB_CHOICE] Single hub found and auto-selected: ${selectedHubForDropOff.value?['hubName']}");
            await _proceedWithHubDropOffDecision();
          } else {
            Map<String, dynamic>? chosenHub = await Get.dialog<Map<String, dynamic>>(
              AlertDialog(
                title: const Text("اختر مقر الشركة للتسليم إليه"),
                content: SizedBox(
                  width: double.maxFinite,
                  child: companyHubsForSelection.isEmpty // تحقق إضافي إذا كانت القائمة فارغة بعد الفلترة (نادر)
                      ? const Center(child: Text("لا توجد مقرات متاحة للاختيار حاليًا."))
                      : ListView.builder(
                    shrinkWrap: true,
                    itemCount: companyHubsForSelection.length,
                    itemBuilder: (ctx, index) {
                      final hub = companyHubsForSelection[index];
                      return ListTile(
                        title: Text(hub['hubName'] as String? ?? 'مقر غير مسمى'),
                        subtitle: Text(hub['hubAddressText'] as String? ?? ''),
                        leading: Icon(Icons.business_rounded, color: Theme.of(context).primaryColor),
                        onTap: () => Get.back(result: hub),
                      );
                    },
                  ),
                ),
                actions: [ TextButton(onPressed: () => Get.back(), child: const Text("إلغاء")) ],
              ),
              barrierDismissible: false, // يفضل جعلها false لإجبار المستخدم على الاختيار أو الإلغاء
            );
            if (chosenHub != null) {
              selectedHubForDropOff.value = chosenHub;
              debugPrint("[NAV_CTRL_HUB_CHOICE] Hub selected by driver: ${selectedHubForDropOff.value?['hubName']}");
              await _proceedWithHubDropOffDecision();
            } else {
              debugPrint("[NAV_CTRL_HUB_CHOICE] Hub selection cancelled by driver.");
            }
          }
        } else {
          Get.snackbar("لا توجد مقرات", "شركة التوصيل هذه لم تُضف أي مقرات مسجلة.", backgroundColor: Colors.orange.shade300, duration: Duration(seconds: 4));
        }
      } else {
        Get.snackbar("خطأ", "لم يتم العثور على بيانات شركة التوصيل لهذه المهمة.", backgroundColor: Colors.red.shade300);
      }
    } catch (e, s) {
      debugPrint("[NAV_CTRL_HUB_CHOICE] Error fetching/choosing company hubs: $e\n$s");
      Get.snackbar("خطأ", "فشل في جلب مقرات الشركة: ${e.toString()}", backgroundColor: Colors.red.shade300);
    } finally {
      isLoadingCompanyHubs.value = false;
    }
  }








  Future<void> confirmDropOffAtHub(BuildContext context, String scannedHubBarcode) async {
    // ... (الكود كما هو في الرد السابق، مع التأكد من أن:
    //    `final String expectedHubBarcode = selectedHubForDropOff.value!['hubConfirmationBarcode'] as String? ?? '';`
    //     وأن `selectedHubForDropOff.value!['hubId']` و `selectedHubForDropOff.value!['hubName']` تُستخدم بشكل صحيح.
    //     وأن `pickedProofImageFile` تُمسح.
    // )
    // الكود من الرد السابق مع التأكيدات:
    if (taskDetails.value == null || driverId == null || selectedHubForDropOff.value == null) {
      Get.snackbar("خطأ", "بيانات غير مكتملة لإتمام تسليم المقر.", snackPosition: SnackPosition.TOP);
      return;
    }
    final hubData = selectedHubForDropOff.value!; // للاستخدام الآمن
    final String expectedHubBarcode = hubData['hubConfirmationBarcode'] as String? ?? '';

    if (expectedHubBarcode.isEmpty) {
      Get.snackbar("خطأ تكوين", "لم يتم تعريف باركود تأكيد لهذا المقر (${hubData['hubName']}). يرجى مراجعة مشرف الشركة.",
          backgroundColor: Colors.red.shade400, duration: const Duration(seconds: 5), snackPosition: SnackPosition.TOP);
      return;
    }
    if (scannedHubBarcode.trim().toLowerCase() != expectedHubBarcode.trim().toLowerCase()) {
      Get.snackbar("باركود مقر خاطئ!", "الباركود الذي مسحته لا يتطابق مع باركود المقر المختار (${hubData['hubName']}).",
          backgroundColor: Colors.red.shade300, duration: const Duration(seconds: 4), snackPosition: SnackPosition.TOP);
      return;
    }

    // ... (باقي منطق التقاط الصورة، الرفع، وتحديث Firestore كما في الرد السابق، مع التأكد من استخدام `hubData`...)
    isLoadingAction.value = true;
    String? hubDropOffProofUrl;

    try {
      if (pickedProofImageFile.value != null) {
        hubDropOffProofUrl = await _uploadImageToStorage(
            pickedProofImageFile.value!,
            "hub_dropoff_proof_${hubData['hubId']}_${taskDetails.value!.taskId}");
        if (hubDropOffProofUrl == null) {
          debugPrint("[NAV_CTRL_HUB_CONFIRM] Warning: Failed to upload hub drop-off proof. Proceeding without it.");
        }
      }
      // (منطق المعاملة transaction لتحديث Task و Driver كما كان)
      await _firestore.runTransaction((transaction) async {
        DocumentReference taskRef = _firestore.collection(FirebaseX.deliveryTasksCollection).doc(taskId);
        DocumentReference driverRef = _firestore.collection(FirebaseX.deliveryDriversCollection).doc(driverId!);

        transaction.update(taskRef, {
          'status': deliveryTaskStatusToString(DeliveryTaskStatus.dropped_at_hub),
          'hubIdDroppedOffAt': hubData['hubId'],
          'hubNameDroppedOffAt': hubData['hubName'], //  (إضافة إذا كان الحقل موجودًا)
          'hubDropOffTime': FieldValue.serverTimestamp(),
          if (hubDropOffProofUrl != null) 'deliveryProofImageUrl': hubDropOffProofUrl,
          'updatedAt': FieldValue.serverTimestamp(),
          'taskNotesInternal': FieldValue.arrayUnion([
            "${DateFormat('yy/MM/dd hh:mm a', 'ar').format(DateTime.now())}: "
                "السائق ($driverId) قام بتسليم الشحنة بنجاح إلى مقر '${hubData['hubName']}' "
                "بواسطة باركود المقر. ${hubDropOffProofUrl != null ? 'صورة إثبات مرفقة.' : ''}"
          ]),
        });
        transaction.update(driverRef, {
          'currentFocusedTaskId': FieldValue.delete(),
          'availabilityStatus': 'online_available',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      Get.snackbar(
          "تم التسليم للمقر بنجاح!",
          "تم تسجيل تسليمك للشحنة بنجاح إلى مقر '${selectedHubForDropOff.value!['hubName']}'.",
          backgroundColor: Colors.green, colorText: Colors.white, duration: const Duration(seconds: 3), snackPosition: SnackPosition.BOTTOM);

      pickedProofImageFile.value = null;
      selectedHubForDropOff.value = null;
    } catch (e,s) {debugPrint("[NAV_CTRL_HUB_CONFIRM] Error confirming hub drop off: $e\n$s");
    Get.snackbar("خطأ", "فشل تأكيد تسليم الشحنة للمقر: ${e.toString()}", backgroundColor: Colors.red.shade300, duration: Duration(seconds:4)); } finally { isLoadingAction.value = false; }
  }
















  Future<void> _proceedWithHubDropOffDecision() async {
    if (selectedHubForDropOff.value == null || taskDetails.value == null || driverId == null) {
      debugPrint("[NAV_CTRL_HUB_PROCEED] Aborted: Missing selected hub, task details, or driver ID.");
      if(selectedHubForDropOff.value == null) Get.snackbar("خطأ", "لم يتم اختيار مقر للتسليم إليه بعد.");
      return;
    }
    isLoadingAction.value = true;
    final hubData = selectedHubForDropOff.value!; // الآن يمكننا استخدامه بأمان
    try {
      await _firestore.collection(FirebaseX.deliveryTasksCollection).doc(taskId).update({
        'status': deliveryTaskStatusToString(DeliveryTaskStatus.en_route_to_hub),
        'driverPickupDecision': 'hub_dropoff',
        'hubIdDroppedOffAt': hubData['hubId'],      //  استخدم 'hubId'
        // يمكنك هنا إضافة اسم المقر المختار للمهمة إذا أردت، لسهولة العرض لاحقًا
        'hubNameDroppedOffAt': hubData['hubName'],  //  (حقل جديد مقترح)
        'updatedAt': FieldValue.serverTimestamp(),
        'taskNotesInternal': FieldValue.arrayUnion([
          "${DateFormat('yy/MM/dd hh:mm a','ar').format(DateTime.now())}: "
              "قرر السائق ($driverId) التوجه لتسليم الشحنة إلى مقر '${hubData['hubName']}'. (ID: ${hubData['hubId']})"
        ])
      });
      //  taskDetails.value سيتم تحديثه تلقائيًا بواسطة StreamSubscription `_taskDetailsSubscription`
      //  وهذا سيؤدي لتحديث الواجهة والخريطة عبر `_updateMapAndCameraState()`
      Get.snackbar("تم تحديد الوجهة", "أنت الآن متجه إلى مقر: ${hubData['hubName']}.", backgroundColor: Colors.blue, colorText: Colors.white, duration: Duration(seconds:3));
    } catch (e,s){
      debugPrint("[NAV_CTRL_HUB_PROCEED] Error updating task status for hub drop-off: $e\n$s");
      Get.snackbar("خطأ", "فشل تحديث وجهة المهمة: ${e.toString()}", backgroundColor:Colors.red.shade300);
      // قد تحتاج لإعادة تعيين selectedHubForDropOff.value إلى null هنا إذا فشل التحديث بشدة
      // selectedHubForDropOff.value = null;
    } finally {
      isLoadingAction.value = false;
    }
  }


  Future<void> refreshTaskDetails() async {
    if (taskId.isEmpty) {
      taskErrorMessage.value = "معرف المهمة غير صالح للتحديث.";
      isLoadingTaskData.value = false;
      return;
    }
    isLoadingTaskData.value = true;
    taskErrorMessage.value = '';
    _taskDetailsSubscription?.cancel();
    currentConsolidatedTasks.clear(); // ابدأ بقائمة فارغة

    debugPrint("[NAV_CTRL_REFRESH] Refreshing tasks. Main Task ID: $taskId. Consolidated Mode: ${isConsolidatedDeliveryMode.value}");

    List<String> idsToFetch = [];
    if(isConsolidatedDeliveryMode.value && receivedConsolidatedTaskIds.isNotEmpty) {
      idsToFetch.addAll(receivedConsolidatedTaskIds.toSet()); // استخدم Set لتجنب تكرار الـ main taskId
    } else {
      idsToFetch.add(taskId); // مهمة واحدة فقط
    }
    if(!idsToFetch.contains(taskId) && taskId.isNotEmpty) idsToFetch.insert(0,taskId); // تأكد من وجود المهمة الرئيسية

    if(idsToFetch.isEmpty) { //  إذا لم يتم تحديد مهمة رئيسية ولم تكن هناك مهام مجمعة
      taskErrorMessage.value = "لا توجد معرفات مهام لجلبها.";
      _handleCriticalErrorAndGoBack(taskErrorMessage.value);
      isLoadingTaskData.value = false;
      return;
    }

    try {
      List<DeliveryTaskModel> fetchedAndValidTasks = [];
      String? commonBuyerIdForConsolidation; // لتخزين buyerId من المهمة الرئيسية
      DeliveryTaskModel? mainTaskCandidate;


      // جلب كل مهمة في idsToFetch
      List<Future<DocumentSnapshot<Map<String, dynamic>>>> fetchFutures = idsToFetch
          .map((id) => _firestore.collection(FirebaseX.deliveryTasksCollection).doc(id).get())
          .toList();

      final List<DocumentSnapshot<Map<String, dynamic>>> taskDocs = await Future.wait(fetchFutures);

      for (var doc in taskDocs) {
        if (doc.exists && doc.data() != null) {
          final currentFetchedTask = DeliveryTaskModel.fromFirestore(doc);
          if (doc.id == taskId) { // هذه هي المهمة "الرئيسية"
            mainTaskCandidate = currentFetchedTask;
            commonBuyerIdForConsolidation = currentFetchedTask.buyerId; // اعتبر buyerId للمهمة الرئيسية هو المرجع
          }
          // أضف المهمة إذا كانت صالحة
          if(_isTaskActuallyDeliverable(currentFetchedTask)){ // <--- تأكد من أن هذه الدالة موجودة وصحيحة
            fetchedAndValidTasks.add(currentFetchedTask);
          } else {
            debugPrint("[NAV_CTRL_REFRESH] Task ${currentFetchedTask.taskId} (${currentFetchedTask.status}) is NOT in a deliverable state. Skipping from active batch.");
          }
        }
      }
      // بعد جلب كل المهام، تأكد أن المهمة الرئيسية موجودة وصالحة
      if (mainTaskCandidate == null || !_isTaskActuallyDeliverable(mainTaskCandidate)) {
        if(mainTaskCandidate != null) { //  جُلبت ولكنها ليست قابلة للتسليم الآن
          taskDetails.value = mainTaskCandidate; //  اعرضها لكن لا تضفها لـ currentConsolidatedTasks إذا لم تكن deliverable
          debugPrint("[NAV_CTRL_REFRESH] Main task ${mainTaskCandidate.taskId} is no longer actively deliverable. Displaying info only.");
          //  _isTaskStillActiveForDriverNavigation سيقوم بالباقي
        } else {
          throw Exception("المهمة الرئيسية ($taskId) المطلوبة لم يتم العثور عليها أو غير صالحة.");
        }
      } else {
        taskDetails.value = mainTaskCandidate; // عيّن المهمة الرئيسية الصالحة
      }


      // إذا كنا في وضع التجميع، قم بفلترة fetchedAndValidTasks للتأكد أنها لنفس المشتري
      if (isConsolidatedDeliveryMode.value && commonBuyerIdForConsolidation != null) {
        currentConsolidatedTasks.assignAll(
            fetchedAndValidTasks.where((t) => t.buyerId == commonBuyerIdForConsolidation).toList()
        );
        if(currentConsolidatedTasks.length <=1 && isConsolidatedDeliveryMode.value){
          // إذا بعد الفلترة، لم يبق إلا مهمة واحدة أو أقل، لم يعد وضع تجميع
          isConsolidatedDeliveryMode.value = false;
          debugPrint("[NAV_CTRL_REFRESH] Downgraded from consolidated mode. Only ${currentConsolidatedTasks.length} tasks for buyer $commonBuyerIdForConsolidation.");
        }
      } else if (taskDetails.value != null && _isTaskActuallyDeliverable(taskDetails.value!)) { // إذا مهمة واحدة فقط وصالحة
        currentConsolidatedTasks.assignAll([taskDetails.value!]);
        isConsolidatedDeliveryMode.value = false; // تأكيد أنه ليس وضع تجميع
      } else {
        //  إذا taskDetails.value كان null أو غير قابل للتسليم ولم يكن وضع تجميع
        currentConsolidatedTasks.clear();
        isConsolidatedDeliveryMode.value = false;
      }


      if (taskDetails.value == null && currentConsolidatedTasks.isEmpty) {
        // هذه الحالة تعني أن حتى المهمة الرئيسية لم يتم جلبها بنجاح أو لم تكن صالحة
        throw Exception("لا توجد أي مهام صالحة للعرض بعد الجلب الأولي.");
      }


      _prepareItemsForPickup(); // <--- جهّز العناصر للمهمة الرئيسية (taskDetails.value)
      _calculateAndSetDistanceAndEta();
      _updateMapAndCameraState();

      debugPrint("[NAV_CTRL_REFRESH] Refresh complete. Main: ${taskDetails.value?.orderIdShort}, Consolidated count: ${currentConsolidatedTasks.length}, Mode: ${isConsolidatedDeliveryMode.value}");

      if (taskDetails.value != null && !_isTaskStillActiveForDriverNavigation(currentTaskStatus)) {
        handleTaskNoLongerActiveNavigation("حالة المهمة تغيرت إلى: ${deliveryTaskStatusToString(taskDetails.value!.status)}.",
            isSuccess: taskDetails.value!.status == DeliveryTaskStatus.delivered);
      } else if (taskDetails.value == null && currentConsolidatedTasks.isEmpty){
        _handleCriticalErrorAndGoBack("لم يتم العثور على بيانات المهمة المطلوبة.");
      }

    }catch (e, s) {
      debugPrint("[NAV_CTRL_REFRESH] Error in refreshTaskDetails: $e\n$s");
      taskErrorMessage.value = e.toString().contains("غير موجودة") ? e.toString() : "خطأ في تحميل بيانات المهمة. حاول لاحقًا.";
      taskDetails.value = null;
      currentConsolidatedTasks.clear();
      isConsolidatedDeliveryMode.value = false; // Reset





      // قد تحتاج لاستدعاء handleTaskNoLongerActiveNavigation هنا لإغلاق الشاشة
      // إذا فشل جلب المهمة الرئيسية تمامًا.
      _handleCriticalErrorAndGoBack(taskErrorMessage.value); // استخدم هذا إذا كان الخطأ يمنع عرض أي شيء
    } finally {
      isLoadingTaskData.value = false;
    }
  }




  bool _isTaskActuallyDeliverable(DeliveryTaskModel task) {
    return task.status == DeliveryTaskStatus.picked_up_from_seller ||
        task.status == DeliveryTaskStatus.out_for_delivery_to_buyer ||
        task.status == DeliveryTaskStatus.at_buyer_location ||
        //  إذا كنت تريد السماح بتجميع مهمة driver_assigned مع أخرى (نادر جدًا)
        // (task.status == DeliveryTaskStatus.driver_assigned && isConsolidatedDeliveryMode.value /* إذا كانت هناك مهام أخرى في الدفعة بالفعل*/)
        false;
  }













  void showFullOrderItemsDialog(BuildContext context) {
    if (taskDetails.value == null || taskDetails.value!.itemsSummary == null || taskDetails.value!.itemsSummary!.isEmpty) {
      Get.snackbar("لا توجد تفاصيل", "لا توجد تفاصيل منتجات لعرضها لهذه المهمة.", snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final items = taskDetails.value!.itemsSummary!;
    final theme = Theme.of(context);

    Get.dialog(
      AlertDialog(
        title: Text("تفاصيل منتجات الطلب #${taskDetails.value!.orderIdShort}"),
        contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: SizedBox(
          width: Get.width * 0.85, // عرض الحوار
          child: Scrollbar( // في حال كانت القائمة طويلة جدًا
            thumbVisibility: true,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (ctx, index) {
                final item = items[index];
                return ListTile(
                  dense: true,
                  leading: Text("${index + 1}.", style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold)),
                  title: Text(item['itemName'] as String? ?? "منتج غير مسمى", style:TextStyle(fontWeight:FontWeight.w500)),
                  subtitle: Text("الكمية: ${item['quantity']?.toString() ?? '1'} - باركود: ${item['itemBarcode'] ?? 'N/A'}"),
                  // يمكنك إضافة صورة المنتج هنا إذا كان لديك رابطها في itemsSummary
                  // trailing: item['itemImageUrl'] != null ? Image.network(item['itemImageUrl'], width:40, height:40, fit:BoxFit.cover) : null,
                );
              },
              separatorBuilder: (ctx, index) => const Divider(height: 1, thickness:0.5, indent:10, endIndent:10),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("إغلاق"),
          ),
        ],
      ),
    );
  }



  void _calculateAndSetDistanceAndEta() { // <--- دالة جديدة
    if (taskDetails.value == null || driverCurrentMapPosition.value == null) {
      currentDistanceToDestination.value = "غير متوفرة";
      currentEtaToDestination.value = ""; // أو "غير متوفر"
      return;
    }
    final task = taskDetails.value!;
    final status = currentTaskStatus;
    LatLng? destinationLatLng;

    if (status == DeliveryTaskStatus.driver_assigned || status == DeliveryTaskStatus.en_route_to_pickup) {
      destinationLatLng = task.pickupLatLng;
    } else if (status == DeliveryTaskStatus.picked_up_from_seller ||
        status == DeliveryTaskStatus.out_for_delivery_to_buyer ||
        status == DeliveryTaskStatus.at_buyer_location) {
      destinationLatLng = task.deliveryLatLng;
    }

    if (destinationLatLng != null) {
      double distanceMeters = Geolocator.distanceBetween(
        driverCurrentMapPosition.value!.latitude,
        driverCurrentMapPosition.value!.longitude,
        destinationLatLng.latitude,
        destinationLatLng.longitude,
      );

      if (distanceMeters < 1000) {
        currentDistanceToDestination.value = "${distanceMeters.toStringAsFixed(0)} متر";
      } else {
        currentDistanceToDestination.value = "${(distanceMeters / 1000).toStringAsFixed(1)} كم";
      }

      // حساب ETA مبدئي (بدون Google Directions API)
      // افترض متوسط سرعة 25 كم/ساعة (تقريباً 0.416 كم/دقيقة أو 416 متر/دقيقة)
      if (distanceMeters > 0) {
        double estimatedMinutes = distanceMeters / 350; // (متر / (متر/دقيقة)) = دقيقة
        if (estimatedMinutes < 1) {
          currentEtaToDestination.value = "~ أقل من دقيقة";
        } else if (estimatedMinutes < 60) {
          currentEtaToDestination.value = "~ ${estimatedMinutes.round()} دقيقة";
        } else {
          currentEtaToDestination.value = "~ ${NumberFormat('0.#', 'ar').format(estimatedMinutes / 60)} ساعة";
        }
      } else if (distanceMeters == 0) { // في حالة كان الحساب 0 (نادر)
        currentEtaToDestination.value = "وصلت تقريبًا";
      }
      else {
        currentEtaToDestination.value = "";
      }
    } else {
      currentDistanceToDestination.value = "الوجهة غير محددة";
      currentEtaToDestination.value = "";
    }
  }


















  void _prepareItemsForPickup() {
    if (taskDetails.value != null && taskDetails.value!.itemsSummary != null) {
      // نفترض أن itemsSummary الآن يحتوي على itemBarcode و scannedByDriverAtPickup
      // ولكن `scannedByDriverAtPickup` هو حالة مؤقتة في الواجهة فقط
      itemsToPickupForCurrentTask.assignAll(
          taskDetails.value!.itemsSummary!.map((itemMap) {
            return {
              ...itemMap, // انسخ كل البيانات الأصلية للعنصر
              'actualScannedBarcode': null, // (String?) لتخزين الباركود الذي مسحه السائق فعليًا (للمقارنة)
              'itemScannedByUserInterface': false, // (bool) لتتبع المسح في الواجهة الحالية
            };
          }).toList()
      );
      totalItemsToScan.value = itemsToPickupForCurrentTask.length;
      scannnedItemsCount.value = itemsToPickupForCurrentTask.where((item) => item['itemScannedByUserInterface'] == true).length;
      isScanningPickupItems.value = false; // ابدأ بحالة المسح مغلقة
      debugPrint("[NAV_CTRL] Prepared ${itemsToPickupForCurrentTask.length} items for pickup scanning.");
    } else {
      itemsToPickupForCurrentTask.clear();
      totalItemsToScan.value = 0;
      scannnedItemsCount.value = 0;
    }
  }


// --- دوال عمليات مسح الباركود والاستلام ---

  void startOrStopPickupItemScanningSession(bool start) {
    isScanningPickupItems.value = start;
    if (!start) {
      // (اختياري) إذا أردت مسح حالة "الممسوح" عند إغلاق شاشة المسح
      // _resetPickupScanStatus();
    }
    // إذا كنت ستستخدم `MobileScannerController` مدمج، يمكنك التحكم به هنا:
    // if (start) scannerController.start(); else scannerController.stop();
  }

  // تُستدعى عند مسح باركود منتج (سواء من ماسح مدمج أو نتيجة من شاشة مسح منفصلة)
  void processScannedPickupItemBarcode(String scannedBarcode) {
    if (!isScanningPickupItems.value) return;

    debugPrint("[NAV_CTRL] Processing scanned pickup barcode: $scannedBarcode");
    final index = itemsToPickupForCurrentTask.indexWhere((item) =>
    item['itemBarcode'] == scannedBarcode &&
        item['itemScannedByUserInterface'] == false // ابحث فقط عن التي لم تُمسح بعد في هذه الجلسة
    );

    if (index != -1) {
      itemsToPickupForCurrentTask[index]['itemScannedByUserInterface'] = true;
      itemsToPickupForCurrentTask[index]['actualScannedBarcode'] = scannedBarcode; // حفظ ما تم مسحه
      scannnedItemsCount.value = itemsToPickupForCurrentTask.where((item) => item['itemScannedByUserInterface'] == true).length;
      // itemsToPickupForCurrentTask.refresh(); //  أو update() إذا كنت تستخدم IDs للـ GetBuilder
      Get.snackbar("تم المسح!", "تم مسح المنتج: ${itemsToPickupForCurrentTask[index]['itemName'] ?? scannedBarcode}", backgroundColor: Colors.green.shade100, duration: Duration(milliseconds: 1500), snackPosition: SnackPosition.TOP, colorText: Colors.green.shade900);
    } else {
      // تحقق مما إذا كان قد تم مسحه مسبقًا في هذه الجلسة
      final alreadyScannedIndex = itemsToPickupForCurrentTask.indexWhere((item) => item['itemBarcode'] == scannedBarcode && item['itemScannedByUserInterface'] == true);
      if(alreadyScannedIndex != -1){
        Get.snackbar("ممسوح مسبقًا", "هذا المنتج تم مسحه بالفعل.", backgroundColor: Colors.amber.shade200, duration: Duration(milliseconds: 1800), snackPosition: SnackPosition.TOP, colorText: Colors.amber.shade900);
      } else {
        Get.snackbar("باركود غير متطابق", "هذا الباركود لا يتطابق مع أي من المنتجات المتبقية في هذه المهمة.", backgroundColor: Colors.red.shade200, duration: Duration(milliseconds: 2500), snackPosition: SnackPosition.TOP, colorText: Colors.red.shade900);
      }
    }
    // إذا كان هذا هو آخر عنصر، يمكنك إغلاق واجهة المسح تلقائيًا أو إظهار زر "تأكيد الاستلام" بشكل بارز
    if(scannnedItemsCount.value == totalItemsToScan.value && totalItemsToScan.value > 0){
      // startOrStopPickupItemScanningSession(false); // إيقاف الماسح
      // Get.snackbar("اكتمل المسح", "تم مسح جميع المنتجات. جاهز لتأكيد الاستلام.", backgroundColor: Colors.lightBlue, colorText: Colors.white, duration: Duration(seconds: 3));
    }
  }



  bool isTaskStillActiveForDriverNavigation(DeliveryTaskStatus? status) {
    if (status == null) return false; //  إذا لم تكن هناك حالة، فهي ليست نشطة
    // الحالات التي تعتبر فيها المهمة لا تزال "نشطة" بالنسبة لواجهة التنقل
    return !(
        status == DeliveryTaskStatus.delivered ||
            status == DeliveryTaskStatus.delivery_failed ||
            status == DeliveryTaskStatus.returned_to_seller ||
            status == DeliveryTaskStatus.cancelled_by_seller ||
            status == DeliveryTaskStatus.cancelled_by_buyer ||
            status == DeliveryTaskStatus.cancelled_by_company_admin ||
            status == DeliveryTaskStatus.cancelled_by_platform_admin
    );
  }


  void _handleCriticalErrorAndGoBack(String errorMessage, {int delaySeconds = 4}) {
    debugPrint("[NAV_CTRL] Critical error for task $taskId: $errorMessage. Navigating back.");
    _stopAllScreenSpecificSubscriptions();

    if (Get.isSnackbarOpen ?? false) Get.closeCurrentSnackbar();
    Get.snackbar("خطأ فادح", errorMessage,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        duration: Duration(seconds: delaySeconds -1),
        snackPosition: SnackPosition.TOP);

    Future.delayed(Duration(seconds: delaySeconds), () {
      if (Get.isRegistered<DeliveryNavigationController>(tag: instanceId) && // استخدام معرّف المثيل
          Get.currentRoute.startsWith(AppRoutes.DRIVER_DELIVERY_NAVIGATION.split('/:').first) ) {
        if(Get.isRegistered<DriverDashboardController>()) Get.find<DriverDashboardController>().refreshAllData(showMainLoader:false);
        Get.offAllNamed(AppRoutes.DRIVER_DASHBOARD);
      }
    });
  }



  void _subscribeToDriverProfileUpdates() {
    if (driverId == null || driverId!.isEmpty) { // أضفت تحقق إضافي لـ driverId
      debugPrint("[NAV_CTRL_PROFILE_SUB] Cannot subscribe to driver profile, driverId is null or empty.");
      return;
    }

    _driverProfileSubscriptionForLocationAndFocus?.cancel(); // إلغاء أي اشتراك سابق
    debugPrint("[NAV_CTRL_PROFILE_SUB] Subscribing to driver profile updates for: $driverId");

    _driverProfileSubscriptionForLocationAndFocus = _firestore
        .collection(FirebaseX.deliveryDriversCollection)
        .doc(driverId!) // استخدم driverId هنا بعد التحقق
        .snapshots()
        .listen((driverDoc) {
      if (driverDoc.exists && driverDoc.data() != null) {
        try { // إضافة try-catch لعملية البارسنج
          final driverData = DeliveryDriverModel.fromMap(driverDoc.data()!, driverDoc.id);
          driverProfile.value = driverData; // قم بتخزين نموذج السائق الكامل إذا احتجت لخصائص أخرى
          driverNameFromProfile.value = driverData.name;
          driverPhoneFromProfile.value = driverData.phoneNumber;

          if (driverData.currentLocation != null) {
            driverCurrentMapPosition.value = LatLng(
              driverData.currentLocation!.latitude,
              driverData.currentLocation!.longitude,
            );
          } else {
            driverCurrentMapPosition.value = null;
          }
          debugPrint("[NAV_CTRL_PROFILE_SUB] Driver profile live update: ${driverData.name}, Location: ${driverCurrentMapPosition.value}");

          // التحقق مما إذا كان السائق قد غير مهمته المركزة
          if (driverData.currentFocusedTaskId != taskId && _isTaskStillActiveForDriverNavigation(taskDetails.value?.status)) {
            debugPrint("[NAV_CTRL_PROFILE_SUB] Driver $driverId is now focused on task ${driverData.currentFocusedTaskId} (not this screen's task $taskId).");
            // (منطق handleTaskNoLongerActiveNavigation للتعامل مع هذا السيناريو)
            handleTaskNoLongerActiveNavigation("تم تغيير المهمة النشطة أو إلغاؤها من مكان آخر.", isSuccess:false, stayOnPage: true);
          }
          _updateMapAndCameraState(); // تحديث الخريطة بعد تحديث موقع السائق
          taskErrorMessage.value = ''; // مسح أي خطأ سابق إذا نجح التحديث
        } catch(e,s) {
          debugPrint("[NAV_CTRL_PROFILE_SUB] Error parsing driver data from Firestore: $e \n $s");
          taskErrorMessage.value = "خطأ في تنسيق بيانات ملف السائق.";
          // يمكنك هنا تعيين driverProfile.value = null; driverCurrentMapPosition.value = null;
        }
      } else {
        debugPrint("[NAV_CTRL_PROFILE_SUB] CRITICAL: Driver profile $driverId NOT FOUND during navigation screen operation!");
        taskErrorMessage.value = "خطأ فادح: لا يمكن الوصول لملفك الشخصي الأساسي. قد يكون الحساب غير نشط.";
        // (منطق handleTaskNoLongerActiveNavigation للعودة)
        handleTaskNoLongerActiveNavigation("خطأ في الوصول لملفك الشخصي.", isSuccess: false);
      }
    }, onError: (error){
      debugPrint("[NAV_CTRL_PROFILE_SUB] Error listening to driver profile: $error");
      taskErrorMessage.value = "فشل تحديث بياناتك: $error";
      // قد ترغب في إيقاف محاولة التحديث المستمر هنا إذا كان الخطأ دائمًا
      // _driverProfileSubscription?.cancel();
    });
  }


  bool _isTaskStillActiveForDriverNavigation(DeliveryTaskStatus? status) {
    if (status == null) return false;
    //  الحالات التي يجب أن يبقى السائق في شاشة التنقل من أجلها
    return status == DeliveryTaskStatus.driver_assigned ||
        status == DeliveryTaskStatus.en_route_to_pickup ||
        status == DeliveryTaskStatus.picked_up_from_seller ||
        status == DeliveryTaskStatus.dropped_at_hub || // <--- الحالة الجديدة هنا
        status == DeliveryTaskStatus.out_for_delivery_to_buyer ||
        status == DeliveryTaskStatus.at_buyer_location;
  }

  void handleTaskNoLongerActiveNavigation(
      String message, {
        required bool isSuccess,
        bool stayOnPage = false,
        int delaySeconds = 3, //  قيمة افتراضية للتأخير
      }) {
    debugPrint("[NAV_CTRL_HANDLER] handleTaskNoLongerActiveNavigation called. Message: '$message', Success: $isSuccess, StayOnPage: $stayOnPage, Delay: $delaySeconds");

    // الخطوة 1: إيقاف الاشتراكات الخاصة بهذه الشاشة *فقط* إذا كنا سنغادرها
    // هذا لمنع أي تحديثات أخرى أثناء عملية الإغلاق أو إذا كانت الشاشة ستُغلق
    if (!stayOnPage) {
      _stopAllScreenSpecificSubscriptions();
    }

    // الخطوة 2: التعامل مع الـ Snackbars
    // أغلق أي Snackbar قديم لضمان عدم تداخلها
    if (Get.isSnackbarOpen ?? false) {
      debugPrint("[NAV_CTRL_HANDLER] Closing existing snackbar before showing new one.");
      Get.closeCurrentSnackbar();
    }

    // عرض Snackbar الجديد بالمعلومات المناسبة
    // تحديد عنوان الـ Snackbar بناءً على isSuccess ونوع المهمة
    String snackbarTitle = isSuccess ? "اكتملت بنجاح" : "تنبيه/خطأ";
    if (isSuccess && taskDetails.value?.status == DeliveryTaskStatus.delivered) {
      snackbarTitle = "تم تسليم المهمة!";
    } else if (isSuccess && taskDetails.value?.status != null) {
      // إذا كان نجاحًا ولكنه ليس تسليمًا (مثلاً، تحديث حالة وسيطة بنجاح)
      snackbarTitle = "تم التحديث بنجاح";
    } else if (!isSuccess && message.toLowerCase().contains("تهيئة")) {
      snackbarTitle = "خطأ في التهيئة";
    }


    Get.snackbar(
      snackbarTitle,
      message,
      duration: Duration(seconds: delaySeconds), // مدة الـ Snackbar هي نفسها مدة التأخير
      snackPosition: SnackPosition.TOP, //  TOP ليكون مرئيًا حتى مع وجود أزرار سفلية
      backgroundColor: isSuccess
          ? Colors.green.shade600
          : (stayOnPage && !isSuccess // إذا كان سيبقى في الصفحة وهناك تنبيه/خطأ غير حاسم
          ? Colors.amber.shade700
          : Colors.red.shade600), // لون خطأ أغمق إذا كان سيخرج من الصفحة
      colorText: Colors.white,
      margin: const EdgeInsets.all(10),
      borderRadius: 10,
      boxShadows: [BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(0,2))],
    );
    debugPrint("[NAV_CTRL_HANDLER] Snackbar shown. Title: '$snackbarTitle', Message: '$message'");


    // الخطوة 3: التنقل إذا لم يكن stayOnPage
    if (!stayOnPage) {
      debugPrint("[NAV_CTRL_HANDLER] Task ($taskId) is final/error, will navigate to dashboard after $delaySeconds s. Current Route: ${Get.currentRoute}");

      // استخدام Future.delayed لانتظار انتهاء مدة الـ Snackbar (أو جزء منها) قبل التنقل
      Future.delayed(Duration(seconds: delaySeconds), () {
        // --- التحقق من أننا لا نزال في السياق الصحيح قبل التنقل ---
        // تعريف المسار الأساسي المتوقع لشاشة التنقل هذه
        // (افترض أن AppRoutes.DRIVER_DELIVERY_NAVIGATION قد يكون '/driver/task/navigation/:taskId')
        final String expectedNavigationRouteBase = AppRoutes.DRIVER_DELIVERY_NAVIGATION.split('/:').first;
        final String currentRouteBase = Get.currentRoute.split('/:').first;

        //  تحقق إذا كان المتحكم الحالي (هذا المثيل) لا يزال مسجلاً وأن المسار الحالي لا يزال هذه الشاشة
        if (Get.isRegistered<DeliveryNavigationController>(tag: instanceId) && //  استخدام instanceId (معرّف فريد للمثيل)
            currentRouteBase == expectedNavigationRouteBase ) {

          // محاولة تحديث بيانات الداشبورد إذا كانت موجودة
          if (Get.isRegistered<DriverDashboardController>()) {
            try {
              final dashboardCtrl = Get.find<DriverDashboardController>();
              debugPrint("[NAV_CTRL_HANDLER] Calling dashboardCtrl.refreshAllData() before navigating from task screen.");
              dashboardCtrl.refreshAllData(showMainLoader: false); // لا تظهر مؤشر تحميل رئيسي للداشبورد
            } catch (e) {
              debugPrint("[NAV_CTRL_HANDLER] Error finding/refreshing DriverDashboardController: $e");
            }
          }

          debugPrint("[NAV_CTRL_HANDLER] Navigating from '${Get.currentRoute}' via offNamedUntil to DRIVER_DASHBOARD.");
          // الانتقال إلى الداشبورد وإزالة جميع المسارات السابقة حتى نصل إلى الداشبورد
          // أو إذا كانت الداشبورد هي الأولى في المكدس
          Get.offNamedUntil(
              AppRoutes.DRIVER_DASHBOARD,
                  (route) => route.settings.name == AppRoutes.DRIVER_DASHBOARD || route.isFirst
          );
        } else {
          debugPrint("[NAV_CTRL_HANDLER] Navigation to dashboard ABORTED. Controller might be disposed or route changed. "
              "IsRegistered: ${Get.isRegistered<DeliveryNavigationController>(tag: instanceId)}, "
              "CurrentRouteBase: $currentRouteBase, ExpectedRouteBase: $expectedNavigationRouteBase");
        }
      });
    } else {
      debugPrint("[NAV_CTRL_HANDLER] stayOnPage is true. No navigation will occur for message: '$message'");
    }
  }







  void onMapCreated(GoogleMapController controllerParam) { // استقبل البارامتر
    googleMapController = controllerParam; // عيّن لمتحكم الكلاس
    debugPrint("[NAV_CTRL] GoogleMap for navigation screen CREATED.");
    // بمجرد إنشاء الخريطة، حاول تحديث الماركرات وحالة الكاميرا
    // البيانات قد تكون تم جلبها بالفعل من onInit
    _updateMapAndCameraState();
  }


// In DeliveryNavigationController.dart
  void _updateMapAndCameraState() {
    if (taskDetails.value == null) {
      mapMarkers.clear(); // افترض أن mapMarkers هو RxSet<Marker> المُعرّف في المتحكم
      polylines.clear();  // امسح الـ polylines هنا أيضًا
      return;
    }
    LatLng? targetDestinationForCamera;

    final Set<Marker> newMarkersSet = {};
    final Set<Polyline> newPolylinesSet = {}; // مجموعة لتخزين الـ polylines الجديدة

    LatLng? pickupTaskLatLng, deliveryTaskLatLng;
    final DeliveryTaskModel currentTask = taskDetails.value!; // الآن يمكننا استخدامه بأمان
    final DeliveryTaskStatus effectiveStatus = currentTaskStatus; // استخدام الـ getter

    // 1. ماركر الاستلام (البائع)
    final sellerGeoPoint = currentTask.pickupLocationGeoPoint;
    if (sellerGeoPoint != null) {
      pickupTaskLatLng = LatLng(sellerGeoPoint.latitude, sellerGeoPoint.longitude);
      newMarkersSet.add(Marker(
          markerId: MarkerId('pickup_dest_${currentTask.taskId}'), // استخدام taskId لضمان التفرد
          position: pickupTaskLatLng,
          infoWindow: InfoWindow(title: "نقطة الاستلام", snippet: currentTask.sellerShopName ?? currentTask.sellerName ?? "البائع"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          zIndex: 0
      ));
    }

    // 2. ماركر التسليم (المشتري)
    final deliveryGeoPoint = currentTask.deliveryLocationGeoPoint;
    if (deliveryGeoPoint != null) {
      deliveryTaskLatLng = LatLng(deliveryGeoPoint.latitude, deliveryGeoPoint.longitude);
      newMarkersSet.add(Marker(
          markerId: MarkerId('delivery_dest_${currentTask.taskId}'),
          position: deliveryTaskLatLng,
          infoWindow: InfoWindow(title: "نقطة التسليم", snippet: currentTask.buyerName ?? "المشتري"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          zIndex: 0
      ));
    }

    // 3. ماركر السائق ومساره (Polyline)
    final LatLng? driverPos = driverCurrentMapPosition.value;
    final String driverDisplayName = driverProfile.value?.name ?? "موقعك الحالي";

    if (driverPos != null) {
      newMarkersSet.add(Marker(
          markerId: MarkerId("driver_live_location_${driverId ?? 'unknown_driver'}"), // إضافة تحقق null لـ driverId
          position: driverPos,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(title: driverDisplayName),
          anchor: const Offset(0.5, 0.5),
          flat: true, // لجعله يلتصق بالخريطة عند إمالتها
          zIndex: 1 // ليكون فوق أي Polyline إذا تداخل
      ));

      // --- رسم Polyline من موقع السائق إلى الوجهة التالية ---
      LatLng? polylineEndPoint;
      String polylineIdSuffix = "";

      if (effectiveStatus == DeliveryTaskStatus.en_route_to_hub && selectedHubForDropOff.value != null) {
        final dynamic hubLocData = selectedHubForDropOff.value!['hubLocation'];
        if (hubLocData is GeoPoint) {
          polylineEndPoint = LatLng(hubLocData.latitude, hubLocData.longitude);
          targetDestinationForCamera = polylineEndPoint;
          polylineIdSuffix = "_to_selected_hub_${selectedHubForDropOff.value!['hubId']}";
        } else if (hubLocData is LatLng) { // إذا كانت مخزنة كـ LatLng مؤقتًا في selectedHubForDropOff
          polylineEndPoint = hubLocData;
          targetDestinationForCamera = polylineEndPoint;
          polylineIdSuffix = "_to_selected_hub_${selectedHubForDropOff.value!['hubId']}";
        } else {
          debugPrint("Warning: Selected hub location data is invalid in _updateMapAndCameraState.");
          // fallback to original delivery location if hub location is bad
          targetDestinationForCamera = deliveryTaskLatLng;
          polylineEndPoint = deliveryTaskLatLng;
          polylineIdSuffix = "_to_buyer_fallback";
        }
      }




      if (effectiveStatus == DeliveryTaskStatus.driver_assigned ||
          effectiveStatus == DeliveryTaskStatus.en_route_to_pickup) {
        polylineEndPoint = pickupTaskLatLng;
        polylineIdSuffix = "_to_pickup";
      } else if (effectiveStatus == DeliveryTaskStatus.picked_up_from_seller ||
          effectiveStatus == DeliveryTaskStatus.out_for_delivery_to_buyer ||
          effectiveStatus == DeliveryTaskStatus.at_buyer_location) {
        polylineEndPoint = deliveryTaskLatLng;
        polylineIdSuffix = "_to_delivery";
      }

      if (polylineEndPoint != null) {
        newPolylinesSet.add(Polyline(
          polylineId: PolylineId('route_${currentTask.taskId}$polylineIdSuffix'),
          points: [driverPos, polylineEndPoint], // خط مباشر
          color: Colors.blueAccent.withOpacity(0.7),
          width: 5, // عرض الخط
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ));
      }












      // --- نهاية رسم Polyline ---
    }
    mapMarkers.assignAll(newMarkersSet);
    polylines.assignAll(newPolylinesSet); // <--- تحديث polylines هنا

    _fitMapToMarkersIfReady();

    _calculateAndSetDistanceAndEta(); // <--- قم باستدعائها هنا
    // --- تحريك الكاميرا ---
    if (googleMapController != null) {
      List<LatLng> pointsForBoundsCalculation = [];
      if (driverPos != null) pointsForBoundsCalculation.add(driverPos);

      double targetZoomLevel = 15.5; // زوم افتراضي جيد

      if (effectiveStatus == DeliveryTaskStatus.driver_assigned ||
          effectiveStatus == DeliveryTaskStatus.en_route_to_pickup) {
        targetDestinationForCamera = pickupTaskLatLng;
      } else if (effectiveStatus == DeliveryTaskStatus.picked_up_from_seller ||
          effectiveStatus == DeliveryTaskStatus.out_for_delivery_to_buyer ||
          effectiveStatus == DeliveryTaskStatus.at_buyer_location) {
        targetDestinationForCamera = deliveryTaskLatLng;
      }
      targetDestinationForCamera ??= driverPos ?? pickupTaskLatLng ?? deliveryTaskLatLng;


      if (targetDestinationForCamera != null) {
        // إضافة الوجهة لحساب الحدود فقط إذا لم تكن هي نفسها موقع السائق
        bool isSameLocation = false;
        if(driverPos != null){
          double distance = Geolocator.distanceBetween(
              driverPos.latitude, driverPos.longitude,
              targetDestinationForCamera.latitude, targetDestinationForCamera.longitude
          );
          if(distance < 50) { // إذا كان السائق قريب جدًا (أقل من 50 مترًا)
            isSameLocation = true;
            targetZoomLevel = 17.0; // زوم أقرب إذا وصل أو قريب جدًا
          }
        }
        if (!isSameLocation && !pointsForBoundsCalculation.any((p) =>
        p.latitude == targetDestinationForCamera!.latitude &&
            p.longitude == targetDestinationForCamera.longitude)) {
          pointsForBoundsCalculation.add(targetDestinationForCamera);
        }
      }


      if (pointsForBoundsCalculation.isEmpty && targetDestinationForCamera != null) {
        // حالة نادرة: لا يوجد موقع للسائق ولكن هناك وجهة (مثلاً مهمة معينة بدون سائق)
        googleMapController!.animateCamera(CameraUpdate.newLatLngZoom(targetDestinationForCamera, 13.0));
        debugPrint("[NAV_CTRL_MAP] Animating to target destination only: $targetDestinationForCamera");
      } else if (pointsForBoundsCalculation.isEmpty) {
        debugPrint("[NAV_CTRL_MAP] No points to focus camera for task ${currentTask.taskId}.");
      } else if (pointsForBoundsCalculation.length == 1 || pointsForBoundsCalculation.toSet().length == 1) {
        // هذا يحدث إذا كان السائق هو النقطة الوحيدة، أو إذا كانت كل النقاط متطابقة (السائق عند الوجهة)
        googleMapController!.animateCamera(CameraUpdate.newLatLngZoom(pointsForBoundsCalculation.first, targetZoomLevel)); // استخدام targetZoomLevel
        debugPrint("[NAV_CTRL_MAP] Animating camera to single point: ${pointsForBoundsCalculation.first} with zoom $targetZoomLevel for task ${currentTask.taskId}.");
      } else { // أكثر من نقطة مختلفة
        try {
          LatLngBounds bounds = _boundsFromLatLngListForNav(pointsForBoundsCalculation);
          googleMapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80.0)); // padding للحدود
          debugPrint("[NAV_CTRL_MAP] Animating camera to bounds for ${pointsForBoundsCalculation.length} points for task ${currentTask.taskId}.");
        } catch (e) {
          debugPrint("[NAV_CTRL_MAP] Error fitting map to bounds for task ${currentTask.taskId}: $e. Zooming to primary target.");
          LatLng fallbackTarget = targetDestinationForCamera ?? (driverPos ?? pointsForBoundsCalculation.first);
          googleMapController!.animateCamera(CameraUpdate.newLatLngZoom(fallbackTarget, 15.0));
        }
      }
    }
    debugPrint("[NAV_CTRL_MAP] Map markers and camera state updated. Markers: ${mapMarkers.length}, Polylines: ${polylines.length} for task ${currentTask.taskId}");
  }


  void _fitMapToMarkersIfReady() {
    if (googleMapController != null && mapMarkers.isNotEmpty) {
      debugPrint("[NAV_CTRL_MAP_FIT] Fitting map to ${mapMarkers.length} markers for task ${taskDetails.value?.taskId}.");
      if (mapMarkers.length == 1) {
        googleMapController!.animateCamera(
            CameraUpdate.newLatLngZoom(mapMarkers.first.position, 16.5));
      } else {
        try {
          // --- التعديل الرئيسي هنا ---
          // 1. استخرج قائمة الـ LatLng من الماركرات
          final List<LatLng> markerPositions = mapMarkers.map((marker) => marker.position).toList();
          // 2. مرر هذه القائمة للدالة الموجودة لديك
          LatLngBounds bounds = _boundsFromLatLngListForNav(markerPositions);
          // --- نهاية التعديل ---
          googleMapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 75.0));
        } catch (e) {
          debugPrint("[NAV_CTRL_MAP_FIT] Error fitting map to bounds for task ${taskDetails.value?.taskId}: $e");
          if (mapMarkers.isNotEmpty) {
            googleMapController!.animateCamera(CameraUpdate.newLatLngZoom(mapMarkers.first.position, 15.0));
          }
        }
      }
    } else {
      debugPrint("[NAV_CTRL_MAP_FIT] Cannot fit map yet. MapCtrl: ${googleMapController!=null}, Markers: ${mapMarkers.length}");
    }
  }

  LatLngBounds _boundsFromLatLngListForNav(List<LatLng> points) { //  دالة حساب الحدود
    if (points.isEmpty) return LatLngBounds(southwest: LatLng(0,0), northeast: LatLng(0,0));
    double minLat = points.first.latitude, maxLat = points.first.latitude;
    double minLng = points.first.longitude, maxLng = points.first.longitude;
    for (LatLng point in points) {
      minLat = min(minLat, point.latitude); maxLat = max(maxLat, point.latitude);
      minLng = min(minLng, point.longitude); maxLng = max(maxLng, point.longitude);
    }
    if (minLat == maxLat) { maxLat = minLat + 0.005; minLat = minLat - 0.005;}
    if (minLng == maxLng) { maxLng = minLng + 0.005; minLng = minLng - 0.005;}
    return LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng));
  }


  // --- دوال أفعال السائق (مع مسح الباركود والتقاط الصور) ---
// In DeliveryNavigationController.dart

// ... (imports and other parts of the class)

// تأكد من أن لديك مسارًا مُعرفًا لهذه الشاشة في AppRoutes و GetMaterialApp
// مثال للمسار: static const String BARCODE_SCANNER_PAGE = '/barcode-scanner';
// وأن الـ Binding الخاص بها (إذا احتجت) لا يتعارض.

// In DeliveryNavigationController.dart

  Future<String?> scanBarcode(BuildContext contextForDialog, String purposeTitle) async {
    debugPrint("[NAV_CTRL] Requesting barcode scan for purpose: $purposeTitle");

    // المسار إلى شاشة المسح يجب أن يكون من AppRoutes
    final dynamic scanResult = await Get.toNamed(
        AppRoutes.BARCODE_SCANNER_PAGE, // <--- استخدام الثابت من AppRoutes
        arguments: {'purposeTitle': purposeTitle}
    );

    if (scanResult is String && scanResult.isNotEmpty) {
      debugPrint("[NAV_CTRL] Barcode scanned successfully: $scanResult");
      return scanResult;
    } else if (scanResult == null) {
      debugPrint("[NAV_CTRL] Barcode scanning cancelled or no result.");
      // لا تعرض Snackbar هنا، لأن شاشة المسح قد تكون أغلقت نفسها أو أن الإلغاء كان مقصودًا
      return null;
    } else {
      debugPrint("[NAV_CTRL] Barcode scanning returned unexpected result type: ${scanResult.runtimeType}");
      Get.snackbar("خطأ في المسح", "حدث خطأ غير متوقع أثناء مسح الباركود.", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red);
      return null;
    }
  }

// ... (imports and other parts of the class) ...
// تأكد من استيراد image_picker و dart:io
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';





  Future<void> reportUnexpectedDelay(BuildContext context) async {
    if (taskDetails.value == null || isLoadingAction.value) return;
    delayReasonController.clear();

    String? reason = await Get.defaultDialog<String>(
      title: "تسجيل تأخير غير متوقع",
      titleStyle: Get.textTheme.titleLarge,
      contentPadding: const EdgeInsets.all(20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("أدخل سبب التأخير (مثلاً: ازدحام مروري، مشكلة في المركبة). سيتم إبلاغ المشرف والمستلم.", textAlign: TextAlign.center),
          const SizedBox(height: 15),
          TextField(
            controller: delayReasonController, // استخدام المتحكم المُعرّف في الكلاس
            decoration: const InputDecoration(labelText: "سبب التأخير", border: OutlineInputBorder()),
            maxLines: 2,
            autofocus: true,
          ),
        ],
      ),
      confirm: ElevatedButton(
        onPressed: () => Get.back(result: delayReasonController.text.trim()),
        child: const Text("إرسال سبب التأخير"),
      ),
      cancel: TextButton(onPressed: () => Get.back(), child: const Text("إلغاء")),
    );

    if (reason != null && reason.isNotEmpty) {
      isLoadingAction.value = true;
      try {
        final String note = "${DateFormat('yy/MM/dd hh:mm a', 'ar').format(DateTime.now())}: أبلغ السائق (${driverProfile.value?.name ?? driverId}) عن تأخير. السبب: $reason";
        await _firestore.collection(FirebaseX.deliveryTasksCollection).doc(taskId).update({
          'taskNotesInternal': FieldValue.arrayUnion([note]),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        Get.snackbar("تم تسجيل التأخير", "تم إبلاغ الأطراف المعنية بسبب التأخير.", backgroundColor: Colors.orange.shade200, colorText: Colors.black87, duration: const Duration(seconds:3));
      } catch (e) {
        Get.snackbar("خطأ", "فشل تسجيل التأخير: $e", backgroundColor: Colors.red);
      } finally {
        isLoadingAction.value = false;
      }
    }
  }







  Future<void> pickDeliveryProofImage(ImageSource source, BuildContext contextForDialog) async { // أضفت context هنا
    debugPrint("[NAV_CTRL] Attempting to pick delivery proof image from $source...");
    // استخدام Dialog لعرض أيقونة كاميرا كبيرة مع خيار إلغاء أوضح
    bool? takePicture = await Get.dialog<bool>(
        AlertDialog(
          title: Text("إثبات التسليم", textAlign: TextAlign.center),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text("مطلوب التقاط صورة للبضاعة عند تسليمها للمشتري أو في مكان آمن متفق عليه.", textAlign: TextAlign.center, style:TextStyle(fontSize:13)),
            SizedBox(height:15),
            Icon(Icons.camera_alt_rounded, size: 60, color: Theme.of(contextForDialog).primaryColor), // استخدام السياق الممرر
          ]),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(onPressed: ()=> Get.back(result: false), child: Text("إلغاء")),
            ElevatedButton.icon(icon: Icon(Icons.camera), label:Text("التقاط صورة الآن"), onPressed: ()=> Get.back(result:true)),
          ],
        ),
        barrierDismissible: false
    );

    if (takePicture != true) {
      debugPrint("[NAV_CTRL] Image picking cancelled by user for delivery proof.");
      return; // المستخدم ألغى
    }


    try {
      final XFile? pickedImage = await _imagePicker.pickImage(
        source: source, // الكاميرا فقط هي المنطقية لإثبات التسليم الفوري
        imageQuality: 65, // جودة مقبولة
        maxWidth: 1200,   // حجم معقول
        maxHeight: 1200,
      );

      if (pickedImage != null) {
        pickedProofImageFile.value = File(pickedImage.path);
        debugPrint("[NAV_CTRL] Delivery proof image picked: ${pickedProofImageFile.value?.path}");
        // (لا يوجد snackbar هنا لأن الواجهة يجب أن تعرض الصورة وزر التأكيد)
      } else {
        debugPrint("[NAV_CTRL] Delivery proof image picking was cancelled or failed after dialog.");
        Get.snackbar("إلغاء", "تم إلغاء التقاط صورة إثبات التسليم.", snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      debugPrint("[NAV_CTRL] Error picking delivery proof image: $e");
      Get.snackbar("خطأ في الكاميرا", "فشل التقاط صورة الإثبات: $e", backgroundColor: Colors.red.shade400);
      pickedProofImageFile.value = null; // تأكد من مسحها عند الخطأ
    }
  }



  Future<String?> _uploadImageToStorage(File imageFile, String actionType) async {
    if (driverId == null) {
      debugPrint("Error: Driver ID is null. Cannot upload image.");
      return null;
    }
    // isLoadingAction.value = true; // يمكنك استخدام هذا إذا كان الرفع جزءًا من فعل رئيسي
    // أو متغير تحميل خاص بالصورة isUploadingProofImage
    isUploadingProofImage.value = true;

    try {
      final String imagePath = '${FirebaseX.driverStoragePath}/$driverId/task_proofs/$taskId/${actionType}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      debugPrint("[NAV_CTRL_UPLOAD] Uploading to: $imagePath");
      final ref = FirebaseStorage.instance.ref().child(imagePath); // <--- استخدام FirebaseStorage.instance هنا
      await ref.putFile(imageFile);
      final String downloadUrl = await ref.getDownloadURL();
      debugPrint("[NAV_CTRL_UPLOAD] Image uploaded successfully: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      debugPrint("[NAV_CTRL_UPLOAD] Error uploading image ($actionType): $e");
      Get.snackbar("خطأ في الرفع", "فشل تحميل صورة الإثبات. يرجى المحاولة مرة أخرى.", backgroundColor:Colors.red.shade300, duration: Duration(seconds: 4));
      return null;
    } finally {
      isUploadingProofImage.value = false;
      // isLoadingAction.value = false; // إذا كنت قد فعلته
    }
  }







// In DeliveryNavigationController.dart

  Future<void> confirmPickupFromSeller(BuildContext context) async {
    if (taskDetails.value == null || driverId == null) {
      Get.snackbar("غير مسموح", "بيانات المهمة أو السائق غير متوفرة لتأكيد الاستلام.");
      return;
    }
    final task = taskDetails.value!; // الآن يمكننا استخدام task بأمان
    final currentStatus = currentTaskStatus; // استخدام الـ getter

    if (!(currentStatus == DeliveryTaskStatus.driver_assigned || currentStatus == DeliveryTaskStatus.en_route_to_pickup)) {
      Get.snackbar("إجراء غير صالح", "لا يمكنك تأكيد الاستلام في هذه المرحلة (${deliveryTaskStatusToString(currentStatus).replaceAll('_', ' ')}).",
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // --- تحديد نوع جهة الاستلام (بائع عادي، مقر مصدر لميل أخير، مقر مصدر لنقل) ---
    // هذا يعتمد على كيفية تمييزك لهذه المهام. سنستخدم isHubToHubTransfer وحقل originHubName.
    String pickupEntityDisplayName = "";
    bool isPickupFromHub = false; // هل الاستلام من مقر؟

    if (task.isHubToHubTransfer == true) {
      pickupEntityDisplayName = task.originHubName ?? task.sellerName ?? "المقر المصدر (نقل)";
      isPickupFromHub = true;
    } else if (task.originHubName != null && task.originHubName!.isNotEmpty) { // مهمة ميل أخير مصدرها مقر
      pickupEntityDisplayName = task.originHubName ?? task.sellerName ?? "مقر الشركة (ميل أخير)";
      isPickupFromHub = true;
    } else { // بائع عادي
      pickupEntityDisplayName = task.sellerShopName ?? task.sellerName ?? "البائع";
      isPickupFromHub = false;
    }
    // ---------------------------------------------------------------------------


    bool allScanRequirementsMet = false; // سيُضبط إلى true إذا تم استيفاء شروط المسح

    // --- التحقق من الباركود الرئيسي (سواء من بائع أو باركود شحنة النقل/الطرد المجمع من المقر) ---
    if (task.sellerMainPickupConfirmationBarcode != null && task.sellerMainPickupConfirmationBarcode!.isNotEmpty) {
      // (الافتراض: الواجهة ستطلب من السائق مسح هذا الباركود أولاً إذا كان موجودًا)
      // هنا، يجب أن نتحقق إذا كان هذا الباركود "تم مسحه بنجاح" بالفعل.
      // لنفترض أن الواجهة تُحدِّث متغيرًا مؤقتًا في المتحكم عند نجاح مسح الباركود الرئيسي.
      // مثال: RxBool isMainPickupBarcodeScannedSuccessfullyForThisTask = false.obs;
      // في هذا المثال، سنجعلها تطلب المسح الآن إذا لم يكن قد تم.

      // للحفاظ على بساطة الدالة، سنفترض الآن أن الواجهة هي من تتعامل مع
      // مسح sellerMainPickupConfirmationBarcode وتُعلم المتحكم بنجاحه.
      // وإذا كان هذا هو الباركود الوحيد المطلوب، يمكن أن تستدعي الواجهة confirmPickupFromSeller مباشرة بعد نجاح مسحه.

      // **تعديل هنا: إذا كان هناك باركود رئيسي، يجب مسحه. لن نعتمد على scannedItems إذا وُجد باركود رئيسي.**
      String purposeTextForScan = isPickupFromHub
          ? "امسح باركود الشحنة من '$pickupEntityDisplayName'"
          : "امسح باركود تأكيد الاستلام من '$pickupEntityDisplayName'";
      String? scannedMainBarcode = await scanBarcode(context, purposeTextForScan);

      if (scannedMainBarcode == null || scannedMainBarcode.trim().toLowerCase() != task.sellerMainPickupConfirmationBarcode!.trim().toLowerCase()) {
        Get.snackbar(
            "باركود خاطئ",
            "الباركود الممسوح لا يتطابق مع الباركود المتوقع من $pickupEntityDisplayName. حاول مرة أخرى.",
            backgroundColor: Colors.red.shade300, duration: Duration(seconds: 4), snackPosition: SnackPosition.TOP
        );
        return; // أوقف العملية إذا كان الباركود الرئيسي مطلوبًا وخاطئًا
      }
      // إذا وصلنا هنا، فباركود الاستلام الرئيسي صحيح
      allScanRequirementsMet = true;
      if (itemsToPickupForCurrentTask.isNotEmpty && itemsToPickupForCurrentTask.first['itemBarcode'] == task.sellerMainPickupConfirmationBarcode) {
        // إذا كان الباركود الرئيسي هو نفسه باركود العنصر الوحيد (في حالة شحنة مجمعة مثلاً)
        itemsToPickupForCurrentTask.first['itemScannedByUserInterface'] = true;
        itemsToPickupForCurrentTask.first['actualScannedBarcode'] = scannedMainBarcode;
        scannnedItemsCount.value = 1;
      }
      Get.snackbar("تم التحقق", "باركود الاستلام من $pickupEntityDisplayName صحيح.", backgroundColor: Colors.green, duration: Duration(milliseconds: 1800));

    }
    // --- أو، إذا لم يكن هناك باركود رئيسي، تحقق من مسح المنتجات الفردية ---
    else if (totalItemsToScan.value > 0) {
      final totalRequired = totalItemsToScan.value;
      final totalActuallyScannedInSession = itemsToPickupForCurrentTask.where((item) => item['itemScannedByUserInterface'] == true).length;

      if (totalActuallyScannedInSession == 0) {
        Get.snackbar("لم يتم المسح", "الرجاء مسح باركودات المنتجات من $pickupEntityDisplayName أولاً.", backgroundColor: Colors.orange);
        return;
      }
      if (totalActuallyScannedInSession < totalRequired) {
        bool? continuePartial = await Get.defaultDialog<bool>(
          title: "استلام جزئي من $pickupEntityDisplayName؟",
          middleText: "لقد مسحت $totalActuallyScannedInSession من $totalRequired منتجات. هل تريد تأكيد استلام هذا العدد فقط؟",
          textConfirm: "نعم، تأكيد الجزئي", textCancel: "لا، أكمل المسح",
          confirmTextColor: Colors.white, buttonColor: Colors.orange.shade600,
        );
        if (continuePartial != true) return;
      }
      allScanRequirementsMet = true;
    }
    // --- أو، إذا لم يكن هناك أي باركودات مطلوبة (لا رئيسي ولا فردي) ---
    else {
      allScanRequirementsMet = true; // لا يوجد ما يتم مسحه، يمكن المتابعة
      debugPrint("[NAV_CTRL_PICKUP] No specific barcodes required for pickup from $pickupEntityDisplayName. Proceeding with confirmation.");
    }

    // --- إذا لم يتم استيفاء متطلبات المسح، لا تكمل ---
    if (!allScanRequirementsMet) {
      // يجب ألا يصل هنا إذا كانت الشروط أعلاه صحيحة
      debugPrint("[NAV_CTRL_PICKUP] Scan requirements not met. Aborting confirmPickupFromSeller.");
      return;
    }


    isLoadingAction.value = true;

    // تجهيز قائمة المنتجات المستلمة فعليًا للسجل
    List<Map<String, dynamic>> actualPickedItemsForRecord = [];
    if (task.sellerMainPickupConfirmationBarcode != null && task.sellerMainPickupConfirmationBarcode!.isNotEmpty && allScanRequirementsMet) {
      // إذا تم الاعتماد على باركود رئيسي واحد فقط
      actualPickedItemsForRecord.add({
        'itemName': task.itemsSummary?.firstOrNull?['itemName'] ?? "شحنة من $pickupEntityDisplayName",
        'itemBarcode': task.sellerMainPickupConfirmationBarcode, // الباركود الرئيسي الذي تم مسحه
        'quantityExpected': task.itemsSummary?.fold<int>(0, (sum,item) => sum + (item['quantity'] as int? ?? 1)) ?? 1, // الكمية الإجمالية إذا أمكن
        'quantityPickedUp': 1, // الباركود الرئيسي يمثل "وحدة" واحدة تم استلامها
      });
    } else { // إذا تم مسح منتجات فردية
      actualPickedItemsForRecord = itemsToPickupForCurrentTask
          .where((item) => item['itemScannedByUserInterface'] == true)
          .map((item) => {
        'itemId': item['itemId'],
        'itemName': item['itemName'],
        'itemBarcode': item['actualScannedBarcode'], // الباركود الذي مسحه السائق فعلاً
        'quantityExpected': item['quantity'],
        'quantityPickedUp': item['itemScannedByUserInterface'] == true ? item['quantity'] : 0,
      }).toList();
    }


    try {
      // --- تحديد الحالة التالية للمهمة ---
      DeliveryTaskStatus nextStatus;
      String logMessageAction;

      if (task.isHubToHubTransfer == true) {
        // إذا كانت مهمة نقل، بعد الاستلام من المقر المصدر، ستصبح...
        // picked_up_from_seller هي حالة عامة، أو يمكنك استخدام حالة أكثر تحديدًا.
        // سنستخدمها مؤقتًا، مع العلم أن الوجهة التالية ستكون المقر الآخر.
        nextStatus = DeliveryTaskStatus.picked_up_from_seller; // أو حالة مثل: en_route_to_destination_hub
        logMessageAction = "استلم شحنة النقل من المقر المصدر: $pickupEntityDisplayName.";
      } else { // ليست نقل بين المقرات (إما بائع عادي أو مقر لميل أخير)
        // بعد الاستلام، الواجهة ستعرض خيارات (للمشتري أو لمقر الشركة)
        // لذا، الحالة هنا هي ببساطة `picked_up_from_seller`.
        nextStatus = DeliveryTaskStatus.picked_up_from_seller;
        logMessageAction = "استلم ${actualPickedItemsForRecord.length} عناصر من $pickupEntityDisplayName.";
      }

      await _firestore.collection(FirebaseX.deliveryTasksCollection).doc(taskId).update({
        'status': deliveryTaskStatusToString(nextStatus),
        'actualPickupTime': FieldValue.serverTimestamp(),
        // فقط سجل itemsPickedUpByDriver إذا كان هناك بالفعل منتجات تم مسحها/تتبعها
        if (actualPickedItemsForRecord.isNotEmpty) 'itemsPickedUpByDriver': actualPickedItemsForRecord,
        'updatedAt': FieldValue.serverTimestamp(),
        'taskNotesInternal': FieldValue.arrayUnion([
          "${DateFormat('yy/MM/dd hh:mm a', 'ar').format(DateTime.now())}: "
              "السائق (${driverProfile.value?.name ?? driverId}) $logMessageAction"
        ])
      });

      Get.snackbar("تم الاستلام بنجاح!", "تم تأكيد استلامك للشحنة من $pickupEntityDisplayName.",
          backgroundColor: Colors.green.shade600, colorText: Colors.white, duration: Duration(seconds: 3), snackPosition: SnackPosition.TOP);

      startOrStopPickupItemScanningSession(false); // أغلق واجهة مسح المنتجات إذا كانت مفتوحة
      pickedProofImageFile.value = null;          // امسح أي صورة إثبات قديمة استعدادًا لعملية التسليم التالية
      _prepareItemsForPickup();                   // أعد تهيئة قائمة مسح المنتجات (لتكون فارغة للمهمة التالية)

      //  لا تحتاج لتحديث selectedHubForDropOff.value هنا لأن هذا خاص بالاستلام
      //  الـ stream لـ taskDetails سيُحدّث الواجهة تلقائيًا بالحالة الجديدة
      //  ودالة _updateMapAndCameraState ستُحدّث وجهة الخريطة والـ polyline

    } catch (e, s) {
      debugPrint("[NAV_CTRL_PICKUP] Error confirming pickup: $e\n$s");
      Get.snackbar("خطأ في التأكيد", "فشل تأكيد الاستلام: ${e.toString()}", backgroundColor: Colors.red.shade300, duration: Duration(seconds:4));
    } finally {
      isLoadingAction.value = false;
    }
  }

  void startOrStopBuyerConfirmationScanning(bool start) {
    isScanningBuyerConfirmation.value = start;
    pickedProofImageFile.value = null; // مسح أي صورة سابقة عند بدء جلسة تأكيد جديدة
    // إذا كان لديك MobileScannerController مدمج للتسليم، قم بتشغيله/إيقافه
    // if (start) deliveryScannerController.start(); else deliveryScannerController.stop();
  }



  Future<void> processScannedBuyerBarcode(String scannedCode, BuildContext contextForDialog) async {
    if (!isScanningBuyerConfirmation.value || taskDetails.value == null) return;

    // **تعديل:** الباركود المتوقع هو buyerId للمهمة الرئيسية (والذي يجب أن يكون نفسه لكل المهام المجمعة)
    final String expectedBuyerBarcode = taskDetails.value!.buyerId; // <--- الافتراض هنا
    // أو يمكنك استخدام: final String expectedBuyerBarcode = controller.consolidatedBuyerConfirmationBarcode.value;
    // إذا كنت قد خزنت الباركود المجمع في متغير منفصل.
    // إذا كنت تستخدم taskDetails.value!.buyerConfirmationBarcode، تأكد أنه مضبوط ليكون هو الـ buyerId عند التجميع.

    debugPrint("[NAV_CTRL] Buyer code scanned: $scannedCode, Expected (based on main task buyerId): $expectedBuyerBarcode");

    if (scannedCode.trim().toLowerCase() != expectedBuyerBarcode.trim().toLowerCase()) {
      Get.snackbar("باركود خاطئ", "باركود تأكيد المشتري غير صحيح. يرجى المحاولة مرة أخرى.", backgroundColor: Colors.red, duration: Duration(seconds: 4), snackPosition: SnackPosition.TOP);
      return;
    }

    Get.snackbar("نجاح!", "باركود المشتري صحيح. الرجاء الآن التقاط صورة إثبات التسليم.", backgroundColor: Colors.blue.shade600, colorText: Colors.white, duration: Duration(seconds: 3), snackPosition: SnackPosition.TOP);
    await pickDeliveryProofImage(ImageSource.camera, contextForDialog);
  }





  Future<void> confirmArrivalAtBuyerLocation() async {
    if (taskDetails.value == null || driverId == null || driverId!.isEmpty) {
      Get.snackbar("خطأ", "لا يمكن إكمال الإجراء، بيانات المهمة أو السائق غير متوفرة.", snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // تحقق من أن السائق في المرحلة المناسبة (أي أنه استلم الطلب وهو في طريقه للمشتري)
    final currentStatus = currentTaskStatus; //  استخدام الـ getter
    if (!(currentStatus == DeliveryTaskStatus.out_for_delivery_to_buyer ||
        currentStatus == DeliveryTaskStatus.picked_up_from_seller)) { // قد ينتقل من picked_up مباشرة إلى at_buyer إذا لم تكن هناك مرحلة "out_for_delivery"
      Get.snackbar("إجراء غير صالح", "لا يمكنك تأكيد الوصول للمشتري في هذه المرحلة من المهمة (${deliveryTaskStatusToString(currentStatus).replaceAll('_', ' ')}).", snackPosition: SnackPosition.BOTTOM);
      return;
    }

    isLoadingAction.value = true; // مؤشر تحميل للفعل
    debugPrint("[NAV_CTRL] Driver $driverId confirming arrival at buyer location for task ${taskDetails.value!.taskId}.");

    try {
      await _firestore.collection(FirebaseX.deliveryTasksCollection).doc(taskId).update({
        'status': deliveryTaskStatusToString(DeliveryTaskStatus.at_buyer_location),
        'updatedAt': FieldValue.serverTimestamp(),
        'taskNotesInternal': FieldValue.arrayUnion([
          "${DateFormat('yyyy/MM/dd hh:mm a', 'ar').format(DateTime.now())}: السائق ($driverId) وصل إلى موقع المشتري."
        ])
      });

      //  الـ listener في _subscribeToTaskDetails سيقوم بتحديث taskDetails.value و currentEffectiveStatus
      //  وبالتالي الواجهة يجب أن تتغير لتعرض أزرار "تأكيد التسليم" و "الإبلاغ عن مشكلة".

      Get.snackbar(
          "تم الوصول بنجاح",
          "تم تسجيل وصولك لموقع المشتري. يرجى الآن تأكيد التسليم.",
          backgroundColor: Colors.blue.shade600,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          snackPosition: SnackPosition.TOP // TOP ليكون ظاهرًا فوق أي أزرار سفلية
      );

      // (اختياري) إرسال إشعار للمشتري بأن السائق قد وصل
      // if (taskDetails.value?.buyerId != null && taskDetails.value!.buyerId.isNotEmpty) {
      //   DocumentSnapshot buyerDoc = await _firestore.collection(FirebaseX.usersCollection).doc(taskDetails.value!.buyerId).get();
      //   if (buyerDoc.exists && buyerDoc.data() != null) {
      //     String? buyerToken = (buyerDoc.data() as Map<String,dynamic>)['fcmToken'];
      //     if (buyerToken != null && buyerToken.isNotEmpty) {
      //       // await NotificationService.sendFcmNotification(
      //       //   token: buyerToken,
      //       //   title: "السائق بالخارج!",
      //       //   body: "سائق التوصيل لطلبك #${taskDetails.value!.orderIdShort} قد وصل إلى موقعك.",
      //       //   data: {'taskId': taskId, 'screen': '/order_tracking_buyer'} // مثال لبيانات إضافية
      //       // );
      //        debugPrint("SIMULATING: Notify buyer ${taskDetails.value!.buyerId} that driver has arrived for task $taskId.");
      //     }
      //   }
      // }

    } catch (e, s) {
      debugPrint("[NAV_CTRL] Error confirming arrival at buyer: $e\n$s");
      Get.snackbar("خطأ", "فشل تحديث حالة الوصول: ${e.toString()}", backgroundColor: Colors.red.shade400);
    } finally {
      isLoadingAction.value = false;
    }
  }




  Future<void> finalizeCurrentStageDelivery(BuildContext context, {String? scannedConfirmationCode}) async {
    final task = taskDetails.value;
    if (task == null || driverId == null) {
      Get.snackbar("خطأ", "بيانات المهمة أو السائق غير متوفرة لإنهاء المرحلة.", snackPosition: SnackPosition.TOP);
      return;
    }

    // --- تحديد نوع المرحلة (تسليم لمشترٍ أم لمقر وجهة) ---
    final bool isFinalDeliveryToBuyer = !task.isHubToHubTransfer && (task.status == DeliveryTaskStatus.at_buyer_location);
    final bool isFinalDropOffAtDestinationHub = task.isHubToHubTransfer && (task.status == DeliveryTaskStatus.at_buyer_location); // 'at_buyer_location' يُستخدم هنا للمقر الوجهة

    if (!isFinalDeliveryToBuyer && !isFinalDropOffAtDestinationHub) {
      Get.snackbar("إجراء غير متوقع", "لا يمكن إنهاء المهمة من هذه الحالة (${deliveryTaskStatusToString(task.status)}).",
          snackPosition: SnackPosition.TOP, backgroundColor: Colors.orange);
      return;
    }

    // --- 1. التحقق من باركود التأكيد ---
    String expectedConfirmationCode = "";
    String entityBeingConfirmed = "";

    if (isFinalDeliveryToBuyer) {
      expectedConfirmationCode = task.buyerConfirmationBarcode ?? task.buyerId; // باركود المشتري
      entityBeingConfirmed = "المشتري '${task.buyerName ?? task.buyerId}'";
    } else if (isFinalDropOffAtDestinationHub) {
      expectedConfirmationCode = task.buyerConfirmationBarcode ?? ""; // الذي هو hubConfirmationBarcode للمقر الوجهة
      entityBeingConfirmed = "المقر الوجهة '${task.destinationHubName ?? task.buyerName}'";
      if (expectedConfirmationCode.isEmpty) {
        Get.snackbar("خطأ تكوين", "لم يتم تحديد باركود تأكيد للمقر الوجهة لهذه المهمة.",
            backgroundColor: Colors.orange.shade400, snackPosition: SnackPosition.TOP, duration: Duration(seconds: 5));
        return;
      }
    }

    // إذا لم يتم تمرير باركود ممسوح، اطلب من المستخدم مسحه الآن
    String? currentScannedCode = scannedConfirmationCode;
    if (currentScannedCode == null || currentScannedCode.isEmpty) {
      currentScannedCode = await scanBarcode(context, "امسح باركود تأكيد استلام $entityBeingConfirmed");
      if (currentScannedCode == null || currentScannedCode.isEmpty) {
        Get.snackbar("إلغاء", "تم إلغاء مسح باركود التأكيد.", snackPosition: SnackPosition.TOP);
        return; // المستخدم ألغى
      }
    }

    if (currentScannedCode.trim().toLowerCase() != expectedConfirmationCode.trim().toLowerCase()) {
      Get.snackbar("باركود خاطئ!", "الباركود الممسوح لا يتطابق مع الباركود المتوقع لـ $entityBeingConfirmed.",
          backgroundColor: Colors.red.shade300, snackPosition: SnackPosition.TOP, duration: Duration(seconds: 5));
      return;
    }
    // --- نهاية التحقق من الباركود ---


    // --- 2. التقاط/التحقق من صورة الإثبات ---
    bool requireProofImage = isFinalDeliveryToBuyer; // إلزامية للمشتري
    bool allowSkipProofForHub = !isFinalDeliveryToBuyer; // يمكن تخطيها للمقر (حسب سياستك)

    if (pickedProofImageFile.value == null && requireProofImage) {
      Get.snackbar("صورة مطلوبة", "الرجاء التقاط صورة كإثبات للتسليم قبل التأكيد.",
          backgroundColor: Colors.orange, duration: Duration(seconds: 4), snackPosition: SnackPosition.TOP);
      await pickDeliveryProofImage(ImageSource.camera, context);
      if (pickedProofImageFile.value == null) return; // إذا ألغى المستخدم
    } else if (pickedProofImageFile.value == null && allowSkipProofForHub) {
      bool? userChoseToTakePicForHub = await Get.defaultDialog<bool>( // <--- تم تغيير اسم المتغير هنا
          title: "صورة إثبات (مستحسن)",
          middleText: "هل ترغب بالتقاط صورة للشحنة كإثبات لتسليمها لـ $entityBeingConfirmed؟",
          textConfirm: "التقاط صورة",
          textCancel: "تخطي الصورة"
      );
      if(userChoseToTakePicForHub == true) {
        await pickDeliveryProofImage(ImageSource.camera, context);
        // لا تحتاج للتحقق من null هنا، سيتم التحقق قبل الرفع
      }
    }
    // --- نهاية قسم صورة الإثبات ---


    isLoadingAction.value = true;
    isUploadingProofImage.value = (pickedProofImageFile.value != null); // حالة تحميل الصورة
    String? proofUrl;

    try {
      if (pickedProofImageFile.value != null) {
        String imagePathSuffix = isFinalDeliveryToBuyer
            ? "delivery_success_proof_${task.taskId}"
            : "hub_transfer_arrival_proof_${task.buyerId}_${task.taskId}"; // task.buyerId هنا هو hubId للمقر الوجهة
        proofUrl = await _uploadImageToStorage(pickedProofImageFile.value!, imagePathSuffix);

        if (proofUrl == null) { // فشل الرفع
          isUploadingProofImage.value = false; // تأكد من إيقاف تحميل الصورة
          //isLoadingAction.value = false; // لا توقف التحميل الرئيسي بعد، فقط تحميل الصورة
          bool? continueWithoutPic = await Get.defaultDialog(title:"فشل رفع الصورة", middleText:"فشل تحميل صورة الإثبات. هل تريد المتابعة بدونها؟", textConfirm:"متابعة بدون صورة", textCancel:"إلغاء المحاولة");
          if(continueWithoutPic != true){
            isLoadingAction.value = false; // أوقف التحميل الرئيسي إذا ألغى
            return;
          }
        }
        isUploadingProofImage.value = false; // تم الانتهاء من محاولة الرفع
      }

      // --- 3. تحديث Firestore داخل معاملة ---
      final String finalTaskStatusString = deliveryTaskStatusToString(DeliveryTaskStatus.delivered); // حالة نهائية موحدة (أو مخصصة)
      String noteActionText = isFinalDeliveryToBuyer ? "تسليم الطلب للمشتري بنجاح" : "وصول شحنة النقل للمقر الوجهة";

      await _firestore.runTransaction((transaction) async {
        DocumentReference taskRef = _firestore.collection(FirebaseX.deliveryTasksCollection).doc(taskId);
        DocumentReference driverRef = _firestore.collection(FirebaseX.deliveryDriversCollection).doc(driverId!);

        // حساب المسافة المقطوعة للمهمة
        double? distanceKm;
        if (task.pickupLocationGeoPoint != null && task.deliveryLocationGeoPoint != null) {
          distanceKm = Geolocator.distanceBetween(
              task.pickupLocationGeoPoint!.latitude, task.pickupLocationGeoPoint!.longitude,
              task.deliveryLocationGeoPoint!.latitude, task.deliveryLocationGeoPoint!.longitude
          ) / 1000.0;
        }

        // --- الجزء المشترك بين الحالتين ---
        Map<String, dynamic> taskUpdateData = {
          'status': finalTaskStatusString,
          'deliveryConfirmationTime': FieldValue.serverTimestamp(), // هذا الوقت يمثل اكتمال المرحلة
          'updatedAt': FieldValue.serverTimestamp(),
          if (proofUrl != null) 'deliveryProofImageUrl': proofUrl,
          if (distanceKm != null) 'distanceTravelledKm': distanceKm, // يسجل للمهمة نفسها
          'taskNotesInternal': FieldValue.arrayUnion([
            "${DateFormat('yy/MM/dd hh:mm a','ar').format(DateTime.now())}: $noteActionText لـ '$entityBeingConfirmed'. تم التأكيد بالباركود. ${proofUrl != null ? 'صورة إثبات مرفقة.' : ''}"
          ]),
        };
        //  إذا كانت نقل بين المقرات، قد لا يكون هناك buyerConfirmationCode يتم تسجيله في المهمة
        // if (isFinalDeliveryToBuyer) {
        //   taskUpdateData['deliveryConfirmationCode'] = currentScannedCode;
        // }
        transaction.update(taskRef, taskUpdateData);


        // --- تحديث ملف السائق (مشترك) ---
        Map<String, dynamic> driverUpdate = {
          'currentFocusedTaskId': FieldValue.delete(),
          'availabilityStatus': "online_available",
          'updatedAt': FieldValue.serverTimestamp(),
        };
        // (إذا كنت تريد إحصائيات منفصلة للمهام المنقولة للمقر مقابل المهام المسلمة للمشتري، أضفها هنا)
        if(isFinalDeliveryToBuyer){
          driverUpdate['totalCompletedTasks'] = FieldValue.increment(currentConsolidatedTasks.isNotEmpty ? currentConsolidatedTasks.length : 1);
          driverUpdate['totalEarnings'] = FieldValue.increment(currentConsolidatedTasks.isNotEmpty ? currentConsolidatedTasks.fold(0.0, (sum, t) => sum + (t.deliveryFee ?? 0.0) ) : (task.deliveryFee ?? 0.0) );
        } else if (isFinalDropOffAtDestinationHub){
          // يمكنك إضافة حقل مثل 'totalHubTransfersCompleted' إذا أردت
          // driverUpdate['totalHubTransfersCompleted'] = FieldValue.increment(1);
          // الأرباح لمهمة النقل قد تكون مختلفة
          // driverUpdate['totalEarnings'] = FieldValue.increment(task.deliveryFeeForHubTransfer ?? task.deliveryFee ?? 0.0);
          // للتبسيط الآن، نعتبرها كمهمة مكتملة عادية من ناحية العدادات الأساسية
          driverUpdate['totalCompletedTasks'] = FieldValue.increment(1); // افترض أن مهمة النقل تُحتسب
          driverUpdate['totalEarnings'] = FieldValue.increment(task.deliveryFee ?? 0.0);
        }
        transaction.update(driverRef, driverUpdate);


        // --- **جديد: تحديث المهام المجمعة إذا كان هذا تسليمًا عاديًا للمشتري** ---
        if (isFinalDeliveryToBuyer && isConsolidatedDeliveryMode.value && currentConsolidatedTasks.isNotEmpty) {
          double totalFeesForThisBatch = 0;
          // تأكد من أن currentConsolidatedTasks تحتوي فقط على المهام التي سيتم تسليمها الآن
          // المهام الأصلية التي تم تجميعها لتشكيل مهمة النقل، لا تُحدّث هنا
          // بل مهمة النقل نفسها هي التي تتغير حالتها

          //  في هذا السياق المدمج، إذا كانت isFinalDeliveryToBuyer = true، فهذا يعني أن
          //  currentConsolidatedTasks هي قائمة الطلبات التي تُسلم *للمشتري*.
          for (var taskToUpdate in currentConsolidatedTasks) {
            if(taskToUpdate.taskId == taskId) continue; // المهمة الرئيسية تم تحديثها بالفعل
            DocumentReference conTaskRef = _firestore.collection(FirebaseX.deliveryTasksCollection).doc(taskToUpdate.taskId);
            transaction.update(conTaskRef, {
              'status': finalTaskStatusString, // نفس الحالة النهائية
              'deliveryConfirmationTime': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
              'deliveryProofImageUrl': proofUrl, // نفس الصورة
              'taskNotesInternal': FieldValue.arrayUnion([
                "${DateFormat('yy/MM/dd hh:mm a','ar').format(DateTime.now())}: تم تسليمها كجزء من دفعة مجمعة ($taskId) للمشتري ${taskToUpdate.buyerName ?? taskToUpdate.buyerId}."
              ]),
            });
            totalFeesForThisBatch += taskToUpdate.deliveryFee ?? 0.0; // لتحديث إحصائيات السائق بشكل أدق
          }
          // لا حاجة لتحديث totalEarnings هنا مرة أخرى لأنها تُجمع بناءً على currentConsolidatedTasks
        }
        // --- نهاية تحديث المهام المجمعة ---


      }); // --- نهاية المعاملة ---

      // تنظيف بعد النجاح
      pickedProofImageFile.value = null;
      isScanningBuyerConfirmation.value = false; // أغلق وضع المسح (أو التأكيد)

      String successMessage = isFinalDeliveryToBuyer
          ? (isConsolidatedDeliveryMode.value && currentConsolidatedTasks.length > 1
          ? "تم تسجيل تسليم ${currentConsolidatedTasks.length} طلبات للمشتري بنجاح."
          : "تم تسجيل تسليم الطلب للمشتري بنجاح.")
          : "تم تأكيد وصول وتسليم الشحنة بنجاح إلى المقر الوجهة '${task.destinationHubName ?? task.buyerName}'.";

      Get.snackbar("تم بنجاح!", successMessage,
          backgroundColor: Colors.green.shade600, colorText: Colors.white,
          duration: const Duration(seconds: 4), snackPosition: SnackPosition.TOP);

      // اشتراك _taskDetailsSubscription سيلتقط تغيير الحالة
      // ودالة handleTaskNoLongerActiveNavigation ستُغلق الشاشة.

    } catch (e,s) {
      debugPrint("[NAV_CTRL_FINALIZE_DELIVERY] Error: $e\n$s");
      Get.snackbar("خطأ فادح", "فشل إتمام العملية: ${e.toString()}",
          backgroundColor:Colors.red.shade700, duration: const Duration(seconds: 5), snackPosition: SnackPosition.TOP);
    } finally {
      isLoadingAction.value = false;
      isUploadingProofImage.value = false;
    }
  }


  Future<bool> _processDeliveryFailure(String reason, File? issueImageFile) async { // <--- تغيير هنا: Future<void> إلى Future<bool>
    // isLoadingAction.value تم تعيينها true في reportDeliveryIssue قبل استدعاء هذه
    debugPrint("[NAV_CTRL] Processing delivery failure for task $taskId. Reason: $reason");
    String? issueImageUrl;
    // لا تعيّن isLoadingAction.value = true هنا مرة أخرى، فقد تم تعيينها في reportDeliveryIssue
    // إذا كنت تريد أن تكون هذه الدالة مستقلة تمامًا، يمكنك إضافة:
    // final prevIsLoadingAction = isLoadingAction.value; // احفظ الحالة السابقة
    // isLoadingAction.value = true;

    if (issueImageFile != null) {
      // يجب أن تكون isUploadingProofImage خاصة بعملية رفع الصورة هذه إذا أردت مؤشرًا منفصلاً
      final prevIsUploading = isUploadingProofImage.value; // حفظ الحالة
      isUploadingProofImage.value = true;
      try {
        issueImageUrl = await _uploadImageToStorage(issueImageFile, "delivery_issue_proof_$taskId"); // اسم ملف فريد
        if (issueImageUrl == null) { // إذا فشل الرفع وكانت هناك صورة
          debugPrint("[NAV_CTRL] Failed to upload issue image for failure report. Will proceed without it.");
          // لا توقف العملية، ولكن اعلم المستخدم إذا أردت
          // Get.snackbar("تنبيه", "فشل تحميل صورة المشكلة، سيتم إرسال البلاغ بدونها.");
        }
      } catch (e) {
        debugPrint("[NAV_CTRL] Exception during issue image upload for failure: $e");
        // يمكنك أيضًا إظهار snackbar هنا للمستخدم
      } finally {
        isUploadingProofImage.value = prevIsUploading; // أعدها للحالة السابقة
      }
    }

    try {
      await _firestore.runTransaction((transaction) async {
        DocumentReference taskRef = _firestore.collection(FirebaseX.deliveryTasksCollection).doc(taskId);
        DocumentReference driverRef = _firestore.collection(FirebaseX.deliveryDriversCollection).doc(driverId!);

        Map<String, dynamic> taskUpdateData = {
          'status': deliveryTaskStatusToString(DeliveryTaskStatus.delivery_failed), // حالة فشل التسليم
          'updatedAt': FieldValue.serverTimestamp(),
          'failureOrCancellationReason': reason, // السبب الذي أدخله السائق
          if (issueImageUrl != null) 'deliveryProofImageUrl': issueImageUrl, // يمكن إعادة استخدام هذا الحقل أو حقل مخصص
          // امسح أي معلومات تسليم ناجح سابقة إذا كانت موجودة (نادر ولكن للاحتياط)
          'deliveryConfirmationTime': FieldValue.delete(),
          'deliveryConfirmationCode': FieldValue.delete(),
          'taskNotesInternal': FieldValue.arrayUnion([
            "${DateFormat('yyyy/MM/dd hh:mm a', 'ar').format(DateTime.now())}: "
                "أبلغ السائق ($driverId) عن فشل في التسليم. السبب: $reason. "
                "${issueImageUrl != null ? 'صورة للمشكلة مرفقة.' : 'بدون صورة مرفقة للمشكلة.'}"
          ]),
        };
        transaction.update(taskRef, taskUpdateData);

        // إعادة السائق إلى حالة متوفر ومسح المهمة الحالية لديه
        // هذا يعتمد على سياسة العمل. هل فشل التسليم يعني أن السائق أصبح متاحًا فورًا؟
        // أم أن المهمة لا تزال "معه" بشكل ما وتحتاج لإجراء آخر (مثل العودة للبائع)؟
        // للتبسيط الآن، سنجعله متاحًا.
        transaction.update(driverRef, {
          'currentFocusedTaskId': FieldValue.delete(),
          'availabilityStatus': "online_available",
          'updatedAt': FieldValue.serverTimestamp()
        });
      });

      // handleTaskNoLongerActiveNavigation سيتم استدعاؤها بواسطة listener على المهمة
      // عندما تتغير الحالة إلى delivery_failed، والتي ستغلق الشاشة وتعرض رسالة.
      // ولكن يمكننا عرض Snackbar فوري هنا أيضًا.
      Get.snackbar("تم إرسال البلاغ بنجاح",
          "تم تسجيل بلاغ المشكلة للمهمة #${taskDetails.value?.orderIdShort ?? taskId}. سيتم مراجعة الأمر من قبل الإدارة.",
          backgroundColor: Colors.orange.shade700, colorText: Colors.white,
          duration: const Duration(seconds: 4), snackPosition: SnackPosition.TOP);

      //isLoadingAction.value = prevIsLoadingAction; // أعدها للحالة السابقة (أو false مباشرة)
      isLoadingAction.value = false; // بما أن العملية انتهت
      return true; // <--- أرجع true عند النجاح

    } catch (e, s) {
      debugPrint("[NAV_CTRL] Error processing delivery failure in transaction: $e\n$s");
      Get.snackbar("خطأ فادح في الإبلاغ", "فشل الإبلاغ عن المشكلة بشكل كامل: ${e.toString()}",
          backgroundColor: Colors.red.shade400, duration: const Duration(seconds: 5), snackPosition: SnackPosition.TOP);
      //isLoadingAction.value = prevIsLoadingAction; // أعدها
      isLoadingAction.value = false;
      return false; // <--- أرجع false عند الفشل
    }
  }




  Future<void> reportDeliveryIssue(BuildContext context) async { // context هنا هو سياق الشاشة الرئيسية
    if (taskDetails.value == null || driverId == null) {
      Get.snackbar("خطأ", "بيانات المهمة أو السائق غير متوفرة للإبلاغ عن مشكلة.", snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (!_isTaskStillActiveForDriverNavigation(currentTaskStatus)) {
      Get.snackbar("إجراء غير متاح", "لا يمكن الإبلاغ عن مشكلة لهذه المهمة لأنها في حالة نهائية.", snackPosition: SnackPosition.BOTTOM);
      return;
    }

    _issueReasonController.clear();
    selectedIssueTypeKey.value = null; // امسح الاختيار السابق لنوع المشكلة
    pickedProofImageFile.value = null; // امسح أي صورة سابقة
    bool reportActuallySubmitted = false; // لتتبع ما إذا تم الضغط على "إرسال البلاغ"

    await Get.bottomSheet(
      StatefulBuilder( // StatefulBuilder لتحديث الـ UI داخل الـ BottomSheet بشكل مستقل
        builder: (BuildContext sheetContext, StateSetter setStateSheet) { // sheetContext هو للسياق داخل الـ BottomSheet
          return Container(
            padding: EdgeInsets.only(
                left: 20, right: 20, top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20
            ),
            decoration: BoxDecoration(
                color: Theme.of(sheetContext).cardColor, // استخدم sheetContext للثيم داخل BottomSheet
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(25.0), topRight: Radius.circular(25.0))),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text("الإبلاغ عن مشكلة في التسليم", style: Get.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  Text("المهمة للطلب: ${taskDetails.value!.orderIdShort}", style: Get.textTheme.bodyMedium, textAlign: TextAlign.center),
                  const Divider(height: 25),

                  Text("اختر نوع المشكلة:*", style: Get.textTheme.titleSmall), // إضافة * للإشارة للإلزامي
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedIssueTypeKey.value, // استخدام القيمة من المتحكم
                    hint: const Text("حدد نوع المشكلة من القائمة"),
                    isExpanded: true,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: commonIssueTypes.map((issue) {
                      return DropdownMenuItem<String>(
                        value: issue['key'],
                        child: Text(issue['display']!, style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      // استخدام setStateSheet لتحديث الـ UI داخل الـ BottomSheet
                      setStateSheet(() {
                        selectedIssueTypeKey.value = newValue;
                      });
                    },
                    validator: (value) => (value == null) ? "يرجى تحديد نوع المشكلة" : null,
                  ),
                  const SizedBox(height: 15),

                  // حقل الوصف، يظهر دائما بعد اختيار نوع المشكلة (أو إذا كان النوع "أخرى")
                  // تم تعديل Obx هنا ليراقب selectedIssueTypeKey.value بشكل صحيح
                  Obx(() {
                    if (selectedIssueTypeKey.value != null) {
                      return Padding( // إضافة Padding
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: TextFormField(
                          controller: _issueReasonController,
                          decoration: InputDecoration(
                            labelText: selectedIssueTypeKey.value == 'other'
                                ? "يرجى توضيح المشكلة الأخرى*" // إلزامي إذا كان "أخرى"
                                : "ملاحظات إضافية (اختياري)",
                            hintText: "صف المشكلة بتفصيل أكثر إذا لزم الأمر...",
                            border: const OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          maxLines: 3, minLines: 1,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),


                  // قسم إرفاق الصورة
                  // استخدام Obx لمراقبة pickedProofImageFile من المتحكم
                  Obx(() => pickedProofImageFile.value == null
                      ? OutlinedButton.icon(
                      icon: const Icon(Icons.camera_alt_outlined, size: 20),
                      label: const Text("إرفاق صورة للمشكلة (اختياري)"),
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12)),
                      onPressed: () async {
                        // استدعاء الدالة الصحيحة من المتحكم
                        await pickDeliveryProofImage(ImageSource.camera, sheetContext);
                        // Obx سيقوم بإعادة بناء هذا الجزء تلقائيًا
                        // يمكن إضافة setStateSheet(() {}); هنا إذا أردت تحديثًا فوريًا جدًا داخل BottomSheet
                        // ولكن pickedProofImageFile.value كونه Rx يجب أن يشغل Obx
                        setStateSheet((){}); //  إضافة للتأكيد
                      })
                      : Column(
                    children: [
                      const Text("صورة المشكلة:", style:TextStyle(fontSize:12, color:Colors.grey)),
                      const SizedBox(height:5),
                      Image.file(pickedProofImageFile.value!, height: 100, fit: BoxFit.contain),
                      TextButton(
                          child: const Text("إزالة الصورة", style:TextStyle(color:Colors.redAccent, fontSize:11)),
                          onPressed: (){
                            pickedProofImageFile.value = null;
                            setStateSheet((){}); //  تحديث واجهة BottomSheet
                          })
                    ],
                  )),
                  const SizedBox(height: 25),

                  Obx(() => isLoadingAction.value
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                    icon: const Icon(Icons.report_gmailerrorred_rounded),
                    label: const Text("إرسال البلاغ وتحديث الحالة"),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      if (selectedIssueTypeKey.value == null) {
                        Get.snackbar("مطلوب", "يرجى تحديد نوع المشكلة من القائمة.", snackPosition: SnackPosition.TOP, backgroundColor:Colors.orange.shade300);
                        return;
                      }
                      if (selectedIssueTypeKey.value == 'other' && _issueReasonController.text.trim().isEmpty) {
                        Get.snackbar("مطلوب", "يرجى توضيح المشكلة الأخرى في حقل الملاحظات.", snackPosition: SnackPosition.TOP, backgroundColor:Colors.orange.shade300);
                        return;
                      }
                      // لا تغلق الـ BottomSheet من هنا بالضرورة، دع _processDeliveryFailure تقرر
                      // Get.back();
                      String issueDisplay = commonIssueTypes.firstWhereOrNull((i) => i['key'] == selectedIssueTypeKey.value)?['display'] ?? selectedIssueTypeKey.value!;
                      String finalReason = selectedIssueTypeKey.value == 'other'
                          ? _issueReasonController.text.trim()
                          : "$issueDisplay${_issueReasonController.text.trim().isNotEmpty ? ' - ملاحظة: ${_issueReasonController.text.trim()}' : ''}";

                      // تمرير سياق الشاشة الأصلي (context) وليس sheetContext إذا كانت _processDeliveryFailure
                      // تحتاج لعرض Snackbars على مستوى الشاشة كلها بعد إغلاق BottomSheet.
                      // أو يمكنك إغلاق BottomSheet داخل _processDeliveryFailure بعد إكمالها.
                      // الخيار الأفضل هو أن _processDeliveryFailure لا تغلق أي شيء، وهذه الدالة هي من تغلق BottomSheet.

                      bool success = await _processDeliveryFailure(finalReason, pickedProofImageFile.value); // افترض أن هذه الدالة تعيد bool للنجاح
                      if(success){
                        reportActuallySubmitted = true; // للإشارة إلى أننا حاولنا الإرسال
                        Get.back(); // أغلق الـ BottomSheet فقط في حالة نجاح المعالجة الكاملة
                      }
                      // إذا لم تنجح، الـ Snackbar من _processDeliveryFailure سيظهر، ويمكن إبقاء BottomSheet مفتوحًا
                      // أو يمكن إغلاقه أيضًا مع رسالة خطأ. حسب تفضيلك.
                    },
                  )),
                  TextButton(
                      onPressed: () => Get.back(), // فقط إغلاق الـ BottomSheet
                      child: const Text("تراجع / إلغاء البلاغ")),
                ],
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 5,
    );

    // بعد إغلاق الـ BottomSheet
    if (!reportActuallySubmitted) {
      debugPrint("Report delivery issue dialog closed without submission.");
      // إعادة تعيين المتغيرات هنا فقط إذا لم يتم الضغط على "إرسال البلاغ" بنجاح
      selectedIssueTypeKey.value = null;
      _issueReasonController.clear();
      pickedProofImageFile.value = null;
    } else {
      debugPrint("Report delivery issue dialog submitted or processing handled by _processDeliveryFailure.");
      //  لا تمسح القيم هنا إذا كانت _processDeliveryFailure ستفعل ذلك أو إذا كنت تريدها أن تبقى
      //  حتى التحديث التالي من الـ stream. مسحها في بداية الدالة عند الفتح القادم أفضل.
    }
  }




  // --- دوال الملاحة والاتصال ---
  Future<void> launchNavigationToPickup() async {
    if (taskDetails.value == null || taskDetails.value!.pickupLocationGeoPoint == null) {
      Get.snackbar(
        "خطأ في الوجهة",
        "موقع الاستلام (البائع) غير محدد لهذه المهمة.",
        backgroundColor: Colors.orange.shade300,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final GeoPoint? pickupGeoPoint = taskDetails.value!.pickupLocationGeoPoint;
    final double latitude = pickupGeoPoint!.latitude;
    final double longitude = pickupGeoPoint.longitude;
    final String? sellerName = taskDetails.value!.sellerName ?? taskDetails.value!.sellerShopName;

    debugPrint("[NAV_LAUNCH] Launching navigation to PICKUP: $latitude, $longitude (Seller: $sellerName)");
    await _launchMapsApp(latitude, longitude, sellerName ?? "موقع الاستLAM");
  }

  Future<void> launchNavigationToDelivery() async {
    if (taskDetails.value == null || taskDetails.value!.deliveryLocationGeoPoint == null) {
      Get.snackbar(
        "خطأ في الوجهة",
        "موقع التسليم (المشتري) غير محدد لهذه المهمة.",
        backgroundColor: Colors.orange.shade300,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final GeoPoint? deliveryGeoPoint = taskDetails.value!.deliveryLocationGeoPoint;
    final double latitude = deliveryGeoPoint!.latitude;
    final double longitude = deliveryGeoPoint.longitude;
    final String? buyerName = taskDetails.value!.buyerName;

    debugPrint("[NAV_LAUNCH] Launching navigation to DELIVERY: $latitude, $longitude (Buyer: $buyerName)");
    await _launchMapsApp(latitude, longitude, buyerName ?? "موقع التسليم");
  }

  // دالة مساعدة عامة لفتح تطبيق الخرائط
  Future<void> _launchMapsApp(double latitude, double longitude, String destinationLabel) async {
    // إنشاء الـ URI بناءً على المنصة
    Uri? uri;

    if (Platform.isAndroid) {
      // رابط لفتح خرائط جوجل مباشرة في وضع الملاحة على أندرويد
      // daddr يحدد الوجهة، و dir_action=navigate يبدأ الملاحة
      uri = Uri.parse("google.navigation:q=$latitude,$longitude&mode=d"); // 'd' for driving
      // كبديل إذا لم يعمل الرابط أعلاه أو لم يتم تثبيت خرائط جوجل (نادر)
      // uri = Uri.parse("https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving");
    } else if (Platform.isIOS) {
      // رابط لفتح خرائط آبل على iOS
      // 'daddr' للوجهة، 'dirflg=d' لوضع القيادة
      uri = Uri.parse("maps://?daddr=$latitude,$longitude&dirflg=d");
      // كبديل إذا لم تكن خرائط آبل متاحة أو إذا فشل الرابط، يمكن استخدام خرائط جوجل ويب
      // if (!await canLaunchUrl(uri)) {
      //   uri = Uri.parse("https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving");
      // }
    } else {
      // للمنصات الأخرى (ويب، سطح مكتب)، استخدم رابط خرائط جوجل ويب
      uri = Uri.parse("https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving");
    }

    debugPrint("[NAV_LAUNCH] Attempting to launch URI: $uri");
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication, //  الأفضل لفتح تطبيق الخرائط مباشرة
        );
        debugPrint("[NAV_LAUNCH] Maps app launched successfully for: $destinationLabel");
      } else {
        debugPrint("[NAV_LAUNCH] Could not launch URI: $uri. Attempting web fallback if not already tried.");
        //  كاحتياطي أخير لجميع المنصات، حاول فتح رابط ويب لخرائط جوجل
        Uri webUri = Uri.parse("https://www.google.com/maps/search/?api=1&query=$latitude,$longitude");
        if (await canLaunchUrl(webUri)) {
          await launchUrl(webUri, mode: LaunchMode.externalApplication);
          debugPrint("[NAV_LAUNCH] Launched web maps as fallback for: $destinationLabel");
        } else {
          throw 'Could not launch $webUri';
        }
      }
    } catch (e) {
      debugPrint("[NAV_LAUNCH] Error launching maps app: $e");
      Get.snackbar(
        'خطأ في الخرائط',
        'لا يمكن فتح تطبيق الخرائط. يرجى التأكد من تثبيت تطبيق خرائط صالح. الخطأ: $e',
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
  void contactSeller() {
    // افترض أن taskDetails.value?.sellerPhoneNumber و taskDetails.value?.sellerName موجودان
    final String? phone = taskDetails.value?.sellerPhoneNumber;
    final String name = taskDetails.value?.sellerName ?? taskDetails.value?.sellerShopName ?? "البائع";
    _contactEntity(phone, name, "البائع");
  }

  void contactBuyer() {
    final String? phone = taskDetails.value?.buyerPhoneNumber;
    final String name = taskDetails.value?.buyerName ?? "المشتري";
    _contactEntity(phone, name, "المشتري");
  }


  Future<void> _contactEntity(String? phoneNumber, String entityNameForDisplay, String entityTypeForError) async {
    if (phoneNumber == null || phoneNumber.trim().isEmpty) {
      debugPrint("[CONTACT_ENTITY] No phone number provided for $entityNameForDisplay.");
      Get.snackbar(
        "لا يوجد رقم هاتف",
        "لا يوجد رقم هاتف مسجل لـ $entityTypeForError ($entityNameForDisplay).",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade300,
        colorText: Colors.black87,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    // تنظيف الرقم وإعداده لـ Uri (بعض الأجهزة قد لا تحتاج لتنظيف المسافات، ولكن من الجيد القيام به)
    final String cleanedPhoneNumber = phoneNumber.replaceAll(RegExp(r'\s+|-|\(|\)'), '');
    final Uri phoneUri = Uri(scheme: 'tel', path: cleanedPhoneNumber);

    debugPrint("[CONTACT_ENTITY] Attempting to call $entityNameForDisplay at $cleanedPhoneNumber (URI: $phoneUri)");

    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
        debugPrint("[CONTACT_ENTITY] Call URI launched for $entityNameForDisplay.");
      } else {
        debugPrint("[CONTACT_ENTITY] Could not launch call URI for $entityNameForDisplay: $phoneUri. Device may not support 'tel' scheme or no app can handle it.");
        Get.snackbar(
          'خطأ في الاتصال',
          'لا يمكن إجراء المكالمة. تأكد من أن جهازك يدعم إجراء المكالمات أو أن الرقم ($phoneNumber) صحيح.',
          backgroundColor: Colors.red.shade400,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e, s) {
      debugPrint("[CONTACT_ENTITY] Exception when trying to launch call URI for $entityNameForDisplay: $e\n$s");
      Get.snackbar(
        'خطأ غير متوقع',
        'حدث خطأ أثناء محاولة الاتصال بـ $entityTypeForError: ${e.toString()}',
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }


  void _stopAllScreenSpecificSubscriptions() {
    debugPrint("[NAV_CTRL] Attempting to cancel screen-specific subscriptions for task $taskId.");

    _taskDetailsSubscription?.cancel(); // <--- الاسم الصحيح هنا
    debugPrint(_taskDetailsSubscription == null ? "  _taskDetailsSubscription was null." : "  _taskDetailsSubscription cancel attempted.");

    _driverProfileSubscriptionForLocationAndFocus?.cancel(); // <--- الاسم الصحيح هنا
    debugPrint(_driverProfileSubscriptionForLocationAndFocus == null ? "  _driverProfileSubscriptionForLocationAndFocus was null." : "  _driverProfileSubscriptionForLocationAndFocus cancel attempted.");

    _directDriverPositionStream?.cancel(); // <--- أضف هذا إذا كنت تستخدمه
    debugPrint(_directDriverPositionStream == null ? "  _directDriverPositionStream was null." : "  _directDriverPositionStream cancel attempted.");

    debugPrint("[NAV_CTRL] Screen-specific subscriptions cancel process completed for $taskId.");
  }

  @override
  void onClose() {
    delayReasonController.dispose(); //  تأكد من التخلص منه
    _issueReasonController.dispose();  //  تأكد من التخلص منه
    _driverProfileSubscriptionForLocationAndFocus?.cancel(); //  كان اسمه القديم
    _taskDetailsSubscription?.cancel();

    _stopAllScreenSpecificSubscriptions();
    googleMapController?.dispose(); // تأكد من التخلص من متحكم الخريطة
    debugPrint("[NAV_CTRL] Controller for task $taskId DISPOSED.");
    super.onClose();
  }



}