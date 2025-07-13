import 'package:flutter/material.dart';
import '../../../Model/original_product_model.dart';

/// Widget محسن لعرض المنتجات الأصلية
/// يعرض القسم الفرعي بالعربي فقط وليس القسم الرئيسي
class OriginalProductDisplayWidget extends StatelessWidget {
  final OriginalProductModel product;
  final VoidCallback? onTap;
  final bool showOnlySubCategoryInArabic;
  final bool isSelected;

  const OriginalProductDisplayWidget({
    super.key,
    required this.product,
    this.onTap,
    this.showOnlySubCategoryInArabic = true,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue[50] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // صورة المنتج واسم الشركة
              _buildProductHeader(),
              
              const SizedBox(height: 8),
              
              // اسم المنتج
              _buildProductName(),
              
              const SizedBox(height: 6),
              
              // معلومات القسم (القسم الفرعي فقط بالعربي)
              _buildCategoryInfo(),
              
              const SizedBox(height: 6),
              
              // معلومات إضافية (مثل باركود أو مواصفات)
              if (product.barcode != null || product.specifications.isNotEmpty)
                _buildAdditionalInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductHeader() {
    return Row(
      children: [
        // صورة المنتج أو أيقونة افتراضية
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[200],
          ),
          child: product.imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    product.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.image_not_supported,
                        color: Colors.grey[400],
                        size: 24,
                      );
                    },
                  ),
                )
              : Icon(
                  Icons.inventory_2,
                  color: Colors.grey[400],
                  size: 24,
                ),
        ),
        
        const SizedBox(width: 12),
        
        // معلومات الشركة
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.companyName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (product.companyBrand != null) ...[
                const SizedBox(height: 2),
                Text(
                  product.companyBrand!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        
        // أيقونة الاختيار أو الحالة
        if (isSelected)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 16,
            ),
          ),
      ],
    );
  }

  Widget _buildProductName() {
    return Text(
      product.productName,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildCategoryInfo() {
    // عرض القسم الفرعي بالعربي فقط حسب المتطلبات
    String categoryText = '';
    
    if (showOnlySubCategoryInArabic) {
      // إظهار القسم الفرعي بالعربي فقط
      if (product.subCategoryNameAr != null && product.subCategoryNameAr!.isNotEmpty) {
        categoryText = product.subCategoryNameAr!;
      }
    } else {
      // إظهار القسم الرئيسي والفرعي
      if (product.mainCategoryNameAr != null && product.subCategoryNameAr != null) {
        categoryText = '${product.mainCategoryNameAr!} > ${product.subCategoryNameAr!}';
      } else if (product.subCategoryNameAr != null) {
        categoryText = product.subCategoryNameAr!;
      } else if (product.mainCategoryNameAr != null) {
        categoryText = product.mainCategoryNameAr!;
      }
    }

    if (categoryText.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.teal[50],
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.teal[200]!),
        ),
        child: Text(
          categoryText,
          style: TextStyle(
            fontSize: 12,
            color: Colors.teal[700],
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildAdditionalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // باركود المنتج
        if (product.barcode != null) ...[
          Row(
            children: [
              Icon(
                Icons.qr_code,
                size: 14,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                'الباركود: ${product.barcode!}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
        
        // مواصفات سريعة
        if (product.specifications.isNotEmpty) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 2,
            children: product.specifications.entries.take(2).map((spec) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${spec.key}: ${spec.value}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[700],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

/// Widget مبسط لعرض المنتج الأصلي في قائمة
class OriginalProductListTile extends StatelessWidget {
  final OriginalProductModel product;
  final VoidCallback? onTap;
  final bool isSelected;

  const OriginalProductListTile({
    super.key,
    required this.product,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey[200],
        child: product.imageUrl != null
            ? ClipOval(
                child: Image.network(
                  product.imageUrl!,
                  fit: BoxFit.cover,
                  width: 40,
                  height: 40,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.inventory_2,
                      color: Colors.grey[400],
                    );
                  },
                ),
              )
            : Icon(
                Icons.inventory_2,
                color: Colors.grey[400],
              ),
      ),
      title: Text(
        product.productName,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.companyName,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          // عرض القسم الفرعي بالعربي فقط
          if (product.subCategoryNameAr != null)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.teal[50],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                product.subCategoryNameAr!,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.teal[700],
                ),
              ),
            ),
        ],
      ),
      trailing: isSelected
          ? const Icon(
              Icons.check_circle,
              color: Colors.blue,
            )
          : const Icon(
              Icons.arrow_forward_ios,
              size: 16,
            ),
      onTap: onTap,
      selected: isSelected,
      selectedTileColor: Colors.blue[50],
    );
  }
} 