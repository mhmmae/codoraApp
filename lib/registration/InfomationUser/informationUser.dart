import 'package:flutter/material.dart';
import 'package:get/get.dart';
// import 'package:image_picker/image_picker.dart';

import '../../XXX/XXXFirebase.dart';
import '../../widget/TextFormFiled.dart';
import 'Getx/GetxInformtionUser.dart';

class InformationUser extends StatelessWidget {
  InformationUser(
      {super.key, required this.email, required this.password, required this.passwordAndEmail});

  bool passwordAndEmail;
  String email;
  String password;
  TextEditingController phoneN = TextEditingController();
  TextEditingController Name = TextEditingController();
  GlobalKey<FormState> globalKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    double hi = MediaQuery.of(context).size.height;
    double wi = MediaQuery.of(context).size.width;
    return Scaffold(
        body: Form(
          key: globalKey,
          child: Stack(
            children: [
            Image.asset(ImageX.ImageOfSignUp,
            width: wi,
            height: hi,
            fit: BoxFit.cover,),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: SingleChildScrollView(
                child: SafeArea(child: Column(children: [
                  SizedBox(height: hi / 13,),
                  GestureDetector(
                      onTap: () {
                        showModalBottomSheet(context: context,
                            builder: (BuildContext context) {
                              return SizedBox(width: wi,
                                height: hi / 4,
                                child: Column(
                                  children: [
                                    GetBuilder<Getxinformtionuser>(
                                        init: Getxinformtionuser(
                                            password: password,
                                            passwordAndEmail: passwordAndEmail,
                                            phoneN: phoneN,
                                            email: email,
                                            globalKey: globalKey,
                                            Name: Name),
                                        builder: (logic) {
                                          return ListTile(
                                              leading: Icon(Icons.camera),
                                              title: Text('كامرة'),
                                              onTap: () {
                                                logic.tackCamera();
                                              }
                                          );
                                        }),
                                    Divider(),
                                    GetBuilder<Getxinformtionuser>(
                                        init: Getxinformtionuser(
                                            password: password,
                                            passwordAndEmail: passwordAndEmail,
                                            phoneN: phoneN,
                                            email: email,
                                            globalKey: globalKey,
                                            Name: Name),
                                        builder: (logic) {
                                          return ListTile(
                                              leading: Icon(Icons.photo),
                                              title: Text('المحفوظة'),
                                              onTap: () {
                                                logic.tackGallery();
                                              }
                                          );
                                        })
                                  ],
                                ),
                              );
                            });
                      },
                      child: GetBuilder<Getxinformtionuser>(
                          init: Getxinformtionuser(
                              password: password,
                              passwordAndEmail: passwordAndEmail,
                              phoneN: phoneN,
                              email: email,
                              globalKey: globalKey,
                              Name: Name),builder: (logic) {
                  return Container(
                  width: wi / 2.75, height: hi / 5.5,
                  decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  image: logic.imagesView2 == null ? DecorationImage(
                  image: AssetImage(ImageX.ImageOfPerson))
                      : DecorationImage(
                  image: MemoryImage(logic.imagesView2!),
                  fit: BoxFit.cover)

                  ),
                  child: Stack(
                  children: [


                  Positioned(right: 0, bottom: 0,child: Icon(Icons.camera_alt,
                  color: Colors.indigoAccent,),)
                  ],

                  ),
                  );
                  }),
                ),
                SizedBox(height: hi / 30,),

                TextFormFiled2(
                    fontSize: wi / 22,
                    validator: (val) {
                      if (val!.isEmpty) {
                        return 'الرجاء اكتب الاسم';
                      } else if (val.length < 5) {
                        return 'الاسم قصير';
                      }
                      return null;
                    },
                    controller: Name,
                    borderRadius: 15,
                    label: 'الآسم',
                    obscure: false,
                    wight: wi,
                    height: hi / 12),


                SizedBox(height: hi / 50,),

                Container(
                  alignment: Alignment.center,
                  width: wi,
                  height: hi / 12,
                  padding: const EdgeInsets.symmetric(horizontal: 5),

                  decoration: BoxDecoration(
                      color: Colors.white70,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.black87)
                  ),

                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(


                        ),

                        width: wi / 6,
                        height: hi / 20,
                        child: GetBuilder<Getxinformtionuser>(
                            init: Getxinformtionuser(
                                password: password,
                                passwordAndEmail: passwordAndEmail,
                                phoneN: phoneN,
                                email: email,
                                globalKey: globalKey,
                                Name: Name), builder: (logic) {
                          return Text(
                            logic.intrNumber, style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: wi / 22),
                          );
                        }),
                      ),

                      Expanded(
                        child: GetBuilder<Getxinformtionuser>(
                            init: Getxinformtionuser(
                                password: password,
                                passwordAndEmail: passwordAndEmail,
                                phoneN: phoneN,
                                email: email,
                                globalKey: globalKey,
                                Name: Name), builder: (logic) {
                          return TextFormField(

                            keyboardType: TextInputType.number,
                            obscureText: false,


                            controller: phoneN,
                            validator: (val) {
                              if (val!.length > 10) {
                                return logic.phoneNumberError(context);
                              } else if (val.length < 10) {
                                return logic.phoneNumberError(context);
                              }
                              return null;
                            },

                            decoration: InputDecoration(

                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        15),
                                    borderSide: BorderSide.none
                                ),


                                hintText: 'رقم الهاتف',


                                hintStyle: TextStyle(fontSize: wi / 22,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w800)
                            ),


                          );
                        }),
                      ),
                    ],
                  ),

                ),
                SizedBox(height: hi / 3.5,),
                GetBuilder<Getxinformtionuser>(init: Getxinformtionuser(
                    password: password,
                    passwordAndEmail: passwordAndEmail,
                    phoneN: phoneN,
                    email: email,
                    globalKey: globalKey,
                    Name: Name),builder: (logic) {
                  return GestureDetector(
                    onTap: () async {
                      logic.NextPage(context);
                    },
                    child: Container(
                      width: wi,
                      height: hi / 12,
                      decoration: BoxDecoration(
                          color: Colors.white60,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black)
                      ),
                      child: Center(
                        child: Text(
                          'التالي', style: TextStyle(fontSize: wi / 22),),
                      ),
                    ),
                  );
                })
                ],
              )

          ),
        )),

    ]
    )
    ,
    )
    );
  }
}
