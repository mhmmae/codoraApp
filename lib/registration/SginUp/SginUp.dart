//
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/widgets.dart';
// import 'package:get/get.dart';
// import '../../XXX/XXXFirebase.dart';
// import '../../widget/TextFormFiled.dart';
// import 'GetSignUp.dart';
//
//
//
//
//
// class SinUp extends StatelessWidget {
//   SinUp({super.key});
//
//   TextEditingController Email = TextEditingController();
//   TextEditingController Password = TextEditingController();
//   GlobalKey<FormState> globalKey = GlobalKey<FormState>();
//   bool isLoding = false;
//
//   @override
//   Widget build(BuildContext context) {
//     double hi = MediaQuery
//         .of(context)
//         .size
//         .height;
//     double wi = MediaQuery
//         .of(context)
//         .size
//         .width;
//     return Scaffold(
//       extendBodyBehindAppBar: true,
//       body: Form(
//         key: globalKey,
//         child: Stack(children: [
//           Image.asset(
//             ImageX.ImageOfSignUp,
//             width: double.infinity,
//             height: double.infinity,
//             fit: BoxFit.cover,
//           ),
//           isLoding
//               ? Center(child: CircularProgressIndicator())
//               : SingleChildScrollView(
//             child: SafeArea(
//               child: Column(
//                 children: [
//                   SizedBox(
//                     height: hi / 15,
//                   ),
//                   Text(
//                     'التسجيل\n',
//                     style: TextStyle(
//                         color: Colors.black,
//                         fontSize: wi / 17,
//                         fontWeight: FontWeight.w300),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 10),
//                     child: Column(children: [
//                       TextFormFiled2(
//                           hintColor: Colors.white,
//                           color1: Colors.black54,
//                           fontSize: wi / 22,
//                           wight: wi,
//                           height: hi / 12,
//                           borderRadius: 20,
//                           obscure: false,
//                           controller: Email,
//                           validator: (val) {
//                             if (val!.isEmpty) {
//                               return 'رجاء آكتب الآيميل';
//                             }
//                             if (!RegExp(
//                                 r"^([a-zA-Z0-9_\-\.]+)@([a-zA-Z0-9_\-\.]+)\.([a-zA-Z]{2,5})$")
//                                 .hasMatch(val)) {
//                               return 'الرجاء اكتب الايميل بشكل صحيح';
//                             }
//                             return null;
//                           },
//                           label: 'Email'),
//                        SizedBox(
//                         height: hi / 70,
//                       ),
//                       TextFormFiled2(
//                           hintColor: Colors.white,
//                           color1: Colors.black54,
//                           fontSize: wi / 22,
//                           wight: double.infinity,
//                           height: hi / 12,
//                           borderRadius: 20,
//                           obscure: true,
//                           controller: Password,
//                           validator: (val) {
//                             if (val!.isEmpty) {
//                               return 'رجاء آكتب الباسود';
//                             }
//                             if (val.length <= 6) {
//                               return 'اجعل الباسورد اقوى';
//                             }
//                             return null;
//                           },
//                           label: 'Password'),
//                     ]),
//                   ),
//                   SizedBox(
//                     height: hi / 5,
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 10),
//                     child: Column(
//                       children: [
//                         GetBuilder<GetSignup>(init: GetSignup(email: Email,
//                             password: Password,
//                           ), builder: (logic) {
//                           return GestureDetector(
//                             onTap: () async {
//                               if (globalKey.currentState!.validate()) {
//                                   logic.signUp(globalKey);
//
//                               }
//                             },
//                             child: Container(
//                               alignment: Alignment.center,
//                               width: wi,
//                               height: hi / 12,
//                               decoration: BoxDecoration(
//                                   color: Colors.white60,
//                                   borderRadius: BorderRadius.circular(16)),
//                               child: Text(
//                                 'التسجيل',
//                                 style: TextStyle(
//                                     fontSize: wi / 19,
//                                     fontWeight: FontWeight.w600),
//                               ),
//                             ),
//                           );
//                         }),
//
//
//
//                       ],
//                     ),
//
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ]),
//       ),
//     );
//   }
// }


































import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../XXX/XXXFirebase.dart';
import '../../widget/TextFormFiled.dart';
import '../signin/GetX/GetSignIn.dart';
import '../signin/signinPage.dart';
import 'GetSignUp.dart';

class SignUpPage extends StatelessWidget {
  SignUpPage({Key? key, required this.isFirstTime}) : super(key: key);

  final bool isFirstTime;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();


