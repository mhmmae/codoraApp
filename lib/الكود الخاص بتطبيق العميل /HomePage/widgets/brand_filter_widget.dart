import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../Model/company_model.dart';
import '../controllers/brand_filter_controller.dart';
import '../controllers/barcode_filter_controller.dart';
import 'barcode_search_widget.dart';

/// ويدجت البحث من خلال البراند مع الانيميشن الاحترافي
class BrandFilterWidget extends StatelessWidget {
  const BrandFilterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final BrandFilterController controller = Get.put(BrandFilterController());
    final BarcodeFilterController barcodeController = Get.put(BarcodeFilterController());
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // الأيقونة المتحركة للتبديل بين الأنماط
          _buildAnimatedToggleButton(controller, barcodeController, theme),
          
          const SizedBox(height: 16),
          
          // المحتوى المتحرك
          AnimatedBuilder(
            animation: controller.animationController,
            builder: (context, child) {
              return Obx(() {
                if (barcodeController.isBarcodeSearchActive.value) {
                  return _buildBarcodeSearchContent(barcodeController, theme);
                } else if (controller.isBrandModeActive.value) {
                  return _buildBrandFilterContent(controller, theme);
                } else {
                  return _buildAllProductsButton(controller, barcodeController, theme);
                }
              });
            },
          ),
          
