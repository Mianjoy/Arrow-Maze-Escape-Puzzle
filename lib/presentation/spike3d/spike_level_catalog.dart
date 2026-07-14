import '../../domain/domain.dart';

/// Datos de una flecha tal como están en `levels/level-N.json` del backend
/// (`arrows[].head/body/direction`), transcritos a mano para el spike.
class SpikeArrowSpec {
  /// Crea una especificación de flecha embebida para el spike.
  const SpikeArrowSpec(this.id, this.direction, this.head, this.body);

  /// Identificador estable de la flecha.
  final String id;

  /// Dirección de disparo de la punta.
  final ArrowDirection direction;

  /// Celda de la punta `(fila, columna)`.
  final (int row, int col) head;

  /// Segmentos del cuerpo, en orden desde la punta.
  final List<(int row, int col)> body;
}

/// Construye un [Board] real (mismo camino que [Level.buildInitialBoard]
/// para el formato wire: tablero vacío + `placeArrowSegments` por flecha)
/// a partir de las specs embebidas — ejercitando el dominio real, no datos
/// inventados.
Board buildSpikeBoard(String boardId, int size, List<SpikeArrowSpec> specs) {
  var board = const BoardFactory().createEmpty(
    id: Identifier('board-$boardId'),
    dimension: BoardDimension(rows: size, columns: size),
  );
  for (final spec in specs) {
    final arrow = Arrow(
      id: Identifier(spec.id),
      position: Position(row: spec.head.$1, column: spec.head.$2),
      direction: Direction(spec.direction),
      body: [for (final p in spec.body) Position(row: p.$1, column: p.$2)],
    );
    board = board.placeArrowSegments(arrow);
  }
  return board;
}

/// Los únicos 5 niveles 9x9 subidos al catálogo del backend
/// (`BackEnd-ArrowMaze/levels/`) — el resto son de otros tamaños o no
/// cuadrados. El cubo necesita 6 caras NxN iguales, así que la 6ª cara
/// reutiliza "Nudo Triple" (no hay un 6º nivel 9x9 disponible todavía).
const int kSpikeFaceSize = 9;

/// Flechas del nivel «Nudo Triple» (level-8), cara 9×9.
const List<SpikeArrowSpec> kLevel8NudoTriple = [
  SpikeArrowSpec('l1', ArrowDirection.left, (0, 0), [(0, 1), (0, 2)]),
  SpikeArrowSpec('l2', ArrowDirection.up, (1, 2), [(2, 2), (3, 2)]),
  SpikeArrowSpec('u1', ArrowDirection.up, (0, 4), [(1, 4), (2, 4)]),
  SpikeArrowSpec('u2', ArrowDirection.up, (3, 4), [(3, 5), (3, 6)]),
  SpikeArrowSpec('u3', ArrowDirection.down, (2, 6), [(1, 6), (0, 6)]),
  SpikeArrowSpec('s1', ArrowDirection.left, (5, 0), [(5, 1), (5, 2)]),
  SpikeArrowSpec('s2', ArrowDirection.up, (6, 2), [(7, 2), (8, 2)]),
  SpikeArrowSpec('s3', ArrowDirection.left, (8, 3), [(8, 4), (8, 5)]),
  SpikeArrowSpec('a10', ArrowDirection.up, (0, 8), [(1, 8)]),
  SpikeArrowSpec('a11', ArrowDirection.down, (8, 8), [(7, 8)]),
  SpikeArrowSpec('a12', ArrowDirection.right, (4, 8), [(4, 7)]),
];

/// Flechas del nivel «Cruce de Caminos» (level-9), cara 9×9.
const List<SpikeArrowSpec> kLevel9CruceDeCaminos = [
  SpikeArrowSpec('u1', ArrowDirection.up, (0, 4), [(1, 4)]),
  SpikeArrowSpec('u2', ArrowDirection.up, (2, 4), [(3, 4)]),
  SpikeArrowSpec('d1', ArrowDirection.down, (8, 4), [(7, 4)]),
  SpikeArrowSpec('d2', ArrowDirection.down, (6, 4), [(5, 4)]),
  SpikeArrowSpec('l1', ArrowDirection.left, (4, 0), [(4, 1)]),
  SpikeArrowSpec('l2', ArrowDirection.left, (4, 2), [(4, 3)]),
  SpikeArrowSpec('r1', ArrowDirection.right, (4, 8), [(4, 7)]),
  SpikeArrowSpec('r2', ArrowDirection.right, (4, 6), [(4, 5)]),
  SpikeArrowSpec('c1', ArrowDirection.up, (0, 0), [(1, 0)]),
  SpikeArrowSpec('c2', ArrowDirection.down, (8, 8), [(7, 8)]),
];

/// Flechas del nivel «Viento de Molino» (level-11), cara 9×9.
const List<SpikeArrowSpec> kLevel11VientoDeMolino = [
  SpikeArrowSpec('b1o', ArrowDirection.right, (1, 8), [(1, 5), (1, 6), (1, 7)]),
  SpikeArrowSpec('b1i', ArrowDirection.up, (2, 5), [(3, 5), (4, 5)]),
  SpikeArrowSpec('b2o', ArrowDirection.down, (8, 7), [(5, 7), (6, 7), (7, 7)]),
  SpikeArrowSpec('b2i', ArrowDirection.right, (5, 6), [(5, 5), (5, 4)]),
  SpikeArrowSpec('b3o', ArrowDirection.left, (7, 0), [(7, 3), (7, 2), (7, 1)]),
  SpikeArrowSpec('b3i', ArrowDirection.down, (6, 3), [(5, 3), (4, 3)]),
  SpikeArrowSpec('b4o', ArrowDirection.up, (0, 1), [(1, 1), (2, 1), (3, 1)]),
  SpikeArrowSpec('b4i', ArrowDirection.left, (3, 2), [(3, 3), (3, 4)]),
  SpikeArrowSpec('h1', ArrowDirection.up, (0, 0), [(1, 0)]),
  SpikeArrowSpec('h2', ArrowDirection.down, (8, 8), [(7, 8)]),
];

