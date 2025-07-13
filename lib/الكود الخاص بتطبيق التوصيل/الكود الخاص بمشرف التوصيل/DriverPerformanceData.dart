import 'package:flutter/foundation.dart'; // For @immutable

// يمكنك وضع هذا الكلاس في ملف خاص به، مثلاً: models/driver_performance_data.dart

@immutable // تشير إلى أن هذا الكائن غير قابل للتغيير بعد إنشائه (ممارسة جيدة للنماذج)
class DriverPerformanceData {
  final String driverId; // معرف السائق الفريد (UID)
  final String driverName; // اسم السائق للعرض
  final String? driverProfileImageUrl; // رابط صورة الملف الشخصي للسائق (اختياري)

  final int completedTasks; // إجمالي عدد المهام المكتملة خلال الفترة المحددة
  final String averageDeliveryTimeFormatted; // متوسط وقت التوصيل (من الاستلام للتسليم) كنص منسق (مثل: "25 دقيقة")
  final double averageDeliveryTimeSeconds; // نفس متوسط وقت التوصيل ولكن بالثواني (للفرز أو الحسابات)

  final String? averageAssignToPickupTimeFormatted; // متوسط الوقت من تعيين المهمة حتى استلامها من البائع (نص منسق)
  final double? averageAssignToPickupTimeSeconds; // نفس الوقت بالثواني (اختياري)

  final double totalFeesGenerated; // إجمالي رسوم التوصيل التي حققها هذا السائق للشركة (إذا كان منطبقًا)
  final double? totalDistanceCoveredKm; // إجمالي المسافة المقطوعة بالكيلومتر (اختياري)
  final double driverOverallRating; // متوسط تقييم السائق العام (من ملفه الشخصي)
  final int driverTotalRatings; // إجمالي عدد التقييمات التي حصل عليها السائق (من ملفه الشخصي)

  const DriverPerformanceData({
    required this.driverId,
    required this.driverName,
    this.driverProfileImageUrl,
    required this.completedTasks,
    required this.averageDeliveryTimeFormatted,
    required this.averageDeliveryTimeSeconds,
    this.averageAssignToPickupTimeFormatted,
    this.averageAssignToPickupTimeSeconds,
    required this.totalFeesGenerated,
    this.totalDistanceCoveredKm,
    required this.driverOverallRating,
    required this.driverTotalRatings,
  });

  // --- يمكن إضافة دوال مساعدة هنا إذا احتجت ---

  // مثال: الحصول على نسبة إنجاز المهام إذا كان هناك إجمالي مهام متوقع للسائق
  // double get taskCompletionRate {
  //   if (totalAssignedTasks > 0) { // افترض وجود totalAssignedTasks
  //     return (completedTasks / totalAssignedTasks) * 100;
  //   }
  //   return 0.0;
  // }

  // --- دوال المصنع (Factory constructors) أو copyWith إذا لزم الأمر ---
  // (copyWith ليست ضرورية جدًا لهذا النموذج إذا كان يتم إنشاؤه فقط للعرض)

  // --- لتحويل هذا الكائن إلى Map إذا احتجت لتخزينه (عادة لا يتم تخزين هذا النموذج المحسوب مباشرة) ---
  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'driverName': driverName,
      'driverProfileImageUrl': driverProfileImageUrl,
      'completedTasks': completedTasks,
      'averageDeliveryTimeFormatted': averageDeliveryTimeFormatted,
      'averageDeliveryTimeSeconds': averageDeliveryTimeSeconds,
      'averageAssignToPickupTimeFormatted': averageAssignToPickupTimeFormatted,
      'averageAssignToPickupTimeSeconds': averageAssignToPickupTimeSeconds,
      'totalFeesGenerated': totalFeesGenerated,
      'totalDistanceCoveredKm': totalDistanceCoveredKm,
      'driverOverallRating': driverOverallRating,
      'driverTotalRatings': driverTotalRatings,
    };
  }


  // --- للمقارنة والطباعة (اختياري ولكن مفيد) ---
  @override
  String toString() {
    return 'DriverPerformanceData(driverId: $driverId, driverName: $driverName, completedTasks: $completedTasks, avgDeliveryTime: $averageDeliveryTimeFormatted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DriverPerformanceData && other.driverId == driverId;
  }

  @override
  int get hashCode => driverId.hashCode;
}

// --- (اختياري) Enum لخيارات الفرز إذا كنت ستستخدمه بشكل متكرر ---
// هذا الـ enum كان معرفًا في CompanyReportsController، يمكنك تركه هناك أو نقله لملف مركزي
// enum DriverSortOption {
//   completedTasksDesc,
//   completedTasksAsc,
//   avgTimeDesc, // الأسرع (وقت أقل)
//   avgTimeAsc,  // الأبطأ (وقت أكبر)
//   nameAsc,
//   ratingDesc,
//   distanceDesc,
// }