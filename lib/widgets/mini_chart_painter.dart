import 'package:flutter/material.dart';

/// ───────────────────────────────────────────────────────────────────────────
/// גרף ה-sparkline של מחיר המניה, בכרטיס הראשי ובמסך החיפוש.
///
/// ללא BuildContext (זהו CustomPainter), ולכן הצבעים מגיעים כפרמטרים
/// מהקורא במקום מהטוקנים ישירות.
/// ───────────────────────────────────────────────────────────────────────────

class MiniChartPainter extends CustomPainter {
  final List<double>? data;
  final bool isPositive;
  final int? touchIndex;

  // הצבעים מגיעים מהטוקנים דרך הקורא - לצייר יש Canvas אבל אין BuildContext
  final Color upColor;
  final Color downColor;

  MiniChartPainter({
    this.data,
    this.isPositive = true,
    this.touchIndex,
    required this.upColor,
    required this.downColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    List<double> points = data != null && data!.isNotEmpty
        ? data!
        : [0.75, 0.68, 0.72, 0.5, 0.47, 0.33, 0.37, 0.25, 0.17, 0.13];

    double maxVal = points.reduce((a, b) => a > b ? a : b);
    double minVal = points.reduce((a, b) => a < b ? a : b);
    double range = maxVal - minVal;
    if (range == 0) range = 1;

    List<double> normalizedPoints = data != null
        ? points.map((p) => 1.0 - ((p - minVal) / range)).toList()
        : points;

    final color = isPositive ? upColor : downColor;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < normalizedPoints.length; i++) {
      final x = (i / (normalizedPoints.length - 1)) * size.width;
      final y = normalizedPoints[i] * size.height;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // סמן הנקודה שנוגעים בה: קו אנכי + עיגול על הערך
    if (touchIndex != null &&
        data != null &&
        touchIndex! >= 0 &&
        touchIndex! < normalizedPoints.length &&
        normalizedPoints.length > 1) {
      final x = (touchIndex! / (normalizedPoints.length - 1)) * size.width;
      final y = normalizedPoints[touchIndex!] * size.height;

      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        Paint()
          ..color = color.withValues(alpha: 0.35)
          ..strokeWidth = 1,
      );
      canvas.drawCircle(
        Offset(x, y),
        6,
        Paint()..color = color.withValues(alpha: 0.25),
      );
      canvas.drawCircle(Offset(x, y), 3.5, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
