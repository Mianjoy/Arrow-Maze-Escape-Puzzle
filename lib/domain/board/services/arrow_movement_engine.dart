import '../entities/board.dart';
import '../entities/arrow.dart';
import '../events/arrow_blocked_event.dart';
import '../events/arrow_extracted_event.dart';
import '../value_objects/arrow_state.dart';
import '../value_objects/move_result.dart';
import '../../shared/exceptions/invalid_move_exception.dart';
import '../../shared/value_objects/identifier.dart';
import '../../shared/value_objects/position.dart';
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

  /// Intenta mover la flecha ubicada en [position] de [board].
  ///
  /// Portado desde el dominio en español (`sinFlecha` de
  /// `ResultadoMovimiento` en la rama `Integracion`): si la celda tocada no
  /// tiene ninguna flecha, retorna [MoveResult.noArrowAtCell] en vez de
  /// lanzar una excepción. Si sí hay flecha, delega en [attemptMove].
  ({Board board, MoveResult result}) attemptMoveAt({
    required Board board,
    required Position position,
  }) {
    final arrowId = board.arrowIdAt(position);
    if (arrowId == null) {
      return (board: board, result: MoveResult.noArrowAtCell());
    }
    return attemptMove(board: board, arrowId: arrowId);
  }

  /// Intenta mover la flecha identificada por [arrowId] en [board].
  ///
  /// Retorna un par con el [Board] actualizado y el [MoveResult]. Además de
  /// mutar el estado de la flecha/celda, registra el evento de dominio
  /// correspondiente ([ArrowBlockedEvent] o [ArrowExtractedEvent]) en el
  /// tablero devuelto (ver [Board.domainEvents]).
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
      final updatedBoard = board.applyArrowUpdate(blockedArrow).withDomainEvent(
            ArrowBlockedEvent(
              arrowId: arrowId,
              blockingPosition: blockingPosition,
              occurredAt: DateTime.now().toUtc(),
            ),
          );
      return (
        board: updatedBoard,
        result: MoveResult.blocked(
          arrowId: arrowId,
          blockingPosition: blockingPosition,
        ),
      );
    }

    final extractedArrow = arrow.copyWith(state: ArrowState.extracted);
    final updatedBoard = board
        .applyArrowUpdate(extractedArrow, clearCell: true)
        .withDomainEvent(
          ArrowExtractedEvent(
            arrowId: arrowId,
            position: arrow.position,
            occurredAt: DateTime.now().toUtc(),
          ),
        );

    return (
      board: updatedBoard,
      result: MoveResult.extracted(arrowId: arrowId),
    );
  }
}
