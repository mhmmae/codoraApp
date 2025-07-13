import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';


import '../../../../Model/model_item.dart';
import '../../../../XXX/xxx_firebase.dart';

class EditProductController extends GetxController {
  // معلومات المنتج الحالي
  // بيانات المنتج (تم نقلها إلى getter/setter أدناه)
  final RxnBool currentProduct = RxnBool(null);
  
  // حالة التحميل والإرسال
  final RxBool isLoading = false.obs;
  final RxBool isSending = false.obs;
  
  // Controllers للحقول النصية
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController costPriceController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController mainBarcodeController = TextEditingController();
  
  // قوائم الصور والفيديو
  final RxList<String> imageUrlList = <String>[].obs;
  final RxList<Uint8List> imageBytesList = <Uint8List>[].obs;
  final RxnString videoUrl = RxnString(null);
  final Rxn<XFile> selectedVideoFile = Rxn<XFile>();
  
  // معلومات حالة المنتج والجودة
  final RxnString selectedItemConditionKey = RxnString(null);
  final RxnInt selectedQualityGrade = RxnInt(null);
  final RxnString selectedCountryOfOriginKey = RxnString(null);
  final RxnString selectedCountryOfOriginAr = RxnString(null);
  final RxnString selectedCountryOfOriginEn = RxnString(null);
  
  // معلومات التصنيف
  final RxString selectedMainCategoryId = ''.obs;
  final RxString selectedSubCategoryId = ''.obs;
  final RxString selectedMainCategoryNameEn = ''.obs;
  final RxString selectedSubCategoryNameEn = ''.obs;
  final RxString selectedMainCategoryNameAr = ''.obs;
  final RxString selectedSubCategoryNameAr = ''.obs;
  
  // قوائم الباركود
  final RxList<String> productBarcodes = <String>[].obs;
  final TextEditingController barcodeController = TextEditingController();
  
  // معلومات المنتج الأصلي
  final RxString originalCompanyId = ''.obs;
  final RxString originalProductId = ''.obs;
  final RxString originalCompanyName = ''.obs;
  final RxString originalProductName = ''.obs;
  
  // الصور الرئيسية
  final Rxn<Uint8List> newMainImage = Rxn<Uint8List>();
  final RxString mainImageUrl = ''.obs;
  
  // خصائص إضافية مطلوبة
  final RxString selectedTypeItem = ''.obs;
  final RxString selectedItemCondition = ''.obs;
  final RxString mainCategoryNameAr = ''.obs;
  final RxString subCategoryNameAr = ''.obs;
  final RxString selectedCountry = ''.obs;
  
  // خصائص متعلقة بالصور والفيديو
  final RxList<Uint8List> newAdditionalImages = <Uint8List>[].obs;
  final RxList<String> additionalImagesUrls = <String>[].obs;
  final Rxn<XFile> newVideoFile = Rxn<XFile>();
  final RxBool isVideoDeleted = false.obs;
  
  // خيارات القوائم المنسدلة
  static const Map<String, String> itemConditionOptions = {
    'original': 'أصلي',
    'commercial': 'تجاري'
  };
  
  static final List<int> qualityGradeOptions = List.generate(10, (index) => index + 1);
  
