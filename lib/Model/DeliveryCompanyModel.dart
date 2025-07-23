import 'package:cloud_firestore/cloud_firestore.dart';

// قد تحتاج إلى هذا إذا كنت ستدعم أنواعًا متعددة من مناطق الخدمة بشكل أكثر تفصيلاً
// enum ServiceAreaType { pincode, geofencePolygon }

class DeliveryCompanyModel {
  final String companyId; // ID فريد للشركة، يفضل أن يكون هو UID لمستخدم Firebase Auth المشرف
  final String companyName;
  final String? logoImageUrl;
  final String contactPhoneNumber; // رقم هاتف الشركة الرئيسي (يجب التحقق منه)
  final String contactEmail;     // بريد إلكتروني رسمي للشركة (يجب التحقق منه)
  final String adminUserId;      // UID الخاص بمستخدم Firebase Auth الذي يدير حساب الشركة
  final double? baseDeliveryFee; // رسم توصيل أساسي لهذه الشركة
  final List<Map<String, dynamic>>? hubLocations; // قائمة بمقرات الشركة

  // معلومات الموقع والخدمة
  final String? headquartersAddressText; // العنوان النصي للمقر الرئيسي
  final GeoPoint? headquartersLocation;   // إحداثيات المقر الرئيسي (اختياري)
  final List<String>? serviceAreaDescriptions; // قائمة بنصوص تصف مناطق الخدمة (مثل: "بغداد - الكرخ", "أربيل - وسط المدينة")
  // للمناطق الجغرافية المتقدمة (Geofencing), يمكنك استخدام هذا لاحقًا:
  // final List<Map<String, dynamic>>? serviceAreaGeofences; // مثال: [{'name': 'Zone A', 'polygon': [GeoPoint(), GeoPoint(), ...]}]

  // معلومات إضافية
  final String? commercialRegistrationNumber; // رقم السجل التجاري
  final String? websiteUrl;                  // رابط موقع الشركة الإلكتروني (إن وجد)
  final String? companyBio;                  // نبذة تعريفية عن الشركة وخدماتها

  // حالات وحالة التحقق
  final bool isApprovedByPlatformAdmin; // هل تمت الموافقة على الشركة من قبل مشرفي تطبيقك (أنت)
  final bool isVerified;                // هل تم التحقق من وثائق الشركة (مثل السجل التجاري)
  final bool isActiveByCompanyAdmin;    // هل مشرف الشركة قام بتفعيل استقبال الطلبات (يمكن للشركة أن توقف استقبال الطلبات مؤقتًا)

  // التقييمات
  final double averageRating;
  final int numberOfRatings;

  final Timestamp createdAt;
  final Timestamp? updatedAt;

  DeliveryCompanyModel({
    this.hubLocations, // <--- إضافة للمُنشئ

    this.baseDeliveryFee,
    required this.companyId,
    required this.companyName,
    this.logoImageUrl,
    required this.contactPhoneNumber,
    required this.contactEmail,
    required this.adminUserId,
    this.headquartersAddressText,
    this.headquartersLocation,
    this.serviceAreaDescriptions,
    // this.serviceAreaGeofences,
    this.commercialRegistrationNumber,
    this.websiteUrl,
    this.companyBio,
    this.isApprovedByPlatformAdmin = false, // تبدأ غير موافق عليها من منصتك
    this.isVerified = false,                 // تبدأ غير موثقة
    this.isActiveByCompanyAdmin = true,   // تفترض الشركة أنها نشطة عند الإنشاء، يمكنها تغييرها
    this.averageRating = 0.0,
    this.numberOfRatings = 0,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId, // يمكن عدم تخزينه هنا إذا كان companyId هو اسم المستند
      'companyName': companyName,
      'logoImageUrl': logoImageUrl,
      'contactPhoneNumber': contactPhoneNumber,
      'contactEmail': contactEmail,
      'hubLocations': hubLocations, // <--- إضافة لـ toMap
      'adminUserId': adminUserId,
      'headquartersAddressText': headquartersAddressText,
      'headquartersLocation': headquartersLocation,
      'serviceAreaDescriptions': serviceAreaDescriptions,
      // 'serviceAreaGeofences': serviceAreaGeofences,
      'commercialRegistrationNumber': commercialRegistrationNumber,
      'websiteUrl': websiteUrl,
      'companyBio': companyBio,
      'isApprovedByPlatformAdmin': isApprovedByPlatformAdmin,
      'isVerified': isVerified,
      'isActiveByCompanyAdmin': isActiveByCompanyAdmin,
      'averageRating': averageRating,
      'numberOfRatings': numberOfRatings,
      'createdAt': createdAt, // أو FieldValue.serverTimestamp() عند الإنشاء
      'updatedAt': FieldValue.serverTimestamp(), // يتم تحديثه دائمًا عند الكتابة
    };
  }

