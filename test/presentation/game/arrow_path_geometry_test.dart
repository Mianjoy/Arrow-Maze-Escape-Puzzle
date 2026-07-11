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
    test('should_place_head_tip_on_upward_cell_edge', () {
      const head = Position(row: 0, column: 3);
      const direction = Direction(ArrowDirection.up);

      final tip = ArrowPathGeometry.headTip(
        head: head,
        direction: direction,
        cellWidth: 40,
        cellHeight: 40,
        margin: 4,
      );

      expect(tip.dx, 140);
      expect(tip.dy, 4);
    });

    test('should_compute_head_base_behind_tip_along_direction', () {
      const direction = Direction(ArrowDirection.up);
      const tip = Offset(100, 4);

      final base = ArrowPathGeometry.headBase(
        tip: tip,
        direction: direction,
        headLength: 12,
      );

      expect(base.dx, closeTo(100, 0.001));
      expect(base.dy, closeTo(16, 0.001));
    });
  });
}
