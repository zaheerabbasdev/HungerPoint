import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../widgets/waiter_drawer.dart';
import 'table_order_screen.dart';
import 'reservation_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _tables = [];
  List<String> _floors = [];
  String? _selectedFloor;

  @override
  void initState() {
    super.initState();
    _loadFloors();
    _loadTables();
    _listenForUpdates();
  }

  void _listenForUpdates() {
    final socket = SocketService().socket;
    socket.on('kitchen.queue_updated', (_) => _loadTables());
    socket.on('order.created', (_) => _loadTables());
    socket.on('order.ready', (_) => _loadTables());
    socket.on('order.preparing', (_) => _loadTables());
    socket.on('order.confirmed', (_) => _loadTables());
  }

  @override
  void dispose() {
    final socket = SocketService().socket;
    socket.off('kitchen.queue_updated');
    socket.off('order.created');
    socket.off('order.ready');
    socket.off('order.preparing');
    socket.off('order.confirmed');
    super.dispose();
  }

  Future<void> _loadFloors() async {
    final floors = await ApiService.fetchFloors();
    if (!mounted) return;
    setState(() => _floors = floors);
  }

  Future<void> _loadTables() async {
    final tables = await ApiService.fetchTables();
    if (!mounted) return;
    setState(() {
      _tables = tables.map((t) => Map<String, dynamic>.from(t)).toList();
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _visibleTables {
    if (_selectedFloor == null) return _tables;
    return _tables.where((t) => t['floor'] == _selectedFloor).toList();
  }

  Map<String, dynamic>? _activeOrder(Map<String, dynamic> table) {
    final orders = table['orders'] as List<dynamic>?;
    if (orders == null || orders.isEmpty) return null;
    return Map<String, dynamic>.from(orders.first);
  }

  Map<String, dynamic>? _upcomingReservation(Map<String, dynamic> table) {
    final reservations = table['reservations'] as List<dynamic>?;
    if (reservations == null || reservations.isEmpty) return null;
    return Map<String, dynamic>.from(reservations.first);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'AVAILABLE':
        return AppColors.success;
      case 'RESERVED':
        return const Color(0xFF7C3AED); // purple — visually distinct from occupied/available
      default:
        return AppColors.primaryOrange;
    }
  }

  Future<void> _onTableTap(Map<String, dynamic> table) async {
    final status = table['status']?.toString() ?? 'AVAILABLE';
    if (status == 'RESERVED') {
      final reservation = _upcomingReservation(table);
      if (reservation == null) {
        // Data drifted (e.g. reservation just expired) — fall back to the normal table screen.
        await Navigator.push(context, MaterialPageRoute(builder: (_) => TableOrderScreen(table: table)));
      } else {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ReservationDetailScreen(table: table, reservation: reservation)),
        );
      }
    } else {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => TableOrderScreen(table: table)));
    }
    _loadTables();
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiService.currentUser;
    final available = _tables.where((t) => t['status'] == 'AVAILABLE').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const WaiterDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => Padding(
            padding: const EdgeInsets.only(left: 12),
            child: GestureDetector(
              onTap: () => Scaffold.of(ctx).openDrawer(),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: AppColors.primaryOrange, shape: BoxShape.circle),
                child: const Icon(Icons.menu, color: Colors.white, size: 20),
              ),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user?['name'] ?? 'Waiter', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.darkNavy)),
            Text(
              '$available of ${_tables.length} tables free',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_floors.length > 1)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                children: [
                  _buildFloorChip('All Floors', null),
                  ..._floors.map((f) => _buildFloorChip(f, f)),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await Future.wait([_loadTables(), _loadFloors()]);
              },
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow))
                  : _visibleTables.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.55,
                              child: const Center(
                                child: Text('No tables on this floor.', style: TextStyle(color: AppColors.textMuted)),
                              ),
                            ),
                          ],
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 0.92,
                          ),
                          itemCount: _visibleTables.length,
                          itemBuilder: (context, index) => _buildTableCard(_visibleTables[index]),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloorChip(String label, String? floor) {
    final isSelected = _selectedFloor == floor;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedFloor = floor),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryYellow : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? AppColors.primaryYellow : AppColors.cardBorder),
          ),
          child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkNavy)),
        ),
      ),
    );
  }

  Widget _buildTableCard(Map<String, dynamic> table) {
    final status = table['status']?.toString() ?? 'AVAILABLE';
    final order = _activeOrder(table);
    final reservation = _upcomingReservation(table);
    final color = _statusColor(status);

    return GestureDetector(
      onTap: () => _onTableTap(table),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: Icon(status == 'RESERVED' ? Icons.event_seat : Icons.table_bar, color: color, size: 22),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                  child: Text(status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Table ${table['number']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.darkNavy)),
            Text('${table['floor'] ?? 'Ground Floor'} · Seats ${table['capacity'] ?? 4}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted), overflow: TextOverflow.ellipsis),
            const Spacer(),
            if (reservation != null) ...[
              const Divider(height: 16, color: AppColors.cardBorder),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14, color: Color(0xFF7C3AED)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(reservation['guestName'] ?? 'Guest', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)), overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              Text('${reservation['partySize'] ?? '—'} guests', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ] else if (order != null) ...[
              const Divider(height: 16, color: AppColors.cardBorder),
              Row(
                children: [
                  const Icon(Icons.receipt_long, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      (order['status'] ?? '').toString().replaceAll('_', ' '),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryOrange),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Text('PKR ${num.tryParse(order['total']?.toString() ?? '0')?.toStringAsFixed(0) ?? '0'}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.darkNavy)),
            ] else
              const Text('Tap to seat & order', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
