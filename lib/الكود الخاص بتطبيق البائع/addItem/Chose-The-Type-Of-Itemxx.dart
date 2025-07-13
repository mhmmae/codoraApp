import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:codora/%D8%A7%D9%84%D9%83%D9%88%D8%AF%20%D8%A7%D9%84%D8%AE%D8%A7%D8%B5%20%D8%A8%D8%AA%D8%B7%D8%A8%D9%8A%D9%82%20%D8%A7%D9%84%D8%A8%D8%A7%D8%A6%D8%B9/addItem/video/Getx/GetChooseVideo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../Model/model_item.dart';
import '../../Model/model_offer_item.dart';
import '../../XXX/xxx_firebase.dart';

import 'dart:typed_data';
import 'dart:math';

import '../../الكود الخاص بتطبيق العميل /bottonBar/botonBar.dart';
import 'addNewItem/class/getAddManyImage.dart';


// الكلاس المسؤول عن اختيار نوع العنصر
class ChoseTheTypeOfItem1 extends StatelessWidget {
  const ChoseTheTypeOfItem1({super.key});

  @override
  Widget build(BuildContext context) {
    double hi = MediaQuery.of(context).size.height;
    double wi = MediaQuery.of(context).size.width;

    // استخدام GetBuilder لإدارة الحالة
    return GetBuilder<Getchosethetypeofitem>(
      init: Getchosethetypeofitem(),
      builder: (controller) {
        return ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(), // تعطيل التمرير
          children: [
            // حاوية تحتوي على عناصر يتم عرضها أفقياً
            Container(
              height: hi / 16,
              decoration: const BoxDecoration(
                border: Border.symmetric(horizontal: BorderSide(color: Colors.black)),
              ),
              child: ListView.builder(
                itemCount: controller.TheWher.length,
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  // لائحة أيقونات العنصر
                  List<Icon> icons = [
                    Icon(Icons.phone_android, size: wi / 22),
                    Icon(Icons.headphones, size: wi / 22),
                    Icon(Icons.tab, size: wi / 22),
                  ];

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: GestureDetector(
                      onTap: () {
                        controller.update(); // تحديث الحالة
                        controller.TheChosen = controller.TheWher[index];
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: controller.TheChosen != controller.TheWher[index]
                              ? Colors.black12
                              : Colors.deepPurpleAccent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black),
                        ),
                        width: wi / 3,
                        height: hi / 22,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 9),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              icons[index % icons.length], // اختيار الأيقونة بالدور
                              SizedBox(width: wi / 80),
                              Text(
                                controller.text[index],
                                style: TextStyle(fontSize: wi / 40),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// الكلاس المسؤول عن إدارة البيانات باستخدام GetX

class Getinformationofitem1 extends GetxController {
  Getinformationofitem1({ required this.uint8list,  required this.TypeItem});

  // --- متغيرات الحالة الإضافية ---
  final RxString sellerTypeAssociatedWithProduct = ''.obs;
  // -----------------------------

  // --- متغيرات الحالة ---
  final RxnString selectedItemConditionKey = RxnString(null); // Key: 'original' / 'commercial'
  final RxnInt selectedQualityGrade = RxnInt(null);        // Value: 1-10
  final RxnString selectedCountryOfOriginKey = RxnString(null); // Key: 'CN', 'US', ...
  final RxnString selectedCountryOfOriginAr = RxnString(null); // الاسم العربي
  final RxnString selectedCountryOfOriginEn = RxnString(null); // الاسم الإنجليزي
  final RxBool isCountryAutoSelected = false.obs; // لتتبع التحديد التلقائي لبلد المنشأ
  final RxnString selectedCategoryNameEn = RxnString(null);// يخزن المفتاح الإنجليزي nameEn
  
  // --- حقول الأقسام الجديدة ---
  final RxString selectedMainCategoryId = ''.obs;
  final RxString selectedSubCategoryId = ''.obs;
  final RxString selectedMainCategoryNameEn = ''.obs;
  final RxString selectedSubCategoryNameEn = ''.obs;
  final RxString selectedMainCategoryNameAr = ''.obs;
  final RxString selectedSubCategoryNameAr = ''.obs;
  
  // --- خيارات القوائم المنسدلة ---
  static const Map<String, String> itemConditionOptions = {'original': 'أصلي', 'commercial': 'تجاري'};
  List<DropdownMenuItem<String>> get conditionDropdownItems => itemConditionOptions.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList();

  static final  List<int> qualityGradeOptions = List.generate(10, (index) => index + 1);
  static const Map<int, String> qualityGradeDisplay = {1: '1', 2: '2', /*...*/ 10: '10'};
  List<DropdownMenuItem<int>> get qualityDropdownItems => qualityGradeOptions.map((g) => DropdownMenuItem(value: g, child: Text(qualityGradeDisplay[g] ?? g.toString()))).toList();
  
  // متغيرات لتتبع درجات الجودة المتاحة
  final RxList<int> availableQualityGrades = <int>[].obs;
  final RxList<int> unavailableQualityGrades = <int>[].obs;

  static const Map<String, Map<String, String>> countryOfOriginOptions = {
    'AD': {'ar': 'أندورا', 'en': 'Andorra'},
    'AE': {'ar': 'الإمارات العربية المتحدة', 'en': 'United Arab Emirates'},
    'AF': {'ar': 'أفغانستان', 'en': 'Afghanistan'},
    'AG': {'ar': 'أنتيغوا وباربودا', 'en': 'Antigua and Barbuda'},
    'AI': {'ar': 'أنغويلا', 'en': 'Anguilla'},
    'AL': {'ar': 'ألبانيا', 'en': 'Albania'},
    'AM': {'ar': 'أرمينيا', 'en': 'Armenia'},
    'AO': {'ar': 'أنغولا', 'en': 'Angola'},
    'AQ': {'ar': 'القارة القطبية الجنوبية', 'en': 'Antarctica'},
    'AR': {'ar': 'الأرجنتين', 'en': 'Argentina'},
    'AS': {'ar': 'ساموا الأمريكية', 'en': 'American Samoa'},
    'AT': {'ar': 'النمسا', 'en': 'Austria'},
    'AU': {'ar': 'أستراليا', 'en': 'Australia'},
    'AW': {'ar': 'أروبا', 'en': 'Aruba'},
    'AZ': {'ar': 'أذربيجان', 'en': 'Azerbaijan'},
    'BA': {'ar': 'البوسنة والهرسك', 'en': 'Bosnia and Herzegovina'},
    'BB': {'ar': 'بربادوس', 'en': 'Barbados'},
    'BD': {'ar': 'بنغلاديش', 'en': 'Bangladesh'},
    'BE': {'ar': 'بلجيكا', 'en': 'Belgium'},
    'BF': {'ar': 'بوركينا فاسو', 'en': 'Burkina Faso'},
    'BG': {'ar': 'بلغاريا', 'en': 'Bulgaria'},
    'BH': {'ar': 'البحرين', 'en': 'Bahrain'},
    'BI': {'ar': 'بوروندي', 'en': 'Burundi'},
    'BJ': {'ar': 'بنين', 'en': 'Benin'},
    'BM': {'ar': 'برمودا', 'en': 'Bermuda'},
    'BN': {'ar': 'بروناي', 'en': 'Brunei'},
    'BO': {'ar': 'بوليفيا', 'en': 'Bolivia'},
    'BR': {'ar': 'البرازيل', 'en': 'Brazil'},
    'BS': {'ar': 'الباهاما', 'en': 'Bahamas'},
    'BT': {'ar': 'بوتان', 'en': 'Bhutan'},
    'BW': {'ar': 'بوتسوانا', 'en': 'Botswana'},
    'BY': {'ar': 'بيلاروسيا', 'en': 'Belarus'},
    'BZ': {'ar': 'بليز', 'en': 'Belize'},
    'CA': {'ar': 'كندا', 'en': 'Canada'},
    'CD': {'ar': 'جمهورية الكونغو الديمقراطية', 'en': 'Democratic Republic of the Congo'},
    'CF': {'ar': 'جمهورية أفريقيا الوسطى', 'en': 'Central African Republic'},
    'CG': {'ar': 'الكونغو', 'en': 'Congo'},
    'CH': {'ar': 'سويسرا', 'en': 'Switzerland'},
    'CI': {'ar': 'ساحل العاج', 'en': 'Ivory Coast'},
    'CK': {'ar': 'جزر كوك', 'en': 'Cook Islands'},
    'CL': {'ar': 'تشيلي', 'en': 'Chile'},
    'CM': {'ar': 'الكاميرون', 'en': 'Cameroon'},
    'CN': {'ar': 'الصين', 'en': 'China'},
    'CO': {'ar': 'كولومبيا', 'en': 'Colombia'},
    'CR': {'ar': 'كوستاريكا', 'en': 'Costa Rica'},
    'CU': {'ar': 'كوبا', 'en': 'Cuba'},
    'CV': {'ar': 'الرأس الأخضر', 'en': 'Cape Verde'},
    'CY': {'ar': 'قبرص', 'en': 'Cyprus'},
    'CZ': {'ar': 'جمهورية التشيك', 'en': 'Czech Republic'},
    'DE': {'ar': 'ألمانيا', 'en': 'Germany'},
    'DJ': {'ar': 'جيبوتي', 'en': 'Djibouti'},
    'DK': {'ar': 'الدنمارك', 'en': 'Denmark'},
    'DM': {'ar': 'دومينيكا', 'en': 'Dominica'},
    'DO': {'ar': 'جمهورية الدومينيكان', 'en': 'Dominican Republic'},
    'DZ': {'ar': 'الجزائر', 'en': 'Algeria'},
    'EC': {'ar': 'الإكوادور', 'en': 'Ecuador'},
    'EE': {'ar': 'إستونيا', 'en': 'Estonia'},
    'EG': {'ar': 'مصر', 'en': 'Egypt'},
    'EH': {'ar': 'الصحراء الغربية', 'en': 'Western Sahara'},
    'ER': {'ar': 'إريتريا', 'en': 'Eritrea'},
    'ES': {'ar': 'إسبانيا', 'en': 'Spain'},
    'ET': {'ar': 'إثيوبيا', 'en': 'Ethiopia'},
    'FI': {'ar': 'فنلندا', 'en': 'Finland'},
    'FJ': {'ar': 'فيجي', 'en': 'Fiji'},
    'FK': {'ar': 'جزر فوكلاند', 'en': 'Falkland Islands'},
    'FM': {'ar': 'ميكرونيزيا', 'en': 'Micronesia'},
    'FO': {'ar': 'جزر فارو', 'en': 'Faroe Islands'},
    'FR': {'ar': 'فرنسا', 'en': 'France'},
    'GA': {'ar': 'الغابون', 'en': 'Gabon'},
    'GB': {'ar': 'المملكة المتحدة', 'en': 'United Kingdom'},
    'GD': {'ar': 'غرينادا', 'en': 'Grenada'},
    'GE': {'ar': 'جورجيا', 'en': 'Georgia'},
    'GF': {'ar': 'غويانا الفرنسية', 'en': 'French Guiana'},
    'GH': {'ar': 'غانا', 'en': 'Ghana'},
    'GI': {'ar': 'جبل طارق', 'en': 'Gibraltar'},
    'GL': {'ar': 'غرينلاند', 'en': 'Greenland'},
    'GM': {'ar': 'غامبيا', 'en': 'Gambia'},
    'GN': {'ar': 'غينيا', 'en': 'Guinea'},
    'GP': {'ar': 'غوادلوب', 'en': 'Guadeloupe'},
    'GQ': {'ar': 'غينيا الاستوائية', 'en': 'Equatorial Guinea'},
    'GR': {'ar': 'اليونان', 'en': 'Greece'},
    'GT': {'ar': 'غواتيمالا', 'en': 'Guatemala'},
    'GU': {'ar': 'غوام', 'en': 'Guam'},
    'GW': {'ar': 'غينيا بيساو', 'en': 'Guinea-Bissau'},
    'GY': {'ar': 'غويانا', 'en': 'Guyana'},
    'HK': {'ar': 'هونغ كونغ', 'en': 'Hong Kong'},
    'HN': {'ar': 'هندوراس', 'en': 'Honduras'},
    'HR': {'ar': 'كرواتيا', 'en': 'Croatia'},
    'HT': {'ar': 'هايتي', 'en': 'Haiti'},
    'HU': {'ar': 'هنغاريا', 'en': 'Hungary'},
    'ID': {'ar': 'إندونيسيا', 'en': 'Indonesia'},
    'IE': {'ar': 'أيرلندا', 'en': 'Ireland'},
    'IL': {'ar': 'إسرائيل', 'en': 'Israel'},
    'IN': {'ar': 'الهند', 'en': 'India'},
    'IQ': {'ar': 'العراق', 'en': 'Iraq'},
    'IR': {'ar': 'إيران', 'en': 'Iran'},
    'IS': {'ar': 'أيسلندا', 'en': 'Iceland'},
    'IT': {'ar': 'إيطاليا', 'en': 'Italy'},
    'JM': {'ar': 'جامايكا', 'en': 'Jamaica'},
    'JO': {'ar': 'الأردن', 'en': 'Jordan'},
    'JP': {'ar': 'اليابان', 'en': 'Japan'},
    'KE': {'ar': 'كينيا', 'en': 'Kenya'},
    'KG': {'ar': 'قيرغيزستان', 'en': 'Kyrgyzstan'},
    'KH': {'ar': 'كمبوديا', 'en': 'Cambodia'},
    'KI': {'ar': 'كيريباتي', 'en': 'Kiribati'},
    'KM': {'ar': 'جزر القمر', 'en': 'Comoros'},
    'KN': {'ar': 'سانت كيتس ونيفيس', 'en': 'Saint Kitts and Nevis'},
    'KP': {'ar': 'كوريا الشمالية', 'en': 'North Korea'},
    'KR': {'ar': 'كوريا الجنوبية', 'en': 'South Korea'},
    'KW': {'ar': 'الكويت', 'en': 'Kuwait'},
    'KY': {'ar': 'جزر كايمان', 'en': 'Cayman Islands'},
    'KZ': {'ar': 'كازاخستان', 'en': 'Kazakhstan'},
    'LA': {'ar': 'لاوس', 'en': 'Laos'},
    'LB': {'ar': 'لبنان', 'en': 'Lebanon'},
    'LC': {'ar': 'سانت لوسيا', 'en': 'Saint Lucia'},
    'LI': {'ar': 'ليختنشتاين', 'en': 'Liechtenstein'},
    'LK': {'ar': 'سريلانكا', 'en': 'Sri Lanka'},
    'LR': {'ar': 'ليبيريا', 'en': 'Liberia'},
    'LS': {'ar': 'ليسوتو', 'en': 'Lesotho'},
    'LT': {'ar': 'ليتوانيا', 'en': 'Lithuania'},
    'LU': {'ar': 'لوكسمبورغ', 'en': 'Luxembourg'},
    'LV': {'ar': 'لاتفيا', 'en': 'Latvia'},
    'LY': {'ar': 'ليبيا', 'en': 'Libya'},
    'MA': {'ar': 'المغرب', 'en': 'Morocco'},
    'MC': {'ar': 'موناكو', 'en': 'Monaco'},
    'MD': {'ar': 'مولدوفا', 'en': 'Moldova'},
    'ME': {'ar': 'الجبل الأسود', 'en': 'Montenegro'},
    'MG': {'ar': 'مدغشقر', 'en': 'Madagascar'},
    'MH': {'ar': 'جزر مارشال', 'en': 'Marshall Islands'},
    'MK': {'ar': 'مقدونيا الشمالية', 'en': 'North Macedonia'},
    'ML': {'ar': 'مالي', 'en': 'Mali'},
    'MM': {'ar': 'ميانمار', 'en': 'Myanmar'},
    'MN': {'ar': 'منغوليا', 'en': 'Mongolia'},
    'MO': {'ar': 'ماكاو', 'en': 'Macao'},
    'MP': {'ar': 'جزر ماريانا الشمالية', 'en': 'Northern Mariana Islands'},
    'MQ': {'ar': 'مارتينيك', 'en': 'Martinique'},
    'MR': {'ar': 'موريتانيا', 'en': 'Mauritania'},
    'MS': {'ar': 'مونتسرات', 'en': 'Montserrat'},
    'MT': {'ar': 'مالطا', 'en': 'Malta'},
    'MU': {'ar': 'موريشيوس', 'en': 'Mauritius'},
    'MV': {'ar': 'المالديف', 'en': 'Maldives'},
    'MW': {'ar': 'مالاوي', 'en': 'Malawi'},
    'MX': {'ar': 'المكسيك', 'en': 'Mexico'},
    'MY': {'ar': 'ماليزيا', 'en': 'Malaysia'},
    'MZ': {'ar': 'موزمبيق', 'en': 'Mozambique'},
    'NA': {'ar': 'ناميبيا', 'en': 'Namibia'},
    'NC': {'ar': 'كاليدونيا الجديدة', 'en': 'New Caledonia'},
    'NE': {'ar': 'النيجر', 'en': 'Niger'},
    'NF': {'ar': 'جزيرة نورفولك', 'en': 'Norfolk Island'},
    'NG': {'ar': 'نيجيريا', 'en': 'Nigeria'},
    'NI': {'ar': 'نيكاراغوا', 'en': 'Nicaragua'},
    'NL': {'ar': 'هولندا', 'en': 'Netherlands'},
    'NO': {'ar': 'النرويج', 'en': 'Norway'},
    'NP': {'ar': 'نيبال', 'en': 'Nepal'},
    'NR': {'ar': 'ناورو', 'en': 'Nauru'},
    'NU': {'ar': 'نيوي', 'en': 'Niue'},
    'NZ': {'ar': 'نيوزيلندا', 'en': 'New Zealand'},
    'OM': {'ar': 'عُمان', 'en': 'Oman'},
    'PA': {'ar': 'بنما', 'en': 'Panama'},
    'PE': {'ar': 'بيرو', 'en': 'Peru'},
    'PF': {'ar': 'بولينيزيا الفرنسية', 'en': 'French Polynesia'},
    'PG': {'ar': 'بابوا غينيا الجديدة', 'en': 'Papua New Guinea'},
    'PH': {'ar': 'الفلبين', 'en': 'Philippines'},
    'PK': {'ar': 'باكستان', 'en': 'Pakistan'},
    'PL': {'ar': 'بولندا', 'en': 'Poland'},
    'PM': {'ar': 'سان بيير وميكلون', 'en': 'Saint Pierre and Miquelon'},
    'PN': {'ar': 'جزر بيتكيرن', 'en': 'Pitcairn Islands'},
    'PR': {'ar': 'بورتوريكو', 'en': 'Puerto Rico'},
    'PS': {'ar': 'فلسطين', 'en': 'Palestine'},
    'PT': {'ar': 'البرتغال', 'en': 'Portugal'},
    'PW': {'ar': 'بالاو', 'en': 'Palau'},
    'PY': {'ar': 'باراغواي', 'en': 'Paraguay'},
    'QA': {'ar': 'قطر', 'en': 'Qatar'},
    'RE': {'ar': 'لا ريونيون', 'en': 'Réunion'},
    'RO': {'ar': 'رومانيا', 'en': 'Romania'},
    'RS': {'ar': 'صربيا', 'en': 'Serbia'},
    'RU': {'ar': 'روسيا', 'en': 'Russia'},
    'RW': {'ar': 'رواندا', 'en': 'Rwanda'},
    'SA': {'ar': 'السعودية', 'en': 'Saudi Arabia'},
    'SB': {'ar': 'جزر سليمان', 'en': 'Solomon Islands'},
    'SC': {'ar': 'سيشل', 'en': 'Seychelles'},
    'SD': {'ar': 'السودان', 'en': 'Sudan'},
    'SE': {'ar': 'السويد', 'en': 'Sweden'},
    'SG': {'ar': 'سنغافورة', 'en': 'Singapore'},
    'SH': {'ar': 'سانت هيلينا', 'en': 'Saint Helena'},
    'SI': {'ar': 'سلوفينيا', 'en': 'Slovenia'},
    'SK': {'ar': 'سلوفاكيا', 'en': 'Slovakia'},
    'SL': {'ar': 'سيراليون', 'en': 'Sierra Leone'},
    'SM': {'ar': 'سان مارينو', 'en': 'San Marino'},
    'SN': {'ar': 'السنغال', 'en': 'Senegal'},
    'SO': {'ar': 'الصومال', 'en': 'Somalia'},
    'SR': {'ar': 'سورينام', 'en': 'Suriname'},
    'ST': {'ar': 'ساو تومي وبرينسيبي', 'en': 'São Tomé and Príncipe'},
    'SV': {'ar': 'السلفادور', 'en': 'El Salvador'},
    'SY': {'ar': 'سوريا', 'en': 'Syria'},
    'SZ': {'ar': 'إسواتيني', 'en': 'Eswatini'},
    'TC': {'ar': 'جزر تركس وكايكوس', 'en': 'Turks and Caicos Islands'},
    'TD': {'ar': 'تشاد', 'en': 'Chad'},
    'TF': {'ar': 'الأقاليم الفرنسية الجنوبية', 'en': 'French Southern Territories'},
    'TG': {'ar': 'توغو', 'en': 'Togo'},
    'TH': {'ar': 'تايلاند', 'en': 'Thailand'},
    'TJ': {'ar': 'طاجيكستان', 'en': 'Tajikistan'},
    'TK': {'ar': 'توكيلاو', 'en': 'Tokelau'},
    'TL': {'ar': 'تيمور الشرقية', 'en': 'East Timor'},
    'TM': {'ar': 'تركمانستان', 'en': 'Turkmenistan'},
    'TN': {'ar': 'تونس', 'en': 'Tunisia'},
    'TO': {'ar': 'تونغا', 'en': 'Tonga'},
    'TR': {'ar': 'تركيا', 'en': 'Turkey'},
    'TT': {'ar': 'ترينيداد وتوباغو', 'en': 'Trinidad and Tobago'},
    'TV': {'ar': 'توفالو', 'en': 'Tuvalu'},
    'TW': {'ar': 'تايوان', 'en': 'Taiwan'},
    'TZ': {'ar': 'تنزانيا', 'en': 'Tanzania'},
    'UA': {'ar': 'أوكرانيا', 'en': 'Ukraine'},
    'UG': {'ar': 'أوغندا', 'en': 'Uganda'},
    'UM': {'ar': 'جزر الولايات المتحدة النائية', 'en': 'United States Minor Outlying Islands'},
    'US': {'ar': 'الولايات المتحدة', 'en': 'United States'},
    'UY': {'ar': 'أوروغواي', 'en': 'Uruguay'},
    'UZ': {'ar': 'أوزبكستان', 'en': 'Uzbekistan'},
    'VA': {'ar': 'الفاتيكان', 'en': 'Vatican City'},
    'VC': {'ar': 'سانت فنسنت والغرينادين', 'en': 'Saint Vincent and the Grenadines'},
    'VE': {'ar': 'فنزويلا', 'en': 'Venezuela'},
    'VG': {'ar': 'جزر العذراء البريطانية', 'en': 'British Virgin Islands'},
    'VI': {'ar': 'جزر العذراء الأمريكية', 'en': 'United States Virgin Islands'},
    'VN': {'ar': 'فيتنام', 'en': 'Vietnam'},
    'VU': {'ar': 'فانواتو', 'en': 'Vanuatu'},
    'WF': {'ar': 'واليس وفوتونا', 'en': 'Wallis and Futuna'},
    'WS': {'ar': 'ساموا', 'en': 'Samoa'},
    'YE': {'ar': 'اليمن', 'en': 'Yemen'},
    'YT': {'ar': 'مايوت', 'en': 'Mayotte'},
    'ZA': {'ar': 'جنوب أفريقيا', 'en': 'South Africa'},
    'ZM': {'ar': 'زامبيا', 'en': 'Zambia'},
    'ZW': {'ar': 'زيمبابوي', 'en': 'Zimbabwe'},
  };
  List<DropdownMenuItem<String>> get countryDropdownItems => countryOfOriginOptions.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value['ar']!))).toList();
  // ----------------------------------------------------------

  // --- دوال تحديث الاختيارات (تحديث قيمة .value للمتغيرات الـ Rx) ---
  void updateItemCondition(String? valueKey) {
    selectedItemConditionKey.value = valueKey; // تحديث قيمة الـ Rx variable
    debugPrint("Condition Key updated: ${selectedItemConditionKey.value}");
    // لا حاجة لـ update() هنا
  }

  void updateQualityGrade(int? value) {
    selectedQualityGrade.value = value; // تحديث قيمة الـ Rx variable
    debugPrint("Quality updated: ${selectedQualityGrade.value}");
    // لا حاجة لـ update() هنا
  }
  
  /// دالة لحساب عدد المنتجات الموجودة للبائع الحالي بنفس الأقسام ودرجة الجودة
  Future<int> getProductCountByQualityAndCategory(int qualityGrade, String mainCategoryId, String subCategoryId) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) return 0;
      
      final String currentUserId = currentUser.uid;
      
      // البحث في المنتجات
      final QuerySnapshot snapshot = await firestore
          .collection(FirebaseX.itemsCollection)
          .where('uidAdd', isEqualTo: currentUserId)
          .where('qualityGrade', isEqualTo: qualityGrade)
          .where('mainCategoryId', isEqualTo: mainCategoryId)
          .where('subCategoryId', isEqualTo: subCategoryId)
          .get();
          
      debugPrint("🔍 عدد المنتجات الموجودة - درجة الجودة $qualityGrade: ${snapshot.docs.length}");
      return snapshot.docs.length;
    } catch (e) {
      debugPrint("❌ خطأ في حساب المنتجات: $e");
      return 0;
    }
  }
  
  /// دالة لتحديث درجات الجودة المتاحة بناءً على الأقسام المختارة
  Future<void> updateAvailableQualityGrades() async {
    // التحقق من وجود أقسام مختارة
    if (selectedMainCategoryId.value.isEmpty || selectedSubCategoryId.value.isEmpty) {
      // إذا لم يتم اختيار أقسام، جعل جميع الدرجات متاحة
      availableQualityGrades.value = List.from(qualityGradeOptions);
      unavailableQualityGrades.clear();
      debugPrint("🔓 لم يتم اختيار أقسام - جميع درجات الجودة متاحة");
      return;
    }
    
    List<int> available = [];
    List<int> unavailable = [];
    
    for (int grade = 1; grade <= 10; grade++) {
      final int currentCount = await getProductCountByQualityAndCategory(
        grade, 
        selectedMainCategoryId.value, 
        selectedSubCategoryId.value
      );
      
      if (grade == 10) {
        // درجة 10 دائماً متاحة (عدد لا نهائي)
        available.add(grade);
        debugPrint("✅ درجة الجودة $grade: متاحة (عدد لا نهائي)");
      } else if (currentCount < grade) {
        // يمكن إضافة المزيد
        available.add(grade);
        debugPrint("✅ درجة الجودة $grade: متاحة ($currentCount/$grade)");
      } else {
        // وصل للحد الأقصى
        unavailable.add(grade);
        debugPrint("❌ درجة الجودة $grade: غير متاحة ($currentCount/$grade)");
      }
    }
    
    availableQualityGrades.value = available;
    unavailableQualityGrades.value = unavailable;
    
    debugPrint("📊 ملخص درجات الجودة:");
    debugPrint("   متاحة: ${available.join(', ')}");
    debugPrint("   غير متاحة: ${unavailable.join(', ')}");
  }

  void updateCountryOfOrigin(String? valueKey, {bool isAutoSelected = false}) {
    selectedCountryOfOriginKey.value = valueKey; // تحديث قيمة الـ Rx variable
    isCountryAutoSelected.value = isAutoSelected; // تحديث حالة التحديد التلقائي
    
    // تحديث الأسماء باللغتين
    if (valueKey != null && countryOfOriginOptions.containsKey(valueKey)) {
      selectedCountryOfOriginAr.value = countryOfOriginOptions[valueKey]!['ar']; // الاسم العربي
      selectedCountryOfOriginEn.value = countryOfOriginOptions[valueKey]!['en']; // الاسم الإنجليزي
    } else {
      selectedCountryOfOriginAr.value = null;
      selectedCountryOfOriginEn.value = null;
    }
    
    debugPrint("Country updated: Key=${selectedCountryOfOriginKey.value}, AR=${selectedCountryOfOriginAr.value}, EN=${selectedCountryOfOriginEn.value} (Auto: $isAutoSelected)");
    // لا حاجة لـ update() هنا
  }

  void updateSelectedCategory(String? valueKey) {
    selectedCategoryNameEn.value = valueKey; // تحديث قيمة الـ Rx variable
    debugPrint("Category Key updated: ${selectedCategoryNameEn.value}");
    // لا حاجة لـ update() هنا
  }
  
  // --- دالة تحديث معلومات الأقسام ---
  void updateCategories(String mainCategoryId, String subCategoryId, String mainCategoryNameEn, String subCategoryNameEn) {
    selectedMainCategoryId.value = mainCategoryId;
    selectedSubCategoryId.value = subCategoryId;
    selectedMainCategoryNameEn.value = mainCategoryNameEn;
    selectedSubCategoryNameEn.value = subCategoryNameEn;
    debugPrint("Categories updated: $mainCategoryId, $subCategoryId");
    
    // تحديث درجات الجودة المتاحة بعد اختيار الأقسام
    updateAvailableQualityGrades();
  }
  
  // --- دالة تحديث معلومات الأقسام مع الأسماء العربية ---
  void updateCategoriesWithArabicNames(String mainCategoryId, String subCategoryId, 
      String mainCategoryNameEn, String subCategoryNameEn,
      String mainCategoryNameAr, String subCategoryNameAr) {
    
    // إصلاح البيانات المخلوطة - وضع كل اسم في مكانه الصحيح
    String finalMainAr = mainCategoryNameAr;
    String finalMainEn = mainCategoryNameEn;
    String finalSubAr = subCategoryNameAr;
    String finalSubEn = subCategoryNameEn;
    
    // التحقق من النصوص العربية باستخدام RegExp
    bool mainEnIsArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(mainCategoryNameEn);
    bool subEnIsArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(subCategoryNameEn);
    
    debugPrint("🔍 تحليل البيانات الواردة:");
    debugPrint("  mainCategoryNameEn: '$mainCategoryNameEn' (عربي؟ $mainEnIsArabic)");
    debugPrint("  subCategoryNameEn: '$subCategoryNameEn' (عربي؟ $subEnIsArabic)");
    debugPrint("  mainCategoryNameAr: '$mainCategoryNameAr'");
    debugPrint("  subCategoryNameAr: '$subCategoryNameAr'");
    
    // إصلاح القسم الرئيسي
    if (mainEnIsArabic) {
      debugPrint("❌ mainCategoryNameEn يحتوي على نص عربي!");
      finalMainAr = mainCategoryNameEn; // نقل العربي لمكانه الصحيح
      finalMainEn = 'Unknown Category'; // قيمة افتراضية للإنجليزي
      debugPrint("✅ تم التصحيح: العربي='$finalMainAr'، الإنجليزي='$finalMainEn'");
    }
    
    // إصلاح القسم الفرعي
    if (subEnIsArabic) {
      debugPrint("❌ subCategoryNameEn يحتوي على نص عربي!");
      finalSubAr = subCategoryNameEn; // نقل العربي لمكانه الصحيح
      finalSubEn = 'Unknown Subcategory'; // قيمة افتراضية للإنجليزي
      debugPrint("✅ تم التصحيح: العربي='$finalSubAr'، الإنجليزي='$finalSubEn'");
    }
    
    // ضمان عدم وجود قيم فارغة
    finalMainAr = finalMainAr.isNotEmpty ? finalMainAr : 'قسم غير محدد';
    finalSubAr = finalSubAr.isNotEmpty ? finalSubAr : 'قسم فرعي غير محدد';
    finalMainEn = finalMainEn.isNotEmpty ? finalMainEn : 'Unknown Category';
    finalSubEn = finalSubEn.isNotEmpty ? finalSubEn : 'Unknown Subcategory';
    
    // حفظ القيم المصححة
    selectedMainCategoryId.value = mainCategoryId;
    selectedSubCategoryId.value = subCategoryId;
    selectedMainCategoryNameEn.value = finalMainEn;
    selectedSubCategoryNameEn.value = finalSubEn;
    selectedMainCategoryNameAr.value = finalMainAr;
    selectedSubCategoryNameAr.value = finalSubAr;
    
    debugPrint("✅ ===== النتيجة النهائية بعد الإصلاح =====");
    debugPrint("📁 Main Category ID: $mainCategoryId");
    debugPrint("📂 Sub Category ID: $subCategoryId");
    debugPrint("🇺🇸 Main Category Name EN: '$finalMainEn'");
    debugPrint("🇦🇪 Main Category Name AR: '$finalMainAr'");
    debugPrint("🇺🇸 Sub Category Name EN: '$finalSubEn'");
    debugPrint("🇦🇪 Sub Category Name AR: '$finalSubAr'");
    debugPrint("========================================");
    
    // تحديث درجات الجودة المتاحة بعد اختيار الأقسام
    updateAvailableQualityGrades();
  }
  // ---------------
  // --- المتغيرات العامة ---
  final String TypeItem; // 'Item' or 'Offer'
  var isSend = false.obs;

  // --- الحقول النصية ---
  final TextEditingController nameOfItem = TextEditingController();
  final TextEditingController priceOfItem = TextEditingController();
  final TextEditingController costPriceOfItem = TextEditingController();
  final TextEditingController descriptionOfItem = TextEditingController();
  final TextEditingController rate = TextEditingController(); // فقط للعروض
  final TextEditingController oldPrice = TextEditingController(); // فقط للعروض
  final TextEditingController productBarcode = TextEditingController(); // باركود المنتج
  final TextEditingController mainProductBarcode = TextEditingController(); // الباركود الرئيسي للمنتج
  final TextEditingController productQuantity = TextEditingController(); // كمية المنتج
  final TextEditingController quantityPerCarton = TextEditingController(); // كمية المنتج في الكارتونة الواحدة (للبائع الجملة فقط)
  final TextEditingController suggestedRetailPrice = TextEditingController(); // السعر المقترح للبائع المفرد (للبائع الجملة فقط)
  final RxList<String> productBarcodes = <String>[].obs; // قائمة باركودات المنتج
  final RxList<String> imageUrlList = <String>[].obs; // قائمة صور المنتج
  final GlobalKey<FormState> globalKey = GlobalKey<FormState>();
  
  // --- معلومات المنتج الأصلي ---
  final RxString originalCompanyId = ''.obs; // معرف الشركة الأصلية
  final RxString originalProductId = ''.obs; // معرف المنتج الأصلي
  final RxString originalCompanyName = ''.obs; // اسم الشركة الأصلية
  final RxString originalProductName = ''.obs; // اسم المنتج الأصلي
  
  final Uint8List uint8list; // تأتي من المُنشئ

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage firebaseStorage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void onInit() {
    super.onInit();
    // تعيين قيمة تحميل أولاً لتجنب إظهار معلومات خاطئة
    sellerTypeAssociatedWithProduct.value = 'loading';
    _fetchSellerType();
    
    // تهيئة جميع درجات الجودة كمتاحة في البداية (قبل اختيار الأقسام)
    availableQualityGrades.value = List.from(qualityGradeOptions);
    unavailableQualityGrades.clear();
  }

  Future<void> _fetchSellerType() async {
    // تعيين حالة التحميل
    sellerTypeAssociatedWithProduct.value = 'loading';
    
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        debugPrint("محاولة جلب نوع البائع للمستخدم: ${currentUser.uid}");
        
        final DocumentSnapshot sellerDoc = await firestore
            .collection(FirebaseX.collectionSeller)
            .doc(currentUser.uid)
            .get();
            
        if (sellerDoc.exists && sellerDoc.data() != null) {
          final data = sellerDoc.data() as Map<String, dynamic>;
          final String? sellerType = data['sellerType'] as String?;
          
          if (sellerType != null && sellerType.isNotEmpty) {
            sellerTypeAssociatedWithProduct.value = sellerType;
            debugPrint("✅ تم جلب نوع البائع بنجاح: $sellerType");
          } else {
            sellerTypeAssociatedWithProduct.value = 'retail'; // قيمة افتراضية
            debugPrint("⚠️ نوع البائع غير محدد في قاعدة البيانات - تم تعيين 'retail' كقيمة افتراضية");
          }
        } else {
          sellerTypeAssociatedWithProduct.value = 'retail'; // قيمة افتراضية
          debugPrint("⚠️ مستند البائع غير موجود للمستخدم: ${currentUser.uid} - تم تعيين 'retail' كقيمة افتراضية");
          
          // محاولة إنشاء مستند البائع تلقائياً
          await _createDefaultSellerDocument(currentUser.uid);
        }
      } else {
        sellerTypeAssociatedWithProduct.value = 'anonymous';
        debugPrint("❌ لا يوجد مستخدم مسجل الدخول");
      }
    } catch (e) {
      debugPrint("❌ خطأ في جلب نوع البائع: $e");
      sellerTypeAssociatedWithProduct.value = 'retail'; // قيمة افتراضية عند الخطأ
      
      // عرض رسالة خطأ اختيارية للمستخدم
      Get.snackbar(
        'تنبيه',
        'لا يمكن تحديد نوع البائع، سيتم استخدام نوع البائع الافتراضي (تجزئة)',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
    }
  }

