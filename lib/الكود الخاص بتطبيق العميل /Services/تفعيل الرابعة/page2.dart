// للتفاعل مع الصورة لاحقاً (إذا احتجت)
import 'package:codora/%D8%A7%D9%84%D9%83%D9%88%D8%AF%20%D8%A7%D9%84%D8%AE%D8%A7%D8%B5%20%D8%A8%D8%AA%D8%B7%D8%A8%D9%8A%D9%82%20%D8%A7%D9%84%D8%B9%D9%85%D9%8A%D9%84%20/Services/%D8%AA%D9%81%D8%B9%D9%8A%D9%84%20%D8%A7%D9%84%D8%B1%D8%A7%D8%A8%D8%B9%D8%A9/page2WIDGET.dart';
import 'package:flutter/material.dart';
// للـ SelectableText
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_barcodes/barcodes.dart';

import 'getPage2.dart'; // يحتوي على تعريف PricingAndloctionController

class BarcodeResultPage extends StatelessWidget {
  final String barcode; // الباركود الذي تم مسحه ضوئيًا

  BarcodeResultPage({super.key, required this.barcode});

  // استخدام Get.put لضمان وجود الكنترولر (أو Get.find إذا تم إنشاؤه مسبقاً)
  final PricingAndloctionController pricingController = Get.put(PricingAndloctionController());
  // مفتاح RepaintBoundary (لا نحتاجه إذا لن نحفظ الباركود كصورة)
  // final GlobalKey _barcodeKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    // جلب السعر إذا كانت المدة والمحافظة متاحتين (يبقى كما هو)
    // ملاحظة: قد يكون من الأفضل وضع هذا المنطق داخل initState أو دالة تهيئة إذا كان هناك حاجة لاستدعائه مرة واحدة فقط
    // أو استخدام Rx لتفاعلية أفضل عند تغيير الدروب داون
    //WidgetsBinding.instance.addPostFrameCallback((_) {
    if (pricingController.selectedProvinceEnglish.value.isNotEmpty &&
        pricingController.selectedDurationEnglish.value.isNotEmpty &&
        pricingController.price.value == 0) { // جلب فقط إذا السعر لم يتم جلبه بعد
      pricingController.fetchPriceAndPhone(
        pricingController.selectedProvinceEnglish.value,
        pricingController.selectedDurationEnglish.value,
      );
    }
    //});

    // أدوات تنسيق مشابهة
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // فورماتر للأرقام لتوحيد شكل السعر
    final numberFormat = NumberFormat("#,##0", Get.locale?.languageCode ?? 'ar');

