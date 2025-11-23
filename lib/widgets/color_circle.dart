import 'package:flutter/material.dart';

class ColorCircle extends StatefulWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback? onTap;

  const ColorCircle({
    Key? key,
    required this.color,
    this.isSelected = false,
    this.onTap,
  }) : super(key: key);

  @override
  State<ColorCircle> createState() => _ColorCircleState();
}

class _ColorCircleState extends State<ColorCircle> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.isSelected ? Colors.black : Colors.white,
            width: widget.isSelected ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: widget.isSelected
            ? const Icon(Icons.check, color: Colors.black, size: 20)
            : null,
      ),
    );
  }
}
