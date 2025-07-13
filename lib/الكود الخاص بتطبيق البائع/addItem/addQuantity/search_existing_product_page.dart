import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../Model/model_item.dart';
import 'controllers/search_existing_product_controller.dart';
import 'add_quantity_page.dart';

class SearchExistingProductPage extends StatelessWidget {
  const SearchExistingProductPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SearchExistingProductController());
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('البحث عن منتج موجود'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // البحث المضغوط
              _buildCompactSearchSection(controller),
              
              const SizedBox(height: 12),
              
              // قسم الترتيب
              _buildSortSection(controller),
              
              const SizedBox(height: 16),
              
              // نتائج البحث
              Expanded(
                child: Obx(() {
                  if (controller.isSearching.value) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.green),
                          SizedBox(height: 16),
                          Text('جاري البحث...'),
                        ],
                      ),
                    );
                  }
                  
                  if (controller.searchResults.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد منتجات مطابقة',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'جرب البحث بكلمة أخرى أو باركود مختلف',
                            style: TextStyle(
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    itemCount: controller.searchResults.length,
                    itemBuilder: (context, index) {
                      final product = controller.searchResults[index];
                      return _buildProductCard(product, controller, index);
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

  Widget _buildCompactSearchSection(SearchExistingProductController controller) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller.searchController,
              decoration: const InputDecoration(
                hintText: 'ابحث بالاسم أو الباركود',
                border: InputBorder.none,
                hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              style: const TextStyle(fontSize: 14),
              onChanged: controller.onSearchChanged,
            ),
          ),
          // أيقونة الكاميرا المميزة
          Container(
            margin: const EdgeInsets.only(left: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: controller.scanBarcode,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Obx(() => controller.isSearching.value
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                  onPressed: controller.clearSearch,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortSection(SearchExistingProductController controller) {
    return SizedBox(
      height: 50,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildSortChip('أبجدي', SortType.alphabetical, controller),
            _buildSortChip('الأعلى سعراً', SortType.sellPrice, controller),
            _buildSortChip('الأقل سعراً', SortType.costPrice, controller),
            _buildSortChip('أكثر كمية', SortType.quantity, controller),
            _buildSortChip('عاجل', SortType.urgent, controller),
            _buildSortChip('الأحدث', SortType.newest, controller),
            _buildSortChip('نفدت الكمية', SortType.lowestStock, controller),
          ],
        ),
      ),
    );
  }

  Widget _buildSortChip(String label, SortType sortType, SearchExistingProductController controller) {
    return Obx(() {
      final isSelected = controller.currentSortType.value == sortType;
      return Container(
        margin: const EdgeInsets.only(right: 8),
        child: FilterChip(
          label: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          selected: isSelected,
          onSelected: (selected) {
            controller.changeSortType(sortType);
          },
          backgroundColor: Colors.grey[200],
          selectedColor: Colors.green,
          checkmarkColor: Colors.white,
          elevation: isSelected ? 4 : 2,
        ),
      );
    });
  }

  Widget _buildProductCard(ItemModel product, SearchExistingProductController controller, int index) {
    final quantity = product.quantity ?? 0;
    final isUrgent = quantity <= 5;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isUrgent ? 6 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isUrgent ? BorderSide(
          color: quantity == 0 ? Colors.red : Colors.orange,
          width: 2,
        ) : BorderSide.none,
      ),
      child: InkWell(
        onTap: () async {
          print('🔄 الانتقال لصفحة إضافة الكمية...');
          try {
            final result = await Get.to(() => AddQuantityPage(product: product));
            print('🔄 العودة من صفحة إضافة الكمية - النتيجة: $result');
            
            if (result == true) {
              print('✅ تم إضافة الكمية بنجاح - تحديث البيانات...');
              await controller.refreshData();
              print('✅ تم تحديث البيانات بنجاح');
            } else {
              print('⚠️ لم يتم إضافة كمية أو تم الإلغاء');
            }
          } catch (e) {
            print('❌ خطأ في التنقل أو التحديث: $e');
            Get.snackbar(
              'خطأ',
              'حدث خطأ في العملية',
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: isUrgent ? BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                (quantity == 0 ? Colors.red : Colors.orange).withOpacity(0.05),
                Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ) : null,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // مؤشر الأولوية للمنتجات العاجلة
                if (isUrgent) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: quantity == 0 ? Colors.red : Colors.orange,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          quantity == 0 ? Icons.error : Icons.warning,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          quantity == 0 ? 'نفدت الكمية - يتطلب إعادة تعبئة فورية!' : 'كمية قليلة - يتطلب إعادة تعبئة',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // المحتوى الأساسي
                Row(
                  children: [
                    // صورة المنتج
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[200],
                      ),
                      child: product.imageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                product.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey[400],
                                    size: 40,
                                  );
                                },
                              ),
                            )
                          : Icon(
                              Icons.inventory_2,
                              color: Colors.grey[400],
                              size: 40,
                            ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // معلومات المنتج
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'السعر: ${product.price.toStringAsFixed(2)} د.ل',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'الكمية المتبقية: ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              // Animation للكمية
                              _buildAnimatedQuantityBadge(quantity, index),
                              const SizedBox(width: 8),
                              Text(
                                _getQuantityStatus(quantity),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _getQuantityColor(quantity),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          if (product.mainProductBarcode != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'الباركود: ${product.mainProductBarcode}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // سهم للانتقال
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey[400],
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedQuantityBadge(int quantity, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800 + (index * 100)),
      curve: Curves.elasticOut,
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: TweenAnimationBuilder<Color?>(
            duration: const Duration(milliseconds: 1000),
            tween: ColorTween(
              begin: Colors.grey,
              end: _getQuantityColor(quantity),
            ),
            builder: (context, color, child) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color!.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 1200 + (index * 150)),
                      curve: Curves.bounceOut,
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      builder: (context, rotation, child) {
                        return Transform.rotate(
                          angle: rotation * 2 * 3.14159,
                          child: Text(
                            _getQuantityIcon(quantity),
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [color, color.withOpacity(0.7)],
                      ).createShader(bounds),
                      child: Text(
                        '$quantity',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Color _getQuantityColor(int quantity) {
    if (quantity == 0) {
      return Colors.red;
    } else if (quantity < 5) {
      return Colors.red[600]!;
    } else if (quantity < 20) {
      return Colors.orange[600]!;
    } else {
      return Colors.green[600]!;
    }
  }
  
  String _getQuantityIcon(int quantity) {
    if (quantity == 0) {
      return '❌';
    } else if (quantity < 5) {
      return '⚠️';
    } else if (quantity < 20) {
      return '🟡';
    } else {
      return '✅';
    }
  }
  
  String _getQuantityStatus(int quantity) {
    if (quantity == 0) {
      return 'نفدت';
    } else if (quantity < 5) {
      return 'قليلة جداً';
    } else if (quantity < 20) {
      return 'متوسطة';
    } else {
      return 'جيدة';
    }
  }
} 