import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

// تأكد من صحة استيراد النماذج والحالات والثوابت
import 'Message.dart';
import 'MessageStatus.dart';
import 'ChatService.dart'; // نحتاجه مؤقتًا للحصول على currentUserId

const String _dbName = 'chat_database.db';
const String _messagesTable = 'messages'; // <--- تعريف اسم الجدول كثابت هنا
const int _dbVersion = 3;

class LocalDatabaseService extends GetxService {
  Database? _database;
  final Map<String, StreamController<List<Message>>> _streamControllers = {};
  // لا حاجة لـ _querySubscriptions غالبًا مع الطريقة الحالية للتنبيه

  // --- تهيئة الخدمة وقاعدة البيانات ---
  Future<LocalDatabaseService> init() async {
    await _ensureDbInitialized();
    if (kDebugMode) debugPrint("[LocalDatabaseService] Initialized successfully.");
    return this;
  }

  Future<int> deleteMessage(String messageId) async {
    final db = await _ensureDbInitialized();
    try {
      final count = await db.delete(
        _messagesTable,
        where: 'messageId = ?',
        whereArgs: [messageId],
      );
      if (kDebugMode) debugPrint("[LocalDBService] Deleted $count message(s) with ID: $messageId");
      return count;
    } catch (e) {
      if (kDebugMode) debugPrint("[LocalDBService] Error deleting message $messageId: $e");
      return 0;
    }
  }

