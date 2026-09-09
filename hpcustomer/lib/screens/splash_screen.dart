import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/profile_service.dart';
import '../services/branch_service.dart';
import '../services/address_service.dart';
import 'main_navigation_screen.dart';
import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializeApp();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    _timer = Timer(const Duration(milliseconds: 2200), _proceedToNextScreen);
  }

  Future<void> _initializeApp() async {
    await ApiService.init();
    await BranchService().fetchBranchesFromBackend();
    await AddressService().fetchAddressesFromBackend();
    if (ApiService.isLoggedIn) {
      await ProfileService().syncWithBackend();
    }
  }

  void _proceedToNextScreen() {
    if (!mounted) return;
    _timer?.cancel();

    if (ApiService.isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _proceedToNextScreen,
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Food Emblem Illustration (Pizza + Burger + Drink)
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              top: 6,
                              left: 8,
                              child: Container(
                                width: 44,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFB300),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(24),
                                    topRight: Radius.circular(24),
                                    bottomLeft: Radius.circular(8),
                                  ),
                                  border: Border.all(color: const Color(0xFF4E2A1D), width: 2.2),
                                ),
                                child: const Center(
                                  child: Text('🍕', style: TextStyle(fontSize: 16)),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              left: 10,
                              child: Container(
                                width: 40,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFC107),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFF4E2A1D), width: 2.2),
                                ),
                                child: const Center(
                                  child: Text('🍔', style: TextStyle(fontSize: 14)),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 10,
                              right: 12,
                              child: Container(
                                width: 26,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFB300),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(4),
                                    topRight: Radius.circular(4),
                                    bottomLeft: Radius.circular(8),
                                    bottomRight: Radius.circular(8),
                                  ),
                                  border: Border.all(color: const Color(0xFF4E2A1D), width: 2.2),
                                ),
                                child: const Center(
                                  child: Text('🥤', style: TextStyle(fontSize: 13)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Brand Title
                  const Text(
                    'HungerPoint',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E1B4B),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Subtitle
                  const Text(
                    'Taste the Greatness',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFF5722),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Subtle Loading Indicator
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD54F)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
