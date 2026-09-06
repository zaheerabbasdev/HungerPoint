import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/address_service.dart';

class NewAddressFormScreen extends StatefulWidget {
  final String mapAddress;
  final SavedAddress? existingAddress;

  const NewAddressFormScreen({
    super.key,
    this.mapAddress = '',
    this.existingAddress,
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

  @override
  void initState() {
    super.initState();
    if (widget.existingAddress != null) {
      final label = widget.existingAddress!.label;
      if (label.toLowerCase() == 'home') {
        _selectedLabel = 0;
        _addressDetailController.text = 'Home';
      } else if (label.toLowerCase() == 'work') {
        _selectedLabel = 1;
        _addressDetailController.text = 'Work';
      } else {
        _selectedLabel = 2;
        _customLabelController.text = label;
        _addressDetailController.text = label;
      }
    }
  }

  String get _currentLabel {
    if (_selectedLabel == 2) {
      return _customLabelController.text.trim();
    }
    return _labels[_selectedLabel];
  }

  OverlayEntry? _topToastOverlay;

  void _showTopToast(String message) {
    _topToastOverlay?.remove();
    _topToastOverlay = null;

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    final topPadding = MediaQuery.of(context).padding.top;

    _topToastOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: topPadding + 14,
        left: 18,
        right: 18,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, -25 * (1 - value)),
                child: Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: child,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_topToastOverlay!);

    Future.delayed(const Duration(seconds: 3), () {
      _topToastOverlay?.remove();
      _topToastOverlay = null;
    });
  }

  void _onSaveAddress() {
    final detail = _addressDetailController.text.trim();
    if (detail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter address details'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final label = _currentLabel;
    if (_selectedLabel == 2 && label.isEmpty) {
      _showTopToast('Please enter address name (e.g. Mardan)');
      return;
    }

    if (widget.existingAddress != null) {
      // Check if another address has this same label
      if (AddressService().hasAddressWithLabelExcludingId(label, widget.existingAddress!.id)) {
        _showTopToast('Address with same address type is already exist');
        return;
      }

      final fullAddress = widget.mapAddress.isNotEmpty
          ? widget.mapAddress
          : widget.existingAddress!.address;

      AddressService().updateAddress(
        id: widget.existingAddress!.id,
        label: label,
        address: fullAddress,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address updated successfully!'),
          backgroundColor: Color(0xFF2E7D32),
          duration: Duration(seconds: 2),
        ),
      );

      // Pop back past AddAddressScreen
      int count = 0;
      Navigator.popUntil(context, (route) {
        return count++ == 2 || route.isFirst;
      });
      return;
    }

    // Check if address with same type/label already exists
    if (AddressService().hasAddressWithLabel(label)) {
      _showTopToast('Address with same address type is already exist');
      return;
    }

    final fullAddress = widget.mapAddress.isNotEmpty
        ? (detail.toLowerCase() == label.toLowerCase() ? widget.mapAddress : '$detail, ${widget.mapAddress}')
        : detail;

    AddressService().addAddress(
      label: label,
      address: fullAddress,
      selectImmediately: true,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Address added successfully!'),
        backgroundColor: Color(0xFF2E7D32),
        duration: Duration(seconds: 2),
      ),
    );

    int count = 0;
    Navigator.popUntil(context, (route) {
      return count++ == 2 || route.isFirst;
    });
  }

  @override
  void dispose() {
    _topToastOverlay?.remove();
    _topToastOverlay = null;
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
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 64,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E1B4B), size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.existingAddress != null ? 'Update Location' : 'New Address',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1B4B),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Complete your address',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E1B4B),
                      ),
                    ),
                    if (widget.mapAddress.isNotEmpty || widget.existingAddress != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        widget.mapAddress.isNotEmpty
                            ? widget.mapAddress
                            : widget.existingAddress!.address,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF6B7280),
                          height: 1.4,
                        ),
                      ),
                    ],
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
                            onTap: () {
                              setState(() {
                                _selectedLabel = i;
                                if (i == 0 && (_addressDetailController.text.isEmpty || _addressDetailController.text == 'Work' || _addressDetailController.text == _customLabelController.text)) {
                                  _addressDetailController.text = 'Home';
                                } else if (i == 1 && (_addressDetailController.text.isEmpty || _addressDetailController.text == 'Home' || _addressDetailController.text == _customLabelController.text)) {
                                  _addressDetailController.text = 'Work';
                                } else if (i == 2 && (_addressDetailController.text == 'Home' || _addressDetailController.text == 'Work')) {
                                  _addressDetailController.text = _customLabelController.text;
                                }
                              });
                            },
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
                            hintText: "e.g. Mardan",
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
                    onPressed: _onSaveAddress,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      widget.existingAddress != null ? 'UPDATE LOCATION' : 'ADD NEW ADDRESS',
                      style: const TextStyle(
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
