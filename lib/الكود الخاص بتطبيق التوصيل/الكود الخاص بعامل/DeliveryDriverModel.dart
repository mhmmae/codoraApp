// In your DeliveryDriverModel.dart file (أو ملف مشابه)

import 'package:cloud_firestore/cloud_firestore.dart';

import '../الكود الخاص بمشرف التوصيل/CompanyAdminDashboardController.dart';
// ... (other imports like enums for DriverApplicationStatus)
// افترض وجود CompanyAdminDashboardController.dart و DriverApplicationStatus معرفة

class DeliveryDriverModel {
  final String uid;
  final String name;
  final String? profileImageUrl;
  final String phoneNumber; // يجب أن يكون موثقًا
  final String vehicleType;
  final String? vehiclePlateNumber;
  final String? fcmToken;
  GeoPoint? currentLocation;
  String availabilityStatus; // "online_available", "on_task", "offline"

  final String? requestedCompanyId;
  String? approvedCompanyId;
  DriverApplicationStatus applicationStatus;
  String? rejectionReason;
  Timestamp? applicationStatusUpdatedAt;

  // --- الحقول الجديدة أو المعدلة ---
  // String? currentTaskId; // هذا الحقل قديم إذا كان السائق سيركز على مهمة واحدة للتنقل.
  // سنعتمد على currentFocusedTaskId
  String? currentFocusedTaskId; // <--- جديد: ID المهمة التي يتنقل إليها السائق حاليًا أو يركز عليها
  List<String>? activeTaskIds; // <--- جديد: قائمة بـ IDs لكل المهام "النشطة" (التي قبلها/عُينت له ولم تكتمل بعد)
  //      هذا الحقل ليس ضروريًا *في هذا النموذج بالذات* إذا كانت المهام النشطة
  //      يمكن الاستعلام عنها بـ assignedToDriverId == driver.uid
  //      وحالة نشطة. يمكن إبقاؤه اختياريًا كمرجع سريع، لكنه يزيد تعقيد المزامنة.
  //      **مقترح مبدئي: لنضعه اختياريًا ونرى إذا احتجناه بشدة.**
  // -----------------------------

  final double averageRating;
  final int numberOfRatings;
  final Timestamp createdAt;
  Timestamp? updatedAt; // ليس serverTimestamp هنا لأنه يتحدث مع البيانات

  DeliveryDriverModel({
    required this.uid,
    required this.name,
    this.profileImageUrl,
    required this.phoneNumber,
    required this.vehicleType,
    this.vehiclePlateNumber,
    this.fcmToken,
    this.currentLocation,
    this.availabilityStatus = "offline", // القيمة الافتراضية
    this.requestedCompanyId,
    this.approvedCompanyId,
    this.applicationStatus = DriverApplicationStatus.pending,
    this.rejectionReason,
    this.applicationStatusUpdatedAt,
    this.currentFocusedTaskId, // <--- إضافة للمُنشئ
    this.activeTaskIds,       // <--- إضافة للمُنشئ
    this.averageRating = 0.0,
    this.numberOfRatings = 0,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'profileImageUrl': profileImageUrl,
      'phoneNumber': phoneNumber,
      'vehicleType': vehicleType,
      'vehiclePlateNumber': vehiclePlateNumber,
      'fcmToken': fcmToken,
      'currentLocation': currentLocation,
      'availabilityStatus': availabilityStatus,
      'requestedCompanyId': requestedCompanyId,
      'approvedCompanyId': approvedCompanyId,
      'applicationStatus': driverApplicationStatusToString(applicationStatus),
      'rejectionReason': rejectionReason,
      'applicationStatusUpdatedAt': applicationStatusUpdatedAt,
      'currentFocusedTaskId': currentFocusedTaskId, // <--- إضافة لـ toMap
      'activeTaskIds': activeTaskIds,             // <--- إضافة لـ toMap (إذا استخدمناه)
      'averageRating': averageRating,
      'numberOfRatings': numberOfRatings,
      'createdAt': createdAt,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory DeliveryDriverModel.fromMap(Map<String, dynamic> map, String documentId) {
    return DeliveryDriverModel(
      uid: documentId,
      name: map['name'] as String? ?? '',
      profileImageUrl: map['profileImageUrl'] as String?,
      phoneNumber: map['phoneNumber'] as String? ?? '',
      vehicleType: map['vehicleType'] as String? ?? 'غير محدد',
      vehiclePlateNumber: map['vehiclePlateNumber'] as String?,
      fcmToken: map['fcmToken'] as String?,
      currentLocation: map['currentLocation'] as GeoPoint?,
      availabilityStatus: map['availabilityStatus'] as String? ?? 'offline',
      requestedCompanyId: map['requestedCompanyId'] as String?,
      approvedCompanyId: map['approvedCompanyId'] as String?,
      applicationStatus: stringToDriverApplicationStatus(map['applicationStatus'] as String?),
      rejectionReason: map['rejectionReason'] as String?,
      applicationStatusUpdatedAt: map['applicationStatusUpdatedAt'] as Timestamp?,
      currentFocusedTaskId: map['currentFocusedTaskId'] as String?, // <--- قراءة
      activeTaskIds: (map['activeTaskIds'] as List<dynamic>?)?.map((e) => e as String).toList(), // <--- قراءة (إذا استخدمناه)
      averageRating: (map['averageRating'] as num?)?.toDouble() ?? 0.0,
      numberOfRatings: (map['numberOfRatings'] as num?)?.toInt() ?? 0,
      createdAt: map['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: map['updatedAt'] as Timestamp?,
    );
  }
}