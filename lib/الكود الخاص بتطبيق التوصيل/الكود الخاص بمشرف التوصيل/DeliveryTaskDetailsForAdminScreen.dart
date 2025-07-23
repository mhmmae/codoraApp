import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart'; // لتنسيق التواريخ والأرقام
import 'package:cached_network_image/cached_network_image.dart';

import '../../XXX/xxx_firebase.dart';
import 'CompanyDriversListScreen.dart';
import 'DeliveryTaskDetailsAdminController.dart';
import '../../Model/DeliveryTaskModel.dart'; // لعرض الصور من رابط

Map<String, dynamic> getTaskStatusVisuals(DeliveryTaskStatus status, BuildContext context) {
  ThemeData theme = Theme.of(context);
  String textToShow;
  Color chipColor;
  Color textColor;
  IconData iconData;

  switch (status) {
  // المرحلة 1: المهمة تنتظر شركة توصيل
    case DeliveryTaskStatus.pending_platform_assignment:
      textToShow = "بانتظار تعيين للمنصة"; chipColor = Colors.blueGrey.shade100; textColor = Colors.blueGrey.shade800; iconData = Icons.lan_outlined;
      break;
    case DeliveryTaskStatus.company_pickup_request:
      textToShow = "متاحة للمطالبة (شركات)"; chipColor = Colors.cyan.shade50; textColor = Colors.cyan.shade700; iconData = Icons.groups_3_outlined;
      break;

  // المرحلة 2: المهمة مع شركة معينة، تنتظر سائقًا
    case DeliveryTaskStatus.pending_driver_assignment:
      textToShow = "بانتظار تعيين سائق"; chipColor = Colors.deepPurple.shade50; textColor = Colors.deepPurple.shade700; iconData = Icons.person_search_sharp;
      break;
    case DeliveryTaskStatus.ready_for_driver_offers_narrow:
      textToShow = "معروضة لسائقين (قريبين)"; chipColor = Colors.lime.shade100; textColor = Colors.lime.shade900; iconData = Icons.near_me_outlined;
      break;
    case DeliveryTaskStatus.ready_for_driver_offers_wide:
      textToShow = "معروضة لسائقين (الكل)"; chipColor = Colors.yellow.shade100; textColor = Colors.yellow.shade900; iconData = Icons.campaign_rounded;
      break;

  // المرحلة 3: تم تعيين سائق وبدأت عملية التوصيل
    case DeliveryTaskStatus.driver_assigned:
      textToShow = "تم تعيين سائق"; chipColor = Colors.lightBlue.shade50; textColor = Colors.lightBlue.shade800; iconData = Icons.assignment_ind_rounded;
      break;
    case DeliveryTaskStatus.en_route_to_pickup:
      textToShow = "السائق نحو البائع"; chipColor = Colors.teal.shade50; textColor = Colors.teal.shade700; iconData = Icons.directions_bike_rounded;
      break;
    case DeliveryTaskStatus.picked_up_from_seller:
      textToShow = "استلمت من البائع"; chipColor = Colors.indigo.shade100; textColor = Colors.indigo.shade700; iconData = Icons.shopping_bag_rounded;
      break;
    case DeliveryTaskStatus.out_for_delivery_to_buyer:
      textToShow = "في الطريق للمشتري"; chipColor = Colors.orange.shade100; textColor = Colors.orange.shade800; iconData = Icons.local_shipping_rounded;
      break;
    case DeliveryTaskStatus.at_buyer_location:
      textToShow = "السائق عند المشتري"; chipColor = Colors.deepOrange.shade100; textColor = Colors.deepOrange.shade800; iconData = Icons.location_on_sharp;
      break;

  // المرحلة 4: اكتمال المهمة أو فشلها
    case DeliveryTaskStatus.delivered:
      textToShow = "تم التسليم"; chipColor = Colors.green.shade100; textColor = Colors.green.shade800; iconData = Icons.check_circle_rounded;
      break;
    case DeliveryTaskStatus.delivery_failed:
      textToShow = "فشل التسليم"; chipColor = Colors.red.shade100; textColor = Colors.red.shade700; iconData = Icons.error_rounded;
      break;
    case DeliveryTaskStatus.returned_to_seller:
      textToShow = "أُرجعت للبائع"; chipColor = Colors.brown.shade100; textColor = Colors.brown.shade800; iconData = Icons.assignment_return_rounded;
      break;

  // المرحلة 5: الإلغاءات
    case DeliveryTaskStatus.cancelled_by_seller:
      textToShow = "ملغاة (البائع)"; chipColor = Colors.pink.shade50; textColor = Colors.pink.shade700; iconData = Icons.store_mall_directory_outlined; // أيقونة البائع مع علامة إلغاء ضمنية
      break;
    case DeliveryTaskStatus.cancelled_by_buyer:
      textToShow = "ملغاة (المشتري)"; chipColor = Colors.pink.shade50; textColor = Colors.pink.shade700; iconData = Icons.person_off_outlined;
      break;
    case DeliveryTaskStatus.cancelled_by_company_admin:
      textToShow = "ملغاة (شركة التوصيل)"; chipColor = Colors.pink.shade50; textColor = Colors.pink.shade700; iconData = Icons.no_transfer_rounded;
      break;
    case DeliveryTaskStatus.cancelled_by_platform_admin:
      textToShow = "ملغاة (المنصة)"; chipColor = Colors.pink.shade50; textColor = Colors.pink.shade700; iconData = Icons.gpp_bad_outlined;
      break;

    default: // حالة غير متوقعة (يجب ألا تحدث إذا غطيت كل الـ enum)
      textToShow = deliveryTaskStatusToString(status).replaceAll('_', ' '); // اسم الحالة الافتراضي
      chipColor = Colors.grey.shade300;
      textColor = Colors.grey.shade800;
      iconData = Icons.help_center_rounded;
  }

  return {"text": textToShow, "color": chipColor, "textColor": textColor, "icon": iconData};
}

