import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // لاستخدام HapticFeedback
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../Model/SellerModel.dart';
import '../controllers/wholesale_market_controller.dart';
import 'store_products_page.dart';

class WholesaleMarketPage extends StatelessWidget {
  const WholesaleMarketPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(WholesaleMarketController());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.refresh,
          color: const Color(0xFF6366F1),
          child: Column(
            children: [
              _buildSearchAndFilters(controller),
              Expanded(child: _buildStoresList(controller)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewToggle(WholesaleMarketController controller) {
    return Obx(
      () => Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.05),
              spreadRadius: 0,
              blurRadius: 8.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildToggleButton(
              icon: Icons.view_list_rounded,
              isActive: !controller.isGridView.value,
              onTap: () => controller.isGridView.value = false,
            ),
            SizedBox(width: 4.w),
            _buildToggleButton(
              icon: Icons.grid_view_rounded,
              isActive: controller.isGridView.value,
              onTap: () => controller.isGridView.value = true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // تأثير اهتزاز خفيف
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(12.r),
        splashColor: const Color(0xFF6366F1).withOpacity(0.3),
        highlightColor: const Color(0xFF6366F1).withOpacity(0.1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF6366F1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow:
                isActive
                    ? [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                        blurRadius: 6.r,
                        offset: Offset(0, 3.h),
                      ),
                    ]
                    : null,
          ),
          child: Icon(
            icon,
            size: 20.sp,
            color: isActive ? Colors.white : const Color(0xFF6366F1),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(WholesaleMarketController controller) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 10.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSearchBarWithViewToggle(controller),
          SizedBox(height: 16.h),
          _buildFilterChips(controller),
          Obx(
            () => AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState:
                  controller.showFilters.value
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: _buildAdvancedFilters(controller),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBarWithViewToggle(WholesaleMarketController controller) {
    return Row(
      children: [
        Expanded(child: _buildSearchBar(controller)),
        SizedBox(width: 12.w),
        _buildViewToggle(controller),
      ],
    );
  }

  Widget _buildSearchBar(WholesaleMarketController controller) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: TextField(
        controller: controller.searchController,
        focusNode: controller.searchFocusNode,
        decoration: InputDecoration(
          hintText: 'ابحث عن متاجر، فئات، أو مواقع...',
          hintStyle: TextStyle(fontSize: 16.sp, color: Colors.grey[500]),
          prefixIcon: Padding(
            padding: EdgeInsets.all(12.w),
            child: Icon(
              Icons.search_rounded,
              size: 24.sp,
              color: const Color(0xFF6366F1),
            ),
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(
                () =>
                    controller.hasFilters
                        ? IconButton(
                          onPressed: controller.clearFilters,
                          icon: Icon(
                            Icons.clear_rounded,
                            size: 20.sp,
                            color: Colors.grey[600],
                          ),
                        )
                        : const SizedBox.shrink(),
              ),
              IconButton(
                onPressed: controller.toggleFilters,
                icon: Obx(
                  () => Icon(
                    controller.showFilters.value
                        ? Icons.filter_list_off_rounded
                        : Icons.filter_list_rounded,
                    size: 20.sp,
                    color: const Color(0xFF6366F1),
                  ),
                ),
              ),
            ],
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 20.w,
            vertical: 16.h,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(WholesaleMarketController controller) {
    return Obx(
      () => SizedBox(
        height: 40.h,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: controller.categories.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildSortChip(controller);
            }
            final category = controller.categories[index - 1];
            return _buildCategoryChip(controller, category);
          },
        ),
      ),
    );
  }

  Widget _buildSortChip(WholesaleMarketController controller) {
    return Padding(
      padding: EdgeInsets.only(left: 8.w),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sort_rounded,
              size: 16.sp,
              color: const Color(0xFF6366F1),
            ),
            SizedBox(width: 4.w),
            Text('ترتيب', style: TextStyle(fontSize: 12.sp)),
          ],
        ),
        selected: false,
        onSelected: (_) {
          // إظهار خيارات الترتيب
          Get.bottomSheet(
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ترتيب حسب',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ترتيب حسب الاسم
                  Obx(
                    () => ListTile(
                      leading: Icon(
                        Icons.sort_by_alpha_rounded,
                        color:
                            controller.sortBy.value == 'name'
                                ? const Color(0xFF6366F1)
                                : Colors.grey[600],
                      ),
                      title: Text(
                        'الاسم',
                        style: TextStyle(
                          color:
                              controller.sortBy.value == 'name'
                                  ? const Color(0xFF6366F1)
                                  : Colors.grey[800],
                          fontWeight:
                              controller.sortBy.value == 'name'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                        ),
                      ),
                      trailing:
                          controller.sortBy.value == 'name'
                              ? Icon(
                                Icons.check_rounded,
                                color: const Color(0xFF6366F1),
                              )
                              : null,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        controller.setSortBy('name');
                        Get.back();
                      },
                    ),
                  ),

                  // ترتيب حسب الفئة
                  Obx(
                    () => ListTile(
                      leading: Icon(
                        Icons.category_rounded,
                        color:
                            controller.sortBy.value == 'category'
                                ? const Color(0xFF6366F1)
                                : Colors.grey[600],
                      ),
                      title: Text(
                        'الفئة',
                        style: TextStyle(
                          color:
                              controller.sortBy.value == 'category'
                                  ? const Color(0xFF6366F1)
                                  : Colors.grey[800],
                          fontWeight:
                              controller.sortBy.value == 'category'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                        ),
                      ),
                      trailing:
                          controller.sortBy.value == 'category'
                              ? Icon(
                                Icons.check_rounded,
                                color: const Color(0xFF6366F1),
                              )
                              : null,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        controller.setSortBy('category');
                        Get.back();
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
          side: BorderSide(color: const Color(0xFF6366F1).withOpacity(0.3)),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(
    WholesaleMarketController controller,
    String category,
  ) {
    return Padding(
      padding: EdgeInsets.only(left: 8.w),
      child: Obx(
        () => FilterChip(
          label: Text(
            category,
            style: TextStyle(
              fontSize: 12.sp,
              color:
                  controller.selectedCategory.value == category
                      ? Colors.white
                      : const Color(0xFF6366F1),
            ),
          ),
          selected: controller.selectedCategory.value == category,
          onSelected: (_) => controller.selectCategory(category),
          selectedColor: const Color(0xFF6366F1),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
            side: BorderSide(color: const Color(0xFF6366F1).withOpacity(0.3)),
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedFilters(WholesaleMarketController controller) {
    return Container(
      margin: EdgeInsets.only(top: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 10.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'فلاتر متقدمة',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 12.h),
          // يمكن إضافة المزيد من الفلاتر هنا
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: controller.clearFilters,
                  icon: Icon(Icons.clear_all_rounded, size: 16.sp),
                  label: Text('مسح الفلاتر', style: TextStyle(fontSize: 12.sp)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    foregroundColor: Colors.grey[700],
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStoresList(WholesaleMarketController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return _buildLoadingState();
      }

      if (controller.filteredStores.isEmpty) {
        return _buildEmptyState(controller);
      }

      return AnimationLimiter(
        child:
            controller.isGridView.value
                ? _buildGridView(controller)
                : _buildListView(controller),
      );
    });
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 0,
                  blurRadius: 20.r,
                ),
              ],
            ),
            child: Column(
              children: [
                CircularProgressIndicator(
                  color: const Color(0xFF6366F1),
                  strokeWidth: 3.w,
                ),
                SizedBox(height: 16.h),
                Text(
                  'جاري تحميل المتاجر...',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(WholesaleMarketController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 0,
                  blurRadius: 20.r,
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50.r),
                  ),
                  child: Icon(
                    Icons.store_mall_directory_outlined,
                    size: 48.sp,
                    color: const Color(0xFF6366F1),
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  controller.hasFilters
                      ? 'لا توجد نتائج للبحث'
                      : 'لا توجد متاجر متاحة حالياً',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  controller.hasFilters
                      ? 'جرب تعديل معايير البحث'
                      : 'اسحب للأسفل للتحديث',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                ),
                if (controller.hasFilters) ...[
                  SizedBox(height: 16.h),
                  ElevatedButton.icon(
                    onPressed: controller.clearFilters,
                    icon: Icon(Icons.clear_all_rounded, size: 16.sp),
                    label: Text('مسح الفلاتر'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(WholesaleMarketController controller) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75, // زيادة الارتفاع لتجنب الoverflow
          crossAxisSpacing: 16.w,
          mainAxisSpacing: 16.h,
        ),
        itemCount: controller.filteredStores.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: const Duration(milliseconds: 600),
            columnCount: 2,
            child: ScaleAnimation(
              child: FadeInAnimation(
                child: _buildGridStoreCard(
                  controller.filteredStores[index],
                  index,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListView(WholesaleMarketController controller) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: ListView.builder(
        itemCount: controller.filteredStores.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 600),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildListStoreCard(
                  controller.filteredStores[index],
                  index,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGridStoreCard(SellerModel store, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          onTap: () {
            // تأثير اهتزاز متوسط عند الانتقال لمتجر
            HapticFeedback.mediumImpact();
            Get.to(
              () => StoreProductsPage(),
              arguments: {'store': store},
              transition: Transition.rightToLeft,
              duration: const Duration(milliseconds: 300),
            );
          },
          splashColor: const Color(0xFF6366F1).withOpacity(0.1),
          highlightColor: const Color(0xFF6366F1).withOpacity(0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20.r),
                      topRight: Radius.circular(20.r),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20.r),
                      topRight: Radius.circular(20.r),
                    ),
                    child: _buildStoreImage(store),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.all(10.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              store.shopName,
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (store.shopCategory.isNotEmpty) ...[
                              SizedBox(height: 3.h),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6.w,
                                  vertical: 2.h,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF6366F1,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Text(
                                  store.shopCategory,
                                  style: TextStyle(
                                    fontSize: 9.sp,
                                    color: const Color(0xFF6366F1),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            size: 10.sp,
                            color: Colors.green,
                          ),
                          SizedBox(width: 3.w),
                          Flexible(
                            child: Text(
                              'بائع جملة',
                              style: TextStyle(
                                fontSize: 9.sp,
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListStoreCard(SellerModel store, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          onTap: () {
            // تأثير اهتزاز متوسط عند الانتقال لمتجر
            HapticFeedback.mediumImpact();
            Get.to(
              () => StoreProductsPage(),
              arguments: {'store': store},
              transition: Transition.rightToLeft,
              duration: const Duration(milliseconds: 300),
            );
          },
          splashColor: const Color(0xFF6366F1).withOpacity(0.1),
          highlightColor: const Color(0xFF6366F1).withOpacity(0.05),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Container(
                  width: 80.w,
                  height: 80.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.r),
                    child: _buildStoreImage(store),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.shopName,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (store.sellerName.isNotEmpty) ...[
                        SizedBox(height: 4.h),
                        Text(
                          'البائع: ${store.sellerName}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          if (store.shopCategory.isNotEmpty) ...[
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                store.shopCategory,
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: const Color(0xFF6366F1),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Spacer(),
                          ],
                          Row(
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                size: 14.sp,
                                color: Colors.green,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                'بائع جملة',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16.sp,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStoreImage(SellerModel store) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6366F1).withOpacity(0.1),
            const Color(0xFF8B5CF6).withOpacity(0.1),
          ],
        ),
      ),
      child:
          store.shopFrontImageUrl != null && store.shopFrontImageUrl!.isNotEmpty
              ? Image.network(
                store.shopFrontImageUrl!,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => _buildDefaultStoreImage(),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.w,
                      color: const Color(0xFF6366F1),
                    ),
                  );
                },
              )
              : _buildDefaultStoreImage(),
    );
  }

  Widget _buildDefaultStoreImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6366F1).withOpacity(0.1),
            const Color(0xFF8B5CF6).withOpacity(0.1),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.storefront_rounded,
          size: 40.sp,
          color: const Color(0xFF6366F1).withOpacity(0.7),
        ),
      ),
    );
  }
}
