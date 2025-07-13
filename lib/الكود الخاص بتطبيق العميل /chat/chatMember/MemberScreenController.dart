import 'dart:async';

import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

// تأكد من استيراد الثوابت والنماذج إن وجدت
import 'package:codora/XXX/xxx_firebase.dart'; // (عدّل المسار)

import '../google/FirestoreConstants.dart';
import '../google/MessageRepository.dart'; // (عدّل المسار)


class MemberScreenController extends GetxController {
  final TextEditingController searchController = TextEditingController();
  final RxString _searchQuery = ''.obs;
  String get searchQuery => _searchQuery.value;

  RxBool isLoading = true.obs;
  RxBool hasData = false.obs; // يشير إذا كان هناك *أي* بيانات (مفلترة أو غير مفلترة)
  RxBool isSearching = false.obs; // للإشارة إذا كانت عملية البحث/الفلترة جارية

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>>? _conversationsStream;
  StreamSubscription? _conversationSubscription; // للاستماع للتحديثات من Firestore
  Worker? _debounceWorker; // لتأخير البحث
  MessageRepository? _messageRepository;
  MessageRepository get messageRepository {
    _messageRepository ??= Get.find<MessageRepository>();
    return _messageRepository!;
  }

  // --- قائمة المحادثات الأصلية ---
  List<Map<String, dynamic>> _originalConversations = [];

  // --- **التغيير الرئيسي: استخدام RxList للنتائج المفلترة** ---
  final RxList<Map<String, dynamic>> filteredConversations = <Map<String, dynamic>>[].obs;
  // ------------------------------------------------------


  @override
  void onInit() {
    super.onInit();
    debugPrint("[MemberScreenController] onInit");
    if (_auth.currentUser != null && _auth.currentUser!.uid.isNotEmpty) {
      // استدعِ الدالة من MessageRepository
      try {
        messageRepository.checkAndUpdateOverallUnreadStatusForCurrentUser(); // ستحتاج لإنشاء هذه الدالة
      } catch (e) {
        debugPrint("خطأ في الوصول لـ MessageRepository: $e");
      }
    }
    // ربط قيمة حقل البحث بـ RxString
    searchController.addListener(() {
      // لا نحدث البحث مباشرة هنا، ننتظر الـ debounce worker
      _searchQuery.value = searchController.text.toLowerCase();
    });

    // --- استخدام Debounce Worker ---
    _debounceWorker = debounce(
        _searchQuery, // مراقبة هذا المتغير التفاعلي
            (String query) {
          if (kDebugMode) debugPrint("[MemberScreenController] Debounce triggered for query: '$query'. Starting filter...");
          // فقط أعد الفلترة من القائمة الأصلية الموجودة
          _filterAndFetchUsers(query); // استدعاء دالة الفلترة المحدثة
        },
        time: const Duration(milliseconds: 400) // تأخير البحث بعد التوقف عن الكتابة
    );
    // ---------------------------

    _initializeAndListenStream(); // تغيير اسم الدالة ودمج الاستماع
  }


  void _initializeAndListenStream() async { // جعلها async
    final userId = _auth.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      if (userId == null || userId.isEmpty) {
        debugPrint("[MemberScreenController] Error: Current User ID is null/empty.");
        isLoading.value = false;
        hasData.value = false;
        return;
      } }

    // إعادة تعيين الحالة عند البدء
    isLoading.value = true;
    hasData.value = false;
    isSearching.value = false; // إعادة تعيين حالة البحث
    _originalConversations.clear(); // مسح القائمة القديمة
    filteredConversations.clear(); // مسح القائمة المفلترة

    // --- الاستماع المستمر لتيار المحادثات الأساسي ---
    _conversationsStream = _firestore
        .collection(FirestoreConstants.chatCollection).doc(userId)
        .collection(FirestoreConstants.chatSubCollection)
        .orderBy(FirestoreConstants.timestamp, descending: true)
        .snapshots();

    // إلغاء أي استماع قديم قبل بدء الجديد
    await _conversationSubscription?.cancel(); // انتظر الإلغاء إذا كان غير متزامن

    _conversationSubscription = _conversationsStream?.listen(
            (querySnapshot) {
          if (kDebugMode) debugPrint("[MemberScreenController] Firestore listener received ${querySnapshot.docs.length} conversation summaries.");
          _originalConversations = querySnapshot.docs.map((doc) => { // تحديث القائمة الأصلية
            'chatData': doc.data(),
            // استخراج otherUserId هنا لتسهيل الفلترة لاحقًا
            'otherUserId': _getOtherUserId(doc.data(), userId)
          }).where((item) {
            final otherId = item['otherUserId']; // النوع هنا Object?
            // التحقق أولاً من أنه ليس null ثم من أنه String وليس فارغاً
            return otherId != null && otherId is String && otherId.isNotEmpty;
          }).toList();

          // تحديث hasData الأصلي
          hasData.value = _originalConversations.isNotEmpty;

          // **تطبيق الفلترة الحالية فوراً بعد استلام البيانات الجديدة**
          _filterAndFetchUsers(searchQuery); // استخدم القيمة الحالية لـ searchQuery

          // يمكن إيقاف isLoading الأولي هنا، لكن isSearching ستتحكم بالتحميل أثناء الفلترة
          // isLoading.value = false; // تم استلام الدفعة الأولى
        },
        onError: (error, stack) {
          if (kDebugMode) debugPrint("!!! [MemberScreenController] Error in Firestore conversation stream: $error\n$stack");
          isLoading.value = false;
          // يمكنك تعيين حالة خطأ هنا وإظهارها في الواجهة
          // hasError.value = true;
        },
        onDone: () {
          if (kDebugMode) debugPrint("[MemberScreenController] Firestore conversation stream closed.");
          isLoading.value = false;
          // يمكنك إعادة تعيين hasData إذا أردت
        }
    );
    if (kDebugMode) debugPrint("[MemberScreenController] Firestore listener attached.");


