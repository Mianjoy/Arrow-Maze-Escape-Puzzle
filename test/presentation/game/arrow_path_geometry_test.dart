import 'package:arrow_maze_escape_puzzle/domain/domain.dart';
import 'package:arrow_maze_escape_puzzle/presentation/game/widgets/arrow_path_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ArrowPathGeometry', () {
    test('should_order_tail_to_head_for_straight_horizontal_arrow', () {
      const arrow = Arrow(
        id: Identifier('a1'),
        position: Position(row: 0, column: 0),
        direction: Direction(ArrowDirection.left),
        body: [Position(row: 0, column: 1)],
      );

      final ordered = ArrowPathGeometry.tailToHead(arrow);

      expect(ordered, [
        const Position(row: 0, column: 1),
        const Position(row: 0, column: 0),
      ]);
    });

    test('should_order_tail_to_head_for_L_shaped_arrow', () {
      const arrow = Arrow(
        id: Identifier('a2'),
        position: Position(row: 1, column: 3),
        direction: Direction(ArrowDirection.up),
        body: [
          Position(row: 2, column: 3),
          Position(row: 2, column: 2),
        ],
      );

      final ordered = ArrowPathGeometry.tailToHead(arrow);

      expect(ordered.first, const Position(row: 2, column: 2));
      expect(ordered.last, const Position(row: 1, column: 3));
      expect(ordered.length, 3);
    });
  });
}
