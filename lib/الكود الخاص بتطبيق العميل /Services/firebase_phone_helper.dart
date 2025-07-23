import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// كلاس مساعد لتشخيص وحل مشاكل Firebase Phone Auth
class FirebasePhoneHelper {
  static const String version = '1.0.0';

  /// تشخيص شامل لإعدادات Firebase Phone Auth
  static Future<Map<String, dynamic>> comprehensiveDiagnosis() async {
    final diagnosis = <String, dynamic>{
      'helper_version': version,
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      // 1. معلومات Firebase الأساسية
      final auth = FirebaseAuth.instance;
      diagnosis['firebase'] = {
        'app_id': auth.app.options.appId,
        'project_id': auth.app.options.projectId,
        'api_key': auth.app.options.apiKey.substring(0, 10) + '...',
        'current_user': auth.currentUser?.uid ?? 'no_user',
        'auth_domain': auth.app.options.authDomain,
      };

      // 2. معلومات المنصة
      diagnosis['platform'] = {
        'os': Platform.operatingSystem,
        'version': Platform.operatingSystemVersion,
        'is_android': Platform.isAndroid,
        'is_ios': Platform.isIOS,
        'is_debug': kDebugMode,
      };

      // 3. فحص إعدادات Android
      if (Platform.isAndroid) {
        diagnosis['android'] = await _diagnoseAndroid(auth);
      }

      // 4. فحص إعدادات iOS
      if (Platform.isIOS) {
        diagnosis['ios'] = await _diagnoseiOS(auth);
      }

      // 5. نصائح التحسين
      diagnosis['optimization_tips'] = _getOptimizationTips();

      debugPrint('🔍 تشخيص Firebase Phone Auth مكتمل');
      return diagnosis;
    } catch (e) {
      diagnosis['error'] = e.toString();
      debugPrint('❌ خطأ في التشخيص الشامل: $e');
      return diagnosis;
    }
  }

  /// تشخيص إعدادات Android
  static Future<Map<String, dynamic>> _diagnoseAndroid(
    FirebaseAuth auth,
  ) async {
    final androidDiag = <String, dynamic>{};

    try {
      // فحص SHA-1 fingerprint (لا يمكن الوصول إليه مباشرة من Flutter)
      androidDiag['sha1_note'] =
          'تأكد من إضافة SHA-1 fingerprint في Firebase Console';

      // فحص SMS permissions
      androidDiag['sms_permissions'] = {
        'note': 'تأكد من إضافة أذونات SMS في AndroidManifest.xml',
        'required_permissions': [
          'android.permission.RECEIVE_SMS',
          'android.permission.READ_SMS',
        ],
      };

      // نصائح Android
      androidDiag['tips'] = [
        'تأكد من تحديث Google Play Services',
        'فعل SafetyNet في Firebase Console',
        'تأكد من SHA-1 fingerprint للتوقيع',
      ];

      return androidDiag;
    } catch (e) {
      androidDiag['error'] = e.toString();
      return androidDiag;
    }
  }

  /// تشخيص إعدادات iOS
  static Future<Map<String, dynamic>> _diagnoseiOS(FirebaseAuth auth) async {
    final iosDiag = <String, dynamic>{};

    try {
      // فحص Bundle ID
      iosDiag['bundle_id_note'] = 'تأكد من تطابق Bundle ID مع Firebase Console';

      // فحص APN
      iosDiag['apn_setup'] = {
        'note': 'reCAPTCHA قد يتطلب إعداد APN صحيح',
        'requirements': [
          'APN Key في Firebase Console',
          'تفعيل Push Notifications في Xcode',
        ],
      };

      // نصائح iOS
      iosDiag['tips'] = [
        'تأكد من Bundle ID صحيح',
        'فعل Push Notifications capability',
        'تأكد من APN authentication key',
        'اختبر على جهاز حقيقي وليس المحاكي',
      ];

      return iosDiag;
    } catch (e) {
      iosDiag['error'] = e.toString();
      return iosDiag;
    }
  }

  /// نصائح تحسين عامة
  static List<String> _getOptimizationTips() {
    return [
      '🔧 تأكد من تفعيل Phone Authentication في Firebase Console',
      '📱 أضف الأرقام التجريبية في قسم "Phone numbers for testing"',
      '🌐 تأكد من إعدادات reCAPTCHA للمنصة المستهدفة',
      '🔒 استخدم HTTPS للـ Authorized domains',
      '📊 راقب حدود الاستخدام في Firebase Console',
      '🧪 اختبر مع أرقام حقيقية وتجريبية',
      '🔄 أعد تشغيل التطبيق بعد تغيير الإعدادات',
    ];
  }

