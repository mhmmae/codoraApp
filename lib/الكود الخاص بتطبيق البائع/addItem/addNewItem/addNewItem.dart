import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'InformationBinding.dart';
import 'informationOFItem.dart';

class ViewImage extends StatelessWidget {
  const ViewImage({
    super.key,
    required this.uint8list,
    required this.TypeItem,
  });

  final Uint8List uint8list; // جعل المتغير final
  final String TypeItem; // جعل المتغير final

  @override
  Widget build(BuildContext context) {
    double hi = MediaQuery.of(context).size.height;
    double wi = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          // خلفية الصورة المتناسقة
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.cover, // تنسيق الصورة بشكل احترافي
                  image: MemoryImage(uint8list),
                ),
              ),
            ),
          ),
          // زر إرسال
          // زر إرسال
          Positioned(
            bottom: hi / 12,
            right: wi / 12,
            child: GestureDetector(
              // ---!!! تعديل onTap لاستخدام Get.to مع Binding !!!---
              onTap: () {
                debugPrint("Navigating to InformationOfItem with Binding..."); // للتحقق
                Get.to(
                  // () => InformationOfItem( // يمكن إزالة تمرير البيانات هنا إذا كانت Binding توفرها بالكامل
                  //   uint8list: uint8list,
                  //   TypeItem: TypeItem,
                  // ),
                  // تعديل بسيط لجعل الكود أوضح
                      () => InformationOfItem(uint8list: uint8list, TypeItem: TypeItem), // << استمر في تمريرها لل Widget اذا احتاجت العرض المباشر

                  binding: InformationBinding( // <-- تفعيل وتمرير البيانات للـ Binding
                    imageBytes: uint8list,
                    itemType: TypeItem,
                  ),
                  // يمكنك إضافة تأثير انتقال
                  transition: Transition.rightToLeftWithFade,
                  preventDuplicates: true, // منع الفتح المتكرر
                );
              },
              // ---------------------------------------------------
              child:  Container(
                height: hi / 12,
                width: wi / 5,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blueAccent, width: 2),
                  color: Colors.white.withBlue(3),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.send,
                  size: 45,
                  color: Colors.blueAccent,
                ),
              ),
            ),
          ),













          // زر العودة
          Positioned(
            bottom: hi / 12,
            left: wi / 12,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                height: hi / 12,
                width: wi / 5,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red, width: 2),
                  color: Colors.white.withAlpha(6),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.shade50,
                      blurRadius: 8,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.keyboard_backspace_sharp,
                  size: 45,
                  color: Colors.red,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
