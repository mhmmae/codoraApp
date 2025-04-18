
import 'package:get/get.dart';

class FirebaseX{
  static String appName ='codora';
  static String collectionApp = 'Usercodora';
  static String StorgeApp ='Imagecodora';
  static String DeliveryUid ='DeliveryUidcodora';

  // unable to read property list from file: /Users/mostafa/AndroidStudioProjects/oscar/ios/Runner/Info.plist:
  // The operation couldn’t be completed. (XCBUtil.PropertyListConversionError error 2.)



  //مهم جدا++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  static String UIDOfWnerApp ='tqTswRuzXXWEGBEKQMODVeANT572';
  static String EmailOfWnerApp ='mhmmae19@gmail.com';
}

class ImageX{
  //الصورة المستخدمة في التسجيل
  static String ImageOfSignUp = 'assete/logo.png';

  static String ImageOfGoogle1 ='assete/imgeGoogle.png';

  static String ImageOfPerson = 'https://firebasestorage.googleapis.com/v0/b/codora-app1.firebasestorage.app/o/codeGroups%2F8931d640-0fb4-11f0-b885-c3fae01248e9?alt=media&token=8186cbe1-2e98-49b6-b941-06ad5bf79325';

  static String ImageApp = 'assete/logo.png';
  static String ImageHome = 'assete/home.png';
  static String ImageAddVodioItem = 'https://firebasestorage.googleapis.com/v0/b/codora-app1.firebasestorage.app/o/codeGroups%2F9b4b5220-0fb4-11f0-b885-c3fae01248e9?alt=media&token=37af57f7-a294-4dea-8e0a-980fbe9e33e8';
  static String ImageAddImage = 'https://firebasestorage.googleapis.com/v0/b/codora-app1.firebasestorage.app/o/codeGroups%2F6307f080-0fb4-11f0-b885-c3fae01248e9?alt=media&token=5b2dc783-40e4-4796-b64a-a2d51bceadce';



//   الصور المستخدمة في الصفحة الشخصية الخريطة
   static String imageofColok ='https://firebasestorage.googleapis.com/v0/b/codora-app1.firebasestorage.app/o/codeGroups%2Fa94eed10-0fb3-11f0-b885-c3fae01248e9?alt=media&token=31493955-a7f8-413e-951f-2c2c49cf3ec0';
   static String imageofdilivery ='https://firebasestorage.googleapis.com/v0/b/codora-app1.firebasestorage.app/o/codeGroups%2F329fd1b0-0fb4-11f0-b885-c3fae01248e9?alt=media&token=bc3dc8b8-b84e-48b2-8b41-518ada08a0b7';
   static String imageofDiliveryDone ='https://firebasestorage.googleapis.com/v0/b/codora-app1.firebasestorage.app/o/codeGroups%2Fe3c6bae0-0fb3-11f0-b885-c3fae01248e9?alt=media&token=ef65ec2f-eac5-48a0-8205-254e63fa74cb';


}



class Getchosethetypeofitem extends GetxController{


  List<String> TheWher =['all','Phone charger','New Phone','Used phone','Phone cover','Wireless headphones','safsdfsa','fetregreg','tyhrtjhrt','tjtyjuyj'];

  List<String> text =[ 'الكل' ,'  شاحن هاتف'  ,'هاتف جديد' ,'هاتف مستعمل','كفر هاتف','سماعات لاسلكية','سسس',',iuu','cvre','erertert'];


  String? TheChosen;




}

