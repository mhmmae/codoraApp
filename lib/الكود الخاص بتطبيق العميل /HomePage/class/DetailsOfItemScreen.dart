import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

// ---!!! استيراد المتحكم الصحيح !!!---
// تأكد من أن المسار لملف DetailsItemController.dart صحيح
// تأكد من أن مسار AddAndRemoveSearchWidget.dart صحيح ويشير للملف المصحح
import '../../../Model/category_model.dart';
import '../../../Model/model_item.dart';
import '../../../Model/model_offer_item.dart';

import '../../../Model/review_model.dart';
import '../../../XXX/xxx_firebase.dart';
import '../../TheOrder/ChooseCategory/CategoryController.dart';
import '../Get-Controllar/addAndRemoveSearch.dart'; // <-- أو AddAndRemoveSearchWidget المصحح


import '../../bottonBar/botonBar.dart';
import 'DetalesOfItems.dart';   // تأكد من المسار

// تأكد من أن هذا الاستيراد لا يتسبب في مشاكل (إذا كنت قد عرفت المتحكم في نفس الملف)
// import 'DetalesOfItems.dart'; // يبدو أن هذا استيراد للملف نفسه؟ يمكن حذفه غالبًا

// شاشات افتراضية (استبدلها بصفحاتك الفعلية إذا لزم الأمر)
class ViewImageFullscreen extends StatelessWidget { final String imageUrl; const ViewImageFullscreen({super.key, required this.imageUrl}); @override Widget build(BuildContext c) { return Scaffold(appBar: AppBar(), body: InteractiveViewer(child: Center(child: CachedNetworkImage(imageUrl: imageUrl, placeholder: (c,u)=>const CircularProgressIndicator(), errorWidget: (c,u,e)=>const Icon(Icons.error))))); } }
// --- نهاية الشاشات الافتراضية ---




class DetailsOfItemScreen extends StatelessWidget {
  // تمرير النموذج بأكمله أسهل الآن
  final dynamic item;
  final bool isActuallyOffer; // لتحديد النوع بوضوح
  late final String itemId;
  late final String uidAdd;

  // --- حقن الـ Controller باستخدام tag فريد (ID المنتج) و Binding ---
  // يجب أن يكون لديك Binding يقوم بحقن DetailsController
  late final DetailsItemController controller;
  final String _controllerTag;

  DetailsOfItemScreen({super.key, required this.item})
      : isActuallyOffer = (item is OfferModel),
        itemId = (item is OfferModel ? item.id : (item as ItemModel).id),
        uidAdd = (item is OfferModel ? item.uidAdd : (item as ItemModel).uidAdd),

      _controllerTag = (item is OfferModel ? item.id : (item as ItemModel).id) {
    // حقن/إيجاد المتحكم
    try {
      controller = Get.find<DetailsItemController>(tag: _controllerTag);
      debugPrint("DetailsScreen: Found controller tag: $_controllerTag");
    } catch (e) {
      debugPrint("DetailsScreen: Putting new controller tag: $_controllerTag");
      controller = Get.put(
          DetailsItemController(item: item, isOffer: isActuallyOffer),
          tag: _controllerTag,
          permanent: false);
    }
  }

  // --- دالة عرض مربع حوار/صفحة إضافة تقييم وتعليق ---
  void _showAddReviewDialog(BuildContext context) {
    // استخدم Get.bottomSheet أو Get.dialog لعرض الواجهة
    Get.bottomSheet(
      AddReviewWidget(controller: controller, productId: item.id), // <--- ويدجت جديدة لهذا
      isScrollControlled: true, // للسماح بالارتفاع حسب المحتوى
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    );
  }

