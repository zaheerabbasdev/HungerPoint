import 'package:flutter/material.dart';
import '../services/branch_service.dart';

class PickupBranchesScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;

  const PickupBranchesScreen({super.key, this.onBackToHome});

  @override
  State<PickupBranchesScreen> createState() => _PickupBranchesScreenState();
}

class _PickupBranchesScreenState extends State<PickupBranchesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Branch? _highlightedBranch;

  @override
  void initState() {
    super.initState();
    final list = BranchService().allBranches;
    _highlightedBranch = BranchService().selectedBranch ?? (list.length > 1 ? list[1] : list.first);
    BranchService().fetchBranchesFromBackend().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Branch> get _filteredBranches {
    final all = BranchService().allBranches;
    final selected = BranchService().selectedBranch;

    // Show the selected branch on the top of the list
    final list = List<Branch>.from(all);
    if (selected != null) {
      list.removeWhere((b) => b.id == selected.id);
      list.insert(0, selected);
    }

    if (_searchQuery.trim().isEmpty) return list;
    return list.where((b) {
      return b.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          b.address.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _showConfirmBranchDialog(Branch branch) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                const Text(
                  'Confirm Branch Selection',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E1B4B),
                  ),
                ),
                const SizedBox(height: 12),

                // Subtitle
                const Text(
                  'You have selected:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),

                // Yellow card with branch name & address
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7D6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        branch.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E1B4B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        branch.address,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF4B5563),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Confirmation question
                const Text(
                  'Would you like to continue with this branch?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1E1B4B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),

                // Action buttons: CANCEL & PROCEED
                Row(
                  children: [
                    // CANCEL
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => Navigator.pop(dialogCtx),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFD1D5DB), width: 1.5),
                          ),
                          child: const Center(
                            child: Text(
                              'CANCEL',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1E1B4B),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // PROCEED
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          // Select branch and set pickup mode
                          BranchService().selectBranch(branch);
                          Navigator.pop(dialogCtx); // close dialog

                          if (Navigator.canPop(context)) {
                            Navigator.pop(context); // pop back to Home
                          } else if (widget.onBackToHome != null) {
                            widget.onBackToHome!();
                          }
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD600),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD600).withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'PROCEED',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1E1B4B),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final branches = _filteredBranches;
    final selectedBranch = BranchService().selectedBranch;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF1E1B4B), size: 24),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else if (widget.onBackToHome != null) {
                        widget.onBackToHome!();
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Branches',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E1B4B),
                    ),
                  ),
                ],
              ),
            ),

            // ─── MAP VIEW (Overview Map) ──────────────────────────────────
            SizedBox(
              height: 250,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _PickupMapPainter(),
                    ),
                  ),

                  // Pins on map
                  Positioned(
                    top: 55,
                    left: 175,
                    child: GestureDetector(
                      onTap: () {
                        final b = BranchService().branches.firstWhere((x) => x.id == 'b_f7');
                        _showConfirmBranchDialog(b);
                      },
                      child: _buildMapPin(
                        isActive: (_highlightedBranch?.id == 'b_f7') || (selectedBranch?.id == 'b_f7'),
                        size: 36,
                      ),
                    ),
                  ),

                  Positioned(
                    top: 105,
                    left: 140,
                    child: GestureDetector(
                      onTap: () {
                        final b = BranchService().branches.firstWhere((x) => x.id == 'b_f10');
                        _showConfirmBranchDialog(b);
                      },
                      child: _buildMapPin(
                        isActive: (_highlightedBranch?.id == 'b_f10') || (selectedBranch?.id == 'b_f10'),
                        size: 36,
                      ),
                    ),
                  ),

                  Positioned(
                    top: 130,
                    left: 185,
                    child: GestureDetector(
                      onTap: () {
                        final b = BranchService().branches.firstWhere((x) => x.id == 'b_i8');
                        _showConfirmBranchDialog(b);
                      },
                      child: _buildMapPin(
                        isActive: (_highlightedBranch?.id == 'b_i8') || (selectedBranch?.id == 'b_i8'),
                        size: 32,
                      ),
                    ),
                  ),

                  Positioned(
                    top: 90,
                    left: 105,
                    child: GestureDetector(
                      onTap: () {
                        final b = BranchService().branches.firstWhere((x) => x.id == 'b_f11');
                        _showConfirmBranchDialog(b);
                      },
                      child: _buildMapPin(
                        isActive: (_highlightedBranch?.id == 'b_f11') || (selectedBranch?.id == 'b_f11'),
                        size: 32,
                      ),
                    ),
                  ),

                  Positioned(
                    top: 30,
                    left: 30,
                    child: GestureDetector(
                      onTap: () {
                        final b = BranchService().branches.firstWhere((x) => x.id == 'b_swabi');
                        _showConfirmBranchDialog(b);
                      },
                      child: _buildMapPin(
                        isActive: (_highlightedBranch?.id == 'b_swabi') || (selectedBranch?.id == 'b_swabi'),
                        size: 32,
                      ),
                    ),
                  ),

                  // Decorative cluster pins
                  Positioned(
                    top: 70,
                    right: 140,
                    child: _buildMapPin(isActive: false, size: 28),
                  ),
                  Positioned(
                    top: 120,
                    right: 110,
                    child: _buildMapPin(isActive: false, size: 28),
                  ),
                  Positioned(
                    top: 135,
                    right: 130,
                    child: _buildMapPin(isActive: false, size: 28),
                  ),
                  Positioned(
                    bottom: 30,
                    left: 170,
                    child: _buildMapPin(isActive: false, size: 28),
                  ),

                  // TPL Maps Watermark (Bottom Left)
                  Positioned(
                    bottom: 12,
                    left: 16,
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              'TPL',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF2E7D32),
                                height: 0.9,
                              ),
                            ),
                            Text(
                              'maps',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1B5E20),
                                height: 0.9,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '1-2',
                            style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // GPS Crosshair Floating Button (Bottom Right)
                  Positioned(
                    bottom: 12,
                    right: 16,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.my_location,
                        color: Color(0xFF1E1B4B),
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ─── SEARCH BY BRANCH ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: const InputDecoration(
                    hintText: 'Search by Branch',
                    hintStyle: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),

            // ─── "All Branches" HEADER ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  'All Branches',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E1B4B),
                  ),
                ),
              ),
            ),

            // ─── BRANCHES LIST ────────────────────────────────────────
            Expanded(
              child: ListView.separated(
                itemCount: branches.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFF3F4F6),
                ),
                itemBuilder: (context, index) {
                  final branch = branches[index];
                  final isCurrentlySelected = selectedBranch?.id == branch.id ||
                      (selectedBranch == null && index == 0);

                  return InkWell(
                    onTap: () {
                      setState(() => _highlightedBranch = branch);
                      _showConfirmBranchDialog(branch);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isCurrentlySelected ? const Color(0xFFFFD600) : Colors.transparent,
                              shape: BoxShape.circle,
                              border: isCurrentlySelected
                                  ? null
                                  : Border.all(color: const Color(0xFF1E1B4B), width: 1.5),
                            ),
                            child: Icon(
                              Icons.storefront_outlined,
                              color: const Color(0xFF1E1B4B),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  branch.name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1E1B4B),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                const Text(
                                  'Open Now',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B7280),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  branch.distance,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF9CA3AF),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: isCurrentlySelected
                                ? const Color(0xFFFFD600)
                                : const Color(0xFF1E1B4B),
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
    );
  }

  Widget _buildMapPin({required bool isActive, double size = 32}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFFFD600) : const Color(0xFF78716C).withValues(alpha: 0.85),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.storefront_rounded,
          color: isActive ? const Color(0xFF1E1B4B) : Colors.white,
          size: size * 0.55,
        ),
      ),
    );
  }
}

