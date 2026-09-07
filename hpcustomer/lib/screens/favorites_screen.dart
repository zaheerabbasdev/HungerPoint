import 'package:flutter/material.dart';
import '../services/favorites_service.dart';
import '../services/cart_service.dart';
import 'item_detail_screen.dart';
import 'cart_screen.dart';

class FavoritesScreen extends StatelessWidget {
  final Function(Map<String, dynamic>) onAddToCart;

  const FavoritesScreen({super.key, required this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E1B4B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'My Favourites',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E1B4B),
              ),
            ),
            SizedBox(height: 3),
            Text(
              'F-7 Old Islamabad',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // ─── 1. FAVORITES LIST ───
          ValueListenableBuilder<List<Map<String, dynamic>>>(
            valueListenable: FavoritesService().favoritesNotifier,
            builder: (context, favorites, _) {
              if (favorites.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFF3ED),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.favorite_border,
                            size: 48,
                            color: Color(0xFFFF5722),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'No Favorites Added Yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E1B4B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap the heart icon on any item in the menu\nto save it here!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                itemCount: favorites.length,
                separatorBuilder: (context, index) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final item = favorites[index];
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
                                  onAddToCart: (addedItem) {
                                    CartService().addItem(addedItem);
                                    onAddToCart(addedItem);
                                  },
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
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    item['image'] ?? '',
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 80,
                                      height: 80,
                                      color: const Color(0xFFF3F4F6),
                                      child: const Icon(Icons.fastfood, color: Colors.grey),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(right: 36.0),
                                        child: Text(
                                          item['name'] ?? '',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1E1B4B),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item['desc'] ?? '',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
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
                                                        onAddToCart: (addedItem) {
                                                          CartService().addItem(addedItem);
                                                          onAddToCart(addedItem);
                                                        },
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

                      // Isolated remove favorite button
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            FavoritesService().toggleFavorite(item);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            color: Colors.transparent,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3ED),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFFF5722), width: 1.2),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.favorite,
                                  color: Color(0xFFFF5722),
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),

          // ─── 2. BOTTOM "VIEW CART" BAR (Matching Provided Screenshot Exactly) ───
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: CartService().cartNotifier,
              builder: (context, cartItems, _) {
                final totalCount = CartService().totalItemCount;
                if (totalCount == 0) return const SizedBox.shrink();

                final totalPrice = CartService().totalPrice;
                final lastImg = cartItems.isNotEmpty && cartItems.last['image'] != null
                    ? cartItems.last['image'] as String
                    : 'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=400&q=80';

                return Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        // Pizza Thumbnail
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            lastImg,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 40,
                              height: 40,
                              color: const Color(0xFFF3F4F6),
                              child: const Icon(Icons.local_pizza, color: Colors.orange, size: 24),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Count & Items Text
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$totalCount',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1E1B4B),
                              ),
                            ),
                            Text(
                              totalCount > 1 ? 'Items' : 'Item',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1E1B4B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),

                        // Yellow Action Button: "PKR [total] Prices are Exclusive of tax" + "VIEW CART >>"
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CartScreen(
                                    onNavigateToExplore: () => Navigator.pop(context),
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD54F),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'PKR $totalPrice',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF1E1B4B),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const Text(
                                          'Prices are Exclusive of tax',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF1E1B4B),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'VIEW CART >>',
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
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
