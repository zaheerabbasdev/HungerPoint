import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/cart_service.dart';
import 'cart_screen.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  static final List<Map<String, dynamic>> _mockOrders = [
    {
      'orderId': '#HP-9842',
      'date': 'Today, 12:35 PM',
      'status': 'In Progress',
      'statusColor': Color(0xFFFF5722),
      'statusBg': Color(0xFFFFF3ED),
      'total': 1890,
      'items': [
        {'name': 'Thin Crust Beef Pepperoni (Large)', 'qty': 1, 'price': 1480, 'emoji': '🍕'},
        {'name': 'Special Garlic Mayo Dip', 'qty': 2, 'price': 240, 'emoji': '🥣'},
        {'name': 'Coca Cola 500ml', 'qty': 1, 'price': 170, 'emoji': '🥤'},
      ],
    },
    {
      'orderId': '#HP-7619',
      'date': '04 Sep 2026, 08:45 PM',
      'status': 'Delivered',
      'statusColor': Color(0xFF2E7D32),
      'statusBg': Color(0xFFE8F5E9),
      'total': 2150,
      'items': [
        {'name': 'Deep Dish Chicken Tikka (Medium)', 'qty': 1, 'price': 1650, 'emoji': '🍕'},
        {'name': 'Crispy Potato Fries', 'qty': 1, 'price': 350, 'emoji': '🍟'},
        {'name': 'Sprite 500ml', 'qty': 1, 'price': 150, 'emoji': '🥤'},
      ],
    },
    {
      'orderId': '#HP-5120',
      'date': '28 Aug 2026, 01:20 PM',
      'status': 'Delivered',
      'statusColor': Color(0xFF2E7D32),
      'statusBg': Color(0xFFE8F5E9),
      'total': 1480,
      'items': [
        {'name': 'Thin Crust Fajita Sicilian (Medium)', 'qty': 1, 'price': 1330, 'emoji': '🍕'},
        {'name': 'Coca Cola 500ml', 'qty': 1, 'price': 150, 'emoji': '🥤'},
      ],
    },
  ];

  void _reorder(BuildContext context, Map<String, dynamic> order) {
    for (var item in order['items']) {
      CartService().addItem({
        'id': 'reorder_${DateTime.now().millisecondsSinceEpoch}_${item['name']}',
        'name': item['name'],
        'price': item['price'],
        'quantity': item['qty'],
        'desc': 'Re-ordered item from previous order',
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Items from ${order['orderId']} added to your cart!'),
        backgroundColor: AppColors.darkNavy,
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: AppColors.primaryYellow,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartScreen()),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E1B4B), size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Order History',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1E1B4B),
          ),
        ),
      ),
      body: _mockOrders.isEmpty
          ? _buildEmptyState(context)
          : ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: _mockOrders.length,
              separatorBuilder: (context, index) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final order = _mockOrders[index];
                final List items = order['items'];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF3F4F6)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Order ID + Status Chip
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order['orderId'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1E1B4B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                order['date'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: order['statusBg'],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              order['status'],
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: order['statusColor'],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFF3F4F6)),
                      const SizedBox(height: 10),

                      // Items list preview
                      ...items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Text(item['emoji'] ?? '🍕', style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${item['qty']}x ${item['name']}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF374151),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Text(
                                'PKR ${item['price']}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E1B4B),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFF3F4F6)),
                      const SizedBox(height: 12),

                      // Footer: Total + Reorder button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Amount',
                                style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                              ),
                              Text(
                                'PKR ${order['total']}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFFF5722),
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _reorder(context, order),
                            icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF1E1B4B)),
                            label: const Text(
                              'RE-ORDER',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1E1B4B),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFD600),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_outlined, size: 40, color: Color(0xFF9CA3AF)),
          ),
          const SizedBox(height: 16),
          const Text(
            'No orders yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E1B4B)),
          ),
          const SizedBox(height: 6),
          const Text(
            'When you place orders, they will appear here.',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}
