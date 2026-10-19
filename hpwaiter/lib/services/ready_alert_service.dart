import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../screens/table_order_screen.dart';
import 'api_service.dart';

/// Shows a "food is ready" alert on whatever screen the waiter is on when the
/// kitchen marks one of their dine-in orders Ready (socket event
/// `waiter.order_ready`, sent only to the waiter who took the order).
class ReadyAlertService {
  static final navigatorKey = GlobalKey<NavigatorState>();
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  // The same order can be announced again after a reconnect; alert once.
  static final Set<String> _announced = {};

  static void handle(dynamic data) {
    if (data is! Map) return;
    final orderId = data['orderId']?.toString();
    if (orderId == null || !_announced.add(orderId)) return;

    final tableNumber = data['tableNumber']?.toString();
    final floor = data['floor']?.toString();
    final tableId = data['tableId']?.toString();
    final title = tableNumber != null ? 'Table $tableNumber — food is ready' : 'Dine-in order is ready';
    final subtitle = [
      if (floor != null && floor.isNotEmpty) floor,
      if (data['orderNumber'] != null) 'Order ${data['orderNumber']}',
    ].join(' · ');

    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.heavyImpact();

    final messenger = messengerKey.currentState;
    if (messenger == null) return;
    messenger.hideCurrentMaterialBanner();
    messenger.showMaterialBanner(
      MaterialBanner(
        backgroundColor: AppColors.success,
        leading: const Icon(Icons.room_service, color: Colors.white, size: 32),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            if (subtitle.isNotEmpty)
              Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => messenger.hideCurrentMaterialBanner(),
            child: const Text('Later', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              messenger.hideCurrentMaterialBanner();
              if (tableId == null) return;
              final table = await ApiService.fetchTableById(tableId);
              final nav = navigatorKey.currentState;
              if (table == null || nav == null) return;
              nav.push(MaterialPageRoute(builder: (_) => TableOrderScreen(table: Map<String, dynamic>.from(table))));
            },
            child: const Text('SERVE NOW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
