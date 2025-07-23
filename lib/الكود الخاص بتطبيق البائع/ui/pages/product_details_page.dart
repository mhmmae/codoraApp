import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../Model/SellerModel.dart';
import '../controllers/store_products_controller.dart';
import '../controllers/retail_cart_controller.dart';
import '../pages/retail_cart_page.dart';
import '../pages/store_products_page.dart';

class ProductDetailsPage extends StatefulWidget {
  const ProductDetailsPage({super.key});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  late final Map<String, dynamic> product;
  late final SellerModel store;
  
  int currentImageIndex = 0;

  // --== State for Smart Price Analysis ==--
  late TextEditingController _retailPriceController;
  double _customRetailPrice = 0.0;
  // --==================================--

  // --== State for Product Classification ==--
  Map<String, dynamic>? _productClassificationData;
  bool _isLoadingClassification = true;
  // --=====================================--

  // الحصول على المتحكمات
  late final StoreProductsController storeController;
  late final RetailCartController cartController;

  @override
  void initState() {
    super.initState();
    product = Get.arguments['product'];
    store = Get.arguments['store'];
    
    // --== Initialize Smart Price Analysis State ==--
    _initializePriceAnalysis();
    // --=========================================--
    
    // --== Load Product Classification Data Once ==--
    _loadProductClassificationData();
    // --==========================================--
    
    // طباعة معلومات المنتج للتشخيص
    debugPrint('🛍️ ═══════ معلومات المنتج في ProductDetailsPage ═══════');
    debugPrint('اسم المنتج: ${product['nameOfItem']}');
    debugPrint('حالة المنتج: ${product['itemCondition']}');
    debugPrint('كمية الكارتونة: ${product['cartonQuantity']}');
    debugPrint('originalCompanyId: ${product['originalCompanyId']}');
    debugPrint('originalProductId: ${product['originalProductId']}');
    debugPrint('جميع مفاتيح المنتج: ${product.keys.toList()}');
    debugPrint('═══════════════════════════════════════════════════════');
    
    // الحصول على المتحكمات مع التحقق من وجودها
    try {
      storeController = Get.find<StoreProductsController>();
    } catch (e) {
      debugPrint('خطأ في العثور على StoreProductsController: $e');
      Get.put(StoreProductsController(store: store));
      storeController = Get.find<StoreProductsController>();
    }
    
    try {
      cartController = Get.find<RetailCartController>();
    } catch (e) {
      debugPrint('خطأ في العثور على RetailCartController: $e');
      Get.put(RetailCartController());
      cartController = Get.find<RetailCartController>();
    }
  }

  // --== Logic for Smart Price Analysis ==--
  void _initializePriceAnalysis() {
    final suggestedPrice = double.tryParse(product['suggestedRetailPrice']?.toString() ?? '0') ?? 0.0;
    _customRetailPrice = suggestedPrice > 0 ? suggestedPrice : (double.tryParse(product['priceOfItem']?.toString() ?? '0') ?? 0.0) * 1.2;
    _retailPriceController = TextEditingController(text: _formatPriceForInput(_customRetailPrice));
    
    _retailPriceController.addListener(() {
      final text = _retailPriceController.text.replaceAll(',', '');
      final newPrice = double.tryParse(text) ?? 0.0;
      if (newPrice != _customRetailPrice) {
        setState(() {
          _customRetailPrice = newPrice;
        });
      }
    });
  }

  String _formatPriceForInput(double price) {
    final formatter = NumberFormat('#,###');
    return formatter.format(price);
  }

  @override
  void dispose() {
    _retailPriceController.dispose();
    super.dispose();
  }
  // --==================================--

  // دالة تنسيق السعر مع الفواصل
  String _formatPrice(double price) {
    final formatter = NumberFormat('#,###', 'ar');
    return formatter.format(price.toInt());
  }

  // دالة تحويل رقم درجة الجودة إلى نص
  String _gradeToText(int grade) {
    const grades = {
      1: 'أولى',
      2: 'ثانية', 
      3: 'ثالثة',
      4: 'رابعة',
      5: 'خامسة',
      6: 'سادسة',
      7: 'سابعة',
      8: 'ثامنة',
      9: 'تاسعة',
      10: 'عاشرة'
    };
    return grades[grade] ?? 'غير محدد';
  }

  // دالة تحويل حالة المنتج إلى نص
  String _itemConditionToText(String condition) {
    if (condition.toLowerCase() == 'original') {
      return 'براند';
    } else {
      return 'تجاري';
    }
  }

