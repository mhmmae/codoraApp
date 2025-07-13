
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../../../الكود الخاص بتطبيق البائع/categories/screens/categories_management_screen.dart';
import '../../../../الكود الخاص بتطبيق البائع/original_products/screens/original_products_management_screen.dart';
import '../../../theCodes/اضافة اسعار الكودات الرابعة وتغيير السعر/code1.dart';
import '../../../theCodes/اضافة الاسعار للكودات وتغييرها /code11.dart';
import '../../../theCodes/اضافة مجموعة كودية/code6.dart';
import '../../../theCodes/الحذف/code3.dart';
import '../../../theCodes/اضافة كودات الرابعة/code4.dart';
import '../../../theCodes/عرض مجوعة الكودات /code7.dart';
import '../../ChooseCategory/AdminManageCategoriesScreen.dart';
import '../../statistics/statistics.dart';

/// ودجة Drawer2 تعرض قائمة خيارات التطبيق.
/// تحتوي على عناصر مثل "اضافة منتجات" و"احصائيات" مع توجيه المستخدم إلى الشاشات المناسبة.
class Drawer2 extends StatelessWidget {
  const Drawer2({super.key});

  @override
  Widget build(BuildContext context) {
    // الحصول على أبعاد الشاشة
    final double hi = MediaQuery
        .of(context)
        .size
        .height;
    final double wi = MediaQuery
        .of(context)
        .size
        .width;

    return Drawer(
      backgroundColor: Colors.white,
      width: wi / 1.4,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView(
            children: [
              // SizedBox(height: hi / 40),
              // _buildDrawerItem(
              //   color: Colors.blueAccent,
              //   context: context,
              //   title: 'اضافة منتجات',
              //   onTap: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(builder: (context) => const AddItem()),
              //     );
              //   },
              //   icon: Icons.add_shopping_cart,
              // ),
              SizedBox(height: hi / 55),
              _buildDrawerItem(
                color: Colors.blueAccent,
                context: context,
                title: 'إدارة المنتجات الأصلية',
                onTap: () {
                  Get.to(() => const OriginalProductsManagementScreen());
                },
                icon: Icons.inventory_2,
              ),
              SizedBox(height: hi / 55),
              _buildDrawerItem(
                color: Colors.blueAccent,
                context: context,
                title: 'إدارة أقسام المنتجات',
                onTap: () {
                  Get.to(() => const CategoriesManagementScreen());
                },
                icon: Icons.category,
              ),
              SizedBox(height: hi / 55),
              _buildDrawerItem(
                color: Colors.blueAccent,
                context: context,
                title: 'احصائيات',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const statistics()),
                  );
                },
                icon: Icons.insert_chart,
              ),
              SizedBox(height: hi / 55),
              GetBuilder<TextController>(init: TextController(numberOfCode: 10),builder: (logic) {
                return _buildDrawerItem(
                  color: Colors.blueAccent,
                  context: context,
                  title: 'اضافة كود الرابعة',
                  onTap: () {
                    final uidCologe  = Uuid().v4();
                    logic.extractImageAndNavigate(uidCologe);
                  },
                  icon: Icons.code,
                );
              }),
              SizedBox(height: hi / 55),
              GetBuilder<TextController>(init: TextController(numberOfCode: 10),builder: (logic) {
                return _buildDrawerItem(
                  color: Colors.blueAccent,
                  context: context,
                  title: 'اضافة مجموعة كودية',
                  onTap: () {
                    Get.to(() => AddCodeGroupScreen());
                  },
                  icon: Icons.code_off,
                );
              }),
              SizedBox(height: hi / 55),
              GetBuilder<TextController>(init: TextController(numberOfCode: 10),builder: (logic) {
                return _buildDrawerItem(
                  color: Colors.blueAccent,
                  context: context,
                  title: 'اضافة اسعار الرابعة وتغييرها',
                  onTap: () {
                    Get.to(() => PricingPage());
                  },
                  icon: Icons.price_change,
                );
              }),
              SizedBox(height: hi / 55),
              GetBuilder<TextController>(init: TextController(numberOfCode: 10),builder: (logic) {
                return _buildDrawerItem(
                  color: Colors.blueAccent,
                  context: context,
                  title: 'اضافة كودات',
                  onTap: () {
                    Get.to(() => CodeGroupsGridScreen());
                  },
                  icon: Icons.price_change,
                );
              }),
              SizedBox(height: hi / 55),
              GetBuilder<TextController>(init: TextController(numberOfCode: 10),builder: (logic) {
                return _buildDrawerItem(
                  color: Colors.blueAccent,
                  context: context,
                  title: 'تغيير اسعار الكودات',
                  onTap: () {
                    Get.to(() => CodeGroupsGrid());
                  },
                  icon: Icons.price_change,
                );
              }),
              SizedBox(height: hi / 55),
              GetBuilder<TextController>(init: TextController(numberOfCode: 10),builder: (logic) {
                return _buildDrawerItem(
                  color: Colors.blueAccent,
                  context: context,
                  title: 'اضافة نوع من ترتيب المتجات',
                  onTap: () {
                    Get.to(() =>   AdminManageCategoriesScreen(),
                    );
                  },
                  icon: Icons.price_change,
                );
              }),
              SizedBox(height: hi / 55),
              GetBuilder<TextController>(init: TextController(numberOfCode: 10),builder: (logic) {
                return _buildDrawerItem(
                  color: Colors.red,
                  context: context,
                  title: 'مسح كودات',
                  onTap: () {
                    Get.to(() => SearchAndDeleteScreen());
                  },
                  icon: Icons.delete_sweep_sharp,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  /// دالة مساعدة لإنشاء عنصر من عناصر الـ Drawer.
  /// [context] : سياق الواجهة.
  /// [title] : عنوان العنصر.
  /// [onTap] : الدالة التي تُنفذ عند الضغط.
  /// [icon] : الأيقونة المعروضة مع النص.
  Widget _buildDrawerItem({
    required BuildContext context,
    required String title,
    required VoidCallback onTap,
    required IconData icon,
    required Color color
  }) {
    final double wi = MediaQuery
        .of(context)
        .size
        .width;
    return  ListTile(
      leading: Icon(icon, color: color, size: wi / 12),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: wi / 26,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.black),
      ),
      tileColor: Colors.blueAccent.withValues(alpha: 0.1),
    );
  }
}



