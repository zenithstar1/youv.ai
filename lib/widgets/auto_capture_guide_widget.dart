import 'package:flutter/material.dart';
import 'dart:math' as math;

/// AutoCaptureGuideWidget provides a professional, minimalistic face positioning guide
/// 
/// Features:
/// - White circular face guide frame
/// - Real-time angle feedback (pitch & yaw)
/// - Auto-capture countdown timer
/// - Smooth animations
/// - Professional minimalistic design
class AutoCaptureGuideWidget extends StatefulWidget {
  /// Current pitch angle (0-90 degrees)
  final double currentPitch;

  /// Current yaw angle (-45 to 45 degrees)
  final double currentYaw;

  /// Whether the current angle is in the perfect range
  final bool isPerfectAngle;

  /// Whether auto-capture timer is counting down
  final bool isCountingDown;

  /// Remaining time in milliseconds for auto-capture
  final int remainingTime;

  /// Minimum pitch for target zone (default: 42)
  final double minTargetPitch;

  /// Maximum pitch for target zone (default: 48)
  final double maxTargetPitch;

  /// Maximum allowed yaw deviation (default: 5)
  final double maxYawDeviation;

  /// Dynamic guidance text from capture controller.
  final String? guidanceText;

  /// Hair mode enables fill-based helper display.
  final bool isHairMode;

  /// Normalized face fill ratio [0..1].
  final double faceFillRatio;

  /// Capture timer duration in milliseconds.
  final int captureTimerMs;

  /// Size of the main guide circle (default: 280)
  final double guideSize;

  const AutoCaptureGuideWidget({
    super.key,
    required this.currentPitch,
    required this.currentYaw,
    required this.isPerfectAngle,
    this.isCountingDown = false,
    this.remainingTime = 0,
    this.minTargetPitch = 42.0,
    this.maxTargetPitch = 48.0,
    this.maxYawDeviation = 5.0,
    this.guidanceText,
    this.isHairMode = false,
    this.faceFillRatio = 0.0,
    this.captureTimerMs = 600,
    this.guideSize = 280,
  });

  @override
  State<AutoCaptureGuideWidget> createState() => _AutoCaptureGuideWidgetState();
}

