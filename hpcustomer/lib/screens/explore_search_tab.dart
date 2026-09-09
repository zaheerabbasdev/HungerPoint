import 'package:flutter/material.dart';
import '../services/cart_service.dart';
import '../services/favorites_service.dart';
import '../services/api_service.dart';
import '../services/branch_service.dart';
import 'item_detail_screen.dart';
import 'explore_tab.dart';

class ExploreSearchScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onAddToCart;
  final VoidCallback? onBackToHome;
  final VoidCallback? onOpenExploreMenu;

  const ExploreSearchScreen({
    super.key,
    required this.onAddToCart,
    this.onBackToHome,
    this.onOpenExploreMenu,
  });

  @override
  State<ExploreSearchScreen> createState() => _ExploreSearchScreenState();
}

class _ExploreSearchScreenState extends State<ExploreSearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<String> get _popularSearches {
    if (_liveItems.isNotEmpty) {
      final names = <String>[];
      for (final it in _liveItems) {
        final n = it['name']?.toString().trim();
        if (n != null && n.isNotEmpty && !names.contains(n)) {
          names.add(n);
        }
      }
      if (names.isNotEmpty) return names.take(8).toList();
    }
    return [
      'Chicken Pepperoni Pizza',
      'Reggy Burger',
      'Euro',
      'Cheese Lover Pizza',
      'Behari Kabab',
      'Chicken Mushroom',
    ];
  }

  List<Map<String, dynamic>> _liveItems = [];
  List<Map<String, dynamic>> get _currentItems => _liveItems;

  @override
  void initState() {
    super.initState();
    _fetchLiveProducts();
    BranchService().fetchBranchesFromBackend();
  }

  Future<void> _fetchLiveProducts() async {
    try {
      final products = await ApiService.fetchProducts();
      if (products.isNotEmpty && mounted) {
        final list = products.map<Map<String, dynamic>>((p) {
          final images = p['images'] as List<dynamic>?;
          final rawImg = (images != null && images.isNotEmpty)
              ? images.first.toString()
              : p['image']?.toString();
          final imgUrl = ApiService.resolveImageUrl(rawImg);
          final rawPrice = p['basePrice'] ?? p['price'];
          final price = rawPrice is num
              ? rawPrice.toInt()
              : (rawPrice is String ? (double.tryParse(rawPrice)?.toInt() ?? 0) : 0);
          return {
            'id': p['id'].toString(),
            'name': p['name']?.toString() ?? 'Product',
            'desc': p['description']?.toString() ?? '',
            'price': price,
            'image': imgUrl,
            'category': (p['category'] != null && p['category']['name'] != null)
                ? p['category']['name'].toString()
                : '',
            'variants': p['variants'],
            'addons': p['addons'],
          };
        }).toList();
        setState(() {
          _liveItems = list;
        });
      }
    } catch (e) {
      debugPrint('Error fetching live search items: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final isSearching = query.isNotEmpty;

    final matchingItems = isSearching
        ? _currentItems.where((item) {
            final name = (item['name'] ?? '').toString().toLowerCase();
            final desc = (item['desc'] ?? '').toString().toLowerCase();
            final cat = (item['category'] ?? '').toString().toLowerCase();
            return name.contains(query) || desc.contains(query) || cat.contains(query);
          }).toList()
        : <Map<String, dynamic>>[];

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E1B4B)),
          onPressed: () {
            if (isSearching) {
              _searchController.clear();
              setState(() {});
            } else if (widget.onBackToHome != null) {
              widget.onBackToHome!();
            } else if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Find HungerPoint Items',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E1B4B),
              ),
            ),
            const SizedBox(height: 2),
            ValueListenableBuilder<Branch?>(
              valueListenable: BranchService().selectedBranchNotifier,
              builder: (context, branch, _) {
                final branchTitle = branch?.name ?? (BranchService().allBranches.isNotEmpty ? BranchService().allBranches.first.name : 'Islamabad');
                return Text(
                  branchTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF9CA3AF),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── 1. SEARCH INPUT BOX ───
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF3F4F6)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    textAlignVertical: TextAlignVertical.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1B4B),
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF9CA3AF),
                        size: 22,
                      ),
                      hintText: 'Search your favorite items',
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF9CA3AF),
                        fontWeight: FontWeight.normal,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() {});
                              },
                              child: Container(
                                margin: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF5722),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),

              // ─── 2. POPULAR SEARCHES ───
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                child: Text(
                  'Popular Searches',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E1B4B),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _popularSearches.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 10),
                  itemBuilder: (context, idx) {
                    final term = _popularSearches[idx];
                    return GestureDetector(
                      onTap: () {
                        _searchController.text = term;
                        _searchController.selection = TextSelection.fromPosition(
                          TextPosition(offset: term.length),
                        );
                        setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFF3F4F6)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            term,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E1B4B),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),

              // ─── 3. CONTENT AREA ───
              Expanded(
                child: isSearching
                    ? (matchingItems.isEmpty
                        ? RefreshIndicator(
                            color: const Color(0xFFFF5722),
                            onRefresh: _fetchLiveProducts,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: _buildEmptyState(),
                            ),
                          )
                        : RefreshIndicator(
                            color: const Color(0xFFFF5722),
                            onRefresh: _fetchLiveProducts,
                            child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                              itemCount: matchingItems.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                final item = matchingItems[index];
                                return _buildItemCard(item);
                              },
                            ),
                          ))
                    : RefreshIndicator(
                        color: const Color(0xFFFF5722),
                        onRefresh: _fetchLiveProducts,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          children: [
                            // "Explore Menu >" Card (Matching First Image)
                            GestureDetector(
                              onTap: () {
                                if (widget.onOpenExploreMenu != null) {
                                  widget.onOpenExploreMenu!();
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ExploreMenuScreen(
                                        onAddToCart: widget.onAddToCart,
                                        cart: CartService().items,
                                        initialCategoryIndex: 0,
                                        onBackToHome: () => Navigator.pop(context),
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFF3F4F6)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: const [
                                    Text(
                                      'Explore Menu',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1E1B4B),
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: Color(0xFF1E1B4B),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),

                            // "HungerPoint - No Products Found" Card
                            _buildEmptyState(),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── HUNGERPOINT LOGO & NO PRODUCTS FOUND CARD ───
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Illustration of Pizza, Burger & Drink
          SizedBox(
            width: 140,
            height: 110,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Top Arched Pizza Slice
                Positioned(
                  top: 0,
                  left: 24,
                  child: Container(
                    width: 72,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB300),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(36),
                        topRight: Radius.circular(36),
                        bottomLeft: Radius.circular(10),
                      ),
                      border: Border.all(color: const Color(0xFF4E2A1D), width: 3),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 14,
                          left: 12,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Color(0xFFD32F2F),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 24,
                          left: 36,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFFD32F2F),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Cheeseburger in center
                Positioned(
                  bottom: 12,
                  left: 20,
                  child: Container(
                    width: 66,
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC107),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFF4E2A1D), width: 3),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 52,
                          height: 6,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          width: 52,
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFF795548),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Drink cup with straw on the right
                Positioned(
                  bottom: 14,
                  right: 22,
                  child: Container(
                    width: 38,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB300),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(6),
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                      border: Border.all(color: const Color(0xFF4E2A1D), width: 3),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: -12,
                          right: 10,
                          child: Container(
                            width: 5,
                            height: 24,
                            color: const Color(0xFF4E2A1D),
                          ),
                        ),
                        Center(
                          child: Container(
                            width: 20,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Center(
                              child: Text(
                                '🧀',
                                style: TextStyle(fontSize: 10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Brand Title
          const Text(
            'HungerPoint',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF4E2A1D),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),

          // No Products Found
          const Text(
            'No Products Found',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E1B4B),
            ),
          ),
        ],
      ),
    );
  }

  // ─── SEARCH RESULT ITEM CARD (Matching Second Image) ───
  Widget _buildItemCard(Map<String, dynamic> item) {
    return Stack(
      children: [
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
                children: [
                  // Item Image inside rounded card
                  Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        ApiService.resolveImageUrl(item['image']?.toString()),
                        width: 82,
                        height: 82,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 82,
                          height: 82,
                          color: const Color(0xFFF3F4F6),
                          child: const Icon(Icons.fastfood, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Item Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 36.0),
                          child: Text(
                            item['name'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E1B4B),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
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
                            ValueListenableBuilder<List<Map<String, dynamic>>>(
                              valueListenable: CartService().cartNotifier,
                              builder: (context, cart, _) {
                                final count = CartService().getItemCount(item['id'], item['name']);

                                return GestureDetector(
                                  behavior: HitTestBehavior.opaque,
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
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFFE5E7EB)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.04),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: count == 0
                                          ? const Icon(
                                              Icons.add,
                                              size: 18,
                                              color: Color(0xFF1E1B4B),
                                            )
                                          : Text(
                                              '$count',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF1E1B4B),
                                              ),
                                            ),
                                    ),
                                  ),
                                );
                              },
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
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              FavoritesService().toggleFavorite(item);
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
