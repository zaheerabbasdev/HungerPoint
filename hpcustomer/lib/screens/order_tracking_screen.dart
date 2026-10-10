import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
    {'key': 'PREPARING', 'label': 'Preparing', 'icon': '🍳'},
    {'key': 'READY', 'label': 'Ready', 'icon': '📦'},
    {'key': 'OUT_FOR_DELIVERY', 'label': 'Out for Delivery', 'icon': '🛵'},
    {'key': 'DELIVERED', 'label': 'Delivered', 'icon': '🎉'},
  ];

  static const _statusEvents = [
    'order.pending', 'order.confirmed', 'order.accepted', 'order.preparing', 'order.ready',
    'order.assigned', 'order.picked_up', 'order.out_for_delivery', 'order.delivered',
    'order.completed', 'order.cancelled', 'order.rejected', 'order.payment_failed', 'order.refunded',
    'order.eta_updated',
  ];

  // Statuses between "Ready" and "Out for Delivery" show under the Ready step.
  static const _stepAlias = {
    'ACCEPTED': 'CONFIRMED',
    'ASSIGNED': 'READY',
    'PICKED_UP': 'READY',
    'COMPLETED': 'DELIVERED',
  };

  Map<String, dynamic>? _order;
  bool _loading = true;

  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _loadOrder();

    final socket = SocketService().socket;
    SocketService().trackOrder(widget.orderId);
    for (final evt in _statusEvents) {
      socket.on(evt, _handleStatusEvent);
    }
    // Re-draw regularly so the countdown keeps shrinking.
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    final socket = SocketService().socket;
    for (final evt in _statusEvents) {
      socket.off(evt, _handleStatusEvent);
    }
    _ticker?.cancel();
    super.dispose();
  }

  // Status events carry a partial order, so refetch the full, current one.
  void _handleStatusEvent(dynamic data) {
    if (data is Map && (data['id'] ?? data['orderId'])?.toString() == widget.orderId && mounted) {
      _loadOrder();
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
    final currentIndex = _statusSteps.indexWhere((s) => s['key'] == (_stepAlias[status] ?? status));
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

          _buildEtaCard(order),

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

  int _nonNegative(int v) => v < 0 ? 0 : v;

  /// One combined time (kitchen preparation + the rider's trip) counting down to the
  /// promised time, plus the delivery address. There is no rider map.
  Widget _buildEtaCard(Map<String, dynamic> order) {
    final status = order['status']?.toString() ?? 'PENDING';
    const finished = ['DELIVERED', 'COMPLETED', 'CANCELLED', 'REJECTED', 'REFUNDED', 'PAYMENT_FAILED'];
    final isDelivery = order['type'] == 'DELIVERY';
    if (finished.contains(status) || !isDelivery) return const SizedBox.shrink();

    final promisedAt = DateTime.tryParse(order['promisedAt']?.toString() ?? '')?.toLocal();
    final minutesLeft = promisedAt == null
        ? null
        : _nonNegative((promisedAt.difference(DateTime.now()).inSeconds / 60).ceil());
    final prep = order['estimatedPrepTime'];
    final travel = order['estimatedDeliveryTime'];
    final address = order['address'] as Map<String, dynamic>?;
    final onTheWay = status == 'OUT_FOR_DELIVERY';

    final headline = onTheWay
        ? 'On the way, arriving in'
        : status == 'PREPARING'
            ? 'Your food will reach you in about'
            : 'Estimated delivery time';

    final rider = (order['delivery'] as Map<String, dynamic>?)?['rider'] as Map<String, dynamic>?;
    final riderName = rider?['user']?['name']?.toString();
    final riderPhone = rider?['user']?['phone']?.toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF3F4F6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(headline, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
            const SizedBox(height: 4),
            Text(
              minutesLeft == null ? 'Calculating...' : '$minutesLeft min',
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Color(0xFFFF5722)),
            ),
            if (!onTheWay && prep != null && travel != null)
              Text('$prep min preparing + $travel min delivery', style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
            if (address != null) ...[
              const Divider(height: 24, color: Color(0xFFF3F4F6)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, color: Color(0xFF1E1B4B), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Delivering to', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                        Text(
                          address['address']?.toString() ?? '',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E1B4B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            if (onTheWay && riderName != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.two_wheeler, color: Color(0xFFFF5722), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(riderName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1E1B4B))),
                  ),
                  if (riderPhone != null)
                    IconButton(
                      icon: const Icon(Icons.call, color: Color(0xFF2E7D32)),
                      onPressed: () => launchUrl(Uri.parse('tel:$riderPhone')),
                    ),
                ],
              ),
            ],
          ],
        ),
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
