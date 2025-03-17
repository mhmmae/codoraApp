
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../addItem/addNewItem/class/getAddManyImage.dart';
import '../bottonBar/botonBar.dart';
import '../Model/ModelItem.dart';
import '../Model/ModelOfferItem.dart';

class FirebaseX{
  static String appName ='codora';
  static String collectionApp = 'Usercodora';
  static String StorgeApp ='Imagecodora';
  static String DeliveryUid ='DeliveryUidcodora';

  // unable to read property list from file: /Users/mostafa/AndroidStudioProjects/oscar/ios/Runner/Info.plist:
  // The operation couldn’t be completed. (XCBUtil.PropertyListConversionError error 2.)



  //مهم جدا++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  static String UIDOfWnerApp ='CkYi1UK0oDOkUHes2vFzkQCFeuZ2';
  static String EmailOfWnerApp ='mhmmae19@gmail.com';
}

class ImageX{
  //الصورة المستخدمة في التسجيل
  static String ImageOfSignUp = 'assete/logo.png';

  static String ImageOfGoogle ='assete/ddd.png';

  static String ImageOfPerson = 'assete/fff.png';

  static String ImageApp = 'assete/ggg.png';
  static String ImageHome = 'assete/sss.png';
  static String ImageAddVodioItem = 'assete/youtube.png';
  static String ImageAddImage = 'assete/menuPickgers.png';



//   الصور المستخدمة في الصفحة الشخصية الخريطة
   static String imageofColok ='asset/colok.png';
   static String imageofdilivery ='asset/dilivery.png';
   static String imageofDiliveryDone ='asset/doneDilivery.png';


}



class Getchosethetypeofitem extends GetxController{


  List<String> TheWher =['all','Phone charger','New Phone','Used phone','Phone cover','Wireless headphones','safsdfsa','fetregreg','tyhrtjhrt','tjtyjuyj'];

  List<String> text =[ 'الكل' ,'  شاحن هاتف'  ,'هاتف جديد' ,'هاتف مستعمل','كفر هاتف','سماعات لاسلكية','سسس',',iuu','cvre','erertert'];


  String? TheChosen;




}

class Getinformationofitem extends GetxController{

  String TheChosen ='' ;
  String TypeItem;
 static bool isSend = false;


  TextEditingController nameOfItem = TextEditingController();
  TextEditingController priceOfItem = TextEditingController();
  TextEditingController descriptionOfItem = TextEditingController();
  TextEditingController rate = TextEditingController();
  TextEditingController oldPrice = TextEditingController();
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseStorage firebaseStorage = FirebaseStorage.instance;
  GlobalKey<FormState> globalKey = GlobalKey<FormState>();

  Uint8List uint8list;

  List<String> TheWher = [
    'Phone charger',
    'New Phone',
    'Used phone',
    'Phone cover',
    'Wireless headphones',
    'safsdfsa',
    'fetregreg',
    'tyhrtjhrt',
    'tjtyjuyj'
  ];

  List<String> text = [
    '  شاحن هاتف',
    'هاتف جديد',
    'هاتف مستعمل',
    'كفر هاتف',
    'سماعات لاسلكية',
    'سسس',
    ',iuu',
    'cvre',
    'erertert'
  ];

  List<Icon> icon = [
    Icon(Icons.phone_android),
    Icon(Icons.phone_android),
    Icon(Icons.phone_android),
    Icon(Icons.headphones),
    Icon(Icons.tab),
    Icon(Icons.javascript),
    Icon(Icons.kayaking),
    Icon(Icons.update),
    Icon(Icons.label_important),
    Icon(Icons.yard),
  ];

  Getinformationofitem({required this.uint8list,required this.TypeItem,required this.descriptionOfItem,
    required this.nameOfItem,required this.oldPrice,required this.priceOfItem,required this.rate,required this.globalKey});

  Future<void> saveData(String videoURL,BuildContext context)async{

    try{



      final uid2 =  Uuid().v4();
      Reference storge =  firebaseStorage.ref(FirebaseX.StorgeApp).child(Uuid().v1());
      UploadTask uploadTask =storge.putData(uint8list);
      TaskSnapshot taskSnapshot =await uploadTask;
      String url =await taskSnapshot.ref.getDownloadURL();
      // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


      if(TypeItem =='Item'){
        if(TheChosen == ''){
          Get.defaultDialog(title:'قم بآختيار نوع الاضافة',cancel: Text('cancel'), );

          // return showDialog<void>(barrierDismissible: true,context: context, builder: (BuildContext context){
          //   return AlertDialog(
          //     actions: [
          //       IconButton(onPressed: (){
          //
          //         Navigator.pop(context,true);
          //
          //       }, icon: Icon(Icons.close))
          //     ],
          //     title: Text('قم بآختيار نوع الاضافة'),
          //
          //   );});

        }else{
          int priceOfItem1= int.parse(priceOfItem.text);
          ModelItem modelItem = ModelItem(uid: uid2, url: url, videoURL: videoURL, descriptionOfItem: descriptionOfItem.text, nameOfItem: nameOfItem.text,
              priceOfItem: priceOfItem1.toInt(), isOfer: false,manyImages:getAddManyImage.manyImageUrls , appName: FirebaseX.appName, typeItem: TheChosen.toString());
          await FirebaseFirestore.instance.collection(TypeItem).doc(uid2).set(modelItem.toMap()).then((value){
            update();
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=>bottonBar(theIndex: 2,)),(route) =>false);
          });

        }

      }

      else{

        int oldPrice1= int.parse(oldPrice.text);
        int priceOfItem1= int.parse(priceOfItem.text);
        int rate1= int.parse(rate.text);
        ModelOfferItem modelOfferItem =ModelOfferItem(appName: FirebaseX.appName, isOfer: true, priceOfItem: priceOfItem1, nameOfItem: nameOfItem.text,
            descriptionOfItem: descriptionOfItem.text,manyImages: getAddManyImage.manyImageUrls, videoURL: videoURL, url: url, uid: uid2, rate: rate1, oldPrice: oldPrice1);

        await FirebaseFirestore.instance.collection(TypeItem).doc(uid2).set(modelOfferItem.toMap()).then((value){

          update();
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=>bottonBar(theIndex: 2,)),(route) =>false);
        });


      }



    }catch(e){print('111111111111111111111111111111111');
    print(e);
    }





  }















}