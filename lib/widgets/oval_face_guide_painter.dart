import 'package:flutter/material.dart';
import 'dart:math' as math;

/// CustomPainter that renders a semi-transparent dark overlay with an
/// elliptical cutout for the face guide, plus an optional countdown
/// progress arc around the oval border.
class OvalFaceGuidePainter extends CustomPainter {
  final Rect ovalRect;
  final Color borderColor;
  final double borderWidth;
  final double overlayOpacity;

  /// 0.0–1.0 progress for the auto-capture countdown arc.
  /// When null, no progress arc is drawn.
  final double? countdownProgress;

  OvalFaceGuidePainter({
    required this.ovalRect,
    this.borderColor = Colors.white,
    this.borderWidth = 2.5,
    this.overlayOpacity = 0.55,
    this.countdownProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Dark overlay with oval cutout (even-odd fill)
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(ovalRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      overlayPath,
      Paint()..color = Colors.black.withValues(alpha: overlayOpacity),
    );

    // Oval border
    canvas.drawOval(
      ovalRect,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth,
    );

    // Countdown progress arc
    if (countdownProgress != null && countdownProgress! > 0) {
      final progressPaint = Paint()
        ..color = Colors.green.shade400
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth + 1.5
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        ovalRect,
        -math.pi / 2, // start from top
        countdownProgress! * 2 * math.pi,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant OvalFaceGuidePainter oldDelegate) {
    return ovalRect != oldDelegate.ovalRect ||
        borderColor != oldDelegate.borderColor ||
        borderWidth != oldDelegate.borderWidth ||
        overlayOpacity != oldDelegate.overlayOpacity ||
        countdownProgress != oldDelegate.countdownProgress;
  }
}
