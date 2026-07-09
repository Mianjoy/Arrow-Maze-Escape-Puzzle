import 'package:meta/meta.dart';

import '../../shared/value_objects/direction.dart';
import '../../shared/value_objects/identifier.dart';
import '../../shared/value_objects/position.dart';

/// Definición estática de una flecha multi-celda (cabeza + cuerpo).
///
/// Representa un elemento del array `arrows` del contrato
/// [StructuredLevelJsonDto], ya traducido a tipos de dominio.
/// [Level.buildInitialBoard] la convierte en una entidad [Arrow] en el tablero.
@immutable
class LevelArrowPlacement {
  /// Crea la definición con [id], [direction], [head] y segmentos de [body].
  ///
  /// [head] es la celda que el jugador toca para disparar; [body] son celdas
  /// adicionales que ocupan espacio y bloquean otras flechas.
  const LevelArrowPlacement({
    required this.id,
    required this.direction,
    required this.head,
    this.body = const [],
  });

  /// Identificador estable de la flecha (coincide con `arrows[].id` del JSON).
  final Identifier id;

  /// Dirección hacia la que se desplaza la flecha al dispararse.
  final Direction direction;

  /// Posición de la cabeza en el grid (base 0).
  final Position head;

  /// Posiciones del cuerpo, excluyendo la cabeza.
  final List<Position> body;

  /// Todas las celdas que ocupa la flecha al inicio del nivel.
  ///
  /// Usado por [Board.placeArrowSegments] y [CollisionValidator].
  List<Position> get allPositions => [head, ...body];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LevelArrowPlacement &&
          id == other.id &&
          direction == other.direction &&
          head == other.head &&
          _listEquals(body, other.body);

  @override
  int get hashCode => Object.hash(id, direction, head, Object.hashAll(body));

  /// Compara dos listas de [Position] elemento a elemento.
  static bool _listEquals(List<Position> a, List<Position> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
