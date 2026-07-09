import 'package:arrow_maze_escape_puzzle/domain/domain.dart';
import 'package:arrow_maze_escape_puzzle/l10n/app_strings.dart';
import 'package:arrow_maze_escape_puzzle/presentation/game/game_screen.dart';
import 'package:arrow_maze_escape_puzzle/presentation/level_select/level_select_screen.dart';
import 'package:arrow_maze_escape_puzzle/presentation/result/defeat_screen.dart';
import 'package:arrow_maze_escape_puzzle/presentation/result/result_screen_args.dart';
import 'package:arrow_maze_escape_puzzle/presentation/result/victory_screen.dart';
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
  /// Construye la app E2E con las mismas rutas que [ArrowMazeApp].
  ///
  /// `AppStringsScope` envuelve el `MaterialApp` completo (no `home`/una
  /// pantalla suelta): las rutas empujadas después son hermanas bajo el
  /// mismo `Navigator`, no descendientes de un scope colocado más adentro,
  /// así que cualquier pantalla que use textos localizados (todas) necesita
  /// el scope como ancestro real de la app, igual que en `main.dart`.
  Widget buildE2eApp() {
    final container = E2eAppFactory.createWithFullSeedCatalog();
    return AppStringsScope(
      strings: const AppStringsEn(),
      child: MaterialApp(
        initialRoute: '/levels',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/game':
              final level = settings.arguments as Level;
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => GameScreen(
                  controller: container.buildGameController(),
                  level: level,
                ),
              );
            case '/victory':
              final args = settings.arguments as VictoryScreenArgs;
              return MaterialPageRoute(settings: settings, builder: (_) => VictoryScreen(args: args));
            case '/defeat':
              final navArgs = settings.arguments as DefeatNavigationArgs;
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => DefeatScreen(
                  args: navArgs.screenArgs,
                  gameController: navArgs.gameController,
                ),
              );
            case '/levels':
            default:
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => LevelSelectScreen(
                  controller: container.buildLevelSelectController(),
                  authSessionController: container.authSessionController,
                ),
              );
          }
        },
      ),
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

    expect(find.byType(VictoryScreen), findsOneWidget);
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

    expect(find.byType(DefeatScreen), findsOneWidget);
  });
}
