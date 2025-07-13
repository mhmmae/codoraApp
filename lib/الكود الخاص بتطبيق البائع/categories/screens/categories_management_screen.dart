import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/categories_management_controller.dart';
import '../../../Model/enhanced_category_model.dart';
import 'add_category_screen.dart';

class CategoriesManagementScreen extends StatefulWidget {
  const CategoriesManagementScreen({super.key});

  @override
  State<CategoriesManagementScreen> createState() => _CategoriesManagementScreenState();
}

class _CategoriesManagementScreenState extends State<CategoriesManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  final CategoriesManagementController controller = Get.put(CategoriesManagementController());
  List<EnhancedCategoryModel> filteredCategories = [];
  
  // إحصائيات المنتجات
  final RxMap<String, int> categoryProductCounts = <String, int>{}.obs;
  final RxBool isLoadingStats = false.obs;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterCategories);
    _loadProductStatistics();
  }

  void _filterCategories() {
    setState(() {
      if (_searchController.text.isEmpty) {
        filteredCategories = controller.mainCategories;
      } else {
        filteredCategories = controller.mainCategories
            .where((category) =>
                category.nameAr.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                category.nameEn.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                category.nameKu.toLowerCase().contains(_searchController.text.toLowerCase()))
            .toList();
      }
    });
  }

  /// تحميل إحصائيات المنتجات لكل فئة
  Future<void> _loadProductStatistics() async {
    try {
      isLoadingStats.value = true;
      
      // إحصائيات المنتجات التجارية
      final commercialSnapshot = await FirebaseFirestore.instance
          .collection('ItemsData')
          .get();
      
      // إحصائيات المنتجات الأصلية  
      final originalSnapshot = await FirebaseFirestore.instance
          .collection('company_products')
          .get();
      
      Map<String, int> counts = {};
      
      // حساب المنتجات التجارية
      for (var doc in commercialSnapshot.docs) {
        final data = doc.data();
        final mainCategoryId = data['mainCategoryId'] as String?;
        final subCategoryId = data['subCategoryId'] as String?;
        
        if (mainCategoryId != null) {
          counts[mainCategoryId] = (counts[mainCategoryId] ?? 0) + 1;
        }
        if (subCategoryId != null) {
          counts[subCategoryId] = (counts[subCategoryId] ?? 0) + 1;
        }
      }
      
      // حساب المنتجات الأصلية
      for (var doc in originalSnapshot.docs) {
        final data = doc.data();
        final mainCategoryId = data['mainCategoryId'] as String?;
        final subCategoryId = data['subCategoryId'] as String?;
        
        if (mainCategoryId != null) {
          counts[mainCategoryId] = (counts[mainCategoryId] ?? 0) + 1;
        }
        if (subCategoryId != null) {
          counts[subCategoryId] = (counts[subCategoryId] ?? 0) + 1;
        }
      }
      
      categoryProductCounts.value = counts;
      
    } catch (e) {
      debugPrint('خطأ في تحميل إحصائيات المنتجات: $e');
    } finally {
      isLoadingStats.value = false;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'إدارة أقسام المنتجات',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () {
              controller.loadCategories();
              _loadProductStatistics();
            },
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'تحديث الأقسام والإحصائيات',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              switch (value) {
                case 'refresh_stats':
                  _loadProductStatistics();
                  break;
                case 'view_all_products':
                  Get.offAllNamed('/home');
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh_stats',
                child: ListTile(
                  leading: Icon(Icons.analytics),
                  title: Text('تحديث الإحصائيات'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'view_all_products',
                child: ListTile(
                  leading: Icon(Icons.home),
                  title: Text('عرض جميع المنتجات'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط البحث
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'البحث في الأقسام...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          
          // قائمة الأقسام
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final categoriesToShow = _searchController.text.isEmpty
                  ? controller.mainCategories
                  : filteredCategories;

              if (categoriesToShow.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchController.text.isEmpty
                            ? 'لا توجد أقسام حتى الآن'
                            : 'لا توجد نتائج للبحث',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'اضغط على + لإضافة قسم جديد',
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
                onRefresh: controller.loadCategories,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: categoriesToShow.length,
                  itemBuilder: (context, index) {
                    final category = categoriesToShow[index];
                    return _buildCategoryCard(category);
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategoryOptions(),
        backgroundColor: Colors.blue,
        label: const Text(
          'إضافة قسم',
          style: TextStyle(color: Colors.white),
        ),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCategoryCard(EnhancedCategoryModel category) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      child: ExpansionTile(
        leading: _buildCategoryImage(category.imageUrl),
        title: Text(
          category.nameAr,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('English: ${category.nameEn}'),
            Text('Kurdish: ${category.nameKu}'),
            Text('الترتيب: ${category.order}'),
            const SizedBox(height: 4),
            Obx(() => Row(
              children: [
                Icon(Icons.inventory_2, size: 16, color: Colors.blue[600]),
                const SizedBox(width: 4),
                Text(
                  '${categoryProductCounts[category.id] ?? 0} منتج',
                  style: TextStyle(
                    color: Colors.blue[600],
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 12),
                if (category.subCategories.isNotEmpty) ...[
                  Icon(Icons.category, size: 16, color: Colors.green[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${category.subCategories.length} قسم فرعي',
                    style: TextStyle(
                      color: Colors.green[600],
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            )),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleCategoryAction(value, category),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'view_products',
              child: ListTile(
                leading: Icon(Icons.visibility, color: Colors.purple[600]),
                title: const Text('عرض المنتجات'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'add_sub',
              child: ListTile(
                leading: Icon(Icons.add, color: Colors.blue),
                title: Text('إضافة قسم فرعي'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit, color: Colors.orange),
                title: Text('تعديل'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('حذف'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        children: [
          // الأقسام الفرعية
          if (category.subCategories.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Text(
                'الأقسام الفرعية:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            ...category.subCategories.map((subCategory) => _buildSubCategoryItem(subCategory)),
          ] else
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                'لا توجد أقسام فرعية',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubCategoryItem(EnhancedCategoryModel subCategory) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ListTile(
        leading: _buildCategoryImage(subCategory.imageUrl, size: 40),
        title: Text(
          subCategory.nameAr,
          style: const TextStyle(fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${subCategory.nameEn} • ${subCategory.nameKu}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 2),
            Obx(() => Row(
              children: [
                Icon(Icons.inventory_2, size: 14, color: Colors.blue[600]),
                const SizedBox(width: 4),
                Text(
                  '${categoryProductCounts[subCategory.id] ?? 0} منتج',
                  style: TextStyle(
                    color: Colors.blue[600],
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ],
            )),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleSubCategoryAction(value, subCategory),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'view_products',
              child: ListTile(
                leading: Icon(Icons.visibility, color: Colors.purple[600]),
                title: const Text('عرض المنتجات'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit, color: Colors.orange),
                title: Text('تعديل'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('حذف'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryImage(String? imageUrl, {double size = 50}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: imageUrl != null && imageUrl.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: imageUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: size,
                height: size,
                color: Colors.grey[300],
                child: const Icon(Icons.image, color: Colors.grey),
              ),
              errorWidget: (context, url, error) => Container(
                width: size,
                height: size,
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            )
          : Container(
              width: size,
              height: size,
              color: Colors.grey[300],
              child: const Icon(Icons.category, color: Colors.grey),
            ),
    );
  }

  void _showAddCategoryOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'اختر نوع القسم',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.category, color: Colors.blue),
              title: const Text('إضافة قسم رئيسي'),
              subtitle: const Text('قسم جديد مستقل'),
              onTap: () {
                Navigator.pop(context);
                Get.to(() => const AddCategoryScreen(isSubCategory: false));
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _handleCategoryAction(String action, EnhancedCategoryModel category) {
    switch (action) {
      case 'view_products':
        _showCategoryProducts(category);
        break;
      case 'add_sub':
        Get.to(() => AddCategoryScreen(
              isSubCategory: true,
              parentCategory: category,
            ));
        break;
      case 'edit':
        Get.to(() => AddCategoryScreen(
              isSubCategory: false,
              categoryToEdit: category,
            ));
        break;
      case 'delete':
        _confirmDelete(category);
        break;
    }
  }

  void _handleSubCategoryAction(String action, EnhancedCategoryModel subCategory) {
    switch (action) {
      case 'view_products':
        _showCategoryProducts(subCategory);
        break;
      case 'edit':
        Get.to(() => AddCategoryScreen(
              isSubCategory: true,
              categoryToEdit: subCategory,
            ));
        break;
      case 'delete':
        _confirmDelete(subCategory);
        break;
    }
  }

  /// عرض المنتجات المرتبطة بفئة معينة
  void _showCategoryProducts(EnhancedCategoryModel category) {
    // الانتقال إلى صفحة HomeScreen مع تطبيق فلترة الفئة
    Get.offAllNamed('/home', arguments: {
      'applyFilter': true,
      'mainCategoryId': category.isMainCategory ? category.id : category.parentId,
      'subCategoryId': !category.isMainCategory ? category.id : null,
      'categoryName': category.nameAr,
    });
    
    // رسالة توضيحية
    Get.snackbar(
      '🔍 فلترة',
      'عرض المنتجات في فئة "${category.nameAr}"',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue[100],
      colorText: Colors.blue[800],
      duration: const Duration(seconds: 3),
    );
  }

  void _confirmDelete(EnhancedCategoryModel category) {
    Get.dialog(
      AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف القسم "${category.nameAr}"؟'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deleteCategory(category.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
} 