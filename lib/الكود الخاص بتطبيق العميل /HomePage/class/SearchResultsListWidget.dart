import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';

// استيراد Widget الأزرار
import '../../../Model/model_item.dart';
import '../../../XXX/xxx_firebase.dart';
import '../Get-Controllar/addAndRemoveSearch.dart'; // أو AddAndRemoveSearchWidget الجديد
// استيراد شاشة التفاصيل
import 'DetailsOfItemScreen.dart';

class SearchResultsListWidget extends StatelessWidget {
  final String searchQuery;
  // حد أدنى لعدد الأحرف لبدء البحث
  static const int minChars = 1; // زيادة إلى 2 أو 3 قد يحسن الأداء

  const SearchResultsListWidget({super.key, required this.searchQuery});

  // Stream لبناء نتائج البحث
  Stream<QuerySnapshot<Map<String, dynamic>>> _buildSearchStream() {
    // إرجاع Stream فارغ إذا كان الاستعلام قصيرًا جدًا
    if (searchQuery.trim().length < minChars) {
      // ---!!! الإصلاح هنا !!!---
      return Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }

    // تهيئة البحث (يفضل تحويل النص المخزن في Firestore للحالة الصغيرة أيضًا عند الحفظ)
    final String term = searchQuery.trim().toLowerCase();

    // بناء الاستعلام
    // ملاحظة: يعتمد هذا الاستعلام على وجود فهرس مناسب في Firestore على حقل name
    // وتحتاج إلى تحويل الحقل name في Firestore إلى حالة الأحرف الصغيرة عند حفظ البيانات لضمان مطابقة case-insensitive.
    // الطريقة الحالية ستطابق فقط الكلمات التي تبدأ بـ term بنفس الحالة (أو أكبر منها).
    return FirebaseFirestore.instance
        .collection(FirebaseX.itemsCollection) // 'Items' مثلاً
        .where('appName', isEqualTo: FirebaseX.appName)
        // --- بديل لتحسين البحث (يتطلب تعديل Firestore أو استخدام خدمة بحث خارجية) ---
        .where(
          'nameOfItem',
          isGreaterThanOrEqualTo: term,
        ) // --- يتطلب أن يكون حقل name بحالة صغيرة في Firestore ---
        .where(
          'nameOfItem',
          isLessThan: '$term\uf8ff',
        ) // للحصول على كل ما يبدأ بـ term
        .orderBy('nameOfItem') // ترتيب النتائج أبجدياً
        .limit(20) // تحديد عدد النتائج
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final hi = MediaQuery.of(context).size.height;
    final wi = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);

    // عرض رسالة مطالبة بالكتابة إذا كان الاستعلام قصيرًا جدًا
    if (searchQuery.trim().length < minChars) {
      return Padding(
        padding: const EdgeInsets.only(top: 50.0),
        child: Center(
          child: Text(
            'اكتب حرفًا واحدًا على الأقل للبحث...', // <<-- تعريب
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ),
      );
    }

    // بناء الواجهة بناءً على حالة الـ Stream
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _buildSearchStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint("Search Error: ${snapshot.error}");
          return const Center(
            child: Text('حدث خطأ أثناء البحث. حاول مرة أخرى.'),
          ); // <<-- تعريب
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          // عرض مؤشر تحميل أثناء البحث
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator(strokeWidth: 3)),
          );
        }

        // الحصول على قائمة المستندات (تكون قائمة فارغة إذا لم تكن هناك بيانات)
        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          // عرض رسالة إذا لم يتم العثور على نتائج
          return Padding(
            padding: const EdgeInsets.only(top: 50.0, left: 20, right: 20),
            child: Center(
              child: Text(
                'لا توجد نتائج تطابق "$searchQuery".', // <<-- تعريب
                style: TextStyle(color: Colors.grey[700], fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        // بناء قائمة النتائج
        return ListView.builder(
          // NeverScrollableScrollPhysics لأنها غالبًا داخل SingleChildScrollView أو Column
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true, // لتأخذ حجم المحتوى فقط
          itemCount: docs.length,
          itemBuilder: (context, index) {
            try {
              // تأكد من معالجة الخطأ إذا فشل fromMap
              final item = ItemModel.fromMap(
                docs[index].data(),
                docs[index].id,
              );
              return _buildResultItem(context, item, wi, hi, theme);
            } catch (e, s) {
              debugPrint("Error parsing search result at index $index: $e\n$s");
              // عرض عنصر خطأ واضح في القائمة
              return ListTile(
                leading: Icon(Icons.error_outline, color: Colors.red[300]),
                title: Text("خطأ في عرض هذه النتيجة"), // <<-- تعريب
                tileColor: Colors.red[50],
              );
            }
          },
        );
      },
    );
  }

  // بناء عنصر نتيجة بحث فردي
  Widget _buildResultItem(
    BuildContext context,
    ItemModel item,
    double wi,
    double hi,
    ThemeData theme,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ), // مسافات حول البطاقة
      elevation: 1.5, // ظل خفيف جداً
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        // جعل العنصر قابلاً للنقر
        borderRadius: BorderRadius.circular(10), // لمطابقة شكل البطاقة
        onTap: () {
          // الانتقال إلى شاشة التفاصيل
          Get.to(() => DetailsOfItemScreen(item: item));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12.0,
            vertical: 10.0,
          ), // مسافات داخلية
          child: Row(
            children: [
              // الصورة المصغرة مع Hero Animation
              Hero(
                tag: 'item_image_${item.id}', // نفس الـ tag في الشبكة والتفاصيل
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: item.imageUrl ?? '',
                    height: hi * 0.08, // ارتفاع مناسب للقائمة
                    width: wi * 0.18, // عرض مناسب للقائمة
                    fit: BoxFit.cover,
                    placeholder:
                        (c, u) => Container(
                          color: Colors.grey[200],
                          height: hi * 0.08,
                          width: wi * 0.18,
                        ),
                    errorWidget:
                        (c, u, e) => Container(
                          color: Colors.grey[100],
                          height: hi * 0.08,
                          width: wi * 0.18,
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: Colors.grey,
                          ),
                        ),
                  ),
                ),
              ),

              const SizedBox(width: 12), // مسافة بين الصورة والنص
              // الاسم والسعر
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: wi * 0.038,
                      ), // خط أعرض قليلاً
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: hi * 0.006), // مسافة صغيرة
                    Text(
                      '${item.suggestedRetailPrice ?? item.price} ${FirebaseX.currency}',
                      style: TextStyle(
                        fontSize: wi / 32,
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10), // مسافة قبل أزرار +/-
              // أزرار الإضافة والإزالة (استخدام الويدجت المصححة)
              // مرر isOffer بشكل صحيح
              AddAndRemoveSearchWidget(
                uidItem: item.id,
                isOffer: false, // المنتج من البحث ليس عرضًا
                uidAdd: item.uidAdd,
                // تخصيص أحجام الأزرار والأيقونات لتناسب القائمة
                buttonHeight: hi * 0.045,
                buttonWidth: wi * 0.08,
                iconSize: wi * 0.05,
                numberFontSize: wi * 0.04,
                spacing: wi * 0.01,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
