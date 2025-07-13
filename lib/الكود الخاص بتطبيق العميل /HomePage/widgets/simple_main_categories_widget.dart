import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/enhanced_category_filter_controller.dart';

/// Widget محسن لعرض الأقسام الرئيسية والفرعية في تطبيق العميل مع صور وانيميشن احترافي
class SimpleMainCategoriesWidget extends StatefulWidget {
  const SimpleMainCategoriesWidget({super.key});

  @override
  State<SimpleMainCategoriesWidget> createState() => _SimpleMainCategoriesWidgetState();
}

class _SimpleMainCategoriesWidgetState extends State<SimpleMainCategoriesWidget> 
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _subCategoriesAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _subCategoriesAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _subCategoriesAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final EnhancedCategoryFilterController controller = Get.put(EnhancedCategoryFilterController());
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان القسم
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.category,
                  color: theme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'الأقسام الرئيسية',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
                const Spacer(),
                // زر إعادة التعيين
                Obx(() {
                  if (!controller.hasAnyActiveFilter) {
                    return const SizedBox.shrink();
                  }
                  return TextButton.icon(
                    onPressed: controller.resetFilters,
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('إعادة تعيين'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  );
                }),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // قائمة الأقسام الأفقية
          _buildMainCategoriesList(controller, theme),
          
          // الأقسام الفرعية
          Obx(() {
            if (controller.selectedMainCategoryId.value.isNotEmpty && 
                controller.subCategories.isNotEmpty) {
              // تشغيل انيميشن الأقسام الفرعية
              _subCategoriesAnimationController.forward();
              
              return AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _subCategoriesAnimationController,
                    curve: Curves.easeOut,
                  ),
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.2),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _subCategoriesAnimationController,
                      curve: Curves.easeOut,
                    )),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        _buildSubCategoriesSection(controller, theme),
                      ],
                    ),
                  ),
                ),
              );
            } else {
              // إعادة تعيين انيميشن الأقسام الفرعية
              _subCategoriesAnimationController.reset();
              return const SizedBox.shrink();
            }
          }),
        ],
      ),
    );
  }

  Widget _buildMainCategoriesList(EnhancedCategoryFilterController controller, ThemeData theme) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const SizedBox(
          height: 110,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      if (controller.mainCategories.isEmpty) {
        return Container(
          height: 110,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text(
              'لا توجد أقسام متاحة',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        );
      }

      return FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: controller.mainCategories.length + 1, // +1 للخيار "الكل"
              itemBuilder: (context, index) {
                // انيميشن منفصل لكل عنصر
                return AnimationCard(
                  delay: Duration(milliseconds: index * 100),
                  child: Builder(builder: (context) {
            if (index == 0) {
              // خيار "الكل"
              return _buildCategoryCard(
                context: context,
                controller: controller,
                categoryId: '',
                categoryName: 'الكل',
                iconName: 'all',
                color: 'blue',
                imageUrl: null,
                subCategoriesCount: 0,
                onTap: () => controller.selectMainCategory('', 'الكل'),
                theme: theme,
              );
            }

            final category = controller.mainCategories[index - 1];
            // حساب عدد الأقسام الفرعية لهذا القسم الرئيسي
            final subCount = category.id.isEmpty ? 0 : 
              controller.allCategories.where((cat) => cat.parentId == category.id).length;
            
            return _buildCategoryCard(
              context: context,
              controller: controller,
              categoryId: category.id,
              categoryName: category.nameAr,
              iconName: category.iconName,
              color: category.color,
              imageUrl: category.imageUrl,
              subCategoriesCount: subCount,
              onTap: () => controller.selectMainCategory(category.id, category.nameAr),
              theme: theme,
            );
                  }),
                );
          },
        ),
          ),
        ),
      );
    });
  }

  Widget _buildSubCategoriesSection(EnhancedCategoryFilterController controller, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // عنوان الأقسام الفرعية
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(
                Icons.subdirectory_arrow_right,
                color: theme.primaryColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'الأقسام الفرعية',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.primaryColor,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // قائمة الأقسام الفرعية
        Obx(() {
          if (controller.isLoadingSubCategories.value) {
            return const SizedBox(
              height: 60,
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }

          return SizedBox(
            height: 85,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: controller.subCategories.length + 1, // +1 للخيار "الكل"
              itemBuilder: (context, index) {
                if (index == 0) {
                  // خيار "الكل" للأقسام الفرعية
                  return _buildSubCategoryChip(
                    controller: controller,
                    categoryId: '',
                    categoryName: 'الكل',
                    imageUrl: null,
                    onTap: () => controller.selectSubCategory('', ''),
                    theme: theme,
                  );
                }

                final subCategory = controller.subCategories[index - 1];
                return _buildSubCategoryChip(
                  controller: controller,
                  categoryId: subCategory.id,
                  categoryName: subCategory.nameAr,
                  imageUrl: subCategory.imageUrl,
                  onTap: () => controller.selectSubCategory(subCategory.id, subCategory.nameAr),
                  theme: theme,
                );
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCategoryCard({
    required BuildContext context,
    required EnhancedCategoryFilterController controller,
    required String categoryId,
    required String categoryName,
    String? iconName,
    String? color,
    String? imageUrl,
    int subCategoriesCount = 0,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return Obx(() {
      final bool isSelected = categoryId.isEmpty 
          ? controller.selectedMainCategoryId.value.isEmpty
          : controller.selectedMainCategoryId.value == categoryId;
      final double targetWidth = isSelected ? 120 : 60;
      final double targetHeight = isSelected ? 100 : 50;
      final double targetFontSize = isSelected ? 16 : 6;
      final FontWeight targetFontWeight = isSelected ? FontWeight.w900 : FontWeight.bold;
      final Color targetTextColor = isSelected ? theme.primaryColor : (imageUrl != null && imageUrl.isNotEmpty ? Colors.white : Colors.black87);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.elasticOut,
            width: targetWidth,
            height: targetHeight,
            margin: const EdgeInsets.only(left: 6),
            child: Material(
              elevation: isSelected ? 12 : 2,
              borderRadius: BorderRadius.circular(isSelected ? 24 : 16),
              shadowColor: theme.primaryColor.withOpacity(0.2),
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onTap();
                },
                borderRadius: BorderRadius.circular(isSelected ? 24 : 16),
                splashColor: theme.primaryColor.withOpacity(0.3),
                highlightColor: theme.primaryColor.withOpacity(0.1),
                onTapDown: (_) {
                  HapticFeedback.lightImpact();
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(isSelected ? 24 : 16),
                    gradient: isSelected 
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
                          )
                        : const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.white, Colors.white],
                          ),
                    border: Border.all(
                      color: isSelected ? Colors.deepPurple : Colors.grey[300]!,
                      width: isSelected ? 4 : 1,
                    ),
                    boxShadow: isSelected 
                        ? [
                            BoxShadow(
                              color: theme.primaryColor.withOpacity(0.3),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                              spreadRadius: 2,
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Stack(
                    children: [
                      if (imageUrl != null && imageUrl.isNotEmpty)
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(isSelected ? 23 : 15),
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[100],
                                child: Icon(
                                  _getIconForCategory(iconName),
                                  color: Colors.grey[400],
                                  size: isSelected ? 48 : 32,
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[100],
                                child: Icon(
                                  _getIconForCategory(iconName),
                                  color: Colors.grey[400],
                                  size: isSelected ? 48 : 32,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (imageUrl != null && imageUrl.isNotEmpty)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(isSelected ? 23 : 15),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                                stops: const [0.3, 1.0],
                              ),
                            ),
                          ),
                        ),
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (imageUrl == null || imageUrl.isEmpty)
                                Icon(
                                  _getIconForCategory(iconName),
                                  color: isSelected ? Colors.white : _getColorFromString(color) ?? theme.primaryColor,
                                  size: isSelected ? 32 : 16,
                                ),
                              const SizedBox(height: 1),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isSelected ? theme.primaryColor.withOpacity(0.85) : Colors.white.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: theme.primaryColor.withOpacity(0.13),
                                            blurRadius: 4,
                                            offset: Offset(0, 1),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeInOutCubic,
                                  style: TextStyle(
                                    fontSize: targetFontSize,
                                    fontWeight: targetFontWeight,
                                    color: isSelected ? Colors.white : theme.primaryColor,
                                    letterSpacing: 0.1,
                                    shadows: isSelected
                                        ? [
                                            Shadow(
                                              offset: Offset(0, 1),
                                              blurRadius: 4,
                                              color: theme.primaryColor.withOpacity(0.18),
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: Text(
                                    categoryName,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSubCategoryChip({
    required EnhancedCategoryFilterController controller,
    required String categoryId,
    required String categoryName,
    String? imageUrl,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return Obx(() {
      final bool isSelected = categoryId.isEmpty 
          ? controller.selectedSubCategoryId.value.isEmpty
          : controller.selectedSubCategoryId.value == categoryId;
      final double targetWidth = isSelected ? 85 : 60;
      final double targetHeight = isSelected ? 75 : 54;
      final double targetFontSize = isSelected ? 10 : 5;
      final FontWeight targetFontWeight = isSelected ? FontWeight.w900 : FontWeight.bold;
      final Color targetTextColor = isSelected ? theme.primaryColor : (imageUrl != null && imageUrl.isNotEmpty ? Colors.white : Colors.black87);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.elasticOut,
            width: targetWidth,
            height: targetHeight,
            margin: const EdgeInsets.only(left: 5),
            child: Material(
              elevation: isSelected ? 10 : 3,
              borderRadius: BorderRadius.circular(isSelected ? 28 : 20),
              shadowColor: theme.primaryColor.withOpacity(0.3),
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onTap();
                },
                borderRadius: BorderRadius.circular(isSelected ? 28 : 20),
                splashColor: theme.primaryColor.withOpacity(0.4),
                highlightColor: theme.primaryColor.withOpacity(0.2),
                onTapDown: (_) {
                  HapticFeedback.lightImpact();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(isSelected ? 28 : 20),
                    gradient: isSelected
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
                          )
                        : const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.white, Colors.white],
                          ),
                    border: Border.all(
                      color: isSelected ? Colors.deepPurple : Colors.grey[300]!,
                      width: isSelected ? 4 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: theme.primaryColor.withOpacity(0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                              spreadRadius: 2,
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.15),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Stack(
                    children: [
                      if (imageUrl != null && imageUrl.isNotEmpty)
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(isSelected ? 27 : 19),
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[100],
                                child: Icon(
                                  Icons.category_outlined,
                                  color: Colors.grey[400],
                                  size: isSelected ? 28 : 14,
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[100],
                                child: Icon(
                                  Icons.category_outlined,
                                  color: Colors.grey[400],
                                  size: isSelected ? 28 : 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (imageUrl != null && imageUrl.isNotEmpty)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(isSelected ? 27 : 13),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                                stops: const [0.4, 1.0],
                              ),
                            ),
                          ),
                        ),
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (imageUrl == null || imageUrl.isEmpty)
                                Icon(
                                  Icons.category_outlined,
                                  color: isSelected ? Colors.white : theme.primaryColor,
                                  size: isSelected ? 28 : 14,
                                ),
                              const SizedBox(height: 1),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isSelected ? theme.primaryColor.withOpacity(0.85) : Colors.white.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(7),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: theme.primaryColor.withOpacity(0.13),
                                            blurRadius: 3,
                                            offset: Offset(0, 1),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 350),
                                  curve: Curves.easeInOutCubic,
                                  style: TextStyle(
                                    fontSize: targetFontSize,
                                    fontWeight: targetFontWeight,
                                    color: isSelected ? Colors.white : theme.primaryColor,
                                    letterSpacing: 0.1,
                                    shadows: isSelected
                                        ? [
                                            Shadow(
                                              offset: Offset(0, 1),
                                              blurRadius: 4,
                                              color: theme.primaryColor.withOpacity(0.18),
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: Text(
                                    categoryName.isEmpty ? 'الكل' : categoryName,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  IconData _getIconForCategory(String? iconName) {
    switch (iconName?.toLowerCase()) {
      case 'all':
        return Icons.apps;
      case 'food':
        return Icons.restaurant;
      case 'electronics':
        return Icons.devices;
      case 'clothing':
        return Icons.checkroom;
      case 'home':
        return Icons.home;
      case 'books':
        return Icons.book;
      case 'sports':
        return Icons.sports;
      case 'beauty':
        return Icons.face;
      case 'toys':
        return Icons.toys;
      case 'automotive':
        return Icons.directions_car;
      case 'health':
        return Icons.medical_services;
      case 'tools':
        return Icons.build;
      case 'garden':
        return Icons.eco;
      default:
        return Icons.category;
    }
  }

  Color? _getColorFromString(String? colorString) {
    if (colorString == null) return null;
    
    switch (colorString.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'teal':
        return Colors.teal;
      case 'pink':
        return Colors.pink;
      case 'indigo':
        return Colors.indigo;
      case 'cyan':
        return Colors.cyan;
      case 'amber':
        return Colors.amber;
      case 'brown':
        return Colors.brown;
      case 'grey':
        return Colors.grey;
      default:
        return null;
    }
  }
}

/// Widget انيميشن احترافي للكروت
class AnimationCard extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const AnimationCard({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  @override
  State<AnimationCard> createState() => _AnimationCardState();
}

class _AnimationCardState extends State<AnimationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
    ));

    // تأخير بدء الانيميشن
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: widget.child,
        ),
      ),
    );
  }
} 