import '../../domain/domain.dart';

/// Contrato del caso de uso de disparo, extraído para permitir decorarlo
/// (p. ej. [LoggingFireArrowUseCaseDecorator]) sin que [GameController]
/// dependa de la implementación concreta.
abstract interface class IFireArrowUseCase {
  /// Intenta disparar la flecha en [position] sobre [game]; retorna el
  /// [Game] resultante y el [MoveResult] del intento.
  Future<({Game game, MoveResult result})> execute({
    required Game game,
    required Position position,
  });
}

/// Caso de uso: intentar disparar la flecha (si existe) en la celda tocada.
///
/// Si la celda está vacía, no muta el dominio (retorna el mismo [Game] con
/// [MoveResult.noArrowAtCell]) — evita que la capa de presentación tenga que
/// distinguir "toqué una celda vacía" de un movimiento real.
///
/// Si la celda tiene una flecha (incluida una previamente bloqueada, que
/// sigue siendo movible), delega en [Game.performMove], que evalúa la
/// colisión de nuevo: la flecha se extrae si su trayectoria ya está libre, o
/// vuelve a quedar bloqueada si no. En ambos casos cuenta como un
/// movimiento (regla de juego del equipo).
class FireArrowUseCase implements IFireArrowUseCase {
  /// Crea el caso de uso con el [gameRepository] donde persistir la partida
  /// y, opcionalmente, un [movementEngine] (por defecto uno con validación
  /// de colisiones estándar).
  const FireArrowUseCase({
    required IGameRepository gameRepository,
    ArrowMovementEngine? movementEngine,
  })  : _gameRepository = gameRepository,
        _movementEngine = movementEngine ??
            const ArrowMovementEngine(collisionValidator: CollisionValidator());

  final IGameRepository _gameRepository;
  final ArrowMovementEngine _movementEngine;

  @override
  Future<({Game game, MoveResult result})> execute({
    required Game game,
    required Position position,
  }) async {
    final arrowId = game.board.arrowIdAt(position);
    if (arrowId == null) {
      return (game: game, result: MoveResult.noArrowAtCell());
    }

    final outcome = game.performMove(
      arrowId: arrowId,
      movementEngine: _movementEngine,
    );

    await _gameRepository.save(outcome.game);
    return outcome;
  }
}
