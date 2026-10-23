import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Custom background with subtle, elegant wedding line-art doodles (watermark pattern).
/// Inspired by luxury matrimony invitation stationery.
class WeddingPatternBackground extends StatelessWidget {
  final Widget child;

  const WeddingPatternBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Soft warm white background with slight blush tint
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                Color(0xFFFFF9FA),
                Color(0xFFFFF4F6),
              ],
            ),
          ),
        ),

        // 2. Watermark wedding doodles painter
        const CustomPaint(
          painter: _WeddingDoodlesPainter(),
        ),

        // 3. Foreground content
        child,
      ],
    );
  }
}

class _WeddingDoodlesPainter extends CustomPainter {
  const _WeddingDoodlesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = const Color(0xFFE91E63).withValues(alpha: 0.13)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.4;

    final fillPaint = Paint()
      ..color = const Color(0xFFF48FB1).withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final goldStroke = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.3;

    final stepX = 110.0;
    final stepY = 115.0;

    int cols = (size.width / stepX).ceil() + 1;
    int rows = (size.height / stepY).ceil() + 1;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final x = c * stepX + ((r % 2 == 1) ? stepX * 0.5 : 0.0) + 20;
        final y = r * stepY + 30;
        final type = (r * 7 + c * 3) % 6;

        switch (type) {
          case 0:
            _drawHeart(canvas, Offset(x, y), 18, strokePaint, fillPaint);
            break;
          case 1:
            _drawInterlockedRings(canvas, Offset(x, y), 12, goldStroke);
            break;
          case 2:
            _drawDove(canvas, Offset(x, y), 16, strokePaint);
            break;
          case 3:
            _drawSparkle(canvas, Offset(x, y), 14, goldStroke);
            break;
          case 4:
            _drawWeddingCake(canvas, Offset(x, y), 18, strokePaint);
            break;
          case 5:
            _drawChampagneGlasses(canvas, Offset(x, y), 16, strokePaint);
            break;
        }
      }
    }
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Paint stroke, Paint fill) {
    final path = Path();
    final w = size;
    final h = size * 0.95;
    final left = center.dx - w / 2;
    final top = center.dy - h / 2;

    path.moveTo(left + w / 2, top + h * 0.35);
    path.cubicTo(left + w * 0.15, top - h * 0.15, left - w * 0.1, top + h * 0.55, left + w / 2, top + h);
    path.cubicTo(left + w * 1.1, top + h * 0.55, left + w * 0.85, top - h * 0.15, left + w / 2, top + h * 0.35);
    path.close();

    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  void _drawInterlockedRings(Canvas canvas, Offset center, double radius, Paint stroke) {
    canvas.drawCircle(Offset(center.dx - radius * 0.5, center.dy), radius, stroke);
    canvas.drawCircle(Offset(center.dx + radius * 0.5, center.dy), radius, stroke);
    // Tiny gem on right ring
    final diamondPath = Path();
    final dX = center.dx + radius * 0.5;
    final dY = center.dy - radius;
    diamondPath.moveTo(dX, dY - 4);
    diamondPath.lineTo(dX + 3, dY);
    diamondPath.lineTo(dX, dY + 4);
    diamondPath.lineTo(dX - 3, dY);
    diamondPath.close();
    canvas.drawPath(diamondPath, stroke);
  }

  void _drawDove(Canvas canvas, Offset center, double size, Paint stroke) {
    final path = Path();
    path.moveTo(center.dx - size * 0.6, center.dy);
    path.quadraticBezierTo(center.dx, center.dy - size * 0.7, center.dx + size * 0.6, center.dy - size * 0.2);
    path.quadraticBezierTo(center.dx + size * 0.2, center.dy + size * 0.4, center.dx - size * 0.6, center.dy);
    canvas.drawPath(path, stroke);
    // Olive branch / tail
    canvas.drawLine(Offset(center.dx - size * 0.6, center.dy), Offset(center.dx - size * 0.9, center.dy + size * 0.2), stroke);
  }

  void _drawSparkle(Canvas canvas, Offset center, double size, Paint stroke) {
    final path = Path();
    path.moveTo(center.dx, center.dy - size);
    path.quadraticBezierTo(center.dx, center.dy, center.dx + size, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + size);
    path.quadraticBezierTo(center.dx, center.dy, center.dx - size, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - size);
    path.close();
    canvas.drawPath(path, stroke);
  }

  void _drawWeddingCake(Canvas canvas, Offset center, double size, Paint stroke) {
    // Bottom tier
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx, center.dy + size * 0.3), width: size * 1.2, height: size * 0.45),
        const Radius.circular(2),
      ),
      stroke,
    );
    // Top tier
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx, center.dy - size * 0.15), width: size * 0.75, height: size * 0.4),
        const Radius.circular(2),
      ),
      stroke,
    );
    // Topper
    canvas.drawCircle(Offset(center.dx, center.dy - size * 0.45), 2.5, stroke);
  }

  void _drawChampagneGlasses(Canvas canvas, Offset center, double size, Paint stroke) {
    // Left glass
    canvas.drawLine(Offset(center.dx - 8, center.dy - size * 0.5), Offset(center.dx - 4, center.dy + size * 0.1), stroke);
    canvas.drawLine(Offset(center.dx - 12, center.dy - size * 0.5), Offset(center.dx - 4, center.dy + size * 0.1), stroke);
    canvas.drawLine(Offset(center.dx - 4, center.dy + size * 0.1), Offset(center.dx - 4, center.dy + size * 0.5), stroke);
    // Right glass clinking
    canvas.drawLine(Offset(center.dx + 8, center.dy - size * 0.5), Offset(center.dx + 4, center.dy + size * 0.1), stroke);
    canvas.drawLine(Offset(center.dx + 12, center.dy - size * 0.5), Offset(center.dx + 4, center.dy + size * 0.1), stroke);
    canvas.drawLine(Offset(center.dx + 4, center.dy + size * 0.1), Offset(center.dx + 4, center.dy + size * 0.5), stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
