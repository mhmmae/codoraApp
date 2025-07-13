import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// مثال توضيحي لكيفية عمل نظام التحميل والترجمة التلقائية في إضافة الأقسام
/// 
/// الميزات المطبقة:
/// 1. ✅ حالة التحميل مع مؤشر دوار
/// 2. ✅ رسائل تقدم واضحة للمستخدم
/// 3. ✅ مسح الحقول تلقائياً بعد النجاح
/// 4. ✅ منع التفاعل أثناء التحميل
/// 5. ✅ رسائل نجاح متدرجة
/// 6. 🔮 نظام ترجمة تلقائية (مُحضر للمستقبل)

class AddCategoryDemo extends StatefulWidget {
  const AddCategoryDemo({super.key});

  @override
  State<AddCategoryDemo> createState() => _AddCategoryDemoState();
}

class _AddCategoryDemoState extends State<AddCategoryDemo> {
  final _formKey = GlobalKey<FormState>();
  final _nameArController = TextEditingController();
  final _nameEnController = TextEditingController();
  final _nameKuController = TextEditingController();
  
  bool _isLoading = false;
  int _addedCount = 0;

  @override
  void dispose() {
    _nameArController.dispose();
    _nameEnController.dispose();
    _nameKuController.dispose();
    super.dispose();
  }

  /// مسح جميع الحقول
  void _clearAllFields() {
    setState(() {
      _nameArController.clear();
      _nameEnController.clear();
      _nameKuController.clear();
    });
  }

  /// محاكاة عملية إضافة القسم
  Future<void> _simulateAddCategory() async {
    if (!_formKey.currentState!.validate()) {
      Get.snackbar(
        '❌ خطأ في البيانات',
        'يرجى ملء جميع الحقول المطلوبة',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      // تفعيل حالة التحميل
      setState(() {
        _isLoading = true;
      });

      // عرض رسالة بدء العملية
      Get.snackbar(
        '⏳ جاري التحميل',
        'جاري إضافة القسم الفرعي...',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      // محاكاة ترجمة تلقائية (خطوة 1)
      await Future.delayed(const Duration(seconds: 1));
      Get.snackbar(
        '🔤 ترجمة تلقائية',
        'جاري ترجمة اسم القسم للغات الأخرى...',
        backgroundColor: Colors.blue[600]!,
        colorText: Colors.white,
        duration: const Duration(seconds: 1),
      );

      // محاكاة رفع البيانات (خطوة 2)
      await Future.delayed(const Duration(seconds: 1));
      Get.snackbar(
        '☁️ رفع البيانات',
        'جاري حفظ القسم في قاعدة البيانات...',
        backgroundColor: Colors.purple[600]!,
        colorText: Colors.white,
        duration: const Duration(seconds: 1),
      );

      // محاكاة تحديث الواجهة (خطوة 3)
      await Future.delayed(const Duration(seconds: 1));

      // إظهار رسالة النجاح
      Get.snackbar(
        '✅ تم بنجاح',
        'تم إضافة القسم الفرعي بنجاح',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      
      // مسح جميع الحقول بعد تأخير قصير
      await Future.delayed(const Duration(milliseconds: 500));
      _clearAllFields();
      
      // تحديث العداد
      setState(() {
        _addedCount++;
      });
      
      // إعطاء انطباع تم الانتهاء من التحميل
      Get.snackbar(
        '🎉 جاهز للإضافة التالية',
        'يمكنك الآن إضافة قسم جديد',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

    } catch (e) {
      Get.snackbar(
        '❌ خطأ',
        'حدث خطأ غير متوقع: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      // إيقاف حالة التحميل
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'مثال: إضافة قسم فرعي مع التحميل',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // معلومات توضيحية
                  Card(
                    elevation: 2,
                    color: Colors.green[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, color: Colors.green[700]),
                              const SizedBox(width: 8),
                              Text(
                                'مثال تطبيقي للميزات المطبقة',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'تم إضافة $_addedCount قسم بنجاح',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // قائمة الميزات المطبقة
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'الميزات المطبقة:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const _FeatureItem(
                            icon: Icons.hourglass_empty,
                            title: 'حالة التحميل مع مؤشر دوار',
                            isImplemented: true,
                          ),
                          const _FeatureItem(
                            icon: Icons.message,
                            title: 'رسائل تقدم واضحة للمستخدم',
                            isImplemented: true,
                          ),
                          const _FeatureItem(
                            icon: Icons.clear_all,
                            title: 'مسح الحقول تلقائياً بعد النجاح',
                            isImplemented: true,
                          ),
                          const _FeatureItem(
                            icon: Icons.block,
                            title: 'منع التفاعل أثناء التحميل',
                            isImplemented: true,
                          ),
                          const _FeatureItem(
                            icon: Icons.check_circle,
                            title: 'رسائل نجاح متدرجة',
                            isImplemented: true,
                          ),
                          const _FeatureItem(
                            icon: Icons.translate,
                            title: 'نظام ترجمة تلقائية',
                            isImplemented: false,
                            note: 'مُحضر للمستقبل',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // حقول الإدخال
                  _buildTextField(
                    controller: _nameArController,
                    label: 'اسم القسم بالعربي*',
                    icon: Icons.text_fields,
                    hintText: 'مثال: إلكترونيات',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'يرجى إدخال اسم القسم بالعربي';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _nameEnController,
                    label: 'اسم القسم بالإنجليزي*',
                    icon: Icons.text_fields,
                    hintText: 'Example: Electronics',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'يرجى إدخال اسم القسم بالإنجليزي';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _nameKuController,
                    label: 'اسم القسم بالكردي*',
                    icon: Icons.text_fields,
                    hintText: 'نموونە: ئەلیکترۆنیات',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'يرجى إدخال اسم القسم بالكردي';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // زر التجربة
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _simulateAddCategory,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.add, color: Colors.white),
                      label: Text(
                        _isLoading
                            ? 'جاري التحميل...'
                            : 'تجربة إضافة القسم',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isLoading ? Colors.grey : Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        const Text(
                          'جاري معالجة البيانات...',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'يرجى الانتظار - تتم معالجة القسم',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hintText,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.blue[600]),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: hintText,
            prefixIcon: Icon(icon),
            enabled: !_isLoading, // منع التعديل أثناء التحميل
          ),
          validator: validator,
        ),
      ],
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isImplemented;
  final String? note;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.isImplemented,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isImplemented ? Icons.check_circle : Icons.schedule,
            color: isImplemented ? Colors.green : Colors.orange,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: isImplemented ? Colors.black87 : Colors.grey[600],
                    decoration: isImplemented ? null : TextDecoration.none,
                  ),
                ),
                if (note != null)
                  Text(
                    note!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 