// class Getinformationofitem extends GetxController{
//
//   String TheChosen ='' ;
//   String TypeItem;
//  static bool isSend = false;
//
//
//   TextEditingController nameOfItem = TextEditingController();
//   TextEditingController priceOfItem = TextEditingController();
//   TextEditingController descriptionOfItem = TextEditingController();
//   TextEditingController rate = TextEditingController();
//   TextEditingController oldPrice = TextEditingController();
//   FirebaseFirestore firestore = FirebaseFirestore.instance;
//   FirebaseStorage firebaseStorage = FirebaseStorage.instance;
//   GlobalKey<FormState> globalKey = GlobalKey<FormState>();
//
//   Uint8List uint8list;
//
//   List<String> TheWher = [
//     'Phone charger',
//     'New Phone',
//     'Used phone',
//     'Phone cover',
//     'Wireless headphones',
//     'safsdfsa',
//     'fetregreg',
//     'tyhrtjhrt',
//     'tjtyjuyj'
//   ];
//
//   List<String> text = [
//     '  شاحن هاتف',
//     'هاتف جديد',
//     'هاتف مستعمل',
//     'كفر هاتف',
//     'سماعات لاسلكية',
//     'سسس',
//     ',iuu',
//     'cvre',
//     'erertert'
//   ];
//
//   List<Icon> icon = [
//     Icon(Icons.phone_android),
//     Icon(Icons.phone_android),
//     Icon(Icons.phone_android),
//     Icon(Icons.headphones),
//     Icon(Icons.tab),
//     Icon(Icons.javascript),
//     Icon(Icons.kayaking),
//     Icon(Icons.update),
//     Icon(Icons.label_important),
//     Icon(Icons.yard),
//   ];

//   Getinformationofitem({required this.uint8list,required this.TypeItem,required this.descriptionOfItem,
//     required this.nameOfItem,required this.oldPrice,required this.priceOfItem,required this.rate,required this.globalKey});
//
//   Future<void> saveData(String videoURL,BuildContext context)async{
//
//     try{
//
//
//
//       final uid2 =  Uuid().v4();
//       Reference storge =  firebaseStorage.ref(FirebaseX.StorgeApp).child(Uuid().v1());
//       UploadTask uploadTask =storge.putData(uint8list);
//       TaskSnapshot taskSnapshot =await uploadTask;
//       String url =await taskSnapshot.ref.getDownloadURL();
//       // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//
//
//       if(TypeItem =='Item'){
//         if(TheChosen == ''){
//           Get.defaultDialog(title:'قم بآختيار نوع الاضافة',cancel: Text('cancel'), );
//
//           // return showDialog<void>(barrierDismissible: true,context: context, builder: (BuildContext context){
//           //   return AlertDialog(
//           //     actions: [
//           //       IconButton(onPressed: (){
//           //
//           //         Navigator.pop(context,true);
//           //
//           //       }, icon: Icon(Icons.close))
//           //     ],
//           //     title: Text('قم بآختيار نوع الاضافة'),
//           //
//           //   );});
//
//         }else{
//           int priceOfItem1= int.parse(priceOfItem.text);
//           ModelItem modelItem = ModelItem(uid: uid2, url: url, videoURL: videoURL, descriptionOfItem: descriptionOfItem.text, nameOfItem: nameOfItem.text,
//               priceOfItem: priceOfItem1.toInt(), isOfer: false,manyImages:getAddManyImage.manyImageUrls , appName: FirebaseX.appName, typeItem: TheChosen.toString());
//           await FirebaseFirestore.instance.collection(TypeItem).doc(uid2).set(modelItem.toMap()).then((value){
//             update();
//             Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=>bottonBar(theIndex: 2,)),(route) =>false);
//           });
//
//         }
//
//       }
//
//       else{
//
//         int oldPrice1= int.parse(oldPrice.text);
//         int priceOfItem1= int.parse(priceOfItem.text);
//         int rate1= int.parse(rate.text);
//         ModelOfferItem modelOfferItem =ModelOfferItem(appName: FirebaseX.appName, isOfer: true, priceOfItem: priceOfItem1, nameOfItem: nameOfItem.text,
//             descriptionOfItem: descriptionOfItem.text,manyImages: getAddManyImage.manyImageUrls, videoURL: videoURL, url: url, uid: uid2, rate: rate1, oldPrice: oldPrice1);
//
//         await FirebaseFirestore.instance.collection(TypeItem).doc(uid2).set(modelOfferItem.toMap()).then((value){
//
//           update();
//           Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=>bottonBar(theIndex: 2,)),(route) =>false);
//         });
//
//
//       }
//
//
//
//     }catch(e){print('111111111111111111111111111111111');
//     print(e);
//     }
//
//
//
//
//
//   }
//
//
// }