  // دالة للحصول على صور المنتج - مطابقة لمنطق StoreProductsPage
  List<String> _getProductImages() {
    try {
      // استخدام نفس منطق StoreProductsPage
      final manyImages = product['manyImages'] as List<dynamic>? ?? [];
      
      // إذا كانت manyImages تحتوي على صور
      if (manyImages.isNotEmpty) {
        final imagesList = manyImages.map((img) => img.toString()).where((url) => 
          url.isNotEmpty && url != 'null').toList();
        if (imagesList.isNotEmpty) {
          debugPrint('صور المنتج من manyImages: ${imagesList.length} صورة');
          return imagesList;
        }
      }
      
      // إذا لم توجد في manyImages، جرب url
      final singleUrl = product['url']?.toString();
      if (singleUrl != null && singleUrl.isNotEmpty && singleUrl != 'null') {
        debugPrint('صورة المنتج من url: $singleUrl');
        return [singleUrl];
      }
      
      // للتوافق مع الإصدارات القديمة - imagesUrls
      final imagesUrls = product['imagesUrls'] as List<dynamic>? ?? [];
      if (imagesUrls.isNotEmpty) {
        final imagesList = imagesUrls.map((img) => img.toString()).where((url) => 
          url.isNotEmpty && url != 'null').toList();
        if (imagesList.isNotEmpty) {
          debugPrint('صور المنتج من imagesUrls: ${imagesList.length} صورة');
          return imagesList;
        }
      }
      
      debugPrint('لا توجد صور للمنتج');
      return [];
    } catch (e) {
      debugPrint('خطأ في جلب صور المنتج: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = _getProductImages();
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // شريط التطبيق مع معرض الصور
          SliverAppBar(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1F2937),
            elevation: 0,
            pinned: true,
            expandedHeight: 250.h,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildImageGallery(images),
            ),
            actions: [
              // زر المفضلة
              IconButton(
                onPressed: () {
                  // إضافة للمفضلة
                },
                icon: Icon(Icons.favorite_border, size: 24.sp),
              ),
              // زر المشاركة
              IconButton(
                onPressed: () {
                  // مشاركة المنتج
                },
                icon: Icon(Icons.share, size: 24.sp),
              ),
            ],
          ),
          
          // محتوى الصفحة
          SliverToBoxAdapter(
            child: Column(
              children: [
                // معلومات المنتج الأساسية
                _buildProductBasicInfo(),
                
                // وصف المنتج
                _buildProductDescription(),
                
                // معلومات المنتج الأصلي
                _buildOriginalProductInfo(),
                
                // تحليل السعر الذكي
                _buildSmartPriceAnalysis(),
                
                // أيقونة الانتقال لمعلومات المتجر
                _buildStoreNavigationButton(),
                
                SizedBox(height: 120.h), // مساحة إضافية للـ bottom bar
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomCartBar(),
    );
  }

  Widget _buildImageGallery(List<String> images) {
    if (images.isEmpty) {
      return Container(
        color: Colors.grey[100],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported,
                size: 80.sp,
                color: Colors.grey[400],
              ),
              SizedBox(height: 8.h),
              Text(
                'لا توجد صورة',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        PageView.builder(
          itemCount: images.length,
          onPageChanged: (index) {
            setState(() {
              currentImageIndex = index;
            });
          },
          itemBuilder: (context, index) {
            return CachedNetworkImage(
              imageUrl: images[index],
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[100],
                child: Center(
                  child: CircularProgressIndicator(
                    color: const Color(0xFF6366F1),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[100],
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error,
                        size: 50.sp,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'خطأ في تحميل الصورة',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        // مؤشرات الصور
        if (images.length > 1)
          Positioned(
            bottom: 16.h,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: images.asMap().entries.map((entry) {
                return Container(
                  width: 8.w,
                  height: 8.h,
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: currentImageIndex == entry.key
                        ? Colors.white
                        : Colors.white.withOpacity(0.4),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildProductBasicInfo() {
    return Container(
      margin: EdgeInsets.all(20.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20.r,
            offset: Offset(0, 4.h),
          ),
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            blurRadius: 40.r,
            offset: Offset(0, 10.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // اسم المنتج
          Container(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Row(
              children: [
                Container(
                  width: 4.w,
                  height: 24.h,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF6366F1),
                        Color(0xFF059669),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'اسم المنتج',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6B7280),
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 4.h),
          Text(
            product['nameOfItem']?.toString() ?? 'اسم المنتج غير متوفر',
            style: TextStyle(
                          fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
                      ).animate().fadeIn(duration: 400.ms).slide(begin: const Offset(-0.3, 0), end: Offset.zero),
          
          SizedBox(height: 20.h),
          
          // widget الأسعار المطور
          _buildRetailPriceWidget(),
          
          SizedBox(height: 20.h),
          
          // معلومات إضافية محسنة
          Row(
            children: [
              // حالة المنتج
              Expanded(
                child: _buildInfoChip(
                  'الحالة',
                  _itemConditionToText(product['itemCondition']?.toString() ?? ''),
                  product['itemCondition']?.toString().toLowerCase() == 'original'
                      ? const Color(0xFF059669)
                      : const Color(0xFF6366F1),
                ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0)),
              ),
              SizedBox(width: 12.w),
              // درجة الجودة
              if (product['grade'] != null)
                Expanded(
                  child: _buildInfoChip(
                    'الدرجة',
                    _gradeToText(product['grade'] as int? ?? 0),
                    const Color(0xFFDC2626),
                  ).animate().fadeIn(duration: 500.ms, delay: 100.ms).scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0)),
                ),
            ],
          ),
        ],
      ),
          ).animate().fadeIn(duration: 600.ms).slide(begin: const Offset(0, 0.2), end: Offset.zero);
  }

  Widget _buildRetailPriceWidget() {
    final wholesalePrice = double.tryParse(product['priceOfItem']?.toString() ?? '0') ?? 0.0;
    final suggestedRetailPrice = double.tryParse(product['suggestedRetailPrice']?.toString() ?? '0') ?? 0.0;
    
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6366F1).withOpacity(0.1),
            const Color(0xFF059669).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          // سعر الجملة (السعر الرئيسي)
          Row(
            children: [
              Icon(
                Icons.price_check,
                color: const Color(0xFF6366F1),
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
        Text(
                'سعر الجملة',
          style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6366F1),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          
          // سعر الجملة الفعلي
          Text(
            '${_formatPrice(wholesalePrice)} د.ع',
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF6366F1),
              letterSpacing: 0.5,
            ),
          ),
          
          SizedBox(height: 16.h),
          
          // خط فاصل
          Container(
            height: 1.h,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  const Color(0xFF6B7280).withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          
          SizedBox(height: 16.h),
          
          // سعر البيع التقريبي
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: const Color(0xFF059669),
                size: 16.sp,
              ),
              SizedBox(width: 6.w),
              Text(
                'سعر البيع التقريبي',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
            color: const Color(0xFF6B7280),
          ),
              ),
            ],
        ),
        SizedBox(height: 4.h),
          
          // السعر التقريبي الفعلي
        Text(
            '${_formatPrice(suggestedRetailPrice)} د.ع',
          style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF059669),
            ),
          ),
          
          // حساب الربح المتوقع
          if (suggestedRetailPrice > wholesalePrice) ...[
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(
                  color: const Color(0xFF059669).withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.attach_money,
                    color: const Color(0xFF059669),
                    size: 12.sp,
                  ),
                  Text(
                    'ربح متوقع: ${_formatPrice(suggestedRetailPrice - wholesalePrice)} د.ع',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
            color: const Color(0xFF059669),
          ),
        ),
      ],
              ),
            ),
          ],
        ],
      ),
         ).animate().fadeIn(duration: 600.ms).slide(begin: const Offset(0, 0.3), end: Offset.zero);
  }

