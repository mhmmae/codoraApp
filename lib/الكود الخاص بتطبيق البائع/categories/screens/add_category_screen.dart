import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/categories_management_controller.dart';
import '../../../Model/enhanced_category_model.dart';

class AddCategoryScreen extends StatefulWidget {
  final bool isSubCategory;
  final EnhancedCategoryModel? parentCategory;
  final EnhancedCategoryModel? categoryToEdit;

  const AddCategoryScreen({
    super.key,
    required this.isSubCategory,
    this.parentCategory,
    this.categoryToEdit,
  });

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameArController = TextEditingController();
  final TextEditingController _nameEnController = TextEditingController();
  final TextEditingController _nameKuController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _orderController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _useImageUpload = false;
  bool _isActive = true;
  bool _isLoading = false; // حالة التحميل

  final CategoriesManagementController controller = Get.find<CategoriesManagementController>();

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    if (widget.categoryToEdit != null) {
      final category = widget.categoryToEdit!;
      _nameArController.text = category.nameAr;
      _nameEnController.text = category.nameEn;
      _nameKuController.text = category.nameKu;
      _imageUrlController.text = category.imageUrl ?? '';
      _orderController.text = category.order.toString();
      _isActive = category.isActive;
      _useImageUpload = false;
    } else {
      _orderController.text = '1';
    }
  }

  @override
  void dispose() {
    _nameArController.dispose();
    _nameEnController.dispose();
    _nameKuController.dispose();
    _imageUrlController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  /// مسح جميع الحقول وإعادة تعيين الشاشة
  void _clearAllFields() {
    setState(() {
      // مسح النصوص
      _nameArController.clear();
      _nameEnController.clear();
      _nameKuController.clear();
      _imageUrlController.clear();
      _orderController.text = '1'; // إعادة تعيين الترتيب للقيمة الافتراضية
      
      // إعادة تعيين المتغيرات
      _selectedImage = null;
      _useImageUpload = false;
      _isActive = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.categoryToEdit != null
              ? 'تعديل القسم'
              : widget.isSubCategory
                  ? 'إضافة قسم فرعي'
                  : 'إضافة قسم رئيسي',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // معلومات القسم الأب (للأقسام الفرعية)
              if (widget.isSubCategory && widget.parentCategory != null) ...[
                Card(
                  elevation: 2,
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.info, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'القسم الرئيسي:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              Text(
                                widget.parentCategory!.nameAr,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // اسم القسم بالعربي
              _buildTextField(
                controller: _nameArController,
                label: 'اسم القسم بالعربي*',
                icon: Icons.text_fields,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال اسم القسم بالعربي';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // اسم القسم بالإنجليزي
              _buildTextField(
                controller: _nameEnController,
                label: 'اسم القسم بالإنجليزي*',
                icon: Icons.text_fields,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال اسم القسم بالإنجليزي';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // اسم القسم بالكردي
              _buildTextField(
                controller: _nameKuController,
                label: 'اسم القسم بالكردي*',
                icon: Icons.text_fields,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال اسم القسم بالكردي';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ترتيب الظهور
              _buildTextField(
                controller: _orderController,
                label: 'ترتيب الظهور*',
                icon: Icons.sort,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال ترتيب الظهور';
                  }
                  if (int.tryParse(value) == null) {
                    return 'يرجى إدخال رقم صحيح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // قسم الصورة
              _buildImageSection(),
              const SizedBox(height: 16),

              // حالة القسم
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.toggle_on, size: 20, color: Colors.blue[600]),
                      const SizedBox(width: 8),
                      const Text(
                        'حالة القسم',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      const Text('مفعل'),
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
                      onPressed: () => Get.back(),
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
                      onPressed: _isLoading ? null : _saveCategory,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.save, color: Colors.white),
                      label: Text(
                        _isLoading
                            ? 'جاري التحميل...'
                            : widget.categoryToEdit != null 
                                ? 'تحديث' 
                                : 'حفظ',
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isLoading ? Colors.grey : Colors.blue,
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
          
          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'جاري معالجة البيانات...',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'يرجى الانتظار',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.blue[600]),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: 'أدخل $label',
            prefixIcon: Icon(icon),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.image, size: 20, color: Colors.blue[600]),
                const SizedBox(width: 8),
                const Text(
                  'صورة القسم',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // أزرار التبديل بين رفع الصورة ورابط الصورة
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _useImageUpload = true;
                        _imageUrlController.clear();
                      });
                    },
                    icon: const Icon(Icons.upload),
                    label: const Text('رفع صورة'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _useImageUpload ? Colors.blue[50] : null,
                      foregroundColor: _useImageUpload ? Colors.blue : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _useImageUpload = false;
                        _selectedImage = null;
                      });
                    },
                    icon: const Icon(Icons.link),
                    label: const Text('رابط صورة'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: !_useImageUpload ? Colors.blue[50] : null,
                      foregroundColor: !_useImageUpload ? Colors.blue : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // قسم رفع الصورة
            if (_useImageUpload) ...[
              if (_selectedImage != null) ...[
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('الكاميرا'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('المعرض'),
                    ),
                  ),
                ],
              ),
            ]
            // قسم رابط الصورة
            else ...[
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'أدخل رابط الصورة',
                  prefixIcon: Icon(Icons.link),
                ),
                onChanged: (value) => setState(() {}),
              ),
              if (_imageUrlController.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: _imageUrlController.text,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      Get.snackbar(
        '❌ خطأ',
        'فشل في اختيار الصورة: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) {
      Get.snackbar(
        '❌ خطأ في البيانات',
        'يرجى ملء جميع الحقول المطلوبة',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      // تفعيل حالة التحميل
      setState(() {
        _isLoading = true;
      });

      // عرض رسالة بدء العملية
      Get.snackbar(
        '⏳ جاري التحميل',
        widget.isSubCategory 
            ? 'جاري إضافة القسم الفرعي...'
            : widget.categoryToEdit != null 
                ? 'جاري تحديث القسم...'
                : 'جاري إضافة القسم الرئيسي...',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      String? imageUrl;

      // رفع الصورة إذا تم اختيارها
      if (_useImageUpload && _selectedImage != null) {
        imageUrl = await controller.uploadCategoryImage(_selectedImage!, _nameArController.text);
        if (imageUrl == null) {
          setState(() {
            _isLoading = false;
          });
          return; // فشل في رفع الصورة
        }
      } else if (!_useImageUpload && _imageUrlController.text.isNotEmpty) {
        imageUrl = _imageUrlController.text.trim();
      }

      // إنشاء نموذج القسم
      final category = EnhancedCategoryModel(
        id: widget.categoryToEdit?.id ?? '',
        nameAr: _nameArController.text.trim(),
        nameEn: _nameEnController.text.trim(),
        nameKu: _nameKuController.text.trim(),
        imageUrl: imageUrl,
        order: int.parse(_orderController.text),
        isActive: _isActive,
        parentId: widget.isSubCategory ? widget.parentCategory?.id : null,
        createdAt: widget.categoryToEdit?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'current_user', // يمكن تحديثه لاحقاً
      );

      bool success;
      if (widget.categoryToEdit != null) {
        // تحديث قسم موجود
        success = await controller.updateCategory(category);
        if (success) {
          Get.snackbar(
            '✅ تم بنجاح',
            'تم تحديث القسم بنجاح',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          Get.back();
        }
      } else {
        // إضافة قسم جديد
        success = await controller.addCategory(category);
        if (success) {
          // عرض رسالة نجاح
          Get.snackbar(
            '✅ تم بنجاح',
            widget.isSubCategory 
                ? 'تم إضافة القسم الفرعي بنجاح'
                : 'تم إضافة القسم الرئيسي بنجاح',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
          
          // مسح جميع الحقول وإعادة تعيين الشاشة بعد تأخير قصير
          await Future.delayed(const Duration(milliseconds: 500));
          _clearAllFields();
          
          // إعطاء انطباع تم الانتهاء من التحميل
          Get.snackbar(
            '🎉 جاهز للإضافة التالية',
            'يمكنك الآن إضافة قسم جديد',
            backgroundColor: Colors.blue,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        }
      }

    } catch (e) {
      Get.snackbar(
        '❌ خطأ',
        'حدث خطأ غير متوقع: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      // إيقاف حالة التحميل
      setState(() {
        _isLoading = false;
      });
    }
  }
} 