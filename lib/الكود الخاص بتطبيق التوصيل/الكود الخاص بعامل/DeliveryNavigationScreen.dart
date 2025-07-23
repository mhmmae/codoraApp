// delivery_navigation_screen.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../routes/app_routes.dart';
import '../الكود الخاص بمشرف التوصيل/DeliveryTaskDetailsForAdminScreen.dart';
import '../../Model/DeliveryTaskModel.dart';
import 'DeliveryNavigationController.dart'; // إذا كنت ستعرض صورة البائع/المشتري
// (قد تحتاج AppRoutes إذا كانت هناك تنقلات من هنا)
// import '../../main.dart'; // لـ AppRoutes

class DeliveryNavigationScreen extends GetView<DeliveryNavigationController> {
  const DeliveryNavigationScreen({super.key});

  // --- ويدجت لعرض معلومات المهمة العلوية (خريطة، تفاصيل وجهة) ---
  Widget _buildHeaderSection(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        // --- الخريطة ---
        SizedBox(
          height: Get.height * 0.35, // يمكنك تعديل ارتفاع الخريطة
          child: Obx(() => GoogleMap(
            onMapCreated: controller.onMapCreated, // <--- التأكد من ربط الدالة الصحيحة
            initialCameraPosition: CameraPosition(
              target: controller.driverCurrentMapPosition.value ?? // موقع السائق كنقطة بداية
                  (controller.taskDetails.value?.pickupLatLng ?? const LatLng(33.3152, 44.3661)),
              zoom: 14.5,
            ),
            markers: controller.mapMarkers,   // <--- استخدام RxSet من المتحكم
            polylines: controller.polylines, // <--- استخدام RxSet من المتحكم
            myLocationButtonEnabled: true, // السماح للسائق بتوسيط موقعه
            myLocationEnabled: false,     // موقع السائق يُعرض كماركر مخصص (البرتقالي)
            zoomControlsEnabled: true,
            padding: EdgeInsets.only(bottom: Get.height * 0.05), // مساحة سفلية طفيفة
          )),
        ),
        // --- شريط معلومات الوجهة التالية ---
        Obx(() {
          if (controller.taskDetails.value == null) return const SizedBox.shrink();
          final task = controller.taskDetails.value!;
          final status = controller.currentTaskStatus; // <--- استخدام الـ getter هنا
          Map<String, dynamic> destinationInfo = _getDestinationInfoForStatus(task, status, context);

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: (destinationInfo['color'] as Color?)?.withOpacity(0.15) ?? theme.primaryColorLight.withOpacity(0.2),
            child: Row(
              children: [
                Icon(destinationInfo['icon'], color: destinationInfo['color'], size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(destinationInfo['title'], style: Get.textTheme.titleSmall?.copyWith(color: Colors.grey.shade700)),
                      Text(destinationInfo['name'], style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      if (destinationInfo['address'] != null && destinationInfo['address'].isNotEmpty)
                        Text(destinationInfo['address'], style: Get.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),

                      Obx(() {
                        if (controller.currentDistanceToDestination.value.isNotEmpty) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Row(
                              children: [
                                Icon(Icons.map_outlined, size: 16, color: Colors.blueGrey.shade700),
                                const SizedBox(width: 6),
                                Text(
                                  "المسافة: ${controller.currentDistanceToDestination.value}",
                                  style: Get.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                                ),
                                if (controller.currentEtaToDestination.value.isNotEmpty) ...[
                                  const Text("  |  ", style: TextStyle(color: Colors.grey)),
                                  Icon(Icons.timer_outlined, size: 16, color: Colors.blueGrey.shade700),
                                  const SizedBox(width: 4),
                                  Text(
                                    controller.currentEtaToDestination.value,
                                    style: Get.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                    ],
                  ),
                ),
                // أزرار الاتصال وفتح الخريطة الخارجية
                if (destinationInfo['phone'] != null && destinationInfo['phone'].isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.call_outlined, color: Colors.green.shade700),
                    onPressed: () => destinationInfo['onContact'](),
                    tooltip: "اتصال بـ ${destinationInfo['name']}",
                  ),
                IconButton(
                  icon: Icon(Icons.navigation_outlined, color: Colors.blue.shade700),
                  onPressed: () => destinationInfo['onNavigate'](),
                  tooltip: "التنقل إلى ${destinationInfo['name']}",
                ),
              ],
            ),
          );
        }),
      ],
    );
  }






  Future<void> launchMapsApp(double latitude, double longitude, String destinationLabel) async {
    Uri? uri;
    // ملاحظة: label يستخدم في خرائط جوجل على الويب، قد لا يظهر في تطبيقات الهاتف دائمًا عند بدء الملاحة مباشرة.
    String mapsUrlApple = 'maps://?daddr=$latitude,$longitude&dirflg=d'; // d for driving
    String mapsUrlGoogle = 'google.navigation:q=$latitude,$longitude&mode=d'; // d for driving
    String webFallbackUrl = 'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving';

    if (Platform.isIOS) {
      //  محاولة فتح خرائط آبل أولاً، ثم خرائط جوجل إذا لم تنجح آبل أو لم تكن مثبتة
      if (await canLaunchUrl(Uri.parse(mapsUrlApple))) {
        await launchUrl(Uri.parse(mapsUrlApple), mode: LaunchMode.externalApplication);
        debugPrint("[MAP_LAUNCH_IOS] Launched Apple Maps to: $destinationLabel");
        return;
      } else if (await canLaunchUrl(Uri.parse("comgooglemaps://?saddr=&daddr=$latitude,$longitude&directionsmode=driving"))) { //  محاولة فتح تطبيق جوجل مابس مباشرة
        await launchUrl(Uri.parse("comgooglemaps://?saddr=&daddr=$latitude,$longitude&directionsmode=driving"), mode: LaunchMode.externalApplication);
        debugPrint("[MAP_LAUNCH_IOS] Launched Google Maps app (iOS) to: $destinationLabel");
        return;
      }
      //  إذا فشل كل شيء، استخدم رابط الويب
      uri = Uri.parse(webFallbackUrl);

    } else if (Platform.isAndroid) {
      //  محاولة فتح تطبيق جوجل مابس مباشرة
      if (await canLaunchUrl(Uri.parse(mapsUrlGoogle))) {
        uri = Uri.parse(mapsUrlGoogle);
      } else { //  إذا فشل، استخدم رابط الويب
        uri = Uri.parse(webFallbackUrl);
      }
    } else { // للمنصات الأخرى (ويب، سطح مكتب)
      uri = Uri.parse(webFallbackUrl);
    }

    debugPrint("[MAP_LAUNCH] Attempting to launch URI: $uri for: $destinationLabel");
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        debugPrint("[MAP_LAUNCH] Maps app launched successfully for: $destinationLabel");
      } else {
        debugPrint("[MAP_LAUNCH] Could not launch specific URI: $uri. Attempting generic web maps.");
        // كاحتياطي أخير، حاول فتح نقطة على الخريطة (بدون توجيه مباشر)
        Uri genericWebUri = Uri.parse("https://www.google.com/maps/search/?api=1&query=$latitude,$longitude");
        if(await canLaunchUrl(genericWebUri)){
          await launchUrl(genericWebUri, mode:LaunchMode.externalApplication);
          debugPrint("[MAP_LAUNCH] Launched generic web maps as fallback for: $destinationLabel");
        } else {
          throw 'Could not launch any maps URI for $latitude,$longitude';
        }
      }
    } catch (e) {
      debugPrint("[MAP_LAUNCH] Error launching maps app: $e");
      Get.snackbar(
        'خطأ في الخرائط',
        'لا يمكن فتح تطبيق الخرائط. يرجى التأكد من تثبيت تطبيق خرائط صالح.',
        backgroundColor: Colors.red.shade400, colorText: Colors.white,
        duration: const Duration(seconds: 5), snackPosition: SnackPosition.BOTTOM,
      );
    }
  }










  // دالة مساعدة لتحديد معلومات الوجهة بناءً على حالة المهمة
  Map<String, dynamic> _getDestinationInfoForStatus(DeliveryTaskModel task, DeliveryTaskStatus status, BuildContext context) {
    String title = "الوجهة التالية";
    String name = "غير محدد";
    String? address = "";
    IconData icon = Icons.pin_drop_outlined;
    Color color = Theme.of(context).primaryColor;
    String? phone;
    VoidCallback? onContact;
    VoidCallback onNavigate = () {
      Get.snackbar("خطأ", "لا يمكن تحديد وجهة التنقل حاليًا.");
    };
    GeoPoint? destinationGeoPoint; // لتخزين الوجهة الجغرافية

    // ... (بداية الـ if/else if blocks لتحديد title, name, address, icon, color, phone, onContact)
    if (status == DeliveryTaskStatus.driver_assigned || status == DeliveryTaskStatus.en_route_to_pickup) {
      title = "التوجه إلى البائع للاستلام";
      name = task.sellerShopName ?? task.sellerName ?? "البائع";
      address = task.pickupAddressText;
      icon = Icons.storefront_outlined;
      color = Colors.blue.shade700;
      phone = task.sellerPhoneNumber;
      onContact = controller.contactSeller; // تأكد أن controller مُشار إليه بشكل صحيح إذا كانت هذه الدالة داخل كلاس الواجهة
      // أو مباشرة contactSeller إذا كانت هذه الدالة عضوًا في المتحكم
      destinationGeoPoint = task.pickupLocationGeoPoint;
    } else if (status == DeliveryTaskStatus.picked_up_from_seller) {
      if (task.driverPickupDecision == 'hub_dropoff' && controller.selectedHubForDropOff.value != null) {
        title = "التوجه إلى مقر الشركة";
        name = controller.selectedHubForDropOff.value!['hubName'] as String? ?? "مقر الشركة";
        address = controller.selectedHubForDropOff.value!['hubAddressText'] as String? ?? '';
        icon = Icons.business_center_outlined;
        color = Colors.deepPurple.shade600;
        destinationGeoPoint = controller.selectedHubForDropOff.value!['hubLocation'] as GeoPoint?;
      } else {
        title = "التوجه للمشتري (أو تحديد الوجهة)"; // تم تغيير النص ليكون أوضح
        name = task.buyerName ?? "المشتري";
        address = task.deliveryAddressText;
        icon = Icons.person_pin_circle_outlined;
        color = Colors.green.shade700;
        phone = task.buyerPhoneNumber;
        onContact = controller.contactBuyer; // أو contactBuyer
        destinationGeoPoint = task.deliveryLocationGeoPoint;
      }
    } else if (status == DeliveryTaskStatus.en_route_to_hub && controller.selectedHubForDropOff.value != null) {
      title = "التوجه إلى مقر الشركة";
      name = controller.selectedHubForDropOff.value!['hubName'] as String? ?? "مقر الشركة";
      address = controller.selectedHubForDropOff.value!['hubAddressText'] as String? ?? '';
      icon = Icons.business_center_outlined;
      color = Colors.deepPurple.shade600;
      destinationGeoPoint = controller.selectedHubForDropOff.value!['hubLocation'] as GeoPoint?;
    } else if (status == DeliveryTaskStatus.out_for_delivery_to_buyer || status == DeliveryTaskStatus.at_buyer_location) {
      title = "التوجه للمشتري للتسليم"; // تم تعديل النص
      name = task.buyerName ?? "المشتري"; // <--- تم إضافة name هنا
      address = task.deliveryAddressText;
      icon = Icons.person_pin_circle_outlined;
      color = Colors.green.shade700;
      phone = task.buyerPhoneNumber;
      onContact = controller.contactBuyer; // أو contactBuyer
      destinationGeoPoint = task.deliveryLocationGeoPoint;
      // تم حذف الشرط المكرر
      // } else if ( (status == DeliveryTaskStatus.driver_assigned || status == DeliveryTaskStatus.en_route_to_pickup) &&
      //     (task.sellerName != null && task.sellerName!.toLowerCase().contains("مقر")) ) {
      //   // ...
    } else { // للحالات النهائية أو غير المتوقعة
      final visuals = getTaskStatusVisuals(status, context); // افترض وجود هذه الدالة
      title = "المهمة: ${visuals['text']}";
      name = "لا توجد وجهة تالية نشطة";
      icon = visuals['icon'];
      color = visuals['color'];
      //  destinationGeoPoint يبقى null، onNavigate ستعرض الرسالة الافتراضية
    }

    // بناء دالة onNavigate بشكل ديناميكي
    if (destinationGeoPoint != null) {
      final String navLabel = name; // استخدم الاسم المحدد كـ label
      onNavigate = () => launchMapsApp(destinationGeoPoint!.latitude, destinationGeoPoint.longitude, navLabel);
    }

    return {
      'title': title, 'name': name, 'address': address,
      'icon': icon, 'color': color, 'phone': phone,
      'onContact': onContact, 'onNavigate': onNavigate
    };
  }

  // --- ويدجت لمنطقة إجراءات الاستلام من البائع ---

  Widget _buildPickupActions(BuildContext context) { // السياق هنا هو BuildContext الخاص بالشاشة
    final theme = Theme.of(context);

    return Obx(() { // يراقب التغيرات في متغيرات controller.isScanningPickupItems، إلخ.
      final task = controller.taskDetails.value; // للوصول الآمن لبيانات المهمة
      if (task == null) return const SizedBox.shrink(); // لا تعرض شيئًا إذا لم تكن هناك مهمة

      return Card(
        margin: const EdgeInsets.all(12),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- الجزء الذي يظهر عندما لا تكون واجهة مسح المنتجات مفعلة ---
              if (!controller.isScanningPickupItems.value) ...[
                Text(
                  "أنت الآن عند \"${task.sellerShopName ?? task.sellerName ?? 'البائع'}\" لاستلام الطلب.",
                  style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: Text(
                    // تحديد نص الزر بناءً على ما إذا كان هناك شيء للمسح
                      (controller.totalItemsToScan.value > 0 || (task.sellerMainPickupConfirmationBarcode != null && task.sellerMainPickupConfirmationBarcode!.isNotEmpty))
                          ? "البدء بمسح الباركود للاستلام"
                          : "تأكيد الاستلام (لا يوجد باركود مطلوب)"
                  ),
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)
                  ),
                  onPressed: controller.isLoadingAction.value
                      ? null // تعطيل إذا كان هناك إجراء رئيسي جارٍ
                      : () {
                    // إذا لم يكن هناك باركودات للمسح (لا فردية ولا رئيسية)، قم بالتأكيد مباشرة
                    if (controller.totalItemsToScan.value == 0 && (task.sellerMainPickupConfirmationBarcode == null || task.sellerMainPickupConfirmationBarcode!.isEmpty)) {
                      controller.confirmPickupFromSeller(context); // تمرير السياق لحوارات محتملة
                    } else {
                      // وإلا، ابدأ جلسة مسح الباركود
                      controller.startOrStopPickupItemScanningSession(true);
                    }
                  },
                ),
              ]
              // --- الجزء الذي يظهر عندما تكون واجهة مسح المنتجات مفعلة ---
              else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("مسح منتجات الاستلام", style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    TextButton.icon(
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text("إلغاء المسح", style: TextStyle(fontSize: 12)),
                        onPressed: () => controller.startOrStopPickupItemScanningSession(false), // إيقاف جلسة المسح
                        style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700)
                    )
                  ],
                ),
                const Divider(height: 15),
                Text(
                    "المنتجات المتوقعة: (${controller.scannnedItemsCount.value} / ${controller.totalItemsToScan.value} تم مسحها)",
                    style: Get.textTheme.bodySmall
                ),
                const SizedBox(height: 8),

                // --- عرض قائمة المنتجات للمسح ---
                // إذا لم يكن هناك باركود رئيسي، وكانت قائمة المنتجات الفردية فارغة أيضًا (نادر)
                if (controller.itemsToPickupForCurrentTask.isEmpty &&
                    controller.totalItemsToScan.value == 0 &&
                    task.sellerMainPickupConfirmationBarcode == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Text(
                      "لا توجد تفاصيل منتجات محددة للمسح في هذه المهمة.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontStyle: FontStyle.italic, color: Colors.blueGrey),
                    ),
                  )
                // إذا كان هناك منتجات فردية للمسح (totalItemsToScan > 0)
                else if (controller.totalItemsToScan.value > 0)
                  SizedBox(
                    height: Get.height * 0.20, // ارتفاع محدد للقائمة لتناسب الشاشات المختلفة
                    child: Scrollbar(
                      thumbVisibility: true,
                      child: ListView.builder(
                        shrinkWrap: true, // ضروري داخل Column
                        itemCount: controller.itemsToPickupForCurrentTask.length,
                        itemBuilder: (ctx, index) {
                          final item = controller.itemsToPickupForCurrentTask[index];
                          final bool isScannedThisSession = item['itemScannedByUserInterface'] == true;
                          return Card(
                            elevation: isScannedThisSession ? 0.5 : 1.5,
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            color: isScannedThisSession ? Colors.green.shade50 : theme.cardColor.withOpacity(0.8),
                            child: ListTile(
                              dense: true,
                              leading: Icon(
                                isScannedThisSession ? Icons.check_circle_outline_rounded : Icons.qr_code_2_rounded,
                                color: isScannedThisSession ? Colors.green.shade700 : theme.primaryColor,
                              ),
                              title: Text(
                                item['itemName'] as String? ?? "منتج غير مسمى", // أضفت cast و null check
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isScannedThisSession ? FontWeight.normal : FontWeight.w500,
                                  decoration: isScannedThisSession ? TextDecoration.lineThrough : null,
                                  color: isScannedThisSession ? Colors.grey.shade700 : null,
                                ),
                              ),
                              subtitle: Text(
                                "الباركود: ${item['itemBarcode'] as String? ?? 'N/A'}", // أضفت cast و null check
                                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 12),

                // --- زر مسح الباركود (سواء للمنتج التالي أو الباركود الرئيسي للبائع) ---
                if (controller.totalItemsToScan.value > 0 || (task.sellerMainPickupConfirmationBarcode != null && task.sellerMainPickupConfirmationBarcode!.isNotEmpty))
                  ElevatedButton.icon(
                    icon: const Icon(Icons.document_scanner_outlined),
                    label: Text(
                      // تحديد نص الزر بناءً على ما إذا كان هناك باركود رئيسي للبائع
                        task.sellerMainPickupConfirmationBarcode != null && task.sellerMainPickupConfirmationBarcode!.isNotEmpty
                            ? "مسح باركود تأكيد البائع الرئيسي"
                            : "مسح باركود المنتج التالي"
                    ),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColorDark, // لون مميز لزر المسح
                        padding: const EdgeInsets.symmetric(vertical: 10)),
                    onPressed: controller.isLoadingAction.value
                        ? null // تعطيل إذا كان هناك إجراء رئيسي آخر جارٍ
                        : () async {
                      String purposeText = task.sellerMainPickupConfirmationBarcode != null && task.sellerMainPickupConfirmationBarcode!.isNotEmpty
                          ? "امسح باركود تأكيد البائع"
                          : "امسح باركود المنتج من البائع";
                      // تمرير السياق هنا لدالة scanBarcode في المتحكم
                      String? scannedValue = await controller.scanBarcode(context, purposeText);
                      if (scannedValue != null && scannedValue.isNotEmpty) {
                        // إذا كان هناك باركود رئيسي للبائع، عالجه
                        if (task.sellerMainPickupConfirmationBarcode != null && task.sellerMainPickupConfirmationBarcode!.isNotEmpty) {
                          if (scannedValue.trim().toLowerCase() == task.sellerMainPickupConfirmationBarcode!.trim().toLowerCase()) {
                            // الباركود الرئيسي صحيح، قم بتأكيد الاستلام الكلي مباشرة
                            controller.confirmPickupFromSeller(context);
                          } else {
                            Get.snackbar("باركود خاطئ", "باركود تأكيد البائع الرئيسي غير صحيح.", backgroundColor: Colors.red.shade300);
                          }
                        } else {
                          // إذا لا، فهذا باركود منتج فردي
                          controller.processScannedPickupItemBarcode(scannedValue);
                        }
                      }
                    },
                  ),
                const SizedBox(height: 16),

                // --- زر تأكيد الاستلام النهائي ---
                ElevatedButton.icon(
                  icon: controller.isLoadingAction.value
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_and_archive_outlined),
                  label: Text(controller.isLoadingAction.value
                      ? "جاري الحفظ..."
                      : "تأكيد استلام (${controller.scannnedItemsCount.value}) والتوجه للوجهة"
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    // تعديل الشرط: يعطل إذا كان هناك باركود رئيسي ولم يتم مسحه (أو لم يكن صحيحا - نحتاج لحالة إضافية إذا أردنا ذلك)
                    // أو إذا كان هناك منتجات للمسح ولم يتم مسح أي منها
                    ( (task.sellerMainPickupConfirmationBarcode != null && task.sellerMainPickupConfirmationBarcode!.isNotEmpty /* && لم يتم مسحه بنجاح بعد */ ) ||
                        (controller.totalItemsToScan.value > 0 && controller.scannnedItemsCount.value == 0 && (task.sellerMainPickupConfirmationBarcode == null || task.sellerMainPickupConfirmationBarcode!.isEmpty) )
                    ) ? Colors.grey.shade400 // معطل
                        : Colors.green.shade700, // فعال
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: (controller.isLoadingAction.value ||
                      // شرط التعطيل:
                      // 1. إذا كان هناك باركود رئيسي ولم يتم التحقق منه بعد (نحتاج لطريقة لتتبع هذا، حاليًا إذا مسحه السائق بنجاح يتم استدعاء confirmPickupFromSeller مباشرة).
                      // 2. أو إذا لا يوجد باركود رئيسي، ولكن هناك منتجات للمسح ولم يتم مسح أي منها.
                      ( (task.sellerMainPickupConfirmationBarcode == null || task.sellerMainPickupConfirmationBarcode!.isEmpty) &&
                          controller.totalItemsToScan.value > 0 && controller.scannnedItemsCount.value == 0
                      )
                  )
                      ? null // يكون معطلاً
                      : () => controller.confirmPickupFromSeller(context), // تمرير السياق
                ),
              ],
            ],
          ),
        ),
      );
    });
  }


  Widget _buildCompletedTaskView(String message, IconData icon, Color color, BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 2,
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(message, style: Get.textTheme.titleMedium?.copyWith(color: color.withOpacity(0.9)), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: () => Get.offNamed(AppRoutes.DRIVER_DASHBOARD), // أو MyTasksScreen
                child: const Text("العودة إلى مهامي")
            )
          ],
        ),
      ),
    );
  }


  Widget _buildTaskActionSection(BuildContext context) {
    return Obx(() {
      final taskStatus = controller.currentTaskStatus; // استخدام الـ getter
      final task = controller.taskDetails.value; // للوصول لـ driverPickupDecision

      switch (taskStatus) {
        case DeliveryTaskStatus.driver_assigned:
        case DeliveryTaskStatus.en_route_to_pickup:
          return _buildPickupActions(context);

        case DeliveryTaskStatus.picked_up_from_seller:
        // --- تعديل هنا: اعرض خيار الوجهة فقط إذا لم يتم اتخاذ قرار بعد ---
          if (task?.driverPickupDecision == null) {
            return _buildPickupDecisionActions(context);
          } else if (task?.driverPickupDecision == 'direct_delivery') {
            //  تم اتخاذ قرار التوصيل المباشر، ولكن لم يتم تغيير الحالة بعد لـ out_for_delivery (نادر)
            //  يفترض أن setDeliveryTargetToBuyer ستغير الحالة
            return _buildPreDeliveryActions(context);
          } else if (task?.driverPickupDecision == 'hub_dropoff') {
            //  تم اتخاذ قرار التوجه للمقر، ولكن لم تتغير الحالة لـ en_route_to_hub (نادر)
            return _buildEnRouteToHubActions(context);
          }
          // حالة احتياطية إذا كان القرار موجودًا ولكن الحالة لم تتطابق (يجب ألا يحدث)
          return const Padding(padding: EdgeInsets.all(16), child: Center(child: Text("جاري تحديد الوجهة التالية...")));

        case DeliveryTaskStatus.out_for_delivery_to_buyer:
          return _buildPreDeliveryActions(context); // "أنا في الطريق للمشتري"

        case DeliveryTaskStatus.en_route_to_hub: // <--- حالة جديدة تم تعريفها سابقًا
          return _buildEnRouteToHubActions(context); // "أنا في الطريق للمقر"

        case DeliveryTaskStatus.at_buyer_location:
          return _buildBuyerDeliveryConfirmationActions(context);

      // يمكنك إضافة حالات أخرى هنا (مثل عرض رسالة إذا كانت المهمة مكتملة أو ملغاة)
        case DeliveryTaskStatus.delivered:
          return _buildCompletedTaskView("تم تسليم هذه المهمة بنجاح.", Icons.check_circle_outline_rounded, Colors.green, context);
        case DeliveryTaskStatus.delivery_failed:
          return _buildCompletedTaskView("فشل تسليم هذه المهمة. السبب: ${controller.taskDetails.value?.failureOrCancellationReason ?? 'غير محدد'}", Icons.error_outline_rounded, Colors.red, context);
      // ... (معالجة باقي الحالات الملغاة المشابهة)
        case DeliveryTaskStatus.cancelled_by_buyer:
        case DeliveryTaskStatus.cancelled_by_seller:
        case DeliveryTaskStatus.cancelled_by_company_admin:
        case DeliveryTaskStatus.cancelled_by_platform_admin:
          return _buildCompletedTaskView("تم إلغاء هذه المهمة. السبب: ${controller.taskDetails.value?.failureOrCancellationReason ?? 'غير محدد'}", Icons.cancel_outlined, Colors.orange, context);


        default:
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(child: Text("الحالة الحالية للمهمة: ${deliveryTaskStatusToString(taskStatus).replaceAll('_',' ')}\n (لا يوجد إجراء محدد لهذه الحالة حاليًا)", textAlign: TextAlign.center)),
          );
      }
    });
  }


