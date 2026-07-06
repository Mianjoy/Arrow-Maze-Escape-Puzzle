import 'package:meta/meta.dart';

import '../../shared/value_objects/identifier.dart';
import '../value_objects/level_progress.dart';
import '../value_objects/level_progress_status.dart';

/// Agregado raíz del progreso de un jugador a través de los niveles.
@immutable
class PlayerProgress {
  /// Crea el progreso con [playerId] y mapa de [levels].
  PlayerProgress({
    required this.playerId,
    Map<Identifier, LevelProgress>? levels,
  }) : _levels = Map.unmodifiable(levels ?? {});

  /// Identificador del jugador propietario del progreso.
  final Identifier playerId;

  final Map<Identifier, LevelProgress> _levels;

  /// Vista de solo lectura del progreso por nivel.
  Map<Identifier, LevelProgress> get levels => _levels;

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
    );
  }

  /// Registra la completitud de un nivel con métricas de desempeño.
  PlayerProgress completeLevel({
    required Identifier levelId,
    required int moveCount,
    required int elapsedSeconds,
  }) {
    final current = _levels[levelId] ??
        LevelProgress(levelId: levelId, status: LevelProgressStatus.unlocked);

    final updated = current.recordCompletion(
      moveCount: moveCount,
      elapsedSeconds: elapsedSeconds,
    );

    return PlayerProgress(
      playerId: playerId,
      levels: {..._levels, levelId: updated},
    );
  }
}
