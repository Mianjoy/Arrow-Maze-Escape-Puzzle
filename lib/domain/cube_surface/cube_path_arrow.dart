import 'package:meta/meta.dart';

import '../shared/enums/arrow_direction.dart';
import '../shared/exceptions/domain_exception.dart';
import '../shared/value_objects/direction.dart';
import '../shared/value_objects/identifier.dart';
import 'cube_surface_position.dart';

/// Flecha sobre la superficie del cubo: punta y cuerpo pueden estar en caras distintas.
@immutable
class CubePathArrow {
  /// Crea una flecha con [tip], [body] (otras caras/celdas) y ruta hasta el escape.
  CubePathArrow({
    required this.id,
    required this.tip,
    required this.direction,
    required List<CubeSurfacePosition> body,
    required List<CubeSurfacePosition> escapeRoute,
  })  : body = List.unmodifiable(body),
        escapeRoute = List.unmodifiable(escapeRoute) {
    if (body.any((p) => p == tip)) {
      throw DomainException('CubePathArrow body cannot include the tip cell.');
    }
    if (escapeRoute.isEmpty) {
      throw DomainException('CubePathArrow escapeRoute cannot be empty.');
    }
  }

  /// Identificador de la flecha.
  final Identifier id;

  /// Celda de la punta (puede estar en otra cara que el cuerpo).
  final CubeSurfacePosition tip;

  /// Dirección local de disparo desde la punta.
  final Direction direction;

  /// Celdas de cuerpo (pueden pertenecer a caras distintas a [tip]).
  final List<CubeSurfacePosition> body;

  /// Camino desde la tip (excluida) hasta el punto de escape (incluido).
  ///
  /// Al disparar, si ninguna otra flecha ocupa estas celdas, la flecha sale
  /// por el escape.
  final List<CubeSurfacePosition> escapeRoute;

  /// Todas las celdas ocupadas (punta + cuerpo).
  List<CubeSurfacePosition> get occupiedCells => [tip, ...body];

  /// Indica si esta flecha ocupa [position].
  bool occupies(CubeSurfacePosition position) =>
      occupiedCells.any((p) => p == position);

  /// Copia con [escapeRoute] validada contra el escape del tablero.
  void ensureEndsAt(CubeSurfacePosition escape) {
    if (escapeRoute.last != escape) {
      throw DomainException(
        'CubePathArrow $id escapeRoute must end at escape point $escape.',
      );
    }
  }

  /// Dirección cardinal de la punta (atajo).
  ArrowDirection get tipDirection => direction.arrowDirection;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CubePathArrow &&
          id == other.id &&
          tip == other.tip &&
          direction == other.direction &&
          _listEquals(body, other.body) &&
          _listEquals(escapeRoute, other.escapeRoute);

  @override
  int get hashCode => Object.hash(id, tip, direction, Object.hashAll(body), Object.hashAll(escapeRoute));

  @override
  String toString() => 'CubePathArrow($id, tip: $tip, body: $body)';
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
