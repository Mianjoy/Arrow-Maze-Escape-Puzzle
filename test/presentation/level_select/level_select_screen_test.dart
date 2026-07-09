import 'package:arrow_maze_escape_puzzle/application/use_cases/ensure_initial_progress_use_case.dart';
import 'package:arrow_maze_escape_puzzle/application/use_cases/get_player_progress_use_case.dart';
import 'package:arrow_maze_escape_puzzle/application/use_cases/load_levels_use_case.dart';
import 'package:arrow_maze_escape_puzzle/domain/domain.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/progress/in_memory_player_progress_repository.dart';
import 'package:arrow_maze_escape_puzzle/l10n/app_strings.dart';
import 'package:arrow_maze_escape_puzzle/presentation/level_select/level_select_controller.dart';
import 'package:arrow_maze_escape_puzzle/presentation/level_select/level_select_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../application/support/fake_repositories.dart';
import '../support/test_auth_session.dart';

void main() {
  LevelSelectController buildController({
    required List<Level> levels,
    required Identifier playerId,
    InMemoryPlayerProgressRepository? progressRepo,
  }) {
    final repo = progressRepo ?? InMemoryPlayerProgressRepository();
    final levelRepo = FakeLevelRepository(levels);
    return LevelSelectController(
      loadLevelsUseCase: LoadLevelsUseCase(levelRepository: levelRepo),
      ensureInitialProgressUseCase: EnsureInitialProgressUseCase(
        levelRepository: levelRepo,
        progressRepository: repo,
      ),
      getPlayerProgressUseCase: GetPlayerProgressUseCase(progressRepository: repo),
      playerId: playerId,
    );
  }

  testWidgets('muestra los niveles cargados por el controlador', (tester) async {
    final level = buildTestLevel(id: 'level-01');
    final playerId = const Identifier('test-user');
    final progressRepo = InMemoryPlayerProgressRepository();
    await progressRepo.save(PlayerProgress(
      playerId: playerId,
      levels: {
        level.id: LevelProgress(levelId: level.id, status: LevelProgressStatus.unlocked),
      },
    ));

    final controller = buildController(
      levels: [level],
      playerId: playerId,
      progressRepo: progressRepo,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AppStringsScope(
          strings: const AppStringsEn(),
          child: LevelSelectScreen(
            controller: controller,
            authSessionController: buildTestAuthSessionController(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('level-01'), findsOneWidget);
  });

  testWidgets('navega a /game con el nivel elegido al tocar un item', (tester) async {
    final level = buildTestLevel(id: 'level-01');
    final playerId = const Identifier('test-user');
    final progressRepo = InMemoryPlayerProgressRepository();
    await progressRepo.save(PlayerProgress(
      playerId: playerId,
      levels: {
        level.id: LevelProgress(levelId: level.id, status: LevelProgressStatus.unlocked),
      },
    ));

    final controller = buildController(
      levels: [level],
      playerId: playerId,
      progressRepo: progressRepo,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AppStringsScope(
          strings: const AppStringsEn(),
          child: LevelSelectScreen(
            controller: controller,
            authSessionController: buildTestAuthSessionController(),
          ),
        ),
        onGenerateRoute: (settings) {
          if (settings.name == '/game') {
            final pushedLevel = settings.arguments as Level;
            return MaterialPageRoute(
              builder: (_) => Text('Game Screen for ${pushedLevel.id.value}'),
            );
          }
          return null;
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('level-01'));
    await tester.pumpAndSettle();

    expect(find.text('Game Screen for level-01'), findsOneWidget);
  });
}
