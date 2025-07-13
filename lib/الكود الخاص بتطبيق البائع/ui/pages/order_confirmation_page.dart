import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/order_confirmation_controller.dart';

class OrderConfirmationPage extends StatelessWidget {
  const OrderConfirmationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OrderConfirmationController());
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: GetBuilder<OrderConfirmationController>(
        builder: (controller) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return SingleChildScrollView(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOrderSummary(controller),
                SizedBox(height: 20.h),
                _buildDeliveryInfo(controller),
                SizedBox(height: 20.h),
                _buildPaymentSummary(controller),
                SizedBox(height: 30.h),
                _buildConfirmButton(controller),
              ],
            ),
          );
        },
      ),
    );
  }
  
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      title: Text(
        'تأكيد الطلب',
        style: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1F2937),
        ),
      ),
      leading: IconButton(
        onPressed: () => Get.back(),
        icon: Icon(
          Icons.arrow_back_ios_rounded,
          color: const Color(0xFF6366F1),
          size: 24.sp,
        ),
      ),
    );
  }
  
  Widget _buildOrderSummary(OrderConfirmationController controller) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
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
          Row(
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                color: const Color(0xFF6366F1),
                size: 24.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'ملخص الطلب',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          
          // معلومات المتجر
          if (controller.storeInfo != null) ...[
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: const Color(0xFF6366F1).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7.r),
                      child: controller.storeInfo!.shopFrontImageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: controller.storeInfo!.shopFrontImageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: const Color(0xFFF3F4F6),
                                child: Icon(
                                  Icons.store_rounded,
                                  color: const Color(0xFF6366F1),
                                  size: 20.sp,
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: const Color(0xFFF3F4F6),
                                child: Icon(
                                  Icons.store_rounded,
                                  color: const Color(0xFF6366F1),
                                  size: 20.sp,
                                ),
                              ),
                            )
                          : Container(
                              color: const Color(0xFFF3F4F6),
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
                          controller.storeInfo!.shopName,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        Text(
                          controller.storeInfo!.shopCategory,
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
            ),
            SizedBox(height: 16.h),
          ],
          
          // المنتجات
          ...controller.cartItems.map((item) => _buildOrderItem(item)),
        ],
      ),
    );
  }
  
  Widget _buildOrderItem(dynamic item) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Container(
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6.r),
              border: Border.all(
                color: const Color(0xFF6366F1).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5.r),
              child: item.productImage.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.productImage,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: const Color(0xFFF3F4F6),
                        child: Icon(
                          Icons.image_outlined,
                          color: const Color(0xFF9CA3AF),
                          size: 20.sp,
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: const Color(0xFFF3F4F6),
                        child: Icon(
                          Icons.image_outlined,
                          color: const Color(0xFF9CA3AF),
                          size: 20.sp,
                        ),
                      ),
                    )
                  : Container(
                      color: const Color(0xFFF3F4F6),
                      child: Icon(
                        Icons.image_outlined,
                        color: const Color(0xFF9CA3AF),
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
                  item.productName,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Text(
                      '${item.productPrice.toStringAsFixed(0)} د.ع',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    Text(
                      ' × ${item.quantity}',
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
          Text(
            '${item.totalPrice.toStringAsFixed(0)} د.ع',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF059669),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDeliveryInfo(OrderConfirmationController controller) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
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
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: const Color(0xFF6366F1),
                size: 24.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'معلومات التسليم',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          
          // العنوان
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'عنوان التسليم:',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  controller.deliveryAddress,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 12.h),
          
          // معلومات المشتري
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'معلومات المشتري:',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                SizedBox(height: 8.h),
                if (controller.buyerInfo != null) ...[
                  _buildInfoRow('الاسم:', controller.buyerInfo!['sellerName'] ?? ''),
                  _buildInfoRow('رقم الهاتف:', controller.buyerInfo!['shopPhoneNumber'] ?? ''),
                  _buildInfoRow('اسم المتجر:', controller.buyerInfo!['shopName'] ?? ''),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: const Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.sp,
                color: const Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPaymentSummary(OrderConfirmationController controller) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
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
          Row(
            children: [
              Icon(
                Icons.receipt_outlined,
                color: const Color(0xFF6366F1),
                size: 24.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'ملخص الدفع',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          
          _buildPaymentRow('المجموع الفرعي:', '${controller.subtotal.toStringAsFixed(0)} د.ع'),
          _buildPaymentRow('رسوم التوصيل:', 'مجاني'),
          Divider(height: 20.h, color: const Color(0xFFE5E7EB)),
          _buildPaymentRow(
            'المجموع الكلي:', 
            '${controller.total.toStringAsFixed(0)} د.ع',
            isTotal: true,
          ),
        ],
      ),
    );
  }
  
  Widget _buildPaymentRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16.sp : 14.sp,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: const Color(0xFF1F2937),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18.sp : 14.sp,
              fontWeight: FontWeight.bold,
              color: isTotal ? const Color(0xFF059669) : const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildConfirmButton(OrderConfirmationController controller) {
    return SizedBox(
      width: double.infinity,
      height: 50.h,
      child: ElevatedButton(
        onPressed: controller.isProcessing ? null : controller.confirmOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          disabledBackgroundColor: const Color(0xFF9CA3AF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.r),
          ),
        ),
        child: controller.isProcessing
            ? SizedBox(
                width: 20.w,
                height: 20.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'تأكيد الطلب',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
} 