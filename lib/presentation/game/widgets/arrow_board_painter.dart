import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/domain.dart';
import '../../theme/app_colors.dart';
import 'arrow_path_geometry.dart';

/// Pinta el tablero: muros y flechas como trazos finos continuos (sin rejilla).
///
/// La cabeza se ancla al borde de su celda en la dirección de disparo para
/// evitar solapamientos con el cuerpo, sobre todo en flechas verticales largas.
class ArrowBoardPainter extends CustomPainter {
  /// Crea el painter para [board] con el tamaño de celda ya calculado.
  const ArrowBoardPainter({
    required this.board,
    required this.cellWidth,
    required this.cellHeight,
  });

  static const _strokeFactor = 0.12;
  static const _headLengthFactor = 1.8;
  static const _headWidthFactor = 1.2;
  static const _headMarginFactor = 0.5;

  /// Estado del tablero a renderizar.
  final Board board;

  /// Ancho de cada celda en píxeles lógicos.
  final double cellWidth;

  /// Alto de cada celda en píxeles lógicos.
  final double cellHeight;

  @override
  void paint(Canvas canvas, Size size) {
    _paintWalls(canvas);
    for (final arrow in board.arrows.where((a) => !a.isExtracted)) {
      _paintArrow(canvas, arrow);
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

  /// Traza una flecha completa con punta en el borde de la celda de cabeza.
  void _paintArrow(Canvas canvas, Arrow arrow) {
    final positions = ArrowPathGeometry.tailToHead(arrow);
    if (positions.isEmpty) return;

    final color = _colorForArrow(arrow);
    final strokeWidth = math.min(cellWidth, cellHeight) * _strokeFactor;
    final headLength = strokeWidth * _headLengthFactor;
    final headWidth = strokeWidth * _headWidthFactor;
    final headMargin = strokeWidth * _headMarginFactor;

    final tip = ArrowPathGeometry.headTip(
      head: arrow.position,
      direction: arrow.direction,
      cellWidth: cellWidth,
      cellHeight: cellHeight,
      margin: headMargin,
    );
    final base = ArrowPathGeometry.headBase(
      tip: tip,
      direction: arrow.direction,
      headLength: headLength,
    );

    if (positions.length == 1) {
      _paintArrowHead(canvas, tip: tip, base: base, color: color, headWidth: headWidth);
      return;
    }

    final pathPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final tail = ArrowPathGeometry.cellCenter(
      positions.first,
      cellWidth: cellWidth,
      cellHeight: cellHeight,
    );
    path.moveTo(tail.dx, tail.dy);

    for (var i = 1; i < positions.length - 1; i++) {
      final point = ArrowPathGeometry.cellCenter(
        positions[i],
        cellWidth: cellWidth,
        cellHeight: cellHeight,
      );
      path.lineTo(point.dx, point.dy);
    }
    path.lineTo(base.dx, base.dy);
    canvas.drawPath(path, pathPaint);

    _paintArrowHead(canvas, tip: tip, base: base, color: color, headWidth: headWidth);
  }

  /// Asigna color según el estado de la flecha.
  Color _colorForArrow(Arrow arrow) {
    return switch (arrow.state) {
      ArrowState.blocked => AppColors.arrowBlocked,
      ArrowState.active => AppColors.arrow,
      ArrowState.extracted => AppColors.arrow.withOpacity(0.3),
    };
  }

  /// Dibuja la punta triangular entre [tip] y [base].
  void _paintArrowHead(
    Canvas canvas, {
    required Offset tip,
    required Offset base,
    required Color color,
    required double headWidth,
  }) {
    final axis = tip - base;
    if (axis.distance < 0.001) return;

    final unit = axis / axis.distance;
    final perpendicular = Offset(-unit.dy, unit.dx);

    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(base.dx + perpendicular.dx * headWidth, base.dy + perpendicular.dy * headWidth)
      ..lineTo(base.dx - perpendicular.dx * headWidth, base.dy - perpendicular.dy * headWidth)
      ..close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant ArrowBoardPainter oldDelegate) {
    return oldDelegate.board != board ||
        oldDelegate.cellWidth != cellWidth ||
        oldDelegate.cellHeight != cellHeight;
  }
}