  // --- دالة للخروج من الشاشة وحذف المتحكم ---
  void _navigateBack() {
    try {
      debugPrint("Navigating back from details, deleting controller with tag: $_controllerTag");
      Get.delete<DetailsItemController>(tag: _controllerTag, force: true);
    } catch(e) { debugPrint("Error deleting DetailsController: $e"); }
    Get.back(); // العودة للشاشة السابقة
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;
    final categoryCtrl = Get.find<CategoryController>();

    // --- الوصول للبيانات من المتحكم ---
    // استخدام Getters لتبسيط الواجهة
    final String name = controller.getItemName();
    final double price = controller.getPrice();
    final double? oldPrice = controller.getOldPrice(); // سيكون null إذا لم يكن عرضًا
    final int? rate = controller.getRate(); // سيكون null إذا لم يكن عرضًا
    final String imageUrl = controller.getImageUrl();
    final String? description = controller.getDescription();
    final String? videoUrl = controller.getVideoUrl();
    final List<String> images = controller.getManyImages();
    final String itemTypeKey = isActuallyOffer ? '' : (item as ItemModel).typeItem;

    // ---!!! التصحيح هنا للتعامل مع orElse الآمن !!!---
    String categoryNameAr; // تعريف المتغير

    if (itemTypeKey.isNotEmpty && !isActuallyOffer) {
      // البحث عن الفئة المطابقة
      final foundCategory = categoryCtrl.categories.firstWhere(
            (cat) => cat.nameEn == itemTypeKey,
        // --- الجزء البديل (orElse) الآمن ---
        orElse: () {
          debugPrint("Warning: Category with key '$itemTypeKey' not found in controller list. Using default.");
          // لا تحاول الوصول لـ .first إذا كانت القائمة قد تكون فارغة.
          // يمكنك إرجاع نموذج افتراضي أو التعامل مع null هنا.
          // بما أن النموذج الآن يضمن قيمة لـ nameAr، يمكن أن نعيد null نظرياً
          // ولكن إرجاع كائن افتراضي أفضل غالبًا لتجنب فحص null لاحقاً
          return const CategoryModel(id: 'unknown', nameEn: 'unknown', nameAr: 'غير مصنف'); // <-- نموذج افتراضي
        },
      );
      categoryNameAr = foundCategory.nameAr; // اسم القسم العربي الآمن
    } else if (isActuallyOffer) {
      categoryNameAr = 'عرض خاص'; // أو نص آخر للعروض
    } else {
      categoryNameAr = 'غير مصنف'; // قيمة افتراضية إذا كان typeItem فارغاً أو خطأ آخر
    }
    return Scaffold(
      bottomNavigationBar: _buildBottomActionBar(context, itemId, uidAdd,isActuallyOffer, theme),



      body: WillPopScope( // للتعامل مع زر الرجوع في الجهاز
        onWillPop: () async { _navigateBack(); return false; },
        child: CustomScrollView(
          controller: controller.scrollController, // ربط الـ ScrollController
          slivers: [
            // --- 1. AppBar مع الصورة كخلفية ---
            SliverAppBar(
              expandedHeight: screenHeight * 0.45, // <--- ارتفاع المنطقة القابلة للتمدد (نصف الشاشة تقريبا)
              pinned: true, // <--- جعل الـ AppBar يبقى ظاهرًا عند التمرير
              stretch: true, // السماح بالتمدد عند السحب لأسفل (اختياري)
              elevation: 1.0, // ظل خفيف عندما يتم تثبيته
              backgroundColor: theme.scaffoldBackgroundColor, // لون خلفية AppBar العادي
              foregroundColor: theme.colorScheme.primary, // لون أيقونة الرجوع والنص
              leading: IconButton( icon: const Icon(Icons.arrow_back_ios_new), onPressed: _navigateBack ),
              title: Obx(()=> controller.showAppBarTitle.value // <--- حالة لعرض العنوان عند الانكماش
                  ? Text(name, style: TextStyle(fontSize: 18, color: theme.textTheme.titleLarge?.color))
                  : const SizedBox.shrink()
              ), // إظهار العنوان فقط عند انكماش الصورة
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [StretchMode.zoomBackground], // تأثير التمدد
                background: Hero( // --- الصورة الرئيسية ---
                  tag: 'item_image_$itemId',
                  child: CachedNetworkImage(
                    imageUrl: imageUrl ?? '',
                    fit: BoxFit.cover, // املأ المساحة
                    errorWidget: (c, u, e) => Container(color: Colors.grey[200], child: const Center(child: Icon(Icons.error))),
                    placeholder: (c, u) => Container(color: Colors.grey[200]), // يمكنك وضع Shimmer هنا
                  ),
                ),
                // --- (اختياري) يمكنك وضع عنوان صغير هنا يظهر دائمًا ---
                // title: Text(item.name, style: TextStyle(shadows: [/*...*/])),
                // centerTitle: true,
              ),
            ), // نهاية SliverAppBar

            // --- 2. المحتوى الأساسي للمنتج ---
            SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // -- اسم المنتج --
                      Text(name, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      // -- السعر و الخصم (إذا كان عرضاً - افترض item.isOffer غير مستخدم ونعتمد على النوع الممرر) --
                      // أو إذا كنت تحتاج لدعم عرض المنتجات العادية كـ "عروض" مؤقتة هنا، ستحتاج لمنطق إضافي
                      _buildPriceSection(price, oldPrice, rate, theme),
                      // Row( children: [ Text('${price} ${FirebaseX.currency ?? 'ريال'}', style: theme.textTheme.headlineSmall?.copyWith(color: theme.primaryColor, fontWeight: FontWeight.bold)) ], ),
                      const SizedBox(height: 12),

                      // -- التقييم الكلي وزر إضافة تقييم --
                      Row(
                        children: [
                          // استخدام Obx لمراقبة متوسط التقييم
                          Obx(() => RatingBarIndicator(

                            rating: controller.averageRating.value, // <--- القيمة من المتحكم
                            itemBuilder: (context, index) => Icon( Icons.star_rounded, color: Colors.amber ),
                            itemCount: 5,
                            itemSize: 22.0,
                            direction: Axis.horizontal,
                          )),
                          SizedBox(width: 8),
                          // عرض عدد المراجعات (إذا كان متاحًا في المتحكم)
                          Obx(()=> Text("(${controller.reviewCount.value})", style: theme.textTheme.bodySmall)), // <--- من المتحكم
                          const Spacer(),
                          TextButton.icon(
                            icon: const Icon(Icons.edit_note_outlined, size: 20),
                            label: const Text("أضف تقييمك"), // <<-- تعريب
                            onPressed: () => _showAddReviewDialog(context),
                            style: TextButton.styleFrom(foregroundColor: theme.primaryColor),
                          )
                        ],
                      ),

                      const Divider(height: 25, thickness: 1),
                      if (!controller.isOffer) ...[ // <-- تحقق من isOffer في Controller
                        // الوصول للبيانات الخاصة بالمنتج من خلال دوال Controller المساعدة
                            () { // استخدام دالة مجهولة للحصول على categoryNameAr بأمان
                          final itemTypeKey = controller.getItemTypeKey(); // الحصول على مفتاح النوع
                          if (itemTypeKey.isEmpty) return _buildInfoRow(Icons.category_outlined, "القسم", "غير مصنف"); // حالة لا يوجد فيها مفتاح

                          final category = categoryCtrl.categories.firstWhere(
                                  (cat) => cat.nameEn == itemTypeKey,
                              orElse: () => const CategoryModel(id: '', nameEn: '', nameAr: 'غير مصنف', order: 999, isActive: false) // افتراضي
                          );
                          return _buildInfoRow(Icons.category_outlined, "القسم", category.nameAr); // عرض اسم القسم
                        }(),
                        _buildInfoRow(Icons.shield_outlined, "الحالة", _getArabicText(controller.getItemCondition())),
                        _buildInfoRow(Icons.star_half_outlined, "الجودة", controller.getQualityGrade()?.toString() ?? 'غير محدد'),
                        _buildInfoRow(Icons.flag_outlined, "بلد المنشأ", _getArabicText(controller.getCountryOfOrigin())),
                      ] else ...[
                        // عرض معلومات العرض إذا أردت
                        _buildInfoRow(Icons.local_offer_rounded, "نوع المنتج", "عرض خاص"), // كمثال
                      ],
                      // // --- معلومات المنتج الإضافية (الحالة، الجودة، القسم، إلخ) ---
                      //
                      // _buildInfoRow(Icons.category_outlined, "القسم", categoryNameAr), // الاسم العربي للقسم
                      // _buildInfoRow(Icons.shield_outlined, "الحالة", _getArabicText(item.itemCondition)), // تحويل النص للعربي
                      // _buildInfoRow(Icons.star_half_outlined, "درجة الجودة", item.qualityGrade?.toString() ?? 'غير محدد'),
                      // _buildInfoRow(Icons.flag_outlined, "بلد المنشأ", _getArabicText(item.countryOfOrigin)),
                      // // أضف أي معلومات أخرى هنا بنفس الطريقة

                      const Divider(height: 25, thickness: 1),
                    ],
                  ),
                )
            ),

            // --- 3. معرض الصور والفيديو الإضافي ---
            if (images.isNotEmpty || (videoUrl != null && videoUrl != 'noVideo'))
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Text("الصور والفيديو", style: theme.textTheme.titleLarge),
                      ),
                      // إضافة معرض الصور والفيديو هنا (مثل ListView أفقي)
                      _buildMediaGallery(context, item.videoUrl, item.manyImages),
                    ],
                  ),
                ),
              ),


            // --- 4. قسم الوصف ---
            if (description != null && description.isNotEmpty)
              SliverPadding( // إضافة Padding لـ Sliver
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                sliver: SliverToBoxAdapter( // تحويل Column إلى Sliver
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("الوصف", style: theme.textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(item.description!, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),


            // --- 5. قسم التقييمات والتعليقات ---
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 5),
              sliver: SliverToBoxAdapter(
                child: Row( // إضافة زر الفرز هنا
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Obx(()=> Text("التقييمات (${controller.reviewCount.value})", style: theme.textTheme.titleLarge)),
                    // --- زر الفرز ---
                    _buildSortButton(context, controller, theme),
                  ],
                ),
              ),
            ),
            // --- بناء قائمة التعليقات باستخدام StreamBuilder ---
            Obx(() {
              if (controller.isReviewsLoading.value) { return const SliverFillRemaining(child: Center(child: CircularProgressIndicator())); } // SliverFillRemaining تملأ المساحة
              if (controller.reviews.isEmpty) { return const SliverFillRemaining(child: Center(child: Text("لا توجد تقييمات بعد..."))); }

              return SliverList(
                delegate: SliverChildBuilderDelegate( (context, index) {
                  final review = controller.reviews[index];
                  // ---!!! استخدام _buildReviewItem المُعدّل !!!---
                  return _buildReviewItem(context, review, controller, theme);
                },
                  childCount: controller.reviews.length,
                ),
              );
            }),

            // --- إضافة مساحة سفلية لتجنب تغطية زر السلة ---
            SliverToBoxAdapter(child: SizedBox(height: screenHeight * 0.12)),

          ],
        ),
      ),
    );
  }




  // ---!!! (جديد) بناء الشريط السفلي للأزرار !!!---
  Widget _buildBottomActionBar(BuildContext context, String currentItemId,String uidAdd, bool isCurrentOffer, ThemeData theme) {
    final wi = MediaQuery.of(context).size.width;
    final hi = MediaQuery.of(context).size.height;

    return Container(
      width: wi,height: hi/10,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor, // لون الخلفية
          border: Border(top: BorderSide(color: Colors.grey[300]!, width: 0.5)), // خط فاصل علوي
          boxShadow: [ // ظل خفيف (اختياري)
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: Offset(0,-2))
          ]
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // توزيع المسافات
        children: [
          // --- أزرار الإضافة والإزالة +/- ---
          // تأكد أن لديك استيراد لهذه الويدجت
          AddAndRemoveSearchWidget(
            uidItem: currentItemId, // تمرير ID المنتج/العرض الحالي
            isOffer: isCurrentOffer, // تمرير حالة هل هو عرض أم لا
            uidAdd: uidAdd,
            // تخصيص الأحجام (اختياري لتناسب الشريط السفلي)
            buttonHeight: hi * 0.055,
            buttonWidth: wi * 0.1,
            iconSize: wi * 0.06,
            numberFontSize: wi * 0.05,
            spacing: wi * 0.02,
          ),

          // --- زر "أضف إلى السلة" (أو الذهاب للسلة) ---
          ElevatedButton.icon(
            onPressed: () {
              // يمكنك هنا إضافة منطق للتحقق مما إذا كان المنتج موجوداً في السلة قبل الانتقال
              // أو فقط الانتقال المباشر
              Get.offAll(() => const BottomBar(initialIndex: 2)); // الذهاب لتبويب السلة (index 2)
            },
            icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 20),
            label: const Text("اذهب إلى السلة"), // <<-- تعريب
            style: ElevatedButton.styleFrom(
              // يمكنك جعل الزر يأخذ عرضًا أكبر إذا أردت
              minimumSize: Size(wi * 0.45, hi * 0.055),
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildPriceSection(double price, double? oldPrice, int? rate, ThemeData theme) {
    // ... (منطق عرض السعر القديم المشطوب والنسبة والسعر الحالي) ...
    return Row( // مثال بسيط
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('$price ${FirebaseX.currency ?? 'ريال'}', style: theme.textTheme.headlineSmall?.copyWith(color: theme.primaryColor, fontWeight: FontWeight.bold)),
        if(oldPrice != null && oldPrice > price) ... [
          const SizedBox(width: 8),
          Text('$oldPrice ${FirebaseX.currency ?? 'ريال'}', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600], decoration: TextDecoration.lineThrough)),
        ],
        if (rate != null && rate > 0) ... [
          const SizedBox(width: 8),
          Chip(label: Text('$rate% خصم'), backgroundColor: theme.colorScheme.errorContainer, labelStyle: TextStyle(color: theme.colorScheme.onErrorContainer, fontSize: 12), padding: EdgeInsets.zero, visualDensity: VisualDensity.compact)
        ]
      ],);
  }



  // --- دوال مساعدة إضافية للبناء ---

  // لعرض صف معلومات (أيقونة - عنوان - قيمة)
  Widget _buildInfoRow(IconData icon, String label, String value) {
    // تجنب عرض الصف إذا كانت القيمة غير متوفرة
    if (value.isEmpty || value == 'غير محدد') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text("$label: ", style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500)),
          Expanded(child: Text(value, style: TextStyle(fontWeight: FontWeight.normal))),
        ],
      ),
    );
  }

  // دالة بسيطة لترجمة بعض النصوص الثابتة (يمكن تحسينها)
  String _getArabicText(String? key) {
    if (key == null) return 'غير محدد'; // <<-- تعريب
    switch(key) {
      case 'original': return 'أصلي';
      case 'commercial': return 'تجاري';
      case 'CN': return 'الصين';
      case 'US': return 'أمريكا';
    // أضف باقي البلدان والحالات هنا
      default: return key; // إرجاع المفتاح كما هو إذا لم يتم العثور على ترجمة
    }
  }


  // دالة بناء معرض الصور والفيديو
  Widget _buildMediaGallery(BuildContext context, String? videoUrl, List<String> imageUrls) {
    final screenWidth = MediaQuery.of(context).size.width;
    final itemHeight = screenWidth * 0.28; // ارتفاع مناسب
    final List<Widget> mediaItems = [];

    // إضافة الفيديو أولاً إذا كان موجودًا
    if (videoUrl != null && videoUrl != 'noVideo') {
      mediaItems.add(
        GestureDetector(
          onTap: () => Get.to(()=> ViewVideoFullscreen(videoUrl: videoUrl)),
          child: Container(
            width: itemHeight * 1.5, // اجعل الفيديو أعرض قليلاً
            height: itemHeight,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.black, // خلفية سوداء للفيديو
            ),
            // يمكنك إضافة صورة مصغرة للفيديو هنا إذا أردت (باستخدام get_thumbnail_video)
            // أو مجرد أيقونة تشغيل
            child: const Center(child: Icon(Icons.play_circle_outline_rounded, color: Colors.white, size: 40)),
          ),
        ),
      );
    }

    // إضافة الصور
    mediaItems.addAll(
      imageUrls.map((url) => GestureDetector(
        onTap: () => Get.to(() => ViewImageFullscreen(imageUrl: url)),
        child: Container(
          width: itemHeight, // اجعل الصور مربعة
          height: itemHeight,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration( borderRadius: BorderRadius.circular(10) ),
          clipBehavior: Clip.antiAlias, // لقص الصورة
          child: CachedNetworkImage(imageUrl: url, fit: BoxFit.cover, placeholder: (c,u)=>Container(color:Colors.grey[200]), errorWidget: (c,u,e)=> Container(color: Colors.grey[100], child: Icon(Icons.image))),
        ),
      )).toList(),
    );

    // عرض القائمة الأفقية
    return SizedBox(
      height: itemHeight,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10), // لإعطاء مسافة قبل أول عنصر وبعد آخر عنصر
        children: mediaItems,
      ),
    );
  }



}
// ---!!! (جديد) بناء عنصر التعليق الواحد مع الردود والإعجاب !!!---
Widget _buildReviewItem(BuildContext context, ReviewModel review, DetailsItemController controller, ThemeData theme) {
  // --- الاستماع لحالة الإعجاب لهذا التعليق المحدد ---
  // (الطريقة المبسطة: استخدام StreamBuilder لكل عنصر)
  final userLikeStream = controller.userLikesStreamForReview(review.id); // <-- دالة جديدة في Controller

  return Padding(
    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 0, top: 8), // تعديل Padding
    // استخدام ExpansionTile لإظهار/إخفاء الردود
    child: ExpansionTile(
      tilePadding: EdgeInsets.zero, // إزالة الحشو الافتراضي
      childrenPadding: const EdgeInsets.only(left: 40, top: 8, bottom: 8), // مسافة بادئة للردود
      // إزالة السهم الافتراضي واستخدام تصميمنا الخاص
      trailing: SizedBox.shrink(),
      // العنوان الرئيسي للتعليق (المحتوى الذي يظهر دائمًا)
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- الصف العلوي (الصورة، الاسم، التقييم، التاريخ) ---
          Row(  children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: (review.userImageUrl != null) ? CachedNetworkImageProvider(review.userImageUrl!) : null,
              child: (review.userImageUrl == null) ? const Icon(Icons.person, size: 18) : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(review.userName, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  // يمكنك إضافة تاريخ التعليق هنا
                  Text(
                    DateFormat('yyyy/MM/dd - hh:mm a', 'ar').format(review.timestamp.toDate()), // <-- تنسيق التاريخ
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            RatingBarIndicator(
              rating: review.rating,
              itemBuilder: (context, index) => const Icon( Icons.star_rounded, color: Colors.amber),
              itemCount: 5,
              itemSize: 16.0,
            ),
          ],
          ),
          // --- نص التعليق ---
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding( padding: const EdgeInsets.only(right: 52, left: 8), child: Text(review.comment!, style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),),
          ],
          const SizedBox(height: 10),
          // --- أزرار الإعجاب والرد ---
          Row(
            mainAxisAlignment: MainAxisAlignment.end, // وضعها في اليمين
            children: [
              // --- زر الإعجاب ---
              StreamBuilder<bool>(
                  stream: userLikeStream, // <--- استخدام Stream المنفصل
                  initialData: false, // افتراض أنه ليس معجب
                  builder: (context, snapshot) {
                    final bool isLiked = snapshot.data ?? false;
                    return TextButton.icon(
                      icon: Icon( isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: isLiked ? Colors.redAccent : Colors.grey, size: 18, ),
                      // عرض العدد بجانب القلب
                      label: Text( controller.getLikesCountForReview(review.id).toString(), style: TextStyle(color: Colors.grey, fontSize: 13)), // <--- دالة جديدة في Controller
                      onPressed: () => controller.toggleLike(review.id, isLiked),
                      style: TextButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2), minimumSize: Size(0, 20), visualDensity: VisualDensity.compact),
                    );
                  }
              ),
              SizedBox(width: 15),
              // --- زر الرد ---
              TextButton.icon(
                icon: const Icon(Icons.reply_outlined, size: 18, color: Colors.grey),
                label: Text("رد", style: TextStyle(color: Colors.grey, fontSize: 13)),
                onPressed: () => controller.startReplying(review.id), // <-- دالة جديدة في Controller
                style: TextButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2), minimumSize: Size(0, 20), visualDensity: VisualDensity.compact),
              ),
            ],
          ),
        ],
      ),

      // --- بناء قائمة الردود (عند توسيع ExpansionTile) ---
      children: <Widget>[ // <-- استخدام <Widget> لتحديد النوع
        // مراقبة الردود المحملة وحالة التحميل
        Obx(() {
          final isLoadingReplies = controller.repliesLoadingMap[review.id] ?? false;
          final repliesList = controller.repliesMap[review.id] ?? [];

          if (isLoadingReplies) {
            return const Padding(padding: EdgeInsets.all(8.0), child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))));
          }
          if (repliesList.isEmpty) {
            return const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Text("لا توجد ردود.", style: TextStyle(color: Colors.grey)));
          }
          // عرض الردود
          return Column(
            children: repliesList.map((replyData) {
              // افترض أن لديك نموذج ReplyModel أو تعامل مع Map مباشرة
              return _buildReplyItem(context, replyData, theme); // <--- دالة جديدة لبناء الرد
            }).toList(),
          );
        }),

        // --- إضافة حقل الرد إذا كان المستخدم يرد على هذا التعليق ---
        Obx(() {
          if (controller.replyingToReviewId.value == review.id) {
            return _buildReplyInput(context, controller, theme); // <--- ويدجت جديدة لحقل الرد
          }
          return const SizedBox.shrink(); // لا تعرض شيئًا إذا لم يكن يرد
        })
      ],
      // --- استدعاء جلب الردود عند توسيع التعليق لأول مرة ---
      onExpansionChanged: (isExpanding) {
        if (isExpanding && (controller.repliesMap[review.id]?.isEmpty ?? true)) {
          controller.fetchReplies(review.id); // جلب الردود فقط عند الحاجة
        }
      },
    ),
  );
}

