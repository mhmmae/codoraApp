import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';
import '../../../XXX/XXXFirebase.dart';
import '../../../bottonBar/botonBar.dart';
import '../../../controler/local-notification-onroller.dart';

class Getxbarcode extends GetxController{
  int up=0 ;
  bool isloding = false;

  MobileScannerController? controller;
  Getxbarcode({ this.controller});



  BarCodeScanner(List<Barcode> scannedBarcodes,BuildContext context)async{
    if(up ==0){
     up++;


      final  DeliveryUserisExiste = FirebaseFirestore.instance
        .collection('DeliveryUser').doc(FirebaseAuth.instance.currentUser!.uid).collection('DeliveryUID').doc(scannedBarcodes.first.rawValue);
    DeliveryUserisExiste.get().then((val) async{
      if(val.exists){

        update();
        final uuid =Uuid().v1();

        final DocumentReference<Map<String, dynamic>> order1 = FirebaseFirestore.instance
            .collection('order').doc(scannedBarcodes.first.rawValue);
        final TheOrder = FirebaseFirestore.instance
            .collection('order').doc(scannedBarcodes.first.rawValue).collection('TheOrder').where('uidUser',isEqualTo: scannedBarcodes.first.rawValue);





        final DocumentReference<Map<String, dynamic>> DeliveryUser = FirebaseFirestore.instance
            .collection('DeliveryUser').doc(FirebaseAuth.instance.currentUser!.uid).collection('DeliveryUID').doc(scannedBarcodes.first.rawValue);
        final  theSales = FirebaseFirestore.instance
            .collection('theSales').doc(uuid);




        order1.get().then((order)async{

          await DeliveryUser.get().then((DeliveryUser1)async{
            TheOrder.get().then((QuerySnapshot querySnapshot)async{
              querySnapshot.docs.forEach((doc) async {
                await FirebaseFirestore.instance
                    .collection('theSales').doc(uuid).collection('theSalesItem').doc(doc['uidOfDoc']).set({
                  'isOfer':doc['isOfer'],
                  'number':doc['number'],
                  'uidItem':doc['uidItem'],
                  'uidOfDoc':doc['uidOfDoc'],
                  'uidUser':doc['uidUser'],

                  'appName':FirebaseX.appName,




                });


              });
              await theSales.set({
                'DeliveryUid': DeliveryUser1.get('DeliveryUid'),
                'orderUidUser':DeliveryUser1.get('orderUid'),
                'timeDeliveryOrder':DeliveryUser1.get('timeOrder'),
                'timeOrderDone':DateTime.now(),
                'nmberOfOrder':DeliveryUser1.get('nmberOfOrder'),
                'totalPriceOfOrder':DeliveryUser1.get('totalPriceOfOrder'),
                'latitude':DeliveryUser1.get('latitude'),
                'longitude':DeliveryUser1.get('longitude'),
                'timeOrder':order.get('timeOrder'),
                'uidOfDoc':uuid,
                'appName':FirebaseX.appName,


              });

            }).then((dele)async{
              await  DeliveryUser.delete();
              await  order1.delete();
              await  FirebaseFirestore.instance.collection('order').doc(scannedBarcodes.first.rawValue).collection('TheOrder').get().then((value) {
                for (DocumentSnapshot students in value.docs){
                  students.reference.delete();
                }
              }).then((done)async{
                final DocumentReference<Map<String, dynamic>> user = FirebaseFirestore.instance
                    .collection(FirebaseX.collectionApp).doc(scannedBarcodes.first.rawValue);



                await user.update({

                  FirebaseX.DeliveryUid :'',





                });
                await  FirebaseFirestore.instance.collection(FirebaseX.collectionApp).doc(scannedBarcodes.first.rawValue).get().then((uid)async{
                  await  localNotification.sendNotificationMessageToUser(uid.get('token'), FirebaseX.appName, 'شكرا لاختياركم متجرنا', FirebaseAuth.instance.currentUser!.uid, 'Done', '');
                  await controller?.stop();



                  await  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => bottonBar(theIndex: 2,)),(rute)=>false);
                });




              });
            });

          });






        });






























      }else {

        final order1 = FirebaseFirestore.instance
            .collection('order').doc(scannedBarcodes.first.rawValue);


        final DocumentReference<Map<String, dynamic>> user = FirebaseFirestore.instance
            .collection(FirebaseX.collectionApp).doc(scannedBarcodes.first.rawValue);



        await user.update({

          FirebaseX.DeliveryUid :FirebaseAuth.instance.currentUser!.uid,





        });



        order1.get().then((DocumentSnapshot documentSnapshot)async {
          if (documentSnapshot.exists) {
            await order1.update({
              'Delivery' : true
            }).then((val)async{
              final DocumentReference<Map<String, dynamic>> DeliveryUser = FirebaseFirestore.instance
                  .collection('DeliveryUser').doc(FirebaseAuth.instance.currentUser!.uid).collection('DeliveryUID').doc(documentSnapshot.get('uidUser'));

              await DeliveryUser.set({

                'latitude': documentSnapshot.get('latitude'),
                'longitude': documentSnapshot.get('longitude'),
                'nmberOfOrder':documentSnapshot.get('nmberOfOrder'),
                'totalPriceOfOrder':documentSnapshot.get('totalPriceOfOrder'),
                'DeliveryUid':FirebaseAuth.instance.currentUser!.uid,
                'appName' :FirebaseX.appName,
                // 'uidUser':documentSnapshot.get('uidUser'),
                'orderUid': scannedBarcodes.first.rawValue,
                'timeOrder':DateTime.now()

              }).then((val)async{

                FirebaseFirestore.instance
                    .collection(FirebaseX.collectionApp)
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .get()
                    .then((DocumentSnapshot documentSnapshot) async{
                  await  FirebaseFirestore.instance.collection(FirebaseX.collectionApp).doc(scannedBarcodes.first.rawValue).get().then((uid)async{
                    await  localNotification.sendNotificationMessageToUser(uid.get('token'), FirebaseX.appName, 'طلبك الان في الطريق', FirebaseAuth.instance.currentUser!.uid, 'ScanerBarCode', '');
                  });
                  if (documentSnapshot.exists) {
                    await controller?.stop();




                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => bottonBar(theIndex: 2,)),(rute)=>false);

                  }else{
                    final DocumentReference<Map<String, dynamic>> DeliveryUser1 = FirebaseFirestore.instance
                        .collection('DeliveryUser').doc(FirebaseAuth.instance.currentUser!.uid);







                    await DeliveryUser1.get().then((deliveryUser1)async{
                      if(deliveryUser1.exists){

                        await controller?.stop();




                        await  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => bottonBar(theIndex: 2,)),(rute)=>false);

                      }else {


                        await Geolocator.getCurrentPosition().then((value12)async{
                          print('2222222222222222222222');
                          print(value12.longitude);
                          print(value12.latitude);


                          await DeliveryUser1.set({

                            // 'UidDeliveryUser' :FirebaseAuth.instance.currentUser!.uid,
                            'latitudeDelivery' :value12.latitude.toDouble(),
                            'longitudeDelivery' : value12.longitude.toDouble()



                          });


                          await controller?.stop();




                          await  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => bottonBar(theIndex: 2,)),(rute)=>false);


                        }

                        );



                      }




                    });

                  }
                });





              });

            });



          }

        });

      }
    });



    }else{
      print(up);


      await controller?.stop().then((ca){
        print('camera Stop/////////////////////////////////////////////////');
        print('camera Stop/////////////////////////////////////////////////');
      });



      await  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => bottonBar(theIndex: 2,)),(rute)=>false);

    }
  }
  @override
  void onClose() async{
    print('/////////////////////////////////////////////////////////////////////');
    await controller?.stop();
    await controller?.dispose();

    // TODO: implement onClose
    super.onClose();
  }





}