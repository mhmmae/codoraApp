import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/edit_product_controller.dart';

class AdditionalInfoSection extends StatelessWidget {
  const AdditionalInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      final controller = Get.find<EditProductController>();
      
      if (!controller.isProductLoaded.value) {
        return const Center(child: CircularProgressIndicator());
      }
      
      return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'معلومات إضافية',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // بلد المنشأ
        Obx(() {
          final countries = _getCountries();
          final currentCountry = controller.selectedCountry.value;
          
          // التحقق من وجود القيمة في القائمة
          final validValue = currentCountry.isEmpty || !countries.containsKey(currentCountry)
              ? null 
              : currentCountry;
          
          return DropdownButtonFormField<String>(
            value: validValue,
            decoration: InputDecoration(
              labelText: 'بلد المنشأ',
              prefixIcon: const Icon(Icons.flag),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            hint: const Text('اختر بلد المنشأ'),
            items: countries.entries.map((entry) {
              return DropdownMenuItem(
                value: entry.key,
                child: Row(
                  children: [
                    Text(entry.value['flag']!),
                    const SizedBox(width: 8),
                    Expanded(child: Text(entry.value['name']!)),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              controller.selectedCountry.value = value ?? '';
            },
          );
        }),
        const SizedBox(height: 16),
        
        // معلومات إضافية للمنتج
        Card(
          color: Colors.blue[50],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text(
                      'ملاحظات هامة',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '• تأكد من دقة جميع المعلومات المدخلة',
                  style: TextStyle(fontSize: 14),
                ),
                const Text(
                  '• الصور الواضحة تساعد في زيادة المبيعات',
                  style: TextStyle(fontSize: 14),
                ),
                const Text(
                  '• حافظ على تحديث الكمية المتوفرة باستمرار',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ],
    );
    } catch (e) {
      return const Center(child: Text('خطأ في تحميل البيانات'));
    }
  }
  
  Map<String, Map<String, String>> _getCountries() {
    return {
      'SA': {'name': 'السعودية', 'flag': '🇸🇦'},
      'AE': {'name': 'الإمارات', 'flag': '🇦🇪'},
      'EG': {'name': 'مصر', 'flag': '🇪🇬'},
      'KW': {'name': 'الكويت', 'flag': '🇰🇼'},
      'QA': {'name': 'قطر', 'flag': '🇶🇦'},
      'BH': {'name': 'البحرين', 'flag': '🇧🇭'},
      'OM': {'name': 'عمان', 'flag': '🇴🇲'},
      'JO': {'name': 'الأردن', 'flag': '🇯🇴'},
      'LB': {'name': 'لبنان', 'flag': '🇱🇧'},
      'SY': {'name': 'سوريا', 'flag': '🇸🇾'},
      'IQ': {'name': 'العراق', 'flag': '🇮🇶'},
      'YE': {'name': 'اليمن', 'flag': '🇾🇪'},
      'LY': {'name': 'ليبيا', 'flag': '🇱🇾'},
      'TN': {'name': 'تونس', 'flag': '🇹🇳'},
      'DZ': {'name': 'الجزائر', 'flag': '🇩🇿'},
      'MA': {'name': 'المغرب', 'flag': '🇲🇦'},
      'SD': {'name': 'السودان', 'flag': '🇸🇩'},
      'TR': {'name': 'تركيا', 'flag': '🇹🇷'},
      'CN': {'name': 'الصين', 'flag': '🇨🇳'},
      'US': {'name': 'أمريكا', 'flag': '🇺🇸'},
      'GB': {'name': 'بريطانيا', 'flag': '🇬🇧'},
      'DE': {'name': 'ألمانيا', 'flag': '🇩🇪'},
      'FR': {'name': 'فرنسا', 'flag': '🇫🇷'},
      'IT': {'name': 'إيطاليا', 'flag': '🇮🇹'},
      'ES': {'name': 'إسبانيا', 'flag': '🇪🇸'},
      'JP': {'name': 'اليابان', 'flag': '🇯🇵'},
      'KR': {'name': 'كوريا الجنوبية', 'flag': '🇰🇷'},
      'IN': {'name': 'الهند', 'flag': '🇮🇳'},
      'OTHER': {'name': 'أخرى', 'flag': '🌍'},
    };
  }
} 