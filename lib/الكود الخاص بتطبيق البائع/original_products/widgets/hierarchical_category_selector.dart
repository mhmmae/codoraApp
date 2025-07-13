import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../categories/controllers/categories_management_controller.dart';
import '../../../Model/enhanced_category_model.dart';

class HierarchicalCategorySelector extends StatefulWidget {
  final String? selectedMainCategoryId;
  final String? selectedSubCategoryId;
  final Function(String? mainCategoryId, String? subCategoryId) onCategoryChanged;
  final bool isRequired;

  const HierarchicalCategorySelector({
    super.key,
    this.selectedMainCategoryId,
    this.selectedSubCategoryId,
    required this.onCategoryChanged,
    this.isRequired = true,
  });

  @override
  State<HierarchicalCategorySelector> createState() => _HierarchicalCategorySelectorState();
}

class _HierarchicalCategorySelectorState extends State<HierarchicalCategorySelector> {
  String? _selectedMainCategoryId;
  String? _selectedSubCategoryId;
  
  @override
  void initState() {
    super.initState();
    _selectedMainCategoryId = widget.selectedMainCategoryId;
    _selectedSubCategoryId = widget.selectedSubCategoryId;
    
    // تأكد من تحميل الأقسام
    final categoriesController = Get.find<CategoriesManagementController>();
    if (categoriesController.mainCategories.isEmpty) {
      categoriesController.loadCategories();
    }
  }

  void _onMainCategoryChanged(String? mainCategoryId) {
    setState(() {
      _selectedMainCategoryId = mainCategoryId;
      _selectedSubCategoryId = null; // مسح الاختيار الفرعي عند تغيير الرئيسي
    });
    
    // تحديث القسم في الواجهة الرئيسية
    widget.onCategoryChanged(_selectedMainCategoryId, _selectedSubCategoryId);
    
    final categoriesController = Get.find<CategoriesManagementController>();
    final selectedCategory = categoriesController.mainCategories
        .firstWhereOrNull((cat) => cat.id == _selectedMainCategoryId);
    
    debugPrint('تم تغيير القسم الرئيسي:');
    debugPrint('معرف القسم الرئيسي: $_selectedMainCategoryId');
    if (selectedCategory != null) {
      debugPrint('القسم الرئيسي: ${selectedCategory.nameAr} (${selectedCategory.nameEn})');
    }
    debugPrint('معرف القسم الفرعي: $_selectedSubCategoryId');
  }

