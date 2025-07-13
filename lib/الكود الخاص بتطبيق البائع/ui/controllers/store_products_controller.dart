import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_storage/get_storage.dart';
import '../../../Model/SellerModel.dart';
import '../../addItem/editProducts/controllers/edit_product_controller.dart';
import '../../../XXX/xxx_firebase.dart';
import 'retail_cart_controller.dart';
import '../pages/product_details_page.dart';

enum ProductViewType { grid, list, compact, detailed }

class StoreProductsController extends GetxController {
  /// تحديث نطاق السعر بشكل آمن
  void setPriceRange(RangeValues values) {
    // تأكد أن القيم ضمن النطاق الصحيح
    final double min = minPrice.value;
    final double max = maxPrice.value;
    double start = values.start.clamp(min, max);
    double end = values.end.clamp(min, max);
    // لا تسمح بأن يكون الحد الأدنى أكبر من الحد الأقصى
    if (start > end) {
      final temp = start;
      start = end;
      end = temp;
    }
    currentMinPrice.value = start;
    currentMaxPrice.value = end;
    priceRange.value = RangeValues(start, end);
    _filterProducts();
  }

  final SellerModel store;

  StoreProductsController({required this.store});

  // تخزين محلي للمفضلة
  final GetStorage _storage = GetStorage();

  // متغيرات الحالة
  final RxList<Map<String, dynamic>> allProducts = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> filteredProducts =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isGridView = true.obs;
  final RxString selectedCategory = 'الكل'.obs;
  final RxList<String> categories = <String>['الكل'].obs;

  // متحكمات البحث والفلاتر
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  final RxString searchQuery = ''.obs;
  final RxString sortBy = 'الأحدث'.obs;
  final RxBool showFilters = false.obs;
  final RxBool showFavoritesOnly = false.obs;
  final RxBool showDiscountedOnly = false.obs;
  final RxDouble minRating = 0.0.obs;
  final RxString currentSort = 'الأحدث'.obs;

  // مميزات جديدة
  final RxList<String> favoriteProducts = <String>[].obs;
  final RxMap<String, double> productRatings = <String, double>{}.obs;
  final RxString voiceSearchQuery = ''.obs;
  final RxBool isVoiceSearching = false.obs;
  final RxList<String> searchSuggestions = <String>[].obs;

  // نظام المقارنة المحسن
  final RxList<Map<String, dynamic>> compareProducts =
      <Map<String, dynamic>>[].obs;
  final int maxCompareItems = 3;

  // فلاتر السعر
  final RxDouble minPrice = 0.0.obs;
  final RxDouble maxPrice =
      4000.0.obs; // Initialize maxPrice to 1000 to match RangeSlider
  final RxDouble currentMinPrice = 0.0.obs;
  final RxDouble currentMaxPrice =
      2000.0.obs; // Initialize currentMaxPrice to 1000 to match RangeSlider

  // New properties for product view and filters
  final Rx<ProductViewType> productViewType = ProductViewType.grid.obs;
  final Rx<RangeValues> priceRange = const RangeValues(0, 1000).obs;

  // فلاتر جديدة
  final RxString selectedCountry = 'كل الدول'.obs;
  // استخدم قائمة الدول الموحدة من EditProductController
  final List<String> countryOptions =
      [
        'كل الدول',
        ...EditProductController.countryOfOriginOptions.entries
            .map((e) => e.value['ar']!)
            .toSet(),
      ].toList();
  final RxString selectedQuality = 'الكل'.obs;
  final List<String> qualityOptions =
      ['الكل', 'ممتاز', 'جيد جداً', 'جيد', 'مقبول'].obs;
  final RxString selectedProductType = 'الكل'.obs;
  final List<String> productTypeOptions = ['الكل', 'تجاري', 'أصلي'].obs;
  final RxBool filterOnOffer = false.obs;

  // تتبع المنتجات في السلة
  final RxInt totalProductsInCart = 0.obs;

  // متغير لمنع الضغط المتكرر على أزرار السلة (يمنع التجميد بسبب الضغط السريع)
  final RxBool isProcessingCart = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadProducts();
    _updateCartCount();
    _loadFavoritesFromStorage(); // تحميل المفضلة من التخزين المحلي
    _loadCompareList(); // تحميل قائمة المقارنة من التخزين المحلي

    // مراقبة تغييرات البحث
    searchController.addListener(() {
      searchQuery.value = searchController.text;
      _filterProducts();
    });

