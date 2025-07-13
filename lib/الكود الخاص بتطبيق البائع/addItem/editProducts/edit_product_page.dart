import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../Model/company_model.dart';
import '../../../Model/model_item.dart';
import '../../categories/controllers/categories_management_controller.dart';
import '../../TextFormFiled.dart';
import '../widgets/enhanced_barcode_input_field.dart';
import '../widgets/enhanced_category_selector.dart';
import '../widgets/main_barcode_input_field.dart';
import '../widgets/original_product_selector.dart';
import '../../original_products/controllers/original_products_controller.dart';
import '../addNewItem/class/addManyImage.dart';
import '../video/chooseVideo.dart';
import '../Chose-The-Type-Of-Itemxx.dart';

// Widget مساعد للحماية من الأخطاء
class SafeWidget extends StatelessWidget {
  final Widget child;
  
  const SafeWidget({super.key, required this.child});
  
  @override
  Widget build(BuildContext context) {
    try {
      return child;
    } catch (e) {
      debugPrint('خطأ في Widget: $e');
      return Container(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.orange),
              const SizedBox(height: 8),
              Text('خطأ في تحميل هذا القسم'),
            ],
          ),
        ),
      );
    }
  }
}

class EditProductPage extends StatefulWidget {
  final ItemModel product;
  
  const EditProductPage({
    super.key,
    required this.product,
  });

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  late Getinformationofitem1 controller;
  late VoidCallback _costPriceListener;
  late VoidCallback _sellingPriceListener;
  
  @override
  void initState() {
    super.initState();
    
    // إنشاء controller جديد للتعديل
    controller = Get.put(Getinformationofitem1(
      uint8list: Uint8List(0), // قائمة فارغة للبداية
      TypeItem: 'Item', // نوع المنتج افتراضي
    ));
    
    // تحميل الأقسام
    final categoriesController = Get.put(CategoriesManagementController());
    categoriesController.loadCategories();
    
    // تحميل بيانات المنتج في الـ controller
    _loadProductData();
    
    // إعداد listeners للأسعار
    _setupPriceValidationListeners();
  }
  
  void _loadProductData() {
    // تحميل البيانات الأساسية
    controller.nameOfItem.text = widget.product.name;
    controller.descriptionOfItem.text = widget.product.description ?? '';
    controller.priceOfItem.text = widget.product.price.toString();
    controller.costPriceOfItem.text = widget.product.costPrice?.toString() ?? '';
    controller.productQuantity.text = widget.product.quantity?.toString() ?? '';
    controller.quantityPerCarton.text = widget.product.quantityPerCarton?.toString() ?? '';
    controller.suggestedRetailPrice.text = widget.product.suggestedRetailPrice?.toString() ?? '';
    
    // تحميل معلومات الباركود
    controller.productBarcode.text = widget.product.productBarcode ?? '';
    controller.mainProductBarcode.text = widget.product.mainProductBarcode ?? '';
    
    // تحميل معلومات الأقسام
    controller.selectedMainCategoryId.value = widget.product.mainCategoryId ?? '';
    controller.selectedSubCategoryId.value = widget.product.subCategoryId ?? '';
    controller.selectedMainCategoryNameAr.value = widget.product.mainCategoryNameAr ?? '';
    controller.selectedMainCategoryNameEn.value = widget.product.mainCategoryNameEn ?? '';
    controller.selectedSubCategoryNameAr.value = widget.product.subCategoryNameAr ?? '';
    controller.selectedSubCategoryNameEn.value = widget.product.subCategoryNameEn ?? '';
    
    // تحميل معلومات حالة المنتج
    controller.selectedItemConditionKey.value = widget.product.itemCondition ?? 'commercial';
    controller.selectedQualityGrade.value = widget.product.qualityGrade;
    
    // تحميل معلومات بلد المنشأ
    if (widget.product.countryOfOrigin != null) {
      controller.updateCountryOfOrigin(widget.product.countryOfOrigin!, isAutoSelected: false);
    }
    
    // تحميل معلومات المنتج الأصلي
    controller.originalCompanyId.value = widget.product.originalCompanyId ?? '';
    controller.originalProductId.value = widget.product.originalProductId ?? '';
    
    // تحميل الشركة المختارة والمنتج المختار إذا كان المنتج أصلي
    if (widget.product.itemCondition == 'original' && 
        widget.product.originalCompanyId != null && 
        widget.product.originalCompanyId!.isNotEmpty) {
      _loadOriginalProductData();
    }
    
    // تحميل الصور
    controller.imageUrlList.assignAll(widget.product.manyImages);
    
    // تحديث نوع البائع
    controller.sellerTypeAssociatedWithProduct.value = widget.product.addedBySellerType ?? 'retail';
    
    // تحديث درجات الجودة المتاحة
    controller.updateAvailableQualityGrades();
    
    controller.update();
  }
  
