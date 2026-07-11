import 'dart:convert';
import 'dart:io';

import 'package:arrow_maze_escape_puzzle/application/models/auth_session.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/http/api_config.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/http/api_exception.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/http/auth_api_client.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/http/leaderboard_api_client.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/http/level_api_client.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/http/progress_api_client.dart';
import 'package:arrow_maze_escape_puzzle/interface_adapters/level_dto_mapper.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../../support/mock_http_client.dart';

/// Pruebas de contrato: verifican que los clientes HTTP REALES del frontend
/// (no una re-implementación de su forma) parsean/emiten datos consistentes
/// con los fixtures compartidos bit-a-bit con
/// `BackEnd-ArrowMaze/docs/contract/fixtures/` (ver
/// `docs/contract/fixtures/README.md` para la justificación de este enfoque
/// en vez de Pact).
Map<String, dynamic> loadFixture(String fileName) {
  final raw = File('docs/contract/fixtures/$fileName').readAsStringSync();
  return jsonDecode(raw) as Map<String, dynamic>;
}

List<dynamic> loadFixtureList(String fileName) {
  final raw = File('docs/contract/fixtures/$fileName').readAsStringSync();
  return jsonDecode(raw) as List<dynamic>;
}

void main() {
  const config = ApiConfig(baseUrl: 'http://contract-test');

  group('AuthApiClient — contract fixtures', () {
    test('should_parse_register_response_fixture_via_real_client', () async {
      final fixture = loadFixture('auth-register-response.json');
      final client = MockHttpClient((request) async {
        return http.Response(jsonEncode(fixture), 201);
      });
      final api = AuthApiClient(config: config, httpClient: client);

      final result = await api.register(username: 'ignored', password: 'ignored12');

      expect(result.userId, fixture['userId']);
      expect(result.username, fixture['username']);
    });

    test('should_parse_login_response_fixture_via_real_client', () async {
      final fixture = loadFixture('auth-login-response.json');
      final client = MockHttpClient((request) async {
        return http.Response(jsonEncode(fixture), 200);
      });
      final api = AuthApiClient(config: config, httpClient: client);

      final session = await api.login(username: 'ignored', password: 'ignored12');

      expect(session.token, fixture['token']);
      expect(session.userId, fixture['userId']);
      expect(session.username, fixture['username']);
    });
  });

  group('ProgressApiClient — contract fixtures', () {
    // `progress-sync-response.json` no se ejercita aquí: `syncProgress()`
    // descarta el cuerpo de la respuesta (devuelve `void`) una vez confirma
    // el 200; el contrato de esa respuesta lo verifica el backend
    // (`contractFixtures.spec.ts`), ya que el frontend no lo consume.
    test('should_send_a_sync_request_body_matching_the_shared_request_fixture', () async {
      final fixture = loadFixture('progress-sync-request.json');
      late Map<String, dynamic> sentBody;
      final client = MockHttpClient((request) async {
        sentBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response('{}', 200);
      });
      final api = ProgressApiClient(config: config, httpClient: client);
      final session = AuthSession(
        token: 'jwt', userId: fixture['userId'] as String, username: 'player',
      );

      await api.syncProgress(
        session: session,
        levelId: fixture['levelId'] as String,
        score: fixture['score'] as int,
        moves: fixture['moves'] as int,
        timeInSeconds: fixture['timeInSeconds'] as int,
        completed: fixture['completed'] as bool,
      );

      expect(sentBody, fixture);
    });

    test('should_parse_progress_get_response_fixture_via_real_client', () async {
      final fixture = loadFixture('progress-get-response.json');
      final client = MockHttpClient((request) async {
        return http.Response(jsonEncode(fixture), 200);
      });
      final api = ProgressApiClient(config: config, httpClient: client);
      const session = AuthSession(token: 'jwt', userId: 'user-1', username: 'player');

      final progress = await api.fetchProgress(session);

      final expectedLevels = fixture['levels'] as List<dynamic>;
      expect(progress, hasLength(expectedLevels.length));
      expect(progress.first.levelId, expectedLevels.first['levelId']);
      expect(progress.first.highScore, expectedLevels.first['highScore']);
      expect(progress.first.minMoves, expectedLevels.first['minMoves']);
      expect(progress.first.minTimeInSeconds, expectedLevels.first['minTimeInSeconds']);
      expect(progress.first.isCompleted, expectedLevels.first['isCompleted']);
    });
  });

  group('LeaderboardApiClient — contract fixtures', () {
    test('should_parse_leaderboard_response_fixture_via_real_client', () async {
      final fixture = loadFixtureList('leaderboard-response.json');
      final client = MockHttpClient((request) async {
        return http.Response(jsonEncode(fixture), 200);
      });
      final api = LeaderboardApiClient(config: config, httpClient: client);

      final entries = await api.fetchLeaderboard(levelId: 'level-1');

      expect(entries, hasLength(fixture.length));
      final first = fixture.first as Map<String, dynamic>;
      expect(entries.first.username, first['username']);
      expect(entries.first.highScore, first['highScore']);
      expect(entries.first.minMoves, first['minMoves']);
      expect(entries.first.minTimeInSeconds, first['minTimeInSeconds']);
    });
  });

  group('LevelApiClient — contract fixtures (GET /levels)', () {
    test('should_map_the_shared_levels_get_response_fixture_via_real_client_and_mapper', () async {
      final fixture = loadFixtureList('levels-get-response.json');
      final client = MockHttpClient((request) async {
        return http.Response(jsonEncode(fixture), 200);
      });
      final api = LevelApiClient(config: config, httpClient: client);
      const mapper = LevelDtoMapper();

      final rawLevels = await api.fetchAllLevels();
      final levels = rawLevels.map(mapper.fromJson).toList();

      final expected = fixture.first as Map<String, dynamic>;
      expect(levels, hasLength(fixture.length));
      expect(levels.first.id.value, expected['id']);
      expect(levels.first.displayName, expected['name']);
      expect(levels.first.levelNumber, expected['levelNumber']);
      expect(levels.first.parMoves, expected['maxMoves']);
      expect(levels.first.timeLimit, expected['maxTimeInSeconds']);
      expect(levels.first.boardDefinition.dimension.rows, expected['height']);
      expect(levels.first.boardDefinition.dimension.columns, expected['width']);
      expect(levels.first.boardDefinition.arrowPlacements, hasLength((expected['arrows'] as List).length));
    });
  });

  group('Error envelope — contract fixtures', () {
    test('should_map_the_shared_401_fixture_to_an_ApiException_with_the_matching_status', () async {
      final fixture = loadFixture('error-401-unauthorized.json');
      final client = MockHttpClient((request) async {
        return http.Response(jsonEncode(fixture), 401);
      });
      final api = AuthApiClient(config: config, httpClient: client);

      await expectLater(
        api.login(username: 'ignored', password: 'ignored12'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.message, 'message', (fixture['error'] as Map)['message']),
        ),
      );
    });

    test('should_map_the_shared_409_fixture_to_an_ApiException_with_the_matching_status', () async {
      final fixture = loadFixture('error-409-user-already-exists.json');
      final client = MockHttpClient((request) async {
        return http.Response(jsonEncode(fixture), 409);
      });
      final api = AuthApiClient(config: config, httpClient: client);

      await expectLater(
        api.register(username: 'ignored', password: 'ignored12'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 409)
              .having((e) => e.message, 'message', (fixture['error'] as Map)['message']),
        ),
      );
    });
  });
}
