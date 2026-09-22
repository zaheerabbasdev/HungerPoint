import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/api_service.dart';

class ReservationFormScreen extends StatefulWidget {
  final Map<String, dynamic> table;

  const ReservationFormScreen({super.key, required this.table});

  @override
  State<ReservationFormScreen> createState() => _ReservationFormScreenState();
}

class _ReservationFormScreenState extends State<ReservationFormScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  int _partySize = 2;
  DateTime _reservedFor = DateTime.now().add(const Duration(hours: 1));
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _reservedFor,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_reservedFor));
    if (time == null) return;

    setState(() => _reservedFor = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guest name and phone are required.')));
      return;
    }

    setState(() => _isSubmitting = true);
    final result = await ApiService.createReservation(
      tableId: widget.table['id'].toString(),
      branchId: widget.table['branchId'].toString(),
      guestName: name,
      guestPhone: phone,
      partySize: _partySize,
      reservedFor: _reservedFor,
      notes: _notesController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Could not reserve table.'), backgroundColor: AppColors.danger),
      );
    }
  }

  String _formatDateTime(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]}, $hour12:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Reserve Table ${widget.table['number']}')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _label('Guest Name'),
          TextField(controller: _nameController, decoration: _inputDecoration('e.g. Sara Malik')),
          const SizedBox(height: 16),

          _label('Guest Phone'),
          TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: _inputDecoration('e.g. 03211234567')),
          const SizedBox(height: 16),

          _label('Party Size'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.cardBorder)),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, color: AppColors.darkNavy),
                  onPressed: () => setState(() => _partySize = (_partySize - 1).clamp(1, 20)),
                ),
                Expanded(
                  child: Text('$_partySize guest${_partySize == 1 ? '' : 's'}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkNavy)),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: AppColors.darkNavy),
                  onPressed: () => setState(() => _partySize = (_partySize + 1).clamp(1, 20)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _label('Reserved For'),
          GestureDetector(
            onTap: _pickDateTime,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.cardBorder)),
              child: Row(
                children: [
                  const Icon(Icons.schedule, color: AppColors.primaryOrange, size: 20),
                  const SizedBox(width: 10),
                  Text(_formatDateTime(_reservedFor), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkNavy)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          _label('Notes (optional)'),
          TextField(controller: _notesController, maxLines: 2, decoration: _inputDecoration('e.g. Birthday, window seat...')),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryYellow, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: _isSubmitting
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.darkNavy))
                  : const Text('Confirm Reservation', style: TextStyle(color: AppColors.darkNavy, fontWeight: FontWeight.w900, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.cardBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.cardBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primaryOrange)),
      );
}
