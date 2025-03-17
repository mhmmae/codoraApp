
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../../../XXX/XXXFirebase.dart';
import '../../../googleMap/googleMap.dart';
import 'dart:ui' as ui;

class Getgotomapdilyvery extends GetxController{

  int NumberOfMap = 0;
  bool isloding = false;


  late  StreamSubscription<Position> positionStream;
  Uint8List? markerDelivery;
  Uint8List? markerUser;
  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }
  IconMarckt() async {
     isloding = true;

    final Uint8List markerDelivery1 = await getBytesFromAsset(ImageX.ImageApp, 60);
    final Uint8List markerUser1 = await getBytesFromAsset(ImageX.ImageHome, 60);
    update();
    markerDelivery = markerDelivery1;
    markerUser =markerUser1;



  }
  send()async{
     isloding = true;
     update();
    double longitude2=0;
    double latitude2 =0;



    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {


    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {

      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.

    }

    if(permission == LocationPermission.whileInUse || permission == LocationPermission.always) {


      await Geolocator.getCurrentPosition().then((value){


      update();
          latitude2 =value.latitude;
          longitude2= value.longitude;





      });

     Get.to(googleMap(idDilivery: true,latitude: latitude2,longitude: longitude2,markerUser: markerUser,markerDelivery: markerDelivery,));






    }


    return   await Geolocator.getCurrentPosition();








  }


  @override
  void onInit() {
    FirebaseFirestore.instance
        .collection('DeliveryUser').doc(FirebaseAuth.instance.currentUser!.uid).collection('DeliveryUID')
        .get()
        .then((QuerySnapshot querySnapshot) {
      for (var doc in querySnapshot.docs) {
        NumberOfMap = querySnapshot.docs.length;

        print('333333333333333333311331211');
        print(querySnapshot.docs.length);
        print(NumberOfMap);
        update();
      }
    });
    // TODO: implement onInit
    super.onInit();
  }
}