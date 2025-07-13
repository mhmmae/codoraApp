import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../Model/enhanced_category_model.dart';
import '../controllers/enhanced_category_controller.dart';

/// Widget محسن لاختيار الأقسام الرئيسية والفرعية
/// يدعم الفلترة حسب نوع المنتج (أصلي/تجاري) ويعرض الأقسام الفرعية بالعربي فقط
/// يدعم جميع أنواع المنتجات (أصلية وتجارية)
class EnhancedCategorySelector extends StatefulWidget {
  final String? productType; // 'original', 'commercial', أو null للكل
  final Function(String mainCategoryId, String subCategoryId, String mainCategoryNameEn, String subCategoryNameEn) onCategoriesSelected;
  final String? initialMainCategoryId;
  final String? initialSubCategoryId;
  final bool showOnlySubCategoryInArabic; // إظهار القسم الفرعي بالعربي فقط

  const EnhancedCategorySelector({
    super.key,
    this.productType,
    required this.onCategoriesSelected,
    this.initialMainCategoryId,
    this.initialSubCategoryId,
    this.showOnlySubCategoryInArabic = false,
  });

  @override
  _EnhancedCategorySelectorState createState() => _EnhancedCategorySelectorState();
}

class _EnhancedCategorySelectorState extends State<EnhancedCategorySelector> {
  final EnhancedCategoryController controller = Get.put(EnhancedCategoryController());
  
  EnhancedCategoryModel? selectedMainCategory;
  EnhancedCategoryModel? selectedSubCategory;
  
  @override
  void initState() {
    super.initState();
    _loadInitialSelections();
  }

  void _loadInitialSelections() {
    if (widget.initialMainCategoryId != null) {
      // تحميل الاختيارات الأولية إذا كانت موجودة
      controller.loadCategoryById(widget.initialMainCategoryId!).then((mainCat) {
        if (mainCat != null) {
          setState(() {
            selectedMainCategory = mainCat;
          });
          
          if (widget.initialSubCategoryId != null) {
            controller.loadCategoryById(widget.initialSubCategoryId!).then((subCat) {
              if (subCat != null) {
                setState(() {
                  selectedSubCategory = subCat;
                });
              }
            });
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'اختيار الأقسام',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          // اختيار القسم الرئيسي
          _buildMainCategorySelector(),
          
          const SizedBox(height: 16),
          
          // اختيار القسم الفرعي (يظهر فقط عند اختيار قسم رئيسي)
          if (selectedMainCategory != null) _buildSubCategorySelector(),
          
          const SizedBox(height: 16),
          
          // عرض الاختيار الحالي
          _buildCurrentSelection(),
        ],
      ),
    );
  }

  Widget _buildMainCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'القسم الرئيسي*',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredMainCategories = controller.mainCategories
              .where((category) => category.canBeUsedForProductType(widget.productType))
              .toList();

          if (filteredMainCategories.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: const Text(
                'لا توجد أقسام رئيسية متاحة',
                style: TextStyle(color: Colors.orange),
              ),
            );
          }

          return DropdownButtonFormField<EnhancedCategoryModel>(
            value: selectedMainCategory,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              hintText: 'اختر القسم الرئيسي',
            ),
            items: filteredMainCategories.map((category) {
              return DropdownMenuItem<EnhancedCategoryModel>(
                value: category,
                child: Row(
                  children: [
                    if (category.iconName != null) ...[
                      Icon(
                        _getIconFromName(category.iconName!),
                        size: 20,
                        color: _getColorFromString(category.color),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        category.nameAr,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (EnhancedCategoryModel? newValue) {
              setState(() {
                selectedMainCategory = newValue;
                selectedSubCategory = null; // إعادة تعيين القسم الفرعي
              });
              
              if (newValue != null) {
                controller.loadSubCategories(newValue.id);
                _notifySelection();
              }
            },
            validator: (value) {
              if (value == null) {
                return 'يرجى اختيار القسم الرئيسي';
              }
              return null;
            },
          );
        }),
      ],
    );
  }

  Widget _buildSubCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'القسم الفرعي*',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() {
          if (controller.isLoadingSubCategories.value) {
            return const Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }

          final subCategories = controller.subCategories
              .where((category) => category.canBeUsedForProductType(widget.productType))
              .toList();

          if (subCategories.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: const Text(
                'لا توجد أقسام فرعية لهذا القسم الرئيسي',
                style: TextStyle(color: Colors.blue),
              ),
            );
          }

          return DropdownButtonFormField<EnhancedCategoryModel>(
            value: selectedSubCategory,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              hintText: 'اختر القسم الفرعي',
            ),
            items: subCategories.map((category) {
              return DropdownMenuItem<EnhancedCategoryModel>(
                value: category,
                child: Row(
                  children: [
                    if (category.iconName != null) ...[
                      Icon(
                        _getIconFromName(category.iconName!),
                        size: 18,
                        color: _getColorFromString(category.color),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        // إذا كان showOnlySubCategoryInArabic مفعل، اعرض العربي فقط
                        widget.showOnlySubCategoryInArabic 
                            ? category.nameAr 
                            : '${category.nameAr} | ${category.nameEn}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (EnhancedCategoryModel? newValue) {
              setState(() {
                selectedSubCategory = newValue;
              });
              _notifySelection();
            },
            validator: (value) {
              if (value == null) {
                return 'يرجى اختيار القسم الفرعي';
              }
              return null;
            },
          );
        }),
      ],
    );
  }

  Widget _buildCurrentSelection() {
    if (selectedMainCategory == null && selectedSubCategory == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الاختيار الحالي:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 4),
          if (selectedMainCategory != null)
            Text(
              'القسم الرئيسي: ${selectedMainCategory!.nameAr}',
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          if (selectedSubCategory != null)
            Text(
              'القسم الفرعي: ${selectedSubCategory!.nameAr}',
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
        ],
      ),
    );
  }

  void _notifySelection() {
    if (selectedMainCategory != null && selectedSubCategory != null) {
      debugPrint('🏷️ إرسال معلومات الفئات من EnhancedCategorySelector:');
      debugPrint('  القسم الرئيسي: ID=${selectedMainCategory!.id}, AR="${selectedMainCategory!.nameAr}", EN="${selectedMainCategory!.nameEn}"');
      debugPrint('  القسم الفرعي: ID=${selectedSubCategory!.id}, AR="${selectedSubCategory!.nameAr}", EN="${selectedSubCategory!.nameEn}"');
      
      widget.onCategoriesSelected(
        selectedMainCategory!.id,
        selectedSubCategory!.id,
        selectedMainCategory!.nameEn,  // هنا نرسل الإنجليزي
        selectedSubCategory!.nameEn,   // هنا نرسل الإنجليزي
      );
    }
  }

  // دوال مساعدة للأيقونات والألوان
  IconData _getIconFromName(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'phone':
        return Icons.phone_android;
      case 'headphones':
        return Icons.headphones;
      case 'tablet':
        return Icons.tablet;
      case 'laptop':
        return Icons.laptop;
      case 'clothing':
        return Icons.checkroom;
      case 'food':
        return Icons.restaurant;
      case 'book':
        return Icons.book;
      case 'car':
        return Icons.directions_car;
      case 'home':
        return Icons.home;
      case 'sports':
        return Icons.sports_soccer;
      default:
        return Icons.category;
    }
  }

  Color _getColorFromString(String? colorString) {
    if (colorString == null) return Colors.grey;
    
    switch (colorString.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'teal':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
} 