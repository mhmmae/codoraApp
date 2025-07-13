// Get2.dart (متحكم BottomBar)
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../chat/google/FirestoreConstants.dart';
import '../../theـchosen/GetXController/GetAddAndRemove.dart';

class Get2 extends GetxController {
  final RxInt selectedIndex = 0.obs;
  final RxBool hasUnreadGlobalMessages = false.obs; // <--- متغير جديد
  StreamSubscription? _unreadStatusSubscription;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void onInit() {
    super.onInit();
    _listenToOverallUnreadStatus(); // ابدأ الاستماع
  }

  void changeIndex(int index) {
    if (selectedIndex.value != index) {
      selectedIndex.value = index;
      
      // إذا تم التبديل لصفحة السلة (index 2)، قم بتحديث السعر
      if (index == 2) {
        debugPrint('🛒 Switched to cart page - refreshing totals...');
        _refreshCartTotals();
      }
    }
  }
  
  void _refreshCartTotals() {
    try {
      // البحث عن GetAddAndRemove controller وتحديث السعر
      if (Get.isRegistered<GetAddAndRemove>()) {
        final cartController = Get.find<GetAddAndRemove>();
        cartController.refreshTotals();
        debugPrint('✅ Cart totals refreshed successfully');
      } else {
        debugPrint('⚠️ GetAddAndRemove controller not found');
      }
    } catch (e) {
      debugPrint('❌ Error refreshing cart totals: $e');
    }
  }

  void _listenToOverallUnreadStatus() {
    _auth.authStateChanges().listen((User? user) {
      _unreadStatusSubscription?.cancel(); // ألغِ أي استماع سابق
      if (user != null && user.uid.isNotEmpty) {
        _unreadStatusSubscription = _firestore
            .collection(FirestoreConstants.userCollection)
            .doc(user.uid)
            .snapshots() // استمع لتغييرات وثيقة المستخدم
            .listen((docSnapshot) {
          if (docSnapshot.exists && docSnapshot.data() != null) {
            final data = docSnapshot.data()!;
            hasUnreadGlobalMessages.value = data['hasUnreadMessages'] ?? false;
            if (kDebugMode) debugPrint("[Get2 - BottomBar] Unread status changed for ${user.uid}: ${hasUnreadGlobalMessages.value}");
          } else {
            hasUnreadGlobalMessages.value = false; // إذا لم توجد الوثيقة، افترض لا رسائل
          }
        }, onError: (e) {
          if (kDebugMode) debugPrint("!!! [Get2 - BottomBar] Error listening to unread status: $e");
          hasUnreadGlobalMessages.value = false;
        });
      } else {
        hasUnreadGlobalMessages.value = false; // لا مستخدم، لا رسائل غير مقروءة
      }
    });
  }

  @override
  void onClose() {
    _unreadStatusSubscription?.cancel();
    super.onClose();
  }
}