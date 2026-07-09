import 'package:flutter/material.dart';

import '../../../domain/domain.dart';

/// Renderiza el [Board] de una partida como una cuadrícula, y notifica
/// [onCellTapped] con la [Position] tocada.
///
/// Puramente presentacional: no conoce casos de uso ni el [Game] completo,
/// solo el [Board] a dibujar (matching Clean Architecture — esta clase
/// vive en Interface Adapters / presentación, no en dominio ni aplicación).
class BoardView extends StatelessWidget {
  /// Crea la vista para dibujar [board] y notificar toques vía [onCellTapped].
  const BoardView({super.key, required this.board, required this.onCellTapped});

  /// Tablero a renderizar.
  final Board board;

  /// Callback invocado con la posición de la celda tocada.
  final ValueChanged<Position> onCellTapped;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: board.dimension.columns / board.dimension.rows,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: board.dimension.columns,
        ),
        itemCount: board.cells.length,
        itemBuilder: (context, index) {
          final cell = board.cells[index];
          final arrowId = cell.arrowId;
          final arrow = arrowId != null ? board.arrowById(arrowId) : null;

          return GestureDetector(
            key: ValueKey('cell-${cell.position.row}-${cell.position.column}'),
            onTap: () => onCellTapped(cell.position),
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: _cellColor(context, arrow, cell),
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(4),
              ),
              child: arrow != null
                  ? Transform.rotate(
                      angle: _rotationFor(arrow.direction.arrowDirection),
                      child: const Icon(Icons.arrow_forward),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  /// Asigna color de fondo según tipo de celda y estado de la flecha.
  ///
  /// Muros (wire format) usan un gris del tema; flechas bloqueadas, rojo suave.
  Color? _cellColor(BuildContext context, Arrow? arrow, Cell cell) {
    if (cell.isWall) {
      return Theme.of(context).colorScheme.surfaceContainerHighest;
    }
    if (arrow == null) return null;
    if (arrow.state == ArrowState.blocked) {
      return Theme.of(context).colorScheme.errorContainer;
    }
    return Theme.of(context).colorScheme.primaryContainer;
  }

  /// Convierte la dirección de dominio a radianes para [Transform.rotate].
  double _rotationFor(ArrowDirection direction) {
    return switch (direction) {
      ArrowDirection.right => 0,
      ArrowDirection.down => 1.5708, // pi/2
      ArrowDirection.left => 3.14159, // pi
      ArrowDirection.up => -1.5708, // -pi/2
    };
  }
}
