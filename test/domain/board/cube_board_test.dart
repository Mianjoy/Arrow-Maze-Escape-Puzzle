import 'package:arrow_maze_escape_puzzle/domain/domain.dart';
import 'package:test/test.dart';

/// [CubeBoard]: 6 [Board] independientes, uno por cara, sin cambios sobre
/// el motor de reglas existente ([ArrowMovementEngine]/[CollisionValidator]).
void main() {
  const engine = ArrowMovementEngine(collisionValidator: CollisionValidator());

  /// Tablero de prueba 2x2 vacío, con las flechas indicadas.
  Board buildBoard(String id, List<Arrow> arrows) {
    var board = const BoardFactory().createEmpty(
      id: Identifier('board-$id'),
      dimension: const BoardDimension(rows: 2, columns: 2),
    );
    for (final arrow in arrows) {
      board = board.placeArrow(arrow);
    }
    return board;
  }

  /// Cubo con un tablero 2x2 vacío por cada cara, salvo overrides.
  CubeBoard buildCube({Map<Face, Board>? overrides}) {
    final boardsByFace = <Face, Board>{
      for (final face in Face.values) face: buildBoard(face.name, const []),
    };
    if (overrides != null) boardsByFace.addAll(overrides);
    return CubeBoard(boardsByFace: boardsByFace);
  }

  group('CubeBoard construction', () {
    test('should_throw_when_a_face_is_missing', () {
      final boardsByFace = <Face, Board>{
        for (final face in Face.values.where((f) => f != Face.back))
          face: buildBoard(face.name, const []),
      };

      expect(
        () => CubeBoard(boardsByFace: boardsByFace),
        throwsA(isA<DomainException>()),
      );
    });
  });

  group('CubeBoard.boardAt', () {
    test('should_expose_the_board_of_each_face_independently', () {
      const arrow = Arrow(
        id: Identifier('arrow-front'),
        position: Position(row: 0, column: 0),
        direction: Direction(ArrowDirection.right),
      );
      final frontBoard = buildBoard('front', [arrow]);
      final cube = buildCube(overrides: {Face.front: frontBoard});

      expect(cube.boardAt(Face.front), same(frontBoard));
      expect(cube.boardAt(Face.front).arrows, hasLength(1));
      expect(cube.boardAt(Face.back).arrows, isEmpty);
    });
  });

  group('CubeBoard.isCleared', () {
    test('should_be_cleared_when_all_6_faces_have_no_arrows_left', () {
      final cube = buildCube();

      expect(cube.isCleared, isTrue);
    });

    test('should_not_be_cleared_while_at_least_one_face_still_has_arrows', () {
      const arrow = Arrow(
        id: Identifier('arrow-front'),
        position: Position(row: 0, column: 0),
        direction: Direction(ArrowDirection.right),
      );
      final cube = buildCube(overrides: {Face.front: buildBoard('front', [arrow])});

      expect(cube.isCleared, isFalse);
    });

    test('should_become_cleared_once_the_last_remaining_faces_arrow_exits', () {
      // REGLA: cada cara se resuelve con su propio motor de reglas — sin cambios sobre lo existente.
      const arrow = Arrow(
        id: Identifier('arrow-front'),
        position: Position(row: 0, column: 0),
        direction: Direction(ArrowDirection.right),
      );
      var cube = buildCube(overrides: {Face.front: buildBoard('front', [arrow])});
      expect(cube.isCleared, isFalse);

      final outcome = engine.attemptMove(
        board: cube.boardAt(Face.front),
        arrowId: arrow.id,
      );
      expect(outcome.result.isExtracted, isTrue);

      cube = cube.withUpdatedFace(Face.front, outcome.board);

      expect(cube.isCleared, isTrue);
    });
  });

  group('CubeBoard.withUpdatedFace', () {
    test('should_not_let_firing_on_one_face_affect_arrows_on_another_face', () {
      // REGLA: las caras son tableros cerrados e independientes.
      const frontArrow = Arrow(
        id: Identifier('arrow-front'),
        position: Position(row: 0, column: 0),
        direction: Direction(ArrowDirection.right),
      );
      const backArrow = Arrow(
        id: Identifier('arrow-back'),
        position: Position(row: 0, column: 0),
        direction: Direction(ArrowDirection.right),
      );
      var cube = buildCube(overrides: {
        Face.front: buildBoard('front', [frontArrow]),
        Face.back: buildBoard('back', [backArrow]),
      });

      final outcome = engine.attemptMove(
        board: cube.boardAt(Face.front),
        arrowId: frontArrow.id,
      );
      cube = cube.withUpdatedFace(Face.front, outcome.board);

      expect(cube.boardAt(Face.front).activeArrows, isEmpty);
      expect(cube.boardAt(Face.back).activeArrows, hasLength(1));
      expect(cube.isCleared, isFalse);
    });
  });
}
