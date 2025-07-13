import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../XXX/xxx_firebase.dart';
import '../../../TextFormFiled.dart';
import '../../../categories/controllers/categories_management_controller.dart';
import '../../Chose-The-Type-Of-Itemxx.dart';
import '../../video/chooseVideo.dart';
import '../../widgets/enhanced_barcode_input_field.dart';
import '../../widgets/enhanced_category_selector.dart';
import '../../widgets/main_barcode_input_field.dart';
import '../../widgets/original_product_selector.dart';
import 'addManyImage.dart';

class ClassOfAddItem extends StatefulWidget {
  final Getinformationofitem1 controller;

  const ClassOfAddItem({
    super.key,
    required this.controller,
  });

  @override
  State<ClassOfAddItem> createState() => _ClassOfAddItemState();
}

class _ClassOfAddItemState extends State<ClassOfAddItem> {
  // متغيرات لحفظ مرجع الـ listeners
  late VoidCallback _costPriceListener;
  late VoidCallback _sellingPriceListener;
  
  @override
  void initState() {
    super.initState();
    // تحميل الأقسام عند بدء التطبيق
    final categoriesController = Get.put(CategoriesManagementController());
    categoriesController.loadCategories();
    
    // إضافة listeners للتحقق من الأسعار عند التغيير
    _setupPriceValidationListeners();
  }
  
    /// دالة لإعداد listeners للتحقق من صحة الأسعار
  void _setupPriceValidationListeners() {
    // listener لسعر التكلفة
    _costPriceListener = () {
      // إعادة التحقق من سعر البيع عند تغيير سعر التكلفة
      if (widget.controller.priceOfItem.text.isNotEmpty) {
        // تحديث الـ form للتحقق من الـ validation
        setState(() {});
      }
    };
    widget.controller.costPriceOfItem.addListener(_costPriceListener);
    
    // listener لسعر البيع
    _sellingPriceListener = () {
      // إعادة التحقق من سعر التكلفة والسعر المقترح عند تغيير سعر البيع
      if (widget.controller.costPriceOfItem.text.isNotEmpty || 
          widget.controller.suggestedRetailPrice.text.isNotEmpty) {
        // تحديث الـ form للتحقق من الـ validation
        setState(() {});
      }
    };
    widget.controller.priceOfItem.addListener(_sellingPriceListener);
   }
   
  @override
  void dispose() {
    // إزالة الـ listeners عند إغلاق الصفحة
    widget.controller.costPriceOfItem.removeListener(_costPriceListener);
    widget.controller.priceOfItem.removeListener(_sellingPriceListener);
    super.dispose();
  }

