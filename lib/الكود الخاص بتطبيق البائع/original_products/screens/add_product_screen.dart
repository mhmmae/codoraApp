import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../controllers/original_products_controller.dart';
import '../../../Model/company_model.dart';
import '../../categories/controllers/categories_management_controller.dart';
import '../widgets/hierarchical_category_selector.dart';

/// شاشة إضافة منتج جديد
class AddProductScreen extends StatefulWidget {
  final String? companyId;
  
  const AddProductScreen({super.key, this.companyId});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _imageUrlController = TextEditingController();
  
  String? _selectedCompanyId;
  String? _selectedMainCategoryId; // القسم الرئيسي المختار
  String? _selectedSubCategoryId; // القسم الفرعي المختار
  String? _selectedCategoryNameEn; // للحفظ النهائي
  bool _isActive = true;
  bool _useImageUpload = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  
  // للبحث والقائمة المنسدلة للمنتجات
  List<CompanyProductModel> _existingProducts = [];
  List<CompanyProductModel> _filteredProducts = [];
  bool _showProductsSuggestions = false;
  final FocusNode _nameFocusNode = FocusNode();
  
  @override
  void initState() {
    super.initState();
    _selectedCompanyId = widget.companyId;
    _loadExistingProducts();
    
    // تهيئة وتحميل الأقسام
    _initializeCategoryController();
    
    // مراقبة التغيير في اسم المنتج
    _nameController.addListener(_onNameChanged);
    _nameFocusNode.addListener(_onFocusChanged);
  }

  void _initializeCategoryController() async {
    try {
      // التأكد من وجود CategoriesManagementController في Get
      final categoryController = Get.put(CategoriesManagementController());
      
      // إذا لم تكن الأقسام محملة، قم بتحميلها
      if (categoryController.allCategories.isEmpty && !categoryController.isLoading.value) {
        debugPrint('Starting to load categories...');
        await categoryController.loadCategories();
        debugPrint('Categories load completed. Count: ${categoryController.allCategories.length}');
      } else if (categoryController.allCategories.isNotEmpty) {
        debugPrint('Categories already loaded. Count: ${categoryController.allCategories.length}');
      }
    } catch (e) {
      debugPrint('Error initializing category controller: $e');
      Get.snackbar(
        '⚠️ تنبيه',
        'حدث خطأ في تحميل الأقسام. يرجى المحاولة مرة أخرى.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _onFocusChanged() {
    if (!_nameFocusNode.hasFocus) {
      setState(() {
        _showProductsSuggestions = false;
      });
    }
  }

  void _onNameChanged() {
    final query = _nameController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _filteredProducts = [];
        _showProductsSuggestions = false;
      });
      return;
    }

    final filtered = _existingProducts.where((product) {
      return product.nameAr.toLowerCase().contains(query.toLowerCase()) ||
             product.nameEn.toLowerCase().contains(query.toLowerCase());
    }).toList();

