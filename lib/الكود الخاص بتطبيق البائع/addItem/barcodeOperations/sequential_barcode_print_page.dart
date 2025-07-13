import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../Model/model_item.dart';
import 'controllers/sequential_barcode_print_controller.dart';

class SequentialBarcodePrintPage extends StatelessWidget {
  const SequentialBarcodePrintPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SequentialBarcodePrintController());
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('طباعة باركود تسلسلي'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            // شريط البحث
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
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
                  const Icon(Icons.search, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: controller.searchController,
                      decoration: const InputDecoration(
                        hintText: 'ابحث عن منتج...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      onChanged: controller.onSearchChanged,
                    ),
                  ),
                  Obx(() => controller.isSearching.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: controller.clearSearch,
                        ),
                  ),
                ],
              ),
            ),
            
            // قائمة المنتجات
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.blue),
                  );
                }
                
                if (controller.products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد منتجات',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.products.length,
                  itemBuilder: (context, index) {
                    final product = controller.products[index];
                    return _buildProductCard(product, controller);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(ItemModel product, SequentialBarcodePrintController controller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showPrintDialog(product, controller),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // صورة المنتج
              Container(
                width: 70,
                height: 70,
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
                              size: 30,
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.inventory_2,
                        color: Colors.grey[400],
                        size: 30,
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
                    Text(
                      'الكمية: ${product.quantity ?? 0}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
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
              
              // أيقونة الطباعة
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.print,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrintDialog(ItemModel product, SequentialBarcodePrintController controller) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.format_list_numbered, color: Colors.blue[700]),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'طباعة باركود تسلسلي',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // معلومات المنتج
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('السعر: ${product.price.toStringAsFixed(2)} د.ل'),
                  Text('الكمية المتوفرة: ${product.quantity ?? 0}'),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // إدخال عدد الباركودات
            const Text(
              'عدد الباركودات التسلسلية:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'أدخل العدد المطلوب',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.numbers),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // ملاحظة مهمة
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'سيتم الطباعة أولاً ثم حفظ الباركودات في قاعدة البيانات',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          Obx(() => ElevatedButton.icon(
            onPressed: controller.isPrinting.value 
                ? null 
                : () => controller.printSequentialBarcodes(product),
            icon: controller.isPrinting.value
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.print, color: Colors.white),
            label: Text(
              controller.isPrinting.value ? 'جاري الطباعة...' : 'طباعة',
              style: const TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
          )),
        ],
      ),
    );
  }
} 