  // دالة مساعدة لإنشاء مستند البائع الافتراضي
  Future<void> _createDefaultSellerDocument(String uid) async {
    try {
      await firestore.collection(FirebaseX.collectionSeller).doc(uid).set({
        'sellerType': 'retail',
        'createdAt': FieldValue.serverTimestamp(),
        'isDefaultCreated': true,
      }, SetOptions(merge: true)); // merge: true للحفاظ على البيانات الموجودة
      
      debugPrint("✅ تم إنشاء مستند البائع الافتراضي بنجاح");
    } catch (e) {
      debugPrint("❌ فشل في إنشاء مستند البائع الافتراضي: $e");
    }
  }

  // دالة إعادة جلب نوع البائع يدوياً
  Future<void> refreshSellerType() async {
    debugPrint("🔄 بدء إعادة جلب نوع البائع يدوياً...");
    await _fetchSellerType();
  }

  // دالة لإنشاء باركود عشوائي
  String generateRandomBarcode() {
    const chars = '0123456789';
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final randomPart = List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
    return 'PRD$timestamp$randomPart';
  }

  // دالة للتأكد من وجود باركود رئيسي قبل الحفظ
  void ensureMainBarcodeExists() {
    if (mainProductBarcode.text.trim().isEmpty) {
      mainProductBarcode.text = generateRandomBarcode();
      debugPrint("✅ تم إنشاء باركود رئيسي عشوائي تلقائياً: ${mainProductBarcode.text}");
    } else {
      debugPrint("✅ باركود رئيسي موجود مُدخل من المستخدم: ${mainProductBarcode.text}");
    }
  }

