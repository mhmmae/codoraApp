# قواعد النماذج (Models) في مشروع كودورا

## 📋 **القاعدة الأساسية:**
> **جميع النماذج (Models) يجب أن تكون في مجلد `lib/Model/` فقط!**

---

## 🎯 **لماذا هذه القاعدة مهمة؟**

### ✅ **الفوائد:**
1. **سهولة الوصول:** جميع التطبيقات الأربعة يمكنها الوصول للنماذج
2. **تجنب التكرار:** نموذج واحد للمنتج بدلاً من 4 نماذج مختلفة
3. **سهولة الصيانة:** تعديل واحد يؤثر على جميع التطبيقات
4. **التنظيم:** مكان واحد لجميع هياكل البيانات
5. **الوضوح:** سهولة العثور على أي نموذج

### ❌ **المشاكل التي تحلها:**
- عدم وجود نماذج متكررة في مجلدات مختلفة
- تضارب في تعريف نفس البيانات
- صعوبة في التحديث والصيانة
- فقدان الوقت في البحث عن النماذج

---

## 📁 **هيكل مجلد lib/Model/**

```
lib/Model/
├── README.md                    # توثيق النماذج
├── ItemModel.dart              # نموذج المنتج الأساسي
├── ModelOfferItem.dart         # نموذج عروض المنتجات
├── ModelUser.dart              # نموذج المستخدم
├── ModelOrder.dart             # نموذج الطلب
├── ModelCategory.dart          # نموذج الفئة
├── ModelCompany.dart           # نموذج الشركة
├── ModelDelivery.dart          # نموذج التوصيل
├── ModelPayment.dart           # نموذج الدفع
├── ModelNotification.dart      # نموذج الإشعارات
├── ModelReview.dart            # نموذج التقييمات
├── ModelCart.dart              # نموذج سلة التسوق
└── ModelSettings.dart          # نموذج الإعدادات
```

---

## 🔧 **متطلبات كل Model:**

### **1. البنية الأساسية:**
```dart
class ExampleModel {
  // الحقول (Fields)
  final String id;
  final String name;
  final DateTime createdAt;
  
  // Constructor
  ExampleModel({
    required this.id,
    required this.name,
    required this.createdAt,
  });
  
  // الطرق المطلوبة
  factory ExampleModel.fromMap(Map<String, dynamic> map, String documentId) {
    // تحويل من Map إلى Object
  }
  
  Map<String, dynamic> toMap() {
    // تحويل من Object إلى Map
  }
  
  // طرق اختيارية
  factory ExampleModel.fromJson(String json) => ExampleModel.fromMap(jsonDecode(json), '');
  String toJson() => jsonEncode(toMap());
  
  @override
  String toString() {
    return 'ExampleModel(id: $id, name: $name, createdAt: $createdAt)';
  }
}
```

### **2. الطرق المطلوبة:**
- ✅ `fromMap()` - تحويل من Firebase Map إلى Object
- ✅ `toMap()` - تحويل من Object إلى Firebase Map
- ⚡ `fromJson()` - تحويل من JSON (اختياري)
- ⚡ `toJson()` - تحويل إلى JSON (اختياري)
- ⚡ `toString()` - عرض محتوى الكائن (للتسهيل في التصحيح)

### **3. التعليقات والتوثيق:**
```dart
/// نموذج المنتج الأساسي
/// يحتوي على جميع المعلومات الخاصة بالمنتج
/// يستخدم في جميع التطبيقات الأربعة
class ItemModel {
  /// معرف المنتج الفريد
  final String id;
  
  /// اسم المنتج
  final String name;
  
  /// وصف المنتج
  final String? description;
  
  // ... باقي الحقول
}
```

---

## 🚀 **كيفية الاستيراد:**

