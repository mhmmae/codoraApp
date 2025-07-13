import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../Model/company_model.dart';

/// كنترولر إدارة الشركات والمنتجات الأصلية
class OriginalProductsController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // قوائم البيانات
  final RxList<CompanyModel> companies = <CompanyModel>[].obs;
  final RxList<CompanyProductModel> products = <CompanyProductModel>[].obs;
  final RxList<CompanyProductModel> filteredProducts = <CompanyProductModel>[].obs;

  // حالة التحميل
  final RxBool isLoading = false.obs;
  final RxBool isLoadingProducts = false.obs;
  final RxBool isUploading = false.obs;

  // الشركة والمنتج المختارين
  final Rxn<CompanyModel> selectedCompany = Rxn<CompanyModel>();
  final Rxn<CompanyProductModel> selectedProduct = Rxn<CompanyProductModel>();

  // للبحث والفلترة المحسنة
  final RxString searchQuery = ''.obs;
  final RxString selectedCategory = ''.obs;
  final RxString selectedMainCategoryId = ''.obs;
  final RxString selectedSubCategoryId = ''.obs;
  final RxString filterByCompanyId = ''.obs;
  final RxBool showActiveOnly = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadCompanies();
    
    // مراقبة تغيير الشركة المختارة
    selectedCompany.listen((company) {
      if (company != null) {
        loadProductsByCompany(company.id);
      } else {
        filteredProducts.clear();
      }
    });

    // مراقبة البحث والفلترة المحسنة
    debounce(searchQuery, (_) => filterProducts(), time: Duration(milliseconds: 500));
    selectedCategory.listen((_) => filterProducts());
    selectedMainCategoryId.listen((_) => filterProducts());
    selectedSubCategoryId.listen((_) => filterProducts());
    filterByCompanyId.listen((_) => filterProducts());
    showActiveOnly.listen((_) => filterProducts());
  }

  /// تحميل جميع الشركات
  Future<void> loadCompanies() async {
    try {
      isLoading.value = true;
      
      final QuerySnapshot snapshot = await _firestore
          .collection('brand_companies')
          .orderBy('nameAr')
          .get();

      final List<CompanyModel> loadedCompanies = [];

      for (final doc in snapshot.docs) {
        final company = CompanyModel.fromFirestore(doc);
        
        // تحميل منتجات كل شركة
        final List<CompanyProductModel> companyProducts = await _loadProductsForCompany(company.id);
        
        // إنشاء شركة مع منتجاتها
        final companyWithProducts = CompanyModel(
          id: company.id,
          nameAr: company.nameAr,
          nameEn: company.nameEn,
          logoUrl: company.logoUrl,
          description: company.description,
          country: company.country,
          isActive: company.isActive,
          createdBy: company.createdBy,
          createdAt: company.createdAt,
          updatedAt: company.updatedAt,
          products: companyProducts,
        );
        
        loadedCompanies.add(companyWithProducts);
        
        // طباعة معلومات البلد للتشخيص
        debugPrint('🏢 شركة: ${company.nameAr} | البلد: "${company.country ?? 'غير محدد'}"');
      }

      companies.value = loadedCompanies;
      debugPrint('تم تحميل ${companies.length} شركة');
    } catch (e) {
      debugPrint('خطأ في تحميل الشركات: $e');
      Get.snackbar(
        'خطأ',
        'فشل في تحميل الشركات: ${e.toString()}',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// تحميل منتجات شركة معينة (دالة مساعدة)
  Future<List<CompanyProductModel>> _loadProductsForCompany(String companyId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('company_products')
          .where('companyId', isEqualTo: companyId)
          .orderBy('nameAr')
          .get();

      return snapshot.docs
          .map((doc) => CompanyProductModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('خطأ في تحميل منتجات الشركة $companyId: $e');
      return [];
    }
  }

  /// تحميل منتجات شركة معينة
  Future<void> loadProductsByCompany(String companyId) async {
    try {
      isLoadingProducts.value = true;
      
      final QuerySnapshot snapshot = await _firestore
          .collection('company_products')
          .where('companyId', isEqualTo: companyId)
          .where('isActive', isEqualTo: true)
          .orderBy('nameAr')
          .get();

      products.value = snapshot.docs
          .map((doc) => CompanyProductModel.fromFirestore(doc))
          .toList();

      filterProducts(); // تطبيق الفلترة
      debugPrint('تم تحميل ${products.length} منتج للشركة');
    } catch (e) {
      debugPrint('خطأ في تحميل المنتجات: $e');
      Get.snackbar(
        'خطأ',
        'فشل في تحميل المنتجات: ${e.toString()}',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    } finally {
      isLoadingProducts.value = false;
    }
  }

  /// فلترة المنتجات المحسنة حسب البحث والفئات والشركة
  void filterProducts() {
    List<CompanyProductModel> filtered = products;

    // فلترة حسب حالة النشاط
    if (showActiveOnly.value) {
      filtered = filtered.where((product) => product.isActive).toList();
    }

    // فلترة حسب البحث النصي
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      filtered = filtered.where((product) =>
          product.nameAr.toLowerCase().contains(query) ||
          product.nameEn.toLowerCase().contains(query) ||
          (product.description?.toLowerCase().contains(query) ?? false) ||
          product.category.toLowerCase().contains(query)
      ).toList();
    }

    // فلترة حسب الفئة القديمة (للتوافق مع النظام الحالي)
    if (selectedCategory.value.isNotEmpty) {
      filtered = filtered.where((product) =>
          product.category == selectedCategory.value
      ).toList();
    }

    // فلترة حسب القسم الرئيسي الجديد
    if (selectedMainCategoryId.value.isNotEmpty) {
      filtered = filtered.where((product) =>
          product.mainCategoryId == selectedMainCategoryId.value
      ).toList();
    }

    // فلترة حسب القسم الفرعي الجديد
    if (selectedSubCategoryId.value.isNotEmpty) {
      filtered = filtered.where((product) =>
          product.subCategoryId == selectedSubCategoryId.value
      ).toList();
    }

    // فلترة حسب الشركة
    if (filterByCompanyId.value.isNotEmpty) {
      filtered = filtered.where((product) =>
          product.companyId == filterByCompanyId.value
      ).toList();
    }

    filteredProducts.value = filtered;
    debugPrint('🔍 تمت فلترة المنتجات: ${filtered.length} من أصل ${products.length}');
  }

  /// البحث بمعايير متقدمة
  Future<void> searchProductsAdvanced({
    String? searchText,
    String? mainCategoryId,
    String? subCategoryId,
    String? companyId,
    bool? activeOnly,
  }) async {
    if (searchText != null) searchQuery.value = searchText;
    if (mainCategoryId != null) selectedMainCategoryId.value = mainCategoryId;
    if (subCategoryId != null) selectedSubCategoryId.value = subCategoryId;
    if (companyId != null) filterByCompanyId.value = companyId;
    if (activeOnly != null) showActiveOnly.value = activeOnly;
    
    filterProducts();
  }

  /// إعادة تعيين الفلاتر
  void clearFilters() {
    searchQuery.value = '';
    selectedCategory.value = '';
    selectedMainCategoryId.value = '';
    selectedSubCategoryId.value = '';
    filterByCompanyId.value = '';
    showActiveOnly.value = true;
    filterProducts();
  }

  /// الحصول على جميع المنتجات الأصلية (من جميع الشركات)
  Future<List<CompanyProductModel>> getAllOriginalProducts() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('company_products')
          .where('isActive', isEqualTo: true)
          .orderBy('nameAr')
          .get();

      return snapshot.docs
          .map((doc) => CompanyProductModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('خطأ في تحميل جميع المنتجات الأصلية: $e');
      return [];
    }
  }

  /// البحث في المنتجات الأصلية لربطها بالمنتجات التجارية
  Future<List<CompanyProductModel>> searchOriginalProductsForCommercial(String query) async {
    try {
      if (query.isEmpty) return [];

      final QuerySnapshot snapshot = await _firestore
          .collection('company_products')
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => CompanyProductModel.fromFirestore(doc))
          .where((product) => 
              product.nameAr.toLowerCase().contains(query.toLowerCase()) ||
              product.nameEn.toLowerCase().contains(query.toLowerCase())
          )
          .take(10) // الحد الأقصى للنتائج
          .toList();
    } catch (e) {
      debugPrint('خطأ في البحث في المنتجات الأصلية: $e');
      return [];
    }
  }

  /// إضافة شركة جديدة (مع صورة)
  Future<void> addCompanyWithImage({
    required String nameAr,
    required String nameEn,
    required Uint8List logoBytes,
  }) async {
    try {
      isUploading.value = true;

      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }

      // رفع الشعار
      final String logoUrl = await _uploadImage(logoBytes, 'brand_companies');

      // إنشاء الشركة
      final String companyId = const Uuid().v4();
      final CompanyModel company = CompanyModel(
        id: companyId,
        nameAr: nameAr,
        nameEn: nameEn,
        logoUrl: logoUrl,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: currentUser.uid,
      );

      // حفظ في Firebase
      await _firestore.collection('brand_companies').doc(companyId).set(company.toMap());

      // إضافة للقائمة المحلية
      companies.add(company);
      companies.sort((a, b) => a.nameAr.compareTo(b.nameAr));

      Get.snackbar(
        '✅ نجح',
        'تم إضافة الشركة بنجاح',
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );

      debugPrint('تم إضافة الشركة: $nameAr');
    } catch (e) {
      debugPrint('خطأ في إضافة الشركة: $e');
      Get.snackbar(
        'خطأ',
        'فشل في إضافة الشركة: ${e.toString()}',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    } finally {
      isUploading.value = false;
    }
  }

  /// إضافة شركة جديدة (نموذج مبسط)
  Future<void> addCompany(CompanyModel company) async {
    try {
      isLoading.value = true;

      // حفظ في Firebase
      await _firestore.collection('brand_companies').doc(company.id).set(company.toMap());

      // إعادة تحميل البيانات لضمان التحديث
      await loadCompanies();

      Get.snackbar(
        '✅ نجح',
        'تم إضافة الشركة بنجاح',
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );

      debugPrint('تم إضافة الشركة: ${company.nameAr}');
    } catch (e) {
      debugPrint('خطأ في إضافة الشركة: $e');
      Get.snackbar(
        'خطأ',
        'فشل في إضافة الشركة: ${e.toString()}',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// إضافة منتج لشركة (بـ Uint8List)
  Future<void> addProductToCompanyWithImage({
    required String companyId,
    required String nameAr,
    required String nameEn,
    required String category,
    required Uint8List imageBytes,
    String? mainCategoryId,
    String? subCategoryId,
  }) async {
    try {
      isUploading.value = true;

      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }

      // رفع صورة المنتج
      final String imageUrl = await _uploadImage(imageBytes, 'company_products');

      // إنشاء المنتج
      final String productId = const Uuid().v4();
      final CompanyProductModel product = CompanyProductModel(
        id: productId,
        companyId: companyId,
        nameAr: nameAr,
        nameEn: nameEn,
        imageUrl: imageUrl,
        category: category,
        mainCategoryId: mainCategoryId,
        subCategoryId: subCategoryId,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: currentUser.uid,
      );

      // حفظ في Firebase
      await _firestore.collection('company_products').doc(productId).set(product.toMap());

      // إضافة للقائمة المحلية إذا كانت الشركة المختارة
      if (selectedCompany.value?.id == companyId) {
        products.add(product);
        products.sort((a, b) => a.nameAr.compareTo(b.nameAr));
        filterProducts();
      }

      Get.snackbar(
        '✅ نجح',
        'تم إضافة المنتج بنجاح',
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );

      debugPrint('تم إضافة المنتج: $nameAr');
      debugPrint('معرف القسم الرئيسي: $mainCategoryId');
      debugPrint('معرف القسم الفرعي: $subCategoryId');
    } catch (e) {
      debugPrint('خطأ في إضافة المنتج: $e');
      Get.snackbar(
        'خطأ',
        'فشل في إضافة المنتج: ${e.toString()}',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    } finally {
      isUploading.value = false;
    }
  }

  /// إضافة منتج لشركة (نموذج مبسط)
  Future<void> addProductToCompany(String companyId, CompanyProductModel product) async {
    try {
      isUploading.value = true;
      
      // التأكد من وجود معرفات الأقسام
      if (product.mainCategoryId == null || product.mainCategoryId!.isEmpty) {
        throw Exception('يجب تحديد القسم الرئيسي للمنتج');
      }
      
      // حفظ في Firebase
      await _firestore.collection('company_products').doc(product.id).set(product.toMap());
      
      // إضافة للشركة في القائمة المحلية
      final companyIndex = companies.indexWhere((c) => c.id == companyId);
      if (companyIndex != -1) {
        companies[companyIndex].products.add(product);
        companies.refresh();
      }
      
      debugPrint('تم إضافة المنتج: ${product.nameAr}');
      debugPrint('معرف القسم الرئيسي: ${product.mainCategoryId}');
      debugPrint('معرف القسم الفرعي: ${product.subCategoryId}');
      
      Get.snackbar(
        '✅ نجح',
        'تم إضافة المنتج بنجاح',
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );
    } catch (e) {
      debugPrint('خطأ في إضافة المنتج: $e');
      Get.snackbar(
        'خطأ',
        'فشل في إضافة المنتج: ${e.toString()}',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
      rethrow;
    } finally {
      isUploading.value = false;
    }
  }

  /// تحديث شركة
  Future<void> updateCompany(CompanyModel company) async {
    try {
      isUploading.value = true;
      
      await _firestore.collection('brand_companies').doc(company.id).update(company.toMap());
      
      final index = companies.indexWhere((c) => c.id == company.id);
      if (index != -1) {
        companies[index] = company;
        companies.refresh();
      }
      
      Get.snackbar('✅ نجح', 'تم تحديث الشركة بنجاح', backgroundColor: Colors.green.withOpacity(0.1), colorText: Colors.green);
    } catch (e) {
      debugPrint('خطأ في تحديث الشركة: $e');
    } finally {
      isUploading.value = false;
    }
  }

  /// تحديث منتج
  Future<void> updateProduct(CompanyProductModel product) async {
    try {
      isUploading.value = true;
      
      await _firestore.collection('company_products').doc(product.id).update(product.toMap());
      
      for (var company in companies) {
        final productIndex = company.products.indexWhere((p) => p.id == product.id);
        if (productIndex != -1) {
          company.products[productIndex] = product;
          companies.refresh();
          break;
        }
      }
      
      Get.snackbar('✅ نجح', 'تم تحديث المنتج بنجاح', backgroundColor: Colors.green.withOpacity(0.1), colorText: Colors.green);
    } catch (e) {
      debugPrint('خطأ في تحديث المنتج: $e');
    } finally {
      isUploading.value = false;
    }
  }

  /// حذف شركة (تعطيل فقط)
  Future<void> deleteCompany(String companyId) async {
    try {
      isLoading.value = true;

      // تعطيل الشركة بدلاً من حذفها
      await _firestore.collection('brand_companies').doc(companyId).update({
        'isActive': false,
        'updatedAt': Timestamp.now(),
      });

      // إزالة من القائمة المحلية
      companies.removeWhere((c) => c.id == companyId);

      // إزالة منتجاتها إذا كانت الشركة المختارة
      if (selectedCompany.value?.id == companyId) {
        selectedCompany.value = null;
        products.clear();
        filteredProducts.clear();
      }

      Get.snackbar(
        '✅ نجح',
        'تم حذف الشركة بنجاح',
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );

      debugPrint('تم حذف الشركة: $companyId');
    } catch (e) {
      debugPrint('خطأ في حذف الشركة: $e');
      Get.snackbar(
        'خطأ',
        'فشل في حذف الشركة: ${e.toString()}',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// حذف منتج (تعطيل فقط)
  Future<void> deleteProduct(String productId) async {
    try {
      isLoadingProducts.value = true;

      // تعطيل المنتج بدلاً من حذفه
      await _firestore.collection('company_products').doc(productId).update({
        'isActive': false,
        'updatedAt': Timestamp.now(),
      });

      // إزالة من القائمة المحلية
      products.removeWhere((p) => p.id == productId);
      filterProducts();

      Get.snackbar(
        '✅ نجح',
        'تم حذف المنتج بنجاح',
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );

      debugPrint('تم حذف المنتج: $productId');
    } catch (e) {
      debugPrint('خطأ في حذف المنتج: $e');
      Get.snackbar(
        'خطأ',
        'فشل في حذف المنتج: ${e.toString()}',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    } finally {
      isLoadingProducts.value = false;
    }
  }

  /// تبديل حالة الشركة
  Future<void> toggleCompanyStatus(String companyId, bool isActive) async {
    try {
      await _firestore.collection('brand_companies').doc(companyId).update({
        'isActive': isActive,
        'updatedAt': Timestamp.now(),
      });
      
      final index = companies.indexWhere((c) => c.id == companyId);
      if (index != -1) {
        companies[index] = companies[index].copyWith(isActive: isActive);
        companies.refresh();
      }
      
      Get.snackbar('✅ نجح', isActive ? 'تم تفعيل الشركة' : 'تم إلغاء تفعيل الشركة', backgroundColor: Colors.green.withOpacity(0.1), colorText: Colors.green);
    } catch (e) {
      debugPrint('خطأ في تحديث حالة الشركة: $e');
    }
  }

  /// تبديل حالة المنتج
  Future<void> toggleProductStatus(String productId, bool isActive) async {
    try {
      await _firestore.collection('company_products').doc(productId).update({
        'isActive': isActive,
        'updatedAt': Timestamp.now(),
      });
      
      for (var company in companies) {
        final productIndex = company.products.indexWhere((p) => p.id == productId);
        if (productIndex != -1) {
          company.products[productIndex] = company.products[productIndex].copyWith(isActive: isActive);
          companies.refresh();
          break;
        }
      }
      
      Get.snackbar('✅ نجح', isActive ? 'تم تفعيل المنتج' : 'تم إلغاء تفعيل المنتج', backgroundColor: Colors.green.withOpacity(0.1), colorText: Colors.green);
    } catch (e) {
      debugPrint('خطأ في تحديث حالة المنتج: $e');
    }
  }

  /// رفع صورة إلى Firebase Storage
  Future<String> _uploadImage(Uint8List imageBytes, String folder) async {
    final String fileName = '${const Uuid().v4()}.jpg';
    final Reference ref = _storage.ref().child('$folder/$fileName');
    
    final UploadTask uploadTask = ref.putData(imageBytes);
    final TaskSnapshot taskSnapshot = await uploadTask;
    
    return await taskSnapshot.ref.getDownloadURL();
  }

  /// رفع صورة إلى Firebase Storage (دالة عامة)
  Future<String> uploadImage(Uint8List imageBytes, String folder) async {
    try {
      isUploading.value = true;
      return await _uploadImage(imageBytes, folder);
    } catch (e) {
      debugPrint('خطأ في رفع الصورة: $e');
      rethrow;
    } finally {
      isUploading.value = false;
    }
  }

  /// رفع صورة من File إلى Firebase Storage
  Future<String> uploadImageFromFile(File imageFile) async {
    try {
      isUploading.value = true;
      final Uint8List imageBytes = await imageFile.readAsBytes();
      return await _uploadImage(imageBytes, 'company_products');
    } catch (e) {
      debugPrint('خطأ في رفع الصورة: $e');
      rethrow;
    } finally {
      isUploading.value = false;
    }
  }

  /// اختيار صورة من المعرض أو الكاميرا
  Future<Uint8List?> pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: source);
      
      if (pickedFile != null) {
        return await pickedFile.readAsBytes();
      }
      return null;
    } catch (e) {
      debugPrint('خطأ في اختيار الصورة: $e');
      Get.snackbar(
        'خطأ',
        'فشل في اختيار الصورة: ${e.toString()}',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
      return null;
    }
  }

  /// تعيين الشركة المختارة
  void setSelectedCompany(CompanyModel? company) {
    debugPrint("🏢 تم اختيار الشركة: ${company?.nameAr ?? 'null'}");
    debugPrint("   البلد: '${company?.country ?? 'غير محدد'}'");
    selectedCompany.value = company;
    selectedProduct.value = null; // مسح المنتج المختار
    
    // تحميل منتجات الشركة المختارة
    if (company != null) {
      loadProductsByCompany(company.id);
    }
  }

  /// تعيين المنتج المختار
  void setSelectedProduct(CompanyProductModel? product) {
    selectedProduct.value = product;
  }

  /// البحث في الشركات
  List<CompanyModel> searchCompanies(String query) {
    if (query.isEmpty) return companies;
    
    return companies.where((company) =>
        company.nameAr.toLowerCase().contains(query.toLowerCase()) ||
        company.nameEn.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  /// تحديث البحث
  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  /// تحديث الفئة المختارة
  void updateSelectedCategory(String category) {
    selectedCategory.value = category;
  }

  /// مسح الاختيارات
  void clearSelections() {
    selectedCompany.value = null;
    selectedProduct.value = null;
    searchQuery.value = '';
    selectedCategory.value = '';
  }

  /// الحصول على الفئات المتاحة
  List<String> getAvailableCategories() {
    final Set<String> categories = {};
    for (final product in products) {
      if (product.category.isNotEmpty) {
        categories.add(product.category);
      }
    }
    return categories.toList()..sort();
  }

  /// استدعاء تحميل الشركات
  Future<void> fetchCompanies() async {
    await loadCompanies();
  }

  @override
  void onClose() {
    // تنظيف الموارد
    companies.clear();
    products.clear();
    filteredProducts.clear();
    super.onClose();
  }
}