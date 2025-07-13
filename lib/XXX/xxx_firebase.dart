
import 'package:get/get.dart';

class FirebaseX{
  static String deliveryTasksCollection = "delivery_tasks";

  static String collectionSeller = 'Sellercodora';
  static String sellersStoragePath = 'seller_files';
  static String appName ='codora';
  static String collectionApp = 'Usercodora';
  static String DeliveryAppUser ='DeliveryAppUser';

  static String deliveryDriversCollection = "delivery_drivers";
  static String deliveryCompaniesCollection = "delivery_companies";
  static String driverStoragePath = "driver_files";
  static String StorgeApp ='Imagecodora';
  static String DeliveryUid ='DeliveryUidcodora';
  static const String favoritesSubcollection = "favorites"; // اسم المجموعة الفرعية للمفضلة
  static String companyStoragePath = "company_files";
  static String defaultCompanyLogoUrl = "https://firebasestorage.googleapis.com/v0/b/codora-app1.firebasestorage.app/o/codeGroups%2F7504e3b0-0fb4-11f0-b885-c3fae01248e9?alt=media&token=e4ff51c8-c40c-42ab-adc7-5464c20c072f"; // مثال
  // أسماء مجموعات Firestore (توحيد الأسماء)
  static const String itemsCollection = 'Item';     // اسم مجموعة المنتجات
  static const String offersCollection = 'Itemoffer';   // اسم مجموعة العروض
  static const String chosenCollection = 'the-chosen'; // اسم مجموعة السلة المؤقتة
  static const String ordersCollection = 'order';   // اسم مجموعة الطلبات
  static const String usersCollection = 'Usercodora';
  static const String currency = 'د.ع.';
// اسم مجموعة المستخدمين (إذا لزم الأمر)
  // أضف مجموعات أخرى حسب الحاجة

  // unable to read property list from file: /Users/mostafa/AndroidStudioProjects/oscar/ios/Runner/Info.plist:
  // The operation couldn’t be completed. (XCBUtil.PropertyListConversionError error 2.)



  //مهم جدا++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  static String UIDOfWnerApp ='Ous2GpIJvzSLCnduci2ja4r8EhB2';
  static String EmailOfWnerApp ='mhmmae19@gmail.com';
}

class ImageX{
  //الصورة المستخدمة في التسجيل
  static String ImageOfSignUp = 'assets/logo.png';

  static String ImageOfGoogle1 ='assets/imgeGoogle.png';

  static String ImageOfPerson = 'https://firebasestorage.googleapis.com/v0/b/codora-app1.firebasestorage.app/o/codeGroups%2F8931d640-0fb4-11f0-b885-c3fae01248e9?alt=media&token=8186cbe1-2e98-49b6-b941-06ad5bf79325';

  static String ImageApp = 'assets/logo.png';
  static String ImageHome = 'assets/home.png';
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
