import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/domain.dart';
import '../../theme/app_colors.dart';
import 'arrow_path_geometry.dart';

/// Pinta muros y flechas con trazo fino, esquinas redondeadas y cabeza integrada.
class ArrowBoardPainter extends CustomPainter {
  /// Crea el painter para [board] con el tamaño de celda ya calculado.
  const ArrowBoardPainter({
    required this.board,
    required this.cellWidth,
    required this.cellHeight,
    this.showGrid = false,
  });

  // Proportions relative to stroke width (itself relative to cell size), not
  // absolute pixels, so the arrow shape stays visually consistent across
  // the wide range of board sizes in the level catalog (currently 5x5 up
  // to much larger boards).
  static const _strokeFactor = 0.12;
  static const _headLengthFactor = 2.8;
  static const _headWidthFactor = 1.0;
  static const _headMarginFactor = 0.5;
  static const _cornerRadiusFactor = 1.4;

  /// Tablero de juego a pintar.
  final Board board;

  /// Ancho de cada celda en píxeles.
  final double cellWidth;

  /// Alto de cada celda en píxeles.
  final double cellHeight;

  /// Si es `true`, dibuja las líneas de la cuadrícula sobre el fondo del tablero.
  final bool showGrid;

  @override
  void paint(Canvas canvas, Size size) {
    if (showGrid) {
      _paintGrid(canvas, size);
    }
    _paintWalls(canvas);
    for (final arrow in board.arrows.where((a) => !a.isExtracted)) {
      _paintArrow(canvas, arrow);
    }
  }

  /// Draws faint grid lines over the board background. Opt-in via [showGrid]
  /// (used by the tutorial overlay to make cell boundaries legible) rather
  /// than always-on, since the grid adds visual noise during normal play
  /// once the player already knows the cell layout.
  void _paintGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gridLine.withValues(alpha: 0.35)
      ..strokeWidth = 0.75;

    for (var column = 0; column <= board.dimension.columns; column++) {
      final x = column * cellWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var row = 0; row <= board.dimension.rows; row++) {
      final y = row * cellHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  /// Draws each wall cell as a small inset rounded square instead of filling
  /// the full cell, so adjacent walls read as separate blocks rather than a
  /// single solid mass.
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

  /// Paints one arrow as a stroked body path plus a filled triangular head.
  ///
  /// A single-segment arrow (no body) has nothing to stroke a path through,
  /// so it short-circuits to just the head triangle instead of calling
  /// [ArrowPathGeometry.buildBodyPath] with a degenerate one-point path.
  void _paintArrow(Canvas canvas, Arrow arrow) {
    final positions = ArrowPathGeometry.tailToHead(arrow);
    if (positions.isEmpty) return;

    final color = _colorForArrow(arrow);
    final strokeWidth = math.min(cellWidth, cellHeight) * _strokeFactor;
    final headLength = strokeWidth * _headLengthFactor;
    final headHalfWidth = strokeWidth * _headWidthFactor;
    final headMargin = strokeWidth * _headMarginFactor;
    final cornerRadius = strokeWidth * _cornerRadiusFactor;

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
      _paintArrowHead(canvas, tip: tip, base: base, color: color, headHalfWidth: headHalfWidth);
      return;
    }

    final bodyPath = ArrowPathGeometry.buildBodyPath(
      positions: positions,
      head: arrow.position,
      cellWidth: cellWidth,
      cellHeight: cellHeight,
      headBase: base,
      cornerRadius: cornerRadius,
    );

    final pathPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(bodyPath, pathPaint);
    _paintArrowHead(canvas, tip: tip, base: base, color: color, headHalfWidth: headHalfWidth);
  }

  /// Maps arrow gameplay state to its display color: blocked arrows are
  /// tinted as a warning, extracted ones fade out instead of disappearing
  /// instantly so the last frame before removal still reads as "this arrow
  /// left the board" rather than a pop.
  Color _colorForArrow(Arrow arrow) {
    return switch (arrow.state) {
      ArrowState.blocked => AppColors.arrowBlocked,
      ArrowState.active => AppColors.arrow,
      ArrowState.extracted => AppColors.arrow.withValues(alpha: 0.3),
    };
  }

  /// Draws the arrowhead as a triangle: [tip] is the point, and [base] is
  /// offset perpendicular to the tip→base axis by `headHalfWidth` on each
  /// side to form the two back corners — this keeps the head correctly
  /// oriented for any of the four cardinal directions without a separate
  /// per-direction code path. Skips drawing if tip and base coincide (a
  /// zero-length axis has no defined perpendicular), which can only happen
  /// for a degenerate/zero-size cell.
  void _paintArrowHead(
    Canvas canvas, {
    required Offset tip,
    required Offset base,
    required Color color,
    required double headHalfWidth,
  }) {
    final axis = tip - base;
    if (axis.distance < 0.001) return;

    final unit = axis / axis.distance;
    final perpendicular = Offset(-unit.dy, unit.dx);

    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        base.dx + perpendicular.dx * headHalfWidth,
        base.dy + perpendicular.dy * headHalfWidth,
      )
      ..lineTo(
        base.dx - perpendicular.dx * headHalfWidth,
        base.dy - perpendicular.dy * headHalfWidth,
      )
      ..close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant ArrowBoardPainter oldDelegate) {
    return oldDelegate.board != board ||
        oldDelegate.cellWidth != cellWidth ||
        oldDelegate.cellHeight != cellHeight ||
        oldDelegate.showGrid != showGrid;
  }
}
