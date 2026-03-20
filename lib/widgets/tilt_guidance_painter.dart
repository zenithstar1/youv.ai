import 'package:flutter/material.dart';
import 'dart:math' as math;

/// TiltGuidancePainter is a CustomPainter that displays a semi-circular tilt guidance UI
/// 
/// It shows:
/// - A semi-circular track (arc) for visual reference
/// - A green target zone between 40-50 degrees
/// - A white pointer that moves based on current pitch
/// - The pointer turns green and glows when pitch is in the perfect angle range
class TiltGuidancePainter extends CustomPainter {
  /// Current pitch angle (0-90 degrees)
  final double currentPitch;

  /// Whether the current angle is in the perfect range (40-50 degrees)
  final bool isPerfectAngle;

  /// Minimum pitch angle for target zone (default: 40)
  final double minTargetPitch;

  /// Maximum pitch angle for target zone (default: 50)
  final double maxTargetPitch;

  /// Radius of the semi-circular track (default: 80)
  final double trackRadius;

  /// Width of the track line (default: 4)
  final double trackWidth;

  /// Cached layout objects to avoid rebuilding text on every frame
  late final TextPainter _label0;
  late final TextPainter _label45;
  late final TextPainter _label90;

  TiltGuidancePainter({
    required this.currentPitch,
    required this.isPerfectAngle,
    this.minTargetPitch = 40.0,
    this.maxTargetPitch = 50.0,
    this.trackRadius = 80.0,
    this.trackWidth = 4.0,
  }) {
    // Pre-layout text labels to avoid rebuilding them on every paint
    _label0 = _createLabel('0°');
    _label45 = _createLabel('45°');
    _label90 = _createLabel('90°');
  }

  /// Creates and layouts a text label once
  TextPainter _createLabel(String text) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    painter.layout();
    return painter;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Draw background circle
    _drawBackgroundCircle(canvas, center);

    // Draw the semi-circular track
    _drawSemiCircularTrack(canvas, center);

    // Draw the target zone (green arc between 40-50 degrees)
    _drawTargetZone(canvas, center);

    // Draw angle degree labels around the arc
    _drawAngleLabels(canvas, center);

    // Draw the current tilt pointer
    _drawTiltPointer(canvas, center);

