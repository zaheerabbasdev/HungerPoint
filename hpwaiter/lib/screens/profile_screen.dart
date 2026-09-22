import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Log Out', style: TextStyle(color: AppColors.darkNavy)),
        content: const Text('Are you sure you want to log out?', style: TextStyle(color: AppColors.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
          TextButton(onPressed: () => Navigator.pop(dialogCtx, true), child: const Text('Log Out', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (confirmed != true) return;

    SocketService().disconnect();
    await ApiService.logout();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiService.currentUser;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.primaryYellow, AppColors.primaryOrange]), shape: BoxShape.circle),
              child: const Icon(Icons.room_service_outlined, size: 44, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Center(child: Text(user?['name'] ?? 'Waiter', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkNavy))),
          Center(child: Text(user?['phone'] ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textMuted))),
          const SizedBox(height: 28),

          _infoRow(Icons.badge_outlined, 'Role', 'WAITER'),
          _infoRow(Icons.mail_outline, 'Email', user?['email'] ?? 'Not set'),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout, color: AppColors.danger),
              label: const Text('Log Out', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.danger), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.cardBorder)),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryOrange, size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.darkNavy)),
        ],
      ),
    );
  }
}
