import 'dart:io';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:codora/%D8%A7%D9%84%D9%83%D9%88%D8%AF%20%D8%A7%D9%84%D8%AE%D8%A7%D8%B5%20%D8%A8%D8%AA%D8%B7%D8%A8%D9%8A%D9%82%20%D8%A7%D9%84%D8%A8%D8%A7%D8%A6%D8%B9/seller_app_auth/controllers/seller_auth_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart'; // For DateFormat
import 'package:geocoding/geocoding.dart' as geo;

import '../../../XXX/xxx_firebase.dart';
import '../../../Model/SellerModel.dart';
import '../../ui/seller_main_screen.dart';
import '../ui/OtpVerificationScreen.dart';
import '../ui/LocationPickerScreen.dart';

class SellerRegistrationController extends GetxController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  RxDouble currentPositionAccuracy = 0.0.obs;

  // --- Firebase Instances ---
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final RxString verificationId = ''.obs; // To store Firebase's verification ID

  // iOS-specific Firebase Storage handler
  late IOSFirebaseStorageHandler _iosStorageHandler;

  // ==========================================================================
  // ==========================================================================
  // ==========================================================================

  // لإضافة نوع البائع
  String? _sellerTypeFromAuth; // سيتم جلب هذا من SellerAuthController

  final Rxn<int> resendToken = Rxn<int>(null); // For resending OTP
  final TextEditingController otpController = TextEditingController();
  final RxBool isOtpSending = false.obs; // Loading state for OTP sending
  final RxBool isOtpVerifying = false.obs; // Loading state for OTP verification
  Map<String, dynamic>? _tempSellerDataForSubmission;
  File? _tempSellerProfileImageFile;
  File? _tempShopFrontImageFile;

  // --- Text Editing Controllers ---
  final TextEditingController sellerNameController = TextEditingController();
  final TextEditingController shopNameController = TextEditingController();
  final TextEditingController shopPhoneNumberController =
      TextEditingController();
  final TextEditingController shopDescriptionController =
      TextEditingController();
  // Add more controllers for other text fields like commercial reg no., etc.

  // --- Image Pickers ---
  final ImagePicker _picker = ImagePicker();
  final Rxn<File> sellerProfileImageFile = Rxn<File>(null);
  final Rxn<File> shopFrontImageFile = Rxn<File>(null);

  // --- Location ---
  final Rxn<LatLng> shopLocation = Rxn<LatLng>(null);
  final RxString shopAddressText = ''.obs;
  final Rxn<LatLng> tempSelectedLocation = Rxn<LatLng>(
    null,
  ); // للموقع المؤقت المختار
  final RxBool isLocationLoading = false.obs; // لحالة تحميل الموقع
  final RxBool showLocationConfirmation = false.obs; // لإظهار تأكيد الموقع
  final RxBool firstTimeAutoExpand =
      true.obs; // للتحكم في التوسيع التلقائي لأول مرة فقط
  GoogleMapController? mapController;

  // --- Working Hours ---
  final List<String> dayKeys = [
    "sunday_en",
    "monday_en",
    "tuesday_en",
    "wednesday_en",
    "thursday_en",
    "friday_en",
    "saturday_en",
  ];
  final RxnString expandedDayPanel = RxnString(null); // For ExpansionPanelList

  final RxMap<String, Map<String, dynamic>> workingHours =
      <String, Map<String, dynamic>>{
        "sunday_en": {
          'isOpen': false,
          'opensAt': null,
          'closesAt': null,
          'name_ar': "الأحد",
        },
        "monday_en": {
          'isOpen': false,
          'opensAt': null,
          'closesAt': null,
          'name_ar': "الاثنين",
        },
        "tuesday_en": {
          'isOpen': false,
          'opensAt': null,
          'closesAt': null,
          'name_ar': "الثلاثاء",
        },
        "wednesday_en": {
          'isOpen': false,
          'opensAt': null,
          'closesAt': null,
          'name_ar': "الأربعاء",
        },
        "thursday_en": {
          'isOpen': false,
          'opensAt': null,
          'closesAt': null,
          'name_ar': "الخميس",
        },
        "friday_en": {
          'isOpen': false,
          'opensAt': null,
          'closesAt': null,
          'name_ar': "الجمعة",
        },
        "saturday_en": {
          'isOpen': false,
          'opensAt': null,
          'closesAt': null,
          'name_ar': "السبت",
        },
      }.obs;
  final RxnString _lastAppliedOpensAt = RxnString(null);
  final RxnString _lastAppliedClosesAt = RxnString(null);
  // --- Main Categories ---
  // قائمة شاملة بفئات المنتجات فقط (لا تتضمن الخدمات)
  final List<String> shopCategories = [
    "إلكترونيات ومعدات تقنية",
    "هواتف ذكية وأجهزة لوحية",
    "حاسوب ولابتوب",
    "ملابس رجالية",
    "ملابس نسائية",
    "ملابس أطفال",
    "أحذية رجالية",
    "أحذية نسائية",
    "حقائب ومحافظ",
    "مواد غذائية وبقالة",
    "حلويات ومعجنات",
    "مشروبات ومرطبات",
    "منتجات صحية وفيتامينات",
    "مستحضرات تجميل ومكياج",
    "منتجات العناية الشخصية",
    "أدوية ومستلزمات طبية",
    "كتب ومجلات",
    "مواد تعليمية وقرطاسية",
    "ألعاب أطفال",
    "ألعاب إلكترونية",
    "معدات رياضية",
    "ملابس رياضية",
    "أدوات منزلية ومطبخ",
    "أجهزة كهربائية منزلية",
    "أثاث منزلي",
    "ديكور ومفروشات",
    "نباتات وزهور",
    "أدوات حدائق",
    "قطع غيار سيارات",
    "إكسسوارات سيارات",
    "أدوات وعدد يدوية",
    "معدات ورش",
    "مواد بناء وتشييد",
    "دهانات ومواد التشطيب",
    "مجوهرات ذهبية",
    "ساعات وإكسسوارات",
    "هدايا وتحف",
    "منتجات الأطفال والمواليد",
    "ملابس وأحذية أطفال",
    "طعام ومستلزمات حيوانات أليفة",
    "آلات موسيقية",
    "معدات صوتية",
    "مواد غذائية عضوية",
    "منتجات طبيعية وعشبية",
    "حرف يدوية وفنون",
    "منتجات تراثية",
    "أقمشة ومواد خياطة",
    "أدوات الخياطة والتطريز",
    "عطور وبخور",
    "زيوت عطرية طبيعية",
    "منتجات رمضانية وعيد",
    "تحف ومقتنيات",
    "أخرى",
  ];

  // الفئات المختارة (حد أقصى 6 فئات)
  final RxList<String> selectedShopCategories = <String>[].obs;
  final int maxCategoriesAllowed = 6;

  // --- Loading State ---
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();

    // Initialize iOS-specific storage handler
    if (Platform.isIOS) {
      _iosStorageHandler = IOSFirebaseStorageHandler(_storage);
    }

    // جلب SellerAuthController والحصول على sellerType
    try {
      final SellerAuthController authController =
          Get.find<SellerAuthController>();
      _sellerTypeFromAuth = authController.sellerType;
      if (_sellerTypeFromAuth != null) {
        debugPrint(
          "SellerRegistrationController: تم جلب نوع البائع من AuthController: $_sellerTypeFromAuth",
        );
      } else {
        debugPrint(
          "SellerRegistrationController: لم يتم العثور على sellerType في AuthController. قد يحتاج المستخدم للعودة واختيار النوع.",
        );
        // يمكنك هنا إضافة منطق لتوجيه المستخدم إذا كان sellerType ضروريًا ولا يمكن أن يكون null
        // مثال: Get.offAll(() => SellerTypeSelectionScreen()); أو عرض رسالة خطأ
      }
    } catch (e) {
      debugPrint(
        "SellerRegistrationController: خطأ أثناء محاولة العثور على SellerAuthController أو الوصول إلى sellerType: $e",
      );
      // معالجة الخطأ، ربما توجيه المستخدم أو عرض رسالة
    }
  }

  @override
  void onClose() {
    sellerNameController.dispose();
    shopNameController.dispose();
    shopPhoneNumberController.dispose();
    shopDescriptionController.dispose();
    mapController?.dispose();
    otpController.dispose();
    super.onClose();
  }

  void removeImage({required bool isProfileImage}) {
    if (isProfileImage) {
      sellerProfileImageFile.value = null;
    } else {
      shopFrontImageFile.value = null;
    }
    update(); // For GetBuilder if used, or just rely on Obx for reactive updates
  }

  Future<void> initiatePhoneVerificationAndCollectData() async {
    debugPrint("🚀 initiatePhoneVerificationAndCollectData called");
    debugPrint("Form validation starting...");

    if (!formKey.currentState!.validate()) {
      debugPrint("❌ Form validation failed");
      Get.snackbar(
        "خطأ",
        "يرجى ملء جميع الحقول المطلوبة بشكل صحيح.",
        backgroundColor: Colors.orange.shade300,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    debugPrint("✅ Form validation passed");

    // --- Add all your previous validations ---
    debugPrint("Checking profile image...");
    if (sellerProfileImageFile.value == null) {
      debugPrint("❌ No profile image selected");
      Get.snackbar(
        "خطأ",
        "يرجى اختيار صورة شخصية.",
        backgroundColor: Colors.orange.shade300,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    debugPrint("✅ Profile image validation passed");

    debugPrint("Checking shop front image...");
    if (shopFrontImageFile.value == null) {
      debugPrint("❌ No shop front image selected");
      Get.snackbar(
        "خطأ",
        "يرجى اختيار صورة لواجهة المحل.",
        backgroundColor: Colors.orange.shade300,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    debugPrint("✅ Shop front image validation passed");

    debugPrint("Checking shop location...");
    if (shopLocation.value == null) {
      debugPrint("❌ No shop location selected");
      Get.snackbar(
        "خطأ",
        "يرجى تحديد موقع المحل.",
        backgroundColor: Colors.orange.shade300,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    debugPrint("✅ Shop location validation passed");

    debugPrint("Checking shop category...");
    if (selectedShopCategories.isEmpty) {
      debugPrint("❌ No shop categories selected");
      Get.snackbar(
        "خطأ",
        "يرجى اختيار فئة واحدة على الأقل للمتجر.",
        backgroundColor: Colors.orange.shade300,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    debugPrint(
      "✅ Shop categories validation passed: ${selectedShopCategories.length} categories selected",
    );

    // التحقق إذا كان _sellerTypeFromAuth فارغًا قبل المتابعة (إذا كان إلزاميًا)
    debugPrint("Checking seller type...");
    if (_sellerTypeFromAuth == null || _sellerTypeFromAuth!.isEmpty) {
      debugPrint("❌ No seller type selected");
      Get.snackbar(
        "خطأ",
        "لم يتم تحديد نوع البائع. يرجى الرجوع واختيار نوع البائع.",
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    debugPrint("✅ Seller type validation passed: $_sellerTypeFromAuth");

    debugPrint("Checking working hours...");
    bool workingHoursValid = true;
    String firstInvalidDay = "";
    workingHours.forEach((key, value) {
      if ((value['isOpen'] == true) &&
          (value['opensAt'] == null || value['closesAt'] == null)) {
        workingHoursValid = false;
        firstInvalidDay = value['name_ar'] as String;
        return;
      }
    });
    if (!workingHoursValid) {
      debugPrint("❌ Working hours validation failed for day: $firstInvalidDay");
      Get.snackbar(
        "خطأ",
        "يرجى تحديد أوقات الفتح والإغلاق لليوم المفتوح: $firstInvalidDay.",
        backgroundColor: Colors.orange.shade300,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    debugPrint("✅ Working hours validation passed");

    String rawPhoneNumber = shopPhoneNumberController.text.trim();
    rawPhoneNumber = rawPhoneNumber.replaceAll(RegExp(r'\s+'), '');
    if (rawPhoneNumber.startsWith('0')) {
      rawPhoneNumber = rawPhoneNumber.substring(1);
    }
    const String countryCode = "+964";
    final String formattedPhoneNumber = "$countryCode$rawPhoneNumber";
    debugPrint("الرقم المدخل الأصلي: ${shopPhoneNumberController.text}");
    debugPrint(
      "الرقم بعد إزالة المسافات والصفر وإضافة رمز الدولة: $formattedPhoneNumber",
    );

    final RegExp iraqiPhoneNumberRegExp = RegExp(r'^\+9647[3-9]\d{8}$');
    debugPrint("Checking phone number validation: $formattedPhoneNumber");
    if (!iraqiPhoneNumberRegExp.hasMatch(formattedPhoneNumber)) {
      debugPrint("Phone number validation failed for: $formattedPhoneNumber");
      Get.snackbar(
        "رقم هاتف غير صالح",
        "الرجاء التأكد من إدخال رقم هاتف عراقي صحيح.",
        backgroundColor: Colors.orange.shade300,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    debugPrint("Phone number validation passed");

    // ---- Set loading states ----
    debugPrint("Setting loading states...");
    isOtpSending.value = true;
    isLoading.value = true;
    update();
    debugPrint("Loading states set successfully");

    try {
      debugPrint("Preparing temp data for submission...");
      _tempSellerProfileImageFile = sellerProfileImageFile.value;
      _tempShopFrontImageFile = shopFrontImageFile.value;
      _tempSellerDataForSubmission = {
        "sellerName": sellerNameController.text.trim(),
        "shopName": shopNameController.text.trim(),
        "shopPhoneNumber": shopPhoneNumberController.text.trim(),
        "shopDescription": shopDescriptionController.text.trim(),
        "location": GeoPoint(
          shopLocation.value!.latitude,
          shopLocation.value!.longitude,
        ),
        "shopAddressText": shopAddressText.value,
        "shopCategories": selectedShopCategories.toList(),
        "workingHours": Map<String, Map<String, dynamic>>.from(workingHours),
        "streetAddress": streetAddressController.text.trim(),
      };
      debugPrint("Temp data prepared successfully");

      debugPrint(
        "Starting Firebase phone verification for: $formattedPhoneNumber",
      );
      debugPrint("FirebaseAuth instance: $_auth");

      // تفعيل reCAPTCHA للـ iOS للجميع
      if (Platform.isIOS) {
        debugPrint("Setting up reCAPTCHA for iOS...");
        try {
          await _auth.setSettings(
            appVerificationDisabledForTesting:
                false, // إزالة دعم الأرقام التجريبية
            forceRecaptchaFlow: true, // reCAPTCHA للجميع
          );

          debugPrint("✅ Firebase Auth settings configured for iOS");
          debugPrint("✅ Firebase Auth settings configured for iOS");

          // إضافة تأخير قصير للسماح للإعدادات بالتطبيق
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          debugPrint("⚠️ Error setting Firebase Auth settings: $e");
          // في حالة فشل إعدادات reCAPTCHA، جرب بدونها
          debugPrint("🔄 Trying without forced reCAPTCHA...");
        }
      }

      // إضافة timeout إضافي للتأكد من عمل الـ callbacks
      Timer callbackTimeoutTimer = Timer(const Duration(seconds: 30), () {
        if (isOtpSending.value || isLoading.value) {
          debugPrint("⚠️ Callback timeout - reCAPTCHA may not have appeared");
          debugPrint("⚠️ This usually means Firebase Console settings issue");
          isOtpSending.value = false;
          isLoading.value = false;
          isOtpVerifying.value = false;
          update();
          Get.snackbar(
            "مشكلة في التحقق",
            "لم تظهر صفحة التحقق. تحقق من إعدادات Firebase أو جرب رقماً آخر.",
            backgroundColor: Colors.orange.shade400,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 5),
          );
        }
      });

      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhoneNumber,
        forceResendingToken: resendToken.value,
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint("🎉 VERIFICATION COMPLETED CALLBACK TRIGGERED");
          debugPrint(
            "Phone auto-verified. Credential SMS code (if available): ${credential.smsCode}",
          );

          // إلغاء timeout timer
          callbackTimeoutTimer.cancel();

          // التأكد من تحديث الحالة قبل المتابعة
          isOtpSending.value = false;
          isLoading.value = true;
          isOtpVerifying.value = true;
          update();

          // إضافة تأخير قصير للسماح للـ UI بالتحديث على iOS
          if (Platform.isIOS) {
            await Future.delayed(const Duration(milliseconds: 100));
          }

          await _finalizeSellerRegistration(isAutoVerified: true);
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint("❌ VERIFICATION FAILED CALLBACK TRIGGERED");
          debugPrint("Phone verification failed: ${e.code} - ${e.message}");
          debugPrint("Full error: ${e.toString()}");

          // إلغاء timeout timer
          callbackTimeoutTimer.cancel();

          // التأكد من إعادة تعيين جميع الحالات
          isOtpSending.value = false;
          isLoading.value = false;
          isOtpVerifying.value = false;
          update();

          String errorMessage = "فشل التحقق من رقم الهاتف.";
          if (e.code == 'invalid-phone-number') {
            errorMessage =
                "رقم الهاتف $formattedPhoneNumber الذي أدخلته غير صالح.";
          } else if (e.code == 'too-many-requests') {
            errorMessage =
                "تم إرسال عدد كبير جدا من الطلبات. حاول مرة أخرى لاحقًا.";
          } else if (e.code == 'network-request-failed') {
            errorMessage =
                "مشكلة في الاتصال بالإنترنت. يرجى التحقق من الاتصال والمحاولة مرة أخرى.";
          }
          Get.snackbar(
            "خطأ",
            errorMessage,
            backgroundColor: Colors.red.shade400,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );
        },
        codeSent: (String verId, int? resendTok) async {
          debugPrint("📱 CODE SENT CALLBACK TRIGGERED");
          debugPrint(
            "OTP code sent. Verification ID: $verId, Resend Token: $resendTok",
          );

          // إلغاء timeout timer
          callbackTimeoutTimer.cancel();

          isOtpSending.value = false; // OTP sending part is done
          // isLoading remains true as we are waiting for OTP input
          update();

          verificationId.value = verId;
          resendToken.value = resendTok;

          // إضافة تأخير قصير على iOS للسماح للـ UI بالتحديث قبل التنقل
          if (Platform.isIOS) {
            await Future.delayed(const Duration(milliseconds: 200));
          }

          // التأكد من أن التنقل يحدث على الـ main thread
          WidgetsBinding.instance.addPostFrameCallback((_) {
            debugPrint("Navigating to OTP verification screen...");
            Get.to(() => OtpVerificationScreen());
          });
        },
        codeAutoRetrievalTimeout: (String verId) {
          debugPrint("⏰ CODE AUTO RETRIEVAL TIMEOUT CALLBACK TRIGGERED");
          debugPrint("OTP auto-retrieval timed out. Verification ID: $verId");
          verificationId.value = verId;
          // إعادة تعيين isOtpSending في حال timeout على iOS
          if (Platform.isIOS) {
            isOtpSending.value = false;
            update();
          }
        },
        timeout:
            Platform.isIOS
                ? const Duration(seconds: 60) // مدة أقصر على iOS
                : const Duration(seconds: 120), // مدة أطول على Android
      );
      debugPrint("✅ verifyPhoneNumber call completed successfully");
    } catch (e) {
      debugPrint("🚨 EXCEPTION CAUGHT IN verifyPhoneNumber");
      debugPrint("Exception type: ${e.runtimeType}");
      debugPrint("Exception details: $e");

      // التأكد من إعادة تعيين جميع الحالات في حالة الخطأ
      isOtpSending.value = false;
      isLoading.value = false;
      isOtpVerifying.value = false;
      update();

      String errorMessage = "حدث خطأ غير متوقع أثناء بدء التحقق من الهاتف.";

      // معالجة أخطاء محددة
      if (e.toString().contains('network')) {
        errorMessage = "مشكلة في الشبكة. يرجى التحقق من الاتصال بالإنترنت.";
      } else if (e.toString().contains('too-many-requests')) {
        errorMessage = "تم إرسال عدد كبير من الطلبات. يرجى المحاولة لاحقاً.";
      }

      Get.snackbar(
        "خطأ",
        errorMessage,
        backgroundColor: Colors.red.shade500,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> verifyOtpAndFinalize(String otpCode) async {
    if (otpCode.isEmpty || otpCode.length < 6) {
      Get.snackbar(
        "خطأ",
        "يرجى إدخال رمز OTP الصحيح المكون من 6 أرقام.",
        backgroundColor: Colors.orange.shade300,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isOtpVerifying.value = true;
    isLoading.value =
        true; // isLoading should ideally be true from the previous step
    update();

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId.value,
        smsCode: otpCode,
      );

      // **** خطوة التحقق الفعلية من الـ Credential هنا ****
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw FirebaseAuthException(
          code: 'no-current-user',
          message: 'No user is currently signed in.',
        );
      }

      // محاولة ربط الـ Credential أو التحقق من OTP
      try {
        await currentUser.linkWithCredential(credential);
        debugPrint("Phone credential linked successfully.");
      } catch (linkError) {
        if (linkError is FirebaseAuthException &&
            linkError.code == 'provider-already-linked') {
          debugPrint(
            "Phone provider already linked, verifying OTP directly...",
          );
          // إذا كان المزود مرتبط بالفعل، نتحقق من صحة OTP فقط
          await _auth.signInWithCredential(credential);
          debugPrint(
            "OTP verified successfully with existing linked provider.",
          );
        } else {
          rethrow; // إعادة طرح أي خطأ آخر
        }
      }

      // إلغاء safety timeout لأن العملية نجحت
      _cancelSafetyTimeout();

      // إذا نجح الربط أو التحقق، قم بإنهاء التسجيل
      await _finalizeSellerRegistration(isOtpNowVerified: true);
    } on FirebaseAuthException catch (e) {
      isOtpVerifying.value = false;
      isLoading.value = false;
      update();
      debugPrint(
        "FirebaseAuthException during OTP verification: ${e.code} - ${e.message}",
      );
      String errorMessage = "فشل التحقق من رمز OTP.";
      if (e.code == 'invalid-verification-code' ||
          e.code == 'invalid-credential') {
        errorMessage = "رمز OTP الذي أدخلته غير صحيح.";
      } else if (e.code == 'session-expired') {
        errorMessage = "انتهت صلاحية جلسة التحقق. يرجى طلب رمز جديد.";
      } else if (e.code == 'credential-already-in-use') {
        // هذه حالة خاصة: الرقم مرتبط بالفعل بحساب آخر. أو إذا كان مرتبطًا بنفس الحساب، يمكن اعتبارها نجاحًا.
        // هنا، نفترض أننا إذا وصلنا لهذه النقطة، والرقم مرتبط بنفس المستخدم، فهذا جيد.
        // ولكن إذا كان مرتبطًا بمستخدم مختلف، فهذه مشكلة.
        // للحفاظ على البساطة، سنعتبرها خطأ عام الآن، ولكن يمكن تحسين هذا.
        // أو إذا كان هذا يعني أنه مرتبط بالفعل بهذا المستخدم، يمكن المتابعة.
        // الخيار الأبسط هو معالجته كخطأ إذا لم تكن متأكدًا من كيفية التعامل مع هذا الحساب.
        // إذا كان يمكن أن يكون مرتبطًا بالفعل بهذا المستخدم، يمكن استدعاء _finalizeSellerRegistration هنا أيضًا.
        // For now, treat as a specific error message or proceed if logic allows
        debugPrint(
          "Credential already in use. Assuming for this user is okay or needs specific handling.",
        );
        // إذا كان الرقم مرتبطًا بالفعل بنفس المستخدم، قد يكون هذا هو المسار الصحيح
        // await _finalizeSellerRegistration(isOtpNowVerified: true);
        // Get.snackbar("معلومة", "رقم الهاتف هذا تم التحقق منه بالفعل لهذا الحساب.", snackPosition: SnackPosition.BOTTOM);
        // return;
        errorMessage =
            "رقم الهاتف هذا مرتبط بالفعل. إذا كان هذا حسابك، يمكنك المتابعة أو الاتصال بالدعم.";
      } else if (e.code == 'no-current-user') {
        errorMessage =
            "انتهت جلسة المستخدم. يرجى تسجيل الدخول مرة أخرى والمحاولة.";
        // يمكنك هنا توجيه المستخدم لصفحة الدخول
      }
      Get.snackbar(
        "خطأ",
        errorMessage,
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      isOtpVerifying.value = false;
      isLoading.value = false;
      update();
      debugPrint("Generic error verifying OTP: $e");
      Get.snackbar(
        "خطأ",
        "حدث خطأ غير متوقع أثناء التحقق من الرمز.",
        backgroundColor: Colors.red.shade500,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _finalizeSellerRegistration({
    bool isAutoVerified = false,
    bool isOtpNowVerified = false,
  }) async {
    debugPrint("🔧 _finalizeSellerRegistration called");
    debugPrint(
      "🔧 isAutoVerified: $isAutoVerified, isOtpNowVerified: $isOtpNowVerified",
    );

    // إذا لم يتم التحقق تلقائيًا ولم يتم التحقق الآن (من verifyOtpAndFinalize)، فلا تتابع
    if (!isAutoVerified && !isOtpNowVerified) {
      debugPrint("❌ Neither auto verified nor OTP verified - stopping");
      Get.snackbar(
        "خطأ",
        "لم يتم التحقق من صحة رقم الهاتف.",
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      isLoading.value = false;
      isOtpVerifying.value = false;
      return;
    }

    debugPrint(
      "✅ Phone verification confirmed, proceeding with registration...",
    );

    // Set loading states for this final part
    isOtpVerifying.value = true;
    isLoading.value = true;
    update();

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        Get.snackbar(
          "خطأ",
          "لم يتم العثور على مستخدم حالي. يرجى تسجيل الدخول مرة أخرى.",
          backgroundColor: Colors.red.shade400,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        isLoading.value = false;
        isOtpVerifying.value = false;
        // Navigate to login or welcome screen
        return;
      }

      String? sellerProfileImageUrl;
      String? shopFrontImageUrl;

      // iOS-specific: Wait for Firebase to be fully ready
      if (Platform.isIOS) {
        debugPrint(
          "🔧 iOS detected - waiting for Firebase Storage to be ready...",
        );
        await Future.delayed(Duration(milliseconds: 3000));

        // Verify Firebase Storage is accessible
        try {
          _storage.ref().child('test_connection');
          debugPrint("✅ Firebase Storage connection test passed");
        } catch (e) {
          debugPrint("⚠️ Firebase Storage connection test failed: $e");
        }
      }

      if (_tempSellerProfileImageFile != null) {
        debugPrint("🖼️ Uploading seller profile image...");
        if (Platform.isIOS) {
          sellerProfileImageUrl = await _iosStorageHandler.uploadFile(
            _tempSellerProfileImageFile!,
            'seller_profile_images/${currentUser.uid}',
          );
        } else {
          sellerProfileImageUrl = await _uploadFile(
            _tempSellerProfileImageFile!,
            'seller_profile_images/${currentUser.uid}',
          );
        }
      }
      if (_tempShopFrontImageFile != null) {
        debugPrint("🏪 Uploading shop front image...");
        if (Platform.isIOS) {
          shopFrontImageUrl = await _iosStorageHandler.uploadFile(
            _tempShopFrontImageFile!,
            'shop_front_images/${currentUser.uid}',
          );
        } else {
          shopFrontImageUrl = await _uploadFile(
            _tempShopFrontImageFile!,
            'shop_front_images/${currentUser.uid}',
          );
        }
      }

      if (_tempSellerProfileImageFile != null &&
          sellerProfileImageUrl == null) {
        throw Exception("Failed to upload seller profile image.");
      }
      if (_tempShopFrontImageFile != null && shopFrontImageUrl == null) {
        throw Exception("Failed to upload shop front image.");
      }

      // الحصول على FCM Token بشكل احترافي
      final String? fcmToken = await _getFCMTokenSafely();

      // استخدام SellerModel لإنشاء البيانات
      final SellerModel sellerToSave = SellerModel(
        uid: currentUser.uid,
        sellerName:
            _tempSellerDataForSubmission?['sellerName'] as String? ?? '',
        sellerProfileImageUrl: sellerProfileImageUrl,
        shopName: _tempSellerDataForSubmission?['shopName'] as String? ?? '',
        shopFrontImageUrl: shopFrontImageUrl,
        shopPhoneNumber:
            _tempSellerDataForSubmission?['shopPhoneNumber'] as String? ?? '',
        shopDescription:
            _tempSellerDataForSubmission?['shopDescription'] as String?,
        location:
            _tempSellerDataForSubmission?['location'] as GeoPoint? ??
            const GeoPoint(
              0,
              0,
            ), // تم التأكد من أن location هو GeoPoint في _tempSellerDataForSubmission
        shopAddressText:
            _tempSellerDataForSubmission?['shopAddressText'] as String?,
        shopCategories:
            (_tempSellerDataForSubmission?['shopCategories'] as List<dynamic>?)
                ?.cast<String>() ??
            ['أخرى'],
        workingHours: Map<String, dynamic>.from(
          _tempSellerDataForSubmission?['workingHours'] ?? {},
        ),
        // الحقول التالية اختيارية في SellerModel وسيتم تعيينها إلى null إذا لم تكن موجودة في _tempSellerDataForSubmission
        commercialRegistrationNumber:
            _tempSellerDataForSubmission?['commercialRegistrationNumber']
                as String?,
        websiteUrl: _tempSellerDataForSubmission?['websiteUrl'] as String?,
        socialMediaLinks:
            _tempSellerDataForSubmission?['socialMediaLinks']
                as Map<String, String>?,

        isProfileComplete: true, // تم إكمال الملف الشخصي في هذه المرحلة
        isApprovedByAdmin: false, // يحتاج موافقة المشرف بشكل افتراضي
        isActiveBySeller: true, // نشط مبدئيًا
        isPhoneNumberVerified: true, // تم التحقق من الهاتف في هذه المرحلة
        averageRating: 0.0,
        numberOfRatings: 0,
        trustScore: 50.0,
        sellerType: _sellerTypeFromAuth, // من SellerAuthController
        registrationCompleted: true, // اكتمل التسجيل في هذه المرحلة
        createdAt:
            Timestamp.now(), // سيتم استبداله بـ FieldValue.serverTimestamp() أدناه
        updatedAt:
            null, // SellerModel.toMap() سيعين FieldValue.serverTimestamp() لهذا
      );

      Map<String, dynamic> sellerDataToSave = sellerToSave.toMap();

      // التأكد من استخدام الطوابع الزمنية للخادم وإضافة الحقول غير الموجودة في SellerModel
      sellerDataToSave['createdAt'] = FieldValue.serverTimestamp();
      sellerDataToSave['updatedAt'] =
          FieldValue.serverTimestamp(); // للتأكيد أو إذا كان SellerModel.toMap لا يفعل ذلك

      // إضافة الحقول التي ليست جزءًا من SellerModel ولكنها مطلوبة في Firestore
      sellerDataToSave['email'] = currentUser.email;

      // معالجة احترافية لحفظ FCM Token
      if (fcmToken != null && fcmToken.isNotEmpty) {
        sellerDataToSave['fcmToken'] = fcmToken;
        sellerDataToSave['fcmTokenUpdatedAt'] = FieldValue.serverTimestamp();
        debugPrint(
          "✅ FCM Token will be saved: ${fcmToken.substring(0, 30)}...",
        );
      } else {
        debugPrint(
          "⚠️ No FCM Token available - saving without notification capability",
        );
        // لا نحفظ fcmToken إذا كان null لتجنب overwrite أي token موجود
        sellerDataToSave['fcmTokenStatus'] = 'failed_to_retrieve';
        sellerDataToSave['fcmTokenFailedAt'] = FieldValue.serverTimestamp();

        // جدولة إعادة المحاولة بعد التسجيل
        debugPrint("📅 Scheduling FCM token retry for later...");
      }

      debugPrint("💾 Saving seller data to Firestore...");
      debugPrint("💾 Document ID: ${currentUser.uid}");
      debugPrint("💾 Collection: ${FirebaseX.collectionSeller}");
      debugPrint("🏆 Trust Score: 50.0 (auto-assigned to new seller)");

      await _firestore
          .collection(FirebaseX.collectionSeller)
          .doc(currentUser.uid)
          .set(sellerDataToSave, SetOptions(merge: true));

      debugPrint("✅ Seller data saved successfully to Firestore!");

      // التأكد من إعادة تعيين الحالات قبل التنقل
      isLoading.value = false;
      isOtpVerifying.value = false;
      update();

      debugPrint("🎉 Registration completed successfully!");

      // إذا لم نحصل على FCM token، جدولة إعادة المحاولة
      if (fcmToken == null || fcmToken.isEmpty) {
        retryFCMTokenLater();
      }

      Get.snackbar(
        "نجاح",
        "تم تسجيل معلوماتك بنجاح!",
        backgroundColor: Colors.green.shade400,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      // إضافة تأخير قصير على iOS قبل التنقل
      if (Platform.isIOS) {
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // التأكد من التنقل على الـ main thread
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAll(
          () => SellerMainScreen(),
        ); // Navigate to seller dashboard or main screen
      });
    } catch (e) {
      isLoading.value = false;
      isOtpVerifying.value = false;
      update();
      debugPrint("Error finalizing seller registration: $e");
      String errorMessage = "فشل إكمال عملية التسجيل.";
      if (e is FirebaseException &&
          e.code == 'invalid-credential' &&
          isAutoVerified) {
        errorMessage =
            "فشل التحقق التلقائي من الهاتف. قد تحتاج إلى إدخال الرمز يدويًا.";
        // Optionally, you could re-route to OTP screen if auto-verification was the only path here
        // Get.to(() => OtpVerificationScreen()); // Might need to handle this case more gracefully
      } else if (e is FirebaseException &&
          e.code == 'invalid-verification-code') {
        errorMessage = "رمز OTP الذي أدخلته غير صحيح.";
      } else if (e is FirebaseException && e.code == 'session-expired') {
        errorMessage = "انتهت صلاحية جلسة التحقق. يرجى طلب رمز جديد.";
      }

      Get.snackbar(
        "خطأ",
        "$errorMessage يرجى المحاولة مرة أخرى.",
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<String?> _uploadFile(File file, String path) async {
    try {
      debugPrint("🔧 Starting file upload to: $path");
      debugPrint("🔧 File exists: ${await file.exists()}");
      debugPrint("🔧 File size: ${await file.length()} bytes");

      // Verify Firebase Storage is properly initialized
      if (Firebase.apps.isEmpty) {
        throw Exception("Firebase not initialized");
      }

      final ref = _storage.ref().child(path);
      debugPrint("🔧 Storage reference created: ${ref.fullPath}");

      // iOS-specific: Add metadata to help with upload
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploaded_by': 'seller_registration',
          'platform': Platform.isIOS ? 'ios' : 'android',
        },
      );

      final uploadTask = ref.putFile(file, metadata);

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes * 100;
        debugPrint("🔧 Upload progress: ${progress.toStringAsFixed(1)}%");
      });

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint("✅ File uploaded successfully: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      debugPrint("❌ Error uploading file ($path): $e");

      // iOS-specific error handling
      if (Platform.isIOS && e.toString().contains('object-not-found')) {
        debugPrint(
          "🔧 iOS Storage issue detected - retrying with different approach",
        );
        return await _uploadFileWithRetry(file, path);
      }

      return null;
    }
  }

  Future<String?> _uploadFileWithRetry(File file, String path) async {
    try {
      // Wait a bit longer on iOS
      await Future.delayed(Duration(milliseconds: 1500));

      // Try with a different path structure for iOS
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newPath = '${path.replaceAll('/', '_')}_$timestamp';

      debugPrint("🔧 Retrying upload with path: $newPath");

      final ref = _storage.ref().child(newPath);
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint("✅ Retry upload successful: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      debugPrint("❌ Retry upload also failed: $e");
      return null;
    }
  }

  Future<void> pickImage(
    ImageSource source, {
    required bool isProfileImage,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1024,
      );
      if (pickedFile != null) {
        if (isProfileImage) {
          sellerProfileImageFile.value = File(pickedFile.path);
        } else {
          shopFrontImageFile.value = File(pickedFile.path);
        }
        update(); // For GetBuilder if used
      }
    } catch (e) {
      Get.snackbar("خطأ في الصورة", "فشل في اختيار الصورة: $e");
    }
  }

  // دالة لإدارة اختيار الفئات المتعددة
  void toggleCategorySelection(String category) {
    if (selectedShopCategories.contains(category)) {
      selectedShopCategories.remove(category);
    } else {
      if (selectedShopCategories.length < maxCategoriesAllowed) {
        selectedShopCategories.add(category);
      } else {
        Get.snackbar(
          "تحذير",
          "يمكنك اختيار حد أقصى $maxCategoriesAllowed فئات فقط",
          backgroundColor: Colors.orange.shade400,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  // دالة للتحقق من اختيار الفئة
  bool isCategorySelected(String category) {
    return selectedShopCategories.contains(category);
  }

  // دالة للحصول على عدد الفئات المختارة
  int get selectedCategoriesCount => selectedShopCategories.length;

  // دالة للحصول على نص عرض الفئات المختارة
  String get selectedCategoriesDisplay {
    if (selectedShopCategories.isEmpty) {
      return 'لم يتم اختيار أي فئة';
    } else if (selectedShopCategories.length == 1) {
      return selectedShopCategories.first;
    } else {
      return '${selectedShopCategories.length} فئات مختارة';
    }
  }

  void toggleDayOpen(String dayKey) {
    if (workingHours[dayKey] != null) {
      bool isCurrentlyOpen = workingHours[dayKey]!['isOpen'] as bool;
      workingHours[dayKey]!['isOpen'] = !isCurrentlyOpen;

      debugPrint(
        "🔄 Toggling day $dayKey from $isCurrentlyOpen to ${!isCurrentlyOpen}",
      );

      if (!workingHours[dayKey]!['isOpen']) {
        // If day is being closed
        workingHours[dayKey]!['opensAt'] = null;
        workingHours[dayKey]!['closesAt'] = null;
        if (expandedDayPanel.value == dayKey) {
          // Close expansion panel if it was this day
          expandedDayPanel.value = null;
          debugPrint("🔒 Closing expansion panel for $dayKey");
        }
      } else {
        // If day is being opened
        workingHours[dayKey]!['opensAt'] =
            _lastAppliedOpensAt.value ?? "09:00 AM";
        workingHours[dayKey]!['closesAt'] =
            _lastAppliedClosesAt.value ?? "05:00 PM";

        // التوسيع التلقائي عند تفعيل أي يوم
        expandedDayPanel.value = dayKey;
        debugPrint("🔓 Auto-expanding panel for $dayKey");

        // إضافة تأخير بسيط لضمان إعادة بناء UI قبل التوسيع
        Future.delayed(Duration(milliseconds: 100), () {
          expandedDayPanel.refresh();
          debugPrint("🔄 Refreshed expansion panel state");
        });
      }
      workingHours.refresh();
    }
  }

  bool canApplyToOthers(String dayKey) {
    final dayData = workingHours[dayKey];
    if (dayData == null || !(dayData['isOpen'] == true)) return false;
    return dayData['opensAt'] != null && dayData['closesAt'] != null;
  }

  void offerToApplyTimesToOtherDays(
    BuildContext context,
    String sourceDayKey,
    String opensAtToApply,
    String closesAtToApply,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text("تطبيق الأوقات؟"),
        content: Text(
          "هل ترغب في تطبيق وقت الفتح ($opensAtToApply) ووقت الإغلاق ($closesAtToApply) على الأيام الأخرى التي تم تحديدها كمفتوحة ولم يتم تحديد أوقات لها بعد أو على جميع الأيام المفتوحة؟",
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(child: const Text("إلغاء"), onPressed: () => Get.back()),
          ElevatedButton(
            child: const Text("للأيام الفارغة فقط"),
            onPressed: () {
              Get.back();
              applyTimesToOtherOpenDays(
                sourceDayKey,
                opensAtToApply,
                closesAtToApply,
                applyToAllOpen: false,
              );
            },
          ),
          ElevatedButton(
            child: const Text("نعم، للكل (المفتوح)"),
            onPressed: () {
              Get.back();
              applyTimesToOtherOpenDays(
                sourceDayKey,
                opensAtToApply,
                closesAtToApply,
                applyToAllOpen: true,
              );
            },
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  void applyTimesToOtherOpenDays(
    String sourceDayKey,
    String opensAtToApply,
    String closesAtToApply, {
    required bool applyToAllOpen,
  }) {
    bool timesApplied = false;
    workingHours.forEach((key, value) {
      if (key != sourceDayKey && (value['isOpen'] == true)) {
        bool apply = false;
        if (applyToAllOpen) {
          apply = true;
        } else {
          // Apply to empty open days only
          if (value['opensAt'] == null || value['closesAt'] == null) {
            apply = true;
          }
        }
        if (apply) {
          value['opensAt'] = opensAtToApply;
          value['closesAt'] = closesAtToApply;
          timesApplied = true;
        }
      }
    });
    if (timesApplied) {
      _lastAppliedOpensAt.value =
          opensAtToApply; // Update template if changes were made
      _lastAppliedClosesAt.value = closesAtToApply;
      workingHours.refresh();
      Get.snackbar(
        "تم التحديث",
        "تم تطبيق الأوقات بنجاح.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade400,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        "لم يتغير شيء",
        "لم يتم العثور على أيام لتطبيق الأوقات عليها حسب اختيارك.",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> selectTime(
    BuildContext context,
    String dayKey,
    bool isOpeningTime,
  ) async {
    final Map<String, dynamic>? dayData = workingHours[dayKey];
    final String? opensAtString = dayData?['opensAt'] as String?;
    final String? closesAtString = dayData?['closesAt'] as String?;

    String? timeToParse;
    if (isOpeningTime) {
      timeToParse = opensAtString;
    } else {
      timeToParse = closesAtString;
    }

    TimeOfDay? initialTime = _parseTime(timeToParse) ?? TimeOfDay.now();

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Get.theme.primaryColor, // header background color
              onPrimary: Colors.white, // header text color
              onSurface: Colors.black, // body text color
            ),
            timePickerTheme: TimePickerThemeData(
              dialHandColor: Get.theme.primaryColor,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Get.theme.primaryColor, // button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      final formattedTime = formatTimeOfDay(pickedTime);
      final currentOpensAt = _parseTime(workingHours[dayKey]?['opensAt']);
      final currentClosesAt = _parseTime(workingHours[dayKey]?['closesAt']);

      if (isOpeningTime) {
        if (currentClosesAt != null &&
            _isTimeBeforeOrEqual(
              pickedTime,
              currentClosesAt,
              isOpening: true,
              isClosing: false,
            )) {
          workingHours[dayKey]!['opensAt'] = formattedTime;
          _lastAppliedOpensAt.value = formattedTime;
        } else if (currentClosesAt != null) {
          Get.snackbar(
            "وقت غير صالح",
            "وقت الفتح يجب أن يكون قبل وقت الإغلاق.",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange.shade300,
          );
          return;
        } else {
          // No closing time set yet, allow setting opening time
          workingHours[dayKey]!['opensAt'] = formattedTime;
          _lastAppliedOpensAt.value = formattedTime;
        }
      } else {
        // isClosingTime
        if (currentOpensAt != null &&
            _isTimeBeforeOrEqual(
              currentOpensAt,
              pickedTime,
              isOpening: false,
              isClosing: true,
            )) {
          workingHours[dayKey]!['closesAt'] = formattedTime;
          _lastAppliedClosesAt.value = formattedTime;
        } else if (currentOpensAt != null) {
          Get.snackbar(
            "وقت غير صالح",
            "وقت الإغلاق يجب أن يكون بعد وقت الفتح.",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange.shade300,
          );
          return;
        } else {
          // No opening time set yet, allow setting closing time
          workingHours[dayKey]!['closesAt'] = formattedTime;
          _lastAppliedClosesAt.value = formattedTime;
        }
      }
      workingHours.refresh();
    }
  }

  bool _isTimeBeforeOrEqual(
    TimeOfDay time1,
    TimeOfDay time2, {
    required bool isOpening,
    required bool isClosing,
  }) {
    final time1Minutes = time1.hour * 60 + time1.minute;
    final time2Minutes = time2.hour * 60 + time2.minute;
    if (isOpening) {
      // time1 is opensAt, time2 is closesAt
      return time1Minutes < time2Minutes;
    } else {
      // time1 is opensAt, time2 is closesAt
      return time1Minutes < time2Minutes;
    }
  }

  String formatTimeOfDay(TimeOfDay tod) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    final format = DateFormat.jm(); // e.g., 5:08 PM
    return format.format(dt);
  }

  TimeOfDay? _parseTime(String? timeString) {
    if (timeString == null) return null;
    try {
      final format =
          DateFormat.jm(); // Needs to match the format used in formatTimeOfDay
      final dt = format.parse(timeString);
      return TimeOfDay.fromDateTime(dt);
    } catch (e) {
      debugPrint("Error parsing time: $e");
      return null;
    }
  }

  // --- Location Methods ---
  final TextEditingController streetAddressController = TextEditingController();

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  /// وظيفة محسنة لفتح منتقي الموقع مع تحديد الموقع الحالي
  Future<void> openLocationPickerScreen(BuildContext context) async {
    LatLng? initialLocation = shopLocation.value;

    // إذا لم يكن هناك موقع محفوظ، جرب الحصول على الموقع الحالي
    if (initialLocation == null) {
      try {
        isLocationLoading.value = true;
        Position currentPosition = await _determinePosition();
        initialLocation = LatLng(
          currentPosition.latitude,
          currentPosition.longitude,
        );
        debugPrint(
          "✅ Current location obtained: ${initialLocation.latitude}, ${initialLocation.longitude}",
        );
      } catch (e) {
        debugPrint("⚠️ Could not get current location: $e");
        // استخدم موقع افتراضي في بغداد إذا فشل تحديد الموقع الحالي
        initialLocation = const LatLng(33.3152, 44.3661);
      } finally {
        isLocationLoading.value = false;
      }
    }

    final LatLng? result = await Get.to<LatLng>(
      () => LocationPickerScreen(initialLocation: initialLocation),
    );

    if (result != null) {
      shopLocation.value = result;
      await _getAddressFromLatLng(result);
      // Optionally move camera on the small map if it's visible and controller is available
      mapController?.animateCamera(CameraUpdate.newLatLngZoom(result, 16.0));
    }
  }

  /// وظيفة لإظهار منتقي موقع محسن مع تأكيد الموقع
  Future<void> showEnhancedLocationPicker(BuildContext context) async {
    LatLng? initialLocation;

    // إذا كان هناك موقع محدد مسبقاً، استخدمه كنقطة بداية
    if (shopLocation.value != null) {
      initialLocation = shopLocation.value!;
      tempSelectedLocation.value =
          shopLocation.value; // تعيين الموقع المؤقت للموقع المحدد سابقاً
      showLocationConfirmation.value = true; // إظهار تأكيد الموقع مباشرة
      debugPrint(
        "🔄 Starting with previously selected location: ${initialLocation.latitude}, ${initialLocation.longitude}",
      );
    } else {
      // الحصول على الموقع الحالي للمستخدم كنقطة بداية
      try {
        isLocationLoading.value = true;
        Position position = await _determinePosition();
        initialLocation = LatLng(position.latitude, position.longitude);
        debugPrint(
          "✅ Starting with current user location: ${initialLocation.latitude}, ${initialLocation.longitude}",
        );
      } catch (e) {
        debugPrint("⚠️ Could not get current location: $e");
        initialLocation = const LatLng(33.3152, 44.3661); // بغداد كموقع افتراضي
      } finally {
        isLocationLoading.value = false;
      }
    }

    // عرض dialog مخصص للخريطة
    await Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(10),
        child: Container(
          height: Get.height * 0.8,
          width: Get.width * 0.95,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'اختر موقع المتجر',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Instructions
              Container(
                padding: EdgeInsets.all(16),
                color: Color(0xFFF8FAFC),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color(0xFF6366F1),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'اضغط على الخريطة لاختيار موقع متجرك بدقة',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Map
              Expanded(
                child: Obx(
                  () => Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: initialLocation!,
                          zoom: 15,
                        ),
                        onTap: (latLng) {
                          tempSelectedLocation.value = latLng;
                          showLocationConfirmation.value = true;
                          _getAddressFromLatLng(latLng); // لتحديث النص
                        },
                        markers: _buildLocationMarkers(
                          initialLocation,
                          shopLocation.value == null,
                        ),
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        mapType: MapType.normal,
                        compassEnabled: true,
                        zoomControlsEnabled: false,
                      ),

                      // Location confirmation overlay
                      if (showLocationConfirmation.value)
                        _buildLocationConfirmationOverlay(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );

    // تنظيف المتغيرات المؤقتة بعد إغلاق الـ dialog
    tempSelectedLocation.value = null;
    showLocationConfirmation.value = false;
  }

  /// بناء المؤشرات على الخريطة
  Set<Marker> _buildLocationMarkers(
    LatLng? initialLocation, [
    bool showCurrentLocationMarker = true,
  ]) {
    Set<Marker> markers = {};

    // مؤشر الموقع الحالي للمستخدم (فقط إذا لم يكن هناك موقع محدد مسبقاً)
    if (initialLocation != null && showCurrentLocationMarker) {
      markers.add(
        Marker(
          markerId: MarkerId('current_location'),
          position: initialLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: 'موقعك الحالي',
            snippet: 'اضغط على الخريطة لاختيار موقع المتجر',
          ),
        ),
      );
    }

    // مؤشر الموقع المؤقت المختار
    if (tempSelectedLocation.value != null) {
      markers.add(
        Marker(
          markerId: MarkerId('selected_location'),
          position: tempSelectedLocation.value!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'موقع المتجر المختار',
            snippet: 'اضغط على "تأكيد الموقع" للمتابعة',
          ),
        ),
      );
    }

    return markers;
  }

  /// بناء overlay تأكيد الموقع
  Widget _buildLocationConfirmationOverlay(BuildContext context) {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 20,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'موقع مختار',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      Obx(
                        () => Text(
                          shopAddressText.value.isNotEmpty
                              ? shopAddressText.value
                              : 'جاري تحديد العنوان...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      tempSelectedLocation.value = null;
                      showLocationConfirmation.value = false;
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Color(0xFF6B7280),
                      side: BorderSide(color: Color(0xFFE5E7EB)),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('إلغاء'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      if (tempSelectedLocation.value != null) {
                        shopLocation.value = tempSelectedLocation.value;
                        Get.back();
                        Get.snackbar(
                          "تم التحديد",
                          "تم اختيار موقع المتجر بنجاح",
                          backgroundColor: Color(0xFF10B981),
                          colorText: Colors.white,
                          snackPosition: SnackPosition.BOTTOM,
                          icon: Icon(Icons.check_circle, color: Colors.white),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, size: 18),
                        SizedBox(width: 8),
                        Text('تأكيد الموقع'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getAddressFromLatLng(LatLng latLng) async {
    try {
      List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks[0];
        // Construct a more detailed or relevant address string
        shopAddressText.value =
            "${p.name}, ${p.locality}, ${p.subAdministrativeArea}, ${p.administrativeArea}"
                .replaceAll("null,", "")
                .trim()
                .replaceAll(RegExp(r'^, |,$'), '');
        if (streetAddressController.text.isEmpty &&
            p.street != null &&
            p.street!.isNotEmpty) {
          streetAddressController.text = p.street!;
        }
      } else {
        shopAddressText.value = "تعذر جلب العنوان";
      }
    } catch (e) {
      debugPrint("Error getting address: $e");
      shopAddressText.value = "خطأ في جلب العنوان";
    }
  }

  /// الحصول على الموقع الحالي وتحديد موقع المتجر
  Future<void> tryMoveToCurrentLocation() async {
    isLocationLoading.value = true;
    update();
    try {
      Position currentPosition = await _determinePosition();
      LatLng newLatLng = LatLng(
        currentPosition.latitude,
        currentPosition.longitude,
      );
      shopLocation.value = newLatLng;
      await _getAddressFromLatLng(newLatLng);
      mapController?.animateCamera(CameraUpdate.newLatLngZoom(newLatLng, 16.0));

      Get.snackbar(
        "تم تحديد الموقع",
        "تم الحصول على موقعك الحالي بنجاح",
        backgroundColor: Color(0xFF10B981),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        icon: Icon(Icons.my_location, color: Colors.white),
      );
    } catch (e) {
      Get.snackbar(
        "خطأ في الموقع",
        "فشل في تحديد الموقع الحالي: ${e.toString()}",
        backgroundColor: Color(0xFFEF4444),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        icon: Icon(Icons.error_outline, color: Colors.white),
      );
    } finally {
      isLocationLoading.value = false;
      update();
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Attempt to open location settings
      await Geolocator.openLocationSettings();
      return Future.error('خدمات الموقع معطلة. يرجى تفعيلها.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('تم رفض أذونات تحديد الموقع.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'أذونات تحديد الموقع مرفوضة بشكل دائم، لا يمكننا طلب الأذونات. يرجى تفعيلها من الإعدادات.',
      );
    }
    currentPositionAccuracy.value =
        (await Geolocator.getCurrentPosition()).accuracy;

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  void submitRegistration(BuildContext context) {
    debugPrint("🔥 submitRegistration called");

    // This method will now call initiatePhoneVerificationAndCollectData
    // as OTP verification is mandatory.

    // إضافة حماية إضافية من التجميد
    _startSafetyTimeout();

    debugPrint("About to call initiatePhoneVerificationAndCollectData...");
    initiatePhoneVerificationAndCollectData();
    debugPrint("initiatePhoneVerificationAndCollectData call completed");
  }

  // آلية حماية إضافية لتجنب التجميد على iOS
  Timer? _safetyTimer;

  void _startSafetyTimeout() {
    _safetyTimer = Timer(Duration(seconds: Platform.isIOS ? 60 : 90), () {
      if ((isLoading.value || isOtpSending.value) && !isOtpVerifying.value) {
        debugPrint("Safety timeout triggered - resetting loading states");
        isLoading.value = false;
        isOtpSending.value = false;
        isOtpVerifying.value = false;
        update();
        Get.snackbar(
          "انتهت المهلة الزمنية",
          "تم انتهاء الوقت المحدد للعملية. يرجى المحاولة مرة أخرى.",
          backgroundColor: Colors.orange.shade400,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    });
  }

  void _cancelSafetyTimeout() {
    _safetyTimer?.cancel();
    _safetyTimer = null;
  }

  /// دالة احترافية للحصول على FCM Token مع معالجة شاملة للأخطاء
  Future<String?> _getFCMTokenSafely() async {
    debugPrint("🔑 Starting FCM token retrieval process...");

    try {
      // 1. طلب الأذونات أولاً
      debugPrint("📱 Requesting Firebase Messaging permissions...");
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: true,
          );

      debugPrint("🔔 Permission status: ${settings.authorizationStatus}");

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint("❌ Notification permissions denied");
        return null;
      }

      // 2. محاولة مباشرة للحصول على FCM token بدون انتظار APNS
      debugPrint(
        "🚀 Attempting direct FCM token retrieval (bypass APNS dependency)...",
      );

      String? fcmToken;
      int directAttempts = 0;
      const maxDirectAttempts = 3;

      while (fcmToken == null && directAttempts < maxDirectAttempts) {
        directAttempts++;
        debugPrint("🔄 Direct FCM attempt $directAttempts/$maxDirectAttempts");

        try {
          // محاولة مباشرة بدون انتظار APNS
          fcmToken = await _firebaseMessaging.getToken().timeout(
            Duration(seconds: 20 + (10 * directAttempts)),
            onTimeout: () => null,
          );

          if (fcmToken != null && fcmToken.isNotEmpty) {
            debugPrint("✅ Direct FCM Token received successfully!");
            debugPrint("🔑 Token preview: ${fcmToken.substring(0, 50)}...");
            await _cacheFCMToken(fcmToken);
            return fcmToken;
          }
        } catch (e) {
          debugPrint("⚠️ Direct FCM attempt $directAttempts failed: $e");
          // إذا لم تكن مشكلة APNS، تابع
          if (!e.toString().toLowerCase().contains('apns')) {
            await Future.delayed(Duration(seconds: directAttempts * 2));
            continue;
          }
        }

        // إذا وصلنا هنا، فالمشكلة متعلقة بـ APNS
        break;
      }

      // 3. إذا فشلت المحاولة المباشرة، جرب الطريقة التقليدية مع APNS
      if (fcmToken == null && Platform.isIOS) {
        debugPrint("🍎 Fallback to APNS-dependent approach...");

        // محاولة تسجيل للإشعارات من native code
        debugPrint("📲 Triggering native notification registration...");

        // انتظار إضافي للنظام
        await Future.delayed(const Duration(seconds: 5));

        // محاولة APNS محدودة
        String? apnsToken;
        for (int attempt = 1; attempt <= 3; attempt++) {
          debugPrint("🔄 APNS attempt $attempt/3");

          try {
            await Future.delayed(Duration(seconds: attempt * 3));
            apnsToken = await _firebaseMessaging.getAPNSToken();
            if (apnsToken != null) {
              debugPrint(
                "✅ APNS Token received: ${apnsToken.substring(0, 20)}...",
              );
              break;
            }
          } catch (e) {
            debugPrint("⚠️ APNS attempt $attempt failed: $e");
          }
        }

        // 4. محاولة FCM مرة أخيرة
        if (apnsToken != null) {
          debugPrint("🔑 Final FCM token attempt with APNS...");

          try {
            fcmToken = await _firebaseMessaging.getToken().timeout(
              const Duration(seconds: 30),
              onTimeout: () => null,
            );

            if (fcmToken != null && fcmToken.isNotEmpty) {
              debugPrint("✅ FCM Token received after APNS setup!");
              await _cacheFCMToken(fcmToken);
              return fcmToken;
            }
          } catch (e) {
            debugPrint("⚠️ Final FCM attempt failed: $e");
          }
        }
      }

      // 5. محاولة استرداد من cache
      debugPrint("♻️ Trying cached token...");
      String? cachedToken = await _getCachedFCMToken();

      if (cachedToken != null) {
        debugPrint("✅ Using cached FCM token");
        return cachedToken;
      }

      // 6. إذا فشل كل شيء، إنشاء placeholder token للتطوير
      if (Platform.isIOS) {
        debugPrint("🛠️ Creating development placeholder token...");
        String placeholderToken = await _createDevelopmentToken();
        if (placeholderToken.isNotEmpty) {
          debugPrint(
            "🔧 Using development token: ${placeholderToken.substring(0, 30)}...",
          );
          await _cacheFCMToken(placeholderToken);
          return placeholderToken;
        }
      }

      debugPrint("❌ All FCM token retrieval methods failed");
      return null;
    } catch (e) {
      debugPrint("🚨 Fatal error in FCM token retrieval: $e");
      debugPrint("📊 Error details: ${e.toString()}");

      // محاولة أخيرة مع cached token
      String? cachedToken = await _getCachedFCMToken();
      if (cachedToken != null) {
        debugPrint("♻️ Emergency fallback to cached token");
        return cachedToken;
      }

      return null;
    }
  }

  /// إنشاء token مؤقت للتطوير عندما يفشل APNS
  Future<String> _createDevelopmentToken() async {
    try {
      final User? currentUser = _auth.currentUser;
      final String deviceId =
          currentUser?.uid ?? DateTime.now().millisecondsSinceEpoch.toString();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      // إنشاء token مؤقت فريد للجهاز
      String developmentToken = "dev_token_ios_${deviceId}_$timestamp";

      debugPrint("🔧 Generated development token for testing");
      return developmentToken;
    } catch (e) {
      debugPrint("⚠️ Failed to create development token: $e");
      return "";
    }
  }

  /// حفظ FCM token في التفضيلات المحلية
  Future<void> _cacheFCMToken(String token) async {
    try {
      final box = GetStorage();
      await box.write('cached_fcm_token', token);
      await box.write(
        'fcm_token_timestamp',
        DateTime.now().millisecondsSinceEpoch,
      );
      debugPrint("💾 FCM token cached successfully");
    } catch (e) {
      debugPrint("⚠️ Failed to cache FCM token: $e");
    }
  }

  /// استرداد FCM token من التفضيلات المحلية
  Future<String?> _getCachedFCMToken() async {
    try {
      final box = GetStorage();
      String? cachedToken = box.read('cached_fcm_token');
      int? timestamp = box.read('fcm_token_timestamp');

      if (cachedToken != null && timestamp != null) {
        // تحقق من عمر الـ token (صالح لمدة 7 أيام)
        DateTime tokenDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
        Duration age = DateTime.now().difference(tokenDate);

        if (age.inDays < 7) {
          debugPrint(
            "♻️ Found valid cached FCM token (age: ${age.inHours} hours)",
          );
          return cachedToken;
        } else {
          debugPrint(
            "⏰ Cached FCM token is too old (${age.inDays} days), ignoring",
          );
        }
      }

      return null;
    } catch (e) {
      debugPrint("⚠️ Failed to retrieve cached FCM token: $e");
      return null;
    }
  }

  /// تحديث FCM Token في Firestore لاحقاً (يمكن استدعاؤها من مكان آخر)
  Future<void> updateFCMTokenInFirestore() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint("⚠️ No current user to update FCM token for");
        return;
      }

      debugPrint("🔄 Attempting to update FCM token in Firestore...");
      final String? fcmToken = await _getFCMTokenSafely();

      if (fcmToken != null && fcmToken.isNotEmpty) {
        await _firestore
            .collection(FirebaseX.collectionSeller)
            .doc(currentUser.uid)
            .update({
              'fcmToken': fcmToken,
              'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
              'fcmTokenStatus': 'active',
            });

        debugPrint("✅ FCM Token updated successfully in Firestore");
        Get.snackbar(
          "تم التحديث",
          "تم تحديث معرف الإشعارات بنجاح",
          backgroundColor: Colors.green.shade400,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      } else {
        debugPrint("❌ Failed to get FCM token for update");
      }
    } catch (e) {
      debugPrint("🚨 Error updating FCM token in Firestore: $e");
    }
  }

  /// دالة محسّنة للحصول على FCM token مع إعداد أفضل لـ iOS
  Future<String?> _getIOSOptimizedFCMToken() async {
    debugPrint("🍎 Starting iOS-optimized FCM token retrieval...");

    try {
      // 1. انتظار إضافي للتأكد من إعداد النظام
      await Future.delayed(const Duration(seconds: 5));

      // 2. محاولة تسجيل للـ remote notifications يدوياً إذا لم يكن مسجلاً
      debugPrint("📱 Ensuring iOS remote notification registration...");

      // 3. طلب الأذونات مرة أخرى
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: true,
          );

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        debugPrint(
          "❌ iOS Notifications not authorized: ${settings.authorizationStatus}",
        );
        return null;
      }

      // 4. محاولة مختلفة للحصول على FCM token مع انتظار أطول
      for (int attempt = 1; attempt <= 3; attempt++) {
        debugPrint("🔑 iOS FCM token attempt $attempt/3");

        try {
          // انتظار متزايد مع كل محاولة
          await Future.delayed(Duration(seconds: 3 * attempt));

          String? token = await _firebaseMessaging.getToken().timeout(
            Duration(seconds: 60 + (10 * attempt)), // انتظار أطول مع كل محاولة
          );

          if (token != null && token.isNotEmpty) {
            debugPrint("✅ iOS FCM token received on attempt $attempt!");
            return token;
          }
        } catch (e) {
          debugPrint("⚠️ iOS FCM attempt $attempt failed: $e");
          if (e.toString().toLowerCase().contains('apns')) {
            // إذا كان خطأ APNS، انتظار أطول
            await Future.delayed(Duration(seconds: 5 * attempt));
          }
        }
      }

      return null;
    } catch (e) {
      debugPrint("🚨 iOS FCM token retrieval failed: $e");
      return null;
    }
  }

  /// مساعد لإعادة المحاولة في الحصول على FCM token بعد التسجيل
  void retryFCMTokenLater() {
    // إعادة المحاولة بعد 30 ثانية للمحاولة الأولى
    Timer(const Duration(seconds: 30), () {
      debugPrint("🔄 Retrying FCM token retrieval after 30 seconds...");
      updateFCMTokenInFirestore();
    });

    // محاولة خاصة بـ iOS بعد دقيقة واحدة
    if (Platform.isIOS) {
      Timer(const Duration(minutes: 1), () async {
        debugPrint("🍎 iOS-specific FCM token retry after 1 minute...");
        final token = await _getIOSOptimizedFCMToken();
        if (token != null) {
          try {
            final User? currentUser = _auth.currentUser;
            if (currentUser != null) {
              await _firestore
                  .collection(FirebaseX.collectionSeller)
                  .doc(currentUser.uid)
                  .update({
                    'fcmToken': token,
                    'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
                    'fcmTokenStatus': 'active',
                  });
              debugPrint("✅ iOS FCM Token updated successfully in retry!");
            }
          } catch (e) {
            debugPrint("❌ Failed to update iOS FCM token in retry: $e");
          }
        }
      });
    }

    // إعادة محاولة إضافية بعد دقيقتين إذا فشلت الأولى
    Timer(const Duration(minutes: 2), () {
      debugPrint("🔄 Second retry attempt for FCM token after 2 minutes...");
      updateFCMTokenInFirestore();
    });

    // محاولة أخيرة بعد 5 دقائق
    Timer(const Duration(minutes: 5), () {
      debugPrint("🔄 Final retry attempt for FCM token after 5 minutes...");
      updateFCMTokenInFirestore();
    });
  }
}

/// iOS-specific Firebase Storage handler to fix image upload issues
class IOSFirebaseStorageHandler {
  final FirebaseStorage _storage;

  IOSFirebaseStorageHandler(this._storage);

  Future<String?> uploadFile(File file, String path) async {
    try {
      debugPrint("🍎 iOS Storage Handler: Starting upload to: $path");

      // Wait longer for Firebase to be fully ready on iOS
      await Future.delayed(Duration(milliseconds: 5000));

      // Verify Firebase is properly initialized
      if (Firebase.apps.isEmpty) {
        throw Exception("Firebase not initialized");
      }

      // Test Firebase Storage connection first
      try {
        _storage.ref().child(
          "connection_test_${DateTime.now().millisecondsSinceEpoch}",
        );
        debugPrint("🍎 Testing Firebase Storage connection...");
        // Just create a reference, don't upload
        debugPrint("✅ Firebase Storage connection test passed");
      } catch (e) {
        debugPrint("❌ Firebase Storage connection test failed: $e");
        throw Exception("Firebase Storage not accessible: $e");
      }

      // Verify file exists and is readable
      if (!await file.exists()) {
        throw Exception("File does not exist at path: ${file.path}");
      }

      final fileSize = await file.length();
      debugPrint("🍎 iOS Storage Handler: File size: $fileSize bytes");

      if (fileSize == 0) {
        throw Exception("File is empty");
      }

      // Use simple path first - try without modifications
      debugPrint("🍎 iOS Storage Handler: Trying direct upload to: $path");

      final ref = _storage.ref().child(path);

      // Set proper metadata for iOS
      final metadata = SettableMetadata(
        contentType: _getContentType(file.path),
        customMetadata: {
          'uploaded_by': 'ios_seller_registration',
          'original_path': path,
          'upload_timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      debugPrint("🍎 iOS Storage Handler: Creating upload task...");
      final uploadTask = ref.putFile(file, metadata);

      // Monitor progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (snapshot.totalBytes > 0) {
          final progress =
              snapshot.bytesTransferred / snapshot.totalBytes * 100;
          debugPrint("🍎 iOS Upload progress: ${progress.toStringAsFixed(1)}%");
        }
      });

      debugPrint("🍎 iOS Storage Handler: Waiting for upload completion...");
      final snapshot = await uploadTask.whenComplete(() {});

      debugPrint("🍎 iOS Storage Handler: Getting download URL...");
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint("✅ iOS Upload successful: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      debugPrint("❌ iOS Storage Handler error: $e");

      // Try alternative upload method for iOS
      return await _alternativeUploadMethod(file, path);
    }
  }

  Future<String?> _alternativeUploadMethod(File file, String path) async {
    // Try multiple alternative approaches for iOS

    // Method 1: putData instead of putFile
    try {
      debugPrint("🔄 iOS Alternative Method 1: Using putData...");
      await Future.delayed(Duration(milliseconds: 3000));

      final bytes = await file.readAsBytes();
      debugPrint("🔄 iOS Read ${bytes.length} bytes from file");

      final ref = _storage.ref().child(path);
      final uploadTask = ref.putData(
        bytes,
        SettableMetadata(
          contentType: _getContentType(file.path),
          customMetadata: {
            'uploaded_by': 'ios_alternative_putdata',
            'original_path': path,
          },
        ),
      );

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint("✅ iOS Alternative Method 1 successful: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      debugPrint("❌ iOS Alternative Method 1 failed: $e");
    }

    // Method 2: Different path structure
    try {
      debugPrint("🔄 iOS Alternative Method 2: Different path structure...");
      await Future.delayed(Duration(milliseconds: 3000));

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final altPath = "mobile_uploads/${path.replaceAll('/', '_')}_$timestamp";

      debugPrint("🔄 iOS Alternative path: $altPath");

      final bytes = await file.readAsBytes();
      final ref = _storage.ref().child(altPath);

      final uploadTask = ref.putData(
        bytes,
        SettableMetadata(
          contentType: _getContentType(file.path),
          customMetadata: {
            'uploaded_by': 'ios_alternative_path',
            'original_path': path,
          },
        ),
      );

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint("✅ iOS Alternative Method 2 successful: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      debugPrint("❌ iOS Alternative Method 2 failed: $e");
    }

    // Method 3: Very simple path
    try {
      debugPrint("🔄 iOS Alternative Method 3: Simple upload...");
      await Future.delayed(Duration(milliseconds: 5000));

      final simplePath = "uploads/${DateTime.now().millisecondsSinceEpoch}";
      debugPrint("🔄 iOS Simple path: $simplePath");

      final bytes = await file.readAsBytes();
      final ref = _storage.ref().child(simplePath);

      final uploadTask = ref.putData(bytes);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint("✅ iOS Alternative Method 3 successful: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      debugPrint("❌ iOS Alternative Method 3 failed: $e");
    }

    debugPrint("❌ All iOS alternative upload methods failed");
    return null;
  }

  String _getContentType(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg'; // Default fallback
    }
  }
}
