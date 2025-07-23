import 'dart:io';
import 'package:flutter/foundation.dart';

/// نظام متقدم لتتبع الأخطاء والتحليلات
class ErrorTracker {
  static final ErrorTracker _instance = ErrorTracker._internal();
  factory ErrorTracker() => _instance;
  ErrorTracker._internal();

  /// تسجيل خطأ مع تفاصيل شاملة
  static Future<void> logError({
    required String error,
    required String location,
    StackTrace? stackTrace,
    Map<String, dynamic>? additionalData,
    ErrorSeverity severity = ErrorSeverity.medium,
  }) async {
    try {
      // طباعة في وضع التطوير
      if (kDebugMode) {
        debugPrint('🔴 ERROR [$severity] in $location:');
        debugPrint('📍 Error: $error');
        if (additionalData != null) {
          debugPrint('📊 Data: $additionalData');
        }
        if (stackTrace != null) {
          debugPrint('📚 Stack: $stackTrace');
        }
        debugPrint('─' * 50);
      }

      // تسجيل مخصص للأخطاء الحرجة
      if (severity == ErrorSeverity.critical) {
        await _handleCriticalError(error, location, additionalData);
      }
    } catch (e) {
      debugPrint('Failed to log error: $e');
    }
  }

  /// تسجيل حدث مخصص
  static void logEvent({
    required String event,
    required String location,
    Map<String, dynamic>? data,
  }) {
    if (kDebugMode) {
      debugPrint('📝 EVENT: $event in $location');
      if (data != null) {
        debugPrint('📊 Data: $data');
      }
    }
  }

  /// تسجيل نجاح العملية
  static void logSuccess({
    required String operation,
    required String location,
    Map<String, dynamic>? data,
  }) {
    if (kDebugMode) {
      debugPrint('✅ SUCCESS: $operation in $location');
      if (data != null) {
        debugPrint('📊 Data: $data');
      }
    }
  }

  /// معالجة الأخطاء الحرجة
  static Future<void> _handleCriticalError(
    String error,
    String location,
    Map<String, dynamic>? data,
  ) async {
    // يمكن إضافة إشعارات للمطورين هنا
    debugPrint('🚨 CRITICAL ERROR: $error in $location');
  }

  /// تسجيل معلومات المستخدم للتتبع
  static void setUserInfo({
    required String userId,
    String? phoneNumber,
    String? email,
  }) {
    if (kDebugMode) {
      debugPrint('👤 User Info Set:');
      debugPrint('🆔 ID: $userId');
      if (phoneNumber != null) debugPrint('📱 Phone: $phoneNumber');
      if (email != null) debugPrint('📧 Email: $email');
    }
  }
}

/// مستويات خطورة الأخطاء
enum ErrorSeverity {
  low('LOW'),
  medium('MEDIUM'),
  high('HIGH'),
  critical('CRITICAL');

  const ErrorSeverity(this.name);
  final String name;
}

/// معلومات النظام للتتبع
class SystemInfo {
  static Map<String, dynamic> get deviceInfo => {
    'platform': Platform.operatingSystem,
    'platformVersion': Platform.operatingSystemVersion,
    'isPhysicalDevice': !kDebugMode,
    'timestamp': DateTime.now().toIso8601String(),
  };
}
