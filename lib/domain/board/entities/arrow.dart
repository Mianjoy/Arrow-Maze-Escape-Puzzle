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
    this.body = const [],
    this.state = ArrowState.active,
  });

  /// Identificador único de la flecha.
  final Identifier id;

  /// Posición actual en el grid.
  final Position position;

  /// Dirección hacia la que apunta y se desplaza al ser activada.
  final Direction direction;

  /// Segmentos de cuerpo adicionales (ocupan celdas pero no son la cabeza).
  ///
  /// Provienen del array `body` del contrato wire. Bloquean trayectorias
  /// de otras flechas igual que la cabeza. Vacío en niveles legacy de una celda.
  final List<Position> body;

  /// Estado operativo actual de la flecha.
  final ArrowState state;

  /// Todas las posiciones que ocupa la flecha (cabeza + cada segmento de cuerpo).
  List<Position> get allPositions => [position, ...body];

  /// Indica si [pos] está ocupada por esta flecha (cabeza o cuerpo).
  ///
  /// Usado por [Board.arrowIdAt] y [CollisionValidator] para flechas multi-celda.
  bool occupies(Position pos) => allPositions.any((p) => p == pos);

  /// Indica si la flecha puede ser seleccionada para un movimiento.
  ///
  /// Una flecha `blocked` (bloqueada por otra en su trayectoria) SÍ es
  /// movible: el bloqueo es una condición del intento anterior, no una
  /// propiedad permanente — una vez que se despeja la flecha que la bloquea,
  /// debe poder dispararse. Solo una flecha ya `extracted` deja de ser
  /// movible (ya salió del tablero).
  bool get isMovable => state != ArrowState.extracted;

  /// Indica si la flecha ya fue extraída del tablero.
  bool get isExtracted => state == ArrowState.extracted;

  /// Reinicia la flecha a su [originalPosition] y [body] iniciales, en estado activo.
  ///
  /// Portado desde el dominio en español (`Flecha.reiniciar()` en la rama
  /// `Integracion`). Quien reinicia el nivel debe proveer posición y cuerpo
  /// originales porque [Arrow] es inmutable y no los conserva internamente.
  Arrow reset({required Position originalPosition, List<Position> body = const []}) {
    return copyWith(position: originalPosition, body: body, state: ArrowState.active);
  }

  /// Retorna una copia con los campos indicados reemplazados.
  Arrow copyWith({
    Identifier? id,
    Position? position,
    Direction? direction,
    List<Position>? body,
    ArrowState? state,
  }) {
    return Arrow(
      id: id ?? this.id,
      position: position ?? this.position,
      direction: direction ?? this.direction,
      body: body ?? this.body,
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
