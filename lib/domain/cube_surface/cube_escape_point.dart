import 'package:meta/meta.dart';

import 'cube_surface_position.dart';

/// Punto fijo por el que las flechas salen del cubo al dispararlas.
@immutable
class CubeEscapePoint {
  /// Crea el punto de escape en la posición de superficie [position].
  const CubeEscapePoint(this.position);

  /// Celda de superficie que actúa como salida del cubo.
  final CubeSurfacePosition position;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CubeEscapePoint && position == other.position;

  @override
  int get hashCode => position.hashCode;

  @override
  String toString() => 'CubeEscapePoint($position)';
}
