import 'package:cloud_firestore/cloud_firestore.dart';

import 'FirestoreConstants.dart';
import 'MessageStatus.dart';


class Message {
  final String messageId; // Unique ID (UUID v1 likely) - Used as local and Firestore doc ID
  final String senderId;
  final String recipientId;
  final String content;     // Text content OR the *REMOTE URL* for media from Firebase Storage
  final String type;        // e.g., FirestoreConstants.typeText, typeImage, etc.
  final Timestamp timestamp; // Firestore Timestamp for sorting and display
  final MessageStatus status; // Tracks the lifecycle state (from MessageStatus enum)
  final String? localThumbnailPath; // مسار المصغرة المخزنة محليًا
  final bool isEdited;
  final Map<String, dynamic>? linkPreviewData; // بيانات مثل title, description, image, siteName, url


  // Optional fields, mainly for local storage and media handling:
  final String? localFilePath;  // Local path ONLY after media is downloaded/saved
  final String? thumbnailUrl;   // Remote URL for video/image thumbnail (stored in Firestore too)
  final String? originalFileName; // Useful for displaying/saving downloaded files

  // --- تحسينات محتملة ---
  final String? quotedMessageId; // ID of the message being replied to (for Reply feature)
  final String? quotedMessageText; // Text snippet of the replied message
  final String? quotedMessageSenderId; // Sender of the replied message
  // Map<String, Timestamp>? reactions; // For message reactions feature { "userId": timestamp }

  // Helper field, not stored directly in DB usually, calculated on fetch/display
  final bool isMe;

  const Message({
    required this.messageId,
    required this.senderId,
    this.linkPreviewData,
    this.isEdited = false, // القيمة الافتراضية
    this.localThumbnailPath, // <--- أضفه هنا
    required this.recipientId,
    required this.content,
    required this.type,
    required this.timestamp,
    required this.status,
    required this.isMe, // This should be determined when fetching/creating
    this.localFilePath,
    this.thumbnailUrl,
    this.originalFileName,
    this.quotedMessageId,
    this.quotedMessageText,
    this.quotedMessageSenderId,
    // this.reactions,
  });

  // --- تحويل من وإلى Map (مهم لـ Firestore و SQLite) ---

  /// Creates a Message instance from a Firestore document snapshot.
  factory Message.fromFirestore(DocumentSnapshot doc, String currentUserId) {
    final data = doc.data() as Map<String, dynamic>? ?? {}; // Handle null data safely
    final String senderId = data[FirestoreConstants.senderId] ?? 'unknown_sender';

    // تحديد الحالة الأولية للمستقبل عند الجلب من Firestore
    // (نفترض أنها وصلت إذا كانت موجودة في Firestore)
    MessageStatus initialStatus;
    final String type = data[FirestoreConstants.messageType] ?? FirestoreConstants.typeText;
    if(senderId == currentUserId) {
      // Status for messages I sent (already past pending/sending)
      initialStatus = data['status'] != null
          ? MessageStatus.values.byName(data['status']) // Try reading status if available
          : MessageStatus.sent; // Default for already sent messages
      // May need more logic for delivered/read from Firestore later
    } else {
      // Status for messages I received
      if(type == FirestoreConstants.typeText) {
        initialStatus = MessageStatus.received; // Text is received immediately
      } else {
        // Media needs download - determine status later based on local DB
        // Or assume needs download initially if just fetching from Firebase
        initialStatus = MessageStatus.received; // Default to received if it's in our listener?
        // More complex logic needed with local DB check
        // Or maybe Firestore trigger marks it received?
        // Let's assume for now Firestore only holds completed messages
      }
    }


    return Message(
      messageId: doc.id, // Use Firestore document ID as messageId
      senderId: senderId,
      recipientId: data[FirestoreConstants.recipientId] ?? 'unknown_recipient',
      content: data[FirestoreConstants.messageContent] ?? '',
      type: type,
      // التعامل الآمن مع Timestamp
      timestamp: data[FirestoreConstants.timestamp] is Timestamp
          ? data[FirestoreConstants.timestamp]
          : Timestamp.now(), // توفير قيمة افتراضية
      status: initialStatus, // قد تحتاج لتعديل الحالة بناءً على مصدر الجلب (local vs remote)
      thumbnailUrl: data[FirestoreConstants.thumbnailUrl],
      // isMe يتم حسابها هنا
      isMe: senderId == currentUserId,
      // Fields usually not directly in Firestore message doc:
      localFilePath: null, // سيبقى null عند الجلب من Firestore مباشرة
      originalFileName: null, // سيبقى null عند الجلب من Firestore مباشرة
      // Parse reply info if exists
      quotedMessageId: data['quotedMessageId'],
      quotedMessageText: data['quotedMessageText'],
      quotedMessageSenderId: data['quotedMessageSenderId'],
      isEdited: data['isEdited'] ?? false, // لـ Firestore

    );
  }