  /// دالة للبحث الذكي عن مفتاح البلد المطابق
  String? _findMatchingCountryKey(String countryName) {
    // إزالة المسافات الزائدة وتحويل النص للأحرف الصغيرة للمقارنة
    String normalizedInput = countryName.trim().toLowerCase();
    
    // البحث المباشر أولاً (بالمفتاح)
    if (Getinformationofitem1.countryOfOriginOptions.containsKey(countryName)) {
      debugPrint("✅ تطابق مباشر بالمفتاح: $countryName");
      return countryName;
    }
    
    // البحث بالقيمة (الاسم العربي)
    for (var entry in Getinformationofitem1.countryOfOriginOptions.entries) {
      if (entry.value['ar']!.toLowerCase() == normalizedInput) {
        debugPrint("✅ تطابق مباشر بالاسم العربي: ${entry.value['ar']} -> ${entry.key}");
        return entry.key;
      }
    }
    
    // البحث الجزئي (يحتوي على النص)
    for (var entry in Getinformationofitem1.countryOfOriginOptions.entries) {
      String normalizedValue = entry.value['ar']!.toLowerCase();
      if (normalizedValue.contains(normalizedInput) || normalizedInput.contains(normalizedValue)) {
        debugPrint("✅ تطابق جزئي: '$countryName' مع '${entry.value['ar']}' -> ${entry.key}");
        return entry.key;
      }
    }
    
    // البحث بالتشابه (إزالة الحروف الإضافية مثل الألف والتاء المربوطة)
    String simplifiedInput = _simplifyArabicText(normalizedInput);
    for (var entry in Getinformationofitem1.countryOfOriginOptions.entries) {
      String simplifiedValue = _simplifyArabicText(entry.value['ar']!.toLowerCase());
      if (simplifiedValue == simplifiedInput) {
        debugPrint("✅ تطابق مبسط: '$countryName' -> '${entry.value['ar']}' -> ${entry.key}");
        return entry.key;
      }
    }
    
    // خريطة البدائل الشائعة
    Map<String, String> commonAlternatives = {
      'افغانستان': 'أفغانستان',
      'امريكا': 'الولايات المتحدة',
      'المانيا': 'ألمانيا',
      'انجلترا': 'المملكة المتحدة',
      'بريطانيا': 'المملكة المتحدة',
      'فرنسا': 'فرنسا',
      'ايطاليا': 'إيطاليا',
      'اسبانيا': 'إسبانيا',
      'هولندا': 'هولندا',
      'بلجيكا': 'بلجيكا',
      'سويسرا': 'سويسرا',
      'النمسا': 'النمسا',
      'السويد': 'السويد',
      'النرويج': 'النرويج',
      'الدنمارك': 'الدنمارك',
      'فنلندا': 'فنلندا',
      'روسيا': 'روسيا',
      'اوكرانيا': 'أوكرانيا',
      'بولندا': 'بولندا',
      'التشيك': 'جمهورية التشيك',
      'المجر': 'هنغاريا',
      'رومانيا': 'رومانيا',
      'بلغاريا': 'بلغاريا',
      'اليونان': 'اليونان',
      'تركيا': 'تركيا',
      'قبرص': 'قبرص',
      'مالطا': 'مالطا',
      'البرتغال': 'البرتغال',
      'ايرلندا': 'أيرلندا',
      'ايسلندا': 'أيسلندا',
      'كندا': 'كندا',
      'المكسيك': 'المكسيك',
      'البرازيل': 'البرازيل',
      'الارجنتين': 'الأرجنتين',
      'تشيلي': 'تشيلي',
      'كولومبيا': 'كولومبيا',
      'بيرو': 'بيرو',
      'فنزويلا': 'فنزويلا',
      'الاكوادور': 'الإكوادور',
      'بوليفيا': 'بوليفيا',
      'باراجواي': 'باراغواي',
      'اوروجواي': 'أوروغواي',
      'الصين': 'الصين',
      'اليابان': 'اليابان',
      'كوريا الجنوبية': 'كوريا الجنوبية',
      'كوريا الشمالية': 'كوريا الشمالية',
      'الهند': 'الهند',
      'باكستان': 'باكستان',
      'بنجلاديش': 'بنغلاديش',
      'سريلانكا': 'سريلانكا',
      'نيبال': 'نيبال',
      'بوتان': 'بوتان',
      'ميانمار': 'ميانمار',
      'تايلاند': 'تايلاند',
      'فيتنام': 'فيتنام',
      'كمبوديا': 'كمبوديا',
      'لاوس': 'لاوس',
      'ماليزيا': 'ماليزيا',
      'سنغافورة': 'سنغافورة',
      'اندونيسيا': 'إندونيسيا',
      'الفلبين': 'الفلبين',
      'بروناي': 'بروناي',
      'استراليا': 'أستراليا',
      'نيوزيلندا': 'نيوزيلندا',
      'مصر': 'مصر',
      'ليبيا': 'ليبيا',
      'تونس': 'تونس',
      'الجزائر': 'الجزائر',
      'المغرب': 'المغرب',
      'السودان': 'السودان',
      'اثيوبيا': 'إثيوبيا',
      'كينيا': 'كينيا',
      'تنزانيا': 'تنزانيا',
      'اوغندا': 'أوغندا',
      'رواندا': 'رواندا',
      'بوروندي': 'بوروندي',
      'جنوب افريقيا': 'جنوب أفريقيا',
      'نيجيريا': 'نيجيريا',
      'غانا': 'غانا',
      'ساحل العاج': 'ساحل العاج',
      'السنغال': 'السنغال',
      'مالي': 'مالي',
      'بوركينا فاسو': 'بوركينا فاسو',
      'النيجر': 'النيجر',
      'تشاد': 'تشاد',
      'الكاميرون': 'الكاميرون',
      'جمهورية افريقيا الوسطى': 'جمهورية أفريقيا الوسطى',
      'الكونغو': 'الكونغو',
      'جمهورية الكونغو الديمقراطية': 'جمهورية الكونغو الديمقراطية',
      'الغابون': 'الغابون',
      'غينيا الاستوائية': 'غينيا الاستوائية',
      'ساو تومي وبرينسيبي': 'ساو تومي وبرينسيبي',
      'انغولا': 'أنغولا',
      'زامبيا': 'زامبيا',
      'زيمبابوي': 'زيمبابوي',
      'بوتسوانا': 'بوتسوانا',
      'ناميبيا': 'ناميبيا',
      'ليسوتو': 'ليسوتو',
      'اسواتيني': 'إسواتيني',
      'موزمبيق': 'موزمبيق',
      'مدغشقر': 'مدغشقر',
      'موريشيوس': 'موريشيوس',
      'سيشل': 'سيشل',
      'جزر القمر': 'جزر القمر',
      'جيبوتي': 'جيبوتي',
      'اريتريا': 'إريتريا',
      'الصومال': 'الصومال',
      'السعودية': 'السعودية',
      'الامارات': 'الإمارات العربية المتحدة',
      'الكويت': 'الكويت',
      'قطر': 'قطر',
      'البحرين': 'البحرين',
      'عمان': 'عُمان',
      'اليمن': 'اليمن',
      'العراق': 'العراق',
      'سوريا': 'سوريا',
      'لبنان': 'لبنان',
      'الاردن': 'الأردن',
      'فلسطين': 'فلسطين',
      'اسرائيل': 'إسرائيل',
      'ايران': 'إيران',
      'ارمينيا': 'أرمينيا',
      'اذربيجان': 'أذربيجان',
      'جورجيا': 'جورجيا',
      'كازاخستان': 'كازاخستان',
      'قيرغيزستان': 'قيرغيزستان',
      'طاجيكستان': 'طاجيكستان',
      'تركمانستان': 'تركمانستان',
      'اوزبكستان': 'أوزبكستان',
      'منغوليا': 'منغوليا',
    };
    
    // البحث في البدائل الشائعة
    String lowerInput = normalizedInput;
    if (commonAlternatives.containsKey(lowerInput)) {
      String alternative = commonAlternatives[lowerInput]!;
      for (var entry in Getinformationofitem1.countryOfOriginOptions.entries) {
        if (entry.value['ar']!.toLowerCase() == alternative.toLowerCase()) {
          debugPrint("✅ تطابق عبر البدائل: '$countryName' -> '$alternative' -> ${entry.key}");
          return entry.key;
        }
      }
    }
    
    debugPrint("❌ لم يتم العثور على تطابق لـ: '$countryName'");
    return null;
  }

