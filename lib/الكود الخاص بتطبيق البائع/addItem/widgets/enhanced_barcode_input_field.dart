import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Chose-The-Type-Of-Itemxx.dart';
import 'advanced_barcode_scanner.dart';

/// حقل إدخال الباركود المحسن مع إمكانية المسح المتقدم
class EnhancedBarcodeInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final bool isRequired;
  final VoidCallback? onBarcodeScanned;
  final Getinformationofitem1 logic;

  const EnhancedBarcodeInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.logic,
    this.validator,
    this.isRequired = false,
    this.onBarcodeScanned,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // عنوان الحقل
        if (label.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, right: 4.0),
            child: Row(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14.5,
                    color: Colors.grey[700],
                  ),
                ),
                if (isRequired) ...[
                  SizedBox(width: 4),
                  Text(
                    '*',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        
        // حقل الإدخال مع أزرار
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey[300]!),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              // حقل النص
              Expanded(
                child: TextFormField(
                  controller: controller,
                  validator: validator,
                  decoration: InputDecoration(
                    hintText: 'أدخل الباركود الرئيسي أو امسح باركودات متعددة',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    prefixIcon: Icon(
                      Icons.qr_code,
                      color: Colors.grey[500],
                      size: 20,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                ),
              ),
              
              // فاصل
              Container(
                width: 1,
                height: 40,
                color: Colors.grey[300],
              ),
              
              // زر المسح المتقدم
              _buildAdvancedScanButton(context, width),
              
              // زر المسح
              _buildClearButton(context),
            ],
          ),
        ),
        
        // عرض الباركودات المسحوبة
        Obx(() {
          if (logic.productBarcodes.isNotEmpty) {
            return Container(
              margin: EdgeInsets.only(top: 12),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.inventory, color: Colors.blue, size: 18),
                      SizedBox(width: 8),
                      Text(
                        "الباركودات المسحوبة (${logic.productBarcodes.length})",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                          fontSize: 14,
                        ),
                      ),
                      Spacer(),
                      TextButton.icon(
                        onPressed: () => _openAdvancedScanner(context),
                        icon: Icon(Icons.edit, size: 16),
                        label: Text("تعديل"),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: logic.productBarcodes.take(6).map((barcode) {
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Text(
                          barcode.length > 8 ? "${barcode.substring(0, 8)}..." : barcode,
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: Colors.blue[700],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (logic.productBarcodes.length > 6) ...[
                    SizedBox(height: 4),
                    Text(
                      "وباركودات أخرى... (المجموع: ${logic.productBarcodes.length})",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }
          return SizedBox.shrink();
        }),
        
        // معلومات إضافية
        if (controller.text.isNotEmpty) ...[
          SizedBox(height: 8),
          _buildBarcodeInfo(),
        ],
      ],
    );
  }

  /// بناء زر المسح المتقدم
  Widget _buildAdvancedScanButton(BuildContext context, double width) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openAdvancedScanner(context),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(15),
          bottomRight: Radius.circular(15),
        ),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.qr_code_scanner,
                color: Colors.deepPurple[600],
                size: 20,
              ),
              SizedBox(width: 6),
              Text(
                'مسح الباركودات',
                style: TextStyle(
                  color: Colors.deepPurple[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// فتح الماسح المتقدم
  void _openAdvancedScanner(BuildContext context) {
    // التحقق من وجود كمية المنتج
    if (logic.productQuantity.text.isEmpty) {
      Get.snackbar(
        'تنبيه',
        'يجب تحديد كمية المنتج أولاً قبل مسح الباركودات',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        icon: Icon(Icons.warning, color: Colors.white),
      );
      return;
    }

    final quantity = int.tryParse(logic.productQuantity.text);
    if (quantity == null || quantity <= 0) {
      Get.snackbar(
        'خطأ',
        'كمية المنتج غير صحيحة. يجب أن تكون رقماً أكبر من صفر.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: Icon(Icons.error, color: Colors.white),
      );
      return;
    }

    // فتح الماسح المتقدم
    Get.to(() => AdvancedBarcodeScanner(
      requiredQuantity: quantity,
      initialBarcodes: logic.productBarcodes.toList(),
      onBarcodesScanned: (List<String> barcodes) {
        logic.productBarcodes.assignAll(barcodes);
        
        // تحديث الكمية إذا تم إضافة باركودات إضافية
        if (barcodes.length != quantity) {
          logic.productQuantity.text = barcodes.length.toString();
          Get.snackbar(
            'تم التحديث',
            'تم تحديث كمية المنتج إلى ${barcodes.length} قطعة',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        }
        
        // تحديث الباركود الرئيسي بأول باركود إذا كان فارغاً
        if (controller.text.isEmpty && barcodes.isNotEmpty) {
          controller.text = barcodes.first;
        }
        
        onBarcodeScanned?.call();
      },
      onQuantityUpdated: (int newQuantity) {
        // تحديث كمية المنتج في حقل الإدخال
        logic.productQuantity.text = newQuantity.toString();
      },
    ));
  }

  /// بناء زر المسح
  Widget _buildClearButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (controller.text.isNotEmpty || logic.productBarcodes.isNotEmpty) {
            // مسح الباركود الرئيسي والقائمة
            controller.clear();
            logic.productBarcodes.clear();
            
            Get.snackbar(
              '🗑️ تم المسح',
              'تم مسح جميع الباركودات',
              backgroundColor: Colors.orange.withOpacity(0.1),
              colorText: Colors.orange[800],
              duration: Duration(seconds: 2),
              icon: Icon(Icons.delete_sweep, color: Colors.orange),
            );
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.all(8),
          child: Icon(
            Icons.clear,
            color: Colors.red[400],
            size: 18,
          ),
        ),
      ),
    );
  }

  /// بناء معلومات الباركود
  Widget _buildBarcodeInfo() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.green[600],
            size: 16,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'الباركود الرئيسي: ${controller.text}',
              style: TextStyle(
                color: Colors.green[700],
                fontSize: 13,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
} 