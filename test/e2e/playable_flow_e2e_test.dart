import 'package:arrow_maze_escape_puzzle/domain/domain.dart';
import 'package:arrow_maze_escape_puzzle/presentation/game/game_screen.dart';
import 'package:arrow_maze_escape_puzzle/presentation/level_select/level_select_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/e2e_app_factory.dart';

/// Desplaza la lista hasta que [levelId] sea visible (ListView virtualiza ítems).
Future<void> scrollToLevel(WidgetTester tester, String levelId) async {
  await tester.scrollUntilVisible(
    find.text(levelId),
    120,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

/// Flujo E2E de UI: lista remota → selección → juego → victoria/derrota.
void main() {
  /// Construye [MaterialApp] con las mismas rutas que [ArrowMazeApp] para E2E.
  Widget buildE2eApp() {
    final container = E2eAppFactory.createWithFullSeedCatalog();
    return MaterialApp(
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/game':
            final level = settings.arguments as Level;
            return MaterialPageRoute(
              builder: (_) => GameScreen(
                controller: container.buildGameController(),
                level: level,
              ),
            );
          case '/':
          default:
            return MaterialPageRoute(
              builder: (_) => LevelSelectScreen(
                controller: container.buildLevelSelectController(),
              ),
            );
        }
      },
    );
  }

  testWidgets('E2E UI: lista incluye level-02 y level-15 tras cargar API', (tester) async {
    await tester.pumpWidget(buildE2eApp());
    await tester.pumpAndSettle();

    expect(find.text('level-02'), findsOneWidget);
    await scrollToLevel(tester, 'level-15');
    expect(find.text('level-15'), findsOneWidget);
  });

  testWidgets('E2E UI: gana level-02 con un disparo', (tester) async {
    await tester.pumpWidget(buildE2eApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('level-02'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('cell-0-0')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('cell-0-0')));
    await tester.pumpAndSettle();

    expect(find.text('Level cleared!'), findsOneWidget);
  });

  testWidgets('E2E UI: derrota en level-09 al agotar parMoves', (tester) async {
    await tester.pumpWidget(buildE2eApp());
    await tester.pumpAndSettle();

    await scrollToLevel(tester, 'level-09');
    await tester.tap(find.text('level-09'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('cell-0-2')), findsOneWidget);

    for (var i = 0; i < 12; i++) {
      await tester.tap(find.byKey(const ValueKey('cell-0-2')));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(find.text('Level failed'), findsOneWidget);
  });
}
