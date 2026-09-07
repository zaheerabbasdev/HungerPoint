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
  int? _selectedVariation;
  int _quantity = 1;
  late List<Map<String, dynamic>> _variations;

  @override
  void initState() {
    super.initState();
    final basePrice = (widget.item['price'] is int)
        ? widget.item['price'] as int
        : int.tryParse(widget.item['price']?.toString() ?? '1480') ?? 1480;
    _variations = [
      {'name': 'Regular', 'price': basePrice},
      {'name': 'Large', 'price': (basePrice * 1.32).round()},
    ];
  }

  @override
  Widget build(BuildContext context) {
    final basePrice = (widget.item['price'] is int)
        ? widget.item['price'] as int
        : int.tryParse(widget.item['price']?.toString() ?? '1480') ?? 1480;
    final selectedPrice = _selectedVariation != null
        ? (_variations[_selectedVariation!]['price'] as int)
        : basePrice;
    final totalAddPrice = selectedPrice * _quantity;

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
              'F-7 Old Islamabad',
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
          // ─── SCROLLABLE CONTENT ───
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Full Product Image (contain fit so full pizza/plate is displayed)
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Stack(
                      children: [
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxHeight: 270,
                              minHeight: 210,
                            ),
                            child: Image.network(
                              widget.item['image'],
                              fit: BoxFit.contain,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 210,
                                color: const Color(0xFFF9FAFB),
                                child: const Center(
                                  child: Icon(Icons.fastfood, size: 64, color: Colors.grey),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Heart Icon (matching choose_item.jpeg bottom right of image area)
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
                          widget.item['name'],
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E1B4B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.item['desc'],
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'PKR ${widget.item['price']}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFF5722),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Variations Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Variation',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E1B4B),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF08A),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'REQUIRED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF854D0E),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Variations Options (matching choose_item.jpeg)
                        ...List.generate(_variations.length, (idx) {
                          final v = _variations[idx];
                          final isSel = _selectedVariation == idx;
                          return InkWell(
                            onTap: () => setState(() => _selectedVariation = idx),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10.0),
                              child: Row(
                                children: [
                                  // Custom Radio Indicator (matching design screenshot)
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSel ? const Color(0xFFFF5722) : const Color(0xFFD1D5DB),
                                        width: isSel ? 6 : 2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Text(
                                    v['name'],
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                      color: const Color(0xFF1E1B4B),
                                    ),
                                  ),
                                  const Spacer(),
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── BOTTOM STEPPER & ADD BUTTON (Lifted upward with SafeArea and padding) ───
          SafeArea(
            top: false,
            bottom: true,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
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

                  // Yellow ADD Button
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_selectedVariation == null) {
                            TopToast.show(context, 'Please select any variation:');
                            return;
                          }

                          final cartItem = {
                            'id': widget.item['id'] ?? widget.item['name'],
                            'name': widget.item['name'],
                            'desc': widget.item['desc'],
                            'image': widget.item['image'],
                            'variation': _variations[_selectedVariation!]['name'],
                            'price': selectedPrice,
                            'quantity': _quantity,
                          };
                          final overlay = Overlay.of(context, rootOverlay: true);
                          widget.onAddToCart(cartItem);
                          Navigator.pop(context);
                          TopToast.showWithOverlay(overlay, 'Product has been added to cart');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD54F),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'ADD   Rs: $totalAddPrice',
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
}
