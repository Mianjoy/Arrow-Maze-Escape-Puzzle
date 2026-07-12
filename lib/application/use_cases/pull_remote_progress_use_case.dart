import '../../domain/domain.dart';
import '../models/auth_session.dart';
import '../ports/i_progress_api_client.dart';

/// Caso de uso: descargar el progreso del jugador desde el servidor y
/// fusionarlo con el progreso local (best-of por nivel).
///
/// Permite que, al iniciar sesión desde un dispositivo o sesión nueva, el
/// jugador recupere los niveles ya completados/desbloqueados que viven en el
/// servidor. Es best-effort: si no hay red, se propaga el error para que el
/// llamador lo trate como "modo sin conexión" sin bloquear el juego.
class PullRemoteProgressUseCase {
  /// Crea el caso de uso con el cliente HTTP y los repositorios necesarios.
  const PullRemoteProgressUseCase({
    required IProgressApiClient progressApiClient,
    required IPlayerProgressRepository progressRepository,
    required ILevelRepository levelRepository,
  })  : _progressApiClient = progressApiClient,
        _progressRepository = progressRepository,
        _levelRepository = levelRepository;

  final IProgressApiClient _progressApiClient;
  final IPlayerProgressRepository _progressRepository;
  final ILevelRepository _levelRepository;

  /// Descarga el progreso remoto de [session] y lo fusiona con el local.
  ///
  /// Lanza si la red falla (el llamador decide si tratarlo como offline).
  Future<PlayerProgress> execute(AuthSession session) async {
    final remote = await _progressApiClient.fetchProgress(session);

    var progress = await _progressRepository.findByPlayerId(session.playerId) ??
        PlayerProgress(playerId: session.playerId);

    for (final remoteLevel in remote.levels) {
      final levelId = Identifier(remoteLevel.levelId);
      progress = progress.mergeRemoteLevel(
        levelId: levelId,
        remoteBestMoveCount: remoteLevel.minMoves,
        remoteBestTimeSeconds: remoteLevel.minTimeInSeconds,
        remoteCompleted: remoteLevel.isCompleted,
      );

      // Mantener la cadena de progresión: si un nivel quedó completado, su
      // sucesor en el catálogo debe estar desbloqueado.
      if (remoteLevel.isCompleted) {
        final next = await _findNextLevel(levelId);
        if (next != null) {
          progress = progress.unlockLevel(next.id);
        }
      }
    }

    progress = progress.mergeRemoteCollectibles(remote.collectibles.toSet());
    await _progressRepository.save(progress);
    return progress;
  }

  /// Nivel inmediatamente posterior a [levelId] en orden de catálogo.
  Future<Level?> _findNextLevel(Identifier levelId) async {
    final levels = await _levelRepository.findAll();
    final sorted = List<Level>.from(levels)
      ..sort((a, b) {
        final an = a.levelNumber ?? 0;
        final bn = b.levelNumber ?? 0;
        if (an != bn) return an.compareTo(bn);
        return a.id.value.compareTo(b.id.value);
      });

    final index = sorted.indexWhere((l) => l.id == levelId);
    if (index < 0 || index + 1 >= sorted.length) return null;
    return sorted[index + 1];
  }
}
