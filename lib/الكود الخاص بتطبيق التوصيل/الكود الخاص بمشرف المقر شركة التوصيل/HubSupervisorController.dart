// hub_supervisor_controller.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // لـ BuildContext في الحوارات
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:syncfusion_flutter_barcodes/barcodes.dart';
import 'package:uuid/uuid.dart'; // لإنشاء IDs إذا لزم الأمر
// <--- مكتبة لمعالجة الصور

// افترض استيراد النماذج والثوابت
import '../../XXX/xxx_firebase.dart'; // عدّل المسار

// قد تحتاج إلى هذا إذا كنت تستخدم PosAlign من esc_pos_utils
// import 'package:esc_pos_utils/esc_pos_utils.dart';

import '../الكود الخاص بمشرف التوصيل/DeliveryCompanyModel.dart';
import '../الكود الخاص بمشرف التوصيل/DeliveryTaskModel.dart'; // لاستخدام StaffUserRole
// (قد تحتاج لنموذج الطرد المجمع لاحقًا)
// import '../models/consolidated_package_model.dart'; //  إذا أنشأته

class HubSupervisorController extends GetxController {
  final String companyId;  // ID الشركة الأم
  final String hubId;      // ID المقر الذي يشرف عليه
  final String hubName;    // اسم المقر (للعرض)
  final String companyName; // اسم الشركة

  HubSupervisorController({required this.companyId, required this.hubId, required this.hubName, required this.companyName});
  final GetStorage _box = GetStorage(); // تعريف GetStorage

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = Uuid();
  final RxBool transferToAnotherHubForButtonState = false.obs;

  // --- قائمة الشحنات الواصلة للمقر وتنتظر معالجة ---
  final RxList<DeliveryTaskModel> tasksAtHubAwaitingProcessing = <DeliveryTaskModel>[].obs;
  StreamSubscription? _tasksAtHubSubscription;
  final RxBool isLoadingTasksAtHub = true.obs;
  final RxString tasksAtHubError = ''.obs;
  // --- متغيرات خاصة بالطابعة مع print_bluetooth_thermal ---
  // PrintBluetoothThermal printerManager = PrintBluetoothThermal(); // لا حاجة لإنشاء مثيل هنا، يمكن استدعاء الدوال مباشرة
  RxList<BluetoothInfo> availableBluetoothDevices = <BluetoothInfo>[].obs; // <--- النوع يتغير إلى BluetoothInfo
  Rxn<BluetoothInfo> selectedPrinterDevice = Rxn<BluetoothInfo>(null);
  RxBool isConnectingToPrinter = false.obs;
  final RxString connectionStatus = "غير متصل".obs; // لتتبع حالة الاتصال وعرضها
  StreamSubscription? _connectionStatusSubscription;
  // --- لتتبع الشحنات المختارة للتجميع ---
  final RxList<DeliveryTaskModel> selectedTasksForConsolidation = <DeliveryTaskModel>[].obs;
  final RxnString currentConsolidationBuyerId = RxnString(null); //  لتتبع المشتري الذي يتم تجميع شحناته حاليًا

  // --- لتتبع الطرود المجمعة الجاهزة للنقل/الميل الأخير ---
  // هذا يمكن أن يكون Stream من مجموعة "consolidated_packages" إذا أنشأتها،
  // أو قائمة تُبنى من مهام الميل الأخير/مهام النقل بين المقرات.
  // للتبسيط الآن، لن نركز على عرض *قائمة الطرود المجمعة* بشكل مباشر هنا،
  // بل على عملية إنشائها ثم إنشاء المهام التالية لها.

  final RxBool isProcessingAction = false.obs; // مؤشر تحميل عام للأفعال


  //  (اختياري) اسم المشتري للعرض في واجهة التحكم في التجميع
  final RxnString currentConsolidationBuyerName = RxnString(null);



  @override
  void onInit() {
    super.onInit();
    _updateConnectionState();
    _tryAutoConnectToSavedPrinter(); // محاولة الاتصال التلقائي بالطابعة المحفوظة

    if (companyId.isEmpty || hubId.isEmpty) {
      tasksAtHubError.value = "خطأ: معلومات الشركة أو المقر غير متوفرة للمشرف.";
      isLoadingTasksAtHub.value = false;
      debugPrint("[HUB_SUPER_CTRL] CRITICAL Error: companyId or hubId is empty in onInit.");
      //  (قد تحتاج لآلية لإعلام المستخدم أو إعادة توجيهه إذا حدث هذا)
      return;
    }
    debugPrint("[HUB_SUPER_CTRL] Initializing for Company: $companyId, Hub: $hubId ('$hubName')");
    subscribeToTasksAtHub();

  }



  // In HubSupervisorController.dart

  Future<void> _updateConnectionState() async {
    try {
      // **افترض أن PrintBluetoothThermal.connectionStatus يُرجع Future<int> أو Future<String> يمثل الحالة**
      // ستحتاج لمعرفة ما هي القيم الفعلية التي تُرجعها هذه الدالة لحالة الاتصال، القطع، إلخ.
      // هذه القيم هي مجرد أمثلة بناءً على الاسم.

      // استخدام final لتجنب إعادة التعيين داخل الـ try
      final dynamic currentStatusFromLibrary = await PrintBluetoothThermal.connectionStatus;
      debugPrint("[PRINTER_STATUS_LIB] Status from library: $currentStatusFromLibrary (Type: ${currentStatusFromLibrary.runtimeType})");

      // **مثال للقيم التي قد تُرجعها المكتبة (يجب التحقق من التوثيق)**
      // قد تكون أرقامًا: 0 لـ NONE، 1 لـ CONNECTING، 2 لـ CONNECTED، 3 لـ DISCONNECTED
      // أو قد تكون سلاسل نصية مثل "CONNECTED", "DISCONNECTED"
      // سأفترض مؤقتًا أنها أرقام وأننا عرفنا ثوابت لها (كما فعلت سابقًا).
      // **القيم التالية افتراضية تمامًا ويجب استبدالها بالقيم الصحيحة من المكتبة!**
      const int libStatusConnected = 2; // مثال
      const int libStatusDisconnected = 3; // مثال
      const int libStatusConnecting = 1; // مثال
      const int libStatusNone = 0; // مثال

      bool isEffectivelyConnected = false;
      if (currentStatusFromLibrary is int) {
        isEffectivelyConnected = (currentStatusFromLibrary == libStatusConnected);
      } else if (currentStatusFromLibrary is String) {
        // إذا كانت المكتبة تُرجع سلاسل نصية
        isEffectivelyConnected = (currentStatusFromLibrary.toUpperCase() == "CONNECTED");
      }
      // أضف المزيد من التحققات لنوع currentStatusFromLibrary إذا لزم الأمر


      if (isEffectivelyConnected && selectedPrinterDevice.value != null) {
        connectionStatus.value = "متصل بـ: ${selectedPrinterDevice.value!.name}";
        isConnectingToPrinter.value = false; // تم الاتصال بنجاح
      } else if (currentStatusFromLibrary == libStatusConnecting && selectedPrinterDevice.value != null) {
        connectionStatus.value = "جاري الاتصال بـ ${selectedPrinterDevice.value!.name}...";
        isConnectingToPrinter.value = true; // لا يزال يحاول
      } else { // DISCONNECTED أو NONE أو أي حالة أخرى
        connectionStatus.value = "غير متصل";
        if (!isConnectingToPrinter.value) { // فقط إذا لم يكن يحاول الاتصال حاليًا
          selectedPrinterDevice.value = null;
        }
        isConnectingToPrinter.value = false;
      }
      debugPrint("[PRINTER_STATUS_UPDATE] Processed connection status to: ${connectionStatus.value}");

    } catch (e) {
      debugPrint("Error in _updateConnectionState (getting status from library): $e");
      connectionStatus.value = "خطأ في قراءة حالة الطابعة";
      selectedPrinterDevice.value = null;
      isConnectingToPrinter.value = false;
    }
  }

