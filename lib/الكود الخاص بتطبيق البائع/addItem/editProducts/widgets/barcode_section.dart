import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/edit_product_controller.dart';

class BarcodeSection extends StatelessWidget {
  const BarcodeSection({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      final controller = Get.find<EditProductController>();
      
      if (!controller.isProductLoaded.value) {
        return const Center(child: CircularProgressIndicator());
      }
      
      return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الباركود',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // الباركود الرئيسي
        TextFormField(
          controller: controller.mainBarcodeController,
          decoration: InputDecoration(
            labelText: 'الباركود الرئيسي للمنتج',
            hintText: 'أدخل الباركود الرئيسي',
            prefixIcon: const Icon(Icons.qr_code_scanner),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        
        // باركود المنتج
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller.barcodeController,
                decoration: InputDecoration(
                  labelText: 'باركود المنتج',
                  hintText: 'أدخل الباركود',
                  prefixIcon: const Icon(Icons.qr_code),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // باركودات إضافية
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'باركودات إضافية',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              onPressed: () => _showAddBarcodeDialog(context, controller),
              icon: const Icon(Icons.add_circle, color: Colors.green),
              tooltip: 'إضافة باركود',
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        Obx(() {
          if (controller.productBarcodes.isEmpty) {
            return Card(
              color: Colors.grey[100],
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'لا توجد باركودات إضافية',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            );
          }
          
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: controller.productBarcodes.asMap().entries.map((entry) {
                  final index = entry.key;
                  final barcode = entry.value;
                  return Chip(
                    label: Text(barcode),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => controller.removeBarcode(index),
                    backgroundColor: Colors.blue[50],
                    deleteIconColor: Colors.red,
                  );
                }).toList(),
              ),
            ),
          );
        }),
      ],
    );
    } catch (e) {
      return const Center(child: Text('خطأ في تحميل البيانات'));
    }
  }
  
  void _showAddBarcodeDialog(BuildContext context, EditProductController controller) {
    final textController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة باركود'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: 'الباركود',
            hintText: 'أدخل الباركود',
            prefixIcon: Icon(Icons.qr_code),
          ),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final barcode = textController.text.trim();
              if (barcode.isNotEmpty) {
                controller.addBarcode(barcode);
                Navigator.pop(context);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }
} 