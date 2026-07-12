import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kisan_unnati/core/theme/app_colors.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

// 🔥 IMPORT YOUR NEW SPLASH SCREEN HERE
import 'package:kisan_unnati/features/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required for async main

  // Note: We will add Firebase initialization right here in the next step!
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await dotenv.load(fileName: ".env"); // Load the API key
  runApp(const KisanUnnatiApp());
}

class KisanUnnatiApp extends StatelessWidget {
  const KisanUnnatiApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KisanUnnati',
      debugShowCheckedModeBanner: false, // Hide the debug banner for presentations
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.backgroundGreen,
        primaryColor: AppColors.primaryGreen,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.backgroundGreen,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.darkGreen),
          titleTextStyle: TextStyle(color: AppColors.textDark, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      // 🔥 EVERYONE STARTS AT THE SPLASH SCREEN NOW!
      home: const SplashScreen(),
    );
  }
}