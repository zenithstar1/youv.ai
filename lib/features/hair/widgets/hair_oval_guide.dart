import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'hair_theme.dart';

/// Dimmed overlay with oval head guide.
class HairOvalGuide extends StatelessWidget {
  final String hint;
  final Widget? child;

  /// Distance from the bottom of the overlay as a fraction of height.
  /// Kept above camera controls when needed.
  final double hintBottomFraction;

  /// Oval geometry as fractions of the overlay size. Poses that show the crown
  /// need a rounder guide sitting higher in the frame than a front portrait.
  final double ovalCenterFraction;
  final double ovalWidthFraction;
  final double ovalHeightFraction;

  const HairOvalGuide({
    super.key,
    this.hint = 'Fit your head in the frame',
    this.child,
    this.hintBottomFraction = 0.18,
    this.ovalCenterFraction = 0.42,
    this.ovalWidthFraction = 0.68,
    this.ovalHeightFraction = 0.48,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        return Stack(
          fit: StackFit.expand,
          children: [
            if (child != null) child!,
            CustomPaint(
              painter: _OvalGuidePainter(
                centerFraction: ovalCenterFraction,
                widthFraction: ovalWidthFraction,
                heightFraction: ovalHeightFraction,
              ),
            ),
            Positioned(
              left: 28,
              right: 28,
              bottom: h * hintBottomFraction,
              child: Text(
                hint,
                textAlign: TextAlign.center,
                style: GoogleFonts.lora(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  shadows: const [
                    Shadow(blurRadius: 8, color: Colors.black54),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OvalGuidePainter extends CustomPainter {
  final double centerFraction;
  final double widthFraction;
  final double heightFraction;

  _OvalGuidePainter({
    required this.centerFraction,
    required this.widthFraction,
    required this.heightFraction,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * centerFraction);
    final ovalW = size.width * widthFraction;
    final ovalH = size.height * heightFraction;

    final overlay = Paint()..color = Colors.black.withValues(alpha: 0.45);
    final hole = Path()
      ..addOval(
        Rect.fromCenter(center: center, width: ovalW, height: ovalH),
      );
    final full = Path()..addRect(Offset.zero & size);
    canvas.drawPath(
      Path.combine(PathOperation.difference, full, hole),
      overlay,
    );

    final border = Paint()
      ..color = HairTheme.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawOval(
      Rect.fromCenter(center: center, width: ovalW, height: ovalH),
      border,
    );
  }

  @override
  bool shouldRepaint(covariant _OvalGuidePainter old) =>
      old.centerFraction != centerFraction ||
      old.widthFraction != widthFraction ||
      old.heightFraction != heightFraction;
}
