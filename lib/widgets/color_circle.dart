import 'package:flutter/material.dart';

class ColorCircle extends StatefulWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback? onTap;

  const ColorCircle({
    super.key,
    required this.color,
    this.isSelected = false,
    this.onTap,
  });

  @override
  State<ColorCircle> createState() => _ColorCircleState();
}

class _ColorCircleState extends State<ColorCircle> {
  @override
  Widget build(BuildContext context) {
    // Determine if the color is light or dark
    final isLightColor = widget.color.computeLuminance() > 0.5;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.isSelected
                ? Colors.black
                : (isLightColor ? Colors.grey[400]! : Colors.white),
            width: widget.isSelected ? 2.5 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: widget.isSelected
            ? Icon(
                Icons.check,
                color: isLightColor ? Colors.black : Colors.white,
                size: 20,
              )
            : null,
      ),
    );
  }
}
