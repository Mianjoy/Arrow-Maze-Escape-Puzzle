import 'dart:convert';

import 'package:arrow_maze_escape_puzzle/application/models/auth_session.dart';
import 'package:arrow_maze_escape_puzzle/application/use_cases/pull_remote_progress_use_case.dart';
import 'package:arrow_maze_escape_puzzle/domain/domain.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/http/api_config.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/http/progress_api_client.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/progress/in_memory_player_progress_repository.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../../application/support/fake_repositories.dart';
import '../../support/mock_http_client.dart';

/// Pruebas de [PullRemoteProgressUseCase]: descarga y fusión del progreso
/// remoto con el local al iniciar sesión.
void main() {
  const session = AuthSession(token: 'tok', userId: 'u1', username: 'p1');
  const config = ApiConfig(baseUrl: 'http://test');

  Level level(String id, int number) => Level(
        id: Identifier(id),
        levelNumber: number,
        difficulty: LevelDifficulty.easy,
        boardDefinition: const LevelBoardDefinition(
          dimension: BoardDimension(rows: 2, columns: 2),
          cells: [],
        ),
        playerStart: const PlayerStart(position: Position(row: 0, column: 0)),
        parMoves: 5,
        optimalMoves: 1,
      );

  test(
      'should_merge_remote_completed_levels_into_local_progress',
      () async {
    // Arrange: el servidor reporta level-01 completado.
    final client = MockHttpClient((request) async {
      expect(request.url.path, '/progress');
      return http.Response(
        jsonEncode({
          'userId': 'u1',
          'levels': [
            {
              'userId': 'u1',
              'levelId': 'level-01',
              'highScore': 100,
              'minMoves': 3,
              'minTimeInSeconds': 10,
              'isCompleted': true,
            },
          ],
          'collectibles': ['collectible-milestone-2'],
        }),
        200,
      );
    });

    final progressRepo = InMemoryPlayerProgressRepository();
    final levelRepo = FakeLevelRepository([
      level('level-01', 1),
      level('level-02', 2),
    ]);

    final useCase = PullRemoteProgressUseCase(
      progressApiClient: ProgressApiClient(config: config, httpClient: client),
      progressRepository: progressRepo,
      levelRepository: levelRepo,
    );

    // Act
    final merged = await useCase.execute(session);

    // Assert: level-01 completado y level-02 desbloqueado (cadena de progresión).
    expect(merged.progressFor(const Identifier('level-01'))?.status, LevelProgressStatus.completed);
    expect(merged.progressFor(const Identifier('level-02'))?.status, LevelProgressStatus.unlocked);
    expect(merged.hasCollectible('collectible-milestone-2'), isTrue);
    // Persistido.
    final saved = await progressRepo.findByPlayerId(session.playerId);
    expect(saved?.progressFor(const Identifier('level-01'))?.status, LevelProgressStatus.completed);
  });

  test(
      'should_throw_when_server_is_unreachable',
      () async {
    // Arrange
    final client = MockHttpClient((request) async => http.Response('down', 500));

    final useCase = PullRemoteProgressUseCase(
      progressApiClient: ProgressApiClient(config: config, httpClient: client),
      progressRepository: InMemoryPlayerProgressRepository(),
      levelRepository: FakeLevelRepository([level('level-01', 1)]),
    );

    // Act & Assert: el llamador (controller) lo trata como modo offline.
    expect(() => useCase.execute(session), throwsA(isA<Object>()));
  });
}
