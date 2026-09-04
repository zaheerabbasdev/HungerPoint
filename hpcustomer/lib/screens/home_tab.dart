import 'package:flutter/material.dart';
import 'dart:async';
import '../constants/app_colors.dart';
import '../services/cart_service.dart';
import 'cart_screen.dart';

class HomeScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final Function(Map<String, dynamic>) onAddToCart;
  final List<Map<String, dynamic>> cart;
  final Function(int)? onNavigateToExplore;

  const HomeScreen({
    super.key,
    required this.scaffoldKey,
    required this.onAddToCart,
    required this.cart,
    this.onNavigateToExplore,
  });


  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isDeliverySelected = true;

  // Carousel auto-slide properties
  late final PageController _pageController;
  Timer? _carouselTimer;
  int _currentPage = 0;

  final List<Map<String, dynamic>> _banners = [
    {
      'title': 'NOW OPEN',
      'subtitle': 'G-15, ISLAMABAD',
      'brand': 'HungerPoint',
      'gradient': [const Color(0xFFFA541C), const Color(0xFFD93800)],
      'image': 'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=400&q=80',
    },
    {
      'title': 'FLAT 30% OFF',
      'subtitle': 'On All Gourmet Pizzas!',
      'brand': 'SPECIAL OFFER',
      'gradient': [const Color(0xFFFF9800), const Color(0xFFE65100)],
      'image': 'https://images.unsplash.com/photo-1628840042765-356cda07504e?auto=format&fit=crop&w=400&q=80',
    },
    {
      'title': 'EXPLORE OUR MENU',
      'subtitle': 'ORDER NOW',
      'brand': 'FRESH & HOT',
      'gradient': [const Color(0xFFFFC107), const Color(0xFFFF8F00)],
      'image': 'https://images.unsplash.com/photo-1534308983496-4fabb1a015ee?auto=format&fit=crop&w=400&q=80',
    },
  ];

  final List<Map<String, String>> _categories = [
    {
      'title': 'Thin Crust Pizza',
      'image': 'https://images.unsplash.com/photo-1628840042765-356cda07504e?auto=format&fit=crop&w=400&q=80',
    },
    {
      'title': 'Malai Tikka',
      'image': 'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=400&q=80',
    },
    {
      'title': 'Beef Peppero...',
      'image': 'https://images.unsplash.com/photo-1534308983496-4fabb1a015ee?auto=format&fit=crop&w=400&q=80',
    },
    {
      'title': 'Starters',
      'image': 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?auto=format&fit=crop&w=400&q=80',
    },
    {
      'title': 'Somewhat Local',
      'image': 'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?auto=format&fit=crop&w=400&q=80',
    },
    {
      'title': 'Somewhat Sooper',
      'image': 'https://images.unsplash.com/photo-1593560708920-61dd98c46a4e?auto=format&fit=crop&w=400&q=80',
    },
  ];

  @override
  void initState() {
    super.initState();
    _currentPage = 1000 * _banners.length;
    _pageController = PageController(initialPage: _currentPage);
    _startCarouselTimer();
  }

  void _startCarouselTimer() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 650),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 1. STATIC TOP HEADER (Deliver to moved left next to Menu button) ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  // Orange Circular Menu Icon
                  GestureDetector(
                    onTap: () => widget.scaffoldKey.currentState?.openDrawer(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF5722),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.menu, color: Colors.white, size: 22),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // "Deliver to v" (Moved to the left right next to menu button)
                  GestureDetector(
                    onTap: () {
                      // Open location dropdown
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'Deliver to ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E1B4B),
                          ),
                        ),
                        Icon(Icons.keyboard_arrow_down, color: Color(0xFF1E1B4B), size: 22),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // White Circular Cart Button with Count Badge
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CartScreen(
                            onNavigateToExplore: () => widget.onNavigateToExplore?.call(0),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFF3F4F6)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                        valueListenable: CartService().cartNotifier,
                        builder: (context, cart, _) {
                          final count = CartService().totalItemCount;
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(Icons.shopping_cart_outlined, color: Color(0xFF1E1B4B), size: 20),
                              if (count > 0)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFF5722),
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                                    child: Center(
                                      child: Text(
                                        '$count',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          height: 1.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ─── 2. STATIC DELIVERY & PICK-UP TOGGLE BUTTONS ─────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  // Delivery Button (Yellow Pill)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isDeliverySelected = true),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 48,
                        decoration: BoxDecoration(
                          color: _isDeliverySelected ? const Color(0xFFFFC107) : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: _isDeliverySelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFFFC107).withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _isDeliverySelected ? const Color(0xFF1E1B4B) : const Color(0xFFFF5722),
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                Icons.person_outline,
                                size: 13,
                                color: _isDeliverySelected ? const Color(0xFF1E1B4B) : const Color(0xFFFF5722),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'DELIVERY',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                color: _isDeliverySelected ? const Color(0xFF1E1B4B) : const Color(0xFFFF5722),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Pick-Up Button (Orange outline styling)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isDeliverySelected = false),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 48,
                        decoration: BoxDecoration(
                          color: !_isDeliverySelected ? const Color(0xFFFFC107) : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: !_isDeliverySelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFFFC107).withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.storefront_outlined,
                              size: 20,
                              color: !_isDeliverySelected ? const Color(0xFF1E1B4B) : const Color(0xFFFF5722),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'PICK-UP',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                color: !_isDeliverySelected ? const Color(0xFF1E1B4B) : const Color(0xFFFF5722),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ─── 3. SCROLLABLE INNER CONTENT ─────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [


              // ─── 3. CAROUSEL BANNER (Auto-sliding every 3 Seconds) ──────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    SizedBox(
                      height: 185,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: 10000,
                        onPageChanged: (idx) {
                          setState(() => _currentPage = idx);
                        },
                        itemBuilder: (context, idx) {

                          final item = _banners[idx % _banners.length];
                          return Container(

                            margin: const EdgeInsets.only(right: 2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: item['gradient'] as List<Color>,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 6,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Row(
                                              children: [
                                                const Text('🍕 ', style: TextStyle(fontSize: 16)),
                                                Text(
                                                  item['brand'],
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w900,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              item['title'],
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 24,
                                                fontWeight: FontWeight.w900,
                                                height: 1.0,
                                                shadows: [
                                                  Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(1, 2)),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              item['subtitle'],
                                              style: const TextStyle(
                                                color: Color(0xFFFEF08A),
                                                fontSize: 16,
                                                fontWeight: FontWeight.w900,
                                                shadows: [
                                                  Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(1, 2)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 5,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(16),
                                          child: Image.network(
                                            item['image'],
                                            fit: BoxFit.cover,
                                            height: 130,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Dynamic Page Indicator Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_banners.length, (idx) {
                        final activeIndex = _currentPage % _banners.length;
                        final isSel = activeIndex == idx;
                        return AnimatedContainer(

                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: isSel ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFFFF5722) : const Color(0xFFD1D5DB),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ─── 4. EXPLORE MENU HEADER (Title & VIEW ALL link) ──────

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Explore Menu',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E1B4B),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => widget.onNavigateToExplore?.call(0),
                      child: const Text(
                        'VIEW ALL',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFFF5722),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ─── 5. EXPLORE MENU 3x2 CATEGORY GRID ──────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _categories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.05,
                  ),
                  itemBuilder: (context, idx) {
                    final cat = _categories[idx];
                    return GestureDetector(
                      onTap: () => widget.onNavigateToExplore?.call(idx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFF3F4F6)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                cat['image']!,
                                height: 52,
                                width: 52,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              cat['title']!,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E1B4B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),



              const SizedBox(height: 20),

              // ─── 6. SECONDARY FEATURED BANNER CARD (From Image 2) ─────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: GestureDetector(
                  onTap: () => widget.onNavigateToExplore?.call(0),
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC107),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(

                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              'EXPLORE OUR MENU',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1E1B4B),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'ORDER NOW',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFFF5722),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=400&q=80',
                          width: 110,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

              const SizedBox(height: 24),

            ],
          ),
        ),
      ),
    ],
  ),
),
    );
  }
}


