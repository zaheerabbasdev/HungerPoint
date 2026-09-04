import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'item_detail_screen.dart';
import 'favorites_screen.dart';
import 'cart_screen.dart';
import '../services/api_service.dart';
import '../services/favorites_service.dart';
import '../services/cart_service.dart';


class ExploreMenuScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onAddToCart;
  final List<Map<String, dynamic>> cart;
  final int initialCategoryIndex;
  final VoidCallback? onBackToHome;

  const ExploreMenuScreen({
    super.key,
    required this.onAddToCart,
    required this.cart,
    this.initialCategoryIndex = 0,
    this.onBackToHome,
  });


  @override
  State<ExploreMenuScreen> createState() => _ExploreMenuScreenState();
}

class _ExploreMenuScreenState extends State<ExploreMenuScreen> {
  int _selectedCategoryIndex = 0;
  final ScrollController _scrollController = ScrollController();
  final ScrollController _tabScrollController = ScrollController();
  final List<GlobalKey> _categoryKeys = [];

  final List<Map<String, dynamic>> _menuCategories = [
    {
      'title': 'Thin Crust Pizza',
      'items': [
        {
          'id': '1',
          'name': 'Thin Crust Beef Pepperoni',
          'desc': 'A crispy thin crust topped with beef pepperoni, mozzarella cheese, and rich marinara sauce.',
          'price': 1480,
          'image': 'https://images.unsplash.com/photo-1628840042765-356cda07504e?auto=format&fit=crop&w=400&q=80',
        },
        {
          'id': '2',
          'name': 'Thin Crust Veggie Lover',
          'desc': 'Cheese blend, mushrooms, sweet corn, black olives, onions, capsicum and tomatoes.',
          'price': 1290,
          'image': 'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=400&q=80',
        },
        {
          'id': '3',
          'name': 'Thin Crust Cheese Lover',
          'desc': 'Extra special mozzarella blend and signature sauce on a crispy thin crust.',
          'price': 1290,
          'image': 'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?auto=format&fit=crop&w=400&q=80',
        },
        {
          'id': '4',
          'name': 'Thin Crust Fajita',
          'desc': 'Tender fajita chicken with mozzarella blend, onions and fresh capsicum.',
          'price': 1290,
          'image': 'https://images.unsplash.com/photo-1534308983496-4fabb1a015ee?auto=format&fit=crop&w=400&q=80',
        },
      ],
    },
    {
      'title': 'Malai Tikka',
      'items': [
        {
          'id': '5',
          'name': 'Malai Tikka',
          'desc': 'A flavorful Pizza loaded with fresh BBQ Malai Tikka chunks and mozzarella cheese.',
          'price': 1530,
          'image': 'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=400&q=80',
        },
      ],
    },
    {
      'title': 'Beef Pepperoni',
      'items': [
        {
          'id': '6',
          'name': 'Beef Pepperoni Pan Pizza',
          'desc': 'Freshly baked pan crust, soft inside and golden-crisp outside topped with beef pepperoni.',
          'price': 1480,
          'image': 'https://images.unsplash.com/photo-1534308983496-4fabb1a015ee?auto=format&fit=crop&w=400&q=80',
        },
      ],
    },
    {
      'title': 'Starters',
      'items': [
        {
          'id': '7',
          'name': 'Cheezy Sticks',
          'desc': 'Freshly baked bread filled with the yummiest Cheese blend and garlic butter.',
          'price': 600,
          'image': 'https://images.unsplash.com/photo-1541745537411-b8046dc6d66c?auto=format&fit=crop&w=400&q=80',
        },
        {
          'id': '8',
          'name': 'Oven Baked Wings',
          'desc': 'Fresh Oven baked wings served with Dip Sauce.',
          'price': 580,
          'image': 'https://images.unsplash.com/photo-1567620832903-9fc6debc209f?auto=format&fit=crop&w=400&q=80',
        },
        {
          'id': '9',
          'name': 'Flaming Wings',
          'desc': 'Fresh oven baked wings tossed in hot Peri Peri Sauce and served with dip.',
          'price': 620,
          'image': 'https://images.unsplash.com/photo-1527477396000-e27163b481c2?auto=format&fit=crop&w=400&q=80',
        },
        {
          'id': '10',
          'name': 'Calzone Chunks',
          'desc': '4 pcs Stuffed Calzone Chunks served with Sauce & Fries.',
          'price': 1100,
          'image': 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?auto=format&fit=crop&w=400&q=80',
        },
        {
          'id': '11',
          'name': 'Arabic Rolls',
          'desc': 'Crispy golden rolls filled with spicy seasoned chicken and garlic sauce.',
          'price': 950,
          'image': 'https://images.unsplash.com/photo-1561651823-34feb02250e4?auto=format&fit=crop&w=400&q=80',
        },
      ],
    },
    {
      'title': 'Somewhat Local',
      'items': [
        {
          'id': '12',
          'name': 'Chicken Tikka Pizza',
          'desc': 'Traditional chicken tikka topping with fresh onions and green peppers.',
          'price': 1350,
          'image': 'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?auto=format&fit=crop&w=400&q=80',
        },
      ],
    },
    {
      'title': 'Somewhat Sooper',
      'items': [
        {
          'id': '13',
          'name': 'Super Supreme Pizza',
          'desc': 'Loaded with beef, chicken, black olives, mushrooms, capsicum and extra cheese.',
          'price': 1590,
          'image': 'https://images.unsplash.com/photo-1593560708920-61dd98c46a4e?auto=format&fit=crop&w=400&q=80',
        },
      ],
    },
  ];