  @override
  Widget build(BuildContext context) {
    double hi = MediaQuery.of(context).size.height;
    double wi = MediaQuery.of(context).size.width;
    final signInController = Get.put(SignInController(
      isFirstTime: false,
      emailController: emailController,
      passwordController: passwordController,
    ));

    // حقن الـ GetSignup Controller مرة واحدة بحيث لا يتم إعادة إنشائه في كل مكان
    final GetSignup signUpController = Get.put(
      GetSignup(email: emailController, password: passwordController),
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Form(
        key: formKey,
        child: Stack(
          children: [
            // الخلفية باستخدام صورة تغطي كامل الشاشة
            Image.asset(
              ImageX.ImageOfSignUp,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
            // استخدام Obx لمراقبة حالة التحميل من الـ Controller
            Obx(() {
              if (signUpController.isLoading.value  ) {
                return Center(child: CircularProgressIndicator());
              } else {
                return SingleChildScrollView(
                  child: SafeArea(
                    child: Column(
                      children: [
                        SizedBox(height: hi / 15),
                        Text(
                          'التسجيل\n',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: wi / 17,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Column(
                            children: [
                              // حقل إدخال البريد الإلكتروني
                              TextFormFiled2(
                                hintColor: Colors.white,
                                backgroundColor: Colors.black54,
                                fontSize: wi / 22,
                                width: wi,
                                height: hi / 12,
                                borderRadius: 20,
                                obscure: false,
                                controller: emailController,
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
                                label: 'Email',
                              ),
                              SizedBox(height: hi / 70),
                              // حقل إدخال كلمة المرور
                              TextFormFiled2(
                                hintColor: Colors.white,
                                backgroundColor: Colors.black54,
                                fontSize: wi / 22,
                                width: double.infinity,
                                height: hi / 12,
                                borderRadius: 20,
                                obscure: true,
                                controller: passwordController,
                                validator: (val) {
                                  if (val!.isEmpty) {
                                    return 'رجاء آكتب الباسورد';
                                  }
                                  if (val.length <= 6) {
                                    return 'اجعل الباسورد أقوى';
                                  }
                                  return null;
                                },
                                label: 'Password',
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: hi / 5),
                        // زر التسجيل باستخدام البريد الإلكتروني
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: GestureDetector(
                            onTap: () async {
                              if (formKey.currentState!.validate()) {
                                await signUpController.signUp(formKey);
                              }
                            },
                            child: Container(
                              alignment: Alignment.center,
                              width: wi,
                              height: hi / 12,
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                'التسجيل',
                                style: TextStyle(
                                  fontSize: wi / 19,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: hi / 30),
                        // صف يحتوي على أزرار التسجيل بواسطة وسائل مختلفة (Facebook, Microsoft)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // زر تسجيل الدخول بواسطة Facebook
                              SocialSignInButton(
                                onTap: () {
                                  signInController.signInWithGoogle();
                                },
                                NetworkPath: 'https://firebasestorage.googleapis.com/v0/b/codora-app1.firebasestorage.app/o/codeGroups%2F20965b60-0fb4-11f0-b885-c3fae01248e9?alt=media&token=eef327cd-e429-4e2f-8fd6-8f7ec0f82c42',
                                width: MediaQuery.of(context).size.width / 5,
                                height: MediaQuery.of(context).size.height / 12,
                              ),
                              SocialSignInButton(
                                onTap: () {
                                  if (Platform.isAndroid) {
                                    signInController.signInWithFacebookForAndroid();
                                  } else if (Platform.isIOS) {
                                    signInController.signInWithFacebookForiOS();
                                  }
                                },
                                NetworkPath: 'https://firebasestorage.googleapis.com/v0/b/codora-app1.firebasestorage.app/o/codeGroups%2Fedb06b50-0fb3-11f0-b885-c3fae01248e9?alt=media&token=c3718974-2b33-4c8a-acba-1dc8426d7472',
                                width: MediaQuery.of(context).size.width / 5,
                                height: MediaQuery.of(context).size.height / 12,
                              ),

                              // زر تسجيل الدخول بواسطة Microsoft
                              SocialSignInButton(
                                onTap: () {
                                  signInController.signInWithMicrosoft();
                                },
                               NetworkPath: 'https://firebasestorage.googleapis.com/v0/b/codora-app1.firebasestorage.app/o/codeGroups%2F7f82bdd0-0fb4-11f0-b885-c3fae01248e9?alt=media&token=8ba41ec5-eca8-4c5d-9568-8d34c601dc15',
                                width: MediaQuery.of(context).size.width / 5,
                                height: MediaQuery.of(context).size.height / 12,
                              )

                            ],
                          ),
                        ),
                        SizedBox(height: hi / 40),
                        // صف يحتوي على أزرار التسجيل بواسطة Yahoo وApple
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // زر تسجيل الدخول بواسطة Yahoo
                              SocialSignInButton(
                                onTap: () {
                                  // استدعاء دالة تسجيل الدخول الخاصة بـ Yahoo مثلاً
                                  signInController.signInWithYahoo();
                                },
                                NetworkPath: 'https://firebasestorage.googleapis.com/v0/b/codora-app1.firebasestorage.app/o/codeGroups%2F926492c0-0fb4-11f0-b885-c3fae01248e9?alt=media&token=73bdea88-0910-43d0-a271-4bf22537af23',
                                width: MediaQuery.of(context).size.width / 5,
                                height: MediaQuery.of(context).size.height / 12,
                              ),


                              // زر تسجيل الدخول بواسطة Apple (يظهر فقط على نظام iOS)
                              Platform.isIOS
                                  ? SocialSignInButton(
                                onTap: () {
                                  signInController.signInWithApple();
                                },
                                NetworkPath: 'https://firebasestorage.googleapis.com/v0/b/codora-app1.firebasestorage.app/o/codeGroups%2Fc7682820-0fb3-11f0-b885-c3fae01248e9?alt=media&token=8954cdb1-8d6a-4ebe-bfbf-1d5dc1111ff8',
                                width: MediaQuery.of(context).size.width / 5,
                                height: MediaQuery.of(context).size.height / 12,
                              )
                                  : Container(),
                            ],
                          ),
                        ),
                        // يمكن إضافة عناصر إضافية مثل روابط لسياسة الخصوصية أو تسجيل الدخول عبر وسائل أخرى
                      ],
                    ),
                  ),
                );
              }
            }),
          ],
        ),
      ),
    );
  }
}
