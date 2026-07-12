import 'package:flutter/material.dart';
import 'package:kisan_unnati/auth/login_screen.dart';
import 'package:kisan_unnati/core/theme/app_colors.dart';
import 'dart:async';
import 'package:kisan_unnati/auth/register_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Smooth fade-in animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);

    _animationController.forward();

    // Wait 3.5 seconds, then move to Registration screen
    Timer(const Duration(milliseconds: 3500), () {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
      print("Splash finished! Ready for Registration Screen.");
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnimation,
        // Stack allows us to overlay the loading spinner on top of the full-screen image
        child: Stack(
          fit: StackFit.expand, // This forces the stack to take up the whole screen
          children: [
            // 1. The Full-Screen Background Image
            Image.asset(
              'assets/images/splash_farmer.png',
              fit: BoxFit.cover, // This stretches the image to fill every corner!
            ),

            // 2. The Loading Indicator overlaid at the bottom
            const Positioned(
              bottom: 60, // Pushes it 60 pixels up from the bottom edge
              left: 0,
              right: 0,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.darkGreen),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}