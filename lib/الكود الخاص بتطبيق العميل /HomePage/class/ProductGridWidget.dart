import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:uuid/uuid.dart';

import '../../../Model/model_item.dart';
import '../../../Model/model_offer_item.dart';
import '../../../XXX/xxx_firebase.dart';
import '../Get-Controllar/GetSerchController.dart';
import '../Get-Controllar/GetStreamBuildBoxOfItem.dart';
import '../controllers/barcode_filter_controller.dart';
import '../controllers/brand_filter_controller.dart';
import '../controllers/enhanced_category_filter_controller.dart';
import 'BoxAddAndRemove.dart';
import 'DetailsOfItemScreen.dart';
import 'FavoriteController.dart';

class ProductGridWidgetOption extends StatefulWidget {
  final String? selectedSubtypeKey;
  final SortOption? sortOption; // <-- إضافة معامل الترتيب (اختياري)

  // تعديل الـ Constructor لاستقبال الترتيب
  const ProductGridWidgetOption({
    super.key,
    this.selectedSubtypeKey,
    this.sortOption, // اجعله اختياريًا أو اقرأه من المتحكم داخليًا
  });

  @override
  State<ProductGridWidgetOption> createState() =>
      _ProductGridWidgetOptionState();
}

class _ProductGridWidgetOptionState extends State<ProductGridWidgetOption> {
  final String allItemsFilterKey = 'all_items';
  final bool _isAdmin =
      FirebaseAuth.instance.currentUser?.email == FirebaseX.EmailOfWnerApp;

  // --- بناء الـ Stream مع الفلتر والترتيب ---
  Stream<QuerySnapshot<Map<String, dynamic>>> _buildProductStream() {
    return _buildProductStreamWithRetry();
  }

