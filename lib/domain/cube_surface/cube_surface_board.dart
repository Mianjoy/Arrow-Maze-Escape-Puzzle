import 'package:meta/meta.dart';

import '../shared/exceptions/domain_exception.dart';
import '../shared/value_objects/identifier.dart';
import 'cube_escape_point.dart';
import 'cube_path_arrow.dart';
import 'cube_surface_position.dart';

/// Tablero de superficie del cubo: flechas multi-cara + un punto de escape fijo.
@immutable
class CubeSurfaceBoard {
  /// Crea un tablero NxN por cara con [arrows] y [escapePoint].
  CubeSurfaceBoard({
    required this.faceSize,
    required this.escapePoint,
    required List<CubePathArrow> arrows,
  }) : arrows = List.unmodifiable(arrows) {
    if (faceSize < 1) {
      throw DomainException('CubeSurfaceBoard faceSize must be >= 1.');
    }
    escapePoint.position.ensureWithin(faceSize);
    for (final arrow in arrows) {
      for (final cell in arrow.occupiedCells) {
        cell.ensureWithin(faceSize);
      }
      for (final cell in arrow.escapeRoute) {
        cell.ensureWithin(faceSize);
      }
      arrow.ensureEndsAt(escapePoint.position);
    }
    _ensureNoOverlap(arrows);
  }

  /// Tamaño de cada cara (p. ej. 3 para probar en 3×3).
  final int faceSize;

  /// Punto por el que salen las flechas al dispararlas.
  final CubeEscapePoint escapePoint;

  /// Flechas aún presentes en la superficie.
  final List<CubePathArrow> arrows;

  /// True si no quedan flechas.
  bool get isCleared => arrows.isEmpty;

  /// Flecha que ocupa [position], o `null`.
  CubePathArrow? arrowAt(CubeSurfacePosition position) {
    for (final arrow in arrows) {
      if (arrow.occupies(position)) return arrow;
    }
    return null;
  }

  /// Flecha por [id].
  CubePathArrow arrowById(Identifier id) {
    return arrows.firstWhere(
      (a) => a.id == id,
      orElse: () => throw DomainException('CubePathArrow $id not found.'),
    );
  }

  /// Copia sin la flecha [id].
  CubeSurfaceBoard withoutArrow(Identifier id) {
    return CubeSurfaceBoard(
      faceSize: faceSize,
      escapePoint: escapePoint,
      arrows: arrows.where((a) => a.id != id).toList(),
    );
  }

  static void _ensureNoOverlap(List<CubePathArrow> arrows) {
    final seen = <CubeSurfacePosition>{};
    for (final arrow in arrows) {
      for (final cell in arrow.occupiedCells) {
        if (!seen.add(cell)) {
          throw DomainException('Overlapping cube arrow cell at $cell.');
        }
      }
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CubeSurfaceBoard &&
          faceSize == other.faceSize &&
          escapePoint == other.escapePoint &&
          _listEquals(arrows, other.arrows);

  @override
  int get hashCode => Object.hash(faceSize, escapePoint, Object.hashAll(arrows));

  @override
  String toString() =>
      'CubeSurfaceBoard(${faceSize}x$faceSize, arrows: ${arrows.length}, escape: $escapePoint)';
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
