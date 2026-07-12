import 'package:arrow_maze_escape_puzzle/application/use_cases/fire_arrow_use_case.dart';
import 'package:arrow_maze_escape_puzzle/application/use_cases/start_game_use_case.dart';
import 'package:arrow_maze_escape_puzzle/domain/domain.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/audio/no_op_audio_service.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/settings/in_memory_app_settings.dart';
import 'package:arrow_maze_escape_puzzle/l10n/app_strings.dart';
import 'package:arrow_maze_escape_puzzle/presentation/game/game_controller.dart';
import 'package:arrow_maze_escape_puzzle/presentation/game/game_screen.dart';
import 'package:arrow_maze_escape_puzzle/presentation/result/result_screen_args.dart';
import 'package:arrow_maze_escape_puzzle/presentation/result/victory_screen.dart';
import 'package:arrow_maze_escape_puzzle/presentation/settings/app_settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../application/support/fake_repositories.dart';
import '../support/test_auth_session.dart';

AppSettingsController _buildTestSettingsController({bool hasSeenTutorial = true}) {
  final settings = InMemoryAppSettings();
  final controller = AppSettingsController(settings: settings);
  if (hasSeenTutorial) {
    settings.setHasSeenTutorial(true);
  }
  return controller;
}

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

/// Dos flechas independientes: extraer una no libera el tablero, así se puede
/// probar el reinicio a mitad de partida sin navegar a la pantalla de victoria.
Level buildTwoArrowLevel() {
  return const Level(
    id: Identifier('level-widget-test-restart'),
    difficulty: LevelDifficulty.easy,
    boardDefinition: LevelBoardDefinition(
      dimension: BoardDimension(rows: 2, columns: 2),
      cells: [
        LevelCellData(position: Position(row: 0, column: 0), direction: Direction(ArrowDirection.right)),
        LevelCellData(position: Position(row: 1, column: 0), direction: Direction(ArrowDirection.right)),
      ],
    ),
    playerStart: PlayerStart(position: Position(row: 0, column: 1)),
    parMoves: 5,
    optimalMoves: 2,
  );
}

/// Nivel 1 (dispara la condición del tutorial) con dos flechas independientes,
/// para poder observar el paso 2 (meta) sin navegar a victoria.
Level buildFirstLevelForTutorial() {
  return const Level(
    id: Identifier('level-1'),
    levelNumber: 1,
    difficulty: LevelDifficulty.easy,
    boardDefinition: LevelBoardDefinition(
      dimension: BoardDimension(rows: 2, columns: 2),
      cells: [
        LevelCellData(position: Position(row: 0, column: 0), direction: Direction(ArrowDirection.right)),
        LevelCellData(position: Position(row: 1, column: 0), direction: Direction(ArrowDirection.right)),
      ],
    ),
    playerStart: PlayerStart(position: Position(row: 0, column: 1)),
    parMoves: 5,
    optimalMoves: 2,
  );
}

