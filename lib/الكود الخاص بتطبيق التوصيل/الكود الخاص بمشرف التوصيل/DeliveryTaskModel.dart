import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // إذا كنت ستضيف دوال مساعدة LatLng

// --- تحديث enum DeliveryTaskStatus ---
enum DeliveryTaskStatus {
  // المرحلة 1: المهمة تنتظر شركة توصيل
  pending_platform_assignment,  // بانتظار منصتك لتعيينها لشركة، أو لفتحها للمطالبة
  company_pickup_request,       // معروضة للشركات المؤهلة للمطالبة بها (بعد أن يوافق البائع)
  available_for_company_drivers,
  // المرحلة 2: المهمة مع شركة معينة، تنتظر سائقًا
  pending_driver_assignment,    // الشركة طالبت/عُينت لها المهمة، وتنتظر تعيين سائق داخليًا
  ready_for_driver_offers_narrow, // تم عرضها من الشركة على السائقين القريبين (مهلة زمنية)
  ready_for_driver_offers_wide,   // تم عرضها من الشركة على جميع سائقيها في المحافظة (بعد انتهاء المهلة الضيقة أو مباشرة)

  // المرحلة 3: تم تعيين سائق وبدأت عملية التوصيل
  driver_assigned,                // تم تعيين سائق (يدويًا أو بقبول السائق للعرض)
  en_route_to_pickup,             // السائق في الطريق إلى البائع
  picked_up_from_seller,          // استلم السائق الطلب من البائع
  out_for_delivery_to_buyer,      // السائق في الطريق إلى المشتري
  at_buyer_location,              // السائق وصل إلى موقع المشتري

  // المرحلة 4: اكتمال المهمة أو فشلها
  delivered,                      // تم التسليم بنجاح
  delivery_failed,                // فشل التسليم (مع سبب)
  returned_to_seller,             // إذا فشل التسليم وتم إرجاعها للبائع

  // المرحلة 5: الإلغاءات
  cancelled_by_seller,            // ألغاها البائع
  cancelled_by_buyer,             // ألغاها المشتري
  cancelled_by_company_admin,     // ألغاها مشرف شركة التوصيل
  cancelled_by_platform_admin,    // ألغاها مشرف التطبيق (أنت)
  en_route_to_hub,         // السائق استلم من البائع وهو الآن في طريقه إلى مقر شركة التوصيل
  dropped_at_hub,          // السائق سلم الشحنة بنجاح في المقر (مهمة السائق الأول انتهت هنا)

  // (اختياري) حالة لإعادة التعيين اليدوي إذا لم تكن covered by pending_driver_assignment
  // needs_manual_reassignment, // (هذه يمكن دمجها مع pending_driver_assignment إذا كان نفس التدفق)
}
// -------------------------------------

// دوال التحويل (يفضل أن تكون في نفس الملف أو ملف utils مشترك)
String deliveryTaskStatusToString(DeliveryTaskStatus status) => status.toString().split('.').last;

DeliveryTaskStatus stringToDeliveryTaskStatus(String? statusStr) {
  if (statusStr == null || statusStr.isEmpty) {
    // اختر حالة افتراضية أكثر منطقية لبداية المهمة إذا كانت السلسلة فارغة
    return DeliveryTaskStatus.pending_platform_assignment;
  }
  return DeliveryTaskStatus.values.firstWhere(
          (e) => e.toString().split('.').last.toLowerCase() == statusStr.toLowerCase(),
      orElse: () {
        debugPrint("WARNING: Unknown DeliveryTaskStatus string '$statusStr', defaulting to pending_platform_assignment.");
        return DeliveryTaskStatus.pending_platform_assignment;
      }
  );
}

class DeliveryTaskModel {
  final String taskId;
  final String orderId; // معرف الطلب الأصلي من تطبيق المشتري
  final String sellerId;
  final String buyerId;

  // --- معلومات الاستلام والتسليم ---
  final String? sellerName;
  final String? sellerPhoneNumber;
  final String? sellerShopName;
  final GeoPoint? pickupLocationGeoPoint;
  final String? pickupAddressText;

