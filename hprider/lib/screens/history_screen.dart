import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = true;
  List<dynamic> _deliveries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final deliveries = await ApiService.getDeliveryHistory();
    if (!mounted) return;
    setState(() {
      _deliveries = deliveries;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery History')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.amber))
            : _deliveries.isEmpty
                ? ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: const Center(
                          child: Text('No completed deliveries yet', style: TextStyle(color: AppColors.textMuted)),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _deliveries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final delivery = _deliveries[index];
                      final order = delivery['order'] ?? {};
                      final status = delivery['status']?.toString() ?? '';
                      final isDelivered = status == 'DELIVERED';
                      final total = num.tryParse(order['total']?.toString() ?? '') ?? 0;
                      final customerName = order['customer']?['user']?['name'] ?? 'Customer';
                      final date = delivery['deliveredAt'] ?? delivery['updatedAt'];
                      final dateStr = date != null ? date.toString().substring(0, 10) : '';

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: (isDelivered ? AppColors.success : AppColors.danger).withValues(alpha: 0.15),
                              child: Icon(isDelivered ? Icons.check : Icons.close, color: isDelivered ? AppColors.success : AppColors.danger, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(order['orderNumber'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                  const SizedBox(height: 2),
                                  Text('$customerName · $dateStr', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                            Text('PKR ${total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.amber)),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
