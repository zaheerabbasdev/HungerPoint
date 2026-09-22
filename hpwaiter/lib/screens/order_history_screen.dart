import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/api_service.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  bool _isLoading = true;
  List<dynamic> _orders = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final orders = await ApiService.getMyBranchOrders(type: 'DINE_IN');
    if (!mounted) return;
    setState(() {
      _orders = orders;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Order History')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow))
            : _orders.isEmpty
                ? ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: const Center(child: Text('No dine-in orders yet', style: TextStyle(color: AppColors.textMuted))),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final order = Map<String, dynamic>.from(_orders[index]);
                      final status = order['status']?.toString() ?? '';
                      final isDone = status == 'COMPLETED';
                      final total = num.tryParse(order['total']?.toString() ?? '') ?? 0;
                      final table = order['table']?['number'] ?? '—';
                      final date = order['createdAt']?.toString();
                      final dateStr = date != null && date.length >= 10 ? date.substring(0, 10) : '';

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.cardBorder)),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: (isDone ? AppColors.success : AppColors.primaryOrange).withValues(alpha: 0.12),
                              child: Icon(isDone ? Icons.check : Icons.hourglass_bottom, color: isDone ? AppColors.success : AppColors.primaryOrange, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Table $table · ${order['orderNumber'] ?? ''}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.darkNavy)),
                                  const SizedBox(height: 2),
                                  Text('$dateStr · ${status.replaceAll('_', ' ')}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                            Text('PKR ${total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryOrange)),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
