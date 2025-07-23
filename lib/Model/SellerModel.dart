import 'package:cloud_firestore/cloud_firestore.dart';

class SellerModel {
  final String
  uid; // معرف المستخدم من FirebaseAuth، سيكون هو ID المستند في مجموعة البائعين
  final String sellerName; // اسم صاحب المحل
  final String? sellerProfileImageUrl;
  final String shopName; // اسم المحل التجاري
  final String? shopFrontImageUrl;
  final String shopPhoneNumber; // رقم الهاتف الذي تم التحقق منه
  final String? shopDescription;
  final String? email; // إضافة حقل البريد الإلكتروني

  // الموقع
  final GeoPoint location; // يُخزن كـ GeoPoint في Firestore
  final String? shopAddressText; // العنوان النصي المقروء

  // الفئة وساعات العمل
  final List<String>
  shopCategories; // قائمة فئات المحل (يمكن أن يكون لديه أكثر من فئة)
  final Map<String, dynamic>
  workingHours; // هيكل Map لتخزين ساعات العمل لكل يوم

  // معلومات إضافية اختيارية
  final String? commercialRegistrationNumber;
  final String? websiteUrl;
  final Map<String, String>?
  socialMediaLinks; // مثال: {'facebook': 'url', 'instagram': 'url'}

  // حالات وحالة التحقق من قبل المشرف (إذا كان لديك نظام موافقة للبائعين)
  final bool
  isProfileComplete; // هل أكمل البائع ملفه (عادةً ما يكون true بعد هذه العملية)
  final bool
  isApprovedByAdmin; // هل تمت الموافقة على البائع من قبل مشرف التطبيق
  final bool isActiveBySeller; // هل البائع جعل متجره نشطًا لاستقبال الطلبات
  final bool isPhoneNumberVerified; // تم التحقق من رقم الهاتف

  // التقييمات
  final double averageRating;
  final int numberOfRatings;

  // نظام الثقة
  final double trustScore; // نقاط الثقة، تبدأ بـ 50 عند التسجيل

  // الحقول الجديدة
  final String?
  sellerType; // نوع البائع: 'wholesale', 'retail', أو null إذا لم يحدد بعد
  final bool registrationCompleted; // هل أكمل البائع جميع خطوات التسجيل

  final Timestamp createdAt;
  final Timestamp? updatedAt; // يُحدث مع كل تعديل

  SellerModel({
    required this.uid,
    required this.sellerName,
    this.sellerProfileImageUrl,
    required this.shopName,
    this.shopFrontImageUrl,
    required this.shopPhoneNumber,
    this.shopDescription,
    this.email, // إضافة هنا
    required this.location,
    this.shopAddressText,
    required this.shopCategories,
    required this.workingHours,
    this.commercialRegistrationNumber,
    this.websiteUrl,
    this.socialMediaLinks,
    this.isProfileComplete =
        true, // يفترض أنه true عند إنشاء هذا النموذج بعد التسجيل
    this.isApprovedByAdmin =
        false, // يبدأ غير موافق عليه (إذا كان هناك نظام موافقة)
    this.isActiveBySeller = true, // البائع يعتبر متجره نشطًا مبدئيًا
    required this.isPhoneNumberVerified, // يجب تمرير هذا بناءً على نتيجة OTP
    this.averageRating = 0.0,
    this.numberOfRatings = 0,
    this.trustScore = 50.0, // الثقة الافتراضية عند التسجيل
    this.sellerType, // إضافة هنا
    this.registrationCompleted = false, // إضافة هنا
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'sellerName': sellerName,
      'sellerProfileImageUrl': sellerProfileImageUrl,
      'shopName': shopName,
      'shopFrontImageUrl': shopFrontImageUrl,
      'shopPhoneNumber': shopPhoneNumber,
      'shopDescription': shopDescription,
      'email': email, // إضافة هنا
      'location': location, // GeoPoint
      'shopAddressText': shopAddressText,
      'shopCategories': shopCategories, // List<String>
      'workingHours': workingHours, // Map <String, Map<String, dynamic>>
      'commercialRegistrationNumber': commercialRegistrationNumber,
      'websiteUrl': websiteUrl,
      'socialMediaLinks': socialMediaLinks,
      'isProfileComplete': isProfileComplete,
      'isApprovedByAdmin': isApprovedByAdmin,
      'isActiveBySeller': isActiveBySeller,
      'isPhoneNumberVerified': isPhoneNumberVerified,
      'averageRating': averageRating,
      'numberOfRatings': numberOfRatings,
      'trustScore': trustScore, // إضافة نقاط الثقة
      'sellerType': sellerType, // إضافة هنا
      'registrationCompleted': registrationCompleted, // إضافة هنا
      'createdAt':
          createdAt, // أو FieldValue.serverTimestamp() إذا كان الإنشاء من جانب الخادم أو في معاملة
      'updatedAt':
          FieldValue.serverTimestamp(), // يتم تحديثه تلقائيًا مع كل عملية set/update
    };
  }

