import '../../domain/domain.dart';

/// Caso de uso: inicializar progreso desbloqueando el primer nivel del catálogo.
///
/// Si el jugador no tiene progreso guardado, crea uno nuevo con el nivel de
/// menor [Level.levelNumber] desbloqueado; el resto queda bloqueado.
class EnsureInitialProgressUseCase {
  /// Crea el caso de uso con repositorios de niveles y progreso.
  const EnsureInitialProgressUseCase({
    required ILevelRepository levelRepository,
    required IPlayerProgressRepository progressRepository,
  })  : _levelRepository = levelRepository,
        _progressRepository = progressRepository;

  final ILevelRepository _levelRepository;
  final IPlayerProgressRepository _progressRepository;

  /// Garantiza progreso existente para [playerId] y devuelve el agregado actual.
  Future<PlayerProgress> execute(Identifier playerId) async {
    final existing = await _progressRepository.findByPlayerId(playerId);
    if (existing != null) return existing;

    final levels = await _levelRepository.findAll();
    if (levels.isEmpty) {
      final empty = PlayerProgress(playerId: playerId);
      await _progressRepository.save(empty);
      return empty;
    }

    final sorted = _sortByLevelNumber(levels);
    var progress = PlayerProgress(playerId: playerId);

    for (final level in sorted) {
      progress = progress.unlockLevel(level.id);
      break; // Solo el primero desbloqueado; los demás quedan sin entrada = locked implícito
    }

    // Marcar explícitamente los demás como locked creando entradas
    for (var i = 1; i < sorted.length; i++) {
      final level = sorted[i];
      progress = PlayerProgress(
        playerId: playerId,
        levels: {
          ...progress.levels,
          level.id: LevelProgress(levelId: level.id, status: LevelProgressStatus.locked),
        },
      );
    }

    await _progressRepository.save(progress);
    return progress;
  }

  /// Ordena niveles por [Level.levelNumber] (fallback al id si falta).
  List<Level> _sortByLevelNumber(List<Level> levels) {
    final copy = List<Level>.from(levels);
    copy.sort((a, b) {
      final an = a.levelNumber ?? 0;
      final bn = b.levelNumber ?? 0;
      if (an != bn) return an.compareTo(bn);
      return a.id.value.compareTo(b.id.value);
    });
    return copy;
  }
}
