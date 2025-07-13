import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../HomePage/controllers/enhanced_category_filter_controller.dart';

/// معايير الفلترة المحسنة
class FilterCriteria {
  final String? mainCategoryId;
  final String? subCategoryId;
  final String? itemCondition;
  final String? productType; // 'original', 'commercial'
  final bool hasOffers;
  final double? minPrice;
  final double? maxPrice;

  FilterCriteria({
    this.mainCategoryId,
    this.subCategoryId,
    this.itemCondition,
    this.productType,
    this.hasOffers = false,
    this.minPrice,
    this.maxPrice,
  });

  bool get hasActiveFilters {
    return (mainCategoryId != null && mainCategoryId!.isNotEmpty) ||
           (subCategoryId != null && subCategoryId!.isNotEmpty) ||
           (itemCondition != null && itemCondition!.isNotEmpty) ||
           (productType != null && productType!.isNotEmpty) ||
           hasOffers ||
           minPrice != null ||
           maxPrice != null;
  }

  FilterCriteria copyWith({
    String? mainCategoryId,
    String? subCategoryId,
    String? itemCondition,
    String? productType,
    bool? hasOffers,
    double? minPrice,
    double? maxPrice,
    bool clearMainCategory = false,
    bool clearSubCategory = false,
  }) {
    return FilterCriteria(
      mainCategoryId: clearMainCategory ? null : (mainCategoryId ?? this.mainCategoryId),
      subCategoryId: clearSubCategory ? null : (subCategoryId ?? this.subCategoryId),
      itemCondition: itemCondition ?? this.itemCondition,
      productType: productType ?? this.productType,
      hasOffers: hasOffers ?? this.hasOffers,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
    );
  }

  Map<String, dynamic> toFirestoreQuery() {
    final Map<String, dynamic> query = {};
    
    if (mainCategoryId != null && mainCategoryId!.isNotEmpty) {
      query['mainCategoryId'] = mainCategoryId;
    }
    
    if (subCategoryId != null && subCategoryId!.isNotEmpty) {
      query['subCategoryId'] = subCategoryId;
    }
    
    if (productType != null && productType!.isNotEmpty) {
      query['itemCondition'] = productType;
    }
    
    return query;
  }

  @override
  String toString() {
    List<String> parts = [];
    if (mainCategoryId != null && mainCategoryId!.isNotEmpty) {
      parts.add('قسم رئيسي: $mainCategoryId');
    }
    if (subCategoryId != null && subCategoryId!.isNotEmpty) {
      parts.add('قسم فرعي: $subCategoryId');
    }
    if (productType != null && productType!.isNotEmpty) {
      parts.add('نوع: $productType');
    }
    if (hasOffers) {
      parts.add('عروض');
    }
    return parts.isEmpty ? 'بدون فلاتر' : parts.join(', ');
  }
}

/// Widget متقدم للفلترة حسب الأقسام الرئيسية والفرعية
/// يستخدم في HomeScreen لفلترة المنتجات
class AdvancedFilterWidget extends StatefulWidget {
  final Function(FilterCriteria) onFilterChanged;
  final FilterCriteria? initialFilter;

  const AdvancedFilterWidget({
    super.key,
    required this.onFilterChanged,
    this.initialFilter,
  });

  @override
  _AdvancedFilterWidgetState createState() => _AdvancedFilterWidgetState();
}

class _AdvancedFilterWidgetState extends State<AdvancedFilterWidget> {
  final EnhancedCategoryFilterController categoryController = Get.put(EnhancedCategoryFilterController());
  
