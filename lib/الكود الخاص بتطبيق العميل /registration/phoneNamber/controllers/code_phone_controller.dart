import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../services/phone_auth_service.dart';
import '../../../services/firebase_phone_helper.dart';
import '../../../../Model/model_user.dart';
import '../../../../XXX/xxx_firebase.dart';
import '../../../bottonBar/botonBar.dart';

/// كونترولر متقدم لصفحة رمز التحقق
/// يدعم التحقق التلقائي من الرسائل، شبكة المراقبة، والتحقق الذكي
class CodePhoneController extends GetxController {
  // ===================== Constants =====================
  static const int _codeLength = 6;
  static const int _resendTimeoutSeconds = 60;
  static const int _maxResendAttempts = 3;
  static const int _maxVerificationAttempts = 5;

  // ===================== Controllers & Focus Nodes =====================
  final List<TextEditingController> codeControllers = List.generate(
    _codeLength,
    (index) => TextEditingController(),
  );

  final List<FocusNode> focusNodes = List.generate(
    _codeLength,
    (index) => FocusNode(),
  );

  // ===================== Observable States =====================
  final RxBool isLoading = false.obs;
  final RxBool isCodeValid = true.obs;
  final RxBool canResend = false.obs;
  final RxBool isNetworkConnected = true.obs;
  final RxInt resendCounter = _resendTimeoutSeconds.obs;
  final RxInt resendAttempts = 0.obs;
  final RxInt verificationAttempts = 0.obs;
  final RxString statusMessage = ''.obs;
  final RxString errorMessage = ''.obs;
  final RxDouble progress = 0.0.obs;
  final RxBool isAutoVerifying = false.obs;
  final RxString allCodeText = ''.obs;

  // ===================== حماية من الطلبات المتكررة =====================
  bool _isCodeSendingInProgress = false;
  DateTime? _lastCodeSendTime;
  bool _hasInitialCodeBeenSent = false;
  static const int _minimumSendInterval = 5000; // 5 ثواني

  // ===================== Services & Utilities =====================
  PhoneAuthService? _phoneAuthService;
  Timer? _resendTimer;
  Timer? _autoFillTimer;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  // ===================== Pinput Controller =====================
  final pinController = TextEditingController();

  // ===================== User Data =====================
  final String phoneNumber;
  final Uint8List userImage;
  final String name;
  final String email;
  final String password;
  String? verificationId;
  int? forceResendingToken;

  // ===================== Constructor =====================
  CodePhoneController({
    required this.phoneNumber,
    required this.userImage,
    required this.name,
    required this.email,
    required this.password,
    this.verificationId,
    this.forceResendingToken,
  });

  // ===================== Lifecycle Methods =====================
  @override
  void onInit() {
    super.onInit();
    _initializeController();
  }

  @override
  void onClose() {
    _disposeResources();
    super.onClose();
  }

  // ===================== Initialization =====================
  Future<void> _initializeController() async {
    try {
      await _initializeService();
      _setupNetworkMonitoring();
      _setupFocusListeners();
      _setupCodeValidation();
      _startResendTimer();
      _setupAutoFill();

      statusMessage.value = 'تم إرسال رمز التحقق إلى $phoneNumber';

      // ✅ فحص جاهزية النظام قبل الإرسال
      final systemReady = await _checkSystemReadiness();
      if (!systemReady) {
        statusMessage.value = 'يتم تهيئة النظام...';
        await Future.delayed(Duration(seconds: 2));
      }

      // ✅ إرسال الرمز فقط إذا لم يتم إرساله من قبل
      if (!_hasInitialCodeBeenSent) {
        await sendVerificationCodeWithDiagnosis();
      } else {
        print('ℹ️ تم تخطي إرسال الرمز - تم إرساله مسبقاً');
        statusMessage.value = 'في انتظار إدخال رمز التحقق';
      }
    } catch (e) {
      _handleError('فشل في تهيئة النظام', e);
    }
  }

