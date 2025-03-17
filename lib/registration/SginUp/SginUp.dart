
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../XXX/XXXFirebase.dart';
import '../../widget/TextFormFiled.dart';
import 'GetSignUp.dart';
import 'dart:io';

// import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';




class SinUp extends StatelessWidget {
  SinUp({super.key});

  TextEditingController Email = TextEditingController();
  TextEditingController Password = TextEditingController();
  GlobalKey<FormState> globalKey = GlobalKey<FormState>();
  bool isLoding = false;

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
      body: Form(
        key: globalKey,
        child: Stack(children: [
          Image.asset(
            ImageX.ImageOfSignUp,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
          isLoding
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
            child: SafeArea(
              child: Column(
                children: [
                  SizedBox(
                    height: hi / 15,
                  ),
                  Text(
                    'التسجيل\n',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: wi / 17,
                        fontWeight: FontWeight.w300),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(children: [
                      TextFormFiled2(
                          hintColor: Colors.white,
                          color1: Colors.black54,
                          fontSize: wi / 22,
                          wight: wi,
                          height: hi / 12,
                          borderRadius: 20,
                          obscure: false,
                          controller: Email,
                          validator: (val) {
                            if (val!.isEmpty) {
                              return 'رجاء آكتب الآيميل';
                            }
                            if (!RegExp(
                                r"^([a-zA-Z0-9_\-\.]+)@([a-zA-Z0-9_\-\.]+)\.([a-zA-Z]{2,5})$")
                                .hasMatch(val)) {
                              return 'الرجاء اكتب الايميل بشكل صحيح';
                            }
                            return null;
                          },
                          label: 'Email'),
                       SizedBox(
                        height: hi / 70,
                      ),
                      TextFormFiled2(
                          hintColor: Colors.white,
                          color1: Colors.black54,
                          fontSize: wi / 22,
                          wight: double.infinity,
                          height: hi / 12,
                          borderRadius: 20,
                          obscure: true,
                          controller: Password,
                          validator: (val) {
                            if (val!.isEmpty) {
                              return 'رجاء آكتب الباسود';
                            }
                            if (val.length <= 6) {
                              return 'اجعل الباسورد اقوى';
                            }
                            return null;
                          },
                          label: 'Password'),
                    ]),
                  ),
                  SizedBox(
                    height: hi / 5,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      children: [
                        GetBuilder<Getsignup>(init: Getsignup(email: Email,
                            password: Password,
                          ), builder: (logic) {
                          return GestureDetector(
                            onTap: () async {
                              if (globalKey.currentState!.validate()) {
                                  logic.SignUp(context,globalKey);

                              }
                            },
                            child: Container(
                              alignment: Alignment.center,
                              width: wi,
                              height: hi / 12,
                              decoration: BoxDecoration(
                                  color: Colors.white60,
                                  borderRadius: BorderRadius.circular(16)),
                              child: Text(
                                'التسجيل',
                                style: TextStyle(
                                    fontSize: wi / 19,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          );
                        }),



                      ],
                    ),

                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