  // --- دالة مساعدة لمسح الحقول ---
  void _resetFields() {
    nameOfItem.clear();
    priceOfItem.clear();
    costPriceOfItem.clear();
    descriptionOfItem.clear();
    selectedCategoryNameEn.value = null;
    rate.clear();
    oldPrice.clear();
    productBarcode.clear(); // مسح حقل الباركود
    mainProductBarcode.clear(); // مسح الباركود الرئيسي
    productQuantity.clear(); // مسح حقل الكمية
      quantityPerCarton.clear(); // مسح حقل كمية المنتج في الكارتونة
      suggestedRetailPrice.clear(); // مسح حقل السعر المقترح للبائع المفرد
    productBarcodes.clear(); // مسح قائمة الباركودات
    selectedItemConditionKey.value = null;
    selectedQualityGrade.value = null;
    selectedCountryOfOriginKey.value = null;
    selectedCountryOfOriginAr.value = null;
    selectedCountryOfOriginEn.value = null;
    isCountryAutoSelected.value = false; // إعادة تعيين حالة التحديد التلقائي
    
    // مسح معلومات الأقسام
    selectedMainCategoryId.value = '';
    selectedSubCategoryId.value = '';
    selectedMainCategoryNameEn.value = '';
    selectedSubCategoryNameEn.value = '';
    selectedMainCategoryNameAr.value = '';
    selectedSubCategoryNameAr.value = '';
    
    // مسح معلومات المنتج الأصلي
    originalCompanyId.value = '';
    originalProductId.value = '';
    originalCompanyName.value = '';
    originalProductName.value = '';
    
    // إعادة تعيين درجات الجودة لحالة البداية (جميع الدرجات متاحة)
    availableQualityGrades.value = List.from(qualityGradeOptions);
    unavailableQualityGrades.clear();
    
    globalKey.currentState?.reset();
    Get.find<GetChooseVideo>().deleteVideo();
    Get.find<GetAddManyImage>().reset();
    debugPrint("Fields Reset!");
  }

