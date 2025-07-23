import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:codora/%D8%A7%D9%84%D9%83%D9%88%D8%AF%20%D8%A7%D9%84%D8%AE%D8%A7%D8%B5%20%D8%A8%D8%AA%D8%B7%D8%A8%D9%8A%D9%82%20%D8%A7%D9%84%D8%AA%D9%88%D8%B5%D9%8A%D9%84/LocationPickerScreen1.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // For LatLng
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../XXX/xxx_firebase.dart';
import '../../Model/DeliveryCompanyModel.dart';
// قم باستيراد شاشة اختيار الموقع التي أنشأناها سابقًا
// import '../location_picker_screen.dart'; // <--- عدّل المسار حسب هيكل مشروعك

// افتراض وجود هذه، عدّل المسارات
// import '../../XXX/xxx_firebase.dart';
// import '../models/DeliveryCompanyModel.dart';

// مثال لـ FirebaseX إذا لم يكن معرفًا


class CompanyRegistrationController extends GetxController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final RxString serviceAreaValidationError = ''.obs; // متغير جديد لتخزين رسالة خطأ مناطق الخدمة

  // --- Firebase Instances ---
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // --- Text Editing Controllers ---
  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController contactPhoneNumberController = TextEditingController();
  final TextEditingController contactEmailController = TextEditingController();
  final TextEditingController commercialRegNumController = TextEditingController(); // رقم السجل التجاري
  final TextEditingController websiteUrlController = TextEditingController();
  final TextEditingController companyBioController = TextEditingController();
  final TextEditingController hqAddressTextController = TextEditingController(); // العنوان النصي للمقر

  // --- Service Area Descriptions ---
  final RxList<String> serviceAreaDescriptions = <String>[].obs;
  final TextEditingController newServiceAreaController = TextEditingController();

  // --- Logo Image ---
  final ImagePicker _picker = ImagePicker();
  final Rxn<File> logoImageFile = Rxn<File>(null);

  // --- Headquarters Location ---
  final Rxn<LatLng> headquartersLocation = Rxn<LatLng>(null);
  // لا نحتاج لعرض العنوان النصي هنا بنفس طريقة البائع، لأن الموقع يُعرض على الخريطة
  // ولكن قد يكون headquartersAddressTextController مفيدًا إذا أرادوا إدخاله يدويًا *بالإضافة* للخريطة.

  // --- Phone & Email Verification (States) ---
  // مشابه لمتحكم تسجيل البائع/السائق
  final RxString companyPhoneNumberForOtp = ''.obs;
  final RxString phoneVerificationId = ''.obs;
  final Rxn<int> phoneResendToken = Rxn<int>(null);
  final RxBool isSendingPhoneOtp = false.obs;
  final RxBool isPhoneVerifiedByOtp = false.obs; // Track if OTP for company phone was successful

  final RxBool isSendingEmailVerification = false.obs;
  final RxBool isCompanyEmailVerified = false.obs; // ستحتاج لآلية تحقق من البريد (رابط أو انتظار)

  // --- Loading State ---
  final RxBool isLoading = false.obs; // For overall submission
  final RxList<Map<String, dynamic>> companyHubs = <Map<String, dynamic>>[].obs;
  final Rxn<Map<String, dynamic>> currentEditingHub = Rxn<Map<String, dynamic>>(null); // لتخزين بيانات المقر عند التعديل
  final TextEditingController hubNameController = TextEditingController();
  final TextEditingController hubAddressController = TextEditingController();
  final TextEditingController hubBarcodeController = TextEditingController(); // يمكن اقتراح قيمة له
  final Rxn<LatLng> hubSelectedLocation = Rxn<LatLng>(null); // الموقع المختار للمقر الحالي
  final Uuid uuid = Uuid(); // لإنشاء IDs فريدة للمقرات

  Timer? _emailVerificationTimer;




  @override
  void onClose() {
    companyNameController.dispose();
    contactPhoneNumberController.dispose();
    contactEmailController.dispose();
    commercialRegNumController.dispose();
    websiteUrlController.dispose();
    companyBioController.dispose();
    hqAddressTextController.dispose();
    newServiceAreaController.dispose();
    _emailVerificationTimer?.cancel();
    hubNameController.dispose();
    hubAddressController.dispose();
    hubBarcodeController.dispose();
    super.onClose();
  }

  // --- Logo Image ---
  Future<void> pickLogoImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
          source: source, imageQuality: 70, maxWidth: 1024);
      if (pickedFile != null) {
        logoImageFile.value = File(pickedFile.path);
      }
    } catch (e) {
      Get.snackbar("خطأ", "فشل اختيار الشعار: $e", backgroundColor: Colors.red.shade300);
    }
  }















  void openHubFormDialog({Map<String, dynamic>? hubToEdit, int? editIndex}) async{
    // مسح المتحكمات والمتغيرات المؤقتة
    hubNameController.clear();
    hubAddressController.clear();
    hubBarcodeController.clear();
    hubSelectedLocation.value = null;
    currentEditingHub.value = hubToEdit; // إذا كان تعديلاً
    final GlobalKey<FormState> hubFormKey = GlobalKey<FormState>(); // مفتاح للـ Form داخل الحوار

    String dialogTitle = "إضافة مقر جديد للشركة";
    String confirmButtonText = "إضافة المقر";

    if (hubToEdit != null) {
      dialogTitle = "تعديل بيانات المقر: ${hubToEdit['hubName']}";
      confirmButtonText = "حفظ التعديلات";
      hubNameController.text = hubToEdit['hubName'] as String? ?? '';
      hubAddressController.text = hubToEdit['hubAddressText'] as String? ?? '';
      hubBarcodeController.text = hubToEdit['hubConfirmationBarcode'] as String? ?? '';
      if (hubToEdit['hubLocation'] is LatLng) {
        hubSelectedLocation.value = hubToEdit['hubLocation'] as LatLng;
      } else if (hubToEdit['hubLocation'] is GeoPoint) { // في حالة تحميل بيانات شركة موجودة
        final gp = hubToEdit['hubLocation'] as GeoPoint;
        hubSelectedLocation.value = LatLng(gp.latitude, gp.longitude);
      }
    } else {
      // اقتراح باركود فريد للمقر الجديد
      hubBarcodeController.text = "HUB_${companyNameController.text.trim().isNotEmpty ? companyNameController.text.trim().substring(0,min(companyNameController.text.trim().length,3)).toUpperCase() : 'COMP'}_${(companyHubs.length + 1).toString().padLeft(2,'0')}";
    }
    final LatLng? pickedLocation = await Get.to<LatLng>(
          () => LocationPickerScreen1(initialLocation: hubSelectedLocation.value),
      transition: Transition.downToUp,
    );
    if (pickedLocation != null) {
      hubSelectedLocation.value = pickedLocation;
      // (اختياري) يمكنك تحديث نص العنوان هنا إذا كانت LocationPickerScreen1 تعيد العنوان أيضًا
      // أو استدعاء دالة geocoding لجلب العنوان بناءً على pickedLocation.
    }

    Get.dialog(
      AlertDialog(
        title: Text(dialogTitle),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: SingleChildScrollView(
          child: Form(
            key: hubFormKey, // <--- ربط المفتاح

            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: hubNameController, decoration: const InputDecoration(labelText: "اسم المقر/الفرع*", hintText: "مثال: فرع المنصور")),
                const SizedBox(height: 12),
                TextField(controller: hubAddressController, decoration: const InputDecoration(labelText: "العنوان التفصيلي للمقر*", hintText: "المنطقة، الشارع، أقرب نقطة دالة")),
                const SizedBox(height: 12),
                TextField(controller: hubBarcodeController, decoration: const InputDecoration(labelText: "باركود تأكيد استلام المقر*", hintText: "رمز فريد لهذا المقر، سيمسحه السائق")),
                const SizedBox(height: 12),
                // زر لاختيار موقع المقر على الخريطة
                InkWell(
                  onTap: () async {
                    final LatLng? pickedLocation = await Get.to<LatLng>(
                          () => LocationPickerScreen1(initialLocation: hubSelectedLocation.value), // استخدم شاشة اختيار الموقع
                      transition: Transition.downToUp,
                    );
                    if (pickedLocation != null) {
                      hubSelectedLocation.value = pickedLocation;
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                        labelText: "موقع المقر على الخريطة*",
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal:12, vertical: 8),
                        suffixIcon: Icon(Icons.map_outlined, color: Get.theme.primaryColor)
                    ),
                    child: Obx(() => Text(
                        hubSelectedLocation.value != null
                            ? "تم الاختيار: ${hubSelectedLocation.value!.latitude.toStringAsFixed(4)}, ${hubSelectedLocation.value!.longitude.toStringAsFixed(4)}"
                            : "انقر هنا لتحديد الموقع",
                        style: TextStyle(fontSize:13, color: hubSelectedLocation.value != null ? Colors.black87: Colors.grey.shade600)
                    )),
                  ),
                ),
                Obx(() {
                  if (hubSelectedLocation.value != null) {
                    return SizedBox(
                      height: 100, // ارتفاع مناسب للخريطة المصغرة
                      child: AbsorbPointer( // لجعلها غير تفاعلية
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(target: hubSelectedLocation.value!, zoom: 15),
                          markers: {Marker(markerId: const MarkerId('selectedHubPin'), position: hubSelectedLocation.value!)},
                          mapToolbarEnabled: false,
                          zoomControlsEnabled: false,
                          scrollGesturesEnabled: false,
                        ),
                      ),
                    );
                  }
                  return const Text("لم يتم تحديد الموقع على الخريطة بعد.", style: TextStyle(fontSize: 12, color: Colors.grey));
                }),
              ],
            ),
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("إلغاء")),
          ElevatedButton(
            onPressed: () {
              // التحقق من الحقول
              if (hubNameController.text.trim().isEmpty ||
                  hubAddressController.text.trim().isEmpty ||
                  hubBarcodeController.text.trim().isEmpty ||
                  hubSelectedLocation.value == null) {
                Get.snackbar("بيانات ناقصة", "يرجى ملء جميع حقول المقر المطلوبة وتحديد موقعه.",
                    backgroundColor: Colors.orange.shade300, snackPosition: SnackPosition.TOP);
                return;
              }

              // التحقق من أن باركود المقر فريد (إذا كان إضافة جديدة)
              if (hubToEdit == null && companyHubs.any((hub) => hub['hubConfirmationBarcode'] == hubBarcodeController.text.trim())) {
                Get.snackbar("باركود مكرر", "باركود تأكيد المقر هذا مستخدم بالفعل. اختر رمزًا آخر.", backgroundColor: Colors.orange.shade300, snackPosition: SnackPosition.TOP);
                return;
              }
              // إذا كان تعديل، وتغير الباركود، تحقق أنه لا يتطابق مع باركود مقر آخر (باستثناء المقر الحالي)
              if (hubToEdit != null && hubToEdit['hubConfirmationBarcode'] != hubBarcodeController.text.trim() &&
                  companyHubs.where((h) => h['hubId'] != hubToEdit['hubId']).any((h) => h['hubConfirmationBarcode'] == hubBarcodeController.text.trim()) ) {
                Get.snackbar("باركود مكرر", "باركود تأكيد المقر هذا مستخدم بالفعل لمقر آخر. اختر رمزًا آخر.", backgroundColor: Colors.orange.shade300, snackPosition: SnackPosition.TOP);
                return;
              }

          
              final newHubData = {
                'hubId': hubToEdit?['hubId'] ?? uuid.v4(), // استخدام ID موجود أو إنشاء جديد
                'hubName': hubNameController.text.trim(),
                'hubAddressText': hubAddressController.text.trim(),
                'hubLocation': hubSelectedLocation.value, // LatLng
                'hubConfirmationBarcode': hubBarcodeController.text.trim(),
              };

              if (hubToEdit != null && editIndex != null) {
                // تعديل المقر الموجود
                companyHubs[editIndex] = newHubData;
              } else {
                // إضافة مقر جديد
                companyHubs.add(newHubData);
              }
              companyHubs.refresh(); // لتحديث الواجهة إذا كانت Obx
              Get.back(); // إغلاق الحوار
            },
            child: Text(confirmButtonText),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void removeHub(int index) {
    if (index >= 0 && index < companyHubs.length) {
      Get.defaultDialog(
          title: "تأكيد الحذف",
          middleText: "هل أنت متأكد من حذف المقر: ${companyHubs[index]['hubName']}؟",
          textConfirm: "نعم، حذف",
          textCancel: "إلغاء",
          confirmTextColor: Colors.white,
          buttonColor: Colors.red.shade400,
          onConfirm: (){
            companyHubs.removeAt(index);
            companyHubs.refresh();
            Get.back();
          }
      );
    }
  }






















  bool validateServiceAreasGlobally() { // سميتها globally للتمييز عن validator داخل TextFormField
    if (serviceAreaDescriptions.isEmpty) {
      serviceAreaValidationError.value = "  *يجب إضافة منطقة خدمة واحدة على الأقل";
      return false;
    }
    serviceAreaValidationError.value = ''; // مسح الخطأ إذا كان صالحًا
    return true;
  }



  // عند إضافة أو إزالة منطقة خدمة، يمكنك إعادة التحقق (اختياري، أو الاعتماد على التحقق عند الإرسال)
  void addServiceArea() {
    final area = newServiceAreaController.text.trim();
    if (area.isNotEmpty && !serviceAreaDescriptions.contains(area)) {
      serviceAreaDescriptions.add(area);
      newServiceAreaController.clear();
      validateServiceAreasGlobally(); // أعد التحقق (سيحدث serviceAreaValidationError)
    } else if (serviceAreaDescriptions.contains(area)){
      Get.snackbar("مكرر", "هذه المنطقة مضافة بالفعل.", snackPosition: SnackPosition.BOTTOM, duration: Duration(seconds: 2));
    }
  }

  void removeServiceArea(String area) {
    serviceAreaDescriptions.remove(area);
    validateServiceAreasGlobally(); // أعد التحقق
  }


  // --- Headquarters Location ---
  Future<void> openHeadquartersLocationPicker(BuildContext context) async {
    // منطق مشابه لـ openLocationPickerScreen في SellerRegistrationController
    // مع إمكانية تمرير الموقع الحالي للمقر إذا تم اختياره سابقًا
    final LatLng? currentHqLocation = headquartersLocation.value;
    // يمكنك محاولة جلب الموقع الحالي للجهاز كنقطة بداية افتراضية
    // LatLng? initialPickerLocation = currentHqLocation;
    // try { /* ... جلب موقع الجهاز ... */ } catch(e) {}

    final LatLng? result = await Get.to<LatLng>(
          () => LocationPickerScreen1( // <--- استخدم شاشتك المعدلة
        initialLocation: currentHqLocation ?? const LatLng(33.3152, 44.3661), // موقع افتراضي
      ),
      transition: Transition.downToUp,
    );

    if (result != null) {
      headquartersLocation.value = result;
      // يمكنك جلب العنوان النصي إذا أردت عرضه أيضًا
      _convertHqLatLngToAddress(result);
      update();
    }
  }
  Future<void> _convertHqLatLngToAddress(LatLng location) async {
    try {
      List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(location.latitude, location.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        hqAddressTextController.text = "${p.street ?? ''} ${p.subLocality ?? ''}, ${p.locality ?? ''}".trim().replaceAll(RegExp(r'^,+|,+$|,{2,}'), ',');
      } else {
        hqAddressTextController.text = "تعذر تحديد العنوان";
      }
    } catch (e) {
      hqAddressTextController.text = "خطأ في جلب العنوان";
      debugPrint("Error geocoding HQ: $e");
    }
  }


  // --- Phone OTP Verification for Company Contact ---
  Future<void> initiateCompanyPhoneVerification(BuildContext contextForDialog) async { // تأكد من تمرير السياق هنا
    debugPrint("[PHONE_OTP_INIT] Initiating company phone verification...");
    if (contactPhoneNumberController.text.trim().isEmpty) {
      Get.snackbar("خطأ", "الرجاء إدخال رقم هاتف الشركة.", backgroundColor: Colors.orange.shade300);
      debugPrint("[PHONE_OTP_INIT] Error: Phone number is empty.");
      return;
    }

    String rawPhoneNumber = contactPhoneNumberController.text.trim().replaceAll(RegExp(r'\s+'), '');
    if (rawPhoneNumber.startsWith('0')) {
      rawPhoneNumber = rawPhoneNumber.substring(1);
    }
    const String countryCode = "+964"; // **تأكد أن هذا هو رمز الدولة الصحيح**
    companyPhoneNumberForOtp.value = "$countryCode$rawPhoneNumber";
    debugPrint("[PHONE_OTP_INIT] Formatted phone number for OTP: ${companyPhoneNumberForOtp.value}");

    final RegExp iraqiPhoneNumberRegExp = RegExp(r'^\+9647[3-9]\d{8}$'); // تأكد أن هذا النمط صحيح
    if (!iraqiPhoneNumberRegExp.hasMatch(companyPhoneNumberForOtp.value)) {
      Get.snackbar("رقم هاتف غير صالح", "الرجاء التأكد من إدخال رقم هاتف عراقي صحيح.", backgroundColor: Colors.orange.shade300);
      debugPrint("[PHONE_OTP_INIT] Error: Phone number format regex mismatch.");
      return;
    }

    isSendingPhoneOtp.value = true;
    update(); // لتحديث واجهة GetBuilder إذا كانت تستمع لـ isSendingPhoneOtp
    debugPrint("[PHONE_OTP_INIT] isSendingPhoneOtp set to TRUE.");

    try {
      debugPrint("[PHONE_OTP_INIT] Calling _auth.verifyPhoneNumber...");
      debugPrint("1111;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;");
      debugPrint(companyPhoneNumberForOtp.value);
      debugPrint(companyPhoneNumberForOtp.value);
      debugPrint(";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;");

      await _auth.verifyPhoneNumber(
        phoneNumber: companyPhoneNumberForOtp.value,
        verificationCompleted: (PhoneAuthCredential credential) async {
          isSendingPhoneOtp.value = false;
          isPhoneVerifiedByOtp.value = true; // تم التحقق
          update();
          debugPrint("[PHONE_OTP_INIT] verificationCompleted: Phone auto-verified for company. Credential SMS: ${credential.smsCode}");
          if (Get.isDialogOpen ?? false) Get.back(); // أغلق أي حوار OTP قد يكون مفتوحًا
          Get.snackbar("تم التحقق", "تم التحقق من رقم هاتف الشركة تلقائيًا.", backgroundColor: Colors.green);
        },
        verificationFailed: (FirebaseAuthException e) {
          isSendingPhoneOtp.value = false;
          isPhoneVerifiedByOtp.value = false; // تأكد من إعادة التعيين عند الفشل
          update();
          debugPrint("[PHONE_OTP_INIT] verificationFailed: Code: ${e.code}, Message: ${e.message}");
          String errorMsg = "فشل التحقق من هاتف الشركة.";
          if (e.code == 'invalid-phone-number') {
            errorMsg = "رقم الهاتف المدخل (${companyPhoneNumberForOtp.value}) غير صالح من قبل Firebase.";
          } else if (e.code == 'too-many-requests'){
            errorMsg = "تم إرسال طلبات كثيرة جدًا. حاول لاحقًا.";
          }
          // أضف معالجة لـ network-request-failed إذا كان شائعًا
          // else if (e.code == 'network-request-failed') {
          //   errorMsg = "فشل الاتصال بالشبكة. يرجى التحقق من اتصالك بالإنترنت.";
          // }
          Get.snackbar("فشل التحقق", errorMsg, backgroundColor: Colors.red.shade300, duration: Duration(seconds: 5));
        },
        codeSent: (String verId, int? resendTok) {
          isSendingPhoneOtp.value = false; // انتهت عملية الإرسال
          update();
          debugPrint("[PHONE_OTP_INIT] codeSent: Verification ID: $verId, Resend Token: $resendTok");
          phoneVerificationId.value = verId;
          phoneResendToken.value = resendTok;
          // --- استدعاء الحوار لإدخال الـ OTP ---
          _showCompanyOtpDialog(contextForDialog, verId); // <--- تأكد أن هذا يتم استدعاؤه
        },
        codeAutoRetrievalTimeout: (String verId) {
          debugPrint("[PHONE_OTP_INIT] codeAutoRetrievalTimeout: Verification ID: $verId. Manual entry required.");
          // لا يزال بإمكان المستخدم إدخال الرمز يدويًا إذا تم استدعاء codeSent
          if (phoneVerificationId.value.isEmpty) { // إذا لم يتم استدعاء codeSent لسبب ما
            phoneVerificationId.value = verId;
          }
        },
        timeout: const Duration(seconds: 100),
      );
      debugPrint("[PHONE_OTP_INIT] _auth.verifyPhoneNumber call has been made (asynchronous).");
    } catch (e, s) {
      isSendingPhoneOtp.value = false;
      isPhoneVerifiedByOtp.value = false;
      update();
      debugPrint("[PHONE_OTP_INIT] GENERIC Exception during OTP initiation: $e");
      debugPrint("[PHONE_OTP_INIT] StackTrace: $s");
      Get.snackbar("خطأ OTP", "خطأ غير متوقع أثناء إرسال الرمز لهاتف الشركة: ${e.toString()}", backgroundColor: Colors.red.shade300);
    }
  }


// In CompanyRegistrationController.dart

  Future<bool> _actuallyVerifyAndUseOtpCredential(PhoneAuthCredential credential, String sourceCall) async {
    debugPrint("[$sourceCall] _actuallyVerifyAndUseOtpCredential: Attempting to use OTP credential.");
    // لا تقم بتعيين isPhoneVerifiedByOtp إلى false هنا مباشرةً، دعنا نرى نتيجة العملية
    bool verificationSucceeded = false; // ابدأ بافتراض الفشل

    // Get.dialog(const Center(child: CircularProgressIndicator(backgroundColor: Colors.white,)), barrierDismissible: false);

    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint("[$sourceCall] Error: No current user to link OTP credential.");
      // if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar("خطأ", "المستخدم غير مسجل الدخول لإكمال التحقق.", backgroundColor: Colors.red.shade700);
      return false;
    }

    try {
      debugPrint("[$sourceCall] Attempting to link credential for user: ${currentUser.uid}");
      // إذا كان الهاتف المراد التحقق منه هو نفسه رقم هاتف المستخدم المسجل والموثق بالفعل،
      // فإن linkWithCredential قد يرمي خطأ أو ينجح بدون تغيير.
      // من الأفضل التحقق أولاً إذا كان هذا هو الحال.
      bool phoneAlreadyVerifiedAndMatchesCurrentUser = (currentUser.phoneNumber == companyPhoneNumberForOtp.value && currentUser.phoneNumber != null && currentUser.phoneNumber!.isNotEmpty);

      if (phoneAlreadyVerifiedAndMatchesCurrentUser) {
        debugPrint("[$sourceCall] Phone number ${companyPhoneNumberForOtp.value} already matches current user's verified phone. OTP check passed implicitly.");
        isPhoneVerifiedByOtp.value = true;
        verificationSucceeded = true;
        // if (Get.isDialogOpen ?? false) Get.back();
        Get.snackbar("تم التحقق مسبقًا", "رقم هاتف الشركة هذا موثق بالفعل لحسابك.",
            backgroundColor: Colors.blue, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
      } else {
        // إذا كان الهاتف مختلفًا أو لم يتم توثيقه للمستخدم بعد، حاول الربط
        await currentUser.linkWithCredential(credential);
        debugPrint("[$sourceCall] Firebase Auth: Phone number LINKED successfully via credential. OTP was correct.");
        isPhoneVerifiedByOtp.value = true;
        verificationSucceeded = true;
        // if (Get.isDialogOpen ?? false) Get.back();
        Get.snackbar("تم التحقق!", "تم التحقق من رقم هاتف الشركة وربطه بنجاح.",
            backgroundColor: Colors.green, snackPosition: SnackPosition.BOTTOM);
      }

    } on FirebaseAuthException catch (e) {
      // if (Get.isDialogOpen ?? false) Get.back();
      debugPrint("[$sourceCall] FirebaseAuthException during linkWithCredential: ${e.code} - ${e.message}");
      String errorMessage = "فشل التحقق من الـ OTP أو ربط الرقم.";

      // ----- نقطة التعديل الهامة -----
      if (e.code == 'provider-already-linked') {
        // هذا يعني أن هذا الحساب *بالفعل* لديه مزود هاتف مرتبط به.
        // تحقق مما إذا كان رقم الهاتف المرتبط هو نفسه الذي نحاول التحقق منه.
        if (currentUser.phoneNumber == companyPhoneNumberForOtp.value) {
          debugPrint("[$sourceCall] Provider already linked, and it's the SAME phone number. Considered VERIFIED for this purpose.");
          isPhoneVerifiedByOtp.value = true;
          verificationSucceeded = true;
          Get.snackbar("معلومة", "رقم هاتف الشركة هذا مرتبط بالفعل بحسابك.",
              backgroundColor: Colors.blue, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
        } else {
          debugPrint("[$sourceCall] Provider already linked, but with a DIFFERENT phone number (${currentUser.phoneNumber}). Failing for ${companyPhoneNumberForOtp.value}.");
          errorMessage = "لديك رقم هاتف آخر (${currentUser.phoneNumber}) مرتبط بحسابك. لا يمكنك ربط هذا الرقم (${companyPhoneNumberForOtp.value}) حاليًا كـ PhoneProvider إضافي بنفس الطريقة.";
          isPhoneVerifiedByOtp.value = false; // فشل لأن الرقم مختلف
          Get.snackbar("خطأ في الربط", errorMessage,
              backgroundColor: Colors.orange.shade400, snackPosition: SnackPosition.TOP, duration: Duration(seconds: 6));
        }
      } else if (e.code == 'credential-already-in-use') {
        // هذا يعني أن هذا الرقم الهاتف *مستخدم من قبل حساب آخر*. يجب أن يفشل.
        errorMessage = "رقم الهاتف هذا (${companyPhoneNumberForOtp.value}) مرتبط بالفعل بحساب آخر. لا يمكن استخدامه.";
        isPhoneVerifiedByOtp.value = false;
        Get.snackbar("خطأ OTP", errorMessage,
            backgroundColor: Colors.red.shade400, snackPosition: SnackPosition.TOP, duration: Duration(seconds: 6));
      } else if (e.code == 'invalid-credential' || e.code == 'invalid-verification-code') {
        errorMessage = "رمز التحقق الذي أدخلته غير صحيح.";
        isPhoneVerifiedByOtp.value = false;
        Get.snackbar("خطأ OTP", errorMessage,
            backgroundColor: Colors.red.shade400, snackPosition: SnackPosition.TOP, duration: Duration(seconds: 5));
      } else if (e.code == 'session-expired') {
        errorMessage = "انتهت صلاحية جلسة التحقق. حاول طلب الرمز مرة أخرى.";
        isPhoneVerifiedByOtp.value = false;
        Get.snackbar("خطأ OTP", errorMessage,
            backgroundColor: Colors.red.shade400, snackPosition: SnackPosition.TOP, duration: Duration(seconds: 5));
      } else if (e.code == 'requires-recent-login'){
        errorMessage = "هذه العملية تتطلب تسجيل دخول حديث لأسباب أمنية. يرجى محاولة تسجيل الخروج ثم الدخول مرة أخرى.";
        isPhoneVerifiedByOtp.value = false;
        Get.snackbar("خطأ OTP", errorMessage,
            backgroundColor: Colors.orange.shade300, snackPosition: SnackPosition.TOP, duration: Duration(seconds: 6));
      } else {
        // أخطاء أخرى
        isPhoneVerifiedByOtp.value = false;
        Get.snackbar("خطأ OTP", "$errorMessage (${e.code})", // أضف رمز الخطأ للمساعدة
            backgroundColor: Colors.red.shade400, snackPosition: SnackPosition.TOP, duration: Duration(seconds: 5));
      }
    } catch (e, s) {
      // if (Get.isDialogOpen ?? false) Get.back();
      debugPrint("[$sourceCall] GENERIC error during linkWithCredential: $e, Stack: $s");
      isPhoneVerifiedByOtp.value = false;
      Get.snackbar("خطأ", "حدث خطأ غير متوقع أثناء التحقق من الـ OTP: ${e.toString()}",
          backgroundColor: Colors.red.shade400, snackPosition: SnackPosition.TOP);
    } finally {
      update();
      debugPrint("[$sourceCall] _actuallyVerifyAndUseOtpCredential finished. isPhoneVerifiedByOtp: ${isPhoneVerifiedByOtp.value}");
    }
    return verificationSucceeded;
  }


  void _showCompanyOtpDialog(BuildContext context, String currentReceivedVerificationId) {
    debugPrint("[OTP_DIALOG] Showing dialog for VerID: $currentReceivedVerificationId");
    final otpInputController = TextEditingController();
    // RxBool للتحكم في حالة التحميل داخل الحوار
    final RxBool isDialogVerifying = false.obs;

    Get.dialog(
      Obx(() => AlertDialog( // Obx لمراقبة isDialogVerifying
        title: const Text("أدخل رمز التحقق"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("تم إرسال الرمز إلى: ${companyPhoneNumberForOtp.value}"),
            const SizedBox(height: 15),
            TextField(
              controller: otpInputController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              autofocus: true,
              decoration: const InputDecoration(labelText: "رمز OTP", border: OutlineInputBorder()),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, letterSpacing: 2),
              enabled: !isDialogVerifying.value, // تعطيل الحقل أثناء التحميل
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: isDialogVerifying.value ? null : () => Get.back(), // تعطيل الإلغاء أثناء التحميل
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            onPressed: isDialogVerifying.value
                ? null // تعطيل الزر أثناء التحميل
                : () async {
              if (otpInputController.text.trim().length == 6) {
                isDialogVerifying.value = true; // بدء التحميل داخل الحوار
                PhoneAuthCredential credential = PhoneAuthProvider.credential(
                    verificationId: currentReceivedVerificationId, // <--- استخدم المعرف الصحيح هنا
                    smsCode: otpInputController.text.trim());

                bool success = await _actuallyVerifyAndUseOtpCredential(credential, "OtpDialogVerification");
                isDialogVerifying.value = false; // إنهاء التحميل داخل الحوار

                if (success) {

                  Get.back(); // أغلق حوار الـ OTP فقط في حالة النجاح
                }
                // إذا فشل، الـ Snackbar من _actuallyVerifyAndUseOtpCredential سيظهر،
                // ويبقى الحوار مفتوحًا ليتمكن المستخدم من المحاولة مرة أخرى أو الإلغاء.
              } else {
                Get.snackbar("خطأ", "الرجاء إدخال رمز مكون من 6 أرقام.",
                    backgroundColor: Colors.orange.shade300, snackPosition: SnackPosition.TOP);
              }
            },
            child: isDialogVerifying.value
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text("تحقق من الرمز"),
          ),
        ],
      )),
      barrierDismissible: false, // أو اجعلها true إذا كنت تريد السماح بالإغلاق بالنقر خارجًا (ولكن ليس أثناء isDialogVerifying)
    );
  }


  // --- Email Verification for Company Contact ---
  Future<void> sendCompanyEmailVerification() async {
    if (contactEmailController.text.trim().isEmpty || !GetUtils.isEmail(contactEmailController.text.trim())) {
      Get.snackbar("خطأ", "الرجاء إدخال بريد إلكتروني صالح للشركة.", backgroundColor: Colors.orange.shade300);
      return;
    }
    // نفترض أن مشرف الشركة هو المستخدم الحالي الذي يقوم بالتسجيل
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      Get.snackbar("خطأ", "يجب تسجيل الدخول أولاً لربط بريد إلكتروني.", backgroundColor: Colors.red.shade300);
      return;
    }

    isSendingEmailVerification.value = true;
    try {
      // السيناريو الأول: إذا كان هذا البريد هو نفسه بريد حساب Firebase Auth للمشرف ولم يتم التحقق منه
      if (currentUser.email == contactEmailController.text.trim() && !currentUser.emailVerified) {
        await currentUser.sendEmailVerification();
        Get.snackbar("تحقق من بريدك", "تم إرسال رابط التحقق إلى ${currentUser.email}. يرجى التحقق منه ثم محاولة الحفظ.",
            backgroundColor: Colors.blue, colorText: Colors.white, duration: Duration(seconds: 7));
        _startListeningForEmailVerification(currentUser); // ابدأ الاستماع للتحقق
      }
      // السيناريو الثاني: إذا كان هذا البريد مختلفًا، أو إذا كنت تريد آلية تحقق منفصلة للبريد الرسمي للشركة.
      // هذا يتطلب عادةً إرسال بريد من سيرفرك الخاص أو خدمة طرف ثالث لتتبع رابط فريد.
      // للتبسيط الآن، سنركز على السيناريو الأول. إذا كنت تريد نظام تحقق منفصل للبريد الرسمي للشركة،
      // فستحتاج لإنشاء رمز فريد، حفظه مع البريد، إرساله عبر البريد، ثم واجهة لإدخال الرمز.
      else if (currentUser.email != contactEmailController.text.trim()) {
        Get.snackbar("تنبيه", "حالياً، يتم التحقق فقط إذا كان البريد المدخل هو نفس بريد حسابك (${currentUser.email}). للبريد الرسمي للشركة، سيتم اعتباره غير موثق مبدئيًا.",
            backgroundColor: Colors.orange, duration: Duration(seconds: 7));
        isCompanyEmailVerified.value = false; // إذا كان مختلفًا، اعتبره غير موثق من هذه العملية
      } else if (currentUser.email == contactEmailController.text.trim() && currentUser.emailVerified){
        Get.snackbar("مُتحقق منه", "بريد حسابك (${currentUser.email}) مُتحقق منه بالفعل.", backgroundColor: Colors.green);
        isCompanyEmailVerified.value = true; // بما أنه نفس بريد الحساب الموثق
      }


    } catch (e) {
      Get.snackbar("خطأ", "فشل إرسال رابط التحقق: $e", backgroundColor: Colors.red.shade300);
    } finally {
      isSendingEmailVerification.value = false;
    }
  }

  void _startListeningForEmailVerification(User user) {
    _emailVerificationTimer?.cancel(); // ألغِ أي مؤقت سابق
    _emailVerificationTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await user.reload();
      User? refreshedUser = _auth.currentUser; // احصل على المستخدم المحدث
      if (refreshedUser != null && refreshedUser.emailVerified) {
        isCompanyEmailVerified.value = true;
        timer.cancel();
        Get.back(); // أغلق أي حوارات مفتوحة للتحقق من البريد
        Get.snackbar("تم التحقق!", "تم التحقق من بريدك الإلكتروني بنجاح.", backgroundColor: Colors.green);
        debugPrint("Company Email (admin's email) verified.");
      }
      // إذا لم يتم إغلاق المتحكم وما زال الحوار مفتوحًا (غير مرجح هنا)
      if (!Get.isRegistered<CompanyRegistrationController>()) {
        timer.cancel();
      }
    });
  }

  // To be called in onInit if needed
  // void checkInitialEmailVerificationStatus() async {
  //   User? currentUser = _auth.currentUser;
  //   if (currentUser != null) {
  //     await currentUser.reload(); // Get latest status
  //     if(contactEmailController.text.trim() == currentUser.email && currentUser.emailVerified){
  //       isCompanyEmailVerified.value = true;
  //     }
  //   }
  // }


  // --- Submission Method ---





  // In CompanyRegistrationController.dart

  Future<void> submitCompanyProfile() async {
    bool isFormValid = formKey.currentState?.validate() ?? false; // تحقق من باقي النموذج
    bool areServiceAreasValid = validateServiceAreasGlobally(); // تحقق من مناطق الخدمة
    bool areHubsValid = true; // افتراضي

    if (!isFormValid || !areServiceAreasValid) { // تحقق من كليهما
      Get.snackbar("بيانات ناقصة", "يرجى ملء جميع الحقول المطلوبة بعلامة (*) والتأكد من إضافة مناطق خدمة.",
          backgroundColor: Colors.orange.shade300, duration: Duration(seconds: 4));
      return;
    }
    if (!formKey.currentState!.validate()) {
      Get.snackbar("بيانات ناقصة", "يرجى ملء جميع الحقول المطلوبة بعلامة (*).", backgroundColor: Colors.orange.shade300);
      return;
    }
    // التحقق من اختيار شعار الشركة
    if (logoImageFile.value == null) {
      Get.snackbar("مطلوب", "الرجاء اختيار شعار للشركة.", backgroundColor: Colors.orange.shade300);
      return;
    }
    // التحقق من تحديد الموقع
    if(headquartersLocation.value == null){
      Get.snackbar("مطلوب", "الرجاء تحديد موقع مقر الشركة على الخريطة.", backgroundColor: Colors.orange.shade300);
      return;
    }
    // التحقق من إدخال منطقة خدمة واحدة على الأقل
    if(serviceAreaDescriptions.isEmpty){
      Get.snackbar("مطلوب", "الرجاء إضافة منطقة خدمة واحدة على الأقل.", backgroundColor: Colors.orange.shade300);
      return;
    }

    // --- التحقق من صحة الهاتف والبريد الإلكتروني ---
    if (!isPhoneVerifiedByOtp.value && contactPhoneNumberController.text.isNotEmpty) {
      Get.snackbar("تحقق مطلوب", "الرجاء التحقق من رقم هاتف الشركة أولاً.", backgroundColor: Colors.orange.shade300, duration: Duration(seconds: 4));
      return;
    }
    isLoading.value = true;
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception("يجب تسجيل الدخول لإضافة شركة.");

      final companyAdminUid = currentUser.uid;
      final companyId = companyAdminUid;

      // 1. Upload logo image
      // ... (كود رفع الشعار) ...
      final String logoPath = '${FirebaseX.companyStoragePath}/$companyId/logo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String? logoUrl = await _uploadFile(logoImageFile.value!, logoPath);
      if (logoUrl == null && logoImageFile.value != null) throw Exception("فشل رفع شعار الشركة.");


      // 2. Get FCM Token for the admin user
      // ... (كود جلب التوكن) ...
      String? adminFcmToken = await _firebaseMessaging.getToken().catchError((e){
        debugPrint("Failed to get FCM for company admin: $e"); return null;
      });


      List<Map<String, dynamic>> hubsToSave = [];
      for (var hubDataMap in companyHubs) {
        GeoPoint? hubGeoP;
        final dynamic locData = hubDataMap['hubLocation'];
        if (locData is LatLng) {
          hubGeoP = GeoPoint(locData.latitude, locData.longitude);
        } else if (locData is GeoPoint){
          hubGeoP = locData;
        }

        if (hubGeoP != null) { // فقط قم بتضمين المقرات التي لديها موقع صالح
          hubsToSave.add({
            'hubId': hubDataMap['hubId'] as String? ?? uuid.v4(),
            'hubName': hubDataMap['hubName'] as String? ?? '',
            'hubAddressText': hubDataMap['hubAddressText'] as String? ?? '',
            'hubLocation': hubGeoP, // <-- هنا GeoPoint
            'hubConfirmationBarcode': hubDataMap['hubConfirmationBarcode'] as String? ?? '',
          });
        } // ...
      }

      // --- التحويل من LatLng? إلى GeoPoint? ---
      GeoPoint? hqGeoPoint; // القيمة الافتراضية null
      if (headquartersLocation.value != null) {
        hqGeoPoint = GeoPoint(
          headquartersLocation.value!.latitude,
          headquartersLocation.value!.longitude,
        );
      }
      // -----------------------------------------


      // 3. Prepare Company Data
      final companyDataMap = DeliveryCompanyModel( // <-- استخدام النموذج لإنشاء الخريطة
        companyId: companyId,
        companyName: companyNameController.text.trim(),
        logoImageUrl: logoUrl ?? FirebaseX.defaultCompanyLogoUrl,
        contactPhoneNumber: companyPhoneNumberForOtp.value.isNotEmpty ? companyPhoneNumberForOtp.value : contactPhoneNumberController.text.trim(),
        contactEmail: contactEmailController.text.trim(),
        adminUserId: companyAdminUid,
        headquartersAddressText: hqAddressTextController.text.trim().isNotEmpty ? hqAddressTextController.text.trim() : null,
        headquartersLocation: hqGeoPoint, // <--- استخدام GeoPoint المحول هنا
        serviceAreaDescriptions: List<String>.from(serviceAreaDescriptions),
        commercialRegistrationNumber: commercialRegNumController.text.trim().isNotEmpty ? commercialRegNumController.text.trim() : null,
        websiteUrl: websiteUrlController.text.trim().isNotEmpty ? websiteUrlController.text.trim() : null,
        companyBio: companyBioController.text.trim().isNotEmpty ? companyBioController.text.trim() : null,
        isApprovedByPlatformAdmin: false,
        isVerified: false,
        isActiveByCompanyAdmin: true,

        hubLocations: hubsToSave.isNotEmpty ? hubsToSave : null,
        createdAt: Timestamp.now(), // استخدم Timestamp.now() هنا بدلاً من انتظار serverTimestamp من toMap
        // averageRating, numberOfRatings defaults to 0.0 and 0
      ).toMap();

      // إضافة/تحديث توكن FCM لمستخدم المشرف بشكل منفصل إذا أردت ذلك
      // هذا يضمن أن finalCompanyData لا تحتوي على حقل fcmToken إذا كان خاصًا بالمستخدم فقط
      if(adminFcmToken != null && companyAdminUid.isNotEmpty){
        await _firestore.collection(FirebaseX.DeliveryAppUser) // أو أي مجموعة تحفظ فيها معلومات المستخدمين/المشرفين
            .doc(companyAdminUid)
            .set({'fcmToken': adminFcmToken, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
        debugPrint("FCM token for company admin $companyAdminUid updated/set.");
      }


      // 4. Save to Firestore
      debugPrint("[COMPANY_REG] Saving company data to Firestore for ID: $companyId");
      await _firestore.collection(FirebaseX.deliveryCompaniesCollection)
          .doc(companyId)
          .set(companyDataMap); // استخدام الخريطة التي تم إنشاؤها بواسطة النموذج

      Get.snackbar("تم الإرسال للمراجعة", "تم إرسال معلومات شركتك. سيتم مراجعتها من قبل الإدارة.",
          backgroundColor: Colors.green, colorText: Colors.white, duration: const Duration(seconds: 5));

      _resetFormFields();

    } catch (e, s) { // إضافة StackTrace للمزيد من التفاصيل
      debugPrint("[COMPANY_REG] Error during company registration: $e");
      debugPrint("[COMPANY_REG] StackTrace: $s");
      Get.snackbar("خطأ في التسجيل", "فشل تسجيل الشركة: ${e.toString()}",
          backgroundColor: Colors.red.shade400, duration: const Duration(seconds: 5));
    } finally {
      isLoading.value = false;
    }
  }

  // ... (باقي الكود في المتحكم)





  void _resetFormFields(){
    companyNameController.clear();
    contactPhoneNumberController.clear();
    contactEmailController.clear();
    commercialRegNumController.clear();
    websiteUrlController.clear();
    companyBioController.clear();
    hqAddressTextController.clear();
    serviceAreaDescriptions.clear();
    newServiceAreaController.clear();
    logoImageFile.value = null;
    headquartersLocation.value = null;
    isPhoneVerifiedByOtp.value = false;
    isCompanyEmailVerified.value = false;
    companyPhoneNumberForOtp.value = '';
    phoneVerificationId.value = '';
    companyHubs.clear();
    hubNameController.clear();
    hubAddressController.clear();
    hubBarcodeController.clear();
    hubSelectedLocation.value = null;
    currentEditingHub.value = null;
    // formKey.currentState?.reset(); //  This can reset validation state too.
  }

  Future<String?> _uploadFile(File file, String path) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint("Error uploading file ($path): $e");
      return null;
    }
  }
}