  void _onSubCategoryChanged(String? subCategoryId) {
    setState(() {
      _selectedSubCategoryId = subCategoryId;
    });
    
    // تحديث القسم في الواجهة الرئيسية
    widget.onCategoryChanged(_selectedMainCategoryId, _selectedSubCategoryId);
    
    final categoriesController = Get.find<CategoriesManagementController>();
    final selectedMainCategory = categoriesController.mainCategories
        .firstWhereOrNull((cat) => cat.id == _selectedMainCategoryId);
    final selectedSubCategory = selectedMainCategory?.subCategories
        .firstWhereOrNull((cat) => cat.id == _selectedSubCategoryId);
    
    debugPrint('تم تغيير القسم الفرعي:');
    debugPrint('معرف القسم الرئيسي: $_selectedMainCategoryId');
    if (selectedMainCategory != null) {
      debugPrint('القسم الرئيسي: ${selectedMainCategory.nameAr} (${selectedMainCategory.nameEn})');
    }
    debugPrint('معرف القسم الفرعي: $_selectedSubCategoryId');
    if (selectedSubCategory != null) {
      debugPrint('القسم الفرعي: ${selectedSubCategory.nameAr} (${selectedSubCategory.nameEn})');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CategoriesManagementController>(
      init: Get.find<CategoriesManagementController>(),
      builder: (controller) {
        if (controller.isLoading.value) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final selectedMainCategory = controller.mainCategories
            .firstWhereOrNull((cat) => cat.id == _selectedMainCategoryId);

        final subCategories = selectedMainCategory?.subCategories ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // القسم الرئيسي
            _buildMainCategorySelector(controller, selectedMainCategory),
            
            const SizedBox(height: 16),
            
            // القسم الفرعي (يظهر فقط عند اختيار قسم رئيسي)
            if (_selectedMainCategoryId != null && subCategories.isNotEmpty) ...[
              _buildSubCategorySelector(subCategories),
              const SizedBox(height: 8),
            ],
            
            // رسالة توضيحية
            if (_selectedMainCategoryId != null && subCategories.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange[700], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'هذا القسم لا يحتوي على أقسام فرعية',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMainCategorySelector(
    CategoriesManagementController controller,
    EnhancedCategoryModel? selectedMainCategory,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.category, size: 20, color: Colors.blue[600]),
            const SizedBox(width: 8),
            Text(
              'القسم الرئيسي${widget.isRequired ? '*' : ''}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        InkWell(
          onTap: () => _showMainCategoryDialog(controller),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedMainCategoryId == null && widget.isRequired 
                    ? Colors.red 
                    : Colors.grey[300]!,
              ),
            ),
            child: Row(
              children: [
                if (selectedMainCategory != null) ...[
                  _buildCategoryIcon(selectedMainCategory),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // الاسم العربي (الرئيسي)
                        Text(
                          selectedMainCategory.nameAr,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        // الاسم الإنجليزي (الثانوي)
                        Text(
                          selectedMainCategory.nameEn,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        if (selectedMainCategory.subCategories.isNotEmpty == true)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '${selectedMainCategory.subCategories.length} قسم فرعي',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ] else ...[
                  Icon(Icons.category, size: 30, color: Colors.grey[400]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'اختر القسم الرئيسي${widget.isRequired ? ' (مطلوب)' : ''}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ),
                ],
                Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
        
        if (_selectedMainCategoryId == null && widget.isRequired)
          Padding(
            padding: const EdgeInsets.only(top: 5, right: 16),
            child: Text(
              'يرجى اختيار القسم الرئيسي - هذا الحقل مطلوب',
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSubCategorySelector(List<EnhancedCategoryModel> subCategories) {
    final selectedSubCategory = subCategories
        .firstWhereOrNull((cat) => cat.id == _selectedSubCategoryId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.subdirectory_arrow_right, size: 20, color: Colors.green[600]),
            const SizedBox(width: 8),
            const Text(
                                          'القسم الفرعي',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        InkWell(
          onTap: () => _showSubCategoryDialog(subCategories),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                if (selectedSubCategory != null) ...[
                  _buildCategoryIcon(selectedSubCategory),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // الاسم العربي (الرئيسي)
                        Text(
                          selectedSubCategory.nameAr,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        // الاسم الإنجليزي (الثانوي)
                        Text(
                          selectedSubCategory.nameEn,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Icon(Icons.subdirectory_arrow_right, size: 30, color: Colors.green[400]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                                                  'اختر القسم الفرعي',
                      style: TextStyle(fontSize: 14, color: Colors.green[600]),
                    ),
                  ),
                ],
                Icon(Icons.arrow_drop_down, color: Colors.green[600]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryIcon(EnhancedCategoryModel category) {
    if (category.imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: category.imageUrl!,
          width: 30,
          height: 30,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) => 
            Icon(Icons.category, size: 30, color: Colors.blue[600]),
        ),
      );
    } else {
      return Icon(Icons.category, size: 30, color: Colors.blue[600]);
    }
  }

  void _showMainCategoryDialog(CategoriesManagementController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.category, color: Colors.blue[600]),
            const SizedBox(width: 8),
            const Text('اختر القسم الرئيسي'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: controller.mainCategories.length,
            itemBuilder: (context, index) {
              final category = controller.mainCategories[index];
              return ListTile(
                leading: _buildCategoryIcon(category),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.nameAr,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      category.nameEn,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                subtitle: category.subCategories.isNotEmpty == true
                    ? Text(
                        '${category.subCategories.length} قسم فرعي',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue[600],
                        ),
                      )
                    : null,
                selected: category.id == _selectedMainCategoryId,
                onTap: () {
                  _onMainCategoryChanged(category.id);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  void _showSubCategoryDialog(List<EnhancedCategoryModel> subCategories) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.subdirectory_arrow_right, color: Colors.green[600]),
            const SizedBox(width: 8),
            const Text('اختر القسم الفرعي'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: subCategories.length,
            itemBuilder: (context, index) {
              final category = subCategories[index];
              return ListTile(
                leading: _buildCategoryIcon(category),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.nameAr,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      category.nameEn,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                selected: category.id == _selectedSubCategoryId,
                onTap: () {
                  _onSubCategoryChanged(category.id);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }
} 