
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'CompanyDetailsDialog.dart';
import 'DeliveryCompanyModel.dart';
import 'PendingCompaniesController.dart';

class PendingCompaniesScreen extends GetView<PendingCompaniesController> {
  const PendingCompaniesScreen({super.key});

  void _showRejectionDialog(DeliveryCompanyModel company) {
    final reasonController = TextEditingController();
    Get.dialog(
        AlertDialog(
          title: Text("سبب رفض شركة: ${company.companyName}"),
          content: TextField(
            controller: reasonController,
            decoration: InputDecoration(labelText: "سبب الرفض (مطلوب)"),
            maxLines: 3,
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: Text("إلغاء")),
            ElevatedButton(
              onPressed: () {
                if (reasonController.text.trim().isNotEmpty) {
                  Get.back(); // أغلق الحوار
                  controller.rejectCompany(company.companyId, company.adminUserId, company.companyName, reasonController.text.trim());
                } else {
                  Get.snackbar("مطلوب", "يرجى إدخال سبب الرفض.", backgroundColor: Colors.orange);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade300),
              child: Text("تأكيد الرفض"),
            ),
          ],
        )
    );
  }


  @override
  Widget build(BuildContext context) {
    // Get.put(PendingCompaniesController()); // أو عبر Binding
    return Scaffold(
      appBar: AppBar(
        title: const Text("طلبات تسجيل الشركات المعلقة"),
        actions: [
          Obx(() => controller.isLoading.value
              ? Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width:20, height:20, child:CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
              : IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.fetchPendingCompanies,
            tooltip: "تحديث القائمة",
          ))
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.pendingCompanies.isEmpty) { // مؤشر تحميل فقط إذا كانت القائمة فارغة
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 50),
                  SizedBox(height:10),
                  Text(controller.errorMessage.value, textAlign: TextAlign.center, style: TextStyle(color: Colors.red.shade700)),
                  SizedBox(height:10),
                  ElevatedButton.icon(icon: Icon(Icons.refresh), label: Text("إعادة المحاولة"), onPressed: controller.fetchPendingCompanies)
                ]),
              )
          );
        }
        if (controller.pendingCompanies.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.inbox_outlined, size: 60, color: Colors.grey),
              SizedBox(height:10),
              Text("لا توجد طلبات تسجيل شركات معلقة حاليًا.", style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
            ]),
          );
        }

        return RefreshIndicator( // للسحب للتحديث
          onRefresh: controller.fetchPendingCompanies,
          child: ListView.builder(
            itemCount: controller.pendingCompanies.length,
            itemBuilder: (context, index) {
              final company = controller.pendingCompanies[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: InkWell( // لجعل العنصر قابل للنقر لعرض التفاصيل
                  onTap: () {
                    // عرض تفاصيل الشركة في حوار أو شاشة جديدة
                    Get.dialog(CompanyDetailsDialog(company: company, adminController: controller), barrierDismissible: true);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: company.logoImageUrl != null && company.logoImageUrl!.isNotEmpty
                                  ? CachedNetworkImageProvider(company.logoImageUrl!)
                                  : null, // يمكنك وضع أيقونة افتراضية
                              child: (company.logoImageUrl == null || company.logoImageUrl!.isEmpty)
                                  ? Icon(Icons.business, color: Colors.grey.shade500, size: 28)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(company.companyName, style: Get.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                                  Text("طلب بتاريخ: ${DateFormat('yyyy/MM/dd', 'ar').format(company.createdAt.toDate())}", style: Get.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                            // زر "موافقة"
                            IconButton(
                              icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
                              onPressed: controller.isLoading.value ? null : () => controller.approveCompany(company.companyId, company.adminUserId, company.companyName),
                              tooltip: "موافقة على الشركة",
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Divider(height: 1, thickness: 0.5),
                        const SizedBox(height: 10),
                        // عرض بعض التفاصيل السريعة
                        Text("الهاتف: ${company.contactPhoneNumber}", style: Get.textTheme.bodyMedium),
                        Text("البريد: ${company.contactEmail}", style: Get.textTheme.bodyMedium),
                        if(company.headquartersAddressText != null && company.headquartersAddressText!.isNotEmpty)
                          Text("العنوان: ${company.headquartersAddressText}", style: Get.textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),

                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon( // زر لرفض الشركة
                              icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size:20),
                              label: const Text("رفض", style: TextStyle(color: Colors.redAccent)),
                              onPressed: controller.isLoading.value ? null : () => _showRejectionDialog(company),
                              style: TextButton.styleFrom(padding: EdgeInsets.symmetric(horizontal:10, vertical: 5)),
                            ),
                            const Spacer(), // لدفع زر التفاصيل إلى اليمين
                            OutlinedButton(
                              onPressed: () {
                                Get.dialog(CompanyDetailsDialog(company: company, adminController: controller), barrierDismissible: true);
                              },
                              style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal:12, vertical: 6)),
                              child: const Text("عرض التفاصيل للمراجعة"),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}