  // --- الوظيفة التي تحفظ البيانات ---
  Future<void> saveData( BuildContext context) async {
    if (!(globalKey.currentState?.validate() ?? false)) {
      debugPrint("Form validation failed!");
      Get.rawSnackbar(message: "يرجى ملء جميع الحقول المطلوبة.", backgroundColor: Colors.orange.shade700);
      return;
    }

    // التأكد من وجود باركود رئيسي
    ensureMainBarcodeExists();

    // إعلان المتغيرات المحلية في بداية الدالة لضمان الوصول إليها
    String finalMainCategoryNameAr = selectedMainCategoryNameAr.value.isEmpty ? 'غير محدد' : selectedMainCategoryNameAr.value;
    String finalMainCategoryNameEn = selectedMainCategoryNameEn.value.isEmpty ? 'undefined' : selectedMainCategoryNameEn.value;
    String finalSubCategoryNameAr = selectedSubCategoryNameAr.value.isEmpty ? 'غير محدد' : selectedSubCategoryNameAr.value;
    String finalSubCategoryNameEn = selectedSubCategoryNameEn.value.isEmpty ? 'undefined' : selectedSubCategoryNameEn.value;

    debugPrint("💾 قيم الأقسام الأولية:");
    debugPrint("   Main AR: '$finalMainCategoryNameAr' | EN: '$finalMainCategoryNameEn'");
    debugPrint("   Sub AR: '$finalSubCategoryNameAr' | EN: '$finalSubCategoryNameEn'");

    // تحديث المتغيرات إذا تحسنت القيم أثناء العمليات
    if (selectedMainCategoryNameAr.value.isNotEmpty && selectedMainCategoryNameAr.value != 'غير محدد') {
      finalMainCategoryNameAr = selectedMainCategoryNameAr.value;
    }
    if (selectedMainCategoryNameEn.value.isNotEmpty && selectedMainCategoryNameEn.value != 'undefined') {
      finalMainCategoryNameEn = selectedMainCategoryNameEn.value;
    }
    if (selectedSubCategoryNameAr.value.isNotEmpty && selectedSubCategoryNameAr.value != 'غير محدد') {
      finalSubCategoryNameAr = selectedSubCategoryNameAr.value;
    }
    if (selectedSubCategoryNameEn.value.isNotEmpty && selectedSubCategoryNameEn.value != 'undefined') {
      finalSubCategoryNameEn = selectedSubCategoryNameEn.value;
    }

    debugPrint("🔄 قيم الأقسام النهائية المحدثة:");
    debugPrint("   Main AR: '$finalMainCategoryNameAr' | EN: '$finalMainCategoryNameEn'");
    debugPrint("   Sub AR: '$finalSubCategoryNameAr' | EN: '$finalSubCategoryNameEn'");

    if (costPriceOfItem.text.isEmpty) {
      _showErrorDialog('يرجى إدخال سعر تكلفة المنتج.');
      return;
    }
    final double? costPrice = double.tryParse(costPriceOfItem.text);
    if (costPrice == null || costPrice <= 0) {
      _showErrorDialog('سعر تكلفة المنتج يجب أن يكون رقماً أكبر من الصفر.');
      return;
    }

    final double? sellingPrice = double.tryParse(priceOfItem.text);
    if (sellingPrice == null || sellingPrice <= 0) {
      _showErrorDialog('سعر بيع المنتج يجب أن يكون رقماً أكبر من الصفر.');
      return;
    }

    if (TypeItem == FirebaseX.itemsCollection) {
      if (selectedCategoryNameEn.value == null || selectedCategoryNameEn.value!.isEmpty) { _showErrorDialog('اختر قسم المنتج.'); return; }
      if (selectedItemConditionKey.value == null) { _showErrorDialog('اختر حالة المنتج.'); return; }
      if (selectedQualityGrade.value == null) { _showErrorDialog('اختر درجة الجودة.'); return; }
      
      // التحقق من حد درجة الجودة المسموح
      final int selectedGrade = selectedQualityGrade.value!;
      if (selectedGrade != 10) { // درجة 10 لا تخضع للحد
        final int currentCount = await getProductCountByQualityAndCategory(
          selectedGrade, 
          selectedMainCategoryId.value, 
          selectedSubCategoryId.value
        );
        
        if (currentCount >= selectedGrade) {
          _showErrorDialog('لا يمكن إضافة المزيد من المنتجات بدرجة الجودة $selectedGrade.\nالحد الأقصى: $selectedGrade منتج، الموجود حالياً: $currentCount منتج.');
          return;
        } else {
          debugPrint("✅ يمكن إضافة منتج بدرجة الجودة $selectedGrade ($currentCount/$selectedGrade)");
        }
      } else {
        debugPrint("✅ درجة الجودة 10 - عدد لا نهائي مسموح");
      }
      
      if (selectedCountryOfOriginKey.value == null) { _showErrorDialog('اختر بلد المنشأ.'); return; }
      
      // التحقق من المتطلبات حسب نوع المنتج
      if (selectedItemConditionKey.value == 'original') {
        // للمنتجات الأصلية: يجب اختيار الشركة المصنعة والمنتج التابع
        if (originalCompanyId.value.isEmpty || originalCompanyName.value.isEmpty) {
          _showErrorDialog('يجب اختيار الشركة المصنعة للمنتج الأصلي.');
          return;
        }
        if (originalProductId.value.isEmpty || originalProductName.value.isEmpty) {
          _showErrorDialog('يجب اختيار المنتج التابع للشركة المصنعة.');
          return;
        }
      } else if (selectedItemConditionKey.value == 'commercial') {
        // للمنتجات التجارية: يجب اختيار القسم الرئيسي والفرعي
        if (selectedMainCategoryId.value.isEmpty) {
          _showErrorDialog('يجب اختيار القسم الرئيسي للمنتج التجاري.');
          return;
        }
        if (selectedSubCategoryId.value.isEmpty) {
          _showErrorDialog('يجب اختيار القسم الفرعي للمنتج التجاري.');
          return;
        }
        // التحقق من أن أسماء الأقسام صحيحة
        if (selectedMainCategoryNameAr.value.isEmpty || selectedMainCategoryNameAr.value == 'غير محدد' ||
            selectedMainCategoryNameEn.value.isEmpty || selectedMainCategoryNameEn.value == 'undefined') {
          _showErrorDialog('خطأ في بيانات القسم الرئيسي. يرجى إعادة اختيار القسم.');
          return;
        }
        if (selectedSubCategoryNameAr.value.isEmpty || selectedSubCategoryNameAr.value == 'غير محدد' ||
            selectedSubCategoryNameEn.value.isEmpty || selectedSubCategoryNameEn.value == 'undefined') {
          _showErrorDialog('خطأ في بيانات القسم الفرعي. يرجى إعادة اختيار القسم.');
          return;
        }
      }
      
      // تحقق إضافي لضمان وجود أسماء الأقسام للمنتجات الأصلية
      if (selectedItemConditionKey.value == 'original' && originalProductId.value.isNotEmpty) {
        bool hasValidCategoryNames = 
            selectedMainCategoryNameAr.value.isNotEmpty && 
            selectedMainCategoryNameEn.value.isNotEmpty &&
            selectedSubCategoryNameAr.value.isNotEmpty && 
            selectedSubCategoryNameEn.value.isNotEmpty &&
            selectedMainCategoryNameAr.value != 'غير محدد' &&
            selectedMainCategoryNameEn.value != 'undefined' &&
            selectedSubCategoryNameAr.value != 'غير محدد' &&
            selectedSubCategoryNameEn.value != 'undefined';
            
        if (!hasValidCategoryNames) {
          debugPrint("❌ خطأ في أسماء الأقسام:");
          debugPrint("   Main AR: '${selectedMainCategoryNameAr.value}'");
          debugPrint("   Main EN: '${selectedMainCategoryNameEn.value}'");
          debugPrint("   Sub AR: '${selectedSubCategoryNameAr.value}'");
          debugPrint("   Sub EN: '${selectedSubCategoryNameEn.value}'");
          _showErrorDialog('خطأ في بيانات الأقسام. يرجى إعادة اختيار المنتج الأصلي والتأكد من اختيار منتج يحتوي على معلومات أقسام صحيحة.');
          return;
        } else {
          debugPrint("✅ جميع أسماء الأقسام صحيحة للمنتج الأصلي");
        }
      }
    } else if (TypeItem == FirebaseX.offersCollection) {
       if (oldPrice.text.isEmpty) { _showErrorDialog('يرجى إدخال السعر القديم للعرض.'); return; }
       final double? oldSellingPrice = double.tryParse(oldPrice.text);
       if (oldSellingPrice == null || oldSellingPrice <= 0) { _showErrorDialog('السعر القديم للعرض يجب أن يكون رقماً أكبر من الصفر.'); return;}
       if (rate.text.isEmpty) { _showErrorDialog('يرجى إدخال نسبة الخصم.'); return;}
       final int? discountRate = int.tryParse(rate.text);
       if (discountRate == null || discountRate <= 0 || discountRate >= 100) { _showErrorDialog('نسبة الخصم يجب أن تكون بين 1 و 99.'); return; }
       if (sellingPrice >= oldSellingPrice) { _showErrorDialog('سعر العرض يجب أن يكون أقل من السعر القديم.'); return; }
    }

    isSend.value = true;
    update(['sendButton']);
    List<String> finalManyImageUrls = [];
    String? finalVideoUrlValue;

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        _showErrorDialog("خطأ: لم يتم تسجيل دخول المستخدم.");
        isSend.value = false;
        update(['sendButton']);
        return;
      }
      final String currentUserId = currentUser.uid;

