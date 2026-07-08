import 'level_generation_config.dart';

/// Nivel de dificultad de un [Level].
enum LevelDifficulty {
  /// Niveles introductorios con pocos obstáculos.
  easy,

  /// Complejidad media.
  medium,

  /// Alta densidad de flechas y patrones complejos.
  hard,

  /// Desafíos extremos o niveles generados proceduralmente.
  expert,
}

/// Acceso ergonómico al preset de generación asociado a cada dificultad.
extension LevelDifficultyGeneration on LevelDifficulty {
  /// Preset de generación procedural (dimensión, densidad y semilla)
  /// correspondiente a esta dificultad.
  LevelGenerationConfig get generationConfig =>
      LevelGenerationConfig.fromDifficulty(this);
}
