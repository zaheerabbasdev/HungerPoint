import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../services/location_tracking_service.dart';
import 'active_delivery_screen.dart';
import 'history_screen.dart';
import '../widgets/rider_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isOnline = false;
  bool _isLoading = true;
  bool _togglingAvailability = false;
  Map<String, dynamic>? _activeDelivery;
  List<dynamic> _upcoming = [];
  String? _claimingOrderId;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _loadRiderStatus();
    _loadActiveDelivery();
    _loadUpcoming();
    _listenForAssignments();
    _listenForPool();
    // Keeps the "ready in ~N min" labels fresh.
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    SocketService().socket.off('rider.pool_updated');
    SocketService().socket.off('rider.assignment_created');
    super.dispose();
  }

  Future<void> _loadUpcoming() async {
    final orders = await ApiService.getAvailableOrders();
    if (mounted) setState(() => _upcoming = orders);
  }

  // The branch's order pool changed (confirmed / being cooked / ready / taken / cancelled).
  void _listenForPool() {
    SocketService().socket.on('rider.pool_updated', (data) {
      if (!mounted) return;
      if (data is Map && data['ready'] == true && _isOnline && _activeDelivery == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🍽️ An order is ready — take it now!'), backgroundColor: AppColors.amber),
        );
      }
      _loadUpcoming();
    });
  }

  Future<void> _takeOrder(Map<String, dynamic> order) async {
    if (_claimingOrderId != null) return;
    setState(() => _claimingOrderId = order['id']?.toString());
    final result = await ApiService.claimOrder(order['id'].toString());
    if (!mounted) return;
    setState(() => _claimingOrderId = null);

    if (result['success'] == true) {
      await _loadActiveDelivery();
      await _loadUpcoming();
      _openActiveDelivery();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Could not take this order.'), backgroundColor: AppColors.danger),
      );
      _loadUpcoming();
    }
  }

  Future<void> _loadRiderStatus() async {
    final rider = await ApiService.getMyRiderProfile();
    if (!mounted || rider == null) return;
    final online = rider['status']?.toString() == 'ONLINE' || rider['status']?.toString() == 'ON_DELIVERY';
    setState(() => _isOnline = online);
    if (online) {
      await LocationTrackingService().start();
    }
  }

  void _listenForAssignments() {
    SocketService().socket.off('rider.assignment_created');
    SocketService().socket.on('rider.assignment_created', (data) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🔔 New delivery assigned to you!'), backgroundColor: AppColors.amber),
      );
      _loadActiveDelivery();
    });
  }

  Future<void> _loadActiveDelivery() async {
    setState(() => _isLoading = true);
    final delivery = await ApiService.getActiveDelivery();
    if (!mounted) return;
    setState(() {
      _activeDelivery = delivery;
      _isLoading = false;
    });
    LocationTrackingService().setActiveOrder(delivery?['orderId']?.toString());
  }

  Future<void> _toggleAvailability(bool goOnline) async {
    setState(() => _togglingAvailability = true);
    final result = await ApiService.updateAvailability(goOnline ? 'ONLINE' : 'OFFLINE');
    if (!mounted) return;
    setState(() => _togglingAvailability = false);

    if (result['success'] == true) {
      setState(() => _isOnline = goOnline);
      if (goOnline) {
        await LocationTrackingService().start();
      } else {
        LocationTrackingService().stop();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Could not update availability.'), backgroundColor: AppColors.danger),
      );
    }
  }

  void _openActiveDelivery() {
    if (_activeDelivery == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActiveDeliveryScreen(delivery: _activeDelivery!, onChanged: _loadActiveDelivery),
      ),
    ).then((_) => _loadActiveDelivery());
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiService.currentUser;

    return Scaffold(
      drawer: RiderDrawer(isOnline: _isOnline),
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => Padding(
            padding: const EdgeInsets.only(left: 12),
            child: GestureDetector(
              onTap: () => Scaffold.of(ctx).openDrawer(),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: AppColors.orange, shape: BoxShape.circle),
                child: const Icon(Icons.menu, color: Colors.white, size: 20),
              ),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user?['name'] ?? 'Rider Portal', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(
              _isOnline ? '🟢 Online & Ready for Orders' : '🔴 Offline',
              style: TextStyle(fontSize: 11, color: _isOnline ? AppColors.success : AppColors.danger),
            ),
          ],
        ),
        actions: [
          if (_togglingAvailability)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.amber))),
            )
          else
            Switch(value: _isOnline, activeThumbColor: AppColors.amber, onChanged: _toggleAvailability),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadActiveDelivery();
          await _loadUpcoming();
        },
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.amber))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_activeDelivery != null)
                    _buildDeliveryCard(_activeDelivery!),

                  const SizedBox(height: 8),
                  Text(
                    _upcoming.isEmpty ? 'Upcoming orders' : 'Upcoming orders (${_upcoming.length})',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 10),
                  if (_upcoming.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 36),
                      child: Column(
                        children: [
                          Icon(Icons.local_shipping_outlined, size: 56, color: AppColors.textMuted.withValues(alpha: 0.5)),
                          const SizedBox(height: 10),
                          Text(
                            _isOnline ? 'No orders right now. New ones appear here as soon as the admin confirms them.' : 'Go online to take deliveries',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    for (final o in _upcoming) _buildUpcomingCard(Map<String, dynamic>.from(o as Map)),

                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
                    icon: const Icon(Icons.history, color: AppColors.amber),
                    label: const Text('Delivery History', style: TextStyle(color: AppColors.amber)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      side: const BorderSide(color: AppColors.surfaceBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // "Being prepared, ready in ~N min" / "Food is ready" for an upcoming order.
  String _upcomingLabel(Map<String, dynamic> o) {
    switch (o['status']?.toString()) {
      case 'READY':
        return 'Food is ready';
      case 'PREPARING':
        final readyBy = DateTime.tryParse(o['readyBy']?.toString() ?? '')?.toLocal();
        if (readyBy == null) return 'Being prepared';
        final mins = (readyBy.difference(DateTime.now()).inSeconds / 60).ceil();
        return mins > 0 ? 'Being prepared, ready in ~$mins min' : 'Being prepared, almost ready';
      default:
        return 'Confirmed, waiting for the kitchen';
    }
  }

  Widget _buildUpcomingCard(Map<String, dynamic> o) {
    final isReady = o['status']?.toString() == 'READY';
    final area = [o['address']?['area'], o['address']?['city']].where((e) => e != null && e.toString().isNotEmpty).join(', ');
    final total = num.tryParse(o['total']?.toString() ?? '') ?? 0;
    final itemCount = o['_count']?['items'] ?? 0;
    final isCash = o['paymentMethod']?.toString() == 'CASH_ON_DELIVERY' && o['paymentStatus']?.toString() != 'PAID';
    final claiming = _claimingOrderId == o['id']?.toString();
    final ride = num.tryParse(o['estimatedDeliveryTime']?.toString() ?? '');
    final canTake = isReady && _isOnline && _activeDelivery == null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isReady ? AppColors.success : AppColors.surfaceBorder, width: isReady ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(o['orderNumber']?.toString() ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.amber)),
              Text('PKR ${total.toStringAsFixed(0)}${isCash ? ' · Cash' : ''}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.success)),
            ],
          ),
          const SizedBox(height: 6),
          Text(_upcomingLabel(o),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: isReady ? AppColors.success : Colors.orangeAccent)),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(area.isEmpty ? 'Delivery area not set' : area, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ),
              Text(ride == null ? '$itemCount item(s)' : 'Ride ~${ride.round()} min · $itemCount item(s)',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
          if (isReady) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canTake && !claiming ? () => _takeOrder(o) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  disabledBackgroundColor: AppColors.surfaceBorder,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: claiming
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(
                        canTake
                            ? 'Take this order'
                            : !_isOnline
                                ? 'Go online to take orders'
                                : 'Finish your current delivery first',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeliveryCard(Map<String, dynamic> delivery) {
    final order = delivery['order'] ?? {};
    final orderNumber = order['orderNumber'] ?? 'HP-0000';
    final status = delivery['status']?.toString() ?? 'ASSIGNED';
    final total = num.tryParse(order['total']?.toString() ?? '') ?? 0;
    final customerName = order['customer']?['user']?['name'] ?? 'Customer';

    return GestureDetector(
      onTap: _openActiveDelivery,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(orderNumber, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.amber)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.orange.withValues(alpha: 0.5)),
                  ),
                  child: Text(status.replaceAll('_', ' '), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
                ),
              ],
            ),
            const Divider(color: AppColors.surfaceBorder, height: 24),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Expanded(child: Text(customerName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
                Text('PKR ${total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.success)),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _openActiveDelivery,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('View Delivery', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
