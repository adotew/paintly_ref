import 'package:flutter/material.dart';

class CornerHandlePainter extends CustomPainter {
  final double handleLength;
  final double handleThickness;
  final Color handleColor;
  final double borderRadius;

  CornerHandlePainter({
    required this.handleLength,
    required this.handleThickness,
    this.handleColor = const Color.fromARGB(255, 255, 255, 255),
    this.borderRadius = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final handleLen = handleLength;
    final radius = borderRadius;

    // Draw handles at each corner
    // First draw dark outline/shadow for visibility
    final outlinePaint = Paint()
      ..color = Colors.black
          .withValues(alpha: 0.6) // Dunkler Schatten
      ..strokeWidth =
          handleThickness +
          4.0 // Etwas dicker als der weiße Strich
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Then draw the white handles on top
    final paint = Paint()
      ..color = handleColor
      ..strokeWidth = handleThickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw all four corners with outline first, then white
    _drawCornerHandle(
      canvas,
      outlinePaint,
      size,
      0,
      0,
      radius,
      handleLen,
    ); // Top-left outline
    _drawCornerHandle(canvas, paint, size, 0, 0, radius, handleLen); // Top-left

    _drawCornerHandle(
      canvas,
      outlinePaint,
      size,
      size.width,
      0,
      radius,
      handleLen,
    ); // Top-right outline
    _drawCornerHandle(
      canvas,
      paint,
      size,
      size.width,
      0,
      radius,
      handleLen,
    ); // Top-right

    _drawCornerHandle(
      canvas,
      outlinePaint,
      size,
      size.width,
      size.height,
      radius,
      handleLen,
    ); // Bottom-right outline
    _drawCornerHandle(
      canvas,
      paint,
      size,
      size.width,
      size.height,
      radius,
      handleLen,
    ); // Bottom-right

    _drawCornerHandle(
      canvas,
      outlinePaint,
      size,
      0,
      size.height,
      radius,
      handleLen,
    ); // Bottom-left outline
    _drawCornerHandle(
      canvas,
      paint,
      size,
      0,
      size.height,
      radius,
      handleLen,
    ); // Bottom-left
  }

  void _drawCornerHandle(
    Canvas canvas,
    Paint paint,
    Size size,
    double cornerX,
    double cornerY,
    double cornerRadius,
    double length,
  ) {
    final path = Path();
    final isTopLeft = cornerX == 0 && cornerY == 0;
    final isTopRight = cornerX == size.width && cornerY == 0;
    final isBottomRight = cornerX == size.width && cornerY == size.height;

    // Determine the corner arc rectangle and angles
    late Rect arcRect;
    late double startAngle;
    const sweepAngle = 90 * (3.14159 / 180);

    if (isTopLeft) {
      // Top-left: horizontal line extending right -> arc following corner -> vertical line extending down
      arcRect = Rect.fromLTWH(0, 0, cornerRadius * 2, cornerRadius * 2);
      startAngle = 270 * (3.14159 / 180);
      // Start from outside, going inward to the corner
      path.moveTo(cornerRadius + length, 0);
      path.lineTo(cornerRadius, 0);
      // Follow the rounded corner arc (counter-clockwise to go from top to left)
      path.addArc(arcRect, startAngle, -sweepAngle);
      // Continue down along the left edge
      path.lineTo(0, cornerRadius + length);
    } else if (isTopRight) {
      // Top-right: horizontal line extending left -> arc following corner -> vertical line extending down
      arcRect = Rect.fromLTWH(
        size.width - cornerRadius * 2,
        0,
        cornerRadius * 2,
        cornerRadius * 2,
      );
      startAngle = 270 * (3.14159 / 180);
      path.moveTo(size.width - cornerRadius - length, 0);
      path.lineTo(size.width - cornerRadius, 0);
      path.addArc(arcRect, startAngle, sweepAngle);
      path.lineTo(size.width, cornerRadius + length);
    } else if (isBottomRight) {
      // Bottom-right: horizontal line extending left -> arc following corner -> vertical line extending up
      arcRect = Rect.fromLTWH(
        size.width - cornerRadius * 2,
        size.height - cornerRadius * 2,
        cornerRadius * 2,
        cornerRadius * 2,
      );
      startAngle = 90 * (3.14159 / 180);
      path.moveTo(size.width - cornerRadius - length, size.height);
      path.lineTo(size.width - cornerRadius, size.height);
      // Arc goes counter-clockwise from bottom to right
      path.addArc(arcRect, startAngle, -sweepAngle);
      path.lineTo(size.width, size.height - cornerRadius - length);
    } else {
      // Bottom-left: horizontal line extending right -> arc following corner -> vertical line extending up
      arcRect = Rect.fromLTWH(
        0,
        size.height - cornerRadius * 2,
        cornerRadius * 2,
        cornerRadius * 2,
      );
      startAngle = 90 * (3.14159 / 180);
      path.moveTo(cornerRadius + length, size.height);
      path.lineTo(cornerRadius, size.height);
      path.addArc(arcRect, startAngle, sweepAngle);
      path.lineTo(0, size.height - cornerRadius - length);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CornerHandlePainter oldDelegate) {
    return oldDelegate.handleLength != handleLength ||
        oldDelegate.handleThickness != handleThickness ||
        oldDelegate.handleColor != handleColor ||
        oldDelegate.borderRadius != borderRadius;
  }
}
