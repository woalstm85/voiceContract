import 'package:flutter/material.dart';

/// 서명 영역에 표시되는 격자 배경을 그리는 CustomPainter
class GridPainter extends CustomPainter {
  final Color gridColor;
  final double strokeWidth;
  final double gridSize;

  GridPainter({
    this.gridColor = const Color(0xFFEEEEEE),
    this.strokeWidth = 0.5,
    this.gridSize = 20,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = strokeWidth;

    // 가로 선
    for (double i = 0; i <= size.height; i += gridSize) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }

    // 세로 선
    for (double i = 0; i <= size.width; i += gridSize) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}