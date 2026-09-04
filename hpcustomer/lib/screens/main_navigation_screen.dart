import 'package:flutter/material.dart';
import '../widgets/side_profile_drawer.dart';
import 'home_tab.dart';
import 'explore_tab.dart';
import 'vouchers_tab.dart';
import 'branches_tab.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  int _exploreCategoryIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Map<String, dynamic>> _cart = [];

  void _addToCart(Map<String, dynamic> item) {
    setState(() {
      _cart.add(item);
    });
  }

  void _navigateToExplore([int categoryIndex = 0]) {
    setState(() {
      _exploreCategoryIndex = categoryIndex;
      _currentIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomeScreen(
        scaffoldKey: _scaffoldKey,
        onAddToCart: _addToCart,
        cart: _cart,
        onNavigateToExplore: _navigateToExplore,
      ),
      ExploreMenuScreen(
        key: ValueKey(_exploreCategoryIndex),
        onAddToCart: _addToCart,
        cart: _cart,
        initialCategoryIndex: _exploreCategoryIndex,
        onBackToHome: () => setState(() => _currentIndex = 0),
      ),

      const VouchersScreen(),
      const BranchesScreen(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: SideProfileDrawer(onClose: () => Navigator.pop(context)),
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (idx) => setState(() => _currentIndex = idx),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: const Color(0xFFFF5722),
          unselectedItemColor: const Color(0xFF4B5563),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home, color: Color(0xFFFF5722)),
              label: 'HOME',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined),
              activeIcon: Icon(Icons.search, color: Color(0xFFFF5722)),
              label: 'EXPLORE',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_offer_outlined),
              activeIcon: Icon(Icons.local_offer, color: Color(0xFFFF5722)),
              label: 'VOUCHERS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.storefront_outlined),
              activeIcon: Icon(Icons.storefront, color: Color(0xFFFF5722)),
              label: 'BRANCHES',
            ),
          ],
        ),
      ),
    );
  }
}
