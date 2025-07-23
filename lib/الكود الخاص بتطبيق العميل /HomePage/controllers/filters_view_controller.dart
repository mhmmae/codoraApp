import 'package:get/get.dart';

/// Controller لإدارة حالة عرض صفحة الفلاتر
class FiltersViewController extends GetxController {
  // حالة عرض الفلاتر بدلاً من المنتجات
  final RxBool showFiltersGrid = false.obs;

  /// تبديل عرض الفلاتر
  void toggleFiltersView() {
    showFiltersGrid.value = !showFiltersGrid.value;
    print(
      '🔄 FiltersViewController - تبديل الفلاتر: ${showFiltersGrid.value ? 'مرئي' : 'مخفي'}',
    );
  }

  /// إظهار الفلاتر
  void showFilters() {
    showFiltersGrid.value = true;
    print('✅ FiltersViewController - إظهار الفلاتر');
  }

  /// إخفاء الفلاتر
  void hideFilters() {
    showFiltersGrid.value = false;
    print('❌ FiltersViewController - إخفاء الفلاتر');
  }
}
