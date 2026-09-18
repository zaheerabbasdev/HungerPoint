import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../services/location_tracking_service.dart';
import '../screens/history_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/login_screen.dart';

/// Side navigation drawer for the rider app, mirroring the structure of
/// hpcustomer's SideProfileDrawer (header card + menu list + support card).
class RiderDrawer extends StatelessWidget {
  final bool isOnline;

  const RiderDrawer({super.key, required this.isOnline});

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you sure you want to log out of your HungerPoint Rider account?',
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('CANCEL', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              LocationTrackingService().stop();
              SocketService().disconnect();
              await ApiService.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('LOGOUT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiService.currentUser;
    final rider = ApiService.currentRider;

    return Drawer(
      backgroundColor: AppColors.background,
      child: Column(
        children: [
          // ─── Header ───────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            color: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [AppColors.amber, AppColors.orange]),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.two_wheeler, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?['name'] ?? 'Rider',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(user?['phone'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (isOnline ? AppColors.success : AppColors.danger).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: (isOnline ? AppColors.success : AppColors.danger).withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    isOnline ? '🟢 Online' : '🔴 Offline',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isOnline ? AppColors.success : AppColors.danger),
                  ),
                ),
                if (rider != null) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.two_wheeler, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Text(rider['vehicle'] ?? 'Vehicle not set', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      if (rider['licensePlate'] != null) ...[
                        const SizedBox(width: 10),
                        const Icon(Icons.confirmation_number_outlined, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Text(rider['licensePlate'], style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ],
                  ),
                  if (rider['branch']?['name'] != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.store_outlined, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Text(rider['branch']['name'], style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),

          // ─── Menu ─────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.home_outlined,
                  title: 'Dashboard',
                  onTap: () => Navigator.pop(context),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.history,
                  title: 'Delivery History',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.person_outline,
                  title: 'Profile',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                  },
                ),
                const Divider(color: AppColors.surfaceBorder, height: 24, indent: 16, endIndent: 16),
                _buildDrawerItem(
                  context,
                  icon: Icons.logout,
                  title: 'Logout',
                  color: AppColors.danger,
                  onTap: () => _showLogoutDialog(context),
                ),
              ],
            ),
          ),

          // ─── Support card ─────────────────────────────────────
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => launchUrl(Uri.parse('tel:+92511114864379')),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.amber, AppColors.orange]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Text('🛠️', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 10),
                      Text('RIDER SUPPORT', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.black)),
                      Spacer(),
                      Icon(Icons.phone, color: Colors.black),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.amber, size: 22),
      title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color ?? Colors.white)),
      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted.withValues(alpha: 0.6)),
      onTap: onTap,
    );
  }
}
