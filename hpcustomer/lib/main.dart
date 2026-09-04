import 'package:flutter/material.dart';
import 'constants/app_colors.dart';
import 'screens/welcome_screen.dart';

void main() {
  runApp(const HungerPointCustomerApp());
}

class HungerPointCustomerApp extends StatelessWidget {
  const HungerPointCustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HungerPoint',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primaryYellow,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryYellow,
          primary: AppColors.primaryYellow,
          secondary: AppColors.accentOrange,
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          iconTheme: IconThemeData(color: AppColors.textNavy),
          titleTextStyle: TextStyle(
            color: AppColors.textNavy,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

      ),
      home: const WelcomeScreen(),
    );
  }
}
