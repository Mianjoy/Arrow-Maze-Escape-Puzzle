import 'package:arrow_maze_escape_puzzle/domain/domain.dart';
import 'package:arrow_maze_escape_puzzle/l10n/app_strings.dart';
import 'package:arrow_maze_escape_puzzle/presentation/mode3d/mode_3d_catalog.dart';
import 'package:arrow_maze_escape_puzzle/presentation/mode3d/mode_3d_face_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('should_extract_blocker_when_tapping_its_cell_on_face_map', (tester) async {
    var board = buildMode3dDemoBoard();
    const engine = CubePathMovementEngine();

    await tester.pumpWidget(
      AppStringsScope(
        strings: const AppStringsEs(),
        child: MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Mode3dFaceMap(
                  board: board,
                  onCellTap: (pos) {
                    setState(() {
                      board = engine.attemptFireAt(board: board, position: pos).board;
                    });
                  },
                );
              },
            ),
          ),
        ),
      ),
    );

    // Tip of blocker: FRONT (0,1)
    await tester.tap(find.byKey(const ValueKey('map-cell-front-0-1')));
    await tester.pumpAndSettle();

    expect(board.arrowAt(const CubeSurfacePosition(face: Face.front, row: 0, column: 1)), isNull);
    expect(board.arrows, hasLength(2));
  });
}
