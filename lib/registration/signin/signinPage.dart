// import 'dart:io';
//
// import 'package:flutter/material.dart';
// // import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
// import 'package:get/get.dart';
// import '../../XXX/XXXFirebase.dart';
// import '../../widget/TextFormFiled.dart';
// import 'GetX/Get.dart';
// import 'GetX/GetSignIn.dart';
//
// class SignInPage extends StatelessWidget {
//   SignInPage({super.key, required this.isFirstTime});
//
//
//
//
//   GlobalKey<FormState> globalKey = GlobalKey<FormState>();
//   bool isFirstTime = false;
//
//   TextEditingController Email = TextEditingController();
//   TextEditingController Password = TextEditingController();
//   bool? remaberMe = true;
//
//   bool isLosing = false;
//
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
//       body: Stack(children: [
//         Image.asset(
//           ImageX.ImageOfSignUp,
//           width: wi,
//           height: hi,
//           fit: BoxFit.cover,
//         ),
//         SingleChildScrollView(
//           child: SafeArea(
//             child: Form(
//               key: globalKey,
//               child: Column(
//                 children: [
//                   SizedBox(
//                     height: hi / 15,
//                   ),
//                   Text(
//                     'تسجيل الدخول\n',
//                     style: TextStyle(
//                         color: Colors.black,
//                         fontSize: wi / 17,
//                         fontWeight: FontWeight.w300),
//                   ),
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 10),
//                     decoration: const BoxDecoration(color: Colors.transparent),
//                     child: Column(
//                       children: [
//                         TextFormFiled2(
//                           hintColor: Colors.white,
//                           color1: Colors.black54,
//                           fontSize: wi / 22,
//                           wight: wi,
//                           height: hi / 12,
//                           borderRadius: 15,
//                           obscure: false,
//                           validator: (val) {
//                             if (val!.isEmpty) {
//                               return 'اكتب ايميل المستخدم';
//                             }
//                             return null;
//                           },
//                           label: 'Email',
//                           controller: Email,
//                         ),
//                         SizedBox(
//                           height: hi / 70,
//                         ),
//                         TextFormFiled2(
//                           hintColor: Colors.white,
//                           color1: Colors.black54,
//                           fontSize: wi / 22,
//                           wight: wi,
//                           height: hi / 12,
//                           borderRadius: 15,
//                           obscure: true,
//                           validator: (val) {
//                             if (val!.isEmpty) {
//                               return 'اكتب الباسورد';
//                             }
//                             return null;
//                           },
//                           label: 'Password',
//                           controller: Password,
//                         ),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Row(
//                               children: [
//                                 GetBuilder<Get1>(
//                                     init: Get1(), builder: (logic) {
//                                   return Checkbox(
//                                     value: remaberMe,
//                                     onChanged: (val) {
//                                       remaberMe = val;
//                                       logic.update();
//                                     },
//                                     activeColor: Colors.blue,
//                                   );
//                                 }),
//                                 Text(
//                                   'Remember Me',
//                                   style: TextStyle(
//                                       color: Colors.black,
//                                       fontSize: wi / 40,
//                                       fontWeight: FontWeight.w700),
//                                 )
//                               ],
//                             ),
//                             Text(
//                               'Forget Passowrd?',
//                               style: TextStyle(
//                                   color: Colors.blue,
//                                   fontSize: wi / 35,
//                                   fontWeight: FontWeight.w900),
//                             )
//                           ],
//                         )
//                       ],
//                     ),
//                   ),
//                   GetBuilder<SignInController>(
//                       init: SignInController(emailController: Email, passwordController: Password,
//                           isFirstTime: isFirstTime), builder: (logic) {
//                     return Container(
//                       color: Colors.transparent,
//                       height: hi / 12,
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 10,
//                       ),
//                       child: GestureDetector(
//                         onTap: () {
//                           logic.signInWithEmail(globalKey);
//                         },
//                         child: isLosing
//                             ? Center(child: CircularProgressIndicator())
//                             : Container(
//                           width: wi,
//                           alignment: Alignment.center,
//                           decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(18),
//                               color: Colors.black54),
//                           child: Text(
//                             'تسجيل الدخول',
//                             style: TextStyle(
//                                 fontSize: wi / 19,
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.w800),
//                           ),
//                         ),
//                       ),
//                     );
//                   }),
//                   SizedBox(
//                     height: hi / 8,
//                   ),
//
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 10),
//                     child: Row(
//                       children: [
//                         Expanded(child: Divider()),
//                         SizedBox(
//                           width: wi / 60,
//                         ),
//                         Text(
//                           'او التسجيل مع',
//                           style: TextStyle(
//                               color: Colors.black,
//                               fontSize: 24,
//                               fontWeight: FontWeight.w600),
//                         ),
//                         SizedBox(
//                           width: wi / 50,
//                         ),
//                         Expanded(child: Divider())
//                       ],
//                     ),
//                   ),
//
//
//
//             SizedBox(
//                     height: hi / 30,
//                   ),
//                   Padding(padding: EdgeInsets.symmetric(horizontal: 5),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         GetBuilder<SignInController>(init:SignInController(isFirstTime: isFirstTime,passwordController: Password,emailController: Email) ,builder: (logic) {
//                           return Padding(
//                               padding: const EdgeInsets.symmetric(horizontal: 10),
//                               child:  GestureDetector(
//                                 onTap: (){
//                                   logic.signInWithGoogle();
//                                 },
//                                 child: Container(
//                                   width: wi/5,
//                                   height: hi / 12,
//                                   decoration: BoxDecoration(
//                                       color: Colors.white,
//                                       border: Border.all(color: Colors.black),
//                                       borderRadius: BorderRadius.circular(15),
//                                       image: DecorationImage(image:
//                                       AssetImage('assete/google.png'))
//                                   ),
//                                   padding: EdgeInsets.symmetric(horizontal: 1),
//
//                                 ),
//                               )
//                           );
//                         }),
//
//
//                         GetBuilder<SignInController>(init:SignInController(isFirstTime: isFirstTime,passwordController: Password,emailController: Email) ,builder: (logic) {
//                           return Padding(
//                               padding: const EdgeInsets.symmetric(horizontal: 0),
//                               child:GestureDetector(
//                                 onTap: (){
//                                   if(Platform.isAndroid){
//                                     logic.signInWithFacebookForAndroid();
//                                   }
//                                   if(Platform.isIOS){
//                                     logic.signInWithFacebookForiOS();
//                                   }
//                                 },
//                                 child: Container(
//                                   width: wi/5,
//                                   height: hi / 12,
//                                   decoration: BoxDecoration(
//                                       color: Colors.white,
//                                       borderRadius: BorderRadius.circular(15),
//                                       image: DecorationImage(image:
//                                       AssetImage('assete/facebook.png'),
//                                           fit: BoxFit.cover)
//                                   ),
//                                   padding: EdgeInsets.symmetric(horizontal: 1),
//
//                                 ),
//                               ));
//                         }),
//
//
//
//
//
//                         //
//
//
//
//                         GetBuilder<SignInController>(init:SignInController(isFirstTime: isFirstTime,passwordController: Password,emailController: Email) ,builder: (logic) {
//                           return Padding(
//                               padding: const EdgeInsets.symmetric(horizontal: 10),
//                               child:GestureDetector(
//                                 onTap: (){
//                                   logic.signInWithMicrosoft();
//
//                                 },
//                                 child: Container(
//                                   width: wi/5,
//                                   height: hi / 12,
//                                   decoration: BoxDecoration(
//                                       color: Colors.white,
//                                       borderRadius: BorderRadius.circular(15),
//                                       image: DecorationImage(image:
//                                       AssetImage('assete/microsoft.png'),
//                                           fit: BoxFit.cover)
//                                   ),
//                                   padding: EdgeInsets.symmetric(horizontal: 1),
//
//                                 ),
//                               ) );
//                         }),
//
//                       ],
//                     ),),
//
//                   SizedBox(
//                     height: hi/40,
//                   ),
//
//                   Padding(padding: EdgeInsets.symmetric(horizontal: 5),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       GetBuilder<SignInController>(init:SignInController(isFirstTime: isFirstTime,passwordController: Password,emailController: Email) ,builder: (logic) {
//                         return Padding(
//                             padding: const EdgeInsets.symmetric(horizontal: 10),
//                             child:GestureDetector(
//                               onTap: (){
//                                 logic.signInWithYahoo();
//
//                               },
//                               child: Container(
//                                 width: wi/5,
//                                 height: hi / 12,
//                                 decoration: BoxDecoration(
//                                     color: Colors.white,
//                                     borderRadius: BorderRadius.circular(15),
//                                     image: DecorationImage(image:
//                                     AssetImage('assete/yahoo.png'),
//                                         fit: BoxFit.cover)
//                                 ),
//                                 padding: EdgeInsets.symmetric(horizontal: 1),
//
//                               ),
//                             ));
//                       }),
//
//
//
//                       GetBuilder<SignInController>(init:SignInController(isFirstTime: isFirstTime,passwordController: Password,emailController: Email) ,builder: (logic) {
//                         return Platform.isIOS ? Padding(
//                             padding: const EdgeInsets.symmetric(horizontal: 10),
//                             child:GestureDetector(
//                               onTap: (){
//                                 logic.signInWithApple();
//
//                               },
//                               child: Container(
//                                 width: wi/5,
//                                 height: hi / 12,
//                                 decoration: BoxDecoration(
//                                     color: Colors.white,
//                                     borderRadius: BorderRadius.circular(15),
//                                     image: DecorationImage(image:
//                                     AssetImage('assete/apple.png'),
//                                         fit: BoxFit.cover)
//                                 ),
//                                 padding: EdgeInsets.symmetric(horizontal: 1),
//
//                               ),
//                             ) ):Container();
//                       }),
//
//                     ],
//                   ),)
//
//
//
//                 ],
//               ),
//             ),
//           ),
//         )
//       ]),
//     );
//   }
// }































