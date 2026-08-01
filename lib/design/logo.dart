import 'package:flutter/material.dart';

import 'tokens.dart';

enum LogoVariant {
  /// Mark + FINOVA wordmark.
  full,

  /// Mark only — app icon, tight spaces.
  mark,

  /// Mark + wordmark in a single flat colour.
  mono,
}

/// The Finova logo, drawn natively rather than loaded from SVG.
///
/// Geometry is identical to assets/brand/logo-mark.svg (a 24x24 unit box with
/// three rounded bars of descending length). Drawing it in a painter avoids
/// pulling in flutter_svg for what amounts to three rounded rectangles.
///
/// Usage rules from the brand section: never rotate, stretch, recolour the
/// gradient, or add a shadow. Clear space around the logo equals the height of
/// the mark, which [Logo] does not enforce — callers must leave it.
class Logo extends StatelessWidget {
  const Logo({
    super.key,
    this.variant = LogoVariant.full,
    this.markSize = 24,
    this.color,
  });

  final LogoVariant variant;

  /// Height of the mark. The header spec calls for 24.
  final double markSize;

  /// Flat colour for [LogoVariant.mono]. Defaults to the primary text colour.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isMono = variant == LogoVariant.mono;
    final flat = color ?? c.textPrimary;

    final mark = SizedBox(
      width: markSize,
      height: markSize,
      child: CustomPaint(
        painter: _MarkPainter(flatColor: isMono ? flat : null),
      ),
    );

    if (variant == LogoVariant.mark) {
      return Semantics(label: 'Finova', image: true, child: mark);
    }

    return Semantics(
      label: 'Finova',
      image: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          mark,
          const SizedBox(width: 10),
          Text(
            'FINOVA',
            style: FType.wordmark.copyWith(
              color: isMono ? flat : c.textPrimary,
              // The mark is 24 tall, the wordmark 20 — nudged so their
              // optical centres line up rather than their boxes.
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter({this.flatColor});

  final Color? flatColor;

  // x, y, width, height in the 24x24 unit box — mirrors the SVG exactly.
  static const List<List<double>> _bars = [
    [1, 3.75, 22, 4.5],
    [1, 9.75, 15, 4.5],
    [1, 15.75, 8.5, 4.5],
  ];
  static const double _radius = 2.25;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24.0;
    final paint = Paint()..isAntiAlias = true;

    if (flatColor != null) {
      paint.color = flatColor!;
    } else {
      // The gradient runs across the mark's own bounding box, weighted toward
      // the vertical so the shortest bar actually reaches cyan.
      paint.shader = const LinearGradient(
        begin: Alignment(-1, -1),
        end: Alignment(-0.4, 1),
        colors: [Color(0xFF7C3AED), Color(0xFF22D3EE)],
      ).createShader(Rect.fromLTWH(1 * s, 3.75 * s, 22 * s, 16.5 * s));
    }

    for (final b in _bars) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(b[0] * s, b[1] * s, b[2] * s, b[3] * s),
          Radius.circular(_radius * s),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) =>
      oldDelegate.flatColor != flatColor;
}
