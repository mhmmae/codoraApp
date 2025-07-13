import 'package:flutter/material.dart';
import 'package:get/get.dart';

// يجب التأكد من استخدام المتحكم الصحيح (إما متحكم الفلتر الرئيسي أو متحكم الإضافة)
import '../Get-Controllar/GetChoseTheTypeOfItem.dart'; // استخدام متحكم الفلتر كمثال

// إعادة التسمية إلى FilterChipWidget أو ما شابه
class ChooseAddItemSubtypeWidget extends StatelessWidget { // <<<--- أو FilterChipWidget
  const ChooseAddItemSubtypeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final hi = MediaQuery.of(context).size.height; final wi = MediaQuery.of(context).size.width; final theme = Theme.of(context);
    final GetChoseTheTypeOfItem controller = Get.find<GetChoseTheTypeOfItem>(); // <<<--- تأكد من المتحكم
    const List<IconData> icons = [ Icons.apps, Icons.phone_android, Icons.local_mall, Icons.headset, Icons.devices ]; // أمثلة للأيقونات, تحتاج للمطابقة مع المفاتيح

    return SizedBox( height: hi * 0.07, child: ListView.builder( itemCount: controller.filterKeys.length, scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), itemBuilder: (c, i) {
      final key = controller.filterKeys[i]; final text = controller.getDisplayText(key); final icon = icons[i % icons.length];
      return Obx(() { final isSelected = controller.selectedFilterKey.value == key; return Padding( padding: const EdgeInsets.symmetric(horizontal: 5), child: GestureDetector( onTap: () => controller.updateSelection(key), child: AnimatedContainer( duration: const Duration(milliseconds: 200), decoration: BoxDecoration( color: isSelected ? theme.primaryColor : Colors.grey[200], borderRadius: BorderRadius.circular(20), border: isSelected ? Border.all(color: theme.primaryColorDark, width: 1.5) : Border.all(color: Colors.grey[400]!)), padding: EdgeInsets.symmetric(horizontal: wi * 0.03, vertical: hi * 0.005), child: Row( mainAxisSize: MainAxisSize.min, children: [ Icon(icon, size: wi * 0.05, color: isSelected ? theme.colorScheme.onPrimary : Colors.grey[700]), SizedBox(width: wi * 0.015), Text(text, style: TextStyle( fontSize: wi * 0.032, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? theme.colorScheme.onPrimary : Colors.grey[800] )) ] )) ) ); }); }, ), );
  }
}