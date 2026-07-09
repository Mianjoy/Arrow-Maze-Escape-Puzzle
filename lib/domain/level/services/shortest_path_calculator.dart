import '../../board/entities/board.dart';
import '../../board/services/arrow_movement_engine.dart';

/// Servicio de dominio que calcula la cantidad mínima de movimientos
/// para completar un tablero (ruta más corta).
///
/// Utiliza BFS sobre el espacio de estados de las flechas.
class ShortestPathCalculator {
  /// Crea el calculador con un [movementEngine] inyectable.
  const ShortestPathCalculator({required ArrowMovementEngine movementEngine})
      : _movementEngine = movementEngine;

  final ArrowMovementEngine _movementEngine;

  /// Retorna el número mínimo de movimientos para vaciar el [board].
  ///
  /// Si el tablero ya está limpio, retorna 0.
  /// Si no existe solución, retorna `null`.
  int? calculateMinimumMoves(Board board) {
    if (board.isCleared) return 0;

    final visited = <String>{};
    final queue = <_SearchNode>[];

    queue.add(_SearchNode(board: board, moves: 0));
    visited.add(_stateKey(board));

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);

      if (current.board.isCleared) {
        return current.moves;
      }

      for (final arrow in current.board.arrows.where((a) => a.isMovable)) {
        final outcome = _movementEngine.attemptMove(
          board: current.board,
          arrowId: arrow.id,
        );

        final key = _stateKey(outcome.board);
        if (visited.contains(key)) continue;

        visited.add(key);
        queue.add(_SearchNode(board: outcome.board, moves: current.moves + 1));
      }
    }

    return null;
  }

  String _stateKey(Board board) {
    final parts = board.arrows
        .map((a) => '${a.id.value}:${a.state.name}:${a.position}')
        .toList()
      ..sort();
    return parts.join('|');
  }
}

class _SearchNode {
  const _SearchNode({required this.board, required this.moves});

  final Board board;
  final int moves;
}
