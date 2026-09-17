import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/cart_service.dart';
import '../services/api_service.dart';
import 'cart_screen.dart';
import 'order_tracking_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _fetchLiveOrders();
  }

  Future<void> _fetchLiveOrders() async {
    try {
      final list = await ApiService.getMyOrders();
      if (list.isNotEmpty && mounted) {
        final serverOrders = list.map<Map<String, dynamic>>((order) {
          final isDelivered = order['status'] == 'DELIVERED';
          final itemsList = (order['items'] as List<dynamic>? ?? []).map((it) {
            return {
              'name': it['product']?['name']?.toString() ?? 'Food Item',
              'qty': it['quantity'] ?? 1,
              'price': num.tryParse(it['unitPrice']?.toString() ?? '')?.toInt() ?? 0,
              'emoji': '🍕',
            };
          }).toList();

          final created = order['createdAt']?.toString() ?? '';
          final dateStr = created.length > 10 ? created.substring(0, 10) : 'Recent';

          return {
            'id': order['id']?.toString() ?? '',
            'orderId': '#${order['orderNumber'] ?? order['id']}',
            'date': dateStr,
            'status': (order['status'] as String? ?? 'In Progress').replaceAll('_', ' '),
            'rawStatus': order['status']?.toString() ?? 'PENDING',
            'statusColor': isDelivered ? const Color(0xFF2E7D32) : const Color(0xFFFF5722),
            'statusBg': isDelivered ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3ED),
            'total': num.tryParse(order['total']?.toString() ?? '')?.toInt() ?? 0,
            'items': itemsList,
          };
        }).toList();

        setState(() {
          _orders = serverOrders;
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('Error loading orders: $e');
    }

    if (mounted) {
      setState(() {
        _orders = [];
        _isLoading = false;
      });
    }
  }

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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD600)),
              ),
            )
          : _orders.isEmpty
              ? _buildEmptyState(context)
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: _orders.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    final List items = order['items'];
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    final orderId = order['id']?.toString() ?? '';
                    if (orderId.isEmpty) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: orderId)),
                    );
                  },
                  child: Container(
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
