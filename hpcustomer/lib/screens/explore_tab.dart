import 'package:flutter/material.dart';
import 'item_detail_screen.dart';
import 'cart_screen.dart';
import 'explore_search_tab.dart';
import '../services/api_service.dart';
import '../services/favorites_service.dart';
import '../services/cart_service.dart';
import '../services/branch_service.dart';


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

  final List<Map<String, dynamic>> _menuCategories = [];

  bool _isAutoScrolling = false;

  bool _isLoading = true;
  bool _hasError = false;

  int _parsePrice(dynamic raw) {
    if (raw == null) return 0;
    if (raw is num) return raw.toInt();
    if (raw is String) {
      final parsed = double.tryParse(raw);
      if (parsed != null) return parsed.toInt();
    }
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _selectedCategoryIndex = widget.initialCategoryIndex;
    _categoryKeys.addAll(List.generate(_menuCategories.length, (_) => GlobalKey()));
    _scrollController.addListener(_onScroll);
    _fetchLiveMenu();
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
    if (index < 0 || index >= _categoryKeys.length) return;
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
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // 1. Fetch categories and products from backend
      final categories = await ApiService.fetchCategories();
      final products = await ApiService.fetchProducts();

      if (mounted) {
        final List<Map<String, dynamic>> menuCats = [];
        final Set<String> matchedProductIds = {};

        if (categories.isNotEmpty) {
          for (final cat in categories) {
            final catId = cat['id']?.toString() ?? '';
            final catName = cat['name']?.toString() ?? 'Category';

            // Filter products belonging to this category
            final catProducts = products.where((p) {
              final pCatId = p['categoryId']?.toString();
              final pCatName = p['category']?['name']?.toString();
              return (pCatId != null && pCatId == catId) ||
                  (pCatName != null && pCatName.toLowerCase() == catName.toLowerCase());
            }).toList();

            final List<Map<String, dynamic>> items = catProducts.map<Map<String, dynamic>>((p) {
              matchedProductIds.add(p['id'].toString());
              final images = p['images'] as List<dynamic>?;
              final rawImg = (images != null && images.isNotEmpty)
                  ? images.first.toString()
                  : p['image']?.toString();
              final imgUrl = ApiService.resolveImageUrl(rawImg);
              return {
                'id': p['id'].toString(),
                'name': p['name']?.toString() ?? 'Product',
                'desc': p['description']?.toString() ?? '',
                'price': _parsePrice(p['basePrice'] ?? p['price']),
                'image': imgUrl,
                'category': catName,
                'variants': p['variants'],
                'addons': p['addons'],
              };
            }).toList();

            // Also check embedded products in category object from backend
            if (items.isEmpty && cat['products'] != null && (cat['products'] as List).isNotEmpty) {
              for (final cp in cat['products']) {
                matchedProductIds.add(cp['id'].toString());
                final cpRaw = cp['image']?.toString();
                items.add({
                  'id': cp['id'].toString(),
                  'name': cp['name']?.toString() ?? 'Product',
                  'desc': cp['description']?.toString() ?? '',
                  'price': _parsePrice(cp['basePrice'] ?? cp['price']),
                  'image': ApiService.resolveImageUrl(cpRaw),
                  'category': catName,
                  'variants': cp['variants'],
                  'addons': cp['addons'],
                });
              }
            }

            menuCats.add({
              'id': catId,
              'title': catName,
              'items': items,
            });
          }
        }

        // Include any remaining products not matched to existing categories
        final remainingProducts = products.where((p) => !matchedProductIds.contains(p['id'].toString())).toList();
        if (remainingProducts.isNotEmpty) {
          final Map<String, List<Map<String, dynamic>>> grouped = {};
          for (final p in remainingProducts) {
            final catName = (p['category'] != null && p['category']['name'] != null)
                ? p['category']['name'].toString()
                : 'Specialties';

            final images = p['images'] as List<dynamic>?;
            final rawImg = (images != null && images.isNotEmpty)
                ? images.first.toString()
                : p['image']?.toString();
            final imgUrl = ApiService.resolveImageUrl(rawImg);

            final item = {
              'id': p['id'].toString(),
              'name': p['name']?.toString() ?? 'Product',
              'desc': p['description']?.toString() ?? '',
              'price': _parsePrice(p['basePrice'] ?? p['price']),
              'image': imgUrl,
              'category': catName,
              'variants': p['variants'],
              'addons': p['addons'],
            };

            grouped.putIfAbsent(catName, () => []).add(item);
          }

          for (final entry in grouped.entries) {
            menuCats.add({
              'title': entry.key,
              'items': entry.value,
            });
          }
        }

        setState(() {
          _isLoading = false;
          _hasError = false;
          _menuCategories.clear();
          _menuCategories.addAll(menuCats);
          _categoryKeys.clear();
          _categoryKeys.addAll(List.generate(_menuCategories.length, (_) => GlobalKey()));
          if (_selectedCategoryIndex >= _menuCategories.length) {
            _selectedCategoryIndex = 0;
          }
        });

        if (widget.initialCategoryIndex > 0 && widget.initialCategoryIndex < _menuCategories.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToCategory(widget.initialCategoryIndex);
          });
        }
      }
    } catch (e) {
      debugPrint('Live API fetch error in explore: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else if (widget.onBackToHome != null) {
                  widget.onBackToHome!();
                }
              },
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Explore Menu',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E1B4B),
                  ),
                ),
                const SizedBox(height: 3),
                ValueListenableBuilder<Branch?>(
                  valueListenable: BranchService().selectedBranchNotifier,
                  builder: (context, branch, _) {
                    final title = branch?.name ?? (BranchService().allBranches.isNotEmpty ? BranchService().allBranches.first.name : 'HungerPoint');
                    return Text(
                      title,
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
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ExploreSearchScreen(
                            onAddToCart: widget.onAddToCart,
                            onBackToHome: () => Navigator.pop(context),
                            onOpenExploreMenu: () => Navigator.pop(context),
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
                child: _isLoading && _menuCategories.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD600)),
                        ),
                      )
                    : _menuCategories.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _hasError ? Icons.wifi_off_rounded : Icons.restaurant_menu_rounded,
                                    size: 56,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _hasError ? 'Failed to load menu' : 'No menu items found',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E1B4B),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _hasError
                                        ? 'Could not connect to the server. Please check your network.'
                                        : 'Menu categories will appear here once added.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  ElevatedButton.icon(
                                    onPressed: _fetchLiveMenu,
                                    icon: const Icon(Icons.refresh, size: 18),
                                    label: const Text('Try Again'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF5722),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            color: const Color(0xFFFF5722),
                            onRefresh: _fetchLiveMenu,
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                              controller: _scrollController,
                              padding: EdgeInsets.fromLTRB(16, 12, 16, 100 + MediaQuery.of(context).padding.bottom),
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
                                    if (items.isEmpty)
                                      const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                        child: Text(
                                          'No products added to this category yet.',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF9CA3AF),
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      )
                                    else
                                      ...items.map((item) => Padding(
                                            padding: const EdgeInsets.only(bottom: 14.0),
                                            child: _buildMenuItemCard(item),
                                          )),
                                  ],
                                );
                              },
                            ),
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
              final bottomInset = MediaQuery.of(context).padding.bottom;

              return Positioned(
                bottom: bottomInset + 20,
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
                            ApiService.resolveImageUrl(lastImg),
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Container(
                              width: 36,
                              height: 36,
                              color: const Color(0xFFFFF7ED),
                              child: const Center(child: Text('🍕', style: TextStyle(fontSize: 18))),
                            ),
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
                      ApiService.resolveImageUrl(item['image']?.toString()),
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        width: 90,
                        height: 90,
                        color: const Color(0xFFFFF7ED),
                        child: const Center(child: Text('🍕', style: TextStyle(fontSize: 32))),
                      ),
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
                                  child: count == 0
                                      ? Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: const Color(0xFFF3F4F6)),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.04),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.add,
                                            size: 18,
                                            color: Color(0xFF1E1B4B),
                                          ),
                                        )
                                      : Container(
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
                                            child: Text(
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
        // Positioned as a sibling in the Stack so clicking it strictly handles favorite toggle and NEVER triggers ItemDetailScreen
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
