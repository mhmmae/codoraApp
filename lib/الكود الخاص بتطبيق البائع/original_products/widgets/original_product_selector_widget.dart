import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/original_products_controller.dart';
import '../../../Model/company_model.dart';

/// Widget لاختيار المنتج الأصلي المرتبط بالمنتج التجاري
/// يساعد البائع على ربط المنتج التجاري بالمنتج الأصلي المقابل له
class OriginalProductSelectorWidget extends StatefulWidget {
  final Function(CompanyProductModel) onProductSelected;
  final CompanyProductModel? initialSelectedProduct;
  final String? filterByCategory;

  const OriginalProductSelectorWidget({
    super.key,
    required this.onProductSelected,
    this.initialSelectedProduct,
    this.filterByCategory,
  });

  @override
  _OriginalProductSelectorWidgetState createState() => _OriginalProductSelectorWidgetState();
}

class _OriginalProductSelectorWidgetState extends State<OriginalProductSelectorWidget> {
  final OriginalProductsController controller = Get.put(OriginalProductsController());
  final TextEditingController searchController = TextEditingController();
  CompanyProductModel? selectedProduct;

  @override
  void initState() {
    super.initState();
    selectedProduct = widget.initialSelectedProduct;
    
    // تحميل جميع المنتجات الأصلية
    _loadOriginalProducts();
    
    // إعداد البحث
    searchController.addListener(() {
      controller.searchQuery.value = searchController.text;
    });
  }

  Future<void> _loadOriginalProducts() async {
    await controller.loadCompanies();
    
    // إذا كان هناك فلترة حسب الفئة
    if (widget.filterByCategory != null) {
      controller.selectedCategory.value = widget.filterByCategory!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // العنوان
          Row(
            children: [
              Icon(Icons.link, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                'ربط بمنتج أصلي',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'يمكنك ربط هذا المنتج التجاري بالمنتج الأصلي المقابل له',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[600],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // شريط البحث
          TextField(
            controller: searchController,
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              hintText: 'البحث في المنتجات الأصلية...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // المنتج المختار حالياً
          if (selectedProduct != null)
            _buildSelectedProductCard(),
          
          const SizedBox(height: 12),
          
          // زر البحث وعرض النتائج
          ElevatedButton.icon(
            onPressed: _showProductSearchDialog,
            icon: const Icon(Icons.search),
            label: Text(selectedProduct == null ? 'اختيار منتج أصلي' : 'تغيير المنتج المختار'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          
          // زر إزالة الاختيار
          if (selectedProduct != null)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  selectedProduct = null;
                });
              },
              icon: const Icon(Icons.clear, color: Colors.red),
              label: const Text('إزالة الربط', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectedProductCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[300]!),
      ),
      child: Row(
        children: [
          // صورة المنتج
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: Colors.grey[200],
            ),
            child: selectedProduct!.imageUrl?.isNotEmpty == true
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      selectedProduct!.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image, color: Colors.grey),
                    ),
                  )
                : const Icon(Icons.image, color: Colors.grey),
          ),
          
          const SizedBox(width: 12),
          
          // تفاصيل المنتج
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedProduct!.nameAr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'السعر: ${selectedProduct!.price} د.ع',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                // عرض معلومات الأقسام
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // القسم الرئيسي
                    if (selectedProduct!.mainCategoryNameAr?.isNotEmpty == true)
                      Row(
                        children: [
                          Text(
                            'القسم الرئيسي: ${selectedProduct!.mainCategoryNameAr!}',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (selectedProduct!.mainCategoryNameEn?.isNotEmpty == true) ...[
                            const SizedBox(width: 4),
                            Text(
                              '(${selectedProduct!.mainCategoryNameEn!})',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 9,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    // القسم الفرعي
                    if (selectedProduct!.subCategoryNameAr?.isNotEmpty == true)
                      Row(
                        children: [
                          Text(
                            'القسم الفرعي: ${selectedProduct!.subCategoryNameAr!}',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (selectedProduct!.subCategoryNameEn?.isNotEmpty == true) ...[
                            const SizedBox(width: 4),
                            Text(
                              '(${selectedProduct!.subCategoryNameEn!})',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 9,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          
          // أيقونة المنتج المختار
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.green[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              color: Colors.green[700],
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _showProductSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // عنوان الحوار
              Row(
                children: [
                  const Icon(Icons.search, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text(
                    'اختيار منتج أصلي',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              
              const Divider(),
              
              // شريط البحث في الحوار
              TextField(
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  hintText: 'البحث في المنتجات الأصلية...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) {
                  controller.searchQuery.value = value;
                },
              ),
              
              const SizedBox(height: 16),
              
              // قائمة المنتجات
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // جمع جميع المنتجات من جميع الشركات
                  final allProducts = <CompanyProductModel>[];
                  for (final company in controller.companies) {
                    allProducts.addAll(company.products.where((p) => p.isActive));
                  }

                  // تطبيق البحث
                  final filteredProducts = allProducts.where((product) {
                    final searchQuery = controller.searchQuery.value.toLowerCase();
                    return searchQuery.isEmpty ||
                        product.nameAr.toLowerCase().contains(searchQuery) ||
                        product.nameEn.toLowerCase().contains(searchQuery);
                  }).toList();

                  if (filteredProducts.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'لا توجد منتجات أصلية',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return _buildProductTile(product);
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductTile(CompanyProductModel product) {
    final isSelected = selectedProduct?.id == product.id;
    
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: Colors.grey[200],
        ),
        child: product.imageUrl?.isNotEmpty == true
            ? ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  product.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.image, color: Colors.grey, size: 20),
                ),
              )
            : const Icon(Icons.image, color: Colors.grey, size: 20),
      ),
      title: Text(
        product.nameAr,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'السعر: ${product.price} د.ع',
            style: TextStyle(
              color: Colors.green[700],
              fontSize: 12,
            ),
          ),
          // عرض معلومات الأقسام
          if (product.mainCategoryNameAr?.isNotEmpty == true ||
              product.subCategoryNameAr?.isNotEmpty == true) ...[
            // القسم الرئيسي
            if (product.mainCategoryNameAr?.isNotEmpty == true)
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    TextSpan(text: 'الرئيسي: ${product.mainCategoryNameAr!}'),
                    if (product.mainCategoryNameEn?.isNotEmpty == true)
                      TextSpan(
                        text: ' (${product.mainCategoryNameEn!})',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 9,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            // القسم الفرعي
            if (product.subCategoryNameAr?.isNotEmpty == true)
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    TextSpan(text: 'الفرعي: ${product.subCategoryNameAr!}'),
                    if (product.subCategoryNameEn?.isNotEmpty == true)
                      TextSpan(
                        text: ' (${product.subCategoryNameEn!})',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 9,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ],
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: Colors.green[700])
          : const Icon(Icons.circle_outlined, color: Colors.grey),
      onTap: () {
        setState(() {
          selectedProduct = product;
        });
        widget.onProductSelected(product);
        Navigator.pop(context);
      },
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
} 