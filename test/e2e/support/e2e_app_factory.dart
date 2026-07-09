import 'dart:convert';

import 'package:arrow_maze_escape_puzzle/application/models/auth_session.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/auth/in_memory_token_storage.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/http/api_config.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/http/level_api_client.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/level/remote_level_repository.dart';
import 'package:arrow_maze_escape_puzzle/main.dart';
import 'package:http/http.dart' as http;

import '../../support/mock_http_client.dart';
import 'seed_catalog_fixture.dart';

/// Fábrica de dependencias para la suite E2E (sin fallback a assets locales).
///
/// Simula el backend con [MockHttpClient], incluye sesión precargada y mocks
/// de auth/progreso/leaderboard para que la UI no requiera login manual en CI.
class E2eAppFactory {
  /// URL ficticia usada en tests; el mock no realiza red real.
  static const ApiConfig apiConfig = ApiConfig(baseUrl: 'http://e2e-test');

  /// Sesión precargada para pruebas E2E sin pantalla de login.
  static const AuthSession e2eSession = AuthSession(
    token: 'e2e-test-token',
    userId: 'e2e-user-id',
    username: 'e2e_player',
  );

  /// Crea un [AppContainer] cableado solo al catálogo [catalog] simulado.
  static AppContainer createAppContainer({
    required List<Map<String, dynamic>> catalog,
    AuthSession? session,
  }) {
    final leaderboardStore = <String, List<Map<String, dynamic>>>{};

    final client = MockHttpClient((request) async {
      if (request.method == 'GET' && request.url.path == '/levels') {
        return http.Response(
          jsonEncode(catalog),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      if (request.method == 'GET' && request.url.path.startsWith('/levels/')) {
        final id = Uri.decodeComponent(request.url.pathSegments.last);
        Map<String, dynamic>? match;
        for (final level in catalog) {
          if (level['id'] == id) {
            match = level;
            break;
          }
        }
        if (match == null) {
          return http.Response('{"error":"not found"}', 404);
        }
        return http.Response(jsonEncode(match), 200);
      }

      if (request.method == 'POST' && request.url.path == '/progress/sync') {
        final auth = request.headers['Authorization'] ?? request.headers['authorization'];
        if (auth != 'Bearer ${e2eSession.token}') {
          return http.Response(
            jsonEncode({'error': {'message': 'Unauthorized'}}),
            401,
          );
        }
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final levelId = body['levelId'] as String;
        final entry = {
          'username': e2eSession.username,
          'highScore': body['score'],
          'minMoves': body['moves'],
          'minTimeInSeconds': body['timeInSeconds'],
        };
        leaderboardStore.putIfAbsent(levelId, () => []).add(entry);
        return http.Response(
          jsonEncode({
            'userId': body['userId'],
            'levelId': levelId,
            'highScore': body['score'],
            'minMoves': body['moves'],
            'minTimeInSeconds': body['timeInSeconds'],
            'isCompleted': body['completed'],
          }),
          200,
        );
      }

      if (request.method == 'GET' && request.url.path.startsWith('/leaderboard/')) {
        final levelId = Uri.decodeComponent(request.url.pathSegments.last);
        final entries = leaderboardStore[levelId] ?? [];
        return http.Response(jsonEncode(entries), 200);
      }

      if (request.method == 'POST' && request.url.path == '/auth/register') {
        return http.Response(
          jsonEncode({
            'userId': e2eSession.userId,
            'username': e2eSession.username,
          }),
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

    return AppContainer(
      levelRepository: remote,
      tokenStorage: InMemoryTokenStorage(),
      apiConfig: apiConfig,
      httpClient: client,
      fallbackToAssets: false,
      initialAuthSession: session ?? e2eSession,
    );
  }

  /// Crea un contenedor con el fixture completo de 15 niveles del seed.
  static AppContainer createWithFullSeedCatalog() {
    return createAppContainer(catalog: SeedCatalogFixture.load());
  }
}
