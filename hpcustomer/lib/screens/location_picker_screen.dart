import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/address_service.dart';
import 'main_navigation_screen.dart';

/// Sample address data for search suggestions (simulating a location API)
const List<Map<String, String>> _allAddresses = [
  {'name': 'F-7 Markaz, Islamabad', 'detail': 'F 7, Islamabad Capital Territory'},
  {'name': 'Blue Area, Islamabad', 'detail': 'Jinnah Avenue, Blue Area, Islamabad'},
  {'name': 'G-11 Markaz, Islamabad', 'detail': 'G-11, Islamabad Capital Territory'},
  {'name': 'E-11, Islamabad', 'detail': 'E-11, Islamabad Capital Territory'},
  {'name': 'Bahria Town Phase 2', 'detail': 'Bahria Town, Rawalpindi, Punjab'},
  {'name': 'DHA Phase 1, Islamabad', 'detail': 'DHA Phase 1, Islamabad Capital Territory'},
  {'name': 'Saddar, Rawalpindi', 'detail': 'Saddar Bazar, Rawalpindi, Punjab'},
  {'name': 'I-8 Markaz, Islamabad', 'detail': 'I-8, Islamabad Capital Territory'},
  {'name': 'PWD Housing Society', 'detail': 'PWD Road, Islamabad Capital Territory'},
  {'name': 'Gulberg Greens, Islamabad', 'detail': 'Gulberg, Islamabad Capital Territory'},
  {'name': 'Sector H-13, Islamabad', 'detail': 'H-13, Islamabad Capital Territory'},
  {'name': 'Centaurus Mall', 'detail': 'Jinnah Avenue, F-8 Markaz, Islamabad'},
  {'name': 'Faisal Mosque Area', 'detail': 'Faisal Mosque Road, Islamabad Capital Territory'},
  {'name': 'Rawalpindi Cantt', 'detail': 'Cantonment, Rawalpindi, Punjab'},
  {'name': 'Kaghan Road, G-7', 'detail': 'G-7 Markaz, Islamabad Capital Territory'},
  {'name': '27, Street 41, F 7/1, F 7', 'detail': 'Islamabad Capital Territory'},
  {'name': 'Malpur, Islamabad', 'detail': 'Malpur Road, Islamabad Capital Territory'},
  {'name': 'Saidpur Village', 'detail': 'Margalla Hills, Islamabad Capital Territory'},
];

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  String _selectedAddress = '27, Street 41, F 7/1, F 7, Islamabad,\nIslamabad Capital Territory';
  List<Map<String, String>> _suggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(() {
      setState(() {
        _showSuggestions = _searchFocusNode.hasFocus && _suggestions.isNotEmpty;
      });
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    final filtered = _allAddresses.where((addr) {
      return addr['name']!.toLowerCase().contains(query) ||
          addr['detail']!.toLowerCase().contains(query);
    }).toList();

    setState(() {
      _suggestions = filtered;
      _showSuggestions = filtered.isNotEmpty && _searchFocusNode.hasFocus;
    });
  }

  void _selectSuggestion(Map<String, String> addr) {
    final fullAddress = '${addr['name']!},\n${addr['detail']!}';
    setState(() {
      _selectedAddress = fullAddress;
      _searchController.text = addr['name']!;
      _suggestions = [];
      _showSuggestions = false;
    });
    _searchFocusNode.unfocus();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _suggestions = [];
      _showSuggestions = false;
    });
  }

  /// Shows the "Please type address" modal dialog.
  Future<void> _showAddressInputModal() async {
    final addressController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Please type address',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E1B4B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: addressController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E1B4B),
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. House123',
                      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primaryYellow, width: 1.8),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please enter your address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFE054), Color(0xFFFFC727)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          final address = addressController.text.trim();
                          AddressService().setAddress(address);
                          Navigator.of(dialogContext).pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'CONTINUE',
                        style: TextStyle(
                          color: Color(0xFF1E1B4B),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
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

    if (!mounted) return;
    if (AddressService().currentAddress != null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _searchFocusNode.unfocus();
        setState(() => _showSuggestions = false);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leadingWidth: 180,
          leading: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.pop(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.arrow_back, color: Color(0xFF1E1B4B), size: 24),
                  SizedBox(width: 6),
                  Text(
                    'Choose Location',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1B4B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            // ─── Map Area ─────────────────────────────────────────
            Expanded(
              child: Stack(
                children: [
                  // Simulated map background
                  Container(
                    color: const Color(0xFFE8EDF0),
                    child: CustomPaint(
                      painter: _MapPainter(),
                      child: const SizedBox.expand(),
                    ),
                  ),

                  // Location pin in center
                  const Center(child: _LocationPin()),

                  // Search bar + dropdown overlay
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      children: [
                        // Search TextField
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1E1B4B),
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search address...',
                              hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                              prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF), size: 20),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? GestureDetector(
                                      onTap: _clearSearch,
                                      child: const Icon(Icons.close, color: Color(0xFF9CA3AF), size: 18),
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),

                        // Suggestions dropdown
                        if (_showSuggestions && _suggestions.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            constraints: const BoxConstraints(maxHeight: 260),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shrinkWrap: true,
                              itemCount: _suggestions.length,
                              separatorBuilder: (_, __) => const Divider(
                                height: 1,
                                indent: 50,
                                endIndent: 16,
                                color: Color(0xFFF3F4F6),
                              ),
                              itemBuilder: (context, index) {
                                final addr = _suggestions[index];
                                return GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => _selectSuggestion(addr),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.only(top: 2),
                                          child: Icon(
                                            Icons.location_on_outlined,
                                            color: AppColors.primaryOrange,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                addr['name']!,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF1E1B4B),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                addr['detail']!,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF6B7280),
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
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ─── Bottom Panel ──────────────────────────────────────
            SafeArea(
              top: false,
              child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, -4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Center(
                    child: Text(
                      'Choose Location',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1B4B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFF3ED),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.primaryOrange,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _selectedAddress,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF4B5563),
                              height: 1.45,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _showAddressInputModal,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primaryOrange, width: 1.8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'CONTINUE',
                        style: TextStyle(
                          color: AppColors.primaryOrange,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ), // SafeArea
          ],
        ),
      ),
    );
  }
}