Widget _buildSectionTitle(String title, BuildContext context) {
  return Padding(
    padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
    child: Text(title, style: Get.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).primaryColorDark)),
  );
}


Widget _buildDetailItem(IconData icon, String label, String? value, BuildContext context, {Color? iconColor}) {
  final theme = Theme.of(context);
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: iconColor ?? theme.colorScheme.primary.withOpacity(0.8)),
        const SizedBox(width: 12),
        Text("$label: ", style: Get.textTheme.titleSmall?.copyWith(color: Colors.blueGrey.shade800, fontWeight: FontWeight.w500)),
        Expanded(child: Text(value ?? 'غير متوفر', style: Get.textTheme.bodyLarge?.copyWith(color: Colors.black87))),
      ],
    ),
  );
}

Widget _buildStatusChip(DeliveryTaskStatus currentStatus, BuildContext context) { // <--- تغيير هنا: استقبل DeliveryTaskStatus
  Map<String, dynamic> statusInfo;
  // لا حاجة لـ toLowerCase() الآن

  switch (currentStatus) { // <--- تغيير هنا: استخدم enum مباشرة
    case DeliveryTaskStatus.company_pickup_request:
      statusInfo = {"text": "جاهز للاستلام", "color": Colors.blue.shade100, "textColor": Colors.blue.shade800, "icon": Icons.inventory_2_outlined};
      break;
    case DeliveryTaskStatus.out_for_delivery_to_buyer:
    case DeliveryTaskStatus.driver_assigned: // يمكنك تجميع الحالات المتشابهة في العرض
    case DeliveryTaskStatus.en_route_to_pickup:
    case DeliveryTaskStatus.picked_up_from_seller:
    case DeliveryTaskStatus.at_buyer_location: // ربما هذا يندرج تحت "في الطريق"
      statusInfo = {"text": "في الطريق للتسليم", "color": Colors.orange.shade100, "textColor": Colors.orange.shade800, "icon": Icons.local_shipping_outlined};
      break;
    case DeliveryTaskStatus.delivered:
      statusInfo = {"text": "تم التسليم", "color": Colors.green.shade100, "textColor": Colors.green.shade800, "icon": Icons.check_circle_outline};
      break;
    case DeliveryTaskStatus.pending_platform_assignment:
      statusInfo = {"text": "بانتظار تعيين مهمة", "color": Colors.grey.shade300, "textColor": Colors.grey.shade800, "icon": Icons.hourglass_empty_rounded};
      break;
    case DeliveryTaskStatus.cancelled_by_seller:
    case DeliveryTaskStatus.cancelled_by_buyer:
    case DeliveryTaskStatus.cancelled_by_platform_admin:
      statusInfo = {"text": "ملغاة", "color": Colors.red.shade100, "textColor": Colors.red.shade700, "icon": Icons.cancel_outlined};
      break;
    case DeliveryTaskStatus.delivery_failed:
      statusInfo = {"text": "فشل التسليم", "color": Colors.red.shade200, "textColor": Colors.red.shade800, "icon": Icons.error_outline_rounded};
      break;
    case DeliveryTaskStatus.returned_to_seller:
      statusInfo = {"text": "تم الإرجاع للبائع", "color": Colors.brown.shade100, "textColor": Colors.brown.shade800, "icon": Icons.assignment_return_outlined};
      break;
    default: // حالة افتراضية إذا كان هناك enum value لم يتم تغطيته
      statusInfo = {"text": currentStatus.toString().split('.').last.replaceAll('_', ' '), "color": Colors.grey.shade200, "textColor": Colors.black54, "icon": Icons.help_outline};
  }

  return Chip(
    avatar: Icon(statusInfo['icon'], color: statusInfo['textColor'], size: 18),
    label: Text(statusInfo['text'], style: TextStyle(color: statusInfo['textColor'], fontWeight: FontWeight.w500)),
    backgroundColor: statusInfo['color'],
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    shape: StadiumBorder(side: BorderSide(color: (statusInfo['textColor'] as Color).withOpacity(0.3))), // إضافة شكل بيضاوي مع إطار خفيف
  );
}

