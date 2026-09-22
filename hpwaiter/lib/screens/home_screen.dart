import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../widgets/waiter_drawer.dart';
import 'table_order_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _tables = [];

  @override
  void initState() {
    super.initState();
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

  Future<void> _loadTables() async {
    final tables = await ApiService.fetchTables();
    if (!mounted) return;
    setState(() {
      _tables = tables.map((t) => Map<String, dynamic>.from(t)).toList();
      _isLoading = false;
    });
  }

  Map<String, dynamic>? _activeOrder(Map<String, dynamic> table) {
    final orders = table['orders'] as List<dynamic>?;
    if (orders == null || orders.isEmpty) return null;
    return Map<String, dynamic>.from(orders.first);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'AVAILABLE':
        return AppColors.success;
      case 'RESERVED':
        return AppColors.primaryYellow;
      default:
        return AppColors.primaryOrange;
    }
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
      body: RefreshIndicator(
        onRefresh: _loadTables,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow))
            : _tables.isEmpty
                ? ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: const Center(
                          child: Text('No tables set up for your branch yet.', style: TextStyle(color: AppColors.textMuted)),
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
                    itemCount: _tables.length,
                    itemBuilder: (context, index) => _buildTableCard(_tables[index]),
                  ),
      ),
    );
  }

  Widget _buildTableCard(Map<String, dynamic> table) {
    final status = table['status']?.toString() ?? 'AVAILABLE';
    final order = _activeOrder(table);
    final color = _statusColor(status);

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TableOrderScreen(table: table)),
        );
        _loadTables();
      },
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
                  child: Icon(Icons.table_bar, color: color, size: 22),
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
            Text('Seats ${table['capacity'] ?? 4}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            const Spacer(),
            if (order != null) ...[
              const Divider(height: 16, color: AppColors.cardBorder),
              Row(
                children: [
                  Icon(Icons.receipt_long, size: 14, color: AppColors.textMuted),
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
