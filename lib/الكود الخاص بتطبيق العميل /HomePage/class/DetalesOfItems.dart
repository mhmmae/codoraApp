import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

import '../../../Model/model_item.dart';
import '../../../Model/model_offer_item.dart';
import '../../../Model/review_model.dart';
import '../../../XXX/xxx_firebase.dart';
import '../../bottonBar/botonBar.dart';

import '../Get-Controllar/GetChoseTheTypeOfItem.dart';
import 'DetailsOfItemScreen.dart';



class AddItemDetailsController extends GetxController {
  final String itemType;
  final Uint8List? mainImageBytes;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  final TextEditingController oldPriceController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Dropdown states for 'Item'
  static const Map<String, String> _itemConditionOptions = {'original': 'أصلي', 'commercial': 'تجاري'};
  final RxnString selectedConditionKey = RxnString(null);
  List<DropdownMenuItem<String>> get conditionDropdownItems => _itemConditionOptions.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList();
  void updateCondition(String? key) => selectedConditionKey.value = key;

  static const List<int> _qualityGradeOptions = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
  static const Map<int, String> _qualityGradeDisplay = {1: '1', 2: '2', 3: '3', 4: '4', 5: '5', 6: '6', 7: '7', 8: '8', 9: '9', 10: '10'};
  final RxnInt selectedQualityGrade = RxnInt(null);
  List<DropdownMenuItem<int>> get qualityDropdownItems => _qualityGradeOptions.map((g) => DropdownMenuItem(value: g, child: Text(_qualityGradeDisplay[g] ?? g.toString()))).toList();
  void updateQualityGrade(int? grade) => selectedQualityGrade.value = grade;

  static const Map<String, String> _countryOfOriginOptions = {'CN': 'الصين', 'US': 'أمريكا', 'DE': 'ألمانيا', /*...*/ 'OTHER': 'أخرى'};
  final RxnString selectedCountryKey = RxnString(null);
  List<DropdownMenuItem<String>> get countryDropdownItems => _countryOfOriginOptions.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList();
  void updateCountry(String? key) => selectedCountryKey.value = key;

  late AddItemSubtypeController _subtypeController;
  // late GetAddManyImage _manyImageController;
  // late GetChooseVideo _videoController;

  final RxBool isUploading = false.obs;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  AddItemDetailsController({required this.itemType, this.mainImageBytes}) {
    assert(itemType == FirebaseX.itemsCollection || itemType == FirebaseX.offersCollection);
    if (mainImageBytes == null) debugPrint("Warning: AddItemDetailsController - Main image bytes are null.");
  }

  @override
  void onInit() {
    super.onInit();
    try {
      _subtypeController = Get.find<AddItemSubtypeController>();
      // _manyImageController = Get.find<GetAddManyImage>();
      // _videoController = Get.find<GetChooseVideo>();
      _subtypeController.clearSelection(); // Reset selections
      // _manyImageController.clearImages();
      // _videoController.deleteVideo();
    } catch (e) {
      _showSnackbar('خطأ', 'فشل تهيئة الصفحة.', Colors.red); // <<-- تعريب
      debugPrint("Dependency Error in AddItemDetails: $e");
      isUploading.value = true; // Disable button if init fails
    }
    debugPrint("AddItemDetailsController ($itemType) Initialized.");
  }

  @override
  void onClose() {
    nameController.dispose(); priceController.dispose(); descriptionController.dispose(); rateController.dispose(); oldPriceController.dispose();
    debugPrint("AddItemDetailsController ($itemType) Disposed.");
    super.onClose();
  }

  void _resetLocalFields() {
    nameController.clear(); priceController.clear(); descriptionController.clear(); rateController.clear(); oldPriceController.clear();
    selectedConditionKey.value = null; selectedQualityGrade.value = null; selectedCountryKey.value = null;
    formKey.currentState?.reset();
    debugPrint("AddItemDetails Local Fields Reset.");
  }

