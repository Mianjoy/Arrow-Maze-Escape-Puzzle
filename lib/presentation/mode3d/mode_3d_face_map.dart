import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import 'mode_3d_catalog.dart';

/// Mapa 2D del cubo (net): las 6 caras 3×3; tocar una celda dispara la flecha.
class Mode3dFaceMap extends StatelessWidget {
  /// Crea el mapa interactivo con el [board] actual.
  const Mode3dFaceMap({
    super.key,
    required this.board,
    required this.onCellTap,
  });

  /// Estado actual de la superficie.
  final CubeSurfaceBoard board;

  /// Se invoca al tocar una celda del mapa.
  final ValueChanged<CubeSurfacePosition> onCellTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppStringsScope.of(context);
    final escape = board.escapePoint.position;

    return Container(
      key: const ValueKey('mode3d-face-map'),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.boardSurface,
        border: Border(top: BorderSide(color: AppColors.sand.withValues(alpha: 0.8))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            strings.mode3dFaceMapTitle,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            strings.mode3dFaceMapHint,
            style: TextStyle(
              color: AppColors.textPrimary.withValues(alpha: 0.65),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final cell = (constraints.maxWidth / 12).clamp(18.0, 28.0);
              const gap = 4.0;

              Widget faceAt(Face face) => _FaceGrid(
                    face: face,
                    board: board,
                    escape: escape,
                    cellSize: cell,
                    gap: gap,
                    onCellTap: onCellTap,
                  );

              return FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [faceAt(Face.top)],
                    ),
                    const SizedBox(height: gap),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        faceAt(Face.left),
                        const SizedBox(width: gap),
                        faceAt(Face.front),
                        const SizedBox(width: gap),
                        faceAt(Face.right),
                        const SizedBox(width: gap),
                        faceAt(Face.back),
                      ],
                    ),
                    const SizedBox(height: gap),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [faceAt(Face.bottom)],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FaceGrid extends StatelessWidget {
  const _FaceGrid({
    required this.face,
    required this.board,
    required this.escape,
    required this.cellSize,
    required this.gap,
    required this.onCellTap,
  });

  final Face face;
  final CubeSurfaceBoard board;
  final CubeSurfacePosition escape;
  final double cellSize;
  final double gap;
  final ValueChanged<CubeSurfacePosition> onCellTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          face.name.toUpperCase(),
          style: TextStyle(
            color: AppColors.textPrimary.withValues(alpha: 0.55),
            fontSize: 9,
            letterSpacing: 0.4,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Column(
          children: [
            for (var row = 0; row < kMode3dFaceSize; row++) ...[
              if (row > 0) SizedBox(height: gap),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var col = 0; col < kMode3dFaceSize; col++) ...[
                    if (col > 0) SizedBox(width: gap),
                    _MapCell(
                      position: CubeSurfacePosition(face: face, row: row, column: col),
                      board: board,
                      escape: escape,
                      size: cellSize,
                      onTap: onCellTap,
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _MapCell extends StatelessWidget {
  const _MapCell({
    required this.position,
    required this.board,
    required this.escape,
    required this.size,
    required this.onTap,
  });

  final CubeSurfacePosition position;
  final CubeSurfaceBoard board;
  final CubeSurfacePosition escape;
  final double size;
  final ValueChanged<CubeSurfacePosition> onTap;

  Color _colorForFace(Face face) => switch (face) {
        Face.front => const Color(0xFF43A047),
        Face.back => const Color(0xFF1E88E5),
        Face.left => const Color(0xFFFB8C00),
        Face.right => const Color(0xFFE53935),
        Face.top => const Color(0xFFF5F5F5),
        Face.bottom => const Color(0xFFFDD835),
      };

  @override
  Widget build(BuildContext context) {
    final arrow = board.arrowAt(position);
    final isEscape = position == escape;
    final isTip = arrow != null && arrow.tip == position;

    Color fill = _colorForFace(position.face);
    if (isEscape) fill = const Color(0xFFFFC107);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('map-cell-${position.face.name}-${position.row}-${position.column}'),
        onTap: () => onTap(position),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF20242B), width: 1.5),
          ),
          child: arrow == null
              ? (isEscape
                  ? const Icon(Icons.logout, size: 12, color: Colors.white)
                  : null)
              : CustomPaint(
                  painter: _FlatArrowPainter(
                    direction: arrow.direction.arrowDirection,
                    isTip: isTip,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Dibuja un cuerpo plano o una punta triangular plana según la dirección.
class _FlatArrowPainter extends CustomPainter {
  _FlatArrowPainter({required this.direction, required this.isTip});

  final ArrowDirection direction;
  final bool isTip;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF171A1F)
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final s = size.shortestSide * 0.32;

    if (!isTip) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy), width: s * 1.35, height: s * 0.7),
          const Radius.circular(2),
        ),
        paint,
      );
      return;
    }

    final path = Path();
    switch (direction) {
      case ArrowDirection.up:
        path.moveTo(cx, cy - s);
        path.lineTo(cx + s, cy + s * 0.6);
        path.lineTo(cx - s, cy + s * 0.6);
      case ArrowDirection.down:
        path.moveTo(cx, cy + s);
        path.lineTo(cx + s, cy - s * 0.6);
        path.lineTo(cx - s, cy - s * 0.6);
      case ArrowDirection.left:
        path.moveTo(cx - s, cy);
        path.lineTo(cx + s * 0.6, cy - s);
        path.lineTo(cx + s * 0.6, cy + s);
      case ArrowDirection.right:
        path.moveTo(cx + s, cy);
        path.lineTo(cx - s * 0.6, cy - s);
        path.lineTo(cx - s * 0.6, cy + s);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _FlatArrowPainter oldDelegate) =>
      oldDelegate.direction != direction || oldDelegate.isTip != isTip;
}
