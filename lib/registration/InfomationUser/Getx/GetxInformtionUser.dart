//
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
// import 'package:image_picker/image_picker.dart';
// // import 'package:image_picker/image_picker.dart';
//
// import '../../phoneNamber/codePhoneNumber.dart';
//
// class Getxinformtionuser extends GetxController{
//   Uint8List? imagesView2;
//   String intrNumber ='+964';
//   TextEditingController phoneN = TextEditingController();
//   GlobalKey<FormState> globalKey = GlobalKey<FormState>();
//   String email;
//   String password;
//   TextEditingController Name = TextEditingController();
//   bool passwordAndEmail;
//
//
//
//   Getxinformtionuser({required this.phoneN,required this.globalKey,required this.email,required this.password,required this.passwordAndEmail,required this.Name});
//
//
//   tackPhoto(ImageSource source) async{
//     final ImagePicker imagePicker =ImagePicker();
//
//     final XFile? image= await imagePicker.pickImage(source: source);
//
//     if(image !=null){
//       return image.readAsBytes();
//     }
//   }
//
//   tackCamera()async{
//     Uint8List img =await tackPhoto(ImageSource.camera);
//       imagesView2 =img;
//     update();
//     }
//   tackGallery()async {
//     Uint8List img =await tackPhoto(ImageSource.gallery);
//       imagesView2= img ;
// update();
//
//   }
//
//   phoneNumberError(BuildContext context){
//     return showDialog(context: context, builder: (context)=>AlertDialog(
//       actions: [
//         IconButton(onPressed: (){
//           Navigator.of(context).pop();
//
//         }, icon: Icon(Icons.close))
//       ],
//       title: Text(' خطاء في رقم الهاتف'),
//       content: Text('الرجاء التاكد من رقم الهاتف'),
//     ));
//   }
//
//   Future<void>? NextPage(BuildContext context)async{
//     try{
//       if(globalKey.currentState!.validate()){
//         final CorrctPhoneNuber = intrNumber + phoneN.text;
//         if(imagesView2 !=null){
//           Navigator.push(context, MaterialPageRoute(builder: (context)=>CodePhonePage(
//             phneNumber: CorrctPhoneNuber,
//             imageUser: imagesView2!,
//             name:Name.text ,
//             email: email,
//             password: password,
//             passwordAndEmail: passwordAndEmail,
//           )));
//
//         }else{
//           return showDialog<void>(barrierDismissible: true,context: context, builder: (BuildContext context){
//             return AlertDialog(
//               actions: [
//                 IconButton(onPressed: (){
//
//                   Navigator.pop(context,true);
//
//                 }, icon: Icon(Icons.close))
//               ],
//               title: Text('قم باختيار الصورة '),
//               content: Text('لم تقم بآختيار صورة '),
//             );});
//
//         }
//       }
//
//
//     }catch(e){}
//     return;
//
//
//   }
//
//
//
// }










import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../../phoneNamber/codePhoneNumber.dart';

class GetxInformationUser extends GetxController {
  // الصورة المختارة من الكاميرا أو المعرض
  Rxn<Uint8List> imagesView2 = Rxn<Uint8List>();

  // رقم الهاتف المدخل والمعلومات الأخرى
  var intrNumber = '+964'.obs; // كود الدولة الافتراضي
  // final TextEditingController phoneController;
  // final TextEditingController nameController;
   // GlobalKey<FormState> formKey;
  // final String email ;
  // final String password;
  final bool passwordAndEmail;

  // لإدارة مؤشر التحميل
  RxBool isLoading = false.obs;

  // الباني (Constructor) لتلقي المدخلات الأولية
  GetxInformationUser({
    // required this.email,
    // required this.password,
    required this.passwordAndEmail,
    // required this.phoneController,
    // required this.nameController,
    // required this.formKey,
  });

  // دالة لضغط الصور لتقليل الحجم
  Future<Uint8List?> compressImage(Uint8List imageData) async {
    try {
      return await FlutterImageCompress.compressWithList(
        imageData,
        quality: 70, // تحديد جودة الصورة المضغوطة
      );
    } catch (e) {
      debugPrint('خطأ أثناء ضغط الصورة: $e');
      return null;
    }
  }

  // دالة مساعدة لاختيار الصورة
  Future<Uint8List?> pickPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);
      if (image != null) {
        Uint8List? originalImage = await image.readAsBytes();
        return await compressImage(originalImage); // ضغط الصورة
      }
    } catch (e) {
      debugPrint('خطأ أثناء اختيار الصورة: $e');
    }
    return null; // إذا لم يتم اختيار صورة
  }

  // دالة لاختيار صورة من الكاميرا
  Future<void> pickFromCamera() async {
    isLoading.value = true;
    imagesView2.value = await pickPhoto(ImageSource.camera);
    isLoading.value = false;
    update(); // إعلام الواجهة بتحديث الحالة
  }

  // دالة لاختيار صورة من المعرض
  Future<void> pickFromGallery() async {
    isLoading.value = true;
    imagesView2.value = await pickPhoto(ImageSource.gallery);
    isLoading.value = false;
    update();
  }

  // دالة للتحقق من صحة رقم الهاتف وإظهار رسالة خطأ
  void showPhoneNumberError(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.close),
          )
        ],
        title: const Text('خطأ في رقم الهاتف'),
        content: const Text('يرجى التأكد من إدخال رقم هاتف صالح.'),
      ),
    );
  }

  // دالة للانتقال إلى الصفحة التالية
  Future<void> goToNextPage(BuildContext context,GlobalKey<FormState> formKey,TextEditingController phoneController,TextEditingController nameController,String email,String password) async {
    try {
      // التحقق من صحة النموذج
      if (formKey.currentState!.validate()) {
        final String correctPhoneNumber = intrNumber.value + phoneController.text;

        // التحقق من اختيار الصورة
        if (imagesView2.value != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CodePhonePage(
                phneNumber: correctPhoneNumber,
                imageUser: imagesView2.value!,
                name: nameController.text,
                email: email,
                password: password,
                passwordAndEmail: passwordAndEmail,
              ),
            ),
          );
        } else {
          // عرض رسالة خطأ إذا لم يتم اختيار صورة
          showDialog(
            barrierDismissible: true,
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                actions: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                    icon: const Icon(Icons.close),
                  )
                ],
                title: const Text('لم يتم اختيار صورة'),
                content: const Text('يرجى اختيار صورة لمتابعة العملية.'),
              );
            },
          );
        }
      }
    } catch (e) {
      debugPrint('خطأ أثناء الانتقال للصفحة التالية: $e');
    }
  }
}