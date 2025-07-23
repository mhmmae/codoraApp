import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/brand_filter_controller.dart';
import '../controllers/barcode_filter_controller.dart';

class FilterStatusIndicator extends StatelessWidget {
  const FilterStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final brandCtrl = Get.find<BrandFilterController>();
    final barcodeCtrl = Get.find<BarcodeFilterController>();
    final theme = Theme.of(context);

    return Obx(() {
      final bool hasBrandFilter = brandCtrl.isBrandModeActive.value;
      final bool hasBarcodeFilter = barcodeCtrl.hasActiveFilter;
      final bool hasAnyFilter = hasBrandFilter || hasBarcodeFilter;

      if (!hasAnyFilter) return const SizedBox.shrink();

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor.withValues(alpha: 0.1),
                  theme.primaryColor.withValues(alpha: 0.05),
                ],
              ),
              border: Border.all(
                color: theme.primaryColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // أيقونة الحالة
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    hasBarcodeFilter ? Icons.qr_code_scanner : Icons.business,
                    color: theme.primaryColor,
                    size: 18,
                  ),
                ),

                const SizedBox(width: 12),

                // النص التوضيحي
                Expanded(
                  child: Text(
                    _getFilterDescription(
                      hasBarcodeFilter,
                      hasBrandFilter,
                      barcodeCtrl,
                      brandCtrl,
                    ),
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),

                // زر الإلغاء
                InkWell(
                  onTap: () {
                    if (hasBarcodeFilter) {
                      barcodeCtrl.clearCurrentBarcode();
                    }
                    if (hasBrandFilter) {
                      brandCtrl.deactivateBrandModeAndClearMemory();
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      color: theme.primaryColor,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  String _getFilterDescription(
    bool hasBarcodeFilter,
    bool hasBrandFilter,
    BarcodeFilterController barcodeCtrl,
    BrandFilterController brandCtrl,
  ) {
    if (hasBarcodeFilter) {
      return 'البحث بالباركود: ${barcodeCtrl.currentSearchBarcode.value}';
    }
    if (hasBrandFilter) {
      final company = brandCtrl.selectedCompany.value;
      final product = brandCtrl.selectedCompanyProduct.value;

      if (product != null) {
        return 'منتج: ${product.nameAr}';
      } else if (company != null) {
        return 'شركة: ${company.nameAr}';
      } else {
        return 'فلتر البراند نشط';
      }
    }
    return 'فلتر نشط';
  }
}
