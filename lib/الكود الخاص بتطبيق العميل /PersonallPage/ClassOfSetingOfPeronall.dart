import 'package:flutter/material.dart';
import 'package:get/get.dart';

// استيراد ال Controllers
// import '../controllers/auth_controller.dart';
// import '../controllers/settings_controller.dart';



// ضع هذا الكود في ملفات منفصلة controllers/auth_controller.dart و controllers/settings_controller.dart
// BEGIN auth_controller_placeholder.dart
class AuthController extends GetxController {
  Future<void> signOut() async {
    Get.dialog(AlertDialog(title: const Text('تسجيل الخروج'), content: const Text('هل أنت متأكد؟'), actions: [TextButton(onPressed: ()=> Get.back(), child: const Text('إلغاء')), TextButton(onPressed: (){ Get.back(); Get.snackbar("نجاح", "تم تسجيل الخروج (محاكاة)");}, child: const Text('موافق'))]));
  }
  Future<void> deleteAccount() async {
    Get.dialog(AlertDialog(title: const Text('حذف الحساب'), content: const Text('سيتم حذف حسابك نهائياً. هل أنت متأكد؟'), actions: [TextButton(onPressed: ()=> Get.back(), child: const Text('إلغاء')), TextButton(onPressed: (){ Get.back(); Get.snackbar("نجاح", "تم حذف الحساب (محاكاة)");}, child: const Text('موافق'))]));
  }
}
// END auth_controller_placeholder.dart

// BEGIN settings_controller_placeholder.dart
class SettingsController extends GetxController {
  var isDarkMode = false.obs;
  void toggleTheme(bool value) {
    isDarkMode.value = value;
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
    Get.snackbar("إعدادات", "تم تغيير الوضع إلى ${isDarkMode.value ? 'الداكن' : 'الفاتح'} (محاكاة)");
  }
  void changeLanguage(String lang) {
    Get.snackbar("إعدادات", "تم تغيير اللغة إلى $lang (محاكاة - يتطلب إعداد ترجمة كامل)");
    // مثال: Get.updateLocale(Locale(lang));
  }
}
// END settings_controller_placeholder.dart


class PersonalSettings extends StatelessWidget {
  const PersonalSettings({super.key});

