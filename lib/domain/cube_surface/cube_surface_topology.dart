import '../board/value_objects/face.dart';
import '../shared/enums/arrow_direction.dart';
import '../shared/value_objects/direction.dart';
import 'cube_surface_position.dart';

/// Grafo de las seis caras exteriores de un cubo NxN.
///
/// Convención de cada cara (vista desde fuera de esa cara):
/// - fila 0 arriba, fila máxima abajo
/// - columna 0 izquierda, columna máxima derecha
/// - [ArrowDirection.up] disminuye la fila
///
/// El wrap entre caras se deriva del embebido 3D compartido, para que la
/// celda destino coincida con el borde visual real del cubo.
class CubeSurfaceTopology {
  /// Crea la topología para caras de [faceSize] celdas.
  const CubeSurfaceTopology(this.faceSize);

  /// Cantidad de filas/columnas de cada cara.
  final int faceSize;

  /// Avanza una celda en la dirección local de la flecha.
  ({CubeSurfacePosition position, Direction direction}) stepForward(
    CubeSurfacePosition position,
    Direction direction,
  ) {
    final arrowDirection = direction.arrowDirection;
    final rowDelta = switch (arrowDirection) {
      ArrowDirection.up => -1,
      ArrowDirection.down => 1,
      _ => 0,
    };
    final columnDelta = switch (arrowDirection) {
      ArrowDirection.left => -1,
      ArrowDirection.right => 1,
      _ => 0,
    };
    final nextRow = position.row + rowDelta;
    final nextColumn = position.column + columnDelta;
    if (nextRow >= 0 &&
        nextRow < faceSize &&
        nextColumn >= 0 &&
        nextColumn < faceSize) {
      return (
        position: CubeSurfacePosition(
          face: position.face,
          row: nextRow,
          column: nextColumn,
        ),
        direction: direction,
      );
    }

    return _wrapAcrossEdge(position, arrowDirection);
  }

  /// Cruce de arista alineado con [_coordinate] (celdas que comparten el borde).
  ({CubeSurfacePosition position, Direction direction}) _wrapAcrossEdge(
    CubeSurfacePosition position,
    ArrowDirection exit,
  ) {
    final max = faceSize - 1;
    final r = position.row;
    final c = position.column;

    // Destino: misma coordenada 3D, otra cara. Dirección = hacia el interior.
    final (Face face, int row, int column, ArrowDirection inward) =
        switch ((position.face, exit)) {
          // FRONT ↔ top/bottom/left/right (mismas columnas / filas)
          (Face.front, ArrowDirection.up) => (
              Face.top,
              max,
              c,
              ArrowDirection.up,
            ),
          (Face.front, ArrowDirection.down) => (
              Face.bottom,
              0,
              c,
              ArrowDirection.down,
            ),
          (Face.front, ArrowDirection.left) => (
              Face.left,
              r,
              max,
              ArrowDirection.left,
            ),
          (Face.front, ArrowDirection.right) => (
              Face.right,
              r,
              0,
              ArrowDirection.right,
            ),

          // BACK (X espejado: col back ↔ max-col frente/top)
          (Face.back, ArrowDirection.up) => (
              Face.top,
              0,
              max - c,
              ArrowDirection.down,
            ),
          (Face.back, ArrowDirection.down) => (
              Face.bottom,
              max,
              max - c,
              ArrowDirection.up,
            ),
          (Face.back, ArrowDirection.left) => (
              Face.right,
              r,
              max,
              ArrowDirection.left,
            ),
          (Face.back, ArrowDirection.right) => (
              Face.left,
              r,
              0,
              ArrowDirection.right,
            ),

          // RIGHT: col 0 = frente, col max = atrás; al salir up/down la fila
          // del destino usa la columna de right.
          (Face.right, ArrowDirection.up) => (
              Face.top,
              max - c,
              max,
              ArrowDirection.left,
            ),
          (Face.right, ArrowDirection.down) => (
              Face.bottom,
              c,
              max,
              ArrowDirection.left,
            ),
          (Face.right, ArrowDirection.left) => (
              Face.front,
              r,
              max,
              ArrowDirection.left,
            ),
          (Face.right, ArrowDirection.right) => (
              Face.back,
              r,
              0,
              ArrowDirection.right,
            ),

          // LEFT: col 0 = atrás, col max = frente
          (Face.left, ArrowDirection.up) => (
              Face.top,
              c,
              0,
              ArrowDirection.right,
            ),
          (Face.left, ArrowDirection.down) => (
              Face.bottom,
              max - c,
              0,
              ArrowDirection.right,
            ),
          (Face.left, ArrowDirection.left) => (
              Face.back,
              r,
              max,
              ArrowDirection.left,
            ),
          (Face.left, ArrowDirection.right) => (
              Face.front,
              r,
              0,
              ArrowDirection.right,
            ),

          // TOP: fila = Z (0 atrás, max frente). Al salir L/R la col del
          // destino lateral usa la FILA de top (recorrido del borde).
          (Face.top, ArrowDirection.up) => (
              Face.back,
              0,
              max - c,
              ArrowDirection.down,
            ),
          (Face.top, ArrowDirection.down) => (
              Face.front,
              0,
              c,
              ArrowDirection.down,
            ),
          (Face.top, ArrowDirection.left) => (
              Face.left,
              0,
              r,
              ArrowDirection.down,
            ),
          (Face.top, ArrowDirection.right) => (
              Face.right,
              0,
              max - r,
              ArrowDirection.down,
            ),

          // BOTTOM: fila 0 frente, max atrás
          (Face.bottom, ArrowDirection.up) => (
              Face.front,
              max,
              c,
              ArrowDirection.up,
            ),
          (Face.bottom, ArrowDirection.down) => (
              Face.back,
              max,
              max - c,
              ArrowDirection.up,
            ),
          (Face.bottom, ArrowDirection.left) => (
              Face.left,
              max,
              max - r,
              ArrowDirection.up,
            ),
          (Face.bottom, ArrowDirection.right) => (
              Face.right,
              max,
              r,
              ArrowDirection.up,
            ),
        };

    return (
      position: CubeSurfacePosition(face: face, row: row, column: column),
      direction: Direction(inward),
    );
  }

