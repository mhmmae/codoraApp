import 'dart:async';
import 'dart:math'; // For Random
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../Model/model_order.dart';
import '../../../XXX/xxx_firebase.dart';
import '../../../Model/model_the_order_list.dart';
import '../../bottonBar/botonBar.dart'; // For navigation
import '../../controler/local-notification-onroller.dart'; // Your LocalNotification class
import '../../theـchosen/GetXController/GetAddAndRemove.dart'; // To get cart summary

class GetxAreYouSureMapOrder extends GetxController {
  // --- الحالة الداخلية للمتحكم ---
  double latitude;
  double longitude;
  final String tokenUser; // FCM token of the current user (buyer)

  // Rx Variables for reactive UI updates
  var isLoading = false.obs; // For overall loading state
  final _confirmationDialogIsLoading =
      false.obs; // Specific for loading within the confirmation dialog

  // --- Firebase Instances ---
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- Cart Controller ---
  // Make sure GetAddAndRemove is put() before this controller is initialized or used.
  // It's better to pass it via constructor or use a binding.
  // For this example, we'll try to find it. If not found, _sendOrder will have issues.
  late GetAddAndRemove _cartController;

  GetxAreYouSureMapOrder({
    required this.latitude,
    required this.longitude,
    required this.tokenUser,
  });

  @override
  void onInit() {
    super.onInit();
    try {
      _cartController = Get.find<GetAddAndRemove>();
    } catch (e) {
      debugPrint(
        "GetxAreYouSureMapOrder: GetAddAndRemove controller not found. Cart summary will not be available.",
      );
      // Initialize with a dummy if needed, or handle this case gracefully
      // For now, if not found, methods requiring it might fail or show defaults.
    }
  }

  /// Generates a random number string (can be improved for uniqueness guarantee)
  String _generateOrderNumber() {
    // Consider using Firestore's auto-generated IDs for more robust uniqueness if this
    // needs to be globally unique across all orders. For per-seller sub-orders, this might be okay.
    Random random = Random();
    return List.generate(10, (_) => random.nextInt(10)).join();
  }

