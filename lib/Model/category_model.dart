// models/category_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id; // معرف المستند
  final String nameEn; // الاسم/المعرف بالإنجليزي
  final String nameAr; // الاسم بالعربي للعرض
  final String? imageUrl; // رابط الصورة (اجعله اختياريًا احتياطًا)
  final int order;    // للترتيب
  final bool isActive; // هل هو فعال؟

  const CategoryModel({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    this.imageUrl,
    this.order = 0, // قيمة افتراضية للترتيب
    this.isActive = true, // قيمة افتراضية للفعالية
  });

// في models/category_model.dart
  factory CategoryModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return CategoryModel(
      id: snapshot.id,
      nameEn: data['name_en'] as String? ?? snapshot.id,
      // --- إضافة قيمة افتراضية واضحة ---
      nameAr: data['name_ar'] as String? ?? 'قسم غير معروف', // <-- أو أي نص افتراضي
      // ---------------------------------
      imageUrl: data['imageUrl'] as String?,
      order: (data['order'] as num?)?.toInt() ?? 999,
      isActive: data['isActive'] as bool? ?? false,
    );
  }

// لا تحتاج لدالة toMap() هنا إلا إذا كنت ستنشئها من داخل التطبيق بشكل مكثف
// عادة ما يتم إنشاؤها من شاشة الأدمن أو لوحة التحكم مباشرة
}