  final String? buyerName;
  final String? buyerPhoneNumber;
  final GeoPoint? deliveryLocationGeoPoint;
  final String? deliveryAddressText;
  final String? deliveryInstructions; // تعليمات خاصة من المشتري
  final bool isHubToHubTransfer;          // <--- جديد: لتحديد نوع المهمة
  final String? originHubName;             // <--- جديد: اسم المقر المصدر (يمكن أن يحل محل sellerName لهذه المهام)
  final String? destinationHubName;        // <--- جديد: اسم المقر الوجهة (يمكن أن يحل محل buyerName لهذه المهام)
  final List<String>? relatedConsolidatedPackageIds; // <--- جديد (اختياري): IDs الطرود المجمعة داخل شحنة النقل هذه.
  // --- معلومات التعيين ---
  String? assignedCompanyId;
  String? assignedCompanyName;
  String? assignedToDriverId; // UID للسائق
  String? driverName;         // اسم السائق
  String? driverPhoneNumber;  // رقم هاتف السائق (للتواصل من البائع/المشتري)

  // --- الحالة والأوقات ---
  DeliveryTaskStatus status;
  final Timestamp createdAt;
  Timestamp? assignTimeToDriver;
  Timestamp? driverOfferExpiryTime; // (للمهام التي تُعرض على السائقين)
  Timestamp? estimatedPickupTime;
  Timestamp? actualPickupTime;         // الوقت الفعلي الذي ضغط فيه السائق "تم الاستلام من البائع"
  Timestamp? estimatedDeliveryTime;
  Timestamp? deliveryConfirmationTime; // الوقت الفعلي لتأكيد التسليم من المشتري
  Timestamp? updatedAt;

  // --- تفاصيل الطلب/المهمة ---
  final List<Map<String, dynamic>>? itemsSummary; // [{ 'itemId': 'xyz', 'itemName': '...', 'quantity': 2, 'itemBarcode': 'BRCD123', 'scannedByDriverAtPickup': false/true }]
  final double? deliveryFee;
  final String? paymentMethod;          // e.g., 'cash_on_delivery', 'paid_online'
  final double? amountToCollect;      // المبلغ المطلوب تحصيله عند التسليم (إذا كان COD)
  final double? distanceTravelledKm;  // المسافة المقطوعة للمهمة (يمكن حسابها عند الاكتمال)
  final String? province;               // المحافظة (قد يفيد في فلترة مهام السائق)

  // --- الباركودات (مهم جداً للخطوة الحالية) ---
  final String? sellerMainPickupConfirmationBarcode; // <--- جديد: باركود رئيسي للمهمة يقدمه البائع إذا لم يتم مسح كل منتج. (اختياري)
  // إذا تم توفيره، يمكن للسائق مسحه بدلاً من مسح كل المنتجات (للسيناريوهات البسيطة).
  String? buyerConfirmationBarcode;  // <--- سيبقى: باركود يقدمه المشتري للتسليم (في البداية قد يكون orderId).

  // --- لتتبع المنتجات الفردية عند الاستلام ---
  // كل عنصر هنا يجب أن يتوافق مع عنصر في itemsSummary إذا كان التتبع دقيقًا
  // أو يمكن أن يكون itemsSummary نفسه هو المصدر الوحيد ونضيف له scannedStatus.
  // للحفاظ على البساطة الأولية، يمكننا إضافة حالة المسح لـ itemsSummary.
  // إذا فصلناها، هكذا ستبدو:
  // List<Map<String, dynamic>>? individualItemPickupStatus; // [{ 'itemBarcode': 'BRCD123', 'status': 'pending'/'scanned'/'missing'}]

  // --- التجميع وقرار السائق (للمراحل اللاحقة) ---
  String? driverPickupDecision;        // <--- جديد: (e.g., 'direct_delivery', 'hub_dropoff')
  String? hubIdDroppedOffAt;           // <--- جديد: ID مركز التجميع الذي تم تسليم الشحنة إليه
  Timestamp? hubDropOffTime;           // <--- جديد: وقت تسليم الشحنة للمركز