  factory SellerModel.fromMap(Map<String, dynamic> map, String documentId) {
    // تحويل workingHours من Firestore (الذي سيكون Map<String, dynamic>)
    // إلى Map<String, Map<String, dynamic>> إذا لزم الأمر لمزيد من الدقة في النوع،
    // أو تركه كـ Map<String, dynamic> إذا كان هذا كافيًا لاستخدامك.
    Map<String, dynamic> workingHoursFromDb = {};
    if (map['workingHours'] is Map) {
      (map['workingHours'] as Map).forEach((key, value) {
        if (value is Map) {
          workingHoursFromDb[key.toString()] = Map<String, dynamic>.from(value);
        }
      });
    }

    return SellerModel(
      uid: documentId, // أو map['uid'] إذا كنت تخزنه كحقل أيضًا
      sellerName: map['sellerName'] as String? ?? '',
      sellerProfileImageUrl: map['sellerProfileImageUrl'] as String?,
      shopName: map['shopName'] as String? ?? '',
      shopFrontImageUrl: map['shopFrontImageUrl'] as String?,
      shopPhoneNumber: map['shopPhoneNumber'] as String? ?? '',
      shopDescription: map['shopDescription'] as String?,
      email: map['email'] as String?, // إضافة هنا
      location:
          map['location'] as GeoPoint? ??
          const GeoPoint(0, 0), // قيمة افتراضية إذا كان null
      shopAddressText: map['shopAddressText'] as String?,
      shopCategories:
          (map['shopCategories'] as List<dynamic>?)?.cast<String>() ??
          ['أخرى'], // قيمة افتراضية
      workingHours: workingHoursFromDb,
      commercialRegistrationNumber:
          map['commercialRegistrationNumber'] as String?,
      websiteUrl: map['websiteUrl'] as String?,
      socialMediaLinks:
          map['socialMediaLinks'] != null
              ? Map<String, String>.from(map['socialMediaLinks'] as Map)
              : null,
      isProfileComplete: map['isProfileComplete'] as bool? ?? false,
      isApprovedByAdmin: map['isApprovedByAdmin'] as bool? ?? false,
      isActiveBySeller: map['isActiveBySeller'] as bool? ?? true,
      isPhoneNumberVerified: map['isPhoneNumberVerified'] as bool? ?? false,
      averageRating: (map['averageRating'] as num?)?.toDouble() ?? 0.0,
      numberOfRatings: (map['numberOfRatings'] as num?)?.toInt() ?? 0,
      trustScore:
          (map['trustScore'] as num?)?.toDouble() ??
          50.0, // قيمة افتراضية للبيانات القديمة
      sellerType: map['sellerType'] as String?, // إضافة هنا
      registrationCompleted:
          map['registrationCompleted'] as bool? ?? false, // إضافة هنا
      createdAt:
          map['createdAt'] as Timestamp? ?? Timestamp.now(), // قيمة افتراضية
      updatedAt: map['updatedAt'] as Timestamp?,
    );
  }