class _AutoCaptureGuideWidgetState extends State<AutoCaptureGuideWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          // Main face guide circle
          _buildMainGuideCircle(),
          const SizedBox(height: 32),
          // Status text
          _buildStatusText(),
          const SizedBox(height: 16),
          // Countdown timer (if active)
          if (widget.isCountingDown) _buildCountdownTimer(),
          // Angle indicators (if NOT counting down)
          if (!widget.isCountingDown) _buildAngleIndicators(),
        ],
      ),
    );
  }

  /// Builds the main circular face guide
  Widget _buildMainGuideCircle() {
    // Calculate color based on angle status
    final isYawOk = widget.currentYaw.abs() <= widget.maxYawDeviation;
    final isPitchOk = widget.currentPitch >= widget.minTargetPitch &&
        widget.currentPitch <= widget.maxTargetPitch;

    final guideColor = widget.isPerfectAngle
        ? Colors.green.shade400
        : (isYawOk && isPitchOk)
            ? Colors.amber.shade300
            : Colors.white;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer pulsing ring (shows perfect angle achieved)
        if (widget.isPerfectAngle)
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: widget.guideSize + 40,
              height: widget.guideSize + 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.green.shade400.withOpacity(0.3),
                  width: 2,
                ),
              ),
            ),
          ),

        // Main guide circle
        Container(
          width: widget.guideSize,
          height: widget.guideSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: guideColor,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: guideColor.withOpacity(widget.isPerfectAngle ? 0.6 : 0.2),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Semi-transparent background
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.02),
                ),
              ),
              // Center crosshair
              _buildCrosshair(),
              // Corner guides
              _buildCornerGuides(),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the center crosshair
  Widget _buildCrosshair() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Horizontal line
        Container(
          width: 40,
          height: 1,
          color: Colors.white.withOpacity(0.3),
        ),
        // Vertical line
        Container(
          width: 1,
          height: 40,
          color: Colors.white.withOpacity(0.3),
        ),
        // Center dot
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  /// Builds the corner guides
  Widget _buildCornerGuides() {
    const cornerSize = 24.0;
    const cornerThickness = 2.0;

    return Stack(
      children: [
        // Top-left
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            width: cornerSize,
            height: cornerSize,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.4),
                  width: cornerThickness,
                ),
                left: BorderSide(
                  color: Colors.white.withOpacity(0.4),
                  width: cornerThickness,
                ),
              ),
            ),
          ),
        ),
        // Top-right
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            width: cornerSize,
            height: cornerSize,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.4),
                  width: cornerThickness,
                ),
                right: BorderSide(
                  color: Colors.white.withOpacity(0.4),
                  width: cornerThickness,
                ),
              ),
            ),
          ),
        ),
        // Bottom-left
        Positioned(
          bottom: 12,
          left: 12,
          child: Container(
            width: cornerSize,
            height: cornerSize,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.4),
                  width: cornerThickness,
                ),
                left: BorderSide(
                  color: Colors.white.withOpacity(0.4),
                  width: cornerThickness,
                ),
              ),
            ),
          ),
        ),
        // Bottom-right
        Positioned(
          bottom: 12,
          right: 12,
          child: Container(
            width: cornerSize,
            height: cornerSize,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.4),
                  width: cornerThickness,
                ),
                right: BorderSide(
                  color: Colors.white.withOpacity(0.4),
                  width: cornerThickness,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the status text
  Widget _buildStatusText() {
    final statusText = widget.isPerfectAngle
      ? '✓ Perfect Position'
      : 'Adjust position';

    final statusColor = widget.isPerfectAngle
        ? Colors.green.shade400
        : Colors.white.withOpacity(0.7);

    final guidanceLine =
      (widget.guidanceText != null && widget.guidanceText!.trim().isNotEmpty)
        ? widget.guidanceText!
        : (widget.isHairMode
          ? 'Tilt down and center scalp in circle'
          : 'Tilt your head to 45 degrees');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          statusText,
          style: TextStyle(
            color: statusColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          guidanceLine,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// Builds the countdown timer display
  Widget _buildCountdownTimer() {
    final remainingSeconds =
        (widget.remainingTime / 1000).toStringAsFixed(1);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Circular timer background
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Colors.green.shade400,
                Colors.green.shade600,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.green.shade400.withOpacity(0.4),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Progress ring
              CustomPaint(
                painter: _RingProgressPainter(
                  progress: 1 - (widget.remainingTime / widget.captureTimerMs),
                  color: Colors.white,
                ),
                size: const Size(80, 80),
              ),
              // Timer text
              Text(
                remainingSeconds,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Auto-capturing...',
          style: TextStyle(
            color: Colors.green.shade400,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  /// Builds the angle indicators
  Widget _buildAngleIndicators() {
    final pitchInRange = widget.currentPitch >= widget.minTargetPitch &&
        widget.currentPitch <= widget.maxTargetPitch;
    final fillPercent = (widget.faceFillRatio * 100).clamp(0, 100).toInt();
    final fillOk = widget.faceFillRatio >= 0.44 && widget.faceFillRatio <= 0.78;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isHairMode)
            _buildAngleIndicatorRow(
              label: 'Scalp Framing',
              value: '$fillPercent',
              unit: '%',
              isOk: fillOk,
              targetRange: '44% - 78%',
            ),
          if (widget.isHairMode) const SizedBox(height: 8),
          // Pitch indicator - MAIN for hair analysis
          _buildAngleIndicatorRow(
            label: 'Head Tilt',
            value: widget.currentPitch.toStringAsFixed(1),
            unit: '°',
            isOk: pitchInRange,
            targetRange: '${widget.minTargetPitch.toInt()}° - ${widget.maxTargetPitch.toInt()}°',
          ),
        ],
      ),
    );
  }

  /// Builds a single angle indicator row
  Widget _buildAngleIndicatorRow({
    required String label,
    required String value,
    required String unit,
    required bool isOk,
    required String targetRange,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOk
              ? Colors.green.shade400.withOpacity(0.3)
              : Colors.amber.shade300.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                targetRange,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: isOk ? Colors.green.shade400 : Colors.amber.shade300,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                unit,
                style: TextStyle(
                  color: (isOk ? Colors.green.shade400 : Colors.amber.shade300)
                      .withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isOk ? Icons.check_circle : Icons.info_outline,
                color:
                    isOk ? Colors.green.shade400 : Colors.amber.shade300,
                size: 18,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// CustomPainter for drawing the progress ring
class _RingProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RingProgressPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // Draw background ring
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, bgPaint);

    // Draw progress ring
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RingProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
