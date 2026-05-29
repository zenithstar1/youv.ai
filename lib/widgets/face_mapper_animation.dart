import 'package:flutter/material.dart';

class FaceMapperAnimation extends StatefulWidget {
  final bool isAnalyzing;

  const FaceMapperAnimation({
    super.key,
    required this.isAnalyzing,
  });

  @override
  State<FaceMapperAnimation> createState() => _FaceMapperAnimationState();
}

class _FaceMapperAnimationState extends State<FaceMapperAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _morphAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _morphAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isAnalyzing) {
      return const SizedBox.shrink();
    }

    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: FaceMapperPainter(
              scale: _scaleAnimation.value,
              morphProgress: _morphAnimation.value,
            ),
            size: const Size(200, 280),
          );
        },
      ),
    );
  }
}

class FaceMapperPainter extends CustomPainter {
  final double scale;
  final double morphProgress;

  FaceMapperPainter({
    required this.scale,
    required this.morphProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Paint for face outline
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Glow paint
    final glowPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw glow circles
    canvas.drawCircle(
      Offset(centerX, centerY),
      50 * scale,
      glowPaint,
    );
    canvas.drawCircle(
      Offset(centerX, centerY),
      60 * scale,
      glowPaint,
    );

    // Draw animated face outline (morphs)
    final facePath = Path();
    final faceWidth = 80 * scale;
    final faceHeight = 120 * scale;

    // Face oval
    facePath.addOval(
      Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: faceWidth,
        height: faceHeight,
      ),
    );

    canvas.drawPath(facePath, paint);

    // Draw animated facial features
    _drawEyes(canvas, centerX, centerY, scale, paint);
    _drawNose(canvas, centerX, centerY, scale, paint);
    _drawMouth(canvas, centerX, centerY, scale, paint);
    _drawFacialGrid(canvas, centerX, centerY, scale, paint);
  }

  void _drawEyes(
    Canvas canvas,
    double centerX,
    double centerY,
    double scale,
    Paint paint,
  ) {
    final eyeY = centerY - 20 * scale;
    const eyeWidth = 8.0;
    const eyeHeight = 12.0;

    // Left eye
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX - 20 * scale, eyeY),
        width: eyeWidth * scale,
        height: eyeHeight * scale,
      ),
      paint,
    );

    // Right eye
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX + 20 * scale, eyeY),
        width: eyeWidth * scale,
        height: eyeHeight * scale,
      ),
      paint,
    );
  }

  void _drawNose(
    Canvas canvas,
    double centerX,
    double centerY,
    double scale,
    Paint paint,
  ) {
    final noseTop = centerY - 5 * scale;
    final noseBottom = centerY + 15 * scale;

    canvas.drawLine(
      Offset(centerX, noseTop),
      Offset(centerX, noseBottom),
      paint,
    );

    // Nose tip
    canvas.drawCircle(
      Offset(centerX, noseBottom),
      3 * scale,
      paint,
    );
  }

  void _drawMouth(
    Canvas canvas,
    double centerX,
    double centerY,
    double scale,
    Paint paint,
  ) {
    final mouthY = centerY + 30 * scale;
    final mouthWidth = 25 * scale;

    // Smile curve
    final path = Path();
    path.moveTo(centerX - mouthWidth, mouthY);
    path.quadraticBezierTo(
      centerX,
      mouthY + 8 * scale,
      centerX + mouthWidth,
      mouthY,
    );

    canvas.drawPath(path, paint);
  }

  void _drawFacialGrid(
    Canvas canvas,
    double centerX,
    double centerY,
    double scale,
    Paint paint,
  ) {
    final gridPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.3 * morphProgress)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw a subtle grid over the face area
    final gridSize = 15 * scale;
    final faceWidth = 80 * scale;
    final faceHeight = 120 * scale;

    final startX = centerX - faceWidth / 2;
    final startY = centerY - faceHeight / 2;

    for (double x = startX; x <= startX + faceWidth; x += gridSize) {
      canvas.drawLine(
        Offset(x, startY),
        Offset(x, startY + faceHeight),
        gridPaint,
      );
    }

    for (double y = startY; y <= startY + faceHeight; y += gridSize) {
      canvas.drawLine(
        Offset(startX, y),
        Offset(startX + faceWidth, y),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(FaceMapperPainter oldDelegate) {
    return oldDelegate.scale != scale ||
        oldDelegate.morphProgress != morphProgress;
  }
}