  /// Displays a confirmation dialog before sending the order.
  Future<void> showConfirmationDialog(BuildContext context) async {
    // Get current cart summary if controller is available
    String totalItemsStr = "-";
    String totalPriceStr = "-";
    int itemCount = 0;

    if (Get.isRegistered<GetAddAndRemove>()) {
      if (!_cartController.initialized) {
        await _cartController.calculateTotals(); // Ensure totals are calculated
      }
      itemCount =
          _cartController
              .getTotalItemCountInCart(); // Implement this in GetAddAndRemove
      totalItemsStr = itemCount.toString();
      totalPriceStr = "${_cartController.total.value} ${FirebaseX.currency}";
    }

    // Check if cart is empty
    if (itemCount == 0 && Get.isRegistered<GetAddAndRemove>()) {
      Get.snackbar(
        "سلة فارغة",
        "الرجاء إضافة منتجات إلى السلة أولاً.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
      );
      return;
    }

    return Get.dialog(
      Obx(
        () => AlertDialog.adaptive(
          // Using adaptive for better platform feel
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          titlePadding: const EdgeInsets.only(
            top: 24,
            bottom: 0,
            left: 24,
            right: 24,
          ),
          title:
              _confirmationDialogIsLoading.value
                  ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Colors.blueAccent),
                      const SizedBox(height: 20),
                      Text(
                        'جاري إرسال الطلب...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: Get.width / 24, // Responsive font size
                          color: Colors.blueGrey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                  : Row(
                    children: [
                      Icon(
                        Icons.shopping_cart_checkout,
                        color: Colors.blueAccent,
                        size: Get.width / 12,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'تأكيد إرسال الطلب؟',
                          style: TextStyle(
                            fontSize: Get.width / 22,
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ),
          content:
              _confirmationDialogIsLoading.value
                  ? const SizedBox.shrink() // Don't show content if loading title is shown
                  : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'سيتم تحديد موقعك الحالي لإتمام عملية التوصيل.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: Get.width / 28,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 15),
                      if (Get.isRegistered<GetAddAndRemove>()) ...[
                        Text(
                          "ملخص الطلب:",
                          style: TextStyle(
                            fontSize: Get.width / 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "إجمالي المنتجات: $totalItemsStr",
                          style: TextStyle(fontSize: Get.width / 28),
                        ),
                        Text(
                          "السعر الإجمالي: $totalPriceStr",
                          style: TextStyle(
                            fontSize: Get.width / 28,
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      const SizedBox(height: 15),
                      Text(
                        'لا يمكن التراجع عن الطلب بعد التأكيد.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: Get.width / 30,
                          color: Colors.red.shade400,
                        ),
                      ),
                    ],
                  ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actionsPadding: const EdgeInsets.only(
            bottom: 16,
            left: 16,
            right: 16,
            top: 0,
          ),
          actions:
              _confirmationDialogIsLoading.value
                  ? [] // No actions when loading in dialog
                  : [
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Get.back(), // Close dialog
                      child: Text(
                        'إلغاء',
                        style: TextStyle(
                          fontSize: Get.width / 26,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        // Don't pop dialog here, _sendOrder will handle navigation or error.
                        // But start dialog specific loading.
                        _confirmationDialogIsLoading.value = true;
                        await _sendOrder(context);
                        _confirmationDialogIsLoading.value = false;
                        if (Get.isDialogOpen ?? false) {
                          // Check if dialog is still open
                          Get.back(); // Close if processing finished and it's still up
                        }
                      },
                      child: Text(
                        'تأكيد وإرسال',
                        style: TextStyle(
                          fontSize: Get.width / 26,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
        ),
      ),
      barrierDismissible:
          !_confirmationDialogIsLoading
              .value, // Prevent dismiss while processing
    );
  }

  /// Main function to process and send the order.
  Future<void> _sendOrder(BuildContext context) async {
    isLoading.value =
        true; // Overall loading state for the screen if needed outside dialog
    update(); // Update UI for screen-level indicators if any

    final String? currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      _showErrorSnackbar("خطأ", "المستخدم غير مسجل الدخول.");
      isLoading.value = false;
      update();
      return;
    }

    // Fetch buyer details for notifications
    String buyerName = 'مستخدم';
    String? buyerImageUrl;
    try {
      DocumentSnapshot buyerDoc =
          await _firestore
              .collection(FirebaseX.collectionApp)
              .doc(currentUserId)
              .get();
      if (buyerDoc.exists) {
        buyerName = buyerDoc.get('name') ?? 'مستخدم';
        buyerImageUrl = buyerDoc.get('url');
      }
    } catch (e) {
      debugPrint("Error fetching buyer details: $e");
      // Continue, default buyerName is set.
    }

    QuerySnapshot cartSnapshot;
    try {
      cartSnapshot =
          await _firestore
              .collection('the-chosen')
              .doc(currentUserId)
              .collection(FirebaseX.appName)
              .get();

      if (cartSnapshot.docs.isEmpty) {
        _showInfoSnackbar("سلة فارغة", "لا يوجد منتجات في السلة لإرسالها.");
        isLoading.value = false;
        update();
        return;
      }
    } catch (e) {
      _showErrorSnackbar("خطأ في الشبكة", "فشل في جلب عناصر السلة: $e");
      isLoading.value = false;
      update();
      return;
    }

    // Group items by seller (uidAdd)
    Map<String, List<QueryDocumentSnapshot>> itemsBySeller = {};
    for (var doc in cartSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      String sellerUid =
          data['uidAdd'] as String? ??
          'unknown_seller_uid'; // Handle if uidAdd is missing
      itemsBySeller.putIfAbsent(sellerUid, () => []).add(doc);
    }

    List<String> successfulSellerOrderDisplayIds = [];
    List<String> failedSellerUids = [];
    bool anySellerProcessingSucceeded = false;

    for (String sellerUid in itemsBySeller.keys) {
      if (sellerUid == 'unknown_seller_uid') {
        debugPrint("Skipping items with unknown_seller_uid");
        // Potentially add these to a separate "failed" list or notify admin
        failedSellerUids.add("منتجات بدون معرّف بائع");
        continue;
      }
      List<QueryDocumentSnapshot> sellerItems = itemsBySeller[sellerUid]!;
      String sellerOrderDisplayNumber =
          _generateOrderNumber(); // For display/notification

      try {
        // ---- Firestore Transaction per Seller ----
        String? createdOrderId = await _firestore.runTransaction((
          transaction,
        ) async {
          DocumentReference sellerOrderDocRef =
              _firestore
                  .collection(FirebaseX.ordersCollection)
                  .doc(); // Auto-ID for main order doc

          double totalPriceForThisSeller = 0.0;
          // Calculate total price for this seller's items
          for (var itemDocInCart in sellerItems) {
            final chosenItemData = itemDocInCart.data() as Map<String, dynamic>;
            String uidItem = chosenItemData['uidItem'] as String;
            int quantity = chosenItemData['number'] as int? ?? 1;
            bool isOfferItem = chosenItemData['isOfer'] as bool? ?? false;

            DocumentSnapshot productDetailsDoc;
            int itemPrice = 0;

            String collectionName =
                isOfferItem
                    ? FirebaseX.offersCollection
                    : FirebaseX.itemsCollection;

            // Use transaction.get() to read data within a transaction
            productDetailsDoc = await transaction.get(
              _firestore.collection(collectionName).doc(uidItem),
            );

            if (productDetailsDoc.exists) {
              // استخدام suggestedRetailPrice أولاً ثم priceOfItem كبديل
              final dynamic suggestedPrice =
                  productDetailsDoc.data() is Map<String, dynamic>
                      ? (productDetailsDoc.data()
                          as Map<String, dynamic>)['suggestedRetailPrice']
                      : null;
              final dynamic regularPrice = productDetailsDoc.get('priceOfItem');

              itemPrice =
                  suggestedPrice != null
                      ? (suggestedPrice as num?)?.toInt() ?? 0
                      : (regularPrice as num?)?.toInt() ?? 0;
            } else {
              debugPrint(
                "!!! تحذير: منتج ID: $uidItem (مجموعة: $collectionName) غير موجود. سيتم احتسابه بصفر.",
              );
              // Throw an error to fail the transaction for this seller if a product is missing
              // This ensures order consistency for the seller.
              throw FirebaseException(
                plugin: 'App',
                code: 'product-not-found',
                message: 'منتج $uidItem مطلوب للبائع $sellerUid غير موجود.',
              );
            }
            totalPriceForThisSeller += (itemPrice * quantity);
          }

          // Create OrderModel for this seller
          OrderModel sellerOrder = OrderModel(
            uidUser: currentUserId,
            appName: FirebaseX.appName,
            location: GeoPoint(latitude, longitude), // حفظ الموقع كـ GeoPoint
            delivery: false,
            doneDelivery: false,
            requestAccept: false,
            timeOrder:
                DateTime.now(), // Server timestamp is better, but DateTime.now() is okay
            numberOfOrder:
                sellerOrderDocRef
                    .id, // Using Firestore Auto-ID as the order number
            totalPriceOfOrder: totalPriceForThisSeller.toInt(),
            uidAdd: sellerUid,
          );
          transaction.set(sellerOrderDocRef, sellerOrder.toMap());

          // Save OrderItems (ModelTheOrderList) as a subcollection
          for (var itemDocInCart in sellerItems) {
            final chosenItemData = itemDocInCart.data() as Map<String, dynamic>;
            ModelTheOrderList orderListItem = ModelTheOrderList(
              uidUser: currentUserId,
              uidItem: chosenItemData['uidItem'] as String,
              uidOfDoc: itemDocInCart.id, // Original doc ID from 'the-chosen'
              uidAdd: sellerUid,
              number: chosenItemData['number'] as int? ?? 1,
              isOfer: chosenItemData['isOfer'] as bool? ?? false,
              appName: FirebaseX.appName,
            );
            transaction.set(
              sellerOrderDocRef.collection('OrderItems').doc(itemDocInCart.id),
              orderListItem.toMap(),
            );
          }

          // Delete items from "the-chosen" for this seller
          for (var itemDocInCart in sellerItems) {
            transaction.delete(
              _firestore
                  .collection('the-chosen')
                  .doc(currentUserId)
                  .collection(FirebaseX.appName)
                  .doc(itemDocInCart.id),
            );
          }
          return sellerOrderDocRef
              .id; // Return the ID of the created order for this seller
        }); // ---- End of Transaction ----

        if (createdOrderId != null) {
          anySellerProcessingSucceeded = true;
          successfulSellerOrderDisplayIds.add(
            sellerOrderDisplayNumber,
          ); // Use generated for display if preferred
          // Send notification AFTER successful transaction
          await _sendNotificationToSeller(
            sellerUid,
            createdOrderId, // Or sellerOrderDisplayNumber if preferred for notification content
            buyerName,
            buyerImageUrl,
          );
        } else {
          // Should not happen if transaction throws, but as a fallback
          failedSellerUids.add(sellerUid);
        }
      } catch (e) {
        debugPrint(
          "Transaction or notification for seller $sellerUid failed: $e",
        );
        failedSellerUids.add(sellerUid);
        _showErrorSnackbar(
          "خطأ في معالجة الطلب",
          "فشل معالجة طلب البائع $sellerUid: ${e.toString().substring(0, min(e.toString().length, 50))}",
        );
      }
    } // End loop for sellerUids

    isLoading.value = false;
    update();

    // Final feedback to user
    if (failedSellerUids.isEmpty && anySellerProcessingSucceeded) {
      _showSuccessSnackbar("نجاح!", "تم إرسال طلبك بنجاح إلى جميع البائعين.");
      Get.offAll(
        () => BottomBar(initialIndex: 0),
      ); // Navigate to home or orders
    } else if (anySellerProcessingSucceeded && failedSellerUids.isNotEmpty) {
      _showWarningSnackbar(
        "نجاح جزئي",
        "تم إرسال الطلب لبعض البائعين. فشل للبائعين: ${failedSellerUids.join(', ')}. أرقام الطلبات الناجحة: ${successfulSellerOrderDisplayIds.join(', ')}",
      );
      Get.offAll(
        () => BottomBar(initialIndex: 0),
      ); // Navigate, user might need to see their orders
    } else if (failedSellerUids.isNotEmpty && !anySellerProcessingSucceeded) {
      _showErrorSnackbar(
        "فشل",
        "لم يتم إرسال طلبك لأي بائع. يرجى المحاولة مرة أخرى.",
      );
      // Stay on the map screen, or offer retry in dialog (complex to implement full retry)
    } else if (!anySellerProcessingSucceeded && cartSnapshot.docs.isNotEmpty) {
      _showErrorSnackbar(
        "فشل",
        "حدث خطأ غير متوقع ولم يتم إرسال الطلب. الرجاء المحاولة مرة أخرى.",
      );
    }
  }

  /// Sends notification to a specific seller.
  Future<void> _sendNotificationToSeller(
    String sellerUid,
    String orderIdentifier,
    String buyerName,
    String? buyerImageUrl,
  ) async {
    try {
      DocumentSnapshot sellerDoc =
          await _firestore
              .collection(FirebaseX.collectionApp)
              .doc(sellerUid)
              .get();
      if (sellerDoc.exists && sellerDoc.data() != null) {
        final sellerData = sellerDoc.data() as Map<String, dynamic>;
        String? sellerToken = sellerData['token'] as String?;

        if (sellerToken != null && sellerToken.isNotEmpty) {
          await LocalNotification.sendNotificationMessageToUser(
            to: sellerToken,
            title: 'طلب جديد من $buyerName!',
            body:
                'لديك طلب جديد برقم مرجعي: $orderIdentifier.', // Use the actual order ID or a generated one
            uid: _auth.currentUser!.uid, // Buyer's UID
            type: 'new_order_for_seller',
            image: buyerImageUrl, // Buyer's image
          );
        } else {
          debugPrint(
            "FCM token not found for seller UID: $sellerUid. Cannot send notification.",
          );
          // Optionally inform admin or log this missing token.
        }
      } else {
        debugPrint(
          "Seller document not found for UID: $sellerUid. Cannot send notification.",
        );
      }
    } catch (e) {
      debugPrint("Error sending notification to seller $sellerUid: $e");
      // Non-critical for the order itself, but log it.
      // Could show a subtle snackbar if really needed:
      // _showInfoSnackbar("تنبيه بسيط", "فشل إرسال إشعار إلى أحد البائعين.");
    }
  }

  // --- Helper Snackbar Methods ---
  void _showErrorSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade700,
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
      margin: const EdgeInsets.all(12),
      borderRadius: 8,
    );
  }

  void _showSuccessSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade600,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(12),
      borderRadius: 8,
    );
  }

  void _showWarningSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange.shade600,
      colorText: Colors.white,
      duration: const Duration(seconds: 7),
      margin: const EdgeInsets.all(12),
      borderRadius: 8,
    );
  }

  void _showInfoSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue.shade600,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(12),
      borderRadius: 8,
    );
  }

  // Call this method from your UI to update controller's lat/lng
  void updateLocation(double lat, double lng) {
    latitude = lat;
    longitude = lng;
    update(); // For any GetBuilders listening directly to the controller outside of specific Obx
  }
}

// In your GetAddAndRemove controller, you might want a helper like this:
// In class GetAddAndRemove:
/*
  int getTotalItemCountInCart() {
    int totalCount = 0;
    if (_itemQuantities.isNotEmpty) { // Assuming _itemQuantities is your Map<String, int>
        _itemQuantities.forEach((key, value) {
            totalCount += value;
        });
    } else {
        // Fallback: if _itemQuantities is not populated correctly after init,
        // this might require re-fetching or ensuring calculateTotals() is complete.
        // For now, this relies on _itemQuantities being up-to-date.
        debugPrint("Warning: _itemQuantities is empty in getTotalItemCountInCart. Call calculateTotals if needed.");
    }
    return totalCount;
  }
  // Ensure onInit calls calculateTotals and it fully populates _itemQuantities.
  // And that any add/remove operation keeps _itemQuantities consistent.
*/
