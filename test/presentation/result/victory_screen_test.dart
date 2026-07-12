import 'package:arrow_maze_escape_puzzle/domain/domain.dart';
import 'package:arrow_maze_escape_puzzle/l10n/app_strings.dart';
import 'package:arrow_maze_escape_puzzle/presentation/result/result_screen_args.dart';
import 'package:arrow_maze_escape_puzzle/presentation/result/victory_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Level _buildWinnableLevel() {
  return const Level(
    id: Identifier('level-victory-test'),
    levelNumber: 1,
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

Game _buildWonGame() {
  final level = _buildWinnableLevel();
  final started = Game.fromLevel(
    gameId: const Identifier('g-victory'),
    playerId: const Identifier('p1'),
    level: level,
  ).start();

  return started.performMove(
    arrowId: started.board.arrows.first.id,
    movementEngine: const ArrowMovementEngine(collisionValidator: CollisionValidator()),
  ).game;
}

void main() {
  testWidgets('should_show_score_and_next_level_button_when_sync_succeeds', (tester) async {
    // Arrange
    final game = _buildWonGame();
    final nextLevel = _buildWinnableLevel();
    final args = VictoryScreenArgs(game: game, nextLevel: nextLevel);

    // Act
    await tester.pumpWidget(
      AppStringsScope(
        strings: const AppStringsEs(),
        child: MaterialApp(home: VictoryScreen(args: args)),
      ),
    );

    // Assert
    const strings = AppStringsEs();
    expect(find.text('${strings.scoreLabel}: ${game.score}'), findsOneWidget);
    expect(find.byKey(const ValueKey('victory-next-level')), findsOneWidget);
    expect(find.text(strings.progressSaved), findsOneWidget);
  });

  testWidgets('should_show_offline_notice_instead_of_raw_error_when_sync_fails', (tester) async {
    // Arrange: sync failed (e.g. offline) but the win was still recorded locally.
    final game = _buildWonGame();
    final args = VictoryScreenArgs(
      game: game,
      nextLevel: _buildWinnableLevel(),
      syncError: Exception('Network error calling http://test/progress/sync'),
    );

    // Act
    await tester.pumpWidget(
      AppStringsScope(
        strings: const AppStringsEs(),
        child: MaterialApp(home: VictoryScreen(args: args)),
      ),
    );

    // Assert: friendly offline message, not the raw exception, and next-level
    // button still available (local win was not lost).
    expect(find.text(const AppStringsEs().offlinePlayNotice), findsOneWidget);
    expect(find.byKey(const ValueKey('victory-next-level')), findsOneWidget);
  });

  testWidgets('should_hide_next_level_button_when_there_is_no_next_level', (tester) async {
    // Arrange: last level of the catalog, nextLevel is null.
    final game = _buildWonGame();
    final args = VictoryScreenArgs(game: game);

    // Act
    await tester.pumpWidget(
      AppStringsScope(
        strings: const AppStringsEs(),
        child: MaterialApp(home: VictoryScreen(args: args)),
      ),
    );

    // Assert
    expect(find.byKey(const ValueKey('victory-next-level')), findsNothing);
  });

  testWidgets('should_show_collectible_banner_when_a_collectible_is_unlocked', (tester) async {
    final game = _buildWonGame();
    final args = VictoryScreenArgs(
      game: game,
      newlyUnlockedCollectible: const MetaCollectible(
        id: 'collectible-milestone-2',
        kind: MetaCollectibleKind.unlockable,
        milestoneLevelNumber: 2,
        assetPath: 'assets/images/collectibles/collectible-02.png',
      ),
    );

    await tester.pumpWidget(
      AppStringsScope(
        strings: const AppStringsEs(),
        child: MaterialApp(home: VictoryScreen(args: args)),
      ),
    );

    expect(
      find.text(const AppStringsEs().collectibleUnlockedMessage(2)),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('victory-collectible-announcement')), findsOneWidget);
  });
}
