import 'package:flutter/material.dart';

import '../../../domain/domain.dart';
import '../../../l10n/app_strings.dart';
import '../../theme/app_colors.dart';
import 'arrow_board_painter.dart';

/// Renderiza el [Board] con fondo liso, muros y flechas de trazo continuo.
///
/// Separa la capa visual ([ArrowBoardPainter]) de la capa de toques invisible
/// para que flechas multi-celda se dibujen como un solo camino. Incluye un
/// botón local para mostrar u ocultar la cuadrícula (solo afecta esta vista).
class BoardView extends StatefulWidget {
  /// Crea la vista para [board] y notificar toques con [onCellTapped].
  const BoardView({super.key, required this.board, required this.onCellTapped});

  /// Tablero a renderizar.
  final Board board;

  /// Callback con la [Position] de la celda tocada.
  final ValueChanged<Position> onCellTapped;

  @override
  State<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<BoardView> {
  bool _showGrid = false;

  @override
  Widget build(BuildContext context) {
    final strings = AppStringsScope.of(context);

    return AspectRatio(
      aspectRatio: widget.board.dimension.columns / widget.board.dimension.rows,
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
                final cellWidth = constraints.maxWidth / widget.board.dimension.columns;
                final cellHeight = constraints.maxHeight / widget.board.dimension.rows;

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: ArrowBoardPainter(
                        board: widget.board,
                        cellWidth: cellWidth,
                        cellHeight: cellHeight,
                        showGrid: _showGrid,
                      ),
                    ),
                    _BoardTouchGrid(
                      board: widget.board,
                      cellWidth: cellWidth,
                      cellHeight: cellHeight,
                      onCellTapped: widget.onCellTapped,
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: _GridToggleButton(
                        showGrid: _showGrid,
                        tooltip: _showGrid ? strings.hideGridTooltip : strings.showGridTooltip,
                        onPressed: () => setState(() => _showGrid = !_showGrid),
                      ),
                    ),
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
class _GridToggleButton extends StatelessWidget {
  const _GridToggleButton({
    required this.showGrid,
    required this.tooltip,
    required this.onPressed,
  });

  final bool showGrid;
  final String tooltip;
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
