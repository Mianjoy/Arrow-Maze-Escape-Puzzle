import 'dart:convert';

import 'package:arrow_maze_escape_puzzle/application/models/auth_session.dart';
import 'package:arrow_maze_escape_puzzle/domain/domain.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/audio/no_op_audio_service.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/auth/in_memory_token_storage.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/http/api_config.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/http/level_api_client.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/level/remote_level_repository.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/progress/in_memory_player_progress_repository.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/settings/in_memory_app_settings.dart';
import 'package:arrow_maze_escape_puzzle/main.dart';
import 'package:http/http.dart' as http;

import '../../support/mock_http_client.dart';
import 'seed_catalog_fixture.dart';

/// Fábrica de dependencias para la suite E2E (sin fallback a assets locales).
class E2eAppFactory {
  static const ApiConfig apiConfig = ApiConfig(baseUrl: 'http://e2e-test');

  static const AuthSession e2eSession = AuthSession(
    token: 'e2e-test-token',
    userId: 'e2e-user-id',
    username: 'e2e_player',
  );

  /// Crea un [AppContainer] cableado al catálogo [catalog] simulado.
  static AppContainer createAppContainer({
    required List<Map<String, dynamic>> catalog,
    AuthSession? session,
  }) {
    final leaderboardStore = <String, List<Map<String, dynamic>>>{};
    final progressRepo = InMemoryPlayerProgressRepository();
    final activeSession = session ?? e2eSession;

    final client = MockHttpClient((request) async {
      if (request.method == 'GET' && request.url.path == '/levels') {
        return http.Response(jsonEncode(catalog), 200, headers: {'content-type': 'application/json'});
      }

      if (request.method == 'GET' && request.url.path.startsWith('/levels/')) {
        final id = Uri.decodeComponent(request.url.pathSegments.last);
        for (final level in catalog) {
          if (level['id'] == id) {
            return http.Response(jsonEncode(level), 200);
          }
        }
        return http.Response('{"error":"not found"}', 404);
      }

      if (request.method == 'POST' && request.url.path == '/progress/sync') {
        final auth = request.headers['Authorization'] ?? request.headers['authorization'];
        if (auth != 'Bearer ${e2eSession.token}') {
          return http.Response(jsonEncode({'error': {'message': 'Unauthorized'}}), 401);
        }
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final levelId = body['levelId'] as String;
        leaderboardStore.putIfAbsent(levelId, () => []).add({
          'username': e2eSession.username,
          'highScore': body['score'],
          'minMoves': body['moves'],
          'minTimeInSeconds': body['timeInSeconds'],
        });
        return http.Response(jsonEncode({...body, 'highScore': body['score'], 'isCompleted': true}), 200);
      }

      if (request.method == 'GET' && request.url.path == '/progress') {
        // Progreso remoto vacío por defecto en E2E; el progreso se siembra
        // localmente vía `_seedAllLevelsUnlocked`.
        return http.Response(jsonEncode({'userId': e2eSession.userId, 'levels': []}), 200);
      }

      if (request.method == 'GET' && request.url.path.startsWith('/leaderboard/')) {
        final levelId = Uri.decodeComponent(request.url.pathSegments.last);
        return http.Response(jsonEncode(leaderboardStore[levelId] ?? []), 200);
      }

      if (request.method == 'POST' && request.url.path == '/auth/register') {
        return http.Response(
          jsonEncode({'userId': e2eSession.userId, 'username': e2eSession.username}),
          201,
        );
      }

      if (request.method == 'POST' && request.url.path == '/auth/login') {
        return http.Response(
          jsonEncode({
            'token': e2eSession.token,
            'userId': e2eSession.userId,
            'username': e2eSession.username,
          }),
          200,
        );
      }

      return http.Response('not found', 404);
    });

    final remote = RemoteLevelRepository(
      apiClient: LevelApiClient(config: apiConfig, httpClient: client),
    );

    _seedAllLevelsUnlocked(progressRepo, catalog, activeSession.playerId);

    return AppContainer(
      levelRepository: remote,
      progressRepository: progressRepo,
      tokenStorage: InMemoryTokenStorage(),
      appSettings: InMemoryAppSettings(),
      audioService: NoOpAudioService(),
      apiConfig: apiConfig,
      httpClient: client,
      initialAuthSession: activeSession,
    );
  }

  /// Desbloquea todos los niveles del catálogo para pruebas E2E de UI.
  static void _seedAllLevelsUnlocked(
    InMemoryPlayerProgressRepository repo,
    List<Map<String, dynamic>> catalog,
    Identifier playerId,
  ) {
    final levels = <Identifier, LevelProgress>{};
    for (final item in catalog) {
      final id = Identifier(item['id'] as String);
      levels[id] = LevelProgress(levelId: id, status: LevelProgressStatus.unlocked);
    }
    repo.save(PlayerProgress(playerId: playerId, levels: levels));
  }

  static AppContainer createWithFullSeedCatalog() {
    return createAppContainer(catalog: SeedCatalogFixture.load());
  }
}
