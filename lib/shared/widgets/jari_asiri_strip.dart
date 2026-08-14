import 'package:flutter/material.dart';

/// Lightweight Asiri (Al-Qatt) geometric strip — secondary brand accent only.
///
/// Allowed: splash, login/OTP, onboarding, large empty states.
/// Forbidden: maps, dense forms, tables, operational dashboards.
class JariAsiriStrip extends StatelessWidget {
  const JariAsiriStrip({
    super.key,
    this.height = 10,
  });

  final double height;

  static const _palette = <Color>[
    Color(0xFFD4A633),
    Color(0xFF0F5B4E),
    Color(0xFFC4553A),
    Color(0xFFF7F3E9),
  ];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      excludeSemantics: true,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _AsiriStripPainter(colors: _palette),
        ),
      ),
    );
  }
}

class _AsiriStripPainter extends CustomPainter {
  _AsiriStripPainter({required this.colors});

  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final unit = size.height;
    var x = 0.0;
    var i = 0;
    final paint = Paint()..style = PaintingStyle.fill;
    while (x < size.width) {
      paint.color = colors[i % colors.length];
      final path = Path()
        ..moveTo(x, size.height)
        ..lineTo(x + unit / 2, 0)
        ..lineTo(x + unit, size.height)
        ..close();
      canvas.drawPath(path, paint);
      x += unit * 0.85;
      i++;
    }
  }

  @override
  bool shouldRepaint(covariant _AsiriStripPainter oldDelegate) =>
      oldDelegate.colors != colors;
}