// --- ويدجت جديدة: اختيار الوجهة بعد الاستلام من البائع ---
  Widget _buildPickupDecisionActions(BuildContext context) {
    final theme = Theme.of(context);
    final task = controller.taskDetails.value;
    if (task == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(12), elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "تم استلام الشحنة بنجاح من \"${task.sellerShopName ?? task.sellerName ?? 'البائع'}\".",
              style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text("يرجى تحديد وجهتك التالية:", textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.person_pin_circle_outlined),
              label: const Text("التوجه مباشرة إلى المشتري"),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 11)),
              onPressed: controller.isLoadingAction.value ? null : () {
                // دالة في المتحكم لتحديث الحالة والقرار
                controller.setDeliveryTargetToBuyer();
              },
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon( //  استخدم OutlinedButton لتمييزه
              icon: Icon(Icons.business_outlined, color: theme.colorScheme.secondary),
              label: Text("تسليم الشحنة لأقرب مقر للشركة", style: TextStyle(color:theme.colorScheme.secondary)),
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  side: BorderSide(color: theme.colorScheme.secondary.withOpacity(0.5))
              ),
              onPressed: controller.isLoadingAction.value || controller.isLoadingCompanyHubs.value
                  ? null
                  : () => controller.chooseHubForDropOff(context),
            ),
          ],
        ),
      ),
    );
  }


