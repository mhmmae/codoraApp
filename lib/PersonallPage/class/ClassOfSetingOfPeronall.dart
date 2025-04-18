//  import 'package:flutter/material.dart';
//
// class Classofsetingofperonall extends StatelessWidget {
//    const Classofsetingofperonall({super.key});
//
//    @override
//    Widget build(BuildContext context) {
//      double hi = MediaQuery.of(context).size.height;
//      double wi = MediaQuery.of(context).size.width;
//      return Column(
//        children: [
//          Padding(
//            padding: const EdgeInsets.symmetric(
//                horizontal: 20, vertical: 10),
//            child: Align(
//                alignment: Alignment.topRight,
//                child: Text('اعدادات عامة')),
//          ),
//          Padding(
//            padding: const EdgeInsets.symmetric(horizontal: 3),
//            child: Container(
//              decoration: BoxDecoration(
//                  color: Colors.black12,
//                  borderRadius: BorderRadius.circular(6),
//                  border: Border.all(color: Colors.black)),
//              child: Column(
//                children: [
//                  SizedBox(
//                    height: hi / 100,
//                  ),
//                  Container(
//                    height: hi / 25,
//                    decoration: BoxDecoration(),
//                    child: Padding(
//                      padding:
//                      const EdgeInsets.symmetric(horizontal: 20),
//                      child: Row(
//                        mainAxisAlignment: MainAxisAlignment.end,
//                        children: [
//                          Text(
//                            'مشاركة التطبيق',
//                            style: TextStyle(fontSize: wi / 30),
//                          ),
//                          SizedBox(
//                            width: wi / 30,
//                          ),
//                          Icon(Icons.share)
//                        ],
//                      ),
//                    ),
//                  ),
//                  Divider(),
//                  Container(
//                    height: hi / 25,
//                    decoration: BoxDecoration(),
//                    child: Padding(
//                      padding:
//                      const EdgeInsets.symmetric(horizontal: 20),
//                      child: Row(
//                        mainAxisAlignment: MainAxisAlignment.end,
//                        children: [
//                          Text(
//                            'قيم التطبيق',
//                            style: TextStyle(fontSize: wi / 30),
//                          ),
//                          SizedBox(
//                            width: wi / 30,
//                          ),
//                          Icon(Icons.star)
//                        ],
//                      ),
//                    ),
//                  ),
//                  Divider(),
//                  Container(
//                    height: hi / 25,
//                    decoration: BoxDecoration(),
//                    child: Padding(
//                      padding:
//                      const EdgeInsets.symmetric(horizontal: 20),
//                      child: Row(
//                        mainAxisAlignment: MainAxisAlignment.end,
//                        children: [
//                          Text(
//                            'تواصل مع الشركة المنفذة للتطبيق',
//                            style: TextStyle(fontSize: wi / 30),
//                          ),
//                          SizedBox(
//                            width: wi / 30,
//                          ),
//                          Icon(Icons.phone)
//                        ],
//                      ),
//                    ),
//                  ),
//                  SizedBox(
//                    height: hi / 100,
//                  ),
//                ],
//              ),
//            ),
//          )
//        ],
//      );
//    }
//  }










import 'package:flutter/material.dart';

class PersonalSettings extends StatelessWidget {
  const PersonalSettings({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // الحصول على أبعاد الشاشة لتحديد أحجام العناصر نسبيًا
    final double hi = MediaQuery.of(context).size.height;
    final double wi = MediaQuery.of(context).size.width;

    // إعداد نمط النص المستخدم في عناصر الإعدادات
    final TextStyle textStyle = TextStyle(fontSize: wi / 30);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // عنوان الإعدادات
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Align(
            alignment: Alignment.topRight,
            child: Text(
              'إعدادات عامة',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.black),
            ),
            child: Column(
              children: [
                SizedBox(height: hi / 100),
                // عنصر مشاركة التطبيق
                _SettingTile(
                  text: 'مشاركة التطبيق',
                  icon: Icons.share,
                  textStyle: textStyle,
                  height: hi / 25,
                ),
                const Divider(height: 1, color: Colors.grey),
                // عنصر تقييم التطبيق
                _SettingTile(
                  text: 'قيم التطبيق',
                  icon: Icons.star,
                  textStyle: textStyle,
                  height: hi / 25,
                ),
                const Divider(height: 1, color: Colors.grey),
                // عنصر تواصل مع الشركة
                _SettingTile(
                  text: 'تواصل مع الشركة المنفذة للتطبيق',
                  icon: Icons.phone,
                  textStyle: textStyle,
                  height: hi / 25,
                ),
                SizedBox(height: hi / 100),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// ويدجت خاص يمثل صف إعداد واحد لتقليل التكرار وتسهيل التعديل لاحقًا.
class _SettingTile extends StatelessWidget {
  const _SettingTile({
    Key? key,
    required this.text,
    required this.icon,
    required this.textStyle,
    required this.height,
  }) : super(key: key);

  final String text;
  final IconData icon;
  final TextStyle textStyle;
  final double height;

  @override
  Widget build(BuildContext context) {
    final double wi = MediaQuery.of(context).size.width;
    return Container(
      height: height,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(text, style: textStyle),
          SizedBox(width: wi / 30),
          Icon(icon),
        ],
      ),
    );
  }
}