    return Scaffold(
      // AppBar بتنسيق مشابه
      appBar: AppBar(
        title: const Text("تفاصيل الكود الممسوح"), // عنوان أوضح
        centerTitle: true,
        // استخدم لون AppBar من السمة أو حدده ليتناسق
        // backgroundColor: theme.appBarTheme.backgroundColor ?? colorScheme.primary,
        // foregroundColor: theme.appBarTheme.foregroundColor ?? colorScheme.onPrimary,
        leading: IconButton(
          icon: Icon(Directionality.of(context).toString() == 'TextDirection.rtl'
              ? Icons.arrow_forward_ios_rounded
              : Icons.arrow_back_ios_new_rounded),
          onPressed: () => Get.back(), // الرجوع البسيط
        ),
      ),
      backgroundColor: theme.scaffoldBackgroundColor, // لون خلفية مشابه
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0), // حشو قياسي
        // مراقبة حالة الـ Controller باستخدام Obx
        child: Obx(() {
          // تهيئة قيمة السعر المنسق مع قيمة افتراضية
          String formattedPrice = "جاري التحميل...";
          if (pricingController.price.value > 0) {
            formattedPrice = "${numberFormat.format(pricingController.price.value)} ريال"; // <--- التنسيق والعملة
          } else if (pricingController.price.value == 0 && pricingController.selectedDurationEnglish.isNotEmpty && pricingController.selectedProvinceEnglish.isNotEmpty){
            formattedPrice = "السعر غير متوفر حاليًا"; // رسالة أوضح
          } else {
            formattedPrice = "اختر المحافظة والمدة"; // رسالة أولية
          }


          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // العناصر تمتد بعرض الشاشة
            children: [
              // --- استخدام Card موحد المظهر ---
              _buildInfoCard(
                  context: context,
                  icon: Icons.person_outline,
                  title: "اسم العميل:",
                  value: pricingController.userName.value.isNotEmpty ? pricingController.userName.value : "غير محدد"
              ),
              const SizedBox(height: 12), // مسافة أقل قليلاً بين البطاقات
              _buildInfoCard(
                  context: context,
                  icon: Icons.phone_outlined,
                  title: "رقم الهاتف:",
                  value: pricingController.userPhone.value.isNotEmpty ? pricingController.userPhone.value : "غير محدد"
              ),
              const SizedBox(height: 12),

              // --- Dropdown للمحافظة بشكل منسق ---
              _buildDropdownCard(
                context: context,
                title: "المحافظة:",
                value: pricingController.selectedProvinceArabic.value.isEmpty
                    ? null
                    : pricingController.selectedProvinceArabic.value,
                hint: "اختر المحافظة...",
                items: pricingController.provincesArabic,
                onChanged: (value) {
                  if (value != null) {
                    pricingController.updateProvince(value);
                    // جلب السعر فقط إذا كانت المدة مختارة أيضًا
                    if (pricingController.selectedDurationEnglish.value.isNotEmpty) {
                      pricingController.fetchPriceAndPhone(
                        pricingController.selectedProvinceEnglish.value,
                        pricingController.selectedDurationEnglish.value,
                      );
                    }
                  }
                },
                iconData: Icons.location_city_outlined,
              ),
              const SizedBox(height: 12),

              // --- Dropdown للمدة بشكل منسق ---
              _buildDropdownCard(
                context: context,
                title: "المدة:",
                value: pricingController.selectedDurationArabic.value, // نفترض أن هناك دائمًا قيمة افتراضية
                items: pricingController.durations
                    .map((duration) => duration['ar']!)
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    pricingController.updateDuration(value);
                    // جلب السعر فقط إذا كانت المحافظة مختارة أيضًا
                    if (pricingController.selectedProvinceEnglish.value.isNotEmpty) {
                      pricingController.fetchPriceAndPhone(
                        pricingController.selectedProvinceEnglish.value,
                        pricingController.selectedDurationEnglish.value,
                      );
                    }
                  }
                },
                iconData: Icons.timer_outlined,
              ),
              const SizedBox(height: 12),

              // --- بطاقة السعر المنسقة ---
              _buildInfoCard(
                context: context,
                icon: Icons.price_change_outlined,
                title: "السعر:",
                value: formattedPrice, // القيمة المنسقة من الأعلى
                valueStyle: TextStyle( // نمط خاص للسعر
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary // استخدام لون السمة
                ),
              ),
              const SizedBox(height: 25), // مسافة أكبر قبل الباركود

              // --- الباركود داخل Card ---
              Center(
                child: Card(
                  elevation: 3, // ظل خفيف للباركود
                  margin: EdgeInsets.zero, // إزالة الهامش الافتراضي
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // حواف أنعم قليلاً
                  clipBehavior: Clip.antiAlias, // لقص الباركود بشكل صحيح
                  child: Container( // لإضافة حشوة ولون خلفية
                    color: Colors.white, // خلفية بيضاء إلزامية للباركود
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    child: SfBarcodeGenerator(
                      value: barcode, // استخدام قيمة الباركود المستلمة
                      symbology: Code128(), // نوع الباركود الشائع
                      showValue: true, // إظهار القيمة النصية أسفل الباركود
                      textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold), // تنسيق النص
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // --- ▼▼▼ تضمين صفحة أخرى - تأكد من تنسيقها أيضًا إذا لزم الأمر ▼▼▼ ---
              // هذا الويدجت (BarcodeResultPage1) يجب أن يُنسق أيضًا ليتوافق مع المظهر الجديد


              BarcodeResultPage1(
                name: pricingController.userName.value,
                phoneNumber: pricingController.userPhone.value,
                barcode: barcode,
              )
              // --- ▲▲▲ ---
            ],
          );
        }),
      ),
    );
  }

  // --- دالة مساعدة لبناء بطاقة المعلومات بتنسيق موحد ---
  Widget _buildInfoCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    TextStyle? valueStyle, // نمط اختياري للقيمة (مثل السعر)
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      elevation: 2.0, // ظل أنعم قليلاً
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // حواف أكثر دائرية
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row( // استخدام Row للأيقونة والعنوان والقيمة
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colorScheme.primary, size: 22), // أيقونة بلون أساسي
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.labelLarge?.copyWith(color: Colors.grey[600]), // نمط موحد للعنوان
                  ),
                  const SizedBox(height: 5),
                  SelectableText( // السماح بتحديد القيمة
                    value,
                    style: valueStyle ?? textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500, height: 1.3), // استخدام النمط الممرر أو نمط افتراضي
                    textAlign: TextAlign.start,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- دالة مساعدة لبناء بطاقة Dropdown بتنسيق موحد ---
  Widget _buildDropdownCard({
    required BuildContext context,
    required String title,
    required String? value, // القيمة الحالية المختارة
    required List<String> items, // قائمة الخيارات
    required ValueChanged<String?> onChanged, // دالة عند التغيير
    String? hint, // النص التلميحي (Hint)
    required IconData iconData, // الأيقونة
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // تصميم مشابه لـ TextField مع حدود وأيقونة
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4.0), // ضبط الحشو
        child: DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: title, // العنوان كـ label
            prefixIcon: Icon(iconData, color: colorScheme.primary), // الأيقونة
            border: InputBorder.none, // إزالة الحدود الداخلية للـ Dropdown
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // حشو داخلي لضبط المحاذاة
          ),
          hint: hint != null ? Text(hint, style: TextStyle(color: Colors.grey[500])) : null, // تنسيق الـ hint
          icon: Icon(Icons.arrow_drop_down_rounded, color: colorScheme.secondary), // تغيير شكل أيقونة السهم
          items: items.map((item) => DropdownMenuItem<String>(
            value: item,
            child: Text(item, style: theme.textTheme.bodyLarge),
          )).toList(),
          onChanged: onChanged,
          validator: (v) => v == null ? 'الحقل مطلوب' : null, // مثال للتحقق
          // إضافة تنسيقات أخرى حسب الرغبة
          // dropdownColor: theme.cardColor,
        ),
      ),
    );
  }
}