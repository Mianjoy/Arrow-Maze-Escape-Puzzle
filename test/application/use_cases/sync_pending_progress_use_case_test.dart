import 'package:arrow_maze_escape_puzzle/application/models/auth_session.dart';
import 'package:arrow_maze_escape_puzzle/application/models/pending_sync_entry.dart';
import 'package:arrow_maze_escape_puzzle/application/use_cases/sync_pending_progress_use_case.dart';
import 'package:arrow_maze_escape_puzzle/domain/domain.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/http/api_config.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/http/progress_api_client.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/progress/in_memory_pending_sync_repository.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../../support/mock_http_client.dart';

/// Pruebas de [SyncPendingProgressUseCase]: drena la cola de
/// sincronizaciones pendientes cuando vuelve la red.
void main() {
  const session = AuthSession(token: 'tok', userId: 'u1', username: 'p1');
  const config = ApiConfig(baseUrl: 'http://test');

  test(
      'should_remove_entry_from_queue_when_sync_succeeds',
      () async {
    // Arrange
    final repo = InMemoryPendingSyncRepository();
    await repo.add(PendingSyncEntry(
      playerId: session.playerId,
      levelId: const Identifier('level-01'),
      score: 100,
      moves: 3,
      timeInSeconds: 20,
    ));

    var syncCalls = 0;
    final client = MockHttpClient((request) async {
      syncCalls++;
      return http.Response('{}', 200);
    });

    final useCase = SyncPendingProgressUseCase(
      pendingSyncRepository: repo,
      progressApiClient: ProgressApiClient(config: config, httpClient: client),
    );

    // Act
    await useCase.execute(session);

    // Assert
    expect(syncCalls, 1);
    expect(await repo.loadAll(), isEmpty);
  });

  test(
      'should_keep_entry_in_queue_when_sync_still_fails',
      () async {
    // Arrange
    final repo = InMemoryPendingSyncRepository();
    await repo.add(PendingSyncEntry(
      playerId: session.playerId,
      levelId: const Identifier('level-01'),
      score: 100,
      moves: 3,
      timeInSeconds: 20,
    ));

    final client = MockHttpClient((request) async => http.Response('down', 500));

    final useCase = SyncPendingProgressUseCase(
      pendingSyncRepository: repo,
      progressApiClient: ProgressApiClient(config: config, httpClient: client),
    );

    // Act
    await useCase.execute(session);

    // Assert
    final pending = await repo.loadAll();
    expect(pending, hasLength(1));
    expect(pending.single.levelId, const Identifier('level-01'));
  });

  test(
      'should_not_touch_entries_belonging_to_other_players',
      () async {
    // Arrange
    final repo = InMemoryPendingSyncRepository();
    await repo.add(PendingSyncEntry(
      playerId: const Identifier('other-player'),
      levelId: const Identifier('level-05'),
      score: 50,
      moves: 5,
      timeInSeconds: 10,
    ));

    var syncCalls = 0;
    final client = MockHttpClient((request) async {
      syncCalls++;
      return http.Response('{}', 200);
    });

    final useCase = SyncPendingProgressUseCase(
      pendingSyncRepository: repo,
      progressApiClient: ProgressApiClient(config: config, httpClient: client),
    );

    // Act: sincroniza para `session` (u1), no para `other-player`.
    await useCase.execute(session);

    // Assert: no llamó a la red ni tocó la entrada ajena.
    expect(syncCalls, 0);
    final pending = await repo.loadAll();
    expect(pending, hasLength(1));
    expect(pending.single.playerId, const Identifier('other-player'));
  });
}
