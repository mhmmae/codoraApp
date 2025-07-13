import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/main_barcode_edit_controller.dart';

class MainBarcodeEditPage extends StatelessWidget {
  const MainBarcodeEditPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MainBarcodeEditController());
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل باركود رئيسي'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.red.withOpacity(0.1),
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
                        hintText: 'ابحث عن منتج لتعديل باركوده...',
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
                    child: CircularProgressIndicator(color: Colors.red),
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

  Widget _buildProductCard(dynamic product, MainBarcodeEditController controller) {
    final bool hasBarcode = product.mainProductBarcode != null && product.mainProductBarcode!.isNotEmpty;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showEditDialog(product, controller),
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
                        color: Colors.red[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (hasBarcode) 
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
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          'لا يوجد باركود رئيسي',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // أيقونة التعديل
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  hasBarcode ? Icons.edit : Icons.add,
                  color: Colors.red,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(dynamic product, MainBarcodeEditController controller) {
    controller.barcodeController.text = product.mainProductBarcode ?? '';
    
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.edit, color: Colors.red[700]),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'تعديل الباركود الرئيسي',
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
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // إدخال الباركود الجديد
            const Text(
              'الباركود الرئيسي الجديد:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.barcodeController,
              decoration: InputDecoration(
                hintText: 'أدخل الباركود الرئيسي الجديد',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.qr_code),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: () => controller.scanBarcode(),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // أزرار إضافية
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => controller.generateRandomBarcode(),
                    icon: const Icon(Icons.shuffle, size: 16),
                    label: const Text('توليد عشوائي', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => controller.clearBarcode(),
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('مسح', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // ملاحظة
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_outlined, color: Colors.red[700], size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'تغيير الباركود الرئيسي قد يؤثر على العمليات الحالية',
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
            onPressed: controller.isUpdating.value 
                ? null 
                : () => controller.updateBarcode(product),
            icon: controller.isUpdating.value
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save, color: Colors.white),
            label: Text(
              controller.isUpdating.value ? 'جاري التحديث...' : 'حفظ',
              style: const TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
          )),
        ],
      ),
    );
  }
}