  /// تحميل بيانات الشركة والمنتج الأصلي المحفوظة مسبقاً
  Future<void> _loadOriginalProductData() async {
    try {
      // الحصول على controller المنتجات الأصلية
      final originalProductsController = Get.put(OriginalProductsController());
      
      // التأكد من تحميل البيانات أولاً
      await originalProductsController.loadCompanies();
      
      // البحث عن الشركة بالـ ID
      final companyId = widget.product.originalCompanyId;
      if (companyId == null || companyId.isEmpty) {
        debugPrint("⚠️ معرف الشركة فارغ أو غير صحيح");
        return;
      }
      
      final company = originalProductsController.companies.firstWhereOrNull(
        (c) => c.id == companyId
      );
      
             if (company != null) {
         // تحديد الشركة المختارة
         originalProductsController.setSelectedCompany(company);
         debugPrint("✅ تم تحميل الشركة: ${company.nameAr}");
         
         // إنتظار تحميل منتجات الشركة
         await Future.delayed(Duration(milliseconds: 800));
         
         // البحث عن المنتج بالـ ID في منتجات الشركة
         final productId = widget.product.originalProductId;
         if (productId == null || productId.isEmpty) {
           debugPrint("⚠️ معرف المنتج فارغ أو غير صحيح");
           return;
         }
         
         CompanyProductModel? product;
         
         // البحث في منتجات الشركة المحملة
         if (company.products.isNotEmpty) {
           product = company.products.firstWhereOrNull((p) => p.id == productId);
         }
         
         // إذا لم نجد المنتج في منتجات الشركة، نبحث في filteredProducts
         product ??= originalProductsController.filteredProducts.firstWhereOrNull(
             (p) => p.id == productId
           );
         
         if (product != null) {
           // تحديد المنتج المختار
           originalProductsController.setSelectedProduct(product);
           debugPrint("✅ تم تحميل المنتج: ${product.nameAr}");
         } else {
           debugPrint("⚠️ لم يتم العثور على المنتج بالـ ID: $productId");
         }
       } else {
        debugPrint("⚠️ لم يتم العثور على الشركة بالـ ID: $companyId");
      }
    } catch (e) {
      debugPrint("❌ خطأ في تحميل بيانات المنتج الأصلي: $e");
    }
  }
  
  void _setupPriceValidationListeners() {
    _costPriceListener = () {
      if (controller.priceOfItem.text.isNotEmpty) {
        setState(() {});
      }
    };
    controller.costPriceOfItem.addListener(_costPriceListener);
    
    _sellingPriceListener = () {
      if (controller.costPriceOfItem.text.isNotEmpty) {
        setState(() {});
      }
    };
    controller.priceOfItem.addListener(_sellingPriceListener);
  }
  
