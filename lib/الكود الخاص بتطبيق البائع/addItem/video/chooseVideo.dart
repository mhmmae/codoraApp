
import 'package:flutter/material.dart';
import 'package:get/get.dart';
// --- استيراد المتحكم الصحيح ---
import 'Getx/GetChooseVideo.dart'; // <--- تأكد من المسار

class ChooseVideo extends StatelessWidget {
  const ChooseVideo({super.key});

  @override
  Widget build(BuildContext context) {
    double hi = MediaQuery.of(context).size.height;
    double wi = MediaQuery.of(context).size.width;
    // --- حقن أو إيجاد المتحكم ---
    // استخدام lazyPut أفضل هنا
    final GetChooseVideo controller = Get.put(GetChooseVideo());
    final theme = Theme.of(context); // للحصول على ألوان الثيم

    // --- استخدام Obx لمراقبة الحالة ---
    return Obx(() {
      // --- حالة التحميل (أثناء اختيار الفيديو أو توليد الصورة المصغرة) ---
      if (controller.isVideoLoading.value) {
        return Container(
          height: hi / 7, // ارتفاع تقديري
          width: double.infinity, // يأخذ عرض الأب
          padding: const EdgeInsets.all(10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Column( // لإضافة نص تحت المؤشر
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(strokeWidth: 3),
              SizedBox(height: 8),
              Text("جاري التحضير...", style: TextStyle(color: Colors.grey)),
            ],
          ),
        );
      }
      // --- حالة عدم وجود فيديو مختار (file و uint8list هما null) ---
      else if (controller.file == null || controller.uint8list == null) {
        return InkWell( // <--- استخدام InkWell لتأثير النقر
          onTap: () async {
            // استدعاء دالة اختيار الفيديو (لا تحتاج لمعالجة أخطاء هنا)
            await controller.getVideo(context);
          },
          borderRadius: BorderRadius.circular(15), // لمنطقة نقر متناسقة
          child: Container(
            height: hi / 8, // ارتفاع معقول
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade50,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: theme.primaryColor.withOpacity(0.6), width: 1.5, style: BorderStyle.solid), // استخدام إطار متقطع أنيق
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.video_call_outlined, size: wi * 0.12, color: theme.primaryColor.withOpacity(0.8)),
                const SizedBox(height: 8),
                Text(
                  "اختر فيديو المنتج (اختياري)",
                  style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.w500),
                )
              ],
            ),
          ),
        );
      }
      // --- حالة وجود فيديو مختار (عرض الصورة المصغرة وزر الحذف) ---
      else {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column( // عمود لعرض الصورة والزرار
            children: [
              Text("الفيديو المختار:", style: theme.textTheme.bodyMedium), // عنوان
              const SizedBox(height: 8),
              Row( // صف لعرض الصورة المصغرة وأزرار التحكم
                crossAxisAlignment: CrossAxisAlignment.start, // محاذاة للأعلى
                children: [
                  // --- عرض الصورة المصغرة ---
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: wi / 3.5, // حجم مناسب للصورة المصغرة
                      height: hi / 9,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.black, // خلفية سوداء إذا فشلت الصورة
                      ),
                      child: controller.uint8list != null
                          ? Image.memory( controller.uint8list!, fit: BoxFit.cover,)
                          : const Icon(Icons.videocam_off_outlined, color: Colors.white54), // أيقونة خطأ
                    ),
                  ),
                  const SizedBox(width: 15),
                  // --- زر لتغيير الفيديو ---
                  Expanded( // ليأخذ المساحة المتبقية
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ElevatedButton.icon(
                          icon: Icon(Icons.edit_outlined, size: 18),
                          label: Text("تغيير الفيديو"),
                          onPressed: () async {
                            await controller.getVideo(context); // اختر فيديو جديد
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey.shade600,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              textStyle: TextStyle(fontSize: 13)
                          ),
                        ),
                        const SizedBox(height: 5),
                        // --- زر حذف الفيديو ---
                        TextButton.icon(
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                          label: const Text("إزالة الفيديو", style: TextStyle(color: Colors.red)),
                          onPressed: () {
                            controller.deleteVideo(); // <--- استدعاء دالة الحذف
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }
    }); // نهاية Obx
  } // نهاية build
} // نهاية ChooseVideo