  /// فحص صحة رقم الهاتف المحسن
  static Map<String, dynamic> validatePhoneNumberAdvanced(String phoneNumber) {
    final validation = <String, dynamic>{
      'input': phoneNumber,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // 1. فحص أساسي
    validation['basic'] = {
      'has_plus': phoneNumber.startsWith('+'),
      'length': phoneNumber.length,
      'is_numeric_only': RegExp(r'^\+\d+$').hasMatch(phoneNumber),
      'contains_spaces': phoneNumber.contains(' '),
      'contains_dashes': phoneNumber.contains('-'),
    };

    // 2. تحليل الدولة
    validation['country'] = _analyzeCountryCode(phoneNumber);

    // 3. تحليل نوع الرقم
    validation['type'] = _analyzePhoneType(phoneNumber);

    // 4. اقتراحات التحسين
    validation['suggestions'] = _getSuggestions(phoneNumber);

    return validation;
  }

  /// تحليل رمز الدولة
  static Map<String, dynamic> _analyzeCountryCode(String phoneNumber) {
    final countryData = <String, dynamic>{};

    if (phoneNumber.startsWith('+964')) {
      countryData.addAll({
        'country': 'العراق',
        'code': '+964',
        'valid_length_range': '13-14',
        'operators': ['زين', 'آسياسيل', 'كورك'],
        'is_supported': true,
      });
    } else if (phoneNumber.startsWith('+966')) {
      countryData.addAll({
        'country': 'السعودية',
        'code': '+966',
        'valid_length_range': '13',
        'operators': ['STC', 'Mobily', 'Zain'],
        'is_supported': true,
      });
    } else if (phoneNumber.startsWith('+1')) {
      countryData.addAll({
        'country': 'الولايات المتحدة/كندا',
        'code': '+1',
        'valid_length_range': '12',
        'is_supported': true,
      });
    } else {
      countryData.addAll({
        'country': 'غير محدد',
        'code':
            phoneNumber.length > 3 ? phoneNumber.substring(0, 4) : 'غير صحيح',
        'is_supported': 'غير معروف',
      });
    }

    return countryData;
  }

  /// تحليل نوع الرقم
  static Map<String, dynamic> _analyzePhoneType(String phoneNumber) {
    final typeData = <String, dynamic>{};

    // فحص إذا كان رقماً تجريبياً
    final testPatterns = [
      '+1555',
      '+15005550',
      '+4474',
      '+33123456',
      '+96412345',
      '+966123',
    ];

    bool isTestNumber = false;
    for (final pattern in testPatterns) {
      if (phoneNumber.startsWith(pattern)) {
        isTestNumber = true;
        break;
      }
    }

    // فحص أنماط تجريبية أخرى
    if (!isTestNumber) {
      if (phoneNumber.contains('123456') ||
          phoneNumber.contains('555555') ||
          phoneNumber.contains('000000')) {
        isTestNumber = true;
      }
    }

    typeData['is_test_number'] = isTestNumber;
    typeData['type'] = isTestNumber ? 'تجريبي' : 'حقيقي';

    if (isTestNumber) {
      typeData['test_note'] =
          'تأكد من إضافة هذا الرقم في Firebase Console تحت "Phone numbers for testing"';
    }

    return typeData;
  }

  /// اقتراحات تحسين الرقم
  static List<String> _getSuggestions(String phoneNumber) {
    final suggestions = <String>[];

    if (!phoneNumber.startsWith('+')) {
      suggestions.add('أضف رمز الدولة (مثل +964 للعراق)');
    }

    if (phoneNumber.contains(' ') || phoneNumber.contains('-')) {
      suggestions.add('احذف المسافات والشرطات');
    }

    if (phoneNumber.length < 10) {
      suggestions.add('الرقم قصير جداً، تأكد من الرقم كاملاً');
    }

    if (phoneNumber.length > 15) {
      suggestions.add('الرقم طويل جداً، تحقق من صحته');
    }

    if (!RegExp(r'^\+\d+$').hasMatch(phoneNumber)) {
      suggestions.add('استخدم الأرقام ورمز + فقط');
    }

    if (suggestions.isEmpty) {
      suggestions.add('الرقم يبدو صحيحاً');
    }

    return suggestions;
  }

  /// نصائح لحل المشاكل الشائعة
  static Map<String, List<String>> getCommonSolutions() {
    return {
      'فشل إرسال الرمز': [
        'تحقق من اتصال الإنترنت',
        'تأكد من صحة رقم الهاتف',
        'تأكد من إعدادات Firebase Console',
        'أعد تشغيل التطبيق',
        'جرب رقماً تجريبياً أولاً',
      ],
      'رمز التحقق غير صحيح': [
        'تأكد من إدخال الرمز الصحيح',
        'للأرقام التجريبية: استخدم الرمز من Firebase Console',
        'للأرقام الحقيقية: استخدم الرمز من SMS',
        'تحقق من انتهاء صلاحية الرمز',
      ],
      'خطأ internal-error': [
        'أعد تشغيل التطبيق',
        'تحقق من إعدادات reCAPTCHA',
        'تحقق من SHA-1 fingerprint (Android)',
        'تحقق من Bundle ID (iOS)',
        'جرب على شبكة مختلفة',
      ],
      'الحد الأقصى للطلبات': [
        'انتظر بضع دقائق قبل إعادة المحاولة',
        'استخدم أرقاماً تجريبية للاختبار',
        'تحقق من حدود Firebase في Console',
      ],
    };
  }

  /// طباعة تقرير مفصل
  static void printDetailedReport(Map<String, dynamic> diagnosis) {
    print('\n🔍 ===== تقرير تشخيص Firebase Phone Auth =====');
    print('📅 الوقت: ${diagnosis['timestamp']}');
    print('📱 المنصة: ${diagnosis['platform']['os']}');
    print('🔧 إصدار المساعد: ${diagnosis['helper_version']}');

    if (diagnosis.containsKey('firebase')) {
      print('\n🔥 Firebase:');
      final firebase = diagnosis['firebase'] as Map<String, dynamic>;
      firebase.forEach((key, value) {
        print('   $key: $value');
      });
    }

    if (diagnosis.containsKey('android')) {
      print('\n🤖 Android:');
      print('   ${diagnosis['android']}');
    }

    if (diagnosis.containsKey('ios')) {
      print('\n🍎 iOS:');
      print('   ${diagnosis['ios']}');
    }

    if (diagnosis.containsKey('optimization_tips')) {
      print('\n💡 نصائح التحسين:');
      for (final tip in diagnosis['optimization_tips'] as List<String>) {
        print('   • $tip');
      }
    }

    print('\n🔧 ===== نهاية التقرير =====\n');
  }
}