    // Draw center guide lines
    _drawCenterGuides(canvas, center);
  }

  /// Draws a semi-transparent background circle
  void _drawBackgroundCircle(Canvas canvas, Offset center) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, trackRadius + 40, paint);
  }

  /// Draws the main semi-circular track
  void _drawSemiCircularTrack(Canvas canvas, Offset center) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = trackWidth;

    const startAngle = math.pi; // 180 degrees (left side)
    const sweepAngle = math.pi; // 180 degrees (half circle)

    final rect = Rect.fromCircle(center: center, radius: trackRadius);
    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  /// Draws the green target zone (40-50 degrees) on the arc
  void _drawTargetZone(Canvas canvas, Offset center) {
    final paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = trackWidth + 2
      ..strokeCap = StrokeCap.round;

    // Convert degrees to radians
    // 0 degrees is at the bottom, 90 is at the left
    // Arc starts at 180 (left) and goes to 0 (right)
    
    // Target zone: 40-50 degrees
    final minRadians = _degreesToRadians(minTargetPitch);
    final maxRadians = _degreesToRadians(maxTargetPitch);
    
    // The arc is drawn from top-left (180°) going down
    // So we need to convert: 0° (pointing up) -> start of arc
    // 90° (pointing down) -> middle of arc
    final startRadian = math.pi - maxRadians; // Start of target zone
    final sweepRadian = maxRadians - minRadians; // Width of target zone

    final rect = Rect.fromCircle(center: center, radius: trackRadius);
    canvas.drawArc(rect, startRadian, sweepRadian, false, paint);
  }

  /// Draws degree labels at key points on the arc (uses pre-laid out labels)
  void _drawAngleLabels(Canvas canvas, Offset center) {
    final labels = [_label0, _label45, _label90];
    final angles = [0, 45, 90];

    for (int i = 0; i < angles.length; i++) {
      final angle = angles[i];
      final label = labels[i];
      final radians = _degreesToRadians(angle.toDouble());
      
      // Position the label outside the arc
      final labelRadius = trackRadius + 35;
      final x = center.dx + labelRadius * math.sin(radians);
      final y = center.dy - labelRadius * math.cos(radians);

      label.paint(
        canvas,
        Offset(x - label.width / 2, y - label.height / 2),
      );
    }
  }

  /// Draws the tilt pointer that moves along the arc
  void _drawTiltPointer(Canvas canvas, Offset center) {
    final radians = _degreesToRadians(currentPitch);

    // Calculate pointer position on the arc
    final pointerX = center.dx + trackRadius * math.sin(radians);
    final pointerY = center.dy - trackRadius * math.cos(radians);
    final pointerPosition = Offset(pointerX, pointerY);

    // Draw glow effect when in perfect angle
    if (isPerfectAngle) {
      _drawGlowEffect(canvas, pointerPosition);
    }

    // Draw the pointer circle
    final pointerColor = isPerfectAngle ? Colors.green : Colors.white;
    final pointerPaint = Paint()
      ..color = pointerColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(pointerPosition, 12, pointerPaint);

    // Draw pointer border
    final borderPaint = Paint()
      ..color = pointerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(pointerPosition, 12, borderPaint);

    // Draw line from center to pointer
    final linePaint = Paint()
      ..color = pointerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, pointerPosition, linePaint);
  }

  /// Draws a glow effect around the pointer when in perfect angle
  void _drawGlowEffect(Canvas canvas, Offset position) {
    final glowPaint = Paint()
      ..color = Colors.green.withOpacity(0.3)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8);

    canvas.drawCircle(position, 16, glowPaint);

    // Additional glow layers for better effect
    final innerGlowPaint = Paint()
      ..color = Colors.green.withOpacity(0.2)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 12);

    canvas.drawCircle(position, 18, innerGlowPaint);
  }

  /// Draws center guide lines (vertical and horizontal)
  void _drawCenterGuides(Canvas canvas, Offset center) {
    final guidePaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const guideLength = 20.0;

    // Vertical guide line (pointing up/down)
    canvas.drawLine(
      Offset(center.dx, center.dy - guideLength),
      Offset(center.dx, center.dy + guideLength),
      guidePaint,
    );

    // Horizontal guide line (pointing left/right)
    canvas.drawLine(
      Offset(center.dx - guideLength, center.dy),
      Offset(center.dx + guideLength, center.dy),
      guidePaint,
    );
  }

  /// Converts degrees to radians
  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  @override
  bool shouldRepaint(TiltGuidancePainter oldDelegate) {
    // Only repaint if values actually changed (not object equality)
    // This prevents unnecessary repaints when the same values are passed
    return (oldDelegate.currentPitch - currentPitch).abs() > 0.5 || // Only repaint if pitch changed by >0.5°
        oldDelegate.isPerfectAngle != isPerfectAngle;
  }

  @override
  bool shouldRebuildSemantics(TiltGuidancePainter oldDelegate) {
    return false; // No semantic changes needed
  }
}

/// TiltGuidanceWidget wraps the CustomPainter in a convenient widget
/// Optimized to work with RepaintBoundary for performance
class TiltGuidanceWidget extends StatelessWidget {
  final double currentPitch;
  final bool isPerfectAngle;
  final double minTargetPitch;
  final double maxTargetPitch;
  final double height;
  final double width;

  const TiltGuidanceWidget({
    super.key,
    required this.currentPitch,
    required this.isPerfectAngle,
    this.minTargetPitch = 40.0,
    this.maxTargetPitch = 50.0,
    this.height = 250,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: TiltGuidancePainter(
          currentPitch: currentPitch,
          isPerfectAngle: isPerfectAngle,
          minTargetPitch: minTargetPitch,
          maxTargetPitch: maxTargetPitch,
        ),
        size: Size(width, height),
      ),
    );
  }
}
