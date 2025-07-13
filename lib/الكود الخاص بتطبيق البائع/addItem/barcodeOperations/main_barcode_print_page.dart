import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/main_barcode_print_controller.dart';

class MainBarcodePrintPage extends StatelessWidget {
  const MainBarcodePrintPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MainBarcodePrintController());
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('طباعة باركود رئيسي'),
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
                        hintText: 'ابحث عن منتج له باركود رئيسي...',
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
                    child: CircularProgressIndicator(color: Colors.green),
                  );
                }
                
                if (controller.products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_scanner,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد منتجات لها باركود رئيسي',
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

  Widget _buildProductCard(dynamic product, MainBarcodePrintController controller) {
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Text(
                        'الباركود: ${product.mainProductBarcode}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green[800],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              
              // أيقونة الطباعة
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.print,
                  color: Colors.green,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrintDialog(dynamic product, MainBarcodePrintController controller) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.qr_code, color: Colors.green[700]),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'طباعة باركود رئيسي',
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
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Text(
                      'الباركود الرئيسي: ${product.mainProductBarcode}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // إدخال عدد النسخ
            const Text(
              'عدد النسخ للطباعة:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'أدخل عدد النسخ (افتراضي: 1)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.content_copy),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // ملاحظة
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.green[700], size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'سيتم طباعة الباركود الرئيسي الموجود مع المنتج',
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
                : () => controller.printMainBarcode(product),
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
              backgroundColor: Colors.green,
            ),
          )),
        ],
      ),
    );
  }
}
