import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:collection';

// تأكد من أن مسار الاستيراد صحيح وأن الملف موجود
// استبدل هذا بالمسار الصحيح لشاشة التفاصيل في مشروعك
import '../معلومات الكود/CodeGroupDetailBinding.dart';
import '../معلومات الكود/CodeGroupDetailScreen.dart';

// --- Enums ---
enum SortOption {
  none, // الافتراضي
  alphabeticalAsc, // أبجدي تصاعدي
  alphabeticalDesc, // أبجدي تنازلي
  importanceDesc, // الأكثر مبيعًا/أهمية تنازلي
  importanceAsc, // الأكثر مبيعًا/أهمية تصاعدي
}

enum ViewType { grid, list }
// --- نهاية Enums ---

class CodeGroupsController extends GetxController {
  static const String favoriteButtonId = 'favoriteButtonId'; // <-- نقل للداخل وتغيير إلى static const

// --- حالة متفاعلة (Reactive State) ---
  var isLoading = true.obs;
  var isLoadingCategories = true.obs;
  var _originalHighImportanceItems = <Map<String, dynamic>>[];
  var _originalRandomItems = <Map<String, dynamic>>[];
  var filteredHighImportanceItems = <Map<String, dynamic>>[].obs;
  var filteredRandomItems = <Map<String, dynamic>>[].obs;
  var currentImageIndex = 0.obs;
  var searchQuery = ''.obs;
  var selectedCategory = 'الكل'.obs;
  var availableCategories = <String>['الكل'].obs;
  var isSearchVisible = false.obs;
  var favoriteItemIds = <String>{}.obs; // Set لتخزين معرفات المفضلة
  var currentSortOption = SortOption.none.obs; // حالة الترتيب
  var currentViewType = ViewType.grid.obs; // حالة نوع العرض
  DocumentSnapshot? _lastDocumentSnapshot; // متغيرات Pagination (إذا تم إضافتها لاحقاً)
  var isLoadingMore = false.obs;
  var hasMoreItems = true.obs;
  late ScrollController scrollController; // متغير Pagination
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance; // <-- إضافة instance للمصادق



  // --- موارد Controller ---
  Timer? imageTimer;
  final PageController pageController = PageController();
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  final GetStorage storage = GetStorage(); // صندوق التخزين المحلي

  // --- دورة حياة Controller ---
  @override
  void onInit() {
    super.onInit();
    _loadPreferences();
    scrollController = ScrollController()..addListener(_scrollListener); // تفعيل Pagination لاحقًا
// تحميل المفضلة ونوع العرض
    fetchData();
    // الاستماع للتغيرات لتطبيق الفلاتر
    debounce(searchQuery, (_) => _applyFilters(), time: const Duration(milliseconds: 300));
    ever(selectedCategory, (_) => _applyFilters());
    ever(currentSortOption, (_) => _applyFilters()); // تطبيق الفلتر عند تغيير الترتيب
  }

  @override
  void onClose() {
    imageTimer?.cancel();
    pageController.dispose();
    searchController.dispose();
    searchFocusNode.dispose();
    super.onClose();
  }

  // --- تحميل/حفظ التفضيلات ---
  void _loadPreferences() {
    // تحميل المفضلة
    final storedFavorites = storage.read<List>('favorites') ?? [];
    favoriteItemIds.assignAll(Set<String>.from(storedFavorites.map((e) => e.toString())));
    // إضافة تصنيف المفضلة إذا لم يكن موجودًا (مع التحقق لتجنب الإضافة المتكررة)
    if (!availableCategories.contains('المفضلة')) {
      availableCategories.insert(1, 'المفضلة');
    }

    // تحميل نوع العرض
    final storedViewType = storage.read<String>('viewType');
    if (storedViewType == ViewType.list.name) { // استخدام .name للمقارنة الآمنة
      currentViewType.value = ViewType.list;
    } else {
      currentViewType.value = ViewType.grid; // الافتراضي
    }
  }

  void _saveFavorites() {
    storage.write('favorites', favoriteItemIds.toList());
  }

  void _saveViewType() {
    storage.write('viewType', currentViewType.value.name); // حفظ اسم الـ enum
  }
  // --- نهاية تحميل/حفظ التفضيلات ---


  // --- إدارة المفضلة ---
  bool isFavorite(String itemId) {
    // التأكد من أن itemId ليس فارغًا أو القيمة الافتراضية
    return itemId.isNotEmpty && !itemId.startsWith('invalid_') && favoriteItemIds.contains(itemId);
  }

