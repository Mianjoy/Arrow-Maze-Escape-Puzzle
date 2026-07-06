import 'package:meta/meta.dart';

import '../../board/value_objects/board_dimension.dart';

/// Value object con la configuración estática de un nivel.
@immutable
class LevelConfiguration {
  /// Crea la configuración con [dimension], [arrowCount] y [timeLimitSeconds].
  const LevelConfiguration({
    required this.dimension,
    required this.arrowCount,
    this.timeLimitSeconds,
  }) : assert(arrowCount > 0, 'arrowCount must be positive');

  /// Dimensiones del tablero del nivel.
  final BoardDimension dimension;

  /// Número de flechas que debe resolver el jugador.
  final int arrowCount;

  /// Límite de tiempo opcional en segundos (`null` = sin límite).
  final int? timeLimitSeconds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LevelConfiguration &&
          runtimeType == other.runtimeType &&
          dimension == other.dimension &&
          arrowCount == other.arrowCount &&
          timeLimitSeconds == other.timeLimitSeconds;

  @override
  int get hashCode => Object.hash(dimension, arrowCount, timeLimitSeconds);
}