      final uid2 = const Uuid().v4();

      debugPrint("Uploading main image...");
      Reference storage = firebaseStorage.ref(FirebaseX.StorgeApp).child(uid2).child('mainImage_${DateTime.now().millisecondsSinceEpoch}');
      UploadTask uploadTask = storage.putData(uint8list);
      TaskSnapshot taskSnapshot = await uploadTask;
      String url = await taskSnapshot.ref.getDownloadURL();
      debugPrint("Main image uploaded: $url");

      final GetChooseVideo videoController = Get.find<GetChooseVideo>();
      if (videoController.file != null) { 
        debugPrint("SaveData: Attempting to upload video...");
        finalVideoUrlValue = await videoController.compressAndUploadVideo(uid2); 
        if (finalVideoUrlValue == null) {
          debugPrint("Video upload failed but proceeding as it might be optional.");
          finalVideoUrlValue = 'noVideo';
        } else {
          debugPrint("SaveData: Video upload finished. URL: $finalVideoUrlValue");
        }
      } else {
        finalVideoUrlValue = 'noVideo'; 
        debugPrint("SaveData: No video selected to upload.");
      }

      final GetAddManyImage imageController = Get.find<GetAddManyImage>();
      if (imageController.selectedImageBytes.isNotEmpty) {
        debugPrint("SaveData: Attempting to upload multiple images...");
        finalManyImageUrls = await imageController.uploadAndGetUrls(uid2); 
        debugPrint("SaveData: Multi-image upload finished. URLs: $finalManyImageUrls");
      } else {
        debugPrint("SaveData: No additional images selected to upload.");
      }

