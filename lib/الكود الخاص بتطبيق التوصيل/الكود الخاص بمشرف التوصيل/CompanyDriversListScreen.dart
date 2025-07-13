import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../XXX/xxx_firebase.dart';
import '../../routes/app_routes.dart';
import '../الكود الخاص بعامل/DeliveryDriverModel.dart';
import 'CompanyAdminDashboardController.dart';
// import 'company_drivers_list_controller.dart';
// import '../models/DeliveryDriverModel.dart'; // تأكد أن لديك هذا النموذج مع حقل applicationStatus و availabilityStatus

// دالة مساعدة لترجمة حالة التوفر إلى نص ولون وأيقونة (يمكن وضعها في ملف أدوات مساعد)
Map<String, dynamic> getDriverAvailabilityVisuals(String statusKey, BuildContext context) {
  final theme = Theme.of(context);
  String textToShow = statusKey;
  switch (statusKey.toLowerCase()) {
    case "online_available":
      return {"text": "متوفر", "color": Colors.green.shade700, "icon": Icons.wifi_rounded};
    case "on_task":
      return {"text": "في مهمة", "color": Colors.orange.shade700, "icon": Icons.delivery_dining_rounded};
    case "offline":
      return {"text": "غير متوفر", "color": Colors.red.shade700, "icon": Icons.wifi_off_rounded};
    default:
      if(statusKey.contains("_")){ // لتحسين عرض الحالات مثل removed_by_company
        textToShow = statusKey.replaceAll('_', ' ');
      }
      return {"text": textToShow, "color": Colors.grey.shade600, "icon": Icons.help_outline_rounded};
  }
}
Widget _buildDriverStatusChipForList(DriverApplicationStatus status, BuildContext context) {
  String text; Color bgColor; Color fgColor; IconData? chipIcon;
  switch (status) {
    case DriverApplicationStatus.approved: text = "معتمد"; bgColor = Colors.teal.withOpacity(0.1); fgColor = Colors.teal.shade700; chipIcon = Icons.check_circle_outline ;break;
    case DriverApplicationStatus.suspended: text = "مُعلق"; bgColor = Colors.orange.withOpacity(0.1); fgColor = Colors.orange.shade800; chipIcon = Icons.pause_circle_outline; break;
  // الحالات الأخرى لا يجب أن تظهر في هذه القائمة، لكن كاحتياط
    case DriverApplicationStatus.pending: text = "معلق المراجعة"; bgColor = Colors.blue.withOpacity(0.1); fgColor = Colors.blue.shade700; chipIcon = Icons.hourglass_empty; break;
    default: text = driverApplicationStatusToString(status).replaceAll('_', ' '); bgColor = Colors.grey.shade200; fgColor = Colors.grey.shade700;
  }
  return Chip(
    avatar: chipIcon != null ? Icon(chipIcon, color: fgColor, size:16) : null,
    label: Text(text, style: TextStyle(color: fgColor, fontSize: 11, fontWeight: FontWeight.w500)),
    backgroundColor: bgColor,
    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // لتقليل حجم الـ padding الزائد
    visualDensity: VisualDensity.compact,
  );
}

class CompanyDriversListScreen extends GetView<CompanyDriversListController> {
  const CompanyDriversListScreen({super.key});