  // --- الإلغاء والفشل والإثبات ---
  String? failureOrCancellationReason;
  String? cancelledByEntityType;
  String? cancelledByEntityId;
  String? deliveryProofImageUrl;
  List<String>? taskNotesInternal;      // ملاحظات النظام أو المشرف على المهمة

  DeliveryTaskModel({
    required this.taskId,
    required this.orderId,
    required this.sellerId,
    required this.buyerId,
    this.sellerName,
    this.sellerPhoneNumber,
    this.isHubToHubTransfer = false,      // <--- القيمة الافتراضية
    this.originHubName,
    this.destinationHubName,
    this.relatedConsolidatedPackageIds,
    this.sellerShopName,
    this.pickupLocationGeoPoint,
    this.pickupAddressText,
    this.buyerName,
    this.buyerPhoneNumber,
    this.deliveryLocationGeoPoint,
    this.deliveryAddressText,
    this.deliveryInstructions,
    this.assignedCompanyId,
    this.assignedCompanyName,
    this.assignedToDriverId,
    this.driverName,
    this.driverPhoneNumber,
    required this.status,
    required this.createdAt,
    this.assignTimeToDriver,
    this.driverOfferExpiryTime,
    this.estimatedPickupTime,
    this.actualPickupTime,
    this.estimatedDeliveryTime,
    this.deliveryConfirmationTime,
    this.updatedAt,
    this.itemsSummary,
    this.deliveryFee,
    this.paymentMethod,
    this.amountToCollect,
    this.distanceTravelledKm,
    this.province,
    this.sellerMainPickupConfirmationBarcode, // <--- إضافة للمُنشئ
    this.buyerConfirmationBarcode,
    // this.individualItemPickupStatus,
    this.driverPickupDecision,                // <--- إضافة
    this.hubIdDroppedOffAt,                   // <--- إضافة
    this.hubDropOffTime,                      // <--- إضافة
    this.failureOrCancellationReason,
    this.cancelledByEntityType,
    this.cancelledByEntityId,
    this.deliveryProofImageUrl,
    this.taskNotesInternal,
  });

  // Getters
  LatLng? get pickupLatLng => pickupLocationGeoPoint != null 
      ? LatLng(pickupLocationGeoPoint!.latitude, pickupLocationGeoPoint!.longitude) 
      : null;
  LatLng? get deliveryLatLng => deliveryLocationGeoPoint != null 
      ? LatLng(deliveryLocationGeoPoint!.latitude, deliveryLocationGeoPoint!.longitude) 
      : null;
  String get orderIdShort => orderId.length > 8 ? '${orderId.substring(0, 8)}...' : orderId;
  bool get isActionableByAdmin {
    // هذه الدالة تُرجع true إذا كانت المهمة *ليست* في حالة نهائية تمامًا.
    // المشرف قد يرغب في اتخاذ إجراء (مثل إعادة محاولة، أو تأكيد الإرجاع)
    // حتى لبعض الحالات التي تعتبر "شبه نهائية".
    // اضبط هذه القائمة حسب ما تراه مناسبًا لعمليات مشرفك.
    return !(
        status == DeliveryTaskStatus.delivered || // إذا تم التسليم بنجاح، لا يمكن للمشرف فعل الكثير
            status == DeliveryTaskStatus.returned_to_seller || // إذا أُرجعت بالكامل، قد تكون هناك إجراءات تتبع ولكن ليس تغيير السائق مثلاً
            status == DeliveryTaskStatus.cancelled_by_platform_admin // إذا ألغاها مشرف المنصة، فهي منتهية
        // يمكنك إضافة حالات إلغاء أخرى إذا كنت تعتبرها نهائية تمامًا من منظور المشرف
        // status == DeliveryTaskStatus.cancelled_by_buyer ||
        // status == DeliveryTaskStatus.cancelled_by_seller ||
        // status == DeliveryTaskStatus.cancelled_by_company_admin
    );
    // مثال بديل أكثر تقييدًا: يسمح بالإجراء فقط إذا لم يتم تسليمها أو إلغاؤها بشكل نهائي
    /*
    return !(
        status == DeliveryTaskStatus.delivered ||
        status == DeliveryTaskStatus.cancelled_by_seller ||
        status == DeliveryTaskStatus.cancelled_by_buyer ||
        status == DeliveryTaskStatus.cancelled_by_company_admin ||
        status == DeliveryTaskStatus.cancelled_by_platform_admin
    );
    */
  }


