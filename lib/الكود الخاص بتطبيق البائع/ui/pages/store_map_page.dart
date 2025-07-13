import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../../../Model/SellerModel.dart';

class StoreMapPage extends StatefulWidget {
  const StoreMapPage({super.key});

  @override
  State<StoreMapPage> createState() => _StoreMapPageState();
}

class _StoreMapPageState extends State<StoreMapPage>
    with TickerProviderStateMixin {
  late GoogleMapController _mapController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // بيانات المتجر
  late SellerModel store;
  late GeoPoint location;
  late LatLng storeLocation;
  
  // حالة الخريطة
  bool _isMapReady = false;
  MapType _currentMapType = MapType.normal;
  Set<Marker> _markers = {};
  
  @override
  void initState() {
    super.initState();
    
    // الحصول على البيانات المرسلة
    final arguments = Get.arguments as Map<String, dynamic>;
    store = arguments['store'] as SellerModel;
    location = store.location;
    storeLocation = LatLng(location.latitude, location.longitude);
    
    // إعداد الأنيميشن
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _setupMarkers();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// إعداد العلامات على الخريطة
  void _setupMarkers() {
    _markers = {
      Marker(
        markerId: const MarkerId('store_location'),
        position: storeLocation,
        infoWindow: InfoWindow(
          title: store.shopName,
          snippet: 'اضغط لعرض التفاصيل',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        onTap: () => _showStoreInfoBottomSheet(),
      ),
    };
  }

  /// عند تجهيز الخريطة
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    setState(() {
      _isMapReady = true;
    });
    
    // تحريك الكاميرا إلى موقع المتجر
    _mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: storeLocation,
          zoom: 16.0,
          tilt: 45.0,
        ),
      ),
    );
  }

  /// تغيير نوع الخريطة
  void _changeMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal 
          ? MapType.satellite 
          : MapType.normal;
    });
  }

  /// عرض معلومات المتجر في Bottom Sheet
  void _showStoreInfoBottomSheet() {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25.r),
            topRight: Radius.circular(25.r),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // مقبض السحب
            Container(
              margin: EdgeInsets.only(top: 10.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            
            SizedBox(height: 20.h),
            
            // معلومات المتجر
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // اسم المتجر
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(
                          Icons.store_rounded,
                          color: Colors.white,
                          size: 20.sp,
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
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                            Text(
                              'متجر ${store.sellerType ?? "تجاري"}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 20.h),
                  
                  // الموقع
                  _buildInfoItem(
                    icon: Icons.location_on_rounded,
                    title: 'الموقع',
                    value: store.shopAddressText ?? 'غير محدد',
                    color: const Color(0xFF10B981),
                  ),
                  
                  SizedBox(height: 12.h),
                  
                  // رقم الهاتف
                  _buildInfoItem(
                    icon: Icons.phone_rounded,
                    title: 'رقم الهاتف',
                    value: store.shopPhoneNumber,
                    color: const Color(0xFF3B82F6),
                    isClickable: true,
                    onTap: () => _makePhoneCall(store.shopPhoneNumber),
                  ),
                  
                  SizedBox(height: 12.h),
                  
                  // التقييم
                  _buildInfoItem(
                    icon: Icons.star_rounded,
                    title: 'التقييم',
                    value: '${store.averageRating.toStringAsFixed(1)} نجمة',
                    color: const Color(0xFFF59E0B),
                  ),
                  
                  SizedBox(height: 20.h),
                  
                  // أزرار الإجراءات
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          title: 'الاتجاهات',
                          icon: Icons.directions_rounded,
                          color: const Color(0xFF6366F1),
                          onTap: () => _getDirections(),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildActionButton(
                          title: 'مشاركة',
                          icon: Icons.share_rounded,
                          color: const Color(0xFF10B981),
                          onTap: () => _shareLocation(),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  /// عنصر معلومات في Bottom Sheet
  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    bool isClickable = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: isClickable ? onTap : null,
      child: Container(
        padding: EdgeInsets.all(12.w),
                 decoration: BoxDecoration(
           color: color.withValues(alpha: 0.1),
           borderRadius: BorderRadius.circular(10.r),
           border: isClickable ? Border.all(
             color: color.withValues(alpha: 0.3),
             width: 1.w,
           ) : null,
         ),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 18.sp,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
            ),
            if (isClickable)
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: color,
                size: 14.sp,
              ),
          ],
        ),
      ),
    );
  }

  /// زر إجراء في Bottom Sheet
  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.8)],
          ),
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 16.sp,
            ),
            SizedBox(width: 6.w),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// الاتصال بالمتجر
  void _makePhoneCall(String phoneNumber) {
    // TODO: إضافة منطق الاتصال
    HapticFeedback.lightImpact();
    Get.snackbar(
      'الاتصال',
      'سيتم الاتصال بـ $phoneNumber',
      backgroundColor: const Color(0xFF3B82F6),
      colorText: Colors.white,
      icon: Icon(Icons.phone_rounded, color: Colors.white),
    );
  }

  /// الحصول على الاتجاهات
  void _getDirections() {
    // TODO: إضافة منطق الاتجاهات
    HapticFeedback.lightImpact();
    Get.snackbar(
      'الاتجاهات',
      'سيتم فتح الاتجاهات في خرائط جوجل',
      backgroundColor: const Color(0xFF6366F1),
      colorText: Colors.white,
      icon: Icon(Icons.directions_rounded, color: Colors.white),
    );
  }

  /// مشاركة الموقع
  void _shareLocation() {
    // TODO: إضافة منطق المشاركة
    HapticFeedback.lightImpact();
    Get.snackbar(
      'مشاركة الموقع',
      'سيتم مشاركة موقع المتجر',
      backgroundColor: const Color(0xFF10B981),
      colorText: Colors.white,
      icon: Icon(Icons.share_rounded, color: Colors.white),
    );
  }

  /// نسخ الإحداثيات
  void _copyCoordinates() {
    final coordinates = '${location.latitude}, ${location.longitude}';
    Clipboard.setData(ClipboardData(text: coordinates));
    
    HapticFeedback.lightImpact();
    Get.snackbar(
      'تم النسخ',
      'تم نسخ الإحداثيات إلى الحافظة',
      backgroundColor: const Color(0xFF059669),
      colorText: Colors.white,
      icon: Icon(Icons.check_circle_rounded, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10.r,
                offset: Offset(0, 2.h),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: const Color(0xFF1F2937),
              size: 20.sp,
            ),
            onPressed: () => Get.back(),
          ),
        ),
        title: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
                           boxShadow: [
               BoxShadow(
                 color: Colors.black.withValues(alpha: 0.1),
                 blurRadius: 10.r,
                 offset: Offset(0, 2.h),
               ),
             ],
           ),
           child: Text(
             store.shopName,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
                         boxShadow: [
             BoxShadow(
               color: Colors.black.withValues(alpha: 0.1),
               blurRadius: 10.r,
               offset: Offset(0, 2.h),
             ),
           ],
         ),
         child: IconButton(
           icon: Icon(
             _currentMapType == MapType.normal 
                 ? Icons.satellite_rounded 
                 : Icons.map_rounded,
                color: const Color(0xFF1F2937),
                size: 20.sp,
              ),
              onPressed: _changeMapType,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // الخريطة
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: storeLocation,
              zoom: 15.0,
            ),
            mapType: _currentMapType,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            buildingsEnabled: true,
            trafficEnabled: false,
          ),
          
          // أزرار التحكم السفلية
          Positioned(
            bottom: 30.h,
            left: 20.w,
            right: 20.w,
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Row(
                  children: [
                    // زر معلومات المتجر
                    Expanded(
                      child: _buildFloatingButton(
                        title: 'معلومات المتجر',
                        icon: Icons.info_rounded,
                        color: const Color(0xFF6366F1),
                        onTap: _showStoreInfoBottomSheet,
                      ),
                    ),
                    
                    SizedBox(width: 12.w),
                    
                    // زر نسخ الإحداثيات
                    _buildFloatingIconButton(
                      icon: Icons.copy_rounded,
                      color: const Color(0xFF10B981),
                      onTap: _copyCoordinates,
                    ),
                    
                    SizedBox(width: 8.w),
                    
                    // زر الموقع الحالي
                    _buildFloatingIconButton(
                      icon: Icons.my_location_rounded,
                      color: const Color(0xFF3B82F6),
                      onTap: () {
                        if (_isMapReady) {
                          _mapController.animateCamera(
                            CameraUpdate.newCameraPosition(
                              CameraPosition(
                                target: storeLocation,
                                zoom: 18.0,
                                tilt: 45.0,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// زر عائم مع نص
  Widget _buildFloatingButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
                 decoration: BoxDecoration(
           gradient: LinearGradient(
             colors: [color, color.withValues(alpha: 0.8)],
           ),
           borderRadius: BorderRadius.circular(16.r),
           boxShadow: [
             BoxShadow(
               color: color.withValues(alpha: 0.4),
               blurRadius: 12.r,
               offset: Offset(0, 6.h),
             ),
           ],
         ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 18.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              title,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// زر عائم بأيقونة فقط
  Widget _buildFloatingIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48.w,
        height: 48.w,
                 decoration: BoxDecoration(
           gradient: LinearGradient(
             colors: [color, color.withValues(alpha: 0.8)],
           ),
           borderRadius: BorderRadius.circular(14.r),
           boxShadow: [
             BoxShadow(
               color: color.withValues(alpha: 0.4),
               blurRadius: 12.r,
               offset: Offset(0, 6.h),
             ),
           ],
         ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20.sp,
        ),
      ),
    );
  }
} 