  static const Map<String, Map<String, String>> countryOfOriginOptions = {
    'AE': {'ar': 'الإمارات العربية المتحدة', 'en': 'United Arab Emirates'},
    'SA': {'ar': 'المملكة العربية السعودية', 'en': 'Saudi Arabia'},
    'EG': {'ar': 'مصر', 'en': 'Egypt'},
    'JO': {'ar': 'الأردن', 'en': 'Jordan'},
    'LB': {'ar': 'لبنان', 'en': 'Lebanon'},
    'SY': {'ar': 'سوريا', 'en': 'Syria'},
    'IQ': {'ar': 'العراق', 'en': 'Iraq'},
    'KW': {'ar': 'الكويت', 'en': 'Kuwait'},
    'QA': {'ar': 'قطر', 'en': 'Qatar'},
    'BH': {'ar': 'البحرين', 'en': 'Bahrain'},
    'OM': {'ar': 'عُمان', 'en': 'Oman'},
    'YE': {'ar': 'اليمن', 'en': 'Yemen'},
    'US': {'ar': 'الولايات المتحدة', 'en': 'United States'},
    'CN': {'ar': 'الصين', 'en': 'China'},
    'JP': {'ar': 'اليابان', 'en': 'Japan'},
    'DE': {'ar': 'ألمانيا', 'en': 'Germany'},
    'FR': {'ar': 'فرنسا', 'en': 'France'},
    'GB': {'ar': 'المملكة المتحدة', 'en': 'United Kingdom'},
    'IT': {'ar': 'إيطاليا', 'en': 'Italy'},
    'ES': {'ar': 'إسبانيا', 'en': 'Spain'},
    'TR': {'ar': 'تركيا', 'en': 'Turkey'},
    'IN': {'ar': 'الهند', 'en': 'India'},
    'KR': {'ar': 'كوريا الجنوبية', 'en': 'South Korea'},
    'BR': {'ar': 'البرازيل', 'en': 'Brazil'},
    'CA': {'ar': 'كندا', 'en': 'Canada'},
    'AU': {'ar': 'أستراليا', 'en': 'Australia'},
    'RU': {'ar': 'روسيا', 'en': 'Russia'},
    'MX': {'ar': 'المكسيك', 'en': 'Mexico'},
    'NL': {'ar': 'هولندا', 'en': 'Netherlands'},
    'CH': {'ar': 'سويسرا', 'en': 'Switzerland'},
    'SE': {'ar': 'السويد', 'en': 'Sweden'},
    'NO': {'ar': 'النرويج', 'en': 'Norway'},
    'DK': {'ar': 'الدنمارك', 'en': 'Denmark'},
    'FI': {'ar': 'فنلندا', 'en': 'Finland'},
    'BE': {'ar': 'بلجيكا', 'en': 'Belgium'},
    'AT': {'ar': 'النمسا', 'en': 'Austria'},
    'PL': {'ar': 'بولندا', 'en': 'Poland'},
    'CZ': {'ar': 'جمهورية التشيك', 'en': 'Czech Republic'},
    'HU': {'ar': 'هنغاريا', 'en': 'Hungary'},
    'GR': {'ar': 'اليونان', 'en': 'Greece'},
    'PT': {'ar': 'البرتغال', 'en': 'Portugal'},
    'IE': {'ar': 'أيرلندا', 'en': 'Ireland'},
    'IL': {'ar': 'إسرائيل', 'en': 'Israel'},
    'ZA': {'ar': 'جنوب أفريقيا', 'en': 'South Africa'},
    'NG': {'ar': 'نيجيريا', 'en': 'Nigeria'},
    'MA': {'ar': 'المغرب', 'en': 'Morocco'},
    'DZ': {'ar': 'الجزائر', 'en': 'Algeria'},
    'TN': {'ar': 'تونس', 'en': 'Tunisia'},
    'LY': {'ar': 'ليبيا', 'en': 'Libya'},
    'SD': {'ar': 'السودان', 'en': 'Sudan'},
    'ET': {'ar': 'إثيوبيا', 'en': 'Ethiopia'},
    'KE': {'ar': 'كينيا', 'en': 'Kenya'},
    'TZ': {'ar': 'تنزانيا', 'en': 'Tanzania'},
    'UG': {'ar': 'أوغندا', 'en': 'Uganda'},
    'GH': {'ar': 'غانا', 'en': 'Ghana'},
    'CI': {'ar': 'ساحل العاج', 'en': 'Ivory Coast'},
    'SN': {'ar': 'السنغال', 'en': 'Senegal'},
    'ML': {'ar': 'مالي', 'en': 'Mali'},
    'BF': {'ar': 'بوركينا فاسو', 'en': 'Burkina Faso'},
    'NE': {'ar': 'النيجر', 'en': 'Niger'},
    'TD': {'ar': 'تشاد', 'en': 'Chad'},
    'CM': {'ar': 'الكاميرون', 'en': 'Cameroon'},
    'CF': {'ar': 'جمهورية أفريقيا الوسطى', 'en': 'Central African Republic'},
    'GA': {'ar': 'الغابون', 'en': 'Gabon'},
    'CG': {'ar': 'الكونغو', 'en': 'Congo'},
    'CD': {'ar': 'جمهورية الكونغو الديمقراطية', 'en': 'Democratic Republic of the Congo'},
    'AO': {'ar': 'أنغولا', 'en': 'Angola'},
    'ZM': {'ar': 'زامبيا', 'en': 'Zambia'},
    'ZW': {'ar': 'زيمبابوي', 'en': 'Zimbabwe'},
    'BW': {'ar': 'بوتسوانا', 'en': 'Botswana'},
    'NA': {'ar': 'ناميبيا', 'en': 'Namibia'},
    'SZ': {'ar': 'إسواتيني', 'en': 'Eswatini'},
    'LS': {'ar': 'ليسوتو', 'en': 'Lesotho'},
    'MW': {'ar': 'مالاوي', 'en': 'Malawi'},
    'MZ': {'ar': 'موزمبيق', 'en': 'Mozambique'},
    'MG': {'ar': 'مدغشقر', 'en': 'Madagascar'},
    'MU': {'ar': 'موريشيوس', 'en': 'Mauritius'},
    'SC': {'ar': 'سيشل', 'en': 'Seychelles'},
    'KM': {'ar': 'جزر القمر', 'en': 'Comoros'},
    'DJ': {'ar': 'جيبوتي', 'en': 'Djibouti'},
    'SO': {'ar': 'الصومال', 'en': 'Somalia'},
    'ER': {'ar': 'إريتريا', 'en': 'Eritrea'},
    'SS': {'ar': 'جنوب السودان', 'en': 'South Sudan'},
    'RW': {'ar': 'رواندا', 'en': 'Rwanda'},
    'BI': {'ar': 'بوروندي', 'en': 'Burundi'},
    'TH': {'ar': 'تايلاند', 'en': 'Thailand'},
    'VN': {'ar': 'فيتنام', 'en': 'Vietnam'},
    'MY': {'ar': 'ماليزيا', 'en': 'Malaysia'},
    'SG': {'ar': 'سنغافورة', 'en': 'Singapore'},
    'ID': {'ar': 'إندونيسيا', 'en': 'Indonesia'},
    'PH': {'ar': 'الفلبين', 'en': 'Philippines'},
    'BN': {'ar': 'بروناي', 'en': 'Brunei'},
    'KH': {'ar': 'كمبوديا', 'en': 'Cambodia'},
    'LA': {'ar': 'لاوس', 'en': 'Laos'},
    'MM': {'ar': 'ميانمار', 'en': 'Myanmar'},
    'BD': {'ar': 'بنغلاديش', 'en': 'Bangladesh'},
    'LK': {'ar': 'سريلانكا', 'en': 'Sri Lanka'},
    'NP': {'ar': 'نيبال', 'en': 'Nepal'},
    'BT': {'ar': 'بوتان', 'en': 'Bhutan'},
    'MV': {'ar': 'المالديف', 'en': 'Maldives'},
    'AF': {'ar': 'أفغانستان', 'en': 'Afghanistan'},
    'PK': {'ar': 'باكستان', 'en': 'Pakistan'},
    'IR': {'ar': 'إيران', 'en': 'Iran'},
    'UZ': {'ar': 'أوزبكستان', 'en': 'Uzbekistan'},
    'KZ': {'ar': 'كازاخستان', 'en': 'Kazakhstan'},
    'KG': {'ar': 'قيرغيزستان', 'en': 'Kyrgyzstan'},
    'TJ': {'ar': 'طاجيكستان', 'en': 'Tajikistan'},
    'TM': {'ar': 'تركمانستان', 'en': 'Turkmenistan'},
    'MN': {'ar': 'منغوليا', 'en': 'Mongolia'},
    'GE': {'ar': 'جورجيا', 'en': 'Georgia'},
    'AM': {'ar': 'أرمينيا', 'en': 'Armenia'},
    'AZ': {'ar': 'أذربيجان', 'en': 'Azerbaijan'},
    'BY': {'ar': 'بيلاروسيا', 'en': 'Belarus'},
    'UA': {'ar': 'أوكرانيا', 'en': 'Ukraine'},
    'MD': {'ar': 'مولدوفا', 'en': 'Moldova'},
    'RO': {'ar': 'رومانيا', 'en': 'Romania'},
    'BG': {'ar': 'بلغاريا', 'en': 'Bulgaria'},
    'RS': {'ar': 'صربيا', 'en': 'Serbia'},
    'ME': {'ar': 'الجبل الأسود', 'en': 'Montenegro'},
    'BA': {'ar': 'البوسنة والهرسك', 'en': 'Bosnia and Herzegovina'},
    'HR': {'ar': 'كرواتيا', 'en': 'Croatia'},
    'SI': {'ar': 'سلوفينيا', 'en': 'Slovenia'},
    'SK': {'ar': 'سلوفاكيا', 'en': 'Slovakia'},
    'MK': {'ar': 'مقدونيا الشمالية', 'en': 'North Macedonia'},
    'AL': {'ar': 'ألبانيا', 'en': 'Albania'},
    'XK': {'ar': 'كوسوفو', 'en': 'Kosovo'},
    'CY': {'ar': 'قبرص', 'en': 'Cyprus'},
    'MT': {'ar': 'مالطا', 'en': 'Malta'},
    'IS': {'ar': 'أيسلندا', 'en': 'Iceland'},
    'LV': {'ar': 'لاتفيا', 'en': 'Latvia'},
    'LT': {'ar': 'ليتوانيا', 'en': 'Lithuania'},
    'EE': {'ar': 'إستونيا', 'en': 'Estonia'},
    'LU': {'ar': 'لوكسمبورغ', 'en': 'Luxembourg'},
    'LI': {'ar': 'ليختنشتاين', 'en': 'Liechtenstein'},
    'MC': {'ar': 'موناكو', 'en': 'Monaco'},
    'SM': {'ar': 'سان مارينو', 'en': 'San Marino'},
    'VA': {'ar': 'الفاتيكان', 'en': 'Vatican City'},
    'AD': {'ar': 'أندورا', 'en': 'Andorra'},
  };

