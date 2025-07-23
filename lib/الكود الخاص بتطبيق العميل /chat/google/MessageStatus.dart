/// تعداد حالات الرسائل في نظام الدردشة
enum MessageStatus {
  /// الرسالة قيد الإرسال
  sending,

  /// تم إرسال الرسالة بنجاح
  sent,

  /// تم تسليم الرسالة للمستلم
  delivered,

  /// تمت قراءة الرسالة من قبل المستلم
  read,

  /// فشل في إرسال الرسالة
  failed,

  /// الرسالة معلقة في الانتظار
  pending,

  /// تم تحديث الرسالة
  updated,

  /// تم حذف الرسالة
  deleted,

  /// الرسالة مؤرشفة
  archived,

  /// تم استلام الرسالة
  received,

  /// جارٍ تحميل الملف/الوسائط
  downloading,

  /// فشل في تحميل الملف/الوسائط
  downloadFailed,
}

/// إضافة طرق مساعدة لحالات الرسائل
extension MessageStatusExtension on MessageStatus {
  /// الحصول على نص وصفي لحالة الرسالة
  String get displayText {
    switch (this) {
      case MessageStatus.sending:
        return 'جارٍ الإرسال...';
      case MessageStatus.sent:
        return 'تم الإرسال';
      case MessageStatus.delivered:
        return 'تم التسليم';
      case MessageStatus.read:
        return 'تمت القراءة';
      case MessageStatus.failed:
        return 'فشل الإرسال';
      case MessageStatus.pending:
        return 'في الانتظار';
      case MessageStatus.updated:
        return 'محدثة';
      case MessageStatus.deleted:
        return 'محذوفة';
      case MessageStatus.archived:
        return 'مؤرشفة';
      case MessageStatus.received:
        return 'تم الاستلام';
      case MessageStatus.downloading:
        return 'جارٍ التحميل...';
      case MessageStatus.downloadFailed:
        return 'فشل التحميل';
    }
  }

  /// الحصول على أيقونة لحالة الرسالة
  String get icon {
    switch (this) {
      case MessageStatus.sending:
        return '⏳';
      case MessageStatus.sent:
        return '✓';
      case MessageStatus.delivered:
        return '✓✓';
      case MessageStatus.read:
        return '✓✓';
      case MessageStatus.failed:
        return '❌';
      case MessageStatus.pending:
        return '⏱️';
      case MessageStatus.updated:
        return '✏️';
      case MessageStatus.deleted:
        return '🗑️';
      case MessageStatus.archived:
        return '📁';
      case MessageStatus.received:
        return '📩';
      case MessageStatus.downloading:
        return '⬇️';
      case MessageStatus.downloadFailed:
        return '❌⬇️';
    }
  }

  /// التحقق من إذا كانت الرسالة قد تم إرسالها بنجاح
  bool get isSuccessful {
    return this == MessageStatus.sent ||
        this == MessageStatus.delivered ||
        this == MessageStatus.read ||
        this == MessageStatus.received;
  }

  /// التحقق من إذا كانت الرسالة قيد المعالجة
  bool get isProcessing {
    return this == MessageStatus.sending ||
        this == MessageStatus.pending ||
        this == MessageStatus.downloading;
  }

  /// التحقق من إذا كانت الرسالة فاشلة
  bool get isFailed {
    return this == MessageStatus.failed || this == MessageStatus.downloadFailed;
  }

  /// التحقق من إذا كانت الرسالة مقروءة
  bool get isRead {
    return this == MessageStatus.read;
  }

  /// التحقق من إذا كانت الرسالة مسلمة
  bool get isDelivered {
    return this == MessageStatus.delivered || this == MessageStatus.read;
  }
}

/// تحويل النص إلى حالة رسالة
MessageStatus messageStatusFromString(String status) {
  switch (status.toLowerCase()) {
    case 'sending':
      return MessageStatus.sending;
    case 'sent':
      return MessageStatus.sent;
    case 'delivered':
      return MessageStatus.delivered;
    case 'read':
      return MessageStatus.read;
    case 'failed':
      return MessageStatus.failed;
    case 'pending':
      return MessageStatus.pending;
    case 'updated':
      return MessageStatus.updated;
    case 'deleted':
      return MessageStatus.deleted;
    case 'archived':
      return MessageStatus.archived;
    case 'received':
      return MessageStatus.received;
    case 'downloading':
      return MessageStatus.downloading;
    case 'downloadfailed':
    case 'download_failed':
      return MessageStatus.downloadFailed;
    default:
      return MessageStatus.pending;
  }
}

/// تحويل حالة الرسالة إلى نص
String messageStatusToString(MessageStatus status) {
  return status.toString().split('.').last;
}
