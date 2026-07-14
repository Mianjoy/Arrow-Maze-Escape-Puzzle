import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_maze_escape_puzzle/domain/domain.dart';
import 'package:arrow_maze_escape_puzzle/presentation/mode3d/mode_3d_catalog.dart';

void main() {
  group('CubePathArrow multi-face', () {
    test('should_allow_tip_and_body_on_different_faces', () {
      final board = buildMode3dDemoBoard();
      final bridge = board.arrowById(const Identifier('bridge'));

      expect(bridge.tip.face, Face.front);
      expect(bridge.body.single.face, Face.top);
      expect(bridge.escapeRoute.last, board.escapePoint.position);
    });
  });

  group('CubePathMovementEngine', () {
    const engine = CubePathMovementEngine();

    test('should_block_bridge_while_blocker_occupies_escape_route', () {
      final board = buildMode3dDemoBoard();

      final outcome = engine.attemptFire(
        board: board,
        arrowId: const Identifier('bridge'),
      );

      expect(outcome.result.isBlocked, isTrue);
      expect(outcome.board.arrows, hasLength(3));
    });

    test('should_extract_through_escape_point_when_route_is_clear', () {
      var board = buildMode3dDemoBoard();

      final first = engine.attemptFire(board: board, arrowId: const Identifier('blocker'));
      expect(first.result.isExtracted, isTrue);
      board = first.board;

      final second = engine.attemptFire(board: board, arrowId: const Identifier('bridge'));
      expect(second.result.isExtracted, isTrue);
      board = second.board;

      final third = engine.attemptFire(board: board, arrowId: const Identifier('corner'));
      expect(third.result.isExtracted, isTrue);
      expect(third.board.isCleared, isTrue);
    });

    test('should_fire_when_tapping_body_on_other_face', () {
      var board = buildMode3dDemoBoard();
      board = engine.attemptFire(board: board, arrowId: const Identifier('blocker')).board;

      final outcome = engine.attemptFireAt(
        board: board,
        position: const CubeSurfacePosition(face: Face.top, row: 2, column: 1),
      );

      expect(outcome.result.isExtracted, isTrue);
      expect(outcome.result.arrowId, const Identifier('bridge'));
    });
  });
}
