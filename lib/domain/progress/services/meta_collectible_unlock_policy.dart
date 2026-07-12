import '../../level/aggregates/level.dart';
import '../../level/value_objects/star_rating.dart';
import '../value_objects/meta_collectible.dart';
import 'meta_collectible_catalog.dart';

/// Reglas de dominio para desbloquear coleccionables meta.
class MetaCollectibleUnlockPolicy {
  /// Constructor privado: solo lógica estática.
  const MetaCollectibleUnlockPolicy._();

  /// `true` si completar [levelNumber] con [starsEarned] y [score] otorga
  /// un coleccionable (niveles pares 2–20 o el último nivel con desempeño perfecto).
  static bool shouldUnlock({
    required int? levelNumber,
    required StarRating starsEarned,
    required int score,
    required Level level,
  }) {
    if (!_meetsPerformanceRequirements(
      levelNumber: levelNumber,
      starsEarned: starsEarned,
      score: score,
      level: level,
    )) {
      return false;
    }

    return MetaCollectibleCatalog.forCompletedLevel(levelNumber!) != null;
  }

  /// Coleccionable que correspondería al nivel [levelNumber] si se cumplen requisitos.
  static MetaCollectible? collectibleForLevel(int? levelNumber) {
    if (levelNumber == null || levelNumber <= 0) return null;
    return MetaCollectibleCatalog.forCompletedLevel(levelNumber);
  }

  static bool _meetsPerformanceRequirements({
    required int? levelNumber,
    required StarRating starsEarned,
    required int score,
    required Level level,
  }) {
    if (levelNumber == null || levelNumber <= 0) return false;
    if (starsEarned != StarRating.three) return false;
    if (score < maxScoreForLevel(level)) return false;

    if (levelNumber == MetaCollectibleCatalog.finalMilestoneLevelNumber) {
      return true;
    }

    if (levelNumber.isOdd) return false;
    return levelNumber < MetaCollectibleCatalog.finalMilestoneLevelNumber;
  }

  /// Puntuación máxima posible al vaciar el tablero del [level].
  static int maxScoreForLevel(Level level) {
    final arrowCount = level.boardDefinition.usesWireLayout
        ? level.boardDefinition.arrowPlacements.length
        : level.boardDefinition.cells.length;
    return arrowCount * MetaCollectibleCatalog.pointsPerExtractedArrow;
  }
}
