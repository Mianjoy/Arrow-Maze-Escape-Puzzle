import 'package:meta/meta.dart';

import '../../level/value_objects/star_rating.dart';
import '../../shared/value_objects/identifier.dart';
import 'level_progress_status.dart';

/// Value object que captura el progreso de un jugador en un nivel concreto.
@immutable
class LevelProgress {
  /// Crea el progreso para [levelId] con [status] y métricas opcionales.
  const LevelProgress({
    required this.levelId,
    required this.status,
    this.bestMoveCount,
    this.bestTimeSeconds,
    this.bestStars,
    this.completionCount = 0,
  });

  /// Identificador del nivel.
  final Identifier levelId;

  /// Estado de desbloqueo/completitud.
  final LevelProgressStatus status;

  /// Menor cantidad de movimientos lograda.
  final int? bestMoveCount;

  /// Mejor tiempo en segundos.
  final int? bestTimeSeconds;

  /// Mejor calificación en estrellas obtenida.
  final StarRating? bestStars;

  /// Veces que el jugador completó el nivel.
  final int completionCount;

  /// Registra una nueva completitud y actualiza récords.
  LevelProgress recordCompletion({
    required int moveCount,
    required int elapsedSeconds,
    required StarRating starsEarned,
  }) {
    final newBestMoves = bestMoveCount == null
        ? moveCount
        : (moveCount < bestMoveCount! ? moveCount : bestMoveCount);

    final newBestTime = bestTimeSeconds == null
        ? elapsedSeconds
        : (elapsedSeconds < bestTimeSeconds! ? elapsedSeconds : bestTimeSeconds);

    final newBestStars = StarRating.bestOf(bestStars, starsEarned);

    return LevelProgress(
      levelId: levelId,
      status: LevelProgressStatus.completed,
      bestMoveCount: newBestMoves,
      bestTimeSeconds: newBestTime,
      bestStars: newBestStars,
      completionCount: completionCount + 1,
    );
  }

  /// Desbloquea el nivel para el jugador.
  LevelProgress unlock() {
    if (status != LevelProgressStatus.locked) {
      return this;
    }
    return LevelProgress(
      levelId: levelId,
      status: LevelProgressStatus.unlocked,
      bestMoveCount: bestMoveCount,
      bestTimeSeconds: bestTimeSeconds,
      bestStars: bestStars,
      completionCount: completionCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LevelProgress &&
          runtimeType == other.runtimeType &&
          levelId == other.levelId &&
          status == other.status &&
          completionCount == other.completionCount;

  @override
  int get hashCode => Object.hash(levelId, status, completionCount);
}
