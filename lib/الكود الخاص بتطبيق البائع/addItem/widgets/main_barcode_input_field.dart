import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../barcode_scanner/product_barcode_scanner.dart';
import '../Chose-The-Type-Of-Itemxx.dart';

/// حقل إدخال الباركود الرئيسي مع قارئ باركود مدمج
class MainBarcodeInputField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final String? Function(String?)? validator;
  final VoidCallback? onBarcodeScanned;
  final Getinformationofitem1 logic;

  const MainBarcodeInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.logic,
    this.hintText = "أدخل الباركود أو امسحه (سيتم إنشاؤه تلقائياً)",
    this.validator,
    this.onBarcodeScanned,
  });

  @override
  State<MainBarcodeInputField> createState() => _MainBarcodeInputFieldState();
}

class _MainBarcodeInputFieldState extends State<MainBarcodeInputField> {
  @override
  void initState() {
    super.initState();
    // إضافة listener للتحديث عند تغيير النص
    widget.controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    // إزالة listener عند dispose
    widget.controller.removeListener(() {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // تسمية الحقل
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 8),
        
        // حقل الإدخال مع الأزرار
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Colors.blue.withOpacity(0.3),
              width: 2,
            ),
            color: Colors.grey[50],
          ),
          child: Row(
            children: [
              // حقل الإدخال الرئيسي
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  validator: widget.validator,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                                          hintText: widget.hintText,
                    hintStyle: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16, 
                      vertical: 12,
                    ),
                    prefixIcon: Icon(
                      Icons.qr_code,
                      color: Colors.blue[600],
                      size: 22,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 15,
                    fontFamily: 'monospace',
                    color: Colors.grey[800],
                  ),
                  onChanged: (value) {
                    // تحديث الواجهة عند تغيير النص
                  },
                ),
              ),
              
              // زر المسح
              if (widget.controller.text.isNotEmpty) _buildClearButton(),
              
              // زر قارئ الباركود
              _buildScanButton(context),
            ],
          ),
        ),
        
        // معلومات إضافية
        if (widget.controller.text.isNotEmpty) ...[
          SizedBox(height: 8),
          _buildBarcodeInfo(),
        ],
        

      ],
    );
  }

  /// بناء زر قارئ الباركود
  Widget _buildScanButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openBarcodeScanner(context),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(15),
          bottomRight: Radius.circular(15),
        ),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.blue[600],
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(13),
              bottomRight: Radius.circular(13),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.qr_code_scanner,
                color: Colors.white,
                size: 18,
              ),
              SizedBox(width: 6),
              Text(
                'مسح',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// فتح قارئ الباركود
  void _openBarcodeScanner(BuildContext context) async {
    final String? scannedBarcode = await Get.to(() => ProductBarcodeScanner());
    
    if (scannedBarcode != null && scannedBarcode.isNotEmpty) {
      widget.controller.text = scannedBarcode;
      widget.onBarcodeScanned?.call();
      
      Get.snackbar(
        '✅ تم مسح الباركود الرئيسي',
        'الباركود: $scannedBarcode',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: Duration(seconds: 2),
        icon: Icon(Icons.check_circle, color: Colors.white),
      );
    }
  }

  /// بناء زر المسح
  Widget _buildClearButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          widget.controller.clear();
          Get.snackbar(
            '🗑️ تم المسح',
            'تم مسح الباركود الرئيسي',
            backgroundColor: Colors.orange.withOpacity(0.1),
            colorText: Colors.orange[800],
            duration: Duration(seconds: 2),
            icon: Icon(Icons.delete_sweep, color: Colors.orange),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.all(8),
          child: Icon(
            Icons.clear,
            color: Colors.red[400],
            size: 16,
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
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.blue[600],
            size: 16,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'الباركود الرئيسي: ${widget.controller.text}',
              style: TextStyle(
                color: Colors.blue[700],
                fontSize: 13,
                fontFamily: 'monospace',
              ),
            ),
          ),
          // زر النسخ
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: widget.controller.text));
                Get.snackbar(
                  '📋 تم النسخ',
                  'تم نسخ الباركود إلى الحافظة',
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  colorText: Colors.blue[800],
                  duration: Duration(seconds: 2),
                  icon: Icon(Icons.content_copy, color: Colors.blue),
                );
              },
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.copy,
                  size: 14,
                  color: Colors.blue[600],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


} 