    // إيقاف التحميل المبدئي إذا لم يبدأ الاستماع لسبب ما (احتياطي)
    Future.delayed(const Duration(seconds: 1), (){ if(isLoading.value && filteredConversations.isEmpty) isLoading.value=false; });


  } // نهاية _initializeAndListenStream

  // دالة مساعدة لاستخراج معرف الطرف الآخر
  String? _getOtherUserId(Map<String, dynamic> chatData, String myUserId){
    String otherUserId = '';
    if (chatData[FirestoreConstants.senderId] == myUserId) {
      otherUserId = chatData[FirestoreConstants.recipientId] ?? '';
    } else {
      otherUserId = chatData[FirestoreConstants.senderId] ?? '';
    }
    return otherUserId.isNotEmpty ? otherUserId : null;
  }


  // --- دالة جديدة للفلترة وجلب المستخدمين (تستدعى بواسطة الـ worker أو مباشرة) ---
  Future<void> _filterAndFetchUsers(String query) async {
    isSearching.value = true; // بدأ الفلترة

    final List<Map<String, dynamic>> currentlyFiltered = [];
    final List<Future<void>> userFetchFutures = [];

    // المرور على قائمة المحادثات *الأصلية* المحفوظة
    for (var conversationSummary in _originalConversations) {
      final otherUserId = conversationSummary['otherUserId'] as String?; // معرف المستخدم الآخر المحفوظ
      final chatData = conversationSummary['chatData'] as Map<String, dynamic>; // بيانات المحادثة

      if (otherUserId == null) continue; // تجاهل إذا كان ID المستخدم الآخر مفقودًا

      // لا حاجة لاستدعاء fetch مرة أخرى، فقط الفلترة بناءً على البيانات المجلوبة سابقاً أو فلترة أولية
      // هنا يمكن الفلترة بناءً على آخر رسالة إذا أردت
      // if (chatData[...].toString().toLowerCase().contains(query)) { ... }

      // التركيز على فلترة اسم المستخدم
      userFetchFutures.add(
          _fetchAndFilterUser(otherUserId, query).then((userData) {
            if (userData != null) { // إذا وجد المستخدم ويتطابق اسمه مع البحث
              currentlyFiltered.add({
                'chatData': chatData,
                'userData': userData,
                'otherUserId': otherUserId,
              });
            }
          })
      );
    }

    // انتظار اكتمال كل عمليات الجلب للمستخدمين المتطابقين
    await Future.wait(userFetchFutures);

    // إعادة الترتيب (ضروري الآن لأن الجلب غير المتزامن قد يخل بالترتيب الأصلي)
    currentlyFiltered.sort((a, b) {
      Timestamp timeA = a['chatData'][FirestoreConstants.timestamp] ?? Timestamp(0,0);
      Timestamp timeB = b['chatData'][FirestoreConstants.timestamp] ?? Timestamp(0,0);
      return timeB.compareTo(timeA);
    });

    // تحديث قائمة النتائج التفاعلية التي تستمع لها الواجهة
    filteredConversations.assignAll(currentlyFiltered);
    hasData.value = filteredConversations.isNotEmpty; // تحديث hasData بناءً على النتائج المفلترة

    if (kDebugMode) debugPrint("[MemberScreenController] Filtering complete for '$query'. Found ${currentlyFiltered.length} results.");
    isSearching.value = false; // انتهاء الفلترة
    isLoading.value = false; // إيقاف مؤشر التحميل العام
  }
  // --- نهاية دالة الفلترة ---


  // دالة جلب بيانات المستخدم (تبقى كما هي)
  Future<Map<String, dynamic>?> _fetchAndFilterUser(String userId, String query) async {
    // ... (الكود كما هو) ...
    try {
      final userDoc = await _firestore.collection(FirebaseX.collectionApp).doc(userId).get();
      if (userDoc.exists) {
        // داخل _fetchAndFilterUser
        final userData = userDoc.data() ?? {}; // <-- إزالة cast
        if (query.isEmpty || (userData[UserField.name] as String? ?? '').toLowerCase().contains(query)) {
          return userData;
        }
      }
    } catch (e) { /* ... */ }
    return null;
  }

  @override
  void onClose() {
    debugPrint("[MemberScreenController] onClose");
    _debounceWorker?.dispose(); // التخلص من الـ worker
    _conversationSubscription?.cancel(); // إلغاء استماع Firestore
    searchController.dispose();
    super.onClose();
  }
}