// --- (جديد) دالة بناء عنصر الرد ---
Widget _buildReplyItem(BuildContext context, Map<String, dynamic> replyData, ThemeData theme) {
  // الوصول للبيانات من الخريطة بأمان
  final String userName = replyData['userName'] ?? 'مستخدم';
  final String? userImageUrl = replyData['userImageUrl'];
  final String comment = replyData['comment'] ?? '';
  final Timestamp timestamp = replyData['timestamp'] ?? Timestamp.now();

  return Padding(
    padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar( radius: 15, /*...*/ backgroundImage: (userImageUrl != null) ? CachedNetworkImageProvider(userImageUrl) : null, child: (userImageUrl == null) ? const Icon(Icons.person, size: 15) : null),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(userName, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
              Text(comment, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13.5, height: 1.4)),
              const SizedBox(height: 2),
              Text(DateFormat('dd MMM, hh:mm a', 'ar').format(timestamp.toDate()), style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey[500], fontSize: 10.5)),
            ],
          ),
        ),
        // يمكن إضافة زر إعجاب أو إبلاغ للرد هنا
      ],
    ),
  );
}

// --- (جديد) بناء ويدجت حقل إدخال الرد ---
Widget _buildReplyInput(BuildContext context, DetailsItemController controller, ThemeData theme) {
  return Padding(
    padding: const EdgeInsets.only(top: 10.0, bottom: 5.0),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller.replyController, // استخدام متحكم الرد
            decoration: InputDecoration(
              hintText: "اكتب ردك هنا...",
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
            style: TextStyle(fontSize: 14),
            minLines: 1, maxLines: 3, // السماح بأكثر من سطر
            textInputAction: TextInputAction.send, // تغيير زر الإدخال
            onSubmitted: (_) => _sendReply(controller), // الإرسال عند الضغط على Enter
          ),
        ),
        const SizedBox(width: 8),
        // زر إرسال الرد (مراقبة حالة الإرسال)
        Obx(()=> IconButton(
          icon: controller.isSendingReply.value
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(Icons.send_rounded, color: theme.primaryColor),
          onPressed: controller.isSendingReply.value ? null : () => _sendReply(controller), // استدعاء الدالة نفسها
        )),
      ],
    ),
  );
}
// دالة مساعدة لإرسال الرد (لتقليل التكرار)
void _sendReply(DetailsItemController controller) {
  if (controller.replyController.text.trim().isNotEmpty && controller.replyingToReviewId.value != null) {
    controller.addReply(controller.replyingToReviewId.value!, controller.replyController.text.trim());
  }
}


