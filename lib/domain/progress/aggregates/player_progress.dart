import 'package:meta/meta.dart';

import '../../level/value_objects/star_rating.dart';
import '../../shared/value_objects/identifier.dart';
import '../value_objects/level_progress.dart';
import '../value_objects/level_progress_status.dart';

/// Agregado raíz del progreso de un jugador a través de los niveles.
@immutable
class PlayerProgress {
  /// Crea el progreso con [playerId], mapa de [levels] y [unlockedCollectibles].
  PlayerProgress({
    required this.playerId,
    Map<Identifier, LevelProgress>? levels,
    Set<String>? unlockedCollectibles,
  })  : _levels = Map.unmodifiable(levels ?? {}),
        _unlockedCollectibles = Set.unmodifiable(unlockedCollectibles ?? {});

  /// Identificador del jugador propietario del progreso.
  final Identifier playerId;

  final Map<Identifier, LevelProgress> _levels;
  final Set<String> _unlockedCollectibles;

  /// Vista de solo lectura del progreso por nivel.
  Map<Identifier, LevelProgress> get levels => _levels;

  /// Identificadores de coleccionables meta ya desbloqueados.
  Set<String> get unlockedCollectibles => _unlockedCollectibles;

  /// Indica si el coleccionable [collectibleId] ya fue desbloqueado.
  bool hasCollectible(String collectibleId) => _unlockedCollectibles.contains(collectibleId);

  /// Obtiene el progreso de un nivel o `null` si no existe registro.
  LevelProgress? progressFor(Identifier levelId) => _levels[levelId];

  /// Desbloquea un nivel en el mapa de progreso.
  PlayerProgress unlockLevel(Identifier levelId) {
    final current = _levels[levelId];
    final updated = (current ?? LevelProgress(levelId: levelId, status: LevelProgressStatus.locked))
        .unlock();

    return PlayerProgress(
      playerId: playerId,
      levels: {..._levels, levelId: updated},
      unlockedCollectibles: _unlockedCollectibles,
    );
  }

  /// Registra el desbloqueo de un coleccionable meta por [collectibleId].
  PlayerProgress unlockCollectible(String collectibleId) {
    if (_unlockedCollectibles.contains(collectibleId)) return this;

    return PlayerProgress(
      playerId: playerId,
      levels: _levels,
      unlockedCollectibles: {..._unlockedCollectibles, collectibleId},
    );
  }

  /// Fusiona el progreso remoto de un nivel (descargado del servidor) con el
  /// local, conservando lo mejor de cada uno.
  ///
  /// Reglas: el estado nunca retrocede (si local ya está `completed`, sigue
  /// `completed`; si el remoto dice completado, se marca `completed`); se toma
  /// el mínimo de movimientos y tiempo. El servidor no persiste estrellas, así
  /// que si el remoto marca completado y localmente no había estrellas, se usa
  /// [StarRating.one] como mínimo; si local ya tenía mejores, se conservan.
  PlayerProgress mergeRemoteLevel({
    required Identifier levelId,
    int? remoteBestMoveCount,
    int? remoteBestTimeSeconds,
    required bool remoteCompleted,
  }) {
    final current = _levels[levelId];

    final mergedStatus = current?.status == LevelProgressStatus.completed || remoteCompleted
        ? LevelProgressStatus.completed
        : (current?.status ?? LevelProgressStatus.unlocked);

    final mergedMoves = _minNullable(current?.bestMoveCount, remoteBestMoveCount);
    final mergedTime = _minNullable(current?.bestTimeSeconds, remoteBestTimeSeconds);

    final mergedStars = mergedStatus == LevelProgressStatus.completed
        ? StarRating.bestOf(current?.bestStars, StarRating.one)
        : current?.bestStars;

    return PlayerProgress(
      playerId: playerId,
      levels: {
        ..._levels,
        levelId: LevelProgress(
          levelId: levelId,
          status: mergedStatus,
          bestMoveCount: mergedMoves,
          bestTimeSeconds: mergedTime,
          bestStars: mergedStars,
          completionCount: current?.completionCount ?? 0,
        ),
      },
      unlockedCollectibles: _unlockedCollectibles,
    );
  }

  /// Devuelve el menor de dos valores que pueden ser nulos (nulo = sin dato).
  static int? _minNullable(int? a, int? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a < b ? a : b;
  }

  /// Fusiona coleccionables desbloqueados descargados del servidor (unión).
  PlayerProgress mergeRemoteCollectibles(Set<String> remoteCollectibleIds) {
    if (remoteCollectibleIds.isEmpty) return this;

    return PlayerProgress(
      playerId: playerId,
      levels: _levels,
      unlockedCollectibles: {..._unlockedCollectibles, ...remoteCollectibleIds},
    );
  }

  /// Registra la completitud de un nivel con métricas de desempeño y estrellas.
  PlayerProgress completeLevel({
    required Identifier levelId,
    required int moveCount,
    required int elapsedSeconds,
    required StarRating starsEarned,
  }) {
    final current = _levels[levelId] ??
        LevelProgress(levelId: levelId, status: LevelProgressStatus.unlocked);

    final updated = current.recordCompletion(
      moveCount: moveCount,
      elapsedSeconds: elapsedSeconds,
      starsEarned: starsEarned,
    );

    return PlayerProgress(
      playerId: playerId,
      levels: {..._levels, levelId: updated},
      unlockedCollectibles: _unlockedCollectibles,
    );
  }
}
