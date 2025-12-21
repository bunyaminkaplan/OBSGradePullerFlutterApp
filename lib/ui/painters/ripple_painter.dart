import 'package:flutter/material.dart';

class RipplePainter extends CustomPainter {
  final double animationValue;
  final Color color;

  RipplePainter(this.animationValue, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < 3; i++) {
      final double opacity = (1.0 - (animationValue + i / 3)) % 1.0;
      final double radius = size.width / 2 * ((animationValue + i / 3) % 1.0);
      final Paint paint = Paint()
        ..color = color
            .withValues(
              alpha: opacity * 0.5,
            ) // Updated to withValues per valid lint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
