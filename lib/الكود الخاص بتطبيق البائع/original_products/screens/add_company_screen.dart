import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/original_products_controller.dart';
import '../../../Model/company_model.dart';

class AddCompanyScreen extends StatefulWidget {
  const AddCompanyScreen({super.key});

  @override
  State<AddCompanyScreen> createState() => _AddCompanyScreenState();
}

class _AddCompanyScreenState extends State<AddCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameArController = TextEditingController();
  final _nameEnController = TextEditingController();
  final _logoUrlController = TextEditingController();

  // متغيرات للصورة
  Uint8List? _selectedImageBytes;
  bool _useImageUpload = true; // true للصورة، false للرابط
  
  // متغير البلد المختار
  String? _selectedCountryKey;

  // متغيرات للاقتراحات
  List<CompanyModel> _filteredCompanies = [];
  bool _showSuggestions = false;
  final FocusNode _nameArFocusNode = FocusNode();
  final FocusNode _nameEnFocusNode = FocusNode();

  // قائمة البلدان (نفس القائمة المستخدمة في addItem)
  static const Map<String, String> countryOptions = {
    'AD': 'أندورا',
    'AE': 'الإمارات العربية المتحدة',
    'AF': 'أفغانستان',
    'AG': 'أنتيغوا وباربودا',
    'AI': 'أنغويلا',
    'AL': 'ألبانيا',
    'AM': 'أرمينيا',
    'AO': 'أنغولا',
    'AQ': 'القارة القطبية الجنوبية',
    'AR': 'الأرجنتين',
    'AS': 'ساموا الأمريكية',
    'AT': 'النمسا',
    'AU': 'أستراليا',
    'AW': 'أروبا',
    'AZ': 'أذربيجان',
    'BA': 'البوسنة والهرسك',
    'BB': 'بربادوس',
    'BD': 'بنغلاديش',
    'BE': 'بلجيكا',
    'BF': 'بوركينا فاسو',
    'BG': 'بلغاريا',
    'BH': 'البحرين',
    'BI': 'بوروندي',
    'BJ': 'بنين',
    'BM': 'برمودا',
    'BN': 'بروناي',
    'BO': 'بوليفيا',
    'BR': 'البرازيل',
    'BS': 'الباهاما',
    'BT': 'بوتان',
    'BW': 'بوتسوانا',
    'BY': 'بيلاروسيا',
    'BZ': 'بليز',
    'CA': 'كندا',
    'CD': 'جمهورية الكونغو الديمقراطية',
    'CF': 'جمهورية أفريقيا الوسطى',
    'CG': 'الكونغو',
    'CH': 'سويسرا',
    'CI': 'ساحل العاج',
    'CK': 'جزر كوك',
    'CL': 'تشيلي',
    'CM': 'الكاميرون',
    'CN': 'الصين',
    'CO': 'كولومبيا',
    'CR': 'كوستاريكا',
    'CU': 'كوبا',
    'CV': 'الرأس الأخضر',
    'CY': 'قبرص',
    'CZ': 'جمهورية التشيك',
    'DE': 'ألمانيا',
    'DJ': 'جيبوتي',
    'DK': 'الدنمارك',
    'DM': 'دومينيكا',
    'DO': 'جمهورية الدومينيكان',
    'DZ': 'الجزائر',
    'EC': 'الإكوادور',
    'EE': 'إستونيا',
    'EG': 'مصر',
    'EH': 'الصحراء الغربية',
    'ER': 'إريتريا',
    'ES': 'إسبانيا',
    'ET': 'إثيوبيا',
    'FI': 'فنلندا',
    'FJ': 'فيجي',
    'FK': 'جزر فوكلاند',
    'FM': 'ميكرونيزيا',
    'FO': 'جزر فارو',
    'FR': 'فرنسا',
    'GA': 'الغابون',
    'GB': 'المملكة المتحدة',
    'GD': 'غرينادا',
    'GE': 'جورجيا',
    'GF': 'غويانا الفرنسية',
    'GH': 'غانا',
    'GI': 'جبل طارق',
    'GL': 'غرينلاند',
    'GM': 'غامبيا',
    'GN': 'غينيا',
    'GP': 'غوادلوب',
    'GQ': 'غينيا الاستوائية',
    'GR': 'اليونان',
    'GT': 'غواتيمالا',
    'GU': 'غوام',
    'GW': 'غينيا بيساو',
    'GY': 'غويانا',
    'HK': 'هونغ كونغ',
    'HN': 'هندوراس',
    'HR': 'كرواتيا',
    'HT': 'هايتي',
    'HU': 'هنغاريا',
    'ID': 'إندونيسيا',
    'IE': 'أيرلندا',
    'IL': 'إسرائيل',
    'IN': 'الهند',
    'IQ': 'العراق',
    'IR': 'إيران',
    'IS': 'أيسلندا',
    'IT': 'إيطاليا',
    'JM': 'جامايكا',
    'JO': 'الأردن',
    'JP': 'اليابان',
    'KE': 'كينيا',
    'KG': 'قيرغيزستان',
    'KH': 'كمبوديا',
    'KI': 'كيريباتي',
    'KM': 'جزر القمر',
    'KN': 'سانت كيتس ونيفيس',
    'KP': 'كوريا الشمالية',
    'KR': 'كوريا الجنوبية',
    'KW': 'الكويت',
    'KY': 'جزر كايمان',
    'KZ': 'كازاخستان',
    'LA': 'لاوس',
    'LB': 'لبنان',
    'LC': 'سانت لوسيا',
    'LI': 'ليختنشتاين',
    'LK': 'سريلانكا',
    'LR': 'ليبيريا',
    'LS': 'ليسوتو',
    'LT': 'ليتوانيا',
    'LU': 'لوكسمبورغ',
    'LV': 'لاتفيا',
    'LY': 'ليبيا',
    'MA': 'المغرب',
    'MC': 'موناكو',
    'MD': 'مولدوفا',
    'ME': 'الجبل الأسود',
    'MG': 'مدغشقر',
    'MH': 'جزر مارشال',
    'MK': 'مقدونيا الشمالية',
    'ML': 'مالي',
    'MM': 'ميانمار',
    'MN': 'منغوليا',
    'MO': 'ماكاو',
    'MP': 'جزر ماريانا الشمالية',
    'MQ': 'مارتينيك',
    'MR': 'موريتانيا',
    'MS': 'مونتسرات',
    'MT': 'مالطا',
    'MU': 'موريشيوس',
    'MV': 'المالديف',
    'MW': 'مالاوي',
    'MX': 'المكسيك',
    'MY': 'ماليزيا',
    'MZ': 'موزمبيق',
    'NA': 'ناميبيا',
    'NC': 'كاليدونيا الجديدة',
    'NE': 'النيجر',
    'NF': 'جزيرة نورفولك',
    'NG': 'نيجيريا',
    'NI': 'نيكاراغوا',
    'NL': 'هولندا',
    'NO': 'النرويج',
    'NP': 'نيبال',
    'NR': 'ناورو',
    'NU': 'نيوي',
    'NZ': 'نيوزيلندا',
    'OM': 'عُمان',
    'PA': 'بنما',
    'PE': 'بيرو',
    'PF': 'بولينيزيا الفرنسية',
    'PG': 'بابوا غينيا الجديدة',
    'PH': 'الفلبين',
    'PK': 'باكستان',
    'PL': 'بولندا',
    'PM': 'سان بيير وميكلون',
    'PN': 'جزر بيتكيرن',
    'PR': 'بورتوريكو',
    'PS': 'فلسطين',
    'PT': 'البرتغال',
    'PW': 'بالاو',
    'PY': 'باراغواي',
    'QA': 'قطر',
    'RE': 'لا ريونيون',
    'RO': 'رومانيا',
    'RS': 'صربيا',
    'RU': 'روسيا',
    'RW': 'رواندا',
    'SA': 'السعودية',
    'SB': 'جزر سليمان',
    'SC': 'سيشل',
    'SD': 'السودان',
    'SE': 'السويد',
    'SG': 'سنغافورة',
    'SH': 'سانت هيلينا',
    'SI': 'سلوفينيا',
    'SK': 'سلوفاكيا',
    'SL': 'سيراليون',
    'SM': 'سان مارينو',
    'SN': 'السنغال',
    'SO': 'الصومال',
    'SR': 'سورينام',
    'ST': 'ساو تومي وبرينسيبي',
    'SV': 'السلفادور',
    'SY': 'سوريا',
    'SZ': 'إسواتيني',
    'TC': 'جزر تركس وكايكوس',
    'TD': 'تشاد',
    'TF': 'الأقاليم الفرنسية الجنوبية',
    'TG': 'توغو',
    'TH': 'تايلاند',
    'TJ': 'طاجيكستان',
    'TK': 'توكيلاو',
    'TL': 'تيمور الشرقية',
    'TM': 'تركمانستان',
    'TN': 'تونس',
    'TO': 'تونغا',
    'TR': 'تركيا',
    'TT': 'ترينيداد وتوباغو',
    'TV': 'توفالو',
    'TW': 'تايوان',
    'TZ': 'تنزانيا',
    'UA': 'أوكرانيا',
    'UG': 'أوغندا',
    'UM': 'جزر الولايات المتحدة النائية',
    'US': 'الولايات المتحدة',
    'UY': 'أوروغواي',
    'UZ': 'أوزبكستان',
    'VA': 'الفاتيكان',
    'VC': 'سانت فنسنت والغرينادين',
    'VE': 'فنزويلا',
    'VG': 'جزر العذراء البريطانية',
    'VI': 'جزر العذراء الأمريكية',
    'VN': 'فيتنام',
    'VU': 'فانواتو',
    'WF': 'واليس وفوتونا',
    'WS': 'ساموا',
    'YE': 'اليمن',
    'YT': 'مايوت',
    'ZA': 'جنوب أفريقيا',
    'ZM': 'زامبيا',
    'ZW': 'زيمبابوي',
  };

  @override
  void initState() {
    super.initState();
    // تحميل الشركات عند بدء الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Get.find<OriginalProductsController>();
      controller.fetchCompanies();
    });

    // إضافة مستمعين للحقول
    _nameArController.addListener(_onTextChanged);
    _nameEnController.addListener(_onTextChanged);

    // إضافة مستمعين للتركيز
    _nameArFocusNode.addListener(() {
      if (!_nameArFocusNode.hasFocus) {
        setState(() => _showSuggestions = false);
      }
    });
    
    _nameEnFocusNode.addListener(() {
      if (!_nameEnFocusNode.hasFocus) {
        setState(() => _showSuggestions = false);
      }
    });
  }

  @override
  void dispose() {
    _nameArController.dispose();
    _nameEnController.dispose();
    _logoUrlController.dispose();
    _nameArFocusNode.dispose();
    _nameEnFocusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final controller = Get.find<OriginalProductsController>();
    final query = _nameArController.text + _nameEnController.text;
    
    if (query.isNotEmpty) {
      setState(() {
        _filteredCompanies = controller.companies.where((company) =>
          company.nameAr.toLowerCase().contains(_nameArController.text.toLowerCase()) ||
          company.nameEn.toLowerCase().contains(_nameEnController.text.toLowerCase())
        ).toList();
        _showSuggestions = _filteredCompanies.isNotEmpty;
      });
    } else {
      setState(() {
        _filteredCompanies = [];
        _showSuggestions = false;
      });
    }
  }

  void _selectCompanySuggestion(CompanyModel company) {
    setState(() {
      _nameArController.text = company.nameAr;
      _nameEnController.text = company.nameEn;
      _selectedCountryKey = countryOptions.entries
          .firstWhere((entry) => entry.value == company.country, 
                     orElse: () => const MapEntry('', ''))
          .key;
      if (_selectedCountryKey!.isEmpty) _selectedCountryKey = null;
      
      if (company.logoUrl != null && company.logoUrl!.isNotEmpty) {
        _logoUrlController.text = company.logoUrl!;
        _useImageUpload = false;
      }
      
      _showSuggestions = false;
    });
    
    // إزالة التركيز من الحقول
    _nameArFocusNode.unfocus();
    _nameEnFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OriginalProductsController>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة شركة جديدة'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Obx(() {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // رأس الصفحة
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade50, Colors.blue.shade100],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.business,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'إضافة شركة جديدة',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'أضف معلومات الشركة الأساسية',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // اسم الشركة بالعربية مع الاقتراحات
                  _buildFormCard(
                    title: 'اسم الشركة بالعربية',
                    isRequired: true,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameArController,
                          focusNode: _nameArFocusNode,
                          decoration: InputDecoration(
                            hintText: 'مثال: آبل',
                            prefixIcon: Icon(Icons.business, color: Colors.blue.shade600),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'يرجى إدخال اسم الشركة بالعربية';
                            }
                            return null;
                          },
                          onTap: () {
                            if (_nameArController.text.isNotEmpty && _filteredCompanies.isNotEmpty) {
                              setState(() => _showSuggestions = true);
                            }
                          },
                        ),
                        
                        // قائمة الاقتراحات
                        if (_showSuggestions && _filteredCompanies.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _filteredCompanies.length > 5 ? 5 : _filteredCompanies.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final company = _filteredCompanies[index];
                                return ListTile(
                                  dense: true,
                                  leading: company.logoUrl != null && company.logoUrl!.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            company.logoUrl!,
                                            width: 32,
                                            height: 32,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => 
                                                Icon(Icons.business, size: 32, color: Colors.grey),
                                          ),
                                        )
                                      : Icon(Icons.business, size: 32, color: Colors.grey),
                                  title: Text(
                                    company.nameAr,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    '${company.nameEn} • ${company.country ?? 'غير محدد'}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'موجود',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.blue.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  onTap: () => _selectCompanySuggestion(company),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // اسم الشركة بالإنجليزية
                  _buildFormCard(
                    title: 'اسم الشركة بالإنجليزية',
                    isRequired: true,
                    child: TextFormField(
                      controller: _nameEnController,
                      focusNode: _nameEnFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Example: Apple',
                        prefixIcon: Icon(Icons.business_outlined, color: Colors.blue.shade600),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال اسم الشركة بالإنجليزية';
                        }
                        return null;
                      },
                      onTap: () {
                        if (_nameEnController.text.isNotEmpty && _filteredCompanies.isNotEmpty) {
                          setState(() => _showSuggestions = true);
                        }
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // اختيار البلد
                  _buildFormCard(
                    title: 'بلد الشركة',
                    isRequired: true,
                    child: InkWell(
                      onTap: () => _showCountrySelectionDialog(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.flag, color: Colors.blue.shade600),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedCountryKey != null 
                                    ? countryOptions[_selectedCountryKey]! 
                                    : 'اختر بلد الشركة',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _selectedCountryKey != null 
                                      ? Colors.black87 
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ),
                            Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // شعار الشركة
                  _buildFormCard(
                    title: 'شعار الشركة',
                    isRequired: false,
                    child: Column(
                      children: [
                        // أزرار التبديل بين الصورة والرابط
                        Row(
                          children: [
                            Expanded(
                              child: _buildToggleButton(
                                text: 'رفع صورة',
                                icon: Icons.upload,
                                isSelected: _useImageUpload,
                                onTap: () => setState(() {
                                  _useImageUpload = true;
                                  _logoUrlController.clear();
                                }),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildToggleButton(
                                text: 'رابط صورة',
                                icon: Icons.link,
                                isSelected: !_useImageUpload,
                                onTap: () => setState(() {
                                  _useImageUpload = false;
                                  _selectedImageBytes = null;
                                }),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // واجهة رفع الصورة أو الرابط
                        if (_useImageUpload) 
                          _buildImageUploadSection()
                        else 
                          _buildImageUrlSection(),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // أزرار الحفظ والإلغاء
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Get.back(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.grey.shade400),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'إلغاء',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: controller.isLoading.value ? null : _saveCompany,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: controller.isLoading.value
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'حفظ الشركة',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFormCard({
    required String title,
    required bool isRequired,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                if (isRequired) ...[
                  const SizedBox(width: 4),
                  const Text(
                    '*',
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton({
    required String text,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      children: [
        if (_selectedImageBytes != null) ...[
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                _selectedImageBytes!,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('تغيير الصورة'),
              ),
              const SizedBox(width: 16),
              TextButton.icon(
                onPressed: () => setState(() => _selectedImageBytes = null),
                icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                label: const Text('حذف الصورة', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ] else ...[
          InkWell(
            onTap: _pickImage,
            child: Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload, size: 40, color: Colors.grey.shade600),
                  const SizedBox(height: 8),
                  Text(
                    'اضغط لاختيار صورة',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'JPG, PNG (الحد الأقصى 5MB)',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImageUrlSection() {
    return Column(
      children: [
        TextFormField(
          controller: _logoUrlController,
          decoration: InputDecoration(
            hintText: 'https://example.com/logo.png',
            prefixIcon: Icon(Icons.link, color: Colors.blue.shade600),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
            ),
          ),
          validator: (value) {
            if (value != null && value.trim().isNotEmpty) {
              final uri = Uri.tryParse(value.trim());
              if (uri == null || !uri.hasAbsolutePath) {
                return 'يرجى إدخال رابط صحيح';
              }
            }
            return null;
          },
        ),
        if (_logoUrlController.text.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _logoUrlController.text,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade100,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, color: Colors.grey.shade400),
                        const SizedBox(height: 4),
                        Text(
                          'خطأ في تحميل الصورة',
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey.shade100,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showCountrySelectionDialog() {
    final searchController = TextEditingController();
    List<MapEntry<String, String>> filteredCountries = countryOptions.entries.toList();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: double.maxFinite,
                height: 500,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // عنوان الحوار
                    Row(
                      children: [
                        Icon(Icons.flag, color: Colors.blue.shade600),
                        const SizedBox(width: 8),
                        const Text(
                          'اختر بلد الشركة',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // حقل البحث
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'ابحث عن البلد...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          final query = value.toLowerCase();
                          filteredCountries = countryOptions.entries.where((entry) {
                            return entry.value.toLowerCase().contains(query);
                          }).toList();
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // قائمة البلدان
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredCountries.length,
                        itemBuilder: (context, index) {
                          final country = filteredCountries[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade50,
                              child: Text(
                                country.key,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                            title: Text(country.value),
                            subtitle: Text(country.key),
                            onTap: () {
                              setDialogState(() {
                                _selectedCountryKey = country.key;
                              });
                              Navigator.pop(context);
                            },
                            selected: _selectedCountryKey == country.key,
                            selectedTileColor: Colors.blue.shade50,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      
      // عرض خيارات اختيار الصورة
      final result = await showDialog<XFile?>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('اختر مصدر الصورة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('الكاميرا'),
                onTap: () async {
                  final image = await picker.pickImage(source: ImageSource.camera);
                  Navigator.pop(context, image);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('المعرض'),
                onTap: () async {
                  final image = await picker.pickImage(source: ImageSource.gallery);
                  Navigator.pop(context, image);
                },
              ),
            ],
          ),
        ),
      );

      if (result != null) {
        final bytes = await result.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء اختيار الصورة: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _saveCompany() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCountryKey == null) {
      Get.snackbar(
        'خطأ',
        'يرجى اختيار بلد الشركة',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final controller = Get.find<OriginalProductsController>();
    
    // التحقق من وجود الشركة
    final nameAr = _nameArController.text.trim();
    final nameEn = _nameEnController.text.trim();
    
    final exists = controller.companies.any((company) =>
        company.nameAr.toLowerCase() == nameAr.toLowerCase() ||
        company.nameEn.toLowerCase() == nameEn.toLowerCase());
    
    if (exists) {
      Get.snackbar(
        'خطأ',
        'اسم الشركة موجود بالفعل. يرجى اختيار اسم آخر',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      String? logoUrl;
      
      // رفع الصورة إذا كانت موجودة
      if (_useImageUpload && _selectedImageBytes != null) {
        logoUrl = await controller.uploadImage(_selectedImageBytes!, 'brand_companies');
      } else if (!_useImageUpload && _logoUrlController.text.trim().isNotEmpty) {
        logoUrl = _logoUrlController.text.trim();
      }
      
      final company = CompanyModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nameAr: nameAr,
        nameEn: nameEn,
        logoUrl: logoUrl,
        country: countryOptions[_selectedCountryKey!],
        isActive: true,
        createdBy: 'current_user', // TODO: استخدام المستخدم الحالي
        createdAt: DateTime.now(),
      );

      await controller.addCompany(company);
      Get.back();
      Get.snackbar(
        'نجح',
        'تم إضافة الشركة بنجاح',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء إضافة الشركة: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
      );
    }
  }
} 