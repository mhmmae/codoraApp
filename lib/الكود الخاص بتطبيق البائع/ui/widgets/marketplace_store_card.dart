import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../Model/SellerModel.dart';
import '../theme/marketplace_colors.dart';

/// بطاقة متجر احترافية قابلة لإعادة الاستخدام
class MarketplaceStoreCard extends StatelessWidget {
  final SellerModel store;
  final VoidCallback onTap;
  final bool isGridView;
  final int index;

  const MarketplaceStoreCard({
    super.key,
    required this.store,
    required this.onTap,
    this.isGridView = false,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: isGridView ? 0 : 16.h),
      decoration: BoxDecoration(
        color: MarketplaceColors.backgroundWhite,
        borderRadius: BorderRadius.circular(MarketplaceDimensions.radiusXLarge.r),
        boxShadow: MarketplaceColors.mediumShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(MarketplaceDimensions.radiusXLarge.r),
          onTap: onTap,
          child: isGridView ? _buildGridCard() : _buildListCard(),
        ),
      ),
    );
  }

  Widget _buildGridCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // صورة المتجر
        Expanded(
          flex: 3,
          child: _buildStoreImage(
            width: double.infinity,
            height: double.infinity,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(MarketplaceDimensions.radiusXLarge.r),
              topRight: Radius.circular(MarketplaceDimensions.radiusXLarge.r),
            ),
          ),
        ),
        
        // معلومات المتجر
        Expanded(
          flex: 2,
          child: Padding(
            padding: EdgeInsets.all(MarketplaceDimensions.paddingMedium.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStoreHeader(),
                _buildStoreFooter(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListCard() {
    return Padding(
      padding: EdgeInsets.all(MarketplaceDimensions.paddingMedium.w),
      child: Row(
        children: [
          // صورة المتجر
          _buildStoreImage(
            width: MarketplaceDimensions.imageMedium.w,
            height: MarketplaceDimensions.imageMedium.h,
            borderRadius: BorderRadius.circular(MarketplaceDimensions.radiusLarge.r),
          ),
          
          SizedBox(width: MarketplaceDimensions.spaceMedium.w),
          
          // معلومات المتجر
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStoreHeader(),
                SizedBox(height: MarketplaceDimensions.spaceSmall.h),
                if (store.sellerName.isNotEmpty) ...[
                  _buildSellerInfo(),
                  SizedBox(height: MarketplaceDimensions.spaceSmall.h),
                ],
                Row(
                  children: [
                    if (store.shopCategory.isNotEmpty) ...[
                      _buildCategoryChip(),
                      const Spacer(),
                    ],
                    _buildVerificationBadge(),
                  ],
                ),
              ],
            ),
          ),
          
          SizedBox(width: MarketplaceDimensions.spaceSmall.w),
          
          // سهم التنقل
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: MarketplaceDimensions.iconSmall.sp,
            color: MarketplaceColors.textLight,
          ),
        ],
      ),
    );
  }

  Widget _buildStoreImage({
    required double width,
    required double height,
    required BorderRadius borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: MarketplaceColors.cardGradient,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          children: [
            // الصورة أو الرمز الافتراضي
            store.shopFrontImageUrl != null && store.shopFrontImageUrl!.isNotEmpty
                ? Image.network(
                    store.shopFrontImageUrl!,
                    width: width,
                    height: height,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildDefaultImage(),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.w,
                          color: MarketplaceColors.primaryBlue,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                  )
                : _buildDefaultImage(),
            
            // تدرج خفيف للتحسين البصري
            if (store.shopFrontImageUrl?.isNotEmpty ?? false)
              Container(
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.1),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultImage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: MarketplaceColors.cardGradient,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.storefront_rounded,
              size: 32.sp,
              color: MarketplaceColors.primaryBlue.withOpacity(0.7),
            ),
            if (!isGridView) ...[
              SizedBox(height: 4.h),
              Text(
                'صورة المتجر',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: MarketplaceColors.textLight,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStoreHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // اسم المتجر
        Text(
          store.shopName,
          style: TextStyle(
            fontSize: isGridView ? 14.sp : 16.sp,
            fontWeight: FontWeight.bold,
            color: MarketplaceColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        
        // فئة المتجر في العرض الشبكي
        if (isGridView && store.shopCategory.isNotEmpty) ...[
          SizedBox(height: MarketplaceDimensions.spaceTiny.h),
          _buildCategoryChip(),
        ],
      ],
    );
  }

  Widget _buildStoreFooter() {
    return Row(
      children: [
        _buildVerificationBadge(),
        if (store.shopPhoneNumber.isNotEmpty) ...[
          const Spacer(),
          _buildCallIcon(),
        ],
      ],
    );
  }

  Widget _buildSellerInfo() {
    return Text(
      'البائع: ${store.sellerName}',
      style: TextStyle(
        fontSize: 12.sp,
        color: MarketplaceColors.textSecondary,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildCategoryChip() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: MarketplaceDimensions.paddingSmall.w,
        vertical: MarketplaceDimensions.paddingTiny.h,
      ),
      decoration: BoxDecoration(
        color: MarketplaceColors.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(MarketplaceDimensions.radiusSmall.r),
        border: Border.all(
          color: MarketplaceColors.primaryBlue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        store.shopCategory,
        style: TextStyle(
          fontSize: 10.sp,
          color: MarketplaceColors.primaryBlue,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildVerificationBadge() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: MarketplaceDimensions.paddingSmall.w,
        vertical: MarketplaceDimensions.paddingTiny.h,
      ),
      decoration: BoxDecoration(
        color: MarketplaceColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(MarketplaceDimensions.radiusSmall.r),
        border: Border.all(
          color: MarketplaceColors.success.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_rounded,
            size: isGridView ? 10.sp : 12.sp,
            color: MarketplaceColors.success,
          ),
          SizedBox(width: 2.w),
          Text(
            'بائع جملة',
            style: TextStyle(
              fontSize: isGridView ? 8.sp : 10.sp,
              color: MarketplaceColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallIcon() {
    return Container(
      padding: EdgeInsets.all(MarketplaceDimensions.paddingTiny.w),
      decoration: BoxDecoration(
        color: MarketplaceColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(MarketplaceDimensions.radiusSmall.r),
      ),
      child: Icon(
        Icons.phone_rounded,
        size: MarketplaceDimensions.iconSmall.sp,
        color: MarketplaceColors.info,
      ),
    );
  }
}

/// بطاقة متجر مع تأثيرات انيميشن
class AnimatedMarketplaceStoreCard extends StatefulWidget {
  final SellerModel store;
  final VoidCallback onTap;
  final bool isGridView;
  final int index;
  final Duration animationDelay;

  const AnimatedMarketplaceStoreCard({
    super.key,
    required this.store,
    required this.onTap,
    this.isGridView = false,
    this.index = 0,
    this.animationDelay = Duration.zero,
  });

  @override
  State<AnimatedMarketplaceStoreCard> createState() => _AnimatedMarketplaceStoreCardState();
}

class _AnimatedMarketplaceStoreCardState extends State<AnimatedMarketplaceStoreCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: MarketplaceAnimations.staggered,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: MarketplaceAnimations.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: MarketplaceAnimations.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: MarketplaceAnimations.easeOutBack,
    ));

    // بدء الانيميشن مع تأخير
    Future.delayed(widget.animationDelay, () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.translate(
            offset: _slideAnimation.value * 50,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: MarketplaceStoreCard(
                store: widget.store,
                onTap: widget.onTap,
                isGridView: widget.isGridView,
                index: widget.index,
              ),
            ),
          ),
        );
      },
    );
  }
} 