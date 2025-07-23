// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import '../controllers/enhanced_category_filter_controller.dart';
// import '../../../Model/enhanced_category_model.dart';
//
// /// Widget للفلترة المتطورة باستخدام EnhancedCategoryModel
// class EnhancedCategoryFilterWidget extends StatelessWidget {
//   final double? height;
//   final EdgeInsetsGeometry? padding;
//
//   const EnhancedCategoryFilterWidget({
//     super.key,
//     this.height,
//     this.padding,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final EnhancedCategoryFilterController controller = Get.put(EnhancedCategoryFilterController());
//     final theme = Theme.of(context);
//     final screenWidth = MediaQuery.of(context).size.width;
//
//     return Container(
//       padding: padding ?? const EdgeInsets.symmetric(vertical: 16),
//       decoration: BoxDecoration(
//         color: theme.cardColor,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // عنوان قسم الفلترة
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             child: Row(
//               children: [
//                 Icon(Icons.filter_list, size: 20, color: theme.primaryColor),
//                 const SizedBox(width: 8),
//                 Text(
//                   'تصفية المنتجات',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: theme.textTheme.titleLarge?.color,
//                   ),
//                 ),
//                 const Spacer(),
//                 // زر مسح الفلاتر
//                 Obx(() => controller.hasActiveFilter
//                     ? TextButton.icon(
//                         onPressed: controller.resetFilters,
//                         icon: const Icon(Icons.clear, size: 16),
//                         label: const Text('مسح الفلاتر', style: TextStyle(fontSize: 12)),
//                         style: TextButton.styleFrom(
//                           foregroundColor: Colors.orange,
//                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                         ),
//                       )
//                     : const SizedBox.shrink()),
//               ],
//             ),
//           ),
//
//           const SizedBox(height: 12),
//
//           // وصف الفلتر المطبق حالياً
//           Obx(() => controller.hasActiveFilter
//               ? Container(
//                   margin: const EdgeInsets.symmetric(horizontal: 16),
//                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                   decoration: BoxDecoration(
//                     color: theme.primaryColor.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(20),
//                     border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Icon(Icons.filter_alt, size: 16, color: theme.primaryColor),
//                       const SizedBox(width: 6),
//                       Flexible(
//                         child: Text(
//                           controller.getFilterDescription(),
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: theme.primaryColor,
//                             fontWeight: FontWeight.w500,
//                           ),
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                     ],
//                   ),
//                 )
//               : const SizedBox.shrink()),
//
//           const SizedBox(height: 16),
//
//           // الأقسام الرئيسية
//           _buildMainCategoriesSection(controller, theme, screenWidth),
//
//           // الأقسام الفرعية (تظهر فقط عند اختيار قسم رئيسي)
//           Obx(() => controller.subCategoriesForSelectedMain.isNotEmpty
//               ? _buildSubCategoriesSection(controller, theme, screenWidth)
//               : const SizedBox.shrink()),
//         ],
//       ),
//     );
//   }
//
//   /// بناء قسم الأقسام الرئيسية
//   Widget _buildMainCategoriesSection(EnhancedCategoryFilterController controller, ThemeData theme, double screenWidth) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           child: Text(
//             'الأقسام الرئيسية',
//             style: TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.w600,
//               color: theme.textTheme.titleMedium?.color,
//             ),
//           ),
//         ),
//         const SizedBox(height: 8),
//         SizedBox(
//           height: 80,
//           child: Obx(() {
//             if (controller.isLoading) {
//               return const Center(child: CircularProgressIndicator());
//             }
//
//             final mainCategories = controller.mainCategories.where((cat) => cat.isActive).toList();
//
//             if (mainCategories.isEmpty) {
//               return const Center(child: Text('لا توجد أقسام متاحة', style: TextStyle(color: Colors.grey)));
//             }
//
//             return ListView.builder(
//               scrollDirection: Axis.horizontal,
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               itemCount: mainCategories.length + 1, // +1 لخيار "الكل"
//               itemBuilder: (context, index) {
//                 if (index == 0) {
//                   // خيار "الكل"
//                   return _buildCategoryChip(
//                     context: context,
//                     controller: controller,
//                     categoryId: EnhancedCategoryFilterController.allFilterKey,
//                     categoryName: 'الكل',
//                     iconData: Icons.apps,
//                     isMainCategory: true,
//                     theme: theme,
//                   );
//                 }
//
//                 final category = mainCategories[index - 1];
//                 return _buildCategoryChip(
//                   context: context,
//                   controller: controller,
//                   categoryId: category.id,
//                   categoryName: category.nameAr,
//                   imageUrl: category.imageUrl,
//                   isMainCategory: true,
//                   theme: theme,
//                   category: category,
//                 );
//               },
//             );
//           }),
//         ),
//       ],
//     );
//   }
//
//   /// بناء قسم الأقسام الفرعية
//   Widget _buildSubCategoriesSection(EnhancedCategoryFilterController controller, ThemeData theme, double screenWidth) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const SizedBox(height: 16),
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           child: Row(
//             children: [
//               Icon(Icons.subdirectory_arrow_right, size: 16, color: theme.primaryColor),
//               const SizedBox(width: 4),
//               Text(
//                 'الأقسام الفرعية',
//                 style: TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w600,
//                   color: theme.textTheme.titleMedium?.color,
//                 ),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 8),
//         SizedBox(
//           height: 70,
//           child: Obx(() {
//             final subCategories = controller.subCategoriesForSelectedMain;
//
//             return ListView.builder(
//               scrollDirection: Axis.horizontal,
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               itemCount: subCategories.length + 1, // +1 لخيار "الكل"
//               itemBuilder: (context, index) {
//                 if (index == 0) {
//                   // خيار "الكل" للأقسام الفرعية
//                   return _buildCategoryChip(
//                     context: context,
//                     controller: controller,
//                     categoryId: EnhancedCategoryFilterController.allFilterKey,
//                     categoryName: 'جميع الفرعيات',
//                     iconData: Icons.category,
//                     isMainCategory: false,
//                     theme: theme,
//                     isSmaller: true,
//                   );
//                 }
//
//                 final category = subCategories[index - 1];
//                 return _buildCategoryChip(
//                   context: context,
//                   controller: controller,
//                   categoryId: category.id,
//                   categoryName: category.nameAr,
//                   imageUrl: category.imageUrl,
//                   isMainCategory: false,
//                   theme: theme,
//                   category: category,
//                   isSmaller: true,
//                 );
//               },
//             );
//           }),
//         ),
//       ],
//     );
//   }
//
//   /// بناء شريحة الفئة (الرئيسية أو الفرعية)
//   Widget _buildCategoryChip({
//     required BuildContext context,
//     required EnhancedCategoryFilterController controller,
//     required String categoryId,
//     required String categoryName,
//     String? imageUrl,
//     IconData? iconData,
//     required bool isMainCategory,
//     required ThemeData theme,
//     EnhancedCategoryModel? category,
//     bool isSmaller = false,
//   }) {
//     final double chipWidth = isSmaller ? 100 : 120;
//     final double chipHeight = isSmaller ? 60 : 70;
//
//     return Obx(() {
//       final bool isSelected = isMainCategory
//           ? controller.selectedMainCategoryId.value == categoryId
//           : controller.selectedSubCategoryId.value == categoryId;
//
//       return Container(
//         width: chipWidth,
//         height: chipHeight,
//         margin: const EdgeInsets.only(right: 8),
//         child: Material(
//           color: Colors.transparent,
//           child: InkWell(
//             onTap: () {
//               if (isMainCategory) {
//                 controller.selectMainCategory(categoryId);
//               } else {
//                 controller.selectSubCategory(categoryId);
//               }
//             },
//             borderRadius: BorderRadius.circular(12),
//             child: Container(
//               decoration: BoxDecoration(
//                 color: isSelected
//                     ? theme.primaryColor.withOpacity(0.1)
//                     : Colors.grey.shade100,
//                 border: Border.all(
//                   color: isSelected
//                       ? theme.primaryColor
//                       : Colors.grey.shade300,
//                   width: isSelected ? 2.0 : 1.0,
//                 ),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   // صورة أو أيقونة
//                   SizedBox(
//                     width: isSmaller ? 24 : 30,
//                     height: isSmaller ? 24 : 30,
//                     child: imageUrl != null && imageUrl.isNotEmpty
//                         ? ClipRRect(
//                             borderRadius: BorderRadius.circular(6),
//                             child: CachedNetworkImage(
//                               imageUrl: imageUrl,
//                               fit: BoxFit.cover,
//                               placeholder: (context, url) => Icon(
//                                 Icons.category,
//                                 size: isSmaller ? 20 : 24,
//                                 color: Colors.grey[400],
//                               ),
//                               errorWidget: (context, url, error) => Icon(
//                                 Icons.error_outline,
//                                 size: isSmaller ? 20 : 24,
//                                 color: Colors.red[300],
//                               ),
//                             ),
//                           )
//                         : Icon(
//                             iconData ?? Icons.category,
//                             size: isSmaller ? 20 : 24,
//                             color: isSelected ? theme.primaryColor : Colors.grey[600],
//                           ),
//                   ),
//                   const SizedBox(height: 4),
//                   // نص الفئة
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 4),
//                     child: Text(
//                       categoryName,
//                       style: TextStyle(
//                         fontSize: isSmaller ? 10 : 12,
//                         fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
//                         color: isSelected ? theme.primaryColor : Colors.grey[700],
//                       ),
//                       textAlign: TextAlign.center,
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                   // عدد الأقسام الفرعية (للأقسام الرئيسية فقط)
//                   if (isMainCategory && category != null && category.subCategories.isNotEmpty)
//                     Text(
//                       '${category.subCategories.length}',
//                       style: TextStyle(
//                         fontSize: 8,
//                         color: isSelected ? theme.primaryColor : Colors.grey[500],
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       );
//     });
//   }
// }