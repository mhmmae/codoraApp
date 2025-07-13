import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/enhanced_category_filter_controller.dart';
import '../../../Model/enhanced_category_model.dart';

/// Widget مبسط لعرض الأقسام الرئيسية والفرعية
class SimpleMainCategoriesWidget extends StatelessWidget {
  final double? height;
  final EdgeInsetsGeometry? padding;

  const SimpleMainCategoriesWidget({
    super.key,
    this.height,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final EnhancedCategoryFilterController controller = Get.put(EnhancedCategoryFilterController());
    final theme = Theme.of(context);

    return Container(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // مؤشر الفلتر المطبق (عند وجود فلتر نشط)
          Obx(() => controller.hasActiveFilter
              ? Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.filter_alt, size: 14, color: theme.primaryColor),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          controller.getFilterDescription(),
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: controller.resetFilters,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: theme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox(height: 8)),

          // قائمة الأقسام الرئيسية
          SizedBox(
            height: height ?? 120,
            child: Obx(() {
              if (controller.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final mainCategories = controller.mainCategories
                  .where((cat) => cat.isActive)
                  .toList();
              
              if (mainCategories.isEmpty) {
                return const Center(
                  child: Text(
                    'لا توجد أقسام متاحة',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: mainCategories.length + 1, // +1 لخيار "الكل"
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // خيار "الكل"
                    return _buildCategoryChip(
                      context: context,
                      controller: controller,
                      categoryId: EnhancedCategoryFilterController.allFilterKey,
                      categoryName: 'الكل',
                      iconData: Icons.apps,
                      theme: theme,
                      isMainCategory: true,
                    );
                  }

                  final category = mainCategories[index - 1];
                  return _buildCategoryChip(
                    context: context,
                    controller: controller,
                    categoryId: category.id,
                    categoryName: category.nameAr,
                    imageUrl: category.imageUrl,
                    theme: theme,
                    category: category,
                    isMainCategory: true,
                  );
                },
              );
            }),
          ),

          // قائمة الأقسام الفرعية (تظهر عند اختيار قسم رئيسي)
          Obx(() {
            final subCategories = controller.subCategoriesForSelectedMain;
            if (subCategories.isEmpty || controller.selectedMainCategoryId.value == EnhancedCategoryFilterController.allFilterKey) {
              return const SizedBox.shrink();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // عنوان الأقسام الفرعية
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.subdirectory_arrow_right, size: 18, color: theme.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'الأقسام الفرعية',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // قائمة الأقسام الفرعية
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: subCategories.length + 1, // +1 لخيار "الكل"
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // خيار "الكل" للأقسام الفرعية
                        return _buildCategoryChip(
                          context: context,
                          controller: controller,
                          categoryId: EnhancedCategoryFilterController.allFilterKey,
                          categoryName: 'الكل',
                          iconData: Icons.category,
                          theme: theme,
                          isMainCategory: false,
                        );
                      }

                      final subCategory = subCategories[index - 1];
                      return _buildCategoryChip(
                        context: context,
                        controller: controller,
                        categoryId: subCategory.id,
                        categoryName: subCategory.nameAr,
                        imageUrl: subCategory.imageUrl,
                        theme: theme,
                        category: subCategory,
                        isMainCategory: false,
                      );
                    },
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  /// بناء شريحة القسم المحسنة
  Widget _buildCategoryChip({
    required BuildContext context,
    required EnhancedCategoryFilterController controller,
    required String categoryId,
    required String categoryName,
    String? imageUrl,
    IconData? iconData,
    required ThemeData theme,
    EnhancedCategoryModel? category,
    required bool isMainCategory,
  }) {
    return Obx(() {
      final bool isSelected = isMainCategory 
          ? controller.selectedMainCategoryId.value == categoryId
          : controller.selectedSubCategoryId.value == categoryId;

      final double chipWidth = isMainCategory ? 90 : 75;
      final double chipHeight = isMainCategory ? 110 : 80;

      return Container(
        width: chipWidth,
        height: chipHeight,
        margin: const EdgeInsets.only(right: 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (isMainCategory) {
                controller.selectMainCategory(categoryId);
              } else {
                controller.selectSubCategory(categoryId);
              }
            },
            borderRadius: BorderRadius.circular(isMainCategory ? 16 : 12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isMainCategory ? 16 : 12),
                border: isSelected ? Border.all(
                  color: theme.primaryColor,
                  width: isMainCategory ? 2 : 1.5,
                ) : null,
                boxShadow: [
                  BoxShadow(
                    color: isSelected 
                        ? theme.primaryColor.withOpacity(0.4)
                        : Colors.black.withOpacity(0.15),
                    blurRadius: isSelected ? (isMainCategory ? 15 : 10) : (isMainCategory ? 8 : 5),
                    offset: Offset(0, isSelected ? (isMainCategory ? 4 : 3) : (isMainCategory ? 2 : 1)),
                    spreadRadius: isSelected ? (isMainCategory ? 1 : 0) : 0,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // الخلفية - صورة أو لون
                  ClipRRect(
                    borderRadius: BorderRadius.circular(isMainCategory ? 16 : 12),
                    child: SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              placeholder: (context, url) => Container(
                                color: Colors.grey.shade200,
                                child: Icon(
                                  Icons.category,
                                  size: isMainCategory ? 40 : 30,
                                  color: Colors.grey[400],
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey.shade200,
                                child: Icon(
                                  Icons.error_outline,
                                  size: isMainCategory ? 40 : 30,
                                  color: Colors.red[300],
                                ),
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    theme.primaryColor.withOpacity(isMainCategory ? 0.7 : 0.5),
                                    theme.primaryColor.withOpacity(isMainCategory ? 0.9 : 0.7),
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  iconData ?? Icons.category,
                                  size: isMainCategory ? 40 : 30,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    ),
                  ),
                  
                  // عدد الأقسام الفرعية في أعلى اليمين (للأقسام الرئيسية فقط)
                  if (isMainCategory && category != null && category.subCategories.isNotEmpty)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '${category.subCategories.length}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  
                  // النص المحسن في الأسفل
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMainCategory ? 8 : 6, 
                        vertical: isMainCategory ? 12 : 8
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(isMainCategory ? 16 : 12),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.8),
                          ],
                        ),
                      ),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMainCategory ? 8 : 6, 
                          vertical: isMainCategory ? 4 : 3
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(isMainCategory ? 8 : 6),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          categoryName,
                          style: TextStyle(
                            fontSize: isMainCategory ? 13 : 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.8),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: isMainCategory ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  
                  // مؤشر الاختيار
                  if (isSelected)
                    Positioned(
                      top: isMainCategory ? 8 : 6,
                      right: isMainCategory ? 8 : 6,
                      child: Container(
                        padding: EdgeInsets.all(isMainCategory ? 6 : 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.check,
                          size: isMainCategory ? 12 : 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
