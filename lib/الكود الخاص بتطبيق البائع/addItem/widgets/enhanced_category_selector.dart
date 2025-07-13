import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../categories/controllers/categories_management_controller.dart';
import '../../../Model/enhanced_category_model.dart';

class EnhancedCategorySelector extends StatefulWidget {
  final String label;
  final String? initialMainCategoryId;
  final String? initialSubCategoryId;
  final Function(String mainCategoryId, String subCategoryId, String mainCategoryNameEn, String subCategoryNameEn) onCategorySelected;
  final bool isRequired;

  const EnhancedCategorySelector({
    super.key,
    required this.label,
    this.initialMainCategoryId,
    this.initialSubCategoryId,
    required this.onCategorySelected,
    this.isRequired = true,
  });

  @override
  State<EnhancedCategorySelector> createState() => _EnhancedCategorySelectorState();
}

class _EnhancedCategorySelectorState extends State<EnhancedCategorySelector> {
  String? _selectedMainCategoryId;
  String? _selectedSubCategoryId;

  @override
  void initState() {
    super.initState();
    _selectedMainCategoryId = widget.initialMainCategoryId;
    _selectedSubCategoryId = widget.initialSubCategoryId;
  }

  @override
  void didUpdateWidget(EnhancedCategorySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    // تحديث القيم عندما تتغير القيم الأولية من الخارج
    if (widget.initialMainCategoryId != oldWidget.initialMainCategoryId ||
        widget.initialSubCategoryId != oldWidget.initialSubCategoryId) {
      setState(() {
        _selectedMainCategoryId = widget.initialMainCategoryId;
        _selectedSubCategoryId = widget.initialSubCategoryId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final CategoriesManagementController controller = Get.put(CategoriesManagementController());
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.category, size: 20, color: Colors.blue[600]),
            const SizedBox(width: 8),
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final mainCategories = controller.mainCategories;
          final selectedMainCategory = mainCategories.firstWhereOrNull(
            (cat) => cat.id == _selectedMainCategoryId
          );

          return Column(
            children: [
              // اختيار القسم الرئيسي
              InkWell(
                onTap: () => _showMainCategoryDialog(context, controller),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedMainCategory?.nameAr ?? 'اختر القسم الرئيسي',
                          style: TextStyle(
                            color: selectedMainCategory == null ? Colors.grey : Colors.black,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                    ],
                  ),
                ),
              ),

              if (selectedMainCategory != null) ...[
                const SizedBox(height: 8),
                // اختيار القسم الفرعي
                InkWell(
                  onTap: () => _showSubCategoryDialog(context, controller, selectedMainCategory),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _getSelectedSubCategoryName(controller, selectedMainCategory) ?? 'اختر القسم الفرعي',
                            style: TextStyle(
                              color: _selectedSubCategoryId == null ? Colors.grey : Colors.black,
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          );
        }),
      ],
    );
  }

  String? _getSelectedSubCategoryName(CategoriesManagementController controller, EnhancedCategoryModel mainCategory) {
    if (_selectedSubCategoryId == null) return null;
    final subCategories = controller.getSubCategories(mainCategory.id);
    final selectedSubCategory = subCategories.firstWhereOrNull((cat) => cat.id == _selectedSubCategoryId);
    return selectedSubCategory?.nameAr;
  }

  void _showMainCategoryDialog(BuildContext context, CategoriesManagementController controller) {
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
                leading: Icon(Icons.category, color: Colors.blue[600]),
                title: Text(category.nameAr),
                selected: category.id == _selectedMainCategoryId,
                onTap: () {
                  setState(() {
                    _selectedMainCategoryId = category.id;
                    _selectedSubCategoryId = null; // مسح الاختيار الفرعي
                  });
                  
                  widget.onCategorySelected(
                    category.id,
                    '',
                    category.nameEn,
                    '',
                  );
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

  void _showSubCategoryDialog(BuildContext context, CategoriesManagementController controller, EnhancedCategoryModel mainCategory) {
    final subCategories = controller.getSubCategories(mainCategory.id);
    
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
            itemCount: subCategories.length + 1, // +1 لخيار "بدون قسم فرعي"
            itemBuilder: (context, index) {
              if (index == 0) {
                // خيار "بدون قسم فرعي"
                return ListTile(
                  leading: Icon(Icons.clear, color: Colors.grey[600]),
                  title: const Text('بدون قسم فرعي'),
                  selected: _selectedSubCategoryId == null,
                  onTap: () {
                    setState(() {
                      _selectedSubCategoryId = null;
                    });
                    
                    widget.onCategorySelected(
                      mainCategory.id,
                      '',
                      mainCategory.nameEn,
                      '',
                    );
                    Navigator.pop(context);
                  },
                );
              }
              
              final category = subCategories[index - 1];
              return ListTile(
                leading: Icon(Icons.subdirectory_arrow_right, color: Colors.green[600]),
                title: Text(category.nameAr),
                selected: category.id == _selectedSubCategoryId,
                onTap: () {
                  setState(() {
                    _selectedSubCategoryId = category.id;
                  });
                  
                  widget.onCategorySelected(
                    mainCategory.id,
                    category.id,
                    mainCategory.nameEn,
                    category.nameEn,
                  );
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