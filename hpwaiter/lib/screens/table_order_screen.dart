import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import 'menu_screen.dart';
import 'reservation_form_screen.dart';

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
  Timer? _ticker;

  // Payment step
  String _method = 'POS_CASH';
  final TextEditingController _cashController = TextEditingController();
  String? _cashFilledForOrder;

  static const _steps = [
    {'key': 'SENT', 'label': 'Sent', 'icon': Icons.receipt_long},
    {'key': 'PREPARING', 'label': 'Preparing', 'icon': Icons.soup_kitchen_outlined},
    {'key': 'READY', 'label': 'Ready', 'icon': Icons.done_all},
    {'key': 'SERVED', 'label': 'Served', 'icon': Icons.restaurant},
    {'key': 'PAID', 'label': 'Paid', 'icon': Icons.check_circle},
  ];

  static const _paymentMethods = [
    {'key': 'POS_CASH', 'label': 'Cash', 'icon': Icons.payments_outlined},
    {'key': 'DEBIT_CARD', 'label': 'Card', 'icon': Icons.credit_card},
    {'key': 'JAZZCASH', 'label': 'JazzCash', 'icon': Icons.phone_android},
    {'key': 'EASYPAISA', 'label': 'EasyPaisa', 'icon': Icons.phone_android},
  ];

  @override
  void initState() {
    super.initState();
    _table = widget.table;
    _refresh();
    // Kitchen starts / extends / finishes the order, or it is served: reload the table.
    SocketService().socket.on('kitchen.queue_updated', _onLiveUpdate);
    // Re-draw regularly so the "expected in N min" countdown keeps shrinking.
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    SocketService().socket.off('kitchen.queue_updated', _onLiveUpdate);
    _ticker?.cancel();
    _cashController.dispose();
    super.dispose();
  }

  void _onLiveUpdate(dynamic _) {
    if (mounted) _refresh();
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

  num _totalOf(Map<String, dynamic> order) => num.tryParse(order['total']?.toString() ?? '') ?? 0;

  /// Minutes until the kitchen's promised time (null if the kitchen has not given one yet).
  int? _minutesLeft(Map<String, dynamic> order) {
    final promised = DateTime.tryParse(order['promisedAt']?.toString() ?? '')?.toLocal();
    if (promised == null) return null;
    return (promised.difference(DateTime.now()).inSeconds / 60).ceil();
  }

  // ─── Step 1: "Mark as Done" — food reached the table. The table stays open. ───
  Future<void> _markDone() async {
    final order = _activeOrder;
    if (order == null) return;
    setState(() => _isSubmitting = true);
    final result = await ApiService.markOrderServed(order['id'].toString());
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marked as served. Now confirm the payment.'), backgroundColor: AppColors.success),
      );
      await _refresh();
    } else {
      _showError(result['message'] ?? 'Could not update order.');
    }
  }

  // ─── Step 2: confirm the payment, which closes the table ───
  Future<void> _confirmPayment() async {
    final order = _activeOrder;
    if (order == null) return;
    final total = _totalOf(order);
    final received = num.tryParse(_cashController.text.trim());

    if (_method == 'POS_CASH' && (received == null || received < total)) {
      _showError('Cash received must be at least PKR ${total.toStringAsFixed(0)}.');
      return;
    }

    setState(() => _isSubmitting = true);
    final result = await ApiService.confirmOrderPayment(
      order['id'].toString(),
      method: _method,
      amountReceived: _method == 'POS_CASH' ? received : null,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment received. Table closed.'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context);
    } else {
      _showError(result['message'] ?? 'Could not confirm payment.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }

  Future<void> _openMenu() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MenuScreen(table: _table ?? widget.table)),
    );
    _refresh();
  }

  Future<void> _reserveTable() async {
    final booked = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ReservationFormScreen(table: _table ?? widget.table)),
    );
    if (booked == true && mounted) {
      Navigator.pop(context);
    }
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
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _reserveTable,
                  icon: const Icon(Icons.event_seat, color: Color(0xFF7C3AED)),
                  label: const Text('Reserve This Table', style: TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    side: const BorderSide(color: Color(0xFF7C3AED)),
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

  int _stepIndexFor(String status, bool served) {
    switch (status) {
      case 'PREPARING':
        return 1;
      case 'READY':
        return served ? 3 : 2;
      case 'COMPLETED':
        return 4;
      default:
        return 0;
    }
  }

  BoxDecoration get _cardDecoration =>
      BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.cardBorder));

  Widget _buildOrderView(Map<String, dynamic> order) {
    final status = order['status']?.toString() ?? 'CONFIRMED';
    final served = order['servedAt'] != null;
    final stepIndex = _stepIndexFor(status, served);
    final items = (order['items'] as List<dynamic>? ?? []);
    final total = _totalOf(order);
    final inPaymentStep = status == 'READY' && served;

    final statusLabel = inPaymentStep
        ? 'AWAITING PAYMENT'
        : status == 'READY'
            ? 'READY TO SERVE'
            : status.replaceAll('_', ' ');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Status stepper
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration,
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

        // Expected time (kitchen's estimate)
        if (status == 'CONFIRMED' || status == 'PENDING' || status == 'PREPARING') ...[
          _buildExpectedTime(order, status),
          const SizedBox(height: 16),
        ],

        // Order number + status
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration,
          child: Row(
            children: [
              const Icon(Icons.confirmation_number_outlined, color: AppColors.primaryOrange, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(order['orderNumber'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkNavy)),
              ),
              Text(statusLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryOrange)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Items
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration,
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

        if (inPaymentStep)
          _buildPaymentStep(order, total)
        else if (status == 'READY')
          _buildMarkDone()
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

        // New rounds are only possible before the table is served and handed to payment.
        if (!inPaymentStep) ...[
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
      ],
    );
  }

  Widget _buildExpectedTime(Map<String, dynamic> order, String status) {
    final minutes = _minutesLeft(order);
    final prep = order['estimatedPrepTime'];
    final waitingForKitchen = status != 'PREPARING' || minutes == null;

    String headline;
    String? detail;
    Color color = AppColors.primaryOrange;
    if (waitingForKitchen) {
      headline = 'Waiting for the kitchen to start';
      detail = 'The expected time appears once the kitchen begins cooking.';
    } else if (minutes <= 0) {
      headline = 'Due now';
      detail = 'The kitchen is finishing this order.';
      color = AppColors.danger;
    } else {
      headline = 'Expected ready in $minutes min';
      if (prep != null) detail = 'Kitchen estimate: $prep min';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(waitingForKitchen ? Icons.hourglass_empty : Icons.timer_outlined, color: color, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(headline, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
                if (detail != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(detail, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Order is Ready: the only action is "Mark as Done". Payment and closing come in the next step.
  Widget _buildMarkDone() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _markDone,
            icon: _isSubmitting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.done_all, color: Colors.white),
            label: const Text('Mark as Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          ),
        ),
        const SizedBox(height: 8),
        const Text('Next: confirm the payment', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
      ],
    );
  }

  // Step 2: confirm the payment, then the table closes.
  Widget _buildPaymentStep(Map<String, dynamic> order, num total) {
    // Pre-fill the cash field with the bill once per order.
    final orderId = order['id'].toString();
    if (_cashFilledForOrder != orderId) {
      _cashFilledForOrder = orderId;
      _cashController.text = total.toStringAsFixed(0);
    }
    final received = num.tryParse(_cashController.text.trim());
    final isCash = _method == 'POS_CASH';
    final change = received == null ? null : received - total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Confirm payment', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.darkNavy)),
          const SizedBox(height: 4),
          const Text('The table closes once the payment is confirmed.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Amount due', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
              Text('PKR ${total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primaryOrange)),
            ],
          ),
          const SizedBox(height: 14),
          const Text('Paid by', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkNavy)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in _paymentMethods)
                ChoiceChip(
                  avatar: Icon(m['icon'] as IconData, size: 16, color: _method == m['key'] ? AppColors.darkNavy : AppColors.textMuted),
                  label: Text(m['label'] as String),
                  selected: _method == m['key'],
                  selectedColor: AppColors.primaryYellow,
                  onSelected: (_) => setState(() => _method = m['key'] as String),
                ),
            ],
          ),
          if (isCash) ...[
            const SizedBox(height: 14),
            TextField(
              controller: _cashController,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Cash received (PKR)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 8),
            if (change != null)
              Text(
                change >= 0 ? 'Change to return: PKR ${change.toStringAsFixed(0)}' : 'Short by PKR ${(-change).toStringAsFixed(0)}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: change >= 0 ? AppColors.success : AppColors.danger),
              ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting || (isCash && (received == null || received < total)) ? null : _confirmPayment,
              icon: _isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.lock_outline, color: Colors.white),
              label: const Text('Confirm Payment & Close Table', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                disabledBackgroundColor: AppColors.cardBorder,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