  Future<void> saveItemData(BuildContext context) async {
    if (_currentUserId == null) return _showSnackbar("خطأ", "لم تسجل الدخول.", Colors.red);
    if (mainImageBytes == null) return _showSnackbar("خطأ", "اختر صورة.", Colors.orange);
    if (!(formKey.currentState?.validate() ?? false)) return _showSnackbar("تنبيه", "أكمل الحقول.", Colors.orange); // <<-- تعريب

    String? selectedSubtype;
    if (itemType == FirebaseX.itemsCollection) {
      selectedSubtype = _subtypeController.selectedSubtypeKey.value;
      if (selectedSubtype == null) return _showSnackbar("تنبيه", "اختر النوع.", Colors.orange);
      if (selectedConditionKey.value == null) return _showSnackbar("تنبيه", "اختر الحالة.", Colors.orange);
      if (selectedQualityGrade.value == null) return _showSnackbar("تنبيه", "اختر الجودة.", Colors.orange);
      if (selectedCountryKey.value == null) return _showSnackbar("تنبيه", "اختر بلد الصنع.", Colors.orange);
    }

    isUploading.value = true;
    try {
      final String newItemId = const Uuid().v4(); String uploadedVideoUrl = 'noVideo'; List<String> uploadedImageUrls = [];

      // --- Upload Video (Placeholder) ---
      // uploadedVideoUrl = await _videoController.uploadVideo(newItemId) ?? 'noVideo';

      // --- Upload Main Image ---
      final mainImagePath = '${FirebaseX.StorgeApp}/$newItemId/main_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference mainImageRef = _storage.ref().child(mainImagePath);
      final TaskSnapshot mainTaskSnapshot = await mainImageRef.putData(mainImageBytes!);
      final String mainImageUrl = await mainTaskSnapshot.ref.getDownloadURL();

      // --- Upload Additional Images (Placeholder) ---
      // uploadedImageUrls = await _manyImageController.saveManyImage(newItemId);

      // --- Prepare Firestore Data ---
      final Map<String, dynamic> dataToSave;
      if (itemType == FirebaseX.itemsCollection) {
        final itemModel = ItemModel(
            id: newItemId, 
            name: nameController.text, 
            description: descriptionController.text, 
            price: double.tryParse(priceController.text) ?? 0.0,
            imageUrl: mainImageUrl, 
            manyImages: uploadedImageUrls, 
            videoUrl: uploadedVideoUrl, 
            typeItem: selectedSubtype!, 
            itemCondition: selectedConditionKey.value, 
            qualityGrade: selectedQualityGrade.value, 
            countryOfOrigin: selectedCountryKey.value, 
            uidAdd: _currentUserId,
            appName: FirebaseX.appName,
            costPrice: 0.0, // قيمة افتراضية لسعر التكلفة
            addedBySellerType: "store_added" // قيمة افتراضية لنوع البائع
            );
        dataToSave = itemModel.toMap();
      } else {
        final offerModel = OfferModel(
            id: newItemId, 
            name: nameController.text, 
            description: descriptionController.text, 
            price: double.tryParse(priceController.text) ?? 0.0,
            oldPrice: double.tryParse(oldPriceController.text) ?? 0.0,
            rate: int.tryParse(rateController.text) ?? 0,
            imageUrl: mainImageUrl, 
            manyImages: uploadedImageUrls, 
            videoUrl: uploadedVideoUrl, 
            uidAdd: _currentUserId,
            appName: FirebaseX.appName,
            costPrice: 0.0, // قيمة افتراضية لسعر التكلفة
            addedBySellerType: "store_added" // قيمة افتراضية لنوع البائع
            );
        dataToSave = offerModel.toMap();
      }

      // --- Save to Firestore ---
      await _firestore.collection(itemType).doc(newItemId).set(dataToSave);

      // --- Cleanup and Navigate ---
      _resetLocalFields(); _subtypeController.clearSelection();
      // _manyImageController.clearImages(); _videoController.deleteVideo();
      isUploading.value = false; _showSnackbar("نجاح", "تمت الإضافة.", Colors.green); // <<-- تعريب
      Get.offAll(() =>  BottomBar(initialIndex: 0));

    } catch (e, s) { isUploading.value = false; _showSnackbar("خطأ", "فشل الحفظ: $e", Colors.red); debugPrint("Save Error: $e\n$s"); } // <<-- تعريب
  }

  void _showSnackbar(String title, String message, Color bg) { Get.snackbar(title, message, snackPosition: SnackPosition.BOTTOM, backgroundColor: bg, colorText: Colors.white, margin: const EdgeInsets.all(10), borderRadius: 8); }
}


// --- إضافة Enum لخيارات الفرز ---
enum ReviewSortOption {
  newest(label: "الأحدث أولاً", firestoreField: "timestamp", descending: true),
  oldest(label: "الأقدم أولاً", firestoreField: "timestamp", descending: false),
  highestRated(label: "الأعلى تقييمًا", firestoreField: "rating", descending: true),
  lowestRated(label: "الأقل تقييمًا", firestoreField: "rating", descending: false);

  const ReviewSortOption({
    required this.label, required this.firestoreField, required this.descending, });
  final String label;
  final String firestoreField;
  final bool descending;
}

class DetailsItemController extends GetxController {
  final String? videoURL;
  VideoPlayerController? videoController;
  final dynamic item; // <-- استقبال نموذج المنتج بالكامل قد يكون أفضل
  final bool isOffer;