// --- (جديد) بناء زر الفرز ---
Widget _buildSortButton(BuildContext context, DetailsItemController controller, ThemeData theme) {
  return PopupMenuButton<ReviewSortOption>(
    icon: Icon(Icons.sort_rounded, color: Colors.grey[600]),
    tooltip: "فرز التعليقات",
    onSelected: controller.changeReviewSort,
    itemBuilder: (BuildContext context) => <PopupMenuEntry<ReviewSortOption>>[
      for (final option in ReviewSortOption.values)
        PopupMenuItem<ReviewSortOption>(
          value: option,
          child: Obx(() => Row( // لإظهار علامة الصح
            children: [
              Text(option.label, style: TextStyle( fontWeight: controller.currentReviewSort.value == option ? FontWeight.bold : FontWeight.normal )),
              if (controller.currentReviewSort.value == option) ...[const Spacer(), const Icon(Icons.check, size: 18)],
            ],
          )),
        ),
    ],
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );
}


// --- ويدجت منفصلة لإضافة تقييم وتعليق (مثال مبسط) ---
class AddReviewWidget extends StatelessWidget {
  final DetailsItemController controller; // تمرير المتحكم للوصول لدالة الحفظ
  final String productId;

  AddReviewWidget({super.key, required this.controller, required this.productId});

