import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/original_products_controller.dart';
import '../../../Model/company_model.dart';
import 'add_product_screen.dart';
import 'add_company_screen.dart';
import '../../categories/widgets/enhanced_category_selector.dart';

/// شاشة إدارة المنتجات الأصلية
/// تعرض قائمة بجميع المنتجات الأصلية مع إمكانية إضافة وتعديل وحذف المنتجات
class OriginalProductsManagementScreen extends StatelessWidget {
  const OriginalProductsManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OriginalProductsController());
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'إدارة المنتجات الأصلية',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              controller.fetchCompanies();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط البحث والفلترة
          _buildSearchAndFilterBar(controller),
          
          // المحتوى الرئيسي
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (controller.companies.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.business_outlined,
                        size: 80,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'لا توجد شركات أصلية',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'ابدأ بإضافة أول شركة أصلية',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await controller.loadCompanies();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.companies.length,
                  itemBuilder: (context, index) {
                    final company = controller.companies[index];
                    return _buildCompanyCard(context, company, controller);
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Get.to(() => const AddCompanyScreen());
        },
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.business, color: Colors.white),
        label: const Text(
          'إضافة شركة',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// بناء شريط البحث والفلترة
  Widget _buildSearchAndFilterBar(OriginalProductsController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // شريط البحث
          Row(
            children: [
              Expanded(
                child: TextField(
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'البحث في المنتجات الأصلية...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    controller.searchQuery.value = value;
                  },
                ),
              ),
              const SizedBox(width: 12),
              
              // زر الفلترة المتقدمة
              ElevatedButton.icon(
                onPressed: () => _showAdvancedFilterDialog(controller),
                icon: const Icon(Icons.filter_list, size: 18),
                label: const Text('فلترة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // مؤشرات الفلترة النشطة
          Obx(() {
            final hasActiveFilters = controller.selectedMainCategoryId.value.isNotEmpty ||
                                   controller.selectedSubCategoryId.value.isNotEmpty ||
                                   controller.filterByCompanyId.value.isNotEmpty ||
                                   !controller.showActiveOnly.value;
                                   
            if (!hasActiveFilters) return const SizedBox();
            
            return Wrap(
              spacing: 8,
              children: [
                if (controller.selectedMainCategoryId.value.isNotEmpty)
                  _buildFilterChip('فئة رئيسية مُحددة', () {
                    controller.selectedMainCategoryId.value = '';
                  }),
                if (controller.selectedSubCategoryId.value.isNotEmpty)
                  _buildFilterChip('فئة فرعية مُحددة', () {
                    controller.selectedSubCategoryId.value = '';
                  }),
                if (controller.filterByCompanyId.value.isNotEmpty)
                  _buildFilterChip('شركة مُحددة', () {
                    controller.filterByCompanyId.value = '';
                  }),
                if (!controller.showActiveOnly.value)
                  _buildFilterChip('تشمل المعطلة', () {
                    controller.showActiveOnly.value = true;
                  }),
                  
                // زر مسح جميع الفلاتر
                TextButton.icon(
                  onPressed: controller.clearFilters,
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('مسح الكل'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onRemove,
      backgroundColor: Colors.blue.withOpacity(0.1),
      deleteIconColor: Colors.blue,
    );
  }

  /// عرض حوار الفلترة المتقدمة
  void _showAdvancedFilterDialog(OriginalProductsController controller) {

    showDialog(
      context: Get.context!,
      builder: (context) => AlertDialog(
        title: const Text('فلترة متقدمة'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // اختيار الشركة
              _buildCompanyDropdown(controller),
              
              const SizedBox(height: 16),
              
              // اختيار الفئات المحسن
              EnhancedCategorySelector(
                productType: 'original',
                onCategoriesSelected: (mainId, subId, mainNameEn, subNameEn) {
                  controller.selectedMainCategoryId.value = mainId;
                  controller.selectedSubCategoryId.value = subId;
                },
                initialMainCategoryId: controller.selectedMainCategoryId.value.isNotEmpty 
                    ? controller.selectedMainCategoryId.value 
                    : null,
                initialSubCategoryId: controller.selectedSubCategoryId.value.isNotEmpty 
                    ? controller.selectedSubCategoryId.value 
                    : null,
              ),
              
              const SizedBox(height: 16),
              
              // خيارات إضافية
              Obx(() => CheckboxListTile(
                title: const Text('إظهار المنتجات المعطلة أيضاً'),
                value: !controller.showActiveOnly.value,
                onChanged: (value) {
                  controller.showActiveOnly.value = !value!;
                },
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              controller.filterProducts();
            },
            child: const Text('تطبيق'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyDropdown(OriginalProductsController controller) {
    return Obx(() => DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'اختر شركة محددة',
        border: OutlineInputBorder(),
      ),
      value: controller.filterByCompanyId.value.isNotEmpty 
          ? controller.filterByCompanyId.value 
          : null,
      items: [
        const DropdownMenuItem<String>(
          value: '',
          child: Text('جميع الشركات'),
        ),
        ...controller.companies.map((company) => 
          DropdownMenuItem<String>(
            value: company.id,
            child: Text(company.nameAr),
          )
        ),
      ],
      onChanged: (value) {
        controller.filterByCompanyId.value = value ?? '';
      },
    ));
  }

  /// بناء كارد عرض الشركة ومنتجاتها
  Widget _buildCompanyCard(BuildContext context, CompanyModel company, OriginalProductsController controller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundImage: company.logoUrl?.isNotEmpty == true 
              ? NetworkImage(company.logoUrl!) 
              : null,
          backgroundColor: Colors.blue.withOpacity(0.1),
          child: company.logoUrl?.isEmpty != false 
              ? Text(
                  company.nameAr.isNotEmpty ? company.nameAr[0].toUpperCase() : 'C',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                )
              : null,
        ),
        title: Text(
          company.nameAr,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عرض البلد
            if (company.country?.isNotEmpty == true)
              Row(
                children: [
                  Icon(
                    Icons.flag,
                    size: 14,
                    color: Colors.blue[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    company.country!,
                    style: TextStyle(
                      color: Colors.blue[600],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 4),
            // عرض الوصف
            if (company.description?.isNotEmpty == true)
              Text(
                company.description!,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.inventory,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${company.products.length} منتج',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: company.isActive ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    company.isActive ? 'نشط' : 'غير نشط',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.edit, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('تعديل'),
                ],
              ),
              onTap: () {
                // TODO: تنفيذ تعديل الشركة
                _showEditCompanyDialog(context, company, controller);
              },
            ),
            PopupMenuItem(
              child: Row(
                children: [
                  Icon(
                    company.isActive ? Icons.visibility_off : Icons.visibility,
                    color: company.isActive ? Colors.orange : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Text(company.isActive ? 'إلغاء تفعيل' : 'تفعيل'),
                ],
              ),
              onTap: () {
                controller.toggleCompanyStatus(company.id, !company.isActive);
              },
            ),
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('حذف'),
                ],
              ),
              onTap: () {
                _showDeleteConfirmationDialog(context, company, controller);
              },
            ),
          ],
        ),
        children: [
          if (company.products.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'لا توجد منتجات في هذه الشركة',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...company.products.map((product) => _buildProductTile(context, product, controller)),
          Padding(
            padding: const EdgeInsets.all(8),
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: إضافة منتج جديد للشركة
                Get.to(() => AddProductScreen(companyId: company.id));
              },
              icon: const Icon(Icons.add),
              label: const Text('إضافة منتج جديد'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// بناء عنصر عرض المنتج
  Widget _buildProductTile(BuildContext context, CompanyProductModel product, OriginalProductsController controller) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: product.imageUrl?.isNotEmpty == true 
            ? NetworkImage(product.imageUrl!) 
            : null,
        backgroundColor: Colors.grey[200],
        child: product.imageUrl?.isEmpty != false 
            ? const Icon(Icons.image, color: Colors.grey)
            : null,
      ),
      title: Text(
        product.nameAr,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                    if (product.description?.isNotEmpty == true)
             Text(
               product.description!,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'السعر: ${product.price} ج.م',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: product.isActive ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  product.isActive ? 'متاح' : 'غير متاح',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: PopupMenuButton(
        icon: const Icon(Icons.more_vert, size: 20),
        itemBuilder: (context) => [
          PopupMenuItem(
            child: const Row(
              children: [
                Icon(Icons.edit, color: Colors.blue, size: 18),
                SizedBox(width: 8),
                Text('تعديل', style: TextStyle(fontSize: 14)),
              ],
            ),
            onTap: () {
              // TODO: تنفيذ تعديل المنتج
              _showEditProductDialog(context, product, controller);
            },
          ),
          PopupMenuItem(
            child: Row(
              children: [
                Icon(
                  product.isActive ? Icons.visibility_off : Icons.visibility,
                  color: product.isActive ? Colors.orange : Colors.green,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  product.isActive ? 'إخفاء' : 'إظهار',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            onTap: () {
              controller.toggleProductStatus(product.id, !product.isActive);
            },
          ),
          PopupMenuItem(
            child: const Row(
              children: [
                Icon(Icons.delete, color: Colors.red, size: 18),
                SizedBox(width: 8),
                Text('حذف', style: TextStyle(fontSize: 14)),
              ],
            ),
            onTap: () {
              _showDeleteProductConfirmationDialog(context, product, controller);
            },
          ),
        ],
      ),
    );
  }

  /// عرض حوار تأكيد حذف الشركة
  void _showDeleteConfirmationDialog(BuildContext context, CompanyModel company, OriginalProductsController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف شركة "${company.nameAr}"؟\nسيتم حذف جميع المنتجات التابعة لها أيضاً.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              controller.deleteCompany(company.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// عرض حوار تأكيد حذف المنتج
  void _showDeleteProductConfirmationDialog(BuildContext context, CompanyProductModel product, OriginalProductsController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف منتج "${product.nameAr}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              controller.deleteProduct(product.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// عرض حوار تعديل الشركة
  void _showEditCompanyDialog(BuildContext context, CompanyModel company, OriginalProductsController controller) {
    final nameController = TextEditingController(text: company.nameAr);
    final descriptionController = TextEditingController(text: company.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل الشركة'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم الشركة',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'وصف الشركة',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                final updatedCompany = company.copyWith(
                  nameAr: nameController.text.trim(),
                  description: descriptionController.text.trim(),
                );
                controller.updateCompany(updatedCompany);
                Navigator.pop(context);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  /// عرض حوار تعديل المنتج
  void _showEditProductDialog(BuildContext context, CompanyProductModel product, OriginalProductsController controller) {
    final nameController = TextEditingController(text: product.nameAr);
    final descriptionController = TextEditingController(text: product.description);
    final priceController = TextEditingController(text: product.price.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل المنتج'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المنتج',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'وصف المنتج',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'السعر',
                  border: OutlineInputBorder(),
                  suffixText: 'ج.م',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty && 
                  priceController.text.trim().isNotEmpty) {
                try {
                  final updatedProduct = product.copyWith(
                    nameAr: nameController.text.trim(),
                    description: descriptionController.text.trim(),
                    price: double.parse(priceController.text.trim()),
                  );
                  controller.updateProduct(updatedProduct);
                  Navigator.pop(context);
                } catch (e) {
                  Get.snackbar(
                    'خطأ',
                    'يرجى إدخال سعر صحيح',
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}