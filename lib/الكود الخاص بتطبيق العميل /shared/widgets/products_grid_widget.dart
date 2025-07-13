import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../Model/model_item.dart';
import '../../../Model/model_offer_item.dart';
import '../controllers/products_filter_controller.dart';
import 'advanced_filter_widget.dart';

/// Widget شامل لعرض المنتجات في شبكة مع فلترة متقدمة
/// يدعم المنتجات الأصلية والتجارية والعروض
class ProductsGridWidget1 extends StatefulWidget {
  final bool showFilterBar;
  final bool showSearchBar;
  final FilterCriteria? initialFilter;
  final Function(ItemModel)? onProductTap;
  final Function(OfferModel)? onOfferTap;
  final bool showOffers;

  const ProductsGridWidget1({
    super.key,
    this.showFilterBar = true,
    this.showSearchBar = true,
    this.initialFilter,
    this.onProductTap,
    this.onOfferTap,
    this.showOffers = false,
  });

  @override
  _ProductsGridWidgetState createState() => _ProductsGridWidgetState();
}

class _ProductsGridWidgetState extends State<ProductsGridWidget1> {
  final ProductsFilterController controller = Get.put(ProductsFilterController());
  final TextEditingController searchController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    
    // تطبيق الفلتر الأولي إذا كان موجوداً
    if (widget.initialFilter != null) {
      controller.applyFilter(widget.initialFilter!);
    }
    
    // إعداد التمرير اللانهائي
    scrollController.addListener(_onScroll);
    
    // تحميل العروض إذا كان مطلوباً
    if (widget.showOffers) {
      controller.loadOffers();
    }
  }

  void _onScroll() {
    if (scrollController.position.pixels >= 
        scrollController.position.maxScrollExtent - 200) {
      controller.loadMoreProducts();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // شريط البحث
        if (widget.showSearchBar) _buildSearchBar(),
        
        // شريط الفلترة
        if (widget.showFilterBar) _buildFilterBar(),
        
        // شريط الإحصائيات
        _buildStatsBar(),
        
        // قائمة المنتجات
        Expanded(
          child: _buildProductsGrid(),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: searchController,
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(
          hintText: 'البحث في المنتجات...',
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    controller.searchProducts('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.teal),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        onChanged: (value) {
          controller.searchProducts(value);
        },
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // زر الفلترة
          ElevatedButton.icon(
            onPressed: _showFilterBottomSheet,
            icon: const Icon(Icons.filter_list, size: 18),
            label: const Text('فلترة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // مؤشر الفلترة النشطة
          Obx(() {
            final hasActiveFilters = controller.currentFilter.value.hasActiveFilters;
            if (!hasActiveFilters) return const SizedBox();
            
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.filter_alt,
                    size: 14,
                    color: Colors.orange[700],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'مطبق',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }),
          
          const Spacer(),
          
          // زر مسح الفلترة
          Obx(() {
            final hasActiveFilters = controller.currentFilter.value.hasActiveFilters;
            if (!hasActiveFilters) return const SizedBox();
            
            return TextButton.icon(
              onPressed: controller.clearFilters,
              icon: const Icon(Icons.clear_all, size: 16),
              label: const Text('مسح'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    return Obx(() {
      final stats = controller.filterStats;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          border: Border(
            top: BorderSide(color: Colors.grey[200]!),
            bottom: BorderSide(color: Colors.grey[200]!),
          ),
        ),
        child: Row(
          children: [
            _buildStatItem('الكل', stats['filtered']!, Colors.blue),
            if (stats['original']! > 0) 
              _buildStatItem('أصلي', stats['original']!, Colors.green),
            if (stats['commercial']! > 0) 
              _buildStatItem('تجاري', stats['commercial']!, Colors.orange),
            if (widget.showOffers && stats['offers']! > 0)
              _buildStatItem('عروض', stats['offers']!, Colors.red),
          ],
        ),
      );
    });
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsGrid() {
    return Obx(() {
      if (controller.isLoading.value && controller.filteredProducts.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('جاري تحميل المنتجات...'),
            ],
          ),
        );
      }

      if (controller.filteredProducts.isEmpty && !controller.isLoading.value) {
        return _buildEmptyState();
      }

      return RefreshIndicator(
        onRefresh: controller.refreshProducts,
        child: GridView.builder(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: controller.filteredProducts.length + 
                     (controller.hasMoreData.value ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == controller.filteredProducts.length) {
              // مؤشر التحميل في النهاية
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final product = controller.filteredProducts[index];
            return _buildProductCard(product);
          },
        ),
      );
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد منتجات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'جرب تغيير معايير البحث أو الفلترة',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              controller.clearFilters();
              searchController.clear();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة تعيين'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ItemModel product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => widget.onProductTap?.call(product),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة المنتج
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  color: Colors.grey[200],
                ),
                child: product.images.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.network(
                          product.images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => 
                            const Icon(Icons.image_not_supported, size: 50),
                        ),
                      )
                    : const Icon(Icons.image, size: 50, color: Colors.grey),
              ),
            ),
            
            // تفاصيل المنتج
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // اسم المنتج
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // نوع المنتج والفئة
                    Row(
                      children: [
                        // نوع المنتج
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: product.itemCondition == 'original' 
                                ? Colors.green[100] 
                                : Colors.orange[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            product.itemCondition == 'original' ? 'أصلي' : 'تجاري',
                            style: TextStyle(
                              fontSize: 10,
                              color: product.itemCondition == 'original' 
                                  ? Colors.green[700] 
                                  : Colors.orange[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        
                        const Spacer(),
                        
                        // السعر
                        Text(
                          '${product.price.toStringAsFixed(0)} د.ع',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal[700],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // الفئة الفرعية (للمنتجات الأصلية)
                    if (product.itemCondition == 'original' && 
                        product.subCategoryNameAr?.isNotEmpty == true)
                      Text(
                        product.subCategoryNameAr!,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // مقبض الإغلاق
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // عنوان
              const Text(
                'فلترة المنتجات',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // widget الفلترة
              Expanded(
                child: AdvancedFilterWidget(
                  initialFilter: controller.currentFilter.value,
                  onFilterChanged: (filter) {
                    controller.applyFilter(filter);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 