          // عرض الباركود المحفوظ للبحث
          Obx(() => barcodeController.currentSearchBarcode.value.isNotEmpty
              ? _buildCurrentBarcodeDisplay(barcodeController, theme)
              : const SizedBox.shrink()),
        ],
      ),
    );
  }

  /// بناء عرض الباركود المحفوظ
  Widget _buildCurrentBarcodeDisplay(BarcodeFilterController barcodeController, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: theme.primaryColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.qr_code,
            color: theme.primaryColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الباركود المحفوظ:',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  barcodeController.currentSearchBarcode.value,
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          // زر المسح
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: barcodeController.clearCurrentBarcode,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.close,
                  color: theme.primaryColor,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// بناء الزر المتحرك للتبديل
  Widget _buildAnimatedToggleButton(BrandFilterController controller, BarcodeFilterController barcodeController, ThemeData theme) {
    return AnimatedBuilder(
      animation: controller.animationController,
      builder: (context, child) {
        return Obx(() {
          final isBrandActive = controller.isBrandModeActive.value;
          final isBarcodeActive = barcodeController.isBarcodeSearchActive.value;
          final isAllActive = !isBrandActive && !isBarcodeActive;
          
          return SizedBox(
            height: 100,
            child: isAllActive 
                ? Row(
                    children: [
                      // عرض الأزرار الثلاثة جنباً إلى جنب في الوضع العادي
                      Expanded(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 600),
                          opacity: 1.0,
                          child: _buildBrandSearchButton(controller, barcodeController, theme),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 600),
                          opacity: 1.0,
                          child: _buildBarcodeSearchButton(controller, barcodeController, theme),
                        ),
                      ),
                    ],
                  )
                : Stack(
                    children: [
                      // وضع النشاط الفردي مع زر العودة
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeInOutCubic,
                        left: 0,
                        top: 0,
                        bottom: 0,
                        right: 80,
                        child: Transform.scale(
                          scale: 1.0,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 400),
                            opacity: 1.0,
                            child: isBrandActive 
                                ? _buildBrandSearchButton(controller, barcodeController, theme)
                                : _buildBarcodeSearchButton(controller, barcodeController, theme),
                          ),
                        ),
                      ),
                      
                      // زر "كل المنتجات" للعودة
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeInOutCubic,
                        right: 0,
                        top: 0,
                        bottom: 0,
                        width: 70,
                        child: Transform.scale(
                          scale: 1.0,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 400),
                            opacity: 1.0,
                            child: _buildAllProductsToggleButton(controller, barcodeController, theme),
                          ),
                        ),
                      ),
                    ],
                  ),
          );
        });
      },
    );
  }

  /// زر "البحث من خلال البراند"
  Widget _buildBrandSearchButton(BrandFilterController controller, BarcodeFilterController barcodeController, ThemeData theme) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(18),
      shadowColor: Colors.purple.withOpacity(0.3),
      child: InkWell(
        onTap: () {
          // إضافة اهتزاز فوري لتأكيد النقر
          HapticFeedback.mediumImpact();
          
          debugPrint('🖱️ تم النقر على زر البحث من خلال البراند');
          
          // إلغاء البحث بالباركود أولاً إذا كان نشطاً
          if (barcodeController.isBarcodeSearchActive.value) {
            barcodeController.deactivateBarcodeSearch();
          }
          controller.activateBrandMode();
        },
        borderRadius: BorderRadius.circular(18),
        splashColor: Colors.white.withOpacity(0.4),
        highlightColor: Colors.white.withOpacity(0.2),
        splashFactory: InkRipple.splashFactory,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [
                Colors.purple.shade600,
                Colors.blue.shade600,
                Colors.teal.shade500,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.0, 0.5, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.35),
                blurRadius: 15,
                offset: const Offset(0, 8),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.blue.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // الصورة تأخذ معظم الحيز العمودي مع تأثير نابض
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.5),
                  child: CachedNetworkImage(
                    imageUrl: 'https://img.youm7.com/ArticleImgs/2020/5/14/73940-3.jpg',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (context, url) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey.shade300, Colors.grey.shade400],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(
                        Icons.business,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey.shade300, Colors.grey.shade400],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(
                        Icons.business,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // النص مع ظل محسن
              Flexible(
                child: Text(
                  'البحث من خلال البراند',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        offset: const Offset(1, 1.5),
                        blurRadius: 4,
                      ),
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // أيقونة السهم مع خلفية محسنة
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// زر "البحث بالباركود"
  Widget _buildBarcodeSearchButton(BrandFilterController controller, BarcodeFilterController barcodeController, ThemeData theme) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(18),
      shadowColor: Colors.deepPurple.withOpacity(0.3),
      child: InkWell(
        onTap: () {
          // إضافة اهتزاز فوري لتأكيد النقر
          HapticFeedback.mediumImpact();
          
          debugPrint('🖱️ تم النقر على زر البحث بالباركود');
          
          // إلغاء البحث بالبراند أولاً إذا كان نشطاً
          if (controller.isBrandModeActive.value) {
            controller.deactivateBrandModeAndClearMemory(); // مسح جميع المعلومات من الذاكرة عند التبديل
          }
          barcodeController.activateBarcodeSearch();
        },
        borderRadius: BorderRadius.circular(18),
        splashColor: Colors.white.withOpacity(0.4),
        highlightColor: Colors.white.withOpacity(0.2),
        splashFactory: InkRipple.splashFactory,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [
                Colors.deepPurple.shade600,
                Colors.indigo.shade600,
                Colors.blue.shade600,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.0, 0.5, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withOpacity(0.35),
                blurRadius: 15,
                offset: const Offset(0, 8),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.blue.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // أيقونة الباركود مع تأثير محسن
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 35,
                height: 35,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.qr_code_scanner,
                  color: Colors.white,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              // النص مع ظل محسن
              Flexible(
                child: Text(
                  'البحث بالباركود',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        offset: const Offset(1, 1.5),
                        blurRadius: 4,
                      ),
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // أيقونة السهم مع خلفية محسنة
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// زر "كل المنتجات" للعودة
  Widget _buildAllProductsToggleButton(BrandFilterController controller, BarcodeFilterController barcodeController, ThemeData theme) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(18),
      shadowColor: theme.primaryColor.withOpacity(0.25),
      child: InkWell(
        onTap: () {
          // إضافة اهتزاز فوري لتأكيد النقر
          HapticFeedback.lightImpact();
          
          debugPrint('🖱️ تم النقر على زر الإغلاق');
          
          // إلغاء أي وضع نشط
          if (controller.isBrandModeActive.value) {
            controller.deactivateBrandModeAndClearMemory(); // مسح جميع المعلومات من الذاكرة
          }
          if (barcodeController.isBarcodeSearchActive.value) {
            barcodeController.deactivateBarcodeSearch();
          }
        },
        borderRadius: BorderRadius.circular(18),
        splashColor: theme.primaryColor.withOpacity(0.3),
        highlightColor: theme.primaryColor.withOpacity(0.1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [
                Colors.white,
                Colors.grey.shade50,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: theme.primaryColor.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 6),
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.grey.withOpacity(0.15),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.primaryColor.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryColor.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.close,
                  color: theme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'إغلاق',
                style: TextStyle(
                  color: theme.primaryColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.1),
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// محتوى فلتر البراند
  Widget _buildBrandFilterContent(BrandFilterController controller, ThemeData theme) {
    return FadeTransition(
      opacity: controller.fadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(controller.slideAnimation),
        child: ScaleTransition(
          scale: controller.scaleAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // عنوان الشركات
              _buildSectionTitle('الشركات المتاحة', theme),
              const SizedBox(height: 12),
              
              // قائمة الشركات
              _buildCompaniesGrid(controller, theme),
              
              // المنتجات الفرعية للشركة المختارة
              Obx(() => controller.selectedCompany.value != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        _buildSectionTitle(
                          'منتجات ${controller.selectedCompany.value!.nameAr}', 
                          theme
                        ),
                        const SizedBox(height: 12),
                        _buildCompanyProductsGrid(controller, theme),
                      ],
                    )
                  : const SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }

  /// عنوان القسم
  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: theme.primaryColor,
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
    );
  }

  /// شبكة الشركات
  Widget _buildCompaniesGrid(BrandFilterController controller, ThemeData theme) {
    return Obx(() {
      if (controller.isLoading.value) {
        return SizedBox(
          height: 100,
          child: const Center(child: CircularProgressIndicator()),
        );
      }

      if (controller.companies.isEmpty) {
        return SizedBox(
          height: 100,
          child: const Center(
            child: Text(
              'لا توجد شركات متاحة',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
        );
      }

      return SizedBox(
        height: 140,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: controller.companies.length,
          itemBuilder: (context, index) {
            final company = controller.companies[index];
            final isSelected = controller.selectedCompany.value?.id == company.id;
            
            return _buildCompanyCard(controller, company, isSelected, theme);
          },
        ),
      );
    });
  }

  /// بطاقة الشركة مع التحسينات البصرية
  Widget _buildCompanyCard(
    BrandFilterController controller,
    CompanyModel company,
    bool isSelected,
    ThemeData theme,
  ) {
    return _CompanyCardTappable(
      key: ValueKey(company.id), // مفتاح لضمان إعادة البناء الصحيحة
      company: company,
      isSelected: isSelected,
      theme: theme,
      onTap: () {
        controller.selectCompany(company);
      },
    );
  }

  /// محتوى كل المنتجات
  Widget _buildAllProductsButton(BrandFilterController controller, BarcodeFilterController barcodeController, ThemeData theme) {
    return const SizedBox.shrink();
  }

  /// محتوى البحث بالباركود
  Widget _buildBarcodeSearchContent(BarcodeFilterController barcodeController, ThemeData theme) {
    return FadeTransition(
      opacity: AlwaysStoppedAnimation(1.0),
      child: BarcodeSearchWidget(
        controller: barcodeController,
        theme: theme,
      ),
    );
  }




  /// شبكة منتجات الشركة
  Widget _buildCompanyProductsGrid(BrandFilterController controller, ThemeData theme) {
    return Obx(() {
      if (controller.selectedCompanyProducts.isEmpty) {
        return SizedBox(
          height: 80,
          child: const Center(
            child: Text(
              'لا توجد منتجات لهذه الشركة',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
        );
      }

      return SizedBox(
        height: 110,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: controller.selectedCompanyProducts.length,
          itemBuilder: (context, index) {
            final product = controller.selectedCompanyProducts[index];
            final isSelected = controller.selectedCompanyProduct.value?.id == product.id;
            
            return _buildCompanyProductCard(controller, product, isSelected, theme);
          },
        ),
      );
    });
  }

  /// بطاقة منتج الشركة مع التحسينات البصرية
  Widget _buildCompanyProductCard(
    BrandFilterController controller,
    CompanyProductModel product,
    bool isSelected,
    ThemeData theme,
  ) {
    return _ProductCardTappable(
      key: ValueKey(product.id),
      product: product,
      isSelected: isSelected,
      theme: theme,
      onTap: () {
        controller.selectCompanyProduct(product);
      },
    );
  }
}

/// ويدجت مخصص للتعامل مع النقر على بطاقة الشركة مع تأثيرات بصرية محسنة
class _CompanyCardTappable extends StatefulWidget {
  final CompanyModel company;
  final bool isSelected;
  final ThemeData theme;
  final VoidCallback onTap;

  const _CompanyCardTappable({
    super.key,
    required this.company,
    required this.isSelected,
    required this.theme,
    required this.onTap,
  });

  @override
  State<_CompanyCardTappable> createState() => _CompanyCardTappableState();
}

class _CompanyCardTappableState extends State<_CompanyCardTappable> {
  @override
  Widget build(BuildContext context) {
    // استخدام الحالة الحقيقية من الكنترولر مباشرة
    final bool showAsSelected = widget.isSelected;

    return GestureDetector(
      onTap: () {
        // إضافة ردود فعل لمسية
        HapticFeedback.mediumImpact();
        debugPrint('🖱️ الضغط على الشركة: ${widget.company.nameAr}');

        // استدعاء الكنترولر لتحديث الحالة
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: 110,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: showAsSelected
              ? LinearGradient(
                  colors: [
                    widget.theme.primaryColor.withOpacity(0.15),
                    widget.theme.primaryColor.withOpacity(0.08),
                    Colors.white,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: const [0.0, 0.5, 1.0],
                )
              : LinearGradient(
                  colors: [Colors.white, Colors.grey.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          border: Border.all(
            color: showAsSelected
                ? widget.theme.primaryColor
                : Colors.grey.shade300,
            width: showAsSelected ? 3 : 1,
          ),
          boxShadow: showAsSelected
              ? [
                  BoxShadow(
                    color: widget.theme.primaryColor.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: widget.theme.primaryColor.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: widget.company.logoUrl != null &&
                            widget.company.logoUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: widget.company.logoUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            placeholder: (context, url) =>
                                const Icon(Icons.business,
                                    color: Colors.grey, size: 25),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.business,
                                    color: Colors.grey, size: 25),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.grey.shade200,
                                  Colors.grey.shade300
                                ],
                              ),
                            ),
                            child: const Icon(Icons.business,
                                color: Colors.grey, size: 25),
                          ),
                  ),
                  // إظهار علامة الصح بناءً على الحالة الحقيقية
                  Positioned(
                    top: -4,
                    right: -4,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: showAsSelected ? 1.0 : 0.0,
                      child: Transform.scale(
                        scale: showAsSelected ? 1.0 : 0.5,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: widget.theme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check,
                                color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.company.nameAr,
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    showAsSelected ? FontWeight.bold : FontWeight.w600,
                color: showAsSelected
                    ? widget.theme.primaryColor
                    : Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// ويدجت مخصص للتعامل مع النقر على بطاقة المنتج مع تأثيرات بصرية محسنة
class _ProductCardTappable extends StatefulWidget {
  final CompanyProductModel product;
  final bool isSelected;
  final ThemeData theme;
  final VoidCallback onTap;

  const _ProductCardTappable({
    super.key,
    required this.product,
    required this.isSelected,
    required this.theme,
    required this.onTap,
  });

  @override
  State<_ProductCardTappable> createState() => _ProductCardTappableState();
}

class _ProductCardTappableState extends State<_ProductCardTappable> {
  @override
  Widget build(BuildContext context) {
    final bool showAsSelected = widget.isSelected;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        debugPrint('🖱️ الضغط على المنتج: ${widget.product.nameAr}');
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: 90,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: showAsSelected
              ? LinearGradient(
                  colors: [
                    widget.theme.primaryColor.withOpacity(0.2),
                    widget.theme.primaryColor.withOpacity(0.1),
                    Colors.white,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: const [0.0, 0.6, 1.0],
                )
              : LinearGradient(
                  colors: [Colors.white, Colors.grey.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          border: Border.all(
            color: showAsSelected
                ? widget.theme.primaryColor
                : Colors.grey.shade300,
            width: showAsSelected ? 2.5 : 1,
          ),
          boxShadow: showAsSelected
              ? [
                  BoxShadow(
                    color: widget.theme.primaryColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                    spreadRadius: 1,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: widget.product.imageUrl != null &&
                            widget.product.imageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: widget.product.imageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.grey.shade200,
                                  Colors.grey.shade300
                                ],
                              ),
                            ),
                            child: const Icon(Icons.inventory_2,
                                color: Colors.grey, size: 20),
                          ),
                  ),
                  Positioned(
                    top: -2,
                    right: -2,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: showAsSelected ? 1.0 : 0.0,
                      child: Transform.scale(
                        scale: showAsSelected ? 1.0 : 0.5,
                        child: Container(
                          padding: const EdgeInsets.all(1.5),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: widget.theme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check,
                                color: Colors.white, size: 12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.product.nameAr,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    showAsSelected ? FontWeight.bold : FontWeight.w600,
                color: showAsSelected
                    ? widget.theme.primaryColor
                    : Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}