  final TextEditingController _commentController = TextEditingController();
  final RxDouble _currentRating = (0.0).obs; // قيمة أولية
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView( // للسماح بالتمرير عند ظهور الكيبورد
      child: Padding(
        padding: EdgeInsets.only( bottom: MediaQuery.of(context).viewInsets.bottom + 16, left: 16, right: 16, top: 16 ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("أضف تقييمك وتعليقك", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 15),
              // --- تحديد التقييم بالنجوم ---
              Obx(() => RatingBar.builder(
                initialRating: _currentRating.value, // <-- ابدأ بالقيمة الحالية
                minRating: 1, // الحد الأدنى للتقييم
                direction: Axis.horizontal,
                allowHalfRating: false, // هل تسمح بنصف نجمة؟
                itemCount: 5,
                itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder: (context, _) => Icon( Icons.star_rounded, color: Colors.amber, ),
                onRatingUpdate: (rating) {
                  _currentRating.value = rating; // تحديث قيمة التقييم التفاعلية
                },
              )),
              const SizedBox(height: 20),
              // --- حقل التعليق (اختياري) ---
              TextFormField(
                controller: _commentController,
                decoration: InputDecoration(
                  labelText: "أضف تعليقًا (اختياري)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  alignLabelWithHint: true, // لجعل الـ label يرتفع عند الكتابة
                ),
                maxLines: 3, // السماح بعدة أسطر
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 25),
              // --- زر الإرسال ---
              ElevatedButton(
                onPressed: () {
                  if (_currentRating.value < 1) { // تأكد أن المستخدم قيم
                    Get.snackbar("تنبيه", "الرجاء تحديد تقييم (نجمة واحدة على الأقل).", snackPosition: SnackPosition.BOTTOM);
                    return;
                  }
                  controller.addReview( // استدعاء دالة في المتحكم
                    productId: productId,
                    rating: _currentRating.value,
                    comment: _commentController.text.trim(),
                  );
                  Get.back(); // إغلاق الـ BottomSheet بعد الإرسال (أو عند النجاح)
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 45), // زر بعرض الشاشة
                ),
                child: const Text("إرسال التقييم"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}






class FullScreenVideoController extends GetxController {
  final String videoUrl;
  FullScreenVideoController({required this.videoUrl}); // استقبال الرابط

  VideoPlayerController? videoPlayerController;

  // --- State Variables (Reactive) ---
  final isLoading = true.obs;
  final showControls = true.obs;
  final isPlaying = false.obs;
  final isInitialized = false.obs;
  final isBuffering = false.obs;
  final currentPosition = Duration.zero.obs;
  final totalDuration = Duration.zero.obs;
  final aspectRatio = (16 / 9).obs; // قيمة افتراضية

  Timer? _hideControlsTimer;

  @override
  void onInit() {
    super.onInit();
    debugPrint("FullScreenVideoController onInit for: $videoUrl");
    _enterFullScreen();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    isLoading.value = true;
    debugPrint("[FS Controller - URL: $videoUrl] Init: Starting");
    final Uri? videoUri = Uri.tryParse(videoUrl);

    if (videoUri == null) {
      debugPrint("[FS Controller - URL: $videoUrl] Init ERROR: Invalid URL");
      _handleInitializationError("رابط الفيديو غير صالح.");
      return;
    }

    try {
      videoPlayerController = VideoPlayerController.networkUrl(videoUri)
        ..addListener(_videoListener);
      debugPrint("[FS Controller - URL: $videoUrl] Init: Controller instance created.");

      await videoPlayerController?.initialize(); // الانتظار هنا
      debugPrint("[FS Controller - URL: $videoUrl] Init: initialize() awaited.");

      // التحقق بعد الانتظار
      if (videoPlayerController == null || !videoPlayerController!.value.isInitialized) {
        debugPrint("[FS Controller - URL: $videoUrl] Init ERROR: Failed after initialize() awaited.");
        throw Exception('Video Controller not initialized after await.');
      }

      // --- نجاح التهيئة ---
      debugPrint("[FS Controller - URL: $videoUrl] Init SUCCESS! Ratio: ${videoPlayerController!.value.aspectRatio}, Duration: ${videoPlayerController!.value.duration}");
      aspectRatio.value = videoPlayerController!.value.aspectRatio;
      totalDuration.value = videoPlayerController!.value.duration;
      isInitialized.value = true;
      isLoading.value = false;

      // --- محاولة التشغيل ---
      videoPlayerController?.play(); // <<--- التشغيل
      isPlaying.value = videoPlayerController?.value.isPlaying ?? false; // تحديث الحالة فوراً
      debugPrint("[FS Controller - URL: $videoUrl] Init: play() called. isPlaying: ${isPlaying.value}");

      _startHideControlsTimer();
      debugPrint("[FS Controller - URL: $videoUrl] Init: State updated, timer started.");

    } catch (error, stackTrace) {
      debugPrint("!!! [FS Controller - URL: $videoUrl] Init CRITICAL ERROR: $error\nStack Trace: $stackTrace");
      _handleInitializationError("فشل تهيئة الفيديو: $error");
    }
  }

  // أضف طباعة في togglePlayPause أيضاً
  void togglePlayPause() {
    if (!isInitialized.value || videoPlayerController == null) return;
    debugPrint("[FS Controller - URL: $videoUrl] Toggle Play/Pause. Current isPlaying: ${videoPlayerController!.value.isPlaying}");
    if (videoPlayerController!.value.isPlaying) {
      videoPlayerController!.pause();
    } else {
      if (currentPosition.value >= totalDuration.value) {
        videoPlayerController!.seekTo(Duration.zero);
      }
      videoPlayerController!.play();
    }
    // المستمع سيحدث isPlaying.value
    _startHideControlsTimer();
  }

  void _handleInitializationError(String message) {
    if (!isClosed) { // التأكد أن المتحكم لم يتم إغلاقه
      isLoading.value = false;
      isInitialized.value = false; // مهم جداً
      videoPlayerController?.removeListener(_videoListener);
      videoPlayerController = null;
      Get.snackbar('خطأ', message, snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.withOpacity(0.8), colorText: Colors.white);
    }
  }

  void _videoListener() {
    if (videoPlayerController == null || !videoPlayerController!.value.isInitialized || isClosed) return;

    currentPosition.value = videoPlayerController!.value.position;
    isBuffering.value = videoPlayerController!.value.isBuffering;

    // تحديث حالة isPlaying مباشرة من المتحكم
    if (isPlaying.value != videoPlayerController!.value.isPlaying) {
      isPlaying.value = videoPlayerController!.value.isPlaying;
    }


    if (!videoPlayerController!.value.isLooping && currentPosition.value >= totalDuration.value && totalDuration.value > Duration.zero) {
      isPlaying.value = false; // توقف عند النهاية
      // videoPlayerController?.seekTo(Duration.zero); // العودة للبداية اختياري
    }
  }



  // ---!!! (جديد) بناء الشريط السفلي للأزرار !!!---
  Widget _buildBottomActionBar(BuildContext context,String uidAdd, String currentItemId, bool isCurrentOffer, ThemeData theme) {
    final wi = MediaQuery.of(context).size.width;
    final hi = MediaQuery.of(context).size.height;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor, // لون الخلفية
          border: Border(top: BorderSide(color: Colors.grey[300]!, width: 0.5)), // خط فاصل علوي
          boxShadow: [ // ظل خفيف (اختياري)
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: Offset(0,-2))
          ]
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // توزيع المسافات
        children: [
          // --- أزرار الإضافة والإزالة +/- ---
          // تأكد أن لديك استيراد لهذه الويدجت
          AddAndRemoveSearchWidget(
            uidItem: currentItemId, // تمرير ID المنتج/العرض الحالي
            isOffer: isCurrentOffer, // تمرير حالة هل هو عرض أم لا
            uidAdd:uidAdd ,
            // تخصيص الأحجام (اختياري لتناسب الشريط السفلي)
            buttonHeight: hi * 0.055,
            buttonWidth: wi * 0.1,
            iconSize: wi * 0.06,
            numberFontSize: wi * 0.05,
            spacing: wi * 0.02,
          ),

          // --- زر "أضف إلى السلة" (أو الذهاب للسلة) ---
          ElevatedButton.icon(
            onPressed: () {
              // يمكنك هنا إضافة منطق للتحقق مما إذا كان المنتج موجوداً في السلة قبل الانتقال
              // أو فقط الانتقال المباشر
              Get.offAll(() => const BottomBar(initialIndex: 2)); // الذهاب لتبويب السلة (index 2)
            },
            icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 20),
            label: const Text("اذهب إلى السلة"), // <<-- تعريب
            style: ElevatedButton.styleFrom(
              // يمكنك جعل الزر يأخذ عرضًا أكبر إذا أردت
              minimumSize: Size(wi * 0.45, hi * 0.055),
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }



  void toggleControls() {
    showControls.value = !showControls.value;
    if (showControls.value) {
      _startHideControlsTimer();
    } else {
      _hideControlsTimer?.cancel();
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (showControls.value && isPlaying.value && !isClosed) {
        showControls.value = false;
      }
    });
  }

  void _enterFullScreen() {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      // يمكن إضافة تغيير اتجاه الشاشة هنا إذا لزم الأمر
    }
  }

  void _exitFullScreen() {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([ DeviceOrientation.portraitUp ]);
    }
  }

  void goBack() {
    // لا تحتاج لاستدعاء dispose هنا، onClose تفعل ذلك
    Get.back();
  }


  @override
  void onClose() {

    debugPrint("FullScreenVideoController onClose for: $videoUrl");
    _exitFullScreen();
    _hideControlsTimer?.cancel();
    videoPlayerController?.removeListener(_videoListener); // إزالة المستمع أولاً
    final controllerToDispose = videoPlayerController; // متغير مؤقت آمن
    videoPlayerController = null; // قطع المرجع
    // التخلص من المتحكم يأخذ بعض الوقت، لا تنتظره ولكن تأكد من استدعائه
    controllerToDispose?.dispose().then((_) => debugPrint("VideoPlayer disposed")).catchError((e)=> debugPrint("Error disposing player: $e"));
    super.onClose();
  }
}



class ViewVideoFullscreen extends StatelessWidget {
  final String videoUrl;
  const ViewVideoFullscreen({super.key, required this.videoUrl});

  @override
  Widget build(BuildContext context) {
    // --- حقن الـ Controller ---
    // نستخدم tag فريد (مثل videoUrl نفسه أو جزء منه) لضمان عدم تداخل المتحكمات
    // إذا فتح المستخدم شاشتين فيديو بملء الشاشة لروابط مختلفة.
    // `permanent: false` مهم جداً ليتم حذف المتحكم عند إغلاق الشاشة.
    final controller = Get.put(
        FullScreenVideoController(videoUrl: videoUrl),
        tag: videoUrl, // استخدام الرابط كـ Tag (أو جزء منه إذا كان طويلاً جداً)
        permanent: false
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea( // استخدم SafeArea لمنع التداخل الكامل مع الحواف
        child: GestureDetector(
          onTap: controller.toggleControls, // استدعاء دالة الـ Controller
          child: Center(
            // --- استخدام Obx لمراقبة isLoading ---
            child: Obx(() {
            // ---!!! طباعة حالة المتحكم عند بناء الواجهة !!!---
            debugPrint("[FS View - ${controller.videoUrl}] Build: isLoading=${controller.isLoading.value}, isInitialized=${controller.isInitialized.value}, isPlaying=${controller.isPlaying.value}");
          // ---------------------------------------------------

          if (controller.isLoading.value) {
    return const CircularProgressIndicator(color: Colors.white);
    }
        if (!controller.isInitialized.value || controller.videoPlayerController == null) {
      return const Text( 'فشل تحميل الفيديو', style: TextStyle(color: Colors.white, fontSize: 18),);
    }
    // ... (باقي بناء AspectRatio و VideoPlayer و Controls) ...

              // --- استخدام Obx لمراقبة aspectRatio وعرض المشغل ---
              return Obx(() => AspectRatio(
                // التأكد أن القيمة موجبة وليست NaN قبل استخدامها
                aspectRatio: controller.aspectRatio.value.isNaN || controller.aspectRatio.value <= 0 ? 16/9 : controller.aspectRatio.value,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    // --- مشغل الفيديو ---
                    VideoPlayer(controller.videoPlayerController!),

                    // --- طبقة الأزرار (استخدام Obx لمراقبة showControls) ---
                    Obx(() => AnimatedOpacity(
                      opacity: controller.showControls.value ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: _buildControlsOverlay(context, controller), // تمرير المتحكم
                    )),
                  ],
                ),
              ));
            }
            ),
          ),
        ),
      ),
    );
  }

