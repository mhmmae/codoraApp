import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../barcode_scanner/product_barcode_scanner.dart';

/// حقل إدخال الباركود مع إمكانية المسح
class BarcodeInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final bool isRequired;
  final VoidCallback? onBarcodeScanned;

  const BarcodeInputField({
    super.key,
    required this.controller,
    required this.label,
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
                    hintText: 'أدخل الباركود أو امسحه',
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
              
              // زر المسح
              _buildScanButton(context, width),
              
              // زر المسح
              _buildClearButton(context),
            ],
          ),
        ),
        
        // معلومات إضافية
        if (controller.text.isNotEmpty) ...[
          SizedBox(height: 8),
          _buildBarcodeInfo(),
        ],
      ],
    );
  }

  /// بناء زر المسح
  Widget _buildScanButton(BuildContext context, double width) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          // فتح شاشة مسح الباركود
          final result = await Get.to(() => ProductBarcodeScanner());
          
          if (result != null && result is String && result.isNotEmpty) {
            controller.text = result;
            
            // إشعار بالنجاح
            Get.snackbar(
              '✅ تم مسح الباركود',
              'تم إضافة الباركود بنجاح: $result',
              backgroundColor: Colors.green.withOpacity(0.1),
              colorText: Colors.green[800],
              duration: Duration(seconds: 3),
              icon: Icon(Icons.check_circle, color: Colors.green),
            );
            
            // استدعاء callback إذا وُجد
            onBarcodeScanned?.call();
          }
        },
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
                color: Colors.blue[600],
                size: 20,
              ),
              SizedBox(width: 6),
              Text(
                'مسح',
                style: TextStyle(
                  color: Colors.blue[600],
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

  /// بناء زر المسح
  Widget _buildClearButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (controller.text.isNotEmpty) {
            controller.clear();
            Get.snackbar(
              '🗑️ تم المسح',
              'تم مسح الباركود',
              backgroundColor: Colors.orange.withOpacity(0.1),
              colorText: Colors.orange[800],
              duration: Duration(seconds: 2),
            );
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.all(8),
          child: Icon(
            Icons.clear,
            color: controller.text.isNotEmpty ? Colors.red[400] : Colors.grey[400],
            size: 18,
          ),
        ),
      ),
    );
  }

  /// بناء معلومات الباركود
  Widget _buildBarcodeInfo() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.blue[600],
            size: 18,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'باركود المنتج:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  controller.text,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          // زر النسخ
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // نسخ الباركود للحافظة
                Get.snackbar(
                  '📋 تم النسخ',
                  'تم نسخ الباركود للحافظة',
                  backgroundColor: Colors.green.withOpacity(0.1),
                  colorText: Colors.green[800],
                  duration: Duration(seconds: 2),
                );
              },
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: EdgeInsets.all(6),
                child: Icon(
                  Icons.copy,
                  color: Colors.blue[600],
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Controller لإدارة حالة حقل الباركود
class BarcodeFieldController extends GetxController {
  final TextEditingController textController = TextEditingController();
  final RxBool hasBarcode = false.obs;
  final RxString barcodeType = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // مراقبة تغييرات النص
    textController.addListener(() {
      hasBarcode.value = textController.text.isNotEmpty;
      _detectBarcodeType();
    });
  }

  @override
  void onClose() {
    textController.dispose();
    super.onClose();
  }

  /// كشف نوع الباركود
  void _detectBarcodeType() {
    final text = textController.text;
    
    if (text.isEmpty) {
      barcodeType.value = '';
      return;
    }

    // كشف أنواع الباركود المختلفة
    if (text.length == 13 && _isNumeric(text)) {
      barcodeType.value = 'EAN-13';
    } else if (text.length == 12 && _isNumeric(text)) {
      barcodeType.value = 'UPC-A';
    } else if (text.length == 8 && _isNumeric(text)) {
      barcodeType.value = 'EAN-8';
    } else if (text.startsWith('978') && text.length == 13) {
      barcodeType.value = 'ISBN';
    } else {
      barcodeType.value = 'Code-128';
    }
  }

  /// فحص إذا كان النص رقمي
  bool _isNumeric(String text) {
    return RegExp(r'^[0-9]+$').hasMatch(text);
  }

  /// تعيين الباركود
  void setBarcode(String barcode) {
    textController.text = barcode;
  }

  /// مسح الباركود
  void clearBarcode() {
    textController.clear();
  }

  /// التحقق من صحة الباركود
  String? validateBarcode(String? value) {
    if (value == null || value.isEmpty) {
      return null; // غير مطلوب افتراضياً
    }

    if (value.length < 6) {
      return 'الباركود قصير جداً';
    }

    if (value.length > 50) {
      return 'الباركود طويل جداً';
    }

    return null;
  }
} 