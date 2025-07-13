

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../الكود الخاص بعامل/DeliveryDriverModel.dart';

class DriverMapInfoDialog extends StatelessWidget {
  final DeliveryDriverModel driver;

  const DriverMapInfoDialog({super.key, required this.driver});

  // دالة مساعدة لترجمة حالة السائق إلى نص عربي ولون
  Map<String, dynamic> _getDriverStatusInfo(String statusKey, BuildContext context) {
    final theme = Theme.of(context);
    switch (statusKey.toLowerCase()) {
      case "online_available":
        return {"text": "متوفر الآن", "color": Colors.green.shade600, "icon": Icons.check_circle_outline_rounded};
      case "on_task":
        return {"text": "في مهمة توصيل", "color": Colors.orange.shade700, "icon": Icons.delivery_dining_outlined};
      case "offline":
        return {"text": "غير متوفر (أوفلاين)", "color": Colors.red.shade600, "icon": Icons.power_settings_new_rounded};
      default:
        return {"text": statusKey, "color": Colors.grey.shade700, "icon": Icons.help_outline_rounded};
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusInfo = _getDriverStatusInfo(driver.availabilityStatus, context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      contentPadding: const EdgeInsets.all(0), // سنتحكم في الـ padding يدويًا
      backgroundColor: theme.cardColor, // استخدام لون بطاقة الثيم
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min, // اجعل الحوار صغيرًا قدر الإمكان
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- الجزء العلوي مع الصورة والاسم ---
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: statusInfo['color'] ?? theme.primaryColor, // لون الحالة أو اللون الأساسي
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.white.withOpacity(0.8),
                    backgroundImage: driver.profileImageUrl != null && driver.profileImageUrl!.isNotEmpty
                        ? CachedNetworkImageProvider(driver.profileImageUrl!)
                        : null,
                    child: (driver.profileImageUrl == null || driver.profileImageUrl!.isEmpty)
                        ? Icon(Icons.person, size: 45, color: Colors.grey.shade600)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    driver.name,
                    style: Get.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "سائق توصيل", // أو "مندوب توصيل"
                    style: Get.textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.85)),
                  ),
                ],
              ),
            ),

            // --- قسم تفاصيل الحالة والتقييم ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // حالة السائق
                  Row(
                    children: [
                      Icon(statusInfo['icon'] ?? Icons.info_outline, color: statusInfo['color'] ?? theme.primaryColor, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          statusInfo['text'] ?? "غير معروف",
                          style: Get.textTheme.titleMedium?.copyWith(
                            color: statusInfo['color'] ?? theme.textTheme.bodyLarge?.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // التقييم
                  Row(
                    children: [
                      Icon(Icons.star_rate_rounded, color: Colors.amber.shade600, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        driver.averageRating.toStringAsFixed(1),
                        style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "(${driver.numberOfRatings} تقييم)",
                        style: Get.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // نوع المركبة
                  Row(
                    children: [
                      Icon(
                          driver.vehicleType.toLowerCase().contains("دراجة نارية") || driver.vehicleType.toLowerCase().contains("motorcycle")
                              ? Icons.two_wheeler_rounded
                              : (driver.vehicleType.toLowerCase().contains("سيارة") || driver.vehicleType.toLowerCase().contains("car")
                              ? Icons.directions_car_filled_rounded
                              : Icons.pedal_bike_rounded), // أيقونة افتراضية لدراجة هوائية أو أيقونة عامة
                          color: theme.iconTheme.color?.withOpacity(0.7), size: 20
                      ),
                      const SizedBox(width: 8),
                      Text(
                        driver.vehicleType,
                        style: Get.textTheme.bodyLarge?.copyWith(color: Colors.black87),
                      ),
                    ],
                  ),

                  // (اختياري) إذا كان السائق في مهمة حالية، يمكن عرض رقم المهمة أو زر للتفاصيل
                  if (driver.availabilityStatus.toLowerCase() == "on_task" && driver.currentFocusedTaskId != null && driver.currentFocusedTaskId!.isNotEmpty) ...[ // <--- إضافة تحقق أن currentTaskId ليس فارغًا أيضًا
                    const SizedBox(height: 10),
                    const Divider(),
                    const SizedBox(height: 10),
                    Text("المهمة الحالية:", style: Get.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    Text("رقم المهمة: ${driver.currentFocusedTaskId!.length > 8 ? '${driver.currentFocusedTaskId!.substring(0,8)}...' : driver.currentFocusedTaskId!}"), // <--- الوصول للحقل الآن صحيح
                    TextButton(
                      onPressed: () {
                        Get.back(); // أغلق الحوار الحالي
                        // تأكد أن لديك مسارًا مُعرفًا لـ DeliveryTaskDetailsForAdminScreen
                        Get.toNamed('/admin/task-details/${driver.currentFocusedTaskId!}');
                        // Get.snackbar("إجراء", "عرض تفاصيل المهمة ${driver.currentTaskId}"); // للتشخيص إذا لزم الأمر
                      },
                      child: const Text("عرض تفاصيل المهمة الحالية"),
                    ),
                  ],
                ],
              ),
            ),

            const Divider(height: 1, thickness: 0.5),

            // --- الأزرار (الإجراءات) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround, // أو .end أو .spaceEvenly
                children: [
                  TextButton(
                    onPressed: () {
                      Get.back(); // إغلاق الحوار
                      Get.toNamed('/admin/driver-profile/${driver.uid}');
                      // Get.to(() => ChatWithDriverScreen(driverId: driver.uid, driverName: driver.name));
                      // Get.snackbar("إجراء", "إرسال رسالة إلى ${driver.name} (لم تنفذ بعد)");
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.message_outlined, color: theme.primaryColor),
                        const SizedBox(height:4),
                        Text("مراسلة", style: TextStyle(color: theme.primaryColor, fontSize: 12)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Get.back(); // إغلاق الحوار
                      // يمكنك إضافة منطق هنا مثل عرض الملف الشخصي الكامل للسائق
                      // Get.to(() => FullDriverProfileScreenForAdmin(driverId: driver.uid));
                      Get.snackbar("إجراء", "عرض الملف الشخصي الكامل لـ ${driver.name} (لم تنفذ بعد)");
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_search_outlined, color: theme.colorScheme.secondary),
                        const SizedBox(height:4),
                        Text("ملف السائق", style: TextStyle(color: theme.colorScheme.secondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  // يمكنك إضافة المزيد من الأزرار هنا حسب الحاجة
                ],
              ),
            )
          ],
        ),
      ),
      // يمكنك إزالة هذا إذا كنت تفضل الإغلاق من خلال أيقونة X في الأعلى
      // actions: [
      //   TextButton(
      //     onPressed: () => Get.back(),
      //     child: const Text("إغلاق"),
      //   ),
      // ],
    );
  }
}