// (getDriverAvailabilityVisuals من الرد السابق)
// --- نهاية دوال المساعدة ---
Widget _buildDriverAvailabilityChip(String availabilityStatus, BuildContext context) {
  final availabilityInfo = getDriverAvailabilityVisuals(availabilityStatus, context);
  final Color statusColor = availabilityInfo['color'] as Color? ?? Colors.grey;
  final IconData statusIcon = availabilityInfo['icon'] as IconData? ?? Icons.help_outline_rounded;
  final String statusText = availabilityInfo['text'] as String? ?? availabilityStatus;

  return Chip(
    avatar: Icon(
      statusIcon,
      color: statusColor, // اجعل لون الأيقونة يطابق لون النص/الحدود
      size: 16,
    ),
    label: Text(
      statusText,
      style: TextStyle(
        color: statusColor, // لون النص يطابق لون الحالة
        fontSize: 11.5,       // حجم خط أصغر قليلاً للـ Chip
        fontWeight: FontWeight.w500,
      ),
    ),
    backgroundColor: statusColor.withOpacity(0.15), // خلفية بلون الحالة ولكن بشفافية
    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0), // padding داخلي للـ Chip
    shape: StadiumBorder( // شكل بيضاوي
      side: BorderSide(color: statusColor.withOpacity(0.5), width: 0.5), // إطار خفيف بلون الحالة
    ),
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // لتقليل المساحة الزائدة القابلة للنقر
    visualDensity: VisualDensity.compact, // لجعل الـ Chip أصغر حجمًا
  );
}

class DeliveryTaskDetailsForAdminScreen extends GetView<DeliveryTaskDetailsAdminController> {
  const DeliveryTaskDetailsForAdminScreen({super.key, required String taskId}) : _taskId = taskId;
  // _taskId يستخدم فقط لتمريره للمتحكم إذا كان الـ Binding يتوقعه في page factory
  // أو يمكنك إزالته إذا كان Binding يستطيع الحصول عليه من Get.parameters دائماً.
  final String _taskId;

