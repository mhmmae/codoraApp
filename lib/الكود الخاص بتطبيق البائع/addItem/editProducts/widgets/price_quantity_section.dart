import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/edit_product_controller.dart';

class PriceQuantitySection extends StatelessWidget {
  const PriceQuantitySection({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      final controller = Get.find<EditProductController>();
      
      // التأكد من أن الكونترولر جاهز
      if (!controller.isProductLoaded.value) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }
      
      return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'السعر والكمية',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            // سعر البيع
            Expanded(
              child: TextFormField(
                controller: controller.priceController,
                decoration: InputDecoration(
                  labelText: 'سعر البيع *',
                  hintText: '0.00',
                  prefixIcon: const Icon(Icons.attach_money),
                  suffixText: 'ريال',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(width: 16),
            
            // سعر التكلفة
            Expanded(
              child: TextFormField(
                controller: controller.costPriceController,
                decoration: InputDecoration(
                  labelText: 'سعر التكلفة',
                  hintText: '0.00',
                  prefixIcon: const Icon(Icons.money_off),
                  suffixText: 'ريال',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // الكمية
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller.quantityController,
                decoration: InputDecoration(
                  labelText: 'الكمية المتوفرة',
                  hintText: '0',
                  prefixIcon: const Icon(Icons.inventory),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(width: 16),
            
            // درجة الجودة
            Expanded(
              child: Obx(() => DropdownButtonFormField<int>(
                value: controller.selectedQualityGrade.value == 0 
                    ? null 
                    : controller.selectedQualityGrade.value,
                decoration: InputDecoration(
                  labelText: 'درجة الجودة',
                  prefixIcon: const Icon(Icons.star),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                hint: const Text('اختر الدرجة'),
                items: List.generate(10, (index) {
                  final grade = index + 1;
                  return DropdownMenuItem(
                    value: grade,
                    child: Row(
                      children: [
                        Text('$grade'),
                        const SizedBox(width: 4),
                        ...List.generate(
                          grade ~/ 2,
                          (i) => const Icon(Icons.star, size: 12, color: Colors.amber),
                        ),
                        if (grade % 2 == 1)
                          const Icon(Icons.star_half, size: 12, color: Colors.amber),
                      ],
                    ),
                  );
                }),
                onChanged: (value) {
                  controller.selectedQualityGrade.value = value ?? 0;
                },
              )),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // معلومات الربح المتوقع
        Obx(() {
          final price = double.tryParse(controller.priceController.text) ?? 0;
          final cost = double.tryParse(controller.costPriceController.text) ?? 0;
          final profit = price - cost;
          final profitPercentage = cost > 0 ? (profit / cost * 100) : 0;
          
          if (cost > 0) {
            return Card(
              color: profit > 0 ? Colors.green[50] : Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      profit > 0 ? Icons.trending_up : Icons.trending_down,
                      color: profit > 0 ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الربح المتوقع: ${profit.toStringAsFixed(2)} ريال',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: profit > 0 ? Colors.green[700] : Colors.red[700],
                            ),
                          ),
                          Text(
                            'نسبة الربح: ${profitPercentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: profit > 0 ? Colors.green[600] : Colors.red[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          
          return const SizedBox();
        }),
      ],
    );
    } catch (e) {
      return const Center(
        child: Text('خطأ في تحميل البيانات'),
      );
    }
  }
} 