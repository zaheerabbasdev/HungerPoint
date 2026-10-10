import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../services/api_service.dart';
import '../services/location_tracking_service.dart';

class ActiveDeliveryScreen extends StatefulWidget {
  final Map<String, dynamic> delivery;
  final VoidCallback onChanged;

  const ActiveDeliveryScreen({super.key, required this.delivery, required this.onChanged});

  @override
  State<ActiveDeliveryScreen> createState() => _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends State<ActiveDeliveryScreen> {
  late Map<String, dynamic> _delivery;
  bool _isSubmitting = false;

  static const _steps = [
    {'key': 'ASSIGNED', 'label': 'Assigned', 'icon': Icons.assignment_outlined},
    {'key': 'ACCEPTED', 'label': 'Accepted', 'icon': Icons.check_circle_outline},
    {'key': 'PICKED_UP', 'label': 'Picked Up', 'icon': Icons.shopping_bag_outlined},
    {'key': 'OUT_FOR_DELIVERY', 'label': 'On the Way', 'icon': Icons.two_wheeler},
    {'key': 'DELIVERED', 'label': 'Delivered', 'icon': Icons.done_all},
  ];

  @override
  void initState() {
    super.initState();
    _delivery = widget.delivery;
    LocationTrackingService().setActiveOrder(_delivery['orderId']?.toString());
  }

  Map<String, dynamic> get _order => _delivery['order'] ?? {};
  String get _status => _delivery['status']?.toString() ?? 'ASSIGNED';

  Future<void> _runAction(Future<Map<String, dynamic>> Function() action, {String? successMessage}) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    final result = await action();
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      final updated = result['data'] as Map<String, dynamic>?;
      if (updated != null) {
        setState(() => _delivery = {..._delivery, ...updated});
      }
      widget.onChanged();
      if (successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMessage), backgroundColor: AppColors.success));
      }
      if (_status == 'DELIVERED') {
        Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Something went wrong.'), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _reportIssue() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Report a Problem', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(hintText: 'e.g. Customer unreachable', hintStyle: TextStyle(color: AppColors.textMuted)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, controller.text.trim().isEmpty ? 'Unable to complete delivery' : controller.text.trim()),
            child: const Text('Submit', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (reason == null) return;
    await _runAction(() => ApiService.markFailed(_delivery['id'], reason), successMessage: 'Delivery marked as failed.');
  }

  Future<void> _navigateTo(double? lat, double? lng, String label) async {
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No coordinates available for $label.')));
      return;
    }
    final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng(${Uri.encodeComponent(label)})');
    final mapsUri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    try {
      if (!await launchUrl(geoUri, mode: LaunchMode.externalApplication)) {
        await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderNumber = _order['orderNumber'] ?? '—';
    final customerName = _order['customer']?['user']?['name'] ?? 'Customer';
    final customerPhone = _order['customer']?['user']?['phone'] ?? '';
    final isPickupType = _order['type'] == 'PICKUP';
    final address = _order['address'];
    final branch = _order['branch'];
    final items = (_order['items'] as List<dynamic>? ?? []);
    final total = num.tryParse(_order['total']?.toString() ?? '') ?? 0;
    final paymentMethod = _order['paymentMethod']?.toString().replaceAll('_', ' ') ?? '';

    final stepIndex = _steps.indexWhere((s) => s['key'] == _status);
    final beforePickup = _status == 'ASSIGNED' || _status == 'ACCEPTED';

    return Scaffold(
      appBar: AppBar(title: Text('Order $orderNumber')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status stepper
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.surfaceBorder)),
              child: Row(
                children: [
                  for (int i = 0; i < _steps.length; i++) ...[
                    Column(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: i <= stepIndex ? AppColors.amber : AppColors.surfaceBorder,
                          child: Icon(_steps[i]['icon'] as IconData, size: 16, color: i <= stepIndex ? Colors.black : AppColors.textMuted),
                        ),
                        const SizedBox(height: 4),
                        Text(_steps[i]['label'] as String, style: TextStyle(fontSize: 9, color: i <= stepIndex ? AppColors.textPrimary : AppColors.textMuted)),
                      ],
                    ),
                    if (i < _steps.length - 1)
                      Expanded(child: Container(height: 2, color: i < stepIndex ? AppColors.amber : AppColors.surfaceBorder)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Pickup from the branch (only until the food is picked up)
            if (beforePickup) ...[
              _locationCard(
                icon: Icons.storefront,
                title: 'Pickup from',
                text: branch?['name'] ?? 'Branch',
                lat: double.tryParse(branch?['latitude']?.toString() ?? ''),
                lng: double.tryParse(branch?['longitude']?.toString() ?? ''),
                label: branch?['name'] ?? 'Branch',
              ),
              const SizedBox(height: 12),
            ],

            // The customer's location is visible from the moment the rider takes the order
            if (!isPickupType) ...[
              _locationCard(
                icon: Icons.location_on,
                title: 'Deliver to',
                text: address?['address'] ?? 'No address on file',
                lat: double.tryParse(address?['latitude']?.toString() ?? ''),
                lng: double.tryParse(address?['longitude']?.toString() ?? ''),
                label: 'Delivery Address',
              ),
              const SizedBox(height: 16),
            ],

            // Customer card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.surfaceBorder)),
              child: Row(
                children: [
                  const Icon(Icons.person, color: AppColors.textMuted, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(customerName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
                  if (customerPhone.toString().isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.call, color: AppColors.success),
                      onPressed: () => launchUrl(Uri.parse('tel:$customerPhone')),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Items card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.surfaceBorder)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Order Items', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  ...items.map((it) {
                    final qty = it['quantity'] ?? 1;
                    final name = it['product']?['name'] ?? 'Item';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Text('${qty}x $name', style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                    );
                  }),
                  const Divider(color: AppColors.surfaceBorder, height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(paymentMethod, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      Text('PKR ${total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildActionButton(),
            const SizedBox(height: 10),
            if (beforePickup)
              TextButton(
                onPressed: _isSubmitting ? null : _releaseOrder,
                child: const Text('Give this order back', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ),
            if (_status != 'DELIVERED')
              TextButton(
                onPressed: _isSubmitting ? null : _reportIssue,
                child: const Text('Report a problem with this delivery', style: TextStyle(color: AppColors.danger, fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _locationCard({
    required IconData icon,
    required String title,
    required String text,
    required double? lat,
    required double? lng,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.surfaceBorder)),
      child: Row(
        children: [
          Icon(icon, color: AppColors.amber),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.directions, color: AppColors.amber),
            onPressed: () => _navigateTo(lat, lng, label),
          ),
        ],
      ),
    );
  }

  // Handover = payment confirmation: cash orders need the collected amount before completing.
  Future<Map<String, dynamic>> _deliverWithPayment() async {
    final total = num.tryParse(_order['total']?.toString() ?? '') ?? 0;
    final needsCash = _order['paymentMethod']?.toString() == 'CASH_ON_DELIVERY' && _order['paymentStatus']?.toString() != 'PAID';
    if (!needsCash) return ApiService.markDelivered(_delivery['id']);

    final controller = TextEditingController(text: total.toStringAsFixed(0));
    final amount = await showDialog<num>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Collect cash', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order total: PKR ${total.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Cash received (PKR)', labelStyle: TextStyle(color: AppColors.textMuted)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, num.tryParse(controller.text.trim())),
            child: const Text('Confirm & hand over', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (amount == null) return {'success': false, 'message': 'Cash collection not confirmed.'};
    return ApiService.markDelivered(_delivery['id'], cashCollected: amount);
  }

  Future<void> _releaseOrder() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Give this order back?', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: const Text('Other riders will be able to take it.', style: TextStyle(color: AppColors.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Keep it', style: TextStyle(color: AppColors.textMuted))),
          TextButton(onPressed: () => Navigator.pop(dialogCtx, true), child: const Text('Give back', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (ok != true || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    final result = await ApiService.releaseDelivery(_delivery['id']);
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (result['success'] == true) {
      widget.onChanged();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Could not release the order.'), backgroundColor: AppColors.danger),
      );
    }
  }

  Widget _buildActionButton() {
    String label;
    IconData icon;
    Color color;
    Future<Map<String, dynamic>> Function() action;

    switch (_status) {
      case 'ASSIGNED':
        label = 'Accept Delivery';
        icon = Icons.check_circle_outline;
        color = AppColors.amber;
        action = () => ApiService.acceptDelivery(_delivery['id']);
        break;
      case 'ACCEPTED':
        label = 'Mark Picked Up';
        icon = Icons.shopping_bag_outlined;
        color = AppColors.amber;
        action = () => ApiService.markPickedUp(_delivery['id']);
        break;
      case 'PICKED_UP':
        label = 'Start Delivery';
        icon = Icons.two_wheeler;
        color = AppColors.amber;
        action = () => ApiService.markOutForDelivery(_delivery['id']);
        break;
      case 'OUT_FOR_DELIVERY':
        label = 'Hand Over & Confirm Payment';
        icon = Icons.done_all;
        color = AppColors.success;
        action = _deliverWithPayment;
        break;
      default:
        return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : () => _runAction(action),
        icon: _isSubmitting
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
            : Icon(icon, color: Colors.black),
        label: Text(label, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
        style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      ),
    );
  }
}
