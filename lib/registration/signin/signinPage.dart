import 'dart:io';

import 'package:flutter/material.dart';
// import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:get/get.dart';
import '../../XXX/XXXFirebase.dart';
import '../../widget/TextFormFiled.dart';
import 'GetX/Get.dart';
import 'GetX/GetSignIn.dart';

class SignInPage extends StatelessWidget {
  SignInPage({super.key, required this.isFirstTime});




  GlobalKey<FormState> globalKey = GlobalKey<FormState>();
  bool isFirstTime = false;

  TextEditingController Email = TextEditingController();
  TextEditingController Password = TextEditingController();
  bool? remaberMe = true;

  bool isLosing = false;


  @override
  Widget build(BuildContext context) {
    double hi = MediaQuery
        .of(context)
        .size
        .height;
    double wi = MediaQuery
        .of(context)
        .size
        .width;
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(children: [
        Image.asset(
          ImageX.ImageOfSignUp,
          width: wi,
          height: hi,
          fit: BoxFit.cover,
        ),
        SingleChildScrollView(
          child: SafeArea(
            child: Form(
              key: globalKey,
              child: Column(
                children: [
                  SizedBox(
                    height: hi / 15,
                  ),
                  Text(
                    'تسجيل الدخول\n',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: wi / 17,
                        fontWeight: FontWeight.w300),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: const BoxDecoration(color: Colors.transparent),
                    child: Column(
                      children: [
                        TextFormFiled2(
                          hintColor: Colors.white,
                          color1: Colors.black54,
                          fontSize: wi / 22,
                          wight: wi,
                          height: hi / 12,
                          borderRadius: 15,
                          obscure: false,
                          validator: (val) {
                            if (val!.isEmpty) {
                              return 'اكتب ايميل المستخدم';
                            }
                            return null;
                          },
                          label: 'Email',
                          controller: Email,
                        ),
                        SizedBox(
                          height: hi / 70,
                        ),
                        TextFormFiled2(
                          hintColor: Colors.white,
                          color1: Colors.black54,
                          fontSize: wi / 22,
                          wight: wi,
                          height: hi / 12,
                          borderRadius: 15,
                          obscure: true,
                          validator: (val) {
                            if (val!.isEmpty) {
                              return 'اكتب الباسورد';
                            }
                            return null;
                          },
                          label: 'Password',
                          controller: Password,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                GetBuilder<Get1>(
                                    init: Get1(), builder: (logic) {
                                  return Checkbox(
                                    value: remaberMe,
                                    onChanged: (val) {
                                      remaberMe = val;
                                      logic.update();
                                    },
                                    activeColor: Colors.blue,
                                  );
                                }),
                                Text(
                                  'Remember Me',
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontSize: wi / 40,
                                      fontWeight: FontWeight.w700),
                                )
                              ],
                            ),
                            Text(
                              'Forget Passowrd?',
                              style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: wi / 35,
                                  fontWeight: FontWeight.w900),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                  GetBuilder<Getsignin>(
                      init: Getsignin(Email: Email, Password: Password,
                          isFirstTime: isFirstTime), builder: (logic) {
                    return Container(
                      color: Colors.transparent,
                      height: hi / 12,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          logic.signIn(context, globalKey);
                        },
                        child: isLosing
                            ? Center(child: CircularProgressIndicator())
                            : Container(
                          width: wi,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              color: Colors.black54),
                          child: Text(
                            'تسجيل الدخول',
                            style: TextStyle(
                                fontSize: wi / 19,
                                color: Colors.white,
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    );
                  }),
                  SizedBox(
                    height: hi / 8,
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Expanded(child: Divider()),
                        SizedBox(
                          width: wi / 60,
                        ),
                        Text(
                          'او التسجيل مع',
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 24,
                              fontWeight: FontWeight.w600),
                        ),
                        SizedBox(
                          width: wi / 50,
                        ),
                        Expanded(child: Divider())
                      ],
                    ),
                  ),



            SizedBox(
                    height: hi / 30,
                  ),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GetBuilder<Getsignin>(init:Getsignin(isFirstTime: isFirstTime,Password: Password,Email: Email) ,builder: (logic) {
                          return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child:  GestureDetector(
                                onTap: (){
                                  logic.signInWithGoogle(context);
                                },
                                child: Container(
                                  width: wi/5,
                                  height: hi / 12,
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: Colors.black),
                                      borderRadius: BorderRadius.circular(15),
                                      image: DecorationImage(image:
                                      AssetImage('assete/google.png'))
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 1),

                                ),
                              )
                          );
                        }),


                        GetBuilder<Getsignin>(init:Getsignin(isFirstTime: isFirstTime,Password: Password,Email: Email) ,builder: (logic) {
                          return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 0),
                              child:GestureDetector(
                                onTap: (){
                                  // if(Platform.isAndroid){
                                  //   logic.signInWithFacebookForandroid(context);
                                  // }
                                  // if(Platform.isIOS){
                                  //   signInWithFacebookForios(context);
                                  // }
                                },
                                child: Container(
                                  width: wi/5,
                                  height: hi / 12,
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(15),
                                      image: DecorationImage(image:
                                      AssetImage('assete/facebook.png'),
                                          fit: BoxFit.cover)
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 1),

                                ),
                              ));
                        }),





                        //


                        // logic.signInWithYahoo(context);
                        GetBuilder<Getsignin>(init:Getsignin(isFirstTime: isFirstTime,Password: Password,Email: Email) ,builder: (logic) {
                          return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child:GestureDetector(
                                onTap: (){
                                  logic.signInWithMicrosoft(context);

                                },
                                child: Container(
                                  width: wi/5,
                                  height: hi / 12,
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(15),
                                      image: DecorationImage(image:
                                      AssetImage('assete/microsoft.png'),
                                          fit: BoxFit.cover)
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 1),

                                ),
                              ) );
                        }),

                      ],
                    ),),

                  SizedBox(
                    height: hi/40,
                  ),

                  Padding(padding: EdgeInsets.symmetric(horizontal: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GetBuilder<Getsignin>(init:Getsignin(isFirstTime: isFirstTime,Password: Password,Email: Email) ,builder: (logic) {
                        return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child:GestureDetector(
                              onTap: (){
                                logic.signInWithYahoo(context);

                              },
                              child: Container(
                                width: wi/5,
                                height: hi / 12,
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                    image: DecorationImage(image:
                                    AssetImage('assete/yahoo.png'),
                                        fit: BoxFit.cover)
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 1),

                              ),
                            ));
                      }),



                      GetBuilder<Getsignin>(init:Getsignin(isFirstTime: isFirstTime,Password: Password,Email: Email) ,builder: (logic) {
                        return Platform.isIOS ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child:GestureDetector(
                              onTap: (){
                                logic.signInWithApple(context);

                              },
                              child: Container(
                                width: wi/5,
                                height: hi / 12,
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                    image: DecorationImage(image:
                                    AssetImage('assete/apple.png'),
                                        fit: BoxFit.cover)
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 1),

                              ),
                            ) ):Container();
                      }),

                    ],
                  ),)



                ],
              ),
            ),
          ),
        )
      ]),
    );
  }
}