    // مراقبة تغييرات الفلاتر
    ever(selectedCategory, (_) => _filterProducts());
    ever(sortBy, (_) => _filterProducts());
    ever(currentMinPrice, (_) => _filterProducts());
    ever(currentMaxPrice, (_) => _filterProducts());
    ever(showFavoritesOnly, (_) => _filterProducts());
    ever(showDiscountedOnly, (_) => _filterProducts());
    ever(minRating, (_) => _filterProducts());
    ever(selectedCountry, (_) => _filterProducts());
    ever(selectedQuality, (_) => _filterProducts());
    ever(selectedProductType, (_) => _filterProducts());

    // تحديث عدد المنتجات في السلة كل ثانية
    Timer.periodic(Duration(seconds: 1), (_) => _updateCartCount());
  }

  @override
  void onClose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.onClose();
  }

  /// تحميل منتجات المتجر
  Future<void> loadProducts() async {
    try {
      isLoading.value = true;
      debugPrint('🔄 بدء تحميل منتجات المتجر: ${store.shopName}');
      debugPrint('🔍 البحث عن منتجات البائع UID: ${store.uid}');
      debugPrint('🗂️ البحث في مجموعة: ${FirebaseX.itemsCollection}');
      debugPrint(
        '🏪 معلومات المتجر: اسم=${store.shopName}, نوع=${store.sellerType}, ID=${store.uid}',
      );

      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance
              .collection(FirebaseX.itemsCollection)
              .where('uidAdd', isEqualTo: store.uid)
              .where('addedBySellerType', isEqualTo: 'wholesale')
              .get();

      final List<Map<String, dynamic>> products = [];
      final Set<String> categorySet = {'الكل'};

      debugPrint('📊 تم العثور على ${snapshot.docs.length} مستند');

      // إذا لم نجد منتجات، جرب بدون فلتر نوع البائع
      if (snapshot.docs.isEmpty) {
        debugPrint(
          '⚠️ لا توجد منتجات مع فلتر نوع البائع، المحاولة بدون فلتر...',
        );
        final fallbackSnapshot =
            await FirebaseFirestore.instance
                .collection(FirebaseX.itemsCollection)
                .where('uidAdd', isEqualTo: store.uid)
                .get();
        debugPrint(
          '📊 الاستعلام الاحتياطي وجد ${fallbackSnapshot.docs.length} مستند',
        );

        for (var doc in fallbackSnapshot.docs) {
          final data = doc.data();
          data['id'] = doc.id;

          debugPrint(
            '📝 منتج احتياطي: ${data['nameOfItem']} - UID: ${data['uidAdd']} - نوع البائع: ${data['addedBySellerType']}',
          );

          products.add(data);

          // إضافة الفئة إلى قائمة الفئات
          final category = data['selectedMainCategoryNameAr'] as String?;
          if (category != null && category.isNotEmpty) {
            categorySet.add(category);
          }
        }
      } else {
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;

          debugPrint(
            '📝 منتج: ${data['nameOfItem']} - UID: ${data['uidAdd']} - نوع البائع: ${data['addedBySellerType']}',
          );

          products.add(data);

          // إضافة الفئة إلى قائمة الفئات
          final category = data['selectedMainCategoryNameAr'] as String?;
          if (category != null && category.isNotEmpty) {
            categorySet.add(category);
          }
        }
      }

      debugPrint('📦 إجمالي المنتجات المعالجة: ${products.length}');
      debugPrint('🏷️ الفئات الموجودة: ${categorySet.join(', ')}');

      allProducts.value = products;
      categories.value = categorySet.toList();

      // تحديد نطاق الأسعار
      if (products.isNotEmpty) {
        final prices =
            products
                .map(
                  (p) =>
                      double.tryParse(p['priceOfItem']?.toString() ?? '0') ??
                      0.0,
                )
                .where((price) => price > 0)
                .toList();

        if (prices.isNotEmpty) {
          minPrice.value = 0.0;
          maxPrice.value = prices.reduce((a, b) => a > b ? a : b);

          // اضبط currentMinPrice وcurrentMaxPrice وpriceRange حسب النطاق الجديد
          currentMinPrice.value = minPrice.value;
          currentMaxPrice.value = maxPrice.value;
          priceRange.value = RangeValues(minPrice.value, maxPrice.value);
        }
      }

      _filterProducts();

      debugPrint(
        '✅ تم تحميل ${products.length} منتج من متجر ${store.shopName}',
      );
      debugPrint('📊 الفئات المتاحة: ${categories.join(', ')}');
    } catch (e) {
      debugPrint('❌ خطأ في تحميل منتجات المتجر: $e');
      Get.snackbar(
        'خطأ',
        'فشل في تحميل المنتجات',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// تصفية المنتجات
  void _filterProducts() {
    // منطق AND: المنتج يجب أن يحقق كل الفلاتر النشطة ليظهر
    List<Map<String, dynamic>> filtered =
        allProducts.where((product) {
          // فلتر البحث
          if (searchQuery.value.isNotEmpty) {
            final name = product['nameOfItem']?.toString().toLowerCase() ?? '';
            final description =
                product['descriptionOfItem']?.toString().toLowerCase() ?? '';
            final query = searchQuery.value.toLowerCase();
            if (!(name.contains(query) || description.contains(query))) {
              return false;
            }
          }
          // فلتر الفئة (يعرض كل منتج ينتمي لهذا القسم الرئيسي)
          if (selectedCategory.value != 'الكل') {
            final String? mainCategoryId =
                product['mainCategoryId']?.toString();
            debugPrint(
              'فلتر القسم الرئيسي: selectedCategory=${selectedCategory.value} | mainCategoryId=$mainCategoryId | اسم المنتج=${product['nameOfItem']}',
            );
            if (mainCategoryId == null || mainCategoryId.isEmpty) {
              debugPrint('❌ المنتج لا يحتوي على mainCategoryId');
              return false;
            }
            if (mainCategoryId != selectedCategory.value) {
              debugPrint('❌ mainCategoryId لا يطابق القسم المختار');
              return false;
            }
            debugPrint('✅ المنتج يطابق القسم الرئيسي');
          }
          // فلتر الدولة (دعم الاسم أو الكود)
          if (selectedCountry.value != 'كل الدول') {
            String? filterCountryCode;
            // إذا كانت القيمة كود دولة (حرفين)
            if (EditProductController.countryOfOriginOptions.containsKey(
              selectedCountry.value,
            )) {
              filterCountryCode = selectedCountry.value;
            } else {
              // ابحث عن الكود من الاسم العربي
              final match = EditProductController.countryOfOriginOptions.entries
                  .firstWhere(
                    (e) => e.value['ar'] == selectedCountry.value,
                    orElse: () => const MapEntry('', {'ar': '', 'en': ''}),
                  );
              filterCountryCode = match.key.isNotEmpty ? match.key : null;
            }
            final productCountryCode =
                product['countryOfOrigin']?.toString() ?? '';
            if (filterCountryCode == null) return false;
            if (productCountryCode != filterCountryCode) return false;
          }
          // فلتر السعر
          final price =
              double.tryParse(product['priceOfItem']?.toString() ?? '0') ?? 0.0;
          if (price < currentMinPrice.value || price > currentMaxPrice.value) {
            return false;
          }
          // فلتر الجودة
          if (selectedQuality.value != 'الكل') {
            if ((product['qualityGrade']?.toString() ?? '') !=
                selectedQuality.value) {
              return false;
            }
          }
          // فلتر نوع المنتج (تحويل من العربي إلى الكود)
          if (selectedProductType.value != 'الكل') {
            String? typeKey;
            if (selectedProductType.value == 'أصلي') {
              typeKey = 'original';
            } else if (selectedProductType.value == 'تجاري') {
              typeKey = 'commercial';
            } else {
              typeKey = selectedProductType.value;
            }
            if ((product['itemCondition']?.toString() ?? '') != typeKey) {
              return false;
            }
          }
          return true;
        }).toList();

    // فقط الترتيب
    _sortProducts(filtered);

    filteredProducts.value = filtered;
    debugPrint('عدد المنتجات بعد منطق AND للفلاتر: ${filtered.length}');
  }

  /// ترتيب المنتجات
  void _sortProducts(List<Map<String, dynamic>> products) {
    switch (sortBy.value) {
      case 'الأحدث':
        products.sort((a, b) {
          final aTime =
              a['createdAt'] as Timestamp? ?? a['timestamp'] as Timestamp?;
          final bTime =
              b['createdAt'] as Timestamp? ?? b['timestamp'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });
        break;
      case 'الأقدم':
        products.sort((a, b) {
          final aTime =
              a['createdAt'] as Timestamp? ?? a['timestamp'] as Timestamp?;
          final bTime =
              b['createdAt'] as Timestamp? ?? b['timestamp'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return aTime.compareTo(bTime);
        });
        break;
      case 'السعر: من الأقل للأعلى':
        products.sort((a, b) {
          final aPrice =
              double.tryParse(a['priceOfItem']?.toString() ?? '0') ?? 0.0;
          final bPrice =
              double.tryParse(b['priceOfItem']?.toString() ?? '0') ?? 0.0;
          return aPrice.compareTo(bPrice);
        });
        break;
      case 'السعر: من الأعلى للأقل':
        products.sort((a, b) {
          final aPrice =
              double.tryParse(a['priceOfItem']?.toString() ?? '0') ?? 0.0;
          final bPrice =
              double.tryParse(b['priceOfItem']?.toString() ?? '0') ?? 0.0;
          return bPrice.compareTo(aPrice);
        });
        break;
      case 'الاسم: أ-ي':
        products.sort((a, b) {
          final aName = a['nameOfItem']?.toString() ?? '';
          final bName = b['nameOfItem']?.toString() ?? '';
          return aName.compareTo(bName);
        });
        break;
      case 'الاسم: ي-أ':
        products.sort((a, b) {
          final aName = a['nameOfItem']?.toString() ?? '';
          final bName = b['nameOfItem']?.toString() ?? '';
          return bName.compareTo(aName);
        });
        break;
    }
  }

  /// تبديل عرض الفلاتر
  void toggleFilters() {
    showFilters.value = !showFilters.value;
  }

  /// مسح الفلاتر
  void clearFilters() {
    searchController.clear();
    selectedCategory.value = 'الكل';
    currentMinPrice.value = minPrice.value;
    currentMaxPrice.value = maxPrice.value;
    sortBy.value = 'الأحدث';
    showFavoritesOnly.value = false;
    showDiscountedOnly.value = false;
    minRating.value = 0.0;
    selectedCountry.value = 'كل الدول';
    selectedQuality.value = 'الكل';
    selectedProductType.value = 'الكل';
    showFilters.value = false;
  }

  /// التحديث
  @override
  Future<void> refresh() async {
    await loadProducts();
  }

  /// التحقق من وجود فلاتر نشطة
  bool get hasFilters {
    return searchQuery.value.isNotEmpty ||
        selectedCategory.value != 'الكل' ||
        currentMinPrice.value != minPrice.value ||
        currentMaxPrice.value != maxPrice.value ||
        sortBy.value != 'الأحدث' ||
        showFavoritesOnly.value ||
        showDiscountedOnly.value ||
        minRating.value > 0.0 ||
        selectedCountry.value != 'كل الدول' ||
        selectedQuality.value != 'الكل' ||
        selectedProductType.value != 'الكل';
  }

  /// عرض تفاصيل المنتج
  void showProductDetails(Map<String, dynamic> product) {
    Get.to(
      () => const ProductDetailsPage(),
      arguments: {'product': product, 'store': store},
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 300),
    );
  }

  /// تحديث عدد المنتجات في السلة
  void _updateCartCount() {
    try {
      final cartController = Get.find<RetailCartController>();
      totalProductsInCart.value = cartController.itemCount;
    } catch (e) {
      totalProductsInCart.value = 0;
    }
  }

  /// إضافة منتج إلى السلة
  void addToCart(Map<String, dynamic> product) {
    if (isProcessingCart.value) return;

    try {
      isProcessingCart.value = true;
      final cartController = Get.find<RetailCartController>();
      cartController.addToCart(product, store);

      // تحديث عداد السلة فقط دون إعادة بناء الصفحة بالكامل
      _updateCartCount();
    } catch (e) {
      // إذا لم يكن Controller مسجل، قم بتسجيله
      Get.put(RetailCartController());
      final cartController = Get.find<RetailCartController>();
      cartController.addToCart(product, store);
      _updateCartCount();
    } finally {
      isProcessingCart.value = false;
    }
  }

  /// التحكم في حالة معالجة السلة
  void setProcessingCart(bool processing) {
    isProcessingCart.value = processing;
  }

  /// التحقق من حالة معالجة السلة
  bool get isCartProcessing => isProcessingCart.value;

  // ===========================================
  // 🎯 نظام التقييمات والمراجعات
  // ===========================================

  void rateProduct(String productId, double rating) {
    productRatings[productId] = rating;
    // هنا يمكن إرسال التقييم إلى Firebase
    update(['rating_$productId']);
  }

  double getProductRating(String productId) {
    return productRatings[productId] ??
        (3.5 + (productId.hashCode % 20) / 10); // تقييم واقعي متنوع
  }

  int getReviewsCount(String productId) {
    return 15 + (productId.hashCode % 85); // عدد مراجعات واقعي
  }

  // ===========================================
  // 🎯 نظام المفضلة المتقدم
  // ===========================================

  /// إضافة منتج لقائمة المفضلة
  void toggleFavorite(String productId) {
    if (isFavorite(productId)) {
      removeFromFavorites(productId);
    } else {
      addToFavorites(productId);
    }
  }

  bool isFavorite(String productId) {
    return favoriteProducts.contains(productId);
  }

  void addToFavorites(String productId) {
    if (!favoriteProducts.contains(productId)) {
      favoriteProducts.add(productId);
      _saveFavoritesToStorage(); // حفظ التغييرات محلياً
    }
    update(['favorites_$productId']); // تحديث محدود للمفضلة فقط
  }

  void removeFromFavorites(String productId) {
    favoriteProducts.remove(productId);
    _saveFavoritesToStorage(); // حفظ التغييرات محلياً
    update(['favorites_$productId']); // تحديث محدود للمفضلة فقط
  }

  void clearAllFavorites() {
    favoriteProducts.clear();
    _saveFavoritesToStorage(); // حفظ التغييرات محلياً
    update();
  }

  int get favoritesCount => favoriteProducts.length;

  // ===========================================
  // 💾 نظام حفظ المفضلة محلياً باستخدام GetStorage
  // ===========================================

  /// تحميل المفضلة من التخزين المحلي
  void _loadFavoritesFromStorage() {
    try {
      final favoritesKey = 'favorites_${store.uid}'; // مفتاح خاص لكل متجر
      final favoritesList = _storage.read<List<dynamic>>(favoritesKey);

      if (favoritesList != null) {
        favoriteProducts.value = favoritesList.cast<String>();
        debugPrint(
          '✅ تم تحميل ${favoriteProducts.length} منتج مفضل من التخزين المحلي',
        );
      } else {
        debugPrint('📝 لا توجد مفضلة محفوظة مسبقاً');
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحميل المفضلة من التخزين المحلي: $e');
    }
    update();
  }

  /// حفظ المفضلة في التخزين المحلي
  void _saveFavoritesToStorage() {
    try {
      final favoritesKey = 'favorites_${store.uid}'; // مفتاح خاص لكل متجر
      _storage.write(favoritesKey, favoriteProducts.toList());
      debugPrint(
        '✅ تم حفظ ${favoriteProducts.length} منتج مفضل في التخزين المحلي',
      );
    } catch (e) {
      debugPrint('❌ خطأ في حفظ المفضلة في التخزين المحلي: $e');
    }
  }

  // ===========================================
  // 🎯 البحث الصوتي والاقتراحات
  // ===========================================

  void startVoiceSearch() {
    isVoiceSearching.value = true;

    // محاكاة البحث الصوتي
    Future.delayed(Duration(seconds: 3), () {
      isVoiceSearching.value = false;
      // استخدام اسم منتج عشوائي من المنتجات المتاحة
      if (allProducts.isNotEmpty) {
        final randomProduct = allProducts[allProducts.length ~/ 2];
        voiceSearchQuery.value = randomProduct['nameOfItem'] ?? '';
        searchController.text = voiceSearchQuery.value;
        searchProducts();
      }
    });
  }

  void searchProducts() {
    generateSearchSuggestions();
    _filterProducts();
  }

  void generateSearchSuggestions() {
    if (searchController.text.isNotEmpty) {
      searchSuggestions.clear();
      Set<String> uniqueSuggestions = {};

      for (var product in allProducts) {
        String name = product['nameOfItem']?.toString() ?? '';
        String category =
            product['selectedMainCategoryNameAr']?.toString() ?? '';

        if (name.toLowerCase().contains(searchController.text.toLowerCase())) {
          uniqueSuggestions.add(name);
        }
        if (category.toLowerCase().contains(
          searchController.text.toLowerCase(),
        )) {
          uniqueSuggestions.add(category);
        }
      }

      searchSuggestions.value = uniqueSuggestions.take(5).toList();
    } else {
      searchSuggestions.clear();
    }
    update();
  }

  void selectSuggestion(String suggestion) {
    searchController.text = suggestion;
    searchQuery.value = suggestion;
    searchSuggestions.clear();
    _filterProducts();
  }

  // ===========================================
  // 🎯 فلاتر متقدمة
  // ===========================================

  /// تبديل فلتر المفضلة
  void toggleFavoritesFilter() {
    showFavoritesOnly.value = !showFavoritesOnly.value;
  }

  /// تبديل فلتر الخصومات
  void toggleDiscountFilter() {
    showDiscountedOnly.value = !showDiscountedOnly.value;
  }

  /// تحديث نطاق السعر
  void updatePriceRange(double min, double max) {
    currentMinPrice.value = min;
    currentMaxPrice.value = max;
  }

  /// تعيين الحد الأدنى للتقييم
  void setMinRating(double rating) {
    minRating.value = rating;
  }

  /// فلترة المنتجات حسب الفئة
  void filterByCategory(String category) {
    selectedCategory.value = category;
  }

  /// ترتيب المنتجات
  void sortProducts(String sortType) {
    sortBy.value = sortType;
    _sortProducts(filteredProducts);
  }

  /// تطبيق الفلاتر
  void applyFilters() {
    _filterProducts();
  }

  /// مسح جميع الفلاتر
  void clearAllFilters() {
    searchController.clear();
    selectedCategory.value = '';
    currentMinPrice.value = minPrice.value;
    currentMaxPrice.value = maxPrice.value;
    sortBy.value = 'الأحدث';
    showFavoritesOnly.value = false;
    showDiscountedOnly.value = false;
    minRating.value = 0.0;
    showFilters.value = false;
  }

  /// التحقق من وجود فلاتر نشطة
  bool hasActiveFilters() {
    return searchController.text.isNotEmpty ||
        selectedCategory.value.isNotEmpty ||
        currentMinPrice.value != minPrice.value ||
        currentMaxPrice.value != maxPrice.value ||
        sortBy.value != 'الأحدث' ||
        showFavoritesOnly.value ||
        showDiscountedOnly.value ||
        minRating.value > 0.0;
  }

  /// الحصول على متوسط السعر
  double getAveragePrice() {
    if (filteredProducts.isEmpty) return 0.0;
    double total = 0.0;
    for (var product in filteredProducts) {
      final price =
          double.tryParse(product['priceOfItem']?.toString() ?? '0') ?? 0.0;
      total += price;
    }
    return total / filteredProducts.length;
  }

  /// الحصول على إجمالي قيمة المخزون
  double getTotalInventoryValue() {
    double total = 0.0;
    for (var product in filteredProducts) {
      final price =
          double.tryParse(product['priceOfItem']?.toString() ?? '0') ?? 0.0;
      final quantity =
          int.tryParse(product['quantity']?.toString() ?? '1') ?? 1;
      total += price * quantity;
    }
    return total;
  }

  /// الحصول على الربح المتوقع
  double getExpectedProfit() {
    double profit = 0.0;
    for (var product in filteredProducts) {
      final price =
          double.tryParse(product['priceOfItem']?.toString() ?? '0') ?? 0.0;
      final cost =
          double.tryParse(product['cost']?.toString() ?? '0') ?? price * 0.7;
      final quantity =
          int.tryParse(product['quantity']?.toString() ?? '1') ?? 1;
      profit += (price - cost) * quantity;
    }
    return profit;
  }

  /// الحصول على نسبة الخصم
  double getDiscountPercentage(double originalPrice) {
    final discountedPrice = getDiscountedPrice(originalPrice);
    if (discountedPrice >= originalPrice) return 0.0;
    return ((originalPrice - discountedPrice) / originalPrice) * 100;
  }

  /// الحصول على الكوبونات الصالحة
  List<Map<String, dynamic>> getValidCoupons() {
    return [
      {
        'code': 'SAVE10',
        'discount': 10.0,
        'type': 'percentage',
        'description': 'خصم 10% على جميع المنتجات',
        'minAmount': 50.0,
      },
      {
        'code': 'FLAT20',
        'discount': 20.0,
        'type': 'fixed',
        'description': 'خصم 20 ريال على الطلبات',
        'minAmount': 100.0,
      },
      {
        'code': 'WELCOME15',
        'discount': 15.0,
        'type': 'percentage',
        'description': 'خصم ترحيبي 15%',
        'minAmount': 75.0,
      },
    ];
  }

  // ===========================================
  // 🎯 مقارنة المنتجات المحسنة
  // ===========================================

  void addToCompare(Map<String, dynamic> product) {
    if (compareProducts.length < maxCompareItems &&
        !isInCompare(product['id'] ?? '')) {
      compareProducts.add(product);
      _saveCompareList(); // حفظ قائمة المقارنة
      update(['compare', 'compare_${product['id']}']); // تحديث UI المخصص
    }
  }

  void removeFromCompare(Map<String, dynamic> product) {
    compareProducts.removeWhere((p) => p['id'] == product['id']);
    _saveCompareList(); // حفظ قائمة المقارنة
    update(['compare', 'compare_${product['id']}']); // تحديث UI المخصص
  }

  bool isInCompare(String productId) {
    return compareProducts.any((p) => p['id'] == productId);
  }

  /// مسح جميع منتجات المقارنة
  void clearCompare() {
    compareProducts.clear();
    _saveCompareList(); // حفظ القائمة الفارغة
    update(['compare']);
  }

  /// حفظ قائمة المقارنة في التخزين المحلي
  void _saveCompareList() {
    try {
      final List<Map<String, dynamic>> compareData =
          compareProducts.map((product) {
            return {
              'id': product['id'],
              'nameOfItem': product['nameOfItem'],
              'priceOfItem': product['priceOfItem'],
              'url': product['url'],
              'manyImages': product['manyImages'],
              'storeId': store.uid, // حفظ معرف المتجر
            };
          }).toList();

      _storage.write('compare_products_${store.uid}', compareData);
      debugPrint('✅ تم حفظ ${compareProducts.length} منتج في قائمة المقارنة');
    } catch (e) {
      debugPrint('❌ خطأ في حفظ قائمة المقارنة: $e');
    }
  }

  /// تحميل قائمة المقارنة من التخزين المحلي
  void _loadCompareList() {
    try {
      final List<dynamic>? savedCompare = _storage.read(
        'compare_products_${store.uid}',
      );
      if (savedCompare != null && savedCompare.isNotEmpty) {
        compareProducts.clear();
        for (var item in savedCompare) {
          if (item is Map<String, dynamic>) {
            compareProducts.add(Map<String, dynamic>.from(item));
          }
        }
        debugPrint(
          '✅ تم تحميل ${compareProducts.length} منتج من قائمة المقارنة المحفوظة',
        );
        update(['compare']); // تحديث UI
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحميل قائمة المقارنة: $e');
    }
  }

  void showComparisonDialog() {
    if (compareProducts.isEmpty) {
      Get.snackbar(
        'تنبيه',
        'لا توجد منتجات للمقارنة',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    Get.dialog(
      AlertDialog(
        title: Text('مقارنة المنتجات (${compareProducts.length})'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              children:
                  compareProducts.map((product) {
                    final price =
                        double.tryParse(
                          product['priceOfItem']?.toString() ?? '0',
                        ) ??
                        0.0;
                    final rating = getProductRating(product['id'] ?? '');
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(product['nameOfItem'] ?? 'غير محدد'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('السعر: ${price.toInt()} ريال'),
                            Text('التقييم: ${rating.toStringAsFixed(1)} ⭐'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => removeFromCompare(product),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => clearCompare(),
            child: Text('مسح الكل', style: TextStyle(color: Colors.red)),
          ),
          TextButton(onPressed: () => Get.back(), child: Text('إغلاق')),
        ],
      ),
    );
  }

  // ===========================================
  // 🎯 نظام الكوبونات والخصومات
  // ===========================================

  final RxString appliedCoupon = ''.obs;
  final RxDouble couponDiscount = 0.0.obs;
  final RxDouble quickRatingValue = 3.0.obs;

  void applyCoupon(String couponCode) {
    Map<String, double> validCoupons = {
      'welcome10': 0.10,
      'save20': 0.20,
      'summer15': 0.15,
      'newuser': 0.25,
      'loyal5': 0.05,
    };

    String code = couponCode.toLowerCase().trim();
    if (validCoupons.containsKey(code)) {
      appliedCoupon.value = couponCode.toUpperCase();
      couponDiscount.value = validCoupons[code]!;
    }
    update(['coupon']);
  }

  void removeCoupon() {
    appliedCoupon.value = '';
    couponDiscount.value = 0.0;
    update(['coupon']);
  }

  void setQuickRatingValue(double value) => quickRatingValue.value = value;

  double getDiscountedPrice(double originalPrice) {
    if (couponDiscount.value > 0) {
      return originalPrice * (1 - couponDiscount.value);
    }
    return originalPrice;
  }

  // ===========================================
  // 🎯 إحصائيات وتحليلات
  // ===========================================

  Map<String, int> get categoryStats {
    Map<String, int> stats = {};
    for (var product in allProducts) {
      String category = product['selectedMainCategoryNameAr'] ?? 'غير محدد';
      stats[category] = (stats[category] ?? 0) + 1;
    }
    return stats;
  }

  String get mostPopularCategory {
    var stats = categoryStats;
    if (stats.isEmpty) return 'لا توجد فئات';
    return stats.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  double get averagePrice {
    if (allProducts.isEmpty) return 0.0;
    double total = allProducts.fold(0.0, (sum, product) {
      return sum +
          (double.tryParse(product['priceOfItem']?.toString() ?? '0') ?? 0.0);
    });
    return total / allProducts.length;
  }

  /// حساب إجمالي قيمة المخزون
  double get totalInventoryValue {
    return allProducts.fold(0.0, (sum, product) {
      final price =
          double.tryParse(product['priceOfItem']?.toString() ?? '0') ?? 0.0;
      return sum + price;
    });
  }

  /// حساب إجمالي تكلفة المخزون
  double get totalInventoryCost {
    return allProducts.fold(0.0, (sum, product) {
      final cost =
          double.tryParse(product['costPrice']?.toString() ?? '0') ?? 0.0;
      return sum + cost;
    });
  }

  /// حساب الربح المتوقع
  double get expectedProfit {
    return totalInventoryValue - totalInventoryCost;
  }

  /// حساب هامش الربح
  double get profitMargin {
    return totalInventoryValue > 0
        ? (expectedProfit / totalInventoryValue) * 100
        : 0.0;
  }

  /// مشاركة منتج
  void shareProduct(Map<String, dynamic> product) {
    String productName = product['nameOfItem'] ?? 'منتج رائع';
    String price = product['priceOfItem']?.toString() ?? '0';
    String storeName = store.shopName;

    String shareText =
        '''
🛍️ منتج رائع من $storeName

📦 $productName
💰 $price جنيه
⭐ ${getProductRating(product['id'] ?? '').toStringAsFixed(1)} من 5
👥 ${getReviewsCount(product['id'] ?? '')} تقييم

#منتجات_عالية_الجودة #تسوق_آمن #$storeName
    '''.trim();

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'مشاركة المنتج',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 15),
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(shareText, style: TextStyle(fontSize: 14)),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareButton('واتساب', Icons.message, Colors.green),
                _buildShareButton('فيسبوك', Icons.facebook, Colors.blue),
                _buildShareButton(
                  'تويتر',
                  Icons.alternate_email,
                  Colors.lightBlue,
                ),
                _buildShareButton('نسخ', Icons.copy, Colors.grey),
              ],
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildShareButton(String name, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        Get.back();
        Get.snackbar(
          'تم النسخ',
          'تم نسخ رابط المنتج للمشاركة على $name',
          backgroundColor: color.withOpacity(0.9),
          colorText: Colors.white,
        );
      },
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 5),
          Text(name, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  /// الانتقال إلى صفحة السلة
  void goToCart() {
    Get.toNamed('/retail-cart');
  }

  /// تبديل العرض بين الشبكة والقائمة
  void toggleView() {
    isGridView.value = !isGridView.value;
  }

  // New methods for product view and filters
  void changeViewType(ProductViewType type) {
    productViewType.value = type;
  }

  void requestStockNotification(Map<String, dynamic> product) {
    Get.snackbar(
      'طلب إشعار توفر',
      'سيتم إعلامك عند توفر ${product['nameOfItem']}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blueAccent,
      colorText: Colors.white,
    );
  }

  void setCountry(String country) {
    selectedCountry.value = country;
    _filterProducts();
  }

  void setQuality(String quality) {
    selectedQuality.value = quality;
    _filterProducts();
  }

  void toggleOnOffer() {
    filterOnOffer.value = !filterOnOffer.value;
    _filterProducts();
  }
}