  @override
  void dispose() {
    controller.costPriceOfItem.removeListener(_costPriceListener);
    controller.priceOfItem.removeListener(_sellingPriceListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<Getinformationofitem1>(
      init: controller,
      builder: (logic) {
        final double hi = MediaQuery.of(context).size.height;
        final double wi = MediaQuery.of(context).size.width;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: const Text('تعديل المنتج'),
            backgroundColor: Colors.amber[600],
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: () => _saveChanges(logic),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: wi / 20,
              right: wi / 20,
              top: 10,
            ),
            child: Form(
              key: logic.globalKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // عرض نوع البائع
                  Obx(() => _buildSellerTypeInfo(logic, wi)),
                  
                  SizedBox(height: hi * 0.02),
                  
                  // اسم المنتج
                  _buildTextFormField(
                    controller: logic.nameOfItem,
                    label: "اسم المنتج",
                    validator: (val) => val == null || val.isEmpty ? "يجب إدخال اسم المنتج" : null,
                    keyboardType: TextInputType.text,
                  ),
                  
                  SizedBox(height: hi * 0.02),
                  
                  // وصف المنتج
                  _buildTextFormField(
                    controller: logic.descriptionOfItem,
                    label: "وصف المنتج",
                    validator: (val) => val == null || val.isEmpty ? "يجب إدخال وصف المنتج" : null,
                    keyboardType: TextInputType.multiline,
                    maxLines: 3,
                  ),
                  
                  SizedBox(height: hi * 0.02),
                  
                  // كمية المنتج
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
                          SizedBox(height: hi * 0.01),
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
                  
                  // باركود المنتج
                  EnhancedBarcodeInputField(
                    controller: logic.productBarcode,
                    label: "باركود الرقم التسلسلي لكل منتج (اختياري)",
                    logic: logic,
                    validator: (val) {
                      if (val == null || val.isEmpty) return null;
                      if (val.length < 6) return "الباركود قصير جداً";
                      if (val.length > 50) return "الباركود طويل جداً";
                      return null;
                    },
                    onBarcodeScanned: () {
                      debugPrint("تم مسح الباركود: ${logic.productBarcode.text}");
                    },
                  ),
                  
                  SizedBox(height: hi * 0.02),
                  
                  // الباركود الرئيسي
                  MainBarcodeInputField(
                    controller: logic.mainProductBarcode,
                    label: "الباركود الرئيسي للمنتج (اختياري)",
                    logic: logic,
                    validator: (val) {
                      if (val == null || val.isEmpty) return null;
                      if (val.length < 6) return "الباركود قصير جداً";
                      if (val.length > 50) return "الباركود طويل جداً";
                      return null;
                    },
                    onBarcodeScanned: () {
                      debugPrint("تم مسح الباركود الرئيسي: ${logic.mainProductBarcode.text}");
                    },
                  ),
                  
                  SizedBox(height: hi * 0.02),
                  
                  // سعر التكلفة
                  _buildTextFormField(
                    controller: logic.costPriceOfItem,
                    label: "سعر تكلفة المنتج",
                    validator: (val) {
                      if (val == null || val.isEmpty) return "يجب إدخال سعر التكلفة";
                      if (double.tryParse(val) == null) return "أدخل سعراً صحيحاً (أرقام)";
                      if (double.parse(val) <= 0) return "السعر يجب أن يكون أكبر من صفر";
                      
                      final sellingPriceText = logic.priceOfItem.text;
                      if (sellingPriceText.isNotEmpty) {
                        final sellingPrice = double.tryParse(sellingPriceText);
                        final costPrice = double.parse(val);
                        if (sellingPrice != null && costPrice > sellingPrice) {
                          return "سعر التكلفة لا يمكن أن يكون أكبر من سعر البيع";
                        }
                      }
                      return null;
                    },
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                  
                  SizedBox(height: hi * 0.02),
                  
                  // سعر البيع
                  _buildTextFormField(
                    controller: logic.priceOfItem,
                    label: "سعر البيع للمنتج",
                    validator: (val) {
                      if (val == null || val.isEmpty) return "يجب إدخال سعر البيع";
                      if (double.tryParse(val) == null) return "أدخل سعراً صحيحاً (أرقام)";
                      if (double.parse(val) <= 0) return "السعر يجب أن يكون أكبر من صفر";
                      
                      final costPriceText = logic.costPriceOfItem.text;
                      if (costPriceText.isNotEmpty) {
                        final costPrice = double.tryParse(costPriceText);
                        final sellingPrice = double.parse(val);
                        if (costPrice != null && sellingPrice < costPrice) {
                          return "سعر البيع لا يمكن أن يكون أقل من سعر التكلفة";
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
                  
                  // تحذير هامش الربح
                  _buildProfitMarginWarning(logic),
                  
                  // حالة المنتج والمنتج الأصلي
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildConditionDropdown(logic, hi, wi, context),
                      SizedBox(height: hi * 0.02),
                      
                      // اختيار المنتج الأصلي (للمنتجات الأصلية)
                      Obx(() {
                        if (logic.selectedItemConditionKey.value == 'original') {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("تحديد المنتج الأصلي (مطلوب)"),
                              SizedBox(height: 8),
                              OriginalProductSelector(
                                onSelectionChanged: (company, product, mainCategoryId, subCategoryId) {
                                  // حفظ معلومات المنتج الأصلي
                                  logic.originalCompanyId.value = company?.id ?? '';
                                  logic.originalProductId.value = product?.id ?? '';
                                  
                                  // تحديث بلد المنشأ تلقائياً
                                  if (company != null && company.country != null && company.country!.isNotEmpty) {
                                    String? matchedCountryKey = _findMatchingCountryKey(company.country!);
                                    if (matchedCountryKey != null) {
                                      logic.updateCountryOfOrigin(matchedCountryKey, isAutoSelected: true);
                                    }
                                  }
                                  
                                  // تحديث الأقسام
                                  logic.selectedMainCategoryId.value = mainCategoryId ?? '';
                                  logic.selectedSubCategoryId.value = subCategoryId ?? '';
                                  
                                  // تحديث الأسماء العربية للأقسام
                                  final categoriesController = Get.find<CategoriesManagementController>();
                                  final mainCategory = categoriesController.mainCategories.firstWhereOrNull((cat) => cat.id == mainCategoryId);
                                  if (mainCategory != null) {
                                    logic.selectedMainCategoryNameAr.value = mainCategory.nameAr;
                                    logic.selectedMainCategoryNameEn.value = mainCategory.nameEn;
                                    
                                    if (subCategoryId != null && subCategoryId.isNotEmpty) {
                                      final subCategory = mainCategory.subCategories.firstWhereOrNull((sub) => sub.id == subCategoryId);
                                      if (subCategory != null) {
                                        logic.selectedSubCategoryNameAr.value = subCategory.nameAr;
                                        logic.selectedSubCategoryNameEn.value = subCategory.nameEn;
                                      }
                                    } else {
                                      logic.selectedSubCategoryNameAr.value = '';
                                      logic.selectedSubCategoryNameEn.value = '';
                                    }
                                  }
                                  
                                  // تحديث درجات الجودة المتاحة بعد اختيار المنتج الأصلي
                                  logic.updateAvailableQualityGrades();
                                  debugPrint("🔄 تم اختيار منتج أصلي - تحديث درجات الجودة المتاحة");
                                  logic.update();
                                },
                              ),
                              SizedBox(height: hi * 0.02),
                            ],
                          );
                        }
                        return SizedBox.shrink();
                      }),
                      
                      // درجة الجودة
                      Obx(() {
                        if (logic.selectedItemConditionKey.value != 'commercial') {
                          return Column(
                            children: [
                              _buildQualityDropdown(logic, hi, wi, context),
                              SizedBox(height: hi * 0.02),
                            ],
                          );
                        }
                        return SizedBox.shrink();
                      }),
                      
                      // بلد المنشأ
                      _buildCountryDropdown(logic, hi, wi, context),
                      SizedBox(height: hi * 0.02),
                      
                      // محدد الأقسام (للمنتجات التجارية)
                      Obx(() {
                        if (logic.selectedItemConditionKey.value == 'commercial') {
                          return Column(
                            children: [
                              _buildEnhancedCategorySelector(logic),
                              SizedBox(height: hi * 0.02),
                            ],
                          );
                        }
                        return SizedBox.shrink();
                      }),
                    ],
                  ),
                  
                  // الصور
                  _buildImageSection(logic),
                  SizedBox(height: hi * 0.02),
                  
                  // الفيديو
                  _buildVideoSection(logic),
                  SizedBox(height: hi * 0.02),
                  
                  // أزرار الحفظ والإلغاء
                  _buildActionButtons(context, logic, hi, wi),
                  SizedBox(height: hi * 0.05),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String? _findMatchingCountryKey(String countryName) {
    String normalizedInput = countryName.trim().toLowerCase();
    
    if (Getinformationofitem1.countryOfOriginOptions.containsKey(countryName)) {
      return countryName;
    }
    
    for (var entry in Getinformationofitem1.countryOfOriginOptions.entries) {
      if (entry.value['ar']!.toLowerCase() == normalizedInput) {
        return entry.key;
      }
    }
    
    return null;
  }

  Widget _buildSellerTypeInfo(Getinformationofitem1 logic, double wi) {
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
        color: displayColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: displayColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(displayIcon, color: displayColor, size: wi / 20),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              "تعديل المنتج كـ: $sellerTypeDisplay",
              style: TextStyle(
                fontSize: wi / 26, 
                fontWeight: FontWeight.w600, 
                color: displayColor
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    required TextInputType keyboardType,
    int? maxLines = 1,
  }) {
    return TextFormFiled(
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

  Widget _buildProfitMarginWarning(Getinformationofitem1 logic) {
    if (logic.costPriceOfItem.text.isEmpty || logic.priceOfItem.text.isEmpty) {
      return SizedBox.shrink();
    }

    final costPrice = double.tryParse(logic.costPriceOfItem.text);
    final sellingPrice = double.tryParse(logic.priceOfItem.text);

    if (costPrice == null || sellingPrice == null || costPrice == 0) {
      return SizedBox.shrink();
    }

    final profitMargin = ((sellingPrice - costPrice) / costPrice * 100);

    if (profitMargin < 10) {
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
            Icon(Icons.warning, color: Colors.orange[600], size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'تحذير: هامش الربح منخفض (${profitMargin.toStringAsFixed(1)}%)',
                style: TextStyle(color: Colors.orange[700], fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox.shrink();
  }

  Widget _buildConditionDropdown(Getinformationofitem1 logic, double hi, double wi, BuildContext context) {
    return Obx(() => _buildDropdownButton<String>(
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
      },
    ));
  }

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
        
        // القائمة المنسدلة المحسنة
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

  Widget _buildCountryDropdown(Getinformationofitem1 logic, double hi, double wi, BuildContext context) {
    return Obx(() => _buildDropdownButton<String>(
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
      },
    ));
  }

  Widget _buildEnhancedCategorySelector(Getinformationofitem1 logic) {
    return Obx(() => EnhancedCategorySelector(
      label: 'قسم المنتج (مطلوب)',
      initialMainCategoryId: logic.selectedMainCategoryId.value.isEmpty ? null : logic.selectedMainCategoryId.value,
      initialSubCategoryId: logic.selectedSubCategoryId.value.isEmpty ? null : logic.selectedSubCategoryId.value,
      onCategorySelected: (mainCategoryId, subCategoryId, mainCategoryNameEn, subCategoryNameEn) {
        logic.selectedMainCategoryId.value = mainCategoryId;
        logic.selectedSubCategoryId.value = subCategoryId;
        logic.selectedMainCategoryNameEn.value = mainCategoryNameEn;
        logic.selectedSubCategoryNameEn.value = subCategoryNameEn;
        
        // تحديث الأسماء العربية أيضاً (للعرض في المساعدة)
        final categoriesController = Get.find<CategoriesManagementController>();
        final mainCategory = categoriesController.mainCategories.firstWhereOrNull((cat) => cat.id == mainCategoryId);
        if (mainCategory != null) {
          logic.selectedMainCategoryNameAr.value = mainCategory.nameAr;
          
          if (subCategoryId.isNotEmpty) {
            final subCategory = mainCategory.subCategories.firstWhereOrNull((sub) => sub.id == subCategoryId);
            if (subCategory != null) {
              logic.selectedSubCategoryNameAr.value = subCategory.nameAr;
            }
          } else {
            logic.selectedSubCategoryNameAr.value = '';
          }
        }
        
        if (subCategoryId.isNotEmpty && subCategoryNameEn.isNotEmpty) {
          logic.selectedCategoryNameEn.value = '${mainCategoryNameEn}_$subCategoryNameEn';
        } else {
          logic.selectedCategoryNameEn.value = mainCategoryNameEn;
        }
        
        // تحديث درجات الجودة المتاحة بعد اختيار الأقسام
        logic.updateAvailableQualityGrades();
        debugPrint("🔄 تم تحديث الأقسام - تحديث درجات الجودة المتاحة");
        logic.update();
      },
      isRequired: true,
    ));
  }

  Widget _buildDropdownButton<T>({
    required BuildContext context,
    required T? currentValue,
    required String hintText,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    bool isLoading = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: isLoading ? Colors.grey.shade200 : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: isLoading ? null : currentValue,
          hint: Text(hintText),
          isExpanded: true,
          items: isLoading ? [] : items,
          onChanged: isLoading ? null : onChanged,
        ),
      ),
    );
  }

  Widget _buildImageSection(Getinformationofitem1 logic) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('صور المنتج', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            AddManyImage(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoSection(Getinformationofitem1 logic) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('فيديو المنتج', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            ChooseVideo(),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 14.5,
        color: Colors.grey[800],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Getinformationofitem1 logic, double hi, double wi) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: Size(double.infinity, hi / 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            onPressed: () => _saveChanges(logic),
            child: Obx(() => logic.isSend.value
                ? const CircularProgressIndicator(color: Colors.white)
                : Text("حفظ التعديلات", style: TextStyle(fontSize: wi / 22, color: Colors.white))),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              minimumSize: Size(double.infinity, hi / 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            onPressed: () => Get.back(),
            child: Text("إلغاء", style: TextStyle(fontSize: wi / 22, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  void _saveChanges(Getinformationofitem1 logic) async {
    if (logic.globalKey.currentState!.validate()) {
      logic.isSend.value = true;
      
      try {
        // هنا ستكون عملية حفظ التعديلات
        await logic.updateProductData(widget.product.id);
        
        Get.snackbar(
          'نجح',
          'تم حفظ التعديلات بنجاح',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        
        Get.back(result: true);
      } catch (e) {
        Get.snackbar(
          'خطأ',
          'فشل في حفظ التعديلات: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      } finally {
        logic.isSend.value = false;
      }
    }
  }

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
                                'حالة الأقسام المختارة:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[800],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'القسم الرئيسي: ${logic.selectedMainCategoryNameAr.value}',
                            style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                          ),
                          if (logic.selectedSubCategoryNameAr.value.isNotEmpty) ...[
                            Text(
                              'القسم الفرعي: ${logic.selectedSubCategoryNameAr.value}',
                              style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                            ),
                          ],
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green[600], size: 14),
                              SizedBox(width: 4),
                              Text(
                                'متاح: ${logic.availableQualityGrades.length} درجة',
                                style: TextStyle(fontSize: 12, color: Colors.green[600]),
                              ),
                              SizedBox(width: 16),
                              Icon(Icons.block, color: Colors.red[600], size: 14),
                              SizedBox(width: 4),
                              Text(
                                'مكتمل: ${logic.unavailableQualityGrades.length} درجة',
                                style: TextStyle(fontSize: 12, color: Colors.red[600]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }
                  return Container();
                }),
                
                SizedBox(height: 20),
                
                // زر الإغلاق
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, size: 18),
                      SizedBox(width: 8),
                      Text('فهمت', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 