import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'sequential_barcode_print_page.dart';
import 'main_barcode_print_page.dart';
import 'sequential_barcode_scan_page.dart';
import 'main_barcode_edit_page.dart';

class BarcodeOperationsPage extends StatelessWidget {
  const BarcodeOperationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طباعة وإدارة الباركود'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // عنوان ترحيبي
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.withOpacity(0.1), Colors.white],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.purple.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.qr_code_scanner,
                      size: 50,
                      color: Colors.purple[700],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'إدارة شاملة للباركود',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[700],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'اختر نوع العملية التي تريد تنفيذها',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // عمليات الباركود
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 0.75,
                children: [
                  // النوع الأول: طباعة باركود تسلسلي
                  _buildBarcodeOperationCard(
                    icon: Icons.format_list_numbered,
                    title: 'طباعة باركود تسلسلي',
                    subtitle: 'إنشاء وطباعة باركودات تسلسلية جديدة',
                    color: Colors.blue,
                    onTap: () => Get.to(() => const SequentialBarcodePrintPage()),
                    badge: '1',
                  ),
                  
                  // النوع الثاني: طباعة باركود رئيسي
                  _buildBarcodeOperationCard(
                    icon: Icons.qr_code,
                    title: 'طباعة باركود رئيسي',
                    subtitle: 'طباعة الباركود الرئيسي للمنتج',
                    color: Colors.green,
                    onTap: () => Get.to(() => const MainBarcodePrintPage()),
                    badge: '2',
                  ),
                  
                  // النوع الثالث: إضافة باركودات بالمسح
                  _buildBarcodeOperationCard(
                    icon: Icons.camera_alt,
                    title: 'إضافة باركودات بالمسح',
                    subtitle: 'مسح وإضافة باركودات تسلسلية موجودة',
                    color: Colors.orange,
                    onTap: () => Get.to(() => const SequentialBarcodeScanPage()),
                    badge: '3',
                  ),
                  
                  // النوع الرابع: تعديل باركود رئيسي
                  _buildBarcodeOperationCard(
                    icon: Icons.edit,
                    title: 'تعديل باركود رئيسي',
                    subtitle: 'تغيير أو تحديث الباركود الرئيسي',
                    color: Colors.red,
                    onTap: () => Get.to(() => const MainBarcodeEditPage()),
                    badge: '4',
                  ),
                ],
              ),
              
              const SizedBox(height: 30),
              
              // معلومات إضافية
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'نصائح مهمة:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text('• تأكد من اتصال الطابعة قبل بدء الطباعة'),
                    const Text('• الباركود التسلسلي يُستخدم لتتبع القطع الفردية'),
                    const Text('• الباركود الرئيسي يُستخدم لتعريف نوع المنتج'),
                    const Text('• يمكنك إضافة باركودات موجودة بسرعة باستخدام الكاميرا'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarcodeOperationCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required String badge,
  }) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                Colors.white,
              ],
            ),
          ),
          child: Stack(
            children: [
              // Badge number
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Main content
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // أيقونة مع تأثير دائري
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        size: 28,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    // العنوان
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    
                    // النص الفرعي
                    Flexible(
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // زر البدء
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        'ابدأ الآن',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
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
} 