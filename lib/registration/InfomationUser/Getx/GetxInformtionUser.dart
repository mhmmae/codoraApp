
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:image_picker/image_picker.dart';

import '../../phoneNamber/codePhoneNumber.dart';

class Getxinformtionuser extends GetxController{
  Uint8List? imagesView2;
  String intrNumber ='+964';
  TextEditingController phoneN = TextEditingController();
  GlobalKey<FormState> globalKey = GlobalKey<FormState>();
  String email;
  String password;
  TextEditingController Name = TextEditingController();
  bool passwordAndEmail;



  Getxinformtionuser({required this.phoneN,required this.globalKey,required this.email,required this.password,required this.passwordAndEmail,required this.Name});


  tackPhoto(ImageSource source) async{
    final ImagePicker imagePicker =ImagePicker();

    final XFile? image= await imagePicker.pickImage(source: source);

    if(image !=null){
      return image.readAsBytes();
    }
  }

  tackCamera()async{
    Uint8List img =await tackPhoto(ImageSource.camera);
      imagesView2 =img;
    update();
    }
  tackGallery()async {
    Uint8List img =await tackPhoto(ImageSource.gallery);
      imagesView2= img ;
update();
  
  }

  phoneNumberError(BuildContext context){
    return showDialog(context: context, builder: (context)=>AlertDialog(
      actions: [
        IconButton(onPressed: (){
          Navigator.of(context).pop();

        }, icon: Icon(Icons.close))
      ],
      title: Text(' خطاء في رقم الهاتف'),
      content: Text('الرجاء التاكد من رقم الهاتف'),
    ));
  }

  Future<void>? NextPage(BuildContext context)async{
    try{
      if(globalKey.currentState!.validate()){
        final CorrctPhoneNuber = intrNumber + phoneN.text;
        if(imagesView2 !=null){
          Navigator.push(context, MaterialPageRoute(builder: (context)=>codePhone(
            phneNumber: CorrctPhoneNuber,
            imageUser: imagesView2!,
            Name:Name.text ,
            Email: email,
            password: password,
            pssworAndEmail: passwordAndEmail,
          )));

        }else{
          return showDialog<void>(barrierDismissible: true,context: context, builder: (BuildContext context){
            return AlertDialog(
              actions: [
                IconButton(onPressed: (){

                  Navigator.pop(context,true);

                }, icon: Icon(Icons.close))
              ],
              title: Text('قم باختيار الصورة '),
              content: Text('لم تقم بآختيار صورة '),
            );});

        }
      }


    }catch(e){}
    return;


  }



}