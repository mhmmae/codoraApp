import 'country_filter_widget.dart';

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/store_products_controller.dart';

/// محور الفلترة المتحرك (Morphing Filter Hub)
class MorphingFilterHub extends StatefulWidget {
  final StoreProductsController controller;
  final VoidCallback onClose;
  const MorphingFilterHub({
    super.key,
    required this.controller,
    required this.onClose,
  });

  @override
  State<MorphingFilterHub> createState() => _MorphingFilterHubState();
}

class _MorphingFilterHubState extends State<MorphingFilterHub>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  int _selectedTab = 0;
  final List<String> _tabs = ['السعر', 'بلد الصنع', 'الجودة', 'العروض'];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Widget _buildTabBar() {
    // Make the tab bar horizontally scrollable and visually enhanced
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final selected = _selectedTab == i;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                gradient:
                    selected
                        ? LinearGradient(
                          colors: [
                            Get.theme.primaryColor,
                            Get.theme.primaryColor.withOpacity(0.7),
                          ],
                        )
                        : null,
                color: selected ? null : Colors.grey[100],
                borderRadius: BorderRadius.circular(18),
                boxShadow:
                    selected
                        ? [
                          BoxShadow(
                            color: Get.theme.primaryColor.withOpacity(0.15),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ]
                        : [],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => setState(() => _selectedTab = i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  child: Text(
                    _tabs[i],
                    style: TextStyle(
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                      color: selected ? Colors.white : Get.theme.primaryColor,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        // السعر
        return Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'حدد نطاق السعر',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Get.theme.primaryColor,
                ),
              ),
              SizedBox(height: 8),
              RangeSlider(
                min: widget.controller.minPrice.value,
                max: widget.controller.maxPrice.value,
                values: RangeValues(
                  widget.controller.currentMinPrice.value,
                  widget.controller.currentMaxPrice.value,
                ),
                onChanged: (v) => widget.controller.setPriceRange(v),
                activeColor: Get.theme.primaryColor,
                inactiveColor: Colors.grey[300],
                divisions: ((widget.controller.maxPrice.value -
                            widget.controller.minPrice.value) ~/
                        10)
                    .clamp(1, 100),
                labels: RangeLabels(
                  widget.controller.currentMinPrice.value.toStringAsFixed(0),
                  widget.controller.currentMaxPrice.value.toStringAsFixed(0),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'من: ${widget.controller.currentMinPrice.value.toStringAsFixed(0)}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'إلى: ${widget.controller.currentMaxPrice.value.toStringAsFixed(0)}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        );
      case 1:
        // بلد الصنع مع بحث نصي واقتراحات
        return CountryFilterWidget(controller: widget.controller);
      case 2:
        // نوع المنتج (أصلي/تجاري)
        final selectedType = widget.controller.selectedProductType.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'فلتر نوع المنتج',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Get.theme.primaryColor,
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: selectedType == 'الكل' ? null : selectedType,
              decoration: InputDecoration(
                labelText: 'اختر نوع المنتج',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              items: const [
                DropdownMenuItem(value: 'أصلي', child: Text('أصلي')),
                DropdownMenuItem(value: 'تجاري', child: Text('تجاري')),
              ],
              onChanged: (value) {
                widget.controller.selectedProductType.value = value ?? 'الكل';
                widget.controller.applyFilters();
              },
              isExpanded: true,
              hint: const Text('الكل'),
            ),
          ],
        );
      case 3:
        // العروض
        return Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'عرض المنتجات التي عليها عروض فقط',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Get.theme.primaryColor,
                      ),
                    ),
                  ),
                  Switch(
                    value: widget.controller.filterOnOffer.value,
                    onChanged: (val) => widget.controller.toggleOnOffer(),
                    activeColor: Get.theme.primaryColor,
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                widget.controller.filterOnOffer.value
                    ? 'سيتم عرض المنتجات التي عليها خصم فقط.'
                    : 'سيتم عرض جميع المنتجات بغض النظر عن العروض.',
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
              ),
            ],
          ),
        );
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animController,
      child: Stack(
        children: [
          // خلفية ضبابية
          GestureDetector(
            onTap: widget.onClose,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                color: Colors.black.withOpacity(0.25),
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          // محور الفلترة داخل Material
          Align(
            alignment: Alignment.topCenter,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.2),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: _animController, curve: Curves.easeOut),
              ),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _animController,
                    curve: Curves.easeOut,
                  ),
                ),
                child: Material(
                  type: MaterialType.card,
                  color: Colors.transparent,
                  elevation: 0,
                  child: Container(
                    margin: const EdgeInsets.only(top: 80, left: 8, right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 22,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 28,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // شريط Tabs
                        _buildTabBar(),
                        const SizedBox(height: 18),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          child: _buildTabContent(),
                          transitionBuilder:
                              (child, anim) => SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.1),
                                  end: Offset.zero,
                                ).animate(anim),
                                child: child,
                              ),
                        ),
                        const SizedBox(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.check),
                              label: const Text('تطبيق الفلاتر'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Get.theme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              onPressed: () {
                                widget.controller.applyFilters();
                                widget.onClose();
                              },
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text('مسح الكل'),
                              style: TextButton.styleFrom(
                                foregroundColor: Get.theme.primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              onPressed: () {
                                widget.controller.clearFilters();
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // زر الإغلاق (Morphing Icon)
          Positioned(
            top: 90,
            right: 32,
            child: AnimatedIcon(
              icon: AnimatedIcons.menu_close,
              progress: _animController,
              color: Get.theme.primaryColor,
              size: 32,
            ),
          ),
          Positioned(
            top: 80,
            right: 24,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.redAccent, size: 28),
              onPressed: widget.onClose,
            ),
          ),
        ],
      ),
    );
  }
}
