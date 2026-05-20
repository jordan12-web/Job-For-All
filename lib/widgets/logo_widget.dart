import 'package:flutter/material.dart';

/// Blue work-bag logo for Job For All branding
/// Simple, professional design using CustomPaint
class LogoWidget extends StatelessWidget {
  final double size;
  final Color color;

  const LogoWidget({
    super.key,
    this.size = 40,
    this.color = const Color(0xFF4C63FF),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: WorkBagPainter(bagColor: color),
    );
  }
}

/// Custom painter for work-bag logo
class WorkBagPainter extends CustomPainter {
  final Color bagColor;

  WorkBagPainter({required this.bagColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = bagColor
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = bagColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Bag body (rounded rectangle)
    final bagRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.15,
        size.height * 0.3,
        size.width * 0.7,
        size.height * 0.55,
      ),
      Radius.circular(size.width * 0.08),
    );
    canvas.drawRRect(bagRect, paint);

    // Bag handle (arc)
    final handlePath = Path();
    handlePath.moveTo(size.width * 0.25, size.height * 0.3);
    handlePath.quadraticBezierTo(
      size.width * 0.5,
      size.height * -0.05,
      size.width * 0.75,
      size.height * 0.3,
    );
    canvas.drawPath(handlePath, strokePaint);

    // Zipper detail (vertical line)
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.35),
      Offset(size.width * 0.5, size.height * 0.75),
      strokePaint,
    );

    // Pocket detail (small rectangle)
    final pocketRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.25,
        size.height * 0.4,
        size.width * 0.5,
        size.height * 0.2,
      ),
      Radius.circular(size.width * 0.05),
    );
    canvas.drawRRect(pocketRect, strokePaint);
  }

  @override
  bool shouldRepaint(WorkBagPainter oldDelegate) {
    return oldDelegate.bagColor != bagColor;
  }
}
