import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'controllers/sequential_barcode_scan_controller.dart';

class SequentialBarcodeScanPage extends StatelessWidget {
  const SequentialBarcodeScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SequentialBarcodeScanController());
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة باركودات بالمسح'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          Obx(() => Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.qr_code_scanner, size: 16, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  '${controller.scannedBarcodes.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
      body: Obx(() {
        if (controller.selectedProduct.value == null) {
          return _buildProductSelection(controller);
        } else {
          return _buildScanningView(controller);
        }
      }),
    );
  }

  Widget _buildProductSelection(SequentialBarcodeScanController controller) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.orange.withOpacity(0.1),
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
                      hintText: 'ابحث عن منتج لإضافة باركودات له...',
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
                  child: CircularProgressIndicator(color: Colors.orange),
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
    );
  }

  Widget _buildProductCard(dynamic product, SequentialBarcodeScanController controller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => controller.selectProduct(product),
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
                        color: Colors.orange[700],
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
                  ],
                ),
              ),
              
              // أيقونة الاختيار
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.qr_code_scanner,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanningView(SequentialBarcodeScanController controller) {
    return Column(
      children: [
        // معلومات المنتج المختار
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            border: Border(
              bottom: BorderSide(color: Colors.orange[200]!),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المنتج المختار:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                      ),
                    ),
                    Text(
                      controller.selectedProduct.value!.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => controller.resetSelection(),
                icon: const Icon(Icons.change_circle, size: 16),
                label: const Text('تغيير', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.orange[700],
                ),
              ),
            ],
          ),
        ),
        
        // منطقة المسح
        Expanded(
          flex: 3,
          child: SizedBox(
            width: double.infinity,
            child: MobileScanner(
              controller: controller.scannerController,
              onDetect: controller.onBarcodeDetected,
            ),
          ),
        ),
        
        // الباركودات الممسوحة
        Expanded(
          flex: 2,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Column(
              children: [
                // عنوان القسم
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.list_alt, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      Text(
                        'الباركودات الممسوحة',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                      const Spacer(),
                      Obx(() => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${controller.scannedBarcodes.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
                
                // قائمة الباركودات
                Expanded(
                  child: Obx(() {
                    if (controller.scannedBarcodes.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.qr_code_2,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'ابدأ بمسح الباركودات',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: controller.scannedBarcodes.length,
                      itemBuilder: (context, index) {
                        final barcode = controller.scannedBarcodes[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.qr_code, color: Colors.orange[600], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  barcode,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red[400], size: 20),
                                onPressed: () => controller.removeBarcode(barcode),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
        
        // أزرار التحكم
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => controller.resetSelection(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('رجوع'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Obx(() => ElevatedButton.icon(
                  onPressed: controller.scannedBarcodes.isEmpty || controller.isSaving.value
                      ? null
                      : controller.saveBarcodes,
                  icon: controller.isSaving.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save, color: Colors.white),
                  label: Text(
                    controller.isSaving.value 
                        ? 'جاري الحفظ...' 
                        : 'حفظ (${controller.scannedBarcodes.length})',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                )),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
