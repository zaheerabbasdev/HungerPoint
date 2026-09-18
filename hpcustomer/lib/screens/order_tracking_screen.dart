import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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

  double? _riderLat;
  double? _riderLng;
  final MapController _mapController = MapController();

  static const _trackableDeliveryStatuses = ['ASSIGNED', 'ACCEPTED', 'PICKED_UP', 'OUT_FOR_DELIVERY'];

  @override
  void initState() {
    super.initState();
    _loadOrder();

    final socket = SocketService().socket;
    SocketService().trackOrder(widget.orderId);
    for (final evt in _statusEvents) {
      socket.on(evt, _handleStatusEvent);
    }
    socket.on('rider.location_updated', _handleRiderLocation);
  }

  @override
  void dispose() {
    final socket = SocketService().socket;
    for (final evt in _statusEvents) {
      socket.off(evt, _handleStatusEvent);
    }
    socket.off('rider.location_updated', _handleRiderLocation);
    super.dispose();
  }

  void _handleStatusEvent(dynamic data) {
    if (data is Map && data['id']?.toString() == widget.orderId && mounted) {
      setState(() => _order = Map<String, dynamic>.from(data));
    }
  }

  void _handleRiderLocation(dynamic data) {
    if (!mounted || data is! Map) return;
    final lat = double.tryParse(data['latitude']?.toString() ?? '');
    final lng = double.tryParse(data['longitude']?.toString() ?? '');
    if (lat == null || lng == null) return;
    setState(() {
      _riderLat = lat;
      _riderLng = lng;
    });
  }

  /// Great-circle distance between two coordinates, in kilometers (Haversine formula).
  double _distanceKm(double lat1, double lng1, double lat2, double lng2) {
    const earthRadiusKm = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLng = (lng2 - lng1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) * math.cos(lat2 * math.pi / 180) * math.sin(dLng / 2) * math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
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

          _buildRiderTrackingCard(order),

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

  Widget _buildRiderTrackingCard(Map<String, dynamic> order) {
    final delivery = order['delivery'] as Map<String, dynamic>?;
    final address = order['address'] as Map<String, dynamic>?;
    final isDeliveryOrder = order['type'] != 'PICKUP';
    final deliveryStatus = delivery?['status']?.toString();

    if (delivery == null || !isDeliveryOrder || !_trackableDeliveryStatuses.contains(deliveryStatus)) {
      return const SizedBox.shrink();
    }

    final rider = delivery['rider'] as Map<String, dynamic>?;
    final riderName = rider?['user']?['name']?.toString() ?? 'Your rider';
    final riderPhone = rider?['user']?['phone']?.toString();

    final destLat = double.tryParse(address?['latitude']?.toString() ?? '');
    final destLng = double.tryParse(address?['longitude']?.toString() ?? '');

    double? distanceKm;
    if (_riderLat != null && _riderLng != null && destLat != null && destLng != null) {
      distanceKm = _distanceKm(_riderLat!, _riderLng!, destLat, destLng);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF3F4F6)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rider info row
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(color: Color(0xFFFFF3ED), shape: BoxShape.circle),
                    child: const Icon(Icons.two_wheeler, color: Color(0xFFFF5722), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(riderName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1E1B4B))),
                        Text(
                          distanceKm != null
                              ? '${distanceKm < 1 ? '${(distanceKm * 1000).round()} m' : '${distanceKm.toStringAsFixed(1)} km'} away'
                              : 'Waiting for live location...',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                  if (riderPhone != null)
                    IconButton(
                      icon: const Icon(Icons.call, color: Color(0xFF2E7D32)),
                      onPressed: () => launchUrl(Uri.parse('tel:$riderPhone')),
                    ),
                ],
              ),
            ),

            // Live map
            if (destLat != null && destLng != null)
              SizedBox(
                height: 220,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _riderLat != null && _riderLng != null ? LatLng(_riderLat!, _riderLng!) : LatLng(destLat, destLng),
                        initialZoom: 14,
                        interactionOptions: const InteractionOptions(flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.hpcustomer',
                          maxZoom: 19,
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(destLat, destLng),
                              width: 34,
                              height: 34,
                              child: const Icon(Icons.location_on, color: Color(0xFF1E1B4B), size: 34),
                            ),
                            if (_riderLat != null && _riderLng != null)
                              Marker(
                                point: LatLng(_riderLat!, _riderLng!),
                                width: 34,
                                height: 34,
                                child: const Icon(Icons.two_wheeler, color: Color(0xFFFF5722), size: 30),
                              ),
                          ],
                        ),
                      ],
                    ),
                    if (_riderLat == null)
                      Container(
                        color: Colors.black.withValues(alpha: 0.35),
                        child: const Center(
                          child: Text(
                            'Waiting for your rider\'s live location...',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
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
