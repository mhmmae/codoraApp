import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../XXX/xxx_firebase.dart';

/// يتحكم هذا المتحكم في إضافة وحذف العناصر من السلة وحساب الأسعار الإجمالية.
/// يعتمد على خريطة لتخزين الكميات الحالية لكل مستند ويستخدم استعلامات متوازية (Future.wait)
/// للحصول على الأسعار من مجموعتي "Item" و"Itemoffer".
class GetAddAndRemove extends GetxController {
  // يخزن الكميات الحالية لكل مستند باستخدام uidOfDoc كمفتاح
  final Map<String, int> _itemQuantities = {};
  RxInt totalCartItemCount = 0.obs;

  // متغيرات Rx لمتابعة التحديثات في الأسعار
  RxInt total = 0.obs;
  RxInt totalPriceOfItem = 0.obs;
  RxInt totalPriceOfofferItem = 0.obs;
  RxInt totalPrice = 0.obs;

  /// دالة لحساب الأسعار الإجمالية بشكل متوازي مع استرجاع بيانات كلا المجموعتين

  Future<void> calculateTotals() async {
    final String userId = FirebaseAuth.instance.currentUser!.uid;
    debugPrint('🔥 Starting calculateTotals for user: $userId');

    try {
      totalPriceOfItem.value = 0;
      totalPriceOfofferItem.value = 0;
      int currentTotalItems = 0; // For sum of quantities

      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance
              .collection('the-chosen')
              .doc(userId)
              .collection(FirebaseX.appName)
              .get();

      debugPrint('🛒 Found ${querySnapshot.docs.length} items in cart');

      // Clear local quantities before recalculating
      _itemQuantities.clear();

      List<Future<void>> priceFutures = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;

        int itemCount = data['number'] as int? ?? 0;
        currentTotalItems += itemCount; // Summing up quantities
        final uidItem = data['uidItem'] as String? ?? "";
        final bool isOffer = data['isOfer'] as bool? ?? false;

        debugPrint(
          '📦 Processing item: $uidItem, quantity: $itemCount, isOffer: $isOffer',
        );

        if (uidItem.isEmpty) continue;

        _itemQuantities[doc.id] = itemCount;

        // إضافة منطق حساب الأسعار الفعلي
        priceFutures.add(
          Future.wait([
            FirebaseFirestore.instance
                .collection(FirebaseX.itemsCollection)
                .doc(uidItem)
                .get(),
            FirebaseFirestore.instance
                .collection(FirebaseX.offersCollection)
                .doc(uidItem)
                .get(),
          ]).then((List<DocumentSnapshot> snapshots) {
            final productSnapshot = snapshots[0];
            final offerSnapshot = snapshots[1];
            int priceNormal = 0;
            int priceOffer = 0;

            debugPrint('🏪 Checking product collections for item: $uidItem');
            debugPrint('   Normal product exists: ${productSnapshot.exists}');
            debugPrint('   Offer product exists: ${offerSnapshot.exists}');

            // قراءة السعر من مجموعة المنتجات الأساسية إذا كانت موجودة
            if (productSnapshot.exists) {
              try {
                // استخدام suggestedRetailPrice أولاً ثم priceOfItem كبديل
                final productData =
                    productSnapshot.data() as Map<String, dynamic>?;
                final suggestedPriceData = productData?['suggestedRetailPrice'];
                final regularPriceData = productSnapshot.get('priceOfItem');

                final priceData = suggestedPriceData ?? regularPriceData;
                debugPrint(
                  '   Raw normal price data: $priceData (${priceData.runtimeType})',
                );
                if (priceData != null) {
                  // التعامل مع النوع المختلط (int أو double أو string)
                  if (priceData is num) {
                    priceNormal = priceData.toInt();
                  } else if (priceData is String) {
                    priceNormal = double.tryParse(priceData)?.toInt() ?? 0;
                  }
                  debugPrint('   Normal price converted: $priceNormal');
                }
              } catch (e) {
                debugPrint("❌ Error parsing normal item price: $e");
              }
            }

            // قراءة السعر من مجموعة العروض إذا كانت موجودة
            if (offerSnapshot.exists) {
              try {
                // استخدام suggestedRetailPrice أولاً ثم priceOfItem كبديل للعروض أيضاً
                final offerData = offerSnapshot.data() as Map<String, dynamic>?;
                final suggestedPriceData = offerData?['suggestedRetailPrice'];
                final regularPriceData = offerSnapshot.get('priceOfItem');

                final priceData = suggestedPriceData ?? regularPriceData;
                debugPrint(
                  '   Raw offer price data: $priceData (${priceData.runtimeType})',
                );
                if (priceData != null) {
                  // التعامل مع النوع المختلط (int أو double أو string)
                  if (priceData is num) {
                    priceOffer = priceData.toInt();
                  } else if (priceData is String) {
                    priceOffer = double.tryParse(priceData)?.toInt() ?? 0;
                  }
                  debugPrint('   Offer price converted: $priceOffer');
                }
              } catch (e) {
                debugPrint("❌ Error parsing offer item price: $e");
              }
            }

            // تحديد السعر المناسب بناءً على نوع المنتج (عرض أم لا)
            int finalPrice = 0;
            if (isOffer) {
              // هذا منتج من مجموعة العروض
              if (priceOffer > 0) {
                finalPrice = priceOffer;
                totalPriceOfofferItem.value += priceOffer * itemCount;
                debugPrint(
                  '💰 Added offer price: ${priceOffer * itemCount} ($priceOffer x $itemCount)',
                );
              } else {
                debugPrint('⚠️ Offer item has no valid price: $uidItem');
              }
            } else {
              // هذا منتج من مجموعة المنتجات العادية
              if (priceNormal > 0) {
                finalPrice = priceNormal;
                totalPriceOfItem.value += priceNormal * itemCount;
                debugPrint(
                  '💰 Added normal price: ${priceNormal * itemCount} ($priceNormal x $itemCount)',
                );
              } else {
                debugPrint('⚠️ Normal item has no valid price: $uidItem');
              }
            }

            if (finalPrice == 0) {
              debugPrint(
                '🚨 NO PRICE FOUND for item: $uidItem (isOffer: $isOffer, normalPrice: $priceNormal, offerPrice: $priceOffer)',
              );
            }
          }),
        );
      }

      await Future.wait(priceFutures);
      total.value = totalPriceOfItem.value + totalPriceOfofferItem.value;
      totalPrice.value = total.value; // تحديث totalPrice أيضاً
      totalCartItemCount.value =
          currentTotalItems; // Update the total item count
      update(); // This updates listeners to GetAddAndRemove

      debugPrint('✅ Calculate totals completed:');
      debugPrint('   Normal items total: ${totalPriceOfItem.value}');
      debugPrint('   Offer items total: ${totalPriceOfofferItem.value}');
      debugPrint('   FINAL TOTAL: ${total.value}');
      debugPrint('   Total item count: ${totalCartItemCount.value}');
    } catch (e) {
      debugPrint("❌ Error calculating totals: $e");
      totalCartItemCount.value = 0; // Reset on error
      total.value = 0;
      totalPrice.value = 0;
      // rethrow; // Or handle gracefully
    }
  }

  // Method to be called by GetxAreYouSureMapOrder
  int getTotalItemCountInCart() {
    return totalCartItemCount.value;
  }

  /// تحدث الأسعار الإجمالية بعد أي تغيير في السلة
  Future<void> refreshTotals() async {
    debugPrint('refreshTotals11111111111111111111111');
    await calculateTotals();
    update();
  }

  /// دالة لزيادة كمية عنصر معين.
  /// تُحدِّث قاعدة البيانات وتعيد حساب الإجماليات.
  Future<void> incrementItem({
    required String uidItem,
    required String uidOfDoc,
    required bool isOfer,
    required String uidAdd,
  }) async {
    final String userId = FirebaseAuth.instance.currentUser!.uid;
    final docRef = FirebaseFirestore.instance
        .collection('the-chosen')
        .doc(userId)
        .collection(FirebaseX.appName)
        .doc(uidOfDoc);

    int currentCount = _itemQuantities[uidOfDoc] ?? 0;
    currentCount++;
    _itemQuantities[uidOfDoc] = currentCount;

    // تحديث Firestore باستخدام set (insert/update)
    await docRef.set({
      'uidUser': userId,
      'uidItem': uidItem,
      'uidOfDoc': uidOfDoc,
      'number': currentCount,
      'isOfer': isOfer,
      'uidAdd': uidAdd,
    });

    await refreshTotals();
    update();
  }

  /// دالة لتقليل كمية عنصر معين.
  /// إذا كانت الكمية 1 أو أقل، يتم حذف السجل.
  Future<void> decrementItem({
    required String uidItem,
    required String uidOfDoc,
    required bool isOfer,
    required String uidAdd,
  }) async {
    final String userId = FirebaseAuth.instance.currentUser!.uid;
    final docRef = FirebaseFirestore.instance
        .collection('the-chosen')
        .doc(userId)
        .collection(FirebaseX.appName)
        .doc(uidOfDoc);

    int currentCount = _itemQuantities[uidOfDoc] ?? 0;

    if (currentCount <= 1) {
      await docRef.delete();
      _itemQuantities[uidOfDoc] = 0;
    } else {
      currentCount--;
      _itemQuantities[uidOfDoc] = currentCount;
      await docRef.update({
        'uidUser': userId,
        'uidItem': uidItem,
        'uidOfDoc': uidOfDoc,
        'number': currentCount,
        'isOfer': isOfer,
        'uidAdd': uidAdd,
      });
    }
    await refreshTotals();
    update();
  }

  /// دالة لاسترجاع الكمية الحالية لمستند معين بناءً على uidOfDoc.
  int getCurrentItemCount(String uidOfDoc) {
    return _itemQuantities[uidOfDoc] ?? 0;
  }

  @override
  void onInit() {
    super.onInit();
    // تحديث الأسعار عند بدء تهيئة المتحكم
    refreshTotals();
    // تشغيل دالة migration للتأكد من أن جميع المنتجات تحتوي على uidAdd
    _migrateCartItemsWithSellerId();
  }

  /// دالة migration لإضافة uidAdd للمنتجات الموجودة في السلة
  Future<void> _migrateCartItemsWithSellerId() async {
    final String userId = FirebaseAuth.instance.currentUser!.uid;
    debugPrint('🔄 Starting cart migration to add seller IDs...');

    try {
      // الحصول على جميع المنتجات في السلة
      QuerySnapshot cartSnapshot =
          await FirebaseFirestore.instance
              .collection('the-chosen')
              .doc(userId)
              .collection(FirebaseX.appName)
              .get();

      int migratedCount = 0;

      for (var doc in cartSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;

        // التحقق من وجود uidAdd
        if (data['uidAdd'] == null || data['uidAdd'].toString().isEmpty) {
          final String uidItem = data['uidItem'] as String? ?? "";
          final bool isOffer = data['isOfer'] as bool? ?? false;

          if (uidItem.isNotEmpty) {
            // الحصول على معلومات المنتج من المجموعة المناسبة
            DocumentSnapshot productDoc;
            if (isOffer) {
              productDoc =
                  await FirebaseFirestore.instance
                      .collection(FirebaseX.offersCollection)
                      .doc(uidItem)
                      .get();
            } else {
              productDoc =
                  await FirebaseFirestore.instance
                      .collection(FirebaseX.itemsCollection)
                      .doc(uidItem)
                      .get();
            }

            if (productDoc.exists) {
              final productData = productDoc.data() as Map<String, dynamic>?;
              final String uidAdd = productData?['uidAdd'] as String? ?? "";

              if (uidAdd.isNotEmpty) {
                // تحديث المستند في السلة بإضافة uidAdd
                await doc.reference.update({'uidAdd': uidAdd});
                migratedCount++;
                debugPrint('✅ Migrated item ${doc.id} with seller ID: $uidAdd');
              } else {
                debugPrint('⚠️ Product $uidItem has no seller ID');
              }
            }
          }
        }
      }

      if (migratedCount > 0) {
        debugPrint(
          '✅ Migration completed: Updated $migratedCount items with seller IDs',
        );
        // إعادة حساب الإجماليات بعد التحديث
        await refreshTotals();
      } else {
        debugPrint('ℹ️ No items needed migration');
      }
    } catch (e) {
      debugPrint('❌ Error during cart migration: $e');
    }
  }

  @override
  void dispose() {
    update();
    _itemQuantities.clear();
    total.value = 0;
    totalPriceOfItem.value = 0;
    totalPriceOfofferItem.value = 0;
    totalPrice.value = 0;
    super.dispose();
  }
}