  RxBool isInitialized = false.obs;
  RxBool isPlaying = false.obs;
  RxDouble volume = 1.0.obs;
  RxBool isMuted = false.obs;
  RxBool isFullScreen = false.obs;
  Rx<Duration> currentPosition = Duration.zero.obs;
  Rx<Duration> totalDuration = Duration.zero.obs;
  double _lastVolume = 1.0;
  // --- حالة التعليقات والتقييمات ---
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final RxList<ReviewModel> reviews = <ReviewModel>[].obs; // قائمة تفاعلية للتعليقات
  final RxBool isReviewsLoading = true.obs;
  final RxDouble averageRating = 0.0.obs;
  final RxInt reviewCount = 0.obs;
  final String tag; // مطلوب للربط
  final RxBool showAppBarTitle = false.obs;
  late final ScrollController scrollController; // سيتم تهيئته في onInit
  late RxString itemName;
  late RxInt currentPrice;

  // --- حالة التعليقات والتقييمات ---

  // ---!!! حالات جديدة للفرز والإعجاب والردود !!!---
  final Rx<ReviewSortOption> currentReviewSort = ReviewSortOption.newest.obs; // <-- فرز افتراضي
  final RxMap<String, bool> userLikes = <String, bool>{}.obs; // لتخزين حالة إعجاب المستخدم الحالي لكل تعليق (Key=reviewId, Value=true/false)
  final RxMap<String, List<Map<String, dynamic>>> repliesMap = <String, List<Map<String, dynamic>>>{}.obs; // <--- تخزين الردود لكل تعليق
  final RxMap<String, bool> repliesLoadingMap = <String, bool>{}.obs; // <--- تتبع تحميل الردود لكل تعليق
  final RxnString replyingToReviewId = RxnString(null); // <--- لتتبع التعليق الذي يتم الرد عليه
  final TextEditingController replyController = TextEditingController(); // متحكم حقل الرد
  final RxBool isSendingReply = false.obs; // حالة إرسال الرد
  final RxMap<String, int> reviewLikesCount = <String, int>{}.obs;

  // ----------------------------------------------
  DetailsItemController({required this.item,  required this.isOffer})
      : videoURL = item.videoUrl, // تهيئة videoURL من المنتج
        tag = (isOffer ? (item as OfferModel).id : (item as ItemModel).id)
  {
    debugPrint("DetailsItemController created with tag: $tag for item: ${item.name}");
  }

  @override
  void onInit() {
    super.onInit();
    scrollController = ScrollController();
    scrollController.addListener(_scrollListener);
    _initializeVideoPlayer();
    _fetchReviewsAndRating(); // جلب التعليقات والتقييم عند البدء
    _listenToReviewsAndRating(); // <-- تغيير اسم الدالة
    _listenToUserLikes();        // <-- استمع لإعجابات المستخدم
    debugPrint("DetailsItemController onInit for tag: $tag, video: $videoURL");
  }
  Future<void> addReview({ required String productId, required double rating, String? comment}) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      Get.snackbar("خطأ", "يجب تسجيل الدخول لإضافة تقييم.", backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }
    if (rating < 1) { // تأكد من إضافة تقييم نجمة واحدة على الأقل
      Get.snackbar("تنبيه", "الرجاء تحديد تقييم (نجمة واحدة على الأقل).", snackPosition: SnackPosition.BOTTOM);
      return;
    }

    isSendingReply.value = true; // استخدم نفس متغير التحميل مؤقتًا أو أضف isSendingReview

    try {
      // ---!!! 1. جلب بيانات المستخدم من مجموعة "AppUsers" !!!---
      // استخدم الاسم الصحيح للمجموعة من FirebaseX
      final userDocRef = _firestore.collection(FirebaseX.collectionApp).doc(user.uid);
      final userDoc = await userDocRef.get();
      String userName = "مستخدم غير معروف"; // قيمة افتراضية
      String? userImageUrl;                 // قيمة افتراضية

      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data()!;
        // استخدم أسماء الحقول الصحيحة من مستند المستخدم لديك
        userName = userData['name'] as String? ?? userName; // <-- افترض اسم الحقل 'name'
        userImageUrl = userData['url'] as String?;    // <-- افترض اسم الحقل 'url'
        debugPrint("Fetched user data for review: Name=$userName, ImageURL=$userImageUrl");
      } else {
        debugPrint("User document not found for uid: ${user.uid}. Using defaults for review.");
        // يمكنك اختيار عدم السماح بالتعليق إذا لم يكن ملف المستخدم كاملاً
      }
      // ----------------------------------------------------

      // --- 2. بناء النموذج بالبيانات المجلوبة ---
      final newReview = ReviewModel(
        id: '', // Firestore سينشئ ID
        userId: user.uid,
        userName: userName,       // <-- الاسم من Firestore
        userImageUrl: userImageUrl, // <-- الصورة من Firestore
        productId: productId,
        rating: rating,
        comment: (comment != null && comment.trim().isNotEmpty) ? comment.trim() : null,
        timestamp: Timestamp.now(), // الوقت الحالي للإضافة الفورية
      );
      // -----------------------------------------

