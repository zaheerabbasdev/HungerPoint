import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/branch_service.dart';

class BranchesScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;
  final bool isSelectionMode;

  const BranchesScreen({
    super.key,
    this.onBackToHome,
    this.isSelectionMode = false,
  });

  @override
  State<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends State<BranchesScreen> {
  Branch? _currentNearestBranch;

  @override
  void initState() {
    super.initState();
    // Default to F-7 Old Islamabad (Image 1)
    _currentNearestBranch = BranchService().branches.firstWhere(
      (b) => b.id == 'b_f7_old',
      orElse: () => BranchService().branches[0],
    );
  }

  /// Launch Google Maps directly for the given branch
  Future<void> _launchGoogleMaps(Branch branch) async {
    final query = Uri.encodeComponent('${branch.name}, ${branch.address}');
    // Google Maps directions URI (navigates from current location to branch)
    final dirUrl = 'https://www.google.com/maps/dir/?api=1&destination=${branch.lat},${branch.lng}&destination_place_id=$query';
    final googleMapsDirUri = Uri.parse(dirUrl);
    // Google Maps search URI
    final googleMapsSearchUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${branch.lat},${branch.lng}+$query');
    // Android Geo Intent URI
    final geoUri = Uri.parse('geo:${branch.lat},${branch.lng}?q=${branch.lat},${branch.lng}(${Uri.encodeComponent(branch.name)})');

    try {
      // 1. Try launching native geo intent
      final launchedGeo = await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      if (launchedGeo) return;
    } catch (_) {}

    try {
      // 2. Try launching Google Maps app with directions
      final launchedDir = await launchUrl(googleMapsDirUri, mode: LaunchMode.externalApplication);
      if (launchedDir) return;
    } catch (_) {}

    try {
      // 3. Try launching Google Maps search in external application
      final launchedSearch = await launchUrl(googleMapsSearchUri, mode: LaunchMode.externalApplication);
      if (launchedSearch) return;
    } catch (_) {}

    try {
      // 4. Fallback to platform default browser
      await launchUrl(googleMapsDirUri, mode: LaunchMode.platformDefault);
    } catch (e) {
      debugPrint('Could not launch maps: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open map: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Opens the "Show All Branches" bottom sheet (Image 2)
  void _showAllBranchesBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final branches = BranchService().branches;

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                // Orange drag handle (Image 2)
                Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5722),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                const SizedBox(height: 16),

                // Branches list
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: branches.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFF3F4F6),
                    ),
                    itemBuilder: (context, index) {
                      final branch = branches[index];
                      return InkWell(
                        onTap: () {
                          Navigator.pop(sheetCtx); // close "Show all" sheet
                          setState(() {
                            _currentNearestBranch = branch;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 4.0),
                          child: Row(
                            children: [
                              // Storefront outline icon in circle
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
                                ),
                                child: const Icon(
                                  Icons.storefront_outlined,
                                  color: Color(0xFF1E1B4B),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Branch Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      branch.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1E1B4B),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      branch.statusText,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: branch.isOpen
                                            ? const Color(0xFF6B7280)
                                            : const Color(0xFF9CA3AF),
                                        fontWeight: FontWeight.w500,
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

                              // Orange Chevron Arrow (Image 2)
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Color(0xFFFF5722),
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
      },
    );
  }

  /// Opens the Branch Details bottom sheet (Image 3)
  void _showBranchDetailsBottomSheet(Branch branch) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  // Orange drag handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5722),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Branch Name
                  Text(
                    branch.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E1B4B),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Distance & GET DIRECTIONS > Row (Image 3)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        branch.distance,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _launchGoogleMaps(branch),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
                          child: Row(
                            children: const [
                              Text(
                                'GET DIRECTIONS',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFFF5722),
                                  letterSpacing: 0.3,
                                ),
                              ),
                              SizedBox(width: 3),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 13,
                                color: Color(0xFFFF5722),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFF3F4F6)),
                  const SizedBox(height: 16),

                  // Service Available Title
                  const Text(
                    'Service Available',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E1B4B),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Service Badges (DINE IN, DELIVERY, PICK-UP)
                  Row(
                    children: branch.services.map((service) {
                      final isPickup = service == 'PICK-UP';
                      return GestureDetector(
                        onTap: () {
                          if (isPickup) {
                            BranchService().selectBranch(branch);
                            Navigator.pop(sheetCtx);
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            } else if (widget.onBackToHome != null) {
                              widget.onBackToHome!();
                            }
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD600),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            service,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E1B4B),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Operating Hours
                  ...branch.openingHours.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            entry.value,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
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
    final nearestBranch = _currentNearestBranch ?? BranchService().branches[0];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar: ← Branches (Image 1)
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

            // ─── MAP SECTION (F-7 Markaz Street Level Map Matching Image 1) ───
            Expanded(
              child: Stack(
                children: [
                  // Vector street map canvas
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _F7MarkazStreetPainter(),
                    ),
                  ),

                  // Center Pin: Overlapping Storefront Icons (Image 1)
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Secondary offset pin behind
                        Positioned(
                          top: -6,
                          right: -6,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFF6B7280).withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.storefront_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                        // Foreground pin
                        GestureDetector(
                          onTap: () => _showBranchDetailsBottomSheet(nearestBranch),
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4B5563),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.storefront_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // GPS Crosshair button (Bottom right)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
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

            // ─── NEAREST BRANCH SECTION (Matching Image 1) ─────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row: Nearest Branch & SHOW ALL BRANCHES >
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Nearest Branch',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E1B4B),
                        ),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _showAllBranchesBottomSheet,
                        child: Row(
                          children: const [
                            Text(
                              'SHOW ALL BRANCHES',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFFF5722),
                                letterSpacing: 0.4,
                              ),
                            ),
                            SizedBox(width: 3),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 13,
                              color: Color(0xFFFF5722),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Nearest Branch Card (Image 1)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _showBranchDetailsBottomSheet(nearestBranch),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Yellow circular icon with storefront inside
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: nearestBranch.isOpen
                                  ? const Color(0xFFFFD600)
                                  : const Color(0xFFE5E7EB),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.storefront_rounded,
                              color: Color(0xFF1E1B4B),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Branch Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nearestBranch.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1E1B4B),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  nearestBranch.statusText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: nearestBranch.isOpen
                                        ? const Color(0xFF6B7280)
                                        : const Color(0xFF9CA3AF),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  nearestBranch.distance,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF9CA3AF),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Trailing Chevron
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Color(0xFF1E1B4B),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for the detailed F-7 Markaz street-level map matching Image 1
class _F7MarkazStreetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Map base background
    final bgPaint = Paint()..color = const Color(0xFFEBEAE5);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. City block polygons / buildings
    final blockPaint = Paint()..color = const Color(0xFFDFDED8);
    for (double y = 20; y < size.height; y += 45) {
      for (double x = 10; x < size.width; x += 55) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x, y, 42, 32), const Radius.circular(4)),
          blockPaint,
        );
      }
    }

    // 3. Roads / Streets (Diagonal and horizontal lines matching F-7 sector grid)
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;

    final roadMinorPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke;

    // Major Streets
    canvas.drawLine(Offset(0, size.height * 0.15), Offset(size.width, size.height * 0.85), roadPaint);
    canvas.drawLine(Offset(size.width * 0.25, 0), Offset(size.width, size.height * 0.7), roadPaint);
    canvas.drawLine(Offset(0, size.height * 0.5), Offset(size.width * 0.85, size.height), roadPaint);
    canvas.drawLine(Offset(0, size.height * 0.8), Offset(size.width, size.height * 0.25), roadMinorPaint);
    canvas.drawLine(Offset(size.width * 0.1, 0), Offset(size.width * 0.9, size.height), roadMinorPaint);
    canvas.drawLine(Offset(0, size.height * 0.35), Offset(size.width, size.height * 0.5), roadMinorPaint);

    // 4. POI Map Icons and Labels (Matching Image 1)
    _drawPoi(canvas, 'Berlin Nights', Offset(size.width * 0.12, 50), const Color(0xFFEA580C), Icons.restaurant);
    _drawPoi(canvas, 'Ox & Grill\nSteakhouse', Offset(size.width * 0.28, size.height * 0.27), const Color(0xFFEA580C), Icons.restaurant);
    _drawPoi(canvas, 'Mantra Safa\nGold Mall', Offset(size.width * 0.55, size.height * 0.26), const Color(0xFF2563EB), Icons.shopping_bag);
    _drawPoi(canvas, 'Executive\nGuest House', Offset(size.width * 0.68, size.height * 0.33), const Color(0xFF7C3AED), Icons.hotel);
    _drawPoi(canvas, 'English Tea\nHouse', Offset(size.width * 0.05, size.height * 0.30), const Color(0xFF7C3AED), Icons.hotel);
    _drawPoi(canvas, 'Marble Stone\nIce Creamery', Offset(size.width * 0.22, size.height * 0.40), const Color(0xFF4B5563), Icons.build);
    _drawPoi(canvas, 'Melberry Guest\nHouse', Offset(size.width * 0.65, size.height * 0.52), const Color(0xFF7C3AED), Icons.hotel);
    _drawPoi(canvas, 'Sarfaraz Nawaz\nCricket Academy', Offset(size.width * 0.22, size.height * 0.55), const Color(0xFF7C3AED), Icons.sports_cricket);
    _drawPoi(canvas, 'Kabul\nRestaurant', Offset(size.width * 0.60, 60), const Color(0xFFEA580C), Icons.restaurant);
    _drawPoi(canvas, 'Saeed Book Bank', Offset(size.width * 0.82, 45), const Color(0xFF2563EB), Icons.shopping_bag);

    // 5. Street Name Labels (Image 1)
    _drawStreetLabel(canvas, 'F 7 MARKAZ', Offset(size.width * 0.65, 95));
    _drawStreetLabel(canvas, 'Bhitai Road', Offset(size.width * 0.72, size.height * 0.27));
    _drawStreetLabel(canvas, 'Street 41', Offset(size.width * 0.50, size.height * 0.40));
    _drawStreetLabel(canvas, 'Street 40', Offset(size.width * 0.54, size.height * 0.45));
    _drawStreetLabel(canvas, 'Street 46', Offset(size.width * 0.86, size.height * 0.36));
    _drawStreetLabel(canvas, 'Street 45', Offset(size.width * 0.88, size.height * 0.41));
    _drawStreetLabel(canvas, 'Street 21', Offset(size.width * 0.08, size.height * 0.22));
  }

  void _drawPoi(Canvas canvas, String title, Offset offset, Color iconColor, IconData icon) {
    // Circle container
    final circlePaint = Paint()..color = iconColor;
    canvas.drawCircle(Offset(offset.dx + 10, offset.dy + 10), 10, circlePaint);

    // Icon
    final iconSpan = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: 11,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: Colors.white,
      ),
    );
    final iconPainter = TextPainter(text: iconSpan, textDirection: TextDirection.ltr)..layout();
    iconPainter.paint(canvas, Offset(offset.dx + 4.5, offset.dy + 4.5));

    // Label Text
    final textSpan = TextSpan(
      text: title,
      style: TextStyle(
        color: iconColor,
        fontSize: 9,
        fontWeight: FontWeight.w700,
        height: 1.05,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 80);
    textPainter.paint(canvas, Offset(offset.dx - 24, offset.dy + 23));
  }

  void _drawStreetLabel(Canvas canvas, String name, Offset offset) {
    final textSpan = TextSpan(
      text: name,
      style: const TextStyle(
        color: Color(0xFF6B7280),
        fontSize: 9.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
