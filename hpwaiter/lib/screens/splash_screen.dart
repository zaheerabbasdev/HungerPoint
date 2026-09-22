import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await ApiService.init();
    if (!mounted) return;

    if (ApiService.isLoggedIn) {
      SocketService().reconnectWithAuth();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.room_service_outlined, size: 64, color: AppColors.primaryOrange),
            SizedBox(height: 16),
            Text(
              'HungerPoint Waiter',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.darkNavy),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(color: AppColors.primaryYellow),
          ],
        ),
      ),
    );
  }
}
