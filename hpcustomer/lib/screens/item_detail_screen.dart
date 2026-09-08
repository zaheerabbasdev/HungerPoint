import 'package:flutter/material.dart';
import '../services/favorites_service.dart';
import '../services/cart_service.dart';
import '../widgets/top_toast.dart';
import 'cart_screen.dart';

class ItemDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  final Function(Map<String, dynamic>) onAddToCart;

  const ItemDetailScreen({
    super.key,
    required this.item,
    required this.onAddToCart,
  });

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  int? _selectedVariationIndex;
  int _quantity = 1;
  late List<Map<String, dynamic>> _variations;
  late int _basePrice;

  String? _selectedFlavour;
  Map<String, dynamic>? _selectedDrink;
  final Set<String> _selectedToppingIds = {};
  final TextEditingController _instructionsController = TextEditingController();

  bool get _isPizza {
    final name = (widget.item['name'] ?? '').toString().toLowerCase();
    final cat = (widget.item['category'] ?? '').toString().toLowerCase();
    final desc = (widget.item['desc'] ?? '').toString().toLowerCase();
    return name.contains('pizza') || cat.contains('pizza') || desc.contains('pizza') || desc.contains('crust');
  }

  bool get _isBurger {
    final name = (widget.item['name'] ?? '').toString().toLowerCase();
    final cat = (widget.item['category'] ?? '').toString().toLowerCase();
    return name.contains('burger') || cat.contains('burger');
  }

  @override
  void initState() {
    super.initState();

    final rawPrice = widget.item['price'];
    _basePrice = (rawPrice is num)
        ? rawPrice.toInt()
        : (int.tryParse(rawPrice?.toString() ?? '1450') ?? 1450);

    // 1. Build size variations
    final backendVariants = widget.item['variants'] as List<dynamic>?;
    if (backendVariants != null && backendVariants.isNotEmpty) {
      _variations = backendVariants.map<Map<String, dynamic>>((v) {
        final rawP = v['price'];
        final p = rawP is num ? rawP.toInt() : (double.tryParse(rawP.toString())?.toInt() ?? _basePrice);
        final name = v['name']?.toString() ?? 'Regular';
        return {
          'id': v['id']?.toString() ?? name,
          'name': name,
          'price': p,
          'sizeKey': _normalizeSizeKey(name),
        };
      }).toList();
    } else if (_isPizza) {
      _variations = [
        {'id': 'v_small', 'name': 'Small', 'price': (_basePrice * 0.72).round(), 'sizeKey': 'small'},
        {'id': 'v_regular', 'name': 'Regular', 'price': _basePrice, 'sizeKey': 'regular'},
        {'id': 'v_large', 'name': 'Large', 'price': (_basePrice * 1.38).round(), 'sizeKey': 'large'},
        {'id': 'v_party', 'name': 'Party Size', 'price': (_basePrice * 1.88).round(), 'sizeKey': 'party'},
      ];
    } else if (_isBurger) {
      _variations = [
        {'id': 'v_single', 'name': 'Single Patty', 'price': _basePrice, 'sizeKey': 'regular'},
        {'id': 'v_double', 'name': 'Double Patty', 'price': (_basePrice * 1.40).round(), 'sizeKey': 'large'},
        {'id': 'v_combo', 'name': 'Meal Combo (Fries & Drink)', 'price': (_basePrice * 1.60).round(), 'sizeKey': 'party'},
      ];
    } else {
      _variations = [
        {'id': 'v_regular', 'name': 'Regular', 'price': _basePrice, 'sizeKey': 'regular'},
        {'id': 'v_large', 'name': 'Large', 'price': (_basePrice * 1.35).round(), 'sizeKey': 'large'},
      ];
    }

    // Initially uncheck variation size as requested
    _selectedVariationIndex = null;

    // Initially uncheck all flavours as requested
    _selectedFlavour = null;

    // Initially uncheck drink selection
    _selectedDrink = null;
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  String _normalizeSizeKey(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('small')) return 'small';
    if (lower.contains('party') || lower.contains('extra large') || lower.contains('xl') || lower.contains('jumbo')) {
      return 'party';
    }
    if (lower.contains('large')) return 'large';
    return 'regular';
  }

  String get _currentSizeKey {
    if (_selectedVariationIndex == null || _selectedVariationIndex! >= _variations.length) {
      return 'regular';
    }
    return _variations[_selectedVariationIndex!]['sizeKey'] as String? ?? 'regular';
  }

  String get _currentSizeName {
    if (_selectedVariationIndex == null || _selectedVariationIndex! >= _variations.length) {
      return 'Regular';
    }
    return _variations[_selectedVariationIndex!]['name'] as String? ?? 'Regular';
  }

  // ─── FLAVOURS ──────────────────────────────────────────────────
  List<Map<String, String>> get _pizzaFlavours => [
        {
          'name': 'Chicken Tikka',
          'desc': 'Traditional spicy marinated chicken with fresh onions & herbs',
        },
        {
          'name': 'Chicken Fajita',
          'desc': 'Mexican spiced chicken with crisp bell peppers & onions',
        },
        {
          'name': 'Spicy Ranch',
          'desc': 'Tender chicken strips drizzled with creamy garlic ranch sauce',
        },
        {
          'name': 'BBQ Buzz',
          'desc': 'Smokey barbecue chicken chunks with red onions & mushrooms',
        },
        {
          'name': 'Creamy Afghani',
          'desc': 'Rich creamy base, garlic chicken chunks & melted mozzarella',
        },
        {
          'name': 'Pepperoni Passion',
          'desc': 'Loaded beef pepperoni with premium double mozzarella cheese',
        },
        {
          'name': 'Veggie Supreme',
          'desc': 'Sweet corn, mushrooms, olives, bell peppers & juicy tomatoes',
        },
        {
          'name': 'Cheese Feast',
          'desc': 'Triple blend of melted mozzarella, cheddar & parmesan cheese',
        },
      ];

  List<Map<String, String>> get _burgerFlavours => [
        {
          'name': 'Classic Crispy',
          'desc': 'Mildly seasoned crunchy recipe with signature sauce',
        },
        {
          'name': 'Spicy Jalapeño',
          'desc': 'Fiery chili glaze with pickled jalapeños & hot sauce',
        },
        {
          'name': 'Smokey BBQ',
          'desc': 'Sweet and smokey barbecue glaze with caramelized onions',
        },
      ];

  // ─── DRINKS ────────────────────────────────────────────────────
  List<Map<String, dynamic>> get _drinkOptions => [
        {'name': 'Coca-Cola (345ml)', 'price': 140, 'tag': 'Chilled'},
        {'name': 'Sprite (345ml)', 'price': 140, 'tag': 'Chilled'},
        {'name': 'Fanta (345ml)', 'price': 140, 'tag': 'Chilled'},
        {'name': 'Diet Coke (345ml Can)', 'price': 160, 'tag': 'Sugar Free'},
        {'name': 'Fresh Lime Soda', 'price': 180, 'tag': 'Refreshing'},
        {'name': 'Mint Margarita', 'price': 220, 'tag': 'Signature'},
        {'name': 'Nestle Mineral Water (500ml)', 'price': 80, 'tag': 'Pure'},
      ];

  // ─── ALL TOPPINGS CATALOG (Size-tagged for dynamic filtering) ───
  List<Map<String, dynamic>> _getAllToppingsCatalog() {
    return [
      // Small Toppings
      {
        'id': 'top_cheese_small',
        'name': 'Extra Cheese (Small)',
        'price': 120,
        'sizeKey': 'small',
        'baseToppingKey': 'cheese',
      },
      {
        'id': 'top_chicken_small',
        'name': 'Extra Chicken / Meat (Small)',
        'price': 150,
        'sizeKey': 'small',
        'baseToppingKey': 'chicken',
      },
      {
        'id': 'top_olives_small',
        'name': 'Black Olives & Mushrooms (Small)',
        'price': 80,
        'sizeKey': 'small',
        'baseToppingKey': 'olives',
      },
      {
        'id': 'top_jalapenos_small',
        'name': 'Pickled Jalapeños (Small)',
        'price': 60,
        'sizeKey': 'small',
        'baseToppingKey': 'jalapenos',
      },

      // Regular Toppings
      {
        'id': 'top_cheese_regular',
        'name': 'Extra Cheese (Regular)',
        'price': 180,
        'sizeKey': 'regular',
        'baseToppingKey': 'cheese',
      },
      {
        'id': 'top_chicken_regular',
        'name': 'Extra Chicken / Meat (Regular)',
        'price': 220,
        'sizeKey': 'regular',
        'baseToppingKey': 'chicken',
      },
      {
        'id': 'top_olives_regular',
        'name': 'Black Olives & Mushrooms (Regular)',
        'price': 120,
        'sizeKey': 'regular',
        'baseToppingKey': 'olives',
      },
      {
        'id': 'top_jalapenos_regular',
        'name': 'Pickled Jalapeños (Regular)',
        'price': 90,
        'sizeKey': 'regular',
        'baseToppingKey': 'jalapenos',
      },
      {
        'id': 'top_stuffed_crust_regular',
        'name': 'Cheese Stuffed Crust (Regular)',
        'price': 200,
        'sizeKey': 'regular',
        'baseToppingKey': 'stuffed_crust',
      },

      // Large Toppings
      {
        'id': 'top_cheese_large',
        'name': 'Extra Cheese (Large)',
        'price': 260,
        'sizeKey': 'large',
        'baseToppingKey': 'cheese',
      },
      {
        'id': 'top_chicken_large',
        'name': 'Extra Chicken / Meat (Large)',
        'price': 320,
        'sizeKey': 'large',
        'baseToppingKey': 'chicken',
      },
      {
        'id': 'top_olives_large',
        'name': 'Black Olives & Mushrooms (Large)',
        'price': 160,
        'sizeKey': 'large',
        'baseToppingKey': 'olives',
      },
      {
        'id': 'top_jalapenos_large',
        'name': 'Pickled Jalapeños (Large)',
        'price': 120,
        'sizeKey': 'large',
        'baseToppingKey': 'jalapenos',
      },
      {
        'id': 'top_cheese_crust_large',
        'name': 'Cheese Stuffed Crust (Large)',
        'price': 280,
        'sizeKey': 'large',
        'baseToppingKey': 'stuffed_crust',
      },
      {
        'id': 'top_kabab_crust_large',
        'name': 'Kabab Stuffed Crust (Large)',
        'price': 330,
        'sizeKey': 'large',
        'baseToppingKey': 'kabab_crust',
      },

      // Party Size / Extra Large Toppings
      {
        'id': 'top_cheese_party',
        'name': 'Extra Cheese (Party Size)',
        'price': 360,
        'sizeKey': 'party',
        'baseToppingKey': 'cheese',
      },
      {
        'id': 'top_chicken_party',
        'name': 'Extra Chicken / Meat (Party Size)',
        'price': 450,
        'sizeKey': 'party',
        'baseToppingKey': 'chicken',
      },
      {
        'id': 'top_olives_party',
        'name': 'Black Olives & Mushrooms (Party Size)',
        'price': 220,
        'sizeKey': 'party',
        'baseToppingKey': 'olives',
      },
      {
        'id': 'top_jalapenos_party',
        'name': 'Pickled Jalapeños (Party Size)',
        'price': 160,
        'sizeKey': 'party',
        'baseToppingKey': 'jalapenos',
      },
      {
        'id': 'top_cheese_crust_party',
        'name': 'Cheese Stuffed Crust (Party Size)',
        'price': 380,
        'sizeKey': 'party',
        'baseToppingKey': 'stuffed_crust',
      },
      {
        'id': 'top_kabab_crust_party',
        'name': 'Kabab Stuffed Crust (Party Size)',
        'price': 440,
        'sizeKey': 'party',
        'baseToppingKey': 'kabab_crust',
      },

      // Universal Dips & Sauces (available for all sizes)
      {
        'id': 'top_garlic_dip',
        'name': 'Garlic Mayo Dip Cup',
        'price': 70,
        'sizeKey': 'all',
        'baseToppingKey': 'garlic_dip',
      },
      {
        'id': 'top_ranch_dip',
        'name': 'Creamy Ranch Dip Cup',
        'price': 80,
        'sizeKey': 'all',
        'baseToppingKey': 'ranch_dip',
      },
      {
        'id': 'top_chipotle_dip',
        'name': 'Smoky Chipotle Dip Cup',
        'price': 80,
        'sizeKey': 'all',
        'baseToppingKey': 'chipotle_dip',
      },
    ];
  }

  /// Returns only the toppings that match the currently selected size (or 'all')
  List<Map<String, dynamic>> get _filteredToppings {
    final currentKey = _currentSizeKey;
    final all = _getAllToppingsCatalog();
    return all.where((t) {
      final key = t['sizeKey'] as String;
      return key == currentKey || key == 'all';
    }).toList();
  }

  /// When changing variation size, enable flavours and migrate toppings
  void _onVariationSelected(int newIndex) {
    final isFirstSelection = _selectedVariationIndex == null;

    final allCatalog = _getAllToppingsCatalog();
    final selectedBaseKeys = <String>{};

    for (final id in _selectedToppingIds) {
      final match = allCatalog.firstWhere(
        (t) => t['id'] == id,
        orElse: () => {},
      );
      if (match.isNotEmpty && match['baseToppingKey'] != null) {
        selectedBaseKeys.add(match['baseToppingKey'] as String);
      }
    }

    setState(() {
      _selectedVariationIndex = newIndex;

      // If user selected size for first time, ensure flavours and drink start unchecked as requested
      if (isFirstSelection) {
        _selectedFlavour = null;
        _selectedDrink = null;
      }

      // Re-populate with matching toppings for the newly selected size
      _selectedToppingIds.clear();
      final newAvailable = _filteredToppings;
      for (final t in newAvailable) {
        if (selectedBaseKeys.contains(t['baseToppingKey'])) {
          _selectedToppingIds.add(t['id'] as String);
        }
      }
    });
  }

  // ─── PRICE CALCULATION ─────────────────────────────────────────
  int get _selectedUnitPrice {
    final variationPrice = (_selectedVariationIndex != null &&
            _selectedVariationIndex! < _variations.length)
        ? (_variations[_selectedVariationIndex!]['price'] as int)
        : _basePrice;

    int toppingsPrice = 0;
    final allCatalog = _getAllToppingsCatalog();
    for (final id in _selectedToppingIds) {
      final match = allCatalog.firstWhere((t) => t['id'] == id, orElse: () => {});
      if (match.isNotEmpty) {
        toppingsPrice += (match['price'] as int? ?? 0);
      }
    }

    final drinkPrice = (_selectedDrink != null) ? (_selectedDrink!['price'] as int? ?? 0) : 0;

    return variationPrice + toppingsPrice + drinkPrice;
  }

  int get _totalOrderPrice => _selectedUnitPrice * _quantity;

  void _handleAddToCart() {
    if (_selectedVariationIndex == null) {
      TopToast.show(context, 'Please select a variation size:');
      return;
    }

    if (_isPizza && (_selectedFlavour == null || _selectedFlavour!.isEmpty)) {
      TopToast.show(context, 'Please select a pizza flavour:');
      return;
    }

    if (_isBurger && (_selectedFlavour == null || _selectedFlavour!.isEmpty)) {
      TopToast.show(context, 'Please select a burger flavour:');
      return;
    }

    final allCatalog = _getAllToppingsCatalog();
    final selectedToppingsList = _selectedToppingIds.map((id) {
      return allCatalog.firstWhere(
        (t) => t['id'] == id,
        orElse: () => {'name': id, 'price': 0},
      );
    }).toList();

    final variationName = _variations[_selectedVariationIndex!]['name'].toString();

    final cartItem = {
      'id': widget.item['id'] ?? widget.item['name'],
      'productId': widget.item['id'],
      'name': widget.item['name'],
      'desc': widget.item['desc'],
      'image': widget.item['image'],
      'variation': variationName,
      'flavour': _selectedFlavour ?? '',
      'drink': _selectedDrink != null ? _selectedDrink!['name'] : '',
      'toppings': selectedToppingsList,
      'instructions': _instructionsController.text.trim(),
      'price': _selectedUnitPrice,
      'quantity': _quantity,
    };

    final overlay = Overlay.of(context, rootOverlay: true);
    widget.onAddToCart(cartItem);
    Navigator.pop(context);
    TopToast.showWithOverlay(overlay, 'Product has been added to cart');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E1B4B), size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Choose Item',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E1B4B),
              ),
            ),
            SizedBox(height: 2),
            Text(
              'HungerPoint Signature Menu',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF9CA3AF),
                fontWeight: FontWeight.w500,
              ),
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
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
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
                          const Icon(
                            Icons.shopping_cart_outlined,
                            color: Color(0xFF1E1B4B),
                            size: 20,
                          ),
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
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── SCROLLABLE CUSTOMIZATION OPTIONS ───
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Stack(
                      children: [
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxHeight: 250,
                              minHeight: 190,
                            ),
                            child: Image.network(
                              widget.item['image'] ?? '',
                              fit: BoxFit.contain,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 200,
                                color: const Color(0xFFF9FAFB),
                                child: const Center(
                                  child: Icon(Icons.fastfood, size: 64, color: Colors.grey),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Heart Favorite Button
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              FavoritesService().toggleFavorite(widget.item);
                            },
                            child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                              valueListenable: FavoritesService().favoritesNotifier,
                              builder: (context, favorites, _) {
                                final isFav = FavoritesService().isFavorite(widget.item['id'] ?? widget.item['name']);
                                return Container(
                                  padding: const EdgeInsets.all(8),
                                  color: Colors.transparent,
                                  child: Icon(
                                    isFav ? Icons.favorite : Icons.favorite_border,
                                    color: isFav ? const Color(0xFFFF5722) : const Color(0xFF1E1B4B),
                                    size: 26,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Item Details Info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E1B4B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.item['desc'] ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Starting from PKR ${_variations.isNotEmpty ? _variations.first['price'] : widget.item['price']}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFF5722),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ─── 1. VARIATION / SIZE SELECTION (REQUIRED, UNCHECKED INITIALLY) ───
                        _buildSectionHeader(
                          title: 'Variation (Size)',
                          badgeText: 'REQUIRED',
                          badgeColor: const Color(0xFFFEF08A),
                          badgeTextColor: const Color(0xFF854D0E),
                        ),
                        const SizedBox(height: 12),
                        ...List.generate(_variations.length, (idx) {
                          final v = _variations[idx];
                          final isSel = _selectedVariationIndex == idx;
                          return InkWell(
                            onTap: () => _onVariationSelected(idx),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10.0),
                              child: Row(
                                children: [
                                  _buildRadioCircle(isSel),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      v['name'],
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                        color: const Color(0xFF1E1B4B),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'PKR ${v['price']}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E1B4B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 28),

                        // ─── BELOW DETAILS SHOWN ONLY AFTER VARIATION IS SELECTED ───
                        if (_selectedVariationIndex != null) ...[
                          // ─── 2. FLAVOUR SELECTION (ALL UNCHECKED INITIALLY) ───
                          if (_isPizza || _isBurger) ...[
                            _buildSectionHeader(
                              title: _isPizza ? 'Pizza Flavour' : 'Flavour Choice',
                              badgeText: 'REQUIRED',
                              badgeColor: const Color(0xFFFEF08A),
                              badgeTextColor: const Color(0xFF854D0E),
                            ),
                            const SizedBox(height: 12),
                            ...(_isPizza ? _pizzaFlavours : _burgerFlavours).map((f) {
                              final isSel = _selectedFlavour == f['name'];
                              return InkWell(
                                onTap: () => setState(() => _selectedFlavour = f['name']),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2.0),
                                        child: _buildRadioCircle(isSel),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              f['name']!,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                                                color: const Color(0xFF1E1B4B),
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              f['desc']!,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF9CA3AF),
                                                height: 1.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: 28),
                          ],

                          // ─── 3. DRINK FLAVOUR SELECTION (ALL UNCHECKED INITIALLY) ───
                          _buildSectionHeader(
                            title: 'Drink Flavour',
                            badgeText: 'OPTIONAL',
                            badgeColor: const Color(0xFFF3F4F6),
                            badgeTextColor: const Color(0xFF4B5563),
                          ),
                          const SizedBox(height: 12),
                          ..._drinkOptions.map((d) {
                            final isSel = _selectedDrink?['name'] == d['name'];
                            final price = d['price'] as int;
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  if (isSel) {
                                    _selectedDrink = null;
                                  } else {
                                    _selectedDrink = d;
                                  }
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10.0),
                                child: Row(
                                  children: [
                                    _buildRadioCircle(isSel),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Wrap(
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        spacing: 6,
                                        runSpacing: 2,
                                        children: [
                                          Text(
                                            d['name'],
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                              color: const Color(0xFF1E1B4B),
                                            ),
                                          ),
                                          if (d['tag'] != null)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF3F4F6),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                d['tag'],
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF6B7280),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '+PKR $price',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFFF5722),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 28),

                          // ─── 4. DYNAMIC EXTRA TOPPINGS (MATCHED TO SELECTED SIZE) ───
                          _buildSectionHeader(
                            title: 'Extra Toppings (for $_currentSizeName)',
                            badgeText: 'OPTIONAL • Multi-select',
                            badgeColor: const Color(0xFFF3F4F6),
                            badgeTextColor: const Color(0xFF4B5563),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Toppings & crusts adapted dynamically for $_currentSizeName size:',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9CA3AF),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._filteredToppings.map((t) {
                            final tid = t['id'] as String;
                            final isChecked = _selectedToppingIds.contains(tid);
                            final price = t['price'] as int;

                            return InkWell(
                              onTap: () {
                                setState(() {
                                  if (isChecked) {
                                    _selectedToppingIds.remove(tid);
                                  } else {
                                    _selectedToppingIds.add(tid);
                                  }
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10.0),
                                child: Row(
                                  children: [
                                    // Custom Square Checkbox Indicator
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: isChecked ? const Color(0xFFFF5722) : Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isChecked ? const Color(0xFFFF5722) : const Color(0xFFD1D5DB),
                                          width: 2,
                                        ),
                                      ),
                                      child: isChecked
                                          ? const Center(
                                              child: Icon(
                                                Icons.check,
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        t['name'],
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isChecked ? FontWeight.bold : FontWeight.w500,
                                          color: const Color(0xFF1E1B4B),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '+PKR $price',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFFF5722),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 28),

                          // ─── 5. SPECIAL INSTRUCTIONS / NOTES ───
                          _buildSectionHeader(
                            title: 'Special Instructions',
                            badgeText: 'OPTIONAL',
                            badgeColor: const Color(0xFFF3F4F6),
                            badgeTextColor: const Color(0xFF4B5563),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _instructionsController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: 'e.g., Less spicy, extra crispy, sauce on the side...',
                              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFFF5722)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── BOTTOM BAR: STEPPER & DYNAMIC ADD BUTTON ───
          SafeArea(
            top: false,
            bottom: true,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(top: BorderSide(color: Color(0xFFF3F4F6))),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Stepper [-] 1 [+]
                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          splashRadius: 20,
                          icon: const Icon(
                            Icons.remove,
                            size: 18,
                            color: Color(0xFF1E1B4B),
                          ),
                          onPressed: () {
                            if (_quantity > 1) setState(() => _quantity--);
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          child: Text(
                            '$_quantity',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E1B4B),
                            ),
                          ),
                        ),
                        IconButton(
                          splashRadius: 20,
                          icon: const Icon(
                            Icons.add,
                            size: 18,
                            color: Color(0xFF1E1B4B),
                          ),
                          onPressed: () => setState(() => _quantity++),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Dynamic Yellow ADD Button
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _handleAddToCart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD54F),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          _selectedVariationIndex == null
                              ? 'ADD   Rs: $_totalOrderPrice'
                              : 'ADD   Rs: $_totalOrderPrice',
                          style: const TextStyle(
                            color: Color(0xFF1E1B4B),
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
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
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String badgeText,
    required Color badgeColor,
    required Color badgeTextColor,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E1B4B),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            badgeText,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: badgeTextColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRadioCircle(bool isSelected) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? const Color(0xFFFF5722) : const Color(0xFFD1D5DB),
          width: isSelected ? 6 : 2,
        ),
      ),
    );
  }
}
