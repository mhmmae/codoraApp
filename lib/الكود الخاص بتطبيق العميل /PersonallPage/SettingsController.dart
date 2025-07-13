import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsController extends GetxController {
  // الوضع الداكن
  var isDarkMode = false.obs; // .obs  يجعلها متغيرة قابلة للمراقبة

  void toggleTheme(bool value) {
    isDarkMode.value = value;
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
    //  تحتاج إلى حفظ هذا الإعداد في SharedPreferences للاستمرار
  }

  // تغيير اللغة - مثال مبسط
  void changeLanguage(String languageCode, String countryCode) {
    var locale = Locale(languageCode, countryCode);
    Get.updateLocale(locale);
    //  تحتاج إلى إعداد ملفات الترجمة (Localization) لـ GetX
    //  وأن يكون GetMaterialApp مهيأ لذلك.
  }
}