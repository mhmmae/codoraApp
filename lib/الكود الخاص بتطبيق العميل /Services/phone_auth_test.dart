import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'phone_auth_service.dart';

/// صفحة اختبار PhoneAuthService
class PhoneAuthTestPage extends StatelessWidget {
  const PhoneAuthTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PhoneAuthTestController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('اختبار خدمة التحقق من الهاتف'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // عرض حالة الخدمة
            Obx(
              () => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'حالة الخدمة:',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('📊 الحالة: ${controller.serviceStatus.value}'),
                      Text('📱 الرقم الحالي: ${controller.currentPhone.value}'),
                      Text(
                        '🔑 معرف التحقق: ${controller.hasVerificationId.value ? "متوفر" : "غير متوفر"}',
                      ),
                      Text(
                        '⏱️ التحميل: ${controller.isLoading.value ? "نعم" : "لا"}',
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // حقل إدخال رقم الهاتف
            TextField(
              controller: controller.phoneController,
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف (مع رمز الدولة)',
                hintText: '+9647XXXXXXXX',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: 16),

            // أزرار الاختبار
            Obx(
              () => ElevatedButton(
                onPressed:
                    controller.isLoading.value ? null : controller.testSendCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child:
                    controller.isLoading.value
                        ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('جاري الإرسال...'),
                          ],
                        )
                        : const Text('إرسال رمز التحقق'),
              ),
            ),

            const SizedBox(height: 8),

            ElevatedButton(
              onPressed: controller.testServiceDiagnosis,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('تشخيص الخدمة'),
            ),

            const SizedBox(height: 8),

            ElevatedButton(
              onPressed: controller.validatePhoneNumber,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('فحص صحة الرقم'),
            ),

            const SizedBox(height: 16),

            // عرض النتائج
            Expanded(
              child: Obx(
                () => Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      controller.results.value,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// متحكم اختبار PhoneAuthService
class PhoneAuthTestController extends GetxController {
  late PhoneAuthService phoneAuthService;

  final phoneController = TextEditingController();
  final RxString results = ''.obs;
  final RxString serviceStatus = 'غير معروف'.obs;
  final RxString currentPhone = ''.obs;
  final RxBool hasVerificationId = false.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeService();
  }

  /// تهيئة الخدمة
  void _initializeService() {
    try {
      phoneAuthService = Get.find<PhoneAuthService>();
      _addResult('✅ تم العثور على PhoneAuthService');
      _updateServiceStatus();
    } catch (e) {
      _addResult('❌ فشل في العثور على PhoneAuthService: $e');
      try {
        Get.put(PhoneAuthService(), permanent: true);
        phoneAuthService = Get.find<PhoneAuthService>();
        _addResult('✅ تم إنشاء PhoneAuthService جديد');
        _updateServiceStatus();
      } catch (e2) {
        _addResult('❌ فشل في إنشاء PhoneAuthService: $e2');
      }
    }
  }

  /// تحديث حالة الخدمة
  void _updateServiceStatus() {
    try {
      serviceStatus.value = phoneAuthService.isLoading ? 'مشغول' : 'جاهز';
      currentPhone.value =
          phoneAuthService.phoneNumber.isEmpty
              ? 'غير محدد'
              : phoneAuthService.phoneNumber;
      hasVerificationId.value = phoneAuthService.verificationId.isNotEmpty;
      isLoading.value = phoneAuthService.isLoading;
    } catch (e) {
      _addResult('❌ خطأ في تحديث حالة الخدمة: $e');
    }
  }

  /// اختبار إرسال رمز التحقق
  Future<void> testSendCode() async {
    final phone = phoneController.text.trim();

    if (phone.isEmpty) {
      _addResult('⚠️ يرجى إدخال رقم الهاتف');
      return;
    }

    _addResult('\n🚀 بدء اختبار إرسال رمز التحقق...');
    _addResult('📱 الرقم: $phone');

    try {
      isLoading.value = true;

      // التحقق من صحة الرقم أولاً
      final validation = phoneAuthService.validatePhoneNumber(phone);
      _addResult('📞 نتيجة فحص الرقم: ${validation.toString()}');

      if (validation['is_valid_format'] != true) {
        _addResult('❌ تنسيق الرقم غير صحيح');
        if (validation['suggestions'] != null) {
          _addResult('💡 اقتراحات: ${validation['suggestions']}');
        }
        return;
      }

      // إرسال رمز التحقق
      _addResult('📤 إرسال رمز التحقق...');
      final result = await phoneAuthService.sendVerificationCode(phone);

      if (result.isSuccess) {
        _addResult('✅ نجح إرسال رمز التحقق!');
        _addResult('📩 نوع النتيجة: ${result.type}');
        if (result.verificationId != null) {
          _addResult('🔑 معرف التحقق: ${result.verificationId}');
        }
      } else {
        _addResult('❌ فشل إرسال رمز التحقق: ${result.error}');
      }
    } catch (e) {
      _addResult('🚨 خطأ غير متوقع: $e');
    } finally {
      isLoading.value = false;
      _updateServiceStatus();
    }
  }

  /// تشخيص الخدمة
  Future<void> testServiceDiagnosis() async {
    _addResult('\n🔍 بدء تشخيص الخدمة...');

    try {
      // اختبار الخدمة
      phoneAuthService.testService();
      _addResult('✅ اختبار الخدمة مكتمل');

      // تشخيص Firebase
      final diagnosis = await phoneAuthService.diagnoseFirebaseSetup();
      _addResult('📊 تشخيص Firebase:');
      diagnosis.forEach((key, value) {
        _addResult('   $key: $value');
      });

      // تقرير الخدمة
      final report = phoneAuthService.getServiceReport();
      _addResult('\n📋 تقرير الخدمة:');
      report.forEach((key, value) {
        _addResult('   $key: $value');
      });
    } catch (e) {
      _addResult('❌ خطأ في التشخيص: $e');
    }

    _updateServiceStatus();
  }

  /// فحص صحة رقم الهاتف
  void validatePhoneNumber() {
    final phone = phoneController.text.trim();

    if (phone.isEmpty) {
      _addResult('⚠️ يرجى إدخال رقم الهاتف أولاً');
      return;
    }

    _addResult('\n📞 فحص صحة رقم الهاتف: $phone');

    try {
      final validation = phoneAuthService.validatePhoneNumber(phone);
      _addResult('📊 نتائج الفحص:');
      validation.forEach((key, value) {
        _addResult('   $key: $value');
      });
    } catch (e) {
      _addResult('❌ خطأ في فحص الرقم: $e');
    }
  }

  /// إضافة نتيجة للسجل
  void _addResult(String result) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    results.value += '[$timestamp] $result\n';
  }

  /// تنظيف السجل
  void clearResults() {
    results.value = '';
  }

  @override
  void onClose() {
    phoneController.dispose();
    super.onClose();
  }
}
