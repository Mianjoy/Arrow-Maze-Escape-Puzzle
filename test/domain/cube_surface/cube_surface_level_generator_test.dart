import 'package:arrow_maze_escape_puzzle/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const generator = CubeSurfaceLevelGenerator(faceSize: 3, arrowCount: 6);
  const engine = CubePathMovementEngine();

  test('generated levels are solvable for many seeds', () {
    for (var seed = 0; seed < 100; seed++) {
      final level = generator.generate(seed: seed);
      var board = level.board;

      expect(board.arrows, hasLength(6), reason: 'seed $seed');
      expect(
        board.arrows.map((arrow) => arrow.tip.face).toSet(),
        containsAll(Face.values),
        reason: 'seed $seed must show arrows on every face',
      );
      expect(
        board.arrowAt(board.escapePoint.position),
        isNull,
        reason: 'seed $seed',
      );
      final topology = CubeSurfaceTopology(board.faceSize);
      for (final arrow in board.arrows) {
        expect(
          arrow.body.length,
          inInclusiveRange(1, 4),
          reason: 'seed $seed: ${arrow.id} body length',
        );
        expect(
          topology.traceTo(
            start: arrow.tip,
            direction: arrow.direction,
            goal: board.escapePoint.position,
          ),
          arrow.escapeRoute,
          reason: 'seed $seed: ${arrow.id} must follow its arrowhead',
        );
        // El cuerpo es la cadena detrás de la punta (puede cruzar caras).
        var current = arrow.tip;
        var walk = arrow.direction.opposite;
        for (final cell in arrow.body) {
          final step = topology.stepForward(current, walk);
          expect(step.position, cell, reason: 'seed $seed ${arrow.id} body link');
          current = step.position;
          walk = step.direction;
        }
      }

      for (final arrowId in level.solutionOrder) {
        final outcome = engine.attemptFire(board: board, arrowId: arrowId);
        expect(outcome.result.isExtracted, isTrue, reason: 'seed $seed: $arrowId');
        board = outcome.board;
      }
      expect(board.isCleared, isTrue, reason: 'seed $seed');
    }
  });

  test('some generated bodies span more than one face', () {
    var multiFaceBodies = 0;
    for (var seed = 0; seed < 80; seed++) {
      final level = generator.generate(seed: seed);
      for (final arrow in level.board.arrows) {
        final faces = {arrow.tip.face, ...arrow.body.map((c) => c.face)};
        if (faces.length > 1) multiFaceBodies++;
      }
    }
    expect(multiFaceBodies, greaterThan(0));
  });

  test('exit varies across generated seeds and faces', () {
    final exits = {
      for (var seed = 0; seed < 40; seed++)
        generator.generate(seed: seed).board.escapePoint.position,
    };
    final faces = exits.map((position) => position.face).toSet();

    expect(exits.length, greaterThan(10));
    expect(faces.length, greaterThan(3));
  });

  test('surface topology crosses cube edges', () {
    const topology = CubeSurfaceTopology(3);
    // Fila 0 = borde superior de la cara; al subir se cruza hacia top.
    const frontTop = CubeSurfacePosition(
      face: Face.front,
      row: 0,
      column: 1,
    );

    expect(
      topology.neighbors(frontTop),
      contains(
        const CubeSurfacePosition(face: Face.top, row: 2, column: 1),
      ),
    );
  });
}
