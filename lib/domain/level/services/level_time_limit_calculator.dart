import '../aggregates/level.dart';
import '../value_objects/level_difficulty.dart';

/// Calcula los segundos disponibles para completar un [Level].
///
/// Usa `maxTimeInSeconds` del wire format cuando está presente; si no,
/// estima un límite a partir de [Level.optimalMoves] y la dificultad.
class LevelTimeLimitCalculator {
  /// Crea el calculador con los factores por defecto del juego.
  const LevelTimeLimitCalculator({
    this.minimumSeconds = 30,
    this.maximumSeconds = 600,
    this.easySecondsPerOptimalMove = 10,
    this.mediumSecondsPerOptimalMove = 8,
    this.hardSecondsPerOptimalMove = 6,
    this.expertSecondsPerOptimalMove = 5,
    this.baseMarginSeconds = 15,
  });

  /// Piso de tiempo para cualquier nivel.
  final int minimumSeconds;

  /// Techo de tiempo para niveles calculados sin wire format.
  final int maximumSeconds;

  /// Segundos por movimiento óptimo en dificultad fácil.
  final int easySecondsPerOptimalMove;

  /// Segundos por movimiento óptimo en dificultad media.
  final int mediumSecondsPerOptimalMove;

  /// Segundos por movimiento óptimo en dificultad difícil.
  final int hardSecondsPerOptimalMove;

  /// Segundos por movimiento óptimo en dificultad experta.
  final int expertSecondsPerOptimalMove;

  /// Margen fijo añadido al tiempo calculado.
  final int baseMarginSeconds;

  /// Resuelve el límite de tiempo jugable en segundos para [level].
  int resolve(Level level) {
    final configured = level.timeLimit;
    if (configured != null && configured > 0) {
      return configured;
    }

    final perMove = switch (level.difficulty) {
      LevelDifficulty.easy => easySecondsPerOptimalMove,
      LevelDifficulty.medium => mediumSecondsPerOptimalMove,
      LevelDifficulty.hard => hardSecondsPerOptimalMove,
      LevelDifficulty.expert => expertSecondsPerOptimalMove,
    };

    final calculated = level.optimalMoves * perMove + baseMarginSeconds;
    return calculated.clamp(minimumSeconds, maximumSeconds);
  }
}
