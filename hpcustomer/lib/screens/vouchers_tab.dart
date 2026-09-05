import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class VouchersScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;

  const VouchersScreen({super.key, this.onBackToHome});

  @override
  State<VouchersScreen> createState() => _VouchersScreenState();
}

class _VouchersScreenState extends State<VouchersScreen> {
  final TextEditingController _voucherController = TextEditingController();

  void _applyVoucher() {
    final code = _voucherController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a voucher code'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Voucher code "$code" is invalid or expired'),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _voucherController.dispose();
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E1B4B), size: 22),
          onPressed: () {
            if (widget.onBackToHome != null) {
              widget.onBackToHome!();
            } else if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        titleSpacing: 0,
        title: const Text(
          'Voucher Codes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E1B4B),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section title
            const Text(
              'Enter Voucher Code',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E1B4B),
              ),
            ),
            const SizedBox(height: 14),

            // Voucher input box with "+ APPLY"
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
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _voucherController,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E1B4B),
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Enter your voucher code',
                        hintStyle: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _applyVoucher,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Text(
                        '+ APPLY',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E1B4B),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Empty state card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Stylized food illustration
                  const SizedBox(
                    width: 140,
                    height: 120,
                    child: CustomPaint(
                      painter: _FoodIllustrationPainter(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Brand Name
                  const Text(
                    'HungerPoint',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF3F1D0B),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // "No Vouchers Found"
                  const Text(
                    'No Vouchers Found',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E1B4B),
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

/// Custom painter that creates the illustrated pizza slice, burger, and drink
/// matching the exact layout in the reference screenshot.
class _FoodIllustrationPainter extends CustomPainter {
  const _FoodIllustrationPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = const Color(0xFF3F1D0B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final yellowFill = Paint()
      ..color = const Color(0xFFFFB800)
      ..style = PaintingStyle.fill;

    final darkYellowFill = Paint()
      ..color = const Color(0xFFE89A00)
      ..style = PaintingStyle.fill;

    final crustFill = Paint()
      ..color = const Color(0xFFD35400)
      ..style = PaintingStyle.fill;

    final lettuceFill = Paint()
      ..color = const Color(0xFF27AE60)
      ..style = PaintingStyle.fill;

    final pattyFill = Paint()
      ..color = const Color(0xFF5D2D0C)
      ..style = PaintingStyle.fill;

    // ─── 1. Pizza Slice (Top-Left) ──────────────────────────────────
    final pizzaPath = Path()
      ..moveTo(size.width * 0.18, size.height * 0.46)
      ..quadraticBezierTo(size.width * 0.22, size.height * 0.16, size.width * 0.52, size.height * 0.14)
      ..quadraticBezierTo(size.width * 0.56, size.height * 0.22, size.width * 0.50, size.height * 0.28)
      ..quadraticBezierTo(size.width * 0.35, size.height * 0.32, size.width * 0.18, size.height * 0.46)
      ..close();

    canvas.drawPath(pizzaPath, crustFill);
    canvas.drawPath(pizzaPath, strokePaint);

    // Pizza cheese layer
    final cheesePath = Path()
      ..moveTo(size.width * 0.24, size.height * 0.42)
      ..quadraticBezierTo(size.width * 0.27, size.height * 0.20, size.width * 0.48, size.height * 0.18)
      ..quadraticBezierTo(size.width * 0.46, size.height * 0.26, size.width * 0.36, size.height * 0.30)
      ..close();
    canvas.drawPath(cheesePath, yellowFill);
    canvas.drawPath(cheesePath, strokePaint);

    // Pepperoni spots
    final pPaint = Paint()..color = const Color(0xFF962D00);
    canvas.drawCircle(Offset(size.width * 0.32, size.height * 0.26), 4.5, pPaint);
    canvas.drawCircle(Offset(size.width * 0.32, size.height * 0.26), 4.5, strokePaint);
    canvas.drawCircle(Offset(size.width * 0.40, size.height * 0.22), 4, pPaint);
    canvas.drawCircle(Offset(size.width * 0.40, size.height * 0.22), 4, strokePaint);

    // ─── 2. Beverage Cup with Straw (Right) ─────────────────────────
    // Straw
    final strawPath = Path()
      ..moveTo(size.width * 0.68, size.height * 0.28)
      ..lineTo(size.width * 0.72, size.height * 0.12);
    canvas.drawPath(strawPath, strokePaint);

    // Cup Lid
    final lidRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.68, size.height * 0.30),
        width: size.width * 0.22,
        height: 6,
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(lidRect, darkYellowFill);
    canvas.drawRRect(lidRect, strokePaint);

    // Cup Body (Tapered trapezoid)
    final cupPath = Path()
      ..moveTo(size.width * 0.59, size.height * 0.33)
      ..lineTo(size.width * 0.62, size.height * 0.76)
      ..quadraticBezierTo(size.width * 0.68, size.height * 0.78, size.width * 0.74, size.height * 0.76)
      ..lineTo(size.width * 0.77, size.height * 0.33)
      ..close();

    canvas.drawPath(cupPath, yellowFill);
    canvas.drawPath(cupPath, strokePaint);

    // Cup decorative lines
    final cupLine1 = Path()
      ..moveTo(size.width * 0.62, size.height * 0.46)
      ..quadraticBezierTo(size.width * 0.68, size.height * 0.49, size.width * 0.74, size.height * 0.47);
    canvas.drawPath(cupLine1, strokePaint);

    final cupLine2 = Path()
      ..moveTo(size.width * 0.63, size.height * 0.60)
      ..quadraticBezierTo(size.width * 0.68, size.height * 0.63, size.width * 0.73, size.height * 0.61);
    canvas.drawPath(cupLine2, strokePaint);

    // ─── 3. Burger / Sandwich (Center & Bottom Left) ───────────────
    // Top Bun (Golden rounded dome)
    final topBunPath = Path()
      ..moveTo(size.width * 0.22, size.height * 0.60)
      ..quadraticBezierTo(size.width * 0.35, size.height * 0.36, size.width * 0.54, size.height * 0.50)
      ..quadraticBezierTo(size.width * 0.40, size.height * 0.62, size.width * 0.22, size.height * 0.60)
      ..close();

    canvas.drawPath(topBunPath, yellowFill);
    canvas.drawPath(topBunPath, strokePaint);

    // Sesame seeds on bun
    final seedPaint = Paint()..color = const Color(0xFF3F1D0B);
    canvas.drawCircle(Offset(size.width * 0.34, size.height * 0.48), 1.8, seedPaint);
    canvas.drawCircle(Offset(size.width * 0.42, size.height * 0.46), 1.8, seedPaint);
    canvas.drawCircle(Offset(size.width * 0.40, size.height * 0.52), 1.8, seedPaint);

    // Green Lettuce
    final lettucePath = Path()
      ..moveTo(size.width * 0.24, size.height * 0.62)
      ..lineTo(size.width * 0.55, size.height * 0.54)
      ..lineTo(size.width * 0.54, size.height * 0.60)
      ..lineTo(size.width * 0.24, size.height * 0.67)
      ..close();
    canvas.drawPath(lettucePath, lettuceFill);
    canvas.drawPath(lettucePath, strokePaint);

    // Beef Patty
    final pattyPath = Path()
      ..moveTo(size.width * 0.25, size.height * 0.66)
      ..lineTo(size.width * 0.55, size.height * 0.59)
      ..lineTo(size.width * 0.54, size.height * 0.66)
      ..lineTo(size.width * 0.26, size.height * 0.72)
      ..close();
    canvas.drawPath(pattyPath, pattyFill);
    canvas.drawPath(pattyPath, strokePaint);

    // Bottom Bun
    final bottomBunPath = Path()
      ..moveTo(size.width * 0.27, size.height * 0.72)
      ..lineTo(size.width * 0.54, size.height * 0.66)
      ..quadraticBezierTo(size.width * 0.42, size.height * 0.80, size.width * 0.27, size.height * 0.72)
      ..close();
    canvas.drawPath(bottomBunPath, yellowFill);
    canvas.drawPath(bottomBunPath, strokePaint);

    // ─── 4. Curved Bottom Swoosh (Surrounding the food) ────────────
    final swooshPath = Path()
      ..moveTo(size.width * 0.18, size.height * 0.62)
      ..quadraticBezierTo(size.width * 0.20, size.height * 0.86, size.width * 0.50, size.height * 0.90)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.86, size.width * 0.80, size.height * 0.68);

    final swooshPaint = Paint()
      ..color = const Color(0xFF3F1D0B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(swooshPath, swooshPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
