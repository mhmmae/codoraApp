import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // لاستخدام HapticFeedback
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../Model/SellerModel.dart';

typedef OnFilterPressed = void Function();

class StoreHeader extends StatelessWidget {
  final SellerModel store;
  final OnFilterPressed? onFilterPressed;

  const StoreHeader({super.key, required this.store, this.onFilterPressed});

  String _getTimeUntilStatusChange(
    Map<String, dynamic> workingHours,
    String currentDayKey,
    String? opensAt,
    String? closesAt,
  ) {
    final now = DateTime.now();
    bool isStoreOpen = _isStoreOpenNow(currentDayKey, opensAt, closesAt);

    try {
      if (isStoreOpen) {
        // If open, calculate time until closing
        final closesTime = DateFormat('HH:mm').parse(closesAt!);
        final todayCloses = DateTime(
          now.year,
          now.month,
          now.day,
          closesTime.hour,
          closesTime.minute,
        );
        if (now.isBefore(todayCloses)) {
          final difference = todayCloses.difference(now);
          return 'يغلق بعد ${difference.inHours} س و ${difference.inMinutes.remainder(60)} د';
        }
      } else {
        // If closed, find the next opening time
        return _findNextOpeningTime(workingHours, now);
      }
    } catch (e) {
      debugPrint('Error calculating time until status change: $e');
    }
    return '';
  }

  String _findNextOpeningTime(Map<String, dynamic> workingHours, DateTime now) {
    final dayOrder = [
      "sunday_en",
      "monday_en",
      "tuesday_en",
      "wednesday_en",
      "thursday_en",
      "friday_en",
      "saturday_en",
    ];
    final currentDayIndex = now.weekday % 7; // Sunday is 7, so map to 0

    for (int i = 0; i < 7; i++) {
      final dayIndex = (currentDayIndex + i) % 7;
      final dayKey = dayOrder[dayIndex];
      final dayData = workingHours[dayKey];

      if (dayData != null && dayData['isOpen'] == true) {
        final opensAt = dayData['opensAt'] as String?;
        if (opensAt != null) {
          final opensTime = DateFormat('HH:mm').parse(opensAt);
          final nextOpeningDateTime = DateTime(
            now.year,
            now.month,
            now.day + i,
            opensTime.hour,
            opensTime.minute,
          );

          if (nextOpeningDateTime.isAfter(now)) {
            final difference = nextOpeningDateTime.difference(now);
            String timeStr = '';
            if (difference.inDays > 0) timeStr += '${difference.inDays} ي ';
            if (difference.inHours.remainder(24) > 0) {
              timeStr += '${difference.inHours.remainder(24)} س ';
            }
            if (difference.inMinutes.remainder(60) > 0) {
              timeStr += '${difference.inMinutes.remainder(60)} د';
            }
            return 'يفتح بعد $timeStr';
          }
        }
      }
    }
    return 'لا توجد أوقات عمل قادمة';
  }