  Map<String, dynamic> toMap() {
    return {
      'isHubToHubTransfer': isHubToHubTransfer,
      'originHubName': originHubName,
      'destinationHubName': destinationHubName,
      'relatedConsolidatedPackageIds': relatedConsolidatedPackageIds,
      'orderId': orderId, 'sellerId': sellerId, 'buyerId': buyerId,
      'sellerName': sellerName, 'sellerPhoneNumber': sellerPhoneNumber, 'sellerShopName': sellerShopName,
      'pickupLocationGeoPoint': pickupLocationGeoPoint, 'pickupAddressText': pickupAddressText,
      'buyerName': buyerName, 'buyerPhoneNumber': buyerPhoneNumber,
      'deliveryLocationGeoPoint': deliveryLocationGeoPoint, 'deliveryAddressText': deliveryAddressText,
      'deliveryInstructions': deliveryInstructions,
      'assignedCompanyId': assignedCompanyId, 'assignedCompanyName': assignedCompanyName,
      'assignedToDriverId': assignedToDriverId, 'driverName': driverName, 'driverPhoneNumber': driverPhoneNumber,
      'status': deliveryTaskStatusToString(status),
      'createdAt': createdAt,
      'assignTimeToDriver': assignTimeToDriver, 'driverOfferExpiryTime': driverOfferExpiryTime,
      'estimatedPickupTime': estimatedPickupTime, 'actualPickupTime': actualPickupTime,
      'estimatedDeliveryTime': estimatedDeliveryTime, 'deliveryConfirmationTime': deliveryConfirmationTime,
      'updatedAt': FieldValue.serverTimestamp(),
      'itemsSummary': itemsSummary, // <--- تأكد من تعديل هذا
      'deliveryFee': deliveryFee, 'paymentMethod': paymentMethod, 'amountToCollect': amountToCollect,
      'distanceTravelledKm': distanceTravelledKm, 'province': province,
      'sellerMainPickupConfirmationBarcode': sellerMainPickupConfirmationBarcode, // <--- إضافة
      'buyerConfirmationBarcode': buyerConfirmationBarcode,
      // 'individualItemPickupStatus': individualItemPickupStatus,
      'driverPickupDecision': driverPickupDecision,                // <--- إضافة
      'hubIdDroppedOffAt': hubIdDroppedOffAt,                   // <--- إضافة
      'hubDropOffTime': hubDropOffTime,                         // <--- إضافة
      'failureOrCancellationReason': failureOrCancellationReason,
      'cancelledByEntityType': cancelledByEntityType, 'cancelledByEntityId': cancelledByEntityId,
      'deliveryProofImageUrl': deliveryProofImageUrl, 'taskNotesInternal': taskNotesInternal,
    };
  }

  factory DeliveryTaskModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    Map<String, dynamic> data = doc.data()!;
    List<Map<String, dynamic>>? items;
    if (data['itemsSummary'] != null) {
      items = (data['itemsSummary'] as List<dynamic>)
          .map((item) {
        // تأكد من أن كل عنصر هو Map وأضف القيم الافتراضية إذا لزم الأمر
        if (item is Map) {
          return {
            'itemId': item['itemId'] as String? ?? 'unknown_item_id',
            'itemName': item['itemName'] as String? ?? 'منتج غير معروف',
            'quantity': (item['quantity'] as num?)?.toInt() ?? 1,
            'itemBarcode': item['itemBarcode'] as String? ?? '', // الباركود الفردي
            'scannedByDriverAtPickup': item['scannedByDriverAtPickup'] as bool? ?? false, // حالة المسح
            // ... أي حقول أخرى للعنصر
          };
        }
        return <String, dynamic>{}; // عنصر فارغ إذا لم يكن map
      })
          .where((itemMap) => itemMap.isNotEmpty) // تجاهل أي عناصر فارغة نتجت عن cast خاطئ
          .toList();
    }


