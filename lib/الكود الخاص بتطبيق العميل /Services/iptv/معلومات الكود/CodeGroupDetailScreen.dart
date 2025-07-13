import 'dart:async'; // للاستخدام المستقبلي المحتمل
import 'package:codora/%D8%A7%D9%84%D9%83%D9%88%D8%AF%20%D8%A7%D9%84%D8%AE%D8%A7%D8%B5%20%D8%A8%D8%AA%D8%B7%D8%A8%D9%8A%D9%82%20%D8%A7%D9%84%D8%B9%D9%85%D9%8A%D9%84%20/Services/iptv/%D9%85%D8%B9%D9%84%D9%88%D9%85%D8%A7%D8%AA%20%D8%A7%D9%84%D9%83%D9%88%D8%AF/%D9%81%D8%A7%D8%AA%D9%88%D8%B1%D8%A9%20%D8%A7%D9%84%D9%83%D9%88%D8%AF/InvoiceWidget.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <-- استيراد Auth
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart'; // <-- استيراد Rating Bar
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // لتنسيق التواريخ (أضف intl إلى pubspec.yaml)
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/rendering.dart'; // <-- لاستخدام RepaintBoundary
import '../عرض كل انواع الكودات /CodeGroupsController.dart';
import 'CodeRequestController.dart';
import 'package:permission_handler/permission_handler.dart'; // <-- استيراد PermissionHandler
// <-- لاستخدام Uint8List
import 'dart:ui' as ui; // <-- لاستخدام ui.Image و ImageByteFormat


// استبدل 'your_app_name' بالاسم الفعلي لحزمتك كما هو في pubspec.yaml

// استبدل هذا بالمسار الصحيح للكنترولر في مشروعك

class CodeGroupDetailScreen extends StatelessWidget {
  final GlobalKey _invoiceBoundaryKey = GlobalKey(); // <--- مفتاح حدود الرسم

  CodeGroupDetailScreen({super.key});
  final List<Map<String, String>> durationOptions = const [
    {"ar": "شهر", "en": "month"},
    {"ar": "ثلاثة أشهر", "en": "three months"},
    {"ar": "ستة أشهر", "en": "six months"},
    // {"ar": "تسعة أشهر", "en": "nine months"}, // يمكنك إضافة المزيد
    {"ar": "سنة", "en": "year"}
  ];


  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? item = Get.arguments as Map<String, dynamic>?;
    final CodeGroupsController listController = Get.find<CodeGroupsController>();
    final CodeRequestController requestController = Get.find<CodeRequestController>();
    final currentUser = FirebaseAuth.instance.currentUser; // <-- الحصول على المستخدم الحالي

    if (item == null) {
      // ... (نفس كود معالجة الخطأ السابق) ...
      return Scaffold( /* ... */ );
    }