  void toggleFavorite(String itemId) {
    // التأكد من أن itemId صالح قبل التغيير
    if (itemId.isEmpty || itemId.startsWith('invalid_')) return;

    if (favoriteItemIds.contains(itemId)) {
      favoriteItemIds.remove(itemId);
    } else {
      favoriteItemIds.add(itemId);
    }
    _saveFavorites(); // حفظ التغيير
    // تحديث الفلتر إذا كان المستخدم في قسم المفضلة
    if (selectedCategory.value == 'المفضلة') {
      _applyFilters();
    }
    update([favoriteButtonId]); // لتحديث الواجهة فورًا (مثل شكل القلب)
  }
  // --- نهاية إدارة المفضلة ---


  // --- المشاركة ---
  // --- المشاركة (مع تعديل لمعالجة الخطأ وإزالة sharePositionOrigin) ---
  Future<void> shareCodeGroup(Map<String, dynamic> item, BuildContext context) async { // أبقينا context حاليًا لكن قد لا نحتاجه
    final String codeName = item['codeName'] ?? 'كود غير مسمى';
    // يمكنك تخصيص النص الذي تتم مشاركته
    final String shareText = 'ألق نظرة على هذا الكود: $codeName';
    // يمكنك إضافة رابط إذا كان متاحًا
    // final String url = item['detailsUrl'] ?? item['link'] ?? '';
    // final String textToShare = url.isNotEmpty ? '$shareText\n$url' : shareText;

    debugPrint("Attempting to share: $shareText"); // طباعة النص للمساعدة في التصحيح

    try {
      // --- ▼▼▼ إزالة حساب sharePositionOrigin ▼▼▼ ---
      // final box = context.findRenderObject() as RenderBox?;
      // final sharePositionOrigin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
      // --- ▲▲▲ نهاية الإزالة ▲▲▲ ---

      // استدعاء Share.share بدون sharePositionOrigin
      await Share.share(
        shareText, // أو textToShare
        subject: 'مشاركة مجموعة كود: $codeName', // عنوان للمشاركة عبر البريد
        // sharePositionOrigin: sharePositionOrigin, // <-- تم إزالة هذا السطر
      );
      debugPrint("Sharing seems successful.");

    } catch (e, stackTrace) { // <-- إضافة stackTrace هنا
      debugPrint("Share Error: $e"); // طباعة الخطأ المحدد
      debugPrint("Share StackTrace: $stackTrace"); // <-- طباعة تتبع المكدس
      Get.snackbar(
          "خطأ في المشاركة",
          "حدث خطأ أثناء محاولة المشاركة. يرجى المحاولة مرة أخرى.", // رسالة أوضح قليلاً
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange[800], // لون مختلف للتحذير
          colorText: Colors.white
      );
    }
  }
  // --- نهاية المشاركة ---
  // --- نهاية المشاركة ---


  // --- التحكم في البحث ونوع العرض والترتيب ---
  void toggleSearchVisibility() {
    isSearchVisible.value = !isSearchVisible.value;
    if (isSearchVisible.value) {
      // تأخير بسيط لضمان بناء الحقل قبل طلب التركيز
      Future.delayed(const Duration(milliseconds: 100), () {
        searchFocusNode.requestFocus();
      });
    } else {
      // مسح البحث وإخفاء لوحة المفاتيح عند الإخفاء
      clearSearch();
    }
  }

  void changeViewType(ViewType newType) {
    if (currentViewType.value != newType) {
      currentViewType.value = newType;
      _saveViewType(); // حفظ التفضيل الجديد
    }
  }

  void changeSortOption(SortOption newOption) {
    if (currentSortOption.value != newOption) {
      currentSortOption.value = newOption;
      // ever() ستقوم باستدعاء _applyFilters
    }
  }
  // --- نهاية التحكم ---


  // --- جلب البيانات وتطبيق الفلاتر/الترتيب ---
  Future<void> fetchData() async {
    try {
      isLoading.value = true;
      isLoadingCategories.value = true;
      final snapshot =
      await FirebaseFirestore.instance.collection('codeGroups').get();
      // تحويل البيانات والتأكد من وجود حقل 'id'
      final allItems = snapshot.docs
          .map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // إضافة معرف المستند إلى البيانات
        return data;
      })
          .where((item) => item['id'] != null) // التأكد من وجود ID
          .toList();