  Future<Database> _ensureDbInitialized() async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, _dbName);
        // await deleteDatabase(path); // ONLY FOR DEBUGGING SCHEMA CHANGES
      _database = await openDatabase(
        path,
        version: _dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: _onConfigure,
        singleInstance: true,
      );
      if (kDebugMode) debugPrint("[LocalDatabaseService] DB opened/created. Path: $path, Version: $_dbVersion");
      return _database!;
    } catch (e, stackTrace) {
      if (kDebugMode) debugPrint("[LocalDatabaseService] Error initializing DB: $e\n$stackTrace");
      rethrow;
    }
  }

  // --- إنشاء وتحديث الجدول ---
  Future<void> _onCreate(Database db, int version) async {
    if (kDebugMode) debugPrint("[LocalDatabaseService] Creating tables for version $version...");
    await db.execute('''
      CREATE TABLE $_messagesTable (
        messageId TEXT PRIMARY KEY,
        senderId TEXT NOT NULL,
        recipientId TEXT NOT NULL,
        content TEXT NOT NULL,
        type TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        status TEXT NOT NULL,
        localFilePath TEXT,
        thumbnailUrl TEXT,
        originalFileName TEXT,
        localThumbnailPath TEXT,
        quotedMessageId TEXT,
        quotedMessageText TEXT,
        quotedMessageSenderId TEXT,
        isEdited INTEGER DEFAULT 0 NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_message_recipient ON $_messagesTable (recipientId, senderId)');
    await db.execute('CREATE INDEX idx_message_timestamp ON $_messagesTable (timestamp)');
    if (kDebugMode) debugPrint("[LocalDatabaseService] Tables and indexes created.");
  }


// LocalDatabaseService.dart
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (kDebugMode) {
      debugPrint("[LocalDB _onUpgrade] Upgrading DB from v$oldVersion to v$newVersion...");
    }

    if (oldVersion < 2) { // للترقية إلى الإصدار 2 (إذا لم تكن قد تمت)
      try {
        await db.execute('ALTER TABLE $_messagesTable ADD COLUMN localThumbnailPath TEXT');
        if (kDebugMode) debugPrint("  [LocalDB _onUpgrade] v2: Added localThumbnailPath column.");
      } catch (e) {
        if (e.toString().toLowerCase().contains("duplicate column name")) {
          if (kDebugMode) debugPrint("  [LocalDB _onUpgrade] v2 info: localThumbnailPath column already exists.");
        } else {
          if (kDebugMode) debugPrint("  !!! [LocalDB _onUpgrade] v2 Error: $e"); rethrow;
        }
      }
    }

    if (oldVersion < 3) { // للترقية إلى الإصدار 3 (يجب أن يتم هذا الآن)
      try {
        await db.execute('ALTER TABLE $_messagesTable ADD COLUMN isEdited INTEGER DEFAULT 0 NOT NULL'); // أضف NOT NULL إذا أردت
        if (kDebugMode) debugPrint("  [LocalDB _onUpgrade] v3: Added isEdited column with DEFAULT 0.");
      } catch (e) {
        if (e.toString().toLowerCase().contains("duplicate column name")) {
          if (kDebugMode) debugPrint("  [LocalDB _onUpgrade] v3 info: isEdited column already exists.");
        } else {
          if (kDebugMode) debugPrint("  !!! [LocalDB _onUpgrade] v3 Error: $e"); rethrow; // أعد رمي الخطأ ليوقف العملية إذا فشلت الترقية
        }
      }
    }
    // يمكنك إضافة if (oldVersion < 4) { ... } للترقيات المستقبلية
  }
  Future<Timestamp?> getEarliestLocalMessageTimestamp(String currentUserId, String otherUserId) async {
    final db = await _ensureDbInitialized();
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        _messagesTable,
        columns: ['timestamp'], // جلب حقل الطابع الزمني فقط
        where: '(senderId = ? AND recipientId = ?) OR (senderId = ? AND recipientId = ?)',
        whereArgs: [currentUserId, otherUserId, otherUserId, currentUserId],
        orderBy: 'timestamp ASC', // <--- التغيير الرئيسي هنا: الأقدم أولاً
        limit: 1,                 // أقدم رسالة فقط
      );
      if (maps.isNotEmpty && maps.first['timestamp'] != null) {
        return Timestamp.fromMillisecondsSinceEpoch(maps.first['timestamp'] as int);
      }
    } catch (e) {
      if (kDebugMode) debugPrint("[LocalDBService] Error fetching EARLIEST local timestamp for $currentUserId-$otherUserId: $e");
    }
    return null;
  }

  // في LocalDatabaseService.dart
  Future<Timestamp?> getLatestLocalMessageTimestamp(String currentUserId, String otherUserId) async {
    final db = await _ensureDbInitialized();
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        _messagesTable,
        columns: ['timestamp'], // جلب حقل الطابع الزمني فقط
        where: '(senderId = ? AND recipientId = ?) OR (senderId = ? AND recipientId = ?)',
        whereArgs: [currentUserId, otherUserId, otherUserId, currentUserId],
        orderBy: 'timestamp DESC', // الأحدث أولاً
        limit: 1,                  // آخر رسالة فقط
      );
      if (maps.isNotEmpty && maps.first['timestamp'] != null) {
        return Timestamp.fromMillisecondsSinceEpoch(maps.first['timestamp'] as int);
      }
    } catch (e) {
      if (kDebugMode) debugPrint("[LocalDBService] Error fetching latest local timestamp for $currentUserId-$otherUserId: $e");
    }
    return null;
  }




  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // --- عمليات الرسائل الأساسية ---
  Future<void> insertOrReplaceMessage(Message message) async {
    final db = await _ensureDbInitialized();
    try {
      await db.insert(
        _messagesTable,
        message.toSqliteMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      if (kDebugMode) debugPrint("[LocalDatabaseService] Inserted/Replaced: ${message.messageId}, Status: ${message.status.name}");
      notifyMessageStreamListeners(message.senderId, message.recipientId);
    } catch (e) {
      if (kDebugMode) debugPrint("[LocalDatabaseService] Error inserting/replacing ${message.messageId}: $e");
    }
  }

  Future<bool> updateMessageStatus(String messageId, MessageStatus newStatus) async {
    return await updateMessageFields(messageId, {'status': newStatus.name}); // استخدم updateMessageFields
  }

  Future<bool> updateLocalPath(String messageId, String? newLocalPath) async {
    return await updateMessageFields(messageId, {'localFilePath': newLocalPath}); // استخدم updateMessageFields
  }

  // --- الدوال المنقولة من الـ extension إلى هنا ---

  Future<bool> messageExists(String messageId) async {
    final db = await _ensureDbInitialized(); // الوصول للمتغير الخاص مباشرة
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        _messagesTable, // الوصول للمتغير الخاص مباشرة
        columns: ['messageId'],
        where: 'messageId = ?',
        whereArgs: [messageId],
        limit: 1,
      );
      return maps.isNotEmpty;
    } catch (e) {
      if (kDebugMode) debugPrint("[LocalDatabaseService] Error checking message existence $messageId: $e");
      return false;
    }
  }

  // داخل كلاس LocalDatabaseService في ملف LocalDatabaseService.dart

  // --- الدالة مع تعريف يقبل معاملين ---
  Future<Message?> getMessageById(String messageId, String currentUserId) async { // <-- تأكد من وجود currentUserId هنا
    final db = await _ensureDbInitialized();
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        _messagesTable,
        where: 'messageId = ?',
        whereArgs: [messageId],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        // استخدام currentUserId الممرر مباشرة
        if(currentUserId.isEmpty){
          if(kDebugMode) debugPrint("!!! [LocalDatabaseService] Error in getMessageById: Passed currentUserId is empty!");
          return null;
        }
        return Message.fromMap(maps.first, currentUserId); // <-- استخدامه هنا
      }
    } catch (e) {
      if (kDebugMode) debugPrint("[LocalDatabaseService] Error fetching message by ID $messageId: $e");
    }
    return null; // إرجاع null إذا لم يتم العثور
  }
  // --- نهاية الدالة ---

// ... (بقية كود LocalDatabaseService) ...

  Future<bool> updateLocalPathAndStatus(String messageId, String? newLocalPath, MessageStatus newStatus) async {
    // يمكن استخدام updateMessageFields لتبسيط هذا أيضًا
    return await updateMessageFields(messageId, {
      'localFilePath': newLocalPath,
      'status': newStatus.name,
    });
  }

  Future<bool> updateMessageFields(String messageId, Map<String, dynamic> fieldsToUpdate) async {
    if (fieldsToUpdate.isEmpty) return true;

    final Map<String, dynamic> sanitizedUpdates = {};
    fieldsToUpdate.forEach((key, value) {
      if (value is MessageStatus) {
        sanitizedUpdates[key] = value.name;
      } else if (value is Timestamp) sanitizedUpdates[key] = value.millisecondsSinceEpoch;
      else sanitizedUpdates[key] = value;
    });

    final db = await _ensureDbInitialized(); // الوصول للمتغير الخاص
    try {
      final count = await db.update(
        _messagesTable, // الوصول للمتغير الخاص
        sanitizedUpdates,
        where: 'messageId = ?',
        whereArgs: [messageId],
      );
      if (count > 0) {
        if (kDebugMode) debugPrint("[LocalDatabaseService] Updated fields ${sanitizedUpdates.keys} for message $messageId.");
        // جلب المشاركين وتنبيه المستمعين
        final participants = await _getMessageParticipants(messageId); // استدعاء الدالة الخاصة
        if (participants != null) {
          notifyMessageStreamListeners(participants['senderId']!, participants['recipientId']!); // استدعاء الدالة الخاصة
        }
        return true;
      } else {
        if (kDebugMode) debugPrint("[LocalDatabaseService] Message $messageId not found for field updates.");
        return false;
      }
    } catch (e) {
      if (kDebugMode) debugPrint("[LocalDatabaseService] Error updating fields for $messageId: $e");
      return false;
    }
  }

  // --- الدوال المساعدة الخاصة بالكلاس ---
  // يجب أن تكون هذه الدوال موجودة كـ private داخل الكلاس

  Future<Map<String, String?>?> _getMessageParticipants(String messageId) async {
    final db = await _ensureDbInitialized();
    try {
      final List<Map<String, dynamic>> maps = await db.query(
          _messagesTable, columns: ['senderId', 'recipientId'], where: 'messageId = ?', whereArgs: [messageId], limit: 1);
      if (maps.isNotEmpty) {
        return {'senderId': maps.first['senderId'] as String?, 'recipientId': maps.first['recipientId'] as String?};
      }
    } catch (e) { /* Handle error */ }
    return null;
  }

  // --- تعديل _notifyMessageStreamListeners ---
  void notifyMessageStreamListeners(String user1Id, String user2Id) {
    // --- الحصول على ID المستخدم الحالي قبل استدعاء _fetch ---
    final String realCurrentUserId = Get.find<ChatService>().currentUserId; // TODO: استبدل هذا بمصدر موثوق
    if (realCurrentUserId.isEmpty) {
      if(kDebugMode) debugPrint("!!! [_notifyListeners] Cannot get current user ID to determine 'isMe'.");
      return;
    }
    // ------------------------------------------------------

    if (user1Id.isEmpty || user2Id.isEmpty) return; // التحقق من IDs المحادثة
    final chatPartnerIds = [user1Id, user2Id]..sort();
    final conversationId = chatPartnerIds.join('_');

    if (_streamControllers.containsKey(conversationId) && !_streamControllers[conversationId]!.isClosed) {
      if (kDebugMode) debugPrint("[LocalDatabaseService] Notifying listeners for $conversationId. User for check: '$realCurrentUserId'");
      // --- تمرير ID المستخدم الحالي الحقيقي هنا ---
      _fetchAndEmitMessages(conversationId, user1Id, user2Id, realCurrentUserId); // <-- تمرير المعامل الرابع
      // ----------------------------------------
    }
  }


  // --- البث المباشر للرسائل (الكود يبقى كما هو في ردك السابق) ---
  Stream<List<Message>> getMessagesStream(String currentUserId, String otherUserId, String currentUserIdForIsMeCheck) { // استقبل المعامل الجديد
    final chatPartnerIds = [currentUserId, otherUserId]..sort();
    final conversationId = chatPartnerIds.join('_');
    if (kDebugMode) debugPrint("[LocalDatabaseService] Requesting stream for $conversationId. User for check: $currentUserIdForIsMeCheck");
    if (!_streamControllers.containsKey(conversationId)) {
      _streamControllers[conversationId] = StreamController<List<Message>>.broadcast(
        // --- تمرير المعامل في onListen ---
        onListen: () {
          if (kDebugMode) debugPrint("    >>> [getMessagesStream - onListen $conversationId] Starting fetch. User for check: $currentUserIdForIsMeCheck");
          _startFetchingMessages(conversationId, currentUserId, otherUserId, currentUserIdForIsMeCheck); // <-- تمرير هنا
        },
        onCancel: () => _stopFetchingMessages(conversationId),
      );
      if (kDebugMode) debugPrint("[LocalDatabaseService] Created new StreamController for $conversationId.");
      // --- تمرير المعامل عند بدء الجلب الأولي ---
      _startFetchingMessages(conversationId, currentUserId, otherUserId, currentUserIdForIsMeCheck); // <-- تمرير هنا أيضًا
    } else {
      // --- تمرير المعامل عند إعادة الإرسال ---
      _fetchAndEmitMessages(conversationId, currentUserId, otherUserId, currentUserIdForIsMeCheck); // <-- تمرير هنا
      if (kDebugMode) debugPrint("[LocalDatabaseService] Re-emitting data for existing controller: $conversationId.");
    }
    return _streamControllers[conversationId]!.stream;
  }

  void _startFetchingMessages(String conversationId, String user1, String user2, String currentUserIdForIsMe) {
    if (kDebugMode) debugPrint("[LocalDatabaseService] Starting fetch for $conversationId");
    // تمرير currentUserIdForIsMe إلى دالة الجلب الفعلية
    _fetchAndEmitMessages(conversationId, user1, user2, currentUserIdForIsMe);
  }

// داخل LocalDatabaseService.dart
// داخل كلاس LocalDatabaseService

// تغيير اسم المعامل الأخير ليكون أوضح: currentUserIdForIsMeCheck
  Future<void> _fetchAndEmitMessages(String conversationId, String user1, String user2, String currentUserIdForIsMeCheck) async {
    final controller = _streamControllers[conversationId];
    if (controller == null || controller.isClosed) {
      if (kDebugMode) debugPrint(">>> [_fetchAndEmitMessages - $conversationId] EXIT: Controller null or closed.");
      return;
    }

    final db = await _ensureDbInitialized();
    if (kDebugMode) debugPrint(">>> [_fetchAndEmitMessages - $conversationId] Attempting DB query. User for 'isMe' check: '$currentUserIdForIsMeCheck'");

    try {
      // ترتيب DESC للحصول على الأحدث أولاً من DB يتناسب مع reverse: true
      final List<Map<String, dynamic>> maps = await db.query(
        _messagesTable,
        where: '(senderId = ? AND recipientId = ?) OR (senderId = ? AND recipientId = ?)',
        // استخدم user1 و user2 (اللذان يمثلان طرفي المحادثة)
        whereArgs: [user1, user2, user2, user1],
        orderBy: 'timestamp DESC', // <-- العودة إلى DESC مهم لـ reverse:true
      );

      if (kDebugMode) debugPrint("    >>> Query Result for $conversationId: Found ${maps.length} maps in SQLite.");

      // استخدام currentUserIdForIsMeCheck للمقارنة عند التحويل
      final messages = maps.map((map) {
        try {
          final String msgId = map['messageId'] ?? 'N/A';
          final String senderId = map['senderId'] ?? 'unknown';
          // --- **المقارنة الصحيحة هنا** ---
          final bool calculatedIsMe = senderId.isNotEmpty && senderId == currentUserIdForIsMeCheck; // <--- استخدم المعامل الممرر
          // -------------------------------
          if (kDebugMode) debugPrint("      -> Map for msg $msgId: sender='$senderId', currentForCheck='$currentUserIdForIsMeCheck' => isMe: $calculatedIsMe");
          return Message.fromMap(map, currentUserIdForIsMeCheck); // <--- مرر ID الصحيح لـ fromMap
        } catch (e, s) {
          if(kDebugMode) debugPrint("!!! Error converting map to Message for ID ${map['messageId']}: $e\n$s");
          return null;
        }
      }).whereType<Message>().toList(); // تجاهل أي رسالة فشل تحويلها

      if (!controller.isClosed) {
        controller.add(messages);
        if (kDebugMode) debugPrint("    >>> Emitted ${messages.length} messages to StreamController for $conversationId.");
      } else {
        if (kDebugMode) debugPrint("    >>> Could not emit for $conversationId, controller closed.");
      }

    } catch (e, s) {
      if (!controller.isClosed) controller.addError(e);
      if (kDebugMode) debugPrint("!!! [LocalDatabaseService] Error querying messages for $conversationId: $e\n$s");
    }
  }

  void _stopFetchingMessages(String conversationId) {
    final controller = _streamControllers[conversationId];
    if (controller != null && !controller.hasListener) {
      if (kDebugMode) debugPrint("[LocalDatabaseService] Closing StreamController for $conversationId.");
      controller.close();
      _streamControllers.remove(conversationId);
    }
  }

  //
  // // --- إغلاق وحذف ---
  Future<void> closeDatabase() async {
    final db = _database; // نسخة لتجنب race condition
    if (db != null && db.isOpen) {
      await db.close();
      _database = null; // إعادة تعيين المتغير
      if (kDebugMode) debugPrint("[LocalDatabaseService] Database closed.");
    }
    // إغلاق وتنظيف كل StreamControllers
    for (var controller in _streamControllers.values) {
      controller.close();
    }
    _streamControllers.clear();
    if (kDebugMode) debugPrint("[LocalDatabaseService] All StreamControllers closed.");
  }



  // دالة اختيارية لحذف كل الرسائل لمستخدم معين (لتسجيل الخروج مثلاً)
  Future<void> deleteAllMessagesForUser(String userId) async {
    final db = await _ensureDbInitialized();
    try {
      int count = await db.delete(
        _messagesTable,
        where: 'senderId = ? OR recipientId = ?',
        whereArgs: [userId, userId],
      );
      if (kDebugMode) debugPrint("[LocalDatabaseService] Deleted $count messages for user $userId.");
      // Optionally, vacuum DB to reduce file size
      // await db.rawQuery('VACUUM');
    } catch (e) {
      if (kDebugMode) debugPrint("[LocalDatabaseService] Error deleting messages for user $userId: $e");
    }
  }

} // نهاية الكلاس