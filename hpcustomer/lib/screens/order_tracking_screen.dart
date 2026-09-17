import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  static const _statusSteps = [
    {'key': 'PENDING', 'label': 'Order Received', 'icon': '📝'},
    {'key': 'CONFIRMED', 'label': 'Confirmed', 'icon': '✓'},
    {'key': 'PREPARING', 'label': 'In Kitchen', 'icon': '🍳'},
    {'key': 'READY', 'label': 'Ready', 'icon': '📦'},
    {'key': 'OUT_FOR_DELIVERY', 'label': 'Out for Delivery', 'icon': '🛵'},
    {'key': 'DELIVERED', 'label': 'Delivered', 'icon': '🎉'},
  ];

  static const _statusEvents = [
    'order.pending', 'order.confirmed', 'order.accepted', 'order.preparing', 'order.ready',
    'order.assigned', 'order.picked_up', 'order.out_for_delivery', 'order.delivered',
    'order.completed', 'order.cancelled', 'order.rejected', 'order.payment_failed', 'order.refunded',
  ];

  Map<String, dynamic>? _order;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrder();

    final socket = SocketService().socket;
    SocketService().trackOrder(widget.orderId);
    for (final evt in _statusEvents) {
      socket.on(evt, _handleStatusEvent);
    }
  }

  @override
  void dispose() {
    final socket = SocketService().socket;
    for (final evt in _statusEvents) {
      socket.off(evt, _handleStatusEvent);
    }
    super.dispose();
  }

  void _handleStatusEvent(dynamic data) {
    if (data is Map && data['id']?.toString() == widget.orderId && mounted) {
      setState(() => _order = Map<String, dynamic>.from(data));
    }
  }

  Future<void> _loadOrder() async {
    final order = await ApiService.getOrderById(widget.orderId);
    if (mounted) {
      setState(() {
        _order = order;
        _loading = false;
      });
    }
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
          'Track Order',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E1B4B)),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD600))),
            )
          : _order == null
              ? const Center(
                  child: Text('Order not found', style: TextStyle(color: Color(0xFF6B7280))),
                )
              : _buildTracker(context, _order!),
    );
  }

  Widget _buildTracker(BuildContext context, Map<String, dynamic> order) {
    final status = order['status']?.toString() ?? 'PENDING';
    final currentIndex = _statusSteps.indexWhere((s) => s['key'] == status);
    final items = (order['items'] as List<dynamic>? ?? []);
    final total = num.tryParse(order['total']?.toString() ?? '') ?? 0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order #${order['orderNumber'] ?? ''}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E1B4B)),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFF3F4F6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < _statusSteps.length; i++)
                  _buildStepRow(
                    icon: _statusSteps[i]['icon']!,
                    label: _statusSteps[i]['label']!,
                    isCompleted: currentIndex >= 0 && i <= currentIndex,
                    isCurrent: i == currentIndex,
                    isLast: i == _statusSteps.length - 1,
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF3F4F6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Items',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1E1B4B)),
                ),
                const SizedBox(height: 10),
                ...items.map((it) {
                  final qty = it['quantity'] ?? 1;
                  final name = it['product']?['name']?.toString() ?? 'Item';
                  final price = num.tryParse(it['totalPrice']?.toString() ?? '') ?? 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${qty}x $name', style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
                        Text('PKR $price', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E1B4B))),
                      ],
                    ),
                  );
                }),
                const Divider(height: 20, color: Color(0xFFF3F4F6)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1E1B4B))),
                    Text('PKR $total', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFFFF5722))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow({
    required String icon,
    required String label,
    required bool isCompleted,
    required bool isCurrent,
    required bool isLast,
  }) {
    final color = isCurrent
        ? const Color(0xFFFF5722)
        : isCompleted
            ? const Color(0xFF2E7D32)
            : const Color(0xFF9CA3AF);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? color.withValues(alpha: 0.15) : const Color(0xFFF3F4F6),
                  border: Border.all(color: color, width: isCurrent ? 2 : 1),
                ),
                child: Center(child: Text(icon, style: const TextStyle(fontSize: 14))),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted ? color : const Color(0xFFF3F4F6),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 20),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w600,
                color: isCompleted ? const Color(0xFF1E1B4B) : const Color(0xFF9CA3AF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
