import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; // For BuildContext
import 'package:geocoding/geocoding.dart' as geo;
import 'package:get/get.dart';
import '../../XXX/xxx_firebase.dart'; // تأكد من صحة المسار
import '../../Model/DeliveryTaskModel.dart';
import '../controllers/local_notification_controller.dart';
import 'Orderofuser/OrderOfUser.dart';

class Getrequest extends GetxController {
  RxBool isloding2 = false.obs; // جعله RxBool للاستخدام مع Obx أو GetX
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // In Getrequest.dart (متحكم البائع)

  Future<void> RequestAccept(String orderId) async {
    debugPrint("[SELLER_ACCEPT] Attempting to accept order: $orderId");
    // Get.dialog(Center(child: CircularProgressIndicator()), barrierDismissible: false); // مؤشر تحميل

    final String? currentSellerUid = _auth.currentUser?.uid;
    if (currentSellerUid == null) {  debugPrint("[SELLER_ACCEPT] Error: Seller not logged in.");
    // if (Get.isDialogOpen ?? false) Get.back(); // أغلق مؤشر التحميل
    Get.snackbar("خطأ", "يجب تسجيل الدخول كبائع أولاً.");
    return; }

    try {
      DocumentReference orderDocRef = _firestore.collection('orders').doc(orderId);
      DocumentSnapshot orderSnapshot = await orderDocRef.get();

      if (!orderSnapshot.exists || orderSnapshot.data() == null) {   debugPrint("[SELLER_ACCEPT] Error: Order document $orderId does not exist or has no data.");
      // if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar("خطأ", "الطلب رقم $orderId غير موجود.");
      return; }
      final orderData = orderSnapshot.data()! as Map<String, dynamic>;
      
      // طباعة بيانات الطلب للتشخيص
      debugPrint("[SELLER_ACCEPT] Order data keys: ${orderData.keys.toList()}");
      debugPrint("[SELLER_ACCEPT] Order location field: ${orderData['location']}");
      debugPrint("[SELLER_ACCEPT] Order latitude field: ${orderData['latitude']}");
      debugPrint("[SELLER_ACCEPT] Order longitude field: ${orderData['longitude']}");

      if (orderData['RequestAccept'] as bool? ?? false) {  Get.to(() => OrderOfUser(uid: orderId));
      return;}

      String? buyerActualUid = orderData['uidUser'] as String?;
      if (buyerActualUid == null || buyerActualUid.isEmpty) {  debugPrint("[SELLER_ACCEPT] Error: Buyer UID (uidUser) missing in order $orderId.");
      // if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar("خطأ في بيانات الطلب", "معرف المشتري مفقود.");
      return; }

      // --- جلب بيانات إضافية ضرورية لإنشاء المهمة ---
      DocumentSnapshot sellerDocSnapshot = await _firestore.collection(FirebaseX.collectionSeller).doc(currentSellerUid).get();
      if (!sellerDocSnapshot.exists || sellerDocSnapshot.data() == null) { debugPrint("[SELLER_ACCEPT] Error: Seller profile for $currentSellerUid not found.");
      // if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar("خطأ في ملف البائع", "لم يتم العثور على ملف البائع الخاص بك.");
      return; }
      final sellerProfileData = sellerDocSnapshot.data()! as Map<String, dynamic>;
      // SellerModel seller = SellerModel.fromMap(sellerProfileData, currentSellerUid); // تحويل إلى نموذج إذا أردت

      DocumentSnapshot buyerUserDocSnapshot = await _firestore.collection(FirebaseX.collectionApp).doc(buyerActualUid).get();
      if (!buyerUserDocSnapshot.exists || buyerUserDocSnapshot.data() == null) {  debugPrint("[SELLER_ACCEPT] Error: Buyer user document $buyerActualUid not found.");
      // if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar("خطأ في بيانات المشتري", "لم يتم العثور على حساب المشتري.");
      return; }
      final buyerUserData = buyerUserDocSnapshot.data()! as Map<String, dynamic>;
      String? buyerToken = buyerUserData['token'] as String?;
      // UserModel buyer = UserModel.fromMap(buyerUserData, buyerActualUid); // تحويل لنموذج إذا أردت

      // --- تحديد المحافظة من موقع البائع (نقطة الاستلام) ---
      String? pickupProvince;
      final GeoPoint? sellerLocation = sellerProfileData['location'] as GeoPoint?; // افترض أن موقع البائع مخزن هنا
      
      // التحقق من وجود موقع البائع
      if (sellerLocation == null) {
        debugPrint("[SELLER_ACCEPT] Warning: Seller location is null, cannot proceed with order acceptance.");
        Get.snackbar(
          "خطأ في الموقع", 
          "لم يتم العثور على موقع محلك. يرجى الذهاب إلى إعدادات المحل وتحديث موقعك أولاً.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 5)
        );
        return;
      }
      
      try {
        List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
            sellerLocation.latitude, sellerLocation.longitude, );
        if (placemarks.isNotEmpty) {
          // adminstrativeArea غالبًا ما تكون المحافظة في العراق/المنطقة
          pickupProvince = placemarks.first.administrativeArea?.isNotEmpty == true
              ? placemarks.first.administrativeArea
              : placemarks.first.locality; // إذا لم تكن المحافظة متاحة، استخدم المدينة
          if (pickupProvince != null && pickupProvince.toLowerCase().contains("governorate")) {
            pickupProvince = pickupProvince.toLowerCase().replaceAll("governorate", "").trim();
          }
          if (pickupProvince != null && pickupProvince.toLowerCase().contains("محافظة")) {
            pickupProvince = pickupProvince.toLowerCase().replaceAll("محافظة", "").trim();
          }
          pickupProvince = pickupProvince?.capitalizeFirst; // اجعل أول حرف كبير
        }
      } catch (e) {
        debugPrint("[SELLER_ACCEPT] Error geocoding seller location to get province: $e");
      }
          debugPrint("[SELLER_ACCEPT] Pickup province determined: $pickupProvince");
      
      // التحقق من وجود موقع التسليم (قد يكون كـ GeoPoint أو latitude/longitude منفصلين)
      GeoPoint? deliveryLocation;
      
      // محاولة قراءة الموقع كـ GeoPoint أولاً
      if (orderData['location'] is GeoPoint) {
        deliveryLocation = orderData['location'] as GeoPoint;
        debugPrint("[SELLER_ACCEPT] Found delivery location as GeoPoint: (${deliveryLocation.latitude}, ${deliveryLocation.longitude})");
      }
      // إذا لم يوجد كـ GeoPoint، جرب قراءة latitude و longitude منفصلين
      else if (orderData['latitude'] != null && orderData['longitude'] != null) {
        final lat = (orderData['latitude'] as num).toDouble();
        final lng = (orderData['longitude'] as num).toDouble();
        deliveryLocation = GeoPoint(lat, lng);
        debugPrint("[SELLER_ACCEPT] Found delivery location as separate lat/lng: ($lat, $lng), converted to GeoPoint");
      }
      
              if (deliveryLocation == null) {
        debugPrint("[SELLER_ACCEPT] Warning: Delivery location is null, cannot proceed with order acceptance.");
        debugPrint("[SELLER_ACCEPT] Available order data keys: ${orderData.keys.toList()}");
        debugPrint("[SELLER_ACCEPT] Order data: $orderData");
        Get.snackbar(
          "خطأ في موقع التسليم", 
          "لم يتم العثور على موقع التسليم في الطلب. يرجى التحقق من أن الطلب يحتوي على بيانات الموقع.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 5)
        );
        return;
      }
      // ------------------------------------------------------

      String? newDeliveryTaskId;

      await _firestore.runTransaction((transaction) async {
        transaction.update(orderDocRef, {'RequestAccept': true, 'sellerAcceptedAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp()});

        DocumentReference newTaskDocRef = _firestore.collection(FirebaseX.deliveryTasksCollection).doc();
        newDeliveryTaskId = newTaskDocRef.id;

        // --- جلب ملخص المنتجات من المجموعة الفرعية OrderItems ---
        QuerySnapshot orderItemsSnapshot = await orderDocRef.collection('OrderItems').get(); // يمكنك قراءتها قبل المعاملة أيضًا
        List<Map<String, dynamic>> itemsSummaryForTask = orderItemsSnapshot.docs.map((doc) {
          final itemData = doc.data() as Map<String, dynamic>;
          return {
            'itemId': itemData['uidItem'], // من الأفضل إضافة السعر هنا إذا كان محفوظًا في OrderItems
            'itemName': itemData['itemNameGenerated'] ?? 'منتج غير مسمى', // افترض أنك تولد/تحفظ اسم المنتج هنا
            'quantity': itemData['number'] ?? 1,
            'isOffer': itemData['isOfer'] ?? false,
          };
        }).toList();
        // ---------------------------------------------------


        debugPrint("[SELLER_ACCEPT] Creating delivery task with:");
        debugPrint("  - Pickup location: (${sellerLocation.latitude}, ${sellerLocation.longitude})");
        debugPrint("  - Delivery location: (${deliveryLocation!.latitude}, ${deliveryLocation.longitude})");
        debugPrint("  - Province: $pickupProvince");
        
        final taskData = DeliveryTaskModel(
          taskId: newDeliveryTaskId!,
          orderId: orderId,
          sellerId: currentSellerUid,
          buyerId: buyerActualUid,
          sellerName: sellerProfileData['sellerName'] as String?, // اسم البائع الشخصي
          sellerShopName: sellerProfileData['shopName'] as String?, // اسم محل البائع
          sellerPhoneNumber: sellerProfileData['shopPhoneNumber'] as String?,
          pickupLocationGeoPoint: sellerLocation, // GeoPoint لموقع البائع
          pickupAddressText: sellerProfileData['shopAddressText'] as String?,
          buyerName: buyerUserData['name'] as String?,
          buyerPhoneNumber: buyerUserData['phoneNumber'] as String?,
          deliveryLocationGeoPoint: deliveryLocation, // موقع التسليم من الطلب
          deliveryAddressText: orderData['shopAddressText'] as String? ?? orderData['deliveryAddress'] as String? ?? orderData['address'] as String?, // العنوان المكتوب في الطلب
          deliveryInstructions: orderData['deliveryNotes'] as String?,
          status: DeliveryTaskStatus.company_pickup_request, // <--- الحالة الأولية الجديدة
          createdAt: Timestamp.now(), // أو serverTimestamp من toMap
          itemsSummary: itemsSummaryForTask,
          deliveryFee: (orderData['deliveryFee'] as num?)?.toDouble(),
          paymentMethod: orderData['paymentMethod'] as String?,
          // amountToCollect: (orderData['totalPriceOfOrder'] as num?)?.toDouble(), // قد يكون totalPriceOfOrder
          province: pickupProvince, // <-- حفظ المحافظة
          // assignedCompanyId و assignedToDriverId يكونان null هنا
        );
        transaction.set(newTaskDocRef, taskData.toMap());
      });

      debugPrint("[SELLER_ACCEPT] Order $orderId accepted by seller, new task $newDeliveryTaskId created with status 'company_pickup_request'.");

      // --- إرسال إشعار للمشتري ---
      if (buyerToken != null && buyerToken.isNotEmpty) {
        // await LocalNotification.sendNotificationMessageToUser(...)
      } else { /* ... */ }

      // --- (اختياري) إرسال إشعار عام (مثلاً لموضوع FCM) بأن هناك مهمة جديدة متاحة للشركات ---
      // هذا يتطلب نظام إشعارات يدعم المواضيع أو إرسال متعدد.
      // await NotificationService.notifyCompaniesAboutNewTask(newDeliveryTaskId, sellerProfileData['shopName'], pickupProvince);

      // if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar("تم القبول", "تم قبول الطلب بنجاح. سيتم الآن عرضه لشركات التوصيل.", backgroundColor: Colors.green, colorText: Colors.white);
      Get.to(() => OrderOfUser(uid: orderId));

    } catch (e, s) {
      debugPrint("[SELLER_ACCEPT] CRITICAL ERROR: $e\n$s");
      // if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar("خطأ فادح", "حدث خطأ غير متوقع: ${e.toString()}", duration: const Duration(seconds: 6));
    }
  }









  Future<void> RequestRejection(String orderId, double size, BuildContext context) async {
    showDialog<void>(
      barrierDismissible: !isloding2.value, // لا تسمح بالإغلاق أثناء التحميل
      context: context,
      builder: (BuildContext dialogContext) { // استخدم dialogContext لتجنب التباس السياق
        return AlertDialog(
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Obx(() => isloding2.value // استخدم .value مع RxBool
                      ? const CircularProgressIndicator()
                      : IconButton(
                    icon: Icon(Icons.done, color: Colors.green, size: size / 15),
                    onPressed: () async {
                      isloding2.value = true; // تحديث RxBool
                      try {
                        DocumentReference orderDocRef = FirebaseFirestore.instance.collection('orders').doc(orderId);
                        DocumentSnapshot orderSnapshot = await orderDocRef.get();

                        if (!orderSnapshot.exists) {
                          Get.snackbar("خطأ", "الطلب المراد حذفه غير موجود.");
                          Navigator.pop(dialogContext); // Close dialog using dialogContext
                          return;
                        }
                        // افترض أن 'uidUser' هو حقل uid المشتري في مستند الطلب
                        String? buyerUid = orderSnapshot.get('uidUser') as String?;

                        if (buyerUid == null || buyerUid.isEmpty) {
                          Get.snackbar("خطأ بيانات", "لم يتم العثور على معرّف المشتري في الطلب لإرسال الإشعار.");
                          // يمكنك أن تقرر ما إذا كنت ستستمر في الحذف أم لا
                        }

                        // حذف المجموعة الفرعية OrderItems
                        QuerySnapshot orderItemsSnapshot = await orderDocRef.collection('OrderItems').get();
                        for (var doc1 in orderItemsSnapshot.docs) {
                          await orderDocRef.collection('OrderItems').doc(doc1.id).delete();
                        }

                        // حذف مستند الطلب الرئيسي
                        await orderDocRef.delete();

                        // إرسال إشعار للمشتري
                        if (buyerUid != null && buyerUid.isNotEmpty) {
                          DocumentSnapshot buyerUserDoc = await FirebaseFirestore.instance
                              .collection(FirebaseX.collectionApp) // اسم مجموعة المستخدمين
                              .doc(buyerUid) // استخدم معرف المشتري الفعلي
                              .get();
                          if (buyerUserDoc.exists) {
                            final buyerData = buyerUserDoc.data() as Map<String,dynamic>;
                            String? token = buyerData['token'] as String?;
                            if(token != null && token.isNotEmpty){
                              await LocalNotificationController.sendNotificationMessageToUser(
                                  to: token,
                                  title: FirebaseX.appName,
                                  body: 'تم إلغاء طلبك رقم: $orderId',
                                  uid: orderId,
                                  type: 'RequestRejected',
                                  image: '');
                            }
                          }
                        }

                        Navigator.pop(dialogContext); // إغلاق حوار التأكيد باستخدام dialogContext
                      } catch (e) {
                        Get.snackbar("خطأ", "فشل حذف الطلب: $e");
                        if (Navigator.canPop(dialogContext)) {
                          Navigator.pop(dialogContext);
                        }
                      } finally {
                        isloding2.value = false; // تحديث RxBool
                      }
                    },
                  ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red, size: size / 17),
                    onPressed: () {
                      if (!isloding2.value) Navigator.pop(dialogContext); // اسمح بالإغلاق فقط إذا لم يكن هناك تحميل
                    },
                  ),
                ],
              ),
            )
          ],
          title: const Text('انت متأكد من حذف الطلب', textAlign: TextAlign.center,),
          content: const Text('لا يمكن التراجع إذا وافقت', textAlign: TextAlign.center),
        );
      },
    );
  }
}