  // دالة مساعدة لبناء الاستعلام مع إعادة المحاولة في حالة خطأ الفهرس
  Stream<QuerySnapshot<Map<String, dynamic>>> _buildProductStreamWithRetry({
    bool skipSort = false,
  }) {
    // ---!!! 1. قراءة خيار الترتيب والفلتر الحاليين !!!---
    // الوصول إلى المتحكمات باستخدام Get.find
    final searchController = Get.find<GetSearchController>();
    final brandController = Get.put(BrandFilterController());

    // تجربة الوصول للنظام الجديد أولاً، وفي حالة عدم وجوده، استخدم النظام القديم
    String currentFilterKey = allItemsFilterKey;

    try {
      final filterController = Get.find<EnhancedCategoryFilterController>();
      currentFilterKey = filterController.getFilterKey();
      debugPrint("🔍 استخدام النظام الجديد للفلاتر: $currentFilterKey");
    } catch (e) {
      debugPrint("🔍 النظام الجديد غير متاح، استخدام النظام المبسط");
      try {
        final categoryFilterController =
            Get.find<EnhancedCategoryFilterController>();
        currentFilterKey = categoryFilterController.getFilterKey();
        debugPrint("🔍 استخدام فلتر النظام المبسط: $currentFilterKey");
      } catch (e2) {
        debugPrint("🔍 النظام المبسط أيضاً غير متاح، استخدام الفلتر الافتراضي");
      }
    }

    final currentSortOption = searchController.currentSortOption.value;

    // التحقق من نوع الفلتر المطلوب (باركود أم براند أم فئات عادية)
    final barcodeController = Get.put(BarcodeFilterController());

    if (barcodeController.hasActiveFilter) {
      currentFilterKey = barcodeController.getFilterKey();
    } else if (brandController.isBrandModeActive.value) {
      currentFilterKey = brandController.getFilterKey();
    } else {
      currentFilterKey = widget.selectedSubtypeKey ?? currentFilterKey;
    }

    debugPrint(
      "🔍 [ProductGridWidget _buildProductStream] Applying Sort: ${currentSortOption.label}, Filter: $currentFilterKey",
    );
    debugPrint("🔍 فلتر النوع: $currentFilterKey");
    debugPrint(
      "🔍 نوع النظام: ${currentFilterKey.contains('_') && currentFilterKey != 'all_items' ? 'نظام جديد (ID-based)' : 'نظام قديم (typeItem)'}",
    );
    debugPrint("🔍 appName: ${FirebaseX.appName}");
    debugPrint("🔍 itemsCollection: ${FirebaseX.itemsCollection}");
    if (currentFilterKey.contains('_') && currentFilterKey != 'all_items') {
      final parts = currentFilterKey.split('_');
      debugPrint("🔍 أجزاء الفلتر: ${parts.join(' | ')}");
    }

    // ---!!! 2. بناء الاستعلام الأساسي مع الفلترة !!!---
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection(FirebaseX.itemsCollection)
        .where('appName', isEqualTo: FirebaseX.appName);

    // تطبيق فلتر النوع إذا كان محددًا
    // دعم النظام القديم (typeItem) والنظام الجديد (mainCategoryId/subCategoryId) ونظام البراند ونظام الباركود
    debugPrint(
      "🔍 مقارنة الفلاتر: currentFilterKey='$currentFilterKey' vs allItemsFilterKey='$allItemsFilterKey'",
    );
    if (currentFilterKey != allItemsFilterKey) {
      // التحقق من نوع الفلتر
      if (currentFilterKey.startsWith('barcode_')) {
        // فلترة حسب الباركود
        final barcodeValue = currentFilterKey.replaceFirst('barcode_', '');
        debugPrint("🎯 تطبيق فلتر الباركود: productBarcode=$barcodeValue");
        query = query.where('productBarcode', isEqualTo: barcodeValue);
      } else if (currentFilterKey.startsWith('original_product_')) {
        // فلترة حسب منتج أصلي محدد
        final productId = currentFilterKey.replaceFirst(
          'original_product_',
          '',
        );
        debugPrint("🎯 تطبيق فلتر المنتج الأصلي: originalProductId=$productId");
        query = query
            .where('itemCondition', isEqualTo: 'original')
            .where('originalProductId', isEqualTo: productId);
      } else if (currentFilterKey.startsWith('original_company_')) {
        // فلترة حسب شركة أصلية محددة
        final companyId = currentFilterKey.replaceFirst(
          'original_company_',
          '',
        );
        debugPrint(
          "🎯 تطبيق فلتر الشركة الأصلية: originalCompanyId=$companyId",
        );
        query = query
            .where('itemCondition', isEqualTo: 'original')
            .where('originalCompanyId', isEqualTo: companyId);
      } else if (currentFilterKey == 'original_brands') {
        // عرض جميع المنتجات الأصلية
        debugPrint("🎯 تطبيق فلتر جميع المنتجات الأصلية");
        query = query.where('itemCondition', isEqualTo: 'original');
      } else if (currentFilterKey.startsWith('main_') ||
          currentFilterKey.startsWith('sub_')) {
        // نظام الأقسام المحسن الجديد - معالجة مباشرة للمفاتيح
        try {
          debugPrint("🎯 تطبيق فلتر النظام المحسن:");
          debugPrint("   - مفتاح الفلتر: '$currentFilterKey'");

          if (currentFilterKey.startsWith('sub_')) {
            // فلتر القسم الفرعي
            final subCategoryId = currentFilterKey.replaceFirst('sub_', '');
            debugPrint("   - القسم الفرعي: '$subCategoryId'");
            query = query.where('subCategoryId', isEqualTo: subCategoryId);
            debugPrint("✅ تم تطبيق فلتر القسم الفرعي: '$subCategoryId'");
          } else if (currentFilterKey.startsWith('main_')) {
            // فلتر القسم الرئيسي
            final mainCategoryId = currentFilterKey.replaceFirst('main_', '');
            debugPrint("   - القسم الرئيسي: '$mainCategoryId'");
            query = query.where('mainCategoryId', isEqualTo: mainCategoryId);
            debugPrint("✅ تم تطبيق فلتر القسم الرئيسي: '$mainCategoryId'");
          }
        } catch (e) {
          debugPrint("❌ خطأ في تطبيق فلتر الأقسام المحسن: $e");
        }
      } else {
        // النظام القديم: typeItem
        debugPrint("🎯 تطبيق فلتر النظام القديم: typeItem=$currentFilterKey");
        query = query.where('typeItem', isEqualTo: currentFilterKey);
      }
    } else {
      debugPrint("🎯 لا توجد فلاتر محددة - سيتم عرض جميع المنتجات");
    }

    // ---!!! 3. تطبيق الترتيب المطلوب !!!---
    if (!skipSort) {
      // تجنب الترتيب المعقد عندما نطبق فلاتر أقسام لتجنب مشاكل الفهارس
      bool hasSpecificCategoryFilter =
          currentFilterKey.startsWith('main_') ||
          currentFilterKey.startsWith('sub_') ||
          currentFilterKey.startsWith('barcode_') ||
          currentFilterKey.startsWith('original_');

      if (!hasSpecificCategoryFilter && currentFilterKey == allItemsFilterKey) {
        // تطبيق الترتيب فقط للاستعلامات العامة
        debugPrint(
          "--> تطبيق الترتيب: ${currentSortOption.field}, descending: ${currentSortOption.descending}",
        );
        try {
          query = query.orderBy(
            currentSortOption.field,
            descending: currentSortOption.descending,
          );
          debugPrint("✅ تم تطبيق الترتيب بنجاح");
        } catch (e) {
          debugPrint("❌ خطأ في تطبيق الترتيب: $e");
        }
      } else {
        debugPrint("--> تخطي الترتيب للفلاتر المحددة لتجنب مشاكل الفهارس");
      }
    } else {
      debugPrint("--> تخطي الترتيب تماماً (إعادة محاولة)");
    }

    // تطبيق limit وإرجاع الـ Stream
    final finalQuery = query.limit(50);
    debugPrint("🔍 الاستعلام النهائي جاهز للتنفيذ مع حد أقصى 50 منتج");
    debugPrint("📊 معايير الفلترة المطبقة:");
    debugPrint(
      "   - الترتيب: ${currentSortOption.field} (${currentSortOption.descending ? 'تنازلي' : 'تصاعدي'})",
    );
    debugPrint("   - الفلتر: $currentFilterKey");
    debugPrint("═══════════════════════════════════════════════════");

    return finalQuery.snapshots();
  }

  // دالة لعرض قائمة السياق للأدمن (مثال مبسط)
  // --- 1. عرض قائمة السياق للأدمن ---
  Future<void> _showAdminContextMenu(
    BuildContext context,
    TapDownDetails details,
    ItemModel item,
    GetStreamBuildBoxOfItemController controller,
  ) async {
    if (!_isAdmin) return;

    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      details.globalPosition & const Size(40, 40), // منطقة صغيرة حول نقطة النقر
      Offset.zero & overlay.size,
    );