class _PickupMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFF1EFEA);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final greenPaint = Paint()
      ..color = const Color(0xFFD3E7CD)
      ..style = PaintingStyle.fill;

    final greenPath1 = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.65, 0)
      ..quadraticBezierTo(size.width * 0.45, 50, size.width * 0.2, 70)
      ..quadraticBezierTo(size.width * 0.05, 90, 0, 110)
      ..close();
    canvas.drawPath(greenPath1, greenPaint);

    final greenPath2 = Path()
      ..moveTo(size.width * 0.75, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, 100)
      ..quadraticBezierTo(size.width * 0.85, 70, size.width * 0.75, 0)
      ..close();
    canvas.drawPath(greenPath2, greenPaint);

    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    final highwayPaint = Paint()
      ..color = const Color(0xFFFEE7A6)
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke;

    final hw1 = Path()
      ..moveTo(0, size.height * 0.4)
      ..quadraticBezierTo(size.width * 0.4, size.height * 0.35, size.width, size.height * 0.6);
    canvas.drawPath(hw1, highwayPaint);

    final hw2 = Path()
      ..moveTo(size.width * 0.5, 0)
      ..quadraticBezierTo(size.width * 0.45, size.height * 0.5, size.width * 0.48, size.height);
    canvas.drawPath(hw2, highwayPaint);

    canvas.drawLine(Offset(size.width * 0.2, 40), Offset(size.width * 0.7, size.height * 0.85), roadPaint);
    canvas.drawLine(Offset(size.width * 0.35, 30), Offset(size.width * 0.85, size.height * 0.7), roadPaint);
    canvas.drawLine(Offset(size.width * 0.1, size.height * 0.6), Offset(size.width * 0.9, size.height * 0.2), roadPaint);

    _drawText(canvas, 'Islamabad', Offset(size.width * 0.32, 50), 16, FontWeight.bold, const Color(0xFF1E1B4B));
    _drawText(canvas, 'Rawalpindi', Offset(size.width * 0.28, size.height * 0.68), 16, FontWeight.bold, const Color(0xFF1E1B4B));
    _drawText(canvas, 'Kahuta', Offset(size.width * 0.85, size.height * 0.65), 10, FontWeight.w600, const Color(0xFF6B7280));
    _drawText(canvas, 'E 9', Offset(size.width * 0.38, 30), 9, FontWeight.w600, const Color(0xFF6B7280));
    _drawText(canvas, 'Blue Area', Offset(size.width * 0.65, 35), 9, FontWeight.w600, const Color(0xFF6B7280));
    _drawText(canvas, 'F 10', Offset(size.width * 0.36, 95), 9, FontWeight.w600, const Color(0xFF6B7280));
    _drawText(canvas, 'E 11', Offset(size.width * 0.29, 82), 9, FontWeight.w600, const Color(0xFF6B7280));
    _drawText(canvas, 'Tarnol', Offset(size.width * 0.05, 120), 9, FontWeight.w600, const Color(0xFF6B7280));
  }

  void _drawText(Canvas canvas, String text, Offset offset, double fontSize, FontWeight weight, Color color) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: weight,
        letterSpacing: 0.2,
      ),
    );
    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
