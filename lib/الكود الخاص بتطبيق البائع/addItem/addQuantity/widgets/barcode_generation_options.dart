import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/add_quantity_controller.dart';

class BarcodeGenerationOptions extends StatelessWidget {
  final AddQuantityController controller;
  
  const BarcodeGenerationOptions({
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
                  Icons.qr_code_2,
                  color: Colors.purple[700],
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'خيارات الباركود والطباعة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[800],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // خيار الباركود التسلسلي
            _buildSequentialBarcodeOption(),
            
            const SizedBox(height: 16),
            
            // خيار طباعة الباركود الرئيسي
            _buildMainBarcodeOption(),
            
            const SizedBox(height: 16),
            
            // أزرار المعاينة
            _buildPreviewButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildSequentialBarcodeOption() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // خيار تفعيل الباركود التسلسلي
          Obx(() => Row(
            children: [
              Checkbox(
                value: controller.generateSequentialBarcodes.value,
                onChanged: (value) => controller.toggleSequentialBarcodes(value ?? false),
                activeColor: Colors.purple,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إنشاء باركودات تسلسلية',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.purple[800],
                      ),
                    ),
                    Text(
                      'سيتم إنشاء باركود فريد لكل قطعة منتج',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )),
          
          // معلومات إضافية عند التفعيل
          Obx(() => controller.generateSequentialBarcodes.value 
              ? Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[700],
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'سيتم إنشاء ${controller.addedQuantity.value} باركود تسلسلي فريد وطباعتها',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildMainBarcodeOption() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // خيار تفعيل طباعة الباركود الرئيسي
          Obx(() => Row(
            children: [
              Checkbox(
                value: controller.printMainBarcode.value,
                onChanged: controller.product.mainProductBarcode != null 
                    ? (value) => controller.toggleMainBarcodePrinting(value ?? false)
                    : null,
                activeColor: Colors.orange,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'طباعة الباركود الرئيسي',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: controller.product.mainProductBarcode != null
                            ? Colors.orange[800]
                            : Colors.grey,
                      ),
                    ),
                    Text(
                      controller.product.mainProductBarcode != null
                          ? 'طباعة الباركود الرئيسي للمنتج'
                          : 'لا يوجد باركود رئيسي لهذا المنتج',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )),
          
          // خيارات إضافية عند التفعيل
          Obx(() => controller.printMainBarcode.value && controller.product.mainProductBarcode != null
              ? Column(
                  children: [
                    const SizedBox(height: 8),
                    
                    // عدد النسخ
                    Row(
                      children: [
                        Text(
                          'عدد النسخ:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[700],
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // أزرار التحكم في العدد
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // زر النقصان
                              InkWell(
                                onTap: () {
                                  if (controller.mainBarcodePrintCount.value > 1) {
                                    controller.updateMainBarcodePrintCount(
                                      controller.mainBarcodePrintCount.value - 1
                                    );
                                  }
                                },
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  bottomLeft: Radius.circular(8),
                                ),
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      bottomLeft: Radius.circular(8),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.remove,
                                    size: 16,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                              
                              // العدد
                              Container(
                                width: 50,
                                height: 30,
                                color: Colors.white,
                                child: Center(
                                  child: Text(
                                    '${controller.mainBarcodePrintCount.value}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              
                              // زر الزيادة
                              InkWell(
                                onTap: () {
                                  controller.updateMainBarcodePrintCount(
                                    controller.mainBarcodePrintCount.value + 1
                                  );
                                },
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(8),
                                  bottomRight: Radius.circular(8),
                                ),
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(8),
                                      bottomRight: Radius.circular(8),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    size: 16,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const Spacer(),
                        
                        // خيار مطابقة الكمية
                        TextButton.icon(
                          onPressed: () {
                            controller.updateMainBarcodePrintCount(
                              controller.addedQuantity.value
                            );
                          },
                          icon: const Icon(Icons.sync, size: 16),
                          label: const Text('مطابقة الكمية'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewButtons() {
    return Row(
      children: [
        // زر معاينة الباركودات
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => controller.previewBarcodes(),
            icon: const Icon(Icons.preview, size: 20),
            label: const Text('معاينة الباركودات'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.purple,
              side: const BorderSide(color: Colors.purple),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // زر المساعدة
        IconButton(
          onPressed: _showBarcodeHelp,
          icon: Icon(
            Icons.help_outline,
            color: Colors.grey[600],
          ),
          tooltip: 'مساعدة حول الباركودات',
        ),
      ],
    );
  }

  void _showBarcodeHelp() {
    Get.dialog(
      AlertDialog(
        title: const Text('مساعدة حول الباركودات'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpItem(
                'الباركودات التسلسلية',
                'باركودات فريدة لكل قطعة منتج، مفيدة لتتبع المخزون والمبيعات بدقة.',
                Icons.qr_code_scanner,
                Colors.purple,
              ),
              const SizedBox(height: 12),
              _buildHelpItem(
                'الباركود الرئيسي',
                'باركود موحد للمنتج، يُستخدم للتعرف السريع على نوع المنتج.',
                Icons.qr_code,
                Colors.orange,
              ),
              const SizedBox(height: 12),
              _buildHelpItem(
                'الطباعة',
                'سيتم حفظ الباركودات فقط بعد تأكيد الطباعة الناجحة.',
                Icons.print,
                Colors.green,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('فهمت'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String title, String description, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 