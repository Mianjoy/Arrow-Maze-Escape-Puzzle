import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/domain.dart';
import '../../theme/app_colors.dart';
import 'arrow_path_geometry.dart';

/// Pinta el tablero completo: rejilla, muros y flechas como trazos continuos.
///
/// Inspirado en el logo del laberinto: líneas gruesas con extremos redondeados
/// y punta triangular en la cabeza. Cada flecha puede abarcar hasta 3 celdas.
class ArrowBoardPainter extends CustomPainter {
  /// Crea el painter para [board] con el tamaño de celda ya calculado.
  const ArrowBoardPainter({
    required this.board,
    required this.cellWidth,
    required this.cellHeight,
  });

  /// Estado del tablero a renderizar.
  final Board board;

  /// Ancho de cada celda en píxeles lógicos.
  final double cellWidth;

  /// Alto de cada celda en píxeles lógicos.
  final double cellHeight;

  @override
  void paint(Canvas canvas, Size size) {
    _paintGrid(canvas, size);
    _paintWalls(canvas);
    for (final arrow in board.arrows.where((a) => !a.isExtracted)) {
      _paintArrow(canvas, arrow);
    }
  }

  /// Dibuja puntos de rejilla tenues sobre el fondo del tablero.
  void _paintGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gridLine.withValues(alpha: 0.25)
      ..strokeWidth = 1;

    for (var row = 0; row <= board.dimension.rows; row++) {
      final y = row * cellHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (var col = 0; col <= board.dimension.columns; col++) {
      final x = col * cellWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  /// Rellena cada celda de muro con un bloque redondeado oscuro.
  void _paintWalls(Canvas canvas) {
    final paint = Paint()..color = AppColors.wall;
    const radius = 6.0;
    const inset = 3.0;

    for (final cell in board.cells.where((c) => c.isWall)) {
      final rect = Rect.fromLTWH(
        cell.position.column * cellWidth + inset,
        cell.position.row * cellHeight + inset,
        cellWidth - inset * 2,
        cellHeight - inset * 2,
      );
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(radius)), paint);
    }
  }

  /// Traza una flecha completa (hasta 3 celdas) con punta en la cabeza.
  void _paintArrow(Canvas canvas, Arrow arrow) {
    final positions = ArrowPathGeometry.tailToHead(arrow);
    if (positions.isEmpty) return;

    final points = positions
        .map(
          (p) => ArrowPathGeometry.cellCenter(
            p,
            cellWidth: cellWidth,
            cellHeight: cellHeight,
          ),
        )
        .toList();

    final color = _colorForArrow(arrow);
    final strokeWidth = math.min(cellWidth, cellHeight) * 0.18;

    if (points.length == 1) {
      _paintArrowHead(canvas, points.first, arrow.direction, color, strokeWidth);
      return;
    }

    final pathPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, pathPaint);

    _paintArrowHead(
      canvas,
      ArrowPathGeometry.cellCenter(
        arrow.position,
        cellWidth: cellWidth,
        cellHeight: cellHeight,
      ),
      arrow.direction,
      color,
      strokeWidth,
    );
  }

  /// Asigna color según el estado de la flecha.
  Color _colorForArrow(Arrow arrow) {
    return switch (arrow.state) {
      ArrowState.blocked => AppColors.arrowBlocked,
      ArrowState.active => AppColors.arrow,
      ArrowState.extracted => AppColors.arrow.withValues(alpha: 0.3),
    };
  }

  /// Dibuja la punta triangular orientada según [direction] en [center].
  void _paintArrowHead(
    Canvas canvas,
    Offset center,
    Direction direction,
    Color color,
    double strokeWidth,
  ) {
    final angle = _angleFor(direction);
    final headLength = strokeWidth * 2.2;
    final headWidth = strokeWidth * 1.6;

    final tip = center + Offset(math.cos(angle), math.sin(angle)) * headLength * 0.6;
    final baseCenter = center - Offset(math.cos(angle), math.sin(angle)) * headLength * 0.4;
    final perpendicular = Offset(-math.sin(angle), math.cos(angle));

    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(baseCenter.dx + perpendicular.dx * headWidth, baseCenter.dy + perpendicular.dy * headWidth)
      ..lineTo(baseCenter.dx - perpendicular.dx * headWidth, baseCenter.dy - perpendicular.dy * headWidth)
      ..close();

    canvas.drawPath(path, Paint()..color = color);
  }

  /// Convierte la dirección de dominio al ángulo en radianes (0 = derecha).
  double _angleFor(Direction direction) {
    return switch (direction.arrowDirection) {
      ArrowDirection.right => 0,
      ArrowDirection.down => math.pi / 2,
      ArrowDirection.left => math.pi,
      ArrowDirection.up => -math.pi / 2,
    };
  }

  @override
  bool shouldRepaint(covariant ArrowBoardPainter oldDelegate) {
    return oldDelegate.board != board ||
        oldDelegate.cellWidth != cellWidth ||
        oldDelegate.cellHeight != cellHeight;
  }
}