      if (TypeItem == FirebaseX.itemsCollection) {
        ItemModel modelItem = ItemModel(
            id: uid2,
            name: nameOfItem.text.trim(),
            price: sellingPrice,
            costPrice: costPrice,
            addedBySellerType: sellerTypeAssociatedWithProduct.value,
            imageUrl: url, 
            manyImages: finalManyImageUrls, 
            videoUrl: (finalVideoUrlValue == 'noVideo') ? null : finalVideoUrlValue,
            typeItem: selectedCategoryNameEn.value!,
            uidAdd: currentUserId,
            appName: FirebaseX.appName,
            description: descriptionOfItem.text.trim(),
            itemCondition: selectedItemConditionKey.value, 
            qualityGrade: selectedQualityGrade.value,  
            countryOfOrigin: selectedCountryOfOriginKey.value,
            countryOfOriginAr: selectedCountryOfOriginAr.value,
            countryOfOriginEn: selectedCountryOfOriginEn.value,
            productBarcode: productBarcode.text.trim().isEmpty ? null : productBarcode.text.trim(),
            mainProductBarcode: mainProductBarcode.text.trim().isEmpty ? null : mainProductBarcode.text.trim(),
            productBarcodes: productBarcodes.isNotEmpty ? productBarcodes.toList() : null,
            quantity: productQuantity.text.trim().isEmpty ? null : int.tryParse(productQuantity.text.trim()),
            quantityPerCarton: quantityPerCarton.text.trim().isEmpty ? null : int.tryParse(quantityPerCarton.text.trim()),
            suggestedRetailPrice: suggestedRetailPrice.text.trim().isEmpty ? null : double.tryParse(suggestedRetailPrice.text.trim()),
            // إضافة حقول الأقسام المنفصلة مع الأسماء (مضمونة عدم كونها null)
            mainCategoryId: selectedMainCategoryId.value.isEmpty ? null : selectedMainCategoryId.value,
            subCategoryId: selectedSubCategoryId.value.isEmpty ? null : selectedSubCategoryId.value,
            mainCategoryNameAr: finalMainCategoryNameAr,
            mainCategoryNameEn: finalMainCategoryNameEn,
            subCategoryNameAr: finalSubCategoryNameAr,
            subCategoryNameEn: finalSubCategoryNameEn,
            // إضافة معلومات المنتج الأصلي إذا كان موجوداً
            originalProductId: originalProductId.value.isEmpty ? null : originalProductId.value,
            originalCompanyId: originalCompanyId.value.isEmpty ? null : originalCompanyId.value,

        );

        debugPrint("💾 ═══════ حفظ المنتج في Firestore ═══════");
        debugPrint("📁 Main Category ID: ${selectedMainCategoryId.value}");
        debugPrint("📂 Sub Category ID: ${selectedSubCategoryId.value}");
        debugPrint("🇦🇪 Arabic Names:");
        debugPrint("   Main: '${selectedMainCategoryNameAr.value}'");
        debugPrint("   Sub:  '${selectedSubCategoryNameAr.value}'");
        debugPrint("🇺🇸 English Names:");
        debugPrint("   Main: '${selectedMainCategoryNameEn.value}'");
        debugPrint("   Sub:  '${selectedSubCategoryNameEn.value}'");
        debugPrint("📋 Type Item: ${selectedCategoryNameEn.value}");
        debugPrint("🌍 Country of Origin:");
        debugPrint("   Key: '${selectedCountryOfOriginKey.value}'");
        debugPrint("   Arabic: '${selectedCountryOfOriginAr.value}'");
        debugPrint("   English: '${selectedCountryOfOriginEn.value}'");
        
        // تحقق نهائي من البيانات (المتغيرات تم إعلانها في بداية الدالة)
        debugPrint("🔒 القيم النهائية المضمونة (لن تكون null أبداً):");
        debugPrint("   Main AR: '$finalMainCategoryNameAr'");
        debugPrint("   Main EN: '$finalMainCategoryNameEn'");
        debugPrint("   Sub AR: '$finalSubCategoryNameAr'");
        debugPrint("   Sub EN: '$finalSubCategoryNameEn'");
        await firestore.collection(FirebaseX.itemsCollection).doc(uid2).set(modelItem.toMap());
        debugPrint("✅ تم حفظ المنتج بنجاح في Firestore!");
        debugPrint("🔍 التحقق النهائي من البيانات المحفوظة:");
        debugPrint("   mainCategoryNameAr: '${modelItem.mainCategoryNameAr}' (طول: ${modelItem.mainCategoryNameAr?.length ?? 0})");
        debugPrint("   mainCategoryNameEn: '${modelItem.mainCategoryNameEn}' (طول: ${modelItem.mainCategoryNameEn?.length ?? 0})");
        debugPrint("   subCategoryNameAr: '${modelItem.subCategoryNameAr}' (طول: ${modelItem.subCategoryNameAr?.length ?? 0})");
        debugPrint("   subCategoryNameEn: '${modelItem.subCategoryNameEn}' (طول: ${modelItem.subCategoryNameEn?.length ?? 0})");
        debugPrint("Item data uploaded.");

      } else if (TypeItem == FirebaseX.offersCollection) {
        OfferModel modelOfferItem = OfferModel(
          id: uid2,
          name: nameOfItem.text.trim(),
          price: sellingPrice,
          oldPrice: double.parse(oldPrice.text),
          rate: int.parse(rate.text),
          costPrice: costPrice,
          addedBySellerType: sellerTypeAssociatedWithProduct.value,
          imageUrl: url,
          manyImages: finalManyImageUrls,
          videoUrl: (finalVideoUrlValue == 'noVideo') ? null : finalVideoUrlValue,
          uidAdd: currentUserId,
          appName: FirebaseX.appName,
          description: descriptionOfItem.text.trim(),
          countryOfOrigin: selectedCountryOfOriginKey.value,
          countryOfOriginAr: selectedCountryOfOriginAr.value,
          countryOfOriginEn: selectedCountryOfOriginEn.value,
          itemCondition: selectedItemConditionKey.value,
          qualityGrade: selectedQualityGrade.value,
          mainProductBarcode: mainProductBarcode.text.trim().isEmpty ? null : mainProductBarcode.text.trim(),
          productBarcodes: productBarcodes.isNotEmpty ? productBarcodes.toList() : null,
          quantity: productQuantity.text.trim().isEmpty ? null : int.tryParse(productQuantity.text.trim()),
          quantityPerCarton: quantityPerCarton.text.trim().isEmpty ? null : int.tryParse(quantityPerCarton.text.trim()),
          suggestedRetailPrice: suggestedRetailPrice.text.trim().isEmpty ? null : double.tryParse(suggestedRetailPrice.text.trim()),
        );
        debugPrint("Uploading Offer data to Firestore...");
        await firestore.collection(FirebaseX.offersCollection).doc(uid2).set(modelOfferItem.toMap());
        debugPrint("Offer data uploaded.");
      }

