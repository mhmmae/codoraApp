import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;

class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final double? initialAccuracy; // دقة الموقع الأولي (إذا كان من GPS)

  const LocationPickerScreen({super.key, this.initialLocation, this.initialAccuracy});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapController;
  late LatLng _currentPickedLocation;
  Marker? _pickedLocationMarker;
  Circle? _accuracyCircle;

  final RxString _currentAddress = 'اسحب العلامة أو انقر لتحديد الموقع'.obs;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _isFetchingAddress = false;

  @override
  void initState() {
    super.initState();
    // إذا لم يتم تمرير موقع أولي، استخدم موقع افتراضي (مثل وسط المدينة أو بلد معين)
    _currentPickedLocation = widget.initialLocation ?? const LatLng(33.3152, 44.3661); // بغداد
    _updateMarkerAndCircle(_currentPickedLocation, accuracy: widget.initialAccuracy);
    if(widget.initialLocation != null) {
      _getAddressFromLatLng(_currentPickedLocation);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    // تحريك الكاميرا إلى الموقع الأولي
    if (widget.initialLocation != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPickedLocation, 16.0),
      );
    }
  }

  Future<void> _getAddressFromLatLng(LatLng location) async {
    if (_isFetchingAddress) return;
    setState(() => _isFetchingAddress = true);
    _currentAddress.value = "جاري جلب العنوان...";
    try {
      List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(location.latitude, location.longitude,);
      if (mounted && placemarks.isNotEmpty) {
        final p = placemarks.first;
        String addr = "${p.street ?? ''} ${p.thoroughfare ?? ''}, ${p.subLocality ?? ''}, ${p.locality ?? ''}, ${p.administrativeArea ?? ''}".trim().replaceAll(RegExp(r'^,+|,+$|,{2,}'), ',');
        if(addr.startsWith(',')) addr = addr.substring(1).trim();
        _currentAddress.value = addr.isNotEmpty ? addr : "تعذر تحديد العنوان الدقيق";
      } else if (mounted) {
        _currentAddress.value = "تعذر تحديد العنوان";
      }
    } catch (e) {
      if (mounted) _currentAddress.value = "خطأ في جلب العنوان";
      debugPrint("Error geocoding in picker: $e");
    } finally {
      if (mounted) setState(() => _isFetchingAddress = false);
    }
  }

  void _updateMarkerAndCircle(LatLng location, {double? accuracy}) {
    setState(() {
      _currentPickedLocation = location;
      _pickedLocationMarker = Marker(
        markerId: const MarkerId('picked_location'),
        position: location,
        draggable: true,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
        onDragEnd: (newPosition) {
          _updateMarkerAndCircle(newPosition); // تحديث الدائرة أيضًا
          _getAddressFromLatLng(newPosition);
        },
      );
      if (accuracy != null && accuracy > 0) {
        _accuracyCircle = Circle(
          circleId: const CircleId('accuracy_circle'),
          center: location,
          radius: accuracy,
          fillColor: Colors.blue.withOpacity(0.15),
          strokeColor: Colors.blue.withOpacity(0.4),
          strokeWidth: 1,
        );
      } else {
        // إذا لم تكن هناك دقة، أو كان التحديد يدويًا، أزل الدائرة أو اجعلها صغيرة جدًا
        _accuracyCircle = null; // أو دائرة شفافة/صغيرة جدًا
      }
    });
  }

  Future<void> _searchAndGoToAddress(String addressString) async {
    if (addressString.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);

    try {
      List<geo.Location> locations = await geo.locationFromAddress(addressString);
      Get.back(); // Close dialog
      if (mounted && locations.isNotEmpty) {
        final location = locations.first;
        final newLatLng = LatLng(location.latitude, location.longitude);
        _updateMarkerAndCircle(newLatLng);
        _getAddressFromLatLng(newLatLng);
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(newLatLng, 16.0));
      } else if (mounted) {
        Get.snackbar("لم يتم العثور عليه", "تعذر العثور على العنوان المحدد.", backgroundColor: Colors.orange);
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back(); // Close dialog on error too
      if (mounted) Get.snackbar("خطأ في البحث", "حدث خطأ أثناء البحث عن العنوان.", backgroundColor: Colors.red);
      debugPrint("Error searching address in picker: $e");
    }
  }

  Future<void> _goToMyLocation() async {
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    LocationPermission permission;
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    Get.back(); // Close dialog

    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      Get.snackbar("الأذونات مرفوضة", "إذن الوصول للموقع مطلوب لاستخدام هذه الميزة.");
      return;
    }

    try {
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15));
      Get.back(); // Close dialog

      final currentLatLng = LatLng(position.latitude, position.longitude);
      _updateMarkerAndCircle(currentLatLng, accuracy: position.accuracy);
      _getAddressFromLatLng(currentLatLng);
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(currentLatLng, 16.0));
    } catch (e) {
      if(Get.isDialogOpen ?? false ) Get.back();
      Get.snackbar("خطأ", "فشل في الحصول على الموقع الحالي: ${e.toString()}", duration: Duration(seconds: 4));
    }
  }


  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("تحديد موقع المحل"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            tooltip: "تأكيد الموقع",
            onPressed: () {
              // إرجاع الموقع المختار
              Get.back(result: _currentPickedLocation);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _currentPickedLocation,
              zoom: 15.0,
            ),
            markers: _pickedLocationMarker != null ? {_pickedLocationMarker!} : {},
            circles: _accuracyCircle != null ? {_accuracyCircle!} : {},
            onTap: (position) {
              _updateMarkerAndCircle(position); // تحديث الدائرة أيضًا عند النقر
              _getAddressFromLatLng(position);
            },
            myLocationEnabled: true, // يعرض نقطة الموقع الحالية للجهاز
            myLocationButtonEnabled: false, // لأن لدينا زر مخصص
            mapType: MapType.normal,
            zoomControlsEnabled: true,
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.12, top: 65),
          ),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'ابحث عن عنوان أو مكان...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear), onPressed: (){
                    _searchController.clear();
                    FocusScope.of(context).unfocus();
                  })
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                ),
                onChanged: (value) {
                  if (_debounce?.isActive ?? false) _debounce!.cancel();
                  _debounce = Timer(const Duration(milliseconds: 900), () {
                    if (value.length > 2) { // ابدأ البحث بعد 3 حروف مثلاً
                      _searchAndGoToAddress(value);
                    }
                  });
                },
                onSubmitted: _searchAndGoToAddress, // البحث عند الضغط على زر الإدخال
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12).copyWith(bottom: MediaQuery.of(context).padding.bottom + 12),
              decoration: BoxDecoration(
                color: theme.cardColor.withOpacity(0.95),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0,-4))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(() => Text(
                    _currentAddress.value,
                    style: Get.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  ),
                  if(_isFetchingAddress) const Padding(
                    padding: EdgeInsets.only(top: 4.0),
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_rounded),
                    label: const Text("تأكيد هذا الموقع"),
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    onPressed: () {
                      Get.back(result: _currentPickedLocation);
                    },
                  )
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0), // تعديل ليناسب ورقة المعلومات السفلية
        child: FloatingActionButton(
          onPressed: _goToMyLocation,
          tooltip: 'موقعي الحالي',
          child: const Icon(Icons.my_location_sharp),
        ),
      ),
    );
  }
}