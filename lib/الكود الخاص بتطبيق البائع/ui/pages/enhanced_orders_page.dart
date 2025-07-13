import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/enhanced_orders_controller.dart';
import '../../ViewOrderSeller/GetDateToText.dart';
import '../../ViewOrderSeller/GetRequest.dart';

class EnhancedOrdersPage extends StatelessWidget {
  const EnhancedOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EnhancedOrdersController());
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildFilterTabs(controller),
          Expanded(
            child: GetBuilder<EnhancedOrdersController>(
              builder: (controller) {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (controller.filteredOrders.isEmpty) {
                  return _buildEmptyState(controller);
                }
                
                return RefreshIndicator(
                  onRefresh: controller.refreshOrders,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16.w),
                    itemCount: controller.filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = controller.filteredOrders[index];
                      return _buildOrderCard(order, controller, context);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      title: Text(
        'الطلبات الواردة',
        style: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1F2937),
        ),
      ),
    );
  }
  
  Widget _buildFilterTabs(EnhancedOrdersController controller) {
    return Container(
      margin: EdgeInsets.all(16.w),
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
      child: Obx(() => Row(
        children: [
          _buildFilterTab(
            'الكل',
            'all',
            controller.getOrdersCount('all'),
            controller,
            Icons.list_alt_rounded,
          ),
          _buildFilterTab(
            'مستخدمين',
            'customer',
            controller.getOrdersCount('customer'),
            controller,
            Icons.person_outline,
          ),
          _buildFilterTab(
            'بائعي تجزئة',
            'retail',
            controller.getOrdersCount('retail'),
            controller,
            Icons.store_outlined,
          ),
        ],
      )),
    );
  }
  
  Widget _buildFilterTab(
    String title,
    String value,
    int count,
    EnhancedOrdersController controller,
    IconData icon,
  ) {
    final isSelected = controller.selectedFilter.value == value;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.changeFilter(value),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20.sp,
                color: isSelected ? Colors.white : const Color(0xFF6B7280),
              ),
              SizedBox(height: 4.h),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF6B7280),
                ),
              ),
              if (count > 0)
                Container(
                  margin: EdgeInsets.only(top: 2.h),
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : const Color(0xFF6366F1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? const Color(0xFF6366F1) : Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyState(EnhancedOrdersController controller) {
    String message;
    IconData icon;
    
    switch (controller.selectedFilter.value) {
      case 'customer':
        message = 'لا توجد طلبات من المستخدمين العاديين';
        icon = Icons.person_outline;
        break;
      case 'retail':
        message = 'لا توجد طلبات من بائعي التجزئة';
        icon = Icons.store_outlined;
        break;
      default:
        message = 'لا توجد طلبات حالياً';
        icon = Icons.inbox_outlined;
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80.sp,
            color: const Color(0xFF9CA3AF),
          ),
          SizedBox(height: 16.h),
          Text(
            message,
            style: TextStyle(
              fontSize: 16.sp,
              color: const Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildOrderCard(
    Map<String, dynamic> order,
    EnhancedOrdersController controller,
    BuildContext context,
  ) {
    final orderType = order['orderType'] ?? 'customer';
    final userData = order['userData'] as Map<String, dynamic>?;
    
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: controller.getOrderTypeColor(orderType).withOpacity(0.3),
          width: 2,
        ),
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
          // رأس البطاقة مع نوع الطلب والتاريخ
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: controller.getOrderTypeColor(orderType).withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12.r),
                topRight: Radius.circular(12.r),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: controller.getOrderTypeColor(orderType),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        controller.getOrderTypeIcon(orderType),
                        size: 14.sp,
                        color: Colors.white,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        controller.getOrderTypeText(orderType),
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                GetBuilder<GetDateToText>(
                  init: GetDateToText(),
                  builder: (dateController) {
                    return Text(
                      dateController.dateToText(order['timeOrder']),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: const Color(0xFF6B7280),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          // محتوى البطاقة
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              children: [
                // صورة المستخدم/المتجر
                _buildUserAvatar(userData, orderType),
                SizedBox(width: 12.w),
                
                // معلومات المستخدم
                Expanded(
                  child: _buildUserInfo(userData, orderType),
                ),
                
                // أزرار التحكم
                _buildActionButtons(order, context),
              ],
            ),
          ),
          
          // معلومات إضافية للطلبات من بائعي التجزئة
          if (orderType == 'retail') _buildRetailOrderInfo(order),
        ],
      ),
    );
  }
  
  Widget _buildUserAvatar(Map<String, dynamic>? userData, String orderType) {
    return Container(
      width: 60.w,
      height: 60.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7.r),
        child: orderType == 'retail'
            ? Container(
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                child: Icon(
                  Icons.store_rounded,
                  size: 30.sp,
                  color: const Color(0xFF8B5CF6),
                ),
              )
            : userData?['url'] != null
                ? CachedNetworkImage(
                    imageUrl: userData!['url'],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: const Color(0xFFF3F4F6),
                      child: Icon(
                        Icons.person,
                        size: 30.sp,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: const Color(0xFFF3F4F6),
                      child: Icon(
                        Icons.person,
                        size: 30.sp,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  )
                : Container(
                    color: const Color(0xFFF3F4F6),
                    child: Icon(
                      Icons.person,
                      size: 30.sp,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
      ),
    );
  }
  
  Widget _buildUserInfo(Map<String, dynamic>? userData, String orderType) {
    if (orderType == 'retail') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            userData?['name'] ?? 'بائع تجزئة',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            userData?['shopName'] ?? '',
            style: TextStyle(
              fontSize: 12.sp,
              color: const Color(0xFF6B7280),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            userData?['phone'] ?? '',
            style: TextStyle(
              fontSize: 11.sp,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            userData?['name'] ?? 'مستخدم',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            userData?['phneNumber']?.toString() ?? '',
            style: TextStyle(
              fontSize: 12.sp,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      );
    }
  }
  
  Widget _buildActionButtons(Map<String, dynamic> order, BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // زر الرفض
        if (!order['Delivery'])
          GetBuilder<Getrequest>(
            init: Getrequest(),
            builder: (reqController) {
              return GestureDetector(
                onTap: () {
                  reqController.RequestRejection(
                    order['numberOfOrder'],
                    MediaQuery.of(context).size.width,
                    context,
                  );
                },
                child: Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 20.sp,
                    color: Colors.red,
                  ),
                ),
              );
            },
          ),
        
        SizedBox(width: 8.w),
        
        // زر القبول
        GetBuilder<Getrequest>(
          init: Getrequest(),
          builder: (reqController) {
            final isAccepted = order['RequestAccept'] == true;
            
            return GestureDetector(
              onTap: isAccepted ? null : () {
                reqController.RequestAccept(order['numberOfOrder']);
              },
              child: Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: isAccepted 
                      ? Colors.green.withOpacity(0.2)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: Colors.green.withOpacity(isAccepted ? 0.5 : 0.3),
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.check_rounded,
                        size: 20.sp,
                        color: Colors.green,
                      ),
                    ),
                    if (!isAccepted)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildRetailOrderInfo(Map<String, dynamic> order) {
    final items = order['items'] as List<dynamic>? ?? [];
    final pricing = order['pricing'] as Map<String, dynamic>?;
    
    return Container(
      margin: EdgeInsets.only(top: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFF8B5CF6).withOpacity(0.05),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12.r),
          bottomRight: Radius.circular(12.r),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                size: 16.sp,
                color: const Color(0xFF8B5CF6),
              ),
              SizedBox(width: 4.w),
              Text(
                'تفاصيل الطلب:',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Text(
                'عدد المنتجات: ${items.length}',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: const Color(0xFF6B7280),
                ),
              ),
              SizedBox(width: 16.w),
              if (pricing != null)
                Text(
                  'المجموع: ${pricing['total']?.toStringAsFixed(0) ?? '0'} د.ع',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF059669),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
} 