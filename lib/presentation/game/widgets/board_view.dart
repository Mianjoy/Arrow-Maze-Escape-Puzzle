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
  const BoardView({super.key, required this.board, required this.onCellTapped});

  /// Tablero a renderizar.
  final Board board;

  /// Callback con la [Position] de la celda tocada.
  final ValueChanged<Position> onCellTapped;

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
            border: Border.all(color: AppColors.sand.withOpacity(0.6)),
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
                      ),
                    ),
                    _BoardTouchGrid(
                      board: board,
                      cellWidth: cellWidth,
                      cellHeight: cellHeight,
                      onCellTapped: onCellTapped,
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
