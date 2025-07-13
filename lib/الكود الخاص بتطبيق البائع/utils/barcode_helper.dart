import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// كلاس مساعد لإدارة عرض الباركود والQR كود
class BarcodeHelper {
  /// عرض حوار الباركود مع خيارات متعددة
  static void showBarcodeDialog(BuildContext context, String orderNumber, String orderTitle) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey[50]!,
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header مع خلفية ملونة
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  vertical: height * 0.025,
                  horizontal: width * 0.05,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Get.theme.colorScheme.primary,
                      Get.theme.colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.qr_code_scanner,
                      color: Colors.white,
                      size: width * 0.08,
                    ),
                    SizedBox(height: height * 0.01),
                    Text(
                      'رمز QR للطلب',
                      style: TextStyle(
                        fontSize: width * 0.05,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              // محتوى الحوار
              Padding(
                padding: EdgeInsets.all(width * 0.05),
                child: Column(
                  children: [
                    // معلومات الطلب
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(width * 0.04),
                      decoration: BoxDecoration(
                        color: Get.theme.colorScheme.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Get.theme.colorScheme.primary.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_bag,
                                color: Get.theme.colorScheme.primary,
                                size: width * 0.05,
                              ),
                              SizedBox(width: width * 0.02),
                              Flexible(
                                child: Text(
                                  orderTitle,
                                  style: TextStyle(
                                    fontSize: width * 0.04,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: height * 0.005),
                          Text(
                            'رقم الطلب: #$orderNumber',
                            style: TextStyle(
                              fontSize: width * 0.035,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: height * 0.025),
                    
                    // QR Code مع تأثيرات
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // حلقة متحركة حول QR Code
                        Container(
                          width: width * 0.6,
                          height: width * 0.6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Get.theme.colorScheme.primary.withOpacity(0.1),
                                Get.theme.colorScheme.primary.withOpacity(0.05),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        // QR Code
                        Container(
                          padding: EdgeInsets.all(width * 0.04),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Get.theme.colorScheme.primary.withOpacity(0.2),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Get.theme.colorScheme.primary.withOpacity(0.1),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: QrImageView(
                            data: orderNumber,
                            version: QrVersions.auto,
                            size: width * 0.45,
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            errorCorrectionLevel: QrErrorCorrectLevel.H,
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: height * 0.025),
                    
                    // رسالة توضيحية
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: width * 0.06,
                        vertical: height * 0.015,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.amber.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.amber[700],
                            size: width * 0.04,
                          ),
                          SizedBox(width: width * 0.02),
                          Flexible(
                            child: Text(
                              'اطلب من عامل التوصيل مسح هذا الرمز',
                              style: TextStyle(
                                fontSize: width * 0.032,
                                color: Colors.amber[900],
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: height * 0.025),
                    
                    // أزرار الأكشن
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue[600]!,
                                  Colors.blue[700]!,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _shareBarcode(orderNumber),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: height * 0.018,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.share,
                                        color: Colors.white,
                                        size: width * 0.04,
                                      ),
                                      SizedBox(width: width * 0.02),
                                      Text(
                                        'مشاركة',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: width * 0.035,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: width * 0.03),
                        Expanded(
                          flex: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Get.theme.colorScheme.primary,
                                  Get.theme.colorScheme.primary.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Get.theme.colorScheme.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => Get.back(),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: height * 0.018,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                        size: width * 0.04,
                                      ),
                                      SizedBox(width: width * 0.02),
                                      Text(
                                        'حسناً',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: width * 0.035,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  /// مشاركة معلومات الباركود
  static void _shareBarcode(String orderNumber) {
    // يمكن تطوير هذه الوظيفة لاحقاً لمشاركة الكود
    Get.snackbar(
      '📱 مشاركة',
      'رقم الطلب: #$orderNumber\nيمكن لعامل التوصيل مسح الكود لتأكيد الاستلام',
      backgroundColor: Get.theme.colorScheme.secondary.withOpacity(0.1),
      colorText: Get.theme.colorScheme.secondary,
      duration: Duration(seconds: 3),
    );
  }

  /// إنشاء QR Code مصغر للعرض في البطاقة
  static Widget buildMiniQRCode(String data, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.grey[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Get.theme.colorScheme.primary.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Get.theme.colorScheme.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: QrImageView(
          data: data,
          version: QrVersions.auto,
          size: size,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.all(8),
          errorCorrectionLevel: QrErrorCorrectLevel.M,
        ),
      ),
    );
  }

  /// دالة مساعدة لتوليد بيانات الباركود
  static String generateBarcodeData(String orderNumber, String sellerId) {
    return 'ORDER:$orderNumber:SELLER:$sellerId';
  }
}