import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../XXX/XXXFirebase.dart';
import '../../widget/TextFormFiled.dart';
import 'GetX/Get.dart';
import 'GetX/GetSignIn.dart'; // تأكد من أن هذه الملفات تحتوي على تعريفات الـ Controllers

class SignInPage extends StatelessWidget {
  SignInPage({Key? key, required this.isFirstTime}) : super(key: key);

  final GlobalKey<FormState> globalKey = GlobalKey<FormState>();
  final bool isFirstTime;
  final TextEditingController Email = TextEditingController();
  final TextEditingController Password = TextEditingController();
  final bool remaberMe = true; // حالة ثابتة هنا؛ يمكنك تعديلها إن لزم الأمر

  @override
  Widget build(BuildContext context) {
    double hi = MediaQuery.of(context).size.height;
    double wi = MediaQuery.of(context).size.width;

    // حقن الـ SignInController مرة واحدة وعدم إعادة إنشائه في كل GetBuilder
    final signInController = Get.put(SignInController(
      isFirstTime: isFirstTime,
      emailController: Email,
      passwordController: Password,
    ));

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
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
                    SizedBox(height: hi / 15),
                    Text(
                      'تسجيل الدخول\n',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: wi / 17,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: const BoxDecoration(color: Colors.transparent),
                      child: Column(
                        children: [
                          TextFormFiled2(
                            hintColor: Colors.white,
                            backgroundColor: Colors.black54,
                            fontSize: wi / 22,
                            width: wi,
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
                          SizedBox(height: hi / 70),
                          TextFormFiled2(
                            hintColor: Colors.white,
                            backgroundColor: Colors.black54,
                            fontSize: wi / 22,
                            width: wi,
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
                                    init: Get1(),
                                    builder: (logic) {
                                      return Checkbox(
                                        value: remaberMe,
                                        onChanged: (val) {
                                          logic.update();
                                        },
                                        activeColor: Colors.blue,
                                      );
                                    },
                                  ),
                                  Text(
                                    'Remember Me',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: wi / 40,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  )
                                ],
                              ),
                              Text(
                                'Forget Password?',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: wi / 35,
                                  fontWeight: FontWeight.w900,
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                    // زر تسجيل الدخول بواسطة البريد الإلكتروني
                    GetBuilder<SignInController>(
                      builder: (logic) {
                        return Container(
                          color: Colors.transparent,
                          height: hi / 12,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: GestureDetector(
                            onTap: () {
                              logic.signInWithEmail(globalKey);
                            },
                            child: logic.isLoading.value
                                ? Center(child: CircularProgressIndicator())
                                : Container(
                              width: wi,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: Colors.black54,
                              ),
                              child: Text(
                                'تسجيل الدخول',
                                style: TextStyle(
                                  fontSize: wi / 19,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: hi / 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                          Expanded(child: Divider()),
                          SizedBox(width: wi / 60),
                          Text(
                            'او التسجيل مع',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: wi / 50),
                          Expanded(child: Divider()),
                        ],
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}












class SocialSignInButton extends StatelessWidget {
  final VoidCallback onTap;
  final String NetworkPath; // مسار الصورة الخاصة بالأيقونة
  final double width;
  final double height;

  // متغير تفاعلي لتحديد حالة الضغط
  final RxBool isPressed = false.obs;

  SocialSignInButton({
    Key? key,
    required this.onTap,
    required this.NetworkPath,
    required this.width,
    required this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(
          () => Transform.scale(
        scale: isPressed.value ? 0.95 : 1.0, // تصغير الحجم عند الضغط
        child: Material(
          color: Colors.white, // خلفية بيضاء
          elevation: isPressed.value ? 2 : 4, // تقليل الظل عند الضغط
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            onTap: onTap,
            // عند تغيير حالة اللمس يتم تحديث المتغير isPressed
            onHighlightChanged: (value) => isPressed.value = value,
            borderRadius: BorderRadius.circular(15),
            splashColor: Colors.grey.withOpacity(0.3),
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                image: DecorationImage(
                  image: NetworkImage(NetworkPath),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
