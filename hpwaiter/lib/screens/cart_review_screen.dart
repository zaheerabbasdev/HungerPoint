import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/api_service.dart';
import '../services/table_cart_service.dart';
import 'table_order_screen.dart';

class CartReviewScreen extends StatefulWidget {
  final Map<String, dynamic> table;

  const CartReviewScreen({super.key, required this.table});

  @override
  State<CartReviewScreen> createState() => _CartReviewScreenState();
}

class _CartReviewScreenState extends State<CartReviewScreen> {
  bool _isSubmitting = false;

  String get _tableId => widget.table['id'].toString();
  String get _branchId => widget.table['branchId'].toString();

  String _composeNotes(Map<String, dynamic> item) {
    final parts = <String>[];
    if ((item['flavour'] as String?)?.isNotEmpty == true) parts.add('Flavour: ${item['flavour']}');
    if ((item['instructions'] as String?)?.isNotEmpty == true) parts.add('Note: ${item['instructions']}');
    return parts.join('. ');
  }

  List<Map<String, dynamic>> _buildOrderItems() {
    final cartItems = TableCartService().itemsFor(_tableId);
    final orderItems = <Map<String, dynamic>>[];

    for (final item in cartItems) {
      final toppings = (item['toppings'] as List<dynamic>? ?? []);
      final addonIds = toppings.map((t) => t is Map ? t['id']?.toString() : null).whereType<String>().toList();

      orderItems.add({
        'productId': item['productId'],
        if (item['variantId'] != null) 'variantId': item['variantId'],
        'quantity': item['quantity'],
        if (addonIds.isNotEmpty) 'addonIds': addonIds,
        if (_composeNotes(item).isNotEmpty) 'notes': _composeNotes(item),
      });

      // A selected drink is a real, separately-priced product — give it its
      // own order line instead of folding it into a text note, so it shows
      // correctly on the kitchen ticket and is priced from the real product.
      if (item['drinkId'] != null) {
        orderItems.add({
          'productId': item['drinkId'],
          'quantity': item['quantity'],
          'notes': 'Drink for ${item['name']}',
        });
      }
    }

    return orderItems;
  }

  Future<void> _submitOrder() async {
    final items = _buildOrderItems();
    if (items.isEmpty) return;

    setState(() => _isSubmitting = true);
    final result = await ApiService.createDineInOrder(branchId: _branchId, tableId: _tableId, items: items);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      TableCartService().clearTable(_tableId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order sent to the kitchen!'), backgroundColor: AppColors.success),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => TableOrderScreen(table: widget.table)),
        (route) => route.isFirst,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Failed to place order'), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Table ${widget.table['number']} — Order')),
      body: ValueListenableBuilder<int>(
        valueListenable: TableCartService().version,
        builder: (context, _, _) {
          final items = TableCartService().itemsFor(_tableId);
          if (items.isEmpty) {
            return const Center(
              child: Text('No items added yet.', style: TextStyle(color: AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.bold)),
            );
          }

          final total = TableCartService().totalPriceFor(_tableId);

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final qty = item['quantity'] as int? ?? 1;
                    final price = item['price'] as int? ?? 0;
                    final toppings = (item['toppings'] as List<dynamic>? ?? []);

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.cardBorder)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${item['name']} (${item['variation']})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkNavy)),
                                    if ((item['flavour'] as String?)?.isNotEmpty == true)
                                      Text('Flavour: ${item['flavour']}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                    if ((item['drink'] as String?)?.isNotEmpty == true)
                                      Text('Drink: ${item['drink']}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                    if (toppings.isNotEmpty)
                                      Text('+ ${toppings.map((t) => t['name']).join(', ')}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                    if ((item['instructions'] as String?)?.isNotEmpty == true)
                                      Text('Note: ${item['instructions']}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic)),
                                  ],
                                ),
                              ),
                              Text('PKR ${price * qty}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.primaryOrange)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.cardBorder)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      iconSize: 16,
                                      icon: const Icon(Icons.remove, color: AppColors.darkNavy),
                                      onPressed: () => TableCartService().updateQuantity(_tableId, index, qty - 1),
                                    ),
                                    Text('$qty', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.darkNavy)),
                                    IconButton(
                                      iconSize: 16,
                                      icon: const Icon(Icons.add, color: AppColors.darkNavy),
                                      onPressed: () => TableCartService().updateQuantity(_tableId, index, qty + 1),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => TableCartService().removeItem(_tableId, index),
                                icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                                label: const Text('Remove', style: TextStyle(color: AppColors.danger, fontSize: 12)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.cardBorder))),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkNavy)),
                          Text('PKR $total', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primaryOrange)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitOrder,
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryYellow, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                          child: _isSubmitting
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.darkNavy))
                              : const Text('Send to Kitchen', style: TextStyle(color: AppColors.darkNavy, fontWeight: FontWeight.w900, fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