  /// فحص جاهزية النظام
  Future<bool> _checkSystemReadiness() async {
    try {
      debugPrint("🔍 فحص جاهزية النظام...");

      // 1. فحص خدمة المصادقة
      if (_phoneAuthService == null) {
        debugPrint("❌ خدمة المصادقة غير مهيأة");
        return false;
      }

      // 2. فحص الاتصال بالشبكة
      if (!isNetworkConnected.value) {
        debugPrint("❌ لا يوجد اتصال بالإنترنت");
        return false;
      }

      // 3. تشخيص Firebase
      final diagnosis = await FirebasePhoneHelper.comprehensiveDiagnosis();
      if (diagnosis.containsKey('error')) {
        debugPrint("❌ خطأ في تشخيص Firebase: ${diagnosis['error']}");
        return false;
      }

      // 4. فحص رقم الهاتف
      final phoneValidation = FirebasePhoneHelper.validatePhoneNumberAdvanced(
        phoneNumber,
      );
      final suggestions = phoneValidation['suggestions'] as List<String>;
      if (suggestions.isNotEmpty && suggestions.first != 'الرقم يبدو صحيحاً') {
        debugPrint("⚠️ مشاكل في رقم الهاتف: ${suggestions.join(', ')}");
        statusMessage.value = "تحقق من رقم الهاتف: ${suggestions.first}";
        return false;
      }

      debugPrint("✅ النظام جاهز للعمل");
      return true;
    } catch (e) {
      debugPrint("❌ خطأ في فحص جاهزية النظام: $e");
      return false;
    }
  }

  Future<void> _initializeService() async {
    try {
      // التحقق من وجود الخدمة أولاً
      if (!Get.isRegistered<PhoneAuthService>()) {
        debugPrint("⚠️ PhoneAuthService غير مسجلة، جاري التسجيل...");
        Get.put(PhoneAuthService(), permanent: true);
        await Future.delayed(Duration(milliseconds: 500)); // انتظار للتهيئة
      }

      _phoneAuthService = Get.find<PhoneAuthService>();

      // التحقق من جاهزية الخدمة
      if (_phoneAuthService != null && !_phoneAuthService!.canMakeRequest) {
        debugPrint("⚠️ الخدمة غير جاهزة، جاري إعادة التعيين...");
        _phoneAuthService!.resetRequestState();
      }

      debugPrint("✅ تم تهيئة PhoneAuthService بنجاح في الكنترولر");

      // اختبار سريع للخدمة
      if (_phoneAuthService != null) {
        final report = _phoneAuthService!.getServiceReport();
        debugPrint("📊 تقرير الخدمة في الكنترولر: ${report['status']}");
      }
    } catch (e) {
      debugPrint("❌ خطأ في تهيئة PhoneAuthService: $e");

      // محاولة إنشاء خدمة جديدة
      try {
        debugPrint("🔄 محاولة إنشاء خدمة جديدة...");
        Get.delete<PhoneAuthService>(force: true);
        await Future.delayed(Duration(milliseconds: 200));

        Get.put(PhoneAuthService(), permanent: true);
        await Future.delayed(Duration(milliseconds: 500));

        _phoneAuthService = Get.find<PhoneAuthService>();
        debugPrint("✅ تم إنشاء وتهيئة خدمة جديدة");
      } catch (retryError) {
        debugPrint("❌ فشل في إنشاء خدمة جديدة: $retryError");
        throw Exception("فشل في تهيئة خدمة المصادقة: $retryError");
      }
    }
  }

  void _setupNetworkMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      final isConnected = results.any(
        (result) => result != ConnectivityResult.none,
      );
      isNetworkConnected.value = isConnected;

