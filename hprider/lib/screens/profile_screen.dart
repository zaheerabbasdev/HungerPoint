import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../services/location_tracking_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _rider;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rider = await ApiService.getMyRiderProfile();
    if (!mounted) return;
    setState(() {
      _rider = rider;
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Log Out', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to log out?', style: TextStyle(color: AppColors.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
          TextButton(onPressed: () => Navigator.pop(dialogCtx, true), child: const Text('Log Out', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (confirmed != true) return;

    LocationTrackingService().stop();
    SocketService().disconnect();
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiService.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.amber))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.amber, AppColors.orange]), shape: BoxShape.circle),
                    child: const Icon(Icons.two_wheeler, size: 44, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                Center(child: Text(user?['name'] ?? 'Rider', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white))),
                Center(child: Text(user?['phone'] ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textMuted))),
                const SizedBox(height: 28),

                _infoRow(Icons.two_wheeler, 'Vehicle', _rider?['vehicle'] ?? 'Not set'),
                _infoRow(Icons.confirmation_number_outlined, 'License Plate', _rider?['licensePlate'] ?? 'Not set'),
                _infoRow(Icons.store_outlined, 'Branch', _rider?['branch']?['name'] ?? 'Unassigned'),
                _infoRow(Icons.circle, 'Status', (_rider?['status'] ?? 'OFFLINE').toString().replaceAll('_', ' ')),

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
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
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Icon(icon, color: AppColors.amber, size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}
