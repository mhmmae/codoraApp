import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'controllers/products_list_controller.dart';
import 'edit_product_page.dart';
import '../../../Model/model_item.dart';

class ProductsListForEditPage extends StatelessWidget {
  const ProductsListForEditPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProductsListController());
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // App Bar مخصص مع animations
          SliverAppBar(
            expandedHeight: 120.0,
            floating: true,
            snap: true,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.amber[600]!,
                    Colors.orange[600]!,
                  ],
                ),
              ),
              child: FlexibleSpaceBar(
                title: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: const Text(
                          'تعديل المنتجات',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                centerTitle: true,
              ),
            ),
            leading: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(-50 * (1 - value), 0),
                  child: Opacity(
                    opacity: value,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Get.back(),
                    ),
                  ),
                );
              },
            ),
            actions: [
              // زر البحث مع animation
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(50 * (1 - value), 0),
                    child: Opacity(
                      opacity: value,
                      child: IconButton(
                        icon: const Icon(Icons.search, color: Colors.white),
                        onPressed: () => _showAnimatedSearchDialog(context, controller),
                      ),
                    ),
                  );
                },
              ),
              // زر الفلتر والترتيب
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(50 * (1 - value), 0),
                    child: Opacity(
                      opacity: value,
                      child: IconButton(
                        icon: const Icon(Icons.filter_list, color: Colors.white),
                        onPressed: () => _showFilterBottomSheet(context, controller),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          
          // محتوى الصفحة
          SliverToBoxAdapter(
            child: Obx(() {
              // عرض شريط البحث النشط
              if (controller.searchText.value.isNotEmpty) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.scale(
                        scale: value,
                        child: Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.amber[100],
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.search, color: Colors.amber[800], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'البحث عن: ${controller.searchText.value}',
                                  style: TextStyle(
                                    color: Colors.amber[800],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: controller.clearSearch,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.amber[600],
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            }),
          ),
          
          // قائمة المنتجات
          Obx(() {
            if (controller.isLoading.value) {
              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildShimmerCard(),
                    childCount: 5,
                  ),
                ),
              );
            }
            
            if (controller.filteredProducts.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(controller),
              );
            }
            
            return SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: AnimationLimiter(
                child: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = controller.filteredProducts[index];
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 600),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _buildEnhancedProductCard(
                              context,
                              product,
                              controller,
                              index,
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: controller.filteredProducts.length,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
      
      // زر إضافة منتج جديد عائم
      floatingActionButton: Obx(() {
        if (controller.isLoading.value) return const SizedBox.shrink();
        
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(seconds: 1),
          builder: (context, value, child) {
            return Transform.rotate(
              angle: value * 2 * 3.14159,
              child: Transform.scale(
                scale: value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber[600]!, Colors.orange[600]!],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Get.back(),
                      borderRadius: BorderRadius.circular(28),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.add, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'منتج جديد',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
  
  // بناء كارد المنتج المحسّن
  Widget _buildEnhancedProductCard(
    BuildContext context,
    ItemModel product,
    ProductsListController controller,
    int index,
  ) {
    return Hero(
      tag: 'product_${product.id}',
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _navigateToEditPage(context, product, controller),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // قسم الصورة والمعلومات الأساسية
                  Container(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // صورة المنتج مع animation
                        _buildProductImage(product),
                        const SizedBox(width: 12),
                        
                        // معلومات المنتج
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // اسم المنتج
                              Text(
                                product.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              
                              // السعر مع animation
                              _buildPriceWidget(product),
                              const SizedBox(height: 6),
                              
                              // معلومات إضافية
                              _buildProductInfo(product),
                            ],
                          ),
                        ),
                        
                        const SizedBox(width: 8),
                        // أيقونة التعديل
                        _buildEditIcon(),
                      ],
                    ),
                  ),
                  
                  // شريط الحالة السفلي
                  _buildStatusBar(product),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // بناء صورة المنتج
  Widget _buildProductImage(ItemModel product) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // الصورة
            product.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: product.imageUrl!,
                    fit: BoxFit.cover,
                    width: 80,
                    height: 80,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.image_not_supported,
                        size: 30,
                        color: Colors.grey[400],
                      ),
                    ),
                  )
                : Container(
                    color: Colors.grey[200],
                    child: Icon(
                      Icons.inventory_2,
                      size: 30,
                      color: Colors.grey[400],
                    ),
                  ),
            
            // مؤشر الصور المتعددة
            if (product.manyImages.isNotEmpty)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.photo_library, size: 10, color: Colors.white),
                      const SizedBox(width: 2),
                      Text(
                        '${product.manyImages.length + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // مؤشر الفيديو
            if (product.videoUrl != null && product.videoUrl != 'noVideo')
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  // بناء widget السعر
  Widget _buildPriceWidget(ItemModel product) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green[400]!, Colors.green[600]!],
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.attach_money, size: 12, color: Colors.white),
              const SizedBox(width: 2),
              Flexible(
                child: Text(
                  '${product.price.toStringAsFixed(0)} ريال',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (product.costPrice != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'التكلفة: ${product.costPrice!.toStringAsFixed(0)}',
              style: TextStyle(
                color: Colors.orange[800],
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
  
  // بناء معلومات المنتج
  Widget _buildProductInfo(ItemModel product) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        // الكمية
        if (product.quantity != null)
          _buildInfoChip(
            icon: Icons.inventory,
            label: 'الكمية: ${product.quantity}',
            color: _getQuantityColor(product.quantity!),
          ),
        
        // الباركود
        if (product.productBarcode != null && product.productBarcode!.isNotEmpty)
          _buildInfoChip(
            icon: Icons.qr_code,
            label: 'باركود',
            color: Colors.blue,
          ),
        
        // نوع المنتج
        if (product.itemCondition != null)
          _buildInfoChip(
            icon: Icons.category,
            label: product.itemCondition == 'original' ? 'أصلي' : 'تجاري',
            color: product.itemCondition == 'original' ? Colors.purple : Colors.teal,
          ),
      ],
    );
  }
  
  // بناء chip المعلومات
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  // بناء أيقونة التعديل
  Widget _buildEditIcon() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber[400]!, Colors.orange[400]!],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.edit_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
        );
      },
    );
  }
  
  // بناء شريط الحالة
  Widget _buildStatusBar(ItemModel product) {
    // حساب نسبة الربح
    double profitPercentage = 0;
    if (product.costPrice != null && product.costPrice! > 0) {
      profitPercentage = ((product.price - product.costPrice!) / product.costPrice!) * 100;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // القسم
          if (product.mainCategoryNameAr != null)
            Flexible(
              flex: 1,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.folder, size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 2),
                  Flexible(
                    child: Text(
                      product.mainCategoryNameAr!,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[700],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(width: 8),
          
          // نسبة الربح
          if (product.costPrice != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: profitPercentage > 20
                    ? Colors.green[100]
                    : profitPercentage > 10
                        ? Colors.orange[100]
                        : Colors.red[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.trending_up,
                    size: 10,
                    color: profitPercentage > 20
                        ? Colors.green[700]
                        : profitPercentage > 10
                            ? Colors.orange[700]
                            : Colors.red[700],
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${profitPercentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: profitPercentage > 20
                          ? Colors.green[700]
                          : profitPercentage > 10
                              ? Colors.orange[700]
                              : Colors.red[700],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  // بناء Shimmer للتحميل
  Widget _buildShimmerCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
  
  // بناء حالة الفراغ
  Widget _buildEmptyState(ProductsListController controller) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(seconds: 1),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(seconds: 1),
                  curve: Curves.elasticOut,
                  builder: (context, innerValue, child) {
                    return Transform.scale(
                      scale: innerValue,
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.amber[50],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.inventory_2_outlined,
                          size: 80,
                          color: Colors.amber[600],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  controller.searchText.value.isEmpty
                      ? 'لا توجد منتجات حالياً'
                      : 'لا توجد نتائج للبحث',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  controller.searchText.value.isEmpty
                      ? 'ابدأ بإضافة منتجاتك الأولى'
                      : 'جرب البحث بكلمات أخرى',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                if (controller.searchText.value.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: controller.clearSearch,
                    icon: const Icon(Icons.clear),
                    label: const Text('مسح البحث'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
  
  // دالة الحصول على لون الكمية
  Color _getQuantityColor(int quantity) {
    if (quantity == 0) {
      return Colors.red;
    } else if (quantity <= 5) {
      return Colors.orange;
    } else if (quantity <= 20) {
      return Colors.yellow[700]!;
    } else {
      return Colors.green;
    }
  }
  
  // عرض نافذة البحث المتحركة
  void _showAnimatedSearchDialog(BuildContext context, ProductsListController controller) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            )),
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.search, color: Colors.amber[600], size: 28),
                        const SizedBox(width: 12),
                        const Text(
                          'البحث عن منتج',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: controller.searchController,
                      onChanged: controller.searchProducts,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'اسم المنتج، الباركود، أو الوصف...',
                        filled: true,
                        fillColor: Colors.grey[100],
                        prefixIcon: Icon(Icons.search, color: Colors.amber[600]),
                        suffixIcon: controller.searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: controller.clearSearch,
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.amber[600]!, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('إغلاق'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            if (controller.searchController.text.isNotEmpty) {
                              controller.searchProducts(controller.searchController.text);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber[600],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('بحث'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  // عرض bottom sheet للفلترة والترتيب
  void _showFilterBottomSheet(BuildContext context, ProductsListController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 300),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 100 * (1 - value)),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // مقبض السحب
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // عنوان
                    Row(
                      children: [
                        Icon(Icons.filter_list, color: Colors.amber[600], size: 28),
                        const SizedBox(width: 12),
                        const Text(
                          'ترتيب وفلترة',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // خيارات الترتيب
                    const Text(
                      'ترتيب حسب:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    Obx(() => Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildSortChip(
                          label: 'الأبجدية',
                          icon: Icons.sort_by_alpha,
                          isSelected: controller.currentSortType.value == SortType.alphabetical,
                          onTap: () {
                            controller.changeSortType(SortType.alphabetical);
                            Navigator.pop(context);
                          },
                        ),
                        _buildSortChip(
                          label: 'الأحدث',
                          icon: Icons.access_time,
                          isSelected: controller.currentSortType.value == SortType.newest,
                          onTap: () {
                            controller.changeSortType(SortType.newest);
                            Navigator.pop(context);
                          },
                        ),
                        _buildSortChip(
                          label: 'السعر',
                          icon: Icons.attach_money,
                          isSelected: controller.currentSortType.value == SortType.price,
                          onTap: () {
                            controller.changeSortType(SortType.price);
                            Navigator.pop(context);
                          },
                        ),
                        _buildSortChip(
                          label: 'الكمية',
                          icon: Icons.inventory,
                          isSelected: controller.currentSortType.value == SortType.quantity,
                          onTap: () {
                            controller.changeSortType(SortType.quantity);
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    )),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  // بناء chip الترتيب
  Widget _buildSortChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber[600] : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.amber[600]! : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // الانتقال لصفحة التعديل
  Future<void> _navigateToEditPage(
    BuildContext context,
    ItemModel product,
    ProductsListController controller,
  ) async {
    try {
      final result = await Get.to(
        () => EditProductPage(product: product),
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 400),
      );
      
      if (result == true) {
        controller.refreshProducts();
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'حدث خطأ في فتح صفحة التعديل',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.error_outline, color: Colors.white),
      );
    }
  }
} 