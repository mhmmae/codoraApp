import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../original_products/controllers/original_products_controller.dart';
import '../../../Model/company_model.dart';

/// Widget لاختيار الشركة والمنتج الأصلي مع إمكانية البحث
class OriginalProductSelector extends StatefulWidget {
  final void Function(CompanyModel?, CompanyProductModel?, String?, String?)? onSelectionChanged;

  const OriginalProductSelector({
    super.key,
    this.onSelectionChanged,
  });

  @override
  State<OriginalProductSelector> createState() => _OriginalProductSelectorState();
}

class _OriginalProductSelectorState extends State<OriginalProductSelector> {
  late OriginalProductsController controller;
  
  // متحكمات البحث
  final TextEditingController _companySearchController = TextEditingController();
  final TextEditingController _productSearchController = TextEditingController();
  
  // قوائم مفلترة للبحث
  List<CompanyModel> _filteredCompanies = [];
  List<CompanyProductModel> _filteredProducts = [];
  
  @override
  void initState() {
    super.initState();
    // تهيئة الكنترولر
    if (Get.isRegistered<OriginalProductsController>()) {
      controller = Get.find<OriginalProductsController>();
    } else {
      controller = Get.put(OriginalProductsController());
    }
    
    // تهيئة القوائم المفلترة
    _updateFilteredLists();
    
    // إضافة مستمعين للبحث
    _companySearchController.addListener(_filterCompanies);
    _productSearchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _companySearchController.dispose();
    _productSearchController.dispose();
    super.dispose();
  }

  /// تحديث القوائم المفلترة عند تحديث البيانات
  void _updateFilteredLists() {
    setState(() {
      _filteredCompanies = controller.companies;
      _filteredProducts = controller.filteredProducts;
    });
  }