  /// Embebido 3D: aristas compartidas ⇒ misma coordenada.
  ({int x, int y, int z}) _coordinate(CubeSurfacePosition position) {
    final max = faceSize - 1;
    final r = position.row;
    final c = position.column;
    return switch (position.face) {
      Face.front => (x: c, y: max - r, z: max),
      Face.back => (x: max - c, y: max - r, z: 0),
      Face.right => (x: max, y: max - r, z: max - c),
      Face.left => (x: 0, y: max - r, z: c),
      Face.top => (x: c, y: max, z: r),
      Face.bottom => (x: c, y: 0, z: max - r),
    };
  }

  /// Sigue la dirección de [start] por el exterior hasta [goal].
  List<CubeSurfacePosition>? traceTo({
    required CubeSurfacePosition start,
    required Direction direction,
    required CubeSurfacePosition goal,
  }) {
    var current = start;
    var currentDirection = direction;
    final route = <CubeSurfacePosition>[];
    final visited =
        <({CubeSurfacePosition position, ArrowDirection direction})>{};

    while (visited.add((
      position: current,
      direction: currentDirection.arrowDirection,
    ))) {
      final step = stepForward(current, currentDirection);
      current = step.position;
      currentDirection = step.direction;
      route.add(current);
      if (current == goal) return route;
    }
    return null;
  }

  /// Todas las celdas de las seis caras.
  List<CubeSurfacePosition> get positions => [
        for (final face in Face.values)
          for (var row = 0; row < faceSize; row++)
            for (var column = 0; column < faceSize; column++)
              CubeSurfacePosition(face: face, row: row, column: column),
      ];

  /// Vecinas ortogonales sobre la superficie exterior.
  List<CubeSurfacePosition> neighbors(CubeSurfacePosition position) {
    final result = <CubeSurfacePosition>[];

    void add(CubeSurfacePosition next) {
      if (!result.contains(next)) result.add(next);
    }

    if (position.row > 0) {
      add(CubeSurfacePosition(
        face: position.face,
        row: position.row - 1,
        column: position.column,
      ));
    }
    if (position.row + 1 < faceSize) {
      add(CubeSurfacePosition(
        face: position.face,
        row: position.row + 1,
        column: position.column,
      ));
    }
    if (position.column > 0) {
      add(CubeSurfacePosition(
        face: position.face,
        row: position.row,
        column: position.column - 1,
      ));
    }
    if (position.column + 1 < faceSize) {
      add(CubeSurfacePosition(
        face: position.face,
        row: position.row,
        column: position.column + 1,
      ));
    }

    for (final dir in ArrowDirection.values) {
      final onEdge = switch (dir) {
        ArrowDirection.up => position.row == 0,
        ArrowDirection.down => position.row == faceSize - 1,
        ArrowDirection.left => position.column == 0,
        ArrowDirection.right => position.column == faceSize - 1,
      };
      if (!onEdge) continue;
      final wrapped = _wrapAcrossEdge(position, dir).position;
      assert(
        _coordinate(position) == _coordinate(wrapped),
        'Wrap $position $dir -> $wrapped must share cube coordinate',
      );
      add(wrapped);
    }
    return result;
  }

  /// Dirección local desde [from] hacia [to] (misma cara o un wrap).
  Direction directionBetween(
    CubeSurfacePosition from,
    CubeSurfacePosition to,
  ) {
    if (from.face == to.face) {
      if (to.row < from.row) return const Direction(ArrowDirection.up);
      if (to.row > from.row) return const Direction(ArrowDirection.down);
      if (to.column < from.column) {
        return const Direction(ArrowDirection.left);
      }
      return const Direction(ArrowDirection.right);
    }

    for (final dir in ArrowDirection.values) {
      final step = stepForward(from, Direction(dir));
      if (step.position == to) return Direction(dir);
    }
    return const Direction(ArrowDirection.right);
  }
}