    // استخلاص البيانات مع القيم الافتراضية أو null
    final String itemId = item['id'] ?? 'unknown_id_${DateTime.now().millisecondsSinceEpoch}';
    final String imageUrl = item['imageUrl'] ?? 'https://via.placeholder.com/400';
    final String codeName = item['codeName'] ?? 'اسم غير معروف';
    // --- ▼▼▼ استخلاص الحقول الجديدة ▼▼▼ ---
    final String? codeValue = item['codeValue'] as String?; // قد يكون null
    final String? description = item['definition'] as String?;
    final String? link = item['link'] as String?;
    final String? provider = item['provider'] as String?;
    final Timestamp? createdAt = item['createdAt'] as Timestamp?; // افترض أن لديك هذا الحقل
    final Timestamp? expiryDate = item['expiryDate'] as Timestamp?; // افترض أن لديك هذا الحقل
    final int copyCount = (item['copyCount'] as num?)?.toInt() ?? 0;
    final double averageRating = (item['averageRating'] as num?)?.toDouble() ?? 0.0;
    final int reviewCount = (item['reviewCount'] as num?)?.toInt() ?? 0;
    // --- ▲▲▲ نهاية استخلاص الحقول الجديدة ▲▲▲ ---
    final String currentLocale = Get.locale?.languageCode ?? 'ar'; // الافتراضي للعربية

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final dateFormat = DateFormat('yyyy/MM/dd - hh:mm a', 'ar'); // تنسيق التاريخ العربي
    final numberFormat = NumberFormat("#,##0", currentLocale);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // استدعاء الدالة من الكنترولر الجديد (مرة واحدة عند فتح الشاشة)
      // التأكد من عدم استدعائها مرة أخرى إذا كانت isLoading=false بالفعل
      if (requestController.isLoadingDurationsAndPrice.value) {
// استدعاء دالة التهيئة الرئيسية بدلاً من الدالة الفرعية
        requestController.initializeForCode(codeName);      }
    });


    // --- دالة مساعدة لفتح الروابط ---
    Future<void> openUrl(String urlString) async {
      final uri = Uri.tryParse(urlString);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar('خطأ', 'لا يمكن فتح الرابط: $urlString');
      }
    }

    // --- دالة مساعدة لعرض مربع حوار الإبلاغ ---
    // دالة مساعدة لعرض مربع حوار الإبلاغ
    void showReportDialog() {
      if (currentUser == null) { // تحقق إضافي
        Get.snackbar("غير مسموح", "يجب تسجيل الدخول للإبلاغ.");
        return;
      }
      final TextEditingController reasonController = TextEditingController();
      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), // حواف دائرية للحوار
          title: const Text('الإبلاغ عن مشكلة في الكود'),
          content: TextField(
            controller: reasonController,
            decoration: const InputDecoration(hintText: 'صف المشكلة بإيجاز...', border: OutlineInputBorder()),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]), // لون مميز لزر الإرسال
              onPressed: () {
                final reason = reasonController.text;
                // التأكد من إدخال سبب قبل الإرسال
                if (reason.trim().isEmpty) {
                  Get.rawSnackbar(message: "الرجاء كتابة سبب الإبلاغ.");
                  return;
                }
                Get.back(); // إغلاق الحوار أولاً
                listController.reportCodeGroup(
                    codeGroupId: itemId,
                    codeGroupName: codeName, // تمرير الاسم لسهولة المراجعة
                    reason: reason
                ); // لاحظ استدعاء listController هنا
              },
              child: const Text('إرسال البلاغ'),
            ),
          ],
        ),
      );
    }

    // --- دالة مساعدة لعرض مربع حوار التقييم ---
    // دالة مساعدة لعرض مربع حوار التقييم
    void showRatingDialog({String? existingReviewId, double initialRating = 0.0, String initialComment = ''}) {
      if (currentUser == null) { // تحقق إضافي
        Get.snackbar("غير مسموح", "يجب تسجيل الدخول للتقييم.");
        return;
      }
      final ratingController = TextEditingController(text: initialComment);
      double currentRating = initialRating;

      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(existingReviewId == null ? 'أضف تقييمك' : 'تعديل تقييمك'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("ما هو تقييمك لهذا الكود؟", style: Get.textTheme.titleSmall),
                const SizedBox(height: 10),
                RatingBar.builder(
                  initialRating: initialRating, minRating: 1, direction: Axis.horizontal,
                  allowHalfRating: false, itemCount: 5, itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                  itemBuilder: (context, _) => const Icon( Icons.star, color: Colors.amber),
                  onRatingUpdate: (rating) { currentRating = rating; },
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: ratingController,
                  decoration: const InputDecoration( hintText: 'شارك بتعليقك (اختياري)...', border: OutlineInputBorder()),
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton( onPressed: () => Get.back(), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                if (currentRating < 1) { /* ... رسالة خطأ التقييم ... */ return;}
                final comment = ratingController.text;
                Get.back(); // إغلاق الحوار
                listController.addReview( // لاحظ استدعاء listController هنا
                    codeGroupId: itemId,
                    rating: currentRating,
                    comment: comment,
                    existingReviewId: existingReviewId
                );
              },
              child: Text(existingReviewId == null ? 'إرسال' : 'تحديث'),
            ),
          ],
        ),
      );
    }



    return Scaffold(
      // استخدام CustomScrollView و SliverAppBar لتأثير إخفاء شريط العنوان عند التمرير
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: screenHeight * 0.35, // نفس ارتفاع الصورة
            pinned: true,
            stretch: true,      // يسمح بتمدد الصورة قليلاً عند السحب لأسفل
            elevation: 2.0,     // ظل خفيف للشريط
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).primaryColor, // لون الخلفية عند التصغير
            // تثبيت الشريط في الأعلى عند التصغير
            leading: IconButton( // زر الرجوع يبقى ظاهرًا
              icon: Container( // خلفية للزر لجعله أوضح فوق الصورة
                  decoration: BoxDecoration( shape: BoxShape.circle, color: Colors.black.withOpacity(0.5)),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(Icons.arrow_back_ios_new, color: Colors.white)
              ),
              onPressed: () => Get.back(),
            ),
            actions: [
              // --- ▼▼▼ زر الإبلاغ ▼▼▼ ---
              if (currentUser != null) // إظهار فقط للمستخدمين المسجلين
                IconButton(
                  icon: Container(
                    decoration: BoxDecoration( shape: BoxShape.circle, color: Colors.black.withOpacity(0.5)),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.flag_rounded, color: Colors.white),
                  ),
                  tooltip: 'الإبلاغ عن الكود',
                  onPressed: showReportDialog,
                ),
              // --- ▲▲▲ زر الإبلاغ ▲▲▲ ---

              // --- ▼▼▼ زر المشاركة ▼▼▼ ---
              Builder( // للحصول على context صحيح
                builder: (actionContext) => IconButton(
                  icon: Container(
                    decoration: BoxDecoration( shape: BoxShape.circle, color: Colors.black.withOpacity(0.5)),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.share_rounded, color: Colors.white),
                  ),
                  tooltip: 'مشاركة',
                  onPressed: () => listController.shareCodeGroup(item, actionContext),
                ),
              ),
              // --- ▲▲▲ زر المشاركة ▲▲▲ ---

              // --- ▼▼▼ زر المفضلة (باستخدام الويدجت المنفصل) ▼▼▼ ---
              Padding(
                padding: const EdgeInsets.only(right: 8.0, left: 4.0), // إضافة هامش يساري أيضًا
                child: _buildFavoriteButton( // استدعاء مباشر (الويدجت هو الذي يعيد بناء نفسه)
                  context: context,
                  controller: listController,
                  itemId: itemId,
                  screenWidth: screenWidth,
                  useDarkBackground: true, // استخدام الخلفية الداكنة
                  sizeMultiplier: 1.05, // تكبيره قليلاً هنا
                ),
              ),
              // --- ▲▲▲ زر المفضلة ▲▲▲ ---
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground, StretchMode.fadeTitle], // تأثيرات التمدد
              // يمكن إضافة عنوان يتلاشى هنا إذا أردت
              title: Text(codeName, style: TextStyle(fontSize: 16.0)),
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 16.0),

              // إضافة تدرج أسود خفيف في الأسفل لتحسين وضوح الأيقونات
              background: Stack(
                 fit: StackFit.expand,
                 children: [
                   Hero( // تأثير انتقال الصورة
                     tag: 'image_$itemId', // استخدم نفس المفتاح من الشاشة السابقة
                     child: Image.network(
                       imageUrl,
                       fit: BoxFit.cover, // غطي المساحة
                       loadingBuilder: (context, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator()),
                       errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[300], child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 50))),
                     ),
                   ), // الصورة
                    DecoratedBox(
                       decoration: BoxDecoration(
                          gradient: LinearGradient(
                             begin: Alignment.bottomCenter,
                             end: Alignment.center,
                             colors: <Color>[Colors.black.withOpacity(0.6), Colors.transparent],
                          ),
                       ),
                    ),
                 ],
              ),
            ),
          ),

          // --- محتوى التفاصيل ---
          SliverPadding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  // --- اسم الكود ---
                  Text( codeName, style: TextStyle(fontSize: screenWidth * 0.06, fontWeight: FontWeight.bold)),
                  SizedBox(height: screenHeight * 0.01),

                  // --- المزود (Provider) ---
                  if (provider != null && provider.isNotEmpty)
                    _buildInfoRow(context, Icons.business_center_rounded, 'المزود:', provider, screenWidth),


                  // --- عداد النسخ والتقييم ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // التقييم
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, color: Colors.amber, size: screenWidth * 0.05),
                          const SizedBox(width: 4),
                          Text(
                              averageRating > 0 ? averageRating.toStringAsFixed(1) : 'لا تقييمات',
                              style: TextStyle(fontSize: screenWidth * 0.04, fontWeight: FontWeight.w500)
                          ),
                          Text( reviewCount > 0 ? ' ($reviewCount مراجعة)' : '', style: TextStyle(fontSize: screenWidth * 0.035, color: Colors.grey))
                        ],
                      ),
                      // عدد النسخ
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.copy_all_rounded, size: screenWidth * 0.045, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text('$copyCount نسخة', style: TextStyle(fontSize: screenWidth * 0.038, color: Colors.grey[700]))
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.02),

                  // --- الكود الفعلي وزر النسخ ---
                  if (codeValue != null && codeValue.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text( 'الكود الفعلي:', style: TextStyle(fontSize: screenWidth * 0.045, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.secondary)),
                        TextButton.icon(
                          icon: Icon(Icons.copy_rounded, size: screenWidth * 0.05),
                          label: const Text('نسخ'),
                          style: TextButton.styleFrom( foregroundColor: Theme.of(context).colorScheme.primary),
                          onPressed: () {
                            listController.incrementCopyCount(itemId); // زيادة العداد من الكنترولر الأساسي
                            Clipboard.setData(ClipboardData(text: codeValue)).then((_) {
                              Get.snackbar('تم النسخ', 'تم نسخ الكود بنجاح!', /*...*/);
                            });
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    Container( // خلفية مميزة للكود
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.015),
                      decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!)
                      ),
                      width: double.infinity,
                      child: SelectableText( // السماح بالنسخ اليدوي
                        codeValue,
                        style: TextStyle(fontSize: screenWidth * 0.055, fontWeight: FontWeight.bold, fontFamily: 'monospace', letterSpacing: 1.5, color: Colors.black87),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.025),
                  ],

                  // --- الوصف ---
                  if (description != null && description.isNotEmpty) ...[
                    Divider(height: screenHeight * 0.03),
                    Text( 'الوصف:', style: TextStyle(fontSize: screenWidth * 0.05, fontWeight: FontWeight.w600)),
                    SizedBox(height: screenHeight * 0.01),
                    SelectableText( description, style: TextStyle(fontSize: screenWidth * 0.042, color: Colors.black87, height: 1.5)),
                    SizedBox(height: screenHeight * 0.025),
                  ],
                  // --- التعليمات ---
                  // if (item['instructions'] != null && item['instructions'].isNotEmpty) ...[ /* اعرض التعليمات */],

                  // --- تاريخ الإضافة والانتهاء ---
                  if (createdAt != null || expiryDate != null) Card( // وضع التواريخ في بطاقة
                    margin: EdgeInsets.zero, // إزالة الهامش الافتراضي للبطاقة
                    elevation: 0.5,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          if (createdAt != null)
                            _buildInfoRow(context, Icons.calendar_today_rounded, 'تاريخ الإضافة:', dateFormat.format(createdAt.toDate()), screenWidth),
                          if (createdAt != null && expiryDate != null) const Divider(height: 10, indent: 40),
                          if (expiryDate != null)
                            _buildInfoRow( context, Icons.event_busy_rounded, 'تاريخ الانتهاء:', dateFormat.format(expiryDate.toDate()), screenWidth,
                                valueColor: expiryDate.toDate().isBefore(DateTime.now()) ? Colors.red[700] : (expiryDate.toDate().isBefore(DateTime.now().add(const Duration(days: 7))) ? Colors.orange[800] : null)
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (createdAt != null || expiryDate != null) SizedBox(height: screenHeight * 0.025),


                  // --- زر الرابط المرتبط ---
                  if (link != null && link.isNotEmpty) ...[
                    Center( // توسيط الزر
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1, vertical: screenHeight * 0.015)),
                        icon: const Icon(Icons.link_rounded),
                        label: const Text('فتح الرابط المرتبط'),
                        onPressed: () => openUrl(link),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.025),
                  ],
                  Divider(height: screenHeight * 0.04, thickness: 1.5),
                  Text( 'شراء كود التفعيل', style: TextStyle(fontSize: screenWidth * 0.055, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                  SizedBox(height: screenHeight * 0.015),

                  if (currentUser == null)
                    Padding(padding: EdgeInsets.all(8),)
                  else
                  // مراقبة حالة تحميل المدد والأسعار باستخدام Obx
                    Obx(() {
                      // حالة التحميل
                      if (requestController.isLoadingDurationsAndPrice.value) {
                        return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()));
                      }
                      // حالة عدم توفر أي مدد (مع سعر وأكواد)
                      else if (requestController.availableDurations.isEmpty) {
                        return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text("عذرًا، لا توجد باقات تفعيل متاحة للشراء لهذا الكود حاليًا.", textAlign: TextAlign.center,)));
                      }
                      // داخل قسم شراء الكود في CodeGroupDetailScreen

                      else if (requestController.availableDurations.isEmpty) {
                        // --- ▼▼▼ تعديل الرسالة هنا ▼▼▼ ---
                        return Center(child: Padding(padding: EdgeInsets.all(16.0),
                            child: Text( requestController.pricingData.value.isEmpty // تحقق هل التسعير فارغ؟
                                ? "لم يتم تحديد أسعار التفعيل لهذا الكود حاليًا."
                                : "لا توجد باقات تفعيل متوفرة (لها سعر وكود متاح) لهذا الكود حاليًا.",
                              textAlign: TextAlign.center,)));
                        // --- ▲▲▲ ---
                      }
                      // حالة توفر المدد
                      else {
                        return Card( elevation: 1.5, child: Padding( padding: const EdgeInsets.all(15.0),
                          child: Column( crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                            // --- القائمة المنسدلة للمدد المتاحة ---
                            DropdownButtonFormField<Map<String, String>>(
                              value: requestController.selectedDurationOption.value,
                              isExpanded: true,
                              decoration: InputDecoration( labelText: 'اختر مدة التفعيل المطلوبة', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), prefixIcon: const Icon(Icons.timer_outlined), ),
                              items: requestController.availableDurations.map((durationMap) {
                                return DropdownMenuItem<Map<String, String>>( value: durationMap, child: Text(durationMap['ar']!),);
                              }).toList(),
                              onChanged: (newValue) { requestController.selectDuration(newValue); },
                              // validator: (value) => value == null ? 'الرجاء اختيار مدة' : null, // (اختياري)
                            ),
                            SizedBox(height: screenHeight * 0.015),

                            // --- عرض السعر للمدة المختارة ---
                            Obx(() {
                              final price = requestController.currentPrice.value;
                              final selectedDur = requestController.selectedDurationOption.value;
                              if (selectedDur == null) return const SizedBox.shrink(); // لا تظهر شيئًا إذا لم يختر مدة
                              if (price == null) return Padding( padding: EdgeInsets.all(8),);

                              // --- يمكنك إضافة تنسيق للعملة هنا ---
                              final formattedPrice = numberFormat.format(price);

                              return Padding( padding: const EdgeInsets.symmetric(vertical: 8.0), child: Center( child: Text( "السعر: $formattedPrice", style: TextStyle(fontSize: screenWidth * 0.048, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),),);
                            }),
                            SizedBox(height: screenHeight * 0.01),

                            // --- زر الشراء ---
                            Obx(() {
                              final isRequesting = requestController.isRequestingCode.value;
                              final currentSelection = requestController.selectedDurationOption.value;
                              // تفعيل الزر فقط إذا اختار المستخدم مدة وكان لها سعر وغير جاري الطلب
                              final canRequest = !isRequesting && currentSelection != null && requestController.currentPrice.value != null;

                              return ElevatedButton.icon(
                                icon: isRequesting ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) : const Icon(Icons.shopping_cart_checkout_rounded),
                                label: Text(currentSelection != null ? 'شراء الآن (${currentSelection['ar']})' : 'اختر المدة أولاً'),
                                style: ElevatedButton.styleFrom( minimumSize: Size(double.infinity, screenHeight * 0.06), backgroundColor: !canRequest ? Colors.grey[400] : Theme.of(context).colorScheme.primary, foregroundColor: Colors.white),
                                onPressed: !canRequest ? null : () {
                                  // عرض حوار التأكيد مع السعر
                                  Get.dialog(AlertDialog(
                                    title: Text('تأكيد الشراء'),
                                    content: Text('هل أنت متأكد من شراء كود $codeName لمدة ${currentSelection['ar']}؟\nالسعر: ${requestController.currentPrice.value}'),
                                    actions: [
                                      TextButton(onPressed: () => Get.back(), child: Text('إلغاء')),
                                      ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green), // زر تأكيد أخضر
                                          onPressed: () async{ Get.back(); // إغلاق الحوار
                                          final Map<String, dynamic>? salesReceipt = await requestController.requestSpecificCode( // <--- تخزين النتيجة
                                            codeName: codeName,
                                            selectedDuration: currentSelection['en']!,
                                            selectedDurationMap: currentSelection, // تمرير الخريطة كاملة
                                          );

                                          // --- التحقق من نجاح العملية وعرض حوار الفاتورة ---
                                          if (salesReceipt != null && salesReceipt['error'] == null) {
                                            // إظهار حوار الفاتورة
                                            Get.dialog(
                                                AlertDialog(
                                                  title: const Text("تفاصيل الفاتورة"),
                                                  contentPadding: const EdgeInsets.all(12), // تقليل الحشو قليلاً
                                                  content: SingleChildScrollView( // مهم إذا كان المحتوى طويلاً
                                                    child: RepaintBoundary( // <--- للالتقاط كصورة
                                                      key: _invoiceBoundaryKey, // <--- ربط المفتاح
                                                      child: InvoiceWidget(salesData: salesReceipt), // <--- استخدام ويدجت الفاتورة
                                                    ),
                                                  ),
                                                  actions: [
                                                    TextButton( onPressed: () => Get.back(), child: const Text("إغلاق"),),
                                                    ElevatedButton.icon( // <--- زر حفظ الصورة
                                                      icon: const Icon(Icons.save_alt_rounded),
                                                      label: const Text("حفظ الفاتورة"),
                                                      onPressed: () {
                                                        _saveInvoiceAsImage(context).then((_) {
                                                          // يمكنك إغلاق حوار الفاتورة بعد الحفظ أو تركه
                                                          // Get.back();
                                                        });
                                                      },
                                                    )
                                                  ],
                                                ),
                                                barrierDismissible: false // منع الإغلاق بالنقر خارجًا
                                            );
                                          } else if (salesReceipt != null && salesReceipt['error'] != null) {
                                            // معالجة خطأ حفظ الفاتورة الذي أشرنا إليه سابقاً
                                            Get.snackbar("تنبيه", "تم تخصيص الكود لك، لكن فشل حفظ الفاتورة: ${salesReceipt['error']}", duration: Duration(seconds: 5));
                                          }
                                            // لا نفعل شيئاً إذا كانت salesReceipt هي null (تم عرض خطأ الشراء بالفعل من الكنترولر)
                                          },
                                          child: Text('تأكيد وشراء'))
                                    ],
                                  ));
                                },
                              );
                            }), // نهاية Obx لزر الشراء
                          ],
                          ),
                        ),
                        );
                      }
                    }),
                  SizedBox(height: screenHeight * 0.025),