  factory DeliveryCompanyModel.fromMap(Map<String, dynamic> map, String documentId) {
    List<Map<String, dynamic>>? hubs;
    if (map['hubLocations'] is List) {
      hubs = (map['hubLocations'] as List<dynamic>).map((hub) {
        if (hub is Map<String, dynamic>) { // التأكد من أن كل عنصر هو Map
          return {
            'hubId': hub['hubId'] as String? ?? '',
            'hubName': hub['hubName'] as String? ?? 'مقر غير مسمى',
            'hubAddressText': hub['hubAddressText'] as String? ?? '',
            'hubLocation': hub['hubLocation'] as GeoPoint? ?? const GeoPoint(0,0),
            'hubConfirmationBarcode': hub['hubConfirmationBarcode'] as String? ?? '',
          };
        }
        return <String,dynamic>{}; // عنصر فارغ إذا لم يكن map صحيح
      }).where((hubMap) => hubMap.isNotEmpty).toList();
      if(hubs.isEmpty) hubs = null; // إذا كانت القائمة فارغة بعد الفلترة
    }
    return DeliveryCompanyModel(
      hubLocations: hubs, // <--- قراءة من Firestore
      companyId: documentId, // استخدام معرف المستند كـ companyId
      companyName: map['companyName'] as String? ?? '',
      logoImageUrl: map['logoImageUrl'] as String?,
      contactPhoneNumber: map['contactPhoneNumber'] as String? ?? '',
      contactEmail: map['contactEmail'] as String? ?? '',
      adminUserId: map['adminUserId'] as String? ?? '',
      headquartersAddressText: map['headquartersAddressText'] as String?,
      headquartersLocation: map['headquartersLocation'] as GeoPoint?,
      serviceAreaDescriptions: (map['serviceAreaDescriptions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      // serviceAreaGeofences: (map['serviceAreaGeofences'] as List<dynamic>?)
      //     ?.map((e) => e as Map<String, dynamic>)
      //     .toList(),
      commercialRegistrationNumber: map['commercialRegistrationNumber'] as String?,
      baseDeliveryFee: (map['baseDeliveryFee'] as num?)?.toDouble(),

      websiteUrl: map['websiteUrl'] as String?,
      companyBio: map['companyBio'] as String?,
      isApprovedByPlatformAdmin: map['isApprovedByPlatformAdmin'] as bool? ?? false,
      isVerified: map['isVerified'] as bool? ?? false,
      isActiveByCompanyAdmin: map['isActiveByCompanyAdmin'] as bool? ?? true,
      averageRating: (map['averageRating'] as num?)?.toDouble() ?? 0.0,
      numberOfRatings: (map['numberOfRatings'] as num?)?.toInt() ?? 0,
      createdAt: map['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: map['updatedAt'] as Timestamp?, // يمكن أن يكون null إذا لم يتم تحديثه بعد
    );
  }
}

// Firestore Collection Name:
// static const String deliveryCompaniesCollection = "delivery_companies";
// اسم المستند داخل هذه المجموعة يمكن أن يكون هو `companyId` (الذي هو `adminUserId` غالباً)