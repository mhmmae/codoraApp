import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/store_products_controller.dart';
import 'filter_chip.dart';

class SearchAndFilters extends StatelessWidget {
  final StoreProductsController controller;

  const SearchAndFilters({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // شريط البحث المحسن
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller.searchController,
                  onChanged: (value) {
                    controller.searchProducts();
                  },
                  decoration: InputDecoration(
                    hintText: 'ابحث عن المنتجات...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // البحث الصوتي
                        IconButton(
                          onPressed: () => controller.startVoiceSearch(),
                          icon: Icon(Icons.mic, color: const Color(0xFF6366F1)),
                          tooltip: 'البحث الصوتي',
                        ),
                        // مسح البحث
                        IconButton(
                          onPressed: () {
                            controller.searchController.clear();
                            controller.searchProducts();
                          },
                          icon: Icon(Icons.clear, color: Colors.grey[600]),
                          tooltip: 'مسح البحث',
                        ),
                      ],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: const Color(0xFF6366F1)),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              // زر الفلاتر المتقدمة
              Container(
                decoration: BoxDecoration(
                  color: controller.hasActiveFilters() ? const Color(0xFF6366F1) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: IconButton(
                  onPressed: () => _showAdvancedFilters(context),
                  icon: Icon(
                    Icons.tune,
                    color: controller.hasActiveFilters() ? Colors.white : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          // فلاتر الفئات السريعة
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Obx(() => CustomFilterChip(
                  label: 'الكل',
                  isSelected: controller.selectedCategory.value.isEmpty,
                  onTap: () => controller.filterByCategory(''),
                )),
                SizedBox(width: 8.w),
                Obx(() => CustomFilterChip(
                  label: 'المفضلة',
                  isSelected: controller.showFavoritesOnly.value,
                  onTap: () => controller.toggleFavoritesFilter(),
                )),
                SizedBox(width: 8.w),
                Obx(() => CustomFilterChip(
                  label: 'عروض',
                  isSelected: controller.showDiscountedOnly.value,
                  onTap: () => controller.toggleDiscountFilter(),
                )),
                SizedBox(width: 8.w),
                Obx(() => CustomFilterChip(
                  label: 'إلكترونيات',
                  isSelected: controller.selectedCategory.value == 'إلكترونيات',
                  onTap: () => controller.filterByCategory('إلكترونيات'),
                )),
                SizedBox(width: 8.w),
                Obx(() => CustomFilterChip(
                  label: 'ملابس',
                  isSelected: controller.selectedCategory.value == 'ملابس',
                  onTap: () => controller.filterByCategory('ملابس'),
                )),
                SizedBox(width: 8.w),
                Obx(() => CustomFilterChip(
                  label: 'منزل وحديقة',
                  isSelected: controller.selectedCategory.value == 'منزل وحديقة',
                  onTap: () => controller.filterByCategory('منزل وحديقة'),
                )),
              ],
            ),
          ),
          // شريط الترتيب
          SizedBox(height: 12.h),
          Row(
            children: [
              Text(
                'ترتيب حسب:',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildSortChip('الأحدث', 'newest'),
                      SizedBox(width: 6.w),
                      _buildSortChip('السعر ↑', 'price_low'),
                      SizedBox(width: 6.w),
                      _buildSortChip('السعر ↓', 'price_high'),
                      SizedBox(width: 6.w),
                      _buildSortChip('الاسم', 'name'),
                      SizedBox(width: 6.w),
                      _buildSortChip('التقييم', 'rating'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, String sortType) {
    return Obx(() => GestureDetector(
      onTap: () => controller.sortProducts(sortType),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: controller.sortBy.value == sortType 
              ? const Color(0xFF6366F1) 
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: controller.sortBy.value == sortType 
                ? const Color(0xFF6366F1) 
                : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            color: controller.sortBy.value == sortType 
                ? Colors.white 
                : Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ));
  }

  void _showAdvancedFilters(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الفلاتر المتقدمة',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: Icon(Icons.close, color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            // فلتر السعر
            Text(
              'نطاق السعر',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            SizedBox(height: 10.h),
            Obx(() => RangeSlider(
              values: RangeValues(
                controller.minPrice.value,
                controller.maxPrice.value,
              ),
              min: 0,
              max: 1000,
              divisions: 20,
              labels: RangeLabels(
                '${controller.minPrice.value.round()} ريال',
                '${controller.maxPrice.value.round()} ريال',
              ),
              onChanged: (values) {
                controller.updatePriceRange(values.start, values.end);
              },
              activeColor: const Color(0xFF6366F1),
            )),
            SizedBox(height: 20.h),
            // فلتر التقييم
            Text(
              'التقييم الأدنى',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            SizedBox(height: 10.h),
            Row(
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => controller.setMinRating(index + 1.0),
                  child: Padding(
                    padding: EdgeInsets.only(right: 4.w),
                    child: Icon(
                      Icons.star,
                      color: (index + 1) <= controller.minRating.value 
                          ? Colors.amber 
                          : Colors.grey[300],
                      size: 24.sp,
                    ),
                  ),
                );
              }),
            ),
            SizedBox(height: 20.h),
            // أزرار التحكم
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      controller.clearAllFilters();
                      Get.back();
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[400]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'مسح الكل',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      controller.applyFilters();
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'تطبيق',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}