
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Getstreammapisdilivery extends GetxController {
  GoogleMapController? controller2;

  bool idDilivery;

  double latitude;

  double longitude;

  Getstreammapisdilivery(
      {required this.idDilivery, required this.longitude, required this.latitude,});


  late StreamSubscription<Position> positionStream;


  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {

    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.

    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      positionStream = Geolocator.getPositionStream().listen(
              (Position? position) {
            FirebaseFirestore.instance.collection('DeliveryUser').doc(
                FirebaseAuth.instance.currentUser!.uid).set({
              'latitudeDelivery': position!.latitude,
              'longitudeDelivery': position.longitude,

            });
            controller2?.animateCamera(CameraUpdate.newLatLng(
                longitude.isNaN ? const LatLng(0, 0) : LatLng(
                    position.latitude, position.longitude)));


            latitude = position.latitude;
            longitude = position.longitude;
            update();
          });
    }


    return await Geolocator.getCurrentPosition();
  }

  // ~~~~~~~~~~~~~~~~~~{{{{{{{{{{{{{{{{}}}}}}}}}}}}}{{{{{{{{{{{{{{{{{}{{{{{{{{{{{{{{{{{{{{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // ~~~~~~~~~~~~~~~~~~~~~~~~=========================================================~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // -------------------------------------------------------


  // -------------------------------------------------------


  @override
  void onInit() {
    print('onInit 0====================================================0');


    _determinePosition();


    // TODO: implement onInit
    super.onInit();
  }

  @override
  void onClose() {
    positionStream.cancel();

    controller2!.dispose();

    print('onClose 0====================================================0');

    // TODO: implement onClose
    super.onClose();
  }
}