      _resetFields();
      isSend.value = false;
      update(); 
      debugPrint("Data saved successfully. Navigating back...");
      Get.snackbar("نجاح", "تم حفظ المنتج بنجاح!", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
      
      // تحديث درجات الجودة المتاحة بعد الحفظ (للمرة القادمة)
      updateAvailableQualityGrades();
      
      Future.delayed(const Duration(seconds: 1), () {
         Get.offAll(() => BottomBar(initialIndex: 0));
      });

    } catch (e, s) {
      debugPrint("Error saving data: $e");
      debugPrint("Stack trace: $s");
      isSend.value = false;
      update(['sendButton']);
      _showErrorDialog("حدث خطأ أثناء حفظ البيانات: ${e.toString()}");
    }
  }

  void _showErrorDialog(String message) {
    Get.defaultDialog(
      title: "خطأ في الإدخال",
      middleText: message,
      textConfirm: "موافق",
      confirmTextColor: Colors.white,
      onConfirm: () => Get.back(),
    );
  }

  // دالة تحديث المنتج
  Future<void> updateProductData(String productId) async {
    if (!(globalKey.currentState?.validate() ?? false)) {
      debugPrint("Form validation failed!");
      Get.rawSnackbar(message: "يرجى ملء جميع الحقول المطلوبة.", backgroundColor: Colors.orange.shade700);
      return;
    }

    // التأكد من وجود باركود رئيسي
    ensureMainBarcodeExists();

    final double? costPrice = double.tryParse(costPriceOfItem.text);
    if (costPrice == null || costPrice <= 0) {
      _showErrorDialog('سعر تكلفة المنتج يجب أن يكون رقماً أكبر من الصفر.');
      return;
    }

    final double? sellingPrice = double.tryParse(priceOfItem.text);
    if (sellingPrice == null || sellingPrice <= 0) {
      _showErrorDialog('سعر بيع المنتج يجب أن يكون رقماً أكبر من الصفر.');
      return;
    }

    // التحققات الأخرى مثل saveData
    if (selectedItemConditionKey.value == null) { _showErrorDialog('اختر حالة المنتج.'); return; }
    if (selectedQualityGrade.value == null) { _showErrorDialog('اختر درجة الجودة.'); return; }
    if (selectedCountryOfOriginKey.value == null) { _showErrorDialog('اختر بلد المنشأ.'); return; }

    isSend.value = true;
    update(['sendButton']);

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        _showErrorDialog("خطأ: لم يتم تسجيل دخول المستخدم.");
        isSend.value = false;
        update(['sendButton']);
        return;
      }

      String? finalVideoUrlValue;
      List<String> finalManyImageUrls = [];

      // رفع الفيديو الجديد إذا كان موجوداً
      final GetChooseVideo videoController = Get.find<GetChooseVideo>();
      if (videoController.file != null) { 
        debugPrint("Updating video...");
        finalVideoUrlValue = await videoController.compressAndUploadVideo(productId); 
        finalVideoUrlValue ??= 'noVideo';
      } else {
        finalVideoUrlValue = 'noVideo';
      }

      // رفع الصور الجديدة إذا كانت موجودة
      final GetAddManyImage imageController = Get.find<GetAddManyImage>();
      if (imageController.selectedImageBytes.isNotEmpty) {
        debugPrint("Updating images...");
        finalManyImageUrls = await imageController.uploadAndGetUrls(productId); 
      } else {
        // استخدام الصور الموجودة
        finalManyImageUrls = imageUrlList.toList();
      }

      // بناء البيانات المحدثة
      Map<String, dynamic> updatedData = {
        'nameOfItem': nameOfItem.text.trim(),
        'priceOfItem': sellingPrice,
        'costPrice': costPrice,
        'descriptionOfItem': descriptionOfItem.text.trim(),
        'quantity': productQuantity.text.trim().isEmpty ? null : int.tryParse(productQuantity.text.trim()),
        'quantityPerCarton': quantityPerCarton.text.trim().isEmpty ? null : int.tryParse(quantityPerCarton.text.trim()),
        'suggestedRetailPrice': suggestedRetailPrice.text.trim().isEmpty ? null : double.tryParse(suggestedRetailPrice.text.trim()),
        'productBarcode': productBarcode.text.trim().isEmpty ? null : productBarcode.text.trim(),
        'mainProductBarcode': mainProductBarcode.text.trim().isEmpty ? null : mainProductBarcode.text.trim(),
        'productBarcodes': productBarcodes.isNotEmpty ? productBarcodes.toList() : null,
        'itemCondition': selectedItemConditionKey.value,
        'qualityGrade': selectedQualityGrade.value,
        'countryOfOrigin': selectedCountryOfOriginKey.value,
        'countryOfOriginAr': selectedCountryOfOriginAr.value,
        'countryOfOriginEn': selectedCountryOfOriginEn.value,
        'manyImages': finalManyImageUrls,
        'videoURL': finalVideoUrlValue == 'noVideo' ? null : finalVideoUrlValue,
        // معلومات الأقسام
        'mainCategoryId': selectedMainCategoryId.value.isEmpty ? null : selectedMainCategoryId.value,
        'subCategoryId': selectedSubCategoryId.value.isEmpty ? null : selectedSubCategoryId.value,
        'mainCategoryNameAr': selectedMainCategoryNameAr.value.isEmpty ? 'غير محدد' : selectedMainCategoryNameAr.value,
        'mainCategoryNameEn': selectedMainCategoryNameEn.value.isEmpty ? 'undefined' : selectedMainCategoryNameEn.value,
        'subCategoryNameAr': selectedSubCategoryNameAr.value.isEmpty ? 'غير محدد' : selectedSubCategoryNameAr.value,
        'subCategoryNameEn': selectedSubCategoryNameEn.value.isEmpty ? 'undefined' : selectedSubCategoryNameEn.value,
        // معلومات المنتج الأصلي
        'originalProductId': originalProductId.value.isEmpty ? null : originalProductId.value,
        'originalCompanyId': originalCompanyId.value.isEmpty ? null : originalCompanyId.value,
        // تحديث وقت التعديل
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      // رفع الصورة الرئيسية الجديدة إذا كانت موجودة
      if (uint8list.isNotEmpty) {
        debugPrint("Uploading new main image...");
        Reference storage = firebaseStorage.ref(FirebaseX.StorgeApp).child(productId).child('mainImage_${DateTime.now().millisecondsSinceEpoch}');
        UploadTask uploadTask = storage.putData(uint8list);
        TaskSnapshot taskSnapshot = await uploadTask;
        String url = await taskSnapshot.ref.getDownloadURL();
        updatedData['url'] = url;
        debugPrint("New main image uploaded: $url");
      }

      // تحديث البيانات في Firestore
      await firestore.collection(FirebaseX.itemsCollection).doc(productId).update(updatedData);
      
      debugPrint("✅ تم تحديث المنتج بنجاح!");
      
      isSend.value = false;
      update();
      
      Get.snackbar(
        "نجاح", 
        "تم تحديث المنتج بنجاح!", 
        snackPosition: SnackPosition.BOTTOM, 
        backgroundColor: Colors.green, 
        colorText: Colors.white
      );

    } catch (e, s) {
      debugPrint("Error updating product: $e");
      debugPrint("Stack trace: $s");
      isSend.value = false;
      update(['sendButton']);
      _showErrorDialog("حدث خطأ أثناء تحديث البيانات: ${e.toString()}");
    }
  }

  @override
  void onClose() {
    // مسح المتحكمات لتجنب تسرب الذاكرة
    nameOfItem.dispose();
    priceOfItem.dispose();
    costPriceOfItem.dispose();
    descriptionOfItem.dispose();
    rate.dispose();
    oldPrice.dispose();
    quantityPerCarton.dispose();
    suggestedRetailPrice.dispose();
    isSend.value = false; // التأكد من إعادة تعيين الحالة

    debugPrint("Getinformationofitem Controller Closed and Cleaned.");
    super.onClose();
  }
}

class Getchosethetypeofitem extends GetxController {
  List<String> TheWher = ["Item", "Offer", "Serves"];
  List<String> text = ["منتج", "عرض", "خدمة"]; // تمت ترجمة الكلمات للعربية
  String TheChosen = "Item"; // القيمة الافتراضية
}