  /// فلترة الشركات حسب النص المدخل
  void _filterCompanies() {
    final query = _companySearchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCompanies = controller.companies;
      } else {
        _filteredCompanies = controller.companies.where((company) {
          return company.nameAr.toLowerCase().contains(query) ||
                 company.nameEn.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  /// فلترة المنتجات حسب النص المدخل
  void _filterProducts() {
    final query = _productSearchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = controller.filteredProducts;
      } else {
        _filteredProducts = controller.filteredProducts.where((product) {
          return product.nameAr.toLowerCase().contains(query) ||
                 product.nameEn.toLowerCase().contains(query) ||
                 product.category.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    return Obx(() {
      // تحديث القوائم المفلترة عند تغيير البيانات
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateFilteredLists());
      
      if (controller.companies.isEmpty) {
        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange[600]),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'لا توجد شركات متاحة. يمكنك إضافة شركات من إدارة المنتجات الأصلية.',
                  style: TextStyle(color: Colors.orange[800]),
                ),
              ),
            ],
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // اختيار الشركة
          _buildCompanySelector(width),
          
          SizedBox(height: 16),
          
          // اختيار المنتج (يظهر فقط بعد اختيار الشركة)
          if (controller.selectedCompany.value != null) ...[
            _buildProductSelector(width),
          ],
        ],
      );
    });
  }

  /// selector للشركة مع البحث
  Widget _buildCompanySelector(double width) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.business, size: 20, color: Colors.blue[600]),
            SizedBox(width: 8),
            Text(
              'الشركة المصنعة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(width: 4),

          ],
        ),
        SizedBox(height: 8),
        
        // زر اختيار الشركة مع البحث
        InkWell(
          onTap: () => _showCompanySearchDialog(context),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                if (controller.selectedCompany.value != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: CachedNetworkImage(
                      imageUrl: controller.selectedCompany.value!.logoUrl ?? '',
                      width: 30,
                      height: 30,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 30,
                        height: 30,
                        color: Colors.grey[300],
                        child: Icon(Icons.business, size: 16, color: Colors.grey[600]),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 30,
                        height: 30,
                        color: Colors.grey[300],
                        child: Icon(Icons.business, size: 16, color: Colors.grey[600]),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.selectedCompany.value!.nameAr,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          controller.selectedCompany.value!.nameEn,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Icon(Icons.search, color: Colors.grey[600]),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'ابحث عن الشركة المصنعة',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
                Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// حوار البحث عن الشركات
  void _showCompanySearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('اختر الشركة المصنعة'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    // حقل البحث
                    TextField(
                      controller: _companySearchController,
                      decoration: InputDecoration(
                        hintText: 'ابحث عن الشركة...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) => setDialogState(() {}),
                    ),
                    SizedBox(height: 16),
                    
                    // قائمة الشركات المفلترة
                    Expanded(
                      child: ListView(
                        children: [
                          // خيار "منتج غير أصلي"
                          ListTile(
                            leading: Icon(Icons.clear, color: Colors.grey[600]),
                            title: Text('منتج غير أصلي'),
                            onTap: () {
                              controller.setSelectedCompany(null);
                              _companySearchController.clear();
                              if (widget.onSelectionChanged != null) {
                                widget.onSelectionChanged!(null, null, null, null);
                              }
                              Navigator.pop(context);
                            },
                          ),
                          Divider(),
                          
                          // الشركات المفلترة
                          ..._filteredCompanies.map((company) {
                            return ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: CachedNetworkImage(
                                  imageUrl: company.logoUrl ?? '',
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    width: 40,
                                    height: 40,
                                    color: Colors.grey[300],
                                    child: Icon(Icons.business, size: 20, color: Colors.grey[600]),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    width: 40,
                                    height: 40,
                                    color: Colors.grey[300],
                                    child: Icon(Icons.business, size: 20, color: Colors.grey[600]),
                                  ),
                                ),
                              ),
                              title: Text(company.nameAr),
                              subtitle: Text(company.nameEn),
                              onTap: () {
                                controller.setSelectedCompany(company);
                                _companySearchController.clear();
                                _productSearchController.clear();
                                if (widget.onSelectionChanged != null) {
                                  widget.onSelectionChanged!(company, null, null, null);
                                }
                                Navigator.pop(context);
                              },
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _companySearchController.clear();
                    Navigator.pop(context);
                  },
                  child: Text('إلغاء'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// selector للمنتج مع البحث
  Widget _buildProductSelector(double width) {
    return Obx(() {
      // تحديث قائمة المنتجات المفلترة
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _filteredProducts = controller.filteredProducts;
        _filterProducts();
      });
      
      if (controller.isLoadingProducts.value) {
        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text(
                'جاري تحميل منتجات الشركة...',
                style: TextStyle(color: Colors.blue[800]),
              ),
            ],
          ),
        );
      }

      if (controller.filteredProducts.isEmpty) {
        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.inventory_outlined, color: Colors.orange[600]),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'لا توجد منتجات لهذه الشركة. يمكنك إضافة منتجات من إدارة المنتجات الأصلية.',
                  style: TextStyle(color: Colors.orange[800]),
                ),
              ),
            ],
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.phone_android, size: 20, color: Colors.blue[600]),
              SizedBox(width: 8),
              Text(
                'المنتج الأصلي',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(width: 4),

            ],
          ),
          SizedBox(height: 8),
          
          // زر اختيار المنتج مع البحث
          InkWell(
            onTap: () => _showProductSearchDialog(context),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  if (controller.selectedProduct.value != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: controller.selectedProduct.value!.imageUrl ?? '',
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 40,
                          height: 40,
                          color: Colors.grey[300],
                          child: Icon(Icons.inventory, size: 20, color: Colors.grey[600]),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 40,
                          height: 40,
                          color: Colors.grey[300],
                          child: Icon(Icons.inventory, size: 20, color: Colors.grey[600]),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.selectedProduct.value!.nameAr,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            controller.selectedProduct.value!.category,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Icon(Icons.search, color: Colors.grey[600]),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'ابحث عن المنتج الأصلي',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ],
                  Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  /// حوار البحث عن المنتجات
  void _showProductSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('اختر المنتج الأصلي'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    // حقل البحث
                    TextField(
                      controller: _productSearchController,
                      decoration: InputDecoration(
                        hintText: 'ابحث عن المنتج...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) => setDialogState(() {}),
                    ),
                    SizedBox(height: 16),
                    
                    // قائمة المنتجات المفلترة
                    Expanded(
                      child: ListView(
                        children: [
                          // خيار "لا يطابق أي منتج"
                          ListTile(
                            leading: Icon(Icons.clear, color: Colors.grey[600]),
                            title: Text('لا يطابق أي منتج أصلي'),
                            onTap: () {
                              controller.setSelectedProduct(null);
                              _productSearchController.clear();
                              if (widget.onSelectionChanged != null) {
                                widget.onSelectionChanged!(controller.selectedCompany.value, null, null, null);
                              }
                              Navigator.pop(context);
                            },
                          ),
                          Divider(),
                          
                          // المنتجات المفلترة
                          ..._filteredProducts.map((product) {
                            return ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: product.imageUrl ?? '',
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.grey[300],
                                    child: Icon(Icons.inventory, size: 25, color: Colors.grey[600]),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.grey[300],
                                    child: Icon(Icons.inventory, size: 25, color: Colors.grey[600]),
                                  ),
                                ),
                              ),
                              title: Text(product.nameAr),
                              subtitle: Text(product.category),
                              onTap: () {
                                controller.setSelectedProduct(product);
                                _productSearchController.clear();
                                if (widget.onSelectionChanged != null) {
                                  debugPrint("تم اختيار المنتج: ${product.nameAr}");
                                  debugPrint("معرف القسم الرئيسي: ${product.mainCategoryId}");
                                  debugPrint("معرف القسم الفرعي: ${product.subCategoryId}");
                                  // إرجاع المعلومات الصحيحة مع أسماء الأقسام من المنتج مباشرة
                                debugPrint("🔍 إرجاع معلومات المنتج الأصلي:");
                                debugPrint("   Main Category: ID=${product.mainCategoryId}, AR='${product.mainCategoryNameAr}', EN='${product.mainCategoryNameEn}'");
                                debugPrint("   Sub Category: ID=${product.subCategoryId}, AR='${product.subCategoryNameAr}', EN='${product.subCategoryNameEn}'");
                                
                                widget.onSelectionChanged!(
                                    controller.selectedCompany.value,
                                    product,
                                    product.mainCategoryId,
                                    product.subCategoryId
                                  );
                                }
                                Navigator.pop(context);
                              },
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _productSearchController.clear();
                    Navigator.pop(context);
                  },
                  child: Text('إلغاء'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}