import '../board/value_objects/move_result.dart';
import '../shared/value_objects/identifier.dart';
import '../shared/value_objects/position.dart';
import 'cube_path_arrow.dart';
import 'cube_surface_board.dart';
import 'cube_surface_position.dart';

/// Resultado de disparar en la superficie del cubo.
typedef CubeSurfaceMoveOutcome = ({CubeSurfaceBoard board, MoveResult result});

/// Motor: al tocar una flecha, sale por [CubeSurfaceBoard.escapePoint] si la ruta está libre.
class CubePathMovementEngine {
  /// Crea el motor de disparo multi-cara.
  const CubePathMovementEngine();

  /// Intenta disparar la flecha en [position] (punta o cuerpo).
  CubeSurfaceMoveOutcome attemptFireAt({
    required CubeSurfaceBoard board,
    required CubeSurfacePosition position,
  }) {
    final arrow = board.arrowAt(position);
    if (arrow == null) {
      return (board: board, result: MoveResult.noArrowAtCell());
    }
    return attemptFire(board: board, arrowId: arrow.id);
  }

  /// Intenta disparar la flecha [arrowId]; sale por el escape si no hay bloqueo.
  CubeSurfaceMoveOutcome attemptFire({
    required CubeSurfaceBoard board,
    required Identifier arrowId,
  }) {
    final arrow = board.arrowById(arrowId);
    final blocking = _findBlockingCell(board: board, arrow: arrow);
    if (blocking != null) {
      return (
        board: board,
        result: MoveResult.blocked(
          arrowId: arrowId,
          blockingPosition: Position(row: blocking.row, column: blocking.column),
        ),
      );
    }
    return (
      board: board.withoutArrow(arrowId),
      result: MoveResult.extracted(arrowId: arrowId),
    );
  }

  /// Primera celda de [arrow.escapeRoute] ocupada por otra flecha.
  CubeSurfacePosition? _findBlockingCell({
    required CubeSurfaceBoard board,
    required CubePathArrow arrow,
  }) {
    for (final cell in arrow.escapeRoute) {
      final occupant = board.arrowAt(cell);
      if (occupant != null && occupant.id != arrow.id) {
        return cell;
      }
    }
    return null;
  }
}
