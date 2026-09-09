import 'package:flutter/material.dart';
import 'dart:async';
import '../constants/app_colors.dart';
import '../services/cart_service.dart';
import '../services/address_service.dart';
import '../services/branch_service.dart';
import '../services/api_service.dart';
import 'cart_screen.dart';
import 'location_picker_screen.dart';
import 'add_address_screen.dart';
import 'pickup_branches_screen.dart';

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
  // Carousel auto-slide properties
  late final PageController _pageController;
  Timer? _carouselTimer;
  int _currentPage = 0;

  static bool _hasShownInitialBottomSheet = false;

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

  List<Map<String, dynamic>> _dynamicCategories = [];

  List<Map<String, dynamic>> get _activeCategories {
    if (BranchService().isPickupMode &&
        BranchService().selectedBranch != null &&
        BranchService().selectedBranch!.menuCategories.isNotEmpty) {
      return BranchService().selectedBranch!.menuCategories;
    }
    return _dynamicCategories;
  }

  Future<void> _loadDynamicCategories() async {
    try {
      // 1. Prioritize categories created from admin side / backend
      final categories = await ApiService.fetchCategories();
      if (categories.isNotEmpty && mounted) {
        final List<Map<String, dynamic>> dynamicList = [];
        for (final c in categories) {
          final catName = c['name']?.toString() ?? 'Category';
          final rawImg = c['image']?.toString();
          final imgUrl = ApiService.resolveImageUrl(rawImg);

          dynamicList.add({
            'id': c['id']?.toString() ?? '',
            'title': catName,
            'name': catName,
            'desc': c['description']?.toString() ?? '',
            'image': imgUrl,
            'itemCount': (c['products'] as List<dynamic>?)?.length ?? 0,
          });
        }
        if (dynamicList.isNotEmpty) {
          setState(() {
            _dynamicCategories = dynamicList;
          });
          return;
        }
      }

      // 2. Fallback: extract distinct categories from products
      final products = await ApiService.fetchProducts();
      if (products.isNotEmpty && mounted) {
        final Map<String, Map<String, dynamic>> categoryMap = {};
        for (final p in products) {
          final catObj = p['category'];
          final catName = (catObj != null && catObj['name'] != null)
              ? catObj['name'].toString()
              : 'Specialties';

          if (!categoryMap.containsKey(catName)) {
            final images = p['images'] as List<dynamic>?;
            final rawImg = (images != null && images.isNotEmpty)
                ? images.first.toString()
                : p['image']?.toString();
            final imgUrl = ApiService.resolveImageUrl(rawImg);

            categoryMap[catName] = {
              'id': catObj != null ? (catObj['id']?.toString() ?? '') : '',
              'title': catName,
              'name': catName,
              'desc': catName,
              'image': imgUrl,
              'itemCount': 1,
            };
          } else {
            categoryMap[catName]!['itemCount'] = (categoryMap[catName]!['itemCount'] as int) + 1;
          }
        }
        if (categoryMap.isNotEmpty) {
          setState(() {
            _dynamicCategories = categoryMap.values.toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading dynamic categories for home: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _currentPage = 1000 * _banners.length;
    _pageController = PageController(initialPage: _currentPage);
    _startCarouselTimer();
    _loadDynamicCategories();
    BranchService().fetchBranchesFromBackend();

    // Sync local state with AddressService
    AddressService().selectedAddressNotifier.addListener(_onAddressChanged);
    AddressService().savedAddressesNotifier.addListener(_onAddressChanged);
    AddressService().customLocationNotifier.addListener(_onAddressChanged);

    // Sync local state with BranchService
    BranchService().selectedBranchNotifier.addListener(_onBranchChanged);
    BranchService().isPickupModeNotifier.addListener(_onBranchChanged);

    // Show address bottom sheet after 5 seconds on first load
    if (!_hasShownInitialBottomSheet) {
      _hasShownInitialBottomSheet = true;
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) _showAddressBottomSheet();
      });
    }
  }

  void _onBranchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onAddressChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  /// Shows the "Add or choose an address" bottom sheet
  void _showAddressBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            final savedList = AddressService().savedAddresses;
            final selected = AddressService().selectedAddress;

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      // Drag handle
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Add or choose an address',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1E1B4B),
                              ),
                            ),
                            const SizedBox(height: 18),
                            // Select new location
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                Navigator.pop(sheetContext);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
                                );
                              },
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFFF3ED),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.near_me_outlined,
                                      color: AppColors.primaryOrange,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  const Text(
                                    'Select new location',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryOrange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Divider(height: 1, color: Color(0xFFF3F4F6)),

                            // Saved addresses list with radio selection
                            ...savedList.map((addr) {
                              final isSelected = selected?.id == addr.id;
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      AddressService().selectAddress(addr);
                                      Navigator.pop(sheetContext);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2),
                                            child: Container(
                                              width: 22,
                                              height: 22,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: isSelected
                                                      ? AppColors.primaryOrange
                                                      : const Color(0xFFD1D5DB),
                                                  width: isSelected ? 2.5 : 2,
                                                ),
                                                color: Colors.white,
                                              ),
                                              child: isSelected
                                                  ? Center(
                                                      child: Container(
                                                        width: 10,
                                                        height: 10,
                                                        decoration: const BoxDecoration(
                                                          shape: BoxShape.circle,
                                                          color: AppColors.primaryOrange,
                                                        ),
                                                      ),
                                                    )
                                                  : null,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  addr.label,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w800,
                                                    color: Color(0xFF1E1B4B),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  addr.address,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Color(0xFF4B5563),
                                                    height: 1.35,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Divider(height: 1, color: Color(0xFFF3F4F6)),
                                ],
                              );
                            }),

                            const SizedBox(height: 16),
                            // + ADD NEW ADDRESS
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                Navigator.pop(sheetContext);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const AddAddressScreen()),
                                );
                              },
                              child: const Center(
                                child: Text(
                                  '+ ADD NEW ADDRESS',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primaryOrange,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
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
    AddressService().selectedAddressNotifier.removeListener(_onAddressChanged);
    AddressService().savedAddressesNotifier.removeListener(_onAddressChanged);
    AddressService().customLocationNotifier.removeListener(_onAddressChanged);
    BranchService().selectedBranchNotifier.removeListener(_onBranchChanged);
    BranchService().isPickupModeNotifier.removeListener(_onBranchChanged);
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

                  // "Deliver to" / "Pickup From" header button
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (BranchService().isPickupMode) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PickupBranchesScreen(
                                onBackToHome: () => setState(() {}),
                              ),
                            ),
                          );
                        } else {
                          _showAddressBottomSheet();
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: BranchService().isPickupMode ? 'Pickup From ' : 'Deliver to ',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E1B4B),
                                    ),
                                  ),
                                  TextSpan(
                                    text: BranchService().isPickupMode
                                        ? (BranchService().selectedBranch?.name ?? 'F-10 Markaz...')
                                        : AddressService().activeDeliveryLabel,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF1E1B4B),
                                    ),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.keyboard_arrow_down, color: Color(0xFF1E1B4B), size: 22),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Refresh Button
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () async {
                      await _loadDynamicCategories();
                      await BranchService().fetchBranchesFromBackend();
                      if (mounted) {
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Menu and branches refreshed!'),
                            duration: Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
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
                      child: const Center(
                        child: Icon(Icons.refresh_rounded, color: Color(0xFF1E1B4B), size: 20),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

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
                  // Delivery Button (Yellow Pill when delivery mode)
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        BranchService().switchToDelivery();
                        setState(() {});
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 48,
                        decoration: BoxDecoration(
                          color: !BranchService().isPickupMode ? const Color(0xFFFFC107) : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: !BranchService().isPickupMode
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
                                  color: !BranchService().isPickupMode ? const Color(0xFF1E1B4B) : const Color(0xFFFF5722),
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                Icons.person_outline,
                                size: 13,
                                color: !BranchService().isPickupMode ? const Color(0xFF1E1B4B) : const Color(0xFFFF5722),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'DELIVERY',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                color: !BranchService().isPickupMode ? const Color(0xFF1E1B4B) : const Color(0xFFFF5722),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Pick-Up Button (Yellow Pill when pickup mode, opens branches screen on click)
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PickupBranchesScreen(
                              onBackToHome: () => setState(() {}),
                            ),
                          ),
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 48,
                        decoration: BoxDecoration(
                          color: BranchService().isPickupMode ? const Color(0xFFFFC107) : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: BranchService().isPickupMode
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
                              color: BranchService().isPickupMode ? const Color(0xFF1E1B4B) : const Color(0xFFFF5722),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'PICK-UP',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                color: BranchService().isPickupMode ? const Color(0xFF1E1B4B) : const Color(0xFFFF5722),
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
              child: RefreshIndicator(
                color: const Color(0xFFFF5722),
                backgroundColor: Colors.white,
                onRefresh: () async {
                  await _loadDynamicCategories();
                  await BranchService().fetchBranchesFromBackend();
                  if (mounted) setState(() {});
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
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
                                            errorBuilder: (ctx, err, stack) => Container(
                                              height: 130,
                                              color: const Color(0xFFFFF7ED),
                                              child: const Center(child: Text('🍕', style: TextStyle(fontSize: 36))),
                                            ),
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
                  itemCount: _activeCategories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.05,
                  ),
                  itemBuilder: (context, idx) {
                    final cat = _activeCategories[idx];
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
                                ApiService.resolveImageUrl(cat['image']?.toString()),
                                height: 52,
                                width: 52,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => Container(
                                  height: 52,
                                  width: 52,
                                  color: const Color(0xFFFFF7ED),
                                  child: const Center(child: Text('🍔', style: TextStyle(fontSize: 24))),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              cat['title'] as String,
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
                          errorBuilder: (ctx, err, stack) => Container(
                            width: 110,
                            height: 100,
                            color: const Color(0xFFFFF7ED),
                            child: const Center(child: Text('🍕', style: TextStyle(fontSize: 32))),
                          ),
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
    ),
  ],
  ),
),
    );
  }
}


