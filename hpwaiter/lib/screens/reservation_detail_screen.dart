import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../services/api_service.dart';
import 'table_order_screen.dart';

class ReservationDetailScreen extends StatefulWidget {
  final Map<String, dynamic> table;
  final Map<String, dynamic> reservation;

  const ReservationDetailScreen({super.key, required this.table, required this.reservation});

  @override
  State<ReservationDetailScreen> createState() => _ReservationDetailScreenState();
}

class _ReservationDetailScreenState extends State<ReservationDetailScreen> {
  bool _isSubmitting = false;

  String _formatDateTime(String? iso) {
    if (iso == null) return '—';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '—';
    final local = dt.toLocal();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.day} ${months[local.month - 1]}, $hour12:$minute $ampm';
  }

  Future<void> _seatGuests() async {
    setState(() => _isSubmitting = true);
    final result = await ApiService.seatReservation(widget.reservation['id'].toString());
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TableOrderScreen(table: widget.table)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Could not seat guests.'), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _cancel({required bool noShow}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(noShow ? 'Mark as No-Show?' : 'Cancel Reservation?'),
        content: Text(noShow ? 'This frees up the table — the guest never arrived.' : 'This frees up the table for other guests.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Back')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(noShow ? 'Mark No-Show' : 'Cancel It', style: const TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isSubmitting = true);
    final result = await ApiService.cancelReservation(widget.reservation['id'].toString(), noShow: noShow);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Could not update reservation.'), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reservation;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Table ${widget.table['number']} — Reserved')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.cardBorder)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(color: AppColors.primaryYellow.withValues(alpha: 0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.event_seat, color: AppColors.primaryOrange, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r['guestName'] ?? 'Guest', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.darkNavy)),
                          Text(r['guestPhone'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 28, color: AppColors.cardBorder),
                _detailRow(Icons.schedule, 'Reserved for', _formatDateTime(r['reservedFor']?.toString())),
                _detailRow(Icons.people_outline, 'Party size', '${r['partySize'] ?? '—'} guests'),
                if ((r['notes'] as String?)?.isNotEmpty == true) _detailRow(Icons.notes, 'Notes', r['notes']),
              ],
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _seatGuests,
              icon: const Icon(Icons.check_circle_outline, color: AppColors.darkNavy),
              label: const Text('Guests Have Arrived — Seat Now', style: TextStyle(color: AppColors.darkNavy, fontWeight: FontWeight.w900)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryYellow, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ),
          ),
          const SizedBox(height: 10),
          if ((r['guestPhone'] as String?)?.isNotEmpty == true)
            OutlinedButton.icon(
              onPressed: () => launchUrl(Uri.parse('tel:${r['guestPhone']}')),
              icon: const Icon(Icons.call, color: AppColors.success),
              label: const Text('Call Guest', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48), side: const BorderSide(color: AppColors.success), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : () => _cancel(noShow: true),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48), side: const BorderSide(color: AppColors.textMuted), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: const Text('No-Show', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : () => _cancel(noShow: false),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48), side: const BorderSide(color: AppColors.danger), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 10),
          SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkNavy))),
        ],
      ),
    );
  }
}
