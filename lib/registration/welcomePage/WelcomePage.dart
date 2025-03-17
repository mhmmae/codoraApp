import 'package:flutter/material.dart';

import '../../XXX/XXXFirebase.dart';
import '../SginUp/SginUp.dart';
import '../signin/signinPage.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
        ),
        body: Stack(
          children: [
            Image.asset(
              ImageX.ImageOfSignUp,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
            SafeArea(
                child: Column(
              children: [
                Flexible(

                  flex: 1,

                  child: Align(

                    alignment: Alignment.topCenter,


                      child: Container(

                          padding: const EdgeInsets.symmetric(horizontal: 13),



                            child: RichText(
                              textAlign: TextAlign.center,

                              text: const TextSpan(children: [
                                TextSpan(
                                    text: 'Welcome Back\n',
                                    style: TextStyle(
                                        fontSize: 45, fontWeight: FontWeight.w600)),
                                TextSpan(
                                    text:
                                        '\n Please log in if you have an account or register now',
                                    style: TextStyle(
                                        fontSize: 22, fontWeight: FontWeight.w700))
                              ]),
                            ),
                          ),
                    ),
                      ),



                 Flexible(
                   flex: 1,
                   child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Row(
                      children: [

                        Expanded(
                          child: loginandsignupbottun(
                                              bottonText: 'Sign Up',
                          colorBotton: Colors.white24,
                          radius: const BorderRadius.only(
                              topRight: Radius.circular(16),
                              bottomRight: Radius.circular(16)),
                          voidCallback: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                     SinUp()));
                          }),
                        ),


                         const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: loginandsignupbottun(
                                bottonText: 'Sign In',
                                colorBotton: Colors.white,
                                radius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    bottomLeft: Radius.circular(16)),
                                voidCallback: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                               SignInPage(isFirstTime: false,)));
                                }),
                        ),

                      ],
                    ),
                                   ),
                 )
              ],
            ))
          ],
        ));
  }
}

class loginandsignupbottun extends StatelessWidget {
  const loginandsignupbottun(
      {super.key,
      required this.bottonText,
      required this.colorBotton,
      required this.radius,
      required this.voidCallback});

  final String bottonText;
  final Color colorBotton;
  final BorderRadius radius;
  final VoidCallback voidCallback;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: voidCallback,
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(color: colorBotton, borderRadius: radius),
        child: Text(
          bottonText,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 27,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
