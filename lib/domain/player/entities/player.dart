import 'package:meta/meta.dart';

import '../../shared/value_objects/identifier.dart';

/// Entidad que representa al jugador humano.
///
/// Contiene datos de identidad básicos. Las estadísticas viven en
/// [PlayerProfile] y el progreso por nivel en `PlayerProgress`.
@immutable
class Player {
  /// Crea un jugador con [id] y [displayName].
  const Player({
    required this.id,
    required this.displayName,
    required this.createdAt,
  }) : assert(displayName != '', 'displayName cannot be empty');

  /// Identificador único del jugador.
  final Identifier id;

  /// Nombre mostrado en la interfaz.
  final String displayName;

  /// Fecha de creación del perfil.
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Player &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          displayName == other.displayName;

  @override
  int get hashCode => Object.hash(id, displayName);

  @override
  String toString() => 'Player(id: $id, displayName: $displayName)';
}
