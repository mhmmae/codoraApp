import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../Model/model_item.dart';
import 'controllers/products_list_controller.dart';
import 'edit_product_page.dart';

class ProductsListForEditPage extends StatelessWidget {
  const ProductsListForEditPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ProductsListController controller = Get.put(ProductsListController());
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: controller.refreshProducts,
        color: Colors.amber[600],
        child: CustomScrollView(
          slivers: [
            // AppBar مخصص ومتحرك
            _buildAnimatedAppBar(controller),
            
            // قائمة المنتجات
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: Obx(() {
                if (controller.isLoading.value) {
                  return _buildLoadingState();
                }
                
                if (controller.filteredProducts.isEmpty) {
                  return SliverFillRemaining(
                    child: _buildEmptyState(controller),
                  );
                }
                
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = controller.filteredProducts[index];
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _buildProductCard(context, product, index),
                          ),
                        ),
                      );
                    },
                    childCount: controller.filteredProducts.length,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
      
      // لا نحتاج زر إضافة منتج في صفحة التعديل
    );
  }
  
  // بناء AppBar متحرك
  Widget _buildAnimatedAppBar(ProductsListController controller) {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: true,
      pinned: true,
      backgroundColor: Colors.amber[600],
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final double top = constraints.biggest.height;
          final double titleOpacity = (top - kToolbarHeight - 50) / 100;
          
          return FlexibleSpaceBar(
            centerTitle: true,
            title: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: titleOpacity.clamp(0.0, 1.0),
              child: Text(
                'إدارة المنتجات',
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.05,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                // خلفية متدرجة
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.amber[600]!,
                        Colors.orange[600]!,
                      ],
                    ),
                  ),
                ),
                
                // رسومات ديكورية
                Positioned(
                  right: -50,
                  top: -50,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(seconds: 2),
                    builder: (context, value, child) {
                      return Transform.rotate(
                        angle: value * 0.5,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // معلومات إحصائية
                Positioned(
                  bottom: 50,
                  left: 20,
                  right: 20,
                  child: Column(
                    children: [
                      Obx(() => TweenAnimationBuilder<int>(
                        tween: IntTween(
                          begin: 0,
                          end: controller.allProducts.length,
                        ),
                        duration: const Duration(seconds: 1),
                        builder: (context, value, child) {
                          return Text(
                            '$value',
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width * 0.08,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        },
                      )),
                      Text(
                        'منتج في المتجر',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.04,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      
      // أزرار الإجراءات
      actions: [
        // زر البحث
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 500),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () => _showAnimatedSearchDialog(context, controller),
              ),
            );
          },
        ),
        
        // زر الفلترة
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 700),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: IconButton(
                icon: const Icon(Icons.filter_list, color: Colors.white),
                onPressed: () => _showFilterBottomSheet(context, controller),
              ),
            );
          },
        ),
      ],
    );
  }
  

  
  // بناء حالة التحميل
  Widget _buildLoadingState() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildShimmerCard(),
        childCount: 5,
      ),
    );
  }
  
  // بناء كرت المنتج
  Widget _buildProductCard(BuildContext context, ItemModel product, int index) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              onTap: () {
                Get.to(
                  () => EditProductPage(product: product),
                  transition: Transition.rightToLeft,
                  duration: const Duration(milliseconds: 500),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // محتوى الكرت الرئيسي
                    Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      child: Row(
                        children: [
                          // صورة المنتج
                          Hero(
                            tag: 'product_${product.id}',
                            child: _buildProductImage(product, isSmallScreen),
                          ),
                          SizedBox(width: isSmallScreen ? 12 : 16),
                          
                          // معلومات المنتج
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // اسم المنتج
                                Text(
                                  product.name,
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                
                                // الوصف
                                if (product.description != null)
                                  Text(
                                    product.description!,
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 11 : 12,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                
                                const SizedBox(height: 8),
                                
                                // السعر
                                _buildPriceWidget(product, isSmallScreen),
                                
                                const SizedBox(height: 8),
                                
                                // معلومات إضافية
                                _buildProductInfo(product, isSmallScreen),
                              ],
                            ),
                          ),
                          
                          // أيقونة التعديل
                          SizedBox(width: isSmallScreen ? 8 : 16),
                          _buildEditIcon(isSmallScreen),
                        ],
                      ),
                    ),
                    
                    // شريط الحالة السفلي
                    _buildStatusBar(product, isSmallScreen),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  // بناء صورة المنتج
  Widget _buildProductImage(ItemModel product, bool isSmallScreen) {
    final size = isSmallScreen ? 80.0 : 100.0;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            // الصورة
            product.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: product.imageUrl!,
                    fit: BoxFit.cover,
                    width: size,
                    height: size,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.image_not_supported,
                        size: size * 0.4,
                        color: Colors.grey[400],
                      ),
                    ),
                  )
                : Container(
                    color: Colors.grey[200],
                    child: Icon(
                      Icons.inventory_2,
                      size: size * 0.4,
                      color: Colors.grey[400],
                    ),
                  ),
            
            // مؤشر الصور المتعددة
            if (product.manyImages.isNotEmpty)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 4 : 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo_library, size: isSmallScreen ? 10 : 12, color: Colors.white),
                      const SizedBox(width: 2),
                      Text(
                        '${product.manyImages.length + 1}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 10 : 11,
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
                  padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow,
                    size: isSmallScreen ? 12 : 14,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  // بناء widget السعر مع مرونة أكبر
  Widget _buildPriceWidget(ItemModel product, bool isSmallScreen) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        // السعر الأساسي
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 6 : 8,
            vertical: isSmallScreen ? 2 : 4,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green[400]!, Colors.green[600]!],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.attach_money,
                size: isSmallScreen ? 10 : 12,
                color: Colors.white,
              ),
              Flexible(
                child: Text(
                  product.price.toStringAsFixed(0),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 10 : 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        
        // سعر التكلفة
        if (product.costPrice != null)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 4 : 6,
              vertical: isSmallScreen ? 2 : 3,
            ),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'تكلفة: ${product.costPrice!.toStringAsFixed(0)}',
              style: TextStyle(
                color: Colors.orange[800],
                fontSize: isSmallScreen ? 9 : 10,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
  
  // بناء معلومات المنتج
  Widget _buildProductInfo(ItemModel product, bool isSmallScreen) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        // الكمية
        if (product.quantity != null)
          _buildInfoChip(
            icon: Icons.inventory,
            label: '${product.quantity}',
            color: _getQuantityColor(product.quantity!),
            isSmallScreen: isSmallScreen,
          ),
        
        // الباركود
        if (product.productBarcode != null && product.productBarcode!.isNotEmpty)
          _buildInfoChip(
            icon: Icons.qr_code,
            label: 'باركود',
            color: Colors.blue,
            isSmallScreen: isSmallScreen,
          ),
        
        // نوع المنتج
        if (product.itemCondition != null)
          _buildInfoChip(
            icon: Icons.category,
            label: product.itemCondition == 'original' ? 'أصلي' : 'تجاري',
            color: product.itemCondition == 'original' ? Colors.purple : Colors.teal,
            isSmallScreen: isSmallScreen,
          ),
      ],
    );
  }
  
  // بناء chip المعلومات
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
    required bool isSmallScreen,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 4 : 6,
        vertical: isSmallScreen ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isSmallScreen ? 10 : 12, color: color),
          const SizedBox(width: 2),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isSmallScreen ? 9 : 10,
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
  Widget _buildEditIcon(bool isSmallScreen) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
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
            child: Icon(
              Icons.edit_rounded,
              color: Colors.white,
              size: isSmallScreen ? 18 : 20,
            ),
          ),
        );
      },
    );
  }
  
  // بناء شريط الحالة
  Widget _buildStatusBar(ItemModel product, bool isSmallScreen) {
    // حساب نسبة الربح
    double profitPercentage = 0;
    if (product.costPrice != null && product.costPrice! > 0) {
      profitPercentage = ((product.price - product.costPrice!) / product.costPrice!) * 100;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 16,
        vertical: isSmallScreen ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          // القسم
          if (product.mainCategoryNameAr != null)
            Expanded(
              flex: 3,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.folder,
                    size: isSmallScreen ? 12 : 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      product.mainCategoryNameAr!,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 10 : 11,
                        color: Colors.grey[700],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          
          // نسبة الربح
          if (product.costPrice != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 6 : 8,
                vertical: isSmallScreen ? 2 : 3,
              ),
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
                    size: isSmallScreen ? 10 : 12,
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
                      fontSize: isSmallScreen ? 9 : 10,
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
        height: 120,
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
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.amber[50],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.inventory_2_outlined,
                          size: 60,
                          color: Colors.amber[600],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  controller.searchText.value.isEmpty
                      ? 'لا توجد منتجات حالياً'
                      : 'لا توجد نتائج للبحث',
                  style: TextStyle(
                    fontSize: 18,
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
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                if (controller.searchText.value.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: controller.clearSearch,
                    icon: const Icon(Icons.clear, size: 18),
                    label: const Text('مسح البحث', style: TextStyle(fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
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
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
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
                        Icon(Icons.search, color: Colors.amber[600], size: 24),
                        const SizedBox(width: 10),
                        const Text(
                          'البحث عن منتج',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller.searchController,
                      onChanged: controller.searchProducts,
                      autofocus: true,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'اسم المنتج، الباركود، أو الوصف...',
                        hintStyle: const TextStyle(fontSize: 13),
                        filled: true,
                        fillColor: Colors.grey[100],
                        prefixIcon: Icon(Icons.search, color: Colors.amber[600], size: 20),
                        suffixIcon: controller.searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('إغلاق', style: TextStyle(fontSize: 14)),
                        ),
                        const SizedBox(width: 10),
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
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                          child: const Text('بحث', style: TextStyle(fontSize: 14)),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
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
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // مقبض السحب
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // عنوان
                    Row(
                      children: [
                        Icon(Icons.filter_list, color: Colors.amber[600], size: isSmallScreen ? 20 : 24),
                        const SizedBox(width: 10),
                        Text(
                          'ترتيب وفلترة',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // خيارات الترتيب
                    Text(
                      'ترتيب حسب:',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
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
                          isSmallScreen: isSmallScreen,
                          onTap: () {
                            controller.changeSortType(SortType.alphabetical);
                            Navigator.pop(context);
                          },
                        ),
                        _buildSortChip(
                          label: 'الأحدث',
                          icon: Icons.access_time,
                          isSelected: controller.currentSortType.value == SortType.newest,
                          isSmallScreen: isSmallScreen,
                          onTap: () {
                            controller.changeSortType(SortType.newest);
                            Navigator.pop(context);
                          },
                        ),
                        _buildSortChip(
                          label: 'السعر',
                          icon: Icons.attach_money,
                          isSelected: controller.currentSortType.value == SortType.price,
                          isSmallScreen: isSmallScreen,
                          onTap: () {
                            controller.changeSortType(SortType.price);
                            Navigator.pop(context);
                          },
                        ),
                        _buildSortChip(
                          label: 'الكمية',
                          icon: Icons.inventory,
                          isSelected: controller.currentSortType.value == SortType.quantity,
                          isSmallScreen: isSmallScreen,
                          onTap: () {
                            controller.changeSortType(SortType.quantity);
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    )),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  // بناء chip للترتيب
  Widget _buildSortChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required bool isSmallScreen,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: isSelected ? 1.0 : 0.9, end: isSelected ? 1.05 : 1.0),
      duration: const Duration(milliseconds: 200),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 16,
                  vertical: isSmallScreen ? 6 : 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.amber[600] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.amber[700]! : Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: isSmallScreen ? 16 : 18,
                      color: isSelected ? Colors.white : Colors.grey[700],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
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
} 