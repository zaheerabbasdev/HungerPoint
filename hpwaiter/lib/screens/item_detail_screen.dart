import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/api_service.dart';
import 'cart_review_screen.dart';

class ItemDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  final Map<String, dynamic> table;
  final Function(Map<String, dynamic>) onAddToCart;

  const ItemDetailScreen({
    super.key,
    required this.item,
    required this.table,
    required this.onAddToCart,
  });

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  int? _selectedVariationIndex;
  int _quantity = 1;
  late List<Map<String, dynamic>> _variations;
  late bool _hasRealVariants;
  late int _basePrice;

  String? _selectedFlavour;
  Map<String, dynamic>? _selectedDrink;
  final Set<String> _selectedToppingIds = {};
  final TextEditingController _instructionsController = TextEditingController();

  List<Map<String, dynamic>> _backendAddons = [];
  List<Map<String, dynamic>> _backendDrinks = [];
  List<Map<String, String>> _dynamicFlavours = [];

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
    _basePrice = (rawPrice is num) ? rawPrice.toInt() : (int.tryParse(rawPrice?.toString() ?? '0') ?? 0);

    final backendVariants = widget.item['variants'] as List<dynamic>?;
    _hasRealVariants = backendVariants != null && backendVariants.isNotEmpty;
    if (_hasRealVariants) {
      _variations = backendVariants!.map<Map<String, dynamic>>((v) {
        final rawP = v['price'];
        int p = rawP is num ? rawP.toInt() : (double.tryParse(rawP?.toString() ?? '')?.toInt() ?? 0);
        if (p == 0) {
          p = _basePrice;
        } else if (p < (_basePrice * 0.5) && _basePrice > 0) {
          p = _basePrice + p;
        }
        return {
          'id': v['id']?.toString(),
          'name': v['name']?.toString() ?? 'Regular',
          'price': p,
        };
      }).toList();
    } else {
      _variations = [
        {'id': null, 'name': 'Regular', 'price': _basePrice},
      ];
    }

    _loadBackendCustomizations();
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _loadBackendCustomizations() async {
    try {
      final addons = await ApiService.fetchAddons();
      if (addons.isNotEmpty && mounted) {
        setState(() {
          _backendAddons = addons.map<Map<String, dynamic>>((a) {
            if (a is Map) return Map<String, dynamic>.from(a);
            return <String, dynamic>{};
          }).where((m) => m.isNotEmpty).toList();
        });
      }

      final prods = await ApiService.fetchProducts();
      if (prods.isNotEmpty && mounted) {
        final drinks = prods.where((p) => p['isBeverage'] == true).toList();
        final mappedDrinks = drinks.map<Map<String, dynamic>>((d) {
          final rawP = d['basePrice'] ?? d['price'];
          final p = rawP is num ? rawP.toInt() : (double.tryParse(rawP?.toString() ?? '140')?.toInt() ?? 140);
          return {'id': d['id']?.toString(), 'name': d['name']?.toString() ?? 'Drink', 'price': p};
        }).toList();
        if (mappedDrinks.isNotEmpty) setState(() => _backendDrinks = mappedDrinks);
      }

      final rawFlavours = widget.item['flavours'] as List<dynamic>?;
      if (rawFlavours != null && rawFlavours.isNotEmpty && mounted) {
        final mappedFlavours = rawFlavours.map<Map<String, String>>((f) {
          return {
            'name': (f is Map ? f['name']?.toString() : null) ?? '',
            'desc': (f is Map ? f['description']?.toString() : null) ?? '',
          };
        }).where((f) => f['name']!.isNotEmpty).toList();
        if (mappedFlavours.isNotEmpty) setState(() => _dynamicFlavours = mappedFlavours);
      }
    } catch (e) {
      debugPrint('Error loading backend customizations: $e');
    }
  }

  bool get _hasFlavours => _dynamicFlavours.isNotEmpty || _isPizza || _isBurger;

  List<Map<String, String>> get _flavourOptions {
    if (_dynamicFlavours.isNotEmpty) return _dynamicFlavours;
    if (_isBurger) {
      return [
        {'name': 'Classic Crispy', 'desc': 'Mildly seasoned crunchy recipe with signature sauce'},
        {'name': 'Spicy Jalapeño', 'desc': 'Fiery chili glaze with pickled jalapeños & hot sauce'},
        {'name': 'Smokey BBQ', 'desc': 'Sweet and smokey barbecue glaze with caramelized onions'},
      ];
    }
    return [
      {'name': 'Chicken Tikka', 'desc': 'Traditional spicy marinated chicken with fresh onions & herbs'},
      {'name': 'Chicken Fajita', 'desc': 'Mexican spiced chicken with crisp bell peppers & onions'},
      {'name': 'Pepperoni Passion', 'desc': 'Loaded beef pepperoni with premium double mozzarella cheese'},
      {'name': 'Veggie Supreme', 'desc': 'Sweet corn, mushrooms, olives, bell peppers & juicy tomatoes'},
      {'name': 'Cheese Feast', 'desc': 'Triple blend of melted mozzarella, cheddar & parmesan cheese'},
    ];
  }

  List<Map<String, dynamic>> get _drinkOptions {
    if (_backendDrinks.isNotEmpty) return _backendDrinks;
    return [
      {'id': null, 'name': 'Coca-Cola (345ml)', 'price': 140},
      {'id': null, 'name': 'Sprite (345ml)', 'price': 140},
      {'id': null, 'name': 'Fanta (345ml)', 'price': 140},
      {'id': null, 'name': 'Mineral Water (500ml)', 'price': 80},
    ];
  }

  List<Map<String, dynamic>> get _filteredToppings {
    final List<Map<String, dynamic>> result = [];
    final seen = <String>{};

    void addAddon(dynamic a) {
      if (a is! Map) return;
      final obj = (a['addon'] is Map) ? Map<String, dynamic>.from(a['addon']) : Map<String, dynamic>.from(a);
      final id = obj['id']?.toString() ?? '';
      final name = obj['name']?.toString() ?? '';
      if (id.isEmpty || name.isEmpty || seen.contains(name.toLowerCase())) return;
      seen.add(name.toLowerCase());
      final rawP = obj['price'];
      final p = rawP is num ? rawP.toInt() : (double.tryParse(rawP?.toString() ?? '0')?.toInt() ?? 0);
      result.add({'id': id, 'name': name, 'price': p});
    }

    final prodAddons = widget.item['addons'] as List<dynamic>?;
    if (prodAddons != null) {
      for (final a in prodAddons) {
        addAddon(a);
      }
    }
    for (final a in _backendAddons) {
      addAddon(a);
    }

    return result;
  }

  void _onVariationSelected(int newIndex) {
    setState(() => _selectedVariationIndex = newIndex);
  }

  int get _selectedUnitPrice {
    final variationPrice = (_selectedVariationIndex != null && _selectedVariationIndex! < _variations.length)
        ? (_variations[_selectedVariationIndex!]['price'] as int)
        : _basePrice;

    int toppingsPrice = 0;
    final allCatalog = _filteredToppings;
    for (final id in _selectedToppingIds) {
      final match = allCatalog.firstWhere((t) => t['id'] == id, orElse: () => {});
      if (match.isNotEmpty) toppingsPrice += (match['price'] as int? ?? 0);
    }

    final drinkPrice = (_selectedDrink != null) ? (_selectedDrink!['price'] as int? ?? 0) : 0;
    return variationPrice + toppingsPrice + drinkPrice;
  }

  int get _totalOrderPrice => _selectedUnitPrice * _quantity;

  void _handleAddToTable() {
    if (_selectedVariationIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a variation size.')));
      return;
    }
    if (_hasFlavours && (_selectedFlavour == null || _selectedFlavour!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a flavour.')));
      return;
    }

    final allCatalog = _filteredToppings;
    final selectedToppingsList = _selectedToppingIds.map((id) {
      return allCatalog.firstWhere((t) => t['id'] == id, orElse: () => {'id': id, 'name': id, 'price': 0});
    }).toList();

    final variation = _variations[_selectedVariationIndex!];

    final cartItem = {
      'id': widget.item['id'] ?? widget.item['name'],
      'productId': widget.item['id'],
      'name': widget.item['name'],
      'desc': widget.item['desc'],
      'image': widget.item['image'],
      'variantId': variation['id'],
      'variation': variation['name'].toString(),
      'flavour': _selectedFlavour ?? '',
      'drinkId': _selectedDrink?['id'],
      'drink': _selectedDrink != null ? _selectedDrink!['name'] : '',
      'drinkPrice': _selectedDrink != null ? (_selectedDrink!['price'] as int? ?? 0) : 0,
      'toppings': selectedToppingsList,
      'instructions': _instructionsController.text.trim(),
      'price': _selectedUnitPrice,
      'quantity': _quantity,
    };

    widget.onAddToCart(cartItem);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${widget.item['name']} added to Table ${widget.table['number']}\'s order.'), backgroundColor: AppColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose Item', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.darkNavy)),
            Text('Table ${widget.table['number']}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CartReviewScreen(table: widget.table))),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: const Icon(Icons.receipt_long_outlined, color: AppColors.darkNavy, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 220, minHeight: 160),
                      child: Image.network(
                        ApiService.resolveImageUrl(widget.item['image']?.toString()),
                        fit: BoxFit.contain,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 180,
                          color: AppColors.background,
                          child: const Center(child: Icon(Icons.fastfood, size: 56, color: Colors.grey)),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.item['name'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.darkNavy)),
                        const SizedBox(height: 8),
                        Text(widget.item['desc'] ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4)),
                        const SizedBox(height: 14),
                        Text('Starting from PKR ${_variations.first['price']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primaryOrange)),
                        const SizedBox(height: 24),

                        _buildSectionHeader('Variation (Size)', 'REQUIRED'),
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
                                  Expanded(child: Text(v['name'], style: TextStyle(fontSize: 15, fontWeight: isSel ? FontWeight.bold : FontWeight.w500, color: AppColors.darkNavy))),
                                  Text('PKR ${v['price']}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.darkNavy)),
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 28),

                        if (_selectedVariationIndex != null) ...[
                          if (_hasFlavours) ...[
                            _buildSectionHeader(_isPizza ? 'Pizza Flavour' : 'Flavour Choice', 'REQUIRED'),
                            const SizedBox(height: 12),
                            ..._flavourOptions.map((f) {
                              final isSel = _selectedFlavour == f['name'];
                              return InkWell(
                                onTap: () => setState(() => _selectedFlavour = f['name']),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(padding: const EdgeInsets.only(top: 2.0), child: _buildRadioCircle(isSel)),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(f['name']!, style: TextStyle(fontSize: 15, fontWeight: isSel ? FontWeight.bold : FontWeight.w600, color: AppColors.darkNavy)),
                                            const SizedBox(height: 3),
                                            Text(f['desc']!, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.3)),
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

                          _buildSectionHeader('Drink', 'OPTIONAL'),
                          const SizedBox(height: 12),
                          ..._drinkOptions.map((d) {
                            final isSel = _selectedDrink?['name'] == d['name'];
                            final price = d['price'] as int;
                            return InkWell(
                              onTap: () => setState(() => _selectedDrink = isSel ? null : d),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10.0),
                                child: Row(
                                  children: [
                                    _buildRadioCircle(isSel),
                                    const SizedBox(width: 14),
                                    Expanded(child: Text(d['name'], style: TextStyle(fontSize: 14, fontWeight: isSel ? FontWeight.bold : FontWeight.w500, color: AppColors.darkNavy))),
                                    Text('+PKR $price', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryOrange)),
                                  ],
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 28),

                          _buildSectionHeader('Extra Add-ons & Toppings', 'OPTIONAL'),
                          const SizedBox(height: 12),
                          if (_filteredToppings.isEmpty)
                            const Text('No add-ons configured for this item.', style: TextStyle(fontSize: 12, color: AppColors.textMuted))
                          else
                            ..._filteredToppings.map((t) {
                              final tid = t['id'] as String;
                              final isChecked = _selectedToppingIds.contains(tid);
                              final price = t['price'] as int;
                              return InkWell(
                                onTap: () => setState(() {
                                  if (isChecked) {
                                    _selectedToppingIds.remove(tid);
                                  } else {
                                    _selectedToppingIds.add(tid);
                                  }
                                }),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color: isChecked ? AppColors.primaryOrange : Colors.white,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: isChecked ? AppColors.primaryOrange : const Color(0xFFD1D5DB), width: 2),
                                        ),
                                        child: isChecked ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(child: Text(t['name'], style: TextStyle(fontSize: 14, fontWeight: isChecked ? FontWeight.bold : FontWeight.w500, color: AppColors.darkNavy))),
                                      Text('+PKR $price', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryOrange)),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          const SizedBox(height: 28),

                          _buildSectionHeader('Special Instructions', 'OPTIONAL'),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _instructionsController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: 'e.g., Less spicy, no onions...',
                              hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                              filled: true,
                              fillColor: AppColors.background,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryOrange)),
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

          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.cardBorder))),
              child: Row(
                children: [
                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E7EB))),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 18, color: AppColors.darkNavy),
                          onPressed: () {
                            if (_quantity > 1) setState(() => _quantity--);
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          child: Text('$_quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkNavy)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 18, color: AppColors.darkNavy),
                          onPressed: () => setState(() => _quantity++),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _handleAddToTable,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryYellow, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        child: Text('ADD   Rs: $_totalOrderPrice', style: const TextStyle(color: AppColors.darkNavy, fontSize: 15, fontWeight: FontWeight.w900)),
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

  Widget _buildSectionHeader(String title, String badgeText) {
    final required = badgeText == 'REQUIRED';
    return Row(
      children: [
        Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkNavy))),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: required ? const Color(0xFFFEF08A) : AppColors.cardBorder, borderRadius: BorderRadius.circular(8)),
          child: Text(badgeText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: required ? const Color(0xFF854D0E) : const Color(0xFF4B5563))),
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
        border: Border.all(color: isSelected ? AppColors.primaryOrange : const Color(0xFFD1D5DB), width: isSelected ? 6 : 2),
      ),
    );
  }
}