      // --- استخلاص وتحديث التصنيفات ---
      final categories = LinkedHashSet<String>.from(
          allItems.map((item) => item['category']?.toString() ?? 'غير مصنف')
      ).toList();
      List<String> finalCategories = ['الكل'];
      // إضافة "المفضلة" بشكل دائم كخيار
      if (!finalCategories.contains('المفضلة')) {
        finalCategories.insert(1, 'المفضلة');
      }
      finalCategories.addAll(categories); // إضافة باقي التصنيفات
      // استخدام Set لإزالة أي تكرار محتمل ثم تحويلها إلى قائمة
      availableCategories.assignAll(LinkedHashSet<String>.from(finalCategories).toList());
      isLoadingCategories.value = false;
      // --- نهاية تحديث التصنيفات ---


      // تخزين القوائم الأصلية (مع التأكد من أن 'importance' هو رقم)
      _originalHighImportanceItems = allItems
          .where((item) => (item['importance'] is num) && ((item['importance'] as num) == 9 || (item['importance'] as num) == 10))
          .toList();
      _originalRandomItems = List.from(allItems)..shuffle(); // خلط أولي

      // تطبيق الفلاتر والترتيب الأولي
      _applyFilters();

    } catch (error, stackTrace) {
      Get.snackbar( "خطأ في جلب البيانات", "حدث خطأ: $error", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      debugPrint("Firestore Fetch Error: $error");
      debugPrint("Stack Trace: $stackTrace");
      isLoadingCategories.value = false;
      _originalHighImportanceItems = [];
      _originalRandomItems = [];
      _applyFilters(); // عرض حالة فارغة
    } finally {
      isLoading.value = false;
    }
  }

  void _applyFilters() {
    isLoading.value = true;
    List<Map<String, dynamic>> tempHighImportance;
    List<Map<String, dynamic>> tempRandom;

    // 1. الفلترة بالتصنيف/المفضلة
    if (selectedCategory.value == 'المفضلة') {
      tempHighImportance = _originalHighImportanceItems.where((item) => favoriteItemIds.contains(item['id']?.toString())).toList();
      tempRandom = _originalRandomItems.where((item) => favoriteItemIds.contains(item['id']?.toString())).toList();
    } else if (selectedCategory.value == 'الكل') {
      tempHighImportance = List.from(_originalHighImportanceItems);
      tempRandom = List.from(_originalRandomItems);
    } else {
      tempHighImportance = _originalHighImportanceItems.where((item) => (item['category']?.toString() ?? 'غير مصنف') == selectedCategory.value).toList();
      tempRandom = _originalRandomItems.where((item) => (item['category']?.toString() ?? 'غير مصنف') == selectedCategory.value).toList();
    }

    // 2. الفلترة بالبحث
    if (searchQuery.value.isNotEmpty) {
      String lowerCaseQuery = searchQuery.value.toLowerCase();
      // التأكد من أن codeName هو String قبل الفلترة
      tempHighImportance = tempHighImportance.where((item) => (item['codeName'] as String?)?.toLowerCase().contains(lowerCaseQuery) ?? false).toList();
      tempRandom = tempRandom.where((item) => (item['codeName'] as String?)?.toLowerCase().contains(lowerCaseQuery) ?? false).toList();
    }

    // 3. تطبيق الترتيب
    final sortOption = currentSortOption.value;
    if (sortOption != SortOption.none) {
      // استخدام دالة المقارنة للترتيب
      tempHighImportance.sort((a, b) => _compareItems(a, b, sortOption));
      tempRandom.sort((a, b) => _compareItems(a, b, sortOption));
    } else if (_originalRandomItems.isNotEmpty) {
      // اختياري: إذا أردت إعادة الخلط عند اختيار "بلا ترتيب" بعد ترتيب سابق
      // tempRandom.shuffle(Random(DateTime.now().millisecondsSinceEpoch));
    }

    // تحديث القوائم المتفاعلة للعرض
    filteredHighImportanceItems.assignAll(tempHighImportance);
    filteredRandomItems.assignAll(tempRandom);

    // تحديث حالة PageView
    if (filteredHighImportanceItems.isEmpty || currentImageIndex.value >= filteredHighImportanceItems.length) {
      currentImageIndex.value = 0;
      imageTimer?.cancel(); // إيقاف المؤقت إذا لم تعد هناك عناصر هامة
    } else if (imageTimer == null || !imageTimer!.isActive) {
      startImageTimer(); // إعادة تشغيل المؤقت إذا كان متوقفًا وهناك عناصر
    }

    isLoading.value = false;
  }

  // دالة مساعدة لمقارنة العناصر للترتيب
  int _compareItems(Map<String, dynamic> a, Map<String, dynamic> b, SortOption sortOption) {
    switch (sortOption) {
      case SortOption.alphabeticalAsc:
      // مقارنة codeName كسلاسل نصية مع التعامل مع null
        return (a['codeName']?.toString() ?? '').compareTo(b['codeName']?.toString() ?? '');
      case SortOption.alphabeticalDesc:
        return (b['codeName']?.toString() ?? '').compareTo(a['codeName']?.toString() ?? '');
      case SortOption.importanceDesc: // الأكثر مبيعًا/أهمية
      // مقارنة importance كأرقام مع التعامل مع null وإعطاء قيمة افتراضية 0
        return (b['importance'] as num? ?? 0).compareTo(a['importance'] as num? ?? 0);
      case SortOption.importanceAsc: // الأقل مبيعًا/أهمية
        return (a['importance'] as num? ?? 0).compareTo(b['importance'] as num? ?? 0);
      case SortOption.none:
      return 0; // لا تغيير في الترتيب
    }
  }
  // --- نهاية جلب البيانات وتطبيق الفلاتر/الترتيب ---


  // --- الدوال المساعدة والتحكم في الواجهة ---
  void startImageTimer() {
    imageTimer?.cancel();
    // التأكد من وجود عناصر وعملاء قبل بدء المؤقت
    if (filteredHighImportanceItems.isNotEmpty && pageController.hasClients) {
      imageTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        // تحقق مرة أخرى داخل المؤقت
        if (filteredHighImportanceItems.isNotEmpty && pageController.hasClients) {
          int nextPage = (currentImageIndex.value + 1) % filteredHighImportanceItems.length;
          pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 400), // تقليل المدة قليلاً
            curve: Curves.easeInOut,
          );
        } else {
          timer.cancel(); // إيقاف المؤقت إذا اختفت العناصر
        }
      });
    }
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
    // debounce سيقوم باستدعاء _applyFilters
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    searchFocusNode.unfocus(); // إخفاء لوحة المفاتيح
    // isSearchVisible سيتم تحديثه تلقائيًا إذا كان مرتبطًا بـ Obx
    // ولكن من الأفضل تحديثه هنا لضمان إخفاء الحقل
    isSearchVisible.value = false;
  }

  void selectCategory(String category) {
    if (selectedCategory.value != category) {
      selectedCategory.value = category;
      // ever() ستقوم باستدعاء _applyFilters
    }
  }

  Future<void> refreshData() async {
    // يمكنك اختيار إعادة تعيين الفلاتر هنا أو لا
    // selectedCategory.value = 'الكل';
    // currentSortOption.value = SortOption.none;
    // clearSearch();
    await fetchData(); // جلب البيانات وتطبيق الفلاتر الحالية
  }

  void onPageChanged(int index) {
    // التأكد أن المؤشر ضمن الحدود قبل التحديث
    if (index < filteredHighImportanceItems.length) {
      imageTimer?.cancel(); // إيقاف المؤقت مؤقتًا عند السحب اليدوي
      currentImageIndex.value = index; // تحديث المؤشر المتفاعل
      startImageTimer(); // إعادة تشغيل المؤقت بعد التغيير اليدوي
    }
  }

  void onDotTapped(int index) {
    // التأكد أن المؤشر صالح وأن الـ PageController جاهز
    if (index < filteredHighImportanceItems.length && pageController.hasClients) {
      imageTimer?.cancel(); // إيقاف المؤقت عند النقر
      pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      // لا تحتاج لتحديث currentImageIndex هنا، onPageChanged ستفعل ذلك
      // startImageTimer(); // لا تحتاج لإعادة تشغيله هنا، onPageChanged ستفعل ذلك
    }
  }

  void navigateToDetail(Map<String, dynamic> item) {
    debugPrint(">>> Navigating to detail for: ${item['codeName']}");
    try {
      // استخدام دالة البناء الصحيحة للشاشة
      Get.to(() => CodeGroupDetailScreen(), // <-- تأكد من اسم الشاشة الصحيح
          arguments: item,
          binding: CodeGroupDetailBinding(), // <--- ربط الـ Binding
          transition: Transition.fadeIn); // يمكنك تغيير الانتقال
      debugPrint(">>> Navigation executed.");
    } catch (e, stackTrace) {
      debugPrint(">>> Navigation Error: $e");
      debugPrint(">>> StackTrace: $stackTrace");
      Get.snackbar(
        "خطأ في الانتقال",
        "لا يمكن فتح تفاصيل العنصر: $e",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // دالة مساعدة لترجمة خيار الترتيب إلى نص للعرض
  String getSortOptionText(SortOption option) {
    switch (option) {
      case SortOption.alphabeticalAsc: return 'أبجدي (أ -> ي)';
      case SortOption.alphabeticalDesc: return 'أبجدي (ي -> أ)';
      case SortOption.importanceDesc: return 'الأكثر مبيعًا'; // النص الجديد
      case SortOption.importanceAsc: return 'الأقل مبيعًا';   // النص الجديد
      case SortOption.none:
      return 'بلا ترتيب (افتراضي)';
    }
  }

  // 1. زيادة عداد النسخ
  Future<void> incrementCopyCount(String codeGroupId) async {
    // لا حاجة للتحقق من المستخدم هنا عادةً
    if (codeGroupId.isEmpty || codeGroupId.startsWith('invalid_')) return;
    try {
      final docRef = _firestore.collection('codeGroups').doc(codeGroupId);
      // استخدام update لزيادة العداد (أكثر أمانًا من جلب المستند ثم تحديثه)
      await docRef.update({'copyCount': FieldValue.increment(1)});
      debugPrint("Copy count incremented for $codeGroupId");
    } catch (e, s) {
      debugPrint("Error incrementing copy count for $codeGroupId: $e \n $s");
    }
  }

  // 2. إضافة / تحديث تقييم وتعليق
// --- إضافة / تحديث تقييم وتعليق (مع جلب الاسم من Usercodora) ---
  Future<bool> addReview({
    required String codeGroupId,
    required double rating,
    String? comment,
    String? existingReviewId,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      Get.snackbar("خطأ", "يجب تسجيل الدخول للمتابعة.", icon: Icon(Icons.login, color: Colors.white), backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
    if (codeGroupId.isEmpty || codeGroupId.startsWith('invalid_')) return false;

    // --- ▼▼▼ جلب اسم المستخدم من مجموعة Usercodora ▼▼▼ ---
    String userNameToShow = 'مستخدم'; // قيمة افتراضية أولية
    try {
      // جلب مستند المستخدم من مجموعة Usercodora باستخدام userId
      final userDocSnapshot = await _firestore.collection('Usercodora').doc(currentUser.uid).get();

      // التحقق من وجود المستند و حقل الاسم
      if (userDocSnapshot.exists && userDocSnapshot.data() != null) {
        final userData = userDocSnapshot.data()!;
        // محاولة الحصول على الاسم، استخدام fallback إذا لم يوجد أو لم يكن String
        userNameToShow = (userData['name'] as String?)?.isNotEmpty ?? false
            ? userData['name']
            : (currentUser.email ?? 'مستخدم'); // استخدام الإيميل كـ fallback إذا لم يوجد اسم
      } else {
        // إذا لم يوجد المستند، استخدم الإيميل أو القيمة الافتراضية
        userNameToShow = currentUser.email ?? 'مستخدم';
        debugPrint("User document not found in Usercodora for ${currentUser.uid}");
      }
    } catch (e, s) {
      // في حالة حدوث خطأ أثناء جلب الاسم، استخدم قيمة احتياطية وسجل الخطأ
      debugPrint("Error fetching user name from Usercodora: $e\n$s");
      userNameToShow = currentUser.email ?? 'مستخدم'; // استخدام الإيميل أو القيمة الافتراضية عند الخطأ
    }
    // --- ▲▲▲ نهاية جلب اسم المستخدم ▲▲▲ ---


    try {
      // تجميع بيانات التقييم مع الاسم الذي تم جلبه
      final reviewData = {
        'userId': currentUser.uid,
        'rating': rating,
        'comment': comment?.trim().isEmpty ?? true ? null : comment!.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        // --- ▼▼▼ استخدام الاسم الذي تم جلبه هنا ▼▼▼ ---
        'userName': userNameToShow, // اسم المستخدم للعرض
        // --- ▲▲▲ ---
      };

      // مرجع لمجموعة التقييمات الفرعية لهذا الكود
      final reviewsCollection = _firestore.collection('codeGroups').doc(codeGroupId).collection('reviews');

      // ... (باقي منطق تحديث أو إضافة التقييم كما هو) ...
      if (existingReviewId != null && existingReviewId.isNotEmpty) {
        // ... تحديث التقييم الموجود ...
        await reviewsCollection.doc(existingReviewId).update(reviewData..['updatedAt'] = FieldValue.serverTimestamp());
        debugPrint("Review updated: $existingReviewId");
        Get.snackbar("تم التحديث", "تم تحديث تقييمك بنجاح.", /*...*/);
      } else {
        // ... البحث عن تقييم سابق وتحديثه أو إضافة جديد ...
        final existingDocs = await reviewsCollection.where('userId', isEqualTo: currentUser.uid).limit(1).get();
        if (existingDocs.docs.isNotEmpty) {
          String docIdToUpdate = existingDocs.docs.first.id;
          await reviewsCollection.doc(docIdToUpdate).update(reviewData..['updatedAt'] = FieldValue.serverTimestamp());
          debugPrint("Review already existed, updated instead: $docIdToUpdate");
          Get.snackbar("تم التحديث", "لقد قمت بتقييم هذا العنصر سابقًا، تم تحديث تقييمك.", /*...*/);
        } else {
          final newReviewRef = await reviewsCollection.add(reviewData);
          debugPrint("Review added: ${newReviewRef.id}");
          Get.snackbar("شكراً لك", "تم إضافة تقييمك بنجاح.", /*...*/);
        }
      }

      // **تذكير:** قم بتنفيذ تحديث المتوسط باستخدام Cloud Function!
      debugPrint("Reminder: Update average rating via Cloud Function is recommended.");

      return true; // نجاح

    } catch (e, s) {
      debugPrint("Error saving review for $codeGroupId: $e \n $s");
      Get.snackbar("خطأ", "فشل حفظ التقييم. حاول مرة أخرى.", /*...*/);
      return false; // فشل
    }
  }

  // 3. الإبلاغ عن كود
  Future<bool> reportCodeGroup({
    required String codeGroupId,
    required String codeGroupName,
    required String reason,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      Get.snackbar("خطأ", "يجب تسجيل الدخول للإبلاغ.", /*...*/);
      return false;
    }
    if (codeGroupId.isEmpty || codeGroupId.startsWith('invalid_')) return false;
    if (reason.trim().isEmpty) {
      Get.snackbar("مطلوب", "يرجى كتابة سبب الإبلاغ.", icon: Icon(Icons.warning_amber, color: Colors.white), backgroundColor: Colors.orange[700], colorText: Colors.white);
      return false;
    }

    try {
      final reportData = {
        'codeGroupId': codeGroupId,
        'codeGroupName': codeGroupName,
        'userId': currentUser.uid,
        'userIdentifier': currentUser.email ?? currentUser.phoneNumber ?? 'N/A', // لتحديد المستخدم بشكل أسهل
        'reason': reason.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending', // حالة أولية للبلاغ
      };

      // إضافة البلاغ إلى مجموعة التقارير الرئيسية
      await _firestore.collection('reports').add(reportData);

      Get.snackbar("تم الاستلام", "شكراً لك، تم إرسال بلاغك وسيتم مراجعته.", icon: Icon(Icons.check_circle, color: Colors.white), backgroundColor: Colors.blue, colorText: Colors.white);
      debugPrint("Report submitted for $codeGroupId by ${currentUser.uid}");
      return true; // نجاح

    } catch (e, s) {
      debugPrint("Error submitting report for $codeGroupId: $e \n $s");
      Get.snackbar("خطأ", "حدث خطأ أثناء إرسال البلاغ.", /*...*/);
      return false; // فشل
    }
  }



  void _scrollListener() {
    // لا تقم بأي شيء إذا لم نقم بتفعيل Pagination بعد
    if (_lastDocumentSnapshot == null && _originalRandomItems.isEmpty) return;

    // تحقق مما إذا وصلنا إلى نهاية القائمة تقريبًا
    // scrollController.position.pixels: الموقع الحالي للتمرير
    // scrollController.position.maxScrollExtent: أقصى مسافة يمكن التمرير إليها
    // -300: هامش (threshold) قبل النهاية الفعلية لبدء التحميل المبكر
    if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 300 &&
        hasMoreItems.value &&      // التأكد من أن هناك المزيد من العناصر لجلبها
        !isLoadingMore.value) {    // التأكد من أننا لا نقوم بالتحميل حاليًا
      debugPrint(">>> Scroll Listener: Reached end, loading more...");
      // loadMoreItems(); // <--- قم بإزالة التعليق عن هذه الدالة عندما تطبق Pagination
    }
  }






// --- نهاية الدوال المساعدة والتحكم في الواجهة ---

} // نهاية الكنترولر