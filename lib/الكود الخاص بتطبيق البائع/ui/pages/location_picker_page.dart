import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../controllers/location_picker_controller.dart';

class LocationPickerPage extends StatelessWidget {
  const LocationPickerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LocationPickerController>();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'اختيار موقع الاستلام',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF7B3F99),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF7B3F99),
            ),
          );
        }

        return Column(
          children: [
            // معلومات العنوان المحفوظ
            if (controller.savedAddress.value.isNotEmpty)
              Container(
                width: double.infinity,
                margin: EdgeInsets.all(16.w),
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF7B3F99).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: const Color(0xFF7B3F99).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: const Color(0xFF7B3F99),
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'العنوان المحفوظ',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF7B3F99),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      controller.savedAddress.value,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: controller.useCurrentLocation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7B3F99),
                              padding: EdgeInsets.symmetric(vertical: 8.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                            child: Text(
                              'استخدام هذا العنوان',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: controller.getCurrentLocation,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF7B3F99)),
                              padding: EdgeInsets.symmetric(vertical: 8.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                            child: Text(
                              'تحديث الموقع',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: const Color(0xFF7B3F99),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // الخريطة
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: Stack(
                    children: [
                      // الخريطة
                      GoogleMap(
                        onMapCreated: (GoogleMapController mapController) {
                          debugPrint('🗺️ تم إنشاء GoogleMap widget');
                          controller.onMapCreated(mapController);
                        },
                        initialCameraPosition: CameraPosition(
                          target: controller.currentLocation.value,
                          zoom: 15.0,
                        ),
                        markers: controller.markers.toSet(),
                        onTap: controller.onMapTap,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        mapType: MapType.normal,
                        compassEnabled: true,
                        tiltGesturesEnabled: true,
                        scrollGesturesEnabled: true,
                        zoomGesturesEnabled: true,
                        rotateGesturesEnabled: true,
                        buildingsEnabled: true,
                        trafficEnabled: false,
                      ),
                      
                      // مؤشر التحميل فوق الخريطة
                      if (!controller.isMapReady.value)
                        Container(
                          color: Colors.white.withOpacity(0.8),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  color: Color(0xFF7B3F99),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'جارٍ تحميل الخريطة...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF7B3F99),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      // زر الموقع الحالي
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: FloatingActionButton(
                          mini: true,
                          backgroundColor: const Color(0xFF7B3F99),
                          onPressed: controller.getCurrentLocation,
                          child: const Icon(
                            Icons.my_location,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // العنوان المحدد حالياً
            if (controller.selectedAddress.value.isNotEmpty)
              Container(
                width: double.infinity,
                margin: EdgeInsets.all(16.w),
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'الموقع المحدد',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      controller.selectedAddress.value,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),

            // زر التأكيد
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(16.w),
              child: ElevatedButton(
                onPressed: controller.selectedAddress.value.isNotEmpty
                    ? controller.confirmLocation
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B3F99),
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: Text(
                  'تأكيد الموقع',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
} 