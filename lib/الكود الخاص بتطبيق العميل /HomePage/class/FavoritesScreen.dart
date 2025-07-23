import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';

// استيراد شاشة تفاصيل المنتج
import '../../../Model/model_item.dart';
import '../../../XXX/xxx_firebase.dart';
import 'DetailsOfItemScreen.dart';
// (اختياري) استيراد زر الإضافة/الإزالة إذا أردت عرضه هنا
import 'FavoriteController.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // حقن أو إيجاد متحكم المفضلة
    final FavoriteController favoriteCtrl = Get.put(FavoriteController());
    final theme = Theme.of(context);

    // متحكمات للتفاعل
    final RxBool isGridView = false.obs;
    final RxString searchQuery = ''.obs;
    final RxString sortBy = 'recent'.obs; // recent, name, price
    final RxBool isAscending = true.obs;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // AppBar متقدم مع تأثيرات بصرية
          SliverAppBar(
            expandedHeight: 200.h,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: theme.primaryColor,
            foregroundColor: Colors.white,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            flexibleSpace: FlexibleSpaceBar(
              title: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      offset: const Offset(0, 1),
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: const Text('قائمة المفضلة'),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.primaryColor,
                      theme.primaryColor.withValues(alpha: 0.8),
                      theme.primaryColor.withValues(alpha: 0.6),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // تأثير الدوائر المتحركة في الخلفية
                    Positioned(
                      top: -50.h,
                      right: -50.w,
                      child: AnimatedContainer(
                        duration: const Duration(seconds: 3),
                        width: 150.w,
                        height: 150.h,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -30.h,
                      left: -30.w,
                      child: AnimatedContainer(
                        duration: const Duration(seconds: 4),
                        width: 100.w,
                        height: 100.h,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    // الأيقونة المركزية
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 30.h),
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 1000),
                            tween: Tween(begin: 0.0, end: 1.0),
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: 0.5 + (0.5 * value),
                                child: Icon(
                                  Icons.favorite_rounded,
                                  size: 60.sp,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 10.h),
                          Text(
                            'منتجاتك المفضلة',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              // زر مسح جميع المفضلة
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: favoriteCtrl.getFavoritesStream(),
                builder: (context, snapshot) {
                  final hasItems = (snapshot.data?.docs.length ?? 0) > 0;
                  if (!hasItems) return const SizedBox.shrink();

                  return IconButton(
                    icon: Icon(
                      Icons.clear_all_rounded,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    onPressed: () => _showClearAllDialog(context, favoriteCtrl),
                    tooltip: 'مسح جميع المفضلة',
                  );
                },
              ),
              // زر تبديل العرض (شبكة/قائمة)
              Obx(
                () => IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      isGridView.value
                          ? Icons.view_list_rounded
                          : Icons.grid_view_rounded,
                      key: ValueKey(isGridView.value),
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () => isGridView.toggle(),
                  tooltip: isGridView.value ? 'عرض القائمة' : 'عرض الشبكة',
                ),
              ),
              SizedBox(width: 8.w),
            ],
          ),

          // شريط البحث والفلاتر
          SliverToBoxAdapter(
            child: Container(
              margin: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  // حقل البحث المتقدم
                  Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(15.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10.r,
                          offset: Offset(0, 2.h),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: (value) => searchQuery.value = value,
                      decoration: InputDecoration(
                        hintText: 'ابحث في المفضلة...',
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: theme.primaryColor,
                          size: 24.sp,
                        ),
                        suffixIcon: Obx(
                          () =>
                              searchQuery.value.isNotEmpty
                                  ? IconButton(
                                    icon: Icon(
                                      Icons.clear_rounded,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () => searchQuery.value = '',
                                  )
                                  : const SizedBox.shrink(),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 16.h,
                        ),
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 12.h),

                  // شريط الفلاتر والترتيب
                  Row(
                    children: [
                      // زر الترتيب
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: theme.primaryColor.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Obx(
                            () => DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: sortBy.value,
                                isExpanded: true,
                                icon: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: theme.primaryColor,
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 12.w),
                                items: [
                                  DropdownMenuItem(
                                    value: 'recent',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 16.sp,
                                        ),
                                        SizedBox(width: 8.w),
                                        Text('الأحدث أولاً'),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'name',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.sort_by_alpha_rounded,
                                          size: 16.sp,
                                        ),
                                        SizedBox(width: 8.w),
                                        Text('حسب الاسم'),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'price',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.attach_money_rounded,
                                          size: 16.sp,
                                        ),
                                        SizedBox(width: 8.w),
                                        Text('حسب السعر'),
                                      ],
                                    ),
                                  ),
                                ],
                                onChanged: (value) => sortBy.value = value!,
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: 8.w),

                      // زر تبديل الترتيب (تصاعدي/تنازلي)
                      Obx(
                        () => Container(
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: theme.primaryColor.withValues(alpha: 0.2),
                            ),
                          ),
                          child: IconButton(
                            icon: AnimatedRotation(
                              turns: isAscending.value ? 0 : 0.5,
                              duration: const Duration(milliseconds: 300),
                              child: Icon(
                                Icons.sort_rounded,
                                color: theme.primaryColor,
                              ),
                            ),
                            onPressed: () => isAscending.toggle(),
                            tooltip: isAscending.value ? 'تصاعدي' : 'تنازلي',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // المحتوى الرئيسي
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: favoriteCtrl.getFavoritesStream(),
            builder: (context, favSnapshot) {
              if (favSnapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingSlivers(context, isGridView);
              }

              if (favSnapshot.hasError) {
                return _buildErrorSliver(
                  context,
                  'حدث خطأ أثناء تحميل المفضلة',
                );
              }

              final favoriteProductIds =
                  favSnapshot.data?.docs.map((doc) => doc.id).toList() ?? [];

              if (favoriteProductIds.isEmpty) {
                return _buildEmptySliver(context);
              }

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream:
                    FirebaseFirestore.instance
                        .collection(FirebaseX.itemsCollection)
                        .where(
                          FieldPath.documentId,
                          whereIn: favoriteProductIds,
                        )
                        .snapshots(),
                builder: (context, productSnapshot) {
                  if (productSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return _buildLoadingSlivers(context, isGridView);
                  }

                  if (productSnapshot.hasError) {
                    return _buildErrorSliver(
                      context,
                      'خطأ في تحميل تفاصيل المنتجات',
                    );
                  }

                  var productDocs = productSnapshot.data?.docs ?? [];

                  if (productDocs.isEmpty) {
                    return _buildEmptySliver(context);
                  }

                  // تطبيق البحث والترتيب
                  return Obx(() {
                    var filteredDocs = productDocs;

                    // تطبيق البحث
                    if (searchQuery.value.isNotEmpty) {
                      filteredDocs =
                          productDocs.where((doc) {
                            try {
                              final item = ItemModel.fromMap(
                                doc.data(),
                                doc.id,
                              );
                              return item.name.toLowerCase().contains(
                                searchQuery.value.toLowerCase(),
                              );
                            } catch (e) {
                              return false;
                            }
                          }).toList();
                    }

                    // تطبيق الترتيب
                    filteredDocs.sort((a, b) {
                      try {
                        final itemA = ItemModel.fromMap(a.data(), a.id);
                        final itemB = ItemModel.fromMap(b.data(), b.id);

                        int comparison = 0;
                        switch (sortBy.value) {
                          case 'name':
                            comparison = itemA.name.compareTo(itemB.name);
                            break;
                          case 'price':
                            comparison = itemA.price.compareTo(itemB.price);
                            break;
                          case 'recent':
                          default:
                            // افتراضياً حسب تاريخ الإضافة (يحتاج تخزين timestamp)
                            comparison = 0;
                            break;
                        }

                        return isAscending.value ? comparison : -comparison;
                      } catch (e) {
                        return 0;
                      }
                    });

                    if (filteredDocs.isEmpty) {
                      return _buildNoResultsSliver(context);
                    }

                    // عرض النتائج مع إحصائيات
                    return SliverMainAxisGroup(
                      slivers: [
                        // إحصائيات المفضلة
                        SliverToBoxAdapter(
                          child: _buildFavoritesStats(
                            context,
                            filteredDocs.length,
                            productDocs.length,
                          ),
                        ),
                        // النتائج
                        isGridView.value
                            ? _buildGridView(
                              context,
                              filteredDocs,
                              favoriteCtrl,
                              theme,
                            )
                            : _buildListView(
                              context,
                              filteredDocs,
                              favoriteCtrl,
                              theme,
                            ),
                      ],
                    );
                  });
                },
              );
            },
          ),

          // مساحة إضافية في النهاية
          SliverToBoxAdapter(child: SizedBox(height: 20.h)),
        ],
      ),
    );
  }

  // بناء Slivers للتحميل
  Widget _buildLoadingSlivers(BuildContext context, RxBool isGridView) {
    return Obx(
      () =>
          isGridView.value
              ? _buildLoadingGrid(context)
              : _buildLoadingList(context),
    );
  }

  // بناء شبكة التحميل
  Widget _buildLoadingGrid(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.all(16.w),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 12.h,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildShimmerCard(context, isGrid: true),
          childCount: 6,
        ),
      ),
    );
  }

  // بناء قائمة التحميل
  Widget _buildLoadingList(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.all(16.w),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildShimmerCard(context, isGrid: false),
          childCount: 5,
        ),
      ),
    );
  }

  // كارد الشيمر
  Widget _buildShimmerCard(BuildContext context, {required bool isGrid}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.r),
        ),
        child:
            isGrid
                ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(15.r),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: EdgeInsets.all(12.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(height: 16.h, color: Colors.white),
                            SizedBox(height: 8.h),
                            Container(
                              height: 12.h,
                              width: 80.w,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
                : SizedBox(
                  height: 100.h,
                  child: Row(
                    children: [
                      Container(
                        width: 100.w,
                        height: 100.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.horizontal(
                            right: Radius.circular(15.r),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(12.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(height: 16.h, color: Colors.white),
                              SizedBox(height: 8.h),
                              Container(
                                height: 12.h,
                                width: 60.w,
                                color: Colors.white,
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

  // بناء Sliver للخطأ
  Widget _buildErrorSliver(BuildContext context, String message) {
    final theme = Theme.of(context);
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 80.sp,
              color: Colors.red[300],
            ),
            SizedBox(height: 20.h),
            Text(
              message,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.red[700],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),
            ElevatedButton.icon(
              onPressed: () => Get.back(),
              icon: Icon(Icons.refresh_rounded),
              label: Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // بناء Sliver للحالة الفارغة
  Widget _buildEmptySliver(BuildContext context) {
    final theme = Theme.of(context);
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1500),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.5 + (0.5 * value),
                  child: Icon(
                    Icons.favorite_border_rounded,
                    size: 120.sp,
                    color: Colors.grey[400],
                  ),
                );
              },
            ),
            SizedBox(height: 24.h),
            Text(
              'قائمة المفضلة فارغة',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: Text(
                'ابدأ بإضافة المنتجات التي تعجبك إلى قائمة المفضلة',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.grey[500],
                  height: 1.5,
                ),
              ),
            ),
            SizedBox(height: 32.h),
            ElevatedButton.icon(
              onPressed: () => Get.back(),
              icon: Icon(Icons.shopping_bag_outlined),
              label: Text('تصفح المنتجات'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.r),
                ),
                elevation: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // بناء Sliver لعدم وجود نتائج
  Widget _buildNoResultsSliver(BuildContext context) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 80.sp,
              color: Colors.grey[400],
            ),
            SizedBox(height: 20.h),
            Text(
              'لا توجد نتائج',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'لم نجد أي منتجات تطابق بحثك',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  // بناء عرض الشبكة
  Widget _buildGridView(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    FavoriteController favoriteCtrl,
    ThemeData theme,
  ) {
    return SliverPadding(
      padding: EdgeInsets.all(16.w),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 12.h,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          try {
            final item = ItemModel.fromMap(docs[index].data(), docs[index].id);
            return _buildGridItem(context, item, favoriteCtrl, theme);
          } catch (e) {
            return _buildErrorCard(context);
          }
        }, childCount: docs.length),
      ),
    );
  }

  // بناء عرض القائمة
  Widget _buildListView(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    FavoriteController favoriteCtrl,
    ThemeData theme,
  ) {
    return SliverPadding(
      padding: EdgeInsets.all(16.w),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          try {
            final item = ItemModel.fromMap(docs[index].data(), docs[index].id);
            return _buildListItem(context, item, favoriteCtrl, theme);
          } catch (e) {
            return _buildErrorCard(context);
          }
        }, childCount: docs.length),
      ),
    );
  }

  // بناء عنصر الشبكة
  Widget _buildGridItem(
    BuildContext context,
    ItemModel item,
    FavoriteController favoriteCtrl,
    ThemeData theme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          onTap: () => Get.to(() => DetailsOfItemScreen(item: item)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الصورة
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20.r),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: item.imageUrl ?? '',
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        placeholder:
                            (c, u) => Container(
                              color: Colors.grey[200],
                              child: Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  color: Colors.grey[400],
                                  size: 40.sp,
                                ),
                              ),
                            ),
                        errorWidget:
                            (c, u, e) => Container(
                              color: Colors.grey[100],
                              child: Center(
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: Colors.grey[400],
                                  size: 40.sp,
                                ),
                              ),
                            ),
                      ),
                    ),
                    // زر المفضلة في الزاوية
                    Positioned(
                      top: 8.h,
                      left: 8.w,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8.r,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.favorite_rounded,
                            color: Colors.red[400],
                            size: 20.sp,
                          ),
                          onPressed:
                              () => favoriteCtrl.toggleFavorite(item.id, true),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(
                            minWidth: 32.w,
                            minHeight: 32.h,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // المحتوى
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.titleMedium?.color,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_formatPrice(item.suggestedRetailPrice ?? item.price)} ريال',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16.sp,
                            color: Colors.grey[400],
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

  // بناء عنصر القائمة
  Widget _buildListItem(
    BuildContext context,
    ItemModel item,
    FavoriteController favoriteCtrl,
    ThemeData theme,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          onTap: () => Get.to(() => DetailsOfItemScreen(item: item)),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                // الصورة
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: CachedNetworkImage(
                    imageUrl: item.imageUrl ?? '',
                    width: 80.w,
                    height: 80.h,
                    fit: BoxFit.cover,
                    placeholder:
                        (c, u) => Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: Icon(
                              Icons.image_outlined,
                              color: Colors.grey[400],
                              size: 30.sp,
                            ),
                          ),
                        ),
                    errorWidget:
                        (c, u, e) => Container(
                          color: Colors.grey[100],
                          child: Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: Colors.grey[400],
                              size: 30.sp,
                            ),
                          ),
                        ),
                  ),
                ),
                SizedBox(width: 16.w),
                // المحتوى
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.titleMedium?.color,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        '${_formatPrice(item.price)} ريال',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                // زر المفضلة والسهم
                Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.favorite_rounded,
                          color: Colors.red[400],
                          size: 24.sp,
                        ),
                        onPressed:
                            () => favoriteCtrl.toggleFavorite(item.id, true),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16.sp,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // بناء كارد الخطأ
  Widget _buildErrorCard(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[400]),
          SizedBox(width: 12.w),
          Text(
            'خطأ في عرض هذا المنتج',
            style: TextStyle(color: Colors.red[700]),
          ),
        ],
      ),
    );
  }

  // مشاركة قائمة المفضلة
  void _shareFavorites(
    BuildContext context,
    FavoriteController favoriteCtrl,
  ) async {
    try {
      // عرض مؤشر التحميل
      Get.dialog(
        Center(
          child: Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10.r,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16.h),
                Text(
                  'جاري تجهيز قائمة المفضلة...',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // الحصول على المفضلة
      final favoritesSnapshot = await favoriteCtrl.getFavoritesStream().first;
      final favoriteIds = favoritesSnapshot.docs.map((doc) => doc.id).toList();

      if (favoriteIds.isEmpty) {
        Get.back();
        Get.snackbar(
          'تنبيه',
          'قائمة المفضلة فارغة',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange[600],
          colorText: Colors.white,
        );
        return;
      }

      // الحصول على تفاصيل المنتجات
      final productsSnapshot =
          await FirebaseFirestore.instance
              .collection(FirebaseX.itemsCollection)
              .where(FieldPath.documentId, whereIn: favoriteIds)
              .get();

      // تجهيز النص للمشاركة
      final StringBuffer shareText = StringBuffer();
      shareText.writeln('🛍️ قائمة منتجاتي المفضلة');
      shareText.writeln('═══════════════════════════════');
      shareText.writeln('');
      shareText.writeln(
        '📊 إجمالي المنتجات: ${productsSnapshot.docs.length} منتج',
      );
      shareText.writeln(
        '📅 تاريخ المشاركة: ${DateTime.now().toString().split(' ')[0]}',
      );
      shareText.writeln('');
      shareText.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      shareText.writeln('');

      int counter = 1;
      double totalPrice = 0;

      for (var doc in productsSnapshot.docs) {
        try {
          final item = ItemModel.fromMap(doc.data(), doc.id);
          final formattedPrice = _formatPrice(item.price);
          totalPrice += item.price;

          shareText.writeln('${counter++}. 📦 ${item.name}');
          shareText.writeln('   💰 السعر: $formattedPrice ريال');

          // إضافة معلومات إضافية إذا كانت متوفرة
          if (item.description?.isNotEmpty == true) {
            final shortDesc =
                item.description!.length > 50
                    ? '${item.description!.substring(0, 50)}...'
                    : item.description!;
            shareText.writeln('   📝 الوصف: $shortDesc');
          }

          // إضافة رابط للصورة بشكل أكثر تنظيماً
          if (item.imageUrl?.isNotEmpty == true) {
            shareText.writeln('   � رابط الصورة: ${item.imageUrl}');
          }

          shareText.writeln('   ────────────────────');
          shareText.writeln('');
        } catch (e) {
          // تجاهل المنتجات التي بها خطأ
        }
      }

      // إضافة إحصائيات
      shareText.writeln(
        '💰 إجمالي قيمة المفضلة: ${_formatPrice(totalPrice)} ريال',
      );
      shareText.writeln('');
      shareText.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      shareText.writeln('');
      shareText.writeln('📱 تم إنشاء هذه القائمة من تطبيق كودورا');
      shareText.writeln('🛒 احصل على التطبيق الآن واستمتع بتجربة تسوق مميزة!');
      shareText.writeln('');
      shareText.writeln('⭐ شارك هذه القائمة مع أصدقائك!');

      // إغلاق مؤشر التحميل
      Get.back();

      // مشاركة النص
      // يجب إضافة share_plus package في pubspec.yaml
      // await Share.share(shareText.toString(), subject: 'قائمة منتجاتي المفضلة');

      // لحين إضافة share package، سنعرض النص في dialog
      _showShareDialog(context, shareText.toString());
    } catch (e) {
      // إغلاق مؤشر التحميل في حالة الخطأ
      if (Get.isDialogOpen ?? false) Get.back();

      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء تجهيز قائمة المفضلة للمشاركة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[600],
        colorText: Colors.white,
      );
    }
  }

  // عرض dialog لمشاركة النص
  void _showShareDialog(BuildContext context, String shareText) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            title: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.share_rounded,
                    color: theme.primaryColor,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مشاركة قائمة المفضلة',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.titleLarge?.color,
                        ),
                      ),
                      Text(
                        'انسخ النص أو شاركه مع أصدقائك',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: Container(
              width: double.maxFinite,
              constraints: BoxConstraints(maxHeight: 450.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // شريط معلومات
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: theme.primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.primaryColor,
                          size: 16.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'يمكنك نسخ النص أدناه ومشاركته عبر أي تطبيق',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: theme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // النص القابل للتحديد
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          shareText,
                          style: TextStyle(
                            fontSize: 13.sp,
                            height: 1.5,
                            color: theme.textTheme.bodyMedium?.color,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              // زر الإغلاق
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close_rounded, size: 16.sp),
                label: Text('إغلاق'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                ),
              ),
              // زر النسخ
              ElevatedButton.icon(
                onPressed: () {
                  // نسخ النص للحافظة
                  Clipboard.setData(ClipboardData(text: shareText));
                  Navigator.of(context).pop();

                  // عرض رسالة نجاح مع انيميشن
                  Get.snackbar(
                    'تم النسخ بنجاح! 📋',
                    'تم نسخ قائمة المفضلة إلى الحافظة\nيمكنك الآن لصقها في أي تطبيق',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.green[600],
                    colorText: Colors.white,
                    icon: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                    ),
                    margin: EdgeInsets.all(16.w),
                    borderRadius: 15.r,
                    duration: const Duration(seconds: 4),
                    isDismissible: true,
                    dismissDirection: DismissDirection.horizontal,
                    forwardAnimationCurve: Curves.easeOutBack,
                    boxShadows: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.3),
                        blurRadius: 10.r,
                        offset: Offset(0, 4.h),
                      ),
                    ],
                  );
                },
                icon: Icon(Icons.copy_rounded, size: 16.sp),
                label: Text('نسخ النص'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 12.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 2,
                ),
              ),
            ],
            actionsPadding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
          ),
    );
  }

  // عرض حوار تأكيد مسح جميع المفضلة
  void _showClearAllDialog(
    BuildContext context,
    FavoriteController favoriteCtrl,
  ) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange[600],
                  size: 28.sp,
                ),
                SizedBox(width: 12.w),
                Text(
                  'تأكيد المسح',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleLarge?.color,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'هل أنت متأكد من رغبتك في مسح جميع المنتجات من قائمة المفضلة؟',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: theme.textTheme.bodyMedium?.color,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 16.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.red[600],
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'لا يمكن التراجع عن هذا الإجراء',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              // زر الإلغاء
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 12.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'إلغاء',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // زر التأكيد
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _clearAllFavorites(favoriteCtrl);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 12.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  'مسح الكل',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  // مسح جميع المفضلة
  void _clearAllFavorites(FavoriteController favoriteCtrl) async {
    try {
      // عرض مؤشر التحميل
      Get.dialog(
        Center(
          child: Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10.r,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16.h),
                Text(
                  'جاري مسح المفضلة...',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // الحصول على جميع المفضلة
      final favoritesStream = favoriteCtrl.getFavoritesStream();
      final snapshot = await favoritesStream.first;
      final favoriteIds = snapshot.docs.map((doc) => doc.id).toList();

      // مسح كل منتج من المفضلة
      for (String productId in favoriteIds) {
        await favoriteCtrl.toggleFavorite(productId, true);
      }

      // إغلاق مؤشر التحميل
      Get.back();

      // عرض رسالة نجاح
      Get.snackbar(
        'تم بنجاح',
        'تم مسح جميع المنتجات من قائمة المفضلة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[600],
        colorText: Colors.white,
        icon: Icon(Icons.check_circle, color: Colors.white),
        margin: EdgeInsets.all(16.w),
        borderRadius: 12.r,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      // إغلاق مؤشر التحميل في حالة الخطأ
      if (Get.isDialogOpen ?? false) Get.back();

      // عرض رسالة خطأ
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء مسح المفضلة: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[600],
        colorText: Colors.white,
        icon: Icon(Icons.error, color: Colors.white),
        margin: EdgeInsets.all(16.w),
        borderRadius: 12.r,
        duration: const Duration(seconds: 4),
      );
    }
  }

  // إضافة دالة مساعدة لعرض إحصائيات المفضلة
  Widget _buildFavoritesStats(
    BuildContext context,
    int filteredCount,
    int totalCount,
  ) {
    final theme = Theme.of(context);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withValues(alpha: 0.1),
            theme.primaryColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: 0.1),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.favorite_rounded,
              color: theme.primaryColor,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إجمالي المفضلة: $totalCount منتج',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (filteredCount != totalCount) ...[
                  SizedBox(height: 2.h),
                  Text(
                    'النتائج المعروضة: $filteredCount منتج',
                    style: TextStyle(
                      color: theme.primaryColor.withValues(alpha: 0.7),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (filteredCount != totalCount)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: theme.primaryColor,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                'مُفلتر',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // دالة تنسيق السعر لإزالة الأصفار غير الضرورية
  String _formatPrice(double price) {
    if (price == price.toInt()) {
      return price.toInt().toString();
    } else {
      return price.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
    }
  }
}