  Widget _buildProductDescription() {
    final description = product['descriptionOfItem']?.toString();
    
    // إذا لم يكن هناك وصف، لا نعرض أي شيء
    if (description == null || description.isEmpty || description.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس القسم
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF8B5CF6),
                  const Color(0xFF7C3AED),
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.r),
                topRight: Radius.circular(20.r),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.article_outlined,
                    color: Colors.white,
                    size: 22.sp,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'وصف المنتج',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'تفاصيل شاملة عن المنتج',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // محتوى الوصف
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // نص الوصف الرئيسي
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(18.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(15.r),
                    border: Border.all(
                      color: const Color(0xFF8B5CF6).withOpacity(0.1),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // أيقونة اقتباس
                      Icon(
                        Icons.format_quote,
                        color: const Color(0xFF8B5CF6).withOpacity(0.6),
                        size: 24.sp,
                      ),
                      SizedBox(height: 12.h),
                      
                      // نص الوصف
                      Text(
                        description.trim(),
                        style: TextStyle(
                          fontSize: 15.sp,
                          height: 1.7,
                          color: const Color(0xFF1F2937),
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 16.h),
                
                // شريط المعلومات الإضافية
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF8B5CF6).withOpacity(0.05),
                        const Color(0xFF7C3AED).withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: const Color(0xFF8B5CF6).withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6.w,
                        height: 6.h,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Icon(
                        Icons.verified_user,
                        size: 16.sp,
                        color: const Color(0xFF8B5CF6),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'معلومات موثقة من البائع المعتمد',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: const Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: 800.ms)
              .slide(begin: const Offset(0, 0.4), end: Offset.zero, curve: Curves.easeOutCubic);
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOriginalProductInfo() {
    // استخدام البيانات المحفوظة مسبقاً بدلاً من FutureBuilder
    if (_isLoadingClassification) {
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 15.r,
              offset: Offset(0, 3.h),
                ),
              ],
            ),
            child: Center(
              child: CircularProgressIndicator(
            color: const Color(0xFF10B981),
              ),
            ),
          );
        }

    final data = _productClassificationData;
        final company = data?['company'];
        final originalProduct = data?['product'];
    final mainCategory = data?['mainCategory'];
    final subCategory = data?['subCategory'];
    
    // التحقق من نوع المنتج (أصلي أو تجاري)
    final itemCondition = product['itemCondition']?.toString().toLowerCase();
    final isOriginalProduct = itemCondition == 'original';

    // إذا لم توجد أي معلومات، لا نعرض الwidget
    if (mainCategory == null && subCategory == null && 
        (!isOriginalProduct || (company == null && originalProduct == null))) {
      return const SizedBox.shrink();
        }

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15.r,
            offset: Offset(0, 3.h),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // رأس القسم
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF10B981),
                  const Color(0xFF059669),
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.r),
                topRight: Radius.circular(20.r),
              ),
            ),
            child: Row(
                children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.verified_outlined,
                    color: Colors.white,
                    size: 22.sp,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                        isOriginalProduct 
                            ? 'معلومات المنتج الأصلي'
                            : 'تصنيف المنتج',
                    style: TextStyle(
                          fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        isOriginalProduct 
                            ? 'تفاصيل الشركة والتصنيف'
                            : 'معلومات التصنيف والقسم',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
                ),
              ],
            ),
          ),
          
          // محتوى المعلومات
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الأقسام (القسم الرئيسي والفرعي)
                if (mainCategory != null || subCategory != null) ...[
                  _buildInfoSection(
                    'التصنيف',
                    Icons.category_outlined,
                    const Color(0xFF6366F1),
                    [
                      if (mainCategory != null)
                        _buildEnhancedInfoItem(
                          'القسم الرئيسي',
                          mainCategory['nameAr'] ?? mainCategory['nameEn'] ?? 'غير محدد',
                          mainCategory['imageUrl'],
                          Icons.folder_outlined,
                          const Color(0xFF6366F1),
                        ),
                      if (subCategory != null)
                        _buildEnhancedInfoItem(
                          'القسم الفرعي',
                          subCategory['nameAr'] ?? subCategory['nameEn'] ?? 'غير محدد',
                          subCategory['imageUrl'],
                          Icons.folder_open_outlined,
                          const Color(0xFF8B5CF6),
                        ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                ],
                
                // معلومات الشركة والمنتج (فقط للمنتجات الأصلية)
                if (isOriginalProduct && (company != null || originalProduct != null)) ...[
                  _buildInfoSection(
                    'معلومات المصدر',
                    Icons.source_outlined,
                    const Color(0xFF10B981),
                    [
                      if (company != null)
                        _buildEnhancedInfoItem(
                  'الشركة المصنعة',
                  company['nameAr'] ?? company['nameEn'] ?? 'غير محدد',
                  company['logoUrl'],
                          Icons.business_outlined,
                          const Color(0xFF10B981),
                        ),
                      if (originalProduct != null)
                        _buildEnhancedInfoItem(
                  'المنتج الأصلي',
                  originalProduct['nameAr'] ?? originalProduct['nameEn'] ?? 'غير محدد',
                  originalProduct['imageUrl'],
                          Icons.inventory_2_outlined,
                          const Color(0xFF059669),
                        ),
                    ],
                ),
              ],
            ],
          ),
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: 900.ms)
      .slide(begin: const Offset(0, 0.3), end: Offset.zero, curve: Curves.easeOutQuart);
  }

  // دالة لبناء قسم معلومات مع عنوان وأيقونة
  Widget _buildInfoSection(String title, IconData icon, Color color, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // عنوان القسم
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: color,
                size: 16.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        
        // عناصر القسم
        ...items.map((item) => Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: item,
        )),
      ],
    );
  }

  // دالة لبناء عنصر معلومات محسن
  Widget _buildEnhancedInfoItem(String title, String value, String? imageUrl, IconData fallbackIcon, Color color) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
      children: [
        // الصورة أو الأيقونة
        Container(
            width: 50.w,
            height: 50.h,
          decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.1),
                  color.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 1,
              ),
          ),
          child: imageUrl != null && imageUrl.isNotEmpty
              ? ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Icon(
                      fallbackIcon,
                        color: color,
                        size: 24.sp,
                    ),
                    errorWidget: (context, url, error) => Icon(
                      fallbackIcon,
                        color: color,
                        size: 24.sp,
                    ),
                  ),
                )
              : Icon(
                  fallbackIcon,
                    color: color,
                    size: 24.sp,
                ),
        ),
          SizedBox(width: 16.w),
          
        // النص
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                ),
              ),
                SizedBox(height: 4.h),
              Text(
                value,
                style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                    height: 1.3,
                ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
          
          // مؤشر بصري
          Container(
            width: 4.w,
            height: 30.h,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: 600.ms, delay: 200.ms)
              .slide(begin: const Offset(0.2, 0), end: Offset.zero);
  }

  Widget _buildSmartPriceAnalysis() {
    // استخراج القيم الأساسية
    final wholesalePrice = double.tryParse(product['priceOfItem']?.toString() ?? '0') ?? 0.0;
    final cartonQuantity = product['cartonQuantity'] as int? ?? 12;
    final suggestedRetailPrice = double.tryParse(product['suggestedRetailPrice']?.toString() ?? '0') ?? (wholesalePrice * 1.25);
    final retailPrice = _customRetailPrice;

    // إجراء الحسابات
    final profitPerPiece = retailPrice - wholesalePrice;
    final roi = (wholesalePrice > 0) ? (profitPerPiece / wholesalePrice) * 100 : 0.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF9FAFB),
            const Color(0xFFF3F4F6),
          ],
        ),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300.withOpacity(0.5),
            blurRadius: 30.r,
            offset: Offset(0, 10.h),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // 1. رأس القسم
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
          Container(
                    padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
                    child: Icon(Icons.insights_rounded, color: const Color(0xFF6366F1), size: 24.sp),
                  ),
                  SizedBox(width: 16.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        "تحليل السعر الذكي",
                      style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                        "حدد سعر البيع لتقدير أرباحك",
                      style: TextStyle(
                          fontSize: 12.sp,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    ],
                    ),
                  ],
                ),
            ),
            
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                children: [
                  // 2. حقل إدخال سعر البيع
                  _buildPriceInputSection(),
                  SizedBox(height: 24.h),

                  // 3. مخطط تحليل الربح
                  _buildProfitAnalysisChart(wholesalePrice, retailPrice, suggestedRetailPrice),
                  SizedBox(height: 24.h),

                  // 4. عرض مقاييس الربحية
                  _buildProfitMetrics(profitPerPiece, cartonQuantity, roi),
              ],
            ),
          ),
        ],
      ),
      ),
    ).animate().fadeIn(duration: 800.ms).slide(begin: const Offset(0, 0.3), end: Offset.zero, curve: Curves.easeOutCubic);
  }

  Widget _buildPriceInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'سعر بيع القطعة للمستهلك',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: const Color(0xFF374151)),
        ),
        SizedBox(height: 12.h),
        TextField(
          controller: _retailPriceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
              style: TextStyle(
            fontSize: 32.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF6366F1),
            letterSpacing: 1.5,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            suffixText: '  د.ع',
            suffixStyle: TextStyle(
              fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              color: const Color(0xFF6366F1).withOpacity(0.7),
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(color: const Color(0xFF6366F1), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfitAnalysisChart(double wholesalePrice, double currentRetailPrice, double suggestedRetailPrice) {
    // تحديد نطاق المحور السيني (السعر)
    final double minPrice = wholesalePrice * 0.8;
    final double maxPrice = suggestedRetailPrice * 1.5;

    // إنشاء نقاط بيانات للمخطط
    final List<FlSpot> spots = [];
    for (double p = minPrice; p <= maxPrice; p += (maxPrice - minPrice) / 10) {
      final profit = p - wholesalePrice;
      spots.add(FlSpot(p, profit));
    }
    
    // تحديد لون الربح
    final profit = currentRetailPrice - wholesalePrice;
    final profitColor = profit > 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return AspectRatio(
      aspectRatio: 1.7,
      child: Stack(
        children: [
          // مخطط الخط البياني الرئيسي
          LineChart(
            LineChartData(
              // إخفاء الحدود والشبكة لجعلها أنظف
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),

              // عناوين المحاور
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 10.sp),
                      );
                    },
                    reservedSize: 35.w,
                  ),
                ),
                bottomTitles: AxisTitles(
                  axisNameWidget: Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: Text("سعر البيع", style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade700)),
                  ),
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value == minPrice || value == maxPrice) {
                        return Text('${(value / 1000).toStringAsFixed(1)}k', style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade600));
                      }
                      return const Text('');
                    },
                    interval: (maxPrice - minPrice) / 4,
                  ),
                ),
              ),
              
              // نطاق المحاور
              minX: minPrice,
              maxX: maxPrice,
              minY: spots.map((s) => s.y).reduce((a, b) => a < b ? a : b),
              maxY: spots.map((s) => s.y).reduce((a, b) => a > b ? a : b),

              // بيانات الخط البياني
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  gradient: LinearGradient(
                    colors: [profitColor.withOpacity(0.5), profitColor],
                  ),
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [profitColor.withOpacity(0.2), profitColor.withOpacity(0.0)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
              
              // خط نقطة التعادل
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: 0,
                    color: Colors.grey.shade400,
                    strokeWidth: 1.5,
                    dashArray: [5, 5],
                    label: HorizontalLineLabel(
                      show: true,
                      labelResolver: (_) => "نقطة التعادل",
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 10.sp),
                      ),
                    ),
                  ],
                ),
            ),
          ),
          
          // مخطط النقاط لتحديد الأسعار المهمة
          ScatterChart(
            ScatterChartData(
              scatterSpots: [
                // نقطة السعر الحالي
                ScatterSpot(
                  currentRetailPrice,
                  currentRetailPrice - wholesalePrice,
                  dotPainter: FlDotCirclePainter(
                    radius: 8,
                    color: Colors.white,
                    strokeColor: profitColor,
                    strokeWidth: 3,
                  ),
                ),
                // نقطة السعر المقترح
                ScatterSpot(
                  suggestedRetailPrice,
                  suggestedRetailPrice - wholesalePrice,
                  dotPainter: FlDotCirclePainter(
                    radius: 5,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
              ],
              minX: minPrice,
              maxX: maxPrice,
              minY: spots.map((s) => s.y).reduce((a, b) => a < b ? a : b),
              maxY: spots.map((s) => s.y).reduce((a, b) => a > b ? a : b),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: const FlTitlesData(show: false),
            ),
          )
        ],
      ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOut)
     );
  }

  Widget _buildProfitMetrics(double profitPerPiece, int cartonQuantity, double roi) {
    final profitPerCarton = profitPerPiece * cartonQuantity;
    final profitColor = profitPerPiece > 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricItem(
            "الربح / قطعة",
            _formatPrice(profitPerPiece),
            "د.ع",
            Icons.monetization_on_outlined,
            profitColor,
          ),
          Container(width: 1.w, height: 50.h, color: Colors.grey.shade200),
          _buildMetricItem(
            "الربح / كارتون",
            _formatPrice(profitPerCarton),
            "د.ع",
            Icons.inventory_2_outlined,
            profitColor,
          ),
          Container(width: 1.w, height: 50.h, color: Colors.grey.shade200),
          _buildMetricItem(
            "العائد (ROI)",
            '${roi.toStringAsFixed(1)}%',
            "",
            Icons.show_chart_outlined,
            profitColor,
              ),
            ],
          ),
    );
  }
          
  Widget _buildMetricItem(String title, String value, String unit, IconData icon, Color color) {
    return Expanded(
      child: Column(
            children: [
          Icon(icon, color: color, size: 24.sp),
          SizedBox(height: 8.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
                color: const Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(animation),
                  child: child,
                ),
              );
            },
            child: Text(
              '$value $unit',
              key: ValueKey<String>(value),
                style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
                ),
              ),
            ],
          ),
    );
  }
  // --- نهاية تحليل السعر الذكي المطور ---



  Widget _buildStoreNavigationButton() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: GestureDetector(
        onTap: () {
          // الانتقال إلى صفحة المتجر مع تمرير بيانات المتجر
          Get.to(
            () =>  StoreProductsPage(),
            arguments: {
              'store': store,
              'showStoreDetails': true, // فلاج لإظهار معلومات المتجر
            },
            transition: Transition.rightToLeftWithFade,
            duration: const Duration(milliseconds: 300),
          );
        },
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6366F1),
                Color(0xFF8B5CF6),
              ],
            ),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.3),
                blurRadius: 15.r,
                offset: Offset(0, 6.h),
              ),
              BoxShadow(
                color: const Color(0xFF8B5CF6).withOpacity(0.2),
                blurRadius: 25.r,
                offset: Offset(0, 10.h),
                ),
              ],
            ),
          child: Row(
            children: [
              // صورة/أيقونة المتجر
          Container(
                width: 50.w,
                height: 50.h,
            decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2.w,
                  ),
                ),
                child: Icon(
                  Icons.storefront_rounded,
                  color: Colors.white,
                  size: 26.sp,
                ),
              ).animate().scale(duration: 600.ms, delay: 200.ms),
              
              SizedBox(width: 16.w),
              
              // معلومات المتجر الأساسية
              Expanded(
            child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                    // اسم المتجر
                    Text(
                      store.sellerName ?? 'متجر تجاري',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ).animate().fadeIn(duration: 500.ms, delay: 300.ms).slide(begin: const Offset(0.3, 0)),
                    
                    SizedBox(height: 6.h),
                    
                    // نص التوجيه
                Row(
                  children: [
                    Icon(
                          Icons.touch_app_rounded,
                          color: Colors.white.withOpacity(0.8),
                      size: 14.sp,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                          'اضغط لعرض تفاصيل المتجر',
                      style: TextStyle(
                        fontSize: 12.sp,
                            color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                    ).animate().fadeIn(duration: 500.ms, delay: 400.ms),
              ],
            ),
          ),
              
              // أيقونة السهم للانتقال
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 16.sp,
                ),
              ).animate().fadeIn(duration: 600.ms, delay: 500.ms).scale(begin: const Offset(0.8, 0.8)),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildBottomCartBar() {
    return GetBuilder<RetailCartController>(
      builder: (controller) {
        final productId = product['id']?.toString() ?? '';
        final quantity = product['quantity'] as int? ?? 0;
        final quantityPerCarton = product['quantityPerCarton'] as int?; // كمية المنتج في الكارتونة الواحدة
        final wholesalePrice = double.tryParse(product['priceOfItem']?.toString() ?? '0') ?? 0.0;
        
        final cartQuantity = cartController.getProductQuantity(productId);
        final isInCart = cartQuantity > 0;
        final availableQuantity = quantity - cartQuantity; // الكمية المتاحة للإضافة
        final canAddToCart = availableQuantity > 0;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12.r),
              topRight: Radius.circular(12.r),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12.r,
                offset: Offset(0, -2.h),
              ),
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.05),
                blurRadius: 25.r,
                offset: Offset(0, -5.h),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(10.w, 10.h, 10.w, 5.h),
          child: Column(
                mainAxisSize: MainAxisSize.min,
            children: [
                  // مؤشر التمرير
              Container(
                    width: 20.w,
                    height: 2.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(1.r),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  
                  // معلومات السعر والكمية
                  Container(
                    padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF6366F1).withOpacity(0.08),
                          const Color(0xFF8B5CF6).withOpacity(0.03),
                        ],
                  ),
                      borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                        color: const Color(0xFF6366F1).withOpacity(0.15),
                        width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                        // معلومات السعر
                        Expanded(
                          flex: 2,
                          child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(3.w),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6366F1).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4.r),
                                    ),
                                    child: Icon(
                                      Icons.price_check,
                                      color: const Color(0xFF6366F1),
                                      size: 8.sp,
                                    ),
                                  ),
                                  SizedBox(width: 4.w),
                        Text(
                                    'سعر الجملة',
                          style: TextStyle(
                                      fontSize: 6.sp,
                            color: const Color(0xFF6B7280),
                                      fontWeight: FontWeight.w500,
                          ),
                        ),
                                ],
                              ),
                              SizedBox(height: 3.h),
                        Text(
                                '${_formatPrice(wholesalePrice)} د.ع',
                          style: TextStyle(
                                  fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF6366F1),
                          ),
                        ),
                      ],
                    ),
                        ),
                        
                        // معلومات الكمية
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // عرض حالة المنتج في السلة
                              if (isInCart) ...[
                      Container(
                                  padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669),
                                    borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                                    'في السلة: $cartQuantity',
                          style: TextStyle(
                                      fontSize: 5.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                                SizedBox(height: 3.h),
                              ],
                              
                              // عرض الكمية المتوفرة دائماً
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Icon(
                                    Icons.inventory,
                                    size: 6.sp,
                                    color: availableQuantity > 0 
                                        ? const Color(0xFF059669) 
                                        : const Color(0xFFEF4444),
                                  ),
                                  SizedBox(width: 2.w),
                                  Text(
                                    'متوفر',
                                    style: TextStyle(
                                      fontSize: 5.sp,
                                      color: const Color(0xFF6B7280),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 1.h),
                              Text(
                                '$availableQuantity قطعة',
                                style: TextStyle(
                                  fontSize: 8.sp,
                                  fontWeight: FontWeight.bold,
                                  color: availableQuantity > 0 
                                      ? const Color(0xFF059669) 
                                      : const Color(0xFFEF4444),
                                ),
                              ),
                              
                              // إجمالي المخزون
                              SizedBox(height: 2.h),
                              Text(
                                'من أصل $quantity',
                                style: TextStyle(
                                  fontSize: 4.sp,
                                  color: const Color(0xFF9CA3AF),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // معلومات كارتونة quantityPerCarton (إذا كانت متوفرة)
                  if (quantityPerCarton != null && quantityPerCarton > 0) ...[
                    SizedBox(height: 6.h),
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF059669).withOpacity(0.08),
                            const Color(0xFF047857).withOpacity(0.03),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: const Color(0xFF059669).withOpacity(0.15),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                children: [
                          // أيقونة الكارتونة
                          Container(
                            padding: EdgeInsets.all(4.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Icon(
                              Icons.inventory_2,
                              color: const Color(0xFF059669),
                              size: 10.sp,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          
                          // معلومات الكارتونة
                  Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'كارتونة خاصة',
                                  style: TextStyle(
                                    fontSize: 6.sp,
                                    color: const Color(0xFF6B7280),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  '$quantityPerCarton قطعة',
                                  style: TextStyle(
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF059669),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // زر إضافة كارتونة خاصة
                          if (isInCart) ...[
                            GestureDetector(
                              onTap: (availableQuantity >= quantityPerCarton) 
                                  ? () => _addSpecialCarton(quantityPerCarton) 
                                  : null,
                    child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: (availableQuantity >= quantityPerCarton) 
                                      ? const Color(0xFF059669) 
                                      : Colors.grey[400],
                                  borderRadius: BorderRadius.circular(6.r),
                                  boxShadow: (availableQuantity >= quantityPerCarton)
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF059669).withOpacity(0.2),
                                            blurRadius: 4.r,
                                            offset: Offset(0, 1.h),
                                          ),
                                        ]
                                      : null,
                        ),
                        child: Row(
                                  mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 8.sp,
                            ),
                                    SizedBox(width: 2.w),
                            Text(
                                      'أضف',
                              style: TextStyle(
                                        fontSize: 7.sp,
                                fontWeight: FontWeight.w600,
                                        color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  
                  // تحذير عندما تكون الكمية المتوفرة قليلة
                  if (availableQuantity > 0 && availableQuantity <= 5) ...[
                    SizedBox(height: 6.h),
                    Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6.r),
                        border: Border.all(
                          color: const Color(0xFFFBBF24),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: const Color(0xFFD97706),
                            size: 8.sp,
                          ),
                          SizedBox(width: 4.w),
                  Expanded(
                            child: Text(
                              'تحذير: كمية قليلة متبقية ($availableQuantity قطعة فقط)',
                              style: TextStyle(
                                fontSize: 6.sp,
                                color: const Color(0xFFD97706),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  // تحذير عندما تنفد الكمية
                  if (availableQuantity <= 0) ...[
                    SizedBox(height: 6.h),
                    Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(6.r),
                        border: Border.all(
                          color: const Color(0xFFFECACA),
                          width: 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                            Icons.error_outline,
                            color: const Color(0xFFEF4444),
                            size: 8.sp,
                            ),
                          SizedBox(width: 4.w),
                          Expanded(
                              child: Text(
                              'نفدت الكمية - لا يمكن إضافة المزيد للسلة',
                                style: TextStyle(
                                fontSize: 6.sp,
                                color: const Color(0xFFEF4444),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  
                  SizedBox(height: 8.h),
                  
                  // أزرار التحكم
                  if (isInCart) ...[
                    // أزرار التحكم في الكمية للمنتجات الموجودة في السلة
                    Row(
                      children: [
                        // زر تقليل الكمية
                        GestureDetector(
                          onTap: () => _decreaseQuantity(productId, cartQuantity),
                          child: Container(
                            width: 22.w,
                            height: 22.h,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFEF4444),
                                  const Color(0xFFDC2626),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(6.r),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEF4444).withOpacity(0.2),
                                  blurRadius: 4.r,
                                  offset: Offset(0, 1.h),
                                ),
                              ],
                            ),
                            child: Icon(
                              cartQuantity > 1 ? Icons.remove : Icons.delete_outline,
                              color: Colors.white,
                              size: 10.sp,
                            ),
                          ),
                        ),
                        
                        // عرض الكمية الحالية
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 6.w),
                            padding: EdgeInsets.symmetric(vertical: 6.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                                width: 0.5,
                    ),
                  ),
                            child: Column(
                    children: [
                      Text(
                                  'الكمية',
                        style: TextStyle(
                                    fontSize: 5.sp,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                                Text(
                                  '$cartQuantity',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1F2937),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // زر زيادة الكمية
                        GestureDetector(
                          onTap: canAddToCart ? () => _increaseQuantity(productId, cartQuantity) : null,
                          child: Container(
                            width: 22.w,
                            height: 22.h,
                            decoration: BoxDecoration(
                              gradient: canAddToCart
                                  ? LinearGradient(
                                      colors: [
                                        const Color(0xFF059669),
                                        const Color(0xFF047857),
                                      ],
                                    )
                                  : LinearGradient(
                                      colors: [
                                        Colors.grey[300]!,
                                        Colors.grey[400]!,
                                      ],
                                    ),
                              borderRadius: BorderRadius.circular(6.r),
                              boxShadow: canAddToCart
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF059669).withOpacity(0.3),
                                        blurRadius: 4.r,
                                        offset: Offset(0, 1.h),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 10.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 6.h),
                    
                    // معلومات الإجمالي المحسن
                          Container(
                      padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF059669).withOpacity(0.15),
                            const Color(0xFF047857).withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: const Color(0xFF059669).withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF059669).withOpacity(0.1),
                            blurRadius: 8.r,
                            offset: Offset(0, 2.h),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(4.w),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF059669),
                                      borderRadius: BorderRadius.circular(6.r),
                                    ),
                                    child: Icon(
                                      Icons.shopping_cart_checkout,
                              color: Colors.white,
                                      size: 8.sp,
                                    ),
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    'الإجمالي',
                                    style: TextStyle(
                                      fontSize: 7.sp,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF059669),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF059669),
                                      const Color(0xFF047857),
                                    ],
                                  ),
                              borderRadius: BorderRadius.circular(8.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF059669).withOpacity(0.3),
                                      blurRadius: 4.r,
                                      offset: Offset(0, 1.h),
                                    ),
                                  ],
                            ),
                            child: Text(
                                  '${_formatPrice(wholesalePrice * cartQuantity)} د.ع',
                              style: TextStyle(
                                    fontSize: 8.sp,
                                fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ).animate()
                                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0), duration: 300.ms, curve: Curves.elasticOut)
                                .shimmer(duration: 1000.ms, color: Colors.white.withOpacity(0.5)),
                            ],
                          ),
                          SizedBox(height: 6.h),
                          // زر الذهاب للسلة
                          GestureDetector(
                            onTap: () async {
                              try {
                                // التأكد من أن المستخدم مسجل دخوله
                                if (FirebaseAuth.instance.currentUser == null) {
                                  Get.snackbar(
                                    'خطأ',
                                    'يجب تسجيل الدخول أولاً',
                                    backgroundColor: Colors.red.withOpacity(0.1),
                                    colorText: Colors.red,
                                  );
                                  return;
                                }
                                
                                // التأكد من وجود عناصر في السلة
                                final hasItems = cartController.storesCarts.values
                                    .any((storeCart) => storeCart.isNotEmpty);
                                if (!hasItems) {
                                  Get.snackbar(
                                    'السلة فارغة',
                                    'لا توجد منتجات في السلة',
                                    backgroundColor: Colors.orange.withOpacity(0.1),
                                    colorText: Colors.orange,
                                  );
                                  return;
                                }
                                
                                // الانتقال للسلة
                                try {
                                  await Get.toNamed('/retail-cart');
                                } catch (routeError) {
                                  debugPrint('خطأ في المسار، محاولة انتقال مباشر: $routeError');
                                  // حل بديل: الانتقال المباشر للصفحة
                                  Get.to(() => const RetailCartPage(), binding: BindingsBuilder(() {
                                    Get.lazyPut<RetailCartController>(() => RetailCartController());
                                  }));
                                }
                              } catch (e) {
                                debugPrint('خطأ في الانتقال للسلة: $e');
                                Get.snackbar(
                                  'خطأ',
                                  'حدث خطأ أثناء فتح السلة',
                                  backgroundColor: Colors.red.withOpacity(0.1),
                                  colorText: Colors.red,
                                );
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(vertical: 8.h),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    const Color(0xFF6366F1),
                                    const Color(0xFF8B5CF6),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6366F1).withOpacity(0.4),
                                    blurRadius: 8.r,
                                    offset: Offset(0, 2.h),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.shopping_cart,
                                    color: Colors.white,
                                    size: 8.sp,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    'الذهاب للسلة',
                                    style: TextStyle(
                                      fontSize: 8.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                      ),
                    ],
                  ),
                ),
                          ).animate()
                            .slide(begin: const Offset(0.3, 0), end: Offset.zero, duration: 400.ms)
                            .fadeIn(duration: 300.ms),
                        ],
                      ),
                    )


                  ] else ...[
                    // أزرار الإضافة للمنتجات الجديدة
                    Column(
                      children: [
                        Row(
                          children: [
                            // زر إضافة قطعة واحدة
                            Expanded(
                              child: GestureDetector(
                                onTap: canAddToCart ? () => _addSingleItem() : null,
                                child: Container(
                                  height: 25.h,
                                  decoration: BoxDecoration(
                                    gradient: canAddToCart
                                        ? LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              const Color(0xFF6366F1),
                                              const Color(0xFF8B5CF6),
                                            ],
                                          )
                                        : LinearGradient(
                                            colors: [
                                              Colors.grey[300]!,
                                              Colors.grey[400]!,
                                            ],
                                          ),
                                    borderRadius: BorderRadius.circular(7.r),
                                    boxShadow: canAddToCart
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFF6366F1).withOpacity(0.3),
                                              blurRadius: 7.r,
                                              offset: Offset(0, 2.h),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_shopping_cart,
                                        color: Colors.white,
                                        size: 10.sp,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        'أضف للسلة',
                                        style: TextStyle(
                                          fontSize: 8.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            
                            // زر إضافة كارتونة خاصة (إذا كانت متوفرة)
                            if (quantityPerCarton != null && quantityPerCarton > 0) ...[
                              SizedBox(width: 6.w),
                              Expanded(
                                                              child: GestureDetector(
                                onTap: (availableQuantity >= quantityPerCarton) ? () => _addSpecialCarton(quantityPerCarton) : null,
                                  child: Container(
                                    height: 25.h,
                                    decoration: BoxDecoration(
                                      gradient: (availableQuantity >= quantityPerCarton)
                                          ? LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                const Color(0xFF10B981),
                                                const Color(0xFF059669),
                                              ],
                                            )
                                          : LinearGradient(
                                              colors: [
                                                Colors.grey[200]!,
                                                Colors.grey[300]!,
                                              ],
                                            ),
                                      borderRadius: BorderRadius.circular(7.r),
                                      border: Border.all(
                                        color: (availableQuantity >= quantityPerCarton)
                                            ? const Color(0xFF10B981).withOpacity(0.3)
                                            : Colors.grey[400]!,
                                        width: 0.5,
                                      ),
                                      boxShadow: (availableQuantity >= quantityPerCarton)
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFF10B981).withOpacity(0.2),
                                                blurRadius: 5.r,
                                                offset: Offset(0, 1.h),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_box,
                                          color: (availableQuantity >= quantityPerCarton) ? Colors.white : Colors.grey[600],
                                          size: 9.sp,
                                        ),
                                        SizedBox(width: 3.w),
                                        Text(
                                          'كارتونة ($quantityPerCarton)',
                                          style: TextStyle(
                                            fontSize: 7.sp,
                                            fontWeight: FontWeight.bold,
                                            color: (availableQuantity >= quantityPerCarton) ? Colors.white : Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
              
              // رسالة عدم توفر كمية كافية
                    if (!canAddToCart) ...[
                      SizedBox(height: 6.h),
                Container(
                        padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(
                            color: const Color(0xFFFECACA),
                            width: 0.5,
                          ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                              Icons.warning_amber_rounded,
                        color: const Color(0xFFEF4444),
                              size: 8.sp,
                            ),
                            SizedBox(width: 4.w),
                            Expanded(
                              child: Text(
                                'الكمية المتاحة: $quantity قطعة فقط',
                        style: TextStyle(
                                  fontSize: 6.sp,
                          color: const Color(0xFFEF4444),
                          fontWeight: FontWeight.w500,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ).animate()
          .slide(begin: const Offset(0, 1), end: Offset.zero, duration: const Duration(milliseconds: 600), curve: Curves.easeOutCubic)
          .fadeIn(duration: const Duration(milliseconds: 400));
      },
    );
  }

  // دوال التحكم في السلة مع إزالة Get.snackbar من إضافة الكارتونة الكاملة
  void _addSingleItem() {
    final productId = product['id']?.toString() ?? '';
    final currentQuantity = cartController.getProductQuantity(productId);
    final totalQuantity = product['quantity'] as int? ?? 0;
    final availableQuantity = totalQuantity - currentQuantity;
    
    // التحقق من توفر قطعة واحدة على الأقل
    if (availableQuantity < 1) {
      Get.snackbar(
        'نفدت الكمية',
        'لا توجد كمية متوفرة لإضافتها للسلة',
        backgroundColor: const Color(0xFFEF4444).withOpacity(0.1),
        colorText: const Color(0xFFEF4444),
        icon: const Icon(Icons.warning_amber, color: Color(0xFFEF4444)),
        duration: const Duration(seconds: 2),
      );
      return;
    }
    
    if (mounted) {
      // إضافة قطعة واحدة للسلة
      cartController.addToCart(product, store, quantity: 1);
      cartController.update();
      setState(() {});
    }
  }

  // دالة إضافة كارتونة خاصة بناءً على quantityPerCarton
  void _addSpecialCarton(int quantityPerCarton) {
    final productId = product['id']?.toString() ?? '';
    final currentQuantity = cartController.getProductQuantity(productId);
    final totalQuantity = product['quantity'] as int? ?? 0;
    final availableQuantity = totalQuantity - currentQuantity;
    
    // التحقق من توفر الكمية المطلوبة
    if (quantityPerCarton > availableQuantity) {
      Get.snackbar(
        'كمية غير متوفرة',
        'الكمية المطلوبة ($quantityPerCarton) أكبر من المتوفر ($availableQuantity قطعة)',
        backgroundColor: const Color(0xFFEF4444).withOpacity(0.1),
        colorText: const Color(0xFFEF4444),
        icon: const Icon(Icons.warning_amber, color: Color(0xFFEF4444)),
        duration: const Duration(seconds: 3),
      );
      return;
    }
    
    if (currentQuantity > 0) {
      // إذا كان المنتج موجود في السلة، أضف الكمية الجديدة
      cartController.updateQuantity(productId, currentQuantity + quantityPerCarton);
    } else {
      // إذا لم يكن المنتج في السلة، أضفه بالكمية المحددة
      cartController.addToCart(product, store, quantity: quantityPerCarton);
    }
    
    cartController.update();
    if (mounted) {
      setState(() {});
    }
    
    // رسالة تأكيد
    Get.snackbar(
      'تمت الإضافة',
      'تم إضافة كارتونة خاصة ($quantityPerCarton قطعة) للسلة',
      backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
      colorText: const Color(0xFF10B981),
      icon: const Icon(Icons.add_box, color: Color(0xFF10B981)),
      duration: const Duration(seconds: 2),
    );
  }

  void _increaseQuantity(String productId, int currentQuantity) {
    cartController.updateQuantity(productId, currentQuantity + 1);
    // تحديث المتحكم والواجهة
    cartController.update();
    if (mounted) {
      setState(() {});
    }
  }

  void _decreaseQuantity(String productId, int currentQuantity) {
    if (currentQuantity > 1) {
      cartController.updateQuantity(productId, currentQuantity - 1);
    } else {
      cartController.removeFromCart(productId);
    }
    // تحديث المتحكم والواجهة
    cartController.update();
    if (mounted) {
      setState(() {});
    }
  }

  // الحصول على فئات المنتج للعرض
  String _getProductCategories() {
    final mainCategoryAr = product['selectedMainCategoryNameAr'] ?? product['mainCategoryNameAr'];
    final subCategoryAr = product['selectedSubCategoryNameAr'] ?? product['subCategoryNameAr'];
    
    if (mainCategoryAr != null && subCategoryAr != null) {
      return '$mainCategoryAr > $subCategoryAr';
    } else if (mainCategoryAr != null) {
      return mainCategoryAr;
    } else if (subCategoryAr != null) {
      return subCategoryAr;
    }
    
    return 'غير محدد';
  }

  // --== Load Product Classification Data Once ==--
  void _loadProductClassificationData() async {
    try {
      final data = await _getOriginalProductInfo();
      setState(() {
        _productClassificationData = data;
        _isLoadingClassification = false;
      });
    } catch (e) {
      debugPrint('❌ خطأ في تحميل بيانات التصنيف: $e');
      setState(() {
        _isLoadingClassification = false;
      });
    }
  }

  // دالة لجلب معلومات الشركة المصنعة والمنتج الأصلي والأقسام (للتحميل الأولي فقط)
  Future<Map<String, dynamic>> _getOriginalProductInfo() async {
    try {
      final originalCompanyId = product['originalCompanyId']?.toString();
      final originalProductId = product['originalProductId']?.toString();
      final mainCategoryId = product['mainCategoryId']?.toString();
      final subCategoryId = product['subCategoryId']?.toString();
      
      // التحقق من نوع المنتج
      final itemCondition = product['itemCondition']?.toString().toLowerCase();
      final isOriginalProduct = itemCondition == 'original';
      
      debugPrint('🔍 البحث عن معلومات المنتج الشاملة:');
      debugPrint('   نوع المنتج: ${isOriginalProduct ? 'أصلي' : 'تجاري'}');
      debugPrint('   originalCompanyId: $originalCompanyId');
      debugPrint('   originalProductId: $originalProductId');
      debugPrint('   mainCategoryId: $mainCategoryId');
      debugPrint('   subCategoryId: $subCategoryId');

      // جلب معلومات الشركة من مجموعة brand_companies (فقط للمنتجات الأصلية)
      Map<String, dynamic>? companyInfo;
      if (isOriginalProduct && originalCompanyId != null) {
        try {
          debugPrint('🏢 جلب معلومات الشركة من brand_companies...');
          final companyDoc = await FirebaseFirestore.instance
              .collection('brand_companies')
              .doc(originalCompanyId)
              .get();
          if (companyDoc.exists) {
            final data = companyDoc.data();
            companyInfo = {
              'nameAr': data?['nameAr'],
              'nameEn': data?['nameEn'],
              'logoUrl': data?['logoUrl'],
            };
            debugPrint('✅ تم العثور على الشركة: ${companyInfo['nameAr']} / ${companyInfo['nameEn']}');
          } else {
            debugPrint('❌ لم يتم العثور على الشركة بالمعرف: $originalCompanyId');
          }
        } catch (e) {
          debugPrint('❌ خطأ في جلب معلومات الشركة: $e');
        }
      }

      // جلب معلومات المنتج الأصلي من مجموعة company_products (فقط للمنتجات الأصلية)
      Map<String, dynamic>? productInfo;
      if (isOriginalProduct && originalProductId != null) {
        try {
          debugPrint('📦 جلب معلومات المنتج من company_products...');
          final productDoc = await FirebaseFirestore.instance
              .collection('company_products')
              .doc(originalProductId)
              .get();
          if (productDoc.exists) {
            final data = productDoc.data();
            productInfo = {
              'nameAr': data?['nameAr'],
              'nameEn': data?['nameEn'],
              'imageUrl': data?['imageUrl'],
            };
            debugPrint('✅ تم العثور على المنتج: ${productInfo['nameAr']} / ${productInfo['nameEn']}');
          } else {
            debugPrint('❌ لم يتم العثور على المنتج بالمعرف: $originalProductId');
          }
        } catch (e) {
          debugPrint('❌ خطأ في جلب معلومات المنتج الأصلي: $e');
        }
      }

      // جلب معلومات القسم الرئيسي من مجموعة categories
      Map<String, dynamic>? mainCategoryInfo;
      if (mainCategoryId != null) {
        try {
          debugPrint('📂 جلب معلومات القسم الرئيسي من categories...');
          final mainCategoryDoc = await FirebaseFirestore.instance
              .collection('categories')
              .doc(mainCategoryId)
              .get();
          if (mainCategoryDoc.exists) {
            final data = mainCategoryDoc.data();
            mainCategoryInfo = {
              'nameAr': data?['nameAr'],
              'nameEn': data?['nameEn'],
              'imageUrl': data?['imageUrl'],
              'iconData': data?['iconData'],
            };
            debugPrint('✅ تم العثور على القسم الرئيسي: ${mainCategoryInfo['nameAr']} / ${mainCategoryInfo['nameEn']}');
          } else {
            debugPrint('❌ لم يتم العثور على القسم الرئيسي بالمعرف: $mainCategoryId');
          }
        } catch (e) {
          debugPrint('❌ خطأ في جلب معلومات القسم الرئيسي: $e');
        }
      }

      // جلب معلومات القسم الفرعي من مجموعة categories
      Map<String, dynamic>? subCategoryInfo;
      if (subCategoryId != null) {
        try {
          debugPrint('📁 جلب معلومات القسم الفرعي من categories...');
          final subCategoryDoc = await FirebaseFirestore.instance
              .collection('categories')
              .doc(subCategoryId)
              .get();
          if (subCategoryDoc.exists) {
            final data = subCategoryDoc.data();
            subCategoryInfo = {
              'nameAr': data?['nameAr'],
              'nameEn': data?['nameEn'],
              'imageUrl': data?['imageUrl'],
              'iconData': data?['iconData'],
            };
            debugPrint('✅ تم العثور على القسم الفرعي: ${subCategoryInfo['nameAr']} / ${subCategoryInfo['nameEn']}');
          } else {
            debugPrint('❌ لم يتم العثور على القسم الفرعي بالمعرف: $subCategoryId');
          }
        } catch (e) {
          debugPrint('❌ خطأ في جلب معلومات القسم الفرعي: $e');
        }
      }

      debugPrint('📋 النتيجة النهائية:');
      if (isOriginalProduct) {
        debugPrint('   الشركة: ${companyInfo?['nameAr']} / ${companyInfo?['nameEn']}');
        debugPrint('   المنتج: ${productInfo?['nameAr']} / ${productInfo?['nameEn']}');
      } else {
        debugPrint('   منتج تجاري - لا توجد معلومات شركة أو منتج أصلي');
      }
      debugPrint('   القسم الرئيسي: ${mainCategoryInfo?['nameAr']} / ${mainCategoryInfo?['nameEn']}');
      debugPrint('   القسم الفرعي: ${subCategoryInfo?['nameAr']} / ${subCategoryInfo?['nameEn']}');

      return {
        'company': companyInfo,
        'product': productInfo,
        'mainCategory': mainCategoryInfo,
        'subCategory': subCategoryInfo,
      };
    } catch (e) {
      debugPrint('❌ خطأ عام في جلب معلومات المنتج الشاملة: $e');
      return {
        'company': null,
        'product': null,
        'mainCategory': null,
        'subCategory': null,
      };
    }
  }

  // دالة لبناء قسم معلومات مع عنوان وأيقونة
}