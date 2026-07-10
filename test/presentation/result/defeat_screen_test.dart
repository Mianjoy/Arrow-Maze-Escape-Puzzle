import 'package:arrow_maze_escape_puzzle/application/use_cases/fire_arrow_use_case.dart';
import 'package:arrow_maze_escape_puzzle/application/use_cases/start_game_use_case.dart';
import 'package:arrow_maze_escape_puzzle/domain/domain.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/audio/no_op_audio_service.dart';
import 'package:arrow_maze_escape_puzzle/l10n/app_strings.dart';
import 'package:arrow_maze_escape_puzzle/presentation/game/game_controller.dart';
import 'package:arrow_maze_escape_puzzle/presentation/result/defeat_screen.dart';
import 'package:arrow_maze_escape_puzzle/presentation/result/result_screen_args.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../application/support/fake_repositories.dart';
import '../support/test_auth_session.dart';

/// Nivel de 1 movimiento donde la flecha queda bloqueada por un muro, así
/// el único disparo posible agota `parMoves` sin vaciar el tablero: derrota
/// garantizada en un solo `performMove`, sin depender de bucles.
Level _buildLosableLevel() {
  return const Level(
    id: Identifier('level-defeat-test'),
    levelNumber: 1,
    difficulty: LevelDifficulty.easy,
    boardDefinition: LevelBoardDefinition(
      dimension: BoardDimension(rows: 1, columns: 2),
      cells: [
        LevelCellData(position: Position(row: 0, column: 0), direction: Direction(ArrowDirection.right)),
      ],
      walls: [Position(row: 0, column: 1)],
    ),
    playerStart: PlayerStart(position: Position(row: 0, column: 0)),
    parMoves: 1,
    optimalMoves: 1,
  );
}

Game _buildLostGame() {
  final level = _buildLosableLevel();
  final started = Game.fromLevel(
    gameId: const Identifier('g-defeat'),
    playerId: const Identifier('p1'),
    level: level,
  ).start();

  return started.performMove(
    arrowId: started.board.arrows.first.id,
    movementEngine: const ArrowMovementEngine(collisionValidator: CollisionValidator()),
  ).game;
}

void main() {
  testWidgets('should_show_loss_message_and_retry_button', (tester) async {
    // Arrange
    final gameRepository = FakeGameRepository();
    final controller = GameController(
      startGameUseCase: StartGameUseCase(gameRepository: gameRepository),
      fireArrowUseCase: FireArrowUseCase(gameRepository: gameRepository),
      authSessionController: buildTestAuthSessionController(),
      audioService: NoOpAudioService(),
    );
    final game = _buildLostGame();
    final args = DefeatNavigationArgs(
      screenArgs: DefeatScreenArgs(game: game),
      gameController: controller,
    );

    // Act
    await tester.pumpWidget(
      AppStringsScope(
        strings: const AppStringsEs(),
        child: MaterialApp(
          home: DefeatScreen(args: args.screenArgs, gameController: args.gameController),
        ),
      ),
    );

    // Assert
    expect(find.byKey(const ValueKey('defeat-retry')), findsOneWidget);
    expect(find.textContaining('perdido'), findsOneWidget);
  });

  testWidgets('should_push_a_fresh_game_route_for_the_same_level_when_retry_is_tapped', (tester) async {
    // Arrange
    final gameRepository = FakeGameRepository();
    final controller = GameController(
      startGameUseCase: StartGameUseCase(gameRepository: gameRepository),
      fireArrowUseCase: FireArrowUseCase(gameRepository: gameRepository),
      authSessionController: buildTestAuthSessionController(),
      audioService: NoOpAudioService(),
    );
    final lostGame = _buildLostGame();

    // No usamos `pop()` a propósito: en la app real, todo el flujo
    // Game→Victory→Game→...→Defeat usa `pushReplacementNamed`, así que
    // debajo de DefeatScreen sigue la instancia original de
    // LevelSelectScreen (con progreso desactualizado), no la partida. Este
    // fake router registra `/game` para capturar la intención de
    // navegación sin depender del wiring real de GameScreen.
    String? pushedRouteName;
    Object? pushedArguments;

    await tester.pumpWidget(
      AppStringsScope(
        strings: const AppStringsEs(),
        child: MaterialApp(
          initialRoute: '/defeat',
          onGenerateRoute: (settings) {
            if (settings.name == '/defeat') {
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => DefeatScreen(
                  args: DefeatScreenArgs(game: lostGame),
                  gameController: controller,
                ),
              );
            }
            pushedRouteName = settings.name;
            pushedArguments = settings.arguments;
            return MaterialPageRoute(settings: settings, builder: (_) => const SizedBox());
          },
        ),
      ),
    );

    // Act
    await tester.tap(find.byKey(const ValueKey('defeat-retry')));
    await tester.pumpAndSettle();

    // Assert: navigated to a fresh `/game` route for the same level, not
    // popped back to whatever sits below in the stack.
    expect(pushedRouteName, '/game');
    expect(pushedArguments, isA<Level>());
    expect((pushedArguments! as Level).id, lostGame.level.id);
  });
}