### ✅ **الطريقة الصحيحة:**
```dart
// في أي تطبيق من التطبيقات الأربعة
import '../../Model/ItemModel.dart';
import '../../Model/ModelUser.dart';
import '../../Model/ModelOrder.dart';

// مثال في تطبيق البائع
// lib/الكود الخاص بتطبيق البائع/controllers/products_controller.dart
import '../../Model/ItemModel.dart';

// مثال في تطبيق العميل
// lib/الكود الخاص بتطبيق العميل/widgets/product_card.dart
import '../../Model/ItemModel.dart';
```

### ❌ **طرق خاطئة:**
```dart
// لا تضع Models في مجلدات التطبيقات
❌ lib/الكود الخاص بتطبيق البائع/models/item_model.dart

// لا تضع Models في shared
❌ lib/shared/models/item_model.dart

// لا تنشئ نماذج متكررة
❌ lib/الكود الخاص بتطبيق العميل/models/product_model.dart (نفس ItemModel)
```

---

## 📝 **أمثلة لنماذج مطلوبة:**

### **1. نموذج المنتج:**
```dart
// lib/Model/ItemModel.dart
class ItemModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String sellerId;
  final String mainCategoryId;
  final String subCategoryId;
  final String itemCondition; // 'original' or 'commercial'
  final List<String> images;
  final DateTime timestamp;
  final bool isActive;
  
  // المطلوب: fromMap, toMap, toString
}
```

### **2. نموذج المستخدم:**
```dart
// lib/Model/ModelUser.dart
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String userType; // 'customer', 'seller', 'delivery', 'admin'
  final String? profileImage;
  final DateTime createdAt;
  final bool isActive;
  
  // المطلوب: fromMap, toMap, toString
}
```

### **3. نموذج الطلب:**
```dart
// lib/Model/ModelOrder.dart
class OrderModel {
  final String id;
  final String customerId;
  final String sellerId;
  final String? deliveryId;
  final List<OrderItem> items;
  final double totalAmount;
  final String status; // 'pending', 'confirmed', 'shipped', 'delivered'
  final DateTime orderDate;
  final String deliveryAddress;
  
  // المطلوب: fromMap, toMap, toString
}
```

---

## ⚠️ **تحذيرات مهمة:**

### **عند إنشاء Model جديد:**
1. ✅ **تأكد من الحفظ في `lib/Model/`**
2. ✅ **استخدم تسمية واضحة (مثل: ProductModel.dart)**
3. ✅ **أضف جميع الطرق المطلوبة**
4. ✅ **اكتب تعليقات باللغة العربية**
5. ✅ **اختبر التحويل من وإلى Map**

### **عند تعديل Model موجود:**
1. ⚠️ **تأكد من تأثير التغيير على جميع التطبيقات**
2. ⚠️ **حدث جميع الملفات التي تستخدم هذا النموذج**
3. ⚠️ **اختبر التطبيقات الأربعة بعد التعديل**
4. ⚠️ **تأكد من عدم كسر Firebase operations**

---

## 🔄 **عند مخالفة القاعدة:**

إذا حاولت إنشاء Model خارج `lib/Model/`، ستظهر لك رسالة:

```
📋 تم اكتشاف إنشاء أو تعديل Model جديد!

🎯 في مشروع كودورا، جميع النماذج يجب أن تكون في:
📁 lib/Model/

الخيارات:
✅ نقل إلى lib/Model/ (مستحسن)
📝 تحديد اسم مختلف في lib/Model/
⚠️ الاحتفاظ بالمكان الحالي (غير مستحسن)
❌ إلغاء العملية
```

---

## 🎯 **الهدف النهائي:**

**مشروع منظم حيث جميع التطبيقات الأربعة تستخدم نفس النماذج المحفوظة في مكان واحد، مما يضمن الاتساق والكفاءة في التطوير والصيانة.**

---

## 📚 **مراجع مفيدة:**

- [دليل Flutter للنماذج](https://flutter.dev/docs)
- [أفضل ممارسات Dart](https://dart.dev/guides/language/effective-dart)
- [Firebase Firestore Models](https://firebase.google.com/docs/firestore)

**تذكر: مجلد `lib/Model/` هو المنزل الوحيد لجميع النماذج في مشروع كودورا! 🏠** 