      // --- 3. الحفظ في Firestore ---
      await _firestore.collection('reviews').add(newReview.toMap()..['timestamp'] = FieldValue.serverTimestamp()); // استخدام Server Timestamp عند الإرسال
      Get.snackbar("نجاح", "شكراً لتقييمك!", backgroundColor: Colors.green, colorText: Colors.white);
      // الواجهة ستتحدث بفضل الـ Stream Listener
    } catch (e) {
      debugPrint("Error adding review: $e");
      Get.snackbar("خطأ", "فشل إرسال التقييم: $e", backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      if (!isClosed) { isSendingReply.value = false; } // إيقاف التحميل
    }
  }

  // (هذه الطريقة الأفضل والأكثر تفاعلية)
  Stream<bool> userLikesStreamForReview(String reviewId) {
    final User? user = _auth.currentUser;
    if (user == null) return Stream.value(false); // المستخدم غير مسجل

    return _firestore
        .collection('reviews').doc(reviewId) // اذهب للمراجعة
        .collection('likes').doc(user.uid)    // ابحث عن مستند بإسم المستخدم الحالي في likes
        .snapshots()                        // استمع للتغيرات
        .map((snapshot) => snapshot.exists) // true إذا كان المستند موجود (معجب)
        .handleError((err) { // معالجة الأخطاء
      debugPrint("Error in userLikesStream for $reviewId: $err");
      return false; // افتراض أنه ليس معجب عند الخطأ
    });
  }
  // -----------------------------------------------------------

  // ---!!! (جديد) دالة للحصول على عدد الإعجابات الحالية للمراجعة !!!---
  // (تعتمد على تحديث reviews أو تحديث reviewLikesCount مباشرة)
  int getLikesCountForReview(String reviewId) {
    // الطريقة الأولى: البحث في القائمة reviews (أبسط لكن قد لا يكون فوريًا بعد toggleLike)
    final review = reviews.firstWhereOrNull((r) => r.id == reviewId);
    return review?.likesCount ?? reviewLikesCount[reviewId] ?? 0; // استخدام قيمة احتياطية من map

    // الطريقة الثانية (إذا قمت بتحديث reviewLikesCount بشكل منفصل):
    // return reviewLikesCount[reviewId] ?? 0;
  }
  // -----------------------------------------------------------


  // ---!!! (جديد) دالة لبدء الرد على تعليق محدد !!!---
  void startReplying(String reviewId) {
    // إذا كان المستخدم يرد بالفعل على هذا التعليق، أغلق حقل الرد
    if (replyingToReviewId.value == reviewId) {
      replyingToReviewId.value = null;
      replyController.clear(); // امسح النص
    } else {
      // إذا كان يرد على تعليق آخر أو لا يرد، افتح الحقل لهذا التعليق
      replyingToReviewId.value = reviewId;
      replyController.clear(); // امسح النص عند فتح حقل جديد
      // يمكنك إضافة منطق لتركيز المؤشر في حقل الإدخال تلقائيًا هنا
      // (يتطلب تمرير FocusNode أو طريقة أخرى)
    }
    debugPrint("Replying to review ID set to: ${replyingToReviewId.value}");
  }
  // -------------------------------------------------


  // --- جلب التعليقات والتقييم (باستخدام stream ويتفاعل مع الفرز) ---
  // --- جلب التعليقات والتقييم (باستخدام stream ويتفاعل مع الفرز) ---
  void _listenToReviewsAndRating() {
    debugPrint("Listening to reviews for product: ${getItemId()} with sort: ${currentReviewSort.value.name}");
    isReviewsLoading.value = true;
    error.value = ''; // مسح الخطأ السابق

    // ---!!! تعديل نوع المتغير query هنا !!!---
    Query<ReviewModel> query = _firestore // <-- تغيير النوع إلى Query<ReviewModel>
        .collection('reviews')
        .withConverter<ReviewModel>( // <--- withConverter يحدد النوع
      fromFirestore: (snapshot, _) => ReviewModel.fromSnapshot(snapshot), // استخدام fromSnapshot المعدل
      toFirestore: (review, _) => review.toMap(),
    )
        .where('productId', isEqualTo: getItemId())
        .orderBy(currentReviewSort.value.firestoreField, descending: currentReviewSort.value.descending);
    // ------------------------------------------

    // إضافة ترتيب ثانوي
    if (currentReviewSort.value.firestoreField != 'timestamp') {
      // عند استخدام withConverter، قد لا يكون من الضروري أو الآمن
      // تعديل نوع Query مرة أخرى. نطبق orderBy على نفس النوع.
      // (عادةً ما يتطلب هذا فهرسًا مناسبًا على أي حال)
      query = query.orderBy('timestamp', descending: true);
    }

    // --- استخدام .snapshots() ---
    // الآن snapshot سيكون QuerySnapshot<ReviewModel>
    query.snapshots().listen((snapshot) {
      try {
        // --- هذا الجزء صحيح الآن بفضل withConverter ---
        reviews.value = snapshot.docs.map((doc) => doc.data()).toList(); // doc.data() يعيد ReviewModel
        // ---------------------------------------------

        // حساب المتوسط والعدد (يبقى كما هو)
        if (reviews.isNotEmpty) {
          double totalRating = reviews.fold(0.0, (sum, item) => sum + item.rating);
          averageRating.value = totalRating / reviews.length;
          reviewCount.value = reviews.length;
        } else { averageRating.value = 0.0; reviewCount.value = 0; }
        isReviewsLoading.value = false;
        debugPrint("Reviews updated. Count: ${reviewCount.value}, Avg: ${averageRating.value.toStringAsFixed(1)}");

      } catch (e, s) {
        debugPrint("Error processing review snapshot data: $e\n$s");
        isReviewsLoading.value = false;
        // يمكنك إظهار خطأ جزئي هنا أو مسح المراجعات
        // reviews.clear(); // مسح المراجعات عند خطأ المعالجة
        error.value = 'خطأ في معالجة بيانات التقييمات.';
      }

    }, onError: (error) {
      debugPrint("Error fetching reviews stream: $error");
      isReviewsLoading.value = false;
      error.value = 'خطأ في جلب التقييمات.'; // <<-- تعريب
      Get.snackbar("خطأ", "فشل في تحميل التقييمات.", colorText: Colors.white, backgroundColor: Colors.red);
    });
  }

  // تأكد من أن لديك RxString error معرف في الـ controller
  final RxString error = ''.obs;

  // --- تغيير خيار الفرز وإعادة الاستماع ---
  void changeReviewSort(ReviewSortOption newSort) {
    if (currentReviewSort.value != newSort) {
      currentReviewSort.value = newSort;
      // إعادة جلب/الاستماع للتعليقات بالترتيب الجديد
      // (الـ Stream سيُحدث الواجهة تلقائياً عند تغير البيانات)
      // يكفي أن _listenToReviewsAndRating تستخدم currentReviewSort.value
      // ولكن نحتاج لطريقة لإعادة تشغيل الاستماع.. الأسهل هو وضع بناء الاستعلام في getter تفاعلي
      // أو استدعاء _listenToReviewsAndRating يدويًا هنا (لكنه قد يؤدي لاشتراكات متعددة إذا لم تتم إدارتها)
      // الحل الأبسط حالياً هو جعل الواجهة تعتمد على Obx حول StreamBuilder جديد
      update(['reviewsList']); // إرسال إشارة لتحديث الواجهة التي تعتمد على المراجعات
      _listenToReviewsAndRating(); // إعادة الاستماع بالترتيب الجديد (تحتاج لتحسين إدارة الاشتراك)
    }
  }


  // --- الاستماع لحالة إعجاب المستخدم الحالي بالتعليقات المعروضة ---
  void _listenToUserLikes() {
    final User? user = _auth.currentUser;
    if (user == null) return; // لا يمكن جلب الإعجابات لغير المسجلين

    // كلما تغيرت قائمة المراجعات المعروضة، تحقق من إعجاب المستخدم لها
    ever(reviews, (List<ReviewModel> currentReviews) {
      if (currentReviews.isEmpty) {
        userLikes.clear(); // مسح الإعجابات القديمة إذا كانت القائمة فارغة
        return;
      }
      // إنشاء قائمة ID للتعليقات الحالية
      final reviewIds = currentReviews.map((r) => r.id).toList();
      // جلب حالة الإعجاب لهذه التعليقات
      _firestore .collectionGroup('likes') // <--- البحث في كل مجموعات likes الفرعية
          .where('userId', isEqualTo: user.uid) // للمستخدم الحالي
          .where(FieldPath.documentId, whereIn: reviewIds.isNotEmpty ? reviewIds : ['dummy_id']) // للمراجعات الحالية فقط (تحتاج لحل مشكلة whereIn مع قائمة فارغة)
          .get().then((likeSnapshot) {
        // تحديث RxMap userLikes
        final Map<String, bool> likesStatus = {};
        for (var doc in likeSnapshot.docs) {
          likesStatus[doc.id] = true; // المستخدم أعجب بهذا التعليق (المفتاح هو ID الإعجاب=ID المستخدم؟ الأفضل جعل ID الإعجاب = ID المستخدم)
          // ----!!!!  تعديل هنا: بناءً على بنية مجموعة الإعجابات
          // إذا كان ID مستند الإعجاب = userId
          // تحتاج لمعرفة الـ reviewId المرتبط بهذا الإعجاب
          // الطريقة الأسهل هي البحث في likes *تحت كل* reviewId
          // سنبسط هذا الآن وسنفترض أن الواجهة ستبحث بنفسها
          // هذا الجزء معقد ويحتاج لإعادة نظر في بنية likes
        }
        // سنعتمد على StreamBuilder منفصل لكل زر إعجاب حاليًا للتبسيط
        // userLikes.value = likesStatus;
      }).catchError((e) => debugPrint("Error fetching user likes: $e"));
    });
  }

  // --- دالة لتبديل إعجاب المستخدم بتعليق معين ---
  Future<void> toggleLike(String reviewId, bool isCurrentlyLiked) async {
    final User? user = _auth.currentUser;
    if (user == null) return; // المستخدم غير مسجل

    // المسار الصحيح لمجموعة likes تحت مستند المراجعة
    final DocumentReference reviewRef = _firestore.collection('reviews').doc(reviewId);
    final DocumentReference likeRef = reviewRef.collection('likes').doc(user.uid); // استخدام userId كـ ID للمستند
    final int incrementValue = isCurrentlyLiked ? -1 : 1; // لزيادة/إنقاص العداد

    debugPrint("${isCurrentlyLiked ? 'Unliking' : 'Liking'} review $reviewId by user ${user.uid}");

    try {
      // استخدام Batch لتحديث العداد وحالة الإعجاب معًا
      WriteBatch batch = _firestore.batch();

      // 1. زيادة/إنقاص العداد في مستند المراجعة
      batch.update(reviewRef, {'likesCount': FieldValue.increment(incrementValue)});

      // 2. إضافة/إزالة مستند الإعجاب
      if (isCurrentlyLiked) {
        batch.delete(likeRef); // إزالة الإعجاب
      } else {
        batch.set(likeRef, {'likedAt': FieldValue.serverTimestamp()}); // إضافة إعجاب
      }

      await batch.commit(); // تنفيذ العمليتين معًا
      // تحديث حالة الإعجاب المحلية (اختياري، الـ Stream سيفعل ذلك)
      userLikes[reviewId] = !isCurrentlyLiked;
    } catch (e) {
      debugPrint("Error toggling like for review $reviewId: $e");
      Get.snackbar("خطأ", "فشل تحديث الإعجاب.", backgroundColor: Colors.red);
    }
  }


  // --- جلب الردود لتعليق محدد ---
  Future<void> fetchReplies(String reviewId) async {
    // إذا تم التحميل مسبقًا، لا تفعل شيئًا (أو يمكنك إضافة منطق للتحديث)
    if (repliesMap.containsKey(reviewId) || repliesLoadingMap[reviewId] == true) return;

    debugPrint("Fetching replies for review $reviewId");
    repliesLoadingMap[reviewId] = true; // بدء التحميل لهذا التعليق
    try {
      final snapshot = await _firestore
          .collection('reviews') // افترض أن reviews هي المجموعة الرئيسية
          .doc(reviewId)
          .collection('replies') // <--- المجموعة الفرعية للردود
          .orderBy('timestamp', descending: false) // الأقدم أولاً
          .get();

      final fetchedReplies = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList(); // تحويل إلى Map
      repliesMap[reviewId] = fetchedReplies; // تخزين الردود في الـ Map الرئيسي
      debugPrint("Fetched ${fetchedReplies.length} replies for $reviewId");
    } catch (e) {
      debugPrint("Error fetching replies for $reviewId: $e");
      // يمكن عرض خطأ للمستخدم هنا
    } finally {
      repliesLoadingMap[reviewId] = false; // انتهاء التحميل لهذا التعليق
      // لا تحتاج update هنا، repliesMap هي RxMap
    }
  }

  Future<void> addReply(String reviewId, String comment) async {
    final User? user = _auth.currentUser;
    if (user == null) { Get.snackbar(
        "خطأ", // العنوان
        "يجب تسجيل الدخول لإضافة رد.", // الرسالة
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange, // لون مناسب للتحذير
        colorText: Colors.white); return; }
    if (comment.trim().isEmpty) {
      Get.snackbar(
          "تنبيه", // العنوان
          "لا يمكن إرسال رد فارغ.", // الرسالة
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orangeAccent, // لون مختلف للتنبيه
          colorText: Colors.black87);
      return; }

    isSendingReply.value = true;

    try {
      // ---!!! 1. جلب بيانات المستخدم من مجموعة "AppUsers" !!!---
      final userDocRef = _firestore.collection(FirebaseX.collectionApp).doc(user.uid);
      final userDoc = await userDocRef.get();
      String userName = "مستخدم مجهول";
      String? userImageUrl;
      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data()!;
        userName = userData['name'] as String? ?? userName; // <-- اسم الحقل 'name'
        userImageUrl = userData['url'] as String?;    // <-- اسم الحقل 'url'
        debugPrint("Fetched user data for reply: Name=$userName, ImageURL=$userImageUrl");
      } else {
        debugPrint("User document not found for uid: ${user.uid}. Using defaults for reply.");
      }
      // ----------------------------------------------------

      // --- 2. بناء بيانات الرد ---
      final replyData = {
        'userId': user.uid,
        'userName': userName,        // <-- الاسم من Firestore
        'userImageUrl': userImageUrl, // <-- الصورة من Firestore (ستكون null إذا لم تكن موجودة)
        'comment': comment.trim(),
        'timestamp': FieldValue.serverTimestamp(), // الوقت من الخادم
      };
      // ---------------------------

      // --- 3. الحفظ في Firestore ---
      final newReplyRef = await _firestore .collection('reviews') .doc(reviewId) .collection('replies') .add(replyData);
      debugPrint("Reply added successfully with ID: ${newReplyRef.id}");

      // --- 4. تحديث الواجهة المحلية ---
      final localTimestamp = Timestamp.now();
      final replyMapEntry = {'id': newReplyRef.id, ...replyData, 'timestamp': localTimestamp};
      repliesMap.update(reviewId, (list) { list.add(replyMapEntry); list.sort((a, b) => (a['timestamp'] as Timestamp).compareTo(b['timestamp'] as Timestamp)); return list; }, ifAbsent: () => [replyMapEntry]);

      replyController.clear();
      replyingToReviewId.value = null;
      Get.snackbar("نجاح", "تمت إضافة ردك.", backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      debugPrint("Error adding reply: $e");
      Get.snackbar("خطأ", "فشل إضافة الرد: $e", backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      if (!isClosed) { isSendingReply.value = false; }
    }
  }


  void _scrollListener() {
    // قيمة تقريبية لتحديد متى يختفي معظم الصورة (ارتفاع AppBar الموسع - ارتفاع AppBar العادي)
    // اضبط هذه القيمة بناءً على expandedHeight وارتفاع AppBar (kToolbarHeight)
    final scrollOffsetThreshold = Get.height * 0.40; // مثال: 40% من ارتفاع الشاشة تقريباً

    // تحديث showAppBarTitle بناءً على موضع التمرير
    if (!showAppBarTitle.value && scrollController.offset > scrollOffsetThreshold) {
      debugPrint("Scroll offset > $scrollOffsetThreshold, showing AppBar title.");
      showAppBarTitle.value = true;
    } else if (showAppBarTitle.value && scrollController.offset <= scrollOffsetThreshold) {
      debugPrint("Scroll offset <= $scrollOffsetThreshold, hiding AppBar title.");
      showAppBarTitle.value = false;
    }
  }










  Future<void> _initializeVideoPlayer() async {
    if (videoURL == null || videoURL!.isEmpty || videoURL == 'noVideo') {
      isInitialized.value = false; return;
    }
    try {
      final uri = Uri.parse(videoURL!);
      videoController = VideoPlayerController.networkUrl(uri)
        ..addListener(_videoListener);
      await videoController?.initialize();
      if (videoController == null || !videoController!.value.isInitialized) {
        throw Exception('Failed to initialize Video Controller.');
      }
      totalDuration.value = videoController!.value.duration;
      isInitialized.value = true;
      isPlaying.value = videoController!.value.isPlaying;
      isMuted.value = videoController!.value.volume == 0;
      volume.value = videoController!.value.volume;
      _lastVolume = volume.value > 0.01 ? volume.value : 1.0;
      debugPrint("Video Initialized for tag: $tag - Duration: ${totalDuration.value}");
    } catch (e, s) {
      isInitialized.value = false; videoController = null;
      debugPrint("Video Init Error for tag $tag: $e\nStack Trace:\n$s");
      _showErrorSnackbar('فشل تحميل الفيديو. تأكد من الرابط والشبكة.');
    }
  }


  String getImageUrl() => isOffer ? (item as OfferModel).imageUrl ?? '' : (item as ItemModel).imageUrl ?? '';
  double getCurrentPrice() => isOffer ? (item as OfferModel).price : (item as ItemModel).price;
  String? getDescription() => isOffer ? (item as OfferModel).description : (item as ItemModel).description;
  String? getVideoUrl() => isOffer ? (item as OfferModel).videoUrl : (item as ItemModel).videoUrl;
  List<String> getManyImages() => isOffer ? (item as OfferModel).manyImages : (item as ItemModel).manyImages;

  // دوال مساعدة للحصول على بيانات الواجهة بشكل آمن
  String getItemName() => isOffer ? (item as OfferModel).name : (item as ItemModel).name;
  double getPrice() => isOffer ? (item as OfferModel).price : (item as ItemModel).price;
  double? getOldPrice() => isOffer ? (item as OfferModel).oldPrice : null;
  int? getRate() => isOffer ? (item as OfferModel).rate : null;

  String? getItemCondition() => !isOffer ? (item as ItemModel).itemCondition : null;
  int? getQualityGrade() => !isOffer ? (item as ItemModel).qualityGrade : null;
  String? getCountryOfOrigin() => !isOffer ? (item as ItemModel).countryOfOrigin : null;
  String getItemTypeKey() => !isOffer ? (item as ItemModel).typeItem : '';
  String getItemId() => isOffer ? (item as OfferModel).id : (item as ItemModel).id;






  void _videoListener() {
    if (videoController == null || !videoController!.value.isInitialized) return;
    currentPosition.value = videoController!.value.position;
    if (isPlaying.value != videoController!.value.isPlaying) {
      isPlaying.value = videoController!.value.isPlaying;
    }
    if (!videoController!.value.isLooping && currentPosition.value >= totalDuration.value && totalDuration.value > Duration.zero) {
      videoController?.seekTo(Duration.zero);
      videoController?.pause();
      currentPosition.value = Duration.zero;
    }
  }

  // جلب التقييمات وحساب المتوسط
  void _fetchReviewsAndRating() {
    isReviewsLoading.value = true;
    debugPrint("Fetching reviews for product: ${item.id}");
    // استمع لتغيرات مجموعة التعليقات لهذا المنتج
    _firestore
        .collection('reviews') // أو /items/{itemId}/reviews
        .where('productId', isEqualTo: item.id)
        .orderBy('timestamp', descending: true) // الأحدث أولاً
        .snapshots() // الحصول على Stream
        .listen((snapshot) {
      debugPrint("Received ${snapshot.docs.length} reviews for product ${item.id}");
      // تحويل الـ snapshots إلى List<ReviewModel>
      reviews.value = snapshot.docs.map((doc) => ReviewModel.fromSnapshot(doc)).toList();
      // حساب متوسط التقييم والعدد
      if (reviews.isNotEmpty) {
        double totalRating = reviews.fold(0.0, (sum, item) => sum + item.rating);
        averageRating.value = totalRating / reviews.length;
        reviewCount.value = reviews.length;
      } else {
        averageRating.value = 0.0;
        reviewCount.value = 0;
      }
      isReviewsLoading.value = false; // انتهاء التحميل
      debugPrint("Reviews updated. Count: ${reviewCount.value}, Avg Rating: ${averageRating.value.toStringAsFixed(1)}");
    }, onError: (error) {
      debugPrint("Error fetching reviews for product ${item.id}: $error");
      isReviewsLoading.value = false;
      Get.snackbar("خطأ", "فشل في تحميل التقييمات.", colorText: Colors.white, backgroundColor: Colors.red);
    });
  }




  void togglePlayPause() {
    if (!isInitialized.value || videoController == null) return;
    videoController!.value.isPlaying ? videoController!.pause() : videoController!.play();
  }

  void toggleMute() {
    if (!isInitialized.value || videoController == null) return;
    isMuted.value = !isMuted.value;
    _setVolume(isMuted.value ? 0.0 : (_lastVolume > 0.01 ? _lastVolume : 1.0));
  }

  void setVolume(double newVolume) {
    if (!isInitialized.value || videoController == null) return;
    _setVolume(newVolume.clamp(0.0, 1.0));
  }

  void _setVolume(double vol) {
    videoController?.setVolume(vol);
    volume.value = vol;
    if (vol <= 0.01) { if (!isMuted.value) isMuted.value = true; }
    else { if (isMuted.value) isMuted.value = false; _lastVolume = vol; }
  }

  // الانتقال إلى موضع معين في الفيديو
  void seekTo(Duration requestedPosition) {
    if (!isInitialized.value || videoController == null) return;

    // ---!!! الإصلاح هنا: تطبيق Clamp يدويًا !!!---
    Duration finalPosition;
    if (requestedPosition < Duration.zero) {
      // إذا كانت القيمة المطلوبة أقل من الصفر، استخدم الصفر
      finalPosition = Duration.zero;
    } else if (requestedPosition > totalDuration.value && totalDuration.value > Duration.zero) {
      // إذا كانت القيمة المطلوبة أكبر من المدة الكلية (وكانت المدة الكلية موجبة)
      // استخدم المدة الكلية كحد أقصى
      finalPosition = totalDuration.value;
    } else {
      // وإلا، استخدم القيمة المطلوبة كما هي
      finalPosition = requestedPosition;
    }
    // ---------------------------------------------

    videoController!.seekTo(finalPosition); // استخدم القيمة المقيدة

    // تحديث الموضع الحالي يدوياً بعد seekTo ليعكس القيمة فوراً (اختياري، المستمع سيفعل ذلك لاحقاً)
    // currentPosition.value = finalPosition;
  }

  void goFullScreen(BuildContext context) {
    if (!isInitialized.value || videoController == null) return;
    videoController?.pause();
    Get.to(() => ViewVideoFullscreen(videoUrl: videoURL!), transition: Transition.zoom);
  }

  void _showErrorSnackbar(String message) {
    if (Get.isSnackbarOpen) Get.back();
    Get.snackbar('خطأ في الفيديو', message, snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade600, colorText: Colors.white);
  }

  @override
  void onClose() {
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();
    debugPrint("DetailsItemController onClose for tag: $tag, video: $videoURL");
    videoController?.removeListener(_videoListener);
    final controllerToDispose = videoController;

    videoController = null;
    controllerToDispose?.dispose().then((_) { debugPrint("Video Player Disposed: $tag"); }).catchError((e) { debugPrint("Player Dispose Error: $e"); });
    if (!kIsWeb && isFullScreen.value) { SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge); SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]); }
    super.onClose();
  }
}












