import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:codora/%D8%A7%D9%84%D9%83%D9%88%D8%AF%20%D8%A7%D9%84%D8%AE%D8%A7%D8%B5%20%D8%A8%D8%AA%D8%B7%D8%A8%D9%8A%D9%82%20%D8%A7%D9%84%D8%AA%D9%88%D8%B5%D9%8A%D9%84/%D8%A7%D9%84%D9%83%D9%88%D8%AF%20%D8%A7%D9%84%D8%AE%D8%A7%D8%B5%20%D8%A8%D9%85%D8%B4%D8%B1%D9%81%20%D8%A7%D9%84%D8%AA%D9%88%D8%B5%D9%8A%D9%84/CompanyAdminDashboardController.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../XXX/xxx_firebase.dart';
import '../الكود الخاص بمشرف التوصيل/DeliveryCompanyModel.dart';
import 'DeliveryDriverModel.dart';

// مثال لـ FirebaseX إذا لم يكن معرفًا

// (تأكد من تعريف DriverApplicationStatus, driverApplicationStatusToString في ملف DeliveryDriverModel)


class DriverProfileSetupController extends GetxController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // --- Firebase Instances ---
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // --- Text Editing Controllers ---
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController(); // For initial input if not from Auth
  final TextEditingController vehicleTypeController = TextEditingController(); // Or use dropdown
  final TextEditingController vehiclePlateController = TextEditingController();

  // --- Image Picker ---
  final ImagePicker _picker = ImagePicker();
  final Rxn<File> profileImageFile = Rxn<File>(null);

  // --- Company Selection ---
  final RxList<DeliveryCompanyModel> availableCompanies = <DeliveryCompanyModel>[].obs;
  final Rxn<DeliveryCompanyModel> selectedCompany = Rxn<DeliveryCompanyModel>(null);
  final RxBool isLoadingCompanies = true.obs;

  // --- Vehicle Types (example) ---
  final List<String> vehicleTypes = ["دراجة نارية", "سيارة", "دراجة هوائية", "شاحنة صغيرة", "أخرى"];
  final RxnString selectedVehicleType = RxnString(null);


  // --- Phone OTP Verification (if needed separately for profile setup) ---
  // إذا كان رقم الهاتف تم التحقق منه بالفعل عند إنشاء حساب Firebase Auth للسائق،
  // قد لا تحتاج لعملية OTP كاملة هنا، فقط تأكيد الرقم.
  // إذا كان هذا هو أول إدخال لرقم الهاتف أو يتم تغييره، فالـ OTP ضروري.
  // حاليًا، سأفترض أننا نحتاج للتحقق إذا لم يتم من Auth مباشرة.
  final RxString driverPhoneNumberForOtp = ''.obs; // الرقم بعد التنسيق
  final RxString verificationId = ''.obs;
  final Rxn<int> resendToken = Rxn<int>(null);
  final RxBool isSendingOtp = false.obs;
  final RxBool isProfileSubmitting = false.obs; // Main loading state for submission
  final RxBool isPhoneNumberVerifiedByOtp = false.obs; // Track if OTP step was successful


  @override
  void onInit() {
    super.onInit();
    fetchAvailableCompanies();
    // إذا كان المستخدم الحالي لديه رقم هاتف موثق من Firebase Auth، استخدمه
    final currentUser = _auth.currentUser;
    if (currentUser != null && currentUser.phoneNumber != null && currentUser.phoneNumber!.isNotEmpty) {
      phoneNumberController.text = currentUser.phoneNumber!; // قد تحتاج لإزالة رمز الدولة
      // Mark as "verified" initially if it came from Firebase Auth verified phone
      // isPhoneNumberVerifiedByOtp.value = true; // Be cautious with this assumption
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneNumberController.dispose();
    vehicleTypeController.dispose();
    vehiclePlateController.dispose();
    super.onClose();
  }

  Future<void> pickProfileImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
          source: source, imageQuality: 70, maxWidth: 800);
      if (pickedFile != null) {
        profileImageFile.value = File(pickedFile.path);
      }
    } catch (e) {
      Get.snackbar("خطأ", "فشل اختيار الصورة: $e", backgroundColor: Colors.red.shade300);
    }
  }

  void onVehicleTypeChanged(String? newValue) {
    selectedVehicleType.value = newValue;
  }

  void onCompanyChanged(DeliveryCompanyModel? newValue) {
    selectedCompany.value = newValue;
  }


  Future<void> fetchAvailableCompanies() async {
    isLoadingCompanies.value = true;
    try {
      final snapshot = await _firestore
          .collection(FirebaseX.deliveryCompaniesCollection)
      //  .where('isActiveByCompanyAdmin', isEqualTo: true) // الشركات النشطة من جانبها
          .where('isApprovedByPlatformAdmin', isEqualTo: true) // الشركات الموافق عليها من منصتك
          .orderBy('companyName')
          .get();

      final companies = snapshot.docs
          .map((doc) => DeliveryCompanyModel.fromMap(doc.data(), doc.id))
          .toList();
      availableCompanies.assignAll(companies);
      debugPrint("Fetched ${availableCompanies.length} active and approved companies.");
    } catch (e) {
      debugPrint("Error fetching companies: $e");
      Get.snackbar("خطأ", "فشل في جلب قائمة الشركات المتاحة.", backgroundColor: Colors.red.shade300);
    } finally {
      isLoadingCompanies.value = false;
    }
  }

  // ----- Phone OTP Verification Logic (Simplified for profile setup context) -----
  // إذا كان رقم هاتف Firebase Auth للمستخدم موثقًا، قد تتخطى هذه الخطوة أو تؤكد فقط.
  // هذا مثال إذا كنت تحتاج لعملية OTP كاملة لرقم يُدخله السائق هنا.
  Future<void> initiateDriverPhoneVerification(BuildContext contextForOtp) async {
    if (phoneNumberController.text.trim().isEmpty) {
      Get.snackbar("خطأ", "الرجاء إدخال رقم الهاتف.", backgroundColor: Colors.orange.shade300);
      return;
    }

    String rawPhoneNumber = phoneNumberController.text.trim();
    rawPhoneNumber = rawPhoneNumber.replaceAll(RegExp(r'\s+'), '');
    if (rawPhoneNumber.startsWith('0')) {
      rawPhoneNumber = rawPhoneNumber.substring(1);
    }
    const String countryCode = "+964"; // **تذكر تعديل رمز الدولة**
    driverPhoneNumberForOtp.value = "$countryCode$rawPhoneNumber";

    // **أضف التحقق من صحة تنسيق الرقم (RegExp) هنا كما في SellerRegistrationController**
    final RegExp iraqiPhoneNumberRegExp = RegExp(r'^\+9647[3-9]\d{8}$');
    if (!iraqiPhoneNumberRegExp.hasMatch(driverPhoneNumberForOtp.value)) {
      Get.snackbar("رقم هاتف غير صالح", "الرجاء التأكد من إدخال رقم هاتف عراقي صحيح.", backgroundColor: Colors.orange.shade300);
      return;
    }

    isSendingOtp.value = true;
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: driverPhoneNumberForOtp.value,
        verificationCompleted: (PhoneAuthCredential credential) async {
          isSendingOtp.value = false;
          debugPrint("Driver phone auto-verified for profile setup.");
          isPhoneNumberVerifiedByOtp.value = true; // تم التحقق
          Get.back(); // أغلق شاشة OTP إذا كانت مفتوحة
          Get.snackbar("تم التحقق", "تم التحقق من رقم الهاتف تلقائيًا.", backgroundColor: Colors.green);
          // يمكنك استدعاء sendApplicationToCompany() مباشرة هنا إذا كان هذا هو التدفق الوحيد
          // أو ببساطة تحديث الحالة والسماح للمستخدم بالضغط على "إرسال طلب"
        },
        verificationFailed: (FirebaseAuthException e) {
          isSendingOtp.value = false;
          debugPrint("Driver phone verification failed: ${e.message}");
          Get.snackbar("فشل التحقق", "فشل التحقق من رقم الهاتف: ${e.message}", backgroundColor: Colors.red.shade300, duration: Duration(seconds: 5));
        },
        codeSent: (String verId, int? resendTok) {
          isSendingOtp.value = false;
          verificationId.value = verId;
          resendToken.value = resendTok;
          debugPrint("OTP sent to driver for profile setup. VerID: $verId");
          // الانتقال إلى شاشة OTP بسيطة (يمكن إنشاؤها أو إعادة استخدامها مع تعديل)
          // Get.to(() => DriverOtpScreen(onVerified: () {
          //      isPhoneNumberVerifiedByOtp.value = true;
          //      Get.back(); // Close OTP screen
          //      Get.snackbar("تم التحقق", "تم التحقق من رقم الهاتف بنجاح.", backgroundColor: Colors.green);
          // }));
          _showOtpDialog(contextForOtp, verId);
        },
        codeAutoRetrievalTimeout: (String verId) {
          verificationId.value = verId;
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      isSendingOtp.value = false;
      Get.snackbar("خطأ", "حدث خطأ أثناء إرسال رمز التحقق: $e", backgroundColor: Colors.red.shade300);
    }
  }

  void _showOtpDialog(BuildContext context, String currentVerificationId) {
    final otpInputController = TextEditingController();
    Get.dialog(
        AlertDialog(
          title: Text("أدخل رمز التحقق"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("تم إرسال الرمز إلى: ${driverPhoneNumberForOtp.value}"),
              SizedBox(height: 15),
              TextField(
                controller: otpInputController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(labelText: "رمز OTP"),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: Text("إلغاء")),
            ElevatedButton(
                onPressed: () async {
                  if (otpInputController.text.trim().length == 6) {
                    PhoneAuthCredential credential = PhoneAuthProvider.credential(
                        verificationId: currentVerificationId, // استخدم الـ ID الممرر
                        smsCode: otpInputController.text.trim());
                    try {
                      // لا نحتاج لـ link أو signIn هنا إذا كان الهدف هو فقط التحقق للنموذج
                      // يكفي أن إنشاء الـ Credential لم يرمِ استثناء
                      debugPrint("Driver OTP verified for profile via dialog. Credential: ${credential.smsCode}");
                      isPhoneNumberVerifiedByOtp.value = true;
                      Get.back(); // أغلق الحوار
                      Get.snackbar("تم التحقق", "تم التحقق من رقم الهاتف.", backgroundColor: Colors.green);
                    } on FirebaseAuthException catch (e) {
                      Get.snackbar("خطأ OTP", "رمز التحقق غير صحيح: ${e.message}", backgroundColor: Colors.red);
                    }
                  } else {
                    Get.snackbar("خطأ", "الرجاء إدخال 6 أرقام.", backgroundColor: Colors.orange);
                  }
                },
                child: Text("تحقق")),
          ],
        ),
        barrierDismissible: false);
  }


  // ----- Main Submission Logic -----
  Future<void> sendApplicationToCompany() async {
    if (!formKey.currentState!.validate()) {
      Get.snackbar("خطأ", "يرجى ملء جميع الحقول المطلوبة.", backgroundColor: Colors.orange.shade300);
      return;
    }
    if (profileImageFile.value == null) {
      Get.snackbar("خطأ", "يرجى اختيار صورة شخصية.", backgroundColor: Colors.orange.shade300);
      return;
    }
    if (selectedVehicleType.value == null) {
      Get.snackbar("خطأ", "يرجى اختيار نوع المركبة.", backgroundColor: Colors.orange.shade300);
      return;
    }
    if (selectedCompany.value == null) {
      Get.snackbar("خطأ", "يرجى اختيار شركة التوصيل التي ترغب بالانضمام إليها.", backgroundColor: Colors.orange.shade300);
      return;
    }

    // **التحقق من رقم الهاتف عبر OTP إذا لم يتم مسبقًا**
    // إذا كان رقم هاتف المستخدم في Firebase Auth موثقًا بالفعل وتم استخدامه،
    // قد لا تحتاج لـ isPhoneNumberVerifiedByOtp.value، وافترض أنه موثق.
    // إذا كان رقمًا جديدًا أو يتطلب تحققًا هنا:
    if (!isPhoneNumberVerifiedByOtp.value && phoneNumberController.text.isNotEmpty) { //phoneNumberController.text.isNotEmpty مهم هنا
      Get.snackbar("تنبيه", "الرجاء التحقق من رقم هاتفك أولاً بالضغط على زر التحقق بجانب حقل الهاتف.", backgroundColor: Colors.amber.shade700, duration: Duration(seconds: 4));
      // أو يمكنك استدعاء initiateDriverPhoneVerification() تلقائيًا من هنا إذا كان الحقل مملوءًا ولم يتم التحقق منه.
      // حاليًا، يتطلب من المستخدم الضغط على زر "تحقق" بجانب رقم الهاتف.
      return;
    }


    isProfileSubmitting.value = true;
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("المستخدم غير مسجل الدخول! لا يمكن إرسال الطلب.");
      }
      final driverUid = currentUser.uid;

      // 1. Upload profile image
      final String profileImagePath = '${FirebaseX.driverStoragePath}/$driverUid/profile_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String? profileImgUrl = await _uploadFile(profileImageFile.value!, profileImagePath);
      if (profileImgUrl == null) throw Exception("فشل رفع الصورة الشخصية.");

      // 2. Get FCM Token
      String? fcmToken = await _firebaseMessaging.getToken().catchError((e) {
        debugPrint("Failed to get FCM token for driver: $e"); return null;
      });

      // 3. Prepare Driver Data
      final driverData = DeliveryDriverModel(
        uid: driverUid,
        name: nameController.text.trim(),
        profileImageUrl: profileImgUrl,
        phoneNumber: driverPhoneNumberForOtp.value.isNotEmpty ? driverPhoneNumberForOtp.value : currentUser.phoneNumber ?? phoneNumberController.text.trim(), // استخدم الرقم الموثق إن وجد
        vehicleType: selectedVehicleType.value!,
        vehiclePlateNumber: vehiclePlateController.text.trim().isNotEmpty ? vehiclePlateController.text.trim() : null,
        fcmToken: fcmToken,
        availabilityStatus: "offline", // Default status
        requestedCompanyId: selectedCompany.value!.companyId, // ID للشركة المختارة
        applicationStatus: DriverApplicationStatus.pending, // يبدأ الطلب كمعلق
        createdAt: Timestamp.now(),
        // approvedCompanyId, rejectionReason, applicationStatusUpdatedAt سيتم تعيينها من قبل الشركة
      );

      // 4. Save to Firestore in "delivery_drivers" collection
      await _firestore.collection(FirebaseX.deliveryDriversCollection)
          .doc(driverUid)
          .set(driverData.toMap());

      // 5. (Optional but good) Send notification to the selected company admin
      final companyAdminUserId = selectedCompany.value!.adminUserId;
      if (companyAdminUserId.isNotEmpty) {
        DocumentSnapshot companyAdminUserDoc = await _firestore.collection("Usercodora") // أو مجموعة مستخدمي المشرفين
            .doc(companyAdminUserId).get();
        if(companyAdminUserDoc.exists && companyAdminUserDoc.data() != null){
          final adminData = companyAdminUserDoc.data() as Map<String,dynamic>;
          String? adminFcmToken = adminData['token'] as String?;
          if(adminFcmToken != null && adminFcmToken.isNotEmpty){
            // Send FCM (You'll need your LocalNotification or a similar service)
            // await LocalNotification.sendNotificationMessageToUser(
            //     to: adminFcmToken,
            //     title: "طلب انضمام سائق جديد",
            //     body: "${driverData.name} يرغب بالانضمام إلى شركتك.",
            //     type: "driver_application",
            //     uid: driverUid // Driver's UID
            // );
            debugPrint("Sent notification to company admin $companyAdminUserId for new driver ${driverData.name}");
          }
        }
      }


      Get.snackbar("تم الإرسال بنجاح", "تم إرسال طلب انضمامك إلى ${selectedCompany.value!.companyName}. سيتم مراجعته.",
          backgroundColor: Colors.green, duration: Duration(seconds: 4), snackPosition: SnackPosition.BOTTOM);

      // Clear form or navigate away
      // Get.offAll(() => DriverWaitingScreen()); // مثال لشاشة انتظار موافقة
      profileImageFile.value = null;
      nameController.clear();
      // phoneNumberController.clear(); // قد لا ترغب بمسح هذا إذا كان من Auth
      vehiclePlateController.clear();
      selectedVehicleType.value = null;
      selectedCompany.value = null;
      isPhoneNumberVerifiedByOtp.value = false; // Reset for next potential registration/edit


    } catch (e) {
      Get.snackbar("خطأ في الإرسال", "فشل إرسال طلب الانضمام: ${e.toString()}",
          backgroundColor: Colors.red.shade400, duration: Duration(seconds: 5), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isProfileSubmitting.value = false;
    }
  }

  Future<String?> _uploadFile(File file, String path) async { // Ensure this method exists
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask.whenComplete(() {});
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint("Error uploading file ($path): $e");
      return null;
    }
  }
}