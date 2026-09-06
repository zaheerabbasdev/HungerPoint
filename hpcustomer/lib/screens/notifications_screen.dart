import 'package:flutter/material.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String time;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    this.isRead = false,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<AppNotification> _notifications = [
    AppNotification(
      id: 'notif_1',
      title: 'Weekend Special: 30% OFF! 🍕',
      message: 'Craving delicious pizza? Enjoy 30% off on all Thin Crust Pizzas this weekend. Use code CRUST30 at checkout!',
      time: '10 mins ago',
      icon: Icons.local_offer_outlined,
      iconColor: const Color(0xFFFF5722),
      iconBgColor: const Color(0xFFFFF3ED),
      isRead: false,
    ),
    AppNotification(
      id: 'notif_2',
      title: 'Order Delivered Successfully 🛵',
      message: 'Your order #HP-8921 has been delivered to Executive Guest House. Enjoy your meal and please rate us!',
      time: '2 hours ago',
      icon: Icons.check_circle_outline,
      iconColor: const Color(0xFF2E7D32),
      iconBgColor: const Color(0xFFE8F5E9),
      isRead: false,
    ),
    AppNotification(
      id: 'notif_3',
      title: 'New Voucher Added! 🎁',
      message: 'A PKR 250 discount voucher has been added to your vouchers tab. Valid until end of month.',
      time: 'Yesterday',
      icon: Icons.card_giftcard,
      iconColor: const Color(0xFF1E1B4B),
      iconBgColor: const Color(0xFFEEF2FF),
      isRead: true,
    ),
    AppNotification(
      id: 'notif_4',
      title: 'Order Confirmed 🔥',
      message: 'HungerPoint Islamabad branch is preparing your order #HP-8921 fresh from the kitchen.',
      time: '2 days ago',
      icon: Icons.restaurant,
      iconColor: const Color(0xFFFF9800),
      iconBgColor: const Color(0xFFFFF8E1),
      isRead: true,
    ),
  ];

  void _markAllAsRead() {
    setState(() {
      for (var n in _notifications) {
        n.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E1B4B), size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1E1B4B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: const Text(
              'Mark all read',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFF5722),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFF3F4F6)),
        ),
      ),
      body: _notifications.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 60, color: Color(0xFFD1D5DB)),
                  SizedBox(height: 12),
                  Text(
                    'No Notifications',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B)),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "You're all caught up with your updates",
                    style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            )
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notif = _notifications[index];
                return Dismissible(
                  key: Key(notif.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
                  ),
                  onDismissed: (_) {
                    setState(() => _notifications.removeAt(index));
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: notif.isRead ? Colors.white : const Color(0xFFFFFBF9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: notif.isRead ? const Color(0xFFF3F4F6) : const Color(0xFFFFE5D9),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Icon
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: notif.iconBgColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(notif.icon, color: notif.iconColor, size: 22),
                        ),
                        const SizedBox(width: 14),

                        // Title, Message, Time
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      notif.title,
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: notif.isRead ? FontWeight.bold : FontWeight.w900,
                                        color: const Color(0xFF1E1B4B),
                                      ),
                                    ),
                                  ),
                                  if (!notif.isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFF5722),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                notif.message,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF4B5563),
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                notif.time,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF9CA3AF),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