  Widget _buildDriverCard(DeliveryDriverModel driver, BuildContext context) {
    final availabilityInfo = getDriverAvailabilityVisuals(driver.availabilityStatus, context);
    final theme = Theme.of(context);

    return Card(
      elevation: 2.0, // تقليل الـ elevation قليلاً
      margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0), // تعديل الهوامش
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10.0),
        onTap: () {
          debugPrint("Navigating to profile for driver: ${driver.uid}");
          Get.toNamed(AppRoutes.ADMIN_DRIVER_PROFILE.replaceFirst(':driverId', driver.uid))
              ?.then((result) { // <--- معالجة النتيجة عند العودة
            // result يمكن أن يكون bool أو Map كما ناقشنا
            // إذا عادت شاشة الملف الشخصي بنتيجة تشير إلى أنه تم تحديث السائق:
            if (result == true || (result is Map && result['profileUpdated'] == true)) {
              debugPrint("Returned from driver profile, refresh requested for driver: ${driver.uid}");
              controller.refreshDriverInList(driver.uid); // <--- استدعاء دالة التحديث
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28, // تقليل حجم الصورة قليلاً
                backgroundColor: Colors.grey.shade200,
                backgroundImage: driver.profileImageUrl != null && driver.profileImageUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(driver.profileImageUrl!) : null,
                child: (driver.profileImageUrl == null || driver.profileImageUrl!.isEmpty)
                    ? const Icon(Icons.person_rounded, size: 28, color: Colors.grey) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(driver.name, style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(availabilityInfo['icon'], color: availabilityInfo['color'], size: 15),
                        const SizedBox(width: 5),
                        Text(availabilityInfo['text'], style: TextStyle(color: availabilityInfo['color'], fontSize: 12, fontWeight: FontWeight.w500)),
                        const SizedBox(width: 8),
                        Text("(${driver.vehicleType})", style: Get.textTheme.bodySmall?.copyWith(fontSize:11)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    _buildDriverStatusChipForList(driver.applicationStatus, context), // حالة الحساب (معتمد/معلق)
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade500),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("سائقو الشركة المعتمدون"),
        actions: [
          Obx(() => controller.isLoading.value
              ? Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical:18), child: SizedBox(width:20, height:20, child:CircularProgressIndicator(strokeWidth: 2, color:Colors.white)))
              : IconButton(icon: Icon(Icons.refresh), onPressed: () => controller.fetchCompanyDrivers(), tooltip: "تحديث")
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 10.0, 12.0, 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.searchController,
                    decoration: InputDecoration(
                      hintText: "ابحث بالاسم، نوع المركبة...",
                      prefixIcon: const Icon(Icons.search, size: 22, color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: Colors.grey.shade300)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: Theme.of(context).primaryColor, width:1.5)),
                      filled: true,
                      fillColor: Theme.of(context).canvasColor, // أو Colors.white
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                      suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                          ? IconButton(icon: const Icon(Icons.clear, size:20, color: Colors.grey), onPressed: controller.clearSearch)
                          : const SizedBox.shrink()),
                    ),
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(color: Colors.grey.shade300),
                      color: Theme.of(context).canvasColor
                  ),
                  child: Obx(() => DropdownButtonHideUnderline( // لإخفاء الخط السفلي الافتراضي
                    child: DropdownButton<String>(
                      value: controller.selectedAvailabilityFilterKey.value,
                      icon: Icon(Icons.filter_list_alt, color: Theme.of(context).primaryColor),
                      elevation: 2,
                      style: TextStyle(color: Colors.black87, fontSize: 14),
                      onChanged: controller.onAvailabilityFilterChanged,
                      alignment: AlignmentDirectional.center,
                      borderRadius: BorderRadius.circular(10),
                      dropdownColor: Colors.white,
                      items: controller.availabilityFiltersDisplay.entries.map((MapEntry<String, String> entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key, // "الكل" أو "online_available" الخ
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(entry.value), // "الكل" أو "متوفر الآن" الخ
                          ),
                        );
                      }).toList(),
                    ),
                  )),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.filteredCompanyDrivers.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.errorMessage.value.isNotEmpty && controller.filteredCompanyDrivers.isEmpty) {
                return Center(
                    child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(controller.errorMessage.value,
                                  style: const TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center),
                              SizedBox(height: 10),
                              ElevatedButton(onPressed: () => controller.fetchCompanyDrivers(), child: Text("إعادة المحاولة"))
                            ]
                        )));
              }
              if (controller.filteredCompanyDrivers.isEmpty && !controller.isLoading.value) {
                return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.no_accounts_rounded, size: 60, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          Text(
                            // --- هنا التعديل الرئيسي ---
                              controller.searchQuery.value.isNotEmpty || controller.selectedAvailabilityFilterKey.value != "الكل"
                                  ? "لا يوجد سائقون يطابقون معايير البحث/الفلترة."
                                  : "لا يوجد سائقون معتمدون لهذه الشركة بعد.",
                              // --------------------------
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16, color: Colors.grey)
                          ),
                        ],
                      ),
                    ));
              }
              return RefreshIndicator(
                onRefresh: () => controller.fetchCompanyDrivers(),
                child: ListView.builder(
                  itemCount: controller.filteredCompanyDrivers.length, // <-- استخدام القائمة المفلترة
                  itemBuilder: (context, index) {
                    final driver = controller.filteredCompanyDrivers[index];
                    return _buildDriverCard(driver, context);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}


class CompanyDriversListController extends GetxController {
  final String companyId; // ID للشركة الحالية، يُمرر من الـ Binding
  CompanyDriversListController({required this.companyId});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxList<DeliveryDriverModel> _allCompanyDrivers = <DeliveryDriverModel>[].obs;
  final RxList<DeliveryDriverModel> filteredCompanyDrivers = <DeliveryDriverModel>[].obs;

  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;

  final List<String> availabilityStatusKeys = ["online_available", "on_task", "offline"];
  final Map<String, String> availabilityFiltersDisplay = {
    "الكل": "الكل",
    "online_available": "متوفر الآن",
    "on_task": "في مهمة",
    "offline": "غير متوفر (أوفلاين)"
  };
  late RxString selectedAvailabilityFilterKey; // سيتم تهيئته في onInit


  @override
  void onInit() {
    super.onInit();
    selectedAvailabilityFilterKey = "الكل".obs; // القيمة الافتراضية

    if (companyId.isEmpty) {
      debugPrint("[DRIVERS_LIST_CTRL] Error: Company ID is empty. Cannot fetch drivers.");
      errorMessage.value = "خطأ فادح: لم يتم تحديد معرف الشركة.";
      isLoading.value = false;
      return;
    }

    searchController.addListener(() {
      // استخدام debounce لمنع استدعاءات متكررة للفلترة أثناء الكتابة السريعة
      // ولكن بما أن الفلترة تتم محليًا، قد لا يكون debounce ضروريًا جدًا هنا إلا إذا كانت القائمة ضخمة.
      // الطريقة الأبسط هي الاعتماد على RxString searchQuery.
      if (searchQuery.value != searchController.text.trim()) {
        searchQuery.value = searchController.text.trim();
      }
    });

    // مستمع لتغييرات البحث والفلتر لتحديث القائمة المعروضة
    // ever() تستمع لكل تغيير، debounce() تنتظر فترة معينة بعد آخر تغيير
    debounce(searchQuery, (_) => _applyFiltersAndSearch(), time: const Duration(milliseconds: 350));
    ever(selectedAvailabilityFilterKey, (_) => _applyFiltersAndSearch());

    fetchCompanyDrivers();
  }

  Future<void> fetchCompanyDrivers({bool showLoadingIndicator = true}) async {
    if (companyId.isEmpty) {
      errorMessage.value = "معرف الشركة غير متوفر لجلب السائقين.";
      if (showLoadingIndicator) isLoading.value = false;
      return;
    }
    if (showLoadingIndicator) isLoading.value = true;
    errorMessage.value = '';
    try {
      debugPrint("[DRIVERS_LIST_CTRL] Fetching drivers for company: $companyId");
      final snapshot = await _firestore
          .collection(FirebaseX.deliveryDriversCollection)
          .where('approvedCompanyId', isEqualTo: companyId) // <--- سائقو هذه الشركة فقط
          .where('applicationStatus', whereIn: [ // <--- الحالات التي تعتبر "جزءًا من فريق العمل"
        driverApplicationStatusToString(DriverApplicationStatus.approved),
        driverApplicationStatusToString(DriverApplicationStatus.suspended), // المشرف قد يرغب في رؤية المعلقين لإعادة تفعيلهم
      ])
      // لا تقم بالفلترة حسب availabilityStatus هنا، دع الفلتر المحلي يقوم بذلك
          .orderBy('name', descending: false) // أو createdAt إذا أردت الأحدث/الأقدم
          .get();

      final drivers = snapshot.docs
          .map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) return null;
        return DeliveryDriverModel.fromMap(data, doc.id);
      })
          .where((driver) => driver != null)
          .cast<DeliveryDriverModel>()
          .toList();

      _allCompanyDrivers.assignAll(drivers);
      _applyFiltersAndSearch(); // طبق الفلاتر والبحث الأولي
      debugPrint("[DRIVERS_LIST_CTRL] Fetched and initially filtered ${_allCompanyDrivers.length} drivers. Displaying ${filteredCompanyDrivers.length}.");
    } catch (e, s) {
      debugPrint("[DRIVERS_LIST_CTRL] Error fetching company drivers: $e\n$s");
      errorMessage.value = "فشل جلب قائمة السائقين: ${e.toString()}";
      _allCompanyDrivers.clear();
      filteredCompanyDrivers.clear();
    } finally {
      if (showLoadingIndicator) isLoading.value = false;
    }
  }

  void _applyFiltersAndSearch() {
    debugPrint("[DRIVERS_LIST_CTRL] Applying filters. Search: '${searchQuery.value}', Availability Key: '${selectedAvailabilityFilterKey.value}'");
    List<DeliveryDriverModel> tempFilteredList = List<DeliveryDriverModel>.from(_allCompanyDrivers);

    // تطبيق فلتر حالة التوفر
    if (selectedAvailabilityFilterKey.value != "all") {
      // selectedAvailabilityFilterKey.value هو المفتاح الإنجليزي (مثل "online_available")
      tempFilteredList = tempFilteredList.where((driver) =>
      driver.availabilityStatus.toLowerCase() == selectedAvailabilityFilterKey.value.toLowerCase()).toList();
    }

    // تطبيق فلتر البحث
    if (searchQuery.value.isNotEmpty) {
      String lowerCaseQuery = searchQuery.value.toLowerCase();
      tempFilteredList = tempFilteredList.where((driver) {
        return driver.name.toLowerCase().contains(lowerCaseQuery) ||
            driver.vehicleType.toLowerCase().contains(lowerCaseQuery) ||
            driver.uid.toLowerCase().contains(lowerCaseQuery); // البحث بالـ UID أيضًا قد يكون مفيدًا للمشرف
      }).toList();
    }
    filteredCompanyDrivers.assignAll(tempFilteredList);
    debugPrint("[DRIVERS_LIST_CTRL] Filtered list updated. Displaying ${filteredCompanyDrivers.length} drivers.");
  }
  Future<void> refreshDriverInList(String driverId) async {
    debugPrint("[DRIVERS_LIST_CTRL] Refreshing specific driver: $driverId or all drivers if needed.");
    // أبسط طريقة هي إعادة جلب الكل إذا كان التغيير قد يؤثر على الفلترة العامة
    // أو إذا كان التحديث يتضمن تغييرات في الحقول المستخدمة للفرز/الفلترة
    await fetchCompanyDrivers(showLoadingIndicator: false); // أعد الجلب بدون إظهار مؤشر التحميل العام
  }
  void onAvailabilityFilterChanged(String? newFilterKey) {
    if (newFilterKey != null) {
      debugPrint("[DRIVERS_LIST_CTRL] Availability filter changed to: $newFilterKey");
      selectedAvailabilityFilterKey.value = newFilterKey;
    }
  }

  void clearSearch() {
    searchController.clear(); // هذا سيؤدي لتحديث searchQuery.value بسبب المستمع
    // searchQuery.value = ''; // لا تحتاج لهذا إذا كان المستمع يعمل
  }

  // هذه الدالة مهمة إذا كنت ستسمح بتعديل حالة السائق من FullDriverProfileAdminScreen
  // وتريد أن تنعكس التغييرات فورًا في هذه القائمة دون إعادة جلب كل شيء.
   Future<void> updateDriverInListAfterEdit(String driverId) async {
    debugPrint("[DRIVERS_LIST_CTRL] Attempting to refresh driver $driverId in list after edit.");
    // أعد جلب بيانات هذا السائق المحدد فقط
    try {
      DocumentSnapshot doc = await _firestore.collection(FirebaseX.deliveryDriversCollection).doc(driverId).get();
      if (doc.exists && doc.data() != null) {
        final updatedDriver = DeliveryDriverModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        int indexAll = _allCompanyDrivers.indexWhere((d) => d.uid == updatedDriver.uid);
        if (indexAll != -1) {
          _allCompanyDrivers[indexAll] = updatedDriver; // حدث في القائمة الرئيسية
        } else {
          _allCompanyDrivers.add(updatedDriver); // أو أضفه إذا لم يكن موجودًا (نادر الحدوث هنا)
        }
        _applyFiltersAndSearch(); // أعد تطبيق الفلاتر لتحديث القائمة المعروضة
        debugPrint("[DRIVERS_LIST_CTRL] Driver $driverId data refreshed in list.");
      }
    } catch(e) {
      debugPrint("[DRIVERS_LIST_CTRL] Error refreshing single driver $driverId in list: $e");
      fetchCompanyDrivers(showLoadingIndicator: false); // كحل احتياطي، أعد جلب الكل بدون مؤشر تحميل
    }
  }


  @override
  void onClose() {
    searchController.dispose(); // تذكر دائمًا التخلص من TextEditingControllers
    debugPrint("[DRIVERS_LIST_CTRL] Controller closed.");
    super.onClose();
  }
}