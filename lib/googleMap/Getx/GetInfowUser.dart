
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';

import '../../XXX/XXXFirebase.dart';

class getInfowUser extends GetxController{

  String userId;
  String? urlOfUser;
  String? email;
  String? name;
  String? phneNumber;
  String? DeliveryUidOscar1;
  double latitude;
  double longitude;
  String? nameOfContry;
  String? nameOfgovernorate;
  String? Administrative;

  bool isDilveyGetUserInformaion = false;

  
  
  getInfowUser({ required this.userId,  required this.latitude,  required this.longitude});

  void getGeoCoding()async{
    List<Placemark>? placemarks = await placemarkFromCoordinates(latitude, longitude);
      nameOfContry = placemarks.first.country;
      nameOfgovernorate =placemarks.first.locality;
      Administrative = placemarks.first.subAdministrativeArea;

     update();


  }

  @override
  void onInit() {
    FirebaseFirestore.instance
        .collection(FirebaseX.collectionApp)
        .doc(userId)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
       urlOfUser = documentSnapshot.get('url');
       email = documentSnapshot.get('email');
       name = documentSnapshot.get('name');
       phneNumber =documentSnapshot.get('phneNumber');
       DeliveryUidOscar1 = documentSnapshot.get('DeliveryUidOscar1');
       update();

      } else {

      }
    });

   if(longitude !=0 ){
     getGeoCoding();
   }

    // TODO: implement onInit
    super.onInit();
  }

}