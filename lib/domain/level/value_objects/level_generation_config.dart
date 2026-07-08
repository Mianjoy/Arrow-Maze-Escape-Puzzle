import 'package:meta/meta.dart';

import '../../board/value_objects/board_dimension.dart';
import '../../board/value_objects/board_generation_config.dart';
import 'level_difficulty.dart';

/// Preset de generación procedural (dimensión, densidad de flechas y
/// semilla) asociado a un [LevelDifficulty].
///
/// Portado desde el dominio en español (`ConfiguracionNivel.desdeDificultad`
/// en la rama `Integracion`) durante la fusión de dominio de Sprint 1. A
/// diferencia de [BoardGenerationConfig] (que exige una cantidad fija de
/// flechas), aquí la cantidad se deriva de una densidad relativa al tamaño
/// del tablero, para poder expresar "más difícil = tablero más grande y
/// más denso" sin acoplar el número exacto de flechas a cada nivel.
@immutable
class LevelGenerationConfig {
  /// Crea la configuración con [dimension], [arrowDensity] (0.0–1.0) y [seed].
  const LevelGenerationConfig({
    required this.dimension,
    required this.arrowDensity,
    required this.seed,
  }) : assert(
          arrowDensity > 0 && arrowDensity <= 1,
          'arrowDensity must be within (0, 1]',
        );

  /// Dimensiones del tablero a generar.
  final BoardDimension dimension;

  /// Proporción de celdas que deben tener una flecha (0.0–1.0).
  final double arrowDensity;

  /// Semilla para reproducibilidad del generador aleatorio.
  final int seed;

  /// Presets por nivel de dificultad.
  ///
  /// Los valores replican los cuatro niveles (fácil/medio/difícil/experto)
  /// definidos originalmente en español en la rama `Integracion`.
  factory LevelGenerationConfig.fromDifficulty(LevelDifficulty difficulty) {
    switch (difficulty) {
      case LevelDifficulty.easy:
        return const LevelGenerationConfig(
          dimension: BoardDimension(rows: 4, columns: 4),
          arrowDensity: 0.3,
          seed: 1,
        );
      case LevelDifficulty.medium:
        return const LevelGenerationConfig(
          dimension: BoardDimension(rows: 5, columns: 5),
          arrowDensity: 0.4,
          seed: 2,
        );
      case LevelDifficulty.hard:
        return const LevelGenerationConfig(
          dimension: BoardDimension(rows: 6, columns: 6),
          arrowDensity: 0.5,
          seed: 3,
        );
      case LevelDifficulty.expert:
        return const LevelGenerationConfig(
          dimension: BoardDimension(rows: 7, columns: 7),
          arrowDensity: 0.6,
          seed: 4,
        );
    }
  }

  /// Convierte este preset a un [BoardGenerationConfig] consumible por
  /// RandomBoardGenerator, derivando `arrowCount` a partir de la densidad.
  BoardGenerationConfig toBoardGenerationConfig() {
    final arrowCount = (dimension.totalCells * arrowDensity).round().clamp(
          1,
          dimension.totalCells,
        );
    return BoardGenerationConfig(
      dimension: dimension,
      arrowCount: arrowCount,
      seed: seed,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LevelGenerationConfig &&
          runtimeType == other.runtimeType &&
          dimension == other.dimension &&
          arrowDensity == other.arrowDensity &&
          seed == other.seed;

  @override
  int get hashCode => Object.hash(dimension, arrowDensity, seed);
}
