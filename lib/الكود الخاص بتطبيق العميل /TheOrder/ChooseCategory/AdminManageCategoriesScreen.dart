// admin/admin_manage_categories_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; // لالتقاط الصور
import 'package:firebase_storage/firebase_storage.dart'; // لرفع الصور
import 'dart:io'; // لاستخدام File
import '../../../Model/category_model.dart';
import 'CategoryController.dart';

class AdminManageCategoriesScreen extends StatelessWidget {
  AdminManageCategoriesScreen({super.key});

  final CategoryController categoryCtrl = Get.find<CategoryController>(); // استخدام نفس المتحكم
  final _formKey = GlobalKey<FormState>();
  final _nameArController = TextEditingController();
  final _nameEnController = TextEditingController();
  final _orderController = TextEditingController();
  final Rxn<File> _selectedImage = Rxn<File>(null);
  final RxBool _isLoading = false.obs;

  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // اختيار صورة
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _selectedImage.value = File(pickedFile.path);
    }
  }

  // إضافة/تعديل قسم
  Future<void> _saveCategory({CategoryModel? existingCategory}) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedImage.value == null && existingCategory == null) { // الصورة إلزامية للإضافة الجديدة
      Get.snackbar("خطأ", "الرجاء اختيار صورة للقسم الجديد.", backgroundColor: Colors.orange);
      return;
    }

    _isLoading.value = true;
    String? imageUrl = existingCategory?.imageUrl; // استخدام الصورة القديمة كافتراضي عند التعديل
    String categoryId = existingCategory?.id ?? _firestore.collection('categories').doc().id; // استخدام ID قديم أو إنشاء جديد

    try {
      // رفع الصورة الجديدة إذا تم اختيار واحدة
      if (_selectedImage.value != null) {
        final ref = _storage.ref().child('category_images').child('$categoryId.jpg');
        final uploadTask = ref.putFile(_selectedImage.value!);
        final snapshot = await uploadTask.whenComplete(() {});
        imageUrl = await snapshot.ref.getDownloadURL();
        debugPrint("Category image uploaded: $imageUrl");
      }

      if (imageUrl == null || imageUrl.isEmpty) {
        throw Exception("فشل تحميل الصورة أو لم يتم توفير رابط.");
      }

      // تحضير البيانات للحفظ
      final categoryData = {
        'name_ar': _nameArController.text.trim(),
        'name_en': _nameEnController.text.trim(), // قد تحتاج لتوليد هذا تلقائياً
        'order': int.tryParse(_orderController.text.trim()) ?? 999,
        'isActive': true, // افترض أنها نشطة عند الإضافة/التعديل
        'imageUrl': imageUrl,
      };

      // حفظ أو تحديث المستند
      await _firestore.collection('categories').doc(categoryId).set(categoryData, SetOptions(merge: true)); // merge=true للتحديث الآمن

      Get.back(); // إغلاق مربع الحوار أو الشاشة
      categoryCtrl.fetchCategories(); // تحديث قائمة الأقسام في الواجهة الرئيسية
      Get.snackbar("نجاح", existingCategory == null ? "تم إضافة القسم بنجاح." : "تم تعديل القسم بنجاح.", backgroundColor: Colors.green);

    } catch (e) {
      debugPrint("Error saving category: $e");
      Get.snackbar("خطأ", "فشل حفظ القسم: $e", backgroundColor: Colors.red);
    } finally {
      _isLoading.value = false;
    }
  }


  // دالة لعرض مربع حوار الإضافة/التعديل
  void _showCategoryDialog({CategoryModel? category}) {
    // ملء الحقول إذا كان تعديلاً
    _nameArController.text = category?.nameAr ?? '';
    _nameEnController.text = category?.nameEn ?? '';
    _orderController.text = category?.order.toString() ?? '';
    _selectedImage.value = null; // مسح الصورة المختارة عند فتح الحوار

    Get.dialog(
      AlertDialog(
        title: Text(category == null ? "إضافة قسم جديد" : "تعديل القسم"),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Obx(() => Column( // Obx لمراقبة _isLoading و _selectedImage
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- اختيار الصورة ---
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 100, height: 100, alignment: Alignment.center,
                      decoration: BoxDecoration( border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                      child: _selectedImage.value != null
                          ? Image.file(_selectedImage.value!, fit: BoxFit.cover, width: 100, height: 100,)
                          : (category?.imageUrl != null && category!.imageUrl!.isNotEmpty
                          ? CachedNetworkImage(imageUrl: category.imageUrl!, fit: BoxFit.cover, width: 100, height: 100, placeholder: (c, u) => const CircularProgressIndicator(), errorWidget: (c,u,e)=> const Icon(Icons.error))
                          : const Icon(Icons.image, size: 40, color: Colors.grey)),
                    ),
                    IconButton( icon: Icon(Icons.edit, color: Colors.white, shadows: [Shadow(blurRadius: 2, color: Colors.black54)]), onPressed: _pickImage, style: IconButton.styleFrom(backgroundColor: Colors.black54)),
                  ],
                ),
                if (_selectedImage.value == null && category == null) Padding(padding: EdgeInsets.only(top: 5), child: Text("الصورة مطلوبة*", style: TextStyle(color: Colors.red, fontSize: 11))),
                const SizedBox(height: 15),
                // --- حقول النص ---
                TextFormField( controller: _nameArController, decoration: InputDecoration(labelText: "اسم القسم (عربي)*"), validator: (v)=>(v==null || v.trim().isEmpty) ? 'مطلوب' : null),
                TextFormField( controller: _nameEnController, decoration: InputDecoration(labelText: "المعرف (إنجليزي)*", hintText: "استخدم حروف إنجليزية وشرطة سفلية فقط"), validator: (v)=>(v==null || v.trim().isEmpty || v.contains(" ")) ? 'مطلوب وبدون مسافات' : null), // تحقق إضافي
                TextFormField( controller: _orderController, decoration: InputDecoration(labelText: "ترتيب الظهور"), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                const SizedBox(height: 20),
                // زر الحفظ مع مؤشر التحميل
                _isLoading.value
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                    onPressed: () => _saveCategory(existingCategory: category),
                    child: Text(category == null ? "إضافة القسم" : "حفظ التعديلات")
                ),
              ],
            )),
          ),
        ),
        // يمكن إضافة زر إلغاء
        actions: [ TextButton(onPressed: () => Get.back(), child: Text("إلغاء")) ],
      ),
      barrierDismissible: !_isLoading.value, // منع الإغلاق أثناء التحميل
    );
  }

  // دالة لحذف قسم (مع تأكيد)
  Future<void> _deleteCategory(CategoryModel category) async {
    Get.defaultDialog(
        title: "تأكيد الحذف",
        middleText: "هل أنت متأكد من حذف القسم \"${category.nameAr}\"؟ \nلن يؤثر هذا على المنتجات الحالية بهذا القسم.",
        confirm: TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Get.back(); // إغلاق التأكيد
              _isLoading.value = true;
              try {
                // حذف الصورة من Storage (اختياري لكن جيد للتنظيف)
                if(category.imageUrl != null) {
                  await _storage.refFromURL(category.imageUrl!).delete().catchError((e){ debugPrint("Ignoring delete image error: $e"); }); // تجاهل الخطأ إذا فشل حذف الصورة
                }
                // حذف المستند من Firestore
                await _firestore.collection('categories').doc(category.id).delete();
                categoryCtrl.fetchCategories(); // تحديث القائمة
                Get.snackbar("نجاح", "تم حذف القسم.", backgroundColor: Colors.green);
              } catch (e) {
                Get.snackbar("خطأ", "فشل حذف القسم: $e", backgroundColor: Colors.red);
              } finally {
                _isLoading.value = false;
              }
            },
            child: const Text("نعم، حذف")
        ),
        cancel: TextButton(onPressed: ()=> Get.back(), child: Text("إلغاء"))
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("إدارة أقسام المنتجات"),
        actions: [ IconButton(icon: const Icon(Icons.refresh), onPressed: categoryCtrl.fetchCategories) ], // زر تحديث
      ),
      // عرض قائمة الأقسام مع أزرار تعديل وحذف
      body: Obx(() => categoryCtrl.isLoading.value
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: categoryCtrl.categories.length,
        itemBuilder: (context, index) {
          final category = categoryCtrl.categories[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: (category.imageUrl != null) ? CachedNetworkImageProvider(category.imageUrl!) : null,
                child: (category.imageUrl == null) ? const Icon(Icons.category) : null,
              ),
              title: Text("${category.nameAr} (${category.nameEn})"),
              subtitle: Text("الترتيب: ${category.order}"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blue), onPressed: () => _showCategoryDialog(category: category)), // تعديل
                  IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _deleteCategory(category)), // حذف
                ],
              ),
            ),
          );
        },
      )),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(), // استدعاء نفس الحوار ولكن بدون تمرير قسم
        tooltip: 'إضافة قسم جديد',
        child: const Icon(Icons.add),
      ),
    );
  }
}