    final String? selectedValue = await showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      elevation: 8.0,
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'edit_name',
          child: const ListTile(
            leading: Icon(Icons.edit_outlined, size: 20),
            title: Text('تعديل الاسم'),
            dense: true,
            contentPadding: EdgeInsets.zero, // إزالة الحشو الداخلي
          ),
        ),
        PopupMenuItem<String>(
          value: 'edit_price',
          child: const ListTile(
            leading: Icon(Icons.price_change_outlined, size: 20),
            title: Text('تعديل السعر'),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem<String>(
          value: 'add_as_offer',
          child: ListTile(
            leading: Icon(Icons.local_offer_outlined, color: Colors.blue[700]),
            title: Text(
              'إضافة كعرض',
              style: TextStyle(color: Colors.blue[700]),
            ), // <<-- تعريب
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'delete',
          child: ListTile(
            leading: Icon(
              Icons.delete_outline,
              color: Colors.red[700],
              size: 20,
            ),
            title: Text('حذف المنتج', style: TextStyle(color: Colors.red[700])),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );

    // ---!!! هنا يتم استدعاء الدوال بناءً على اختيار الأدمن !!!---
    switch (selectedValue) {
      case 'edit_name':
        // استدعاء دالة عرض مربع حوار تعديل الاسم
        _showEditDialog(context, controller, item, isEditingName: true);
        break;
      case 'edit_price':
        // استدعاء دالة عرض مربع حوار تعديل السعر
        _showEditDialog(context, controller, item, isEditingName: false);
        break;
      case 'add_as_offer':
        // استدعاء دالة عرض مربع حوار إضافة العرض
        _showAddOfferDialog(context, item);
        break;
      case 'delete':
        // استدعاء دالة عرض مربع حوار تأكيد الحذف
        _showDeleteConfirmationDialog(context, item.id);
        break;
      default:
        debugPrint("Admin context menu dismissed.");
        break;
    }
    // ---------------------------------------------------------
  }

  // ---!!! (جديد) دالة عرض مربع حوار إضافة العرض !!!---
  void _showAddOfferDialog(BuildContext context, ItemModel item) {
    // متحكمات محلية للحقول الجديدة
    final TextEditingController offerPriceController = TextEditingController();
    // السعر القديم يمكن أخذه مباشرة من المنتج
    final double oldPrice = item.suggestedRetailPrice ?? item.price;
    final TextEditingController rateController =
        TextEditingController(); // اختياري
    final Rxn<DateTime> expiryDate = Rxn<DateTime>(
      null,
    ); // لتاريخ الانتهاء (تفاعلي)

    // لحساب نسبة الخصم تلقائياً
    void calculateRate() {
      final int? newPrice = int.tryParse(offerPriceController.text.trim());
      if (newPrice != null && oldPrice > 0 && newPrice < oldPrice) {
        final double discount = ((oldPrice - newPrice) / oldPrice) * 100;
        rateController.text = discount.toStringAsFixed(0); // نسبة صحيحة
      } else {
        rateController.text = ''; // مسح النسبة إذا كان السعر غير صالح
      }
    }

    // إضافة مستمع لتحديث النسبة عند تغيير السعر
    offerPriceController.addListener(calculateRate);

    Get.defaultDialog(
      title: "إضافة المنتج كعرض",
      titleStyle: const TextStyle(fontWeight: FontWeight.bold),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      // جعل مربع الحوار قابل للتمرير
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min, // لتجنب أخذ ارتفاع الشاشة كاملة
          children: [
            Text("منتج: ${item.name}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 5),
            Text("السعر الأصلي: $oldPrice د.ع."),
            const Divider(height: 20),

            // --- حقل السعر الجديد للعرض (إجباري) ---
            TextFormField(
              controller: offerPriceController,
              decoration: InputDecoration(
                labelText: "سعر العرض *",
                hintText: "أدخل السعر بعد الخصم",
                prefixIcon: Icon(Icons.local_offer_outlined, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ], // السماح بالأرقام فقط
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'سعر العرض مطلوب';
                }
                final int? price = int.tryParse(value.trim());
                if (price == null || price <= 0) {
                  return 'أدخل سعراً صحيحاً أكبر من صفر';
                }
                if (price >= oldPrice) {
                  return 'سعر العرض يجب أن يكون أقل من السعر الأصلي';
                } // تحقق إضافي
                return null;
              },
            ),
            const SizedBox(height: 10),

            // --- حقل نسبة الخصم (اختياري ويتم حسابه) ---
            TextFormField(
              controller: rateController,
              decoration: InputDecoration(
                labelText: "نسبة الخصم (%)",
                prefixIcon: Icon(Icons.percent, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                enabled: false, // اجعله غير قابل للتعديل، فقط للقراءة
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 15),

            // --- (اختياري) حقل اختيار تاريخ الانتهاء ---
            Obx(
              () => ListTile(
                // استخدام Obx لتحديث النص عند اختيار تاريخ
                leading: const Icon(Icons.calendar_today_outlined),
                title: Text(
                  expiryDate.value == null
                      ? "تحديد تاريخ انتهاء العرض (اختياري)"
                      : "ينتهي في: ${DateFormat('yyyy/MM/dd').format(expiryDate.value!)}",
                ),
                trailing:
                    expiryDate.value != null
                        ? IconButton(
                          icon: Icon(Icons.clear, size: 20),
                          onPressed:
                              () => expiryDate.value = null, // مسح التاريخ
                        )
                        : null,
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate:
                        expiryDate.value ??
                        DateTime.now().add(
                          const Duration(days: 7),
                        ), // الافتراضي بعد أسبوع
                    firstDate: DateTime.now(), // لا يمكن اختيار تاريخ في الماضي
                    lastDate: DateTime.now().add(
                      const Duration(days: 365 * 2),
                    ), // سنتين كحد أقصى مثلاً
                  );
                  if (pickedDate != null) {
                    expiryDate.value = pickedDate;
                  }
                },
              ),
            ),
            // ---------------------------------------
          ],
        ),
      ),
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700]),
        onPressed: () {
          // التحقق من صحة سعر العرض
          final int? newPrice = int.tryParse(offerPriceController.text.trim());
          if (newPrice == null || newPrice <= 0 || newPrice >= oldPrice) {
            // يمكنك عرض Snackbar أو التعامل مع الخطأ هنا
            Get.snackbar(
              "خطأ",
              "الرجاء إدخال سعر عرض صحيح أقل من السعر الأصلي.",
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.orange,
            );
            return;
          }
          // جمع البيانات النهائية
          final offerData = {
            'newPrice': newPrice,
            'oldPrice': oldPrice,
            'rate':
                int.tryParse(rateController.text.trim()) ??
                0, // استخدم 0 إذا كان فارغاً
            'expiryDate': expiryDate.value,
          };

          Get.back(); // أغلق مربع الحوار
          _saveAsOffer(item, offerData); // استدعاء دالة الحفظ
        },
        child: const Text("إنشاء العرض"), // <<-- تعريب
      ),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: const Text("إلغاء"), // <<-- تعريب
      ),
      radius: 15,
    );

    // التخلص من المستمع عند إغلاق مربع الحوار
    // (يمكن وضعه في onClose الخاص بالحوار إذا كان Get.dialog يدعم ذلك)
    // أو استخدام GetxController للحوار لإدارة المتحكمات بشكل أفضل
  }

  // ---!!! (جديد) دالة لحفظ المنتج كعرض في Firestore !!!---
  Future<void> _saveAsOffer(
    ItemModel originalItem,
    Map<String, dynamic> offerDetails,
  ) async {
    final String newOfferId = const Uuid().v4(); // ID جديد للعرض
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      _showSnackbar('خطأ', 'لم يتم تسجيل الدخول.', Colors.red);
      return;
    }

    try {
      // بناء نموذج العرض الجديد
      final OfferModel newOffer = OfferModel(
        id: newOfferId, // ID جديد
        name: originalItem.name, // نسخ البيانات من المنتج الأصلي
        description: originalItem.description,
        imageUrl: originalItem.imageUrl,
        manyImages: originalItem.manyImages,
        videoUrl: originalItem.videoUrl,
        appName: originalItem.appName,
        uidAdd: currentUserId, // معرف من قام بالإضافة
        // إضافة بيانات العرض
        price: offerDetails['newPrice'], // السعر الجديد
        oldPrice: offerDetails['oldPrice'],
        rate: offerDetails['rate'],
        // يمكنك إضافة حقل لتاريخ الانتهاء إذا اخترت استخدامه
        // expiryTimestamp: offerDetails['expiryDate'] != null ? Timestamp.fromDate(offerDetails['expiryDate']) : null,
        // ربط بالعنصر الأصلي (اختياري)
        originalItemId: originalItem.id,
      );

      // حفظ العرض في مجموعة العروض
      await FirebaseFirestore.instance
          .collection(
            FirebaseX.offersCollection,
          ) // تأكد من أن هذا هو اسم مجموعة العروض الصحيح
          .doc(newOfferId)
          .set(newOffer.toMap());

      _showSnackbar(
        'نجاح',
        'تمت إضافة المنتج "${originalItem.name}" كعرض بنجاح.',
        Colors.green,
      );
    } catch (e) {
      debugPrint("Error saving offer: $e");
      _showSnackbar('خطأ', 'حدث خطأ أثناء حفظ العرض.', Colors.red);
    }
  }

  // دالة Snackbar (ضعها هنا أو يفضل في المتحكم)
  void _showSnackbar(String title, String message, Color backgroundColor) {
    if (Get.isSnackbarOpen) {
      Get.back();
    }
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: backgroundColor,
      colorText: Colors.white,
      margin: const EdgeInsets.all(10),
      borderRadius: 8,
    );
  }

  // دالة مساعدة لتحديد اللون بناءً على درجة الجودة
  Color _getQualityColor(int? grade) {
    if (grade == null) {
      return Colors.grey.shade400; // لون افتراضي إذا لم تتوفر الدرجة
    }
    if (grade >= 1 && grade <= 4) {
      return Colors.green.shade600; // أخضر للدرجات 1-4
    } else if (grade >= 5 && grade <= 7) {
      return Colors.amber.shade700; // أصفر/برتقالي للدرجات 5-7
    } else {
      return Colors.red.shade600; // أحمر للدرجات 8-10
    }
  }

  // دالة عرض حقل تعديل النص (كما في الكود السابق، لكن تحتاج لوضعها داخل مربع حوار غالباً)
  Widget _buildEditTextField(
    TextEditingController controller,
    String label,
    TextInputType inputType,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: SizedBox(
        width: 250, // عرض مناسب لمربع الحوار
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 12,
            ),
          ),
          keyboardType: inputType,
          autofocus: true, // تركيز تلقائي عند الظهور
        ),
      ),
    );
  }

  // مربع حوار لتأكيد الحذف
  void _showDeleteConfirmationDialog(BuildContext context, String itemId) {
    final logic =
        Get.find<GetStreamBuildBoxOfItemController>(); // احصل على المتحكم

    Get.defaultDialog(
      title: "تأكيد الحذف", // <<-- تعريب
      titleStyle: TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.red[700],
      ),
      middleText:
          "هل أنت متأكد من رغبتك في حذف هذا المنتج نهائيًا؟ لا يمكن التراجع عن هذا الإجراء.", // <<-- تعريب
      middleTextStyle: const TextStyle(fontSize: 15),
      confirm: ElevatedButton.icon(
        icon: const Icon(Icons.delete_forever),
        label: const Text("حذف"), // <<-- تعريب
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600]),
        onPressed: () async {
          Get.back(); // إغلاق مربع الحوار أولاً
          try {
            await FirebaseFirestore.instance
                .collection(FirebaseX.itemsCollection)
                .doc(itemId)
                .delete();
            logic.showSnackbar(
              'نجاح',
              'تم حذف المنتج بنجاح.',
              Colors.green,
            ); // <<-- تعريب
          } catch (e) {
            logic.showSnackbar(
              'خطأ',
              'فشل حذف المنتج.',
              Colors.red,
            ); // <<-- تعريب
            debugPrint("Delete Error: $e");
          }
        },
      ),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: const Text("إلغاء"), // <<-- تعريب
      ),
      radius: 10.0,
    );
  }

  // ... (باقي الكود الخاص بـ ProductGridWidget كما هو) ...
  // ... _showAdminContextMenu, _buildEditTextField, _showDeleteConfirmationDialog ...
  // ... build method ...
  @override
  Widget build(BuildContext context) {
    return GetBuilder<EnhancedCategoryFilterController>(
      init: EnhancedCategoryFilterController(),
      builder: (controller) {
        final hi = MediaQuery.of(context).size.height;
        final wi = MediaQuery.of(context).size.width;
        final GetStreamBuildBoxOfItemController logic = Get.put(
          GetStreamBuildBoxOfItemController(),
        );
        Get.put(FavoriteController());

        debugPrint(
          "🔄 إعادة بناء ProductGridWidget - الفلتر المطبق: ${controller.getFilterKey()}",
        );

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream:
              _buildProductStream(), // <-- الدالة تستخدم الترتيب من Get.find الآن
          builder: (context, snapshot) {
            // ... (الكود كما هو لمعالجة loading, error, empty, grid building) ...
            if (snapshot.hasError) {
              debugPrint("❌ Product Grid Error: ${snapshot.error}");
              debugPrint("❌ Stack trace: ${snapshot.stackTrace}");

              // تحليل نوع الخطأ وإعطاء رسالة مناسبة
              String errorMessage = 'خطأ غير معروف';
              if (snapshot.error.toString().contains('requires an index')) {
                errorMessage = 'خطأ في قاعدة البيانات - يتم إصلاحه...';
                debugPrint(
                  "🔧 خطأ الفهرس المكتشف - جاري إعادة المحاولة بدون ترتيب",
                );
              } else if (snapshot.error.toString().contains('permission')) {
                errorMessage = 'خطأ في الصلاحيات';
              } else if (snapshot.error.toString().contains('network')) {
                errorMessage = 'خطأ في الاتصال بالشبكة';
              }

              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade300,
                        size: 60,
                      ),
                      const SizedBox(height: 15),
                      Text(
                        errorMessage,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'جاري المحاولة مرة أخرى...',
                        style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              // return _buildLoadingGrid(context); // استبدال هذا
              return _buildShimmerLoadingGrid(
                context,
              ); // <-- استخدام دالة Shimmer
            }
            final docs = snapshot.data?.docs ?? [];
            debugPrint("🔍 عدد المنتجات المستلمة: ${docs.length}");
            if (docs.isNotEmpty) {
              debugPrint("🔍 أول منتج: ${docs.first.data()}");
            }
            if (docs.isEmpty) {
              debugPrint("❌ لا توجد منتجات تطابق الاستعلام الحالي");

              // إضافة تحقق من وجود البيانات في Firebase بصفة عامة
              FirebaseFirestore.instance
                  .collection(FirebaseX.itemsCollection)
                  .where('appName', isEqualTo: FirebaseX.appName)
                  .limit(5)
                  .get()
                  .then((querySnapshot) {
                    debugPrint(
                      "🔍 عدد المنتجات الإجمالي في التطبيق: ${querySnapshot.docs.length}",
                    );
                    if (querySnapshot.docs.isNotEmpty) {
                      final sampleItem = querySnapshot.docs.first.data();
                      debugPrint("🔍 مثال على منتج في قاعدة البيانات:");
                      debugPrint(
                        "   - mainCategoryId: ${sampleItem['mainCategoryId']}",
                      );
                      debugPrint(
                        "   - subCategoryId: ${sampleItem['subCategoryId']}",
                      );
                      debugPrint("   - typeItem: ${sampleItem['typeItem']}");
                      debugPrint(
                        "   - itemCondition: ${sampleItem['itemCondition']}",
                      );
                    }
                  });

              return _buildEmptyStateWidget(
                context,
              ); // <-- استخدام دالة الحالة الفارغة المحسنة
            }
            // بناء الشبكة
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7),
              child: GridView.builder(
                // NeverScrollableScrollPhysics لأن الشبكة داخل ListView غالباً
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap:
                    true, // لتناسب حجم المحتوى داخل الـ ListView الرئيسي
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // عدد الأعمدة
                  // تحديث childAspectRatio بعد تقليل حجم الصورة بنسبة 8%
                  childAspectRatio:
                      (wi * 0.5) /
                      (hi * 0.31), // تقليل من 0.338 لتتناسب مع الحجم الجديد
                  crossAxisSpacing: 10, // المسافة بين الأعمدة
                  mainAxisSpacing: 10, // المسافة بين الصفوف
                ),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  try {
                    // تأكد من معالجة الخطأ إذا فشل fromMap
                    final item = ItemModel.fromMap(
                      docs[index].data(),
                      docs[index].id,
                    );
                    return _buildItemCard(context, item, wi, hi, logic);
                  } catch (e, s) {
                    debugPrint("Error parsing item at index $index: $e\n$s");
                    // عرض بطاقة خطأ واضحة للمستخدم
                    return Card(
                      color: Colors.red[50],
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.red[400],
                                size: 30,
                              ),
                              SizedBox(height: 5),
                              Text(
                                'خطأ في عرض المنتج',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.red[700]),
                              ), // <<-- تعريب
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  // ---!!! (جديد) بناء هيكل تحميل واحد بـ Shimmer !!!---
  Widget _buildProductSkeletonCard(BuildContext context) {
    final wi = MediaQuery.of(context).size.width;
    final cardWidth = wi * 0.5 - 12; // عرض تقريبي مع الأخذ بالتباعد

    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // منطقة الصورة - حجم ثابت مقلل بنسبة 8%
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.1656,
            child: Container(color: Colors.white),
          ),
          // منطقة النص والأزرار
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: cardWidth * 0.8,
                    height: 12,
                    color: Colors.white,
                  ), // شريط لاسم المنتج
                  SizedBox(height: 5),
                  Container(
                    width: cardWidth * 0.5,
                    height: 10,
                    color: Colors.white,
                  ), // شريط للسعر/أزرار
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---!!! (جديد) بناء شبكة هياكل التحميل بـ Shimmer !!!---
  Widget _buildShimmerLoadingGrid(BuildContext context) {
    final wi = MediaQuery.of(context).size.width;
    final hi = MediaQuery.of(context).size.height;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Shimmer.fromColors(
        // <-- تغليف الشبكة بالشيمر
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio:
                (wi * 0.5) /
                (hi * 0.31), // نفس النسبة المحدثة بعد تقليل الصورة 8%
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: 6, // عرض 6 هياكل تحميل
          itemBuilder:
              (context, index) =>
                  _buildProductSkeletonCard(context), // بناء الهيكل
        ),
      ),
    );
  }

  // ---!!! (جديد) بناء واجهة "لا توجد نتائج" المحسنة !!!---
  Widget _buildEmptyStateWidget(BuildContext context) {
    // معرفة هل تم تطبيق فلتر أم لا
    bool isFiltered = false;
    try {
      final filterController = Get.find<EnhancedCategoryFilterController>();
      isFiltered = filterController.hasActiveFilter.value;
    } catch (e) {
      isFiltered =
          (widget.selectedSubtypeKey != null &&
              widget.selectedSubtypeKey != allItemsFilterKey);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 50.0, horizontal: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFiltered
                  ? Icons.filter_alt_off_outlined
                  : Icons.shelves, // أيقونة مختلفة للفلتر
              size: 70,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            Text(
              isFiltered
                  ? 'لا توجد منتجات تطابق هذا الفلتر'
                  : 'لا توجد منتجات بعد!', // <<-- تعريب
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              isFiltered
                  ? 'جرب اختيار نوع آخر أو قم بإزالة الفلتر.'
                  : 'كن أول من يرى جديدنا!', // <<-- تعريب
              style: TextStyle(fontSize: 15, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            // إضافة زر مسح الفلاتر فقط إذا كان هناك فلتر مطبق
            if (isFiltered) ...[
              const SizedBox(height: 25),
              OutlinedButton.icon(
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text("عرض كل المنتجات"), // <<-- تعريب
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onPressed: () {
                  // استدعاء دالة إعادة التعيين في متحكم الفلتر
                  try {
                    final filterController =
                        Get.find<EnhancedCategoryFilterController>();
                    filterController.resetFilters();
                  } catch (e) {
                    debugPrint("خطأ في إعادة تعيين الفلاتر: $e");
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  // بناء بطاقة المنتج الفردي

  // بناء بطاقة المنتج الفردي (مع إضافة شريط الحالة والجودة)
  // --- بناء بطاقة المنتج الفردي ---
  Widget _buildItemCard(
    BuildContext context,
    ItemModel item,
    double wi,
    double hi,
    GetStreamBuildBoxOfItemController controller,
  ) {
    final theme = Theme.of(context); // الحصول على الثيم لاستخدامه
    final FavoriteController favoriteCtrl =
        Get.find<FavoriteController>(); // <-- مهم هنا

    // --- 1. تحضير نص الحالة والجودة واللون ---
    String conditionText = '';
    if (item.itemCondition == 'original') {
      conditionText = 'براند'; // تغيير من "أصلي" إلى "براند"
    } else if (item.itemCondition == 'commercial') {
      conditionText = 'تجاري';
    }
    // تحضير نص درجة الجودة "د.X"
    String qualityText =
        item.qualityGrade != null ? 'د.${item.qualityGrade}' : '';
    // دمج النصين بمسافة (بدون فاصل '|') فقط إذا كان كلاهما موجودًا
    String combinedStatusText = conditionText;
    if (conditionText.isNotEmpty && qualityText.isNotEmpty) {
      combinedStatusText += ' $qualityText'; // إضافة مسافة بينهما
    } else {
      // إذا كان الأول فارغًا، أضف الثاني مباشرةً (أو العكس)
      combinedStatusText += qualityText;
    }
    // الحصول على لون الخلفية المناسب للدرجة
    Color qualityColor = _getQualityColor(
      item.qualityGrade,
    ); // استدعاء الدالة المساعدة
    // -------------------------------------

    // --- 2. بناء البطاقة الرئيسية ---
    return Card(
      elevation: 2.5, // زيادة طفيفة للظل
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias, // ضروري لـ Stack والحواف الدائرية
      child: InkWell(
        onTap: () {
          debugPrint("Navigating to details for ${item.name} (ID: ${item.id})");
          // انتقل إلى شاشة التفاصيل
          Get.to(() => DetailsOfItemScreen(item: item));
        },
        // استدعاء قائمة السياق عند الضغط (لأسفل أو مطولاً) إذا كان المستخدم أدمن
        onTapDown: (details) {
          if (_isAdmin) {
            _showAdminContextMenu(context, details, item, controller);
          }
        },
        onLongPress: () {
          if (_isAdmin) {
            final center = Offset(wi / 2, hi / 2);
            _showAdminContextMenu(
              context,
              TapDownDetails(globalPosition: center),
              item,
              controller,
            );
          }
        },
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch, // لجعل العناصر الفرعية تملأ العرض
          children: [
            // --- 3. الجزء العلوي: الصورة مع الشريط ---
            SizedBox(
              height:
                  hi *
                  0.1656, // تحديد حجم ثابت للصورة (تقليل 8% من الحجم السابق)
              child: Stack(
                fit: StackFit.expand, // لجعل الصورة تملأ المساحة المتاحة
                children: [
                  // --- الصورة باستخدام Hero و CachedNetworkImage ---
                  // الصورة ستملأ المساحة المتاحة لها بفضل Positioned.fill ضمنياً
                  _buildItemImage(item, wi, hi), // بناء الصورة
                  // --- أيقونة الفيديو (إذا كان موجوداً) ---
                  if (item.videoUrl != null && item.videoUrl != 'noVideo')
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_circle_fill,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),

                  // --- شريط الحالة والجودة (يظهر فقط إذا كان هناك نص) ---
                  if (combinedStatusText
                      .trim()
                      .isNotEmpty) // تحقق أن النص غير فارغ بعد إزالة المسافات
                    Positioned(
                      top: 6, // المسافة من الحافة العلوية
                      right: 6, // المسافة من الحافة اليمنى
                      child: IgnorePointer(
                        // لمنع هذا الشريط من اعتراض نقرات المستخدم على البطاقة
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ), // تباعد داخلي حول النص
                          decoration: BoxDecoration(
                            color: qualityColor.withOpacity(
                              0.9,
                            ), // اللون المحسوب مع شفافية طفيفة
                            borderRadius: BorderRadius.circular(
                              6,
                            ), // حواف دائرية
                            // إضافة حدود خفيفة إذا أردت (اختياري)
                            // border: Border.all(color: Colors.white.withOpacity(0.5), width: 0.5),
                            boxShadow: [
                              // ظل خفيف لتحسين الوضوح (اختياري)
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            combinedStatusText, // النص النهائي ("أصلي د.1", "تجاري", "د.8", إلخ.)
                            style: TextStyle(
                              color: Colors.white, // لون نص أبيض
                              fontSize: wi * 0.027, // حجم خط صغير ومناسب
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow:
                                TextOverflow
                                    .ellipsis, // للتعامل مع النص الطويل جدًا (غير محتمل هنا)
                          ),
                        ),
                      ),
                    ),
                  // ------------------------------------
                  Positioned(
                    top:
                        combinedStatusText.trim().isNotEmpty
                            ? 35
                            : 6, // <--- ضبط الموقع بناءً على وجود الشريط
                    right: 6,
                    // استخدام StreamBuilder لمراقبة حالة المفضلة الحالية
                    child: StreamBuilder<bool>(
                      stream: favoriteCtrl.isFavoriteStream(
                        item.id,
                      ), // الاستماع للمنتج الحالي
                      builder: (context, favSnapshot) {
                        // التعامل مع حالات StreamBuilder (اختياري)
                        // if (favSnapshot.connectionState == ConnectionState.waiting) {
                        //   return SizedBox(width: 30, height: 30, child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 1.5)));
                        // }
                        // إذا كان هناك خطأ في الستريم (نادراً ما يحدث هنا)
                        // if (favSnapshot.hasError) {
                        //    return Icon(Icons.error_outline, color: Colors.red[200]);
                        // }
                        // الحالة الافتراضية أو عند عدم وجود بيانات أولية
                        final bool isFavorite =
                            favSnapshot.data ?? false; // افتراض أنه ليس مفضل

                        return Material(
                          // استخدام Material لـ InkWell/splash effect
                          color: Colors.black.withOpacity(
                            0.3,
                          ), // خلفية شبه شفافة
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              // استدعاء دالة تبديل المفضلة في المتحكم
                              favoriteCtrl.toggleFavorite(item.id, isFavorite);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(6.0), // تباعد داخلي
                              child: Icon(
                                // عرض أيقونة مملوءة أو فارغة بناءً على الحالة
                                isFavorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color:
                                    isFavorite
                                        ? Colors.redAccent
                                        : Colors.white, // ألوان مميزة
                                size: wi * 0.055, // حجم الأيقونة
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ), // نهاية Stack الصورة
            // --- 4. الجزء السفلي: الاسم والسعر والأزرار ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 8,
                  right: 8,
                  top: 8,
                  bottom: 4,
                ), // زيادة top padding من 6 إلى 8
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.center, // توسيط المحتوى
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween, // لتوزيع المساحة
                  children: [
                    // اسم المنتج - سطر واحد فقط مع تحسين الوضوح والتميز
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        item.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700, // زيادة من w600 إلى w700
                          fontSize:
                              wi *
                              0.027, // تقليل من 0.040 إلى 0.036 (تقليل 10%)
                          height: 1, // زيادة قليلة في تباعد الأسطر
                          color: theme.textTheme.titleMedium?.color
                              ?.withOpacity(0.9),
                          letterSpacing: 0.3, // إضافة تباعد بين الحروف للوضوح
                        ),
                        maxLines: 1, // سطر واحد فقط كما طلب المستخدم
                        overflow:
                            TextOverflow.ellipsis, // إخفاء النص الزائد بـ ...
                        textAlign: TextAlign.center, // توسيط النص
                      ),
                    ),
                    // السعر وأزرار +/-
                    // التأكد من تمرير البيانات الصحيحة (price يجب أن يكون int)
                    BoxAddAndRemove(
                      uidItem: item.id,
                      price:
                          item.suggestedRetailPrice ??
                          item.price, // <-- استخدام السعر المقترح أولاً ثم السعر العادي
                      name: item.name, // <-- تمرير الاسم
                      isOffer: false,
                      uidAdd: item.uidAdd, // ليس عرضًا هنا
                    ),
                  ],
                ),
              ),
            ), // نهاية الجزء السفلي
          ],
        ),
      ),
    );
  }

  // --- (جديد) دالة لعرض مربع حوار التعديل (اسم أو سعر) ---
  void _showEditDialog(
    BuildContext context,
    GetStreamBuildBoxOfItemController controller,
    ItemModel item, {
    required bool isEditingName,
  }) {
    // تهيئة المتحكم النصي بالقيمة الحالية
    final editController = TextEditingController(
      text:
          isEditingName
              ? item.name
              : (item.suggestedRetailPrice ?? item.price).toString(),
    );
    final String title =
        isEditingName ? "تعديل اسم المنتج" : "تعديل سعر المنتج";
    final String label = isEditingName ? "الاسم الجديد" : "السعر الجديد";
    final TextInputType keyboardType =
        isEditingName
            ? TextInputType.text
            : TextInputType.numberWithOptions(
              decimal: false,
            ); // استخدام لوحة أرقام للسعر

    Get.defaultDialog(
      title: title,
      titlePadding: const EdgeInsets.only(top: 20, bottom: 10),
      titleStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      // استخدام Form للتحقق المحتمل
      content: Form(
        // يمكنك إضافة GlobalKey<FormState> هنا إذا احتجت للتحقق المعقد
        child: _buildEditTextField(
          editController,
          label,
          keyboardType,
        ), // استخدام الدالة لبناء حقل النص
      ),
      confirm: ElevatedButton(
        onPressed: () async {
          // تمرير القيمة الجديدة للمتحكم الذي يتولى التحديث في Firestore
          final controllerToUpdate =
              Get.find<
                GetStreamBuildBoxOfItemController
              >(); // العثور على المتحكم مجدداً للتأكد
          // قم بتحديث القيمة المحلية في المتحكم النصي المؤقت إذا أردت (ليس ضروريًا هنا)
          if (isEditingName) {
            controllerToUpdate.nameEditController.text =
                editController.text; // تحديث متحكم الاسم الرئيسي
            controllerToUpdate.isEditingName.value =
                true; // تحديد أننا نعدل الاسم
            controllerToUpdate.isEditingPrice.value = false;
          } else {
            controllerToUpdate.priceEditController.text =
                editController.text; // تحديث متحكم السعر الرئيسي
            controllerToUpdate.isEditingPrice.value =
                true; // تحديد أننا نعدل السعر
            controllerToUpdate.isEditingName.value = false;
          }
          Get.back(); // أغلق مربع الحوار الحالي
          await controllerToUpdate.confirmEdit(
            item.id,
          ); // استدعاء دالة التأكيد في المتحكم الرئيسي
        },
        child: const Text("حفظ"), // <<-- تعريب
      ),
      cancel: TextButton(
        onPressed: () {
          // مسح حالة التعديل إذا تم الإلغاء (اختياري)
          controller.cancelEditing();
          Get.back();
        },
        child: const Text("إلغاء"), // <<-- تعريب
      ),
      radius: 15.0,
    );
  }

  Widget _buildItemImage(ItemModel item, double wi, double hi) {
    // استخدام Hero لتأثير الانتقال السلس عند فتح التفاصيل
    return Hero(
      // Tag يجب أن يكون فريدًا لكل عنصر ويرتبط بنفس الـ Tag في شاشة التفاصيل
      tag: 'item_image_${item.id}',
      child: CachedNetworkImage(
        imageUrl: item.imageUrl ?? '', // استخدام رابط فارغ آمن
        placeholder: (context, url) => Container(color: Colors.grey[200]),
        errorWidget:
            (context, url, error) => Container(
              color: Colors.grey[100],
              child: const Icon(Icons.broken_image_outlined),
            ),
        fit: BoxFit.cover, // تغطية المساحة
      ),
    );
  }

  // دالة لتنسيق السعر مع فاصلة للآلاف وإزالة الأصفار غير الضرورية
  String formatPrice(double price) {
    String priceString;
    if (price == price.toInt()) {
      priceString = price.toInt().toString();
    } else {
      priceString = price.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
    }

    // إضافة فاصلة للآلاف
    final parts = priceString.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? '.${parts[1]}' : '';

    // إضافة فاصلة كل ثلاث خانات من اليمين
    String formattedInteger = '';
    for (int i = integerPart.length - 1; i >= 0; i--) {
      formattedInteger = integerPart[i] + formattedInteger;
      if ((integerPart.length - i) % 3 == 0 && i != 0) {
        formattedInteger = ',$formattedInteger';
      }
    }

    return formattedInteger + decimalPart;
  }
}
