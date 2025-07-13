import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/edit_product_controller.dart';

class BasicInfoSection extends StatelessWidget {
  const BasicInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      final controller = Get.find<EditProductController>();
      
      // التأكد من أن الكونترولر جاهز
      if (!controller.isProductLoaded.value) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }
      
      return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'المعلومات الأساسية',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // اسم المنتج
        TextFormField(
          controller: controller.nameController,
          decoration: InputDecoration(
            labelText: 'اسم المنتج *',
            hintText: 'أدخل اسم المنتج',
            prefixIcon: const Icon(Icons.inventory_2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          maxLines: 1,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        
        // وصف المنتج
        TextFormField(
          controller: controller.descriptionController,
          decoration: InputDecoration(
            labelText: 'وصف المنتج',
            hintText: 'أدخل وصف تفصيلي للمنتج',
            prefixIcon: const Icon(Icons.description),
            alignLabelWithHint: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          maxLines: 4,
          textInputAction: TextInputAction.newline,
        ),
        const SizedBox(height: 16),
        
        // نوع المنتج
        Obx(() {
          final productTypes = _getProductTypes();
          final currentValue = controller.selectedTypeItem.value;
          
          // تحويل الأسماء الإنجليزية القديمة إلى عربية
          final displayValue = _convertOldEnglishToArabic(currentValue);
          
          // إضافة القيمة الحالية إلى القائمة إذا لم تكن موجودة
          if (displayValue.isNotEmpty && !productTypes.contains(displayValue)) {
            productTypes.insert(0, displayValue); // إضافة في البداية
          }
          
          return DropdownButtonFormField<String>(
            value: displayValue.isEmpty ? null : displayValue,
            decoration: InputDecoration(
              labelText: 'نوع المنتج',
              prefixIcon: const Icon(Icons.category),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            hint: const Text('اختر نوع المنتج'),
            items: productTypes.toSet().map((type) { // استخدام toSet() لإزالة التكرار
              return DropdownMenuItem(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                controller.selectedTypeItem.value = value;
              }
            },
          );
        }),
        const SizedBox(height: 16),
        
        // حالة المنتج
        Obx(() => DropdownButtonFormField<String>(
          value: controller.selectedItemCondition.value.isEmpty 
              ? null 
              : controller.selectedItemCondition.value,
          decoration: InputDecoration(
            labelText: 'حالة المنتج',
            prefixIcon: const Icon(Icons.new_releases),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          hint: const Text('اختر حالة المنتج'),
          items: const [
            DropdownMenuItem(value: 'original', child: Text('أصلي')),
            DropdownMenuItem(value: 'commercial', child: Text('تجاري')),
            DropdownMenuItem(value: 'used', child: Text('مستعمل')),
            DropdownMenuItem(value: 'refurbished', child: Text('مجدد')),
          ],
          onChanged: (value) {
            controller.selectedItemCondition.value = value ?? '';
          },
        )),
      ],
    );
    } catch (e) {
      return const Center(
        child: Text('خطأ في تحميل البيانات'),
      );
    }
  }
  
  /// تحويل القيم الإنجليزية القديمة إلى عربية
  String _convertOldEnglishToArabic(String value) {
    // خريطة للقيم القديمة المحتملة
    final Map<String, String> oldToNewMapping = {
      'alictonic': 'إلكترونيات',
      'alictonic_phone': 'هواتف وأجهزة لوحية',
      'alictonic_computer': 'كمبيوتر ولابتوب',
      'alictonic_accessories': 'ملحقات إلكترونية',
      'electronics': 'إلكترونيات',
      'phone': 'هواتف وأجهزة لوحية',
      'phones': 'هواتف وأجهزة لوحية',
      'mobile': 'هواتف وأجهزة لوحية',
      'computer': 'كمبيوتر ولابتوب',
      'laptop': 'كمبيوتر ولابتوب',
      'clothes_men': 'ملابس رجالية',
      'clothes_women': 'ملابس نسائية',
      'clothes_kids': 'ملابس أطفال',
      'shoes': 'أحذية',
      'accessories': 'حقائب وإكسسوارات',
      'jewelry': 'مجوهرات وساعات',
      'cosmetics': 'مستحضرات تجميل',
      'perfume': 'عطور',
      'home_tools': 'أدوات منزلية',
      'furniture': 'أثاث',
      'books': 'كتب ومجلات',
      'toys': 'ألعاب',
      'games': 'ألعاب إلكترونية',
      'sports': 'رياضة ولياقة',
      'cars': 'سيارات وقطع غيار',
      'real_estate': 'عقارات',
      'services': 'خدمات',
      'food': 'أطعمة ومشروبات',
      'health': 'صحة وجمال',
      'baby': 'أطفال ورضع',
      'pets': 'حيوانات أليفة',
      'garden': 'حدائق ونباتات',
      'other': 'أخرى',
    };
    
    // إذا كانت القيمة موجودة في الخريطة، استخدم النسخة العربية
    if (oldToNewMapping.containsKey(value.toLowerCase())) {
      return oldToNewMapping[value.toLowerCase()]!;
    }
    
    // إذا كانت القيمة فارغة أو null
    if (value.isEmpty) {
      return '';
    }
    
    // إذا كانت القيمة عربية بالفعل أو غير موجودة في الخريطة، أعدها كما هي
    return value;
  }

  List<String> _getProductTypes() {
    return <String>[
      'إلكترونيات',
      'هواتف وأجهزة لوحية',
      'كمبيوتر ولابتوب',
      'ملحقات إلكترونية',
      'أجهزة منزلية',
      'ملابس رجالية',
      'ملابس نسائية',
      'ملابس أطفال',
      'أحذية',
      'حقائب وإكسسوارات',
      'مجوهرات وساعات',
      'مستحضرات تجميل',
      'عطور',
      'أدوات منزلية',
      'أثاث',
      'ديكور',
      'كتب ومجلات',
      'ألعاب',
      'ألعاب إلكترونية',
      'رياضة ولياقة',
      'سيارات وقطع غيار',
      'دراجات',
      'عقارات',
      'خدمات',
      'أطعمة ومشروبات',
      'صحة وجمال',
      'أدوية ومكملات',
      'أطفال ورضع',
      'حيوانات أليفة',
      'حدائق ونباتات',
      'قرطاسية ومكتبية',
      'أدوات وعدد',
      'مواد بناء',
      'أخرى',
    ];
  }
} 