  /// دالة لتبسيط النص العربي (إزالة الحروف الإضافية)
  String _simplifyArabicText(String text) {
    return text
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll('ء', '')
        .replaceAll(' ', '');
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<Getinformationofitem1>(
      init: widget.controller,
      builder: (logic) {
        final double hi = MediaQuery.of(context).size.height;
        final double wi = MediaQuery.of(context).size.width;

        // تأكد من إعادة تعيين chosenItem إذا كانت هذه أول مرة يتم بناء الويدجت فيها
        // أو يمكنك فعل ذلك في onInit الخاص بـ Controller إذا كان أنسب
        // chosenItem = null; // قم بإلغاء التعليق إذا احتجت مسحه هنا

        return Scaffold(
          resizeToAvoidBottomInset: true,
          body: SingleChildScrollView(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20), // إضافة padding سفلي
            child: Form(
              key: logic.globalKey, // استخدام المفتاح من الـ Controller
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: wi / 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: hi * 0.02),
                    Obx(() {
                      String sellerTypeDisplay = "غير محدد";
                      Color displayColor = Colors.deepPurple;
                      IconData displayIcon = Icons.person;
                      
                      switch (logic.sellerTypeAssociatedWithProduct.value) {
                        case 'wholesale':
                          sellerTypeDisplay = "بائع جملة";
                          displayColor = Colors.green;
                          displayIcon = Icons.store;
                          break;
                        case 'retail':
                          sellerTypeDisplay = 'بائع مفرد';
                          displayColor = Colors.blue;
                          displayIcon = Icons.shopping_bag;
                          break;
                        case 'loading':
                          sellerTypeDisplay = "جاري تحديد نوع البائع...";
                          displayColor = Colors.orange;
                          displayIcon = Icons.sync;
                          break;
                        case 'anonymous':
                          sellerTypeDisplay = "مستخدم غير مسجل";
                          displayColor = Colors.grey;
                          displayIcon = Icons.person_outline;
                          break;
                        case 'unknown':
                        default:
                          sellerTypeDisplay = "بائع تجزئة (افتراضي)";
                          displayColor = Colors.blue;
                          displayIcon = Icons.shopping_bag;
                          break;
                      }
                      
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                        margin: const EdgeInsets.only(bottom: 10.0, top: 5.0),
                        decoration: BoxDecoration(
                          color: displayColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: displayColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              displayIcon,
                              color: displayColor,
                              size: wi / 20,
                            ),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                "إضافة المنتج كـ: $sellerTypeDisplay",
                                style: TextStyle(
                                  fontSize: wi / 26, 
                                  fontWeight: FontWeight.w600, 
                                  color: displayColor
                                ),
                              ),
                            ),
                            // إضافة زر إعادة التحديث إذا كان نوع البائع غير محدد
                            if (logic.sellerTypeAssociatedWithProduct.value == 'unknown' || 
                                logic.sellerTypeAssociatedWithProduct.value == 'retail')
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: GestureDetector(
                                  onTap: () async {
                                    await logic.refreshSellerType();
                                  },
                                  child: Icon(
                                    Icons.refresh,
                                    color: displayColor,
                                    size: wi / 25,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                    SizedBox(height: hi * 0.01),
                    _buildTextFormField(
                      controller: logic.nameOfItem, // استخدام Controller مُمرر
                      label: "اسم المنتج",
                      validator: (val) => val == null || val.isEmpty ? "يجب إدخال اسم المنتج" : null,
                      keyboardType: TextInputType.text,
                    ),
                    SizedBox(height: hi * 0.02),
                    _buildTextFormField(
                      controller: logic.descriptionOfItem, // استخدام Controller مُمرر
                      label: "وصف المنتج",
                      validator: (val) => val == null || val.isEmpty ? "يجب إدخال وصف المنتج" : null,
                      keyboardType: TextInputType.multiline,
                      maxLines: 3,
                    ),
                    SizedBox(height: hi * 0.02),

                    _buildTextFormField(
                      controller: logic.productQuantity,
                      label: "كمية المنتج",
                      validator: (val) {
                        if (val == null || val.isEmpty) return "يجب إدخال كمية المنتج";
                        final quantity = int.tryParse(val);
                        if (quantity == null) return "أدخل كمية صحيحة (أرقام فقط)";
                        if (quantity <= 0) return "الكمية يجب أن تكون أكبر من صفر";
                        if (quantity > 100000) return "الكمية كبيرة جداً";
                        return null;
                      },
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: hi * 0.02),
                    
                    // حقل كمية المنتج في الكارتونة - يظهر فقط للبائع الجملة
                    Obx(() {
                      if (logic.sellerTypeAssociatedWithProduct.value == 'wholesale') {
                        return Column(
                          children: [
                            _buildTextFormField(
                              controller: logic.quantityPerCarton,
                              label: "كمية المنتج في الكارتونة الواحدة",
                              validator: (val) {
                                if (val == null || val.isEmpty) return "يجب إدخال كمية المنتج في الكارتونة";
                                final quantity = int.tryParse(val);
                                if (quantity == null) return "أدخل كمية صحيحة (أرقام فقط)";
                                if (quantity <= 0) return "الكمية يجب أن تكون أكبر من صفر";
                                if (quantity > 1000) return "الكمية في الكارتونة كبيرة جداً";
                                return null;
                              },
                              keyboardType: TextInputType.number,
                            ),
                            SizedBox(height: hi * 0.02),
                            // إضافة نص توضيحي
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "هذه المعلومة ستساعد البائع المفرد في طلب كارتونة كاملة مباشرة",
                                      style: TextStyle(
                                        color: Colors.blue.shade700,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: hi * 0.02),
                          ],
                        );
                      } else {
                        return SizedBox.shrink(); // لا يظهر شيء للبائع المفرد
                      }
                    }),
                    
                                         // حقل الباركود المحسن مع إمكانية المسح المتقدم
                     EnhancedBarcodeInputField(
                       controller: logic.productBarcode,
                       label: "باركود الرقم التسلسلي لكل منتج (اختياري)",
                       logic: logic,
                       validator: (val) {
                         if (val == null || val.isEmpty) return null; // اختياري
                         if (val.length < 6) return "الباركود قصير جداً";
                         if (val.length > 50) return "الباركود طويل جداً";
                         return null;
                       },
                       onBarcodeScanned: () {
                         // يمكن إضافة أي إجراءات إضافية هنا
                         debugPrint("تم مسح الباركود: ${logic.productBarcode.text}");
                         debugPrint("عدد الباركودات المسحوبة: ${logic.productBarcodes.length}");
                       },
                     ),
                    SizedBox(height: hi * 0.02),
                    
                    // الباركود الرئيسي للمنتج
                    MainBarcodeInputField(
                      controller: logic.mainProductBarcode,
                      label: "الباركود الرئيسي للمنتج (اختياري)",
                      logic: logic,
                      validator: (val) {
                        // الباركود الرئيسي اختياري - سيتم إنشاؤه تلقائياً إذا كان فارغاً
                        if (val == null || val.isEmpty) return null; // اختياري
                        if (val.length < 6) return "الباركود قصير جداً";
                        if (val.length > 50) return "الباركود طويل جداً";
                        return null;
                      },
                      onBarcodeScanned: () {
                        debugPrint("تم مسح الباركود الرئيسي: ${logic.mainProductBarcode.text}");
                      },
                    ),
                    SizedBox(height: hi * 0.02),
                    
                    _buildTextFormField(
                      controller: logic.costPriceOfItem,
                      label: "سعر تكلفة المنتج",
                      validator: (val) {
                        if (val == null || val.isEmpty) return "يجب إدخال سعر التكلفة";
                        if (double.tryParse(val) == null) return "أدخل سعراً صحيحاً (أرقام)";
                        if (double.parse(val) <= 0) return "السعر يجب أن يكون أكبر من صفر";
                        
                        // التحقق من أن سعر التكلفة ليس أكبر من سعر البيع
                        final sellingPriceText = logic.priceOfItem.text;
                        if (sellingPriceText.isNotEmpty) {
                          final sellingPrice = double.tryParse(sellingPriceText);
                          final costPrice = double.parse(val);
                          if (sellingPrice != null && costPrice > sellingPrice) {
                            return "سعر التكلفة لا يمكن أن يكون أكبر من سعر البيع (${sellingPrice.toStringAsFixed(2)})";
                          }
                        }
                        
                        return null;
                      },
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                    SizedBox(height: hi * 0.02),
                    _buildTextFormField(
                      controller: logic.priceOfItem,
                      label: "سعر البيع للمنتج",
                      validator: (val) {
                        if (val == null || val.isEmpty) return "يجب إدخال سعر البيع";
                        if (double.tryParse(val) == null) return "أدخل سعراً صحيحاً (أرقام)";
                        if (double.parse(val) <= 0) return "السعر يجب أن يكون أكبر من صفر";
                        
                        // التحقق من أن سعر البيع ليس أقل من سعر التكلفة
                        final costPriceText = logic.costPriceOfItem.text;
                        if (costPriceText.isNotEmpty) {
                          final costPrice = double.tryParse(costPriceText);
                          final sellingPrice = double.parse(val);
                          if (costPrice != null && sellingPrice < costPrice) {
                            return "سعر البيع لا يمكن أن يكون أقل من سعر التكلفة (${costPrice.toStringAsFixed(2)})";
                          }
                        }
                        
                        return null;
                      },
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                    SizedBox(height: hi * 0.02),
                    
                    // حقل السعر المقترح للبائع المفرد - يظهر فقط للبائع الجملة
                    Obx(() {
                      if (logic.sellerTypeAssociatedWithProduct.value == 'wholesale') {
                        return Column(
                          children: [
                            _buildTextFormField(
                              controller: logic.suggestedRetailPrice,
                              label: "السعر المقترح للبائع المفرد",
                              validator: (val) {
                                if (val == null || val.isEmpty) return "يجب إدخال السعر المقترح للبائع المفرد";
                                final suggestedPrice = double.tryParse(val);
                                if (suggestedPrice == null) return "أدخل سعراً صحيحاً (أرقام)";
                                if (suggestedPrice <= 0) return "السعر يجب أن يكون أكبر من صفر";
                                
                                // التحقق من أن السعر المقترح أكبر من سعر البيع للجملة
                                final wholesalePriceText = logic.priceOfItem.text;
                                if (wholesalePriceText.isNotEmpty) {
                                  final wholesalePrice = double.tryParse(wholesalePriceText);
                                  if (wholesalePrice != null && suggestedPrice <= wholesalePrice) {
                                    return "السعر المقترح للمفرد يجب أن يكون أكبر من سعر الجملة (${wholesalePrice.toStringAsFixed(2)})";
                                  }
                                }
                                
                                return null;
                              },
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                            ),
                            SizedBox(height: hi * 0.01),
                            // إضافة نص توضيحي
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.amber.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.price_check, color: Colors.amber.shade700, size: 20),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "هذا السعر سيساعد البائع المفرد في تحديد سعر البيع المناسب مع ضمان هامش ربح مناسب",
                                      style: TextStyle(
                                        color: Colors.amber.shade800,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: hi * 0.02),
                          ],
                        );
                      } else {
                        return SizedBox.shrink(); // لا يظهر شيء للبائع المفرد
                      }
                    }),
                    
                    // عرض تحذير هامش الربح
                    _buildProfitMarginWarning(logic),

                    if (logic.TypeItem == FirebaseX.offersCollection)
                      Column(
                        children: [
                          _buildTextFormField(
                            controller: logic.oldPrice,
                            label: "السعر القديم (للعرض)",
                            validator: (val) {
                              if (val == null || val.isEmpty) return "يجب إدخال السعر القديم";
                              if (double.tryParse(val) == null) return "أدخل سعراً صحيحاً";
                              if (double.parse(val) <= 0) return "السعر القديم يجب أن يكون أكبر من صفر";
                              return null;
                            },
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                          ),
                          SizedBox(height: hi * 0.02),
                          _buildTextFormField(
                            controller: logic.rate,
                            label: "نسبة الخصم % (للعرض)",
                            validator: (val) {
                              if (val == null || val.isEmpty) return "يجب إدخال نسبة الخصم";
                              if (int.tryParse(val) == null) return "أدخل نسبة صحيحة";
                              final rate = int.parse(val);
                              if (rate <= 0 || rate >= 100) return "النسبة بين 1 و 99";
                              return null;
                            },
                            keyboardType: TextInputType.number,
                          ),
                          SizedBox(height: hi * 0.02),
                        ],
                      ),
                    // حالة المنتج والمنتج الأصلي (للمنتجات العادية فقط)
                    if (logic.TypeItem == FirebaseX.itemsCollection)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildConditionDropdown(logic, hi, wi, context),
                    SizedBox(height: hi * 0.02),

                          // اختيار المنتج الأصلي (يظهر مباشرة بعد اختيار حالة "أصلي")
                          Obx(() {
                            if (logic.selectedItemConditionKey.value == 'original') {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel("تحديد المنتج الأصلي (مطلوب)"),
                                  SizedBox(height: 8),
                                  OriginalProductSelector(
                                    onSelectionChanged: (company, product, mainCategoryId, subCategoryId) {
                                      debugPrint("🎯 تم استدعاء onSelectionChanged:");
                                      debugPrint("   الشركة: ${company?.nameAr ?? 'null'}");
                                      debugPrint("   المنتج: ${product?.nameAr ?? 'null'}");
                                      
                                      // حفظ معلومات المنتج الأصلي في الكنترولر
                                      logic.originalCompanyId.value = company?.id ?? '';
                                      logic.originalProductId.value = product?.id ?? '';
                                      logic.originalCompanyName.value = company?.nameAr ?? '';
                                      logic.originalProductName.value = product?.nameAr ?? '';
                                      
                                      // تحديث بلد المنشأ تلقائياً من معلومات الشركة المصنعة
                                      debugPrint("🔍 فحص معلومات الشركة للتحديد التلقائي لبلد المنشأ:");
                                      debugPrint("   الشركة: ${company?.nameAr ?? 'null'}");
                                      debugPrint("   بلد الشركة: '${company?.country ?? 'null'}'");
                                      debugPrint("   البلدان المتاحة: ${Getinformationofitem1.countryOfOriginOptions.keys.toList()}");
                                      
                                      if (company != null && company.country != null && company.country!.isNotEmpty) {
                                        String? matchedCountryKey = _findMatchingCountryKey(company.country!);
                                        
                                        if (matchedCountryKey != null) {
                                          logic.updateCountryOfOrigin(matchedCountryKey, isAutoSelected: true);
                                          debugPrint("✅ تم تحديد بلد المنشأ تلقائياً: $matchedCountryKey (${Getinformationofitem1.countryOfOriginOptions[matchedCountryKey]!['ar']})");
                                        } else {
                                          debugPrint("⚠️ بلد الشركة '${company.country}' غير موجود في قائمة البلدان المتاحة");
                                          debugPrint("   البلدان المتاحة: ${Getinformationofitem1.countryOfOriginOptions.values.map((v) => v['ar']).join(', ')}");
                                          
                                          // إشعار المستخدم أن بلد الشركة غير متاح
                                          Get.snackbar(
                                            'تنبيه',
                                            'بلد الشركة "${company.country}" غير متاح في قائمة البلدان. يرجى اختيار بلد المنشأ يدوياً.',
                                            snackPosition: SnackPosition.BOTTOM,
                                            backgroundColor: Colors.orange,
                                            colorText: Colors.white,
                                            duration: Duration(seconds: 4),
                                            icon: Icon(Icons.warning, color: Colors.white),
                                          );
                                        }
                                      } else if (company == null) {
                                        // إذا تم إلغاء اختيار الشركة (منتج غير أصلي)، قم بمسح بلد المنشأ
                                        logic.updateCountryOfOrigin(null, isAutoSelected: false);
                                        debugPrint("🔄 تم مسح بلد المنشأ بعد إلغاء اختيار الشركة");
                                      } else {
                                        debugPrint("⚠️ لا توجد معلومات بلد للشركة المختارة");
                                        debugPrint("   company.country != null: ${company.country != null}");
                                        debugPrint("   company.country.isNotEmpty: ${company.country?.isNotEmpty ?? false}");
                                      }
                                      
                                      // تحديث الأقسام المختارة
                                      logic.selectedMainCategoryId.value = mainCategoryId ?? '';
                                      logic.selectedSubCategoryId.value = subCategoryId ?? '';
                                      
                                      // استخدام أسماء الأقسام من المنتج الأصلي مباشرة (أكثر دقة)
                                      if (product != null) {
                                        // استخدام الأسماء من المنتج الأصلي مباشرة
                                        logic.selectedMainCategoryNameEn.value = product.mainCategoryNameEn ?? 'undefined';
                                        logic.selectedMainCategoryNameAr.value = product.mainCategoryNameAr ?? 'غير محدد';
                                        logic.selectedSubCategoryNameEn.value = product.subCategoryNameEn ?? 'undefined';
                                        logic.selectedSubCategoryNameAr.value = product.subCategoryNameAr ?? 'غير محدد';
                                        
                                        debugPrint("✅ تم استخدام أسماء الأقسام من المنتج الأصلي:");
                                        debugPrint("   Main: AR='${logic.selectedMainCategoryNameAr.value}', EN='${logic.selectedMainCategoryNameEn.value}'");
                                        debugPrint("   Sub: AR='${logic.selectedSubCategoryNameAr.value}', EN='${logic.selectedSubCategoryNameEn.value}'");
                                      } else {
                                        // كبديل: جلب أسماء الأقسام من CategoriesManagementController
                                        final categoriesController = Get.find<CategoriesManagementController>();
                                        final mainCategory = mainCategoryId != null && mainCategoryId.isNotEmpty
                                            ? categoriesController.getCategoryById(mainCategoryId)
                                            : null;
                                        final subCategory = subCategoryId != null && subCategoryId.isNotEmpty
                                            ? categoriesController.getCategoryById(subCategoryId)
                                            : null;
                                        
                                        logic.selectedMainCategoryNameEn.value = mainCategory?.nameEn ?? 'undefined';
                                        logic.selectedMainCategoryNameAr.value = mainCategory?.nameAr ?? 'غير محدد';
                                        logic.selectedSubCategoryNameEn.value = subCategory?.nameEn ?? 'undefined';
                                        logic.selectedSubCategoryNameAr.value = subCategory?.nameAr ?? 'غير محدد';
                                        
                                        debugPrint("⚠️ تم استخدام أسماء الأقسام من CategoriesManagementController كبديل");
                                      }
                                      
                                      // تحديث القسم المختار للحفظ - استخدام القسم الفرعي إذا كان موجود، وإلا القسم الرئيسي
                                      String finalMainEn = logic.selectedMainCategoryNameEn.value;
                                      String finalSubEn = logic.selectedSubCategoryNameEn.value;
                                      
                                      if (finalSubEn.isNotEmpty && finalSubEn != 'undefined') {
                                        // إذا كان هناك قسم فرعي، استخدم تنسيق "الرئيسي_الفرعي"
                                        logic.selectedCategoryNameEn.value = '${finalMainEn}_$finalSubEn';
                                      } else if (finalMainEn.isNotEmpty && finalMainEn != 'undefined') {
                                        // إذا كان القسم الرئيسي فقط
                                        logic.selectedCategoryNameEn.value = finalMainEn;
                                      }
                                      
                                      debugPrint("🎯 ملخص الأقسام النهائية:");
                                      debugPrint("📁 القسم الرئيسي: ID=${logic.selectedMainCategoryId.value}");
                                      debugPrint("   🇦🇪 AR: '${logic.selectedMainCategoryNameAr.value}'");
                                      debugPrint("   🇺🇸 EN: '${logic.selectedMainCategoryNameEn.value}'");
                                      debugPrint("📂 القسم الفرعي: ID=${logic.selectedSubCategoryId.value}");
                                      debugPrint("   🇦🇪 AR: '${logic.selectedSubCategoryNameAr.value}'");
                                      debugPrint("   🇺🇸 EN: '${logic.selectedSubCategoryNameEn.value}'");
                                      debugPrint("📋 القسم المختار للحفظ: '${logic.selectedCategoryNameEn.value}'");
                                      debugPrint("🔒 ضمان: لن تكون أي قيمة null عند الحفظ!");
                                      
                                      // تحديث درجات الجودة المتاحة بعد اختيار المنتج الأصلي
                                      logic.updateAvailableQualityGrades();
                                      
                                      logic.update();
                                    },
                                  ),
                                  // عرض الأقسام المختارة - مخفي للبائع لكن البيانات محفوظة
                                  // Obx(() {
                                  //   if (logic.originalProductId.value.isNotEmpty) {
                                  //     return Column(
                                  //       crossAxisAlignment: CrossAxisAlignment.start,
                                  //       children: [
                                  //         SizedBox(height: 10),
                                  //         _buildLabel("القسم الرئيسي"),
                                  //         Container(
                                  //           padding: EdgeInsets.all(12),
                                  //           decoration: BoxDecoration(
                                  //             border: Border.all(color: Colors.grey),
                                  //             borderRadius: BorderRadius.circular(8),
                                  //           ),
                                  //           child: Text(
                                  //             logic.selectedMainCategoryNameAr.value.isNotEmpty 
                                  //                 ? logic.selectedMainCategoryNameAr.value 
                                  //                 : "لم يتم تحديد قسم رئيسي",
                                  //             style: TextStyle(fontSize: 16),
                                  //           ),
                                  //         ),
                                  //         SizedBox(height: 10),
                                  //         _buildLabel("القسم الفرعي"),
                                  //         Container(
                                  //           padding: EdgeInsets.all(12),
                                  //           decoration: BoxDecoration(
                                  //             border: Border.all(color: Colors.grey),
                                  //             borderRadius: BorderRadius.circular(8),
                                  //           ),
                                  //           child: Text(
                                  //             logic.selectedSubCategoryNameAr.value.isNotEmpty 
                                  //                 ? logic.selectedSubCategoryNameAr.value 
                                  //                 : "لم يتم تحديد قسم فرعي",
                                  //             style: TextStyle(fontSize: 16),
                                  //           ),
                                  //         ),
                                  //       ],
                                  //     );
                                  //   }
                                  //   return SizedBox.shrink();
                                  // }),
                                ],
                              );
                            }
                            return SizedBox.shrink();
                          }),
                        ],
                      ),
                    
                    // قسم المنتج (يظهر فقط إذا كان المنتج ليس أصلي أو إذا لم يتم اختيار منتج أصلي)
                    Obx(() {
                      // إخفاء اختيار الأقسام إذا كان المنتج أصلي وتم اختيار منتج أصلي
                      if (logic.selectedItemConditionKey.value == 'original' && 
                          logic.originalProductId.value.isNotEmpty) {
                        // إخفاء النص التوضيحي - البيانات محفوظة في الخلفية
                        return SizedBox.shrink();
                      }
                      
                      // إظهار اختيار الأقسام العادي
                      return Column(
                        children: [
                          _buildEnhancedCategorySelector(logic),
                          SizedBox(height: hi * 0.02),
                        ],
                      );
                    }),

                    // باقي خصائص المنتج (للمنتجات العادية فقط)
                    if (logic.TypeItem == FirebaseX.itemsCollection)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          _buildQualityDropdown(logic, hi, wi, context),
                    SizedBox(height: hi * 0.02),
                          _buildCountryDropdown(logic, hi, wi, context),
                    SizedBox(height: hi * 0.02),
                        ],
                      ),
                    _buildLabel("فيديو المنتج (اختياري)"),
                    const ChooseVideo(),
                    SizedBox(height: hi / 25),
                    _buildLabel("صور إضافية (اختياري)"),
                    AddManyImage(),
                    SizedBox(height: hi / 30),
                    _buildActionButtons(context, logic, hi, wi), // تمرير الـ Controller الأصلي
                    SizedBox(height: hi / 30),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, right: 4.0), // تباعد أسفل ويمين العنوان
      child: Align(
          alignment: Alignment.centerRight,
      child: Text( text, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14.5),
      ),
    )
    );
  }
  
  /// دالة لبناء تحذير هامش الربح
  Widget _buildProfitMarginWarning(Getinformationofitem1 logic) {
    final costPriceText = logic.costPriceOfItem.text;
    final sellingPriceText = logic.priceOfItem.text;
    
    if (costPriceText.isEmpty || sellingPriceText.isEmpty) {
      return SizedBox.shrink();
    }
    
    final costPrice = double.tryParse(costPriceText);
    final sellingPrice = double.tryParse(sellingPriceText);
    
    if (costPrice == null || sellingPrice == null) {
      return SizedBox.shrink();
    }
    
    if (sellingPrice <= costPrice) {
      return SizedBox.shrink(); // سيتم التعامل مع هذا في الـ validator
    }
    
    final profitMargin = ((sellingPrice - costPrice) / costPrice) * 100;
    
    if (profitMargin < 10) { // إذا كان هامش الربح أقل من 10%
      return Container(
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange[600], size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تحذير: هامش ربح منخفض',
                    style: TextStyle(
                      color: Colors.orange[800],
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'هامش الربح الحالي: ${profitMargin.toStringAsFixed(1)}%\nالربح: ${(sellingPrice - costPrice).toStringAsFixed(2)} ريال',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (profitMargin >= 10 && profitMargin < 20) {
      return Container(
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.info, color: Colors.blue[600], size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'هامش الربح: ${profitMargin.toStringAsFixed(1)}% | الربح: ${(sellingPrice - costPrice).toStringAsFixed(2)} ريال',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return SizedBox.shrink();
  }

  /// دالة لإنشاء حقول الإدخال (كما هي)
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    required TextInputType keyboardType,
    int? maxLines = 1,
  }) {
    return TextFormFiled( // تأكد من اسم الويدجت الصحيح
      controller: controller,
      borderRadius: 15,
      fontSize: 16,
      label: label,
      obscure: false,
      width: double.infinity,
      validator: validator,
      textInputType: keyboardType,
      maxLines: maxLines,
    );
  }

  // --- دالة بناء القائمة المنسدلة العامة (مُعدلة لتقبل isLoading) ---
  Widget _buildDropdownButton<T>({
    required BuildContext context,
    required T? currentValue,
    required String hintText,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    // ---!!! إضافة معامل isLoading الاختياري !!!---
    bool isLoading = false,
    // --------------------------------------------
  }) {
    return IgnorePointer( // تعطيل التفاعل عند التحميل
      ignoring: isLoading,
      child: Opacity( // جعلها باهتة عند التحميل
        opacity: isLoading ? 0.5 : 1.0,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          decoration: BoxDecoration(
            // --- تغيير اللون عند التحميل ---
            color: isLoading ? Colors.grey.shade200 : (Theme.of(context).inputDecorationTheme.fillColor ?? Colors.white),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: isLoading ? Colors.grey.shade300 : Colors.grey.shade400),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: isLoading ? null : currentValue, // مسح القيمة عند التحميل
              hint: Text(hintText, style: TextStyle(color: Colors.grey.shade600)),
              isExpanded: true,
              icon: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.arrow_drop_down, color: Colors.grey), // تغيير الأيقونة
              items: isLoading ? [] : items, // لا تعرض عناصر عند التحميل
              onChanged: isLoading ? null : onChanged, // تعطيل onChanged عند التحميل
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }

  // دالة بناء محدد الأقسام الجديد
  Widget _buildEnhancedCategorySelector(Getinformationofitem1 logic) {
    return Obx(() => EnhancedCategorySelector(
      label: logic.selectedItemConditionKey.value == 'commercial' 
          ? 'قسم المنتج (مطلوب)' 
          : 'قسم المنتج',
      initialMainCategoryId: logic.selectedMainCategoryId.value.isEmpty ? null : logic.selectedMainCategoryId.value,
      initialSubCategoryId: logic.selectedSubCategoryId.value.isEmpty ? null : logic.selectedSubCategoryId.value,
      onCategorySelected: (mainCategoryId, subCategoryId, mainCategoryNameEn, subCategoryNameEn) {
        // تحديث الكنترولر بمعلومات الأقسام المختارة
        logic.selectedMainCategoryId.value = mainCategoryId;
        logic.selectedSubCategoryId.value = subCategoryId;
        logic.selectedMainCategoryNameEn.value = mainCategoryNameEn;
        logic.selectedSubCategoryNameEn.value = subCategoryNameEn;
        
        // تحديث الأسماء العربية للأقسام أيضاً
        try {
          final categoriesController = Get.find<CategoriesManagementController>();
          final mainCategory = categoriesController.mainCategories.firstWhereOrNull((cat) => cat.id == mainCategoryId);
          if (mainCategory != null) {
            logic.selectedMainCategoryNameAr.value = mainCategory.nameAr;
            debugPrint("✅ تم تحديث اسم القسم الرئيسي العربي: '${mainCategory.nameAr}'");
            
            if (subCategoryId.isNotEmpty) {
              final subCategory = mainCategory.subCategories.firstWhereOrNull((sub) => sub.id == subCategoryId);
              if (subCategory != null) {
                logic.selectedSubCategoryNameAr.value = subCategory.nameAr;
                debugPrint("✅ تم تحديث اسم القسم الفرعي العربي: '${subCategory.nameAr}'");
              } else {
                logic.selectedSubCategoryNameAr.value = '';
                debugPrint("⚠️ لم يتم العثور على القسم الفرعي بالـ ID: $subCategoryId");
              }
            } else {
              logic.selectedSubCategoryNameAr.value = '';
              debugPrint("📝 لا يوجد قسم فرعي محدد");
            }
          } else {
            debugPrint("❌ لم يتم العثور على القسم الرئيسي بالـ ID: $mainCategoryId");
            logic.selectedMainCategoryNameAr.value = 'غير محدد';
            logic.selectedSubCategoryNameAr.value = 'غير محدد';
          }
        } catch (e) {
          debugPrint("❌ خطأ في تحديث الأسماء العربية للأقسام: $e");
          logic.selectedMainCategoryNameAr.value = 'غير محدد';
          logic.selectedSubCategoryNameAr.value = 'غير محدد';
        }
        
        // تحديث القسم المختار للحفظ - استخدام القسم الفرعي إذا كان موجود، وإلا القسم الرئيسي
        if (subCategoryId.isNotEmpty && subCategoryNameEn.isNotEmpty) {
          // إذا كان هناك قسم فرعي، استخدم تنسيق "الرئيسي_الفرعي"
          logic.selectedCategoryNameEn.value = '${mainCategoryNameEn}_$subCategoryNameEn';
        } else {
          // إذا كان القسم الرئيسي فقط
          logic.selectedCategoryNameEn.value = mainCategoryNameEn;
        }
        
        // طباعة معلومات التشخيص
        debugPrint("تم تحديث الأقسام:");
        debugPrint("القسم الرئيسي: ${logic.selectedMainCategoryId.value}");
        debugPrint("  العربي: '${logic.selectedMainCategoryNameAr.value}'");
        debugPrint("  الإنجليزي: '${logic.selectedMainCategoryNameEn.value}'");
        debugPrint("القسم الفرعي: ${logic.selectedSubCategoryId.value}");
        debugPrint("  العربي: '${logic.selectedSubCategoryNameAr.value}'");
        debugPrint("  الإنجليزي: '${logic.selectedSubCategoryNameEn.value}'");
        debugPrint("القسم المختار للحفظ: ${logic.selectedCategoryNameEn.value}");
        
        // تحديث درجات الجودة المتاحة بعد اختيار الأقسام
        logic.updateAvailableQualityGrades();
        
        // تحديث واجهة المستخدم
        logic.update();
      },
      isRequired: logic.selectedItemConditionKey.value == 'commercial',
    ));
  }



  // --- ▼▼▼ دالة بناء خاصة لنوع المنتج الفرعي (للعرض العربي والحفظ الإنجليزي) ▼▼▼ ---
  // Widget _buildProductSubtypeDropdownq(Getinformationofitem logic, double hi, double wi,BuildContext context) {
  //   return _buildDropdownButton<String>(
  //     context: context, // الحصول على context من GetX
  //     currentValue: ClassOfAddItem.chosenItem, // القيمة الحالية (الإنجليزية)
  //     hintText: "اختر نوع المنتج",
  //     // بناء العناصر: القيمة إنجليزية، العرض عربي
  //     items: logic.productSubtypeOptions.entries.map((entry) {
  //       return DropdownMenuItem<String>(
  //         value: entry.key, // القيمة الإنجليزية للحفظ
  //         child: Text(
  //           entry.value, // القيمة العربية للعرض
  //           style: TextStyle(fontSize: wi / 25),
  //         ),
  //       );
  //     }).toList(),
  //     // عند التغيير: حفظ القيمة الإنجليزية وتحديث الواجهة
  //     onChanged: (selectedValue) {
  //       // تحديث المتغير الثابت مباشرة
  //       ClassOfAddItem.chosenItem = selectedValue;
  //       // استدعاء update للـ controller لإعادة بناء هذا الجزء من الواجهة
  //       logic.update();
  //       debugPrint("Chosen Subtype (English): ${ClassOfAddItem.chosenItem}");
  //     },
  //   );
  // }
  // --- ▲▲▲ نهاية دالة بناء نوع المنتج الفرعي ▲▲▲ ---

  // --- ▼▼▼ دوال بناء القوائم المنسدلة الأخرى باستخدام الدالة العامة ▼▼▼ ---

  // --- تعديل دالة بناء قائمة حالة المنتج ---
  Widget _buildConditionDropdown(Getinformationofitem1 logic, double hi, double wi, BuildContext context) {
    return Obx(() => 
      _buildDropdownButton<String>(
        context: context,
        currentValue: logic.selectedItemConditionKey.value,
        items: Getinformationofitem1.itemConditionOptions.entries.map((entry) {
          return DropdownMenuItem<String>(
            value: entry.key,
            child: Text(entry.value),
          );
        }).toList(),
        hintText: "اختر حالة المنتج",
        onChanged: (value) {
          logic.updateItemCondition(value);
          debugPrint("تم تغيير حالة المنتج إلى: $value");
        },
      )
    );
  }

  // --- تعديل دالة بناء قائمة الجودة ---
  Widget _buildQualityDropdown(Getinformationofitem1 logic, double hi, double wi, BuildContext context) {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // عنوان مع أيقونة المساعدة
        Row(
          children: [
            Text(
              'درجة الجودة',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14.5,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showQualityGradeHelpDialog(context, logic),
              child: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue[300]!, width: 1),
                ),
                child: Icon(
                  Icons.help_outline,
                  color: Colors.blue[600],
                  size: 16,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 6),
        
        // القائمة المنسدلة
        _buildDropdownButton<int>(
          context: context,
          currentValue: logic.selectedQualityGrade.value,
          items: Getinformationofitem1.qualityGradeOptions.map((grade) {
          final bool isAvailable = logic.availableQualityGrades.contains(grade);
          final bool isUnavailable = logic.unavailableQualityGrades.contains(grade);
          
          return DropdownMenuItem<int>(
            value: grade,
            enabled: isAvailable,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isUnavailable 
                    ? Colors.red[100] // خلفية حمراء للدرجات غير المتاحة
                    : isAvailable 
                        ? Colors.green[100] // خلفية خضراء للدرجات المتاحة
                        : Colors.grey[100], // خلفية رمادية للدرجات العادية
                borderRadius: BorderRadius.circular(6),
                border: isUnavailable 
                    ? Border.all(color: Colors.red[300]!, width: 1)
                    : isAvailable 
                        ? Border.all(color: Colors.green[300]!, width: 1)
                        : null,
              ),
              child: Row(
                children: [
                  Text(
                    'درجة $grade',
                    style: TextStyle(
                      color: isUnavailable 
                          ? Colors.red[700] // نص أحمر للدرجات غير المتاحة
                          : isAvailable 
                              ? Colors.green[700] // نص أخضر للدرجات المتاحة
                              : Colors.black, // نص أسود للدرجات العادية
                      fontWeight: isUnavailable || isAvailable ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  SizedBox(width: 8),
                  if (isUnavailable) ...[
                    Icon(Icons.block, color: Colors.red[600], size: 16),
                    SizedBox(width: 4),
                    Text(
                      'ممتلئ',
                      style: TextStyle(
                        color: Colors.red[600],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ] else if (isAvailable && grade != 10) ...[
                    Icon(Icons.check_circle, color: Colors.green[600], size: 16),
                    SizedBox(width: 4),
                    Text(
                      'متاح',
                      style: TextStyle(
                        color: Colors.green[600],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ] else if (grade == 10) ...[
                    Icon(Icons.all_inclusive, color: Colors.blue[600], size: 16),
                    SizedBox(width: 4),
                    Text(
                      'لا نهائي',
                      style: TextStyle(
                        color: Colors.blue[600],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
        hintText: "اختر درجة الجودة",
        onChanged: (value) {
          if (value != null && logic.availableQualityGrades.contains(value)) {
            logic.updateQualityGrade(value);
            debugPrint("تم تغيير درجة الجودة إلى: $value");
          } else {
            // منع اختيار درجة جودة غير متاحة
            Get.snackbar(
              'تنبيه',
              'هذه الدرجة غير متاحة حالياً',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
              duration: Duration(seconds: 2),
            );
          }
        },
        )
      ],
    ));
  }

  /// دالة عرض نافذة توضيح درجات الجودة
  void _showQualityGradeHelpDialog(BuildContext context, Getinformationofitem1 logic) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue[50]!,
                  Colors.white,
                  Colors.blue[50]!,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // عنوان مع أيقونة
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    Icons.lightbulb_outline,
                    color: Colors.blue[600],
                    size: 32,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'نظام درجات الجودة',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                
                // المحتوى التفصيلي
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHelpItem(
                        icon: Icons.looks_one,
                        color: Colors.orange[600]!,
                        title: 'نظام العدد المحدود',
                        description: 'كل درجة جودة لها حد أقصى:\n• درجة 1: منتج واحد فقط\n• درجة 2: منتجين فقط\n• درجة 3: ثلاث منتجات... وهكذا',
                      ),
                      SizedBox(height: 12),
                      _buildHelpItem(
                        icon: Icons.all_inclusive,
                        color: Colors.blue[600]!,
                        title: 'درجة الجودة العاشرة',
                        description: 'درجة الجودة 10 تسمح بعدد لا نهائي من المنتجات في نفس القسم',
                      ),
                      SizedBox(height: 12),
                      _buildHelpItem(
                        icon: Icons.category,
                        color: Colors.green[600]!,
                        title: 'فصل الأقسام',
                        description: 'الحدود تطبق لكل قسم منفصل. يمكنك إضافة درجة 1 في الإلكترونيات ودرجة 1 أخرى في الملابس',
                      ),
                      SizedBox(height: 12),
                      _buildHelpItem(
                        icon: Icons.person,
                        color: Colors.purple[600]!,
                        title: 'خصوصية البائع',
                        description: 'هذه الحدود خاصة بك فقط ولا تتأثر بمنتجات البائعين الآخرين',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                
                // معلومات الحالة الحالية
                Obx(() {
                  if (logic.selectedMainCategoryId.value.isNotEmpty) {
                    return Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!, width: 1),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue[600], size: 16),
                              SizedBox(width: 8),
                              Text(
                                'القسم المختار حالياً:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[800],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${logic.selectedMainCategoryNameAr.value}${logic.selectedSubCategoryNameAr.value.isNotEmpty ? ' > ${logic.selectedSubCategoryNameAr.value}' : ''}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue[700],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                  return SizedBox.shrink();
                }),
                SizedBox(height: 20),
                
                // أزرار التحكم
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.blue[300]!, width: 1),
                          ),
                        ),
                        child: Text(
                          'فهمت',
                          style: TextStyle(
                            color: Colors.blue[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // تحديث البيانات عند الإغلاق
                          logic.updateAvailableQualityGrades();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'تحديث البيانات',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  /// دالة بناء عنصر المساعدة
  Widget _buildHelpItem({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- تعديل دالة بناء قائمة بلد المنشأ ---
  Widget _buildCountryDropdown(Getinformationofitem1 logic, double hi, double wi, BuildContext context) {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        
        // القائمة المنسدلة
        _buildDropdownButton<String>(
          context: context,
          currentValue: logic.selectedCountryOfOriginKey.value,
          items: Getinformationofitem1.countryOfOriginOptions.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value['ar']!),
            );
          }).toList(),
          hintText: "اختر بلد المنشأ",
          onChanged: (value) {
            logic.updateCountryOfOrigin(value, isAutoSelected: false);
            debugPrint("تم تغيير بلد المنشأ إلى: $value");
          },
        ),
      ],
    ));
  }
  // --- ▲▲▲ نهاية دوال بناء القوائم المنسدلة الأخرى ▲▲▲ ---


  /// دالة لإنشاء أزرار الإجراءات
  Widget _buildActionButtons(BuildContext context, Getinformationofitem1 logic, double hi, double wi) {
    return Obx(() => ElevatedButton( // استخدام Obx لمراقبة isSend
            style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurpleAccent,
            minimumSize: Size(double.infinity, hi / 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
          onPressed: logic.isSend.value ? null : () => logic.saveData(context),
          child: logic.isSend.value
              ? const CircularProgressIndicator(color: Colors.white)
              : Text("إضافة المنتج", style: TextStyle(fontSize: wi / 22, color: Colors.white)),
        ));
  }
}