/// Simple "location pin" widget
class _LocationPin extends StatelessWidget {
  const _LocationPin();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(
            color: AppColors.primaryOrange,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.location_on, color: Colors.white, size: 26),
        ),
        CustomPaint(
          size: const Size(14, 8),
          painter: _PinTrianglePainter(),
        ),
      ],
    );
  }
}

class _PinTrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.primaryOrange;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Draws a simple stylized city-block map grid to simulate a map
class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;

    final minorRoadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    for (int i = 1; i < 8; i++) {
      final y = size.height * i / 8;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), i % 2 == 0 ? roadPaint : minorRoadPaint);
    }
    for (int i = 1; i < 6; i++) {
      final x = size.width * i / 6;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), i % 2 == 0 ? roadPaint : minorRoadPaint);
    }

    final blockPaint = Paint()
      ..color = const Color(0xFFD1E8C7).withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.05, size.height * 0.1, size.width * 0.25, size.height * 0.15),
      blockPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.55, size.height * 0.4, size.width * 0.3, size.height * 0.12),
      blockPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.1, size.height * 0.65, size.width * 0.2, size.height * 0.18),
      blockPaint,
    );

    final bldgPaint = Paint()
      ..color = const Color(0xFFCDD5E0).withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.4, size.height * 0.05, size.width * 0.14, size.height * 0.14),
      bldgPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.62, size.height * 0.6, size.width * 0.2, size.height * 0.16),
      bldgPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.1, size.height * 0.3, size.width * 0.22, size.height * 0.1),
      bldgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