  FilterCriteria currentFilter = FilterCriteria();
  bool showSubCategories = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialFilter != null) {
      currentFilter = widget.initialFilter!;
      if (currentFilter.mainCategoryId != null && currentFilter.mainCategoryId!.isNotEmpty) {
        showSubCategories = true;
        categoryController.selectMainCategory(
          currentFilter.mainCategoryId!,
          'القسم المحدد',
        );
      }
    }
  }

  void _notifyFilterChange() {
    // تحديث الفلتر بناءً على الاختيارات الحالية من الكونترولر
    final updatedFilter = currentFilter.copyWith(
      mainCategoryId: categoryController.selectedMainCategoryId.value.isEmpty 
          ? null 
          : categoryController.selectedMainCategoryId.value,
      subCategoryId: categoryController.selectedSubCategoryId.value.isEmpty 
          ? null 
          : categoryController.selectedSubCategoryId.value,
      clearMainCategory: categoryController.selectedMainCategoryId.value.isEmpty,
      clearSubCategory: categoryController.selectedSubCategoryId.value.isEmpty,
    );
    
    setState(() {
      currentFilter = updatedFilter;
    });
    
    widget.onFilterChanged(updatedFilter);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان الفلترة
          _buildFilterHeader(),
          
          const SizedBox(height: 16),
          
          // فلترة سريعة بالأقسام الرئيسية
          _buildQuickMainCategoryFilter(),
          
          // الأقسام الفرعية
          Obx(() {
            if (categoryController.selectedMainCategoryId.value.isNotEmpty && 
                categoryController.subCategories.isNotEmpty) {
              return Column(
                children: [
                  const SizedBox(height: 16),
                  _buildSubCategoryFilter(),
                ],
              );
            }
            return const SizedBox.shrink();
          }),
          
          const SizedBox(height: 16),
          
          // فلاتر إضافية
          _buildAdditionalFilters(),
          
          const SizedBox(height: 16),
          
          // أزرار التحكم
          _buildControlButtons(),
        ],
      ),
    );
  }

  Widget _buildFilterHeader() {
    return Row(
      children: [
        Icon(
          Icons.filter_alt,
          color: Theme.of(context).primaryColor,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          'فلترة متقدمة',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const Spacer(),
        Obx(() {
          final hasFilters = currentFilter.hasActiveFilters || 
                           categoryController.hasAnyActiveFilter;
          if (!hasFilters) return const SizedBox.shrink();
          
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'نشط',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildQuickMainCategoryFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الأقسام الرئيسية',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() {
          if (categoryController.isLoading.value) {
            return const Center(
              child: SizedBox(
                height: 40,
                child: CircularProgressIndicator(),
              ),
            );
          }

          return SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categoryController.mainCategories.length + 1, // +1 للخيار "الكل"
              itemBuilder: (context, index) {
                if (index == 0) {
                  // خيار "الكل"
                  return _buildMainCategoryChip(
                    id: '',
                    nameAr: 'الكل',
                    iconName: 'all',
                    color: 'blue',
                    isSelected: categoryController.selectedMainCategoryId.value.isEmpty,
                  );
                }

                final category = categoryController.mainCategories[index - 1];
                return _buildMainCategoryChip(
                  id: category.id,
                  nameAr: category.nameAr,
                  iconName: category.iconName,
                  color: category.color,
                  isSelected: categoryController.selectedMainCategoryId.value == category.id,
                );
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMainCategoryChip({
    required String id,
    required String nameAr,
    String? iconName,
    String? color,
    required bool isSelected,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: FilterChip(
        selected: isSelected,
        onSelected: (bool selected) {
          if (id.isEmpty) {
            // اختيار "الكل"
            categoryController.resetFilters();
          } else {
            categoryController.selectMainCategory(id, nameAr);
          }
          _notifyFilterChange();
        },
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIconFromName(iconName ?? 'category'),
              size: 16,
              color: isSelected ? Colors.white : _getColorFromString(color),
            ),
            const SizedBox(width: 4),
            Text(
              nameAr,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.grey[100],
        selectedColor: _getColorFromString(color) ?? Theme.of(context).primaryColor,
        checkmarkColor: Colors.white,
      ),
    );
  }

  Widget _buildSubCategoryFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الأقسام الفرعية',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() {
          if (categoryController.isLoadingSubCategories.value) {
            return const Center(
              child: SizedBox(
                height: 40,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }

          if (categoryController.subCategories.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'لا توجد أقسام فرعية متاحة',
                style: TextStyle(color: Colors.blue),
              ),
            );
          }

          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // خيار "الكل" للأقسام الفرعية
              FilterChip(
                selected: categoryController.selectedSubCategoryId.value.isEmpty,
                onSelected: (bool selected) {
                  categoryController.selectSubCategory('', '');
                  _notifyFilterChange();
                },
                label: const Text('الكل', style: TextStyle(fontSize: 12)),
                backgroundColor: Colors.grey[100],
                selectedColor: Theme.of(context).primaryColor,
                checkmarkColor: Colors.white,
              ),
              
              // الأقسام الفرعية
              ...categoryController.subCategories.map((subCategory) {
                final isSelected = categoryController.selectedSubCategoryId.value == subCategory.id;
                return FilterChip(
                  selected: isSelected,
                  onSelected: (bool selected) {
                    categoryController.selectSubCategory(
                      selected ? subCategory.id : '',
                      selected ? subCategory.nameAr : '',
                    );
                    _notifyFilterChange();
                  },
                  label: Text(
                    subCategory.nameAr,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  backgroundColor: Colors.grey[100],
                  selectedColor: Theme.of(context).primaryColor,
                  checkmarkColor: Colors.white,
                );
              }),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildAdditionalFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'فلاتر إضافية',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        
        // فلتر نوع المنتج
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              selected: currentFilter.productType == null,
              onSelected: (selected) {
                setState(() {
                  currentFilter = currentFilter.copyWith(productType: null);
                });
                widget.onFilterChanged(currentFilter);
              },
              label: const Text('الكل', style: TextStyle(fontSize: 12)),
              backgroundColor: Colors.grey[100],
              selectedColor: Theme.of(context).primaryColor,
            ),
            FilterChip(
              selected: currentFilter.productType == 'original',
              onSelected: (selected) {
                setState(() {
                  currentFilter = currentFilter.copyWith(
                    productType: selected ? 'original' : null,
                  );
                });
                widget.onFilterChanged(currentFilter);
              },
              label: const Text('منتجات أصلية', style: TextStyle(fontSize: 12)),
              backgroundColor: Colors.grey[100],
              selectedColor: Colors.green,
            ),
            FilterChip(
              selected: currentFilter.productType == 'commercial',
              onSelected: (selected) {
                setState(() {
                  currentFilter = currentFilter.copyWith(
                    productType: selected ? 'commercial' : null,
                  );
                });
                widget.onFilterChanged(currentFilter);
              },
              label: const Text('منتجات تجارية', style: TextStyle(fontSize: 12)),
              backgroundColor: Colors.grey[100],
              selectedColor: Colors.orange,
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // فلتر العروض
        CheckboxListTile(
          title: const Text('المنتجات التي عليها عروض فقط'),
          value: currentFilter.hasOffers,
          onChanged: (bool? value) {
            setState(() {
              currentFilter = currentFilter.copyWith(hasOffers: value ?? false);
            });
            widget.onFilterChanged(currentFilter);
          },
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildControlButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              categoryController.resetFilters();
              setState(() {
                currentFilter = FilterCriteria();
              });
              widget.onFilterChanged(currentFilter);
            },
            icon: const Icon(Icons.clear_all),
            label: const Text('إعادة تعيين'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              widget.onFilterChanged(currentFilter);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.done),
            label: const Text('تطبيق الفلاتر'),
          ),
        ),
      ],
    );
  }

  IconData _getIconFromName(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'all':
        return Icons.apps;
      case 'food':
        return Icons.restaurant;
      case 'electronics':
        return Icons.devices;
      case 'clothing':
        return Icons.checkroom;
      case 'home':
        return Icons.home;
      case 'books':
        return Icons.book;
      case 'sports':
        return Icons.sports;
      case 'beauty':
        return Icons.face;
      case 'toys':
        return Icons.toys;
      case 'automotive':
        return Icons.directions_car;
      case 'health':
        return Icons.medical_services;
      case 'tools':
        return Icons.build;
      case 'garden':
        return Icons.eco;
      default:
        return Icons.category;
    }
  }

  Color? _getColorFromString(String? colorString) {
    if (colorString == null) return null;
    
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
      case 'pink':
        return Colors.pink;
      case 'indigo':
        return Colors.indigo;
      case 'cyan':
        return Colors.cyan;
      case 'amber':
        return Colors.amber;
      case 'brown':
        return Colors.brown;
      case 'grey':
        return Colors.grey;
      default:
        return null;
    }
  }
}

 