void main() {
  testWidgets('should_navigate_to_victory_screen_when_board_is_cleared', (tester) async {
    final gameRepository = FakeGameRepository();
    final controller = GameController(
      startGameUseCase: StartGameUseCase(gameRepository: gameRepository),
      fireArrowUseCase: FireArrowUseCase(gameRepository: gameRepository),
      authSessionController: buildTestAuthSessionController(),
      audioService: NoOpAudioService(),
    );
    final level = buildSingleArrowLevel();

    // AppStringsScope debe envolver el MaterialApp completo (no solo `home`):
    // las rutas empujadas después (p. ej. `/victory`) son hermanas de `home`
    // bajo el mismo Navigator, no descendientes de su subárbol, así que un
    // scope colocado solo dentro de `home` no las alcanza.
    await tester.pumpWidget(
      AppStringsScope(
        strings: const AppStringsEn(),
        child: MaterialApp(
          home: GameScreen(
            controller: controller,
            level: level,
            settingsController: _buildTestSettingsController(),
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
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('cell-0-0')));
    await tester.pumpAndSettle();

    expect(find.byType(VictoryScreen), findsOneWidget);
  });

  testWidgets('should_keep_progress_when_restart_is_cancelled_and_reset_it_when_confirmed', (tester) async {
    final gameRepository = FakeGameRepository();
    final controller = GameController(
      startGameUseCase: StartGameUseCase(gameRepository: gameRepository),
      fireArrowUseCase: FireArrowUseCase(gameRepository: gameRepository),
      authSessionController: buildTestAuthSessionController(),
      audioService: NoOpAudioService(),
    );
    final level = buildTwoArrowLevel();

    await tester.pumpWidget(
      AppStringsScope(
        strings: const AppStringsEn(),
        child: MaterialApp(
          home: GameScreen(
            controller: controller,
            level: level,
            settingsController: _buildTestSettingsController(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Extrae una de las dos flechas: la partida sigue en curso.
    await tester.tap(find.byKey(const ValueKey('cell-0-0')));
    await tester.pumpAndSettle();
    expect(controller.game!.moveCount, 1);

    // Cancelar el reinicio no debe alterar el progreso.
    await tester.tap(find.byKey(const ValueKey('board-restart')));
    await tester.pumpAndSettle();
    expect(find.text(const AppStringsEn().restartLevelConfirmTitle), findsOneWidget);
    await tester.tap(find.text(const AppStringsEn().cancel));
    await tester.pumpAndSettle();
    expect(controller.game!.moveCount, 1);

    // Confirmar el reinicio debe volver la partida a su estado inicial.
    await tester.tap(find.byKey(const ValueKey('board-restart')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(const AppStringsEn().retry));
    await tester.pumpAndSettle();
    expect(controller.game!.moveCount, 0);
  });

  testWidgets('should_show_tutorial_on_level_1_the_first_time_and_advance_by_tapping', (tester) async {
    final gameRepository = FakeGameRepository();
    final controller = GameController(
      startGameUseCase: StartGameUseCase(gameRepository: gameRepository),
      fireArrowUseCase: FireArrowUseCase(gameRepository: gameRepository),
      authSessionController: buildTestAuthSessionController(),
      audioService: NoOpAudioService(),
    );
    final level = buildFirstLevelForTutorial();
    final settingsController = _buildTestSettingsController(hasSeenTutorial: false);

    await tester.pumpWidget(
      AppStringsScope(
        strings: const AppStringsEn(),
        child: MaterialApp(
          home: GameScreen(
            controller: controller,
            level: level,
            settingsController: settingsController,
          ),
        ),
      ),
    );
    // No se usa `pumpAndSettle`: el anillo pulsante del tutorial corre en
    // bucle (`AnimationController.repeat`) y nunca "se asienta".
    await tester.pump();

    expect(find.text(const AppStringsEn().tutorialTapArrowHint), findsOneWidget);
    expect(settingsController.hasSeenTutorial, isFalse);

    // Tocar una flecha real avanza al paso 2 (meta) y, tras el auto-cierre,
    // persiste que el tutorial ya se vio.
    await tester.tap(find.byKey(const ValueKey('cell-0-0')));
    await tester.pump();
    expect(find.text(const AppStringsEn().tutorialGoalHint), findsOneWidget);

    // Deja pasar el auto-desvanecido (~2.5s) y el frame que remueve el
    // overlay (y con él, el `AnimationController` en bucle).
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text(const AppStringsEn().tutorialGoalHint), findsNothing);
    expect(settingsController.hasSeenTutorial, isTrue);
  });

  testWidgets('should_dismiss_tutorial_immediately_when_skipped', (tester) async {
    final gameRepository = FakeGameRepository();
    final controller = GameController(
      startGameUseCase: StartGameUseCase(gameRepository: gameRepository),
      fireArrowUseCase: FireArrowUseCase(gameRepository: gameRepository),
      authSessionController: buildTestAuthSessionController(),
      audioService: NoOpAudioService(),
    );
    final level = buildFirstLevelForTutorial();
    final settingsController = _buildTestSettingsController(hasSeenTutorial: false);

    await tester.pumpWidget(
      AppStringsScope(
        strings: const AppStringsEn(),
        child: MaterialApp(
          home: GameScreen(
            controller: controller,
            level: level,
            settingsController: settingsController,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('tutorial-skip')));
    await tester.pumpAndSettle();

    expect(find.text(const AppStringsEn().tutorialTapArrowHint), findsNothing);
    expect(settingsController.hasSeenTutorial, isTrue);
  });

  testWidgets('should_not_show_tutorial_when_already_seen_or_not_level_1', (tester) async {
    final gameRepository = FakeGameRepository();
    final controller = GameController(
      startGameUseCase: StartGameUseCase(gameRepository: gameRepository),
      fireArrowUseCase: FireArrowUseCase(gameRepository: gameRepository),
      authSessionController: buildTestAuthSessionController(),
      audioService: NoOpAudioService(),
    );
    final level = buildFirstLevelForTutorial();

    // Ya visto: no debe aparecer aunque sea el nivel 1.
    await tester.pumpWidget(
      AppStringsScope(
        strings: const AppStringsEn(),
        child: MaterialApp(
          home: GameScreen(
            controller: controller,
            level: level,
            settingsController: _buildTestSettingsController(hasSeenTutorial: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(const AppStringsEn().tutorialTapArrowHint), findsNothing);
  });
}
