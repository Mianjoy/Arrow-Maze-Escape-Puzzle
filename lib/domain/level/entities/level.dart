import 'package:meta/meta.dart';

import '../../shared/value_objects/identifier.dart';
import 'level_configuration.dart';
import 'level_difficulty.dart';

/// Entidad que representa un nivel jugable del juego Arrow Maze.
///
/// Un nivel define metadatos (nombre, dificultad, orden) y la
/// [configuration] que determina cómo se construye el tablero.
@immutable
class Level {
  /// Crea un nivel con [id], [name], [orderIndex] y [configuration].
  const Level({
    required this.id,
    required this.name,
    required this.orderIndex,
    required this.difficulty,
    required this.configuration,
  }) : assert(orderIndex >= 0, 'orderIndex must be non-negative');

  /// Identificador único del nivel.
  final Identifier id;

  /// Nombre visible para el jugador.
  final String name;

  /// Posición en la secuencia de niveles (0 = primero).
  final int orderIndex;

  /// Etiqueta de dificultad.
  final LevelDifficulty difficulty;

  /// Parámetros de generación o carga del tablero.
  final LevelConfiguration configuration;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Level &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          orderIndex == other.orderIndex &&
          difficulty == other.difficulty &&
          configuration == other.configuration;

  @override
  int get hashCode => Object.hash(id, name, orderIndex, difficulty, configuration);

  @override
  String toString() => 'Level(id: $id, name: $name, order: $orderIndex)';
}
