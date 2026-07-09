import '../../domain/domain.dart';

/// Caso de uso: iniciar una nueva partida a partir de un nivel ya cargado.
///
/// Construye el [Game] inicial vía [Game.fromLevel], lo transiciona a
/// `inProgress` con [Game.start], y lo persiste vía [IGameRepository].
class StartGameUseCase {
  /// Crea el caso de uso con el [gameRepository] donde persistir la partida.
  const StartGameUseCase({required IGameRepository gameRepository})
      : _gameRepository = gameRepository;

  final IGameRepository _gameRepository;

  /// Inicia y persiste una nueva partida sobre [level] para [playerId],
  /// identificada por [gameId]; retorna el [Game] ya en progreso.
  Future<Game> execute({
    required Identifier gameId,
    required Identifier playerId,
    required Level level,
  }) async {
    final game = Game.fromLevel(
      gameId: gameId,
      playerId: playerId,
      level: level,
    ).start();

    await _gameRepository.save(game);
    return game;
  }
}