  // void _listenToConnectionStatus() {
  //   _connectionStatusSubscription = PrintBluetoothThermal.connectionStatus.listen((status) {
  //     debugPrint("[PRINTER_STATUS] Connection status: $status");
  //     // القيم الصحيحة تعتمد على مكتبة print_bluetooth_thermal
  //     // افترض قيمًا مؤقتة، يجب التحقق من التوثيق
  //     const int PRINTER_CONNECTED = 1; // مثال، تحقق من التوثيق
  //     const int PRINTER_DISCONNECTED = 2; // مثال، تحقق من التوثيق
  //     const int PRINTER_NONE = 0; // مثال، تحقق من التوثيق
  //
  //     switch(status) {
  //       case PRINTER_CONNECTED: // PrintBluetoothThermal.CONNECTED:
  //         connectionStatus.value = "متصل بـ: ${selectedPrinterDevice.value?.name ?? 'الطابعة'}";
  //         isConnectingToPrinter.value = false; //  تأكيد إيقاف تحميل الاتصال
  //         // Get.snackbar("نجاح", "تم الاتصال بالطابعة بنجاح!", backgroundColor: Colors.green);
  //         break;
  //       case PRINTER_DISCONNECTED: // PrintBluetoothThermal.DISCONNECTED:
  //         connectionStatus.value = "غير متصل (انقطع الاتصال)";
  //         if(isConnectingToPrinter.value){ //  إذا كان يحاول الاتصال وفشل
  //           Get.snackbar("فشل الاتصال", "فشل الاتصال بالطابعة المحددة.", backgroundColor: Colors.red, duration:Duration(seconds:3));
  //         }
  //         isConnectingToPrinter.value = false;
  //         selectedPrinterDevice.value = null; // مسح الطابعة المختارة عند الانقطاع
  //         break;
  //       case PRINTER_NONE: // PrintBluetoothThermal.NONE: // يمكن التعامل معها كـ DISCONNECTED
  //       default:
  //         connectionStatus.value = "غير متصل";
  //         isConnectingToPrinter.value = false;
  //         break;
  //     }
  //   });
  // }





