import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../controllers/retail_cart_controller.dart';

class RetailCartPage extends StatelessWidget {
  const RetailCartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0XFFF8FAFC),
      body: SafeArea(
        child: GetBuilder<RetailCartController>(
          builder: (controller) {
            // التحقق من وجود أي متاجر تحتوي على منتجات
            if (controller.totalStoresCount == 0) {
              return _buildEmptyCart(controller);
            }

            return Column(
              children: [
                _buildAppBar(controller),
                // إضافة قائمة المتاجر إذا كان هناك أكثر من متجر
                if (controller.totalStoresCount > 1)
                  _buildStoreSelector(controller),
                _buildStoreInfo(controller),
                Expanded(child: _buildCartItems(controller)),
                _buildBottomSection(controller),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(RetailCartController controller) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                Get.back();
              },
              borderRadius: BorderRadius.circular(12.r),
              splashColor: const Color(0xFF6366F1).withOpacity(0.3),
              highlightColor: const Color(0xFF6366F1).withOpacity(0.1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: const Color(0xFF6366F1),
                  size: 20.sp,
                ),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'سلة التسوق',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    if (controller.totalStoresCount > 1) ...[
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          '${controller.totalStoresCount} متجر',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: const Color(0xFF6366F1),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Obx(
                  () => Text(
                    controller.totalStoresCount > 1
                        ? '${controller.totalItemsCount} منتج في ${controller.totalStoresCount} متاجر'
                        : '${controller.itemCount} منتج',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              if (controller.totalStoresCount > 1)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _showAllStoresDialog(controller);
                    },
                    borderRadius: BorderRadius.circular(8.r),
                    splashColor: const Color(0xFF6366F1).withOpacity(0.3),
                    highlightColor: const Color(0xFF6366F1).withOpacity(0.1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.store_outlined,
                            color: const Color(0xFF6366F1),
                            size: 16.sp,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'جميع المتاجر',
                            style: TextStyle(
                              color: const Color(0xFF6366F1),
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (controller.totalStoresCount > 1) SizedBox(width: 8.w),
              if (controller.cartItems.isNotEmpty)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      _showClearCartDialog(controller);
                    },
                    borderRadius: BorderRadius.circular(8.r),
                    splashColor: Colors.red.withOpacity(0.3),
                    highlightColor: Colors.red.withOpacity(0.1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        controller.totalStoresCount > 1
                            ? 'مسح المتجر'
                            : 'مسح الكل',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
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

  /// بناء قائمة اختيار المتجر النشط
  Widget _buildStoreSelector(RetailCartController controller) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'اختر المتجر:',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: 8.h),
          SizedBox(
            height: 40.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: controller.storesWithItems.length,
              itemBuilder: (context, index) {
                final store = controller.storesWithItems[index];
                final isActive = controller.activeStoreId.value == store.uid;
                final itemCount = controller.getStoreItemCount(store.uid);
                final totalAmount = controller.getStoreTotalAmount(store.uid);
                final formatter = NumberFormat('#,###', 'ar');

                return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          controller.setActiveStore(store.uid);
                        },
                        borderRadius: BorderRadius.circular(8.r),
                        splashColor:
                            isActive
                                ? Colors.white.withOpacity(0.3)
                                : const Color(0xFF6366F1).withOpacity(0.2),
                        highlightColor:
                            isActive
                                ? Colors.white.withOpacity(0.1)
                                : const Color(0xFF6366F1).withOpacity(0.1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: EdgeInsets.only(left: 8.w),
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            gradient:
                                isActive
                                    ? LinearGradient(
                                      colors: [
                                        const Color(0xFF6366F1),
                                        const Color(0xFF8B5CF6),
                                      ],
                                    )
                                    : null,
                            color: isActive ? null : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color:
                                  isActive
                                      ? const Color(0xFF6366F1)
                                      : const Color(0xFFE5E7EB),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                store.shopName.length > 10
                                    ? '${store.shopName.substring(0, 10)}...'
                                    : store.shopName,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isActive
                                          ? Colors.white
                                          : const Color(0xFF1F2937),
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                '$itemCount منتج - ${formatter.format(totalAmount.toInt())} د.ع',
                                style: TextStyle(
                                  fontSize: 9.sp,
                                  color:
                                      isActive
                                          ? Colors.white.withOpacity(0.8)
                                          : const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .animate(delay: (index * 100).ms)
                    .fadeIn()
                    .slideX(begin: 0.3, end: 0);
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0);
  }

  /// عرض حوار جميع المتاجر
  void _showAllStoresDialog(RetailCartController controller) {
    final formatter = NumberFormat('#,###', 'ar');

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(
              Icons.store_rounded,
              color: const Color(0xFF6366F1),
              size: 24.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              'جميع المتاجر في السلة',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: controller.storesWithItems.length,
            itemBuilder: (context, index) {
              final store = controller.storesWithItems[index];
              final itemCount = controller.getStoreItemCount(store.uid);
              final totalAmount = controller.getStoreTotalAmount(store.uid);
              final isActive = controller.activeStoreId.value == store.uid;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    controller.setActiveStore(store.uid);
                    Get.back();
                  },
                  borderRadius: BorderRadius.circular(8.r),
                  splashColor:
                      isActive
                          ? const Color(0xFF6366F1).withOpacity(0.2)
                          : const Color(0xFF6366F1).withOpacity(0.1),
                  highlightColor: const Color(0xFF6366F1).withOpacity(0.05),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(bottom: 8.h),
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color:
                          isActive
                              ? const Color(0xFF6366F1).withOpacity(0.1)
                              : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color:
                            isActive
                                ? const Color(0xFF6366F1)
                                : const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40.w,
                          height: 40.w,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: const Color(0xFF6366F1).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(7.r),
                            child:
                                store.shopFrontImageUrl != null
                                    ? CachedNetworkImage(
                                      imageUrl: store.shopFrontImageUrl!,
                                      fit: BoxFit.cover,
                                      errorWidget:
                                          (context, url, error) => Container(
                                            color: const Color(
                                              0xFF6366F1,
                                            ).withOpacity(0.1),
                                            child: Icon(
                                              Icons.store_rounded,
                                              color: const Color(0xFF6366F1),
                                              size: 20.sp,
                                            ),
                                          ),
                                    )
                                    : Container(
                                      color: const Color(
                                        0xFF6366F1,
                                      ).withOpacity(0.1),
                                      child: Icon(
                                        Icons.store_rounded,
                                        color: const Color(0xFF6366F1),
                                        size: 20.sp,
                                      ),
                                    ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                store.shopName,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1F2937),
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                '$itemCount منتج',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${formatter.format(totalAmount.toInt())} د.ع',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                            if (isActive)
                              Container(
                                margin: EdgeInsets.only(top: 4.h),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6.w,
                                  vertical: 2.h,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1),
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                child: Text(
                                  'نشط',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(width: 8.w),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'clear') {
                              HapticFeedback.mediumImpact();
                              Get.back();
                              _showClearStoreDialog(controller, store);
                            }
                          },
                          itemBuilder:
                              (context) => [
                                PopupMenuItem(
                                  value: 'clear',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                        size: 16.sp,
                                      ),
                                      SizedBox(width: 8.w),
                                      Text(
                                        'مسح سلة المتجر',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                          child: Icon(
                            Icons.more_vert,
                            color: const Color(0xFF6B7280),
                            size: 20.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'إغلاق',
              style: TextStyle(fontSize: 14.sp, color: const Color(0xFF6B7280)),
            ),
          ),
          if (controller.totalStoresCount > 1)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Get.back();
                  _showClearAllStoresDialog(controller);
                },
                borderRadius: BorderRadius.circular(8.r),
                splashColor: Colors.red.withOpacity(0.3),
                highlightColor: Colors.red.withOpacity(0.1),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'مسح الكل',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart(RetailCartController controller) {
    return Column(
      children: [
        _buildAppBar(controller),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                      width: 120.w,
                      height: 120.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(60.r),
                      ),
                      child: Icon(
                        Icons.shopping_cart_outlined,
                        size: 60.sp,
                        color: const Color(0xFF6366F1),
                      ),
                    )
                    .animate()
                    .scale(duration: 600.ms, curve: Curves.elasticOut)
                    .fadeIn(duration: 400.ms),
                SizedBox(height: 24.h),
                Text(
                  'السلة فارغة',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                SizedBox(height: 8.h),
                Text(
                  'أضف بعض المنتجات لتبدأ التسوق',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: const Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
                SizedBox(height: 32.h),
                Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF6366F1),
                            const Color(0xFF8B5CF6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(25.r),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.3),
                            blurRadius: 10.r,
                            offset: Offset(0, 4.h),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            Get.back();
                          },
                          borderRadius: BorderRadius.circular(25.r),
                          splashColor: Colors.white.withOpacity(0.3),
                          highlightColor: Colors.white.withOpacity(0.1),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 32.w,
                              vertical: 16.h,
                            ),
                            child: Text(
                              'تصفح المنتجات',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 400.ms)
                    .slideY(begin: 0.2, end: 0),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStoreInfo(RetailCartController controller) {
    if (controller.currentStore == null) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6366F1).withOpacity(0.1),
            const Color(0xFF8B5CF6).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: const Color(0xFF6366F1).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child:
                  controller.currentStore!.shopFrontImageUrl != null
                      ? CachedNetworkImage(
                        imageUrl: controller.currentStore!.shopFrontImageUrl!,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => Container(
                              color: const Color(0xFF6366F1).withOpacity(0.1),
                              child: Icon(
                                Icons.store_rounded,
                                color: const Color(0xFF6366F1),
                                size: 25.sp,
                              ),
                            ),
                        errorWidget:
                            (context, url, error) => Container(
                              color: const Color(0xFF6366F1).withOpacity(0.1),
                              child: Icon(
                                Icons.store_rounded,
                                color: const Color(0xFF6366F1),
                                size: 25.sp,
                              ),
                            ),
                      )
                      : Container(
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        child: Icon(
                          Icons.store_rounded,
                          color: const Color(0xFF6366F1),
                          size: 25.sp,
                        ),
                      ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.currentStore!.shopName,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(
                      Icons.store_outlined,
                      size: 14.sp,
                      color: const Color(0xFF6366F1),
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        controller.currentStore!.shopCategories.join(', '),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              'متاح',
              style: TextStyle(
                fontSize: 10.sp,
                color: const Color(0xFF10B981),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2, end: 0);
  }

  Widget _buildCartItems(RetailCartController controller) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: controller.cartItems.length,
      itemBuilder: (context, index) {
        final item = controller.cartItems[index];
        return _buildCartItem(item, controller, index);
      },
    );
  }

  Widget _buildCartItem(
    CartItem item,
    RetailCartController controller,
    int index,
  ) {
    return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                spreadRadius: 0,
                blurRadius: 15.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                // صورة المنتج مع تحسينات
                _buildProductImage(item),
                SizedBox(width: 16.w),

                // معلومات المنتج
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // اسم المنتج
                      Text(
                        item.productName,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8.h),

                      // السعر الفردي مع تصميم مميز
                      _buildPriceDisplay(item.productPrice),
                      SizedBox(height: 6.h),

                      // عرض الكمية المتوفرة والكمية المطلوبة
                      _buildQuantityInfo(item),
                      SizedBox(height: 8.h),

                      // معلومات الكارتونة وزر سريع (للمنتجات من بائع جملة)
                      _buildCartonInfo(item, controller),
                      SizedBox(height: 12.h),

                      // التحكم في الكمية والسعر الإجمالي - مُحسن لتجنب overflow
                      Column(
                        children: [
                          Row(
                            children: [
                              _buildQuantityControls(item, controller),
                              const Spacer(),
                              _buildDeleteButton(item, controller),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [_buildTotalPrice(item)],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
        .animate(delay: (index * 100).ms)
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.2, end: 0);
  }

  Widget _buildProductImage(CartItem item) {
    return Container(
      width: 90.w,
      height: 90.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11.r),
        child: Stack(
          children: [
            // الصورة الرئيسية مع تحسينات
            if (item.productImage.isNotEmpty)
              CachedNetworkImage(
                imageUrl: item.productImage,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                placeholder:
                    (context, url) => Container(
                      color: const Color(0xFFF8FAFC),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: const Color(0xFF6366F1),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'جاري التحميل...',
                            style: TextStyle(
                              fontSize: 8.sp,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                errorWidget: (context, url, error) {
                  debugPrint('خطأ في تحميل الصورة: $url, Error: $error');
                  return _buildImagePlaceholder();
                },
              )
            else
              _buildImagePlaceholder(),

            // تأثير التدرج
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 30.h,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.1)],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_rounded,
            color: const Color(0xFF9CA3AF),
            size: 28.sp,
          ),
          SizedBox(height: 4.h),
          Text(
            'خطأ في التحميل',
            style: TextStyle(fontSize: 8.sp, color: const Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityInfo(CartItem item) {
    // استخراج الكمية الإجمالية من بيانات المنتج
    final int originalQuantity = (item.productData['quantity'] as int?) ?? 0;
    final int availableQuantity = originalQuantity - item.quantity;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color:
            availableQuantity <= 0
                ? Colors.red.withOpacity(0.1)
                : availableQuantity <= 5
                ? Colors.orange.withOpacity(0.1)
                : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(
          color:
              availableQuantity <= 0
                  ? Colors.red.withOpacity(0.3)
                  : availableQuantity <= 5
                  ? Colors.orange.withOpacity(0.3)
                  : Colors.green.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            availableQuantity <= 0
                ? Icons.inventory_2_outlined
                : Icons.inventory_2,
            size: 14.sp,
            color:
                availableQuantity <= 0
                    ? Colors.red
                    : availableQuantity <= 5
                    ? Colors.orange
                    : Colors.green,
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Text(
              'متوفر: $availableQuantity قطعة | في السلة: ${item.quantity}',
              style: TextStyle(
                fontSize: 11.sp,
                color:
                    availableQuantity <= 0
                        ? Colors.red
                        : availableQuantity <= 5
                        ? Colors.orange
                        : Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (availableQuantity <= 0)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                'نفدت',
                style: TextStyle(
                  fontSize: 8.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else if (availableQuantity <= 5)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                'قليلة',
                style: TextStyle(
                  fontSize: 8.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCartonInfo(CartItem item, RetailCartController controller) {
    // التحقق من وجود معلومات الكارتونة
    final productData = item.productData;
    if (productData['addedBySellerType'] != 'wholesale' ||
        productData['quantityPerCarton'] == null ||
        productData['quantityPerCarton'] <= 0) {
      return const SizedBox.shrink();
    }

    final cartonQuantity = productData['quantityPerCarton'] as int;
    final int originalQuantity = (productData['quantity'] as int?) ?? 0;
    final int availableQuantity = originalQuantity - item.quantity;

    // التحقق من توفر كمية كافية للكارتونة
    final bool canAddCarton = availableQuantity >= cartonQuantity;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color:
            canAddCarton
                ? const Color(0xFF059669).withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(
          color:
              canAddCarton
                  ? const Color(0xFF059669).withOpacity(0.2)
                  : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.inventory_2,
            size: 12.sp,
            color: canAddCarton ? const Color(0xFF059669) : Colors.grey,
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'كارتونة: $cartonQuantity قطعة',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: canAddCarton ? const Color(0xFF059669) : Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!canAddCarton)
                  Text(
                    'يتطلب $cartonQuantity قطعة (متوفر: $availableQuantity)',
                    style: TextStyle(
                      fontSize: 8.sp,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          // إظهار زر الإضافة فقط إذا كانت الكمية كافية
          if (canAddCarton)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  // إضافة كارتونة كاملة
                  controller.updateQuantity(
                    item.productId,
                    item.quantity + cartonQuantity,
                  );
                },
                borderRadius: BorderRadius.circular(4.r),
                splashColor: const Color(0xFF059669).withOpacity(0.3),
                highlightColor: const Color(0xFF059669).withOpacity(0.1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    'أضف',
                    style: TextStyle(
                      fontSize: 8.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            )
          else
            // إظهار رسالة عدم توفر كمية كافية
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                'غير متاح',
                style: TextStyle(
                  fontSize: 8.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPriceDisplay(double price) {
    final formatter = NumberFormat('#,###', 'ar');
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withOpacity(0.1),
            const Color(0xFF8B5CF6).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.monetization_on_rounded,
            size: 14.sp,
            color: const Color(0xFF6366F1),
          ),
          SizedBox(width: 4.w),
          Text(
            '${formatter.format(price.toInt())} د.ع',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF6366F1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityControls(
    CartItem item,
    RetailCartController controller,
  ) {
    // حساب الكمية المتوفرة
    final int originalQuantity = (item.productData['quantity'] as int?) ?? 0;
    final int availableQuantity = originalQuantity - item.quantity;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildQuantityButton(
            icon: Icons.remove,
            onPressed: () {
              HapticFeedback.lightImpact();
              controller.updateQuantity(item.productId, item.quantity - 1);
            },
            isEnabled: item.quantity > 1,
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            child: Text(
              '${item.quantity}',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
          ),
          _buildQuantityButton(
            icon: Icons.add,
            onPressed: () {
              if (availableQuantity > 0) {
                HapticFeedback.lightImpact();
                controller.updateQuantity(item.productId, item.quantity + 1);
              }
            },
            isEnabled: availableQuantity > 0,
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isEnabled,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:
            isEnabled
                ? () {
                  HapticFeedback.lightImpact();
                  onPressed();
                }
                : null,
        borderRadius: BorderRadius.circular(8.r),
        splashColor:
            isEnabled
                ? const Color(0xFF6366F1).withOpacity(0.3)
                : Colors.transparent,
        highlightColor:
            isEnabled
                ? const Color(0xFF6366F1).withOpacity(0.1)
                : Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 32.w,
          height: 32.w,
          decoration: BoxDecoration(
            color:
                isEnabled ? const Color(0xFF6366F1) : const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            icon,
            size: 18.sp,
            color: isEnabled ? Colors.white : const Color(0xFF9CA3AF),
          ),
        ),
      ),
    );
  }

  Widget _buildTotalPrice(CartItem item) {
    final formatter = NumberFormat('#,###', 'ar');
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF10B981), const Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Text(
        '${formatter.format(item.totalPrice.toInt())} د.ع',
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildDeleteButton(CartItem item, RetailCartController controller) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          _showDeleteConfirmation(item, controller);
        },
        borderRadius: BorderRadius.circular(8.r),
        splashColor: Colors.red.withOpacity(0.3),
        highlightColor: Colors.red.withOpacity(0.1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 32.w,
          height: 32.w,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.red.withOpacity(0.2), width: 1),
          ),
          child: Icon(
            Icons.delete_outline_rounded,
            color: Colors.red,
            size: 16.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection(RetailCartController controller) {
    final formatter = NumberFormat('#,###', 'ar');

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 20.r,
            offset: Offset(0, -5.h),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // تفاصيل الحساب المُحسنة - مُقلصة الحجم
            _buildCompactPriceBreakdown(controller, formatter),

            SizedBox(height: 16.h),

            // زر إتمام الشراء
            _buildCheckoutButton(controller),
          ],
        ),
      ),
    ).animate().slideY(
      begin: 1,
      end: 0,
      duration: 500.ms,
      curve: Curves.easeOutBack,
    );
  }

  Widget _buildCompactPriceBreakdown(
    RetailCartController controller,
    NumberFormat formatter,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6366F1).withOpacity(0.05),
            const Color(0xFF8B5CF6).withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'المجموع الكلي',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
              Obx(
                () => Text(
                  '${controller.itemCount} منتج',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
          Obx(
            () => Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF10B981), const Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                    '${formatter.format(controller.totalAmount.value.toInt())} د.ع',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                  .animate(key: ValueKey(controller.totalAmount.value))
                  .scale(duration: 300.ms, curve: Curves.elasticOut)
                  .then()
                  .shimmer(
                    duration: 500.ms,
                    color: Colors.white.withOpacity(0.3),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutButton(RetailCartController controller) {
    return Container(
          width: double.infinity,
          height: 50.h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                const Color(0xFF6366F1),
                const Color(0xFF8B5CF6),
                const Color(0xFF6366F1),
              ],
            ),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.4),
                blurRadius: 15.r,
                offset: Offset(0, 8.h),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (controller.cartItems.isNotEmpty) {
                  HapticFeedback.mediumImpact();
                  Get.toNamed('/location-picker');
                }
              },
              borderRadius: BorderRadius.circular(16.r),
              splashColor: Colors.white.withOpacity(0.3),
              highlightColor: Colors.white.withOpacity(0.1),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'إتمام عملية الشراء',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate()
        .scale(duration: 200.ms, curve: Curves.easeOut)
        .then()
        .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.2));
  }

  void _showClearCartDialog(RetailCartController controller) {
    final isMultipleStores = controller.totalStoresCount > 1;
    final currentStoreName = controller.currentStore?.shopName ?? 'المتجر';

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 24.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              isMultipleStores ? 'مسح سلة المتجر' : 'مسح السلة',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
          ],
        ),
        content: Text(
          isMultipleStores
              ? 'هل أنت متأكد من مسح جميع العناصر من سلة "$currentStoreName"؟'
              : 'هل أنت متأكد من مسح جميع العناصر من السلة؟',
          style: TextStyle(fontSize: 14.sp, color: const Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              Get.back();
            },
            child: Text(
              'إلغاء',
              style: TextStyle(fontSize: 14.sp, color: const Color(0xFF6B7280)),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                controller.clearCart();
                Get.back();
              },
              borderRadius: BorderRadius.circular(8.r),
              splashColor: Colors.red.withOpacity(0.3),
              highlightColor: Colors.red.withOpacity(0.1),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  'مسح',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// حوار مسح سلة متجر معين
  void _showClearStoreDialog(RetailCartController controller, store) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24.sp),
            SizedBox(width: 8.w),
            Text(
              'مسح سلة المتجر',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
          ],
        ),
        content: Text(
          'هل أنت متأكد من مسح جميع العناصر من سلة "${store.shopName}"؟',
          style: TextStyle(fontSize: 14.sp, color: const Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              Get.back();
            },
            child: Text(
              'إلغاء',
              style: TextStyle(fontSize: 14.sp, color: const Color(0xFF6B7280)),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                controller.clearStoreCart(store.uid);
                Get.back();
              },
              borderRadius: BorderRadius.circular(8.r),
              splashColor: Colors.red.withOpacity(0.3),
              highlightColor: Colors.red.withOpacity(0.1),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  'مسح',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// حوار مسح جميع السلال
  void _showClearAllStoresDialog(RetailCartController controller) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24.sp),
            SizedBox(width: 8.w),
            Text(
              'مسح جميع السلال',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
          ],
        ),
        content: Text(
          'هل أنت متأكد من مسح جميع العناصر من كل المتاجر؟ لا يمكن التراجع عن هذا الإجراء.',
          style: TextStyle(fontSize: 14.sp, color: const Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              Get.back();
            },
            child: Text(
              'إلغاء',
              style: TextStyle(fontSize: 14.sp, color: const Color(0xFF6B7280)),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                controller.clearAllCarts();
                Get.back();
              },
              borderRadius: BorderRadius.circular(8.r),
              splashColor: Colors.red.withOpacity(0.3),
              highlightColor: Colors.red.withOpacity(0.1),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  'مسح الكل',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(CartItem item, RetailCartController controller) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'حذف المنتج',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
          ),
        ),
        content: Text(
          'هل تريد حذف "${item.productName}" من السلة؟',
          style: TextStyle(fontSize: 14.sp, color: const Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              Get.back();
            },
            child: Text(
              'إلغاء',
              style: TextStyle(fontSize: 14.sp, color: const Color(0xFF6B7280)),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                controller.removeFromCart(item.productId);
                Get.back();
              },
              borderRadius: BorderRadius.circular(8.r),
              splashColor: Colors.red.withOpacity(0.3),
              highlightColor: Colors.red.withOpacity(0.1),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  'حذف',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
