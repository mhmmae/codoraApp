// في ملف: models/review_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String userId;
  final String userName;
  final String? userImageUrl;
  final String productId;
  final double rating;
  final String? comment;
  final Timestamp timestamp;
  // ---!!! حقول جديدة !!!---
  final int likesCount; // عدد الإعجابات الإجمالي
  // ملاحظة: لا نخزن قائمة الردود هنا، بل نستخدم مجموعة فرعية
  // ---------------------

  ReviewModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userImageUrl,
    required this.productId,
    required this.rating,
    this.comment,
    required this.timestamp,
    this.likesCount = 0, // قيمة افتراضية
  });

  // في models/review_model.dart

  factory ReviewModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    // ----------------------------------------------
    final data = snapshot.data(); // سيُرجع Map<String, dynamic>?

    if (data == null) {
      // يمكنك التعامل مع هذه الحالة هنا أيضاً إذا أردت
      throw StateError("Missing data for Review ID: ${snapshot.id}");
    }

    // --- الوصول للبيانات بأمان ---
    Timestamp timestampData = data['timestamp'] as Timestamp? ?? Timestamp.now();

    return ReviewModel(
      id: snapshot.id,
      userId: data['userId'] as String? ?? 'unknown_user',
      userName: data['userName'] as String? ?? 'مستخدم مجهول',
      userImageUrl: data['userImageUrl'] as String?,
      productId: data['productId'] as String? ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      comment: data['comment'] as String?,
      timestamp: timestampData,
      likesCount: (data['likesCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'userId': userId,
      'userName': userName,
      if (userImageUrl != null) 'userImageUrl': userImageUrl,
      'productId': productId,
      'rating': rating,
      if (comment != null && comment!.isNotEmpty) 'comment': comment,
      'timestamp': timestamp,
      // --- حفظ الحقل الجديد ---
      'likesCount': likesCount, // حفظ العدد الحالي
    };
    return map;
  }

  // دالة لتحديث likesCount (إذا كنت ستستخدمها في تحديث جزئي)
  Map<String, dynamic> likesUpdateMap() {
    return {'likesCount': likesCount};
  }
}
// في ملف: models/reply_model.dart (أو ملف النماذج الرئيسي)

class ReplyModel {
  final String id;          // معرف مستند الرد نفسه في المجموعة الفرعية 'replies'
  final String userId;      // معرف المستخدم الذي كتب الرد
  final String userName;    // اسم المستخدم للعرض
  final String? userImageUrl;// رابط صورة المستخدم (اختياري)
  final String comment;     // نص الرد (هنا إجباري، لا معنى لرد فارغ)
  final Timestamp timestamp; // وقت إنشاء الرد

  const ReplyModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userImageUrl,
    required this.comment,
    required this.timestamp,
  });

  // دالة لتحويل مستند Firestore (Snapshot) إلى كائن ReplyModel
  factory ReplyModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();

    if (data == null) {
      // يمكنك التعامل مع هذه الحالة بشكل مختلف، ربما إرجاع كائن افتراضي أو رمي خطأ أوضح
      throw Exception("Document data was null for Reply ID: ${snapshot.id}");
    }

    // التأكد من وجود timestamp وتحويله
    Timestamp timestampData = data['timestamp'] as Timestamp? ?? Timestamp.now(); // استخدم الوقت الحالي كاحتياطي

    return ReplyModel(
      id: snapshot.id, // الحصول على ID المستند
      userId: data['userId'] as String? ?? 'unknown_user', // قيمة افتراضية آمنة
      userName: data['userName'] as String? ?? 'مستخدم مجهول', // قيمة افتراضية آمنة
      userImageUrl: data['userImageUrl'] as String?, // الصورة اختيارية
      comment: data['comment'] as String? ?? '(رد محذوف)', // قيمة افتراضية للتعليق إذا كان null
      timestamp: timestampData,
    );
  }

  // دالة لتحويل كائن ReplyModel إلى Map لحفظه في Firestore
  Map<String, dynamic> toMap() {
    return {
      // لا نحفظ الـ id هنا
      'userId': userId,
      'userName': userName,
      // حفظ الصورة فقط إذا كانت موجودة
      if (userImageUrl != null && userImageUrl!.isNotEmpty) 'userImageUrl': userImageUrl,
      'comment': comment, // التعليق إجباري عند الإنشاء
      'timestamp': timestamp, // يمكن استخدام FieldValue.serverTimestamp() عند الإرسال
    };
  }

// (اختياري) يمكنك إضافة Equatable للمقارنة إذا لزم الأمر
// @override
// List<Object?> get props => [id, userId, userName, comment, timestamp];

// @override
// bool? get stringify => true;
}