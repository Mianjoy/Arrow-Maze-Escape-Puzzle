import 'package:arrow_maze_escape_puzzle/application/use_cases/fire_arrow_use_case.dart';
import 'package:arrow_maze_escape_puzzle/application/use_cases/start_game_use_case.dart';
import 'package:arrow_maze_escape_puzzle/domain/domain.dart';
import 'package:arrow_maze_escape_puzzle/presentation/game/game_controller.dart';
import 'package:arrow_maze_escape_puzzle/presentation/game/game_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../application/support/fake_repositories.dart';
import '../support/test_auth_session.dart';

/// Nivel de 1x2 con una única flecha en (0,0) apuntando a la derecha,
/// sin obstáculos: se extrae (y gana la partida) en un solo toque.
Level buildSingleArrowLevel() {
  return const Level(
    id: Identifier('level-widget-test'),
    difficulty: LevelDifficulty.easy,
    boardDefinition: LevelBoardDefinition(
      dimension: BoardDimension(rows: 1, columns: 2),
      cells: [
        LevelCellData(position: Position(row: 0, column: 0), direction: Direction(ArrowDirection.right)),
      ],
    ),
    playerStart: PlayerStart(position: Position(row: 0, column: 1)),
    parMoves: 3,
    optimalMoves: 1,
  );
}

void main() {
  testWidgets('renderiza el tablero y muestra el diálogo de victoria al vaciarlo', (tester) async {
    // Arrange
    final gameRepository = FakeGameRepository();
    final controller = GameController(
      startGameUseCase: StartGameUseCase(gameRepository: gameRepository),
      fireArrowUseCase: FireArrowUseCase(gameRepository: gameRepository),
      authSessionController: buildTestAuthSessionController(),
    );
    final level = buildSingleArrowLevel();

    // Act
    await tester.pumpWidget(
      MaterialApp(home: GameScreen(controller: controller, level: level)),
    );
    await tester.pumpAndSettle();

    // Assert: el tablero se renderizó con 2 celdas tocables.
    expect(find.byKey(const ValueKey('cell-0-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('cell-0-1')), findsOneWidget);

    // Act: tocar la celda con la flecha.
    await tester.tap(find.byKey(const ValueKey('cell-0-0')));
    await tester.pumpAndSettle();

    // Assert: el diálogo de victoria aparece.
    expect(find.text('Level cleared!'), findsOneWidget);
  });
}
