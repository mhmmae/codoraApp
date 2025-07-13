import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../../../Model/SellerModel.dart';
import 'package:url_launcher/url_launcher.dart';

class WholesaleMarketController extends GetxController 
    with GetSingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Animation Controllers
  late AnimationController animationController;
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;
  
  // قوائم المتاجر
  final RxList<SellerModel> allStores = <SellerModel>[].obs;
  final RxList<SellerModel> filteredStores = <SellerModel>[].obs;
  final RxList<String> categories = <String>[].obs;
  
  // حالة التحميل والانيميشن
  final RxBool isLoading = false.obs;
  final RxBool isSearching = false.obs;
  final RxBool showFilters = false.obs;
  
  // نص البحث والفلاتر
  final RxString searchText = ''.obs;
  final RxString selectedCategory = ''.obs;
  final RxString selectedLocation = ''.obs;
  final RxString sortBy = 'name'.obs; // name, rating, newest
  
  // حالة العرض
  final RxBool isGridView = false.obs;
  final RxInt selectedStoreIndex = (-1).obs;
  
  // مفاتيح التحكم
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

  @override
  void onInit() {
    super.onInit();
    _initializeAnimations();
    loadWholesaleStores();
    _setupSearchListener();
  }

  void _initializeAnimations() {
    animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOut,
    ));
    
    slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOutBack,
    ));
  }

  void _setupSearchListener() {
    searchController.addListener(() {
      if (searchController.text != searchText.value) {
        searchText.value = searchController.text;
        _debounceSearch();
      }
    });
  }

  Timer? _debounceTimer;
  void _debounceSearch() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      applyFilters();
    });
  }

  /// تحميل جميع متاجر الجملة من Firebase
  Future<void> loadWholesaleStores() async {
    try {
      isLoading.value = true;
      
      debugPrint('🔄 بدء تحميل متاجر الجملة...');
      
      final QuerySnapshot querySnapshot = await _firestore
          .collection('Sellercodora')
          .where('sellerType', isEqualTo: 'wholesale')
          .where('isActiveBySeller', isEqualTo: true)
          .get();
      
      debugPrint('📊 تم العثور على ${querySnapshot.docs.length} متجر جملة');
      
      final List<SellerModel> stores = [];
      final Set<String> categoriesSet = <String>{};
      
      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final store = SellerModel.fromMap(data, doc.id);
          
          if (store.shopName.isNotEmpty && store.sellerType == 'wholesale') {
            stores.add(store);
            if (store.shopCategory.isNotEmpty) {
              categoriesSet.add(store.shopCategory);
            }
            debugPrint('✅ تم إضافة متجر: ${store.shopName}');
          }
        } catch (e) {
          debugPrint('❌ خطأ في معالجة وثيقة ${doc.id}: $e');
        }
      }
      
      // ترتيب المتاجر
      _sortStores(stores);
      
      allStores.value = stores;
      filteredStores.value = stores;
      categories.value = categoriesSet.toList()..sort();
      
      // بدء الانيميشن
      animationController.forward();
      
      debugPrint('✅ تم تحميل ${stores.length} متجر جملة بنجاح');
      
    } catch (e) {
      debugPrint('❌ خطأ في تحميل متاجر الجملة: $e');
      _showErrorSnackbar('حدث خطأ أثناء تحميل المتاجر');
    } finally {
      isLoading.value = false;
    }
  }

  /// تطبيق الفلاتر المتقدمة
  void applyFilters() {
    List<SellerModel> filtered = List.from(allStores);
    
    // فلتر البحث النصي
    if (searchText.value.isNotEmpty) {
      filtered = filtered.where((store) {
        final query = searchText.value.toLowerCase();
        return store.shopName.toLowerCase().contains(query) ||
               store.sellerName.toLowerCase().contains(query) ||
               store.shopCategory.toLowerCase().contains(query) ||
               (store.shopDescription?.toLowerCase().contains(query) ?? false) ||
               (store.shopAddressText?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
    
    // فلتر الفئة
    if (selectedCategory.value.isNotEmpty) {
      filtered = filtered.where((store) => 
        store.shopCategory == selectedCategory.value).toList();
    }
    
    // فلتر الموقع
    if (selectedLocation.value.isNotEmpty) {
      filtered = filtered.where((store) => 
        store.shopAddressText?.contains(selectedLocation.value) ?? false).toList();
    }
    
    // ترتيب النتائج
    _sortStores(filtered);
    
    filteredStores.value = filtered;
    
    debugPrint('🔍 تطبيق الفلاتر - النتائج: ${filtered.length}');
  }

  void _sortStores(List<SellerModel> stores) {
    switch (sortBy.value) {
      case 'name':
        stores.sort((a, b) => a.shopName.compareTo(b.shopName));
        break;
      case 'category':
        stores.sort((a, b) => a.shopCategory.compareTo(b.shopCategory));
        break;
      case 'newest':
        // يمكن إضافة ترتيب حسب تاريخ الإنشاء إذا كان متوفراً
        break;
    }
  }

  // وظائف التحكم في الفلاتر
  void toggleFilters() {
    showFilters.value = !showFilters.value;
  }

  void selectCategory(String category) {
    selectedCategory.value = category == selectedCategory.value ? '' : category;
    applyFilters();
  }

  void setSortBy(String sort) {
    sortBy.value = sort;
    applyFilters();
  }

  void toggleViewMode() {
    isGridView.value = !isGridView.value;
  }

  void clearFilters() {
    searchController.clear();
    searchText.value = '';
    selectedCategory.value = '';
    selectedLocation.value = '';
    sortBy.value = 'name';
    applyFilters();
  }

  // وظائف التفاعل مع المتاجر
  void selectStore(int index) {
    selectedStoreIndex.value = index;
  }

  Future<void> callStore(String phoneNumber) async {
    final url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      _showErrorSnackbar('لا يمكن فتح تطبيق الهاتف');
    }
  }

  Future<void> openLocation(String? address) async {
    if (address == null || address.isEmpty) {
      _showErrorSnackbar('العنوان غير متوفر');
      return;
    }
    
    final url = Uri.parse('https://maps.google.com/?q=${Uri.encodeComponent(address)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _showErrorSnackbar('لا يمكن فتح الخرائط');
    }
  }

  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'خطأ',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.withOpacity(0.1),
      colorText: Colors.red[800],
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  void _showSuccessSnackbar(String message) {
    Get.snackbar(
      'تم بنجاح',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.withOpacity(0.1),
      colorText: Colors.green[800],
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  // Getters
  int get storesCount => allStores.length;
  int get filteredStoresCount => filteredStores.length;
  bool get hasFilters => searchText.value.isNotEmpty || 
                        selectedCategory.value.isNotEmpty || 
                        selectedLocation.value.isNotEmpty;

  @override
  Future<void> refresh() async {
    await loadWholesaleStores();
  }

  @override
  void onClose() {
    animationController.dispose();
    searchController.dispose();
    searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.onClose();
    debugPrint('🧹 تم تنظيف WholesaleMarketController');
  }
} 