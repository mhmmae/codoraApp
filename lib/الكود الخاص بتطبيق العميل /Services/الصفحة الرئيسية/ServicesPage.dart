import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../iptv/عرض كل انواع الكودات /CodeGroupsScreen.dart';
import '../تفعيل الرابعة/page1scanar.dart';

class Servicespage extends StatelessWidget {
  const Servicespage({super.key});

  @override
  Widget build(BuildContext context) {
    // استخدام MediaQuery للحصول على أبعاد الشاشة
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('خدمات',style: TextStyle(color: Colors.black54),),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // الحاوية الأولى: تأخذ الارتفاع ربع الشاشة
              // نستخدم ClipRRect لإضافة زوايا دائرية للحاوية بأكملها
              GestureDetector(
                onTap: (){
                  Get.to(BarcodeScannerPage());
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20), // زوايا دائرية بقيمة 20
                  child: Container(
                    width: screenWidth, // العرض الكامل
                    height: screenHeight * 0.3,// ربع ارتفاع الشاشة
                    color: Colors.black87,
                    child: Center(
                      child: Container(
                        width: screenWidth/2, // العرض الكامل
                        height: screenHeight * 0.25, // ربع ارتفاع الشاشة
                        decoration:  BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(

                              'https://firebasestorage.googleapis.com/v0/b/codora-app1.firebasestorage.app/o/codeGroups%2F767bc1b0-0fb3-11f0-b885-c3fae01248e9?alt=media&token=c5aa3fee-230e-49bf-b99d-706de6f4237f', // رابط الصورة

                            ),
                            fit: BoxFit.cover, // تغطية الحاوية بالصورة
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // الحاوية الثانية: تأخذ الارتفاع نصف الشاشة
              GestureDetector(
                onTap: (){
                  Get.to(() => CodeGroupsScreen());
                },
                child: Container(
                  width: screenWidth,

                  color: Colors.transparent,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // استخدام ClipRRect لتقريب زوايا الصورة داخل الحاوية
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          'https://firebasestorage.googleapis.com/v0/b/codora-app1.firebasestorage.app/o/codeGroups%2F4cb62cb0-0fb5-11f0-b885-c3fae01248e9?alt=media&token=d66e84d2-9206-4d1c-aa51-50e071d20602', // رابط الصورة
                          height: screenHeight * 0.3,
                          width: screenWidth ,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'خدمات البث الرقمي iptv',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: 0.5,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: screenWidth,
                color: Colors.transparent,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        'https://firebasestorage.googleapis.com/v0/b/codora-app1.firebasestorage.app/o/codeGroups%2F0e3defd0-0fb6-11f0-b885-c3fae01248e9?alt=media&token=f3cb6d74-8143-4899-ba34-c38d0d5c0efd', // رابط الصورة
                        width: screenWidth ,
                        height: screenHeight * 0.3,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'خدمات العاب الفيديو ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: 0.5,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // الحاوية الثالثة: تأخذ الارتفاع نصف الشاشة
          
            ],
          ),
        ),
      ),
    );
  }
}
