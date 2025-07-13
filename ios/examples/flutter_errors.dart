// ملف أمثلة لاختبار نظام تحليل أخطاء Flutter/Dart
// يحتوي على أخطاء متعمدة من أنواع مختلفة

import 'dart:async'; // إضافة لاستخدام StreamSubscription
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http; // إضافة لاستخدام http
// import 'non_existent_package.dart'; // خطأ استيراد متعمد (محذوف لتجنب خطأ الـ analyzer)

// خطأ 1: استخدام StatefulWidget غير ضروري
class UnnecessaryStatefulWidget extends StatefulWidget {
  const UnnecessaryStatefulWidget({super.key});

  // لا يستخدم setState أبداً
  @override
  _UnnecessaryStatefulWidgetState createState() => _UnnecessaryStatefulWidgetState();
}

class _UnnecessaryStatefulWidgetState extends State<UnnecessaryStatefulWidget> {
  String title = "مرحبا";
  
  @override
  Widget build(BuildContext context) {
    // لا يوجد استخدام لـ setState
    return Text(title);
  }
}

// خطأ 2: استخدام GetX بشكل خاطئ
class BadGetXUsage {
  var count = 0.obs; // استخدام .obs بدون Controller
  
  void increment() {
    count++; // لن يعمل التحديث
  }
}

// خطأ 3: rebuild غير ضروري
class InefficientWidget extends StatefulWidget {
  const InefficientWidget({super.key});

  @override
  _InefficientWidgetState createState() => _InefficientWidgetState();
}

class _InefficientWidgetState extends State<InefficientWidget> {
  void doNothing() {
    setState(() {}); // rebuild بدون تغيير أي شيء!
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // بناء widget ثقيل في كل rebuild
        for (int i = 0; i < 1000; i++)
          Container(
            child: Text('Item $i'),
          ),
      ],
    );
  }
}

// خطأ 4: عدم استخدام const
class NoConstWidget extends StatelessWidget {
  const NoConstWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container( // يجب أن يكون const Container
      child: Text('نص ثابت'), // يجب أن يكون const Text
    );
  }
}

// خطأ 5: استخدام BuildContext بشكل خاطئ
class WrongContextUsage extends StatelessWidget {
  const WrongContextUsage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.delayed(Duration(seconds: 1)),
      builder: (context, snapshot) {
        // استخدام context خاطئ بعد async
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => Container(),
        ));
        return Container();
      },
    );
  }
}

// خطأ 6: تسريب ذاكرة
class MemoryLeakWidget extends StatefulWidget {
  const MemoryLeakWidget({super.key});

  @override
  _MemoryLeakWidgetState createState() => _MemoryLeakWidgetState();
}

class _MemoryLeakWidgetState extends State<MemoryLeakWidget> {
  StreamSubscription? subscription;
  
  @override
  void initState() {
    super.initState();
    subscription = Stream.periodic(Duration(seconds: 1)).listen((event) {
      print(event);
    });
    // لم يتم إلغاء الاشتراك في dispose!
  }
  
  @override
  Widget build(BuildContext context) {
    return Container();
  }
  // نسيان dispose()!
}

// خطأ 7: استخدام خاطئ لـ async
Future<void> wrongAsync() async {  // إضافة async
  // نسيان await - خطأ متعمد
  Future.delayed(Duration(seconds: 1));
  print('سيطبع فوراً بدلاً من الانتظار');
}

// خطأ 8: عدم معالجة الأخطاء
Future<String> riskyOperation() async {
  // لا يوجد try-catch
  final response = await http.get(Uri.parse('https://api.example.com'));
  return response.body; // ماذا لو فشل الطلب؟
}

// خطأ 9: استخدام ! بشكل خطر
class UnsafeNullCheck {
  String? nullableString;
  
  void dangerousMethod() {
    print(nullableString!.length); // قد يسبب null error
  }
}

// خطأ 10: Widget كبير جداً
class HugeWidget extends StatelessWidget {
  const HugeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Widget يحتوي على أكثر من 200 سطر
    return Scaffold(
      appBar: AppBar(
        title: Text('عنوان'),
        actions: [
          IconButton(icon: Icon(Icons.search), onPressed: () {}),
          IconButton(icon: Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(child: Text('القائمة')),
            ListTile(title: Text('العنصر 1')),
            ListTile(title: Text('العنصر 2')),
            ListTile(title: Text('العنصر 3')),
            ListTile(title: Text('العنصر 4')),
            ListTile(title: Text('العنصر 5')),
          ],
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 200,
            child: ListView.builder(
              itemCount: 100,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text('$index')),
                    title: Text('العنصر $index'),
                    subtitle: Text('وصف العنصر $index'),
                    trailing: Icon(Icons.arrow_forward),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
              ),
              itemCount: 50,
              itemBuilder: (context, index) {
                return Card(
                  child: Center(child: Text('$index')),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'البحث'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'الملف'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: Icon(Icons.add),
      ),
    );
  }
} 