  Widget _buildSectionTitle(String title, BuildContext context, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Get.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String? value, BuildContext context, {Color? iconColor, VoidCallback? onValueTap, bool isEmphasized = false}) {
    final theme = Theme.of(context);
    if (value == null || value.isEmpty) return const SizedBox.shrink(); // لا تعرض شيئًا إذا كانت القيمة فارغة
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor ?? theme.colorScheme.secondary.withOpacity(0.8)),
          const SizedBox(width: 10),
          Text("$label: ", style: Get.textTheme.bodyLarge?.copyWith(color: Colors.blueGrey.shade700, fontWeight: FontWeight.w500)),
          Expanded(
            child: InkWell(
              onTap: onValueTap,
              child: Text(
                value,
                style: Get.textTheme.bodyLarge?.copyWith(
                  color: onValueTap != null ? theme.colorScheme.primary : (isEmphasized ? theme.colorScheme.error : Colors.black87),
                  fontWeight: isEmphasized ? FontWeight.w600 : FontWeight.normal,
                  decoration: onValueTap != null ? TextDecoration.underline : TextDecoration.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSummaryCard(List<Map<String,dynamic>>? items, BuildContext context){
    if(items == null || items.isEmpty) return _buildDetailItem(Icons.list_alt_outlined, "المنتجات", "لا يوجد ملخص منتجات لهذه المهمة", context);

    return Card(
      elevation: 0.5,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile( // لجعلها قابلة للطي
        leading: Icon(Icons.fastfood_outlined, color: Theme.of(context).primaryColor), // أو أي أيقونة مناسبة
        title: Text("ملخص المنتجات المطلوبة (${items.length})", style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        tilePadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        childrenPadding: EdgeInsets.only(left: 16, right: 16, bottom: 12),
        initiallyExpanded: items.length <=3, // افتحها تلقائيًا إذا كان عدد المنتجات قليل
        children: items.map((item) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text("• ${item['itemName'] ?? 'منتج غير معروف'}", style: Get.textTheme.bodyMedium)),
              Text("الكمية: ${item['quantity'] ?? 1}", style: Get.textTheme.bodyMedium?.copyWith(color: Colors.blueGrey)),
              // يمكنك إضافة السعر هنا إذا كان متاحًا في itemsSummary
              // if(item['price'] != null) SizedBox(width: 10),
              // if(item['price'] != null) Text("${NumberFormat.currency(locale: 'ar_SA', symbol: FirebaseX.currency).format(item['price'])}"),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildEntityCard(String title, IconData entityIcon, String? name, String? phone, String? address, VoidCallback? onContact, BuildContext context) {
    if ((name == null || name.isEmpty) && (phone == null || phone.isEmpty) && (address == null || address.isEmpty)) return SizedBox.shrink();
    final theme = Theme.of(context);
    return Card(
        elevation: 1,
        margin: const EdgeInsets.symmetric(vertical:6),
        child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.primaryColor)),
                  const Divider(height: 12),
                  if(name != null && name.isNotEmpty) _buildDetailItem(entityIcon, "الاسم", name, context),
                  if(phone != null && phone.isNotEmpty) _buildDetailItem(Icons.phone_in_talk_rounded, "الهاتف", phone, context, onValueTap: onContact, iconColor: Colors.green.shade600),
                  if(address != null && address.isNotEmpty) _buildDetailItem(Icons.location_history_rounded, "العنوان", address, context, iconColor: Colors.orange.shade700),
                ]
            )
        )
    );
  }


  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormatter = NumberFormat.currency(locale: 'ar_SA', symbol: FirebaseX.currency, decimalDigits: 0);
    final DateFormat dateTimeFormatter = DateFormat('EEEE، dd MMMM yyyy - hh:mm a', 'ar');
    final DateFormat timeFormatter = DateFormat('hh:mm a', 'ar');
    final theme = Theme.of(context);


    return Scaffold(
      appBar: AppBar(
        title: Obx(()=> Text(controller.task.value != null ? "تفاصيل مهمة #${controller.task.value!.orderId.length > 6 ? '${controller.task.value!.orderId.substring(0,6)}...' : controller.task.value!.orderId }" : "جاري تحميل التفاصيل...")),
        actions: [ Obx(()=> controller.isLoading.value ? SizedBox.shrink() : IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: controller.fetchTaskDetails, tooltip: "تحديث")) ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.task.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.errorMessage.value.isNotEmpty && controller.task.value == null) {
          return Center(child: Padding(padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, children: [Text("خطأ: ${controller.errorMessage.value}",
            style: const TextStyle(color: Colors.red), textAlign: TextAlign.center,), const SizedBox(height:10),
            ElevatedButton(onPressed: controller.fetchTaskDetails, child: const Text("إعادة المحاولة"))])));
        }


        if (controller.task.value == null) {
        return const Center(child: Text("لا توجد بيانات لهذه المهمة. قد تكون حُذفت أو المعرف غير صالح."));
        }

        final task = controller.task.value!;
        final driver = controller.driver.value;
        final seller = controller.seller.value;
        final buyer = controller.buyer.value;

        final statusVisuals = getTaskStatusVisuals(task.status, context); // استخدام دالة الحالة المرئية

        return Column(
        children: [
        // --- الخريطة ---
        SizedBox(
        height: Get.height * 0.30, // تقليل ارتفاع الخريطة قليلاً
        child: Obx(() => GoogleMap(
        onMapCreated: controller.onMapCreated,
        initialCameraPosition: CameraPosition(
        target: task.pickupLatLng!,
        zoom: 11.0, // بدء بزوم أبعد قليلاً لترى السياق
        ),
        markers: controller.markers.value,
        polylines: controller.polylines.value,
        myLocationButtonEnabled: false, // يمكن تفعيله إذا أردت معرفة موقع المشرف بالنسبة للمهمة
        zoomControlsEnabled: true,
        compassEnabled: true,
        mapToolbarEnabled: true,
        trafficEnabled: false, // يمكنك تفعيلها
        )),
        ),

        // --- شريط الحالة الرئيسي ---
        Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: (statusVisuals['color'] as Color).withOpacity(0.9),
        child: Row(
        children: [
        Icon(statusVisuals['icon'], color: statusVisuals['textColor'], size: 24),
        const SizedBox(width: 10),
        Expanded(child: Text(statusVisuals['text'], style: Get.textTheme.titleMedium?.copyWith(color:statusVisuals['textColor'], fontWeight: FontWeight.bold))),
        ]
        ),
        ),

        Expanded(
        child: ListView( // استخدام ListView هنا أفضل من SingleChildScrollView + Column
        padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 80.0), // ترك مساحة للـ FAB إذا أضفته
        children: [
        _buildSectionTitle("تفاصيل الطلب", context),
        _buildDetailItem(Icons.receipt_long_outlined, "رقم الطلب الأساسي", task.orderId, context),
        if (task.paymentMethod != null) _buildDetailItem(Icons.credit_card_rounded, "طريقة الدفع", task.paymentMethod, context),
        if (task.amountToCollect != null && task.amountToCollect! > 0) _buildDetailItem(Icons.account_balance_wallet_outlined, "المبلغ للتحصيل", currencyFormatter.format(task.amountToCollect), context, isEmphasized: true),
        if (task.deliveryFee != null) _buildDetailItem(Icons.local_atm_rounded, "رسوم التوصيل", currencyFormatter.format(task.deliveryFee), context),
        _buildDetailItem(Icons.more_time_rounded, "وقت إنشاء المهمة", dateTimeFormatter.format(task.createdAt.toDate()), context),
        if (task.estimatedDeliveryTime != null) _buildDetailItem(Icons.hourglass_bottom_rounded, "التسليم المقدر", dateTimeFormatter.format(task.estimatedDeliveryTime!.toDate()), context),
        if (task.actualPickupTime != null) _buildDetailItem(Icons.event_available_rounded, "وقت التسليم الفعلي", dateTimeFormatter.format(task.actualPickupTime!.toDate()), context, iconColor: Colors.green.shade700),
        if (task.updatedAt != null) _buildDetailItem(Icons.history_toggle_off_rounded, "آخر تحديث للمهمة", dateTimeFormatter.format(task.updatedAt!.toDate()), context),

        _buildItemsSummaryCard(task.itemsSummary, context),

        _buildEntityCard("معلومات الاستلام (البائع)", Icons.storefront_rounded, seller?.shopName ?? task.sellerName, seller?.shopPhoneNumber ?? task.sellerPhoneNumber, task.pickupAddressText, controller.contactSeller, context),
        _buildEntityCard("معلومات التسليم (المشتري)", Icons.person_pin_circle_rounded, buyer?.name ?? task.buyerName, buyer?.phoneNumber ?? task.buyerPhoneNumber, task.deliveryAddressText, controller.contactBuyer, context),
        if (task.deliveryInstructions != null && task.deliveryInstructions!.isNotEmpty) _buildDetailItem(Icons.speaker_notes_off_outlined, "تعليمات المشتري", task.deliveryInstructions, context),
          if (task.deliveryConfirmationTime != null) // <--- استخدام الاسم الصحيح
            _buildDetailItem(
                Icons.event_available_rounded,
                "وقت التسليم الفعلي",
                dateTimeFormatter.format(task.deliveryConfirmationTime!.toDate()), // <--- استخدام الاسم الصحيح
                context,
                iconColor: Colors.green.shade700,
                isEmphasized: true // لتمييزه
            ),

        if (driver != null) ...[
        _buildSectionTitle("السائق المعين", context, trailing: _buildDriverAvailabilityChip(driver.availabilityStatus, context)),
        Card(
        elevation:1,
        child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
        children: [
        Row(children: [
        CircleAvatar(radius:22, backgroundImage: driver.profileImageUrl != null ? CachedNetworkImageProvider(driver.profileImageUrl!) : null, child: driver.profileImageUrl==null?Icon(Icons.person_rounded):null),
        SizedBox(width:10),
        Expanded(child: Text(driver.name, style: Get.textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w500))),
        // أيقونة للتواصل مع السائق
        IconButton(icon: Icon(Icons.call_outlined, color: theme.primaryColor), onPressed: controller.contactDriver, tooltip: "اتصال بالسائق"),
        ]),
        SizedBox(height:8),
        _buildDetailItem(Icons.directions_car_filled_outlined, "المركبة", driver.vehicleType, context),
        ]
        )
        )
        )
        ] else if (
        task.status == DeliveryTaskStatus.pending_platform_assignment ||
            task.status == DeliveryTaskStatus.company_pickup_request ||
            task.status == DeliveryTaskStatus.pending_driver_assignment ||
            task.status == DeliveryTaskStatus.ready_for_driver_offers_narrow ||
            task.status == DeliveryTaskStatus.ready_for_driver_offers_wide
        ) ...[
        _buildSectionTitle("السائق", context),
        Text("لم يتم تعيين سائق لهذه المهمة بعد.", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.blueGrey)),
        ],


        // --- أزرار الإجراءات ---
        // اعرض الأزرار فقط إذا كانت المهمة لا تزال قابلة للتعديل
        if (!_isTaskFinalState(task.status)) ...[
        const SizedBox(height: 24),
        _buildSectionTitle("الإجراءات المتاحة", context),
        const SizedBox(height: 8),
        Wrap( // استخدام Wrap أفضل من Column هنا للأزرار
        spacing: 12,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: [
        if (task.status == DeliveryTaskStatus.ready_for_driver_offers_wide ||task.status == DeliveryTaskStatus.ready_for_driver_offers_narrow || task.assignedToDriverId == null || task.status == DeliveryTaskStatus.driver_assigned) // أمثلة للحالات التي يمكن إعادة التعيين فيها
        ElevatedButton.icon(
        icon: const Icon(Icons.swap_calls_rounded),
        label: const Text("تعيين/إعادة تعيين السائق"),
        onPressed: controller.isLoading.value ? null : controller.reassignTaskToNewDriver, // استخدم isLoading العام لمنع التضارب
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey.shade700, foregroundColor: Colors.white),
        ),
        ElevatedButton.icon(
        icon: const Icon(Icons.cancel_schedule_send_rounded),
        label: const Text("إلغاء المهمة (كمشرف)"),
        onPressed: controller.isLoading.value ? null : () => controller.cancelTaskByAdmin(context),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white),
        ),
        // يمكنك إضافة المزيد من الأزرار حسب الحاجة
        ],
        )
        ]
        ],
        ),
        ),
        ],
        );
      }),
    );
  }

  // دالة مساعدة لتحديد ما إذا كانت حالة المهمة نهائية (لا يمكن اتخاذ إجراءات عليها)
  bool _isTaskFinalState(DeliveryTaskStatus status){
    return status == DeliveryTaskStatus.delivered ||
        status == DeliveryTaskStatus.cancelled_by_platform_admin ||
        status == DeliveryTaskStatus.cancelled_by_buyer ||
        status == DeliveryTaskStatus.cancelled_by_seller ||
        status == DeliveryTaskStatus.delivery_failed || // قد ترغب في إجراء ما هنا (مثل إعادة الجدولة)
        status == DeliveryTaskStatus.returned_to_seller;
  }
}

// ----- قم بإنشاء الـ Binding في ملف منفصل (delivery_task_details_admin_binding.dart) -----
// class DeliveryTaskDetailsAdminBinding extends Bindings {
//   @override
//   void dependencies() {
//     final String taskId = Get.parameters['taskId'] ?? '';
//     if (taskId.isEmpty) {
//       debugPrint("DeliveryTaskDetailsAdminBinding: CRITICAL - TaskId is empty from route parameters!");
//       // يمكنك هنا توجيه المستخدم للوراء أو عرض رسالة خطأ عامة بدلاً من السماح للمتحكم بالتهيئة بدون ID
//       // Get.offAllNamed(AppRoutes.COMPANY_ADMIN_DASHBOARD); // مثال
//       // return; // منع إنشاء المتحكم
//     }
//     Get.lazyPut<DeliveryTaskDetailsAdminController>(
//       () => DeliveryTaskDetailsAdminController(taskId: taskId),
//     );
//   }
// }