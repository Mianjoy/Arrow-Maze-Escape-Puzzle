import 'package:meta/meta.dart';

import '../enums/arrow_direction.dart';
import 'position.dart';

/// Value object que modela una dirección de desplazamiento en el tablero.
///
/// Encapsula un [ArrowDirection] y expone el delta de coordenadas asociado.
@immutable
class Direction {
  /// Crea una dirección a partir de un [ArrowDirection].
  const Direction(this.arrowDirection);

  /// Dirección cardinal subyacente.
  final ArrowDirection arrowDirection;

  /// Delta de fila al moverse en esta dirección (-1, 0 o 1).
  int get deltaRow => switch (arrowDirection) {
        ArrowDirection.up => -1,
        ArrowDirection.down => 1,
        ArrowDirection.left || ArrowDirection.right => 0,
      };

  /// Delta de columna al moverse en esta dirección (-1, 0 o 1).
  int get deltaColumn => switch (arrowDirection) {
        ArrowDirection.left => -1,
        ArrowDirection.right => 1,
        ArrowDirection.up || ArrowDirection.down => 0,
      };

  /// Calcula la siguiente [Position] al avanzar desde [from].
  Position nextPositionFrom(Position from) {
    return from.translate(dRow: deltaRow, dCol: deltaColumn);
  }

  /// Dirección opuesta a la actual.
  Direction get opposite => Direction(switch (arrowDirection) {
        ArrowDirection.up => ArrowDirection.down,
        ArrowDirection.down => ArrowDirection.up,
        ArrowDirection.left => ArrowDirection.right,
        ArrowDirection.right => ArrowDirection.left,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Direction &&
          runtimeType == other.runtimeType &&
          arrowDirection == other.arrowDirection;

  @override
  int get hashCode => arrowDirection.hashCode;

  @override
  String toString() => 'Direction($arrowDirection)';
}
