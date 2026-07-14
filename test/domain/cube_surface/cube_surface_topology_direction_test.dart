import 'package:arrow_maze_escape_puzzle/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const topology = CubeSurfaceTopology(3);

  test('first step always matches arrow direction on all faces', () {
    for (final face in Face.values) {
      for (final arrowDirection in ArrowDirection.values) {
        final start = CubeSurfacePosition(face: face, row: 1, column: 1);
        final step = topology.stepForward(start, Direction(arrowDirection));
        expect(
          topology.directionBetween(start, step.position).arrowDirection,
          arrowDirection,
          reason: '$face $arrowDirection -> ${step.position}',
        );
      }
    }
  });

  test('front up goes to top and down goes to bottom', () {
    expect(
      topology
          .stepForward(
            const CubeSurfacePosition(face: Face.front, row: 0, column: 1),
            const Direction(ArrowDirection.up),
          )
          .position,
      const CubeSurfacePosition(face: Face.top, row: 2, column: 1),
    );
    expect(
      topology
          .stepForward(
            const CubeSurfacePosition(face: Face.front, row: 2, column: 1),
            const Direction(ArrowDirection.down),
          )
          .position,
      const CubeSurfacePosition(face: Face.bottom, row: 0, column: 1),
    );
  });

  test('generated routes start in the tip direction', () {
    const generator = CubeSurfaceLevelGenerator(faceSize: 3, arrowCount: 6);
    for (var seed = 0; seed < 30; seed++) {
      final level = generator.generate(seed: seed);
      for (final arrow in level.board.arrows) {
        final first = arrow.escapeRoute.first;
        expect(
          topology.directionBetween(arrow.tip, first),
          arrow.direction,
          reason: 'seed $seed ${arrow.id}',
        );
        expect(
          topology.traceTo(
            start: arrow.tip,
            direction: arrow.direction,
            goal: level.board.escapePoint.position,
          ),
          arrow.escapeRoute,
          reason: 'seed $seed ${arrow.id} full route',
        );
      }
    }
  });
}
