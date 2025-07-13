//
//
//
//
//
//
//
//
//
//
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import '../bottonBar/botonBar.dart';
// import 'Getx/GetXareYouShorMapOrder.dart';
//
// class GoogleMapOrder extends StatelessWidget {
//   final double longitude; // خط الطول
//   final double latitude; // خط العرض
//   final String tokenUser; // رمز المستخدم
//   final Uint8List marker; // صورة العلامة (Marker)
//
//   GoogleMapOrder({
//     super.key,
//     required this.longitude,
//     required this.latitude,
//     required this.marker,
//     required this.tokenUser,
//   });
//
//   GoogleMapController? controller; // التحكم في الخرائط
//
//   @override
//   Widget build(BuildContext context) {
//     double hi = MediaQuery.of(context).size.height; // ارتفاع الشاشة
//     double wi = MediaQuery.of(context).size.width; // عرض الشاشة
//
//     return Scaffold(
//       body: Stack(
//         children: [
//           // عرض خريطة Google
//           GetBuilder<GetxAreYouSureMapOrder>(
//             init: GetxAreYouSureMapOrder(
//               longitude: longitude,
//               latitude: latitude,
//               tokenUser: tokenUser,
//             ),
//             builder: (logic) {
//               List<Marker> markers = [
//                 Marker(
//                   markerId: const MarkerId('1'),
//                   position: LatLng(logic.latitude, logic.longitude),
//                   icon: BitmapDescriptor.bytes(marker),
//                 ),
//               ];
//
//               return logic.isLoading
//                   ? const Center(child: CircularProgressIndicator())
//                   : GoogleMap(
//                 mapType: MapType.hybrid,
//                 markers: markers.toSet(),
//                 onTap: (LatLng position) {
//                   logic.longitude = position.longitude;
//                   logic.latitude = position.latitude;
//                   logic.update();
//                 },
//                 initialCameraPosition: CameraPosition(
//                   target: LatLng(logic.latitude, logic.longitude),
//                   zoom: 17,
//                 ),
//                 onMapCreated: (controller) {
//                   this.controller = controller;
//                 },
//               );
//             },
//           ),
//
//           // زر الرجوع إلى الصفحة الرئيسية
//           Positioned(
//             top: hi / 17,
//             left: wi / 20,
//             child: GestureDetector(
//               onTap: () {
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(builder: (context) => BottomBar(initialIndex: 0)),
//                 );
//               },
//               child: _buildReturnButton(wi, hi),
//             ),
//           ),
//
//           // زر إرسال الطلب
//           GetBuilder<GetxAreYouSureMapOrder>(
//             init: GetxAreYouSureMapOrder(
//               latitude: latitude,
//               longitude: longitude,
//               tokenUser: tokenUser,
//             ),
//             builder: (logic) {
//               return Positioned(
//                 bottom: hi / 30,
//                 left: wi / 20,
//                 right: wi / 20,
//                 child: GestureDetector(
//                   onTap: () {
//                     logic.showConfirmationDialog(
//                       wi / 30, // حجم النص للإلغاء
//                       wi / 25, // حجم النص للإرسال
//                       wi / 27, // حجم العنوان
//                       wi / 30, // حجم النص للمحتوى
//                       wi / 60, // المسافة بين العناصر
//                       context,
//                     );
//                   },
//                   child: _buildSendButton(wi, hi),
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }
//
//   /// زر العودة إلى الصفحة الرئيسية
//   Widget _buildReturnButton(double wi, double hi) {
//     return Container(
//       width: wi / 4,
//       height: hi / 22,
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.black),
//         borderRadius: const BorderRadius.only(
//           topRight: Radius.circular(15),
//           bottomRight: Radius.circular(15),
//           topLeft: Radius.circular(200),
//           bottomLeft: Radius.circular(200),
//         ),
//         color: Colors.red,
//       ),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 10),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Icon(
//               Icons.home,
//               size: wi / 17,
//               color: Colors.white,
//             ),
//             Icon(
//               Icons.arrow_back,
//               size: wi / 13,
//               color: Colors.white,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   /// زر إرسال الطلب
//   Widget _buildSendButton(double wi, double hi) {
//     return Container(
//       width: wi,
//       height: hi / 14,
//       decoration: BoxDecoration(
//         color: Colors.deepPurpleAccent,
//         borderRadius: BorderRadius.circular(15),
//       ),
//       child: Center(
//         child: Text(
//           'ارسال الطلب',
//           style: TextStyle(
//             fontSize: wi / 20,
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),
//     );
//   }
// }






import 'dart:async';
// For Uint8List marker
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo; // Aliased to avoid conflict

import '../bottonBar/botonBar.dart'; // For navigation
import 'Getx/GetXareYouShorMapOrder.dart'; // Ensure this is the correct path

class GoogleMapOrder extends StatefulWidget {
  final double initialLongitude;
  final double initialLatitude;
  final String tokenUser; // Buyer's FCM token
  final Uint8List markerIconBytes;

  const GoogleMapOrder({
    super.key,
    required this.initialLongitude,
    required this.initialLatitude,
    required this.tokenUser,
    required this.markerIconBytes,
  });

