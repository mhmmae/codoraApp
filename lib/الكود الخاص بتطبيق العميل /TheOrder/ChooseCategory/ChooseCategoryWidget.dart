// widgets/choose_category_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../Model/category_model.dart';
import 'CategoryController.dart'; // لعرض الصور

class ChooseCategoryWidget extends StatelessWidget {
  const ChooseCategoryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // الحصول على المتحكم (يفترض أنه محقون مسبقًا في مكان أعلى مثل HomeScreen أو Binding)
    final CategoryController controller = Get.find<CategoryController>();
    final theme = Theme.of(context);

    final double cardWidth = MediaQuery.of(context).size.width / 3.1; // <-- قسمة على عدد أقل لزيادة العرض
    final double cardHeight = 75.0; // <-- زيادة الارتفاع

    return Obx(() { // مراقبة isLoading و categories
      // --- عرض شريط التحميل ---
      if (controller.isLoading.value) {
        return SizedBox(height: cardHeight + 16,
            child: const Center(child: LinearProgressIndicator()));
      }
      // --- عرض رسالة الخطأ ---
      if (controller.error.value.isNotEmpty) {
        return Padding(padding: const EdgeInsets.all(16.0),
            child: Text(controller.error.value,
                style: TextStyle(color: Colors.red[700])));
      }
      // --- عرض رسالة إذا لم تكن هناك أقسام ---
      if (controller.categories.isEmpty) {
        return SizedBox(height: cardHeight + 16,
            child: Center(child: Text("لا توجد أقسام متاحة")));
      }

      // --- بناء قائمة الأقسام ---
      return SizedBox(
        height: cardHeight + 16,
        child: ListView.builder(
          itemCount: controller.categories.length + 1,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          itemBuilder: (context, index) {
            // --- حالة زر "الكل" ---
            if (index == 0) {
              final String key = CategoryController.allFilterKey;
              // لم نعد بحاجة لحساب isSelected هنا
              return _buildCategoryChip(
                context: context,
                label: "الكل",
                iconData: Icons.apps,
                // ---!!! تمرير controller والمفتاح بدلاً من isSelected !!!---
                controller: controller,
                itemKey: key,
                // -------------------------------------------------------
                onTap: () => controller.selectCategory(key),
                cardWidth: cardWidth * 0.8,
                cardHeight: cardHeight,
              );
            }

            // --- بناء بطاقة القسم الفعلي ---
            final categoryIndex = index - 1;
            final CategoryModel category = controller.categories[categoryIndex];
            // لم نعد بحاجة لحساب isSelected هنا
            return _buildCategoryChip(
              context: context,
              label: category.nameAr,
              imageUrl: category.imageUrl,
              // ---!!! تمرير controller والمفتاح بدلاً من isSelected !!!---
              controller: controller,
              itemKey: category.nameEn,
              // مرر المفتاح (nameEn)
              // -------------------------------------------------------
              onTap: () => controller.selectCategory(category.nameEn),
              cardWidth: cardWidth,
              cardHeight: cardHeight,
            );
          },
        ),
      );
    });
  }


  // بناء بطاقة/Chip للقسم بتصميم جديد
  Widget _buildCategoryChip({
    required BuildContext context,
    required String label,
    IconData? iconData,
    String? imageUrl,
    required CategoryController controller,
    required String itemKey,
    required VoidCallback onTap,
    // ---!!! زيادة الأحجام الافتراضية المقترحة !!!---
    required double cardWidth,  // سيتم زيادته في build
    required double cardHeight, // سيتم زيادته في build
    // ---------------------------------------------
  }) {
    final theme = Theme.of(context);
    // نسبة تكبير طفيفة للـ Chip المختار (اختياري)
    final double scaleFactor = 1.0; // أو 1.05 للزيادة عند الاختيار

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6), // زيادة التباعد قليلاً
      child: Obx(() {
        final bool isSelected = controller.selectedCategoryKey.value == itemKey;
        // --- استخدام Transform.scale لإضافة تأثير تكبير طفيف عند الاختيار ---
        return AnimatedScale(
          scale: isSelected ? scaleFactor : 1.0, // تكبير طفيف
          duration: const Duration(milliseconds: 150),
          child: GestureDetector(
            onTap: onTap,
            child: SizedBox( // استخدام SizedBox لتحديد الحجم الكلي
              width: cardWidth,
              height: cardHeight,
              child: ClipRRect( // --- ClipRRect لحواف دائرية ولصق المحتوى ---
                borderRadius: BorderRadius.circular(12.0), // زيادة دائرية الحواف
                child: Stack( // --- استخدام Stack لوضع النص فوق الصورة ---
                  fit: StackFit.expand, // لجعل العناصر تملأ المساحة
                  children: [
                    // --- 1. الخلفية: الصورة أو الأيقونة بلون ---
                    Container(
                      decoration: BoxDecoration(
                          color: isSelected ? theme.primaryColor.withOpacity(0.1) : Colors.grey.shade200, // لون خلفية بديل
                          border: Border.all( // إطار خفيف للتمييز
                            color: isSelected ? theme.primaryColor : Colors.grey.shade300,
                            width: isSelected ? 2.0 : 1.0,
                          ),
                          borderRadius: BorderRadius.circular(12.0) // يجب أن يطابق ClipRRect
                      ),
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        placeholder: (c, u) => Center(child: Icon(Icons.category, size: cardHeight * 0.4, color: Colors.grey[400])), // أيقونة Placeholder أكبر
                        errorWidget: (c, u, e) => Center(child: Icon(Icons.error_outline, size: cardHeight * 0.4, color: Colors.red[300])),
                        fit: BoxFit.cover, // <-- جعل الصورة تملأ الخلفية
                      )
                      // عرض أيقونة أكبر في المنتصف إذا لم تكن هناك صورة
                          : Center(child: Icon( iconData ?? Icons.category, size: cardHeight * 0.5, color: isSelected ? theme.primaryColor : Colors.grey[600] )),
                    ),

                    // --- 2. طبقة تعتيم فوق الصورة (لجعل النص أوضح) ---
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0), // نفس الحواف
                        // تدرج لوني من شفاف في الأعلى إلى داكن قليلاً في الأسفل
                        gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.05), // شفافية قليلة جدًا في الأعلى
                              Colors.black.withOpacity(0.50), // أكثر قتامة في الأسفل
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [0.4, 1.0] // التحكم في مكان بدء وانتهاء التدرج
                        ),
                        // أو استخدم لونًا ثابتًا شبه شفاف:
                        // color: Colors.black.withOpacity(0.35),
                      ),
                    ),

                    // --- 3. النص (اسم القسم) فوق الصورة/التعتيم ---
                    Positioned(
                      bottom: 6, // المسافة من الأسفل
                      left: 6,   // المسافة من اليسار
                      right: 6,  // المسافة من اليمين
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white, // <-- لون أبيض للنص
                          fontSize: cardWidth * 0.12, // حجم أكبر قليلاً
                          fontWeight: FontWeight.bold, // خط عريض دائمًا
                          height: 1.1,
                          // إضافة ظل للنص لتحسين الوضوح فوق أي خلفية
                          shadows: [
                            Shadow( blurRadius: 3.0, color: Colors.black.withOpacity(0.6), offset: Offset(0, 1),),
                            Shadow( blurRadius: 1.0, color: Colors.black.withOpacity(0.7),), // ظل إضافي خفيف
                          ],
                        ),
                        maxLines: 2, // السماح بسطرين إذا كان الاسم طويلاً جداً
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // --- (اختياري) إضافة مؤشر اختيار في زاوية ما ---
                    if (isSelected)
                      Positioned(
                        top: 5,
                        left: 5,
                        child: Container(
                          padding: EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: theme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.check, size: cardWidth * 0.12, color: Colors.white),
                        ),
                      ),

                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}