    return DeliveryTaskModel(
      taskId: doc.id,
      isHubToHubTransfer: data['isHubToHubTransfer'] as bool? ?? false,
      originHubName: data['originHubName'] as String?,
      destinationHubName: data['destinationHubName'] as String?,
      relatedConsolidatedPackageIds: (data['relatedConsolidatedPackageIds'] as List<dynamic>?)?.map((e) => e as String).toList(),
      orderId: data['orderId'] as String? ?? '',
      sellerId: data['sellerId'] as String? ?? '',
      buyerId: data['buyerId'] as String? ?? '',
      sellerName: data['sellerName'] as String?,
      sellerPhoneNumber: data['sellerPhoneNumber'] as String?,
      sellerShopName: data['sellerShopName'] as String?,
      pickupLocationGeoPoint: data['pickupLocationGeoPoint'] as GeoPoint?,
      pickupAddressText: data['pickupAddressText'] as String?,
      buyerName: data['buyerName'] as String?,
      buyerPhoneNumber: data['buyerPhoneNumber'] as String?,
      deliveryLocationGeoPoint: data['deliveryLocationGeoPoint'] as GeoPoint?,
      deliveryAddressText: data['deliveryAddressText'] as String?,
      deliveryInstructions: data['deliveryInstructions'] as String?,
      assignedCompanyId: data['assignedCompanyId'] as String?,
      assignedCompanyName: data['assignedCompanyName'] as String?,
      assignedToDriverId: data['assignedToDriverId'] as String?,
      driverName: data['driverName'] as String?,
      driverPhoneNumber: data['driverPhoneNumber'] as String?,
      status: stringToDeliveryTaskStatus(data['status'] as String?),
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      assignTimeToDriver: data['assignTimeToDriver'] as Timestamp?,
      driverOfferExpiryTime: data['driverOfferExpiryTime'] as Timestamp?,
      estimatedPickupTime: data['estimatedPickupTime'] as Timestamp?,
      actualPickupTime: data['actualPickupTime'] as Timestamp?,
      estimatedDeliveryTime: data['estimatedDeliveryTime'] as Timestamp?,
      deliveryConfirmationTime: data['deliveryConfirmationTime'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
      itemsSummary: items, // استخدام items المعالجة
      deliveryFee: (data['deliveryFee'] as num?)?.toDouble(),
      paymentMethod: data['paymentMethod'] as String?,
      amountToCollect: (data['amountToCollect'] as num?)?.toDouble(),
      distanceTravelledKm: (data['distanceTravelledKm'] as num?)?.toDouble(),
      province: data['province'] as String?,
      sellerMainPickupConfirmationBarcode: data['sellerMainPickupConfirmationBarcode'] as String?, // <--- قراءة
      buyerConfirmationBarcode: data['buyerConfirmationBarcode'] as String?,
      // individualItemPickupStatus: (data['individualItemPickupStatus'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList(),
      driverPickupDecision: data['driverPickupDecision'] as String?,                // <--- قراءة
      hubIdDroppedOffAt: data['hubIdDroppedOffAt'] as String?,                   // <--- قراءة
      hubDropOffTime: data['hubDropOffTime'] as Timestamp?,                         // <--- قراءة
      failureOrCancellationReason: data['failureOrCancellationReason'] as String?,
      cancelledByEntityType: data['cancelledByEntityType'] as String?,
      cancelledByEntityId: data['cancelledByEntityId'] as String?,
      deliveryProofImageUrl: data['deliveryProofImageUrl'] as String?,
      taskNotesInternal: (data['taskNotesInternal'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );
  }
}