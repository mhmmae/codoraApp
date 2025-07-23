import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:codora/الكود الخاص بتطبيق العميل /Services/phone_auth_service.dart';

class TestPhoneAuthPage extends StatefulWidget {
  const TestPhoneAuthPage({super.key});

  @override
  _TestPhoneAuthPageState createState() => _TestPhoneAuthPageState();
}

class _TestPhoneAuthPageState extends State<TestPhoneAuthPage> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final PhoneAuthService phoneAuthService = Get.find<PhoneAuthService>();

  String statusMessage = 'جاهز للاختبار';
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🧪 اختبار مصادقة الهاتف'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // معلومات النظام
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📊 معلومات النظام',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('🏗️ Project ID: codora-app1'),
                    Text('📱 Package: com.homy.codora'),
                    Text(
                      '🔑 SHA-1: 68:AE:1B:D8:91:FA:07:3B:73:AE:E3:A7:6C:24:BF:68:EC:0E:36:36',
                    ),
                    SizedBox(height: 8),
                    Obx(
                      () => Text(
                        '📊 حالة الخدمة: ${phoneAuthService.isLoading ? "قيد المعالجة" : "جاهز"}',
                      ),
                    ),
                    Obx(
                      () => Text(
                        '📱 رقم الهاتف: ${phoneAuthService.phoneNumber}',
                      ),
                    ),
                    Obx(
                      () => Text(
                        '🔑 معرف التحقق: ${phoneAuthService.verificationId}',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // إدخال رقم الهاتف
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      '📱 إرسال رمز التحقق',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'رقم الهاتف (مع رمز الدولة)',
                        hintText: '+966512345678',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            isLoading ? null : () => sendVerificationCode(),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        child:
                            isLoading
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text('إرسال رمز التحقق'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // التحقق من الرمز
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      '🔑 التحقق من الرمز',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: codeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: InputDecoration(
                        labelText: 'رمز التحقق',
                        hintText: '123456',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : () => verifyCode(),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.green,
                        ),
                        child: Text('تحقق من الرمز'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // حالة الرسائل
            Expanded(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📋 سجل الحالة',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              statusMessage,
                              style: TextStyle(fontFamily: 'monospace'),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void sendVerificationCode() async {
    if (phoneController.text.trim().isEmpty) {
      updateStatus('❌ خطأ: يرجى إدخال رقم الهاتف');
      return;
    }

    setState(() {
      isLoading = true;
    });

    updateStatus(
      '🚀 بدء إرسال رمز التحقق...\n📱 الرقم: ${phoneController.text}',
    );

    try {
      final result = await phoneAuthService.sendVerificationCode(
        phoneController.text.trim(),
      );

      if (result.isSuccess) {
        updateStatus(
          '✅ تم إرسال الرمز بنجاح!\n🔑 معرف التحقق: ${result.verificationId}',
        );
      } else {
        updateStatus('❌ فشل الإرسال: ${result.error}');
      }
    } catch (error) {
      updateStatus('💥 خطأ غير متوقع: ${error.toString()}');
      print('💥 خطأ في sendVerificationCode: $error');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void verifyCode() async {
    if (codeController.text.trim().isEmpty) {
      updateStatus('❌ خطأ: يرجى إدخال رمز التحقق');
      return;
    }

    if (phoneAuthService.verificationId.isEmpty) {
      updateStatus('❌ خطأ: لا يوجد معرف تحقق. يرجى إرسال رمز التحقق أولاً');
      return;
    }

    setState(() {
      isLoading = true;
    });

    updateStatus('🔍 التحقق من الرمز...\n🔑 الرمز: ${codeController.text}');

    try {
      final result = await phoneAuthService.verifyCode(
        codeController.text.trim(),
      );

      if (result.isSuccess) {
        updateStatus(
          '🎉 تم التحقق بنجاح!\n👤 المستخدم: ${result.user?.uid ?? "غير معروف"}',
        );
      } else {
        updateStatus('❌ فشل التحقق: ${result.error}');
      }
    } catch (error) {
      updateStatus('💥 خطأ غير متوقع في التحقق: ${error.toString()}');
      print('💥 خطأ في verifyCode: $error');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void updateStatus(String message) {
    setState(() {
      final timestamp = DateTime.now().toString().substring(11, 19);
      statusMessage = '[$timestamp] $message\n\n$statusMessage';
    });
  }

  @override
  void dispose() {
    phoneController.dispose();
    codeController.dispose();
    super.dispose();
  }
}
