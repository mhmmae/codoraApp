import 'dart:async'; // لاستخدامه لاحقاً إذا احتجنا عمليات غير متزامنة أخرى
import 'package:cloud_firestore/cloud_firestore.dart'; // للتفاعل مع Firestore
import 'package:firebase_auth/firebase_auth.dart'; // للتحقق من المستخدم الحالي
import 'package:flutter/material.dart'; // لاستخدام Icon في الـ SnackBar
import 'package:get/get.dart';
import 'package:uuid/uuid.dart'; // أساس مكتبة GetX لإدارة الحالة والتنقل والـ SnackBar

/// ## CodeRequestController
///
/// كنترولر مخصص لإدارة عملية طلب وشراء كود تفعيل معين بناءً على اسمه ومدته.
/// يتضمن جلب المدد المتاحة فعليًا التي لها سعر وتوفر في الأكواد،
/// وعرض السعر للمدة المختارة، وتنفيذ عملية الشراء/الحجز باستخدام معاملة Firestore آمنة.
class CodeRequestController extends GetxController {
  // --- الاعتماديات (Dependencies) ---
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // للوصول إلى Firestore
  final FirebaseAuth _auth = FirebaseAuth.instance; // للوصول إلى معلومات المستخدم الحالي

  // --- حالة متفاعلة (Reactive State) ---

  /// هل عملية طلب الكود جارية حاليًا؟
  /// يُستخدم لتعطيل الزر وإظهار مؤشر تحميل أثناء العملية.
  var isRequestingCode = false.obs;

  /// القائمة الأصلية لجميع خيارات المدد الممكنة مع ترجماتها.
  /// يمكن جلب هذه القائمة من مصدر بيانات آخر إذا تغيرت ديناميكيًا.
  final List<Map<String, String>> _allDurationOptions = const [
    {"ar": "شهر", "en": "month"},
    {"ar": "ثلاثة أشهر", "en": "three months"},
    {"ar": "ستة أشهر", "en": "six months"},
    {"ar": "تسعة أشهر", "en": "nine months"}, // مثال: أضفها إذا كانت متاحة
    {"ar": "سنة", "en": "year"}
  ];

  /// قائمة المدد المتوفرة **فعليًا** للشراء (يوجد لها سعر وأكواد غير مستخدمة).
  /// يتم تحديثها عند فتح شاشة التفاصيل لكل كود.
  var availableDurations = <Map<String, String>>[].obs;

  /// المدة التي اختارها المستخدم حاليًا من القائمة المنسدلة.
  /// من نوع Rx للسماح بقيمة null عندما لا يكون هناك اختيار.
  var selectedDurationOption = Rx<Map<String, String>?>(null);

  /// هل عملية جلب المدد المتوفرة والأسعار جارية حاليًا؟
  /// يُستخدم لإظهار مؤشر تحميل للقسم الخاص بالمدد والأسعار.
  var isLoadingDurationsAndPrice = true.obs;

  /// بيانات التسعير التي تم جلبها للكود الحالي.
  /// يخزن البيانات كـ Map، مثلاً: { 'month': 10.5, 'year': 100 }.
  var pricingData = Rx<Map<String, dynamic>>({});

  /// السعر المحسوب للمدة المختارة حاليًا.
  /// يُعرض للمستخدم قبل الضغط على زر الشراء.
  var currentPrice = Rx<num?>(null); // يسمح بـ null إذا لم يتم تحديد سعر

