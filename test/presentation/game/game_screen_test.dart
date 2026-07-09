import 'package:arrow_maze_escape_puzzle/application/use_cases/fire_arrow_use_case.dart';
import 'package:arrow_maze_escape_puzzle/application/use_cases/start_game_use_case.dart';
import 'package:arrow_maze_escape_puzzle/domain/domain.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/audio/no_op_audio_service.dart';
import 'package:arrow_maze_escape_puzzle/l10n/app_strings.dart';
import 'package:arrow_maze_escape_puzzle/presentation/game/game_controller.dart';
import 'package:arrow_maze_escape_puzzle/presentation/game/game_screen.dart';
import 'package:arrow_maze_escape_puzzle/presentation/result/result_screen_args.dart';
import 'package:arrow_maze_escape_puzzle/presentation/result/victory_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../application/support/fake_repositories.dart';
import '../support/test_auth_session.dart';

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
  testWidgets('navega a pantalla de victoria al vaciar el tablero', (tester) async {
    final gameRepository = FakeGameRepository();
    final controller = GameController(
      startGameUseCase: StartGameUseCase(gameRepository: gameRepository),
      fireArrowUseCase: FireArrowUseCase(gameRepository: gameRepository),
      authSessionController: buildTestAuthSessionController(),
      audioService: NoOpAudioService(),
    );
    final level = buildSingleArrowLevel();

    await tester.pumpWidget(
      MaterialApp(
        home: AppStringsScope(
          strings: const AppStringsEn(),
          child: GameScreen(controller: controller, level: level),
        ),
        onGenerateRoute: (settings) {
          if (settings.name == '/victory') {
            return MaterialPageRoute(
              builder: (_) => VictoryScreen(args: settings.arguments as VictoryScreenArgs),
            );
          }
          return null;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('cell-0-0')));
    await tester.pumpAndSettle();

    expect(find.text('Level cleared!'), findsOneWidget);
  });
}