  // --- دوال مساعدة ( اختيارية ) ---

  // دالة للتحقق مما إذا كان المتجر مفتوحًا الآن
  // هذه تحتاج إلى منطق أكثر تفصيلاً لمقارنة الوقت الحالي بساعات العمل المحفوظة
  // مع مراعاة اليوم الحالي والمنطقة الزمنية إذا لزم الأمر.
  // bool isShopOpenNow() {
  //   if (!isActiveBySeller || !isApprovedByAdmin) return false;
  //   // منطق للتحقق من workingHours مقابل الوقت الحالي
  //   // ... (سيكون هذا معقدًا بعض الشيء ويتطلب تحويل أوقات السلسلة النصية)
  //   return true; // مجرد قيمة افتراضية الآن
  // }

  //  يمكن إضافة copyWith إذا احتجت لتعديل كائنات النموذج بسهولة
  SellerModel copyWith({
    String? uid,
    String? sellerName,
    String? sellerProfileImageUrl,
    String? shopName,
    // ...أضف باقي الحقول
    String? shopPhoneNumber,
    String? shopDescription,
    String? email, // إضافة هنا
    GeoPoint? location,
    String? shopAddressText,
    List<String>? shopCategories,
    Map<String, dynamic>? workingHours,
    String? commercialRegistrationNumber,
    String? websiteUrl,
    Map<String, String>? socialMediaLinks,
    bool? isProfileComplete,
    bool? isApprovedByAdmin,
    bool? isActiveBySeller,
    bool? isPhoneNumberVerified,
    double? averageRating,
    int? numberOfRatings,
    double? trustScore, // إضافة نقاط الثقة
    String? sellerType, // إضافة هنا
    bool? registrationCompleted, // إضافة هنا
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return SellerModel(
      uid: uid ?? this.uid,
      sellerName: sellerName ?? this.sellerName,
      sellerProfileImageUrl:
          sellerProfileImageUrl ?? this.sellerProfileImageUrl,
      shopName: shopName ?? this.shopName,
      // ...مرر باقي القيم
      shopPhoneNumber: shopPhoneNumber ?? this.shopPhoneNumber,
      shopDescription: shopDescription ?? this.shopDescription,
      email: email ?? this.email, // إضافة هنا
      location: location ?? this.location,
      shopAddressText: shopAddressText ?? this.shopAddressText,
      shopCategories: shopCategories ?? this.shopCategories,
      workingHours: workingHours ?? this.workingHours,
      commercialRegistrationNumber:
          commercialRegistrationNumber ?? this.commercialRegistrationNumber,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      socialMediaLinks: socialMediaLinks ?? this.socialMediaLinks,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      isPhoneNumberVerified:
          isPhoneNumberVerified ?? this.isPhoneNumberVerified,
      isApprovedByAdmin: isApprovedByAdmin ?? this.isApprovedByAdmin,
      isActiveBySeller: isActiveBySeller ?? this.isActiveBySeller,
      averageRating: averageRating ?? this.averageRating,
      numberOfRatings: numberOfRatings ?? this.numberOfRatings,
      trustScore: trustScore ?? this.trustScore, // إضافة نقاط الثقة
      sellerType: sellerType ?? this.sellerType, // إضافة هنا
      registrationCompleted:
          registrationCompleted ?? this.registrationCompleted, // إضافة هنا
      createdAt: createdAt ?? this.createdAt,
      updatedAt:
          updatedAt, // يمكن تمرير null إذا كان سيتحدث بواسطة serverTimestamp
    );
  }
}

// Firestore Collection Name for Sellers (من FirebaseX الخاص بك)
// static const String sellersCollection = "Sellercodora";

// Firestore Collection Name for Sellers (من FirebaseX الخاص بك)
// static const String sellersCollection = "Sellercodora";