// --- ويدجت جديدة: مرحلة "في الطريق إلى المقر" و "تأكيد التسليم للمقر" ---
  Widget _buildEnRouteToHubActions(BuildContext context) {
    final theme = Theme.of(context);
    final task = controller.taskDetails.value;
    final hubData = controller.selectedHubForDropOff.value; // المقر المختار
    if (task == null || hubData == null) return const SizedBox.shrink();

    if (controller.currentTaskStatus != DeliveryTaskStatus.en_route_to_hub) {
      // قد يعرض مؤشر تحميل بسيط إذا كان selectedHubForDropOff لم يُعين بعد
      // لكن يُفترض أنه تم تعيينه بواسطة _proceedWithHubDropOffDecision قبل الوصول لهذه الحالة
      if (controller.isLoadingAction.value || controller.isLoadingCompanyHubs.value) { // إذا كان لا يزال يحمل شيء
        return const Card(margin:EdgeInsets.all(12), child: Padding(padding:EdgeInsets.all(20), child: Center(child: CircularProgressIndicator())));
      }
      return const Card(margin:EdgeInsets.all(12), child: Padding(padding:EdgeInsets.all(20), child: Center(child: Text("جاري تجهيز معلومات التوجه للمقر..."))));
    }
    // هل نحن في وضع مسح باركود المقر؟ يمكن استخدام isScanningBuyerConfirmation بشكل مؤقت
    // أو إضافة متغير حالة جديد isScanningHubConfirmation
    bool isActuallyConfirmingAtHub = controller.isScanningBuyerConfirmation.value; // إعادة استخدام المتغير الحالي


    return Card(
      margin: const EdgeInsets.all(12), elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isActuallyConfirmingAtHub) ...[ // إذا لم يكن في وضع تأكيد المسح للمقر
              Text(
                "أنت الآن في طريقك إلى مقر الشركة:",
                style: Get.textTheme.titleSmall,
                textAlign: TextAlign.center,
              ),
              Text(
                "\"${hubData['hubName'] ?? 'مقر غير محدد'}\"",
                style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              if(hubData['hubAddressText'] != null && hubData['hubAddressText']!.isNotEmpty)
                Text("(${hubData['hubAddressText']})", textAlign: TextAlign.center, style:Get.textTheme.bodySmall?.copyWith(color:Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: controller.isLoadingAction.value
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.location_on_outlined),
                label: Text(controller.isLoadingAction.value ? "جاري..." : "لقد وصلت إلى المقر"),
                onPressed: controller.isLoadingAction.value
                    ? null
                    : () => controller.startOrStopBuyerConfirmationScanning(true), // إعادة استخدام للدخول في وضع التأكيد
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), backgroundColor: Colors.orange.shade700),
              ),
            ] else ...[
              // --- واجهة تأكيد التسليم للمقر ---
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("تأكيد تسليم الشحنة للمقر", style:Get.textTheme.titleMedium?.copyWith(fontWeight:FontWeight.bold)),
                    TextButton.icon(icon:Icon(Icons.close,size:18), label:Text("إلغاء", style:TextStyle(fontSize:12)),
                        onPressed:()=> controller.startOrStopBuyerConfirmationScanning(false), // إعادة استخدام
                        style:TextButton.styleFrom(foregroundColor: Colors.grey.shade700)
                    )
                  ]
              ),
              const Divider(height:15),
              Text(
                "أنت في \"${hubData['hubName']}\". اطلب من مشرف المقر باركود تأكيد استلام الشحنة (الباركود الخاص بالمقر: ${hubData['hubConfirmationBarcode'] ?? 'غير محدد'})، ثم امسحه.",
                textAlign: TextAlign.center, style: Get.textTheme.bodySmall?.copyWith(height: 1.4),
              ),
              const SizedBox(height: 12),
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text("مسح باركود تأكيد المقر"),
                  style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColorDark, padding: const EdgeInsets.symmetric(vertical:10, horizontal: 16)),
                  onPressed: (controller.isLoadingAction.value || controller.isUploadingProofImage.value) // منع أثناء أي تحميل
                      ? null
                      : () async {
                    // استدعاء مسح الباركود وتمرير السياق
                    String? scannedHubCode = await controller.scanBarcode(context, "امسح باركود تأكيد استلام المقر");
                    if (scannedHubCode != null && scannedHubCode.isNotEmpty) {
                      // هنا لا نحتاج لـ processScannedBuyerBarcode، بل مباشرة confirmDropOffAtHub
                      // الذي سيقوم هو بالتحقق من الباركود
                      controller.confirmDropOffAtHub(context, scannedHubCode);
                    }
                  },
                ),
              ),
              const SizedBox(height: 15),

              // --- قسم التقاط صورة الإثبات (اختياري للمقر) ---
              // هذا القسم مشابه لقسم التقاط صورة المشتري
              Obx(() {
                final bool canInteract = !controller.isLoadingAction.value && !controller.isUploadingProofImage.value;
                if (controller.pickedProofImageFile.value == null) {
                  return OutlinedButton.icon(
                    icon: controller.isUploadingProofImage.value
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 1.5))
                        : const Icon(Icons.camera_alt_outlined, size: 20),
                    label: Text(controller.isUploadingProofImage.value ? "جاري الرفع..." :"التقاط صورة للشحنة (مستحسن)"),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                    onPressed: canInteract ? () => controller.pickDeliveryProofImage(ImageSource.camera, context) : null,
                  );
                } else {
                  return Column(
                    children: [
                      const Text("صورة الشحنة المسلمة للمقر:", style:TextStyle(fontSize:12, color:Colors.grey)), SizedBox(height:3),
                      Stack(
                        alignment: Alignment.topLeft,
                        children: [
                          ClipRRect( borderRadius: BorderRadius.circular(8), child: Image.file(controller.pickedProofImageFile.value!, height: 100, fit: BoxFit.contain)),
                          if (canInteract) Positioned(top: -2, left: -2, child: InkWell( onTap: () => controller.pickedProofImageFile.value = null, child: const CircleAvatar(backgroundColor:Colors.black45, radius:12, child: Icon(Icons.close, size: 14, color: Colors.white)))),
                        ],
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.replay_circle_filled_outlined, size: 16),
                        label: const Text("إعادة الالتقاط", style: TextStyle(fontSize: 11)),
                        onPressed: canInteract ? () => controller.pickDeliveryProofImage(ImageSource.camera, context) : null,
                      ),
                    ],
                  );
                }
              }),
              const Divider(height: 20),
              // --- زر التأكيد النهائي للتسليم للمقر ---
              // هذا الزر ليس ضروريًا هنا إذا كان confirmDropOffAtHub يُستدعى مباشرة بعد مسح باركود المقر بنجاح
              // ولكن يمكن إبقاؤه إذا أردت أن يكون مسح الباركود خطوة ثم التقاط الصورة خطوة ثم التأكيد.
              // للتبسيط، confirmDropOffAtHub الآن هو من يتحقق من الباركود وينفذ.
              // سنزيل هذا الزر إذا كان التدفق هو: (مسح باركود المقر) -> (التقاط صورة اختياري) -> (تنفيذ confirmDropOffAtHub).

            ],
          ],
        ),
      ),
    );
  }

