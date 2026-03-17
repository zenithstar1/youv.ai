import 'package:flutter/material.dart';

class LightAndFacePositioningChecker extends StatefulWidget {
  final bool isVisible;

  const LightAndFacePositioningChecker({
    super.key,
    required this.isVisible,
  });

  @override
  State<LightAndFacePositioningChecker> createState() =>
      _LightAndFacePositioningCheckerState();
}

class _LightAndFacePositioningCheckerState
    extends State<LightAndFacePositioningChecker>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Face positioning guide
        Container(
          width: 220,
          height: 280,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.cyan.withOpacity(0.6),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Corner guides
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.cyan.withOpacity(0.8)),
                      left: BorderSide(color: Colors.cyan.withOpacity(0.8)),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.cyan.withOpacity(0.8)),
                      right: BorderSide(color: Colors.cyan.withOpacity(0.8)),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.cyan.withOpacity(0.8)),
                      left: BorderSide(color: Colors.cyan.withOpacity(0.8)),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.cyan.withOpacity(0.8)),
                      right: BorderSide(color: Colors.cyan.withOpacity(0.8)),
                    ),
                  ),
                ),
              ),
              // Center guide circle (pulsing)
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.green.withOpacity(0.6),
                      width: 2,
                    ),
                  ),
                ),
              ),
              // Face position text
              Positioned(
                bottom: 15,
                child: Text(
                  'Center your face',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Light check indicator
        _buildCheckItem(
          icon: Icons.lightbulb_outline,
          label: 'Adequate lighting',
          isGood: true,
        ),
        const SizedBox(height: 10),
        _buildCheckItem(
          icon: Icons.face,
          label: 'Face centered',
          isGood: true,
        ),
        const SizedBox(height: 10),
        _buildCheckItem(
          icon: Icons.close_fullscreen,
          label: 'Fill the frame',
          isGood: false,
        ),
      ],
    );
  }

  Widget _buildCheckItem({
    required IconData icon,
    required String label,
    required bool isGood,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: isGood ? Colors.green : Colors.orange,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: isGood ? Colors.green : Colors.orange,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 6),
        Icon(
          isGood ? Icons.check_circle : Icons.error_outline,
          color: isGood ? Colors.green : Colors.orange,
          size: 16,
        ),
      ],
    );
  }
}
