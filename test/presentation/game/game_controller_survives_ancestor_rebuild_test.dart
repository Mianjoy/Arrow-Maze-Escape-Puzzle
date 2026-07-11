import 'package:arrow_maze_escape_puzzle/application/use_cases/fire_arrow_use_case.dart';
import 'package:arrow_maze_escape_puzzle/application/use_cases/start_game_use_case.dart';
import 'package:arrow_maze_escape_puzzle/domain/domain.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/audio/no_op_audio_service.dart';
import 'package:arrow_maze_escape_puzzle/l10n/app_strings.dart';
import 'package:arrow_maze_escape_puzzle/presentation/game/game_controller.dart';
import 'package:arrow_maze_escape_puzzle/presentation/game/game_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../application/support/fake_repositories.dart';
import '../support/test_auth_session.dart';

/// `ChangeNotifier` de ejemplo para simular `AppSettingsController`: un
/// ancestro (como `_ArrowMazeAppState`) hace `setState` en cada cambio.
class _FakeAppSettings extends ChangeNotifier {
  void toggleMuted() => notifyListeners();
}

/// Reproduce la estructura real de `ArrowMazeApp`/`_ArrowMazeAppState` en
/// `main.dart`: un `StatefulWidget` que escucha el controlador de ajustes y
/// hace `setState({})` en cada cambio, envolviendo el `MaterialApp` completo
/// — incluyendo las rutas ya empujadas (como el juego, debajo de Ajustes).
class _Harness extends StatefulWidget {
  const _Harness({required this.settings, required this.onGenerateRoute});
  final _FakeAppSettings settings;
  final RouteFactory onGenerateRoute;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  @override
  void initState() {
    super.initState();
    widget.settings.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.settings.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return AppStringsScope(
      strings: const AppStringsEn(),
      child: MaterialApp(initialRoute: '/game', onGenerateRoute: widget.onGenerateRoute),
    );
  }
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

void main() {
  /// `MaterialPageRoute.builder` se reinvoca en cada rebuild de cualquier
  /// ancestro del `Navigator` (p. ej. `ArrowMazeApp` al cambiar ajustes) —
  /// no una sola vez por navegación como podría asumirse. Si el `builder`
  /// construye un `GameController` nuevo cada vez (como hacía
  /// `_onGenerateRoute` para `/game` antes de este fix), esa instancia nueva
  /// y nunca inicializada reemplaza a la que ya arrancó la partida, dejando
  /// el tablero en blanco (spinner infinito) — reproducido y explicado en la
  /// consulta del usuario "el tablero ya no se ve al volver de Ajustes".
  testWidgets(
    'should_keep_same_game_controller_when_ancestor_rebuilds_while_route_is_covered',
    (tester) async {
      final gameRepository = FakeGameRepository();
      final level = buildSingleArrowLevel();
      final settings = _FakeAppSettings();

      GameController buildGameController() => GameController(
            startGameUseCase: StartGameUseCase(gameRepository: gameRepository),
            fireArrowUseCase: FireArrowUseCase(gameRepository: gameRepository),
            authSessionController: buildTestAuthSessionController(),
            audioService: NoOpAudioService(),
          );

      Route<dynamic>? onGenerateRoute(RouteSettings routeSettings) {
        switch (routeSettings.name) {
          case '/game':
            // Construido UNA vez por navegación, fuera de `builder:` — el
            // mismo patrón aplicado en `main.dart` para corregir el bug.
            final gameController = buildGameController();
            return MaterialPageRoute(
              settings: routeSettings,
              builder: (_) => GameScreen(controller: gameController, level: level),
            );
          case '/settings':
            return MaterialPageRoute(
              settings: routeSettings,
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Settings')),
                body: ElevatedButton(
                  key: const ValueKey('toggle-mute'),
                  onPressed: settings.toggleMuted,
                  child: const Text('Mute'),
                ),
              ),
            );
        }
        return null;
      }

      await tester.pumpWidget(_Harness(settings: settings, onGenerateRoute: onGenerateRoute));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const ValueKey('cell-0-0')), findsOneWidget);

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pushNamed('/settings');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Simula togglear el mute mientras la partida sigue activa detrás:
      // dispara `notifyListeners()` en el `ChangeNotifier` que el ancestro
      // (`ArrowMazeApp`) escucha, causando su `setState`.
      await tester.tap(find.byKey(const ValueKey('toggle-mute')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      navigator.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.byKey(const ValueKey('cell-0-0')),
        findsOneWidget,
        reason: 'el tablero debe seguir visible al volver de Ajustes tras un cambio de settings',
      );
    },
  );
}
