import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'new_address_form_screen.dart';

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  static const List<Map<String, String>> _allAddresses = [
    {'name': 'F-7 Markaz, Islamabad', 'detail': 'F 7, Islamabad Capital Territory'},
    {'name': 'Blue Area, Islamabad', 'detail': 'Jinnah Avenue, Blue Area, Islamabad'},
    {'name': 'G-11 Markaz, Islamabad', 'detail': 'G-11, Islamabad Capital Territory'},
    {'name': 'E-11, Islamabad', 'detail': 'E-11, Islamabad Capital Territory'},
    {'name': 'Bahria Town Phase 2', 'detail': 'Bahria Town, Rawalpindi, Punjab'},
    {'name': 'DHA Phase 1, Islamabad', 'detail': 'DHA Phase 1, Islamabad Capital Territory'},
    {'name': 'Saddar, Rawalpindi', 'detail': 'Saddar Bazar, Rawalpindi, Punjab'},
    {'name': 'I-8 Markaz, Islamabad', 'detail': 'I-8, Islamabad Capital Territory'},
    {'name': 'Gulberg Greens, Islamabad', 'detail': 'Gulberg, Islamabad Capital Territory'},
    {'name': 'Centaurus Mall', 'detail': 'Jinnah Avenue, F-8 Markaz, Islamabad'},
    {'name': 'Faisal Mosque Area', 'detail': 'Faisal Mosque Road, Islamabad Capital Territory'},
    {'name': 'Kaghan Road, G-7', 'detail': 'G-7 Markaz, Islamabad Capital Territory'},
    {'name': 'Mantra Safa Gold Mall', 'detail': 'F-7 Markaz, Islamabad Capital Territory'},
    {'name': 'Saidpur Village', 'detail': 'Margalla Hills, Islamabad Capital Territory'},
  ];

  List<Map<String, String>> _suggestions = [];
  bool _showSuggestions = false;
  String _selectedMapAddress = '27, Street 41, F 7/1, F 7, Islamabad Capital Territory';

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
      setState(() { _suggestions = []; _showSuggestions = false; });
      return;
    }
    final filtered = _allAddresses.where((a) =>
        a['name']!.toLowerCase().contains(query) ||
        a['detail']!.toLowerCase().contains(query)).toList();
    setState(() {
      _suggestions = filtered;
      _showSuggestions = filtered.isNotEmpty && _searchFocusNode.hasFocus;
    });
  }

  void _selectSuggestion(Map<String, String> addr) {
    setState(() {
      _selectedMapAddress = '${addr['name']!}, ${addr['detail']!}';
      _searchController.text = addr['name']!;
      _suggestions = [];
      _showSuggestions = false;
    });
    _searchFocusNode.unfocus();
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
                    'Add Address',
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
        ),
        body: Column(
          children: [
            // ─── Map Area ────────────────────────────────────────
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

                  // Centered location pin
                  const Center(child: _LocationPin()),

                  // Search bar + suggestions overlay
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      children: [
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
                                      onTap: () {
                                        _searchController.clear();
                                        setState(() { _suggestions = []; _showSuggestions = false; });
                                      },
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
                            constraints: const BoxConstraints(maxHeight: 240),
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
                                height: 1, indent: 50, endIndent: 16,
                                color: Color(0xFFF3F4F6),
                              ),
                              itemBuilder: (context, i) {
                                final addr = _suggestions[i];
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
                                          child: Icon(Icons.location_on_outlined, color: AppColors.primaryOrange, size: 20),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(addr['name']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E1B4B))),
                                              const SizedBox(height: 2),
                                              Text(addr['detail']!, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
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

            // ─── Bottom Panel ────────────────────────────────────
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
                        'Add Location',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E1B4B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Location icon row
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFF3ED),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on_outlined,
                            color: AppColors.primaryOrange,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // + ADD NEW ADDRESS button
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NewAddressFormScreen(
                              mapAddress: _selectedMapAddress,
                            ),
                          ),
                        );
                      },
                      child: const Center(
                        child: Text(
                          '+ ADD NEW ADDRESS',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryOrange,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationPin extends StatelessWidget {
  const _LocationPin();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: const BoxDecoration(
            color: AppColors.primaryOrange,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.location_on, color: Colors.white, size: 28),
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

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()..color = Colors.white..strokeWidth = 10..style = PaintingStyle.stroke;
    final minor = Paint()..color = Colors.white.withValues(alpha: 0.65)..strokeWidth = 5..style = PaintingStyle.stroke;

    for (int i = 1; i < 8; i++) {
      final y = size.height * i / 8;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), i % 2 == 0 ? road : minor);
    }
    for (int i = 1; i < 6; i++) {
      final x = size.width * i / 6;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), i % 2 == 0 ? road : minor);
    }

    final green = Paint()..color = const Color(0xFFD1E8C7).withValues(alpha: 0.55)..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(size.width * 0.04, size.height * 0.08, size.width * 0.26, size.height * 0.16), green);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.55, size.height * 0.38, size.width * 0.32, size.height * 0.13), green);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.08, size.height * 0.62, size.width * 0.22, size.height * 0.2), green);

    final grey = Paint()..color = const Color(0xFFCDD5E0).withValues(alpha: 0.6)..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(size.width * 0.38, size.height * 0.04, size.width * 0.15, size.height * 0.14), grey);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.62, size.height * 0.58, size.width * 0.22, size.height * 0.18), grey);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.1, size.height * 0.28, size.width * 0.24, size.height * 0.11), grey);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
