import 'package:flutter/material.dart';

import '../../../domain/domain.dart';
import '../../theme/app_colors.dart';
import 'arrow_board_painter.dart';

/// Renderiza el [Board] con fondo liso, muros y flechas de trazo continuo.
///
/// Separa la capa visual ([ArrowBoardPainter]) de la capa de toques invisible
/// para que flechas multi-celda se dibujen como un solo camino.
class BoardView extends StatelessWidget {
  /// Crea la vista para [board] y notificar toques con [onCellTapped].
  const BoardView({
    super.key,
    required this.board,
    required this.onCellTapped,
    this.showGrid = false,
    this.overlayBuilder,
  });

  /// Tablero a renderizar.
  final Board board;

  /// Callback con la [Position] de la celda tocada.
  final ValueChanged<Position> onCellTapped;

  /// Si es `true`, dibuja las líneas de la cuadrícula sobre el fondo del tablero.
  final bool showGrid;

  /// Construye una capa opcional sobre el tablero (p. ej. el tutorial
  /// interactivo) usando el mismo `cellWidth`/`cellHeight` ya calculados,
  /// para que cualquier resaltado quede alineado con las celdas reales.
  final Widget Function(double cellWidth, double cellHeight)? overlayBuilder;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: board.dimension.columns / board.dimension.rows,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.boardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.sand.withValues(alpha: 0.6)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cellWidth = constraints.maxWidth / board.dimension.columns;
                final cellHeight = constraints.maxHeight / board.dimension.rows;

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: ArrowBoardPainter(
                        board: board,
                        cellWidth: cellWidth,
                        cellHeight: cellHeight,
                        showGrid: showGrid,
                      ),
                    ),
                    _BoardTouchGrid(
                      board: board,
                      cellWidth: cellWidth,
                      cellHeight: cellHeight,
                      onCellTapped: onCellTapped,
                    ),
                    if (overlayBuilder != null) overlayBuilder!(cellWidth, cellHeight),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón compacto para activar o desactivar la cuadrícula del tablero.
class BoardGridToggleButton extends StatelessWidget {
  /// Crea el botón con [showGrid], [tooltip] y [onPressed].
  const BoardGridToggleButton({
    super.key,
    required this.showGrid,
    required this.tooltip,
    required this.onPressed,
  });

  /// Indica si la cuadrícula está visible (icono `grid_off` vs `grid_on`).
  final bool showGrid;

  /// Texto del tooltip al mantener pulsado.
  final String tooltip;

  /// Se invoca al pulsar el botón.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(8),
      child: IconButton(
        key: const ValueKey('board-grid-toggle'),
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.all(4),
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        tooltip: tooltip,
        icon: Icon(
          showGrid ? Icons.grid_off : Icons.grid_on,
          size: 18,
          color: showGrid ? AppColors.arrowActive : AppColors.textPrimary,
        ),
        onPressed: onPressed,
      ),
    );
  }
}

/// Botón compacto para reiniciar el nivel actual desde la pantalla de juego.
class BoardRestartButton extends StatelessWidget {
  /// Crea el botón con [tooltip] y [onPressed].
  const BoardRestartButton({
    super.key,
    required this.tooltip,
    required this.onPressed,
  });

  /// Texto del tooltip al mantener pulsado.
  final String tooltip;

  /// Se invoca al pulsar el botón.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(8),
      child: IconButton(
        key: const ValueKey('board-restart'),
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.all(4),
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        tooltip: tooltip,
        icon: const Icon(
          Icons.replay,
          size: 18,
          color: AppColors.arrowBlocked,
        ),
        onPressed: onPressed,
      ),
    );
  }
}

/// Capa invisible de detección de toques, una celda por hijo del [Stack].
///
/// Mantiene las `ValueKey('cell-row-col')` que usan los tests de widget.
class _BoardTouchGrid extends StatelessWidget {
  const _BoardTouchGrid({
    required this.board,
    required this.cellWidth,
    required this.cellHeight,
    required this.onCellTapped,
  });

  final Board board;
  final double cellWidth;
  final double cellHeight;
  final ValueChanged<Position> onCellTapped;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (final cell in board.cells)
          Positioned(
            left: cell.position.column * cellWidth,
            top: cell.position.row * cellHeight,
            width: cellWidth,
            height: cellHeight,
            child: GestureDetector(
              key: ValueKey('cell-${cell.position.row}-${cell.position.column}'),
              behavior: HitTestBehavior.translucent,
              onTap: () => onCellTapped(cell.position),
            ),
          ),
      ],
    );
  }
}
