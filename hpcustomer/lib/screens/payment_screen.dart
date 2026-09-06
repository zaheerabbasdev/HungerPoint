import 'package:flutter/material.dart';
import '../services/cart_service.dart';
import '../services/address_service.dart';
import '../services/branch_service.dart';
import 'location_picker_screen.dart';
import 'add_address_screen.dart';
import 'vouchers_tab.dart';
import 'main_navigation_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedPaymentMethod = 'Cash on Delivery';
  final TextEditingController _instructionsController = TextEditingController();
  SavedAddress? _selectedAddress;
  int _appliedDiscount = 0;
  String? _appliedVoucherCode;

  @override
  void initState() {
    super.initState();
    _selectedAddress = AddressService().selectedAddress;
    AddressService().selectedAddressNotifier.addListener(_onAddressChanged);
    AddressService().savedAddressesNotifier.addListener(_onAddressChanged);
    AddressService().customLocationNotifier.addListener(_onAddressChanged);
  }

  @override
  void dispose() {
    AddressService().selectedAddressNotifier.removeListener(_onAddressChanged);
    AddressService().savedAddressesNotifier.removeListener(_onAddressChanged);
    AddressService().customLocationNotifier.removeListener(_onAddressChanged);
    _instructionsController.dispose();
    super.dispose();
  }

  void _onAddressChanged() {
    if (mounted) {
      setState(() {
        _selectedAddress = AddressService().selectedAddress;
      });
    }
  }

  /// Opens the "Add or choose an address" bottom sheet matching Image 3
  void _showAddressBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setModalState) {
            final savedList = AddressService().savedAddresses;
            final currentSelected = AddressService().selectedAddress;

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      // Orange drag handle (Image 3)
                      Container(
                      width: 44,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5722),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: const Text(
                          'Add or choose an address',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E1B4B),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Select new location Row
                    InkWell(
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFF3ED),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.near_me_outlined,
                                color: Color(0xFFFF5722),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Text(
                              'Select new location',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFFF5722),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),

                    // Saved Addresses List with Orange Radio Selection (Image 3)
                    ...savedList.map((addr) {
                      final isSelected = currentSelected?.id == addr.id;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () {
                              AddressService().selectAddress(addr);
                              Navigator.pop(sheetCtx);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Custom Radio button (orange when selected)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected ? const Color(0xFFFF5722) : const Color(0xFFD1D5DB),
                                          width: isSelected ? 2.5 : 2,
                                        ),
                                        color: Colors.white,
                                      ),
                                      child: isSelected
                                          ? Center(
                                              child: Container(
                                                width: 10,
                                                height: 10,
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Color(0xFFFF5722),
                                                ),
                                              ),
                                            )
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Address Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          addr.label,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF1E1B4B),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          addr.address,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF6B7280),
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFF3F4F6)),
                        ],
                      );
                    }),
                    const SizedBox(height: 16),

                    // + ADD NEW ADDRESS Button
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AddAddressScreen()),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: const Center(
                          child: Text(
                            '+ ADD NEW ADDRESS',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFFF5722),
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          );
          },
        );
      },
    );
  }

  /// Handles Place Order action
  void _handlePlaceOrder(int total) {
    CartService().clearCart();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              Navigator.of(dialogCtx, rootNavigator: true).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                (route) => false,
              );
            }
          },
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 48),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Order Placed Successfully!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E1B4B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your order of PKR $total via $_selectedPaymentMethod has been confirmed.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF6B7280),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD600),
                        foregroundColor: const Color(0xFF1E1B4B),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.of(dialogCtx, rootNavigator: true).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                          (route) => false,
                        );
                      },
                      child: const Text(
                        'Go to Home',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Current branch name
    final branchName = BranchService().selectedBranch?.name ?? 'F-7 Old Islamabad';

    // Products price calculated from CartService
    final productsPrice = CartService().totalPrice > 0 ? CartService().totalPrice : 890;
    final discount = _appliedDiscount;
    const deliveryFee = 0;
    final tax = (productsPrice * 0.15).round(); // 15% tax
    final total = productsPrice - discount + deliveryFee + tax;
    final onlineTotal = (productsPrice * 1.05).round(); // slight variation for online options matching screenshot

    final address = _selectedAddress ?? AddressService().selectedAddress;
    final addressLabel = address?.label ?? 'Work';
    final addressText = address?.address ??
        'Executive Guest House, Bhitai Road, F 7/1, F 7, Islamabad, Islamabad Capital Territory';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E1B4B), size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Basket',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E1B4B),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              branchName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 1. DELIVER TO SECTION (Image 1) ───────────────────────
            const Text(
              'Deliver To',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E1B4B),
              ),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF3F4F6)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        addressLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E1B4B),
                        ),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _showAddressBottomSheet,
                        child: const Text(
                          'EDIT',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFF5722),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    addressText,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4B5563),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ─── 2. PAYMENT METHOD YELLOW CARD (Image 1) ───────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFDE03),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD600).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Method',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E1B4B),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 4 Payment Options
                  _buildPaymentOption(
                    title: 'Cash on Delivery',
                    price: 'PKR $total',
                    isSelected: _selectedPaymentMethod == 'Cash on Delivery',
                    onTap: () => setState(() => _selectedPaymentMethod = 'Cash on Delivery'),
                  ),
                  _buildPaymentOption(
                    title: 'Debit / Credit Card',
                    price: 'PKR $onlineTotal',
                    isSelected: _selectedPaymentMethod == 'Debit / Credit Card',
                    onTap: () => setState(() => _selectedPaymentMethod = 'Debit / Credit Card'),
                  ),
                  _buildPaymentOption(
                    title: 'JazzCash',
                    price: 'PKR $onlineTotal',
                    isSelected: _selectedPaymentMethod == 'JazzCash',
                    onTap: () => setState(() => _selectedPaymentMethod = 'JazzCash'),
                  ),
                  _buildPaymentOption(
                    title: 'Easypaisa',
                    price: 'PKR $onlineTotal',
                    isSelected: _selectedPaymentMethod == 'Easypaisa',
                    onTap: () => setState(() => _selectedPaymentMethod = 'Easypaisa'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ─── 3. APPLY VOUCHERS (Image 1 & 2) ───────────────────────
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VouchersScreen(
                      onVoucherApplied: (code, discount) {
                        setState(() {
                          _appliedVoucherCode = code;
                          _appliedDiscount = discount;
                        });
                      },
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFF3F4F6)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Apply Vouchers',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E1B4B),
                          ),
                        ),
                        if (_appliedVoucherCode != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5722),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _appliedVoucherCode!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Color(0xFF1E1B4B),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ─── 4. BILL SUMMARY (Image 2) ─────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF3F4F6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bill Summary',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E1B4B),
                    ),
                  ),
                  const SizedBox(height: 14),

                  _buildBillRow('Products Price', 'PKR $productsPrice'),
                  const SizedBox(height: 10),
                  _buildBillRow('Discount', '-Rs.$discount'),
                  const SizedBox(height: 10),
                  _buildBillRow('Delivery Fee', '+Rs.$deliveryFee'),
                  const SizedBox(height: 10),
                  _buildBillRow('Tax (15%)', '+Rs $tax'),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFF3F4F6)),
                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E1B4B),
                        ),
                      ),
                      Text(
                        'PKR $total',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFFF5722),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ─── 5. DELIVERY INSTRUCTIONS (Image 2) ────────────────────
            const Text(
              'Delivery Instructions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E1B4B),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Are there any specific delivery instructions?',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF3F4F6)),
              ),
              child: TextField(
                controller: _instructionsController,
                decoration: const InputDecoration(
                  hintText: 'e.g No doorbell ring',
                  hintStyle: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFFF9FAFB),
        padding: EdgeInsets.fromLTRB(
          16,
          10,
          16,
          MediaQuery.of(context).padding.bottom + 42,
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFDE03),
              foregroundColor: const Color(0xFF1E1B4B),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => _handlePlaceOrder(total),
            child: const Text(
              'PLACE ORDER',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String title,
    required String price,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            // Custom Radio Button (Orange filled dot when selected matching Image 1)
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF1E1B4B),
                  width: 2,
                ),
                color: Colors.white,
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFFF9800),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E1B4B),
              ),
            ),
            const Spacer(),

            Text(
              price,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E1B4B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13.5,
            color: Color(0xFF1E1B4B),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E1B4B),
          ),
        ),
      ],
    );
  }
}
