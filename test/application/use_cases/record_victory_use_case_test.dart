import 'package:arrow_maze_escape_puzzle/application/models/auth_session.dart';
import 'package:arrow_maze_escape_puzzle/application/use_cases/record_victory_use_case.dart';
import 'package:arrow_maze_escape_puzzle/domain/domain.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/http/api_config.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/http/progress_api_client.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/progress/in_memory_pending_sync_repository.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/progress/in_memory_player_progress_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../application/support/fake_repositories.dart';
import '../../support/mock_http_client.dart';

Level buildWinnableLevel({String id = 'level-01', int? levelNumber}) {
  return Level(
    id: Identifier(id),
    levelNumber: levelNumber ?? 1,
    difficulty: LevelDifficulty.easy,
    boardDefinition: const LevelBoardDefinition(
      dimension: BoardDimension(rows: 1, columns: 2),
      cells: [
        LevelCellData(position: Position(row: 0, column: 0), direction: Direction(ArrowDirection.right)),
      ],
    ),
    playerStart: const PlayerStart(position: Position(row: 0, column: 1)),
    parMoves: 3,
    optimalMoves: 1,
  );
}

void main() {
  const session = AuthSession(token: 'tok', userId: 'u1', username: 'p1');
  const config = ApiConfig(baseUrl: 'http://test');

  test('should_save_local_progress_and_call_POST_progress_sync', () async {
    var syncCalled = false;
    final client = MockHttpClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/progress/sync');
      syncCalled = true;
      return http.Response('{}', 200);
    });

    final levelRepo = FakeLevelRepository([
      buildWinnableLevel(id: 'level-01', levelNumber: 1),
      buildWinnableLevel(id: 'level-02', levelNumber: 2),
    ]);

    final useCase = RecordVictoryUseCase(
      progressRepository: InMemoryPlayerProgressRepository(),
      levelRepository: levelRepo,
      progressApiClient: ProgressApiClient(config: config, httpClient: client),
      pendingSyncRepository: InMemoryPendingSyncRepository(),
    );

    final level = buildWinnableLevel();
    final started = Game.fromLevel(
      gameId: const Identifier('g1'),
      playerId: session.playerId,
      level: level,
    ).start();

    final won = started.performMove(
      arrowId: started.board.arrows.first.id,
      movementEngine: const ArrowMovementEngine(collisionValidator: CollisionValidator()),
    ).game;

    expect(won.isWon, isTrue);

    final result = await useCase.execute(game: won, session: session);

    expect(syncCalled, isTrue);
    expect(result.nextLevel?.id.value, 'level-02');
  });

  test(
      'should_unlock_next_level_locally_when_progress_sync_fails',
      () async {
    // Arrange: backend inalcanzable — cada intento de red falla.
    final client = MockHttpClient((request) async {
      return http.Response('backend down', 500);
    });

    final levelRepo = FakeLevelRepository([
      buildWinnableLevel(id: 'level-01', levelNumber: 1),
      buildWinnableLevel(id: 'level-02', levelNumber: 2),
    ]);

    final pendingSyncRepository = InMemoryPendingSyncRepository();
    final useCase = RecordVictoryUseCase(
      progressRepository: InMemoryPlayerProgressRepository(),
      levelRepository: levelRepo,
      progressApiClient: ProgressApiClient(config: config, httpClient: client),
      pendingSyncRepository: pendingSyncRepository,
    );

    final level = buildWinnableLevel();
    final started = Game.fromLevel(
      gameId: const Identifier('g1'),
      playerId: session.playerId,
      level: level,
    ).start();

    final won = started.performMove(
      arrowId: started.board.arrows.first.id,
      movementEngine: const ArrowMovementEngine(collisionValidator: CollisionValidator()),
    ).game;

    // Act
    final result = await useCase.execute(game: won, session: session);

    // Assert: progreso y desbloqueo locales no dependen de que el sync tenga éxito.
    expect(result.syncError, isNotNull);
    expect(result.nextLevel?.id.value, 'level-02');
    expect(result.progress.progressFor(level.id)?.status, LevelProgressStatus.completed);

    // Assert: la sincronización fallida quedó encolada para reintentar después.
    final pending = await pendingSyncRepository.loadAll();
    expect(pending, hasLength(1));
    expect(pending.single.levelId, level.id);
    expect(pending.single.playerId, session.playerId);
  });

  test('should_unlock_collectible_when_even_level_is_cleared_with_three_stars', () async {
    final client = MockHttpClient((request) async => http.Response('{}', 200));

    final levelRepo = FakeLevelRepository([
      buildWinnableLevel(id: 'level-02', levelNumber: 2),
      buildWinnableLevel(id: 'level-03', levelNumber: 3),
    ]);

    final useCase = RecordVictoryUseCase(
      progressRepository: InMemoryPlayerProgressRepository(),
      levelRepository: levelRepo,
      progressApiClient: ProgressApiClient(config: config, httpClient: client),
      pendingSyncRepository: InMemoryPendingSyncRepository(),
    );

    final level = buildWinnableLevel(id: 'level-02', levelNumber: 2);
    final started = Game.fromLevel(
      gameId: const Identifier('g-collectible'),
      playerId: session.playerId,
      level: level,
    ).start();

    final won = started.performMove(
      arrowId: started.board.arrows.first.id,
      movementEngine: const ArrowMovementEngine(collisionValidator: CollisionValidator()),
    ).game;

    expect(won.isWon, isTrue);
    expect(won.starsEarned, StarRating.three);

    final result = await useCase.execute(game: won, session: session);

    expect(result.newlyUnlockedCollectible?.milestoneLevelNumber, 2);
    expect(result.progress.hasCollectible('collectible-milestone-2'), isTrue);
  });
}
