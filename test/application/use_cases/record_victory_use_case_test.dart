import 'dart:convert';

import 'package:arrow_maze_escape_puzzle/application/models/auth_session.dart';
import 'package:arrow_maze_escape_puzzle/application/use_cases/record_victory_use_case.dart';
import 'package:arrow_maze_escape_puzzle/domain/domain.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/http/api_config.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/http/progress_api_client.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/progress/in_memory_player_progress_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../support/mock_http_client.dart';

/// Nivel ganable en un solo movimiento para tests de sync.
Level buildWinnableLevel() {
  return const Level(
    id: Identifier('level-01'),
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
  const session = AuthSession(token: 'tok', userId: 'u1', username: 'p1');
  const config = ApiConfig(baseUrl: 'http://test');

  test('RecordVictoryUseCase guarda progreso local y llama POST /progress/sync', () async {
    var syncCalled = false;
    final client = MockHttpClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/progress/sync');
      expect(request.headers['Authorization'], 'Bearer tok');
      syncCalled = true;
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['levelId'], 'level-01');
      expect(body['completed'], isTrue);
      return http.Response('{}', 200);
    });

    final useCase = RecordVictoryUseCase(
      progressRepository: InMemoryPlayerProgressRepository(),
      progressApiClient: ProgressApiClient(config: config, httpClient: client),
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

    await useCase.execute(game: won, session: session);

    expect(syncCalled, isTrue);
  });
}
