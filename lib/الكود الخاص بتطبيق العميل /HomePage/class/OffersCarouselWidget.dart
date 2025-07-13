import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
// ---!!! إضافة الاستيراد التالي !!!---

// استيراد شاشة التفاصيل الفعلية
import '../../../Model/model_offer_item.dart';
import '../../../XXX/xxx_firebase.dart';
import 'DetailsOfItemScreen.dart'; // تأكد من المسار الصحيح

class OffersCarouselController extends GetxController {
  // متحكم الصفحة للـ PageView
  late PageController pageController;

  // متغير تفاعلي لتتبع الصفحة الحالية
  final RxInt currentPage = 0.obs;

  @override
  void onInit() {
    super.onInit();
    // تهيئة PageController عند بدء المتحكم
    pageController = PageController(initialPage: currentPage.value);
    // إضافة مستمع لمراقبة تغييرات الصفحة
    pageController.addListener(() {
      // تحديث currentPage.value فقط إذا تغيرت الصفحة فعلياً
      // استخدام round() للحصول على الصفحة الصحيحة أثناء التمرير
      final currentRoundedPage = pageController.page?.round() ?? 0;
      if (currentPage.value != currentRoundedPage) {
        currentPage.value = currentRoundedPage;
        // debugPrint("Offer Page changed to: ${currentPage.value}"); // لـ Debugging
      }
    });
    debugPrint("OffersCarouselController Initialized");
  }

  @override
  void onClose() {
    debugPrint("OffersCarouselController Disposed");
    // التخلص من PageController عند إغلاق المتحكم
    pageController.dispose();
    super.onClose();
  }

  // دالة Stream لجلب العروض (يمكن تركها في الويدجت أو وضعها هنا)
  // وضعها هنا قد يكون أفضل لفصل الاهتمامات
  Stream<QuerySnapshot<Map<String, dynamic>>> get offerStream =>
      FirebaseFirestore.instance
          .collection(FirebaseX.offersCollection) // اسم مجموعة العروض
          .where('appName', isEqualTo: FirebaseX.appName)
          // .orderBy('timestamp', descending: true)
          .limit(10) // يمكن جعل العدد قابلاً للتغيير
          .snapshots();

  // دالة الانتقال (يمكن تركها في الويدجت أيضاً)
  void navigateToDetails(BuildContext context, OfferModel offer) {
    Get.to(() =>
        DetailsOfItemScreen(
          // ---!!! تمرير كائن OfferModel مباشرة !!!---
          item: offer, // <-- تمرير الكائن نفسه
        ));
  }
}


// ==========================================================
//  2. تعديل ملف OffersCarouselWidget.dart
// ==========================================================

class OffersCarouselWidget extends StatelessWidget {
  // <-- تغيير إلى StatelessWidget
  const OffersCarouselWidget({super.key});

