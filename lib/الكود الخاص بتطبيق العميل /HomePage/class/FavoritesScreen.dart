import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

// استيراد شاشة تفاصيل المنتج
import '../../../Model/model_item.dart';
import '../../../XXX/xxx_firebase.dart';
import 'DetailsOfItemScreen.dart';
// (اختياري) استيراد زر الإضافة/الإزالة إذا أردت عرضه هنا
import 'FavoriteController.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // حقن أو إيجاد متحكم المفضلة
    final FavoriteController favoriteCtrl = Get.put(FavoriteController());
    final theme = Theme.of(context); // الحصول على الثيم

    return Scaffold(
      appBar: AppBar(
        title: Text('المفضلة', style: TextStyle(color: theme.textTheme.titleLarge?.color)),
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        elevation: theme.appBarTheme.elevation ?? 0.5, // ظل خفيف للتمييز
        foregroundColor: theme.appBarTheme.foregroundColor ?? theme.colorScheme.primary, // لون أيقونة الرجوع
        // يمكن إزالة زر الرجوع الافتراضي إذا كان GetX يتعامل معه
        // leading: IconButton(icon: Icon(Icons.arrow_back_ios_new), onPressed: () => Get.back()),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        // --- بناء Stream لجلب معرفات المنتجات المفضلة ---
          stream: favoriteCtrl.getFavoritesStream(), // <--- استدعاء Stream من المتحكم
          builder: (context, favSnapshot) {

            // --- حالة الانتظار (أثناء جلب المفضلة) ---
            if (favSnapshot.connectionState == ConnectionState.waiting) {
              // يمكنك عرض هيكل تحميل هنا (Shimmer list)
              return _buildLoadingFavoritesList(context);
            }

            // --- حالة الخطأ في جلب المفضلة ---
            if (favSnapshot.hasError) {
              debugPrint("Error fetching favorites list: ${favSnapshot.error}");
              return Center(child: Text('حدث خطأ أثناء تحميل المفضلة.', style: TextStyle(color: Colors.red[700])));
            }

            // --- الحصول على قائمة معرّفات المنتجات المفضلة ---
            final favoriteProductIds = favSnapshot.data?.docs.map((doc) => doc.id).toList() ?? [];

            // --- إذا كانت المفضلة فارغة ---
            if (favoriteProductIds.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_border_rounded, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 20),
                    Text('قائمة المفضلة فارغة', style: theme.textTheme.headlineSmall?.copyWith(color: Colors.grey[600])),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: Text(
                        'أضف المنتجات التي تعجبك بالنقر على أيقونة القلب!',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                      ),
                    ),
                  ],
                ),
              );
            }

            // --- جلب تفاصيل المنتجات الفعلية باستخدام المعرّفات ---
            // ملاحظة: استخدام `whereIn` فعال حتى 30 عنصرًا حسب وثائق Firestore الجديدة
            // إذا كان المستخدم قد يضيف أكثر من ذلك، قد تحتاج لطرق أخرى (مثل denormalization)
            // لكن لهذا العدد المحدود، `whereIn` مقبول.
            debugPrint("Fetching details for favorite IDs: $favoriteProductIds");
            if (favoriteProductIds.length > 30) {
              debugPrint("Warning: 'whereIn' query used with more than 30 IDs, performance might be affected.");
            }
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection(FirebaseX.itemsCollection)
                // جلب المستندات التي يطابق معرّفها (__name__) المعرّفات في قائمة المفضلة
                    .where(FieldPath.documentId, whereIn: favoriteProductIds)
                    .snapshots(),
                builder: (context, productSnapshot) {
                  // --- حالة انتظار تحميل تفاصيل المنتجات ---
                  if (productSnapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingFavoritesList(context); // إعادة استخدام نفس شاشة التحميل
                  }

                  // --- حالة الخطأ في تحميل تفاصيل المنتجات ---
                  if (productSnapshot.hasError) {
                    debugPrint("Error fetching favorite product details: ${productSnapshot.error}");
                    return Center(child: Text('خطأ في تحميل تفاصيل المنتجات المفضلة.', style: TextStyle(color: Colors.red[700])));
                  }

                  final productDocs = productSnapshot.data?.docs ?? [];

                  // --- إذا لم يتم العثور على تفاصيل لأي سبب ---
                  if (productDocs.isEmpty) {
                    // قد يحدث هذا إذا تم حذف المنتج الأصلي بعد إضافته للمفضلة
                    return const Center(child: Text('لم يتم العثور على تفاصيل للمنتجات المفضلة.'));
                  }

                  // --- عرض قائمة المنتجات المفضلة ---
                  return ListView.builder(
                    itemCount: productDocs.length,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                    itemBuilder: (context, index) {
                      try {
                        final item = ItemModel.fromMap(productDocs[index].data(), productDocs[index].id);
                        // بناء عنصر القائمة للمفضلة
                        return _buildFavoriteListItem(context, item, favoriteCtrl, theme);
                      } catch (e, s) {
                        debugPrint("Error parsing favorite item at index $index: $e\n$s");
                        // عنصر خطأ في القائمة
                        return ListTile( leading: Icon(Icons.error_outline, color: Colors.red[200]), title: Text("خطأ في عرض هذا المنتج"), tileColor: Colors.red[50] );
                      }
                    },
                  );
                }
            );
          }
      ),
    );
  }

  // بناء واجهة هيكل التحميل لقائمة المفضلة
  Widget _buildLoadingFavoritesList(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.builder(
      itemCount: 5, // عرض 5 عناصر تحميل
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: ListTile(
          leading: Container( width: 55, height: 55, color: Colors.white), // لصورة مصغرة
          title: Container( height: 14, color: Colors.white, margin: EdgeInsets.only(bottom: 5)), // لاسم المنتج
          subtitle: Container( width: 100, height: 12, color: Colors.white), // للسعر أو تفاصيل أخرى
          trailing: Icon(Icons.favorite, color: theme.disabledColor.withOpacity(0.1)), // أيقونة قلب باهتة
        ),
      ),
    );
  }


  // بناء عنصر قائمة لمنتج مفضل
  Widget _buildFavoriteListItem(BuildContext context, ItemModel item, FavoriteController favoriteCtrl, ThemeData theme) {
    final wi = MediaQuery.of(context).size.width;
    final hi = MediaQuery.of(context).size.height;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell( // جعل العنصر قابلاً للنقر للانتقال للتفاصيل
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          // انتقل إلى شاشة تفاصيل المنتج
          Get.to(() => DetailsOfItemScreen(
            // ---!!! تمرير كائن OfferModel مباشرة !!!---
            item: item, // <-- تمرير الكائن نفسه
          ));
        },
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: [
              // --- الصورة المصغرة ---
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl ?? '',
                  height: hi * 0.08,
                  width: wi * 0.18,
                  fit: BoxFit.cover,
                  placeholder: (c, u) => Container(color: Colors.grey[200]),
                  errorWidget: (c, u, e) => Container(color: Colors.grey[100], child: const Icon(Icons.image_not_supported)),
                ),
              ),
              const SizedBox(width: 12),
              // --- الاسم والسعر ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.name,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: hi * 0.006),
                    Text('${item.price} ${FirebaseX.currency ?? 'ريال'}',
                        style: TextStyle(fontSize: wi / 32, color: theme.primaryColor, fontWeight: FontWeight.bold))
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // --- زر إزالة من المفضلة ---
              IconButton(
                icon: const Icon(Icons.favorite_rounded, color: Colors.redAccent),
                tooltip: 'إزالة من المفضلة',
                iconSize: 28,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(), // لتقليل حجم منطقة اللمس الزائدة
                onPressed: () {
                  // استدعاء دالة الإزالة مباشرة (مرر true لأننا متأكدون أنه في المفضلة هنا)
                  favoriteCtrl.toggleFavorite(item.id, true);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}