// --- نهاية Obx الخارجي ---


                  // --- قسم التقييمات والتعليقات ---
                  Divider(height: screenHeight * 0.03),
                  Text( 'التقييمات والتعليقات', style: TextStyle(fontSize: screenWidth * 0.05, fontWeight: FontWeight.w600)),
                  SizedBox(height: screenHeight * 0.01),
                  // --- زر إضافة/تعديل تقييم ---
                  Padding(
                    padding: EdgeInsets.only(top: screenHeight*0.01, bottom: screenHeight * 0.01),
                    child: Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text( 'التقييمات', style: TextStyle(fontSize: screenWidth * 0.05, fontWeight: FontWeight.w600)),
                      if (currentUser != null) TextButton.icon( // زر الإضافة/التعديل فقط للمسجلين
                        onPressed: () { // البحث عن تقييم المستخدم الحالي أولاً قبل فتح الحوار
                          FirebaseFirestore.instance .collection('codeGroups').doc(itemId).collection('reviews')
                              .where('userId', isEqualTo: currentUser.uid).limit(1).get().then((snapshot) {
                            String? existingId; double initialRating = 0.0; String initialComment = '';
                            if (snapshot.docs.isNotEmpty) {
                              final doc = snapshot.docs.first; existingId = doc.id;
                              initialRating = (doc.data())['rating']?.toDouble() ?? 0.0;
                              initialComment = (doc.data())['comment'] ?? ''; }
                            showRatingDialog( existingReviewId: existingId, initialRating: initialRating, initialComment: initialComment,); }); },
                        icon: const Icon(Icons.edit_note), label: const Text("أضف/عدّل تقييمك"),), ]),
                  ),

                  if (currentUser != null) // السماح فقط للمسجلين بالتقييم

                    StreamBuilder<QuerySnapshot>(
                      // البحث عن تقييم سابق للمستخدم الحالي
                        stream: FirebaseFirestore.instance
                            .collection('codeGroups').doc(itemId).collection('reviews')
                            .where('userId', isEqualTo: currentUser.uid)
                            .limit(1)
                            .snapshots(),
                        builder: (context, snapshot) {
                          String? existingReviewId;
                          double initialRating = 0.0;
                          String initialComment = '';

                          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                            final userReviewDoc = snapshot.data!.docs.first;
                            existingReviewId = userReviewDoc.id;
                            initialRating = (userReviewDoc.data() as Map<String,dynamic>)['rating']?.toDouble() ?? 0.0;
                            initialComment = (userReviewDoc.data() as Map<String,dynamic>)['comment'] ?? '';
                          }

                          return Center(
                            child: ElevatedButton.icon(
                                icon: Icon(existingReviewId == null ? Icons.rate_review_outlined : Icons.edit_note_rounded),
                                label: Text(existingReviewId == null ? 'أضف تقييمك' : 'تعديل تقييمك'),
                                onPressed: () => showRatingDialog(
                                  existingReviewId: existingReviewId,
                                  initialRating: initialRating,
                                  initialComment: initialComment,
                                )
                            ),
                          );
                        }
                    )
                  else // رسالة لغير المسجلين
                    const Text("سجّل الدخول لتتمكن من إضافة تقييم."),
                  SizedBox(height: screenHeight * 0.02),


                  // --- عرض التقييمات الموجودة ---
                  StreamBuilder<QuerySnapshot>(
                    // جلب التقييمات مرتبة بالأحدث
                    stream: FirebaseFirestore.instance
                        .collection('codeGroups').doc(itemId).collection('reviews')
                        .orderBy('createdAt', descending: true)
                    // يمكنك إضافة .limit(عدد معين) هنا إذا أردت تحديد عدد التقييمات المعروضة
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Center(child: Text("خطأ في تحميل التعليقات."));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text("لا توجد تقييمات لهذا الكود بعد."));
                      }

                      // بناء قائمة بالتقييمات
                      final reviews = snapshot.data!.docs;
                      return ListView.builder(
                        shrinkWrap: true, // ضروري داخل SliverList
                        physics: const NeverScrollableScrollPhysics(), // منع التمرير داخل القائمة
                        itemCount: reviews.length,
                        itemBuilder: (context, index) {
                          final reviewData = reviews[index].data() as Map<String, dynamic>;
                          final rating = (reviewData['rating'] as num?)?.toDouble() ?? 0.0;
                          final comment = reviewData['comment'] as String?;
                          final userName = reviewData['userName'] ?? 'مستخدم';
                          final reviewTime = (reviewData['createdAt'] as Timestamp?)?.toDate();

                          return Card(
                            margin: EdgeInsets.symmetric(vertical: screenHeight * 0.008),
                            elevation: 1,
                            child: Padding(
                              padding: EdgeInsets.all(screenWidth * 0.03),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(userName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth*0.038)),
                                      if(reviewTime != null)
                                        Text(DateFormat('yy/MM/dd', 'ar').format(reviewTime), style: TextStyle(color: Colors.grey, fontSize: screenWidth*0.03)),
                                    ],
                                  ),
                                  SizedBox(height: screenHeight * 0.005),
                                  RatingBarIndicator( // عرض النجوم للقراءة فقط
                                    rating: rating,
                                    itemBuilder: (context, index) => const Icon( Icons.star, color: Colors.amber),
                                    itemCount: 5,
                                    itemSize: screenWidth * 0.045,
                                    direction: Axis.horizontal,
                                  ),
                                  if (comment != null && comment.isNotEmpty) ...[
                                    SizedBox(height: screenHeight * 0.01),
                                    Text(comment, style: TextStyle(fontSize: screenWidth*0.038)),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // دالة مساعدة لعرض صف معلومات (أيقونة، عنوان، قيمة)
  Widget _buildInfoRow(BuildContext context, IconData icon, String title, String value, double screenWidth, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0), // زيادة المسافة الرأسية قليلاً
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // محاذاة الأيقونة والنص للبداية
        children: [
          Icon(icon, size: screenWidth * 0.048, color: Colors.grey[600]), // تكبير الأيقونة قليلاً
          SizedBox(width: screenWidth * 0.03),
          Text('$title ', style: TextStyle(fontSize: screenWidth * 0.04, color: Colors.grey[700], fontWeight: FontWeight.w500)), // تغيير لون الخط قليلاً
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: screenWidth * 0.041, fontWeight: FontWeight.w600, color: valueColor), // زيادة حجم وسمك الخط
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }





  // --- ▼▼▼ تعديل دالة بناء زر المفضلة لاستخدام GetBuilder ▼▼▼ ---
  Widget _buildFavoriteButton({
    required BuildContext context, // قد لا نحتاج context هنا
    required CodeGroupsController controller,
    required String itemId,
    required double screenWidth,
    double sizeMultiplier = 1.0,
    bool useDarkBackground = true,
  }) {
    // التأكد من أن itemId صالح
    if (itemId.isEmpty || itemId.startsWith('invalid_')) {
      return const SizedBox.shrink();
    }

    // استخدام GetBuilder الذي يستمع للتحديثات عبر المعرف المحدد
    return GetBuilder<CodeGroupsController>(
      id: CodeGroupsController.favoriteButtonId, // استخدام المعرف المحدد في الكنترولر
      init: controller, // يمكنك تحديد الكنترولر هنا أو الاعتماد على Get.find
      builder: (ctrl) { // ctrl هنا هو نفس controller الذي تم تمريره أو العثور عليه
        // قراءة الحالة الحالية من الكنترولر
        final bool isFav = ctrl.isFavorite(itemId);
        // تحديد لون الأيقونة
        final Color iconColor = useDarkBackground
            ? (isFav ? Colors.pinkAccent : Colors.white)
            : (isFav ? Colors.pinkAccent : Colors.grey[600]!);

        // بناء واجهة الزر (Material, InkWell, Icon)
        return Material(
          color: useDarkBackground ? Colors.black38 : Colors.transparent, // استخدم black38
          shape: const CircleBorder(),
          elevation: useDarkBackground ? 2.0 : 0.0,
          child: InkWell(
            onTap: () => ctrl.toggleFavorite(itemId), // استدعاء الدالة لتبديل الحالة
            customBorder: const CircleBorder(),
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.012 * sizeMultiplier),
              child: Icon(
                // تحديد شكل الأيقونة بناءً على الحالة الحالية
                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: iconColor,
                size: screenWidth * 0.055 * sizeMultiplier,
              ),
            ),
          ),
        );
      },
    );
  }

   // --- ▼▼▼ دالة لحفظ الفاتورة كصورة ▼▼▼ ---
   Future<void> _saveInvoiceAsImage(BuildContext context) async {
     // 1. طلب الأذونات اللازمة
     PermissionStatus status;
     if (GetPlatform.isIOS) {
       status = await Permission.photosAddOnly.request(); // إذن إضافة صور لـ iOS
     } else if (GetPlatform.isAndroid) {
       // لإصدارات Android 13+، نطلب الوصول للصور فقط
       // لإصدارات أقدم، قد يتطلب الأمر Storage ولكن package:image_gallery_saver غالبًا يتعامل معها
       final sdkInt = /*await _getAndroidSDKVersion() ??*/ 33; // افترض مؤقتًا 33، يمكنك الحصول على الرقم الفعلي
       if (sdkInt >= 33) {
         status = await Permission.photos.request();
       } else {
         status = await Permission.storage.request();
       }
     } else {
       status = PermissionStatus.granted; // افترض الإذن لمنصات أخرى غير مدعومة مباشرة
     }


     // 2. التحقق من حالة الإذن
     if (!status.isGranted) {
       debugPrint("Photo Library permission not granted.");
       Get.snackbar(
         "الإذن مطلوب",
         "نحتاج إذن الوصول إلى معرض الصور لحفظ الفاتورة.",
         mainButton: TextButton(
             onPressed: () => openAppSettings(), // فتح إعدادات التطبيق
             child: const Text("فتح الإعدادات")),
         duration: const Duration(seconds: 5),
       );
       return;
     }

     // إظهار مؤشر تحميل بسيط
     Get.dialog( const Center(child: CircularProgressIndicator( valueColor: AlwaysStoppedAnimation<Color>(Colors.white), )), barrierDismissible: false);


     // 3. تحويل الويدجت (RepaintBoundary) إلى صورة
     try {
       RenderRepaintBoundary boundary = _invoiceBoundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
       ui.Image image = await boundary.toImage(pixelRatio: 2.0);
       ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
       if (byteData == null) { throw Exception("Failed to convert image to byte data."); }
       Uint8List pngBytes = byteData.buffer.asUint8List();
       // 4. حفظ الصورة باستخدام image_gallery_saver
       final result = await ImageGallerySaverPlus.saveImage( // <--- هذا يجب أن يعمل الآن
           pngBytes,
           quality: 90,
           name: "فاتورة_كود_${DateTime.now().millisecondsSinceEpoch}",
           isReturnImagePathOfIOS: true // تحقق من اسم هذا المعامل في الحزمة الجديدة إذا لزم الأمر
       );

       Get.back(closeOverlays: true); // إغلاق مؤشر التحميل المحدد

       debugPrint("Image save result: $result");
       if (result != null && result['isSuccess'] == true) {
         Get.snackbar( "تم الحفظ", "تم حفظ الفاتورة بنجاح في معرض الصور.", icon: const Icon(Icons.check_circle, color: Colors.white), backgroundColor: Colors.green, colorText: Colors.white);

       } else {
         throw Exception("ImageGallerySaver failed: ${result?['errorMessage'] ?? 'Unknown error'}");
       }
     } catch (e,s) {
       Get.back(); // إخفاء مؤشر التحميل في حالة الخطأ
       debugPrint("Error saving invoice image: $e\n$s");
       Get.snackbar("خطأ", "حدث خطأ أثناء حفظ صورة الفاتورة.", icon: const Icon(Icons.error, color: Colors.white), backgroundColor: Colors.red, colorText: Colors.white);
     }
   }
// --- ▲▲▲ نهاية دالة حفظ الفاتورة ▲▲▲ ---

}