  /// Creates a Message instance from a Map (e.g., from SQLite).
  /// Note: Timestamp might be stored as ISO string or integer in SQLite.
  factory Message.fromMap(Map<String, dynamic> map, String currentUserId) {
    final String senderId = map['senderId'] ?? 'unknown';
    final bool calculatedIsMe = senderId.isNotEmpty && senderId == currentUserId;

    return Message(
      messageId: map['messageId'] ?? '',
      senderId: senderId,
      recipientId: map['recipientId'] ?? '',
      localThumbnailPath: map['localThumbnailPath'], // <-- قراءته من SQLite
      content: map['content'] ?? '',
      type: map['type'] ?? FirestoreConstants.typeText,
      // تحويل Timestamp من SQLite (نفترض تخزينها كانتجر لـ millisecondsSinceEpoch)
      timestamp: map['timestamp'] is int
          ? Timestamp.fromMillisecondsSinceEpoch(map['timestamp'])
          : Timestamp.now(), // أو معالجة صيغة أخرى (مثل String ISO8601)
      // تحويل Status من SQLite (نفترض تخزينها كنص مطابق لأسماء enum)
      status: map['status'] is String
          ? MessageStatus.values.firstWhere(
            (e) => e.name == map['status'],
        orElse: () => MessageStatus.failed, // قيمة افتراضية عند عدم العثور
      )
          : MessageStatus.pending, // قيمة افتراضية
      localFilePath: map['localFilePath'],
      thumbnailUrl: map['thumbnailUrl'],
      originalFileName: map['originalFileName'],
      quotedMessageId: map['quotedMessageId'],
      quotedMessageText: map['quotedMessageText'],
      isEdited: map['isEdited'] == 1, // لـ SQLite (إذا خزنت كـ 0 أو 1)
      quotedMessageSenderId: map['quotedMessageSenderId'],
      isMe: calculatedIsMe,
    );
  }


  /// Converts the Message instance to a Map suitable for Firestore.
  Map<String, dynamic> toFirestoreMap() {
    return {
      // لا نحتاج لتضمين messageId هنا لأنه سيكون معرف الوثيقة
      FirestoreConstants.senderId: senderId,
      FirestoreConstants.recipientId: recipientId,
      FirestoreConstants.messageContent: content, // هذا يجب أن يكون URL للوسائط
      FirestoreConstants.messageType: type,
      FirestoreConstants.timestamp: timestamp, // أو FieldValue.serverTimestamp() عند الإنشاء
      // Firestore might not store all local statuses, just final ones like sent/delivered/read
      // Or store the status enum name for sender's copy? Requires design choice.
      // 'status': status.name, // تخزين اسم الحالة؟ (اختياري للمرسل)
      FirestoreConstants.thumbnailUrl: thumbnailUrl, // ضروري للفيديو والصور
      // Store reply info if exists
      // if (quotedMessageId != null) 'quotedMessageId': quotedMessageId,
      // if (quotedMessageText != null) 'quotedMessageText': quotedMessageText,
      // if (quotedMessageSenderId != null) 'quotedMessageSenderId': quotedMessageSenderId,
      if (quotedMessageId != null && quotedMessageId!.isNotEmpty) 'quotedMessageId': quotedMessageId,
      if (quotedMessageText != null && quotedMessageText!.isNotEmpty) 'quotedMessageText': quotedMessageText,
      if (quotedMessageSenderId != null && quotedMessageSenderId!.isNotEmpty) 'quotedMessageSenderId': quotedMessageSenderId,
      if (isEdited) 'isEdited': true, // لـ Firestore

      // Store reactions map if not null/empty
      // if (reactions != null && reactions!.isNotEmpty) 'reactions': reactions,
    };
  }


  /// Converts the Message instance to a Map suitable for SQLite.
  // Map<String, dynamic> toSqliteMap() {
  //   return {
  //     'localThumbnailPath': localThumbnailPath, // <-- حفظه في SQLite
  //     'messageId': messageId, // يجب أن يكون المفتاح الأساسي في SQLite
  //     'senderId': senderId,
  //     'recipientId': recipientId,
  //     'content': content, // يمكن أن يكون نصًا أو remote URL
  //     'type': type,
  //     // تحويل Timestamp إلى صيغة مناسبة لـ SQLite (الأسهل هو millisecondsSinceEpoch)
  //     'timestamp': timestamp.millisecondsSinceEpoch,
  //     // تخزين اسم الحالة كنص
  //     'status': status.name,
  //     'localFilePath': localFilePath,
  //     'thumbnailUrl': thumbnailUrl,
  //     'originalFileName': originalFileName,
  //     'quotedMessageId': quotedMessageId,
  //     'quotedMessageText': quotedMessageText,
  //     'quotedMessageSenderId': quotedMessageSenderId,
  //     // لا نخزن isMe لأنه يمكن حسابه
  //     // لا نخزن Reactions مباشرة بهذه الطريقة، قد تحتاج جدول منفصل
  //   };
  // }



