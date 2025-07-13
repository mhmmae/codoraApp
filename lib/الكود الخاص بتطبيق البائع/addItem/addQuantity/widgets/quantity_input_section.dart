import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controllers/add_quantity_controller.dart';

class QuantityInputSection extends StatelessWidget {
  final AddQuantityController controller;
  
  const QuantityInputSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عنوان القسم
            Row(
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: Colors.green[700],
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'إضافة كمية جديدة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // حقل إدخال الكمية
            Row(
              children: [
                // أزرار التحكم
                Column(
                  children: [
                    // زر الزيادة
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green, width: 1),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.add, color: Colors.green),
                        onPressed: _incrementQuantity,
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // زر النقصان
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red, width: 1),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.remove, color: Colors.red),
                        onPressed: _decrementQuantity,
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(width: 16),
                
                // حقل الإدخال
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الكمية المراد إضافتها',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: controller.quantityController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        decoration: InputDecoration(
                          hintText: 'ادخل الكمية',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.green),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.green, width: 2),
                          ),
                          suffixIcon: const Icon(Icons.inventory_2, color: Colors.green),
                          prefixText: '+ ',
                          prefixStyle: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        onChanged: controller.updateQuantity,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // معلومات الكمية الجديدة
            Obx(() => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue, width: 1),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue[700],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الكمية بعد الإضافة',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(controller.product.quantity ?? 0)} + ${controller.addedQuantity.value} = ${(controller.product.quantity ?? 0) + controller.addedQuantity.value}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
            
            const SizedBox(height: 12),
            
            // أزرار سريعة للكميات الشائعة
            Text(
              'كميات سريعة',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [1, 5, 10, 25, 50, 100].map((quantity) => 
                _buildQuickQuantityButton(quantity)
              ).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickQuantityButton(int quantity) {
    return Obx(() => InkWell(
      onTap: () => _setQuantity(quantity),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: controller.addedQuantity.value == quantity 
              ? Colors.green 
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: controller.addedQuantity.value == quantity 
                ? Colors.green 
                : Colors.grey,
            width: 1,
          ),
        ),
        child: Text(
          '$quantity',
          style: TextStyle(
            color: controller.addedQuantity.value == quantity 
                ? Colors.white 
                : Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ));
  }

  void _incrementQuantity() {
    final currentValue = int.tryParse(controller.quantityController.text) ?? 0;
    final newValue = currentValue + 1;
    controller.quantityController.text = newValue.toString();
    controller.updateQuantity(newValue.toString());
  }

  void _decrementQuantity() {
    final currentValue = int.tryParse(controller.quantityController.text) ?? 0;
    if (currentValue > 0) {
      final newValue = currentValue - 1;
      controller.quantityController.text = newValue.toString();
      controller.updateQuantity(newValue.toString());
    }
  }

  void _setQuantity(int quantity) {
    controller.quantityController.text = quantity.toString();
    controller.updateQuantity(quantity.toString());
  }
} 