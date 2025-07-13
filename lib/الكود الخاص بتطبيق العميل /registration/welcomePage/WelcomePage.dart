

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../XXX/xxx_firebase.dart';
import '../SginUp/SginUp.dart';
import '../signin/signinPage.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // إعداد تأثير التلاشي عند دخول الصفحة
    _fadeController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double hi = MediaQuery.of(context).size.height;
    double wi = MediaQuery.of(context).size.width;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Stack(
        children: [
          Image.asset(
            ImageX.ImageOfSignUp,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // الجزء العلوي: الترحيب والنص
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        text: 'مرحبا بك\n',
                        style: TextStyle(
                          fontSize: 45,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                        children: [
                          TextSpan(
                            text: 'قم بالتسجيل الدخول الى حسابك\nاو قم بالتسجيل',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // الجزء السفلي: أزرار التنقل
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
                    child: Row(
                      children: [
                        // زر التسجيل "Sign Up"
                        Expanded(
                          child: AnimatedButton(
                            onTap: () {
                              Get.to(() => SignUpPage(isFirstTime: false));
                            },
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white24,
                                elevation: 4,
                                padding: EdgeInsets.symmetric(vertical: 20),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(16),
                                    bottomRight: Radius.circular(16),
                                  ),
                                ),
                              ),
                              onPressed: () {Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder:(context)=>SignUpPage(isFirstTime: false,) ), (rute)=>false);}, // لا حاجة لتنفيذ هنا لأن onTap يحرك النتيجة
                              child:  Text(
                                'التسجيل',
                                style: TextStyle(
                                  fontSize: wi/30,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // زر تسجيل الدخول "Sign In"
                        Expanded(
                          child: AnimatedButton(
                            onTap: () {
                              Get.to(() => SignInPage(isFirstTime: false));
                            },
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(

                                backgroundColor: Colors.white,
                                elevation: 4,
                                padding: EdgeInsets.symmetric(vertical: 20),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    bottomLeft: Radius.circular(16),
                                  ),
                                ),
                              ),
                              onPressed: () {Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder:(context)=>SignInPage(isFirstTime: false,) ), (rute)=>false);},
                              child:  Text(
                                'تسجيل الدخول',
                                style: TextStyle(
                                  fontSize: wi/30,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}





class AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const AnimatedButton({
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  _AnimatedButtonState createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    // إعداد AnimationController مع مدة قصيرة لتأثير الضغط
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 100),
      value: 1.0,
      lowerBound: 0.95,
      upperBound: 1.0,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // عند الضغط يتم تقليل الحجم
      onTapDown: (_) => _animationController.reverse(),
      // عند الإفلات يعود الحجم إلى الطبيعي
      onTapUp: (_) => _animationController.forward(),
      onTapCancel: () => _animationController.forward(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _animationController.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}
