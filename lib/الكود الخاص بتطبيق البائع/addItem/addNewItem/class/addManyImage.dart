import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:typed_data'; // <--- تأكد من وجود هذا

// --- استيراد المتحكم والـ Widget الأخرى ---
import 'getAddManyImage.dart';    // <-- استيراد المتحكم المعدل

class AddManyImage extends StatelessWidget {
  const AddManyImage({super.key});

  @override
  Widget build(BuildContext context) {
    double hi = MediaQuery.of(context).size.height; // ارتفاع الشاشة
    double wi = MediaQuery.of(context).size.width; // عرض الشاشة
    // --- الحصول على أو حقن المتحكم ---
    // lazyPut هنا جيد لأنه يستخدم فقط عند بناء هذه الويدجت
    final GetAddManyImage controller = Get.put(GetAddManyImage());

    // --- استخدام Obx لمراقبة الحالات المتغيرة ---
    return Obx(() {
      // --- حالة معالجة الصور (اختيار/ضغط) ---
      if (controller.isProcessing.value) { // <--- .value هنا لأن isProcessing هي RxBool
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0), // بعض التباعد
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text("جارٍ معالجة الصور..."),
            ],
          ),
        );
      }

      // --- حالة عدم اختيار أي صور ---
      if (controller.selectedImageBytes.isEmpty) {
        return Center( // <--- وضع الزر في المنتصف غالباً أفضل
          child: GestureDetector(
            onTap: () async {
              // --- لا تحتاج start/stop Processing هنا ---
              // لأنها تدار داخل processAndSelectImages
              // استدعاء عملية الاختيار والمعالجة
              await controller.processAndSelectImages();
              // لا تحتاج try/catch هنا لأن الدالة نفسها يجب أن تعالج الأخطاء
            },
            child: Container(
              height: hi / 9, // <-- زيادة الارتفاع قليلاً
              width: wi / 3, // <-- زيادة العرض قليلاً
              decoration: BoxDecoration(
                color: Colors.grey[200], // لون خلفية بديل
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: Column( // أيقونة ونص لتوضيح الزر
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, size: wi * 0.1, color: Colors.grey[600]),
                  const SizedBox(height: 5),
                  Text("إضافة صور", style: TextStyle(color: Colors.grey[700]))
                ],
              ),
            ),
          ),
        );
      }

      // --- حالة وجود صور مختارة ---
      return Column(
        children: [
          // --- زر لحذف كل الصور المختارة وإعادة الاختيار ---
          Align(
            alignment: AlignmentDirectional.centerStart, // <--- تغيير للمحاذاة
            child: TextButton.icon(
              icon: const Icon(Icons.close, color: Colors.red, size: 20),
              label: const Text("مسح الكل", style: TextStyle(color: Colors.red)), // <--- تغيير الزر
              onPressed: () {
                controller.reset(); // <-- استدعاء دالة إعادة التعيين
              },
            ),
          ),
          const SizedBox(height: 5),

          // --- عرض الصور المختارة في قائمة أفقية ---
          SizedBox(
            // تعديل الارتفاع ليناسب الحجم الجديد للعناصر
              height: (hi / 8) + 16, // <-- ارتفاع الصورة + padding العمودي
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: controller.selectedImageBytes.length,
                itemBuilder: (context, index) {
                  final Uint8List imageBytes = controller.selectedImageBytes[index]; // الوصول للقائمة التفاعلية
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                    child: Stack(
                      // السماح للزر بالظهور فوق الصورة قليلاً
                      clipBehavior: Clip.none, // <-- مهم للسماح للزر بالخروج
                      children: [
                        // حاوية الصورة
                        ClipRRect( // <-- استخدام ClipRRect للحواف الدائرية
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: wi / 3.5, // <-- حجم البطاقة
                            height: hi / 8,   // <-- حجم البطاقة
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(10), // نفس الحواف
                            ),
                            child: Image.memory(
                              imageBytes,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        // زر حذف الصورة الفردية
                        Positioned(
                          top: -8,  // <-- تعديل الموضع ليظهر فوق قليلاً
                          right: -8, // <-- تعديل الموضع ليظهر فوق قليلاً
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.85),
                              shape: BoxShape.circle,
                            ),
                            // استخدام Material لجعل IconButton دائريًا ويتفاعل
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20), // شكل منطقة النقر
                                onTap: () {
                                  controller.removeImageAt(index); // <-- استدعاء دالة الحذف الجديدة
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(4.0), // زيادة المساحة القابلة للنقر
                                  child: Icon( Icons.close_rounded, color: Colors.white, size: 16,),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              )
          ),
        ],
      );
    }); // نهاية Obx الرئيسي
  }
}