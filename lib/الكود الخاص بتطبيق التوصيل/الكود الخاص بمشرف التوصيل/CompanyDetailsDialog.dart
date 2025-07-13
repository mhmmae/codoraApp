import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // لعرض الخريطة
import 'package:intl/intl.dart';

import 'DeliveryCompanyModel.dart';
import 'PendingCompaniesController.dart';

// افترض وجود هذه الملفات
// import '../models/DeliveryCompanyModel.dart';
// import 'pending_companies_controller.dart';

class CompanyDetailsDialog extends StatelessWidget {
  final DeliveryCompanyModel company;
  final PendingCompaniesController adminController; // لتنفيذ الإجراءات

  const CompanyDetailsDialog({super.key, required this.company, required this.adminController});

  Widget _buildDetailRow(String label, String? value, {bool isLink = false}) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
          Expanded(
            child: isLink
                ? InkWell(child: Text(value, style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline)), onTap: () { /* TODO: Open Link */ })
                : Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final LatLng? hqLocation = company.headquartersLocation != null
        ? LatLng(company.headquartersLocation!.latitude, company.headquartersLocation!.longitude)
        : null;

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical:10),
      actionsPadding: const EdgeInsets.symmetric(horizontal:12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(company.companyName, style: Get.textTheme.headlineSmall, overflow: TextOverflow.ellipsis)),
              IconButton(icon: Icon(Icons.close), onPressed:() => Get.back())
            ],
          ),
          const Divider(),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (company.logoImageUrl != null && company.logoImageUrl!.isNotEmpty)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: company.logoImageUrl!,
                    height: 100, width: 100, fit: BoxFit.contain,
                    placeholder: (c, u) => const SizedBox(height:100, width:100, child: Center(child:CircularProgressIndicator(strokeWidth:2))),
                    errorWidget: (c, u, e) => const Icon(Icons.broken_image, size: 60, color: Colors.grey),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            _buildDetailRow("المعرف", company.companyId),
            _buildDetailRow("مشرف الشركة (UID)", company.adminUserId),
            _buildDetailRow("رقم الهاتف للتواصل", company.contactPhoneNumber),
            _buildDetailRow("البريد الإلكتروني للتواصل", company.contactEmail),
            _buildDetailRow("السجل التجاري", company.commercialRegistrationNumber),
            _buildDetailRow("الموقع الإلكتروني", company.websiteUrl, isLink: company.websiteUrl != null && company.websiteUrl!.isNotEmpty),
            _buildDetailRow("نبذة عن الشركة", company.companyBio),
            const SizedBox(height: 8),
            const Text("مناطق الخدمة:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
            if (company.serviceAreaDescriptions != null && company.serviceAreaDescriptions!.isNotEmpty)
              Wrap(spacing: 6, runSpacing: 0, children: company.serviceAreaDescriptions!.map((area) => Chip(label: Text(area), visualDensity: VisualDensity.compact)).toList())
            else
              const Text("لم تحدد بعد", style: TextStyle(fontStyle: FontStyle.italic)),
            const SizedBox(height: 8),
            _buildDetailRow("العنوان النصي للمقر", company.headquartersAddressText),
            if (hqLocation != null) ...[
              const SizedBox(height: 8),
              Text("موقع المقر على الخريطة:", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
              SizedBox(
                  height: 150, // ارتفاع الخريطة المصغرة
                  child: AbsorbPointer(
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(target: hqLocation, zoom: 15),
                      markers: {Marker(markerId: MarkerId("hq"), position: hqLocation)},
                      zoomGesturesEnabled: false, scrollGesturesEnabled: false,
                      tiltGesturesEnabled: false, rotateGesturesEnabled: false,
                    ),
                  ))
            ],
            const SizedBox(height: 12),
            const Divider(),
            _buildDetailRow("تاريخ الطلب", DateFormat('yyyy/MM/dd hh:mm a', 'ar').format(company.createdAt.toDate())),
            Row(children: [
              Text("موثقة من المنصة: ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
              Icon(company.isVerified ? Icons.verified_user_rounded : Icons.shield_outlined, color: company.isVerified ? Colors.teal : Colors.orange, size: 20),
              Text(company.isVerified ? " نعم" : " لا", style: TextStyle(color: company.isVerified ? Colors.teal : Colors.orange)),
            ]),
            Row(children: [
              Text("نشطة من الشركة: ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
              Icon(company.isActiveByCompanyAdmin ? Icons.toggle_on_rounded : Icons.toggle_off_outlined, color: company.isActiveByCompanyAdmin ? Colors.green : Colors.grey, size: 26),
              Text(company.isActiveByCompanyAdmin ? " نعم" : " لا", style: TextStyle(color: company.isActiveByCompanyAdmin ? Colors.green : Colors.grey)),
            ]),


          ],
        ),
      ),
      actions: <Widget>[
        OutlinedButton.icon( // زر لرفض الشركة
          icon: const Icon(Icons.cancel_rounded, color: Colors.redAccent),
          label: const Text("رفض الشركة", style: TextStyle(color: Colors.redAccent)),
          onPressed: adminController.isLoading.value ? null : () {
            Get.back(); // Close this dialog first
            _showRejectionDialogInAdmin(company, adminController);
          },
        ),
        const SizedBox(width: 8),
        // زر للتحكم في isVerified
        TextButton.icon(
          icon: Icon(company.isVerified ? Icons.unpublished_outlined : Icons.verified_outlined, color: company.isVerified ? Colors.orange : Colors.teal, size: 20),
          label: Text(company.isVerified ? "إلغاء التوثيق" : "توثيق الوثائق", style: TextStyle(color:company.isVerified ? Colors.orange : Colors.teal)),
          onPressed: () => adminController.markAsVerified(company.companyId, company.companyName, company.isVerified),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.approval_rounded),
          label: const Text("الموافقة على الشركة"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600),
          onPressed: adminController.isLoading.value ? null : () {
            Get.back(); // Close this dialog
            adminController.approveCompany(company.companyId, company.adminUserId, company.companyName);
          },
        ),
      ],
    );
  }

  // دالة لعرض حوار الرفض من داخل هذا الحوار (لتجنب مشاكل السياق)
  void _showRejectionDialogInAdmin(DeliveryCompanyModel company, PendingCompaniesController ctrl) {
    final reasonController = TextEditingController();
    Get.dialog(
        AlertDialog(
          title: Text("سبب رفض شركة: ${company.companyName}"),
          content: TextField(
            controller: reasonController,
            decoration: InputDecoration(labelText: "سبب الرفض (مطلوب)"),
            maxLines: 3,
            autofocus: true,
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: Text("إلغاء")),
            ElevatedButton(
              onPressed: () {
                if (reasonController.text.trim().isNotEmpty) {
                  Get.back(); // أغلق حوار السبب
                  ctrl.rejectCompany(company.companyId, company.adminUserId, company.companyName, reasonController.text.trim());
                } else { /* ... */ }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade300),
              child: Text("تأكيد الرفض"),
            ),
          ],
        )
    );
  }
}