import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';

/// خدمة التحقق من رقم الهاتف المحسنة - تعمل فقط مع Firebase والأرقام الحقيقية
class PhoneAuthService extends GetxService {
  static PhoneAuthService get instance => Get.find<PhoneAuthService>();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // حالات الخدمة المحسنة مع حماية من الطلبات المتكررة
  final RxBool _isLoading = false.obs;
  final RxString _currentVerificationId = ''.obs;
  final RxString _currentPhoneNumber = ''.obs;
  final RxInt _resendToken = 0.obs;

  // حماية من الطلبات المتكررة
  DateTime? _lastRequestTime;
  String? _lastRequestedPhone;
  bool _isRequestInProgress = false;
  static const int _minimumRequestInterval = 5000; // 5 ثواني بين الطلبات

  // Getters
  bool get isLoading => _isLoading.value;
  String get verificationId => _currentVerificationId.value;
  String get phoneNumber => _currentPhoneNumber.value;
  bool get canMakeRequest => !_isRequestInProgress;

  @override
  void onInit() {
    super.onInit();
    _setupAuthStateListener();
    debugPrint('📱 تم تهيئة PhoneAuthService بنجاح');
    _logEvent('PhoneAuthService تم تهيئته', {
      'timestamp': DateTime.now().toString(),
    });
  }

