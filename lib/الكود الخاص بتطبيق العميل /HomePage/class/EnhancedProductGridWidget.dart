import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../Model/model_item.dart';
import '../../../XXX/xxx_firebase.dart';

import '../controllers/enhanced_category_filter_controller.dart';
import 'BoxAddAndRemove.dart';
import 'DetailsOfItemScreen.dart';
import 'FavoriteController.dart';

/// ProductGridWidget محدث ليستخدم EnhancedCategoryFilterController
class EnhancedProductGridWidget extends StatelessWidget {
  final String? selectedSubtypeKey;
  final bool showLoadingShimmer;
  final int? maxItems;
  
  const EnhancedProductGridWidget({
    super.key,
    this.selectedSubtypeKey,
    this.showLoadingShimmer = true,
    this.maxItems,
  });

  // مرجع ثابت لـ allItemsFilterKey
  static const String allItemsFilterKey = 'all_items';
  
  // التحقق من حالة الأدمن
  bool get _isAdmin => FirebaseAuth.instance.currentUser?.email == FirebaseX.EmailOfWnerApp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _buildProductStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorWidget(context, snapshot.error.toString());
        }

        if (snapshot.connectionState == ConnectionState.waiting && showLoadingShimmer) {
          return _buildLoadingShimmer();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          final filterController = Get.find<EnhancedCategoryFilterController>();
          return _buildEmptyStateWidget(context, filterController);
        }

        final items = snapshot.data!.docs
            .map((doc) => ItemModel.fromMap(doc.data(), doc.id))
            .toList();

        return _buildProductGrid(context, items, theme);
      },
    );
  }

  /// بناء stream المنتجات مع الفلترة
  Stream<QuerySnapshot<Map<String, dynamic>>> _buildProductStream() {
    final filterController = Get.find<EnhancedCategoryFilterController>();
    
    // بناء الاستعلام الأساسي
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection(FirebaseX.itemsCollection)
        .where('appName', isEqualTo: FirebaseX.appName);

    // تطبيق فلتر الفئة إذا كان محددًا
    final currentFilterKey = filterController.getFilterKey();
    if (currentFilterKey != 'all_items') {
      // دعم النظام القديم (typeItem) والنظام الجديد (mainCategoryId/subCategoryId)
      if (currentFilterKey.contains('_') && currentFilterKey.split('_').length >= 2) {
        // نظام جديد: mainCategoryId_subCategoryId أو mainCategoryId_subCategoryId_productType
        final parts = currentFilterKey.split('_');
        final mainCategoryId = parts[0];
        final subCategoryId = parts[1];
        final productType = parts.length > 2 ? parts[2] : null;
        
        debugPrint("📱 EnhancedProductGrid: تطبيق فلتر النظام الجديد: mainCategory=$mainCategoryId, subCategory=$subCategoryId, productType=$productType");
        query = query.where('mainCategoryId', isEqualTo: mainCategoryId);
        if (subCategoryId != 'all' && subCategoryId.isNotEmpty) {
          query = query.where('subCategoryId', isEqualTo: subCategoryId);
        }
        if (productType != null && productType != 'all' && productType.isNotEmpty) {
          query = query.where('itemCondition', isEqualTo: productType);
        }
      } else {
        // النظام القديم: typeItem
        debugPrint("📱 EnhancedProductGrid: تطبيق فلتر النظام القديم: typeItem=$currentFilterKey");
        query = query.where('typeItem', isEqualTo: currentFilterKey);
      }
    }

    // ترتيب بالوقت (الأحدث أولاً)
    query = query.orderBy('timestamp', descending: true);

    // تطبيق الحد إذا كان محددًا
    if (maxItems != null) {
      query = query.limit(maxItems!);
    } else {
      query = query.limit(50);
    }

    debugPrint("📱 [EnhancedProductGrid] الاستعلام النهائي جاهز للتنفيذ");
    debugPrint("📊 [EnhancedProductGrid] معايير الفلترة المطبقة:");
    debugPrint("   - الفلتر: $currentFilterKey");
    debugPrint("   - الحد الأقصى للعناصر: ${maxItems ?? 50}");
    debugPrint("══════════════════════════════════════════════════");
    
    return query.snapshots();
  }

  /// بناء شبكة المنتجات
  Widget _buildProductGrid(BuildContext context, List<ItemModel> items, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildProductCard(context, item, theme);
        },
      ),
    );
  }

  /// بناء بطاقة المنتج
  Widget _buildProductCard(BuildContext context, ItemModel item, ThemeData theme) {
    final favoriteController = Get.put(FavoriteController());

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Get.to(() => DetailsOfItemScreen(item: item)),
        onTapDown: _isAdmin ? (details) => _showAdminContextMenu(context, details, item) : null,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة المنتج
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: CachedNetworkImage(
                    imageUrl: item.imageUrl ?? '',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.error, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
            
            // معلومات المنتج
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // اسم المنتج
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // نوع المنتج
                    Text(
                      item.typeItem,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const Spacer(),
                    
                    // السعر وأزرار الإضافة/المفضلة
                    Row(
                      children: [
                        // السعر
                        Text(
                          '${item.price} ${FirebaseX.currency ?? ''}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                        const Spacer(),
                        
                        // زر المفضلة
                        StreamBuilder<bool>(
                          stream: favoriteController.isFavoriteStream(item.id),
                          builder: (context, snapshot) {
                            final bool isFavorite = snapshot.data ?? false;
                            return IconButton(
                              icon: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: Colors.red,
                                size: 20,
                              ),
                              onPressed: () => favoriteController.toggleFavorite(item.id, isFavorite),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                            );
                          },
                        ),
                        
                        // زر الإضافة للسلة
                        BoxAddAndRemove(
                          uidItem: item.id,
                          uidAdd: item.uidAdd,
                          price: item.price,
                          name: item.name,
                          isOffer: item.isOffer,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// عرض قائمة السياق للأدمن
  Future<void> _showAdminContextMenu(BuildContext context, TapDownDetails details, ItemModel item) async {
    if (!_isAdmin) return;

    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
        details.globalPosition & const Size(40, 40),
        Offset.zero & overlay.size
    );

    final String? selectedValue = await showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      elevation: 8.0,
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'edit_name',
          child: const ListTile(
            leading: Icon(Icons.edit_outlined, size: 20),
            title: Text('تعديل الاسم'),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem<String>(
          value: 'edit_price',
          child: const ListTile(
            leading: Icon(Icons.price_change_outlined, size: 20),
            title: Text('تعديل السعر'),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem<String>(
          value: 'add_as_offer',
          child: ListTile(
            leading: Icon(Icons.local_offer_outlined, color: Colors.blue[700]),
            title: Text('إضافة كعرض', style: TextStyle(color: Colors.blue[700])),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete_outline, color: Colors.red[700], size: 20),
            title: Text('حذف المنتج', style: TextStyle(color: Colors.red[700])),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );

    // معالجة اختيار الأدمن
    switch (selectedValue) {
      case 'edit_name':
        _showEditDialog(context, item, isEditingName: true);
        break;
      case 'edit_price':
        _showEditDialog(context, item, isEditingName: false);
        break;
      case 'add_as_offer':
        _showAddOfferDialog(context, item);
        break;
      case 'delete':
        _showDeleteConfirmationDialog(context, item.id);
        break;
    }
  }

  /// حوار تعديل المنتج
  void _showEditDialog(BuildContext context, ItemModel item, {required bool isEditingName}) {
    final TextEditingController controller = TextEditingController(
      text: isEditingName ? item.name : item.price.toString(),
    );

    Get.defaultDialog(
      title: isEditingName ? 'تعديل اسم المنتج' : 'تعديل سعر المنتج',
      content: TextField(
        controller: controller,
        keyboardType: isEditingName ? TextInputType.text : TextInputType.number,
        inputFormatters: isEditingName ? null : [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: isEditingName ? 'اسم المنتج' : 'السعر',
          border: const OutlineInputBorder(),
        ),
      ),
      textConfirm: 'حفظ',
      textCancel: 'إلغاء',
      onConfirm: () async {
        final newValue = controller.text.trim();
        if (newValue.isNotEmpty) {
          try {
            final updateData = isEditingName
                ? {'nameOfItem': newValue}
                : {'priceOfItem': double.parse(newValue)};

            await FirebaseFirestore.instance
                .collection(FirebaseX.itemsCollection)
                .doc(item.id)
                .update(updateData);

            Get.back();
            Get.snackbar(
              'تم بنجاح',
              'تم تحديث ${isEditingName ? 'اسم' : 'سعر'} المنتج',
              backgroundColor: Colors.green,
              colorText: Colors.white,
            );
          } catch (e) {
            Get.snackbar('خطأ', 'فشل في التحديث: $e', backgroundColor: Colors.red, colorText: Colors.white);
          }
        }
      },
    );
  }

  /// حوار إضافة عرض
  void _showAddOfferDialog(BuildContext context, ItemModel item) {
    final TextEditingController offerPriceController = TextEditingController();
    final TextEditingController rateController = TextEditingController();
    final Rxn<DateTime> expiryDate = Rxn<DateTime>(null);

    void calculateRate() {
      final double? newPrice = double.tryParse(offerPriceController.text.trim());
      if (newPrice != null && item.price > 0 && newPrice < item.price) {
        final double discount = ((item.price - newPrice) / item.price) * 100;
        rateController.text = discount.toStringAsFixed(0);
      } else {
        rateController.text = '';
      }
    }

    offerPriceController.addListener(calculateRate);

    Get.defaultDialog(
      title: "إضافة المنتج كعرض",
      content: SingleChildScrollView(
        child: Column(
          children: [
            Text("منتج: ${item.name}"),
            Text("السعر الأصلي: ${item.price} ${FirebaseX.currency ?? ''}"),
            const SizedBox(height: 16),
            TextField(
              controller: offerPriceController,
              decoration: const InputDecoration(
                labelText: "سعر العرض",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: rateController,
              decoration: const InputDecoration(
                labelText: "نسبة الخصم (%)",
                border: OutlineInputBorder(),
              ),
              enabled: false,
            ),
            const SizedBox(height: 16),
            Obx(() => ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(
                expiryDate.value == null
                    ? "تحديد تاريخ انتهاء العرض (اختياري)"
                    : "ينتهي في: ${DateFormat('yyyy/MM/dd').format(expiryDate.value!)}"
              ),
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 7)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  expiryDate.value = picked;
                }
              },
            )),
          ],
        ),
      ),
      textConfirm: 'إضافة العرض',
      textCancel: 'إلغاء',
      onConfirm: () async {
        final double? offerPrice = double.tryParse(offerPriceController.text.trim());
        if (offerPrice != null && offerPrice > 0 && offerPrice < item.price) {
          try {
            // إضافة منتج جديد كعرض
            final offerData = {
              'nameOfItem': item.name,
              'priceOfItem': offerPrice,
              'originalPrice': item.price,
              'url': item.imageUrl,
              'manyImages': item.manyImages,
              'videoURL': item.videoUrl ?? 'noVideo',
              'typeItem': item.typeItem,
              'itemCondition': item.itemCondition,
              'qualityGrade': item.qualityGrade,
              'countryOfOrigin': item.countryOfOrigin,
              'uidAdd': item.uidAdd,
              'appName': item.appName,
              'isOfer': true,
              'discountRate': double.parse(rateController.text.trim()),
              'expiryDate': expiryDate.value,
              'timestamp': FieldValue.serverTimestamp(),
            };

            await FirebaseFirestore.instance
                .collection(FirebaseX.itemsCollection)
                .add(offerData);

            Get.back();
            Get.snackbar(
              'تم بنجاح',
              'تم إضافة المنتج كعرض',
              backgroundColor: Colors.green,
              colorText: Colors.white,
            );
          } catch (e) {
            Get.snackbar('خطأ', 'فشل في إضافة العرض: $e', backgroundColor: Colors.red, colorText: Colors.white);
          }
        } else {
          Get.snackbar('خطأ', 'يرجى إدخال سعر عرض صحيح', backgroundColor: Colors.orange, colorText: Colors.white);
        }
      },
    );
  }

  /// حوار تأكيد الحذف
  void _showDeleteConfirmationDialog(BuildContext context, String itemId) {
    Get.defaultDialog(
      title: 'تأكيد الحذف',
      middleText: 'هل أنت متأكد من حذف هذا المنتج؟ لا يمكن التراجع عن هذا الإجراء.',
      textConfirm: 'حذف',
      textCancel: 'إلغاء',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        try {
          await FirebaseFirestore.instance
              .collection(FirebaseX.itemsCollection)
              .doc(itemId)
              .delete();

          Get.back();
          Get.snackbar(
            'تم بنجاح',
            'تم حذف المنتج',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } catch (e) {
          Get.snackbar('خطأ', 'فشل في حذف المنتج: $e', backgroundColor: Colors.red, colorText: Colors.white);
        }
      },
    );
  }

  /// widget حالة الخطأ
  Widget _buildErrorWidget(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'حدث خطأ في تحميل المنتجات',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // إعادة تحميل
            },
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  /// widget حالة فارغة
  Widget _buildEmptyStateWidget(BuildContext context, EnhancedCategoryFilterController filterController) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            filterController.hasActiveFilter.value
                ? 'لا توجد منتجات في هذا القسم'
                : 'لا توجد منتجات متاحة',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (filterController.hasActiveFilter.value) ...[
            Text(
              'جرب تصفية أخرى أو اعرض جميع المنتجات',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => filterController.resetFilters(),
              child: const Text('عرض جميع المنتجات'),
            ),
          ],
        ],
      ),
    );
  }

  /// شكل تحميل مع Shimmer
  Widget _buildLoadingShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 14,
                            width: double.infinity,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 12,
                            width: 100,
                            color: Colors.white,
                          ),
                          const Spacer(),
                          Container(
                            height: 14,
                            width: 80,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
} 