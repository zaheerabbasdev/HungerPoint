// ============================================================
// HungerPoint Rider App — Flutter Main App
// ============================================================

import 'package:flutter/material.dart';
import 'constants/app_colors.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const HungerPointRiderApp());
}

class HungerPointRiderApp extends StatelessWidget {
  const HungerPointRiderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HungerPoint Rider',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.amber,
          secondary: AppColors.orange,
          surface: AppColors.surface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.appBar,
          elevation: 0,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
