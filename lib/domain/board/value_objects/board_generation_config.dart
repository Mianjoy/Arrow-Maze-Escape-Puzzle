import 'package:meta/meta.dart';

import '../value_objects/board_dimension.dart';

/// Parámetros para la generación procedural de un tablero.
@immutable
class BoardGenerationConfig {
  /// Crea la configuración con [dimension], [arrowCount] y [seed] opcional.
  const BoardGenerationConfig({
    required this.dimension,
    required this.arrowCount,
    this.seed,
  }) : assert(arrowCount > 0, 'arrowCount must be positive');

  /// Dimensiones del tablero a generar.
  final BoardDimension dimension;

  /// Cantidad de flechas a colocar.
  final int arrowCount;

  /// Semilla opcional para reproducibilidad del generador aleatorio.
  final int? seed;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoardGenerationConfig &&
          runtimeType == other.runtimeType &&
          dimension == other.dimension &&
          arrowCount == other.arrowCount &&
          seed == other.seed;

  @override
  int get hashCode => Object.hash(dimension, arrowCount, seed);
}