  bool _isAutoScrolling = false;

  @override
  void initState() {
    super.initState();
    _selectedCategoryIndex = widget.initialCategoryIndex;
    _categoryKeys.addAll(List.generate(_menuCategories.length, (_) => GlobalKey()));
    _scrollController.addListener(_onScroll);
    _fetchLiveMenu();

    if (widget.initialCategoryIndex > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCategory(widget.initialCategoryIndex);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _tabScrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isAutoScrolling) return;

    for (int i = 0; i < _categoryKeys.length; i++) {
      final key = _categoryKeys[i];
      final context = key.currentContext;
      if (context != null) {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null) {
          final position = box.localToGlobal(Offset.zero);
          // Check if top of category header is near the top of viewport (offset around 140-180)
          if (position.dy >= 80 && position.dy <= 260) {
            if (_selectedCategoryIndex != i) {
              setState(() {
                _selectedCategoryIndex = i;
              });
              _scrollTabToCenter(i);
            }
            break;
          }
        }
      }
    }
  }

  void _scrollTabToCenter(int index) {
    if (_tabScrollController.hasClients) {
      final tabOffset = index * 130.0;
      _tabScrollController.animateTo(
        tabOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollToCategory(int index) {
    _isAutoScrolling = true;
    setState(() {
      _selectedCategoryIndex = index;
    });
    _scrollTabToCenter(index);

    final context = _categoryKeys[index].currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.05,
      ).then((_) {
        _isAutoScrolling = false;
      });
    } else {
      _isAutoScrolling = false;
    }
  }

  Future<void> _fetchLiveMenu() async {
    try {
      final response = await http.get(Uri.parse('${ApiService.baseUrl}/products'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['data'] as List<dynamic>? ?? [];
        if (list.isNotEmpty) {
          // Live fallback updates if needed
        }
      }
    } catch (e) {
      debugPrint('Live API fetch fallback: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartTotal = widget.cart.fold(
      0,
      (sum, item) => sum + (item['price'] as int) * (item['quantity'] as int),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            toolbarHeight: 68,
            titleSpacing: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF1E1B4B), size: 22),
              onPressed: () {
                if (widget.onBackToHome != null) {
                  widget.onBackToHome!();
                } else if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'Explore Menu',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E1B4B),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'No branch found',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
            actions: [
              // Cart Button with Count Badge
              Center(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CartScreen(),
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
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 14,
                          offset: const Offset(0, 3),
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
              ),
              const SizedBox(width: 8),

              // Search Button
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Center(
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFF3F4F6)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 14,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.search, color: Color(0xFF1E1B4B), size: 22),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),




      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── 1. STICKY CATEGORY TAB BAR (Orange Active Underline) ───
              Container(
                color: Colors.white,
                height: 48,
                child: ListView.builder(
                  controller: _tabScrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _menuCategories.length,
                  itemBuilder: (context, idx) {
                    final isSelected = _selectedCategoryIndex == idx;
                    final catName = _menuCategories[idx]['title'] as String;
                    return GestureDetector(
                      onTap: () => _scrollToCategory(idx),
                      child: Container(
                        margin: const EdgeInsets.only(right: 22),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: isSelected ? const Color(0xFFFF5722) : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Text(
                          catName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                            color: isSelected ? const Color(0xFFFF5722) : const Color(0xFF1E1B4B),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ─── 2. CONTINUOUS VERTICAL SCROLLABLE MENU SECTIONS ──────

              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _menuCategories.length,
                  itemBuilder: (context, catIdx) {
                    final cat = _menuCategories[catIdx];
                    final catTitle = cat['title'] as String;
                    final items = cat['items'] as List<Map<String, dynamic>>;

                    return Column(
                      key: _categoryKeys[catIdx],
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Orange Category Section Title (as in screenshots)
                        Padding(
                          padding: const EdgeInsets.only(top: 16, bottom: 12),
                          child: Text(
                            catTitle,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFFF5722),
                            ),
                          ),
                        ),

                        // Products in this Category
                        ...items.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 14.0),
                              child: _buildMenuItemCard(item),
                            )),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),

          // ─── 3. FLOATING BOTTOM CART BAR ───────────────────────────
          ValueListenableBuilder<List<Map<String, dynamic>>>(
            valueListenable: CartService().cartNotifier,
            builder: (context, cart, _) {
              if (cart.isEmpty) return const SizedBox.shrink();
              final totalCount = CartService().totalItemCount;
              final totalPrice = CartService().totalPrice;
              final lastImg = cart.last['image'] ?? 'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=400&q=80';

              return Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CartScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD54F),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            lastImg,
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$totalCount Item${totalCount > 1 ? 's' : ''}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E1B4B),
                              ),
                            ),
                            Text(
                              'PKR $totalPrice',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1E1B4B),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Text(
                          'VIEW BASKET >>',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E1B4B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── PRODUCT ITEM CARD (Matching Provided Screenshots Exactly) ────
  Widget _buildMenuItemCard(Map<String, dynamic> item) {
    return Stack(
      children: [
        // Main Card (tapping opens Choose Item / ItemDetailScreen)
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ItemDetailScreen(
                    item: item,
                    onAddToCart: widget.onAddToCart,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF3F4F6)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      item['image'],
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Content Right
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title (padded right to leave clearance for the heart icon)
                        Padding(
                          padding: const EdgeInsets.only(right: 36.0),
                          child: Text(
                            item['name'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E1B4B),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Description
                        Text(
                          item['desc'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Price + Plus Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'PKR ${item['price']}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFFF5722),
                              ),
                            ),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFF3F4F6)),
                              ),
                              child: const Icon(
                                Icons.add,
                                size: 18,
                                color: Color(0xFF1E1B4B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Isolated Favorite Button on Top-Right
        // Positioned as a sibling in the Stack so clicking it strictly handles favorite toggle and NEVER triggers ItemDetailScreen
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              final added = FavoritesService().toggleFavorite(item);
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  duration: const Duration(seconds: 2),
                  backgroundColor: const Color(0xFF1E1B4B),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  content: Text(
                    added
                        ? '❤️ Added ${item['name']} to My Favorites!'
                        : 'Removed ${item['name']} from Favorites',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  action: added
                      ? SnackBarAction(
                          label: 'VIEW',
                          textColor: const Color(0xFFFF9800),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FavoritesScreen(
                                  onAddToCart: widget.onAddToCart,
                                ),
                              ),
                            );
                          },
                        )
                      : null,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              color: Colors.transparent,
              child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                valueListenable: FavoritesService().favoritesNotifier,
                builder: (context, favorites, _) {
                  final isFav = FavoritesService().isFavorite(item['id'] ?? item['name']);
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isFav ? const Color(0xFFFFF3ED) : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isFav ? const Color(0xFFFF5722) : const Color(0xFFF3F4F6),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                        color: isFav ? const Color(0xFFFF5722) : const Color(0xFF1E1B4B),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
