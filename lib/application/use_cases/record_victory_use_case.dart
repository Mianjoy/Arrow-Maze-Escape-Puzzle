import '../../domain/domain.dart';
import '../../infrastructure/http/progress_api_client.dart';
import '../models/auth_session.dart';

/// Caso de uso: registrar victoria localmente y sincronizar con el backend.
///
/// Actualiza [PlayerProgress] en el repositorio local y envía `POST /progress/sync`
/// con el JWT de la sesión activa.
class RecordVictoryUseCase {
  /// Crea el caso de uso con repositorio local y cliente HTTP de progreso.
  const RecordVictoryUseCase({
    required IPlayerProgressRepository progressRepository,
    required ProgressApiClient progressApiClient,
  })  : _progressRepository = progressRepository,
        _progressApiClient = progressApiClient;

  final IPlayerProgressRepository _progressRepository;
  final ProgressApiClient _progressApiClient;

  /// Persiste la victoria de [game] para [session] y sincroniza con la API.
  Future<void> execute({
    required Game game,
    required AuthSession session,
  }) async {
    final stars = game.starsEarned ?? StarRating.one;
    var progress = await _progressRepository.findByPlayerId(session.playerId) ??
        PlayerProgress(playerId: session.playerId);

    progress = progress.completeLevel(
      levelId: game.level.id,
      moveCount: game.moveCount,
      elapsedSeconds: game.elapsedSeconds,
      starsEarned: stars,
    );
    await _progressRepository.save(progress);

    await _progressApiClient.syncProgress(
      session: session,
      levelId: game.level.id.value,
      score: game.score,
      moves: game.moveCount,
      timeInSeconds: game.elapsedSeconds,
      completed: true,
    );
  }
}