  @override
  Widget build(BuildContext context) {
    // تسجيل الـ Controllers إذا لم يكونوا مسجلين بالفعل
    // الأفضل تسجيلهم في مكان أعلى في شجرة الويدجات أو عند بدء التطبيق
    final AuthController authController = Get.put(AuthController());
    final SettingsController settingsController = Get.put(SettingsController());

    final double hi = MediaQuery.of(context).size.height;
    final double wi = MediaQuery.of(context).size.width;
    final TextStyle textStyle = TextStyle(fontSize: wi / 26, fontWeight: FontWeight.w500); // تعديل طفيف لحجم الخط
    final Color iconColor = Theme.of(context).colorScheme.primary; // لون أيقونة ديناميكي

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0, bottom: 10, top:10),
            child: Text(
              'إعدادات عامة',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: wi / 20, color: Theme.of(context).colorScheme.secondary),
              textAlign: TextAlign.right,
            ),
          ),
          _buildSettingsCard(
            wi: wi,
            hi: hi,
            children: [
              _SettingTile(
                text: 'مشاركة التطبيق',
                icon: Icons.share_outlined,
                textStyle: textStyle,
                iconColor: iconColor,
                onTap: () {
                  //  منطق مشاركة التطبيق
                  Get.snackbar("مشاركة", "قيد التنفيذ...");
                },
              ),
              const _CustomDivider(),
              _SettingTile(
                text: 'قيّم التطبيق',
                icon: Icons.star_outline,
                textStyle: textStyle,
                iconColor: iconColor,
                onTap: () {
                  //  منطق تقييم التطبيق
                  Get.snackbar("تقييم", "قيد التنفيذ...");
                },
              ),
              const _CustomDivider(),
              _SettingTile(
                text: 'تواصل مع الشركة',
                icon: Icons.support_agent_outlined,
                textStyle: textStyle,
                iconColor: iconColor,
                onTap: () {
                  // منطق التواصل
                  Get.snackbar("تواصل", "قيد التنفيذ...");
                },
              ),
            ],
          ),

          SizedBox(height: hi / 40),
          Padding(
            padding: const EdgeInsets.only(right: 8.0, bottom: 10, top:10),
            child: Text(
              'إعدادات الحساب والتطبيق',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: wi / 20, color: Theme.of(context).colorScheme.secondary),
              textAlign: TextAlign.right,
            ),
          ),
          _buildSettingsCard(
              wi: wi,
              hi: hi,
              children: [
                Obx(() => SwitchListTile.adaptive( // Obx للاستماع لتغيرات isDarkMode
                  title: Text('الوضع الداكن', style: textStyle, textAlign: TextAlign.right,),
                  value: settingsController.isDarkMode.value,
                  onChanged: (value) {
                    settingsController.toggleTheme(value);
                  },
                  secondary: Icon(settingsController.isDarkMode.value ? Icons.dark_mode_outlined : Icons.light_mode_outlined, color: iconColor,),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                )),
                const _CustomDivider(),
                _SettingTile(
                  text: 'تغيير اللغة',
                  icon: Icons.language_outlined,
                  textStyle: textStyle,
                  iconColor: iconColor,
                  onTap: () {
                    _showLanguageDialog(context, settingsController);
                  },
                ),
                const _CustomDivider(),
                _SettingTile(
                  text: 'تسجيل الخروج',
                  icon: Icons.logout_outlined,
                  textStyle: textStyle,
                  iconColor: Colors.orange.shade700,
                  onTap: () {
                    authController.signOut();
                  },
                ),
                const _CustomDivider(),
                _SettingTile(
                  text: 'حذف الحساب',
                  icon: Icons.delete_forever_outlined,
                  textStyle: textStyle,
                  iconColor: Colors.red.shade700,
                  onTap: () {
                    _confirmAccountDeletion(context, authController);
                  },
                ),
              ]
          )
        ],
      ),
    );
  }

  Widget _buildSettingsCard({required double wi, required double hi, required List<Widget> children}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          children: children,
        ),
      ),
    );
  }


  void _showLanguageDialog(BuildContext context, SettingsController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('اختر اللغة', textAlign: TextAlign.right),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('العربية', textAlign: TextAlign.right),
              onTap: () {
                controller.changeLanguage('ar'); //  افترض وجود كود اللغة ar
                Get.back();
              },
            ),
            ListTile(
              title: const Text('English', textAlign: TextAlign.right),
              onTap: () {
                controller.changeLanguage('en'); //  افترض وجود كود اللغة en
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmAccountDeletion(BuildContext context, AuthController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('تأكيد حذف الحساب', textAlign: TextAlign.right,),
        content: const Text('هل أنت متأكد أنك تريد حذف حسابك بشكل نهائي؟ هذا الإجراء لا يمكن التراجع عنه.', textAlign: TextAlign.right,),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            child: const Text('إلغاء'),
            onPressed: () => Get.back(),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
            child: const Text('حذف الحساب'),
            onPressed: () {
              Get.back(); // أغلق مربع الحوار أولاً
              controller.deleteAccount();
            },
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    // Key key, // ليس ضروريًا في الإصدارات الحديثة إذا لم يكن هناك استخدام محدد
    required this.text,
    required this.icon,
    required this.textStyle,
    this.iconColor,
    this.onTap,
  }); // : super(key: key); // ليس ضروريًا

  final String text;
  final IconData icon;
  final TextStyle textStyle;
  final Color? iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // final double wi = MediaQuery.of(context).size.width; //  غير مستخدم حاليًا
    return InkWell(
      onTap: onTap,
      child: Container(
        height: kMinInteractiveDimension, // ارتفاع مناسب للتفاعل
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(text, style: textStyle),
            const SizedBox(width: 15), // زيادة المسافة قليلاً
            Icon(icon, color: iconColor ?? Theme.of(context).iconTheme.color, size: textStyle.fontSize! * 1.2), // حجم أيقونة نسبي
          ],
        ),
      ),
    );
  }
}

class _CustomDivider extends StatelessWidget {
  const _CustomDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 0.5, // سمك أقل
      color: Colors.grey.shade300,
      indent: 20, // مسافة بادئة من اليمين
      endIndent: 20, // مسافة بادئة من اليسار
    );
  }
}