  // خاصية لحفظ المنتج
  ItemModel? _product;
  final RxBool isProductLoaded = false.obs;
  
  ItemModel get product => _product!;
  set product(ItemModel value) {
    _product = value;
    isProductLoaded.value = true;
    _loadProductData();
  }



  /// حذف المنتج
  Future<bool> deleteProduct() async {
    try {
      isLoading.value = true;
      
      // حذف الصور من Storage
      for (String imageUrl in imageUrlList) {
        await _deleteFileFromStorage(imageUrl);
      }
      
      // حذف الفيديو من Storage
      if (videoUrl.value != null && videoUrl.value!.isNotEmpty) {
        await _deleteFileFromStorage(videoUrl.value!);
      }
      
      // حذف المنتج من Firestore
      await FirebaseFirestore.instance
          .collection(FirebaseX.itemsCollection)
          .doc(product.id)
          .delete();
      
      Get.snackbar('نجح', 'تم حذف المنتج بنجاح', backgroundColor: Colors.green, colorText: Colors.white);
      return true;
      
    } catch (e) {
      debugPrint('خطأ في حذف المنتج: $e');
      Get.snackbar('خطأ', 'حدث خطأ أثناء حذف المنتج', backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// اختيار الصورة الرئيسية
  Future<void> pickMainImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      final bytes = await image.readAsBytes();
      newMainImage.value = bytes;
      mainImageUrl.value = image.path; // مؤقتاً
    }
  }

  /// اختيار صور إضافية
  Future<void> pickAdditionalImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    
    for (XFile image in images) {
      final bytes = await image.readAsBytes();
      newAdditionalImages.add(bytes);
    }
  }

