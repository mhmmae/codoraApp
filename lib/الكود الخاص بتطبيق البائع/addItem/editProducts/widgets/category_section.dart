import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/edit_product_controller.dart';

class CategorySection extends StatelessWidget {
  const CategorySection({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      final controller = Get.find<EditProductController>();
      
      if (!controller.isProductLoaded.value) {
        return const Center(child: CircularProgressIndicator());
      }
      
      return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الأقسام والفئات',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        Obx(() {
          final hasCategory = controller.mainCategoryNameAr.value.isNotEmpty ||
                            controller.subCategoryNameAr.value.isNotEmpty;
          
          if (!hasCategory) {
            return Card(
              color: Colors.grey[100],
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'لم يتم تحديد فئة لهذا المنتج',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            );
          }
          
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (controller.mainCategoryNameAr.value.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.folder, color: Colors.amber),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'القسم الرئيسي',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                controller.mainCategoryNameAr.value,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  if (controller.subCategoryNameAr.value.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.subdirectory_arrow_right, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'القسم الفرعي',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                controller.subCategoryNameAr.value,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        }        ),
      ],
    );
    } catch (e) {
      return const Center(child: Text('خطأ في تحميل البيانات'));
    }
  }
} 