  // --- بناء طبقة التحكم (أصبحت دالة ثابتة أو ضمن الـ StatelessWidget) ---
  Widget _buildControlsOverlay(BuildContext context, FullScreenVideoController controller) {
    final theme = Theme.of(context); // الحصول على الثيم هنا
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Colors.black54],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // زر الرجوع
          Align( alignment: Alignment.topLeft, child: Padding( padding: const EdgeInsets.all(8.0), child: IconButton( icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 28), onPressed: controller.goBack, // <-- استدعاء دالة المتحكم
          ), ), ),
          // الأزرار السفلية
          Padding( padding: const EdgeInsets.all(8.0), child: Column( mainAxisSize: MainAxisSize.min, children: [
            // شريط التقدم (استخدام Obx لمراقبته إذا لزم الأمر لميزات معقدة)
            if (controller.videoPlayerController != null) // تحقق إضافي
              VideoProgressIndicator(
                controller.videoPlayerController!,
                allowScrubbing: true,
                padding: const EdgeInsets.symmetric(vertical: 10),
                colors: VideoProgressColors( playedColor: theme.colorScheme.primary, bufferedColor: Colors.white54, backgroundColor: Colors.white24, ),
              ),
            // زر التشغيل/الإيقاف (استخدام Obx لمراقبة isPlaying)
            Obx(() => IconButton(
              icon: Icon(
                controller.isPlaying.value ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                color: Colors.white, size: 60,
              ),
              onPressed: controller.togglePlayPause, // <-- استدعاء دالة المتحكم
            )),
          ], ), ),
        ],
      ),
    );
  }
}