/// Flechas del nivel «Punto de Quiebre» (level-12), cara 9×9.
const List<SpikeArrowSpec> kLevel12PuntoDeQuiebre = [
  SpikeArrowSpec('t1', ArrowDirection.up, (0, 0),
      [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8)]),
  SpikeArrowSpec('t2', ArrowDirection.up, (1, 1),
      [(1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7)]),
  SpikeArrowSpec('t3', ArrowDirection.up, (2, 2), [(2, 3), (2, 4), (2, 5), (2, 6)]),
  SpikeArrowSpec('t4', ArrowDirection.up, (3, 3), [(3, 4), (3, 5)]),
  SpikeArrowSpec('s1', ArrowDirection.down, (8, 0),
      [(8, 1), (8, 2), (8, 3), (8, 4), (8, 5), (8, 6), (8, 7), (8, 8)]),
  SpikeArrowSpec('s2', ArrowDirection.down, (7, 1),
      [(7, 2), (7, 3), (7, 4), (7, 5), (7, 6), (7, 7)]),
  SpikeArrowSpec('s3', ArrowDirection.down, (6, 2), [(6, 3), (6, 4), (6, 5), (6, 6)]),
  SpikeArrowSpec('s4', ArrowDirection.down, (5, 3), [(5, 4), (5, 5)]),
  SpikeArrowSpec('w1', ArrowDirection.left, (4, 0), [(4, 1)]),
  SpikeArrowSpec('w2', ArrowDirection.right, (4, 8), [(4, 7)]),
];

/// Flechas del nivel «El Remolino» (level-13), cara 9×9.
const List<SpikeArrowSpec> kLevel13ElRemolino = [
  SpikeArrowSpec('sp1', ArrowDirection.left, (0, 0),
      [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8)]),
  SpikeArrowSpec('sp2', ArrowDirection.up, (1, 8),
      [(2, 8), (3, 8), (4, 8), (5, 8), (6, 8), (7, 8), (8, 8)]),
  SpikeArrowSpec('sp3', ArrowDirection.right, (8, 7),
      [(8, 6), (8, 5), (8, 4), (8, 3), (8, 2), (8, 1), (8, 0)]),
  SpikeArrowSpec('sp4', ArrowDirection.down, (7, 0),
      [(6, 0), (5, 0), (4, 0), (3, 0), (2, 0), (1, 0)]),
  SpikeArrowSpec('sp5', ArrowDirection.left, (1, 1),
      [(1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7)]),
  SpikeArrowSpec('sp6', ArrowDirection.up, (2, 7), [(3, 7), (4, 7), (5, 7), (6, 7), (7, 7)]),
  SpikeArrowSpec('sp7', ArrowDirection.right, (7, 6), [(7, 5), (7, 4), (7, 3), (7, 2), (7, 1)]),
  SpikeArrowSpec('sp8', ArrowDirection.down, (6, 1), [(5, 1), (4, 1), (3, 1), (2, 1)]),
  SpikeArrowSpec('sp9', ArrowDirection.left, (2, 2), [(2, 3), (2, 4), (2, 5), (2, 6)]),
  SpikeArrowSpec('sp10', ArrowDirection.up, (3, 6), [(4, 6), (5, 6), (6, 6)]),
  SpikeArrowSpec('sp11', ArrowDirection.right, (6, 5), [(6, 4), (6, 3), (6, 2)]),
  SpikeArrowSpec('sp12', ArrowDirection.down, (5, 2), [(4, 2), (3, 2)]),
  SpikeArrowSpec('sp13', ArrowDirection.left, (3, 3), [(3, 4), (3, 5)]),
  SpikeArrowSpec('sp14', ArrowDirection.up, (4, 5), [(5, 5)]),
  SpikeArrowSpec('sp15', ArrowDirection.right, (5, 4), [(5, 3)]),
];

/// Construye el [CubeBoard] de demostración con 5 niveles reales del
/// catálogo (uno por cara) más "Nudo Triple" repetido en la 6ª cara.
CubeBoard buildSpikeCubeBoard() {
  final boardsByFace = <Face, Board>{
    Face.front: buildSpikeBoard('level-8-nudo-triple', kSpikeFaceSize, kLevel8NudoTriple),
    Face.back: buildSpikeBoard('level-9-cruce-de-caminos', kSpikeFaceSize, kLevel9CruceDeCaminos),
    Face.left: buildSpikeBoard('level-11-viento-de-molino', kSpikeFaceSize, kLevel11VientoDeMolino),
    Face.right: buildSpikeBoard('level-12-punto-de-quiebre', kSpikeFaceSize, kLevel12PuntoDeQuiebre),
    Face.top: buildSpikeBoard('level-13-el-remolino', kSpikeFaceSize, kLevel13ElRemolino),
    // Reutilizado: no hay un 6º nivel 9x9 en el catálogo todavía.
    Face.bottom: buildSpikeBoard('level-8-nudo-triple-bottom', kSpikeFaceSize, kLevel8NudoTriple),
  };
  return CubeBoard(boardsByFace: boardsByFace);
}