    setState(() {
      _filteredProducts = filtered;
      _showProductsSuggestions = filtered.isNotEmpty && _nameFocusNode.hasFocus;
    });
  }

  void _loadExistingProducts() async {
    if (_selectedCompanyId != null) {
      final controller = Get.find<OriginalProductsController>();
      final company = controller.companies.firstWhereOrNull((c) => c.id == _selectedCompanyId);
      if (company != null) {
        setState(() {
          _existingProducts = company.products ?? [];
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _imageUrlController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  /// مسح جميع القيم المدخلة وإعادة تعيين الشاشة
  void _clearAllFields() {
    setState(() {
      // مسح النصوص
      _nameController.clear();
      _imageUrlController.clear();
      
      // إعادة تعيين المتغيرات
      _selectedMainCategoryId = null;
      _selectedSubCategoryId = null;
      _selectedCategoryNameEn = null;
      _selectedImage = null;
      _useImageUpload = false;
      _isActive = true;
      
      // مسح قوائم المنتجات المقترحة
      _existingProducts.clear();
      _filteredProducts.clear();
      _showProductsSuggestions = false;
      
      // إزالة التركيز من الحقول
      _nameFocusNode.unfocus();
    });
    
    // إعادة تحميل المنتجات الموجودة للشركة
    _loadExistingProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'إضافة منتج جديد',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: GetBuilder<OriginalProductsController>(
        init: OriginalProductsController(),
        builder: (controller) {
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // اختيار الشركة
                      if (widget.companyId == null) ...[
                        Row(
                          children: [
                            Icon(Icons.business, size: 20, color: Colors.blue[600]),
                            const SizedBox(width: 8),
                            const Text(
                              'اختر الشركة*',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedCompanyId,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'اختر الشركة',
                            prefixIcon: Icon(Icons.business),
                          ),
                          items: controller.companies.map((company) {
                            return DropdownMenuItem<String>(
                              value: company.id,
                              child: Text(company.nameAr),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCompanyId = value;
                              _loadExistingProducts();
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'يرجى اختيار الشركة - هذا الحقل مطلوب';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // اسم المنتج مع القائمة المنسدلة
                      Row(
                        children: [
                          Icon(Icons.inventory_2, size: 20, color: Colors.blue[600]),
                          const SizedBox(width: 8),
                          const Text(
                            'اسم المنتج*',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        focusNode: _nameFocusNode,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'أدخل اسم المنتج',
                          prefixIcon: Icon(Icons.inventory_2),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'يرجى إدخال اسم المنتج - هذا الحقل مطلوب';
                          }
                          if (value.trim().length < 3) {
                            return 'اسم المنتج يجب أن يكون 3 أحرف على الأقل';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // اختيار الأقسام
                      HierarchicalCategorySelector(
                        selectedMainCategoryId: _selectedMainCategoryId,
                        selectedSubCategoryId: _selectedSubCategoryId,
                        onCategoryChanged: _onCategoryChanged,
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),
                      
                      // الصورة
                      _buildImageSection(),
                      const SizedBox(height: 16),
                      
                      // حالة المنتج
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.toggle_on, size: 20, color: Colors.blue[600]),
                              const SizedBox(width: 8),
                              const Text(
                                'حالة المنتج',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              const Text('متاح'),
                              Switch(
                                value: _isActive,
                                onChanged: (value) {
                                  setState(() {
                                    _isActive = value;
                                  });
                                },
                                activeColor: Colors.green,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // أزرار الحفظ والإلغاء
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Get.back();
                              },
                              icon: const Icon(Icons.cancel),
                              label: const Text('إلغاء'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: const BorderSide(color: Colors.red),
                                foregroundColor: Colors.red,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: controller.isLoading.value ? null : _saveProduct,
                              icon: controller.isLoading.value
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.save),
                              label: Text(controller.isLoading.value ? 'جاري الحفظ...' : 'حفظ المنتج'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // قائمة اقتراحات المنتجات
              if (_showProductsSuggestions && _filteredProducts.isNotEmpty)
                Positioned(
                  top: widget.companyId == null ? 200 : 140,
                  left: 16,
                  right: 16,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withOpacity(0.5), width: 2),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning, color: Colors.orange[700], size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'منتجات موجودة بأسماء مشابهة:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _filteredProducts.length,
                              itemBuilder: (context, index) {
                                final product = _filteredProducts[index];
                                return ListTile(
                                  leading: product.imageUrl != null && product.imageUrl!.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: CachedNetworkImage(
                                            imageUrl: product.imageUrl!,
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                            errorWidget: (context, url, error) => const Icon(Icons.inventory_2),
                                          ),
                                        )
                                      : const Icon(Icons.inventory_2),
                                  title: Text(
                                    product.nameAr,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  subtitle: Text(
                                    'موجود في قسم: ${product.category}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  trailing: const Icon(Icons.warning, color: Colors.orange, size: 16),
                                  dense: true,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _onCategoryChanged(String? mainCategoryId, String? subCategoryId) {
    setState(() {
      _selectedMainCategoryId = mainCategoryId;
      _selectedSubCategoryId = subCategoryId;
      
      // تحديث اسم القسم للحفظ
      if (mainCategoryId != null) {
        final categoryController = Get.find<CategoriesManagementController>();
        final mainCategory = categoryController.mainCategories
            .firstWhereOrNull((cat) => cat.id == mainCategoryId);
        if (mainCategory != null) {
          if (subCategoryId != null) {
            final subCategory = mainCategory.subCategories
                .firstWhereOrNull((cat) => cat.id == subCategoryId);
            if (subCategory != null) {
              _selectedCategoryNameEn = subCategory.nameEn;
            }
          } else {
            _selectedCategoryNameEn = mainCategory.nameEn;
          }
        }
      }
    });
    
    debugPrint('تم تحديث الأقسام:');
    debugPrint('القسم الرئيسي: $_selectedMainCategoryId');
    debugPrint('القسم الفرعي: $_selectedSubCategoryId');
    debugPrint('اسم القسم: $_selectedCategoryNameEn');
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.image, size: 20, color: Colors.blue[600]),
            const SizedBox(width: 8),
            const Text(
              'صورة المنتج*',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // أزرار التبديل
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _useImageUpload = true;
                    _imageUrlController.clear();
                  });
                },
                icon: const Icon(Icons.upload),
                label: const Text('رفع صورة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _useImageUpload ? Colors.blue : Colors.grey[300],
                  foregroundColor: _useImageUpload ? Colors.white : Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _useImageUpload = false;
                    _selectedImage = null;
                  });
                },
                icon: const Icon(Icons.link),
                label: const Text('رابط صورة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: !_useImageUpload ? Colors.blue : Colors.grey[300],
                  foregroundColor: !_useImageUpload ? Colors.white : Colors.black,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // منطقة الصورة
        if (_useImageUpload) ...[
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedImage == null ? Colors.red : Colors.grey[300]!,
                  width: _selectedImage == null ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[50],
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text('اضغط لاختيار صورة (مطلوب)', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
            ),
          ),
          if (_selectedImage == null)
            Padding(
              padding: const EdgeInsets.only(top: 5, right: 16),
              child: Text(
                'يرجى اختيار صورة للمنتج - هذا الحقل مطلوب',
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 12,
                ),
              ),
            ),
        ] else ...[
          TextFormField(
            controller: _imageUrlController,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderSide: BorderSide(
                  color: _imageUrlController.text.trim().isEmpty ? Colors.red : Colors.grey,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: _imageUrlController.text.trim().isEmpty ? Colors.red : Colors.grey,
                ),
              ),
              hintText: 'أدخل رابط صورة المنتج (مطلوب)',
              prefixIcon: Icon(Icons.link),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'يرجى إدخال رابط صورة المنتج - هذا الحقل مطلوب';
              }
              // تحقق بسيط من صحة الرابط
              if (!value.trim().startsWith('http')) {
                return 'يرجى إدخال رابط صحيح يبدأ بـ http';
              }
              return null;
            },
            onChanged: (value) {
              setState(() {}); // لتحديث لون الحدود
            },
          ),
          if (_imageUrlController.text.trim().isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 5, right: 16),
              child: Text(
                'يرجى إدخال رابط صورة المنتج - هذا الحقل مطلوب',
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 12,
                ),
              ),
            ),
          if (_imageUrlController.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: _imageUrlController.text,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(Icons.error, color: Colors.red),
                  ),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Future<void> _pickImage() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر مصدر الصورة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('الكاميرا'),
              onTap: () {
                Navigator.pop(context);
                _getImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('المعرض'),
              onTap: () {
                Navigator.pop(context);
                _getImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _saveProduct() async {
    // التحقق من صحة النموذج
    if (!_formKey.currentState!.validate()) {
      Get.snackbar(
        '❌ خطأ في البيانات',
        'يرجى ملء جميع الحقول المطلوبة بشكل صحيح',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    // التحقق من اختيار الشركة
    if (_selectedCompanyId == null) {
      Get.snackbar(
        '❌ خطأ',
        'يرجى اختيار الشركة',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    // التحقق من اختيار قسم المنتج
    if (_selectedCategoryNameEn == null) {
      Get.snackbar(
        '❌ خطأ',
        'يرجى اختيار قسم المنتج',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    // التحقق من وجود صورة المنتج
    if (_useImageUpload && _selectedImage == null) {
      Get.snackbar(
        '❌ خطأ',
        'يرجى اختيار صورة للمنتج من الكاميرا أو المعرض',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    if (!_useImageUpload && _imageUrlController.text.trim().isEmpty) {
      Get.snackbar(
        '❌ خطأ',
        'يرجى إدخال رابط صورة المنتج',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    final controller = Get.find<OriginalProductsController>();
    
    // التحقق من وجود منتج بنفس الاسم
    final duplicateProduct = _existingProducts.firstWhereOrNull(
      (product) => product.nameAr.toLowerCase() == _nameController.text.trim().toLowerCase()
    );
    
    if (duplicateProduct != null) {
      Get.dialog(
        AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange[700]),
              const SizedBox(width: 8),
              const Text('تحذير'),
            ],
          ),
          content: Text(
            'يوجد منتج بنفس الاسم "${duplicateProduct.nameAr}" في هذه الشركة.\n\nهل تريد المتابعة وإضافة المنتج رغم ذلك؟'
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('إلغاء', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                Get.back();
                _proceedWithSave(controller);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('متابعة رغم التشابه', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    _proceedWithSave(controller);
  }

  void _proceedWithSave(OriginalProductsController controller) async {
    // التحقق من اختيار القسم الرئيسي
    if (_selectedMainCategoryId == null || _selectedMainCategoryId!.isEmpty) {
      Get.snackbar(
        '❌ خطأ',
        'يرجى اختيار القسم الرئيسي للمنتج',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    String? imageUrl;
    
    // رفع الصورة إذا تم اختيارها
    if (_useImageUpload && _selectedImage != null) {
      try {
        imageUrl = await controller.uploadImageFromFile(_selectedImage!);
      } catch (e) {
        Get.snackbar(
          '❌ خطأ في رفع الصورة',
          'فشل في رفع الصورة: ${e.toString()}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        return;
      }
    } else if (!_useImageUpload && _imageUrlController.text.trim().isNotEmpty) {
      imageUrl = _imageUrlController.text.trim();
    }

    // إعداد معلومات القسم للحفظ
    String categoryInfo = '';
    String? mainCategoryNameAr;
    String? mainCategoryNameEn;
    String? subCategoryNameAr;
    String? subCategoryNameEn;
    
    final categoryController = Get.find<CategoriesManagementController>();
    
    // الحصول على معلومات القسم الرئيسي
    final mainCategory = categoryController.mainCategories
        .firstWhereOrNull((cat) => cat.id == _selectedMainCategoryId);
    if (mainCategory != null) {
      categoryInfo = mainCategory.nameEn;
      mainCategoryNameAr = mainCategory.nameAr;
      mainCategoryNameEn = mainCategory.nameEn;
      
      // إضافة معلومات القسم الفرعي إذا تم اختياره
      if (_selectedSubCategoryId != null) {
        final subCategory = mainCategory.subCategories
            .firstWhereOrNull((cat) => cat.id == _selectedSubCategoryId);
        if (subCategory != null) {
          categoryInfo = '${mainCategory.nameEn}_${subCategory.nameEn}';
          subCategoryNameAr = subCategory.nameAr;
          subCategoryNameEn = subCategory.nameEn;
        }
      }
    }

    debugPrint('إعداد المنتج للحفظ:');
    debugPrint('القسم الرئيسي: $_selectedMainCategoryId');
    debugPrint('القسم الفرعي: $_selectedSubCategoryId');
    debugPrint('معلومات القسم: $categoryInfo');

    final product = CompanyProductModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nameAr: _nameController.text.trim(),
      nameEn: _nameController.text.trim(),
      category: categoryInfo,
      mainCategoryId: _selectedMainCategoryId,
      subCategoryId: _selectedSubCategoryId,
      mainCategoryNameAr: mainCategoryNameAr,
      mainCategoryNameEn: mainCategoryNameEn,
      subCategoryNameAr: subCategoryNameAr,
      subCategoryNameEn: subCategoryNameEn,
      companyId: _selectedCompanyId!,
      imageUrl: imageUrl,
      isActive: _isActive,
      createdBy: 'current_user',
      createdAt: DateTime.now(),
      price: 0.0,
      description: null,
    );

    try {
      await controller.addProductToCompany(_selectedCompanyId!, product);
      
      // عرض رسالة النجاح مع معلومات الفئة
      String categoryMessage = 'تم إضافة المنتج "${product.nameAr}" بنجاح';
      if (mainCategoryNameAr != null) {
        categoryMessage += '\nالقسم الرئيسي: $mainCategoryNameAr';
        if (subCategoryNameAr != null) {
          categoryMessage += '\nالقسم الفرعي: $subCategoryNameAr';
        }
      }
      
      Get.snackbar(
        '✅ تم بنجاح',
        categoryMessage,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 4),
      );
      
      // مسح جميع القيم وإعادة تعيين الشاشة
      _clearAllFields();
      
    } catch (e) {
      Get.snackbar(
        '❌ خطأ',
        'حدث خطأ أثناء إضافة المنتج: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }
}