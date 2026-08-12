import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'hair_theme.dart';

/// The head position a capture asks the user for.
enum HairCapturePose {
  front(
    label: 'Look straight ahead',
    instruction: 'Hold the phone at eye level and keep your whole head in the oval',
    tiltDegrees: 0,
    turnDegrees: 0,
    hint: 'Fit your head in the oval, then tap capture',
  ),
  top(
    label: 'Tilt your head down',
    instruction:
        'Lower your chin toward your chest so the top of your head faces the camera',
    tiltDegrees: 38,
    turnDegrees: 0,
    hint: 'Chin down — show the crown, then tap capture',
  ),
  left(
    label: 'Turn to your left',
    instruction: 'Turn your head to show the left side and parting',
    tiltDegrees: 0,
    turnDegrees: -70,
    hint: 'Left side in the oval, then tap capture',
  ),
  right(
    label: 'Turn to your right',
    instruction: 'Turn your head to show the right side and parting',
    tiltDegrees: 0,
    turnDegrees: 70,
    hint: 'Right side in the oval, then tap capture',
  );

  const HairCapturePose({
    required this.label,
    required this.instruction,
    required this.tiltDegrees,
    required this.turnDegrees,
    required this.hint,
  });

  final String label;
  final String instruction;

  /// Forward head tilt at the end of the animation.
  final double tiltDegrees;

  /// Horizontal head turn at the end of the animation.
  /// Negative turns to the user's left, positive to the right.
  final double turnDegrees;

  /// Persistent hint shown under the oval guide.
  final String hint;

  bool get needsCoach => tiltDegrees != 0 || turnDegrees != 0;
}

/// Full-screen coach shown before capture: a head silhouette that repeatedly
/// moves into the pose being asked for.
class HairPoseCoach extends StatefulWidget {
  final HairCapturePose pose;
  final VoidCallback onDismiss;

  const HairPoseCoach({
    super.key,
    required this.pose,
    required this.onDismiss,
  });

  @override
  State<HairPoseCoach> createState() => _HairPoseCoachState();
}