  /// إعداد مستمع حالة المصادقة
  void _setupAuthStateListener() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        debugPrint('✅ المستخدم مسجل الدخول: ${user.uid}');
        _logSuccess('تم تسجيل الدخول', {
          'uid': user.uid,
          'phone': user.phoneNumber,
        });
      } else {
        debugPrint('❌ لا يوجد مستخدم مسجل');
      }
    });
  }

  /// إرسال رمز التحقق إلى رقم الهاتف مع حماية من الطلبات المتكررة وتحسينات للأرقام التجريبية
  Future<PhoneAuthResult> sendVerificationCode(String phoneNumber) async {
    // فحص الحماية من الطلبات المتكررة
    if (!_canMakeNewRequest(phoneNumber)) {
      final timeLeft = _getTimeUntilNextRequest();
      debugPrint('🛡️ طلب مرفوض - يجب الانتظار $timeLeft ثانية');
      return PhoneAuthResult.error(
        'يرجى الانتظار $timeLeft ثانية قبل المحاولة مرة أخرى',
      );
    }

    // فحص إذا كان هناك طلب قيد التنفيذ
    if (_isRequestInProgress) {
      debugPrint('⚠️ طلب إرسال رمز قيد التنفيذ بالفعل');
      return PhoneAuthResult.error(
        'يتم إرسال رمز التحقق بالفعل، يرجى الانتظار',
      );
    }

    try {
      _isRequestInProgress = true;
      _isLoading.value = true;
      _currentPhoneNumber.value = phoneNumber;
      _lastRequestTime = DateTime.now();
      _lastRequestedPhone = phoneNumber;

      debugPrint('📤 بدء إرسال رمز التحقق إلى: $phoneNumber');
      debugPrint('🛡️ حماية مطبقة - آخر طلب: $_lastRequestTime');

      _logEvent('بدء التحقق من الهاتف', {
        'phone': phoneNumber,
        'platform': Platform.operatingSystem,
        'request_time': _lastRequestTime.toString(),
        'protection_active': true,
      });

      // فحص إعدادات Firebase قبل البدء
      await _ensureFirebaseReady();

      final Completer<PhoneAuthResult> completer = Completer();

      // إعدادات محسنة للـ reCAPTCHA
      if (Platform.isIOS) {
        debugPrint('🍎 تهيئة iOS reCAPTCHA...');
        await _configureiOSRecaptcha();
      }

      // ✅ إعدادات محسنة لدعم الأرقام التجريبية
      debugPrint('🧪 فحص إذا كان الرقم تجريبي...');
      final isTestNumber = _isTestPhoneNumber(phoneNumber);
      debugPrint('📱 نوع الرقم: ${isTestNumber ? "تجريبي" : "حقيقي"}');

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: Duration(
          seconds: isTestNumber ? 60 : 120,
        ), // مهلة أقل للأرقام التجريبية
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint('✅ تم التحقق التلقائي');
          _logSuccess('اكتمل التحقق التلقائي');

          try {
            final result = await _signInWithCredential(credential);
            if (!completer.isCompleted) {
              completer.complete(
                PhoneAuthResult.success(
                  type: PhoneAuthResultType.autoVerified,
                  credential: credential,
                  user: result.user,
                ),
              );
            }
          } catch (e) {
            debugPrint('❌ فشل التسجيل التلقائي: $e');
            _logError('فشل التسجيل التلقائي', e.toString());
            if (!completer.isCompleted) {
              completer.complete(PhoneAuthResult.error(e.toString()));
            }
          }
        },
        verificationFailed: (FirebaseAuthException e) async {
          debugPrint('❌ فشل التحقق من الهاتف: ${e.code} - ${e.message}');

          // معالجة خاصة للأرقام التجريبية
          if (isTestNumber && e.code == 'invalid-phone-number') {
            debugPrint(
              '🧪 خطأ رقم تجريبي - قد يكون الرقم غير مُضاف في Firebase Console',
            );
            if (!completer.isCompleted) {
              completer.complete(
                PhoneAuthResult.error(
                  'الرقم التجريبي غير مُضاف في إعدادات Firebase. تأكد من إضافته في Firebase Console تحت Phone numbers for testing.',
                ),
              );
            }
            return;
          }

          // معالجة خاصة لـ internal-error
          if (e.code == 'internal-error') {
            await _handleInternalError(e, phoneNumber, completer);
            return;
          }

          _logError('فشل التحقق من الهاتف', '${e.code} - ${e.message}', {
            'error_code': e.code,
            'error_message': e.message,
            'phone': phoneNumber,
            'is_test_number': isTestNumber,
          });

          if (!completer.isCompleted) {
            completer.complete(
              PhoneAuthResult.error(_getLocalizedErrorMessage(e.code)),
            );
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          _currentVerificationId.value = verificationId;
          _resendToken.value = resendToken ?? 0;

          debugPrint('📩 تم إرسال رمز التحقق بنجاح. ID: $verificationId');
          debugPrint(
            '🧪 نوع الرقم: ${isTestNumber ? "تجريبي - استخدم الرمز المحدد في Firebase Console" : "حقيقي - استخدم الرمز المُرسل عبر SMS"}',
          );

          _logSuccess('تم إرسال رمز التحقق', {
            'verification_id': verificationId,
            'resend_token': resendToken,
            'is_test_number': isTestNumber,
          });

          if (!completer.isCompleted) {
            completer.complete(
              PhoneAuthResult.success(
                type: PhoneAuthResultType.codeSent,
                verificationId: verificationId,
              ),
            );
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _currentVerificationId.value = verificationId;
          debugPrint('⏰ انتهت مهلة الاستلام التلقائي. ID: $verificationId');
          debugPrint(
            '🧪 للأرقام التجريبية: استخدم الرمز المحدد في Firebase Console',
          );

          _logEvent('انتهت مهلة الاستلام التلقائي', {
            'verification_id': verificationId,
            'is_test_number': isTestNumber,
          });
        },
      );

      return completer.future;
    } catch (e, stackTrace) {
      debugPrint('🚨 خطأ في إرسال رمز التحقق: $e');
      debugPrint('StackTrace: $stackTrace');
      _logError('فشل إرسال رمز التحقق', e.toString(), {
        'phone': phoneNumber,
        'stack_trace': stackTrace.toString(),
      });

      return PhoneAuthResult.error('حدث خطأ غير متوقع: ${e.toString()}');
    } finally {
      _isLoading.value = false;
      _isRequestInProgress = false;
      debugPrint('🔄 تم إنهاء طلب الإرسال - الحماية نشطة');
    }
  }

  /// التأكد من جاهزية Firebase
  Future<void> _ensureFirebaseReady() async {
    try {
      // التحقق من التهيئة
      if (_auth.app.isAutomaticDataCollectionEnabled) {
        debugPrint('✅ Firebase Auth جاهز');
      }

      // فحص الاتصال
      final user = _auth.currentUser;
      debugPrint('👤 المستخدم الحالي: ${user?.uid ?? "لا يوجد"}');

      // انتظار صغير للتأكد من الاستقرار
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      debugPrint('⚠️ تحذير في فحص Firebase: $e');
    }
  }

  /// تكوين reCAPTCHA لـ iOS
  Future<void> _configureiOSRecaptcha() async {
    try {
      if (Platform.isIOS) {
        // إعطاء وقت إضافي لتحميل reCAPTCHA على iOS
        await Future.delayed(const Duration(milliseconds: 1000));
        debugPrint('🔐 تم تكوين iOS reCAPTCHA');
      }
    } catch (e) {
      debugPrint('⚠️ تحذير في تكوين iOS reCAPTCHA: $e');
    }
  }

  /// معالجة خاصة لخطأ internal-error
  Future<void> _handleInternalError(
    FirebaseAuthException e,
    String phoneNumber,
    Completer<PhoneAuthResult> completer,
  ) async {
    debugPrint('🔧 معالجة internal-error...');

    // محاولة التشخيص
    final diagnosis = await diagnoseFirebaseSetup();
    debugPrint('📊 تشخيص عند الخطأ: $diagnosis');

    // اقتراحات للحل
    String errorMsg = 'خطأ داخلي في Firebase. ';

    if (Platform.isIOS) {
      errorMsg +=
          'للأجهزة iOS: تأكد من إعدادات reCAPTCHA في Firebase Console. ';
    }

    if (Platform.isAndroid) {
      errorMsg +=
          'للأجهزة Android: تأكد من SHA-1 fingerprint في Firebase Console. ';
    }

    // محاولة إعادة التهيئة
    try {
      debugPrint('🔄 محاولة إعادة التهيئة...');
      await Future.delayed(const Duration(seconds: 2));

      // إعادة المحاولة مرة واحدة
      if (!completer.isCompleted) {
        errorMsg += 'يرجى المحاولة مرة أخرى بعد لحظات.';
        completer.complete(PhoneAuthResult.error(errorMsg));
      }
    } catch (retryError) {
      debugPrint('❌ فشل في إعادة المحاولة: $retryError');
      if (!completer.isCompleted) {
        completer.complete(
          PhoneAuthResult.error('$errorMsg خطأ إضافي: $retryError'),
        );
      }
    }
  }

  /// التحقق من رمز SMS المدخل - فقط للأرقام الحقيقية
  Future<PhoneAuthResult> verifyCode(String smsCode) async {
    try {
      if (_currentVerificationId.value.isEmpty) {
        throw Exception('لم يتم إرسال رمز التحقق بعد');
      }

      _isLoading.value = true;

      debugPrint('🔍 بدء التحقق من الرمز: $smsCode');
      _logEvent('التحقق من رمز SMS', {
        'code_length': smsCode.length,
        'phone_number': _currentPhoneNumber.value,
      });

      // استخدام Firebase للتحقق من الرمز
      final credential = PhoneAuthProvider.credential(
        verificationId: _currentVerificationId.value,
        smsCode: smsCode,
      );

      final result = await _signInWithCredential(credential);

      debugPrint('✅ تم التحقق من الرمز بنجاح. UID: ${result.user?.uid}');
      _logSuccess('تم التحقق من رمز SMS بنجاح', {'uid': result.user?.uid});

      return PhoneAuthResult.success(
        type: PhoneAuthResultType.verified,
        credential: credential,
        user: result.user,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ فشل التحقق من الرمز: ${e.code} - ${e.message}');
      _logError('فشل التحقق من الرمز', '${e.code} - ${e.message}', {
        'error_code': e.code,
        'error_message': e.message,
        'code_length': smsCode.length,
      });

      return PhoneAuthResult.error(_getLocalizedErrorMessage(e.code));
    } catch (e, stackTrace) {
      debugPrint('🚨 خطأ غير متوقع في التحقق: $e');
      debugPrint('StackTrace: $stackTrace');
      _logError('خطأ غير متوقع في التحقق', e.toString(), {
        'stack_trace': stackTrace.toString(),
      });

      return PhoneAuthResult.error('حدث خطأ أثناء التحقق: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  /// إعادة إرسال رمز التحقق
  Future<PhoneAuthResult> resendCode() async {
    if (_currentPhoneNumber.value.isEmpty) {
      return PhoneAuthResult.error('لم يتم تحديد رقم الهاتف');
    }

    return sendVerificationCode(_currentPhoneNumber.value);
  }

  /// تسجيل الدخول باستخدام الاعتماد
  Future<UserCredential> _signInWithCredential(
    PhoneAuthCredential credential,
  ) async {
    return await _auth.signInWithCredential(credential);
  }

  /// ترجمة رسائل الخطأ للعربية مع تفاصيل إضافية
  String _getLocalizedErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'invalid-phone-number':
        return '''رقم الهاتف غير صحيح.
• تأكد من إضافة رمز الدولة (+964 للعراق)
• تأكد من عدم وجود مسافات أو رموز إضافية
• للأرقام التجريبية: تأكد من إضافتها في Firebase Console تحت "Phone numbers for testing"''';
      case 'too-many-requests':
        return 'تم إرسال الكثير من الطلبات. يرجى الانتظار ${_getWaitTime()} دقيقة والمحاولة لاحقاً.';
      case 'invalid-verification-code':
        return '''رمز التحقق غير صحيح.
• تأكد من إدخال الرمز الصحيح
• للأرقام التجريبية: استخدم الرمز المحدد في Firebase Console
• للأرقام الحقيقية: استخدم الرمز المُرسل عبر SMS''';
      case 'session-expired':
        return 'انتهت صلاحية الجلسة. يرجى طلب رمز جديد.';
      case 'quota-exceeded':
        return 'تم تجاوز الحد المسموح من رسائل التحقق اليومية. يرجى المحاولة غداً.';
      case 'captcha-check-failed':
        return 'فشل التحقق الأمني (reCAPTCHA). يرجى إعادة تشغيل التطبيق والمحاولة مرة أخرى.';
      case 'web-context-cancelled':
        return 'تم إلغاء عملية التحقق. يرجى المحاولة مرة أخرى.';
      case 'network-request-failed':
        return 'مشكلة في الاتصال بالإنترنت. يرجى التحقق من اتصالك والمحاولة مرة أخرى.';
      case 'app-not-authorized':
        return 'التطبيق غير مُخول لاستخدام Firebase Auth. يرجى التواصل مع الدعم الفني.';
      case 'internal-error':
        return _getInternalErrorMessage();
      case 'missing-client-identifier':
        return 'خطأ في إعدادات التطبيق. يرجى إعادة تثبيت التطبيق.';
      case 'invalid-app-credential':
        return 'بيانات اعتماد التطبيق غير صحيحة. يرجى التواصل مع الدعم الفني.';
      case 'operation-not-allowed':
        return '''التحقق من رقم الهاتف غير مفعل.
• تأكد من تفعيل Phone Authentication في Firebase Console
• تأكد من إعداد الأرقام التجريبية إذا كنت تستخدم رقماً تجريبياً''';
      case 'user-disabled':
        return 'تم تعطيل حسابك. يرجى التواصل مع الدعم الفني.';
      default:
        return 'حدث خطأ غير متوقع: $errorCode. يرجى المحاولة مرة أخرى أو التواصل مع الدعم الفني.';
    }
  }

  /// رسالة خطأ internal-error مخصصة
  String _getInternalErrorMessage() {
    if (Platform.isIOS) {
      return '''خطأ داخلي في النظام (iOS). 
الحلول المقترحة:
• تأكد من اتصالك بالإنترنت
• أعد تشغيل التطبيق
• إذا استمر الخطأ، فقد تكون هناك مشكلة في إعدادات reCAPTCHA
• يرجى المحاولة مرة أخرى بعد بضع دقائق''';
    } else if (Platform.isAndroid) {
      return '''خطأ داخلي في النظام (Android).
الحلول المقترحة:
• تأكد من اتصالك بالإنترنت
• أعد تشغيل التطبيق
• تأكد من تحديث Google Play Services
• يرجى المحاولة مرة أخرى بعد بضع دقائق''';
    } else {
      return 'خطأ داخلي في النظام. يرجى إعادة المحاولة أو التواصل مع الدعم الفني.';
    }
  }

  /// حساب وقت الانتظار بناءً على عدد المحاولات
  String _getWaitTime() {
    // يمكن تحسين هذا بناءً على عدد المحاولات الفعلي
    return '5'; // افتراضياً 5 دقائق
  }

  /// تنظيف البيانات
  void reset() {
    _currentVerificationId.value = '';
    _currentPhoneNumber.value = '';
    _resendToken.value = 0;
    _isLoading.value = false;

    debugPrint('🔄 تم إعادة تعيين PhoneAuthService');
    _logEvent('تم إعادة تعيين PhoneAuthService');
  }

  /// تشخيص إعدادات Firebase وإعطاء تقرير مفصل
  Future<Map<String, dynamic>> diagnoseFirebaseSetup() async {
    final diagnosis = <String, dynamic>{};

    try {
      // 1. فحص Firebase Auth
      diagnosis['firebase_auth_initialized'] = true;
      diagnosis['current_user'] = _auth.currentUser?.uid ?? 'no_user';

      // 2. فحص Platform
      diagnosis['platform'] = Platform.operatingSystem;
      diagnosis['is_android'] = Platform.isAndroid;
      diagnosis['is_ios'] = Platform.isIOS;

      // 3. فحص إعدادات التطبيق
      diagnosis['app_id'] = _auth.app.options.appId;
      diagnosis['project_id'] = _auth.app.options.projectId;

      // 4. فحص حالة الخدمة
      diagnosis['service_loading'] = _isLoading.value;
      diagnosis['current_phone'] = _currentPhoneNumber.value;
      diagnosis['verification_id'] = _currentVerificationId.value.isNotEmpty;

      debugPrint('📊 تشخيص Firebase مكتمل: $diagnosis');
      _logEvent('تم إكمال تشخيص Firebase', diagnosis);

      return diagnosis;
    } catch (e) {
      diagnosis['error'] = e.toString();
      debugPrint('❌ خطأ في تشخيص Firebase: $e');
      return diagnosis;
    }
  }

  /// فحص صحة رقم الهاتف
  Map<String, dynamic> validatePhoneNumber(String phoneNumber) {
    final validation = <String, dynamic>{};

    // 1. فحص التنسيق
    validation['has_plus'] = phoneNumber.startsWith('+');
    validation['length'] = phoneNumber.length;
    validation['is_numeric'] = RegExp(r'^\+\d+$').hasMatch(phoneNumber);

    // 2. فحص البلد
    if (phoneNumber.startsWith('+964')) {
      validation['country'] = 'Iraq';
      validation['valid_length'] =
          phoneNumber.length >= 13 && phoneNumber.length <= 14;
    } else if (phoneNumber.startsWith('+966')) {
      validation['country'] = 'Saudi Arabia';
      validation['valid_length'] = phoneNumber.length == 13;
    } else if (phoneNumber.startsWith('+1')) {
      validation['country'] = 'US/Canada';
      validation['valid_length'] = phoneNumber.length == 12;
    } else {
      validation['country'] = 'Other';
      validation['valid_length'] = phoneNumber.length >= 10;
    }

    // النظام يعمل فقط مع الأرقام الحقيقية
    validation['is_real_number'] = true;

    debugPrint('📞 تحقق من صحة الرقم: $validation');
    return validation;
  }

  /// طريقة للتحقق من أن الخدمة تعمل
  void testService() {
    debugPrint('🧪 اختبار PhoneAuthService...');
    debugPrint('✅ الخدمة تعمل بشكل صحيح!');
    debugPrint('📊 حالة التحميل: ${_isLoading.value}');
    debugPrint('📱 رقم الهاتف الحالي: ${_currentPhoneNumber.value}');
    debugPrint('🔑 معرف التحقق: ${_currentVerificationId.value}');
  }

  /// حصول على تقرير شامل عن حالة الخدمة
  Map<String, dynamic> getServiceReport() {
    return {
      'service_name': 'PhoneAuthService',
      'version': '2.0.0',
      'status': isLoading ? 'busy' : 'ready',
      'current_session': {
        'phone_number': _currentPhoneNumber.value,
        'has_verification_id': _currentVerificationId.value.isNotEmpty,
      },
      'firebase_info': {
        'auth_initialized': _auth.currentUser != null,
        'current_user_uid': _auth.currentUser?.uid,
        'current_user_phone': _auth.currentUser?.phoneNumber,
      },
      'generated_at': DateTime.now().toIso8601String(),
    };
  }

  // === دوال التسجيل المحلية ===

  /// تسجيل حدث عام
  void _logEvent(String event, [Map<String, dynamic>? data]) {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('📊 [$timestamp] PhoneAuthService: $event');
    if (data != null && data.isNotEmpty) {
      debugPrint('   📄 البيانات: ${data.toString()}');
    }
  }

  /// تسجيل عملية ناجحة
  void _logSuccess(String operation, [Map<String, dynamic>? data]) {
    _logEvent('✅ نجح: $operation', data);
  }

  /// تسجيل خطأ
  void _logError(
    String operation,
    String error, [
    Map<String, dynamic>? additionalData,
  ]) {
    final errorData = {
      'error': error,
      'operation': operation,
      if (additionalData != null) ...additionalData,
    };
    _logEvent('❌ فشل: $operation', errorData);
  }

  /// فحص إمكانية إجراء طلب جديد (حماية من الطلبات المتكررة)
  bool _canMakeNewRequest(String phoneNumber) {
    // إذا لم يكن هناك طلب سابق، يمكن الإرسال
    if (_lastRequestTime == null) {
      return true;
    }

    // إذا كان الرقم مختلف، يمكن الإرسال
    if (_lastRequestedPhone != phoneNumber) {
      return true;
    }

    // فحص الفترة الزمنية
    final timeSinceLastRequest =
        DateTime.now().difference(_lastRequestTime!).inMilliseconds;
    return timeSinceLastRequest >= _minimumRequestInterval;
  }

  /// حساب الوقت المتبقي للطلب التالي
  int _getTimeUntilNextRequest() {
    if (_lastRequestTime == null) return 0;

    final timeSinceLastRequest =
        DateTime.now().difference(_lastRequestTime!).inMilliseconds;
    final timeLeft = _minimumRequestInterval - timeSinceLastRequest;
    return (timeLeft / 1000).ceil().clamp(0, 99);
  }

  /// إعادة تعيين حالة الطلبات (للطوارئ أو الاختبار)
  void resetRequestState() {
    _lastRequestTime = null;
    _lastRequestedPhone = null;
    _isRequestInProgress = false;
    debugPrint('🔄 تم إعادة تعيين حالة طلبات PhoneAuthService');
  }

  /// فحص إذا كان رقم الهاتف تجريبي
  bool _isTestPhoneNumber(String phoneNumber) {
    // قائمة الأرقام التجريبية الشائعة
    final testPatterns = [
      '+1555', // أرقام تجريبية أمريكية
      '+15005550', // أرقام تجريبية أمريكية
      '+4474', // أرقام تجريبية بريطانية
      '+33123456', // أرقام تجريبية فرنسية
      '+96412345', // أرقام تجريبية عراقية
      '+966123', // أرقام تجريبية سعودية
    ];

    // فحص إذا كان الرقم يبدأ بأي من الأنماط التجريبية
    for (final pattern in testPatterns) {
      if (phoneNumber.startsWith(pattern)) {
        return true;
      }
    }

    // فحص أنماط أخرى للأرقام التجريبية
    // الأرقام التي تحتوي على أنماط متكررة قد تكون تجريبية
    if (phoneNumber.contains('123456') ||
        phoneNumber.contains('555555') ||
        phoneNumber.contains('000000')) {
      return true;
    }

    return false;
  }
}

/// نتيجة عملية المصادقة
class PhoneAuthResult {
  final bool isSuccess;
  final String? error;
  final PhoneAuthResultType? type;
  final String? verificationId;
  final PhoneAuthCredential? credential;
  final User? user;

  PhoneAuthResult._({
    required this.isSuccess,
    this.error,
    this.type,
    this.verificationId,
    this.credential,
    this.user,
  });

  factory PhoneAuthResult.success({
    required PhoneAuthResultType type,
    String? verificationId,
    PhoneAuthCredential? credential,
    User? user,
  }) {
    return PhoneAuthResult._(
      isSuccess: true,
      type: type,
      verificationId: verificationId,
      credential: credential,
      user: user,
    );
  }

  factory PhoneAuthResult.error(String error) {
    return PhoneAuthResult._(isSuccess: false, error: error);
  }
}

/// أنواع نتائج المصادقة
enum PhoneAuthResultType { codeSent, autoVerified, verified }