  // --- الدوال العامة ---
  /// ## initializeForCode
  ///
  /// يتم استدعاؤها عند فتح شاشة تفاصيل الكود لبدء تحميل بيانات الأسعار
  /// والمدد المتاحة الخاصة بهذا الكود المحدد.
  Future<void> initializeForCode(String? codeName) async {
    if (codeName == null || codeName.isEmpty) {
      debugPrint("CodeRequestController: اسم الكود غير موجود، لا يمكن التهيئة.");
      availableDurations.clear(); selectedDurationOption.value = null; pricingData.value = {}; currentPrice.value = null;
      isLoadingDurationsAndPrice.value = false;
      return;
    }

    // --- ▼▼▼ تأكد من عدم البدء إذا كانت العملية جارية لنفس الكود (اختياري) ▼▼▼ ---
    // يمكن إضافة متغير لتتبع اسم الكود الذي يجري تهيئته حاليًا لمنع الاستدعاء المتكرر
    // static String? _initializingCodeName;
    // if (_initializingCodeName == codeName) return;
    // _initializingCodeName = codeName;
    // --- ▲▲▲ ---


    debugPrint("CodeRequestController: بدء تهيئة لـ $codeName");
    // إعادة تعيين الحالة قبل البدء
    isLoadingDurationsAndPrice.value = true; // <--- بداية التحميل
    availableDurations.clear();
    selectedDurationOption.value = null;
    pricingData.value = {};
    currentPrice.value = null;

    // --- ▼▼▼ استخدام try...finally لضمان إيقاف التحميل ▼▼▼ ---
    try {
      // 1. جلب بيانات التسعير أولاً
      await _fetchPricingData(codeName);

      // 2. جلب المدد المتوفرة (التي يوجد لها سعر وأكواد متاحة)
      // نمرر اسم الكود كمعامل صحيح هنا
      await _fetchAvailableDurations(codeName);

    } catch (e, s) {
      // التعامل مع أي أخطاء غير متوقعة قد تحدث أثناء التهيئة نفسها
      debugPrint("CodeRequestController: خطأ عام أثناء التهيئة لـ $codeName: $e\n$s");
      // الحالة تم إعادة تعيينها بالفعل في البداية، لا داعي لإعادة المسح هنا
      // يمكن عرض Snackbar عام إذا لزم الأمر
      Get.snackbar("خطأ", "فشل تحميل تفاصيل الشراء.");

    } finally {
      // --- هذا الجزء سيُنفذ دائمًا، سواء نجحت العمليات أو فشلت ---
      isLoadingDurationsAndPrice.value = false; // <--- إيقاف التحميل دائمًا
      debugPrint("CodeRequestController: انتهت تهيئة $codeName. isLoading = ${isLoadingDurationsAndPrice.value}");
      // _initializingCodeName = null; // مسح اسم الكود الجاري تهيئته
    }
    // --- ▲▲▲ نهاية try...finally ▲▲▲ ---
  }