  @override
  State<GoogleMapOrder> createState() => _GoogleMapOrderState();
}

class _GoogleMapOrderState extends State<GoogleMapOrder> {
  GoogleMapController? _mapController;
  late GetxAreYouSureMapOrder _mapOrderLogicController; // Controller for order logic

  final RxString _currentAddress = ''.obs;
  final RxBool _isMapLoading = true.obs; // For map tiles loading
  final RxBool _isFetchingLocation = false.obs; // For "My Location" button

  // For address search
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Initialize the order logic controller.
    // It's crucial this is only put once for this screen's lifecycle.
    // If this screen can be pushed multiple times creating new instances, use a unique tag or ensure proper disposal.
    _mapOrderLogicController = Get.put(
      GetxAreYouSureMapOrder(
        latitude: widget.initialLatitude,
        longitude: widget.initialLongitude,
        tokenUser: widget.tokenUser,
      ),
      // Consider using a unique tag if this page might be stacked multiple times:
      // tag: widget.key.toString(), // Example: using the widget's key
    );
    _updateAddressFromLatLng(widget.initialLatitude, widget.initialLongitude);
  }


  Future<void> _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;
    _isMapLoading.value = false;
  }

  Future<void> _updateAddressFromLatLng(double lat, double lng, {bool updateMarker = false}) async {
    if (mounted) {
      _currentAddress.value = "جاري جلب العنوان...";
    }
    try {
      // تم إزالة localeIdentifier من هنا
      List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(lat, lng);

      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        // بناء العنوان. يمكنك تعديل هذا ليتناسب مع تفضيلاتك
        String thoroughfare = p.thoroughfare ?? ''; // اسم الشارع مع رقم المنزل
        String subLocality = p.subLocality ?? '';   // الحي أو المنطقة الفرعية
        String locality = p.locality ?? '';         // المدينة
        String administrativeArea = p.administrativeArea ?? ''; // المحافظة أو الولاية
        String country = p.country ?? '';           // الدولة

        // بناء العنوان بشكل منظم أكثر مع فواصل
        List<String> addressParts = [];
        if (thoroughfare.isNotEmpty) addressParts.add(thoroughfare);
        if (subLocality.isNotEmpty) addressParts.add(subLocality);
        if (locality.isNotEmpty) addressParts.add(locality);
        if (administrativeArea.isNotEmpty) addressParts.add(administrativeArea);
        // if (country.isNotEmpty) addressParts.add(country); // يمكنك إضافة الدولة إذا أردت

        String formattedAddress = addressParts.join(', ');

        if (formattedAddress.isEmpty) {
          _currentAddress.value = "تعذر تحديد العنوان الدقيق";
        } else {
          _currentAddress.value = formattedAddress;
        }

      } else if (mounted) {
        _currentAddress.value = "تعذر تحديد العنوان";
      }
    } catch (e) {
      if (mounted) {
        _currentAddress.value = "خطأ في جلب العنوان";
      }
      debugPrint("Error getting address using geocoding: $e");
    }

    // هذا الجزء يبقى كما هو لتحديث المتحكم الرئيسي إذا لزم الأمر
    if (updateMarker && mounted) {
      _mapOrderLogicController.updateLocation(lat, lng);
    }
  }

  Future<void> _goToMyLocation() async {
    _isFetchingLocation.value = true;
    LocationPermission permission;

    // Check and request permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar("الأذونات مرفوضة", "تم رفض إذن الوصول للموقع.");
        _isFetchingLocation.value = false;
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      Get.snackbar("الأذونات مرفوضة بشكل دائم", "إذن الموقع مرفوض بشكل دائم, لا يمكن طلب الإذن.");
      _isFetchingLocation.value = false;
      // Optionally guide user to app settings
      // openAppSettings();
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15) // Add timeout
      );
      _mapOrderLogicController.updateLocation(position.latitude, position.longitude);
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(position.latitude, position.longitude), zoom: 17),
        ),
      );
      await _updateAddressFromLatLng(position.latitude, position.longitude); // Update address display
    } catch (e) {
      Get.snackbar("خطأ", "فشل في الحصول على الموقع الحالي: ${e.toString()}");
      debugPrint("Error getting current location: $e");
    } finally {
      _isFetchingLocation.value = false;
    }
  }

  Future<void> _searchAndGoToAddress(String addressString) async {
    if (addressString.trim().isEmpty) return;
    _isFetchingLocation.value = true; // Use same loading indicator
    FocusScope.of(context).unfocus(); // Dismiss keyboard

    try {
      List<geo.Location> locations = await geo.locationFromAddress(addressString);
      if (locations.isNotEmpty && mounted) {
        final location = locations.first;
        _mapOrderLogicController.updateLocation(location.latitude, location.longitude);
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(location.latitude, location.longitude), 17),
        );
        await _updateAddressFromLatLng(location.latitude, location.longitude);
        _searchController.clear();
      } else if (mounted) {
        Get.snackbar("لم يتم العثور عليه", "تعذر العثور على العنوان المحدد.", backgroundColor: Colors.orange);
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar("خطأ في البحث", "حدث خطأ أثناء البحث عن العنوان.", backgroundColor: Colors.red);
      }
      debugPrint("Error searching address: $e");
    } finally {
      if(mounted) _isFetchingLocation.value = false;
    }
  }


  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    // IMPORTANT: Dispose the GetX controller if it was 'put' by this widget
    // and is not meant to be persistent or managed by a binding for this route.
    // This depends on your GetX architecture. If this page owns the controller instance.
    // Get.delete<GetxAreYouSureMapOrder>(tag: widget.key.toString()); // If tagged
    Get.delete<GetxAreYouSureMapOrder>(); // If not tagged and only one instance expected
    debugPrint("GoogleMapOrder disposed and GetxAreYouSureMapOrder deleted.");
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('تحديد موقع الطلب'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Consider Get.back() or Navigator.pop(context)
            // If using Get.offAll in _sendOrder, direct navigation might be better
            Get.offAll(()=> BottomBar(initialIndex: 0));
          },
        ),
        backgroundColor: theme.colorScheme.inversePrimary,
      ),
      body: GetBuilder<GetxAreYouSureMapOrder>( // This GetBuilder listens to the controller _put earlier
        // No 'init' here, it uses the one from initState/Get.put
        // id: 'mapUpdater', // if you use specific IDs for updates in controller
        builder: (logic) { // 'logic' is the instance of _mapOrderLogicController
          final currentMarkerPosition = LatLng(logic.latitude, logic.longitude);
          return Stack(
            children: [
              GoogleMap(
                key: const ValueKey('myOrderGoogleMap'), // <-- أضف هذا

                mapType: MapType.hybrid,
                initialCameraPosition: CameraPosition(
                  target: currentMarkerPosition,
                  zoom: 17,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('selected_location'),
                    position: currentMarkerPosition,
                    icon: BitmapDescriptor.fromBytes(widget.markerIconBytes),
                    draggable: true, // Allow dragging marker
                    onDragEnd: (newPosition) {
                      logic.updateLocation(newPosition.latitude, newPosition.longitude);
                      _updateAddressFromLatLng(newPosition.latitude, newPosition.longitude);
                    },
                  )
                },
                onMapCreated: _onMapCreated,
                onTap: (LatLng position) {
                  logic.updateLocation(position.latitude, position.longitude);
                  _updateAddressFromLatLng(position.latitude, position.longitude);
                },
                myLocationButtonEnabled: false, // We have a custom one
                myLocationEnabled: true, // Shows the blue dot for current location
                zoomControlsEnabled: true,
                padding: EdgeInsets.only(bottom: Get.height * 0.15, top: Get.height * 0.1), // Adjust padding for overlays
              ),
              Obx(() {
                if (_isMapLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                return const SizedBox.shrink();
              }),

              // Address Search Bar
              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                          hintText: 'ابحث عن عنوان أو مكان...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(icon: const Icon(Icons.clear), onPressed: (){
                            _searchController.clear();
                            FocusScope.of(context).unfocus();
                          })
                              : null,
                          border: InputBorder.none, // OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20)
                      ),
                      onChanged: (value) {
                        if (_debounce?.isActive ?? false) _debounce!.cancel();
                        _debounce = Timer(const Duration(milliseconds: 700), () {
                          if (value.isNotEmpty) {
                            _searchAndGoToAddress(value);
                          }
                        });
                      },
                      onSubmitted: _searchAndGoToAddress,
                    ),
                  ),
                ),
              ),


              // Address Display and Send Button Area
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16.0).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_pin, color: theme.primaryColor, size: 28),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Obx(() => Text(
                              _currentAddress.value.isEmpty ? "اسحب العلامة أو استخدم البحث لتحديد الموقع" : _currentAddress.value,
                              style: TextStyle(fontSize: Get.width/28),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            )),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Obx(() => ElevatedButton.icon(
                        icon: logic.isLoading.value // Using the controller's global isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2,))
                            : const Icon(Icons.send_rounded),
                        label: Text(logic.isLoading.value ? 'جاري الإرسال...' : 'إرسال الطلب لهذا الموقع'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: theme.colorScheme.onPrimary,
                          minimumSize: Size(Get.width * 0.8, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        onPressed: logic.isLoading.value
                            ? null // Disable button when loading
                            : () {
                          logic.showConfirmationDialog(context); // logic is _mapOrderLogicController
                        },
                      ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: Get.height * 0.18), // Adjust to avoid overlap with bottom sheet
        child: Obx(() => FloatingActionButton.extended(
          onPressed: _isFetchingLocation.value ? null : _goToMyLocation,
          label: _isFetchingLocation.value
              ? const SizedBox(width:18, height:18, child: CircularProgressIndicator(strokeWidth: 2.0, color: Colors.white))
              : const Text('موقعي الحالي'),
          icon: _isFetchingLocation.value ? const SizedBox.shrink() : const Icon(Icons.my_location),
          backgroundColor: theme.colorScheme.secondary,
          foregroundColor: theme.colorScheme.onSecondary,
        )),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}







