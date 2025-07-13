import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/brand_filter_controller.dart';
import '../controllers/barcode_filter_controller.dart';
import '../controllers/enhanced_category_filter_controller.dart';

/// ويدجت موحد لعرض وصف الفلتر النشط
class EnhancedFilterDisplayWidget extends StatelessWidget {
  const EnhancedFilterDisplayWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final BrandFilterController brandController = Get.put(BrandFilterController());
    final BarcodeFilterController barcodeController = Get.put(BarcodeFilterController());
    final EnhancedCategoryFilterController categoryController = Get.put(EnhancedCategoryFilterController());
    final theme = Theme.of(context);

    return Obx(() {
      // تحديد المتحكم النشط
      final bool isBrandModeActive = brandController.isBrandModeActive.value;
      final bool isBarcodeSearchActive = barcodeController.hasActiveFilter;
      
      final bool hasActiveFilter = isBarcodeSearchActive
          ? barcodeController.hasActiveFilter
          : isBrandModeActive 
          ? brandController.hasActiveFilter
          : categoryController.hasActiveFilter.value;

      if (!hasActiveFilter) {
        return const SizedBox.shrink();
      }

      final String filterDescription = isBarcodeSearchActive
          ? barcodeController.getFilterDescription()
          : isBrandModeActive
          ? brandController.getFilterDescription()
          : categoryController.getFilterDescription();
          
      final IconData filterIcon = isBarcodeSearchActive
          ? Icons.qr_code_scanner
          : isBrandModeActive 
          ? Icons.business 
          : Icons.filter_alt;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: theme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.primaryColor.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              filterIcon,
              size: 18,
              color: theme.primaryColor,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                filterDescription,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            // زر الإغلاق
            InkWell(
              onTap: () {
                if (isBarcodeSearchActive) {
                  barcodeController.clearCurrentBarcode();
                } else if (isBrandModeActive) {
                  if (brandController.selectedCompanyProduct.value != null) {
                    brandController.selectedCompanyProduct.value = null;
                  } else if (brandController.selectedCompany.value != null) {
                    brandController.selectedCompany.value = null;
                  } else {
                    brandController.deactivateBrandMode();
                  }
                } else {
                  categoryController.resetFilters();
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: theme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
} 