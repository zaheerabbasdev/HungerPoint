import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/address_service.dart';
import 'main_navigation_screen.dart';

class NewAddressFormScreen extends StatefulWidget {
  final String mapAddress;

  const NewAddressFormScreen({
    super.key,
    this.mapAddress = '',
  });

  @override
  State<NewAddressFormScreen> createState() => _NewAddressFormScreenState();
}

class _NewAddressFormScreenState extends State<NewAddressFormScreen> {
  final TextEditingController _addressDetailController = TextEditingController();
  final TextEditingController _customLabelController = TextEditingController();

  /// 0 = Home, 1 = Work, 2 = Other
  int _selectedLabel = 0;

  static const List<String> _labels = ['Home', 'Work', 'Other'];

  String get _currentLabel {
    if (_selectedLabel == 2) {
      final custom = _customLabelController.text.trim();
      return custom.isNotEmpty ? custom : 'Other';
    }
    return _labels[_selectedLabel];
  }

  void _onAddNewAddress() {
    final detail = _addressDetailController.text.trim();
    if (detail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter house / flat / apartment / office number'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Build display address
    final label = _currentLabel;

    // Check if address with same type/label already exists
    if (AddressService().hasAddressWithLabel(label)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Address with same address type is already exist',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    final fullAddress = widget.mapAddress.isNotEmpty
        ? '$detail, ${widget.mapAddress}'
        : detail;

    AddressService().addAddress(
      label: label,
      address: fullAddress,
      selectImmediately: true,
    );

    // Navigate all the way back to home
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _addressDetailController.dispose();
    _customLabelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 160,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.pop(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.arrow_back, color: Color(0xFF1E1B4B), size: 22),
                SizedBox(width: 6),
                Text(
                  'New Address',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1B4B),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30),
          child: Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Complete your address',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Address Section ──────────────────────────────
                    const Text(
                      'Address',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E1B4B),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // House / Flat input field
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _addressDetailController,
                        textCapitalization: TextCapitalization.words,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1E1B4B),
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'House / Flat / Apartment / Office No.',
                          hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ─── Add Label Section ────────────────────────────
                    const Divider(color: Color(0xFFE5E7EB), height: 1),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        'Add Label',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Home / Work / Other label buttons
                    Row(
                      children: List.generate(3, (i) {
                        final isSelected = _selectedLabel == i;
                        return Padding(
                          padding: EdgeInsets.only(right: i < 2 ? 10 : 0),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedLabel = i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primaryOrange : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? AppColors.primaryOrange : const Color(0xFFE5E7EB),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  if (!isSelected)
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                ],
                              ),
                              child: Text(
                                _labels[i],
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? Colors.white : const Color(0xFF4B5563),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),

                    // Custom label field (only when "Other" is selected)
                    if (_selectedLabel == 2) ...[
                      const SizedBox(height: 14),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _customLabelController,
                          textCapitalization: TextCapitalization.words,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF1E1B4B),
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: const InputDecoration(
                            hintText: "e.g Osama's House",
                            hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ─── ADD NEW ADDRESS Button ───────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SafeArea(
                top: false,
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFE054), Color(0xFFFFC727)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFC107).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _onAddNewAddress,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                      'ADD NEW ADDRESS',
                      style: TextStyle(
                        color: Color(0xFF1E1B4B),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
