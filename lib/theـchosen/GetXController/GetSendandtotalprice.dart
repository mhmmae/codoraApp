

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'dart:ui' as ui;


import '../../XXX/XXXFirebase.dart';
import '../../googleMap/GoogleMapOrder.dart';

class Getsendandtotalprice extends GetxController {
  String uid;
  bool isLoding = false;
  Getsendandtotalprice({ required this.uid});
  late StreamSubscription<Position> positionStream;

  Uint8List? markerUser;
  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }
  IconMarckt() async {





  }



  send()async{
    isLoding = false;
    update();
    final Uint8List markerUser1 = await getBytesFromAsset(ImageX.ImageHome, 60);
    update();
    markerUser =markerUser1;

    await  FirebaseFirestore.instance
        .collection('the-chosen').doc(FirebaseAuth.instance.currentUser!.uid).collection(FirebaseX.appName)
        // .where('uidUser',isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .get().then((val)async{
          if(val.docs.isNotEmpty){
            double? longitude2;
            double? latitude2;



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
              
             await FirebaseFirestore.instance.collection(FirebaseX.collectionApp).doc(uid).get().then((token)async{
               await Geolocator.getCurrentPosition().then((value){








                 latitude2 =value.latitude;
                 longitude2= value.longitude;

                 update();

                 Get.to(()=> GoogleMapOrder(longitude: longitude2!,latitude: latitude2!,marker: markerUser!,tokenUser: token.get('token'), ));




               });
               
                
              });


             





            }



            return   await Geolocator.getCurrentPosition();



          }else{
            Get.defaultDialog(title: '',
            middleText:  'قم بآختيار منتج اولا ',
            textCancel: 'رجوع',);
          }
    });


  }

}

