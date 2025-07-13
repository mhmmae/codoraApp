import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../Model/model_item.dart';
import 'controllers/add_quantity_controller.dart';
import 'widgets/barcode_generation_options.dart';
import 'widgets/product_info_card.dart';
import 'widgets/quantity_input_section.dart';

class AddQuantityPage extends StatelessWidget {
  final ItemModel product;
  final VoidCallback? onSuccess;
  
  const AddQuantityPage({
    super.key,
    required this.product,
    this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AddQuantityController(
      product: product,
      onSuccess: () {
        print('🎉 تم استدعاء callback النجاح');
        onSuccess?.call();
        Navigator.of(context).pop(true);
      },
    ));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة كمية منتج'),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // معلومات المنتج
              ProductInfoCard(product: product),
              
              const SizedBox(height: 20),
              
              // قسم إدخال الكمية
              QuantityInputSection(controller: controller),
              
              const SizedBox(height: 20),
              
              // خيارات إنتاج الباركود
              BarcodeGenerationOptions(controller: controller),
              
              const SizedBox(height: 30),
              
              // أزرار العمل
              _buildActionButtons(controller, context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(AddQuantityController controller, BuildContext context) {
    return Column(
      children: [
        // زر إضافة الكمية
        SizedBox(
          width: double.infinity,
          height: 50,
          child: Obx(() => ElevatedButton.icon(
            onPressed: controller.isLoading.value ? null : controller.addQuantity,
            icon: controller.isLoading.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.add_circle, color: Colors.white),
            label: Text(
              controller.isLoading.value ? 'جاري الإضافة...' : 'إضافة الكمية',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          )),
        ),
        
        const SizedBox(height: 12),
        
        // زر الإلغاء
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () {
              print('🔙 إلغاء العملية والعودة للصفحة السابقة...');
              Get.back(result: false);
            },
            icon: const Icon(Icons.cancel, color: Colors.grey),
            label: const Text(
              'إلغاء',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.grey),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
} 