import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_maze_escape_puzzle/domain/domain.dart';

void main() {
  const topology = CubeSurfaceTopology(3);

  test('crossing an edge always lands on an adjacent face cell', () {
    for (final face in Face.values) {
      for (final dir in ArrowDirection.values) {
        for (var row = 0; row < 3; row++) {
          for (var col = 0; col < 3; col++) {
            final start = CubeSurfacePosition(face: face, row: row, column: col);
            final step = topology.stepForward(start, Direction(dir));
            final next = step.position;
            if (next.face == face) continue;

            expect(
              topology.neighbors(start),
              contains(next),
              reason: '$start $dir -> $next must be a topological neighbor',
            );
            // Nunca saltar a la cara opuesta en un solo paso.
            expect(
              _isOpposite(face, next.face),
              isFalse,
              reason: '$start $dir jumped to opposite face ${next.face}',
            );
          }
        }
      }
    }
  });

  test('body behind tip forms a contiguous neighbor chain', () {
    // Punta en el borde inferior del frente mirando arriba → el cuerpo baja
    // y cruza a Bottom (cara adyacente al borde).
    const tip = CubeSurfacePosition(face: Face.front, row: 2, column: 1);
    const tipDir = Direction(ArrowDirection.up);
    var current = tip;
    var walk = tipDir.opposite;
    final body = <CubeSurfacePosition>[];
    for (var i = 0; i < 4; i++) {
      final step = topology.stepForward(current, walk);
      expect(
        topology.neighbors(current),
        contains(step.position),
        reason: 'body link $current -> ${step.position}',
      );
      expect(
        _isOpposite(current.face, step.position.face),
        isFalse,
        reason: 'single step must not land on opposite face',
      );
      body.add(step.position);
      current = step.position;
      walk = step.direction;
    }
    expect(
      body.first,
      const CubeSurfacePosition(face: Face.bottom, row: 0, column: 1),
    );
  });

  test('generated multi-face bodies stay contiguous', () {
    const generator = CubeSurfaceLevelGenerator(faceSize: 3, arrowCount: 6);
    for (var seed = 0; seed < 50; seed++) {
      final level = generator.generate(seed: seed);
      for (final arrow in level.board.arrows) {
        final shaft = [arrow.tip, ...arrow.body];
        for (var i = 0; i < shaft.length - 1; i++) {
          expect(
            topology.neighbors(shaft[i]),
            contains(shaft[i + 1]),
            reason: 'seed $seed ${arrow.id}: ${shaft[i]} -> ${shaft[i + 1]}',
          );
        }
      }
    }
  });

  test('top and bottom side wraps track the edge position', () {
    expect(
      topology
          .stepForward(
            const CubeSurfacePosition(face: Face.top, row: 1, column: 2),
            const Direction(ArrowDirection.right),
          )
          .position,
      const CubeSurfacePosition(face: Face.right, row: 0, column: 1),
    );
    expect(
      topology
          .stepForward(
            const CubeSurfacePosition(face: Face.bottom, row: 1, column: 0),
            const Direction(ArrowDirection.left),
          )
          .position,
      const CubeSurfacePosition(face: Face.left, row: 2, column: 1),
    );
  });
}

bool _isOpposite(Face a, Face b) => switch ((a, b)) {
      (Face.front, Face.back) || (Face.back, Face.front) => true,
      (Face.left, Face.right) || (Face.right, Face.left) => true,
      (Face.top, Face.bottom) || (Face.bottom, Face.top) => true,
      _ => false,
    };
