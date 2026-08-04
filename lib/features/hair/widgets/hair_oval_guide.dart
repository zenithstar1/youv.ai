import 'package:flutter/material.dart';
import 'hair_theme.dart';

/// Dimmed overlay with oval head guide.
class HairOvalGuide extends StatelessWidget {
  final String hint;
  final Widget? child;

  const HairOvalGuide({
    super.key,
    this.hint = 'Fit your head in the frame',
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (child != null) child!,
        CustomPaint(painter: _OvalGuidePainter()),
        Positioned(
          left: 24,
          right: 24,
          bottom: 28,
          child: Text(
            hint,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
            ),
          ),
        ),
      ],
    );
  }
}

class _OvalGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Paint()..color = Colors.black.withValues(alpha: 0.45);
    final hole = Path()
      ..addOval(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height * 0.42),
          width: size.width * 0.62,
          height: size.height * 0.52,
        ),
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
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.42),
        width: size.width * 0.62,
        height: size.height * 0.52,
      ),
      border,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