      if (isConnected) {
        statusMessage.value = 'تم استعادة الاتصال بالإنترنت';
      } else {
        statusMessage.value = 'لا يوجد اتصال بالإنترنت';
      }
    });
  }

  void _setupFocusListeners() {
    for (int i = 0; i < focusNodes.length; i++) {
      focusNodes[i].addListener(() {
        if (focusNodes[i].hasFocus) {
          HapticFeedback.selectionClick();
        }
      });
    }
  }

  void _setupCodeValidation() {
    for (int i = 0; i < codeControllers.length; i++) {
      codeControllers[i].addListener(() {
        _validateInput(i);
      });
    }
  }

  void _startResendTimer() {
    canResend.value = false;
    resendCounter.value = _resendTimeoutSeconds;

    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendCounter.value > 0) {
        resendCounter.value--;
      } else {
        canResend.value = true;
        timer.cancel();
      }
    });
  }

  void _setupAutoFill() {
    _requestSmsListenPermission();
    _setupPinputController();
  }

  // ===================== Pinput Setup =====================
  void _setupPinputController() {
    pinController.addListener(() {
      final text = pinController.text;
      if (text.length == _codeLength) {
        // التحقق التلقائي بعد إدخال جميع الأرقام
        Future.delayed(const Duration(milliseconds: 300), () {
          if (pinController.text.length == _codeLength) {
            verifyCode();
          }
        });
      }
    });
  }

  // ===================== Pinput Helper Methods =====================
  void clearPinput() {
    pinController.clear();
    isCodeValid.value = true;
    errorMessage.value = '';
  }

  void setPinputCode(String code) {
    pinController.text = code;
  }

  String getPinputCode() {
    return pinController.text;
  }

  bool get isPinputComplete => pinController.text.length == _codeLength;

  // ===================== Pinput Code Validation =====================
  bool validatePinputCode() {
    final code = pinController.text;

    if (code.length != _codeLength) {
      _showError('يرجى إدخال الرمز كاملاً');
      return false;
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(code)) {
      _showError('الرمز يجب أن يحتوي على أرقام فقط');
      return false;
    }

    return true;
  }

  // ===================== Pinput Verification =====================
  Future<void> verifyCodeFromPinput() async {
    final code = pinController.text;

    if (code.length != _codeLength) {
      _showError('يرجى إدخال الرمز كاملاً');
      return;
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(code)) {
      _showError('الرمز يجب أن يحتوي على أرقام فقط');
      return;
    }

    verificationAttempts.value++;

    if (verificationAttempts.value > _maxVerificationAttempts) {
      _handleError('تم تجاوز الحد الأقصى للمحاولات', 'يرجى المحاولة لاحقاً');
      return;
    }

    try {
      isLoading.value = true;
      statusMessage.value = 'جاري التحقق من الرمز...';

      if (_phoneAuthService == null) {
        throw Exception('خدمة المصادقة غير مهيأة');
      }

      final result = await _phoneAuthService!.verifyCode(code);

      if (result.isSuccess) {
        await _handleSuccessfulVerification(result.user);
      } else {
        _handleVerificationError(result.error ?? 'خطأ في التحقق من الرمز');
      }
    } catch (e) {
      _handleVerificationError(e);
    } finally {
      isLoading.value = false;
    }
  }

  // ===================== SMS Permission (للاستخدام المستقبلي) =====================
  Future<void> _requestSmsListenPermission() async {
    try {
      // طلب إذن قراءة الرسائل
      final status = await Permission.sms.request();

      if (status.isGranted) {
        statusMessage.value =
            'يمكنك إدخال رمز التحقق يدوياً أو انتظار الملء التلقائي';
      } else {
        statusMessage.value = 'يمكنك إدخال رمز التحقق يدوياً';
      }
    } catch (e) {
      print('خطأ في طلب إذن قراءة الرسائل: $e');
      statusMessage.value = 'يمكنك إدخال رمز التحقق يدوياً';
    }
  }

  // ===================== دوال الحماية من الطلبات المتكررة =====================

  /// التحقق من إمكانية إرسال طلب جديد
  bool _canSendNewCode() {
    if (_isCodeSendingInProgress) {
      print('⚠️ طلب إرسال رمز التحقق قيد التنفيذ بالفعل');
      return false;
    }

    if (_lastCodeSendTime != null) {
      final timeSinceLastSend =
          DateTime.now().difference(_lastCodeSendTime!).inMilliseconds;
      if (timeSinceLastSend < _minimumSendInterval) {
        final waitTime = _minimumSendInterval - timeSinceLastSend;
        print(
          '⚠️ يجب الانتظار ${(waitTime / 1000).ceil()} ثانية قبل إرسال رمز جديد',
        );
        statusMessage.value =
            'يجب الانتظار ${(waitTime / 1000).ceil()} ثانية قبل إعادة الإرسال';
        return false;
      }
    }

    return true;
  }

  /// تحديث حالة إرسال الرمز
  void _updateCodeSendingState(bool isInProgress) {
    _isCodeSendingInProgress = isInProgress;
    if (isInProgress) {
      _lastCodeSendTime = DateTime.now();
    }
  }

  /// إعادة تعيين حالة الحماية
  void _resetDuplicateProtection() {
    _isCodeSendingInProgress = false;
    _lastCodeSendTime = null;
    _hasInitialCodeBeenSent = false;
  }

  // ===================== Main Controller Methods =====================
  /// إرسال رمز التحقق مع تشخيص شامل
  Future<void> sendVerificationCodeWithDiagnosis() async {
    debugPrint("🔍 بدء عملية إرسال رمز التحقق إلى: $phoneNumber");

    // التحقق من تهيئة الخدمة أولاً
    if (_phoneAuthService == null) {
      try {
        await _initializeService();
      } catch (e) {
        _handleError("فشل في تهيئة خدمة المصادقة", e);
        return;
      }
    }

    // ✅ التحقق من الحماية من الطلبات المتكررة مع مرونة أكبر
    if (!_canSendNewCode()) {
      // إذا كان هناك خطأ سابق، امنح فرصة جديدة
      if (_hasInitialCodeBeenSent && !canResend.value) {
        debugPrint("⚠️ إعطاء فرصة جديدة بعد خطأ سابق");
        _hasInitialCodeBeenSent = false;
        _resetDuplicateProtection();
      } else {
        return;
      }
    }

    if (!isNetworkConnected.value) {
      _handleError('لا يوجد اتصال بالإنترنت', 'تحقق من الاتصال وحاول مرة أخرى');
      return;
    }

    try {
      // ✅ تشخيص ما قبل الإرسال مع المساعد المحسن
      debugPrint("🔍 تشخيص ما قبل الإرسال...");

      if (_phoneAuthService == null) {
        throw Exception('خدمة المصادقة غير مهيأة');
      }

      // تشخيص شامل باستخدام المساعد
      final comprehensiveDiagnosis =
          await FirebasePhoneHelper.comprehensiveDiagnosis();
      debugPrint(
        "📊 تشخيص Firebase الشامل: ${comprehensiveDiagnosis['firebase']}",
      );

      // فحص صحة رقم الهاتف المحسن
      final phoneValidation = FirebasePhoneHelper.validatePhoneNumberAdvanced(
        phoneNumber,
      );
      debugPrint("📞 فحص رقم الهاتف المحسن: ${phoneValidation['type']}");

      // طباعة نصائح إذا كان رقماً تجريبياً
      if (phoneValidation['type']['is_test_number'] == true) {
        debugPrint(
          "🧪 رقم تجريبي مكتشف: ${phoneValidation['type']['test_note']}",
        );
      }

      // التحقق من الاقتراحات
      final suggestions = phoneValidation['suggestions'] as List<String>;
      if (suggestions.isNotEmpty && suggestions.first != 'الرقم يبدو صحيحاً') {
        debugPrint("💡 اقتراحات تحسين الرقم: ${suggestions.join(', ')}");
        statusMessage.value = "اقتراحات: ${suggestions.first}";
        await Future.delayed(Duration(seconds: 2));
      }

      if (phoneValidation['basic']['is_numeric_only'] != true) {
        final suggestions = phoneValidation['suggestions'] as List<String>;
        _handleError("رقم الهاتف غير صحيح", suggestions.join('\n'));
        return;
      }

      // ✅ تعيين حالة إرسال الطلب
      _updateCodeSendingState(true);
      isLoading.value = true;
      statusMessage.value = 'جاري إرسال رمز التحقق...';
      progress.value = 0.2;

      debugPrint("📤 إرسال طلب التحقق إلى Firebase...");
      final result = await _phoneAuthService!.sendVerificationCode(phoneNumber);

      progress.value = 0.8;

      if (result.isSuccess) {
        if (result.type == PhoneAuthResultType.codeSent) {
          verificationId = result.verificationId;
          statusMessage.value = 'تم إرسال رمز التحقق بنجاح';
          _hasInitialCodeBeenSent = true;
          progress.value = 1.0;

          debugPrint("✅ تم إرسال رمز التحقق بنجاح");
          debugPrint("🔑 معرف التحقق: ${verificationId?.substring(0, 10)}...");

          // إزالة رسالة الخطأ إن وجدت
          errorMessage.value = '';
        } else if (result.type == PhoneAuthResultType.autoVerified) {
          debugPrint("✅ تم التحقق التلقائي");
          await _handleSuccessfulVerification(result.user);
          return;
        }
      } else {
        final errorMsg = result.error ?? 'خطأ غير معروف في إرسال الرمز';
        debugPrint("❌ فشل في إرسال الرمز: $errorMsg");

        // إعادة تعيين الحماية في حالة الفشل لإتاحة المحاولة مرة أخرى
        _hasInitialCodeBeenSent = false;
        _resetDuplicateProtection();

        _handleError('فشل في إرسال رمز التحقق', errorMsg);
      }
    } catch (e) {
      debugPrint("🚨 استثناء في إرسال رمز التحقق: $e");

      // إعادة تعيين الحماية في حالة الاستثناء
      _hasInitialCodeBeenSent = false;
      _resetDuplicateProtection();

      _handleError('فشل في إرسال رمز التحقق', e);
    } finally {
      // ✅ إنهاء حالة إرسال الطلب
      _updateCodeSendingState(false);
      isLoading.value = false;
      progress.value = 0.0;

      debugPrint("🔄 تم إنهاء عملية إرسال الرمز");
    }
  }

  Future<void> verifyCode() async {
    if (!_validateAllInputs()) return;

    verificationAttempts.value++;

    if (verificationAttempts.value > _maxVerificationAttempts) {
      _handleError('تم تجاوز الحد الأقصى للمحاولات', 'يرجى المحاولة لاحقاً');
      return;
    }

    final code = _getCompleteCode();

    try {
      isLoading.value = true;
      statusMessage.value = 'جاري التحقق من الرمز...';

      if (_phoneAuthService == null) {
        throw Exception('خدمة المصادقة غير مهيأة');
      }

      final result = await _phoneAuthService!.verifyCode(code);

      if (result.isSuccess) {
        await _handleSuccessfulVerification(result.user);
      } else {
        _handleVerificationError(result.error ?? 'خطأ في التحقق من الرمز');
      }
    } catch (e) {
      _handleVerificationError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resendCode() async {
    // ✅ التحقق من القيود والحماية من الطلبات المتكررة
    if (!canResend.value || resendAttempts.value >= _maxResendAttempts) {
      statusMessage.value = 'تم تجاوز الحد الأقصى لإعادة الإرسال';
      return;
    }

    if (!_canSendNewCode()) {
      return;
    }

    resendAttempts.value++;
    _clearAllInputs();
    await sendVerificationCodeWithDiagnosis();
    _startResendTimer();
  }

  // ===================== Input Validation & Management =====================
  void _validateInput(int index) {
    final text = codeControllers[index].text;

    if (text.isNotEmpty &&
        text.length == 1 &&
        RegExp(r'[0-9]').hasMatch(text)) {
      isCodeValid.value = true;
      errorMessage.value = '';
      _moveToNextField(index);
    } else if (text.length > 1) {
      codeControllers[index].text = text[text.length - 1];
    }

    _updateAllCodeText();
    _checkAutoVerification();
  }

  void _moveToNextField(int currentIndex) {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (currentIndex < _codeLength - 1) {
        focusNodes[currentIndex + 1].requestFocus();
        HapticFeedback.lightImpact();
      } else {
        focusNodes[currentIndex].unfocus();
      }
    });
  }

  void _moveToPreviousField(int currentIndex) {
    if (currentIndex > 0) {
      focusNodes[currentIndex - 1].requestFocus();
      HapticFeedback.lightImpact();
    }
  }

  void _updateAllCodeText() {
    allCodeText.value = codeControllers.map((c) => c.text).join();
  }

  void _checkAutoVerification() {
    if (allCodeText.value.length == _codeLength &&
        allCodeText.value
            .split('')
            .every((char) => RegExp(r'[0-9]').hasMatch(char))) {
      _autoFillTimer?.cancel();
      _autoFillTimer = Timer(const Duration(milliseconds: 500), () {
        if (!isLoading.value) {
          verifyCode();
        }
      });
    }
  }

  bool _validateAllInputs() {
    final code = _getCompleteCode();

    if (code.length != _codeLength) {
      _showError('يرجى إدخال الرمز كاملاً');
      return false;
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(code)) {
      _showError('الرمز يجب أن يحتوي على أرقام فقط');
      return false;
    }

    return true;
  }

  String _getCompleteCode() {
    return codeControllers.map((controller) => controller.text).join();
  }

  void _clearAllInputs() {
    for (var controller in codeControllers) {
      controller.clear();
    }
    allCodeText.value = '';
    focusNodes[0].requestFocus();
    HapticFeedback.mediumImpact();
  }

  // ===================== Success Handling =====================
  Future<void> _handleSuccessfulVerification(User? user) async {
    if (user == null) {
      _handleError('فشل في التحقق', 'لم يتم إنشاء المستخدم');
      return;
    }

    try {
      statusMessage.value = 'تم التحقق بنجاح! جاري حفظ البيانات...';

      await _saveUserDataToFirestore(user);

      _showSuccessMessage();
      _navigateToBottomBar();
    } catch (e) {
      _handleError('فشل في حفظ البيانات', e);
    }
  }

  Future<void> _saveUserDataToFirestore(User user) async {
    try {
      // الحصول على FCM Token
      String fcmToken = '';
      try {
        fcmToken = await FirebaseMessaging.instance.getToken() ?? '';
        print('FCM Token: $fcmToken');
      } catch (e) {
        print('خطأ في الحصول على FCM Token: $e');
      }

      // رفع صورة المستخدم أولاً للحصول على الرابط
      String profileImageUrl = '';
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child(FirebaseX.StorgeApp)
            .child('${user.uid}.jpg');

        await storageRef.putData(userImage);
        profileImageUrl = await storageRef.getDownloadURL();
      } catch (e) {
        print('خطأ في رفع الصورة: $e');
        profileImageUrl = ImageX.ImageOfPerson; // صورة افتراضية
      }

      // إنشاء نموذج المستخدم مع FCM Token
      final userModel = UserModel(
        uid: user.uid,
        name: name,
        email: email,
        password: password, // ملاحظة: يجب تشفير كلمة المرور في بيئة الإنتاج
        phoneNumber: phoneNumber,
        token: fcmToken, // حفظ FCM Token
        url: profileImageUrl,
        appName: FirebaseX.appName,
      );

      // حفظ بيانات المستخدم باستخدام UserModel و FirebaseX
      await FirebaseFirestore.instance
          .collection(FirebaseX.collectionApp)
          .doc(user.uid)
          .set({
            ...userModel.toMap(),
            'createdAt': FieldValue.serverTimestamp(),
            'lastLoginAt': FieldValue.serverTimestamp(),
            'isPhoneVerified': true,
            'userType': 'customer',
          });

      print('تم حفظ بيانات المستخدم بنجاح في: ${FirebaseX.collectionApp}');
      print('FCM Token محفوظ: $fcmToken');
    } catch (e) {
      print('خطأ في حفظ بيانات المستخدم: $e');
      rethrow;
    }
  }

  void _showSuccessMessage() {
    statusMessage.value = 'تم التحقق من رقم الهاتف بنجاح!';
    HapticFeedback.heavyImpact();
  }

  void _navigateToBottomBar() {
    Future.delayed(const Duration(milliseconds: 1000), () {
      // الانتقال إلى BottomBar مع initialIndex = 0
      Get.offAll(() => const BottomBar(initialIndex: 0));
    });
  }

  // ===================== Error Handling =====================
  void _handleVerificationError(dynamic error) {
    String message = 'خطأ في التحقق من الرمز';

    if (error is String) {
      message = error;
    } else if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-verification-code':
          message = 'رمز التحقق غير صحيح';
          _clearAllInputs();

          // إضافة نصائح للأرقام التجريبية
          final phoneValidation =
              FirebasePhoneHelper.validatePhoneNumberAdvanced(phoneNumber);
          if (phoneValidation['type']['is_test_number'] == true) {
            message +=
                '\n\n💡 للأرقام التجريبية: استخدم الرمز المحدد في Firebase Console تحت "Phone numbers for testing"';
          } else {
            message += '\n\n💡 للأرقام الحقيقية: استخدم الرمز المُرسل عبر SMS';
          }
          break;
        case 'invalid-verification-id':
          message = 'معرف التحقق غير صالح - قد تحتاج لطلب رمز جديد';
          break;
        case 'session-expired':
          message = 'انتهت صلاحية الجلسة، يرجى طلب رمز جديد';
          break;
        case 'too-many-requests':
          message = 'تم تجاوز الحد الأقصى للمحاولات - انتظر بضع دقائق';
          break;
        default:
          message = error.message ?? 'خطأ غير معروف';
      }
    } else {
      message = error.toString();
    }

    _showError(message);

    // إظهار حلول مقترحة
    final solutions = FirebasePhoneHelper.getCommonSolutions();
    if (message.contains('غير صحيح')) {
      Future.delayed(Duration(seconds: 3), () {
        statusMessage.value =
            'نصائح: ${solutions['رمز التحقق غير صحيح']?.first ?? ''}';
      });
    }
  }

  void _handleError(String title, dynamic error) {
    final errorMsg = error.toString();
    print('خطأ في $title: $errorMsg');

    // الحصول على حلول مقترحة من المساعد
    final solutions = FirebasePhoneHelper.getCommonSolutions();
    String solutionText = '';

    // البحث عن حل مناسب
    if (title.contains('إرسال')) {
      solutionText =
          '\nحلول مقترحة:\n${solutions['فشل إرسال الرمز']?.take(3).join('\n• ') ?? ''}';
    } else if (errorMsg.contains('internal-error')) {
      solutionText =
          '\nحلول مقترحة:\n${solutions['خطأ internal-error']?.take(3).join('\n• ') ?? ''}';
    } else if (errorMsg.contains('too-many-requests')) {
      solutionText =
          '\nحلول مقترحة:\n${solutions['الحد الأقصى للطلبات']?.take(3).join('\n• ') ?? ''}';
    }

    // عرض رسالة خطأ مع الحلول
    Get.snackbar(
      title,
      errorMsg + solutionText,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red.withOpacity(0.1),
      colorText: Colors.red,
      duration: Duration(seconds: 8), // مدة أطول لقراءة الحلول
      maxWidth: Get.width * 0.95,
    );

    statusMessage.value = title;
  }

  void _showError(String message) {
    errorMessage.value = message;
    isCodeValid.value = false;
    HapticFeedback.heavyImpact();

    Future.delayed(const Duration(seconds: 3), () {
      errorMessage.value = '';
      isCodeValid.value = true;
    });
  }

  // ===================== Resource Management =====================
  void _disposeResources() {
    _resendTimer?.cancel();
    _autoFillTimer?.cancel();
    _connectivitySubscription.cancel();
    pinController.dispose();

    // ✅ تنظيف حالة الحماية من الطلبات المتكررة
    _resetDuplicateProtection();

    for (var controller in codeControllers) {
      controller.dispose();
    }

    for (var node in focusNodes) {
      node.dispose();
    }
  }

  // ===================== Public Methods for UI =====================
  void moveToNextField(int currentIndex) {
    _moveToNextField(currentIndex);
  }

  void handlePastedText(String text, int startIndex) {
    // تنظيف النص - إزالة كل شيء عدا الأرقام
    final cleanText = text.replaceAll(RegExp(r'[^0-9]'), '');

    // ملء الحقول بناءً على النص المنسوخ
    for (
      int i = 0;
      i < cleanText.length && (startIndex + i) < _codeLength;
      i++
    ) {
      codeControllers[startIndex + i].text = cleanText[i];
    }

    // التركيز على الحقل التالي المناسب
    final nextIndex = (startIndex + cleanText.length).clamp(0, _codeLength - 1);
    if (nextIndex < _codeLength) {
      focusNodes[nextIndex].requestFocus();
    }

    // التحقق التلقائي إذا تم ملء جميع الحقول
    _updateAllCodeText();
    _checkAutoVerification();
  }

  // ===================== Utility Methods =====================
  void onBackspacePressed(int index) {
    if (codeControllers[index].text.isEmpty && index > 0) {
      _moveToPreviousField(index);
    } else {
      codeControllers[index].clear();
    }
  }

  void onFieldTapped(int index) {
    focusNodes[index].requestFocus();
    HapticFeedback.selectionClick();
  }

  double get verificationProgress {
    final filledFields = codeControllers.where((c) => c.text.isNotEmpty).length;
    return filledFields / _codeLength;
  }

  String get resendButtonText {
    if (canResend.value) {
      return 'إعادة إرسال الرمز';
    } else {
      return 'إعادة الإرسال خلال ${resendCounter.value}s';
    }
  }

  bool get isResendEnabled =>
      canResend.value && resendAttempts.value < _maxResendAttempts;
}