  // دالة بناء هيكل تحميل شريط العروض
  Widget _buildShimmerOfferSkeleton(BuildContext context, double targetHeight) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 10.0),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        // ---!!! تغليف Child بـ SizedBox ذو ارتفاع محدد !!!---
        child: SizedBox(
          height: targetHeight, // <-- استخدام الارتفاع الممرر
          child: _buildOfferSkeletonCard(context), // بناء الهيكل
        ),
        // ------------------------------------------------
      ),
    );
  }
  // بناء هيكل بطاقة العرض الواحدة
  Widget _buildOfferSkeletonCard(BuildContext context) {
    final wi = MediaQuery
        .of(context)
        .size
        .width;
    return Card(
        elevation: 3.0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Row(children: [
          Expanded(flex: 3,
              child: Padding(padding: const EdgeInsets.all(10.0),
                  child: Column(children: [
                    Container(width: wi * 0.2, height: 20, color: Colors.white),
                    const Spacer(flex: 1),
                    Container(width: wi * 0.3, height: 14, color: Colors.white),
                    const SizedBox(height: 5),
                    Container(
                        width: wi * 0.25, height: 12, color: Colors.white),
                    const Spacer(flex: 1),
                    Container(
                        width: wi * 0.18, height: 10, color: Colors.white),
                    const SizedBox(height: 4),
                    Container(
                        width: wi * 0.22, height: 16, color: Colors.white),
                    const Spacer(flex: 2),
                  ]))),
          Expanded(flex: 4, child: Container(color: Colors.white)),
        ]));
  }

  Widget _buildErrorWidget(double wi, double hi) =>
      SizedBox(
        height: hi * 0.28,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.red[200]!)),
            child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.cloud_off, color: Colors.red[400], size: wi * 0.1),
                  const SizedBox(height: 8),
                  Text('فشل تحميل العروض. حاول مرة أخرى.', // <<-- تعريب
                      style: TextStyle(color: Colors.red[700]),
                      textAlign: TextAlign.center)
                ])),
          ),
        ),
      );

  // بناء واجهة المستخدم لحالة عدم وجود عروض متاحة
  Widget _buildEmptyOfferState(BuildContext context) {
    // الحصول على ارتفاع وعرض الشاشة للتحجيم النسبي (اختياري)
    // final screenHeight = MediaQuery.of(context).size.height;
    final theme = Theme.of(context); // للوصول إلى ألوان ونصوص الثيم

    return SizedBox(
      // استخدم ارتفاعًا مشابهًا لارتفاع الكاروسيل للحفاظ على التخطيط
      // يمكنك تعديل هذا الارتفاع حسب تصميمك
      height: MediaQuery.of(context).size.height * 0.28,
      child: Center( // توسيط المحتوى
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0), // إضافة بعض الحشو الأفقي
          child: Column(
            mainAxisSize: MainAxisSize.min, // ليأخذ العمود أقل ارتفاع ممكن
            children: [
              // أيقونة معبرة
              Icon(
                Icons.campaign_outlined, // أيقونة حملات أو عروض (بديل لـ local_offer_off)
                // Icons.sentiment_very_dissatisfied_outlined, // أيقونة وجه حزين
                size: 70, // حجم الأيقونة
                color: Colors.grey[400], // لون رمادي باهت
              ),
              const SizedBox(height: 20), // مسافة بين الأيقونة والنص

              // النص الرئيسي
              Text(
                "لا توجد عروض حالياً!", // رسالة واضحة
                style: theme.textTheme.titleMedium?.copyWith( // استخدام نمط عنوان متوسط من الثيم
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8), // مسافة بين النص الرئيسي والثانوي

              // النص الثانوي (اختياري)
              Text(
                "تابعنا باستمرار لمعرفة آخر الخصومات المميزة.", // رسالة تشجيعية
                style: theme.textTheme.bodySmall?.copyWith( // استخدام نمط جسم صغير
                  color: Colors.grey[600],
                  height: 1.4, // تباعد أسطر أفضل للقراءة
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // واجهة عنصر تالف
  Widget _buildCorruptedItemWidget(double wi, double hi) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6.0),
    child: Card(
        elevation: 2.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        color: Colors.orange[50], // لون مختلف للخطأ
        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children:[ Icon(Icons.error_outline, color: Colors.orange[600], size: wi*0.1), SizedBox(height: 5), Text('بيانات تالفة', style: TextStyle(color: Colors.orange[800])) ]))),
  );

  // بناء بطاقة العرض

  // --- بناء بطاقة العرض ---
  Widget _buildOfferCard(OffersCarouselController controlar,BuildContext context, OfferModel offer, double wi, double hi, ThemeData theme) {
    return GestureDetector(
      onTap: () => controlar.navigateToDetails(context, offer), // استدعاء دالة الانتقال
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0), // مسافة بين البطاقات
        child: Card(
          elevation: 3.0, // ظل خفيف
          clipBehavior: Clip.antiAlias, // قص المحتوى الزائد عند الحواف
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Row(
            children: [
              // --- القسم الأيسر: النصوص والمعلومات ---
              Expanded(
                flex: 3, // يأخذ 3 أجزاء من المساحة
                child: Container(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center, // توسيط العناصر عمودياً
                    children: [
                      // شارة الخصم (إذا كان موجودًا)
                      if (offer.rate > 0)
                        Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: theme.colorScheme.error, // لون مميز للخصم
                                borderRadius: BorderRadius.circular(20)),
                            child: Text('${offer.rate}% خصم', // <<-- تعريب
                                style: TextStyle(
                                    color: theme.colorScheme.onError, // لون النص على لون الخطأ
                                    fontSize: wi * 0.04, fontWeight: FontWeight.bold))),

                      // const Spacer(flex: 1), // مسافة مرنة

                      // اسم العرض
                      Text(offer.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: wi * 0.045 // حجم مناسب
                          ),
                          maxLines: 2, // حد أقصى سطرين
                          overflow: TextOverflow.ellipsis, // نقاط عند النص الطويل
                          textAlign: TextAlign.center),

                      const Spacer(flex: 1), // مسافة مرنة

                      // عرض الأسعار
                      Column(
                        children: [
                          // السعر القديم (مشطوب عليه إذا كان موجوداً وأكبر من السعر الحالي)
                          if (offer.oldPrice > 0 && offer.oldPrice > offer.price)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2.0),
                              child: Text(
                                  '${offer.oldPrice} ${FirebaseX.currency}',
                                  style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: wi * 0.038,
                                      decoration: TextDecoration.lineThrough,
                                      decorationColor: Colors.red,
                                      decorationThickness: 1.5)),
                            ),

                          // السعر الحالي (بعد الخصم إن وجد)
                          Text('${offer.price} ${FirebaseX.currency}',
                              style: TextStyle(
                                  color: theme.primaryColor,
                                  fontSize: wi * 0.05, // حجم أكبر للسعر
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),

                      const Spacer(flex: 2) // مسافة مرنة أكبر في الأسفل
                    ],
                  ),
                ),
              ),

              // --- القسم الأيمن: الصورة ---
              Expanded(
                  flex: 4, // يأخذ 4 أجزاء من المساحة (أكبر للصورة)
                  child: Stack(
                    fit: StackFit.expand, // لتمديد الصورة والغطاء ليملأ المساحة
                    children: [
                      // الصورة باستخدام CachedNetworkImage
                      CachedNetworkImage(
                        imageUrl: offer.imageUrl ?? '', // استخدام رابط فارغ آمن
                        placeholder: (context, url) => Container(
                            color: Colors.grey[200],
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                        errorWidget: (context, url, error) => Container(
                            color: Colors.grey[100],
                            child: Center(child: Icon(Icons.error_outline, color: Colors.grey[400], size: wi * 0.1))),
                        fit: BoxFit.cover, // تغطية المساحة المتاحة
                      ),
                      // عرض أيقونة تشغيل الفيديو إذا كان الرابط موجودًا
                      if (offer.videoUrl != null && offer.videoUrl != 'noVideo')
                        Positioned(
                            top: 10,
                            right: 10, // في الزاوية اليمنى العلوية
                            child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
                                child: const Icon(Icons.play_circle_outline_rounded, size: 22, color: Colors.white)))
                    ],
                  )
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- حقن أو إيجاد المتحكم ---
    // نستخدم Get.put إذا كان هذا هو المكان الوحيد لاستخدام المتحكم،
    // أو Get.find إذا تم حقنه في مكان أعلى (Binding أو Parent Widget).
    // لجعلها مستقلة أكثر، نستخدم Get.put هنا.
    final OffersCarouselController controller = Get.put(OffersCarouselController());

    final hi = MediaQuery.of(context).size.height;
    final wi = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    final double carouselHeight = hi * 0.28;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      // --- الحصول على الـ stream من المتحكم ---
      stream: controller.offerStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerOfferSkeleton(context,carouselHeight);
        }
        if (snapshot.hasError) {
          debugPrint("Error loading offers: ${snapshot.error}");
          return _buildErrorWidget(wi,hi);
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return _buildEmptyOfferState(context);
        }

        // عدد العناصر
        final int itemCount = docs.length;

        return Column(
          children: [
            SizedBox(
              height: hi * 0.28,
              child: PageView.builder(
                // --- استخدام PageController من المتحكم ---
                controller: controller.pageController,
                itemCount: itemCount,
                itemBuilder: (ctx, index) {
                  try {
                    final offer = OfferModel.fromMap(docs[index].data(), docs[index].id);
                    // --- تمرير المتحكم لدالة البناء ---
                    return _buildOfferCard(controller,context, offer, wi, hi, theme, );
                  } catch (e, s) {
                    debugPrint("Error parsing offer at index $index: $e\n$s");
                    return _buildCorruptedItemWidget(wi, hi); // تأكد من أن هذه الدالة معرفة
                  }
                },
              ),
            ),

            // --- استخدام المؤشر مع القيمة التفاعلية من المتحكم ---
            if (itemCount > 1)
              Padding(
                padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
                child: SmoothPageIndicator( // <--- استخدام SmoothPageIndicator
                  // --- استخدام PageController من المتحكم مباشرة ---
                  controller: controller.pageController, // <<<--- هنا التغيير الأساسي
                  count: itemCount,                    // عدد النقاط/الصفحات
                  // --- اختيار التأثير الذي تريده ---
                  effect: WormEffect( // أو ExpandingDotsEffect, ScrollingDotsEffect, ScaleEffect, etc.
                    dotHeight: 9,      // حجم النقطة
                    dotWidth: 9,
                    spacing: 8,     // المسافة بين النقاط
                    activeDotColor: theme.primaryColor, // لون النقطة النشطة
                    dotColor: Colors.grey[300]!,     // لون النقطة غير النشطة
                    // يمكنك إضافة type: WormType.thin إذا أردت شكل الدودة أرق
                  ),
                  // (اختياري) الانتقال عند النقر على النقاط
                  onDotClicked: (index) {
                    controller.pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              )
            else
              const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}