import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// إذا كنت ستحصل على companyId من هنا
import 'package:flutter/material.dart'; // لـ Get.dialog context
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../XXX/xxx_firebase.dart';
import '../../routes/app_routes.dart';
import '../الكود الخاص بعامل/DeliveryDriverModel.dart';
import 'CompanyAdminDashboardController.dart';



class DriverApplicationReviewController extends GetxController {
  final String companyId; // ID للشركة الحالية التي يديرها المشرف
  DriverApplicationReviewController({required this.companyId});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxList<DeliveryDriverModel> pendingApplications = <DeliveryDriverModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  final TextEditingController rejectionReasonController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    if (companyId.isEmpty) {
      errorMessage.value = "خطأ: لم يتم توفير معرف الشركة للمراجعة.";
      isLoading.value = false;
      debugPrint("[DRIVER_APPS_CTRL] Error: Company ID is empty in onInit.");
      return;
    }
    fetchPendingApplications();
  }

  Future<void> fetchPendingApplications() async {
    if (companyId.isEmpty) {
      debugPrint("[DRIVER_APPS_CTRL] Cannot fetch, company ID is empty.");
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    errorMessage.value = '';
    try {
      debugPrint("[DRIVER_APPS_CTRL] Fetching pending applications for company: $companyId");
      final snapshot = await _firestore
          .collection(FirebaseX.deliveryDriversCollection)
          .where('requestedCompanyId', isEqualTo: companyId)
          .where('applicationStatus', isEqualTo: driverApplicationStatusToString(DriverApplicationStatus.pending))
          .orderBy('createdAt', descending: true)
          .get();

      final applications = snapshot.docs
          .map((doc) => DeliveryDriverModel.fromMap(doc.data(), doc.id)) // تأكد من الـ Cast
          .toList();
      pendingApplications.assignAll(applications);
      debugPrint("[DRIVER_APPS_CTRL] Fetched ${pendingApplications.length} pending applications.");
    } catch (e, s) {
      debugPrint("[DRIVER_APPS_CTRL] Error fetching pending applications: $e\n$s");
      errorMessage.value = "خطأ في جلب طلبات الانضمام: ${e.toString()}";
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _updateDriverApplicationStatus({
    required String driverUid,
    required DriverApplicationStatus newStatus,
    required String driverName, // لرسالة النجاح/الفشل
    String? reason, // سبب الرفض أو التعليق
  }) async {
    // يمكنك إضافة مؤشر تحميل خاص لكل عملية قبول/رفض إذا أردت
    // Get.dialog(Center(child: CircularProgressIndicator()), barrierDismissible: false);
    debugPrint("[DRIVER_APPS_CTRL] Updating status for driver $driverUid to ${driverApplicationStatusToString(newStatus)}");
    try {
      Map<String, dynamic> updateData = {
        'applicationStatus': driverApplicationStatusToString(newStatus),
        'applicationStatusUpdatedAt': FieldValue.serverTimestamp(),
      };

      if (newStatus == DriverApplicationStatus.approved) {
        updateData['approvedCompanyId'] = companyId; // تعيين الشركة الموافِقة
        updateData['rejectionReason'] = null; // مسح أي سبب رفض سابق
        // يمكن تحديث availabilityStatus إلى 'offline' أو 'online_available' إذا أردت
        // updateData['availabilityStatus'] = "offline";
      } else if (newStatus == DriverApplicationStatus.rejected) {
        updateData['rejectionReason'] = reason;
        updateData['approvedCompanyId'] = null; // التأكد من أنه ليس معتمدًا
      }
      // يمكنك إضافة حالات أخرى مثل suspended

      await _firestore
          .collection(FirebaseX.deliveryDriversCollection)
          .doc(driverUid)
          .update(updateData);

      // إزالة الطلب من القائمة المحلية (أو تحديثه إذا أردت الاحتفاظ به مع حالة جديدة)
      pendingApplications.removeWhere((app) => app.uid == driverUid);
      // إذا كانت لديك قائمة للسائقين الموافق عليهم/المرفوضين، أضف إليها
      Get.snackbar("تم بنجاح", "تم ${newStatus == DriverApplicationStatus.approved ? 'قبول' : 'رفض'} طلب السائق $driverName.",
          backgroundColor: newStatus == DriverApplicationStatus.approved ? Colors.green : Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM
      );

      // --- إرسال إشعار للسائق ---
      _sendNotificationToDriver(driverUid, newStatus, driverName, reason: reason);

    } catch (e,s) {
      debugPrint("[DRIVER_APPS_CTRL] Error updating driver $driverUid status: $e\n$s");
      Get.snackbar("خطأ", "فشل تحديث حالة طلب السائق: ${e.toString()}",
          backgroundColor: Colors.red, snackPosition: SnackPosition.BOTTOM);
    } finally {
      // if(Get.isDialogOpen ?? false) Get.back(); // أغلق مؤشر التحميل إذا أضفته
    }
  }


  void showRejectionDialog(DeliveryDriverModel driverApp) {
    rejectionReasonController.clear(); // مسح أي سبب سابق
    Get.defaultDialog(
      title: "سبب رفض طلب: ${driverApp.name}",
      titlePadding: EdgeInsets.symmetric(vertical: 20, horizontal: 15),
      contentPadding: EdgeInsets.symmetric(horizontal: 15),
      content: TextField(
        controller: rejectionReasonController,
        decoration: InputDecoration(
          labelText: "أدخل سبب الرفض (مطلوب)",
          hintText: "مثال: معلومات غير مكتملة، لا توجد شواغر...",
          border: OutlineInputBorder(),
        ),
        maxLines: 3,
        minLines: 1,
        autofocus: true,
      ),
      confirm: ElevatedButton(
        onPressed: () {
          if (rejectionReasonController.text.trim().isNotEmpty) {
            Get.back(); // أغلق الحوار
            _updateDriverApplicationStatus(
                driverUid: driverApp.uid,
                newStatus: DriverApplicationStatus.rejected,
                driverName: driverApp.name,
                reason: rejectionReasonController.text.trim());
          } else {
            Get.snackbar("مطلوب", "يرجى إدخال سبب الرفض.", backgroundColor: Colors.orange.shade300, snackPosition: SnackPosition.TOP);
          }
        },
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400),
        child: Text("تأكيد الرفض", style: TextStyle(color: Colors.white)),
      ),
      cancel: TextButton(onPressed: () => Get.back(), child: Text("إلغاء")),
    );
  }

  void acceptDriverApplication(DeliveryDriverModel driverApp) {
    Get.defaultDialog(
        title: "تأكيد القبول",
        middleText: "هل أنت متأكد من قبول انضمام السائق ${driverApp.name} إلى شركتك؟",
        confirm: ElevatedButton(
            onPressed: () {
              Get.back(); // أغلق الحوار
              _updateDriverApplicationStatus(
                  driverUid: driverApp.uid,
                  newStatus: DriverApplicationStatus.approved,
                  driverName: driverApp.name
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600),
            child: Text("نعم، قبول", style: TextStyle(color:Colors.white))
        ),
        cancel: TextButton(onPressed: () => Get.back(), child: Text("إلغاء"))
    );

  }

  Future<void> _sendNotificationToDriver(String driverUid, DriverApplicationStatus status, String driverName, {String? reason}) async {
    try {
      DocumentSnapshot driverUserDoc = await _firestore.collection(FirebaseX.deliveryDriversCollection).doc(driverUid).get();
      // أو إذا كنت تخزن توكنات المستخدمين في مجموعة أخرى (مثل usersCollection) مع نفس الـ UID
      // DocumentSnapshot driverUserDoc = await _firestore.collection(FirebaseX.usersCollection).doc(driverUid).get();


      if (driverUserDoc.exists && driverUserDoc.data() != null) {
        final driverData = driverUserDoc.data() as Map<String, dynamic>;
        String? driverToken = driverData['fcmToken'] as String?; // افترض وجوده في مستند السائق

        if(driverToken != null && driverToken.isNotEmpty){
          String title = "";
          String body = "";

          if (status == DriverApplicationStatus.approved) {
            title = "تهانينا، $driverName!";
            body = "تم قبول طلب انضمامك إلى شركتنا. يمكنك الآن البدء في استقبال المهام.";
          } else if (status == DriverApplicationStatus.rejected) {
            title = "تحديث بخصوص طلب انضمامك";
            body = "نأسف لإبلاغك برفض طلب انضمامك. السبب: ${reason ?? 'غير محدد'}.";
          }

          if (title.isNotEmpty) {
            // استخدم خدمة الإشعارات لديك
            // await NotificationService.sendNotification(
            //     to: driverToken,
            //     title: title,
            //     body: body,
            //     data: {'type': 'driver_application_status', 'driverUid': driverUid, 'status': driverApplicationStatusToString(status)}
            // );
            debugPrint("[DRIVER_APPS_NOTIF] Sent status notification to driver $driverUid: $title");
          }
        } else {
          debugPrint("[DRIVER_APPS_NOTIF] FCM token not found for driver: $driverUid. Notification not sent.");
        }
      }
    } catch (e) {
      debugPrint("[DRIVER_APPS_NOTIF] Error sending status notification to driver $driverUid: $e");
    }
  }

  @override
  void onClose(){
    rejectionReasonController.dispose();
    super.onClose();
  }

}




class DriverApplicationReviewScreen extends GetView<DriverApplicationReviewController> {
  const DriverApplicationReviewScreen({super.key});

  // هذه الدالة ستُستخدم لبناء كل بطاقة طلب انضمام سائق
  Widget _buildApplicationCard(DeliveryDriverModel driverApp, BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: driverApp.profileImageUrl != null && driverApp.profileImageUrl!.isNotEmpty
                      ? CachedNetworkImageProvider(driverApp.profileImageUrl!)
                      : null,
                  child: (driverApp.profileImageUrl == null || driverApp.profileImageUrl!.isEmpty)
                      ? const Icon(Icons.person_pin_rounded, size: 35, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(driverApp.name, style: Get.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("نوع المركبة: ${driverApp.vehicleType}", style: Get.textTheme.bodyMedium?.copyWith(color: Colors.black54)),
                      const SizedBox(height: 4),
                      Text(
                        "تاريخ الطلب: ${DateFormat('yyyy/MM/dd', 'ar').format(driverApp.createdAt.toDate())}",
                        style: Get.textTheme.bodySmall?.copyWith(color: Colors.blueGrey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text("مراجعة التفاصيل"),
                  style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.primaryColor),
                      foregroundColor: theme.primaryColor,
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                  ),
                  onPressed: () {
                    // --- هنا الانتقال إلى شاشة الملف الشخصي الكامل للسائق ---
                    // نفترض أن لديك مسارًا مُعرفًا لـ FullDriverProfileAdminScreen
                    // وأن Binding الخاص به يأخذ driverId من Get.parameters
                    Get.toNamed(AppRoutes.ADMIN_DRIVER_PROFILE.replaceFirst(':driverId', driverApp.uid));
                    debugPrint("Navigating to review driver profile for UID: ${driverApp.uid}");
                  },
                ),
                Row(
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
                      label: const Text("رفض", style: TextStyle(color: Colors.redAccent)),
                      onPressed: () => controller.showRejectionDialog(driverApp),
                      style: TextButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 8)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text("قبول"),
                      onPressed: () => controller.acceptDriverApplication(driverApp),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600),
                    ),
                  ],
                )
              ],
            )
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    // التأكد من أن companyId تم تمريره بشكل صحيح للمتحكم (عبر Binding)
    // final String companyIdFromArgs = Get.arguments as String? ?? ''; //  مثال إذا مررته كـ argument
    // Get.put(DriverApplicationReviewController(companyId: companyIdFromArgs)); // الأفضل عبر Binding

    if (controller.companyId.isEmpty && !controller.isLoading.value) {
      return Scaffold(appBar: AppBar(title: const Text("مراجعة طلبات السائقين")), body: Center(child: Text(controller.errorMessage.value.isNotEmpty ? controller.errorMessage.value : "خطأ: لم يتم تحميل معرف الشركة.")));
    }


    return Scaffold(
      appBar: AppBar(
        title: const Text("مراجعة طلبات انضمام السائقين"),
        centerTitle: true,
        actions: [
          Obx(() => controller.isLoading.value
              ? const Padding(padding: EdgeInsets.all(16), child: SizedBox(width:20, height:20, child:CircularProgressIndicator(strokeWidth: 2, color:Colors.white)))
              : IconButton(icon: const Icon(Icons.refresh), onPressed: controller.fetchPendingApplications, tooltip: "تحديث القائمة")
          )
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.pendingApplications.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.errorMessage.value.isNotEmpty && controller.pendingApplications.isEmpty) {
          return Center(
              child: Padding(padding: const EdgeInsets.all(16),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(controller.errorMessage.value, style: TextStyle(color: Colors.red.shade700)),
                    const SizedBox(height:10),
                    ElevatedButton(onPressed: controller.fetchPendingApplications, child: Text("إعادة المحاولة"))
                  ])));
        }
        if (controller.pendingApplications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_rounded, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text("لا توجد طلبات انضمام سائقين معلقة حاليًا.", style: TextStyle(fontSize: 17, color: Colors.grey)),
              ],
            ),
          );
        }
        // --- هنا يتم استخدام ListView.builder و _buildApplicationCard ---
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 70), // ترك مساحة لـ FAB إذا احتجت
          itemCount: controller.pendingApplications.length,
          itemBuilder: (context, index) {
            final driverApp = controller.pendingApplications[index];
            return _buildApplicationCard(driverApp, context); // <-- استدعاء الودجة المساعدة
          },
        );
      }),
    );
  }
}