  Map<String, dynamic> toSqliteMap() {
    // ابدأ بالخريطة الأساسية
    final Map<String, dynamic> map = {
      'messageId': messageId,
      'senderId': senderId,
      'recipientId': recipientId,
      'content': content, // المحتوى (نص أو اسم ملف محلي مبدئياً للوسائط)
      'type': type,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status.name,
      // thumbnailUrl قد يكون مفيداً لتخزينه حتى لو كان null مبدئياً
      'thumbnailUrl': thumbnailUrl,
      // الأصل أفضل تخزينه
      'originalFileName': originalFileName,
      // الردود
      'quotedMessageId': quotedMessageId,
      'quotedMessageText': quotedMessageText,
      'quotedMessageSenderId': quotedMessageSenderId,
      'isEdited': isEdited ? 1 : 0, // لـ SQLite
    };

    // --- أضف الحقول الاختيارية فقط إذا لم تكن null ---
    if (localFilePath != null && localFilePath!.isNotEmpty) {
      map['localFilePath'] = localFilePath;
    }
    if (localThumbnailPath != null && localThumbnailPath!.isNotEmpty) {
      map['localThumbnailPath'] = localThumbnailPath;
    }
    // ----------------------------------------------

    return map;
  }


  // --- نسخ الكائن مع تعديل بعض الحقول (copyWith) ---
  /// Creates a new Message instance with updated fields.
  Message copyWith({
    String? messageId,
    String? senderId,
    String? recipientId,
    String? content,
    String? type,
    bool? isEdited,
    Timestamp? timestamp,
    MessageStatus? status,

    bool? isMe,
    // استخدام Object مميز للإشارة إلى الرغبة في جعل القيمة null بشكل صريح
    Object? localFilePath = const _Undefined(),
    Object? localThumbnailPath = const _Undefined(), // <--- تعديل هنا
    Object? thumbnailUrl = const _Undefined(),
    Object? originalFileName = const _Undefined(),
    Object? quotedMessageId = const _Undefined(),
    Object? quotedMessageText = const _Undefined(),
    Object? quotedMessageSenderId = const _Undefined(),
  }) {
    String? resolveStringField(Object? newValue, String? currentValue) {
      if (newValue is _Undefined) return currentValue; // لم يتم التمرير، استخدم القديم
      return newValue as String?; // مرر الجديد (قد يكون null)
    }

    return Message(
      messageId: messageId ?? this.messageId,
      senderId: senderId ?? this.senderId,
      recipientId: recipientId ?? this.recipientId,
      content: content ?? this.content,
      // localThumbnailPath: localThumbnailPath is _Undefined ? this.localThumbnailPath : localThumbnailPath as String,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      isMe: isMe ?? this.isMe,
      localFilePath: localFilePath is _Undefined ? this.localFilePath : localFilePath as String?,
      thumbnailUrl: resolveStringField(thumbnailUrl, this.thumbnailUrl),                 // <-- تطبيق الدالة
      localThumbnailPath: resolveStringField(localThumbnailPath, this.localThumbnailPath), // <-- تطبيق الدالة
      originalFileName: originalFileName is _Undefined ? this.originalFileName : originalFileName as String?,
      quotedMessageId: quotedMessageId is _Undefined ? this.quotedMessageId : quotedMessageId as String?,
      quotedMessageText: quotedMessageText is _Undefined ? this.quotedMessageText : quotedMessageText as String?,
      quotedMessageSenderId: quotedMessageSenderId is _Undefined ? this.quotedMessageSenderId : quotedMessageSenderId as String?,
    );
  }

  // يمكنك إضافة override لـ toString, hashCode, و operator == إذا احتجت
  @override
  String toString() {
    return 'Message(messageId: $messageId, type: $type, status: $status, sender: $senderId, content: ${content.substring(0, content.length > 30 ? 30 : content.length)}...)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Message &&
              runtimeType == other.runtimeType &&
              messageId == other.messageId;

  @override
  int get hashCode => messageId.hashCode;

}

// Helper class for copyWith to differentiate between setting null explicitly
// and not providing a value (keeping the original).
class _Undefined {
  const _Undefined();
}