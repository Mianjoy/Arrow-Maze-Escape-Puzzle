import '../../domain/domain.dart';
import '../../infrastructure/http/progress_api_client.dart';
import '../models/auth_session.dart';
import '../models/record_victory_result.dart';

/// Caso de uso: registrar victoria localmente, desbloquear siguiente nivel y sincronizar.
///
/// Actualiza [PlayerProgress] en el repositorio local, desbloquea el nivel siguiente
/// en la secuencia y envía `POST /progress/sync` con el JWT de la sesión activa.
class RecordVictoryUseCase {
  /// Crea el caso de uso con repositorios y cliente HTTP de progreso.
  const RecordVictoryUseCase({
    required IPlayerProgressRepository progressRepository,
    required ILevelRepository levelRepository,
    required ProgressApiClient progressApiClient,
  })  : _progressRepository = progressRepository,
        _levelRepository = levelRepository,
        _progressApiClient = progressApiClient;

  final IPlayerProgressRepository _progressRepository;
  final ILevelRepository _levelRepository;
  final ProgressApiClient _progressApiClient;

  /// Persiste la victoria de [game], desbloquea el siguiente nivel y sincroniza con la API.
  Future<RecordVictoryResult> execute({
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

    final nextLevel = await _findNextLevel(game.level);
    if (nextLevel != null) {
      progress = progress.unlockLevel(nextLevel.id);
    }
    await _progressRepository.save(progress);

    await _progressApiClient.syncProgress(
      session: session,
      levelId: game.level.id.value,
      score: game.score,
      moves: game.moveCount,
      timeInSeconds: game.elapsedSeconds,
      completed: true,
    );

    return RecordVictoryResult(progress: progress, nextLevel: nextLevel);
  }

  /// Obtiene el nivel inmediatamente posterior a [completedLevel] en el catálogo.
  Future<Level?> _findNextLevel(Level completedLevel) async {
    final allLevels = await _levelRepository.findAll();
    final sorted = List<Level>.from(allLevels)
      ..sort((a, b) {
        final an = a.levelNumber ?? 0;
        final bn = b.levelNumber ?? 0;
        if (an != bn) return an.compareTo(bn);
        return a.id.value.compareTo(b.id.value);
      });

    final index = sorted.indexWhere((l) => l.id == completedLevel.id);
    if (index < 0 || index + 1 >= sorted.length) return null;

    return sorted[index + 1];
  }
}
