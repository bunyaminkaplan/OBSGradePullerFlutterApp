import 'package:flutter/material.dart';

/// Ripple effect for hold-duration based intensity.
/// Higher intensity = thicker strokes, brighter colors.
class RipplePainter extends CustomPainter {
  final List<double> rippleValues;
  final List<double> rippleIntensities; // Intensity per ripple (0.0 - 1.0)
  final Color color;

  RipplePainter(this.rippleValues, this.color, [List<double>? intensities])
    : rippleIntensities =
          intensities ??
          List.filled(rippleValues.length, 0.5); // Default medium intensity

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < rippleValues.length; i++) {
      final val = rippleValues[i];
      final intensity = i < rippleIntensities.length
          ? rippleIntensities[i].clamp(0.0, 1.0)
          : 0.5;

      if (val > 0.0 && val < 1.0) {
        // Max radius extends BEYOND the container for dramatic fade effect
        final double maxRadius =
            size.width / 2 * 1.4; // 40% larger than container
        // Ripple always starts OUTSIDE the icon (icon container is ~53% of total size)
        final double minRadius = size.width / 2 * 0.55;

        final double radius = minRadius + (maxRadius - minRadius) * val;
        final double baseOpacity = (1.0 - val).clamp(0.0, 1.0);
        // Higher intensity = higher opacity
        final double opacity = baseOpacity * (0.3 + intensity * 0.5);

        // Higher intensity = thicker stroke
        final double strokeWidth = 2 + (intensity * 4) + (2 * (1 - val));

        final Paint paint = Paint()
          ..color = color.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth;

        canvas.drawCircle(
          Offset(size.width / 2, size.height / 2),
          radius,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant RipplePainter oldDelegate) => true;
}
