import '../aggregates/board.dart';
import '../entities/arrow.dart';
import '../value_objects/arrow_state.dart';
import '../value_objects/move_result.dart';
import '../../shared/exceptions/invalid_move_exception.dart';
import '../../shared/value_objects/identifier.dart';
import 'i_collision_validator.dart';

/// Servicio de dominio que orquesta el movimiento de flechas.
///
/// Aplica las reglas de negocio: solo flechas activas pueden moverse,
/// se validan colisiones y se determina si la flecha es extraída o bloqueada.
class ArrowMovementEngine {
  /// Crea el motor con un [collisionValidator] inyectable.
  const ArrowMovementEngine({required ICollisionValidator collisionValidator})
      : _collisionValidator = collisionValidator;

  final ICollisionValidator _collisionValidator;

  /// Intenta mover la flecha identificada por [arrowId] en [board].
  ///
  /// Retorna un par con el [Board] actualizado y el [MoveResult].
  /// Lanza [InvalidMoveException] si la flecha no existe o no es movible.
  ({Board board, MoveResult result}) attemptMove({
    required Board board,
    required Identifier arrowId,
  }) {
    final arrow = board.arrowById(arrowId);

    if (!arrow.isMovable) {
      throw InvalidMoveException(
        'Arrow $arrowId cannot be moved (state: ${arrow.state}).',
      );
    }

    final blockingPosition = _collisionValidator.findBlockingPosition(
      board: board,
      arrow: arrow,
    );

    if (blockingPosition != null) {
      final blockedArrow = arrow.copyWith(state: ArrowState.blocked);
      final updatedBoard = board.applyArrowUpdate(blockedArrow);
      return (
        board: updatedBoard,
        result: MoveResult.blocked(
          arrowId: arrowId,
          blockingPosition: blockingPosition,
        ),
      );
    }

    final extractedArrow = arrow.copyWith(state: ArrowState.extracted);
    final updatedBoard = board.applyArrowUpdate(
      extractedArrow,
      clearCell: true,
    );

    return (
      board: updatedBoard,
      result: MoveResult.extracted(arrowId: arrowId),
    );
  }
}
