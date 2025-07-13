import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../controllers/barcode_filter_controller.dart';

class BarcodeSearchWidget extends StatelessWidget {
  final BarcodeFilterController controller;
  final ThemeData theme;

  const BarcodeSearchWidget({
    super.key,
    required this.controller,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان القسم
          _buildSectionTitle(),
          const SizedBox(height: 16),
          
          // زر مسح الباركود بالكاميرا
          _buildScanBarcodeButton(),
          
          const SizedBox(height: 20),
          
          // عرض نتائج البحث
          Obx(() => controller.searchResults.isNotEmpty
              ? _buildSearchResults()
              : const SizedBox.shrink()),
        ],
      ),
    );
  }

  /// عنوان القسم
  Widget _buildSectionTitle() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.qr_code_scanner,
            color: theme.primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'البحث بالباركود',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
          ),
        ),
      ],
    );
  }

  /// زر مسح الباركود بالكاميرا
  Widget _buildScanBarcodeButton() {
    return SizedBox(
      width: double.infinity,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            controller.startCameraScan();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 80,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor,
                  theme.primaryColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.qr_code_scanner,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  'مسح الباركود',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  /// عرض نتائج البحث
  Widget _buildSearchResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.search, color: theme.primaryColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'نتائج البحث:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Obx(() => Text(
                '${controller.searchResults.length} منتج',
                style: TextStyle(
                  color: theme.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              )),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          constraints: const BoxConstraints(maxHeight: 300),
          child: Obx(() => ListView.builder(
            shrinkWrap: true,
            itemCount: controller.searchResults.length,
            itemBuilder: (context, index) {
              final product = controller.searchResults[index];
              return _buildProductCard(product);
            },
          )),
        ),
      ],
    );
  }

  /// بطاقة المنتج
  Widget _buildProductCard(product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          // يمكن إضافة منطق للانتقال لصفحة تفاصيل المنتج
          debugPrint('تم اختيار المنتج: ${product.name}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // صورة المنتج
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey.shade100,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: product.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => 
                              Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          errorWidget: (context, url, error) => 
                              Icon(Icons.inventory_2, color: Colors.grey, size: 30),
                        ),
                      )
                    : Icon(Icons.inventory_2, color: Colors.grey, size: 30),
              ),
              const SizedBox(width: 12),
              
              // معلومات المنتج
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name ?? 'غير محدد',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                                          Row(
                        children: [
                          Icon(Icons.qr_code, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'الباركود: ${product.productBarcode ?? 'غير متوفر'}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 4),
                    if (product.price != null) ...[
                      Row(
                        children: [
                          Icon(Icons.attach_money, size: 14, color: Colors.green),
                          Text(
                            '${product.price} ر.س',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              // سهم للتفاصيل
              Icon(
                Icons.arrow_forward_ios,
                color: theme.primaryColor,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 