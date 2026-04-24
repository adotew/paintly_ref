import 'package:flutter/material.dart';

class CornerHandleMetrics {
  CornerHandleMetrics._();

  // Screen-space values. Divide by canvasScale so they stay visually fixed.
  static const double _baseHandlePadding = 40.0;
  static const double _baseHitArea = 44.0;

  static const double baseRadius = 8.0;
  static const double baseOffset = 11.0;

  static double handlePadding(double canvasScale) =>
      _baseHandlePadding / canvasScale;

  static double hitAreaSize(double canvasScale) => _baseHitArea / canvasScale;

  static double radiusForCanvasScale(double canvasScale) =>
      baseRadius / canvasScale;

  static double offsetForCanvasScale(double canvasScale) =>
      baseOffset / canvasScale;
}

class CircleHandlePainter extends CustomPainter {
  final double radius;
  final double offset; // distance to push circle center outside each corner
  final Color fillColor;
  final Color shadowColor;
  final double shadowWidth;

  const CircleHandlePainter({
    required this.radius,
    this.offset = 0.0,
    this.fillColor = const Color(0xFFFFFFFF),
    this.shadowColor = const Color(0x99000000),
    this.shadowWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final o = offset;
    final corners = [
      Offset(-o, -o), // top-left
      Offset(size.width + o, -o), // top-right
      Offset(size.width + o, size.height + o), // bottom-right
      Offset(-o, size.height + o), // bottom-left
    ];

    final shadowPaint = Paint()
      ..color = shadowColor
      ..style = PaintingStyle.fill;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    for (final c in corners) {
      canvas.drawCircle(c, radius + shadowWidth, shadowPaint);
      canvas.drawCircle(c, radius, fillPaint);
    }
  }

  @override
  bool shouldRepaint(CircleHandlePainter old) =>
      old.radius != radius ||
      old.offset != offset ||
      old.fillColor != fillColor ||
      old.shadowColor != shadowColor;
}
