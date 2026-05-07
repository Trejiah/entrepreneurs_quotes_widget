import 'package:flutter/material.dart';

class DottedLinesBackground extends StatelessWidget {
  const DottedLinesBackground({
    super.key,
    this.lineColor = Colors.white54,
    this.lineWidth = 1,
    this.dashWidth = 6,
    this.dashSpace = 4,
    this.lineCount = 5,
  });

  final Color lineColor;
  final double lineWidth;
  final double dashWidth;
  final double dashSpace;
  final int lineCount;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DottedLinesPainter(
        lineColor: lineColor,
        lineWidth: lineWidth,
        dashWidth: dashWidth,
        dashSpace: dashSpace,
        lineCount: lineCount,
      ),
      child: Text(""), // ton contenu
    );
  }
}

class _DottedLinesPainter extends CustomPainter {
  final Color lineColor;
  final double lineWidth;
  final double dashWidth;
  final double dashSpace;
  final int lineCount;

  _DottedLinesPainter({
    required this.lineColor,
    required this.lineWidth,
    required this.dashWidth,
    required this.dashSpace,
    required this.lineCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke;

    // espacement vertical (spaceBetween)
    final double step = size.height / (lineCount - 1);

    for (int i = 0; i < lineCount; i++) {
      final y = i * step;
      double startX = 0;

      // draw the dashed line
      while (startX < size.width) {
        canvas.drawLine(
          Offset(startX, y),
          Offset(startX + dashWidth, y),
          paint,
        );
        startX += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
