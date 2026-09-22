import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/api_service.dart';
import 'menu_screen.dart';

class TableOrderScreen extends StatefulWidget {
  final Map<String, dynamic> table;

  const TableOrderScreen({super.key, required this.table});

  @override
  State<TableOrderScreen> createState() => _TableOrderScreenState();
}

class _TableOrderScreenState extends State<TableOrderScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  Map<String, dynamic>? _table;

  static const _steps = [
    {'key': 'CONFIRMED', 'label': 'Sent', 'icon': Icons.receipt_long},
    {'key': 'PREPARING', 'label': 'Preparing', 'icon': Icons.soup_kitchen_outlined},
    {'key': 'READY', 'label': 'Ready', 'icon': Icons.done_all},
    {'key': 'COMPLETED', 'label': 'Served', 'icon': Icons.check_circle},
  ];

  @override
  void initState() {
    super.initState();
    _table = widget.table;
    _refresh();
  }

  Future<void> _refresh() async {
    final fresh = await ApiService.fetchTableById(widget.table['id'].toString());
    if (!mounted) return;
    setState(() {
      if (fresh != null) _table = fresh;
      _isLoading = false;
    });
  }

  Map<String, dynamic>? get _activeOrder {
    final orders = _table?['orders'] as List<dynamic>?;
    if (orders == null || orders.isEmpty) return null;
    return Map<String, dynamic>.from(orders.first);
  }

  Future<void> _markServed() async {
    final order = _activeOrder;
    if (order == null) return;
    setState(() => _isSubmitting = true);
    final result = await ApiService.updateOrderStatus(order['id'].toString(), 'COMPLETED');
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Table served & closed.'), backgroundColor: AppColors.success),
      );
      await _refresh();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Could not update order.'), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _openMenu() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MenuScreen(table: _table ?? widget.table)),
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final order = _activeOrder;
    final tableNumber = _table?['number'] ?? widget.table['number'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Table $tableNumber')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow))
          : RefreshIndicator(
              onRefresh: _refresh,
              child: order == null ? _buildEmptyState() : _buildOrderView(order),
            ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.55,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.table_bar, size: 64, color: AppColors.textMuted.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                const Text(
                  'This table is free.\nSeat guests and start an order.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _openMenu,
                  icon: const Icon(Icons.add, color: AppColors.darkNavy),
                  label: const Text('Start New Order', style: TextStyle(color: AppColors.darkNavy, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryYellow,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderView(Map<String, dynamic> order) {
    final status = order['status']?.toString() ?? 'CONFIRMED';
    final stepIndex = _steps.indexWhere((s) => s['key'] == status);
    final items = (order['items'] as List<dynamic>? ?? []);
    final total = num.tryParse(order['total']?.toString() ?? '') ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Status stepper
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.cardBorder)),
          child: Row(
            children: [
              for (int i = 0; i < _steps.length; i++) ...[
                Column(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: i <= stepIndex ? AppColors.primaryYellow : AppColors.cardBorder,
                      child: Icon(_steps[i]['icon'] as IconData, size: 16, color: i <= stepIndex ? AppColors.darkNavy : AppColors.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(_steps[i]['label'] as String, style: TextStyle(fontSize: 9, color: i <= stepIndex ? AppColors.darkNavy : AppColors.textMuted)),
                  ],
                ),
                if (i < _steps.length - 1)
                  Expanded(child: Container(height: 2, color: i < stepIndex ? AppColors.primaryYellow : AppColors.cardBorder)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Order number + waiter
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.cardBorder)),
          child: Row(
            children: [
              const Icon(Icons.confirmation_number_outlined, color: AppColors.primaryOrange, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(order['orderNumber'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkNavy)),
              ),
              Text(status.replaceAll('_', ' '), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryOrange)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Items
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.cardBorder)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Order Items', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.darkNavy)),
              const SizedBox(height: 10),
              ...items.map((it) {
                final qty = it['quantity'] ?? 1;
                final name = it['product']?['name'] ?? 'Item';
                final variant = it['variant']?['name'];
                final notes = it['notes']?.toString();
                final addons = (it['addons'] as List<dynamic>? ?? []);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${qty}x', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryOrange)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$name${variant != null ? ' ($variant)' : ''}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkNavy)),
                            if (addons.isNotEmpty)
                              Text(
                                addons.map((a) => a['addonName']).join(', '),
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            if (notes != null && notes.isNotEmpty)
                              Text(notes, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                      Text('PKR ${num.tryParse(it['totalPrice']?.toString() ?? '0')?.toStringAsFixed(0) ?? '0'}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkNavy)),
                    ],
                  ),
                );
              }),
              const Divider(height: 20, color: AppColors.cardBorder),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.darkNavy)),
                  Text('PKR ${total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primaryOrange)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        if (status == 'READY')
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _markServed,
              icon: _isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.done_all, color: Colors.white),
              label: const Text('Mark Served & Close Table', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.primaryYellow.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primaryOrange, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Waiting for the kitchen to mark this order Ready before it can be served.',
                      style: TextStyle(fontSize: 12, color: AppColors.darkNavy, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _openMenu,
          icon: const Icon(Icons.add, color: AppColors.primaryOrange),
          label: const Text('Start Another Round', style: TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            side: const BorderSide(color: AppColors.primaryOrange),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }
}
