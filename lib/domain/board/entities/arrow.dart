import 'package:meta/meta.dart';

import '../../shared/value_objects/direction.dart';
import '../../shared/value_objects/identifier.dart';
import '../../shared/value_objects/position.dart';
import '../value_objects/arrow_state.dart';

/// Entidad que representa una flecha colocada en el tablero.
///
/// Cada flecha tiene una [position], una [direction] y un [state] que evoluciona
/// durante la partida. Pertenece al estado del tablero gestionado por [Game].
@immutable
class Arrow {
  /// Crea una flecha con identidad, posición, dirección y estado inicial.
  const Arrow({
    required this.id,
    required this.position,
    required this.direction,
    this.state = ArrowState.active,
  });

  /// Identificador único de la flecha.
  final Identifier id;

  /// Posición actual en el grid.
  final Position position;

  /// Dirección hacia la que apunta y se desplaza al ser activada.
  final Direction direction;

  /// Estado operativo actual de la flecha.
  final ArrowState state;

  /// Indica si la flecha puede ser seleccionada para un movimiento.
  bool get isMovable => state == ArrowState.active;

  /// Indica si la flecha ya fue extraída del tablero.
  bool get isExtracted => state == ArrowState.extracted;

  /// Reinicia la flecha a su [originalPosition], dejándola activa de nuevo.
  ///
  /// Portado desde el dominio en español (`Flecha.reiniciar()` en la rama
  /// `Integracion`), usado al reiniciar un nivel. Como [Arrow] es inmutable
  /// y no conserva su posición original, quien reinicia el nivel (la capa
  /// que orquesta el reinicio) debe proveerla explícitamente.
  Arrow reset({required Position originalPosition}) {
    return copyWith(position: originalPosition, state: ArrowState.active);
  }

  /// Retorna una copia con los campos indicados reemplazados.
  Arrow copyWith({
    Identifier? id,
    Position? position,
    Direction? direction,
    ArrowState? state,
  }) {
    return Arrow(
      id: id ?? this.id,
      position: position ?? this.position,
      direction: direction ?? this.direction,
      state: state ?? this.state,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Arrow &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          position == other.position &&
          direction == other.direction &&
          state == other.state;

  @override
  int get hashCode => Object.hash(id, position, direction, state);

  @override
  String toString() =>
      'Arrow(id: $id, position: $position, direction: $direction, state: $state)';
}