  /// حذف صورة
  void deleteImage(String imageUrl) {
    additionalImagesUrls.remove(imageUrl);
  }

  /// حذف صورة جديدة
  void deleteNewImage(int index) {
    if (index >= 0 && index < newAdditionalImages.length) {
      newAdditionalImages.removeAt(index);
    }
  }

  /// اختيار فيديو
  Future<void> pickVideo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
    
    if (video != null) {
      newVideoFile.value = video;
      isVideoDeleted.value = false;
    }
  }

  /// حذف فيديو
  void deleteVideo() {
    newVideoFile.value = null;
    videoUrl.value = null;
    isVideoDeleted.value = true;
  }

  /// الحصول على VideoPlayerController
  VideoPlayerController? get videoController {
    if (newVideoFile.value != null) {
      return VideoPlayerController.file(File(newVideoFile.value!.path));
    } else if (videoUrl.value != null && videoUrl.value!.isNotEmpty && videoUrl.value != 'noVideo') {
      return VideoPlayerController.networkUrl(Uri.parse(videoUrl.value!));
    }
    return null;
  }

  /// تحديث معلومات المنتج الأصلي
  void updateOriginalProduct({
    required String companyId,
    required String productId,
    required String companyName,
    required String productName,
    String? mainCategoryId,
    String? subCategoryId,
    String? mainCategoryNameAr,
    String? subCategoryNameAr,
    String? mainCategoryNameEn,
    String? subCategoryNameEn,
  }) {
    originalCompanyId.value = companyId;
    originalProductId.value = productId;
    originalCompanyName.value = companyName;
    originalProductName.value = productName;
    
    // تحديث معلومات التصنيف إذا توفرت
    if (mainCategoryId != null) selectedMainCategoryId.value = mainCategoryId;
    if (subCategoryId != null) selectedSubCategoryId.value = subCategoryId;
    if (mainCategoryNameAr != null) selectedMainCategoryNameAr.value = mainCategoryNameAr;
    if (subCategoryNameAr != null) selectedSubCategoryNameAr.value = subCategoryNameAr;
    if (mainCategoryNameEn != null) selectedMainCategoryNameEn.value = mainCategoryNameEn;
    if (subCategoryNameEn != null) selectedSubCategoryNameEn.value = subCategoryNameEn;
    
    update();
  }

  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    costPriceController.dispose();
    quantityController.dispose();
    mainBarcodeController.dispose();
    barcodeController.dispose();
    super.onClose();
  }

  /// تحميل بيانات المنتج الحالي
  void _loadProductData() {
    nameController.text = product.name;
    descriptionController.text = product.description ?? '';
    priceController.text = product.price.toString();
    costPriceController.text = product.costPrice?.toString() ?? '';
    quantityController.text = product.quantity?.toString() ?? '';
    mainBarcodeController.text = product.mainProductBarcode ?? '';
    
    // تحميل قوائم الصور والفيديو
    if (product.images.isNotEmpty) {
      imageUrlList.assignAll(product.images);
      additionalImagesUrls.assignAll(product.images);
    }
    
    if (product.videoUrl != null && product.videoUrl!.isNotEmpty && product.videoUrl != 'noVideo') {
      videoUrl.value = product.videoUrl!;
    }
    
    // تحميل معلومات حالة المنتج
    selectedItemConditionKey.value = product.itemCondition;
    selectedQualityGrade.value = product.qualityGrade;
    selectedCountryOfOriginKey.value = product.countryOfOrigin;
    
    // تحديث أسماء البلد
    if (selectedCountryOfOriginKey.value != null) {
      final countryData = countryOfOriginOptions[selectedCountryOfOriginKey.value];
      if (countryData != null) {
        selectedCountryOfOriginAr.value = countryData['ar'];
        selectedCountryOfOriginEn.value = countryData['en'];
      }
    }
    
    // تحميل معلومات التصنيف
    selectedMainCategoryId.value = product.mainCategoryId ?? '';
    selectedSubCategoryId.value = product.subCategoryId ?? '';
    selectedMainCategoryNameAr.value = product.mainCategoryNameAr ?? '';
    selectedMainCategoryNameEn.value = product.mainCategoryNameEn ?? '';
    selectedSubCategoryNameAr.value = product.subCategoryNameAr ?? '';
    selectedSubCategoryNameEn.value = product.subCategoryNameEn ?? '';
    mainCategoryNameAr.value = product.mainCategoryNameAr ?? '';
    subCategoryNameAr.value = product.subCategoryNameAr ?? '';
    
    // تحميل خصائص أخرى
    selectedTypeItem.value = product.typeItem;
    selectedItemCondition.value = product.itemCondition ?? 'original';
    selectedCountry.value = product.countryOfOrigin ?? '';
    
    // تحميل معلومات الصور والفيديو
    if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
      mainImageUrl.value = product.imageUrl!;
    }
    
    if (product.videoUrl != null && product.videoUrl!.isNotEmpty && product.videoUrl != 'noVideo') {
      videoUrl.value = product.videoUrl!;
    }
    
    // تحميل الصور الإضافية (إذا كانت متوفرة في النموذج)
    // additionalImagesUrls.clear();
    
    // تحميل قائمة الباركود
    productBarcodes.assignAll(product.productBarcodes ?? []);
  }

  /// تحديث حالة المنتج
  void updateItemCondition(String? condition) {
    selectedItemConditionKey.value = condition;
    update();
  }

  /// تحديث درجة الجودة
  void updateQualityGrade(int? grade) {
    selectedQualityGrade.value = grade;
    update();
  }

  /// تحديث بلد المنشأ
  void updateCountryOfOrigin(String? countryKey) {
    selectedCountryOfOriginKey.value = countryKey;
    if (countryKey != null) {
      final countryData = countryOfOriginOptions[countryKey];
      if (countryData != null) {
        selectedCountryOfOriginAr.value = countryData['ar'];
        selectedCountryOfOriginEn.value = countryData['en'];
      }
    } else {
      selectedCountryOfOriginAr.value = null;
      selectedCountryOfOriginEn.value = null;
    }
    update();
  }

  /// البحث عن مفتاح البلد المطابق
  String? findMatchingCountryKey(String countryName) {
    String normalizedInput = countryName.trim().toLowerCase();
    
    // البحث المباشر بالمفتاح
    if (countryOfOriginOptions.containsKey(countryName)) {
      return countryName;
    }
    
    // البحث بالاسم العربي
    for (var entry in countryOfOriginOptions.entries) {
      if (entry.value['ar']!.toLowerCase() == normalizedInput) {
        return entry.key;
      }
    }
    
    // البحث الجزئي
    for (var entry in countryOfOriginOptions.entries) {
      String normalizedValue = entry.value['ar']!.toLowerCase();
      if (normalizedValue.contains(normalizedInput) || normalizedInput.contains(normalizedValue)) {
        return entry.key;
      }
    }
    
    return null;
  }

  /// إضافة صورة جديدة
  void addImage(Uint8List imageBytes) {
    imageBytesList.add(imageBytes);
    update();
  }

  /// حذف صورة
  void removeImage(int index) {
    if (index < imageUrlList.length) {
      imageUrlList.removeAt(index);
    } else {
      int bytesIndex = index - imageUrlList.length;
      if (bytesIndex >= 0 && bytesIndex < imageBytesList.length) {
        imageBytesList.removeAt(bytesIndex);
      }
    }
    update();
  }

  /// إضافة فيديو
  void addVideo(XFile videoFile) {
    selectedVideoFile.value = videoFile;
    update();
  }

  /// حذف الفيديو
  void removeVideo() {
    videoUrl.value = null;
    selectedVideoFile.value = null;
    update();
  }

  /// إضافة باركود
  void addBarcode(String barcode) {
    if (barcode.isNotEmpty && !productBarcodes.contains(barcode)) {
      productBarcodes.add(barcode);
      update();
    }
  }

  /// حذف باركود
  void removeBarcode(int index) {
    if (index >= 0 && index < productBarcodes.length) {
      productBarcodes.removeAt(index);
      update();
    }
  }

  /// التحقق من صحة البيانات
  bool _validateInputs() {
    if (nameController.text.trim().isEmpty) {
      Get.snackbar('خطأ', 'يرجى إدخال اسم المنتج', backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    if (priceController.text.trim().isEmpty) {
      Get.snackbar('خطأ', 'يرجى إدخال سعر المنتج', backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    double? price = double.tryParse(priceController.text);
    if (price == null || price <= 0) {
      Get.snackbar('خطأ', 'يرجى إدخال سعر صحيح', backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    // التحقق من سعر التكلفة إذا تم إدخاله
    if (costPriceController.text.isNotEmpty) {
      double? costPrice = double.tryParse(costPriceController.text);
      if (costPrice == null || costPrice < 0) {
        Get.snackbar('خطأ', 'يرجى إدخال سعر تكلفة صحيح', backgroundColor: Colors.red, colorText: Colors.white);
        return false;
      }
      
      if (costPrice >= price) {
        Get.snackbar('خطأ', 'سعر التكلفة يجب أن يكون أقل من سعر البيع', backgroundColor: Colors.red, colorText: Colors.white);
        return false;
      }
    }

    return true;
  }

  /// حفظ التعديلات
  Future<bool> updateProduct() async {
    if (!_validateInputs()) return false;

    try {
      isLoading.value = true;

      // رفع الصور الجديدة
      List<String> newImageUrls = [];
      for (Uint8List imageBytes in imageBytesList) {
        String fileName = 'image_${DateTime.now().millisecondsSinceEpoch}';
        String? imageUrl = await _uploadImage(imageBytes, fileName);
        if (imageUrl != null) {
          newImageUrls.add(imageUrl);
        }
      }

      // رفع الفيديو الجديد
      String? newVideoUrl;
      if (selectedVideoFile.value != null) {
        newVideoUrl = await _uploadVideo(selectedVideoFile.value!);
      }

      // تحضير البيانات المحدثة
      Map<String, dynamic> updatedData = {
        'nameOfItem': nameController.text.trim(),
        'descriptionOfItem': descriptionController.text.trim(),
        'priceOfItem': double.parse(priceController.text),
        'imageUrlList': [...imageUrlList, ...newImageUrls],
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      // إضافة البيانات الاختيارية
      if (costPriceController.text.isNotEmpty) {
        updatedData['costPrice'] = double.parse(costPriceController.text);
      }
      
      if (quantityController.text.isNotEmpty) {
        updatedData['quantityOfItem'] = int.parse(quantityController.text);
      }
      
      if (newVideoUrl != null) {
        updatedData['videoUrl'] = newVideoUrl;
      } else if (videoUrl.value != null) {
        updatedData['videoUrl'] = videoUrl.value;
      }
      
      if (selectedItemConditionKey.value != null) {
        updatedData['itemCondition'] = selectedItemConditionKey.value;
      }
      
      if (selectedQualityGrade.value != null) {
        updatedData['qualityGrade'] = selectedQualityGrade.value;
      }
      
      if (selectedCountryOfOriginKey.value != null) {
        updatedData['countryOfOrigin'] = selectedCountryOfOriginKey.value;
      }
      
      if (mainBarcodeController.text.isNotEmpty) {
        updatedData['mainProductBarcode'] = mainBarcodeController.text.trim();
      }
      
      if (productBarcodes.isNotEmpty) {
        updatedData['productBarcodes'] = productBarcodes.toList();
      }

      // حفظ البيانات في Firebase
      await FirebaseFirestore.instance
          .collection(FirebaseX.itemsCollection)
          .doc(product.id)
          .update(updatedData);

      Get.snackbar('نجح', 'تم تحديث المنتج بنجاح', backgroundColor: Colors.green, colorText: Colors.white);
      return true;

    } catch (e) {
      debugPrint('خطأ في تحديث المنتج: $e');
      Get.snackbar('خطأ', 'حدث خطأ أثناء تحديث المنتج', backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// رفع صورة إلى Firebase Storage
  Future<String?> _uploadImage(Uint8List imageBytes, String fileName) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('products')
          .child('${product.uidAdd}/$fileName.jpg');
      
      final uploadTask = await ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('خطأ في رفع الصورة: $e');
      return null;
    }
  }

  /// رفع فيديو إلى Firebase Storage
  Future<String?> _uploadVideo(XFile videoFile) async {
    try {
      final bytes = await videoFile.readAsBytes();
      final ref = FirebaseStorage.instance
          .ref()
          .child('products')
          .child('${product.uidAdd}/video_${DateTime.now().millisecondsSinceEpoch}.mp4');
      
      final uploadTask = await ref.putData(
        bytes,
        SettableMetadata(contentType: 'video/mp4'),
      );
      
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('خطأ في رفع الفيديو: $e');
      return null;
    }
  }

  /// حذف ملف من Firebase Storage
  Future<void> _deleteFileFromStorage(String url) async {
    try {
      final ref = FirebaseStorage.instance.refFromURL(url);
      await ref.delete();
    } catch (e) {
      debugPrint('خطأ في حذف الملف: $e');
    }
  }
} 