  /// ## _fetchPricingData
  ///
  /// دالة داخلية لجلب وثيقة التسعير من مجموعة `pricing` بناءً على `codeName`.
  Future<void> _fetchPricingData(String codeName) async {
    debugPrint("جلب بيانات التسعير لـ $codeName...");
    try {
      final docSnapshot = await _firestore.collection('pricing').doc(codeName).get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        pricingData.value = docSnapshot.data()!; // تحديث متغير Rx
        debugPrint("تم العثور على بيانات التسعير: ${pricingData.value}");
      } else {
        pricingData.value = {}; // لا توجد بيانات تسعير لهذا الكود
        debugPrint("لم يتم العثور على وثيقة تسعير لـ $codeName.");
      }
    } catch (e, s) {
      debugPrint("خطأ أثناء جلب بيانات التسعير لـ $codeName: $e\n$s");
      pricingData.value = {}; // مسح البيانات عند حدوث خطأ
      Get.snackbar("خطأ", "فشل في تحميل بيانات التسعير.");
    }
    // محاولة تحديث السعر بناءً على المدة الافتراضية (إذا تم تحديدها)
    _updateCurrentPrice();
  }





  /// ## _fetchAvailableDurations
  ///
  /// دالة داخلية خاصة (`_` تعني خاصة بهذا الكلاس).
  /// الهدف منها: التحقق من كل مدة ممكنة (_allDurationOptions) والتأكد
  /// إذا كان للمدة سعر معرف **وأيضًا** يتوفر لها كود واحد على الأقل
  /// غير مستخدم (`isRUN == false`) بنفس اسم الكود (`codeNameParam`)
  /// ونفس المدة في مجموعة `codes` بـ Firestore.
  ///
  /// تأخذ معامل واحد:
  ///   - `codeNameParam`: اسم الكود (من نوع String) الذي نبحث عن مدد له.
  ///
  /// لا تُعيد قيمة (void)، لكنها تُحدّث متغيرات الحالة Rx:
  /// `availableDurations`, `selectedDurationOption`.
  Future<void> _fetchAvailableDurations(String codeNameParam) async {
    // --- بدء العملية ---
    debugPrint("التحقق من المدد المتاحة (أكواد + سعر) لـ '$codeNameParam'...");
    // قائمة مؤقتة لتخزين المدد التي سيتم عرضها في النهاية
    List<Map<String, String>> foundAndPricedDurations = [];

    try {
      // قائمة لتجميع كل عمليات التحقق من Firestore (Futures)
      // نستخدم QuerySnapshot? لأننا قد نضيف Future.value(null) للمدد بدون سعر
      List<Future<QuerySnapshot?>> codeCheckFutures = [];
      bool priceWasMissing = false; // متغير لتتبع هل السبب هو عدم وجود سعر
      if (foundAndPricedDurations.isEmpty && _allDurationOptions.any((opt) => !pricingData.value.containsKey(opt['en']!))) {
        priceWasMissing = true;
      }
      // المرور على كل خيارات المدد الأصلية (شهر، 3 أشهر، ...)
      for (var durationMap in _allDurationOptions) {
        // القيمة الإنجليزية للمدة (المستخدمة في Firestore كمفتاح للسعر وكمجال للمدة)
        final durationValueEn = durationMap['en']!;

        // --- التحقق الأساسي: هل يوجد سعر لهذه المدة أصلاً؟ ---
        // pricingData.value هو المتغير Rx الذي يحمل بيانات التسعير التي تم جلبها مسبقًا
        if (pricingData.value.containsKey(durationValueEn)) {
          // نعم، يوجد سعر مسجل لهذه المدة.
          debugPrint("السعر موجود للمدة '$durationValueEn'. الآن نبحث عن كود متاح...");

          // --- الآن نبحث في Firestore عن كود مطابق للمواصفات ---
          // بناء الاستعلام
          final query = _firestore.collection('codes') // تأكد من اسم المجموعة الصحيح
              .where('codeName', isEqualTo: codeNameParam)    // نفس اسم الكود المطلوب
              .where('duration', isEqualTo: durationValueEn) // نفس مدة هذه الدورة (month, year, etc.)
              .where('isRUN', isEqualTo: false)           // الكود غير مستخدم (لم يتم شراؤه/تفعيله)
              .limit(1);                                   // نريد فقط معرفة إن كان هناك كود واحد على الأقل

          // إضافة عملية الاستعلام (الـ Future) إلى قائمتنا
          codeCheckFutures.add(query.get());

        } else {
          // لا، لا يوجد سعر مسجل لهذه المدة في مجموعة 'pricing'.
          debugPrint("السعر غير معرف للمدة '$durationValueEn'، تخطي التحقق من الأكواد.");
          // نضيف Future وهمي يعيد null إلى القائمة للحفاظ على نفس حجم القائمة وترتيبها
          // هذا مهم لمطابقة النتائج لاحقاً مع _allDurationOptions
          codeCheckFutures.add(Future.value(null));
        }
      } // نهاية حلقة for

      // --- انتظار كل عمليات البحث عن الأكواد لتكتمل ---
      // Future.wait ينتظر كل الـ Futures في القائمة ثم يعيد قائمة بالنتائج بنفس الترتيب
      debugPrint("انتظار نتائج البحث عن الأكواد لكل المدد...");
      final List<QuerySnapshot?> results = await Future.wait(codeCheckFutures);
      debugPrint("تم الحصول على ${results.length} نتيجة بحث.");

      // --- تحليل النتائج ---
      // المرور على نتائج البحث (بنفس ترتيب المدد في _allDurationOptions)
      for (int i = 0; i < results.length; i++) {
        final queryResult = results[i]; // نتيجة البحث عن كود لهذه المدة المحددة (قد تكون null إذا تخطينا البحث)
        final durationMap = _allDurationOptions[i]; // المدة المقابلة من القائمة الأصلية

        // التحقق إذا كان queryResult ليس null (أي أننا بحثنا لأن السعر كان موجودًا)
        // وأيضًا إذا كان queryResult يحتوي على مستند واحد على الأقل (أي وجدنا كودًا متاحًا)
        if (queryResult != null && queryResult.docs.isNotEmpty) {
          // الشرط تحقق: يوجد سعر + يوجد كود متاح
          foundAndPricedDurations.add(durationMap); // أضف هذه المدة للقائمة النهائية
          debugPrint("✔️ المدة '${durationMap['en']}' متاحة للشراء (يوجد سعر وكود).");
        }
        // لا داعي لـ else هنا لأننا نريد فقط المدد التي يتوفر لها سعر وكود
        // أو يمكنك إضافة طباعة للمدد التي لها سعر ولكن لا أكواد:
        else if (pricingData.value.containsKey(durationMap['en']!) && queryResult != null && queryResult.docs.isEmpty) {
          debugPrint("⏳ المدة '${durationMap['en']}' غير متاحة حالياً (يوجد سعر لكن لا توجد أكواد متوفرة).");
        }
      }
      if (foundAndPricedDurations.isEmpty && priceWasMissing && Get.isSnackbarOpen == false) {
        // Get.snackbar("معلومة", "لم يتم تحديد أسعار التفعيل لهذا الكود حاليًا.");
      }
      availableDurations.assignAll(foundAndPricedDurations);
// نهاية حلقة تحليل النتائج

    } catch (e, s) {
      // التعامل مع أي خطأ يحدث أثناء جلب البيانات أو الانتظار
      debugPrint("حدث خطأ أثناء التحقق من المدد المتاحة لـ $codeNameParam: $e \n$s");
      Get.snackbar("خطأ", "فشل في تحميل مدد التفعيل المتاحة.");
      // اترك قائمة المدد المتاحة فارغة عند حدوث خطأ
    }

    // --- تحديث متغيرات الحالة Rx في النهاية ---
    availableDurations.assignAll(foundAndPricedDurations); // تحديث قائمة GetX لتحديث الواجهة
    // تحديد الخيار الافتراضي في القائمة المنسدلة (أول مدة متاحة)
    if (foundAndPricedDurations.isNotEmpty) {
      selectedDurationOption.value = foundAndPricedDurations.first;
      debugPrint("تم تحديد '${foundAndPricedDurations.first['ar']}' كمدة افتراضية.");
    } else {
      selectedDurationOption.value = null; // لا يوجد اختيار افتراضي إذا لم تتوفر أي مدة
      debugPrint("لا توجد مدد متاحة لتحديد اختيار افتراضي.");
    }
    // تحديث السعر المعروض بناءً على الاختيار الافتراضي (أو null)
    _updateCurrentPrice();
  }
  // --- نهاية دالة _fetchAvailableDurations ---

  /// ## _updateCurrentPrice
  ///
  /// دالة داخلية لتحديث قيمة `currentPrice` بناءً على `selectedDurationOption`
  /// والبيانات المخزنة في `pricingData`.
  void _updateCurrentPrice() {
    final selectedEn = selectedDurationOption.value?['en']; // الحصول على القيمة الإنجليزية للمدة المختارة
    if (selectedEn != null && pricingData.value.containsKey(selectedEn)) {
      // إذا كانت المدة مختارة وهناك سعر لها في بيانات التسعير
      final dynamic priceValue = pricingData.value[selectedEn];
      if (priceValue is num) { // التأكد أن السعر هو رقم (int أو double)
        currentPrice.value = priceValue; // تحديث قيمة السعر الحالية (Rx)
        debugPrint("تم تحديد السعر الحالي بـ: ${currentPrice.value} للمدة $selectedEn");
      } else {
        // إذا كانت القيمة المخزنة للسعر ليست رقمًا
        debugPrint("قيمة السعر للمدة $selectedEn ليست رقمًا: $priceValue");
        currentPrice.value = null; // تعيين السعر كـ null
      }
    } else {
      // إذا لم يتم اختيار مدة أو لا يوجد سعر للمدة المختارة
      currentPrice.value = null;
      debugPrint("لا يوجد سعر أو مدة مختارة. السعر الحالي هو null.");
    }
  }

  /// ## selectDuration
  ///
  /// تُستدعى من الواجهة (DropdownButton) عند تغيير المدة المختارة.
  void selectDuration(Map<String, String>? newDuration) {
    selectedDurationOption.value = newDuration; // تحديث المدة المختارة (Rx)
    _updateCurrentPrice(); // استدعاء دالة تحديث السعر
  }


  /// ## requestSpecificCode
  ///
  /// تنفيذ عملية طلب/شراء كود محدد باستخدام معاملة Firestore.
  Future<Map<String, dynamic>?> requestSpecificCode({
    required String codeName,
    required String selectedDuration, // القيمة الإنجليزية للمدة ('month', 'year', ...)
    required Map<String,String> selectedDurationMap, // لتمرير الاسم العربي بسهولة
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) { /* ... رسالة تسجيل الدخول ... */ return null; }
    if (isRequestingCode.value) return null; // منع الطلبات المتزامنة

    isRequestingCode.value = true; // بدء عملية الطلب (لإظهار التحميل في الزر)
    String? assignedCodeValue;    // لتخزين قيمة الكود المخصص
    DocumentReference? codeToAssignRef;
    num? purchasePrice = currentPrice.value; // <-- احفظ السعر الحالي قبل بدء المعاملة
// مرجع للمستند الذي سيتم تحديثه

    try {
      // 1. البحث عن كود متاح (نفس اسم المنتج، نفس المدة، غير مفعل) - *خارج المعاملة*
      debugPrint("Searching for available code: Name='$codeName', Duration='$selectedDuration', isRUN=false");
      final query = _firestore.collection('codes')
          .where('codeName', isEqualTo: codeName)
          .where('duration', isEqualTo: selectedDuration)
          .where('isRUN', isEqualTo: false)
          .where('is4', isEqualTo: false)// التأكد من حالة عدم التفعيل
          .limit(1); // نريد كود واحد فقط

      final snapshot = await query.get();

      // 2. التحقق من وجود كود مرشح
      if (snapshot.docs.isEmpty) {
        debugPrint("No available code found matching criteria outside transaction.");
        Get.snackbar("نفدت الكمية!", "عذرًا، لا توجد أكواد متاحة لهذه المدة حاليًا. حاول لاحقًا.", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange);
        isRequestingCode.value = false;
        return null; // الخروج إذا لم نجد
      }

      // 3. الحصول على مرجع الكود المرشح
      codeToAssignRef = snapshot.docs.first.reference;
      debugPrint("Found potential code: ${codeToAssignRef.id}. Starting transaction...");

      // 4. تشغيل المعاملة الذرية لضمان عدم التضارب
      assignedCodeValue = await _firestore.runTransaction<String?>((transaction) async {
        // أ. جلب أحدث نسخة من المستند داخل المعاملة للتأكد من حالته
        final freshDocSnapshot = await transaction.get(codeToAssignRef!);

        // ب. التحقق من وجود المستند ومن حالته مرة أخرى (أمان إضافي)
        if (!freshDocSnapshot.exists) {
          debugPrint("Code ${codeToAssignRef.id} no longer exists.");
          throw FirebaseException(plugin: 'Firestore', code: 'aborted', message: 'حدث خطأ، الكود لم يعد موجودًا.');
        }
        final codeDocData = freshDocSnapshot.data() as Map<String, dynamic>?;
        if (codeDocData == null || codeDocData['isRUN'] == true || codeDocData['assignedToUserId'] != null) {
          debugPrint("Code ${codeToAssignRef.id} was claimed during transaction.");
          throw FirebaseException(plugin: 'Firestore', code: 'aborted', message: 'عذرًا، تم حجز هذا الكود للتو. حاول مرة أخرى.');
        }

        // ج. إذا كان الكود لا يزال متاحًا، قم بتحديثه لربطه بالمستخدم وجعله غير متاح
        transaction.update(codeToAssignRef, {
          'isRUN': true,                           // تحديث الحالة
          'assignedToUserId': currentUser.uid,     // ربط المستخدم
          'assignedAt': FieldValue.serverTimestamp(), // وقت التخصيص
          // 'assignedUserEmail': currentUser.email // (اختياري)
        });

        debugPrint("Transaction successful: Updated code ${codeToAssignRef.id} for user ${currentUser.uid}");

        // د. إرجاع قيمة الكود الفعلية من البيانات التي قرأناها
        return codeDocData['code'] as String?;

      }, timeout: const Duration(seconds: 15)); // المهلة للمعاملة

      // 5. التعامل مع نتيجة المعاملة الناجحة
      if (assignedCodeValue != null) {
        Get.snackbar("تم الشراء بنجاح!", "الكود الخاص بك: $assignedCodeValue", icon: const Icon(Icons.check_circle, color: Colors.white), backgroundColor: Colors.green, colorText: Colors.white, duration: const Duration(seconds: 10), isDismissible: true);
// --- ▼▼▼ *جديد*: جلب بيانات المستخدم لـ الفاتورة ▼▼▼ ---
        String customerName = 'غير معروف'; // قيمة افتراضية لاسم العميل
        String customerPhone = 'غير متوفر'; // قيمة افتراضية لرقم الهاتف

        try {
          debugPrint("Fetching user data from Usercodora for invoice...");
          // جلب مستند المستخدم من مجموعة Usercodora
          final userDocSnapshot = await _firestore.collection('Usercodora').doc(currentUser.uid).get();

          if (userDocSnapshot.exists && userDocSnapshot.data() != null) {
            final userData = userDocSnapshot.data()!;
            debugPrint("Usercodora data found: $userData");
            // الحصول على الاسم بأمان
            customerName = (userData['name'] as String?)?.isNotEmpty ?? false ? userData['name'] : 'لا يوجد اسم';
            // الحصول على رقم الهاتف بأمان
            customerPhone = (userData['phneNumber'] as String?)?.isNotEmpty ?? false ? userData['phneNumber'] : 'لا يوجد رقم';
          } else {
            debugPrint("User document NOT found in Usercodora for ${currentUser.uid}");
          }
        } catch(e, s) {
          debugPrint("!!! Error fetching user data for invoice (using defaults): $e\n$s");
          // استخدم القيم الافتراضية في حالة الخطأ
        }
        // --- ▲▲▲ نهاية جلب بيانات المستخدم ▲▲▲ ---

        try {


          final arabicDuration = selectedDurationMap['ar'] ?? selectedDuration; // الاسم العربي
          final saleUuid = const Uuid().v1(); // معرف فريد للفاتورة
          final Timestamp purchaseTimestamp = Timestamp.now();



          // تجميع بيانات الفاتورة
          final salesData = {
            'saleId': saleUuid, // المعرف الفريد للفاتورة
            'userId': currentUser.uid,
            'name': customerName,     // الاسم المجلوب أو الافتراضي
            'phneNumber': customerPhone, // الرقم المجلوب أو الافتراضي
            'userEmail': currentUser.email, // (اختياري)
            'codeName': codeName,           // اسم نوع الكود
            'assignedCodeValue': assignedCodeValue, // الكود الفعلي الذي تم الحصول عليه
            'selectedDurationEn': selectedDuration, // المدة (الإنجليزية)
            'selectedDurationAr': arabicDuration, // المدة (العربية)
            'purchasePrice': purchasePrice,      // السعر وقت الشراء
            'purchaseTimestamp': purchaseTimestamp,            // حفظ الـ Timestamp مباشرة
            'is4':false,
            'isRUN': true, // حالة الكود (مفعل)
            // يمكنك إضافة حقول أخرى مثل:
            // 'paymentMethod': '...' // (إذا كان لديك نظام دفع)
             'status': 'completed'
          };

          // حفظ الفاتورة في مجموعة theSales
          await _firestore.collection('theSales').doc(saleUuid).set(salesData);
          debugPrint("Sales record created successfully: $saleUuid");

          return salesData;


        } catch(e, s) {
          // خطأ أثناء حفظ الفاتورة (لكن الكود تم تخصيصه بالفعل)
          debugPrint("!!! Error creating sales record for $codeName ($selectedDuration) AFTER successful assignment: $e\n$s");
          // إظهار رسالة خطأ للمستخدم بأن الكود تم لكن هناك مشكلة في سجل الشراء
          Get.snackbar("خطأ في السجل", "تم تخصيص الكود لك بنجاح، ولكن حدث خطأ أثناء تسجيل عملية الشراء.", snackPosition: SnackPosition.BOTTOM);
          // لا تقم بإرجاع null هنا، لأن المستخدم حصل على الكود بالفعل
        }
        // --- (اختياري) يمكنك إضافة تحديث للبيانات المعروضة إذا أردت إخفاء المدة فورًا ---
        // await fetchAvailableDurations(codeName); // إعادة جلب المدد المتاحة
        // return assignedCodeValue;
      } else {
        // هذه الحالة قد لا تحدث كثيرًا بسبب رمي الاستثناء داخل المعاملة
        debugPrint("Transaction completed but assignedCodeValue is null (unexpected).");
        Get.snackbar("خطأ", "فشل الحصول على الكود بعد المعاملة.", snackPosition: SnackPosition.BOTTOM);
        return null;
      }
      return null;


    } on FirebaseException catch (e) {
      // معالجة أخطاء Firestore المحددة (خاصةً 'aborted')
      debugPrint("Firestore Transaction Error: ${e.code} - ${e.message}");
      Get.snackbar( e.code == 'aborted' ? "محاولة أخرى" : "خطأ Firestore (${e.code})", e.message ?? "فشل طلب الكود. حاول مرة أخرى.", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange[800]);
      return null;
    } catch (e, s) {
      // معالجة أي أخطاء أخرى غير متوقعة
      debugPrint("Generic Error during code request: $e\n$s");
      Get.snackbar("خطأ فني", "حدث خطأ غير متوقع أثناء طلب الكود.", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red);
      return null;
    } finally {
      isRequestingCode.value = false; // إنهاء حالة التحميل دائمًا
    }
  }

} // نهاية CodeRequestController