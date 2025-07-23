import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // For Get.snackbar context
import 'package:get/get.dart';

import '../../Model/DeliveryCompanyModel.dart';

// افترض وجود هذه الملفات، قم بتعديل المسارات
// import '../../XXX/xxx_firebase.dart';
// import '../models/DeliveryCompanyModel.dart';
// import '../../controler/local-notification-onroller.dart'; // لإرسال الإشعارات

// مثال لـ FirebaseX
class FirebaseX {
  static String deliveryCompaniesCollection = "delivery_companies";
  static String usersCollection = "Usercodora"; // مجموعة المستخدمين لجلب توكن مشرف الشركة
  static String appName = "CodoraApp"; // اسم تطبيقك للإشعارات
}

class PendingCompaniesController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxList<DeliveryCompanyModel> pendingCompanies = <DeliveryCompanyModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPendingCompanies();
  }

  Future<void> fetchPendingCompanies() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      debugPrint("[ADMIN] Fetching pending companies...");
      final snapshot = await _firestore
          .collection(FirebaseX.deliveryCompaniesCollection)
          .where('isApprovedByPlatformAdmin', isEqualTo: false) // جلب الشركات غير الموافق عليها بعد
          .orderBy('createdAt', descending: true) // الأحدث أولاً
          .get();

      final companies = snapshot.docs
          .map((doc) => DeliveryCompanyModel.fromMap(doc.data(), doc.id))
          .toList();
      pendingCompanies.assignAll(companies);
      debugPrint("[ADMIN] Fetched ${pendingCompanies.length} pending companies.");
    } catch (e, s) {
      debugPrint("[ADMIN] Error fetching pending companies: $e\n$s");
      errorMessage.value = "خطأ في جلب طلبات الشركات: ${e.toString()}";
      pendingCompanies.clear(); // مسح القائمة عند الخطأ
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> approveCompany(String companyId, String companyAdminUserId, String companyName) async {
    isLoading.value = true; // يمكن استخدام مؤشر تحميل خاص لعملية الموافقة
    try {
      debugPrint("[ADMIN] Approving company: $companyId");
      await _firestore
          .collection(FirebaseX.deliveryCompaniesCollection)
          .doc(companyId)
          .update({'isApprovedByPlatformAdmin': true, 'updatedAt': FieldValue.serverTimestamp()});

      // تحديث القائمة في الواجهة
      pendingCompanies.removeWhere((company) => company.companyId == companyId);
      Get.snackbar("تمت الموافقة", "تمت الموافقة على شركة '$companyName' بنجاح.",
          backgroundColor: Colors.green, colorText: Colors.white);

      // إرسال إشعار لمشرف الشركة (اختياري)
      await _sendApprovalNotification(companyAdminUserId, companyName);

    } catch (e) {
      debugPrint("[ADMIN] Error approving company $companyId: $e");
      Get.snackbar("خطأ", "فشل الموافقة على الشركة: ${e.toString()}", backgroundColor: Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> rejectCompany(String companyId, String companyAdminUserId, String companyName, String rejectionReason) async {
    isLoading.value = true;
    try {
      debugPrint("[ADMIN] Rejecting company: $companyId with reason: $rejectionReason");
      // يمكنك إما حذف المستند أو تحديث حالته إلى "مرفوض"
      // الخيار الأول: تحديث الحالة (أفضل للاحتفاظ بالسجل)
      await _firestore
          .collection(FirebaseX.deliveryCompaniesCollection)
          .doc(companyId)
          .update({
        'isApprovedByPlatformAdmin': false, // قد ترغب في حقل جديد مثل 'applicationStatus'
        'platformAdminRejectionReason': rejectionReason, // حقل جديد لسبب الرفض
        'updatedAt': FieldValue.serverTimestamp()
      });
      // أو الخيار الثاني: الحذف (إذا كنت لا تريد الاحتفاظ بسجلات الشركات المرفوضة)
      // await _firestore.collection(FirebaseX.deliveryCompaniesCollection).doc(companyId).delete();


      pendingCompanies.removeWhere((company) => company.companyId == companyId);
      Get.snackbar("تم الرفض", "تم رفض طلب شركة '$companyName'.",
          backgroundColor: Colors.orange, colorText: Colors.white);

      // إرسال إشعار لمشرف الشركة بالرفض
      await _sendRejectionNotification(companyAdminUserId, companyName, rejectionReason);

    } catch (e) {
      debugPrint("[ADMIN] Error rejecting company $companyId: $e");
      Get.snackbar("خطأ", "فشل رفض الشركة: ${e.toString()}", backgroundColor: Colors.red);
    } finally {
      isLoading.value = false;
    }
  }


  Future<void> markAsVerified(String companyId, String companyName, bool currentVerifiedStatus) async {
    // isLoading.value = true; // مؤشر تحميل خاص
    try {
      debugPrint("[ADMIN] Marking company $companyId as verified: ${!currentVerifiedStatus}");
      await _firestore
          .collection(FirebaseX.deliveryCompaniesCollection)
          .doc(companyId)
          .update({'isVerified': !currentVerifiedStatus, 'updatedAt': FieldValue.serverTimestamp()});

      // تحديث العنصر في القائمة الحالية لعكس التغيير فورًا
      int index = pendingCompanies.indexWhere((c) => c.companyId == companyId);
      if (index != -1) {
        // إنشاء نسخة جديدة مع تحديث الحالة لتحديث Obx
        // هذا يفترض أن isApprovedByPlatformAdmin لا يزال false
        // إذا كانت هذه الشركات في قائمة منفصلة (موافق عليها)، عدل القائمة المناسبة
        var companyToUpdate = pendingCompanies[index];
        // Note: This local update of 'isVerified' might not be immediately visible
        // if the item is removed from the pending list upon approval.
        // This is more relevant for an "Approved Companies" list.
        // For now, we just update Firestore. Fetch will refresh the list if it's still pending.
      }


      Get.snackbar("تم التحديث", "تم تحديث حالة توثيق شركة '$companyName'.",
          backgroundColor: Colors.blue, colorText: Colors.white);
      fetchPendingCompanies(); // أعد جلب القائمة لضمان التحديث (أو حدث العنصر محليًا)
    } catch (e) {
      Get.snackbar("خطأ", "فشل تحديث حالة التوثيق: ${e.toString()}", backgroundColor: Colors.red);
    } finally {
      // isLoading.value = false;
    }
  }


  Future<void> _sendApprovalNotification(String companyAdminUserId, String companyName) async {
    try {
      DocumentSnapshot adminUserDoc = await _firestore.collection(FirebaseX.usersCollection).doc(companyAdminUserId).get();
      if (adminUserDoc.exists && adminUserDoc.data() != null) {
        final adminData = adminUserDoc.data() as Map<String, dynamic>;
        String? adminToken = adminData['fcmToken'] as String?; // افترض أن حقل التوكن اسمه 'fcmToken'
        if (adminToken != null && adminToken.isNotEmpty) {
          // استخدم خدمة الإشعارات لديك
          // await YourNotificationService.sendNotification(
          //   to: adminToken,
          //   title: "تهانينا! تمت الموافقة على شركتك",
          //   body: "تمت الموافقة على شركة '$companyName' ويمكنك الآن استقبال طلبات التوصيل وإدارة السائقين.",
          //   data: {'type': 'company_approved', 'companyId': companyAdminUserId}
          // );
          debugPrint("[ADMIN_NOTIF] Sent approval notification to company admin: $companyAdminUserId for company: $companyName");
          // مثال باستخدام LocalNotification (قد تحتاج لتعديله أو استخدام خدمة FCM مباشرة من سيرفر إذا أمكن)
          // await LocalNotification.sendNotificationMessageToUser(
          //     to: adminToken,
          //     title: "${FirebaseX.appName}: تمت الموافقة على شركتك!",
          //     body: "مرحباً ${companyName}, تم قبول طلب تسجيل شركتك في منصتنا.",
          //     uid: companyAdminUserId, // يمكن أن يكون companyId هنا
          //     type: "COMPANY_APPLICATION_APPROVED"
          // );
        } else {
          debugPrint("[ADMIN_NOTIF] FCM token not found for company admin: $companyAdminUserId");
        }
      }
    } catch (e) {
      debugPrint("[ADMIN_NOTIF] Error sending approval notification: $e");
    }
  }

  Future<void> _sendRejectionNotification(String companyAdminUserId, String companyName, String reason) async {
    try {
      DocumentSnapshot adminUserDoc = await _firestore.collection(FirebaseX.usersCollection).doc(companyAdminUserId).get();
      if (adminUserDoc.exists && adminUserDoc.data() != null) {
        final adminData = adminUserDoc.data() as Map<String, dynamic>;
        String? adminToken = adminData['fcmToken'] as String?;
        if (adminToken != null && adminToken.isNotEmpty) {
          // await YourNotificationService.sendNotification(
          //   to: adminToken,
          //   title: "تحديث بخصوص طلب تسجيل شركتك",
          //   body: "نأسف لإبلاغك برفض طلب تسجيل شركة '$companyName'. السبب: $reason",
          //   data: {'type': 'company_rejected', 'companyId': companyAdminUserId}
          // );
          debugPrint("[ADMIN_NOTIF] Sent rejection notification to company admin: $companyAdminUserId for company: $companyName");
        }
      }
    } catch(e){
      debugPrint("[ADMIN_NOTIF] Error sending rejection notification: $e");
    }
  }

}