  bool _isStoreOpenNow(String dayKey, String? opensAt, String? closesAt) {
    if (opensAt == null || closesAt == null) {
      return false;
    }

    final now = DateTime.now();
    final currentDay =
        DateFormat('EEEE').format(now).toLowerCase(); // e.g., 'monday'

    // Map dayKey (e.g., sunday_en) to currentDay (e.g., sunday)
    String normalizedDayKey = dayKey.replaceAll('_en', '');

    if (normalizedDayKey != currentDay) {
      return false; // Not today
    }

    try {
      final opensTime = DateFormat('HH:mm').parse(opensAt);
      final closesTime = DateFormat('HH:mm').parse(closesAt);

      final currentHour = now.hour;
      final currentMinute = now.minute;

      final opensHour = opensTime.hour;
      final opensMinute = opensTime.minute;

      final closesHour = closesTime.hour;
      final closesMinute = closesTime.minute;

      // Create DateTime objects for comparison, using today's date
      final todayOpens = DateTime(
        now.year,
        now.month,
        now.day,
        opensHour,
        opensMinute,
      );
      final todayCloses = DateTime(
        now.year,
        now.month,
        now.day,
        closesHour,
        closesMinute,
      );
      final currentTime = DateTime(
        now.year,
        now.month,
        now.day,
        currentHour,
        currentMinute,
      );

      if (todayOpens.isBefore(todayCloses)) {
        // Normal case: opens and closes on the same day
        return currentTime.isAfter(todayOpens) &&
            currentTime.isBefore(todayCloses);
      } else {
        // Overnight case: e.g., opens 22:00, closes 06:00
        // Open if current time is after opening OR current time is before closing (next day)
        return currentTime.isAfter(todayOpens) ||
            currentTime.isBefore(todayCloses);
      }
    } catch (e) {
      debugPrint('Error parsing time: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF667EEA),
            const Color(0xFF764BA2),
            const Color(0xFF6B73FF),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.4),
            blurRadius: 25.r,
            spreadRadius: 3.r,
            offset: Offset(0, 12.h),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.2),
            blurRadius: 10.r,
            spreadRadius: 1.r,
            offset: Offset(0, -2.h),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            // إضافة تأثير الزجاج الشفاف
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            ),
          ),
          child: Row(
            children: [
              // زر الرجوع المحسن مع تأثيرات التفاعل
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    // تأثير اهتزاز للتأكيد
                    HapticFeedback.lightImpact();
                    Get.back();
                  },
                  borderRadius: BorderRadius.circular(12.r),
                  splashColor: Colors.white.withOpacity(0.3),
                  highlightColor: Colors.white.withOpacity(0.1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.w,
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_rounded,
                      color: Colors.white,
                      size: 16.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),

              // صورة المتجر مع تأثيرات محسنة والتفاعل
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    if (store.shopFrontImageUrl != null &&
                        store.shopFrontImageUrl!.isNotEmpty) {
                      _showEnlargedStoreImage(
                        context,
                        store.shopFrontImageUrl!,
                        'store_image_${store.uid}',
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(50.r),
                  splashColor: Colors.white.withOpacity(0.3),
                  highlightColor: Colors.white.withOpacity(0.1),
                  child: Hero(
                    tag: 'store_image_${store.uid}',
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.6),
                            Colors.white.withOpacity(0.2),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 15.r,
                            spreadRadius: 2.r,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 28.r,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: store.shopFrontImageUrl ?? '',
                            width: 65.w,
                            height: 65.h,
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) => Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.3),
                                        Colors.white.withOpacity(0.1),
                                      ],
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.store_rounded,
                                    color: Colors.white.withOpacity(0.8),
                                    size: 40.sp,
                                  ),
                                ),
                            errorWidget:
                                (context, url, error) => Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.3),
                                        Colors.white.withOpacity(0.1),
                                      ],
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.store_rounded,
                                    color: Colors.white.withOpacity(0.8),
                                    size: 40.sp,
                                  ),
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 14.w),

              // معلومات المتجر
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // اسم المتجر مع تأثير نصي محسن
                    Text(
                      store.shopName,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 8.r,
                            color: Colors.black.withOpacity(0.4),
                            offset: Offset(2.w, 2.h),
                          ),
                          Shadow(
                            blurRadius: 2.r,
                            color: Colors.white.withOpacity(0.2),
                            offset: Offset(-1.w, -1.h),
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6.h),

                    // شارة التحقق والحالة
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 5.h,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF10B981),
                                const Color(0xFF34D399),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20.r),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withOpacity(0.4),
                                blurRadius: 8.r,
                                offset: Offset(0, 3.h),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                color: Colors.white,
                                size: 14.sp,
                              ),
                              SizedBox(width: 3.w),
                              Text(
                                'متجر معتمد',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8.w),

                        // مؤشر الحالة (مفتوح/مغلق)
                        _buildStatusIndicator(),
                      ],
                    ),
                  ],
                ),
              ),

              // أزرار الإجراءات المحسنة مع التفاعل
              Column(
                children: [
                  // زر الفلترة المحسن
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        onFilterPressed?.call();
                      },
                      borderRadius: BorderRadius.circular(16.r),
                      splashColor: Colors.white.withOpacity(0.3),
                      highlightColor: Colors.white.withOpacity(0.1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.25),
                              Colors.white.withOpacity(0.15),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.w,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8.r,
                              offset: Offset(0, 4.h),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          color: Colors.white,
                          size: 15.sp,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),

                  // زر المعلومات المحسن
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        showStoreDetailsBottomSheet(context, store);
                      },
                      borderRadius: BorderRadius.circular(16.r),
                      splashColor: Colors.white.withOpacity(0.3),
                      highlightColor: Colors.white.withOpacity(0.1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.25),
                              Colors.white.withOpacity(0.15),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.w,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8.r,
                              offset: Offset(0, 4.h),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.info_outline_rounded,
                          color: Colors.white,
                          size: 15.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // مؤشر حالة المتجر المحسن
  Widget _buildStatusIndicator() {
    final now = DateTime.now();
    final currentDayKey = '${DateFormat('EEEE').format(now).toLowerCase()}_en';
    final dayData = store.workingHours[currentDayKey];
    final opensAt = dayData?['opensAt'] as String?;
    final closesAt = dayData?['closesAt'] as String?;

    bool isOpen = _isStoreOpenNow(currentDayKey, opensAt, closesAt);

    // تحديد الألوان حسب حالة المتجر مثل widget معلومات المتجر
    final openColors = {
      'gradient': [Color(0xFF10B981), Color(0xFF34D399)],
      'shadow': Color(0xFF10B981).withOpacity(0.4),
    };

    final closedColors = {
      'gradient': [Color(0xFFF43F5E), Color(0xFFF87171)],
      'shadow': Color(0xFFF43F5E).withOpacity(0.4),
    };

    final colors = isOpen ? openColors : closedColors;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors['gradient'] as List<Color>,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: colors['shadow'] as Color,
            blurRadius: 8.r,
            spreadRadius: 1.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8.w,
            height: 8.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.6),
                  blurRadius: 4.r,
                  spreadRadius: 1.r,
                ),
              ],
            ),
          ),
          SizedBox(width: 4.w),
          Text(
            isOpen ? 'مفتوح' : 'مغلق',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  blurRadius: 2.r,
                  color: Colors.black.withOpacity(0.2),
                  offset: Offset(1.w, 1.h),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEnlargedStoreImage(
    BuildContext context,
    String imageUrl,
    String tag,
  ) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (BuildContext context, _, __) {
          return Scaffold(
            backgroundColor: Colors.black.withOpacity(0.8),
            body: Dismissible(
              key: const Key('enlarged_image'),
              direction: DismissDirection.vertical,
              onDismissed: (_) => Navigator.of(context).pop(),
              child: Center(
                child: Hero(
                  tag: tag,
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                      placeholder:
                          (context, url) =>
                              const Center(child: CircularProgressIndicator()),
                      errorWidget:
                          (context, url, error) =>
                              const Icon(Icons.error, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void showStoreDetailsBottomSheet(BuildContext context, SellerModel store) {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFF0F4F8), // لون فاتح
              const Color(0xFFE0E6ED), // لون أغمق قليلاً
            ],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 25.r,
              spreadRadius: 5.r,
              offset: Offset(0, -10.h),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.6),
              blurRadius: 10.r,
              spreadRadius: 2.r,
              offset: Offset(0, -5.h),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // شريط السحب وزر الإغلاق
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'معلومات المتجر',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 5.r,
                          color: Colors.black.withOpacity(0.3),
                          offset: Offset(2.w, 2.h),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white, size: 28.sp),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),
            // شريط السحب (Handle)
            Center(
              child: Container(
                width: 80.w,
                height: 6.h,
                margin: EdgeInsets.symmetric(vertical: 10.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey[400]!, Colors.grey[200]!],
                  ),
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
            // معلومات المتجر الفعلية
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Shop Name and Owner Info
                    Container(
                      margin: EdgeInsets.only(bottom: 15.h),
                      padding: EdgeInsets.all(15.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10.r,
                            offset: Offset(0, 5.h),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.grey[200]!,
                          width: 1.w,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Shop Image
                          if (store.shopFrontImageUrl != null &&
                              store.shopFrontImageUrl!.isNotEmpty)
                            GestureDetector(
                              onTap:
                                  () => _showEnlargedStoreImage(
                                    context,
                                    store.shopFrontImageUrl!,
                                    'shopImage',
                                  ),
                              child: Hero(
                                tag: 'shopImage',
                                child: CircleAvatar(
                                  radius: 28.r,
                                  backgroundColor: Colors.grey[200],
                                  backgroundImage: CachedNetworkImageProvider(
                                    store.shopFrontImageUrl!,
                                  ),
                                  onBackgroundImageError: (
                                    exception,
                                    stacktrace,
                                  ) {
                                    // Fallback to a default icon if image fails to load
                                    debugPrint(
                                      'Error loading shop image: $exception',
                                    );
                                  },
                                ),
                              ),
                            )
                          else
                            CircleAvatar(
                              radius: 28.r,
                              backgroundColor: Colors.grey[200],
                              child: Icon(
                                Icons.store,
                                size: 30.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          SizedBox(width: 15.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  store.shopName,
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1F2937),
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                // Owner Name and Image
                                Row(
                                  children: [
                                    if (store.sellerProfileImageUrl != null &&
                                        store.sellerProfileImageUrl!.isNotEmpty)
                                      CircleAvatar(
                                        radius: 12.r,
                                        backgroundColor: Colors.grey[200],
                                        backgroundImage:
                                            CachedNetworkImageProvider(
                                              store.sellerProfileImageUrl!,
                                            ),
                                        onBackgroundImageError: (
                                          exception,
                                          stacktrace,
                                        ) {
                                          debugPrint(
                                            'Error loading owner image: $exception',
                                          );
                                        },
                                      )
                                    else
                                      Icon(
                                        Icons.person_outline,
                                        size: 20.sp,
                                        color: Colors.grey[600],
                                      ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      store.sellerName,
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Address
                    GestureDetector(
                      onTap: () {
                        // TODO: Implement map navigation
                        Get.snackbar(
                          'الموقع',
                          'سيتم فتح الخريطة قريباً لعرض موقع المتجر.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.blueAccent,
                          colorText: Colors.white,
                        );
                      },
                      child: Container(
                        margin: EdgeInsets.only(bottom: 15.h),
                        padding: EdgeInsets.all(15.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 10.r,
                              offset: Offset(0, 5.h),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.grey[200]!,
                            width: 1.w,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF6366F1),
                                    const Color(0xFF8B5CF6),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF6366F1,
                                    ).withOpacity(0.3),
                                    blurRadius: 8.r,
                                    offset: Offset(0, 4.h),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 24.sp,
                              ),
                            ),
                            SizedBox(width: 15.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'العنوان',
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF4B5563),
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    store.shopAddressText != null &&
                                            store.shopAddressText!.contains(',')
                                        ? store.shopAddressText!
                                            .split(',')
                                            .last
                                            .trim() // Display only the Iraqi governorate
                                        : store.shopAddressText ?? 'غير متوفر',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      color: const Color(0xFF1F2937),
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
                    // Working Hours - Improved UI
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 20.h),
                        Text(
                          'ساعات العمل',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 2,
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(12.w),
                          child: Column(
                            children: _buildEnhancedWorkingHoursRows(
                              store.workingHours,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Store Status Widget
                    SizedBox(height: 15.h),
                    _buildStoreStatusWidget(store.workingHours),
                    SizedBox(height: 4.h),
                    _buildDetailRow(
                      Icons.phone,
                      'رقم الهاتف',
                      store.shopPhoneNumber,
                    ),
                    _buildDetailRow(
                      Icons.email,
                      'البريد الإلكتروني',
                      store.email,
                    ),
                    if (store.shopDescription != null &&
                        store.shopDescription!.isNotEmpty)
                      _buildDetailRow(
                        Icons.description,
                        'الوصف',
                        store.shopDescription,
                      ),

                    SizedBox(height: 20.h),
                    Center(
                      child: ElevatedButton(
                        onPressed: () => Get.back(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.transparent, // لجعل التدرج مرئياً
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.r),
                          ),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF6366F1),
                                const Color(0xFF8B5CF6),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(15.r),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6366F1).withOpacity(0.4),
                                blurRadius: 10.r,
                                offset: Offset(0, 5.h),
                              ),
                            ],
                          ),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 40.w,
                              vertical: 15.h,
                            ),
                            child: Text(
                              'إغلاق',
                              style: TextStyle(
                                fontSize: 18.sp,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
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
      isScrollControlled: true,
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String? value) {
    return Container(
      margin: EdgeInsets.only(bottom: 15.h),
      padding: EdgeInsets.all(15.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10.r,
            offset: Offset(0, 5.h),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!, width: 1.w),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  blurRadius: 8.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24.sp),
          ),
          SizedBox(width: 15.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4B5563),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value ?? 'غير متوفر',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: const Color(0xFF1F2937),
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

  Widget _buildStoreStatusWidget(Map<String, dynamic> workingHours) {
    final now = DateTime.now();
    final currentDayKey = '${DateFormat('EEEE').format(now).toLowerCase()}_en';
    final dayData = workingHours[currentDayKey];

    final opensAt = dayData?['opensAt'] as String?;
    final closesAt = dayData?['closesAt'] as String?;

    bool isStoreOpenNow = _isStoreOpenNow(currentDayKey, opensAt, closesAt);
    String timeUntilStatusChange = _getTimeUntilStatusChange(
      workingHours,
      currentDayKey,
      opensAt,
      closesAt,
    );

    // Define color schemes for open and closed states
    final openColors = {
      'gradient': [Color(0xFF10B981), Color(0xFF34D399)],
      'shadow': Color(0xFF10B981).withOpacity(0.4),
      'text': Colors.white,
      'icon': Colors.white,
    };

    final closedColors = {
      'gradient': [Color(0xFFF43F5E), Color(0xFFF87171)],
      'shadow': Color(0xFFF43F5E).withOpacity(0.4),
      'text': Colors.white,
      'icon': Colors.white,
    };

    final colors = isStoreOpenNow ? openColors : closedColors;
    IconData statusIcon =
        isStoreOpenNow ? Icons.storefront_rounded : Icons.watch_later_outlined;

    return Animate(
      effects: [
        FadeEffect(duration: 800.ms),
        ScaleEffect(begin: Offset(0.9, 0.9), curve: Curves.elasticOut),
      ],
      child: Container(
        margin: EdgeInsets.only(bottom: 15.h),
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors['gradient'] as List<Color>,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: colors['shadow'] as Color,
              blurRadius: 15.r,
              spreadRadius: 2.r,
              offset: Offset(0, 8.h),
            ),
          ],
        ),
        child: Row(
          children: [
            Animate(
              effects: [
                ShakeEffect(duration: 1200.ms, hz: 2, rotation: 0.05),
                ShimmerEffect(duration: 2000.ms, color: Colors.white70),
              ],
              child: Icon(
                statusIcon,
                color: colors['icon'] as Color,
                size: 32.sp,
              ),
            ),
            SizedBox(width: 15.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isStoreOpenNow ? 'المتجر مفتوح الآن' : 'المتجر مغلق حالياً',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: colors['text'] as Color,
                      shadows: [
                        Shadow(
                          blurRadius: 2,
                          color: Colors.black.withOpacity(0.2),
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                  if (timeUntilStatusChange.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 4.h),
                      child: Text(
                        timeUntilStatusChange,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: (colors['text'] as Color).withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Animate(onPlay: (controller) => controller.repeat()).custom(
              duration: 2000.ms,
              builder: (context, value, child) {
                return Opacity(
                  opacity: 1 - (value * 0.5),
                  child: Transform.scale(
                    scale: 1 + (value * 0.1),
                    child: Icon(
                      Icons.circle,
                      color: (colors['icon'] as Color).withOpacity(0.2),
                      size: 12.sp,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildEnhancedWorkingHoursRows(
    Map<String, dynamic> workingHours,
  ) {
    final daysOfWeek = [
      {'name': 'الأحد', 'key': 'sunday_en'},
      {'name': 'الإثنين', 'key': 'monday_en'},
      {'name': 'الثلاثاء', 'key': 'tuesday_en'},
      {'name': 'الأربعاء', 'key': 'wednesday_en'},
      {'name': 'الخميس', 'key': 'thursday_en'},
      {'name': 'الجمعة', 'key': 'friday_en'},
      {'name': 'السبت', 'key': 'saturday_en'},
    ];

    return daysOfWeek.map((day) {
      final dayData = workingHours[day['key']] as Map<String, dynamic>?;
      final isClosed =
          dayData == null || !(dayData['isOpen'] as bool? ?? false);
      final opensAt = dayData?['opensAt'] as String?;
      final closesAt = dayData?['closesAt'] as String?;

      return Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              day['name']!,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4B5563),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: isClosed ? Colors.grey[100] : const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                isClosed
                    ? 'مغلق'
                    : (opensAt != null && closesAt != null
                        ? '$opensAt - $closesAt'
                        : 'غير محدد'),
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                  color: isClosed ? Colors.grey[600] : const Color(0xFF065F46),
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
