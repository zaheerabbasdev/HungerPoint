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

  @override
  void initState() {
    super.initState();
    _loadRiderStatus();
    _loadActiveDelivery();
    _listenForAssignments();
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
        onRefresh: _loadActiveDelivery,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.amber))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_activeDelivery == null) ...[
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.55,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.local_shipping_outlined, size: 64, color: AppColors.textMuted.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            Text(
                              _isOnline ? 'Waiting for your next delivery...' : 'Go online to start receiving deliveries',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else
                    _buildDeliveryCard(_activeDelivery!),

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
