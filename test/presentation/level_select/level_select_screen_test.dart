import 'package:arrow_maze_escape_puzzle/application/use_cases/load_levels_use_case.dart';
import 'package:arrow_maze_escape_puzzle/domain/domain.dart';
import 'package:arrow_maze_escape_puzzle/presentation/level_select/level_select_controller.dart';
import 'package:arrow_maze_escape_puzzle/presentation/level_select/level_select_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../application/support/fake_repositories.dart';

void main() {
  testWidgets('muestra los niveles cargados por el controlador', (tester) async {
    // Arrange
    final level = buildTestLevel(id: 'level-01');
    final controller = LevelSelectController(
      loadLevelsUseCase: LoadLevelsUseCase(levelRepository: FakeLevelRepository([level])),
    );

    // Act
    await tester.pumpWidget(
      MaterialApp(home: LevelSelectScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('level-01'), findsOneWidget);
  });

  testWidgets('navega a /game con el nivel elegido al tocar un item', (tester) async {
    // Arrange
    final level = buildTestLevel(id: 'level-01');
    final controller = LevelSelectController(
      loadLevelsUseCase: LoadLevelsUseCase(levelRepository: FakeLevelRepository([level])),
    );

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: LevelSelectScreen(controller: controller),
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

    // Assert
    expect(find.text('Game Screen for level-01'), findsOneWidget);
  });
}