  Future<void> scanAndSelectPrinter() async {
    if (!(await _checkBluetoothPermissions())) return;

    isConnectingToPrinter.value = true; // يمكن استخدام هذا كـ "جاري البحث"
    connectionStatus.value = "جاري البحث عن طابعات...";
    availableBluetoothDevices.clear(); // امسح القائمة القديمة

    try {
      final List<BluetoothInfo> devices = await PrintBluetoothThermal.pairedBluetooths;
      availableBluetoothDevices.assignAll(devices);
      isConnectingToPrinter.value = false;

      if (availableBluetoothDevices.isNotEmpty) {
        BluetoothInfo? chosenDevice = await Get.dialog<BluetoothInfo>(
          AlertDialog(
            title: const Text("اختر طابعة بلوتوث مقترنة"),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                itemCount: availableBluetoothDevices.length,
                shrinkWrap: true,
                itemBuilder: (c, i) {
                  final dev = availableBluetoothDevices[i];
                  return ListTile(
                    leading: const Icon(Icons.print_rounded),
                    title: Text(dev.name),
                    subtitle: Text(dev.macAdress),
                    onTap: () => Get.back(result: dev),
                  );
                },
              ),
            ),
            actions: [TextButton(onPressed: ()=> Get.back(), child:Text("إلغاء"))],
          ),
        );

        if (chosenDevice != null) {
          await connectToPrinter(chosenDevice);
        } else {
          connectionStatus.value = "تم إلغاء اختيار الطابعة";
        }
      } else {
        connectionStatus.value = "لا توجد طابعات مقترنة";
        Get.snackbar("لا توجد طابعات", "يرجى اقتران طابعة بلوتوث حرارية بجهازك أولاً من إعدادات البلوتوث.", duration: const Duration(seconds: 4));
      }
    } catch (e) {
      debugPrint("Error scanning for printers: $e");
      Get.snackbar("خطأ في البحث", "حدث خطأ أثناء البحث عن الطابعات: $e", backgroundColor: Colors.red);
      connectionStatus.value = "خطأ في البحث";
      isConnectingToPrinter.value = false;
    }finally {
      isConnectingToPrinter.value = false; //  البحث انتهى (بغض النظر عن نتيجة الاتصال اللاحق)
      await _updateConnectionState(); // حدث الحالة لمعرفة ما إذا تم الاتصال أو بقي غير متصل
    }
  }


  Future<void> _tryAutoConnectToSavedPrinter() async {
    final String? savedMacAddress = _box.read<String>('last_connected_printer_mac');
    final String? savedName = _box.read<String>('last_connected_printer_name');

    if (savedMacAddress != null && savedName != null) {
      debugPrint("[PRINTER_AUTO_CONNECT] Attempting to auto-connect to saved printer: $savedName ($savedMacAddress)");
      BluetoothInfo savedDevice = BluetoothInfo(name: savedName, macAdress: savedMacAddress);
      await connectToPrinter(savedDevice); // ستحاول الاتصال وتحديث الحالة
    } else {
      debugPrint("[PRINTER_AUTO_CONNECT] No saved printer found.");
    }
  }






  Future<void> connectToPrinter(BluetoothInfo device) async {
    if (isConnectingToPrinter.value && selectedPrinterDevice.value?.macAdress == device.macAdress) {
      debugPrint("Already attempting to connect to ${device.name}");
      return;
    }
    await disconnectPrinter(); //  اقطع أي اتصال سابق قبل محاولة الاتصال بجديد

    isConnectingToPrinter.value = true;
    selectedPrinterDevice.value = device;
    connectionStatus.value = "جاري الاتصال بـ ${device.name}...";
    bool connectedSuccessfully = false;

    try {
      final bool connectResult = await PrintBluetoothThermal.connect(macPrinterAddress: device.macAdress);
      if (connectResult) {
        connectionStatus.value = "متصل بـ: ${device.name}";
        //  احفظ الطابعة المتصلة
        await _box.write('last_connected_printer_mac', device.macAdress);
        await _box.write('last_connected_printer_name', device.name);
        Get.snackbar("تم الاتصال", "تم الاتصال بالطابعة: ${device.name}", backgroundColor: Colors.green, colorText: Colors.white);
        connectedSuccessfully = true;
      } else {
        throw Exception("فشل الاتصال بالطابعة (أرجعت المكتبة false)");
      }
    } catch (e) {
      debugPrint("Error connecting to printer ${device.name}: $e");
      connectionStatus.value = "فشل الاتصال بـ: ${device.name}";
      selectedPrinterDevice.value = null; // مسح الاختيار عند الفشل
      Get.snackbar("خطأ في الاتصال", "لم يتمكن من الاتصال بالطابعة: ${e.toString()}", backgroundColor: Colors.red.shade300);
    } finally {
      isConnectingToPrinter.value = false;
      await _updateConnectionState(); // حدث الحالة النهائية
      if(!connectedSuccessfully) await _box.remove('last_connected_printer_mac'); // مسح الحفظ إذا فشل
      // await _updateConnectionState(); //  تحديث الحالة النهائية
    }
  }

  Future<void> disconnectPrinter() async {
    if (selectedPrinterDevice.value == null && connectionStatus.value == "غير متصل") {
      return; // ليس هناك ما يتم قطعه
    }
    connectionStatus.value = "جاري قطع الاتصال...";
    try {
      final bool disconnected = await PrintBluetoothThermal.disconnect;
      if (disconnected) {
        debugPrint("Printer disconnected successfully via library.");
      } else {
        debugPrint("PrintBluetoothThermal.disconnect returned false or error.");
        //  قد لا تحتاج لرسالة خطأ هنا إذا كان الانقطاع سيعالج كـ "غير متصل"
      }
    } catch (e) {
      debugPrint("Error during disconnectPrinter: $e");
    } finally {
      await _updateConnectionState();

      await _box.remove('last_connected_printer_mac'); // مسح الطابعة المحفوظة
      await _box.remove('last_connected_printer_name');
      debugPrint("Local printer state reset after disconnect attempt.");
    }
  }

  Future<bool> _checkBluetoothPermissions() async {
    PermissionStatus bluetoothScanStatus = await Permission.bluetoothScan.status;
    if (!bluetoothScanStatus.isGranted) {
      bluetoothScanStatus = await Permission.bluetoothScan.request();
    }
    PermissionStatus bluetoothConnectStatus = await Permission.bluetoothConnect.status;
    if (!bluetoothConnectStatus.isGranted) {
      bluetoothConnectStatus = await Permission.bluetoothConnect.request();
    }
    // لبعض الأجهزة القديمة أو المكتبات، قد تحتاج لأذونات الموقع لمسح BLE
    PermissionStatus locationStatus = await Permission.locationWhenInUse.status;
    if(!locationStatus.isGranted && (GetPlatform.isAndroid && (await _getAndroidSDKVersion() ?? 0) < 31) ){ // Android 11 و أقل
      locationStatus = await Permission.locationWhenInUse.request();
    }

    return bluetoothScanStatus.isGranted && bluetoothConnectStatus.isGranted && ( (GetPlatform.isAndroid && (await _getAndroidSDKVersion() ?? 0) < 31) ? locationStatus.isGranted : true );
  }
  Future<int?> _getAndroidSDKVersion() async {
    // هذا يتطلب `device_info_plus` أو كود أصلي. للتبسيط، سأضع قيمة تقديرية.
    // في تطبيق حقيقي، استخدم `device_info_plus`
    return 29; // مثال (Android 10)
  }






  Future<Uint8List?> _generateBarcodeImageBytesSyncfusion(
      BuildContext captureContext, // <--- تم إضافة السياق كمعامل
      String data,
      Symbology symbologyInstance, {
        double targetWidth = 300,
        double targetHeight = 80,
        Color barColor = Colors.black,
        Color backgroundColor = Colors.white,
        bool showTextWithValue = false,
        TextStyle textStyleForValue = const TextStyle(fontSize: 12, color: Colors.black),
      }) async {
    final GlobalKey barcodeKey = GlobalKey();
    Uint8List? pngBytes;
    OverlayEntry? overlayEntry; // <--- **قم بتعريف overlayEntry هنا، خارج الـ try**

    Widget barcodeCaptureWidget = RepaintBoundary(
      key: barcodeKey,
      child: Container(
        width: targetWidth,
        height: targetHeight,
        color: backgroundColor,
        alignment: Alignment.center,
        child: SfBarcodeGenerator(
          value: data,
          symbology: symbologyInstance,
          barColor: barColor,
          backgroundColor: backgroundColor,
          showValue: showTextWithValue,
          textStyle: textStyleForValue,
        ),
      ),
    );

    try {
      // استخدام captureContext الممرر للوصول إلى الـ Overlay
      final OverlayState overlayState = Overlay.of(captureContext);


      overlayEntry = OverlayEntry( // <--- تعيين القيمة للمتغير المعرف في النطاق الأعلى
        builder: (context) => Positioned(
          left: -targetWidth * 2, // ضعها بعيدًا جدًا عن الشاشة
          top: -targetHeight * 2,
          child: Material(
            type: MaterialType.transparency,
            child: barcodeCaptureWidget,
          ),
        ),
      );

      overlayState.insert(overlayEntry); // استخدم ! بعد التأكد من عدم الـ null أو معالجته

      // انتظر لحظة للسماح بالبناء
      // استخدام addPostFrameCallback أفضل من Future.delayed هنا
      await WidgetsBinding.instance.endOfFrame; //  ينتظر حتى نهاية الإطار الحالي
      //  أو يمكنك إضافة تأخير صغير إضافي إذا لزم الأمر، ولكن endOfFrame غالبًا كافٍ
      // await Future.delayed(const Duration(milliseconds: 50));


      RenderRepaintBoundary? boundary =
      barcodeKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary != null && boundary.debugNeedsPaint == false) {
        ui.Image image = await boundary.toImage(pixelRatio: 3.0);
        ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        pngBytes = byteData?.buffer.asUint8List();
        image.dispose();
      } else {
        if (boundary == null) {
          debugPrint("Syncfusion Barcode: RenderRepaintBoundary is null after overlay.");
        } else if (boundary.debugNeedsPaint == true) debugPrint("Syncfusion Barcode: Boundary still needs paint.");
      }

    } catch (e, s) {
      debugPrint('Error capturing SfBarcodeGenerator as image: $e');
      debugPrint(s as String?);
      Get.snackbar("خطأ باركود SF-RB", "فشل التقاط صورة الباركود: $e",
          backgroundColor: Colors.red.shade300, duration: const Duration(seconds: 4), snackPosition: SnackPosition.BOTTOM);
      // لا نُرجع null هنا بعد، دع finally يقوم بإزالة الـ overlay
    } finally {
      // --- **تأكد من إزالة الـ OverlayEntry دائمًا في finally** ---
      if (overlayEntry != null) {
        overlayEntry.remove();
        overlayEntry = null; // أعد تعيينه إلى null
        debugPrint("OverlayEntry for barcode capture removed.");
      }
    }
    // الآن قم بإرجاع pngBytes (قد تكون null إذا فشل الالتقاط)
    if (pngBytes != null) {
      debugPrint("Syncfusion barcode PNG (via RepaintBoundary) generated. Length: ${pngBytes.length}");
    } else {
      debugPrint("Failed to generate barcode image using Syncfusion (RepaintBoundary method). PngBytes is null.");
    }
    return pngBytes;
  }

   final Map<int, int> _unicodeToCp864SimpleMap = {
    // Arabic Letter Alef
    0x0627: 0x80, // أ (شكل منفصل/نهائي)
    // ... (يجب ملء هذا الجدول بالكثير من القيم الصحيحة لكل أشكال الحروف)
    // ... على سبيل المثال، لحرف الباء:
    0x0628: 0x81, // ب (شكل منفصل)
    0xFE8F: 0x81, // ب (شكل بداية - FE8F هو شكل العرض لـ ب في البداية)
    0xFE91: 0x81, // ب (شكل وسط - FE91)
    0xFE90: 0x81, // ب (شكل نهاية - FE90)
    // هذه القيم (0x81) لـ CP864 هي افتراضية، قد تحتاج للتحقق منها
  };



  Future<void> _printConsolidatedPackageLabel(
      BuildContext captureContext, String packageBarcode, String recipientName, String recipientPhone,
      String recipientProvince, String recipientAddress,       // <--- تمرير السياق هنا
      List<String> originalOrders,
      String? transferDestination) async {

    // القيم الصحيحة تعتمد على مكتبة print_bluetooth_thermal
    // افترض قيمًا مؤقتة، يجب التحقق من التوثيق
    const int printerConnected = 1; // مثال، تحقق من التوثيق
    final bool isCurrentlyConnected = await PrintBluetoothThermal.connectionStatus == printerConnected; // PrintBluetoothThermal.CONNECTED;
    await _updateConnectionState(); // <--- تحديث الحالة أولاً

    if (!isCurrentlyConnected) {
      Get.snackbar("الطابعة غير متصلة", "الرجاء اختيار طابعة والاتصال بها أولاً.", duration: Duration(seconds:3), snackPosition: SnackPosition.BOTTOM);
      // اختياريًا، استدعِ scanAndSelectPrinter() مباشرة هنا
      // await scanAndSelectPrinter();
      // if(!(await PrintBluetoothThermal.connectionStatus == PrintBluetoothThermal.CONNECTED)) return;
      return;
    }


    // --- 2. تجهيز أوامر ESC/POS الخام ---
    List<int> bytes = [];

    // الأمر الأهم: تحديد مجموعة الأحرف للعربية (يجب أن يتم مرة واحدة في البداية)
    // PC864 (Arabic): عادة table رقم 21 (0x15)
    // PC720 (Arabic): عادة table رقم 20 (0x14)
    // يجب التجربة مع طابعتك!
    // ESC t n  (n هو رقم الجدول)
    bytes += [0x1B, 0x74, 21]; // محاولة استخدام جدول CP864

    // تهيئة الطابعة
    bytes += [0x1B, 0x40]; // ESC @ (Initialize printer)

    // العنوان الرئيسي (مثال: حجم مزدوج ومحاذاة للوسط)
    bytes += [0x1B, 0x61, 1]; // ESC a 1 (Center alignment)
    bytes += [0x1D, 0x21, 0x11]; // GS ! 11 (Double height, double width)
    bytes.addAll(await _convertArabicForPrinter("ملصق شحنة\n")); // <--- استخدام دالة التحويل
    bytes += [0x1D, 0x21, 0x00]; // GS ! 00 (Normal size)

    // خط فاصل
    String hrLine = "--------------------------------\n"; // اضبط العدد ليناسب عرض الورق
    bytes.addAll(utf8.encode(hrLine)); // ASCII يعمل مباشرة مع utf8.encode أو codeUnits
    final Symbology symbologyForPrinting = Code128(module: 2); //  اجعل module double

    // --- طباعة الباركود (كصورة أولاً ثم كنص) ---
    final Uint8List? barcodeImageBytes = await _generateBarcodeImageBytesSyncfusion(
        captureContext, // <--- تمرير السياق
        packageBarcode,
        symbologyForPrinting,
        targetWidth: 384, // العرض النهائي المرغوب للصورة
        targetHeight: 70,  // الارتفاع النهائي المرغوب للصورة
        showTextWithValue: false
    );
    if (barcodeImageBytes != null) {
      // **التحدي:** مكتبة print_bluetooth_thermal قد لا تحتوي على دالة مباشرة لطباعة `Uint8List` كصورة.
      // عادةً، مكتبات مثل esc_pos_utils تقوم بتحويل الصورة إلى صيغة نقطية (raster format) بأوامر ESC/POS.
      // ستحتاج إما:
      // أ) تنفيذ دالة لتحويل imageBytes إلى أوامر ESC/POS لطباعة الصور النقطية (مثل GS v 0 ...). هذا معقد.
      // ب) البحث في توثيق print_bluetooth_thermal عن طريقة لطباعة الصور.
      // ج) إذا كانت الطابعة تدعم أوامر طباعة صور مدمجة مباشرة، يمكن إرسالها.

      // **للتبسيط حاليًا، سنقوم فقط بطباعة نص الباركود.**
      // لاحقًا يمكنك البحث عن طريقة لتحويل `barcodeImageBytes` لأوامر طابعة الصور.
      // أو يمكنك استخدام دالة printCustom (إذا كانت موجودة وتسمح بإرسال bytes مباشرة للصورة).

      bytes += [0x1B, 0x61, 1]; // Center
      bytes.addAll(utf8.encode(packageBarcode));
      bytes += [0x0A]; // New line
      bytes += [0x1B, 0x61, 0]; // Default align (left or right for RTL)
      debugPrint("INFO: Barcode image generated, but raw ESC/POS image printing is complex without a utility. Printing barcode text instead.");
    } else {
      bytes += [0x1B, 0x61, 1]; // Center
      bytes.addAll(utf8.encode(packageBarcode)); // اطبع النص إذا فشلت الصورة
      bytes += [0x0A];
    }
    bytes += [0x0A]; // سطر فارغ إضافي
    bytes.addAll(utf8.encode(hrLine));


    // --- معلومات المستلم والنقل ---
    // لطباعة النصوص العربية من اليمين لليسار، تحتاج طابعتك لدعم ذلك أو أوامر خاصة
    // الأمر ESC a 2 يضبط المحاذاة لليمين للنص، ولكن لا يضمن عرض الحروف RTL
    bytes += [0x1B, 0x61, 2]; // ESC a 2 (Right alignment for the following Arabic text)

    if (transferDestination != null && transferDestination.isNotEmpty) {
      bytes.addAll(await _convertArabicForPrinter("وجهة النقل: $transferDestination\n", bold: true));
    }
    bytes.addAll(await _convertArabicForPrinter("إلى: $recipientName\n", bold: true));
    bytes.addAll(await _convertArabicForPrinter("الهاتف: $recipientPhone\n")); // الأرقام ستطبع LTR
    bytes.addAll(await _convertArabicForPrinter("المحافظة: $recipientProvince\n"));
    bytes.addAll(await _convertArabicForPrinter("العنوان: $recipientAddress\n"));
    bytes.addAll(utf8.encode(hrLine));

    bytes.addAll(await _convertArabicForPrinter("من: مقر $hubName (شركة $companyName)\n"));
    if (originalOrders.isNotEmpty) {
      bytes.addAll(await _convertArabicForPrinter("الطلبات الأصلية:\n"));
      for (var orderId in originalOrders) {
        bytes.addAll(await _convertArabicForPrinter("- $orderId\n"));
      }
    }
    bytes.addAll(utf8.encode(hrLine));

    // التاريخ والوقت (في الوسط)
    bytes += [0x1B, 0x61, 1]; // Center alignment
    bytes.addAll(utf8.encode(DateFormat('yyyy/MM/dd hh:mm a', 'en_US').format(DateTime.now()))); // استخدم en_US للأرقام
    bytes += [0x0A];
    bytes.addAll([0x1B, 0x61, 0]); // العودة للمحاذاة الافتراضية (يسار)

    // --- أوامر نهائية ---
    bytes.addAll([0x0A, 0x0A, 0x0A, 0x0A]); // تغذية 4 أسطر (لإخراج الورقة)
    bytes.addAll([0x1D, 0x56, 66, 0]); // GS V m n (قص جزئي للورق) - قد تحتاج لتغيير 66

    // --- 3. إرسال البيانات للطابعة ---
    try {
      Get.snackbar("جاري الطباعة...", "إرسال البيانات إلى الطابعة ${selectedPrinterDevice.value?.name ?? ''}",
          showProgressIndicator: true, duration: const Duration(seconds: 5), snackPosition: SnackPosition.BOTTOM);

      final bool result = await PrintBluetoothThermal.writeBytes(bytes); // <--- إرسال البايتات الخام

      if (Get.isSnackbarOpen ?? false) Get.closeCurrentSnackbar(); // أغلق مؤشر التقدم
      if (result) {
        Get.snackbar("نجاح الطباعة", "تم إرسال الملصق إلى الطابعة بنجاح.", backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        Get.snackbar("خطأ في الطباعة", "فشل إرسال البيانات للطابعة (أرجعت الدالة false).", backgroundColor: Colors.red, duration: const Duration(seconds: 4));
      }
    } catch (e) {
      if (Get.isSnackbarOpen ?? false) Get.closeCurrentSnackbar();
      Get.snackbar("خطأ في الطباعة", "فشل إرسال البيانات للطابعة: $e", backgroundColor: Colors.red, duration: const Duration(seconds: 5));
      debugPrint("Error writing to printer (raw with print_bluetooth_thermal): $e");
    }
  }

  // --- دالة مساعدة لتحويل النص العربي إلى بايتات CP864 (مثال بسيط جدًا، قد تحتاج لتحسينه) ---
  // **تحذير:** هذا التحويل بدائي جدًا. الطابعات المختلفة قد تتطلب طرقًا مختلفة.
  // الأفضل هو أن تدعم الطابعة UTF-8 مباشرة أو أن تجد جدول تحويل دقيق.
  Future<List<int>> _convertArabicForPrinter(
      String text, {
        bool bold = false,
        bool doubleHeight = false,
        bool doubleWidth = false,
        int align = 2, // 0=left, 1=center, 2=right - حل مؤقت بدلاً من PosAlign
        // (0=left, 1=center, 2=right)
      }) async {
    List<int> command = [];

    // 1. أوامر التنسيق الأولية
    // أوامر المحاذاة، إلخ. يجب أن تكون معروفة للطابعة أو من مكتبة ESC/POS
    // هذه قيم افتراضية وقد لا تعمل
    final List<int> alignLeft = [0x1B, 0x61, 0];
    final List<int> alignCenter = [0x1B, 0x61, 1];
    final List<int> alignRight = [0x1B, 0x61, 2];
    final List<int> boldOn = [0x1B, 0x45, 1];
    final List<int> boldOff = [0x1B, 0x45, 0];
    final List<int> normalSize = [0x1D, 0x21, 0x00];
    final List<int> lf = [0x0A];

    switch(align){
      case 1: command.addAll(alignCenter); break; // Center
      case 2: command.addAll(alignRight); break;  // Right
      default: command.addAll(alignLeft); break; // Left
    }
    if (bold) command.addAll(boldOn);
    int sizeCmd = 0x00;
    if (doubleHeight && doubleWidth) {
      sizeCmd = 0x11;
    } else if (doubleHeight) sizeCmd = 0x01;
    else if (doubleWidth) sizeCmd = 0x10;
    if (sizeCmd != 0x00) command.addAll([0x1D, 0x21, sizeCmd]);

    // --- الجزء الحاسم: تحويل النص ---
    // إذا لم يكن لديك Shaping + جدول تحويل CP864 صحيح،
    // فالنتائج ستكون غير مثالية للعربية.

    // **محاولة (1): إذا كانت طابعتك قد تدعم UTF-8 مباشرة مع أوامر تهيئة**
    // ابحث في دليل طابعتك عن أمر لتفعيل UTF-8. إذا وجد، أرسله.
    // command.addAll([0x1C, 0x26]); // مثال لأمر UTF-8 (يختلف)
    // command.addAll(utf8.encode(text)); // ثم أرسل النص كـ UTF-8

    // **محاولة (2): استخدام Code Page (CP864 كمثال) مع تحويل بسيط (لن يكون مثاليًا)**
    // هذا يفترض أن أمر `setArabicCP864` قد تم إرساله مسبقًا (أو يتم إرساله هنا)
    // command.addAll(setArabicCP864);
    List<int> textBytes = [];
    for (int charCode in text.codeUnits) { // text.codeUnits تعطي UTF-16
      // هل هو حرف عربي أساسي (نطاق Unicode للعربية الأساسية)
      if (charCode >= 0x0600 && charCode <= 0x06FF) {
        // هنا يجب أن يكون لديك جدول تحويل صحيح لـ CP864 أو الترميز الذي تستهدفه
        // المثال البسيط أدناه يستخدم _unicodeToCp864SimpleMap (وهو غير كامل)
        int? cp864Char = _unicodeToCp864SimpleMap[charCode];
        if (cp864Char != null) {
          textBytes.add(cp864Char);
        } else {
          textBytes.add(0x3F); // علامة استفهام إذا لم يوجد الحرف في الخريطة
        }
      }
      // إذا كان رقمًا أو رمزًا أو حرفًا لاتينيًا ضمن نطاق ASCII/CP864
      else if (charCode < 256) { //  (بافتراض أن الأرقام والرموز تقع ضمن هذا النطاق في CP864)
        textBytes.add(charCode);
      }
      // تجاهل الحروف الأخرى أو استبدلها
      else {
        textBytes.add(0x3F); // علامة استفهام للحروف غير المدعومة
      }
    }
    command.addAll(textBytes);
    // --- نهاية الجزء الحاسم ---


    // إلغاء أوامر التنسيق
    if (sizeCmd != 0x00) command.addAll(normalSize);
    if (bold) command.addAll(boldOff);
    // لا نعيد المحاذاة هنا، كل سطر يتم ضبط محاذاته بشكل منفصل

    command.addAll(lf); // إضافة سطر جديد دائمًا بعد النص

    return command;
  }









  void subscribeToTasksAtHub() {
    isLoadingTasksAtHub.value = true;
    tasksAtHubError.value = '';
    _tasksAtHubSubscription?.cancel(); // إلغاء أي اشتراك سابق
    debugPrint("[HUB_SUPER_CTRL] Subscribing to tasks at hub: $hubId (Company: $companyId)");

    // تأكيد إضافي
    if (companyId.isEmpty || hubId.isEmpty) {
      tasksAtHubError.value = "لا يمكن الاشتراك بدون معرف شركة ومقر صالحين.";
      isLoadingTasksAtHub.value = false;
      return;
    }

    _tasksAtHubSubscription = _firestore
        .collection(FirebaseX.deliveryTasksCollection)
        .where('assignedCompanyId', isEqualTo: companyId)  // تابعة لنفس الشركة
        .where('hubIdDroppedOffAt', isEqualTo: hubId)     // تم تسليمها لهذا المقر المحدد
        .where('status', isEqualTo: deliveryTaskStatusToString(DeliveryTaskStatus.dropped_at_hub)) // حالتها أنها تنتظر معالجة في المقر
        .orderBy('hubDropOffTime', descending: false) //  <--- الأفضل هنا الترتيب بوقت وصولها للمقر (الأقدم أولاً)
    // إذا لم يكن hubDropOffTime دقيقًا دائمًا، يمكن استخدام createdAt للمهمة الأصلية.
        .snapshots()
        .listen((snapshot) {
      debugPrint("[HUB_SUPER_CTRL] Firestore snapshot received for tasks at hub. Docs count: ${snapshot.docs.length}");
      try {
        final tasks = snapshot.docs
            .map((doc) => DeliveryTaskModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
            .toList();
        tasksAtHubAwaitingProcessing.assignAll(tasks);

        // منطق مسح التحديدات إذا تغيرت القائمة بشكل جذري (مفيد للحفاظ على تناسق الواجهة)
        List<String> currentTaskIdsInList = tasks.map((t) => t.taskId).toList();
        selectedTasksForConsolidation.retainWhere((selectedTask) => currentTaskIdsInList.contains(selectedTask.taskId));
        if (selectedTasksForConsolidation.isEmpty) {
          currentConsolidationBuyerId.value = null;
        }
        selectedTasksForConsolidation.refresh(); // لتحديث الواجهة إذا تغير شيء في التحديد

      } catch (e, s) {
        debugPrint("[HUB_SUPER_CTRL] Error parsing tasks from snapshot: $e\n$s");
        tasksAtHubError.value = "خطأ في تنسيق بيانات الشحنات الواصلة.";
        tasksAtHubAwaitingProcessing.clear(); // مسح القائمة عند خطأ البارسنج
      } finally {
        isLoadingTasksAtHub.value = false; // تم الانتهاء من محاولة التحديث (سواء نجحت أم فشلت في البارسنج)
      }
      debugPrint("[HUB_SUPER_CTRL] Tasks at hub (awaiting processing) list updated. Count: ${tasksAtHubAwaitingProcessing.length}");
    }, onError: (error, stackTrace) { // معالجة أخطاء الـ Stream نفسه
      debugPrint("[HUB_SUPER_CTRL] Error listening to tasks at hub: $error\n$stackTrace");
      tasksAtHubError.value = "فشل في الاستماع لتحديثات الشحنات: $error";
      tasksAtHubAwaitingProcessing.clear();
      isLoadingTasksAtHub.value = false;
    });
  }


  // --- دوال اختيار المهام للتجميع ---
  void toggleTaskForConsolidation(DeliveryTaskModel task) {


    // التأكد أولاً أن المهمة لا تزال في قائمة الانتظار (قد تكون عولجت في تحديث آخر)
    if (!tasksAtHubAwaitingProcessing.any((t) => t.taskId == task.taskId)){
      Get.snackbar("تم التحديث", "هذه الشحنة ربما تمت معالجتها بالفعل. يتم تحديث القائمة.", snackPosition: SnackPosition.BOTTOM, duration: Duration(seconds:2));
      // لا تفعل شيئًا هنا، الـ stream سيُحدّث القائمة
      return;
    }


    if (selectedTasksForConsolidation.any((t) => t.taskId == task.taskId)) {
      // إذا كانت محددة، قم بإلغاء تحديدها
      selectedTasksForConsolidation.removeWhere((t) => t.taskId == task.taskId);
      // إذا كانت هذه هي آخر مهمة محددة، قم بمسح currentConsolidationBuyerId
      if (selectedTasksForConsolidation.isEmpty) {
        currentConsolidationBuyerId.value = null;
        currentConsolidationBuyerName.value = null;      }
    } else {
      // إذا لم تكن محددة
      if (currentConsolidationBuyerId.value == null) {
        selectedTasksForConsolidation.add(task);
        currentConsolidationBuyerId.value = task.buyerId;
        currentConsolidationBuyerName.value = task.buyerName; // خزن الاسم للعرض
      } else if (task.buyerId == currentConsolidationBuyerId.value) {
        // المهمة لنفس المشتري، أضفها
        selectedTasksForConsolidation.add(task);
      } else {
        // المهمة لمشترٍ مختلف، اعرض تنبيهًا
        Get.snackbar("تجميع لمشترٍ واحد فقط", "لا يمكن تجميع شحنات لمشترين مختلفين في نفس الطرد. قم بمعالجة شحنات '${currentConsolidationBuyerName.value ?? 'المشتري الحالي'}' أولاً.",
            backgroundColor: Colors.orange.shade400, duration: const Duration(seconds: 5), snackPosition: SnackPosition.TOP, colorText: Colors.black87);
      }
    }
    selectedTasksForConsolidation.refresh(); // لتحديث الواجهة
  }

  bool isTaskSelectedForConsolidation(String taskId) {
    return selectedTasksForConsolidation.any((t) => t.taskId == taskId);
  }

  void clearConsolidationSelection() {
    selectedTasksForConsolidation.clear();
    currentConsolidationBuyerId.value = null;
    currentConsolidationBuyerName.value = null;
    selectedTasksForConsolidation.refresh();
  }

  // --- دالة إنشاء الطرد المجمع ومهمة الميل الأخير/النقل ---
  Future<void> createConsolidatedPackageAndNextTask(BuildContext context, {required bool transferToAnotherHub}) async {
    if (selectedTasksForConsolidation.isEmpty) {
      Get.snackbar("لم يتم التحديد", "يرجى تحديد شحنة واحدة على الأقل للمعالجة.", snackPosition: SnackPosition.TOP, backgroundColor: Colors.orange.shade300);
      return;
    }
    // التأكد من أن كل المهام المحددة لنفس المشتري (تم هذا عند toggleTaskForConsolidation)
    // ولكن كتحقق إضافي إذا لزم الأمر.
    final String? targetBuyerId = currentConsolidationBuyerId.value;
    if (targetBuyerId == null) {
      Get.snackbar("خطأ", "لم يتم تحديد المشتري المستهدف لهذه المجموعة.", snackPosition: SnackPosition.TOP, backgroundColor: Colors.red.shade300);
      return;
    }
    if (!selectedTasksForConsolidation.every((task) => task.buyerId == targetBuyerId)) {
      Get.snackbar("خطأ في التحديد", "يجب أن تكون كل الشحنات المحددة موجهة لنفس المشتري.", /*...*/);
      clearConsolidationSelection(); // مسح التحديد الخاطئ
      return;
    }
    isProcessingAction.value = true; // تفعيل مؤشر التحميل العام للإجراء

    // 1. إنشاء معرف وباركود للطرد المجمع
    String consolidatedPackageId = "CPKG_${_uuid.v4().substring(0, 12)}"; // ID فريد للطرد
    String suggestedBarcode = "CPBAR_${targetBuyerId.substring(0, min(4, targetBuyerId.length))}_${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}"; // اقتراح للباركود

    // (اختياري ولكنه جيد) حوار لتأكيد/تعديل الباركود المجمع من قبل المشرف
    String? finalConsolidatedPackageBarcode = await Get.dialog<String>(
      AlertDialog(
        title: Text("تأكيد باركود الطرد المجمع", style: Get.textTheme.titleLarge),
        content: TextFormField(
          initialValue: suggestedBarcode,
          onChanged: (val) => suggestedBarcode = val, // السماح بالتعديل
          decoration: const InputDecoration(labelText: "الباركود النهائي للطرد المجمع", hintText: "يجب أن يكون فريدًا"),
          validator: (val) => (val == null || val.trim().isEmpty) ? "الباركود مطلوب" : null,
        ),
        actions: [
          TextButton(onPressed: () => Get.back(result: null), child: const Text("إلغاء")),
          ElevatedButton(
              onPressed: () {
                if (suggestedBarcode.trim().isNotEmpty) {
                  Get.back(result: suggestedBarcode.trim());
                } else {
                  Get.snackbar("مطلوب", "الرجاء إدخال باركود صالح.", snackPosition: SnackPosition.TOP);
                }
              },
              child: const Text("تأكيد الباركود"))
        ],
      ),
      barrierDismissible: false,
    );

    if (finalConsolidatedPackageBarcode == null) {
      isProcessingAction.value = false;
      Get.snackbar("إلغاء", "تم إلغاء عملية إنشاء الطرد المجمع.", snackPosition: SnackPosition.TOP);
      return;
    }
    consolidatedPackageId = finalConsolidatedPackageBarcode; // استخدام الباركود كمعرف للطرد إذا كان مناسبًا، أو الاحتفاظ بالـ UUID. دعنا نستخدم الباركود كمعرف إذا كان المشرف يؤكده.


    // --- تحديد معلومات المهمة التالية (المصدر، الوجهة، إلخ) ---
    DeliveryCompanyModel? currentCompanyFullData;
    GeoPoint? currentHubLocation; // موقع المقر الحالي (المرسل)
    String currentHubActualName = hubName; // الاسم الممرر للمتحكم أو من بيانات الشركة

    // جلب بيانات الشركة الكاملة للحصول على قائمة المقرات وموقع المقر الحالي
    try {
      DocumentSnapshot companyDoc = await _firestore.collection(FirebaseX.deliveryCompaniesCollection).doc(companyId).get();
      if (companyDoc.exists && companyDoc.data() != null) {
        currentCompanyFullData = DeliveryCompanyModel.fromMap(companyDoc.data() as Map<String,dynamic>, companyId);
        final hubData = currentCompanyFullData.hubLocations?.firstWhereOrNull((h) => h['hubId'] == hubId);
        if (hubData != null && hubData['hubLocation'] is GeoPoint) {
          currentHubLocation = hubData['hubLocation'] as GeoPoint;
          currentHubActualName = hubData['hubName'] as String? ?? hubName; // استخدام اسم المقر من البيانات إذا وجد
        } else {
          throw Exception("لم يتم العثور على إحداثيات صالحة للمقر الحالي ($hubId) في بيانات الشركة.");
        }
      } else {
        throw Exception("لم يتم العثور على بيانات الشركة ($companyId).");
      }
    } catch (e,s) {
      debugPrint("[HUB_SUPER_CTRL_CREATE_PKG] Error fetching company/current hub data: $e\n$s");
      Get.snackbar("خطأ تهيئة", "فشل في جلب بيانات الشركة/المقر الحالي: ${e.toString()}", backgroundColor: Colors.red.shade400, duration: Duration(seconds:5));
      isProcessingAction.value = false; return;
    }


    String nextTaskSellerId = hubId; // البائع هو المقر الحالي
    String nextTaskSellerName = "مقر: $currentHubActualName";
    GeoPoint nextTaskPickupLocation = currentHubLocation; // تم التحقق منه أعلاه
    String nextTaskPickupAddressText = "من $nextTaskSellerName (شركة ${currentCompanyFullData.companyName})";

    String nextTaskBuyerId = "";
    String? nextTaskBuyerName = "";
    String? nextTaskBuyerPhoneNumber;
    GeoPoint? nextTaskDeliveryLocation;
    String? nextTaskDeliveryAddressText;
    String? nextTaskFinalBuyerConfirmationBarcode; // هذا سيكون buyerId للمشتري أو hubConfirmationBarcode للمقر الوجهة
    String? nextTaskDestinationHubId; // لمعرفة وجهة مهمة النقل بين المقرات
    String? nextTaskDestinationHubName;
    bool isActuallyHubToHub = transferToAnotherHub; // تحديد نوع المهمة التالية بوضوح

    if (transferToAnotherHub) {
      // ----- اختيار المقر الوجهة لعملية النقل -----
      final List<Map<String, dynamic>> otherHubs = currentCompanyFullData.hubLocations?.where((h) => h['hubId'] != hubId && (h['hubId'] as String).isNotEmpty).toList() ?? [];
      if (otherHubs.isEmpty) {
        Get.snackbar("لا توجد مقرات أخرى", "لا توجد مقرات أخرى متاحة للنقل إليها في هذه الشركة.", backgroundColor: Colors.orange.shade300, duration: Duration(seconds:4));
        isProcessingAction.value = false; return;
      }

      Map<String, dynamic>? destinationHubData = await Get.dialog<Map<String, dynamic>>(
          AlertDialog(
            title: const Text("اختر المقر الوجهة للشحنة"),
            content: SizedBox(width: double.maxFinite, child: ListView.builder(
                itemCount: otherHubs.length, shrinkWrap: true,
                itemBuilder: (c, i) {
                  final h = otherHubs[i];
                  return ListTile(
                      title: Text(h['hubName'] as String? ?? 'مقر غير مسمى'),
                      subtitle: Text(h['hubAddressText'] as String? ?? ''),
                      leading: const Icon(Icons.business_rounded),
                      onTap: () => Get.back(result: h));
                }
            )),
            actions: [TextButton(onPressed: () => Get.back(), child: const Text("إلغاء"))],
          ),
          barrierDismissible: false
      );

      if (destinationHubData == null) { // المستخدم ألغى اختيار المقر الوجهة
        isProcessingAction.value = false; return;
      }

      nextTaskDeliveryLocation = destinationHubData['hubLocation'] as GeoPoint?;
      nextTaskBuyerId = destinationHubData['hubId'] as String; // ID المقر الوجهة هو "المشتري"
      nextTaskBuyerName = destinationHubData['hubName'] as String?;
      nextTaskDeliveryAddressText = destinationHubData['hubAddressText'] as String?;
      nextTaskFinalBuyerConfirmationBarcode = destinationHubData['hubConfirmationBarcode'] as String?; // هذا ما سيمسحه السائق عند الوصول
      nextTaskDestinationHubId = destinationHubData['hubId'] as String;
      nextTaskDestinationHubName = destinationHubData['hubName'] as String?;

      if (nextTaskDeliveryLocation == null || (nextTaskFinalBuyerConfirmationBarcode == null || nextTaskFinalBuyerConfirmationBarcode.isEmpty)) {
        Get.snackbar("بيانات مقر وجهة ناقصة", "المقر الوجهة المختار ليس لديه موقع أو باركود تأكيد صالح.", backgroundColor: Colors.red.shade300, duration: Duration(seconds:4));
        isProcessingAction.value = false; return;
      }

    } else { // توصيل مباشر للميل الأخير (للمشتري)
      final DeliveryTaskModel firstTaskInSelection = selectedTasksForConsolidation.first;
      nextTaskDeliveryLocation = firstTaskInSelection.deliveryLocationGeoPoint;
      nextTaskBuyerId = firstTaskInSelection.buyerId; // buyerId الأصلي
      nextTaskBuyerName = firstTaskInSelection.buyerName;
      nextTaskBuyerPhoneNumber = firstTaskInSelection.buyerPhoneNumber;
      nextTaskDeliveryAddressText = firstTaskInSelection.deliveryAddressText;
      nextTaskFinalBuyerConfirmationBarcode = firstTaskInSelection.buyerId; // باركود المشتري هو buyerId الخاص به
      isActuallyHubToHub = false; // تأكيد أنها ليست نقل
    }

    // --- تجهيز ملخص المنتجات للمهمة الجديدة ---
    List<Map<String, dynamic>> newItemsSummary = [];
    if(isActuallyHubToHub){
      // لمهمة النقل، يمكن أن يكون ملخص بسيط
      newItemsSummary.add({
        'itemName': "شحنة نقل مجمعة (${selectedTasksForConsolidation.length} طلبات أصلية) إلى ${nextTaskDestinationHubName ?? 'مقر آخر'}",
        'quantity': 1,
        'itemBarcode': finalConsolidatedPackageBarcode, // نفس باركود الشحنة الرئيسية
      });
    } else {
      // لمهمة الميل الأخير، نجمع كل itemsSummary من المهام الأصلية
      for (var originalTask in selectedTasksForConsolidation) {
        if (originalTask.itemsSummary != null) {
          for (var item in originalTask.itemsSummary!) {
            // نضيف معرّف الطلب الأصلي للعنصر لتمييزه (اختياري)
            newItemsSummary.add({
              ...item, // كل حقول العنصر الأصلي
              'originalOrderIdForDisplay': originalTask.orderIdShort, // للمساعدة في العرض
            });
          }
        } else { // إذا لم يكن هناك itemsSummary للمهمة الأصلية
          newItemsSummary.add({
            'itemName': "منتجات الطلب ${originalTask.orderIdShort}",
            'quantity': 1, // افترض كمية 1
            'itemBarcode': originalTask.taskId, // استخدم taskId كباركود احتياطي للعنصر
            'originalOrderIdForDisplay': originalTask.orderIdShort,
          });
        }
      }
    }




    // --- 3. تنفيذ المعاملة (Batch Write) ---
    try {
      WriteBatch batch = _firestore.batch();
      String newDeliveryTaskId = _firestore.collection(FirebaseX.deliveryTasksCollection).doc().id;
      List<String> originalTaskIdsInPackage = selectedTasksForConsolidation.map((t) => t.taskId).toList();

      // أ. تحديث حالة المهام الأصلية وربطها بالطرد المجمع
      for (var taskToUpdate in selectedTasksForConsolidation) {
        DocumentReference originalTaskRef = _firestore.collection(FirebaseX.deliveryTasksCollection).doc(taskToUpdate.taskId);
        batch.update(originalTaskRef, {
          'status': 'aggregated_in_hub_TEMP', //  استخدام قيمة مؤقتة، يجب إصلاح Enum
          'consolidatedPackageId_AtHub': consolidatedPackageId, // اسم مختلف للتمييز عن تجميع السائق
          'nextDeliveryLegTaskId': newDeliveryTaskId,
          'updatedAt': FieldValue.serverTimestamp(),
          'taskNotesInternal': FieldValue.arrayUnion([
            "${DateFormat('yy/MM/dd hh:mm a','ar').format(DateTime.now())}: "
                "تم تجميعها في المقر '$currentHubActualName' ضمن الطرد ($consolidatedPackageId). جاهزة للمرحلة التالية (مهمة: $newDeliveryTaskId)."
          ]),
        });
      }

      // ب. إنشاء مهمة التوصيل الجديدة (ميل أخير أو نقل)
      DocumentReference newDeliveryTaskRef = _firestore.collection(FirebaseX.deliveryTasksCollection).doc(newDeliveryTaskId);
      DeliveryTaskModel nextLegTask = DeliveryTaskModel(
        taskId: newDeliveryTaskId,
        orderId: consolidatedPackageId, // هذا هو معرّف هذه الشحنة/الدفعة
        sellerId: nextTaskSellerId,    // هو hubId للمقر الحالي
        sellerName: nextTaskSellerName,
        pickupLocationGeoPoint: nextTaskPickupLocation,
        pickupAddressText: nextTaskPickupAddressText,
        sellerMainPickupConfirmationBarcode: finalConsolidatedPackageBarcode, // مهم للسائق الثاني

        buyerId: nextTaskBuyerId,       // إما buyerId للمشتري أو hubId للمقر الوجهة
        buyerName: nextTaskBuyerName,
        buyerPhoneNumber: nextTaskBuyerPhoneNumber, // يكون null لمهمة النقل
        deliveryLocationGeoPoint: nextTaskDeliveryLocation!,
        deliveryAddressText: nextTaskDeliveryAddressText,
        buyerConfirmationBarcode: nextTaskFinalBuyerConfirmationBarcode, // مهم للسائق الثاني

        itemsSummary: newItemsSummary.isNotEmpty ? newItemsSummary : [{'itemName': 'طرد مجمع', 'quantity':1, 'itemBarcode': finalConsolidatedPackageBarcode}],
        status: DeliveryTaskStatus.pending_driver_assignment, // جاهزة للتعيين
        createdAt: Timestamp.now(),
        assignedCompanyId: companyId,
        isHubToHubTransfer: isActuallyHubToHub,
        originHubName: isActuallyHubToHub ? currentHubActualName : null,
        destinationHubName: nextTaskDestinationHubName, // إذا كانت نقل
        deliveryFee: null, // رسوم هذه المرحلة يمكن تحديدها لاحقًا أو بشكل منفصل
        taskNotesInternal: [
          "تم إنشاؤها في المقر '$currentHubActualName' كـ ${isActuallyHubToHub ? 'مهمة نقل إلى ${nextTaskDestinationHubName ?? 'مقر آخر'}' : 'مهمة ميل أخير للمشتري ${nextTaskBuyerName ?? 'زبون'}'}. "
              "باركود الاستلام من هذا المقر: $finalConsolidatedPackageBarcode."
        ],
      );
      batch.set(newDeliveryTaskRef, nextLegTask.toMap());

      await batch.commit();

      // --- بعد نجاح المعاملة ---
      Get.snackbar("تمت العملية بنجاح!",
          isActuallyHubToHub
              ? "تم إنشاء مهمة نقل الطرد ($consolidatedPackageId) إلى مقر $nextTaskDestinationHubName. الباركود: $finalConsolidatedPackageBarcode"
              : "تم إنشاء مهمة توصيل للطرد ($consolidatedPackageId) للمشتري $nextTaskBuyerName. الباركود: $finalConsolidatedPackageBarcode",
          backgroundColor: Colors.green, colorText: Colors.white, duration: const Duration(seconds: 6), snackPosition: SnackPosition.BOTTOM);

      // "طباعة" الملصق (العرض في حوار كما كان)
      await _printConsolidatedPackageLabel( //  <--- تمت إضافة await هنا أيضًا بما أن _printConsolidatedPackageLabel أصبحت async
          context, // <--- **السياق المُمرر للدالة الرئيسية**
          finalConsolidatedPackageBarcode,
          nextTaskBuyerName ?? "المستلم النهائي/المقر",
          nextTaskBuyerPhoneNumber ?? (isActuallyHubToHub ? "N/A" : "رقم المشتري"),
          selectedTasksForConsolidation.first.province ?? "المحافظة الأصلية",
          nextTaskDeliveryAddressText ?? "العنوان النهائي",
          originalTaskIdsInPackage,
          isActuallyHubToHub ? "وجهة النقل: ${nextTaskDestinationHubName ?? 'مقر آخر'}" : null
      );

      clearConsolidationSelection(); // مسح التحديدات
      // subscribeToTasksAtHub() سيُحدّث قائمة الشحنات في المقر تلقائيًا بسبب تغيير حالة المهام الأصلية.

    } catch (e, s) {
      debugPrint("[HUB_SUPER_CTRL_CREATE_PKG] Error committing batch or during next task setup: $e\n$s");
      Get.snackbar("خطأ في الإنشاء", "فشل إنشاء الطرد/المهمة التالية: ${e.toString()}",
          backgroundColor: Colors.red.shade400, duration: const Duration(seconds: 5), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isProcessingAction.value = false;
    }
  }


  // --- دالة (مثال) "لطباعة" معلومات الملصق للـ Console ---
  void _printConsolidatedPackageLabel1(String packageBarcode, String buyerName, String buyerPhone,
      String buyerProvince, String buyerAddress,      String? transferDestination ,
  List<String> originalOrders) {
    debugPrint("\n--- ملصق الطرد المجمع ---");
    debugPrint("باركود الشحنة: $packageBarcode");
    debugPrint("--------------------------");
    debugPrint("إلى: $buyerName");
    debugPrint("الهاتف: $buyerPhone");
    debugPrint("المحافظة: $buyerProvince");
    debugPrint("العنوان: $buyerAddress");
    debugPrint("--------------------------");
    debugPrint("شركة التوصيل: $companyName - مقر: $hubName");
    debugPrint("يحتوي على الطلبات الأصلية:");
    for (var orderId in originalOrders) {
      debugPrint("- $orderId");
    }

    debugPrint("--------------------------\n");
    String labelContent =
        "--- ملصق شحنة جاهزة للنقل/التسليم ---\n"
        "باركود الشحنة (للسائق التالي): $packageBarcode\n";
    //  هنا يمكنك دمجها مع مكتبة PDF أو طابعة حرارية لإنشاء الملصق الفعلي
    if(transferDestination != null && transferDestination.isNotEmpty){
      labelContent += "وجهة الشحن: $transferDestination\n";
    }
    Get.dialog(
        AlertDialog(
          title: Text("ملصق جاهز للطباعة (مثال)"),
          content: SingleChildScrollView(
              child: SelectableText( // اجعله قابل للتحديد والنسخ
                  "--- ملصق الطرد المجمع ---\n"
                      "باركود الشحنة: $packageBarcode\n"
                      "--------------------------\n"
                      "إلى: $buyerName\n"
                      "الهاتف: $buyerPhone\n"
                      "المحافظة: $buyerProvince\n"
                      "العنوان: $buyerAddress\n"
                      "--------------------------\n"
                      "شركة التوصيل: $companyName - مقر: $hubName\n"
                      "يحتوي على الطلبات الأصلية:\n${originalOrders.join('\n- ')}\n"
                      "--------------------------"
              )
          ),
          actions: [TextButton(onPressed: ()=>Get.back(), child: Text("إغلاق"))],
        )
    );
  }


  @override
  void onClose() {
    _tasksAtHubSubscription?.cancel();

    //  لا يوجد disconnect صريح في print_bluetooth_thermal، لكن من الجيد مسح الحالة
    selectedPrinterDevice.value = null;
    connectionStatus.value = "غير متصل";
    debugPrint("[HUB_SUPER_CTRL] Controller for hub $hubId (Company: $companyId) closed.");
    super.onClose();
  }
}
