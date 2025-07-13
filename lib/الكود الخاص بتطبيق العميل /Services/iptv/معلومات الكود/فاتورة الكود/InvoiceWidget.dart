import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // لاستخدام تنسيق الأرقام والتواريخ
import 'package:cloud_firestore/cloud_firestore.dart'; // للوصول لنوع Timestamp

/// ويدجت بسيط لعرض تفاصيل الفاتورة بتنسيق مناسب.
class InvoiceWidget extends StatelessWidget {
  /// بيانات الفاتورة التي تم إنشاؤها وحفظها في aheSales`.
  final Map<String, dynamic> salesData;

  const InvoiceWidget({super.key, required this.salesData});

  @override
  Widget build(BuildContext context) {
    // أدوات التنسيق
    final String currentLocale = Get.locale?.languageCode ?? 'ar';
    final numberFormat = NumberFormat("#,##0.##", currentLocale); // للسماح بالكسور إذا لزم الأمر
    final dateTimeFormat = DateFormat('yyyy/MM/dd hh:mm a', currentLocale);

    // استخلاص البيانات من الخريطة مع قيم افتراضية آمنة
    final String saleId = salesData['saleId'] ?? 'N/A';
    final String userEmail = salesData['userEmail'] ?? salesData['userId'] ?? 'مستخدم';
    final String name = salesData['name'] ?? salesData['userId'] ?? 'مستخدم';
    final String phneNumber = salesData['phneNumber'] ?? salesData['userId'] ?? 'مستخدم';

    final String codeName = salesData['codeName'] ?? 'غير معروف';
    final String assignedCode = salesData['assignedCodeValue'] ?? '---';
    final String durationAr = salesData['selectedDurationAr'] ?? 'غير محدد';
    final num price = salesData['purchasePrice'] ?? 0;
    final Timestamp? purchaseTime = salesData['purchaseTimestamp'] as Timestamp?;

    final String formattedPrice = numberFormat.format(price);
    final String formattedTime = purchaseTime != null
        ? dateTimeFormat.format(purchaseTime.toDate())
        : 'غير معروف';

    // تصميم الواجهة للفاتورة
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white, // خلفية بيضاء للفاتورة
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // لجعل العمود يأخذ أقل ارتفاع ممكن
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان الفاتورة
          Center(
            child: Text(
              "فاتورة شراء",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(thickness: 1.5, height: 20),

          // تفاصيل الفاتورة
          _buildInvoiceRow("رقم الفاتورة:", saleId),
          _buildInvoiceRow("تاريخ الشراء:", formattedTime),
          _buildInvoiceRow("الاسم :", name),
          _buildInvoiceRow("ايميل :", userEmail),
          _buildInvoiceRow("رقم الهاتف :", phneNumber),
          const Divider(height: 15),
          _buildInvoiceRow("اسم المنتج:", codeName),
          _buildInvoiceRow("المدة:", durationAr),
          _buildInvoiceRow("الكود المخصص:", assignedCode, isCode: true),
          const Divider(height: 15),
          _buildInvoiceRow("السعر:", "$formattedPrice دينار", isBold: true), // إضافة رمز العملة

          const SizedBox(height: 10),
          // رسالة شكر أو ملاحظة
          const Center(child: Text("شكراً لشرائكم", style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }

  // ويدجت مساعد لعرض صف في الفاتورة
  Widget _buildInvoiceRow(String label, String value, {bool isBold = false, bool isCode = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("$label ", style: TextStyle(color: Colors.grey[700])),
          Expanded(
            child: SelectableText( // جعل القيمة قابلة للنسخ
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontFamily: isCode ? 'monospace' : null, // خط مميز للكود
                letterSpacing: isCode ? 1.2 : null,
                fontSize: isCode ? 15 : 14, // حجم خط أكبر للكود
              ),
            ),
          ),
        ],
      ),
    );
  }
}