class _HairPoseCoachState extends State<HairPoseCoach>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    // Move into the pose, hold it, then return and pause before repeating.
    _progress = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 38,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 26),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 16),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pose = widget.pose;

    return Material(
      color: Colors.black.withValues(alpha: 0.82),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              SizedBox(
                width: 220,
                height: 220,
                child: AnimatedBuilder(
                  animation: _progress,
                  builder: (context, _) => CustomPaint(
                    painter: _PoseHeadPainter(
                      pose: pose,
                      t: _progress.value,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                pose.label,
                textAlign: TextAlign.center,
                style: GoogleFonts.lora(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                pose.instruction,
                textAlign: TextAlign.center,
                style: GoogleFonts.lora(
                  color: Colors.white70,
                  fontSize: 14.5,
                  height: 1.45,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: widget.onDismiss,
                  style: FilledButton.styleFrom(
                    backgroundColor: HairTheme.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    "Got it",
                    style: GoogleFonts.lora(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact inline version of the coach animation, drawn over the preview so the
/// user can keep following it while framing the shot.
class HairPoseHint extends StatefulWidget {
  final HairCapturePose pose;
  final double size;

  const HairPoseHint({super.key, required this.pose, this.size = 84});

  @override
  State<HairPoseHint> createState() => _HairPoseHintState();
}

class _HairPoseHintState extends State<HairPoseHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _progress = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 38,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 26),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 16),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24),
      ),
      padding: const EdgeInsets.all(6),
      child: AnimatedBuilder(
        animation: _progress,
        builder: (context, _) => CustomPaint(
          painter: _PoseHeadPainter(
            pose: widget.pose,
            t: _progress.value,
            compact: true,
          ),
        ),
      ),
    );
  }
}

/// Draws a head in profile that tilts / turns into the requested pose.
class _PoseHeadPainter extends CustomPainter {
  final HairCapturePose pose;
  final double t;
  final bool compact;

  _PoseHeadPainter({
    required this.pose,
    required this.t,
    this.compact = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Head faces the user's right by default; mirror for a left turn so the
    // silhouette always rotates toward the side being photographed.
    final facingLeft = pose.turnDegrees < 0;
    final turn = (pose.turnDegrees.abs() * t) * math.pi / 180;
    final tilt = (pose.tiltDegrees * t) * math.pi / 180;

    final pivot = Offset(w * 0.45, h * 0.84);

    canvas.save();
    if (facingLeft) {
      canvas.translate(w, 0);
      canvas.scale(-1, 1);
    }

    // A horizontal turn is shown by foreshortening the profile toward the
    // camera: full width means facing the lens, narrow means full profile.
    if (turn != 0) {
      final squash = math.cos(turn).abs().clamp(0.35, 1.0);
      canvas.translate(pivot.dx, 0);
      canvas.scale(1 - (1 - squash) * 0.55, 1);
      canvas.translate(-pivot.dx, 0);
    }

    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(tilt);
    canvas.translate(-pivot.dx, -pivot.dy);

    _paintNeck(canvas, w, h);
    _paintHead(canvas, w, h);

    canvas.restore();

    if (!compact) {
      _paintMotionArrow(canvas, w, h, pivot);
    }
  }

  void _paintNeck(Canvas canvas, double w, double h) {
    final neck = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.36, h * 0.58, w * 0.54, h * 0.86),
      Radius.circular(w * 0.05),
    );
    canvas.drawRRect(
      neck,
      Paint()..color = Colors.white.withValues(alpha: 0.16),
    );
    canvas.drawRRect(
      neck,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.012,
    );
  }

  void _paintHead(Canvas canvas, double w, double h) {
    final head = Path()
      ..moveTo(w * 0.20, h * 0.42)
      ..cubicTo(w * 0.17, h * 0.14, w * 0.60, h * 0.08, w * 0.68, h * 0.33)
      ..lineTo(w * 0.70, h * 0.43)
      ..cubicTo(w * 0.79, h * 0.45, w * 0.79, h * 0.50, w * 0.70, h * 0.52)
      ..lineTo(w * 0.68, h * 0.57)
      ..cubicTo(w * 0.67, h * 0.65, w * 0.57, h * 0.70, w * 0.46, h * 0.68)
      ..cubicTo(w * 0.30, h * 0.66, w * 0.20, h * 0.57, w * 0.20, h * 0.42)
      ..close();

    canvas.drawPath(
      head,
      Paint()..color = Colors.white.withValues(alpha: 0.16),
    );
    canvas.drawPath(
      head,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.014
        ..strokeJoin = StrokeJoin.round,
    );

    // Crown / scalp highlight — the region the scan actually looks at.
    canvas.drawArc(
      Rect.fromLTWH(w * 0.17, h * 0.09, w * 0.53, h * 0.48),
      math.pi * 1.02,
      math.pi * 0.86,
      false,
      Paint()
        ..color = HairTheme.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.045
        ..strokeCap = StrokeCap.round,
    );
  }

  /// Curved arrow tracing the direction the head should move.
  void _paintMotionArrow(Canvas canvas, double w, double h, Offset pivot) {
    if (!pose.needsCoach) return;

    final paint = Paint()
      ..color = HairTheme.accent.withValues(alpha: 0.55 + 0.45 * t)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.016
      ..strokeCap = StrokeCap.round;

    if (pose.tiltDegrees != 0) {
      final rect = Rect.fromCircle(center: pivot, radius: h * 0.62);
      canvas.drawArc(rect, -math.pi * 0.62, math.pi * 0.24, false, paint);

      final end = Offset(
        pivot.dx + h * 0.62 * math.cos(-math.pi * 0.38),
        pivot.dy + h * 0.62 * math.sin(-math.pi * 0.38),
      );
      _paintArrowHead(canvas, end, math.pi * 0.20, w, paint);
    } else {
      final dir = pose.turnDegrees < 0 ? -1.0 : 1.0;
      final y = h * 0.90;
      final from = Offset(w * (0.5 - 0.16 * dir), y);
      final to = Offset(w * (0.5 + 0.20 * dir), y);
      canvas.drawLine(from, to, paint);
      _paintArrowHead(canvas, to, dir > 0 ? 0 : math.pi, w, paint);
    }
  }

  void _paintArrowHead(
    Canvas canvas,
    Offset tip,
    double angle,
    double w,
    Paint paint,
  ) {
    const spread = 0.55;
    final len = w * 0.07;
    final a = Offset(
      tip.dx - len * math.cos(angle - spread),
      tip.dy - len * math.sin(angle - spread),
    );
    final b = Offset(
      tip.dx - len * math.cos(angle + spread),
      tip.dy - len * math.sin(angle + spread),
    );
    canvas.drawLine(tip, a, paint);
    canvas.drawLine(tip, b, paint);
  }

  @override
  bool shouldRepaint(covariant _PoseHeadPainter old) =>
      old.t != t || old.pose != pose || old.compact != compact;
}