// في DeliveryNavigationScreen.dart

  Widget _buildBuyerDeliveryConfirmationActions(BuildContext context) {
    final theme = Theme.of(context);

    // Obx يراقب متغيرات الحالة في المتحكم (isScanningBuyerConfirmation, pickedProofImageFile, isLoadingAction, isUploadingProofImage)
    return Obx(() {
      final task = controller.taskDetails.value; // المهمة الرئيسية
      if (task == null) return const SizedBox.shrink();

      return Card(
        margin: const EdgeInsets.all(12),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!controller.isScanningBuyerConfirmation.value) ...[


                if (controller.isConsolidatedDeliveryMode.value && controller.currentConsolidatedTasks.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0, bottom: 8.0),
                    child: Chip(
                      avatar: const Icon(Icons.inventory_2_outlined, size: 18, color: Colors.white70),
                      label: Text("تسليم ${controller.currentConsolidatedTasks.length} طلبات مجمعة للمشتري",
                          style: const TextStyle(fontSize: 12, color: Colors.white)),
                      backgroundColor: theme.primaryColor.withOpacity(0.85),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),





                Text(
                  "أنت الآن في موقع \"${task.buyerName ?? 'المشتري'}\".",
                  style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                // --- جديد: عرض معلومات إذا كان تسليم مجمع ---
                if (controller.isConsolidatedDeliveryMode.value && controller.currentConsolidatedTasks.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                    child: Chip(
                      avatar: const Icon(Icons.inventory_2_outlined, size: 18),
                      label: Text("تسليم ${controller.currentConsolidatedTasks.length} طلبات مجمعة لهذا العميل", style: TextStyle(fontSize: 12)),
                      backgroundColor: Colors.blue.shade50,
                    ),
                  ),
                // ------------------------------------------
                const SizedBox(height: 10), // تقليل المسافة قليلاً
                ElevatedButton.icon(
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text("بدء عملية تسليم الطلب وتأكيده"),
                  // ... (style و onPressed كما كان)
                  onPressed: controller.isLoadingAction.value
                      ? null
                      : () => controller.startOrStopBuyerConfirmationScanning(true),
                ),
              ]
            // --- العرض عندما تكون واجهة تأكيد التسليم للمشتري مفعلة ---
            else ...[


                if (controller.isConsolidatedDeliveryMode.value && controller.currentConsolidatedTasks.isNotEmpty)
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text("محتويات هذه الدفعة (${controller.currentConsolidatedTasks.length} طلبات):",
                        style: Get.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    initiallyExpanded: controller.currentConsolidatedTasks.length <= 3, // افتح إذا كانت قليلة
                    children: controller.currentConsolidatedTasks.map((consolidatedTask) {
                      return ListTile(
                        dense: true,
                        leading: Text("•", style: TextStyle(color: theme.primaryColor, fontSize: 16)),
                        title: Text("طلب ${consolidatedTask.orderIdShort}", style: const TextStyle(fontSize: 13)),
                        subtitle: Text(
                            consolidatedTask.isHubToHubTransfer // إذا كانت مهمة نقل (نادر أن تكون مجمعة هنا إلا إذا كان المشتري هو Hub آخر)
                                ? "شحنة نقل إلى: ${consolidatedTask.destinationHubName ?? 'مقر'}"
                                : "من: ${consolidatedTask.sellerShopName ?? consolidatedTask.sellerName ?? 'بائع غير محدد'}",
                            style: const TextStyle(fontSize: 11)
                        ),
                      );
                    }).toList(),
                  ),
                if (controller.isConsolidatedDeliveryMode.value && controller.currentConsolidatedTasks.isNotEmpty)
                  const SizedBox(height: 10),









              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("تأكيد التسليم للمشتري", style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  TextButton.icon(
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text("إلغاء", style: TextStyle(fontSize: 12)),
                      // تعطيل زر الإلغاء أثناء أي عملية تحميل لمنع الخروج غير المتوقع
                      onPressed: (controller.isLoadingAction.value || controller.isUploadingProofImage.value)
                          ? null
                          : () => controller.startOrStopBuyerConfirmationScanning(false),
                      style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700))
                ],
              ),
              const Divider(height: 15),
                if (controller.isConsolidatedDeliveryMode.value && controller.currentConsolidatedTasks.isNotEmpty)
                  ExpansionTile( // لجعلها قابلة للطي إذا كانت القائمة طويلة
                    tilePadding: EdgeInsets.zero,
                    title: Text("الطلبات التي سيتم تسليمها (${controller.currentConsolidatedTasks.length}):",
                        style: Get.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                    initiallyExpanded: controller.currentConsolidatedTasks.length <= 3, // افتحها إذا كانت قليلة
                    children: controller.currentConsolidatedTasks.map((consolidatedTask) {
                      return ListTile(
                        dense: true,
                        leading: Text("•", style: TextStyle(color: theme.primaryColor)),
                        title: Text("طلب ${consolidatedTask.orderIdShort}", style: const TextStyle(fontSize: 12)),
                        subtitle: Text("من: ${consolidatedTask.sellerShopName ?? consolidatedTask.sellerName ?? 'بائع غير محدد'}", style: const TextStyle(fontSize: 11)),
                      );
                    }).toList(),
                  ),
                if (controller.isConsolidatedDeliveryMode.value) const SizedBox(height: 10),
                // ------------------------------------------------

                Text( // التعليمات لمسح الباركود
                  controller.isConsolidatedDeliveryMode.value && controller.currentConsolidatedTasks.length > 1
                      ? "اطلب من العميل عرض باركود الاستلام   لهذه الدفعة "
                      : "اطلب من المشتري عرض باركود الاستلام الخاص به (عادةً ، ثم قم بمسحه.",
                  textAlign: TextAlign.center,
                  style: Get.textTheme.bodySmall?.copyWith(height: 1.4),
                ),
              const SizedBox(height: 12),
              Center(
                child: Obx(() { // Obx داخلي لزر مسح باركود المشتري (لعرض مؤشر تحميل خاص به إذا أردت)
                  // يمكن إضافة متغير تحميل خاص لمسح الباركود إذا كانت العملية تستغرق وقتًا (مثلاً: isScanningBarcode.value)
                  // حاليًا، سنعطله بنفس حالات الأزرار الأخرى
                  bool isScanButtonLoading = controller.isLoadingAction.value || controller.isUploadingProofImage.value;
                  return ElevatedButton.icon(
                    icon: isScanButtonLoading
                        ? const SizedBox(width:16, height:16, child:CircularProgressIndicator(strokeWidth:1.5, color: Colors.white))
                        : const Icon(Icons.qr_code_scanner_rounded),
                    label: const Text("مسح باركود تأكيد المشتري"),
                    style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColorDark, padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16)),
                    onPressed: isScanButtonLoading
                        ? null
                        : ()  async {
                      final bool isHubTransferTask = controller.taskDetails.value?.isHubToHubTransfer ?? false;
                      String purposeText = isHubTransferTask
                          ? "امسح باركود المقر الوجهة (${controller.taskDetails.value?.destinationHubName ?? controller.taskDetails.value?.buyerName ?? ''})"
                          : "امسح باركود تأكيد استلام المشتري";

                      String? scannedCode = await controller.scanBarcode(context, purposeText);

                      if (scannedCode != null && scannedCode.isNotEmpty) {
                        if (isHubTransferTask) {
                          // *** مباشرة استدعِ دالة إتمام النقل للمقر ***
                          await controller.finalizeCurrentStageDelivery(context, scannedConfirmationCode: scannedCode);
                        } else {
                          controller.processScannedBuyerBarcode(scannedCode, context);
                        }
                      }
                    },
                  );
                }),
              ),
              const SizedBox(height: 15),

              // --- قسم التقاط صورة الإثبات ---
              // Obx هنا مكررة، يمكن إزالتها إذا كانت Obx الخارجية تغطي كل التغييرات اللازمة
              // سنبقيها الآن لأنها تفصل منطق عرض هذا الجزء
              Obx(() {
                // متغير لتحسين القراءة وتجنب تكرار الشرط الطويل
                final bool canInteractWithImagePicker = !controller.isLoadingAction.value && !controller.isUploadingProofImage.value;

                if (controller.pickedProofImageFile.value == null) {
                  return OutlinedButton.icon(
                    icon: controller.isUploadingProofImage.value // مؤشر تحميل خاص بالصورة
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 1.5))
                        : const Icon(Icons.camera_alt_outlined, size: 20),
                    label: Text(controller.isUploadingProofImage.value ? "جاري تحميل الصورة..." : "التقط صورة إثبات التسليم (إلزامي)"),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                    onPressed: canInteractWithImagePicker
                        ? () => controller.pickDeliveryProofImage(ImageSource.camera, context) // تمرير السياق
                        : null,
                  );
                } else {
                  // عرض الصورة الملتقطة مع خيار إزالتها/إعادة التقاطها
                  return Column(
                    children: [
                      Text("صورة الإثبات:", style: Get.textTheme.labelMedium?.copyWith(color: Colors.grey.shade700)),
                      const SizedBox(height: 5),
                      Stack(
                        alignment: Alignment.topLeft,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(controller.pickedProofImageFile.value!, height: 130, width: Get.width * 0.7, fit: BoxFit.contain),
                          ),
                          // زر الحذف يظهر فقط إذا لم يكن هناك تحميل جارٍ
                          if (canInteractWithImagePicker)
                            Positioned(
                              top: -2, left: -2, // تعديل طفيف للموضع
                              child: InkWell(
                                onTap: () => controller.pickedProofImageFile.value = null,
                                child: const CircleAvatar(backgroundColor: Colors.black54, radius: 12, child: Icon(Icons.close, size: 14, color: Colors.white)),
                              ),
                            ),
                        ],
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.replay_circle_filled_outlined, size: 18),
                        label: const Text("إعادة التقاط الصورة", style: TextStyle(fontSize: 12)),
                        onPressed: canInteractWithImagePicker
                            ? () => controller.pickDeliveryProofImage(ImageSource.camera, context) // تمرير السياق
                            : null,
                      ),
                    ],
                  );
                }
              }),
              const Divider(height: 20),
              // --- زر التأكيد النهائي ---
              // Obx داخلي لزر التأكيد لضمان إعادة بنائه عند تغير أي من حالات التحميل أو الصورة
              Obx(() {
                final bool canConfirmFinalDelivery = !controller.isLoadingAction.value &&
                    controller.pickedProofImageFile.value != null &&
                    !controller.isUploadingProofImage.value;
                return ElevatedButton.icon(
                  icon: controller.isLoadingAction.value // التحميل الرئيسي للتأكيد
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.task_alt_rounded),
                  label: Text( (controller.taskDetails.value?.isHubToHubTransfer ?? false)
                      ? "تأكيد الوصول وتسليم للمقر"
                      : "تأكيد التسليم للمشتري"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: canConfirmFinalDelivery ? Colors.green.shade700 : Colors.grey.shade400, // تغيير اللون إذا كان معطلاً
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  onPressed:  (controller.isLoadingAction.value || controller.isUploadingProofImage.value)
                      ? null
                      : () async {
                    //  استدعاء الدالة المدمجة مباشرة، هي ستطلب مسح الباركود
                    await controller.finalizeCurrentStageDelivery(context);
                  },
                );
              }),
            ],
          ],
        ),
      ),
    );
    } );
  }







  Widget _buildPreDeliveryActions(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "أنت في طريقك لتسليم الطلب إلى \"${controller.taskDetails.value?.buyerName ?? 'المشتري'}\".",
              style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator( // مؤشر تقدم بصري (اختياري)
              valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
              backgroundColor: theme.primaryColor.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: controller.isLoadingAction.value
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.location_on_outlined),
              label: Text(controller.isLoadingAction.value ? "جاري التحديث..." : "لقد وصلت إلى موقع المشتري"),
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.orange.shade700, // لون مميز لمرحلة الوصول
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)
              ),
              onPressed: controller.isLoadingAction.value ? null : controller.confirmArrivalAtBuyerLocation,
            ),
          ],
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        // ... (منطق التحميل والخطأ للمهمة كما كان)
        if (controller.taskDetails.value == null && controller.isLoadingTaskData.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.taskDetails.value == null) { // بعد انتهاء التحميل ولم توجد مهمة
          return Center(child: Padding(padding:EdgeInsets.all(20), child:Column(mainAxisSize: MainAxisSize.min,
              children:[ Text("فشل تحميل تفاصيل المهمة أو المهمة غير موجودة."), Text(controller.taskErrorMessage.value,
                  style:TextStyle(color:Colors.red.shade300), textAlign: TextAlign.center), SizedBox(height:10),
                ElevatedButton(onPressed: controller.refreshTaskDetails, child:Text("إعادة المحاولة"))])));
        }


        return Column(
          children: [
            _buildHeaderSection(context), // الجزء العلوي (خريطة، معلومات وجهة، مسافة/ETA)
            Expanded(
              child: Scrollbar( // <--- إضافة Scrollbar هنا
                thumbVisibility: true, // إظهار شريط التمرير دائمًا
                thickness: 6.0,
                radius: const Radius.circular(3.0),
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 20),
                  children: [
                    // --- قسم الإجراءات الديناميكي ---
                    _buildTaskActionSection(context),



                    Obx(() {
                      final task = controller.taskDetails.value;
                      if (task != null && task.deliveryInstructions != null && task.deliveryInstructions!.isNotEmpty &&
                          controller.isTaskStillActiveForDriverNavigation(controller.currentTaskStatus)) { // <--- استخدام getter
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                          child: Card(
                            elevation: 1,
                            color: Colors.blue.shade50, // لون مميز للتعليمات
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Colors.blue.shade200, width:0.8)
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.speaker_notes_outlined, color: Colors.blue.shade700, size:20),
                                      const SizedBox(width: 8),
                                      Text("تعليمات خاصة من المشتري:", style: Get.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(task.deliveryInstructions!, style: Get.textTheme.bodyMedium?.copyWith(height: 1.4)),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),





                    // --- قسم الأزرار المساعدة (الجديد) ---
                    Obx(() {
                      if (controller.taskDetails.value == null ||
                          !controller.isTaskStillActiveForDriverNavigation(controller.currentTaskStatus)) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                        child: Card( // <--- وضعها داخل Card لمظهر أفضل
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column( // استخدام Column لأن لدينا عدة أزرار مساعدة
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text("أدوات مساعدة:", style: Get.textTheme.titleSmall?.copyWith(fontWeight:FontWeight.w500)),
                                const SizedBox(height:8),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.list_alt_rounded, size: 18),
                                  label: const Text("عرض تفاصيل المنتجات"),
                                  onPressed: () => controller.showFullOrderItemsDialog(context),
                                  style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 9),
                                      side: BorderSide(color: Colors.grey.shade400),
                                      textStyle: const TextStyle(fontSize: 13)
                                  ),
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  icon: Icon(Icons.timer_off_outlined, color: Colors.orange.shade800, size: 18),
                                  label: Text("تسجيل تأخير غير متوقع", style: TextStyle(color: Colors.orange.shade800, fontSize: 13)),
                                  onPressed: controller.isLoadingAction.value ? null : () => controller.reportUnexpectedDelay(context),
                                  style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 9),
                                      side: BorderSide(color: Colors.orange.shade800.withOpacity(0.5))
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                    // --- زر الإبلاغ عن مشكلة العام ---
                    Obx(() {
                      if (controller.taskDetails.value != null &&
                          controller.isTaskStillActiveForDriverNavigation(controller.currentTaskStatus)) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 8.0),
                          child: ElevatedButton.icon( // <--- تم تغييره لـ ElevatedButton لمظهر مختلف
                            icon: const Icon(Icons.report_problem_outlined),
                            label: const Text("الإبلاغ عن مشكلة أو إلغاء التسليم"),
                            onPressed: controller.isLoadingAction.value
                                ? null
                                : () => controller.reportDeliveryIssue(context), // هذا يعرض BottomSheet
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade50,
                                foregroundColor: Colors.red.shade700,
                                side: BorderSide(color: Colors.red.shade200),
                                elevation:1,
                                padding: const EdgeInsets.symmetric(vertical:11)
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}